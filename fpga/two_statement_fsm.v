module two_statement_fsm(
    input       clk,
    input       rst,
    input [7:0] scan_data,
    input       ready,
    input       overflow,
    output      nextdata_n,
    output reg [7:0]   key_data,
    output [7:0]   count_out,
    output      display_en,
    output reg  key_valid
);

reg [7:0]   count;
reg [1:0]   state;
// 0 -> 等待通码数据
// 1 -> 等待断码数据

reg [7:0]   cur_key;

assign nextdata_n = (state == 2'b00);
assign display_en = ~nextdata_n;
assign count_out = count;


always @(posedge clk)begin
    if(rst) begin
        count   <= 8'd0;
        state   <= 2'b00;
        key_data    <= 8'd0;
    end
    else if (overflow) begin
        state    <= 2'b00;
        key_data <= 8'd0;
        cur_key <= 8'd0;
    end
    else begin
        key_valid <= 1'b0;
        case (state)
            2'b00: begin
                if(ready && scan_data != 8'hF0) begin
                    key_data    <= scan_data;
                    cur_key <= scan_data;
                    key_valid  <= 1'b1;
                    state   <= 2'b01;
                end
            end 
            2'b01: begin
                if(ready && scan_data == 8'hF0) begin
                    state   <= 2'b10;
                end
                else if(ready && scan_data == cur_key) begin
                    state <= 2'b01;
                end

            end 
            2'b10: begin
                if(ready && cur_key == scan_data) begin
                    count <= count + 8'd1;
                    state <= 2'b00;
                end
                else if(ready) state <= 2'b00;
            end
            default: begin
                key_data <= 8'd0;
                state <= 2'b00;
            end
        endcase

    end

end



endmodule