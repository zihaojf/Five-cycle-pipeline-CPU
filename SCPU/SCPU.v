`include "definition.vh"

module SCPU #(
	parameter WIDTH = `PR_DATA_WIDTH
)(
	input 			clk,
	input			rst,
	input [31:0]	inst_in,
	input [31:0]	Data_in,
	output			mem_w,
	output [31:0]	PC_out,
	output [31:0]	Addr_out,
	output [31:0]	Data_out,
	input [4:0] 	reg_sel,
	output [31:0] 	reg_data
);

reg		pipe1_valid;
reg		pipe2_valid;
reg		pipe3_valid;
reg     pipe4_valid;


// ------cpu相关变量------

//	IF阶段
reg [31:0]		if_pc;
assign PC_out = if_pc;
wire [31:0]		npc;   

//	------ID阶段------

//	decode
wire [6:0] id_Op;
wire [6:0] id_Funct7;
wire [2:0] id_Funct3;
wire [4:0] id_rs1;
wire [4:0] id_rs2;
wire [4:0] id_rd;
wire [4:0] id_iimm_shamt;
wire [11:0] id_iimm;
wire [11:0] id_simm;
wire [11:0] id_bimm;
wire [19:0] id_uimm;
wire [19:0] id_jimm;

//	ctrl
wire		id_RFWr;
wire		id_MemWrite;
wire [5:0]	id_EXTOp;
wire [4:0]	id_ALUOp;
wire		id_ALUSrc;
wire [2:0]	id_DMType;
wire [1:0]	id_WDSel;
wire [2:0]	id_NPCOp;

// RF
wire [31:0] id_RD1;
wire [31:0] id_RD2;

// EXT
wire [31:0] id_immout;



//	------- EX阶段 -------
wire [31:0] ex_AluResult;
wire 		ex_Zero;
wire [31:0] ex_B;

//	------- MEM阶段 ------
wire		mem_branch;
wire [31:0]	mem_npc;

//	------- WB阶段 -------
wire [31:0]	wb_WD;




//	------- 流水线传递变量 ------

// IF/ID阶段变量
reg [31:0] 		if_id_pc;
reg [31:0]		if_id_instr;


// ID/EX阶段变量
reg [31:0]		id_ex_RD1;
reg [31:0]		id_ex_RD2;
reg [31:0]		id_ex_immout;
reg [31:0]		id_ex_PC;

reg				id_ex_ALUSrc;
reg	[4:0]		id_ex_ALUOp;
reg 			id_ex_RFWr;
reg				id_ex_MemWrite;

reg [1:0]		id_ex_WDSel;
reg [2:0]		id_ex_DMType;
reg [4:0]		id_ex_rd;
reg [2:0]		id_ex_NPCOp;



// EX/MEM阶段变量
reg [31:0]		ex_mem_PC;
reg [31:0]		ex_mem_AluResult;
reg 			ex_mem_MemWrite;
reg [31:0]		ex_mem_WriteData;

reg 			ex_mem_RFWr;
reg [1:0]		ex_mem_WDSel;
reg [2:0]		ex_mem_DMType;
reg [4:0]		ex_mem_rd;

reg	[2:0]		ex_mem_NPCOp;
reg [31:0]		ex_mem_immout;
reg				ex_mem_Zero;

// MEM/WB阶段变量
reg [31:0]		mem_wb_PC;
reg [4:0]		mem_wb_rd;
reg				mem_wb_RFWr;
reg	[1:0]		mem_wb_WDSel;

reg [31:0]		mem_wb_AluResult;
reg [31:0]		mem_wb_MemData;
reg [2:0]		mem_wb_DMType;






// ------IF阶段------ 
// 调用PC模块
PC U_PC(
	.clk(clk),
	.rst(rst),
	.NPC(npc),
	.PC(if_pc)
);



// ------IF/ID阶段(pipe 1)------
wire 	pipe1_allowin;
wire	pipe1_ready_go;
wire	pipe1_to_pipe2_valid;

wire    validin;
assign validin = 1'b1;//先默认都有效

assign pipe1_ready_go = 1'b1; //此处恒设定为1，在具体实现中可根据条件修改
assign pipe1_allowin = !pipe1_valid || pipe1_ready_go && pipe2_allowin; // 优先级 ! > && > ||
assign pipe1_to_pipe2_valid = pipe1_valid && pipe1_ready_go;

always @(posedge clk ) begin
	if (rst) begin
		pipe1_valid <= 1'b0;

		// 数据重置
		if_id_pc <= 32'd0;
		if_id_instr <= 32'd0;

	end
	else if (pipe1_allowin) begin
		pipe1_valid <= validin;

		if (validin && pipe1_allowin) begin
		// 传递pc和instr
		if_id_pc <= if_pc;
		if_id_instr <= inst_in;
		end
	end

	
