module pic(
    input [18:0]    addr,
    output [11:0] data
);

reg [11:0] mem[327679:0];

initial begin
    $readmemh("my_picture.hex",mem);
end


assign  data = mem[addr];


endmodule