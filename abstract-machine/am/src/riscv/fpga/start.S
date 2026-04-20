.section entry, "ax"
.globl _start
.type _start, @function

_start:
  la sp, _stack_top
  jal _trm_init
1:
  j 1b
