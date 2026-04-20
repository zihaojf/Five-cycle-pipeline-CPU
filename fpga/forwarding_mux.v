module forwardingmux (
    A,B,C,muxres,sel
);

input   [31:0]  A;
input   [31:0]  B;
input   [31:0]  C;
input   [1:0]   sel;
output reg [31:0]  muxres;

always @(*)begin
    case (sel)
        2'b00:  muxres = A;
        2'b01:  muxres = B;
        2'b10:  muxres = C; 
        default: muxres = 32'd0;
    endcase
end


endmodule