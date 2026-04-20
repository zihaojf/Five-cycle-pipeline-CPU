#include <arch/fpga.h>

void HEX_CLR(void) {
  for (uint8_t i = 0; i < 6; i++) {
    outb(HEX_ADDR + i, 0);
  }
}

void HEX_PRINT(uint32_t hex_num) {
  HEX_CLR();
  for (uint8_t i = 0; hex_num && i < 6; hex_num >>= 4, i++) {
    outb(HEX_ADDR + i, hex_num & 0x0f);
  }
}

void HEX_PRINT_DEC(uint32_t dec_num) {
  HEX_CLR();
  for (uint8_t i = 0; dec_num && i < 6; dec_num /= 10, i++) {
    outb(HEX_ADDR + i, dec_num % 10);
  }
}
