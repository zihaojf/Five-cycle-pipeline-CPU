#include <am.h>
#include <klib.h>
#include <klib-macros.h>

#define _heap heap
#define _putc putch
#define _halt halt
#define _ioe_init ioe_init

#ifndef FPGA_DEF_KEYID

#define MAP_KEY(k) _KEY_##k = AM_KEY_##k,
enum {
  MAP_KEY(NONE)
  AM_KEYS(MAP_KEY)
};

#endif

static inline uint32_t uptime() {
#ifndef OSLAB0_UPTIME_DIV
#define OSLAB0_UPTIME_DIV 1u
#endif
  return (uint32_t)(io_read(AM_TIMER_UPTIME).us / (1000ull * (uint64_t)OSLAB0_UPTIME_DIV));
}

#ifdef FPGA_DEF_KEYID
static inline int am_key_to_legacy_key(int am_key) {
  switch (am_key) {
    case AM_KEY_NONE: return _KEY_NONE;
    case AM_KEY_ESCAPE: return _KEY_ESC;
    case AM_KEY_EQUALS: return _KEY_EQ;
    case AM_KEY_LSHIFT: return _KEY_LSIFHT;
    case AM_KEY_APPLICATION: return _KEY_LGUI;

    case AM_KEY_F1: return _KEY_F1;
    case AM_KEY_F2: return _KEY_F2;
    case AM_KEY_F3: return _KEY_F3;
    case AM_KEY_F4: return _KEY_F4;
    case AM_KEY_F5: return _KEY_F5;
    case AM_KEY_F6: return _KEY_F6;
    case AM_KEY_F7: return _KEY_F7;
    case AM_KEY_F8: return _KEY_F8;
    case AM_KEY_F9: return _KEY_F9;
    case AM_KEY_F10: return _KEY_F10;
    case AM_KEY_F11: return _KEY_F11;
    case AM_KEY_F12: return _KEY_F12;
    case AM_KEY_GRAVE: return _KEY_GRAVE;
    case AM_KEY_1: return _KEY_1;
    case AM_KEY_2: return _KEY_2;
    case AM_KEY_3: return _KEY_3;
    case AM_KEY_4: return _KEY_4;
    case AM_KEY_5: return _KEY_5;
    case AM_KEY_6: return _KEY_6;
    case AM_KEY_7: return _KEY_7;
    case AM_KEY_8: return _KEY_8;
    case AM_KEY_9: return _KEY_9;
    case AM_KEY_0: return _KEY_0;
    case AM_KEY_MINUS: return _KEY_MINUS;
    case AM_KEY_BACKSPACE: return _KEY_BACKSPACE;
    case AM_KEY_TAB: return _KEY_TAB;
    case AM_KEY_Q: return _KEY_Q;
    case AM_KEY_W: return _KEY_W;
    case AM_KEY_E: return _KEY_E;
    case AM_KEY_R: return _KEY_R;
    case AM_KEY_T: return _KEY_T;
    case AM_KEY_Y: return _KEY_Y;
    case AM_KEY_U: return _KEY_U;
    case AM_KEY_I: return _KEY_I;
    case AM_KEY_O: return _KEY_O;
    case AM_KEY_P: return _KEY_P;
    case AM_KEY_LEFTBRACKET: return _KEY_LEFTBRACKET;
    case AM_KEY_RIGHTBRACKET: return _KEY_RIGHTBRACKET;
    case AM_KEY_BACKSLASH: return _KEY_BACKSLASH;
    case AM_KEY_CAPSLOCK: return _KEY_CAPSLOCK;
    case AM_KEY_A: return _KEY_A;
    case AM_KEY_S: return _KEY_S;
    case AM_KEY_D: return _KEY_D;
    case AM_KEY_F: return _KEY_F;
    case AM_KEY_G: return _KEY_G;
    case AM_KEY_H: return _KEY_H;
    case AM_KEY_J: return _KEY_J;
    case AM_KEY_K: return _KEY_K;
    case AM_KEY_L: return _KEY_L;
    case AM_KEY_SEMICOLON: return _KEY_SEMICOLON;
    case AM_KEY_APOSTROPHE: return _KEY_APOSTROPHE;
    case AM_KEY_RETURN: return _KEY_RETURN;
    case AM_KEY_Z: return _KEY_Z;
    case AM_KEY_X: return _KEY_X;
    case AM_KEY_C: return _KEY_C;
    case AM_KEY_V: return _KEY_V;
    case AM_KEY_B: return _KEY_B;
    case AM_KEY_N: return _KEY_N;
    case AM_KEY_M: return _KEY_M;
    case AM_KEY_COMMA: return _KEY_COMMA;
    case AM_KEY_PERIOD: return _KEY_PERIOD;
    case AM_KEY_SLASH: return _KEY_SLASH;
    case AM_KEY_RSHIFT: return _KEY_RSHIFT;
    case AM_KEY_LCTRL: return _KEY_LCTRL;
    case AM_KEY_LALT: return _KEY_LALT;
    case AM_KEY_SPACE: return _KEY_SPACE;
    case AM_KEY_RALT: return _KEY_RALT;
    case AM_KEY_RCTRL: return _KEY_RCTRL;
    case AM_KEY_UP: return _KEY_UP;
    case AM_KEY_DOWN: return _KEY_DOWN;
    case AM_KEY_LEFT: return _KEY_LEFT;
    case AM_KEY_RIGHT: return _KEY_RIGHT;
    case AM_KEY_INSERT: return _KEY_INSERT;
    case AM_KEY_DELETE: return _KEY_DELETE;
    case AM_KEY_HOME: return _KEY_HOME;
    case AM_KEY_END: return _KEY_END;
    case AM_KEY_PAGEUP: return _KEY_PAGEUP;
    case AM_KEY_PAGEDOWN: return _KEY_PAGEDOWN;
    default: return _KEY_NONE;
  }
}
#endif

static inline int read_key() {
  AM_INPUT_KEYBRD_T keybrd = io_read(AM_INPUT_KEYBRD);
#ifdef FPGA_DEF_KEYID
  int key = am_key_to_legacy_key(keybrd.keycode);
#else
  int key = keybrd.keycode;
#endif
  key = key | (keybrd.keydown << 15);
  return key;
}

static inline void draw_rect(uint32_t *pixels, int x, int y, int w, int h) {
  io_write(AM_GPU_FBDRAW, x, y, pixels, w, h, 0);
}

static inline void draw_sync() {
  io_write(AM_GPU_FBDRAW, 0, 0, NULL, 0, 0, 1);
}

static inline int screen_width() {
  return io_read(AM_GPU_CONFIG).width;
}

static inline int screen_height() {
  return io_read(AM_GPU_CONFIG).height;
}
