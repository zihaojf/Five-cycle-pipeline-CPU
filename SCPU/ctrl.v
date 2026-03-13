// `include "ctrl_encode_def.v"

module ctrl(Op, Funct7, Funct3, 
            RegWrite, MemWrite,
            EXTOp, ALUOp, NPCOp, 
            ALUSrc, WDSel,DMType,MemRead
            );
            
   input  [6:0] Op;       // opcode
   input  [6:0] Funct7;    // funct7
   input  [2:0] Funct3;    // funct3
   //input        Zero;
   
   output       RegWrite; // control signal for register write
   output       MemWrite; // control signal for memory write
   output [5:0] EXTOp;    // control signal to signed extension
   output [4:0] ALUOp;    // ALU opertion
   output [2:0] NPCOp;    // next pc operation
   output       ALUSrc;   // ALU source for B
	 output [2:0] DMType;
   output [1:0] WDSel;    // (register) write data selection
   output       MemRead;
   
  // r format
    wire rtype  = ~Op[6]&Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0110011
    wire i_add  = rtype& ~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // add 0000000 000
    wire i_sub  = rtype& ~Funct7[6]& Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]&~Funct3[2]&~Funct3[1]&~Funct3[0]; // sub 0100000 000
    wire i_or   = rtype& ~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]& Funct3[2]& Funct3[1]&~Funct3[0]; // or 0000000 110
    wire i_and  = rtype& ~Funct7[6]&~Funct7[5]&~Funct7[4]&~Funct7[3]&~Funct7[2]&~Funct7[1]&~Funct7[0]& Funct3[2]& Funct3[1]& Funct3[0]; // and 0000000 111
 

 // i format
   wire itype_l  = ~Op[6]&~Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0000011
   wire i_lb  = itype_l & ~Funct3[2] & ~Funct3[1] & ~Funct3[0];  // lb 000
   wire i_lh  = itype_l & ~Funct3[2] & ~Funct3[1] & Funct3[0];   // lh 001
   wire i_lw  = itype_l & ~Funct3[2] & Funct3[1] & ~Funct3[0];   // lw 010
   wire i_lbu = itype_l & Funct3[2] & ~Funct3[1] & ~Funct3[0];  // lbu 100
   wire i_lhu = itype_l & Funct3[2] & ~Funct3[1] & Funct3[0];   // lhu 101

