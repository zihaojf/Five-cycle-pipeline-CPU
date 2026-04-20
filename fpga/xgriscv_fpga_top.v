`timescale 1ns / 1ps

module IP2SOC_Top #(
  parameter integer SYS_CLK_FREQ  = 100000000
)(
  input         clk,
  input         rstn,
  input [15:0]  sw_i,
  output [7:0]  disp_seg_o,
  output [7:0]  disp_an_o,
  output [3:0]  vga_red_o,
  output [3:0]  vga_green_o,
  output [3:0]  vga_blue_o,
  output        vga_hs_o,
  output        vga_vs_o,
  input         ps2_clk,
  input         ps2_data
);

  wire rst_btn;
  assign rst_btn = ~rstn;

  // Run CPU/peripherals at 50MHz from 100MHz board clock.
  // Keep VGA pixel clock at 25MHz.
  localparam integer CPU_OUT_FREQ = 50000000;
  localparam integer VGA_OUT_FREQ = 25000000;

  wire clk_cpu;
  wire clk_vga;

  clkgen #(
    .clk_freq(CPU_OUT_FREQ),
    .clkin_freq(SYS_CLK_FREQ)
  ) u_cpu_clk_div (
    .clkin(clk),
    .rst(1'b0),
    .clken(1'b1),
    .clkout(clk_cpu)
  );

  clkgen #(
    .clk_freq(VGA_OUT_FREQ),
    .clkin_freq(SYS_CLK_FREQ)
  ) u_vga_clk_div (
    .clkin(clk),
    .rst(1'b0),
    .clken(1'b1),
    .clkout(clk_vga)
  );

  // Power-on reset stretch so the system gets a clean reset pulse
  // even if external reset pin is already released at configuration time.
  reg [7:0] por_cnt;
  wire rst;
  assign rst = rst_btn | ~por_cnt[7];

  initial begin
    por_cnt = 8'h00;
  end

  always @(posedge clk_cpu or posedge rst_btn) begin
    if (rst_btn) begin
      por_cnt <= 8'h00;
    end else if (!por_cnt[7]) begin
      por_cnt <= por_cnt + 1'b1;
    end
  end

  wire [31:0] instr;
  wire [31:0] PC;
  wire        MemWrite;
  wire        MemRead;

  wire [31:0] cpu_data_out;
  wire [31:0] cpu_data_addr;
  wire [31:0] cpu_data_in;
  wire [2:0]  cpu_data_amp;

  wire [31:0] dm_din;
  wire [31:0] dm_dout;
  wire [31:0] ram_addr;
  wire [2:0]  ram_amp;
  wire        ram_we;

  wire [31:0] vmem_addr;
  wire [31:0] vmem_data_in;
  wire        vmem_we;
  wire [2:0]  vmem_amp;

  wire [31:0] key_data_out;
  wire        key_re;
  reg         key_re_pos;
  wire [31:0] ps2_data_raw;
  wire        ps2_ready;
  reg         nextdata_n;
  localparam integer KBD_Q_DEPTH = 16;
  reg  [7:0]  kbd_q [0:KBD_Q_DEPTH - 1];
  reg  [3:0]  kbd_q_wptr;
  reg  [3:0]  kbd_q_rptr;
  reg  [4:0]  kbd_q_count;
  integer     kbd_q_i;

  wire [31:0] hex_data_next;
  wire        seg7_we;

  wire [31:0] ledr_data_in;
  wire        ledr_we;

  wire [31:0] vga_ctrl_data;
  wire        vga_ctrl_we;

  wire [31:0] fb_addr;
  wire [31:0] fb_data_in;
  wire [31:0] fb_data_out;
  wire        fb_we;
  wire [2:0]  fb_amp;

  reg [31:0] hex_data_reg;
  reg [31:0] ledr_data_reg;
  reg [31:0] vga_ctrl_reg;

  reg [31:0] clk_us_cnt;
  reg [31:0] clk_ms_cnt;
  reg [31:0] clk_ds_cnt;
  reg [31:0] clk_s_cnt;

  reg [31:0] us_div;
  reg [31:0] ms_div;
  reg [31:0] ds_div;
  reg [31:0] s_div;

  // MMIO timer counters are generated in clk_cpu domain.
  // Use the intended cpu output frequency directly to avoid SYS_CLK_FREQ
  // mis-configuration (e.g. set to 100 instead of 100000000) breaking timing scale.
  localparam integer CPU_CLK_FREQ = CPU_OUT_FREQ;
  localparam integer US_DIV_MAX = (CPU_CLK_FREQ / 1000000 > 0) ? (CPU_CLK_FREQ / 1000000 - 1) : 0;
  localparam integer MS_DIV_MAX = (CPU_CLK_FREQ / 1000    > 0) ? (CPU_CLK_FREQ / 1000    - 1) : 0;
  localparam integer DS_DIV_MAX = (CPU_CLK_FREQ / 10      > 0) ? (CPU_CLK_FREQ / 10      - 1) : 0;
  localparam integer S_DIV_MAX  = (CPU_CLK_FREQ           > 0) ? (CPU_CLK_FREQ           - 1) : 0;

  wire [31:0] reg_data;
  wire [31:0] seg7_data;

  // Sample KBD read request on posedge. The local queue pops on negedge using
  // this sampled request, i.e. after MEM/WB has already captured Data_in.
  always @(posedge clk_cpu or posedge rst) begin
    if (rst) begin
      key_re_pos <= 1'b0;
    end else begin
      key_re_pos <= key_re;
    end
  end

  // Keyboard bridge for pipelined CPU:
  // drain PS2 FIFO into a local queue, then let CPU consume at MMIO read pace.
  // This prevents dropped keys when make/break/extended sequences arrive in bursts.
  always @(negedge clk_cpu or posedge rst) begin
    if (rst) begin
      nextdata_n <= 1'b1;
      kbd_q_wptr <= 4'd0;
      kbd_q_rptr <= 4'd0;
      kbd_q_count <= 5'd0;
      for (kbd_q_i = 0; kbd_q_i < KBD_Q_DEPTH; kbd_q_i = kbd_q_i + 1) begin
        kbd_q[kbd_q_i] <= 8'h00;
      end
    end else begin
      // default high; pull low only when taking one byte from ps2_keyboard FIFO
      nextdata_n <= 1'b1;

      // CPU consumes one queued byte on a KBD MMIO read
      if (key_re_pos && (kbd_q_count != 0)) begin
        kbd_q_rptr <= kbd_q_rptr + 4'd1;
      end

      // drain one byte from ps2 FIFO whenever local queue has space
      // (or when this cycle also dequeues one byte from local queue)
      if (ps2_ready && ((kbd_q_count != KBD_Q_DEPTH) || (key_re_pos && (kbd_q_count != 0)))) begin
        kbd_q[kbd_q_wptr] <= ps2_data_raw[7:0];
        kbd_q_wptr <= kbd_q_wptr + 4'd1;
        nextdata_n <= 1'b0;
      end

      case ({(ps2_ready && ((kbd_q_count != KBD_Q_DEPTH) || (key_re_pos && (kbd_q_count != 0)))), (key_re_pos && (kbd_q_count != 0))})
        2'b10: kbd_q_count <= kbd_q_count + 5'd1;
        2'b01: kbd_q_count <= kbd_q_count - 5'd1;
        default: kbd_q_count <= kbd_q_count;
      endcase
    end
  end

  // Keep compatibility with existing MIO_BUS decode:
  // bit[8] = ready, bit[7:0] = scan code.
  assign key_data_out = {23'b0, (kbd_q_count != 0), kbd_q[kbd_q_rptr]};

  im U_IM(
    .clk(~clk_cpu),
    .addr(PC[31:2]),
    .dout(instr)
  );

  dm U_dmem(
    .clk(clk_cpu),
    .DMWr(ram_we),
    .DMType(ram_amp),
    .addr(ram_addr),
    .din(dm_din),
    .dout(dm_dout)
  );

  MIO_BUS U_MIO(
    .mem_w(MemWrite),
    .mem_r(MemRead),
    .sw_i(sw_i),
    .cpu_data_out(cpu_data_out),
    .cpu_data_addr(cpu_data_addr),
    .cpu_data_amp(cpu_data_amp),

    .ram_data_out(dm_dout),
    .key_data_out(key_data_out),
    .hex_data_out(hex_data_reg),
    .ledr_data_out(ledr_data_reg),
    .vga_ctrl_out(vga_ctrl_reg),
    .clk_us_out(clk_us_cnt),
    .clk_ms_out(clk_ms_cnt),
    .clk_ds_out(clk_ds_cnt),
    .clk_s_out(clk_s_cnt),
    .fb_data_out(fb_data_out),

    .cpu_data_in(cpu_data_in),

    .ram_data_in(dm_din),
    .ram_addr(ram_addr),
    .ram_we(ram_we),
    .ram_amp(ram_amp),

    .vmem_data_in(vmem_data_in),
    .vmem_addr(vmem_addr),
    .vmem_we(vmem_we),
    .vmem_amp(vmem_amp),

    .cpuseg7_data(hex_data_next),
    .seg7_we(seg7_we),

    .ledr_data_in(ledr_data_in),
    .ledr_we(ledr_we),

    .key_re(key_re),

    .vga_ctrl_data(vga_ctrl_data),
    .vga_ctrl_we(vga_ctrl_we),

    .fb_data_in(fb_data_in),
    .fb_addr(fb_addr),
    .fb_we(fb_we),
    .fb_amp(fb_amp)
  );

  always @(posedge clk_cpu or posedge rst) begin
    if (rst) begin
      hex_data_reg  <= 32'h0;
      ledr_data_reg <= 32'h0;
      vga_ctrl_reg  <= 32'h0;
    end else begin
      if (seg7_we)   hex_data_reg  <= hex_data_next;
      if (ledr_we)   ledr_data_reg <= ledr_data_in;
      if (vga_ctrl_we) vga_ctrl_reg <= vga_ctrl_data;
    end
  end

  always @(posedge clk_cpu or posedge rst) begin
    if (rst) begin
      clk_us_cnt <= 32'h0;
      clk_ms_cnt <= 32'h0;
      clk_ds_cnt <= 32'h0;
      clk_s_cnt  <= 32'h0;
      us_div <= 32'd0;
      ms_div <= 32'd0;
      ds_div <= 32'd0;
      s_div  <= 32'd0;
    end else begin
      if (us_div == US_DIV_MAX) begin
        us_div <= 32'd0;
        clk_us_cnt <= clk_us_cnt + 1'b1;
      end else begin
        us_div <= us_div + 1'b1;
      end

      if (ms_div == MS_DIV_MAX) begin
        ms_div <= 32'd0;
        clk_ms_cnt <= clk_ms_cnt + 1'b1;
      end else begin
        ms_div <= ms_div + 1'b1;
      end

      if (ds_div == DS_DIV_MAX) begin
        ds_div <= 32'd0;
        clk_ds_cnt <= clk_ds_cnt + 1'b1;
      end else begin
        ds_div <= ds_div + 1'b1;
      end

      if (s_div == S_DIV_MAX) begin
        s_div <= 32'd0;
        clk_s_cnt <= clk_s_cnt + 1'b1;
      end else begin
        s_div <= s_div + 1'b1;
      end
    end
  end

  MULTI_CH32 U_Multi(
    .clk(clk_cpu),
    .rst(rst),
    .EN(seg7_we),
    .ctrl(sw_i[5:0]),
    .Data0(hex_data_next),
    .data1({2'b0, PC[31:2]}),
    .data2(PC),
    .data3(instr),
    .data4(cpu_data_addr),
    .data5(cpu_data_out),
    .data6(dm_dout),
    .data7(ram_addr),
    .reg_data(reg_data),
    .seg7_data(seg7_data)
  );

  SCPU U_xgriscv(
    .clk(clk_cpu),
    .rst(rst),
    .PC_out(PC),
    .inst_in(instr),
    .mem_w(MemWrite),
    .mem_r(MemRead),
    .dm_dmtype(cpu_data_amp),
    .Addr_out(cpu_data_addr),
    .Data_out(cpu_data_out),
    .Data_in(cpu_data_in),
    .reg_sel(sw_i[4:0]),
    .reg_data(reg_data)
  );

  SEG7x16 U_7SEG(
    .clk(clk_cpu),
    .rst(rst),
    .cs(1'b1),
    .i_data(seg7_data),
    .o_seg(disp_seg_o),
    .o_sel(disp_an_o)
  );

  // VGA scan
  wire [9:0] h_addr;
  wire [9:0] v_addr;
  wire [11:0] text_vga_data;
  wire [11:0] fb_vga_data;
  wire        vga_valid_unused;

  vga_ctrl U_vga_ctrl(
    .pclk(clk_vga),
    .reset(rst),
    .vga_data(vga_ctrl_reg[0] ? fb_vga_data : text_vga_data),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .hsync(vga_hs_o),
    .vsync(vga_vs_o),
    .valid(vga_valid_unused),
    .vga_r(vga_red_o),
    .vga_g(vga_green_o),
    .vga_b(vga_blue_o)
  );

  videomem U_VIDEOMEM(
    .clk(clk_cpu),
    .pclk(clk_vga),
    .rst(rst),
    .vmem_data_in(vmem_data_in),
    .cpu_vmem_addr(vmem_addr),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .vmem_we(vmem_we),
    .VMType(vmem_amp),
    .vmem_data_out(text_vga_data)
  );

  framebuffer U_FRAMEBUFFER(
    .clk(clk_cpu),
    .pclk(clk_vga),
    .rst(rst),
    .fb_data_in(fb_data_in),
    .fb_addr(fb_addr),
    .fb_we(fb_we),
    .FBType(fb_amp),
    .h_addr(h_addr),
    .v_addr(v_addr),
    .fb_data_out(fb_data_out),
    .fb_pixel_out(fb_vga_data)
  );

  ps2_keyboard U_PS2_KEYBOARD(
    .clk(clk_cpu),
    .clrn(~rst),
    .ps2_clk(ps2_clk),
    .ps2_data(ps2_data),
    .nextdata_n(nextdata_n),
    .data(ps2_data_raw),
    .ready(ps2_ready),
    .overflow()
  );

endmodule
