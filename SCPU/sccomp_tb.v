
// testbench for simulation
module sccomp_tb();
    
   reg  clk, rstn;
   reg  [4:0] reg_sel;
   wire [31:0] reg_data;
    
// instantiation of sccomp    
   sccomp U_SCCOMP(
      .clk(clk), .rstn(rstn), .reg_sel(reg_sel), .reg_data(reg_data) 
   );

  	integer foutput;
  	integer counter = 0;
   
   initial begin
      $dumpfile("wave.vcd");
      $dumpvars(0, sccomp_tb);
      $readmemh( "Test_8_Instr.dat" , U_SCCOMP.U_IM.ROM); // load instructions into instruction memory
    //$monitor("PC = 0x%8X, instr = 0x%8X", U_SCCOMP.PC, U_SCCOMP.instr); // used for debug
      foutput = $fopen("results.txt");
      clk = 0;
      rstn = 1;
      #5 ;
      rstn = 0;
      #2 ;
      clk = 1;
      #20 ;
      rstn = 1;
      #5 ;
      clk = 0;
      #1000 ;
      reg_sel = 7;
   end
   
    always begin
    #(50) clk = ~clk;
    if (clk == 1'b1) begin
      if ((counter == 1000) || (U_SCCOMP.U_SCPU.PC_out=== 32'h00000049)) begin
        $fclose(foutput);
        $stop;
      end
      else begin
        if (U_SCCOMP.PC <= 32'h00000300) begin
          counter = counter + 1;
          $fdisplay(foutput, "pc:\t %h", U_SCCOMP.PC);
          $fdisplay(foutput, "instr:\t\t %h", U_SCCOMP.instr);
          $fdisplay(foutput, "rf00-03:\t %h %h %h %h", 0, U_SCCOMP.U_SCPU.U_RF.rf[1], U_SCCOMP.U_SCPU.U_RF.rf[2], U_SCCOMP.U_SCPU.U_RF.rf[3]);
          $fdisplay(foutput, "rf04-07:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[4], U_SCCOMP.U_SCPU.U_RF.rf[5], U_SCCOMP.U_SCPU.U_RF.rf[6], U_SCCOMP.U_SCPU.U_RF.rf[7]);
          $fdisplay(foutput, "rf08-11:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[8], U_SCCOMP.U_SCPU.U_RF.rf[9], U_SCCOMP.U_SCPU.U_RF.rf[10], U_SCCOMP.U_SCPU.U_RF.rf[11]);
          $fdisplay(foutput, "rf12-15:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[12], U_SCCOMP.U_SCPU.U_RF.rf[13], U_SCCOMP.U_SCPU.U_RF.rf[14], U_SCCOMP.U_SCPU.U_RF.rf[15]);
          $fdisplay(foutput, "rf16-19:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[16], U_SCCOMP.U_SCPU.U_RF.rf[17], U_SCCOMP.U_SCPU.U_RF.rf[18], U_SCCOMP.U_SCPU.U_RF.rf[19]);
          $fdisplay(foutput, "rf20-23:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[20], U_SCCOMP.U_SCPU.U_RF.rf[21], U_SCCOMP.U_SCPU.U_RF.rf[22], U_SCCOMP.U_SCPU.U_RF.rf[23]);
          $fdisplay(foutput, "rf24-27:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[24], U_SCCOMP.U_SCPU.U_RF.rf[25], U_SCCOMP.U_SCPU.U_RF.rf[26], U_SCCOMP.U_SCPU.U_RF.rf[27]);
          $fdisplay(foutput, "rf28-31:\t %h %h %h %h", U_SCCOMP.U_SCPU.U_RF.rf[28], U_SCCOMP.U_SCPU.U_RF.rf[29], U_SCCOMP.U_SCPU.U_RF.rf[30], U_SCCOMP.U_SCPU.U_RF.rf[31]);

          // display DM content (byte addressing)
          $fdisplay(foutput, "dmem:");
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 0,  U_SCCOMP.U_DM.dmem[0],  U_SCCOMP.U_DM.dmem[1],  U_SCCOMP.U_DM.dmem[2],  U_SCCOMP.U_DM.dmem[3]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 4,  U_SCCOMP.U_DM.dmem[4],  U_SCCOMP.U_DM.dmem[5],  U_SCCOMP.U_DM.dmem[6],  U_SCCOMP.U_DM.dmem[7]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 8,  U_SCCOMP.U_DM.dmem[8],  U_SCCOMP.U_DM.dmem[9],  U_SCCOMP.U_DM.dmem[10], U_SCCOMP.U_DM.dmem[11]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 12, U_SCCOMP.U_DM.dmem[12], U_SCCOMP.U_DM.dmem[13], U_SCCOMP.U_DM.dmem[14], U_SCCOMP.U_DM.dmem[15]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 16, U_SCCOMP.U_DM.dmem[16], U_SCCOMP.U_DM.dmem[17], U_SCCOMP.U_DM.dmem[18], U_SCCOMP.U_DM.dmem[19]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 20, U_SCCOMP.U_DM.dmem[20], U_SCCOMP.U_DM.dmem[21], U_SCCOMP.U_DM.dmem[22], U_SCCOMP.U_DM.dmem[23]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 24, U_SCCOMP.U_DM.dmem[24], U_SCCOMP.U_DM.dmem[25], U_SCCOMP.U_DM.dmem[26], U_SCCOMP.U_DM.dmem[27]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 28, U_SCCOMP.U_DM.dmem[28], U_SCCOMP.U_DM.dmem[29], U_SCCOMP.U_DM.dmem[30], U_SCCOMP.U_DM.dmem[31]);
          $fdisplay(foutput, "dm[%08h]:\t %02h %02h %02h %02h", 32, U_SCCOMP.U_DM.dmem[32], U_SCCOMP.U_DM.dmem[33], U_SCCOMP.U_DM.dmem[34], U_SCCOMP.U_DM.dmem[35]);
          $fdisplay(foutput, "----------------------------------------");
        
          //$fdisplay(foutput, "hi lo:\t %h %h", U_SCCOMP.U_SCPU.U_RF.rf.hi, U_SCCOMP.U_SCPU.U_RF.rf.lo);
          // $fclose(foutput);
          // $stop;
        end
        else begin
          counter = counter + 1;
          $display("pc: %h", U_SCCOMP.PC);
          $display("instr: %h", U_SCCOMP.instr);
          $display("if_id_pc: %h", U_SCCOMP.U_SCPU.if_id_pc);
          $display("if_id_instr: %h", U_SCCOMP.U_SCPU.if_id_instr);
          $display("next_pc: %h", U_SCCOMP.U_SCPU.ex_npc);
          $fclose(foutput);
          $finish;
        end
      end
    end
  end //end always
   
endmodule
