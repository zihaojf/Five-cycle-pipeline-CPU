`timescale 1ns / 1ps

module IP2SOC_Top_tb;

  reg         clk;
  reg         rstn;
  reg  [15:0] sw_i;
  reg         ps2_clk;
  reg         ps2_data;

  wire [7:0]  disp_seg_o;
  wire [7:0]  disp_an_o;
  wire [3:0]  vga_red_o;
  wire [3:0]  vga_green_o;
  wire [3:0]  vga_blue_o;
  wire        vga_hs_o;
  wire        vga_vs_o;

  integer foutput;
  integer counter;

  //========================================================
  // DUT
  //========================================================
  IP2SOC_Top U_TOP (
    .clk        (clk),
    .rstn       (rstn),
    .sw_i       (sw_i),
    .disp_seg_o (disp_seg_o),
    .disp_an_o  (disp_an_o),
    .vga_red_o  (vga_red_o),
    .vga_green_o(vga_green_o),
    .vga_blue_o (vga_blue_o),
    .vga_hs_o   (vga_hs_o),
    .vga_vs_o   (vga_vs_o),
    .ps2_clk    (ps2_clk),
    .ps2_data   (ps2_data)
  );

  //========================================================
  // Initial
  //========================================================
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, IP2SOC_Top_tb);

    // 如果 imem 内部存储器名字不是 ROM，请按你的 imem 定义修改
    $readmemh("Test_8_Instr.dat", U_TOP.U_IM.ROM);

    foutput = $fopen("results.txt", "w");
    counter = 0;

    sw_i     = 16'h0000;
    ps2_clk  = 1'b1;
    ps2_data = 1'b1;
    clk = 0;
    rstn = 0;
    
    #1500;
    rstn = 1;

    // 选择要观察的寄存器，例如 x7
    sw_i[4:0] = 5'd7;
    sw_i[14:10] = 5'd4;

    #1000000;
    $display("TIMEOUT");
    $finish;

  end

  //========================================================
  // Clock
  //========================================================
  always #(50) clk = ~clk;   // 100MHz

  //========================================================
  // Monitor at positive edge
  //========================================================
  always @(posedge clk) begin
    if (rstn) begin
      counter = counter + 1;

      // 停止条件：计数上限 或 PC 到达指定位置
      if ((counter == 100000) || (U_TOP.U_xgriscv.PC_out === 32'h00000049)) begin
        $fclose(foutput);
        $stop;
      end
      else begin
        if (U_TOP.PC <= 32'h00000400) begin
          $fdisplay(foutput, "pc:\t\t %h", U_TOP.PC);
          $fdisplay(foutput, "instr:\t\t %h", U_TOP.instr);

          $fdisplay(foutput, "rf00-03:\t %h %h %h %h",
                    32'h00000000,
                    U_TOP.U_xgriscv.U_RF.rf[1],
                    U_TOP.U_xgriscv.U_RF.rf[2],
                    U_TOP.U_xgriscv.U_RF.rf[3]);

          $fdisplay(foutput, "rf04-07:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[4],
                    U_TOP.U_xgriscv.U_RF.rf[5],
                    U_TOP.U_xgriscv.U_RF.rf[6],
                    U_TOP.U_xgriscv.U_RF.rf[7]);

          $fdisplay(foutput, "rf08-11:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[8],
                    U_TOP.U_xgriscv.U_RF.rf[9],
                    U_TOP.U_xgriscv.U_RF.rf[10],
                    U_TOP.U_xgriscv.U_RF.rf[11]);

          $fdisplay(foutput, "rf12-15:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[12],
                    U_TOP.U_xgriscv.U_RF.rf[13],
                    U_TOP.U_xgriscv.U_RF.rf[14],
                    U_TOP.U_xgriscv.U_RF.rf[15]);

          $fdisplay(foutput, "rf16-19:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[16],
                    U_TOP.U_xgriscv.U_RF.rf[17],
                    U_TOP.U_xgriscv.U_RF.rf[18],
                    U_TOP.U_xgriscv.U_RF.rf[19]);

          $fdisplay(foutput, "rf20-23:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[20],
                    U_TOP.U_xgriscv.U_RF.rf[21],
                    U_TOP.U_xgriscv.U_RF.rf[22],
                    U_TOP.U_xgriscv.U_RF.rf[23]);

          $fdisplay(foutput, "rf24-27:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[24],
                    U_TOP.U_xgriscv.U_RF.rf[25],
                    U_TOP.U_xgriscv.U_RF.rf[26],
                    U_TOP.U_xgriscv.U_RF.rf[27]);

          $fdisplay(foutput, "rf28-31:\t %h %h %h %h",
                    U_TOP.U_xgriscv.U_RF.rf[28],
                    U_TOP.U_xgriscv.U_RF.rf[29],
                    U_TOP.U_xgriscv.U_RF.rf[30],
                    U_TOP.U_xgriscv.U_RF.rf[31]);

          $fdisplay(foutput, "dmem:");
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 0,
                    U_TOP.U_dmem.dmem[0],  U_TOP.U_dmem.dmem[1],
                    U_TOP.U_dmem.dmem[2],  U_TOP.U_dmem.dmem[3]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 4,
                    U_TOP.U_dmem.dmem[4],  U_TOP.U_dmem.dmem[5],
                    U_TOP.U_dmem.dmem[6],  U_TOP.U_dmem.dmem[7]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 8,
                    U_TOP.U_dmem.dmem[8],  U_TOP.U_dmem.dmem[9],
                    U_TOP.U_dmem.dmem[10], U_TOP.U_dmem.dmem[11]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 12,
                    U_TOP.U_dmem.dmem[12], U_TOP.U_dmem.dmem[13],
                    U_TOP.U_dmem.dmem[14], U_TOP.U_dmem.dmem[15]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 16,
                    U_TOP.U_dmem.dmem[16], U_TOP.U_dmem.dmem[17],
                    U_TOP.U_dmem.dmem[18], U_TOP.U_dmem.dmem[19]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 20,
                    U_TOP.U_dmem.dmem[20], U_TOP.U_dmem.dmem[21],
                    U_TOP.U_dmem.dmem[22], U_TOP.U_dmem.dmem[23]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 24,
                    U_TOP.U_dmem.dmem[24], U_TOP.U_dmem.dmem[25],
                    U_TOP.U_dmem.dmem[26], U_TOP.U_dmem.dmem[27]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 28,
                    U_TOP.U_dmem.dmem[28], U_TOP.U_dmem.dmem[29],
                    U_TOP.U_dmem.dmem[30], U_TOP.U_dmem.dmem[31]);

          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 32,
                    U_TOP.U_dmem.dmem[32], U_TOP.U_dmem.dmem[33],
                    U_TOP.U_dmem.dmem[34], U_TOP.U_dmem.dmem[35]);

          $fdisplay(foutput, "----------------------------------------");
        end
        else begin
          $display("pc: %h",         U_TOP.PC);
          $display("instr: %h",      U_TOP.instr);
          $display("if_id_pc: %h",   U_TOP.U_xgriscv.if_id_pc);
          $display("if_id_instr: %h",U_TOP.U_xgriscv.if_id_instr);
          $display("next_pc: %h",    U_TOP.U_xgriscv.ex_npc);

          $fclose(foutput);
          $finish;
        end
      end
    end
  end

endmodule