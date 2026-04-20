`include "ctrl_encode_def.v"

module framebuffer(
    input         clk,
    input         pclk,
    input         rst,
    input  [31:0] fb_data_in,
    input  [31:0] fb_addr,
    input         fb_we,
    input  [2:0]  FBType,
    input  [9:0]  h_addr,
    input  [9:0]  v_addr,
    output reg [31:0] fb_data_out,
    output [11:0] fb_pixel_out
);

localparam FB_WIDTH  = 640;
localparam FB_HEIGHT = 480;
localparam FB_PIXELS = FB_WIDTH * FB_HEIGHT;

localparam FB_ADDRW = 19;

// Store RGBI444-index (4bpp) in BRAM to fit board resources.
wire [FB_ADDRW-1:0] wr_idx = fb_addr[20:2];
wire [FB_ADDRW-1:0] rd_idx = ({9'b0, v_addr} << 9) + ({9'b0, v_addr} << 7) + h_addr;
// Quantize 24-bit RGB to 4-bit RGBI.
// Keep primary colors stable; only raise I for near-white pixels.
wire [3:0] wr_color = {
    fb_data_in[23],                                // R msb
    fb_data_in[15],                                // G msb
    fb_data_in[7],                                 // B msb
    (fb_data_in[22] & fb_data_in[14] & fb_data_in[6]) // intensity only when RGB are all bright
};
wire       wr_valid = (wr_idx < FB_PIXELS);
wire       rd_valid = (rd_idx < FB_PIXELS);

reg  [3:0] fb_cpu_q;
reg  [3:0] fb_vga_q;
reg        wr_valid_d;
reg        rd_valid_d;

wire [3:0] fb_cpu_q_w;
wire [3:0] fb_vga_q_w;

wire [1:0] fb_cpu_r2 = {fb_cpu_q[3], fb_cpu_q[0]};
wire [1:0] fb_cpu_g2 = {fb_cpu_q[2], fb_cpu_q[0]};
wire [1:0] fb_cpu_b2 = {fb_cpu_q[1], fb_cpu_q[0]};
wire [1:0] fb_vga_r2 = {fb_vga_q[3], fb_vga_q[0]};
wire [1:0] fb_vga_g2 = {fb_vga_q[2], fb_vga_q[0]};
wire [1:0] fb_vga_b2 = {fb_vga_q[1], fb_vga_q[0]};

wire [FB_ADDRW-1:0] addra = wr_valid ? wr_idx : {FB_ADDRW{1'b0}};
wire [FB_ADDRW-1:0] addrb = rd_valid ? rd_idx : {FB_ADDRW{1'b0}};

// Keep interface behavior; FBType does not change pixel packing.
wire _unused_fbtype = ^FBType;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        wr_valid_d  <= 1'b0;
        fb_cpu_q    <= 4'b0000;
        fb_data_out <= 32'h0000_0000;
    end else begin
        wr_valid_d <= wr_valid;
        fb_cpu_q   <= wr_valid_d ? fb_cpu_q_w : 4'b0000;
        fb_data_out <= {
            8'h00,
            {4{fb_cpu_r2}},
            {4{fb_cpu_g2}},
            {4{fb_cpu_b2}}
        };
    end
end

always @(posedge pclk or posedge rst) begin
    if (rst) begin
        rd_valid_d <= 1'b0;
        fb_vga_q   <= 4'b0000;
    end else begin
        rd_valid_d <= rd_valid;
        fb_vga_q   <= rd_valid_d ? fb_vga_q_w : 4'b0000;
    end
end

assign fb_pixel_out = {
    {2{fb_vga_r2}},
    {2{fb_vga_g2}},
    {2{fb_vga_b2}}
};

`ifdef SYNTHESIS
xpm_memory_tdpram #(
    .ADDR_WIDTH_A(FB_ADDRW),
    .ADDR_WIDTH_B(FB_ADDRW),
    .AUTO_SLEEP_TIME(0),
    .BYTE_WRITE_WIDTH_A(4),
    .BYTE_WRITE_WIDTH_B(4),
    .CASCADE_HEIGHT(0),
    .CLOCKING_MODE("independent_clock"),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("none"),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(FB_PIXELS * 4),
    .MESSAGE_CONTROL(0),
    .READ_DATA_WIDTH_A(4),
    .READ_DATA_WIDTH_B(4),
    .READ_LATENCY_A(1),
    .READ_LATENCY_B(1),
    .READ_RESET_VALUE_A("0"),
    .READ_RESET_VALUE_B("0"),
    .RST_MODE_A("SYNC"),
    .RST_MODE_B("SYNC"),
    .SIM_ASSERT_CHK(0),
    .USE_EMBEDDED_CONSTRAINT(0),
    .USE_MEM_INIT(0),
    .WAKEUP_TIME("disable_sleep"),
    .WRITE_DATA_WIDTH_A(4),
    .WRITE_DATA_WIDTH_B(4),
    .WRITE_MODE_A("read_first"),
    .WRITE_MODE_B("read_first")
) u_fb_ram (
    .addra(addra),
    .addrb(addrb),
    .clka(clk),
    .clkb(pclk),
    .dina(wr_color),
    .dinb(4'b0000),
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
    .wea(fb_we && wr_valid),
    .web(1'b0),
    .douta(fb_cpu_q_w),
    .doutb(fb_vga_q_w),
    .dbiterra(),
    .dbiterrb(),
    .sbiterra(),
    .sbiterrb()
);
`else
(* ram_style = "block" *) reg [3:0] fb_mem [0:FB_PIXELS - 1];

assign fb_cpu_q_w = fb_mem[addra];
assign fb_vga_q_w = fb_mem[addrb];

always @(posedge clk) begin
    if (fb_we && wr_valid) begin
        fb_mem[wr_idx] <= wr_color;
    end
end
`endif

endmodule
