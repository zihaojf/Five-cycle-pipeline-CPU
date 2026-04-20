module clkgen(
    input clkin,
    input rst,
    input clken,
    output reg clkout
);
    parameter integer clk_freq   = 1000;
    parameter integer clkin_freq = 50000000;
    localparam integer countlimit_raw = (clk_freq > 0) ? (clkin_freq / (2 * clk_freq)) : 1;
    localparam integer countlimit     = (countlimit_raw < 1) ? 1 : countlimit_raw;

    reg [31:0] clkcount;
    initial begin
        clkcount = 32'd0;
        clkout   = 1'b0;
    end

    always @(posedge clkin) begin
        if (rst) begin
            clkcount <= 32'd0;
            clkout   <= 1'b0;
        end else if (clken) begin
            if (clkcount + 1 >= countlimit) begin
                clkcount <= 32'd0;
                clkout   <= ~clkout;
            end else begin
                clkcount <= clkcount + 1'b1;
            end
        end
    end
endmodule
