module debug_serial (
  input        clk,
  input        we,
  input  [7:0] data
);
  always @(posedge clk) begin
    if (we) begin
      $write("%c", data);
    end
  end
endmodule