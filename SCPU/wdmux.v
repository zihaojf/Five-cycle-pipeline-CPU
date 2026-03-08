`include "ctrl_encode_def.v"
module wdmux(
    input [1:0] WDSel,
    input [31:0]    AluResult,
    input [31:0]    MemData,
    input [31:0]    PC,
    output reg [31:0]   WD
);

always @(*) begin
    case (WDSel)
        `WDSel_FromALU: WD <= AluResult;
        `WDSel_FromMEM: WD <= MemData;
        `WDSel_FromPC:  WD <= PC + 3'h4;
        default:        WD <= 32'h0;
    endcase
end

endmodule