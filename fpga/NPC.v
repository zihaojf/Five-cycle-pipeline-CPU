`include "ctrl_encode_def.v"

module NPC(PC, NPCOp, IMM, NPC, aluout, Zero, if_PC, branch);  // next pc module
    
   input  [31:0] PC;        // pc from pipeline
   input  [31:0] if_PC;
   input  [2:0]  NPCOp;     // next pc operation
   input  [31:0] IMM;       // immediate
	input [31:0] aluout;
   input         Zero;
   output reg [31:0] NPC;   // next pc
   output reg     branch;
   
   wire [31:0] PCPLUS4;
   
   assign PCPLUS4 = if_PC + 32'd4; // pc + 4

   always @(*) begin
      branch = 1'b0;
      case (NPCOp)
          `NPC_PLUS4:  begin 
            NPC = PCPLUS4;
          end
          `NPC_BRANCH: begin
            NPC = Zero ? PC+IMM : PCPLUS4;
            branch = Zero;
          end

          `NPC_JUMP:   begin
            NPC = PC+IMM;
            branch = 1'b1;
          end
		    `NPC_JALR:	  begin
            NPC = aluout;
            branch = 1'b1;
          end
          default:     NPC = PCPLUS4;
      endcase
   end // end always
   
endmodule
