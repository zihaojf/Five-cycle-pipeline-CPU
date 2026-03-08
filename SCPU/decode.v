module decode(
input  [31:0] inst_in,

output [6:0] Op,
output [6:0] Funct7,
output [2:0] Funct3,

output [4:0] rs1,
output [4:0] rs2,
output [4:0] rd,

output [4:0] iimm_shamt,
output [11:0] iimm,
output [11:0] simm,
output [11:0] bimm,
output [19:0] uimm,
output [19:0] jimm
);

// 基本字段
assign Op     = inst_in[6:0];
assign Funct7 = inst_in[31:25];
assign Funct3 = inst_in[14:12];

assign rs1 = inst_in[19:15];
assign rs2 = inst_in[24:20];
assign rd  = inst_in[11:7];

// I type
assign iimm = inst_in[31:20];

// shift amount
assign iimm_shamt = inst_in[24:20];

// S type
assign simm = {inst_in[31:25], inst_in[11:7]};

// B type
assign bimm = {inst_in[31],inst_in[7],inst_in[30:25],inst_in[11:8]};

// U type
assign uimm = inst_in[31:12];

// J type
assign jimm = {inst_in[31],inst_in[19:12],inst_in[20],inst_in[30:21]};

endmodule