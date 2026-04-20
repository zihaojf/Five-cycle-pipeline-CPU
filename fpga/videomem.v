`include "ctrl_encode_def.v"

module videomem(
    input         clk,
    input         pclk,
    input         rst,
    input  [31:0] vmem_data_in,
    input  [31:0] cpu_vmem_addr,
    input  [9:0]  h_addr,
    input  [9:0]  v_addr,
    input         vmem_we,
    input  [2:0]  VMType,
    output [11:0] vmem_data_out
);

localparam VMEM_COLS   = 80;
localparam VMEM_ROWS   = 30;
localparam VMEM_WORDS  = 2048; // 4096 text cells, two cells per 32-bit word
localparam VMEM_ADDRW  = 11;

localparam FONT_WORDS  = 4096;
localparam FONT_ADDRW  = 12;

wire [4:0] s0_vaddr   = v_addr[8:4];
wire [6:0] s0_haddr   = h_addr[9:3];
wire [2:0] s0_font_h  = h_addr[2:0];
wire [3:0] s0_font_v  = v_addr[3:0];
wire       s0_valid   = (s0_vaddr < VMEM_ROWS) && (s0_haddr < VMEM_COLS);
wire [11:0] s0_cell   = s0_vaddr * VMEM_COLS + s0_haddr;
wire [VMEM_ADDRW-1:0] s0_word_addr = s0_cell[11:1];
wire       s0_half_sel = s0_cell[0];

wire [VMEM_ADDRW-1:0] cpu_word_addr = cpu_vmem_addr[12:2];
wire [1:0] cpu_byte_off = cpu_vmem_addr[1:0];

reg [31:0] cpu_din_w;
reg [3:0]  cpu_we_w;

wire [31:0] vmem_q_cpu;
wire [31:0] vmem_q_vga;
wire [8:0]  font_q;

reg         s0d_valid;
reg         s0d_half_sel;
reg [2:0]   s0d_font_h;
reg [3:0]   s0d_font_v;

reg         s1_valid;
reg [2:0]   s1_font_h;
reg [11:0]  s1_bg_color;
reg [11:0]  s1_fg_color;
reg [11:0]  s1_font_addr;

reg         s2_valid;
reg [2:0]   s2_font_h;
reg [11:0]  s2_bg_color;
reg [11:0]  s2_fg_color;
reg [8:0]   s2_font_bits;

wire [15:0] s1_cell_w = s0d_half_sel ? vmem_q_vga[31:16] : vmem_q_vga[15:0];
wire        s1_bspecial_w = s1_cell_w[15];
wire [2:0]  s1_bspec_w    = s1_cell_w[14:12];
wire        s1_fspecial_w = s1_cell_w[11];
wire [2:0]  s1_fspec_w    = s1_cell_w[10:8];
wire [7:0]  s1_ascii_w    = s1_cell_w[7:0];
wire [11:0] s1_bg_w = s1_bspecial_w ? {{4{s1_bspec_w[0]}}, {4{s1_bspec_w[1]}}, {4{s1_bspec_w[2]}}} : 12'h000;
wire [11:0] s1_fg_w = s1_fspecial_w ? {{4{s1_fspec_w[0]}}, {4{s1_fspec_w[1]}}, {4{s1_fspec_w[2]}}} : 12'hfff;
wire [11:0] s1_font_addr_w = {s1_ascii_w, s0d_font_v};

wire [VMEM_ADDRW-1:0] vga_word_addr = s0_valid ? s0_word_addr : {VMEM_ADDRW{1'b0}};
wire _unused_vmem_q_cpu = ^vmem_q_cpu;

always @(*) begin
    cpu_din_w = 32'h0;
    cpu_we_w  = 4'b0000;
    if (vmem_we) begin
        case (VMType)
            `dm_word: begin
                cpu_din_w = vmem_data_in;
                cpu_we_w  = 4'b1111;
            end

            `dm_halfword: begin
                cpu_din_w = {vmem_data_in[15:0], vmem_data_in[15:0]};
                cpu_we_w  = cpu_vmem_addr[1] ? 4'b1100 : 4'b0011;
            end

            `dm_byte: begin
                cpu_din_w = {4{vmem_data_in[7:0]}};
                case (cpu_byte_off)
                    2'b00: cpu_we_w = 4'b0001;
                    2'b01: cpu_we_w = 4'b0010;
                    2'b10: cpu_we_w = 4'b0100;
                    2'b11: cpu_we_w = 4'b1000;
                    default: cpu_we_w = 4'b0000;
                endcase
            end

            default: begin
                cpu_din_w = 32'h0;
                cpu_we_w  = 4'b0000;
            end
        endcase
    end
end

