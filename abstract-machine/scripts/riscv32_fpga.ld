ENTRY(_start)
OUTPUT_FORMAT("elf32-littleriscv")

MEMORY {
  imem (rx)  : ORIGIN = 0x00000000, LENGTH = 128K
  dmem (rwx) : ORIGIN = 0x01000000, LENGTH = 128K
}

SECTIONS {
  . = ORIGIN(imem);
  .text : {
    *(entry)
    *(.text.init)
    *(.text*)
  } > imem

  . = ORIGIN(dmem);
  .rodata : {
    *(.rodata*)
  } > dmem

  .data : {
    *(.data*)
  } > dmem

  .bss (NOLOAD) : {
    *(.bss*)
    *(COMMON)
  } > dmem

  . = ALIGN(16);
  _heap_start = .;
  _stack_top = ORIGIN(dmem) + LENGTH(dmem);
}
