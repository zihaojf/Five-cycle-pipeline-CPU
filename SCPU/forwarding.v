module forwarding(
    ex_mem_RFWr,
    ex_mem_rd,
    id_ex_rs1,
    id_ex_rs2,

    mem_wb_RFWr,
    mem_wb_rd,
    ex_ForwardA,
    ex_ForwardB
);

input               ex_mem_RFWr;
input   [4:0]       ex_mem_rd;
input   [4:0]       id_ex_rs1;
input   [4:0]       id_ex_rs2;

input               mem_wb_RFWr;
input   [4:0]       mem_wb_rd;
output  reg [1:0]   ex_ForwardA;
output  reg [1:0]   ex_ForwardB;

always @(*)begin
    ex_ForwardA = 2'b00;
    ex_ForwardB = 2'b00;

    // EX/MEM 前递 
    if (ex_mem_RFWr && ex_mem_rd != 0 && (ex_mem_rd == id_ex_rs1) )
        ex_ForwardA = 2'b01;
    if (ex_mem_RFWr && ex_mem_rd != 0 && (ex_mem_rd == id_ex_rs2) )
        ex_ForwardB = 2'b01;
    
    // MEM/WB 前递
    if (mem_wb_RFWr && mem_wb_rd != 0 && 
    !(ex_mem_RFWr && ex_mem_rd != 0 && (ex_mem_rd == id_ex_rs1))
    && (mem_wb_rd == id_ex_rs1 ) )
        ex_ForwardA = 2'b10;
    
    if (mem_wb_RFWr && mem_wb_rd != 0 && 
    !(ex_mem_RFWr && ex_mem_rd != 0 && (ex_mem_rd == id_ex_rs2))
    && (mem_wb_rd == id_ex_rs2 ) )
        ex_ForwardB = 2'b10;

end



endmodule