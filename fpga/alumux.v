module alumux(
    input [31:0] A,
    input [31:0] B,
    input ALUSrc,
    output [31:0] MuxResult
);

assign MuxResult = ALUSrc ? B : A;
endmodule