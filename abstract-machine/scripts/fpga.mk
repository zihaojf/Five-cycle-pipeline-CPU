ARCH_H := arch/fpga.h

CROSS_COMPILE := riscv32-unknown-elf-

COMMON_CFLAGS := -fno-pic -march=rv32i -mabi=ilp32 -mcmodel=medany -mstrict-align
CFLAGS        += $(COMMON_CFLAGS) -static -DISA_H=\"riscv/riscv.h\"
ASFLAGS       += $(COMMON_CFLAGS) -O0
LDFLAGS       += -melf32lriscv

LDSCRIPTS += $(AM_HOME)/scripts/riscv32_fpga.ld

AM_SRCS += riscv/fpga/start.S \
           riscv/fpga/trm.c \
           riscv/fpga/ioe.c \
           riscv/fpga/timer.c \
           riscv/fpga/input.c \
           riscv/fpga/gpu.c \
           riscv/fpga/hex.c \
           riscv/fpga/keymap.c \
           riscv/fpga/vmem_ctrl.c \
           riscv/fpga/putch.c \
           riscv/fpga/readline.c \
           riscv/fpga/mulsi3.S \
           riscv/fpga/div.S
