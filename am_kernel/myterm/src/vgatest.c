#include <myterm.h>

#define FPS 30
#define N   32
#define CLEAR_CHUNK_W 256

static inline uint32_t pixel(uint8_t r, uint8_t g, uint8_t b) {
  return ((uint32_t)r << 16) | ((uint32_t)g << 8) | (uint32_t)b;
}

static uint32_t canvas[N][N];
static uint8_t used[N][N];
static uint32_t color_buf[32 * 32];

static void redraw(void) {
  AM_GPU_CONFIG_T cfg = io_read(AM_GPU_CONFIG);
  int w = cfg.width / N;
  int h = cfg.height / N;
  int block_size = w * h;
  assert((uint32_t)block_size <= LENGTH(color_buf));

  for (int y = 0; y < N; y++) {
    for (int x = 0; x < N; x++) {
      for (int k = 0; k < block_size; k++) {
        color_buf[k] = canvas[y][x];
      }
      io_write(AM_GPU_FBDRAW, x * w, y * h, color_buf, w, h, false);
    }
  }
  io_write(AM_GPU_FBDRAW, 0, 0, NULL, 0, 0, true);
}

static uint32_t p(int tsc) {
  int b = tsc & 0xff;
  return pixel((uint8_t)(b * 6), (uint8_t)(b * 7), (uint8_t)b);
}

static void update_canvas(void) {
  static int tsc = 0;
  static int dx[4] = {0, 1, 0, -1};
  static int dy[4] = {1, 0, -1, 0};

  tsc++;

  for (int i = 0; i < N; i++) {
    for (int j = 0; j < N; j++) {
      used[i][j] = 0;
    }
  }

  int init = tsc;
  canvas[0][0] = p(init);
  used[0][0] = 1;
  int x = 0, y = 0, d = 0;
  for (int step = 1; step < N * N; step++) {
    for (int t = 0; t < 4; t++) {
      int x1 = x + dx[d], y1 = y + dy[d];
      if (x1 >= 0 && x1 < N && y1 >= 0 && y1 < N && !used[x1][y1]) {
        x = x1;
        y = y1;
        used[x][y] = 1;
        canvas[x][y] = p(init + step / 2);
        break;
      }
      d = (d + 1) % 4;
    }
  }
}

static int exit_key_pressed(void) {
  AM_INPUT_KEYBRD_T ev = io_read(AM_INPUT_KEYBRD);
  if (!ev.keydown) return 0;
  return (ev.keycode == AM_KEY_ESCAPE || ev.keycode == AM_KEY_Q);
}

static void clear_graphic_screen(void) {
  AM_GPU_CONFIG_T cfg = io_read(AM_GPU_CONFIG);
  static uint32_t line[CLEAR_CHUNK_W];

  for (int i = 0; i < CLEAR_CHUNK_W; i++) line[i] = 0x00000000u;

  for (int y = 0; y < cfg.height; y++) {
    int x = 0;
    while (x < cfg.width) {
      int w = cfg.width - x;
      if (w > CLEAR_CHUNK_W) w = CLEAR_CHUNK_W;
      io_write(AM_GPU_FBDRAW, x, y, line, w, 1, false);
      x += w;
    }
  }
  io_write(AM_GPU_FBDRAW, 0, 0, NULL, 0, 0, true);
}

int exe_vgatest(int argc, char *argv[]) {
  (void)argc;
  (void)argv;

#ifdef __ARCH_FPGA
  VGA_GRAPHIC_ON();
#endif

  printf("vgatest: press ESC/Q to exit.\n");

  unsigned long last = io_read(AM_TIMER_UPTIME).us / 1000;
  while (1) {
    if (exit_key_pressed()) break;

    unsigned long upt = io_read(AM_TIMER_UPTIME).us / 1000;
    if (upt - last >= 1000 / FPS) {
      update_canvas();
      redraw();
      last = upt;
    }
  }

  clear_graphic_screen();

#ifdef __ARCH_FPGA
  VGA_FONT_ON();
#endif
  putch('\n');
  return 0;
}
