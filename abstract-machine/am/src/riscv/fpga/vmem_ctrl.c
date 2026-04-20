#include <arch/fpga.h>

uint16_t page[PAGE_HEIGHT][VMEM_WIDTH];
uint8_t page_top = 0;
uint8_t page_bottom = VMEM_HEIGHT;
uint8_t window_top = 0;
uint8_t window_bottom = VMEM_HEIGHT;
uint8_t cur_vaddr = 0;
uint8_t cur_haddr = 0;

static bool blinkon = false;

static inline uint8_t vaddr_to_screen(uint8_t vaddr) {
  return (uint8_t)((vaddr + PAGE_HEIGHT - window_top) % PAGE_HEIGHT);
}

void vmem_init(void) {
  for (uint8_t v = 0; v < PAGE_HEIGHT; v++) {
    for (uint8_t h = 0; h < VMEM_WIDTH; h++) {
      page[v][h] = 0x0f20; // 0x0f = white fg + black bg, 0x20 = space
    }
  }

  page_top = 0;
  page_bottom = VMEM_HEIGHT;
  window_top = 0;
  window_bottom = VMEM_HEIGHT;
  cur_vaddr = 0;
  cur_haddr = 0;
  blinkon = false;

  update_vmem();
}

void ext_bottem(void) {
  if (page_bottom == page_top) INC_MPH(page_top);
  for (uint8_t haddr = 0; haddr < VMEM_WIDTH; haddr++) {
    page[page_bottom][haddr] = 0x0f20; // initialize new line with white fg + black bg + space
  }
  INC_MPH(page_bottom);
}

void update_vmem(void) {
  uint8_t screen_v = 0;
  for (uint8_t vaddr = window_top; vaddr != window_bottom; INC_MPH(vaddr)) {
    for (uint8_t haddr = 0; haddr < VMEM_WIDTH; haddr++) {
      VMEM_WR(screen_v, haddr, page[vaddr][haddr]);
    }
    screen_v++;
  }
}

bool scoll_up(void) {
  if (window_top == page_top) return false;
  DEC_MPH(window_bottom);
  DEC_MPH(window_top);
  update_vmem();
  return true;
}

bool scoll_down(void) {
  if (window_bottom == page_bottom) return false;
  INC_MPH(window_bottom);
  INC_MPH(window_top);
  update_vmem();
  return true;
}

void window_setbottom(void) {
  if (window_bottom == page_bottom) return;
  window_bottom = page_bottom;
  window_top = (window_bottom + PAGE_HEIGHT - VMEM_HEIGHT) % PAGE_HEIGHT;
  update_vmem();
}

void new_line(void) {
  cur_blinkoff();
  window_setbottom();
  if ((cur_vaddr + 1) % PAGE_HEIGHT == window_bottom) {
    ext_bottem();
    scoll_down();
  }
  INC_MPH(cur_vaddr);
  cur_haddr = 0;
  window_setbottom();
}

void vga_backspace(void) {
  window_setbottom();
  cur_moveleft();
  window_setbottom();
  page[cur_vaddr][cur_haddr] = 0x0f20; // clear with white fg + black bg + space
  VMEM_WR(vaddr_to_screen(cur_vaddr), cur_haddr, 0x0f20);
}

void vga_putch(uint16_t put_data) {
  window_setbottom();
  page[cur_vaddr][cur_haddr] = put_data;
  VMEM_WR(vaddr_to_screen(cur_vaddr), cur_haddr, put_data);
  cur_moveright();
}

void cur_blinkon(void) {
  if (window_bottom != page_bottom) {
    cur_blinkoff();
    return;
  }
  if (!blinkon) {
    VMEM_WR(vaddr_to_screen(cur_vaddr), cur_haddr, 0xf000);
    blinkon = true;
  }
}

void cur_blinkoff(void) {
  if (blinkon) {
    VMEM_WR(vaddr_to_screen(cur_vaddr), cur_haddr, page[cur_vaddr][cur_haddr]);
    blinkon = false;
  }
}

void cur_moveleft(void) {
  cur_blinkoff();
  window_setbottom();
  if (cur_haddr != 0) {
    cur_haddr--;
    return;
  }
  if (cur_vaddr == window_top) {
    if (!scoll_up()) return;
  }
  DEC_MPH(cur_vaddr);
  cur_haddr = VMEM_WIDTH - 1;
  while (cur_haddr > 0 && page[cur_vaddr][cur_haddr - 1] == 0) {
    cur_haddr--;
  }
}

void cur_moveright(void) {
  cur_blinkoff();
  window_setbottom();
  cur_haddr++;
  if (cur_haddr == VMEM_WIDTH) {
    new_line();
  } else {
    window_setbottom();
  }
}