// i format
    wire itype_r  = ~Op[6]&~Op[5]&Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0]; //0010011
    wire i_addi  =  itype_r& ~Funct3[2]& ~Funct3[1]& ~Funct3[0]; // addi 000
    wire i_ori  =  itype_r& Funct3[2]& Funct3[1]&~Funct3[0]; // ori 110
	
 //jalr
	wire i_jalr =Op[6]&Op[5]&~Op[4]&~Op[3]&Op[2]&Op[1]&Op[0];//jalr 1100111

  // s format
   wire stype  = ~Op[6]&Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];//0100011
   wire i_sw   =  stype& ~Funct3[2]& Funct3[1]&~Funct3[0]; // sw 010
   wire i_sb   =  stype & ~Funct3[2] & ~Funct3[1] & ~Funct3[0]; // sb 000
   wire i_sh   =  stype & ~Funct3[2] & ~Funct3[1] & Funct3[0];  // sh 001
   


  // sb format
   wire sbtype  = Op[6]&Op[5]&~Op[4]&~Op[3]&~Op[2]&Op[1]&Op[0];//1100011
   wire i_beq  = sbtype& ~Funct3[2]& ~Funct3[1]&~Funct3[0]; // beq 000
   wire i_bne  = sbtype & ~Funct3[2] & ~Funct3[1] & Funct3[0]; // bne 001
   wire i_blt  = sbtype & Funct3[2] & ~Funct3[1] & ~Funct3[0]; // blt 100
   wire i_bge  = sbtype & Funct3[2] & ~Funct3[1] &  Funct3[0]; // bge 101
   wire i_bltu = sbtype & Funct3[2] & Funct3[1] & ~Funct3[0];  // bltu 110
   wire i_bgeu = sbtype & Funct3[2] & Funct3[1] & Funct3[0];   // bgeu 111      
	
 // j format
   wire i_jal  = Op[6]& Op[5]&~Op[4]& Op[3]& Op[2]& Op[1]& Op[0];  // jal 1101111

  // lui 0110111
  wire lui = ~Op[6] & Op[5] & Op[4] & ~Op[3] & Op[2] & Op[1] & Op[0];

  // auipc 0010111
  wire auipc = ~Op[6] & ~Op[5] & Op[4] & ~Op[3] & Op[2] & Op[1] & Op[0];













  // 产生控制信号
  assign RegWrite   = rtype | itype_r | i_jalr | i_jal | itype_l | lui | auipc; // register write
  assign MemWrite   = stype;                           // memory write
  assign ALUSrc     = itype_r | stype | i_jal | i_jalr | lui | auipc | itype_l;   // ALU B is from instruction immediate
  assign MemRead    = itype_l; // load型指令读取dm

  // signed extension
  // EXT_CTRL_ITYPE_SHAMT 6'b100000
  // EXT_CTRL_ITYPE	      6'b010000
  // EXT_CTRL_STYPE	      6'b001000
  // EXT_CTRL_BTYPE	      6'b000100
  // EXT_CTRL_UTYPE	      6'b000010
  // EXT_CTRL_JTYPE	      6'b000001
  assign EXTOp[5] = 0;
  assign EXTOp[4]    =  i_ori | i_addi | i_jalr | itype_l;  
  assign EXTOp[3]    = stype; 
  assign EXTOp[2]    = sbtype; 
  assign EXTOp[1]    = lui | auipc;   
  assign EXTOp[0]    = i_jal;         


  
  
  // WDSel_FromALU 2'b00
  // WDSel_FromMEM 2'b01
  // WDSel_FromPC  2'b10 
  assign WDSel[0] = itype_l;
  assign WDSel[1] = i_jal | i_jalr;

  // NPC_PLUS4   3'b000
  // NPC_BRANCH  3'b001
  // NPC_JUMP    3'b010
  // NPC_JALR	3'b100

  // assign NPCOp[0] = sbtype & Zero;
  assign NPCOp[0] = sbtype;
  assign NPCOp[1] = i_jal;
	assign NPCOp[2] = i_jalr;

// dm_word 3'b000
// dm_halfword 3'b001
// dm_halfword_unsigned 3'b010
// dm_byte 3'b011
// dm_byte_unsigned 3'b100
  assign DMType[0] = i_sb | i_sh | i_lb |i_lh;
  assign DMType[1] = i_sb | i_lb | i_lhu;
  assign DMType[2] = i_lbu;

// `define ALUOp_nop 5'b00000
// `define ALUOp_lui 5'b00001
// `define ALUOp_auipc 5'b00010
// `define ALUOp_add 5'b00011
// `define ALUOp_sub 5'b00100
// `define ALUOp_bne 5'b00101
// `define ALUOp_blt 5'b00110
// `define ALUOp_bge 5'b00111
// `define ALUOp_bltu 5'b01000
// `define ALUOp_bgeu 5'b01001
// `define ALUOp_slt 5'b01010
// `define ALUOp_sltu 5'b01011
// `define ALUOp_xor 5'b01100
// `define ALUOp_or 5'b01101
// `define ALUOp_and 5'b01110
// `define ALUOp_sll 5'b01111
// `define ALUOp_srl 5'b10000
// `define ALUOp_sra 5'b10001
 
	assign ALUOp[0] = itype_l|stype|i_addi|i_ori|i_add|i_or | lui | i_jalr | i_bne|i_bge;
	assign ALUOp[1] = i_jalr| i_jal |itype_l|stype|i_addi|i_add|i_and | auipc | i_blt|i_bge;
	assign ALUOp[2] = i_and|i_ori|i_or|i_beq|i_sub |i_bne|i_blt|i_bge;
  assign ALUOp[3] = i_and|i_ori|i_or|i_bltu;    
	assign ALUOp[4] = 0;

endmodule
