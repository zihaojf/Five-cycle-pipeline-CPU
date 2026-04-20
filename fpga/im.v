// instruction memory (BRAM-friendly, sync read)
module im(
  input         clk,
  input  [31:2] addr,
  output [31:0] dout
);

  localparam IMEM_WORDS = 32768;

  (* ram_style = "block" *) reg [31:0] ROM [0:IMEM_WORDS - 1];
  reg [31:0] dout_r;
  integer i;

  initial begin
    for (i = 0; i < IMEM_WORDS; i = i + 1) begin
      ROM[i] = 32'h00000013; // nop
    end
    $readmemh("Test_8_Instr.dat", ROM);
  end

  // Use registered read data so Vivado can infer block RAM.
  always @(posedge clk) begin
    dout_r <= ROM[addr];
  end

  assign dout = dout_r;

endmodule
