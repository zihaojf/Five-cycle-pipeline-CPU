#ifndef __ARCH_FPGA_H__
#define __ARCH_FPGA_H__

#include <stdint.h>
#include <stddef.h>
#include <stdbool.h>

#include <arch/riscv.h>

// MMIO base addresses (aligned with FPGA bus decode)
#define MEM_ADDR      0x01000000u
#define KBD_ADDR      0x02000000u
#define VMEM_ADDR     0x03000000u
#define HEX_ADDR      0x04000000u
#define LEDR_ADDR     0x05000000u
#define SW_ADDR       0x06000000u
#define KEY_ADDR      0x07000000u
#define CLK_ADDR      0x08000000u
#define CLK_US_ADDR   (CLK_ADDR + 0x0u)
#define CLK_MS_ADDR   (CLK_ADDR + 0x4u)
#define CLK_DS_ADDR   (CLK_ADDR + 0x8u)
#define CLK_S_ADDR    (CLK_ADDR + 0xcu)
#define VGA_CTRL      0x09000000u
#define FB_ADDR       0x0a000000u

#define VGA_FONT      0x0u
#define VGA_GRAPHIC   0x1u
#define VGA_FONT_MODE    VGA_FONT
#define VGA_GRAPHIC_MODE VGA_GRAPHIC

#define SCREEN_WIDTH  640
#define SCREEN_HEIGHT 480

#define VMEM_WIDTH   80
#define VMEM_HEIGHT  30
#define VMEM_HIGHT   VMEM_HEIGHT
#define PAGE_HEIGHT  64

#define INC_MPH(var) ((var) = ((var) + 1) % PAGE_HEIGHT)
#define DEC_MPH(var) ((var) = ((var) + PAGE_HEIGHT - 1) % PAGE_HEIGHT)

// keyboard begin
#define KEY_LIST(f) \
  f(0) f(1) f(2) f(3) f(4) f(5) f(6) f(7) f(8) f(9) \
  f(A) f(B) f(C) f(D) f(E) f(F) f(G) f(H) f(I) f(J) \
  f(K) f(L) f(M) f(N) f(O) f(P) f(Q) f(R) f(S) f(T) \
  f(U) f(V) f(W) f(X) f(Y) f(Z) f(MINUS) f(EQ) f(LEFTBRACKET) \
  f(RIGHTBRACKET) f(BACKSLASH) f(SEMICOLON) f(APOSTROPHE) \
  f(COMMA) f(PERIOD) f(SLASH) f(SPACE) f(GRAVE) f(TAB) \
  f(ESC) f(F1) f(F2) f(F3) f(F4) f(F5) f(F6) f(F7) f(F8) \
  f(F9) f(F10) f(F11) f(F12) f(BACKSPACE) f(CAPSLOCK) f(RETURN) \
  f(LSIFHT) f(LCTRL) f(LGUI) f(LALT) f(RALT) f(RGUI) f(FN) f(RCTRL) f(RSHIFT) \
  f(UP) f(DOWN) f(LEFT) f(RIGHT) f(INSERT) f(DELETE) \
  f(HOME) f(END) f(PAGEUP) f(PAGEDOWN) f(NUM) f(KP_SLASH) f(KP_STAR) \
  f(KP_MINUS) f(KP_PLUS) f(KP_EN) f(KP) f(KP_0) f(KP_1) f(KP_2) f(KP_3) \
  f(KP_4) f(KP_5) f(KP_6) f(KP_7) f(KP_8) f(KP_9)

#define _KEYCODE_BREAK  0xf0u
#define _KEYCODE_SECOND 0xe0u
#define _KEYID_BREAK_MASK 0x80u
#define FPGA_DEF_KEYID

#define DEF_KEY_ID(name) _KEY_##name,
enum {
  _KEY_NONE,
  KEY_LIST(DEF_KEY_ID)
  NR_KEY
};

// Compatibility alias for the typo used in the original sample project.
#define _KEY_LSHIFT _KEY_LSIFHT

extern char key_id2ascii[NR_KEY];
extern char key_id2ascii_shift[NR_KEY];

static inline uint8_t KBD_RD_KEYCODE(void) {
  return *(volatile uint8_t *)KBD_ADDR;
}

uint8_t KBD_RD(void);
// keyboard end

static inline uint8_t inb(uintptr_t addr) {
  return *(volatile uint8_t *)addr;
}

static inline uint16_t inw(uintptr_t addr) {
  return *(volatile uint16_t *)addr;
}

static inline uint32_t inl(uintptr_t addr) {
  return *(volatile uint32_t *)addr;
}

static inline void outb(uintptr_t addr, uint8_t data) {
  *(volatile uint8_t *)addr = data;
}

static inline void outw(uintptr_t addr, uint16_t data) {
  *(volatile uint16_t *)addr = data;
}

static inline void outl(uintptr_t addr, uint32_t data) {
  *(volatile uint32_t *)addr = data;
}

// vga text mode helpers
static inline void VMEM_WR(uint8_t vaddr, uint8_t haddr, uint16_t data) {
  outw(VMEM_ADDR + (uintptr_t)((((uintptr_t)vaddr * VMEM_WIDTH) + haddr) << 1), data);
}

static inline void VMEM_WR_CH(uint8_t vaddr, uint8_t haddr, uint8_t color, uint8_t ascii) {
  outw(VMEM_ADDR + (uintptr_t)((((uintptr_t)vaddr * VMEM_WIDTH) + haddr) << 1),
       (uint16_t)(((uint16_t)color << 8) | ascii));
}

extern uint16_t page[][VMEM_WIDTH];
extern uint8_t page_top, page_bottom;
extern uint8_t window_top, window_bottom;
extern uint8_t cur_vaddr, cur_haddr;

void vmem_init(void);
void ext_bottem(void);
void update_vmem(void);
bool scoll_up(void);
bool scoll_down(void);
void new_line(void);
void vga_backspace(void);
void vga_putch(uint16_t put_data);
void window_setbottom(void);
void cur_blinkon(void);
void cur_blinkoff(void);
void cur_moveleft(void);
void cur_moveright(void);

#define READBUF_LEN 256
char *readline(void);

// clock helpers
static inline uint32_t CLK_US_RD(void) { return inl(CLK_US_ADDR); }
static inline uint32_t CLK_MS_RD(void) { return inl(CLK_MS_ADDR); }
static inline uint32_t CLK_DS_RD(void) { return inl(CLK_DS_ADDR); }
static inline uint32_t CLK_S_RD(void)  { return inl(CLK_S_ADDR);  }

// fpga io helpers
void HEX_CLR(void);
void HEX_PRINT(uint32_t hex_num);
void HEX_PRINT_DEC(uint32_t dec_num);

static inline void HEX_WR(uint8_t wridx, uint8_t wrval) {
  outb(HEX_ADDR + (uintptr_t)wridx, wrval);
}

static inline void LEDR_WR(uint16_t wrval) {
  outw(LEDR_ADDR, wrval);
}

static inline uint16_t SW_RD(void) {
  return inw(SW_ADDR);
}

static inline void VGA_FONT_ON(void) {
  outb(VGA_CTRL, VGA_FONT);
}

static inline void VGA_GRAPHIC_ON(void) {
  outb(VGA_CTRL, VGA_GRAPHIC);
}

#endif
