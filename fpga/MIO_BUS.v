`timescale 1ns / 1ps
`include "ctrl_encode_def.v"

// memory IO bus
module MIO_BUS(
    input         mem_w,
    input         mem_r,
    input [15:0]  sw_i,
    input [31:0]  cpu_data_out,
    input [31:0]  cpu_data_addr,
    input [2:0]   cpu_data_amp,

    input [31:0]  ram_data_out,
    input [31:0]  key_data_out,
    input [31:0]  hex_data_out,
    input [31:0]  ledr_data_out,
    input [31:0]  vga_ctrl_out,
    input [31:0]  clk_us_out,
    input [31:0]  clk_ms_out,
    input [31:0]  clk_ds_out,
    input [31:0]  clk_s_out,
    input [31:0]  fb_data_out,

    output reg [31:0] cpu_data_in,

    output reg [31:0] ram_data_in,
    output reg [31:0] ram_addr,
    output reg        ram_we,
    output reg [2:0]  ram_amp,

    output reg [31:0] vmem_data_in,
    output reg [31:0] vmem_addr,
    output reg        vmem_we,
    output reg [2:0]  vmem_amp,

    output reg [31:0] cpuseg7_data,
    output reg        seg7_we,

    output reg [31:0] ledr_data_in,
    output reg        ledr_we,

    output reg        key_re,

    output reg [31:0] vga_ctrl_data,
    output reg        vga_ctrl_we,

    output reg [31:0] fb_data_in,
    output reg [31:0] fb_addr,
    output reg        fb_we,
    output reg [2:0]  fb_amp
);

localparam [3:0] TAG_MEM      = 4'h1;
localparam [3:0] TAG_KBD      = 4'h2;
localparam [3:0] TAG_VMEM     = 4'h3;
localparam [3:0] TAG_HEX      = 4'h4;
localparam [3:0] TAG_LEDR     = 4'h5;
localparam [3:0] TAG_SW       = 4'h6;
localparam [3:0] TAG_KEY      = 4'h7;
localparam [3:0] TAG_CLK      = 4'h8;
localparam [3:0] TAG_VGA_CTRL = 4'h9;
localparam [3:0] TAG_FB       = 4'ha;

always @* begin
    cpu_data_in   = 32'h0;

    ram_addr      = 32'h0;
    ram_data_in   = 32'h0;
    ram_we        = 1'b0;
    ram_amp       = 3'b0;

    vmem_addr     = 32'h0;
    vmem_data_in  = 32'h0;
    vmem_we       = 1'b0;
    vmem_amp      = 3'b0;

    cpuseg7_data  = hex_data_out;
    seg7_we       = 1'b0;

    ledr_data_in  = ledr_data_out;
    ledr_we       = 1'b0;

    key_re        = 1'b0;

    vga_ctrl_data = vga_ctrl_out;
    vga_ctrl_we   = 1'b0;

    fb_addr       = 32'h0;
    fb_data_in    = 32'h0;
    fb_we         = 1'b0;
    fb_amp        = 3'b0;

    // MMIO map (aligned with NJU_DigitalDesignProject)
    // 0x0100_0000 MEM
    // 0x0200_0000 KBD
    // 0x0300_0000 VMEM
    // 0x0400_0000 HEX
    // 0x0500_0000 LEDR
    // 0x0600_0000 SW
    // 0x0700_0000 KEY
    // 0x0800_0000 CLK
    // 0x0900_0000 VGA_CTRL
    // 0x0a00_0000 FB
    case (cpu_data_addr[27:24])
      TAG_MEM: begin
        ram_addr    = cpu_data_addr - 32'h01000000;
        ram_data_in = cpu_data_out;
        ram_we      = mem_w;
        ram_amp     = cpu_data_amp;
        cpu_data_in = ram_data_out;
      end

      TAG_KBD: begin
        if (cpu_data_addr == 32'h02000000) begin
          key_re      = mem_r;
          cpu_data_in = key_data_out[8] ? {24'h0, key_data_out[7:0]} : 32'h0;
        end
      end

      TAG_VMEM: begin
        vmem_addr    = cpu_data_addr - 32'h03000000;
        vmem_data_in = cpu_data_out;
        vmem_we      = mem_w;
        vmem_amp     = cpu_data_amp;
      end

      TAG_HEX: begin
        cpu_data_in = hex_data_out;
        if (mem_w && cpu_data_addr[2:1] != 2'b11) begin
          case (cpu_data_addr[2:0])
            3'd0: cpuseg7_data[3:0]   = cpu_data_out[3:0];
            3'd1: cpuseg7_data[7:4]   = cpu_data_out[3:0];
            3'd2: cpuseg7_data[11:8]  = cpu_data_out[3:0];
            3'd3: cpuseg7_data[15:12] = cpu_data_out[3:0];
            3'd4: cpuseg7_data[19:16] = cpu_data_out[3:0];
            3'd5: cpuseg7_data[23:20] = cpu_data_out[3:0];
            default: ;
          endcase
          seg7_we = (cpu_data_addr[2:0] < 3'd6);
        end
      end

      TAG_LEDR: begin
        cpu_data_in = ledr_data_out;
        if (mem_w) begin
          ledr_data_in = cpu_data_out;
          ledr_we      = 1'b1;
        end
      end

      TAG_SW: begin
        if (cpu_data_addr == 32'h06000000) cpu_data_in = {16'h0, sw_i};
      end

      TAG_KEY: begin
        cpu_data_in = 32'h0;
      end

      TAG_CLK: begin
        case (cpu_data_addr[3:2])
          2'b00: cpu_data_in = clk_us_out;
          2'b01: cpu_data_in = clk_ms_out;
          2'b10: cpu_data_in = clk_ds_out;
          2'b11: cpu_data_in = clk_s_out;
          default: cpu_data_in = 32'h0;
        endcase
      end

      TAG_VGA_CTRL: begin
        cpu_data_in = vga_ctrl_out;
        if (mem_w) begin
          vga_ctrl_data = cpu_data_out;
          vga_ctrl_we   = 1'b1;
        end
      end

      TAG_FB: begin
        fb_addr    = cpu_data_addr - 32'h0a000000;
        fb_data_in = cpu_data_out;
        fb_we      = mem_w;
        fb_amp     = cpu_data_amp;
        cpu_data_in = fb_data_out;
      end

      default: begin
      end
    endcase
  end

endmodule
