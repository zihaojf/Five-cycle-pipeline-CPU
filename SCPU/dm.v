
// data memory
// `define dm_word 3'b000
// `define dm_halfword 3'b001
// `define dm_halfword_unsigned 3'b010
// `define dm_byte 3'b011
// `define dm_byte_unsigned 3'b100

module dm(clk, DMWr, addr, din, dout, DMType);
   input          clk;
   input          DMWr;
   input  [8:0]   addr;
   input  [31:0]  din;
   input  [2:0]   DMType;
   output reg [31:0]  dout;
     
   reg [7:0] dmem[511:0];
   
   integer i;

   initial begin
      for (i = 0; i < 512; i = i + 1)
         dmem[i] = 8'b0;
   end


   always @(posedge clk)
      if (DMWr) begin
         case(DMType)
            `dm_word: begin
                dmem[addr] <= din[7:0];
                dmem[addr+1] <= din[15:8];
                dmem[addr+2] <= din[23:16];
                dmem[addr+3] <= din[31:24];
             end
            `dm_halfword: begin
                dmem[addr] <= din[7:0];
                dmem[addr+1] <= din[15:8];
             end
            `dm_byte: dmem[addr] <= din[7:0];
        endcase
        $display("dmem[0x%8X] = 0x%8X,", addr, din);
      end
   
   always @(*)begin
    case(DMType)
         `dm_byte: dout = {{24{dmem[addr][7]}}, dmem[addr][7:0]};
         `dm_halfword: dout = {{16{dmem[addr+1][7]}},dmem[addr+1][7:0],dmem[addr][7:0]};
         `dm_word: dout = {dmem[addr+3][7:0],dmem[addr+2][7:0],dmem[addr+1][7:0],dmem[addr][7:0]};
         `dm_halfword_unsigned: dout = {16'b0, dmem[addr+1][7:0], dmem[addr][7:0]};
         `dm_byte_unsigned: dout = {24'b0, dmem[addr][7:0]};
         default: dout = {{24{dmem[addr][7]}}, dmem[addr][7:0]};
    endcase
   end
    
endmodule    
