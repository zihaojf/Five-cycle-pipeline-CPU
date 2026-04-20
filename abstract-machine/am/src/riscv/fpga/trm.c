#include <am.h>
#include <arch/fpga.h>
#include <klib-macros.h>

extern char _heap_start;
extern char _stack_top;

Area heap = RANGE(&_heap_start, &_stack_top);

extern int main();

void halt(int code) {
  const uint16_t good_trap = 0x03ff;
  const uint16_t bad_trap  = 0x02aa;

  HEX_PRINT((uint32_t)code);

  while (1) {
    uint32_t now_ds_time = CLK_DS_RD();
    LEDR_WR(((now_ds_time / 4) % 2) ? (code ? bad_trap : good_trap) : 0);

    uint8_t key_id = KBD_RD();
    if (key_id == _KEY_NONE || (key_id & _KEYID_BREAK_MASK)) continue;
    if (key_id == _KEY_PAGEUP) scoll_up();
    else if (key_id == _KEY_PAGEDOWN) scoll_down();
  }
}

void _trm_init() {
  VGA_FONT_ON();
  vmem_init();

  int ret = main();
  halt(ret);
}
