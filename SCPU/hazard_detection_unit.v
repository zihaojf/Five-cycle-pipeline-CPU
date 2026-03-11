module hazard_detection_unit (
    id_ex_MemRead,
    id_ex_rd,
    id_rs1,
    id_rs2,
    pc_write,
    if_id_stall,
    id_ex_flush
);

input           id_ex_MemRead;
input   [4:0]   id_ex_rd;
input   [4:0]   id_rs1;
input   [4:0]   id_rs2;
output  reg     pc_write;
output  reg     if_id_stall;
output  reg     id_ex_flush;

always @(*)begin
    pc_write <= 1'b1;
    if_id_stall <= 1'b0;
    id_ex_flush <= 1'b0;

    if( id_ex_MemRead && 
    ( (id_ex_rd == id_rs1 ) || (id_ex_rd == id_rs2 )) ) begin
        pc_write    <= 1'b0;
        if_id_stall <= 1'b1;
        id_ex_flush <= 1'b1;
    end

end


endmodule