always @(posedge pclk or posedge rst) begin
    if (rst) begin
        s0d_valid    <= 1'b0;
        s0d_half_sel <= 1'b0;
        s0d_font_h   <= 3'd0;
        s0d_font_v   <= 4'd0;

        s1_valid     <= 1'b0;
        s1_font_h    <= 3'd0;
        s1_bg_color  <= 12'h000;
        s1_fg_color  <= 12'hfff;
        s1_font_addr <= 12'h000;

        s2_valid     <= 1'b0;
        s2_font_h    <= 3'd0;
        s2_bg_color  <= 12'h000;
        s2_fg_color  <= 12'hfff;
        s2_font_bits <= 9'h000;
    end else begin
        // Align metadata with BRAM read latency (1 cycle)
        s0d_valid    <= s0_valid;
        s0d_half_sel <= s0_half_sel;
        s0d_font_h   <= s0_font_h;
        s0d_font_v   <= s0_font_v;

        // Build glyph/color request from text cell fetched from VMEM
        s1_valid     <= s0d_valid;
        s1_font_h    <= s0d_font_h;
        s1_bg_color  <= s1_bg_w;
        s1_fg_color  <= s1_fg_w;
        s1_font_addr <= s1_font_addr_w;

        // Fetch font row (font ROM is also 1-cycle sync read)
        s2_valid     <= s1_valid;
        s2_font_h    <= s1_font_h;
        s2_bg_color  <= s1_bg_color;
        s2_fg_color  <= s1_fg_color;
        s2_font_bits <= font_q;
    end
end

assign vmem_data_out = s2_valid ? (s2_font_bits[s2_font_h] ? s2_fg_color : s2_bg_color) : 12'h000;

`ifdef SYNTHESIS
xpm_memory_tdpram #(
    .ADDR_WIDTH_A(VMEM_ADDRW),
    .ADDR_WIDTH_B(VMEM_ADDRW),
    .AUTO_SLEEP_TIME(0),
    .BYTE_WRITE_WIDTH_A(8),
    .BYTE_WRITE_WIDTH_B(8),
    .CASCADE_HEIGHT(0),
    .CLOCKING_MODE("independent_clock"),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("vmem_init.mem"),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(VMEM_WORDS * 32),
    .MESSAGE_CONTROL(0),
    .READ_DATA_WIDTH_A(32),
    .READ_DATA_WIDTH_B(32),
    .READ_LATENCY_A(1),
    .READ_LATENCY_B(1),
    .READ_RESET_VALUE_A("0"),
    .READ_RESET_VALUE_B("0"),
    .RST_MODE_A("SYNC"),
    .RST_MODE_B("SYNC"),
    .SIM_ASSERT_CHK(0),
    .USE_EMBEDDED_CONSTRAINT(0),
    .USE_MEM_INIT(1),
    .WAKEUP_TIME("disable_sleep"),
    .WRITE_DATA_WIDTH_A(32),
    .WRITE_DATA_WIDTH_B(32),
    .WRITE_MODE_A("read_first"),
    .WRITE_MODE_B("read_first")
) u_vmem (
    .addra(cpu_word_addr),
    .addrb(vga_word_addr),
    .clka(clk),
    .clkb(pclk),
    .dina(cpu_din_w),
    .dinb(32'h0),
    .ena(1'b1),
    .enb(1'b1),
    .injectdbiterra(1'b0),
    .injectdbiterrb(1'b0),
    .injectsbiterra(1'b0),
    .injectsbiterrb(1'b0),
    .regcea(1'b1),
    .regceb(1'b1),
    .rsta(rst),
    .rstb(rst),
    .sleep(1'b0),
    .wea(cpu_we_w),
    .web(4'b0000),
    .douta(vmem_q_cpu),
    .doutb(vmem_q_vga),
    .dbiterra(),
    .dbiterrb(),
    .sbiterra(),
    .sbiterrb()
);

xpm_memory_sprom #(
    .ADDR_WIDTH_A(FONT_ADDRW),
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("vga_font.mem"),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(FONT_WORDS * 9),
    .MESSAGE_CONTROL(0),
    .READ_DATA_WIDTH_A(9),
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("0"),
    .RST_MODE_A("SYNC"),
    .SIM_ASSERT_CHK(0),
    .USE_MEM_INIT(1),
    .WAKEUP_TIME("disable_sleep")
) u_font (
    .addra(s1_font_addr),
    .clka(pclk),
    .douta(font_q),
    .ena(1'b1),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),
    .regcea(1'b1),
    .rsta(rst),
    .sleep(1'b0),
    .dbiterra(),
    .sbiterra()
);
`else
(* ram_style = "block" *) reg [31:0] vmem [0:VMEM_WORDS - 1];
(* rom_style = "block" *) reg [8:0] fontmem [0:FONT_WORDS - 1];
reg [31:0] vmem_q_cpu_r;
reg [31:0] vmem_q_vga_r;

integer i;
initial begin
    for (i = 0; i < VMEM_WORDS; i = i + 1) begin
        vmem[i] = 32'h0f20_0f20;
    end
    for (i = 0; i < FONT_WORDS; i = i + 1) begin
        fontmem[i] = 9'h000;
    end
    $readmemh("vga_font.mem", fontmem);
end

always @(posedge clk) begin
    if (cpu_we_w[0]) vmem[cpu_word_addr][7:0]   <= cpu_din_w[7:0];
    if (cpu_we_w[1]) vmem[cpu_word_addr][15:8]  <= cpu_din_w[15:8];
    if (cpu_we_w[2]) vmem[cpu_word_addr][23:16] <= cpu_din_w[23:16];
    if (cpu_we_w[3]) vmem[cpu_word_addr][31:24] <= cpu_din_w[31:24];
    vmem_q_cpu_r <= vmem[cpu_word_addr];
end

always @(posedge pclk) begin
    vmem_q_vga_r <= vmem[vga_word_addr];
end

assign vmem_q_cpu = vmem_q_cpu_r;
assign vmem_q_vga = vmem_q_vga_r;
assign font_q     = fontmem[s1_font_addr];
`endif

endmodule
