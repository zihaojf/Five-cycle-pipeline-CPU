module PC( clk, rst, NPC, en,PC );

  input              clk;
  input              rst;
  input       [31:0] NPC;
  input              en;
  output reg  [31:0] PC;

  always @(posedge clk, posedge rst)
    if (rst) 
      PC <= 32'h0000_0000;
//      PC <= 32'h0000_3000;
    else if(en)
      PC <= NPC;
      
endmodule