end


// ------ID阶段------
// 调用decode,ctrl,RF,EXT四个模块

// 1.decode
decode U_DECODE(
	.inst_in(if_id_instr),
	.Op(id_Op),
	.Funct7(id_Funct7),
	.Funct3(id_Funct3),
	.rs1(id_rs1),
	.rs2(id_rs2),
	.rd(id_rd),
	.iimm_shamt(id_iimm_shamt),
	.iimm(id_iimm),
	.simm(id_simm),
	.bimm(id_bimm),
	.uimm(id_uimm),
	.jimm(id_jimm)
);

// 2.ctrl
ctrl U_CTRL(
	.Op(id_Op),
	.Funct7(id_Funct7),
	.Funct3(id_Funct3),
	.RegWrite(id_RFWr),
	.MemWrite(id_MemWrite),
	.EXTOp(id_EXTOp),
	.ALUOp(id_ALUOp),
	.NPCOp(id_NPCOp),
	.ALUSrc(id_ALUSrc),
	.DMType(id_DMType),
	.WDSel(id_WDSel)
);

// 3.RF
RF U_RF(
	.clk(clk),
	.rst(rst),
	.RFWr(mem_wb_RFWr && pipe4_valid),
	.A1(id_rs1),
	.A2(id_rs2),
	.A3(mem_wb_rd),
	.WD(wb_WD),
	.RD1(id_RD1),
	.RD2(id_RD2)
);
// 输出对应寄存器的值
assign reg_data = U_RF.rf[reg_sel];

// 4.EXT
EXT U_EXT(
	.iimm_shamt(id_iimm_shamt),
	.iimm(id_iimm),
	.simm(id_simm),
	.bimm(id_bimm),
	.uimm(id_uimm),
	.jimm(id_jimm),
	.EXTOp(id_EXTOp),
	.immout(id_immout)
);



// ------- ID/EX阶段(pipe 2) -------
// 数据： RD1,RD2,immout,pc
// 控制信号： 
wire 	pipe2_allowin;
wire	pipe2_ready_go;
wire	pipe2_to_pipe3_valid;

assign pipe2_ready_go = 1'b1; //此处恒设定为1，在具体实现中可根据条件修改
assign pipe2_allowin = !pipe2_valid || pipe2_ready_go && pipe3_allowin; // 优先级 ! > && > ||
assign pipe2_to_pipe3_valid = pipe2_valid && pipe2_ready_go;

always @(posedge clk ) begin
	if (rst) begin
		pipe2_valid <= 1'b0;

		// 数据重置
		id_ex_RD1 		<= 32'd0;
		id_ex_RD2 		<= 32'd0;
		id_ex_immout 	<= 32'd0;
		id_ex_PC		<= 32'd0;

		id_ex_ALUSrc	<= 1'b0;
		id_ex_ALUOp		<= `ALUOp_nop;
		id_ex_RFWr		<= 1'b0;
		id_ex_MemWrite	<= 1'b0;

		id_ex_WDSel		<= `WDSel_FromALU;
		id_ex_DMType	<= `dm_word;
		id_ex_rd		<= 5'd0;
		id_ex_NPCOp		<= `NPC_PLUS4;

	end
	else if (pipe2_allowin) begin
		pipe2_valid <= pipe1_to_pipe2_valid;

		if (pipe1_to_pipe2_valid && pipe2_allowin) begin
		id_ex_RD1 		<= id_RD1;
		id_ex_RD2 		<= id_RD2;
		id_ex_immout 	<= id_immout;
		id_ex_PC 		<= if_id_pc;

		id_ex_ALUSrc	<= id_ALUSrc;
		id_ex_ALUOp		<= id_ALUOp;
		id_ex_RFWr		<= id_RFWr;
		id_ex_MemWrite	<= id_MemWrite;

		id_ex_WDSel		<= id_WDSel;
		id_ex_DMType	<= id_DMType;
		id_ex_rd		<= id_rd;
		id_ex_NPCOp		<= id_NPCOp;

		end

	end

	
end

//	------- EX阶段 -------

// 1.ALUSrc
alumux U_ALUMUX(
	.A(id_ex_RD2),
	.B(id_ex_immout),
	.ALUSrc(id_ex_ALUSrc),
	.MuxResult(ex_B)
);

// 2.ALU
alu U_ALU(
	.A(id_ex_RD1),
	.B(ex_B),
	.ALUOp(id_ex_ALUOp),
	.PC(id_ex_PC),
	.C(ex_AluResult),
	.Zero(ex_Zero)
);



