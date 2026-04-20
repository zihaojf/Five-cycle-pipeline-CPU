#include <am.h>
#include <arch/fpga.h>

void __am_gpu_init() {
  for (uint32_t i = 0; i < (uint32_t)(SCREEN_WIDTH * SCREEN_HEIGHT); i++) {
    outl(FB_ADDR + ((uintptr_t)i << 2), 0);
  }
  outb(VGA_CTRL, VGA_FONT_MODE);
}

void __am_gpu_config(AM_GPU_CONFIG_T *cfg) {
  *cfg = (AM_GPU_CONFIG_T) {
    .present = true,
    .has_accel = false,
    .width = SCREEN_WIDTH,
    .height = SCREEN_HEIGHT,
    .vmemsz = SCREEN_WIDTH * SCREEN_HEIGHT,
  };
}

void __am_gpu_fbdraw(AM_GPU_FBDRAW_T *ctl) {
  if (ctl->pixels != NULL && ctl->w > 0 && ctl->h > 0) {
    uint32_t *pixels = (uint32_t *)ctl->pixels;
    for (int y = 0; y < ctl->h; y++) {
      int py = ctl->y + y;
      if (py < 0 || py >= SCREEN_HEIGHT) continue;

      for (int x = 0; x < ctl->w; x++) {
        int px = ctl->x + x;
        if (px < 0 || px >= SCREEN_WIDTH) continue;

        uintptr_t dst = FB_ADDR + (uintptr_t)(((py * SCREEN_WIDTH) + px) << 2);
        outl(dst, pixels[y * ctl->w + x]);
      }
    }
  }

  if (ctl->sync) {
    outb(VGA_CTRL, VGA_GRAPHIC_MODE);
  }
}

void __am_gpu_status(AM_GPU_STATUS_T *status) {
  status->ready = true;
}
