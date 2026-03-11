## 1.五阶段流水线框架搭建
allowin 表示本级流水线是否允许有数据输入;
ready_go 表示本级流水线的当前数据是否准备好了传递给下一级;
pipex_to_pipex_valid 表示流水线传递的数据是否合法

## 2. 添加前递
![](./SCPU/images/Forwarding_unit.png)
    IF  |   ID  |   EX  |   MEM |   WB  
共有这五个阶段  
可能会从MEM/WB和EX/MEM这两个流水线后前递到ALU处。
### EX/MEM 前递
```verilog
Forwarding Condition: EX/MEM hazard
     if (EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
and (EX/MEM.RegisterRd = ID/EX.RegisterRs1)) ForwardA = 01
     if (EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
and (EX/MEM.RegisterRd = ID/EX.RegisterRs2)) ForwardB = 01
```
### MEM/WB 前递
```verilog
Forwarding Condition: MEM/WB hazard
     if (MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)
and not(EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
and (EX/MEM.RegisterRd = ID/EX.RegisterRs1))
and (MEM/WB.RegisterRd = ID/EX.RegisterRs1)) ForwardA = 10
     if (MEM/WB.RegWrite and (MEM/WB.RegisterRd ≠ 0)
and not(EX/MEM.RegWrite and (EX/MEM.RegisterRd ≠ 0)
and (EX/MEM.RegisterRd = ID/EX.RegisterRs2))
and (MEM/WB.RegisterRd = ID/EX.RegisterRs2)) ForwardB = 10
```
MEM/WB 要保证没有发生EX/MEM前递，即EX/MEM前递优先处理！

### 实现思路
1. 添加一个Fowarding unit模块，产生控制信号，确定是否有前递情况
2. ALU_A处的mux：一是来自RD1,二是来自前递的两个数据
3. ALU_B处的mux：先要确定数据来自RD2还是immout,在确定是否有前递

所以要在ALU前再添加两个mux，命名为 `Forwarding_A_MUX`和`Forwarding_B_MUX`


## 3.冒险检测+停顿
检测条件
```verilog
ID/EX.MemRead
and ((ID/EX.RegisterRd = IF/ID.RegisterRs1)
or (ID/EX.RegisterRd = IF/ID.RegisterRs2))
```
条件成立，PC_write = 0,IF/ID.write = 0,然后再把ID/EX flush控制信号清零  
插入一个NOP
![](./SCPU/images/hazard_detection_unit.png)

## 4.跳转指令
在NPC模块下添加了一个branch信号输出是否跳转，当跳转成立时，应当flush IF/ID,ID/EX的信号。

## 5.38条指令
待实现的38条指令
• I0={LUI, AUIPC}
• I1={JAL, JALR, BEQ, BNE, BLT, BGE, BLTU, BGEU}
• I2={LB, LH, LW, LBU, LHU, SB, SH, SW}
• I3={ADDI, SLTI, SLTIU, XORI, ORI, ANDI, ALLI, SRLI,
SRALI, SRAI}
• I4={ADD, SUB, SLL, SLT, SLTU, XOR, SRL, SRA, OR, AND}

### 5.1 LUI, AUIPC
![](./SCPU/images/lui_auipc.png)
```
LUI (load upper immediate) is used to build 32-bit constants and uses the U-type format. LUI places
the 32-bit U-immediate value into the destination register rd, filling in the lowest 12 bits with zeros.
```
```
AUIPC (add upper immediate to pc) is used to build pc-relative addresses and uses the U-type format.
AUIPC forms a 32-bit offset from the U-immediate, filling in the lowest 12 bits with zeros, adds this
offset to the address of the AUIPC instruction, then places the result in register rd.
```