// ------ EX/MEM阶段(pipe 3) -------
wire 	pipe3_allowin;
wire	pipe3_ready_go;
wire	pipe3_to_pipe4_valid;

assign pipe3_ready_go = 1'b1; //此处恒设定为1，在具体实现中可根据条件修改
assign pipe3_allowin = !pipe3_valid || pipe3_ready_go && pipe4_allowin; // 优先级 ! > && > ||
assign pipe3_to_pipe4_valid = pipe3_valid && pipe3_ready_go;

always @(posedge clk ) begin
	if (rst) begin
		pipe3_valid <= 1'b0;

		//	数据重置
		ex_mem_PC			<= 32'd0;
		ex_mem_AluResult	<= 32'd0; 
		ex_mem_MemWrite		<= 1'b0;
		ex_mem_WriteData	<= 32'd0;

		ex_mem_RFWr			<= 1'b0;
		ex_mem_WDSel		<= `WDSel_FromALU;
		ex_mem_DMType		<= `dm_word;
		ex_mem_rd			<= 5'd0;
		
		ex_mem_NPCOp		<= `NPC_PLUS4;
		ex_mem_immout		<= 32'd0;
		ex_mem_Zero			<= 1'b0;

	end
	else if (pipe3_allowin) begin
		pipe3_valid <= pipe2_to_pipe3_valid;

		if (pipe2_to_pipe3_valid && pipe3_allowin) begin
		ex_mem_PC			<= id_ex_PC;
		ex_mem_AluResult 	<= ex_AluResult;
		ex_mem_MemWrite		<= id_ex_MemWrite;
		ex_mem_WriteData	<= id_ex_RD2;
		
		ex_mem_RFWr			<= id_ex_RFWr;
		ex_mem_WDSel		<= id_ex_WDSel;
		ex_mem_DMType		<= id_ex_DMType;
		ex_mem_rd			<= id_ex_rd;

		ex_mem_NPCOp		<= id_ex_NPCOp;
		ex_mem_immout		<= id_ex_immout;
		ex_mem_Zero			<= ex_Zero;

		end
	end

	
end


// -------- MEM阶段 -------

// 1.npc 
NPC U_NPC(
	.PC(ex_mem_PC),
	.NPCOp(ex_mem_NPCOp),
	.IMM(ex_mem_immout),
	.aluout(ex_mem_AluResult),
	.Zero(ex_mem_Zero),
	.NPC(mem_npc),
	.if_PC(if_pc)
);

assign npc = pipe3_valid ? mem_npc : (if_pc + 32'd4);


// 2.DM
assign mem_w = ex_mem_MemWrite && pipe3_valid;
assign Addr_out = ex_mem_AluResult;
assign Data_out = ex_mem_WriteData;

// 注意这个DM还没有实现单个字节读取，要用DMType！！！




// ------ MEM/WB阶段(pipe 4) -------
wire 	pipe4_allowin;
wire	pipe4_ready_go;

assign pipe4_ready_go = 1'b1; //此处恒设定为1，在具体实现中可根据条件修改
assign pipe4_allowin = !pipe4_valid || pipe4_ready_go ; // 优先级 ! > && > ||

always @(posedge clk ) begin
	if (rst) begin
		pipe4_valid <= 1'b0;

		//	数据重置
		mem_wb_PC			<= 32'd0;
		mem_wb_rd			<= 5'd0;
		mem_wb_RFWr			<= 1'b0;
		mem_wb_WDSel		<= `WDSel_FromALU;

		mem_wb_AluResult	<= 32'd0;
		mem_wb_MemData		<= 32'd0;
		mem_wb_DMType		<= `dm_word;

	end
	else if (pipe4_allowin) begin
		pipe4_valid <= pipe3_to_pipe4_valid;

		if (pipe3_to_pipe4_valid && pipe4_allowin) begin
		mem_wb_PC			<= ex_mem_PC;
		mem_wb_rd			<= ex_mem_rd;
		mem_wb_RFWr			<= ex_mem_RFWr;
		mem_wb_WDSel		<= ex_mem_WDSel;

		mem_wb_AluResult	<= ex_mem_AluResult;
		mem_wb_MemData		<= Data_in;
		mem_wb_DMType		<= ex_mem_DMType;
		end
	end

	
end

//	------ WB阶段 ------

// WriteData mux
wdmux U_WDMUX(
	.WDSel(mem_wb_WDSel),
	.AluResult(mem_wb_AluResult),
	.MemData(mem_wb_MemData),
	.PC(mem_wb_PC),
	.WD(wb_WD)
);



// assign validout = pipe4_valid && pipe4_ready_go;

endmodule