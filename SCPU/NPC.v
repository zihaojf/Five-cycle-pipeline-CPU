`include "ctrl_encode_def.v"

module NPC(PC, NPCOp, IMM, NPC, aluout, Zero, if_PC, branch);  // next pc module
    
   input  [31:0] PC;        // pc from pipeline
   input  [31:0] if_PC;
   input  [2:0]  NPCOp;     // next pc operation
   input  [31:0] IMM;       // immediate
	input [31:0] aluout;
   input         Zero;
   output reg [31:0] NPC;   // next pc
   output         branch;
   
   wire [31:0] PCPLUS4;
   
   assign PCPLUS4 = if_PC + 32'd4; // pc + 4
   assign branch = (NPC != PCPLUS4);

   always @(*) begin
      case (NPCOp)
          `NPC_PLUS4:  NPC = PCPLUS4;
          `NPC_BRANCH: NPC = Zero ? PC+IMM : PCPLUS4;
          `NPC_JUMP:   NPC = PC+IMM;
		    `NPC_JALR:	  NPC = aluout;
          default:     NPC = PCPLUS4;
      endcase
   end // end always
   
endmodule
