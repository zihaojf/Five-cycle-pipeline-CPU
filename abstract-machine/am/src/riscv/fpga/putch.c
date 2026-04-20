#include <am.h>
#include <arch/fpga.h>

enum {
  ASNI_CTRL_NONE,
  ASNI_CTRL_BEGIN,
  ASNI_CTRL_LEFTB,
  ASNI_CTRL_END,
  ASNI_CTRL_COLOR,
  ASNI_CTRL_SEMIC,
  ASNI_CTRL_FGBG,
  ASNI_CTRL_CODE
};

enum {
  ASNI_CTRL_COLOR_NONE,
  ASNI_CTRL_COLOR_FG,
  ASNI_CTRL_COLOR_BG
};

static uint8_t asni_color = 0x0f; // white fg + black bg by default

static inline void asni_color_clr(void) {
  asni_color = 0;
}

static inline void asni_set_fg(uint8_t color_code) {
  asni_color = (asni_color & 0xf0) | 0x08 | (color_code & 0x07);
}

static inline void asni_set_bg(uint8_t color_code) {
  asni_color = 0x80 | ((color_code & 0x07) << 4) | (asni_color & 0x0f);
}

void putch(char ch) {
  static uint16_t asni_state = ASNI_CTRL_NONE;
  static uint8_t asni_color_type = ASNI_CTRL_COLOR_NONE;
  uint16_t put_data;

  switch (asni_state) {
    case ASNI_CTRL_BEGIN:
      if (ch == '[') asni_state = ASNI_CTRL_LEFTB;
      else asni_state = ASNI_CTRL_NONE;
      return;

    case ASNI_CTRL_LEFTB:
      if (ch == '1') asni_state = ASNI_CTRL_COLOR;
      else if (ch == '0') {
        asni_color_clr();
        asni_state = ASNI_CTRL_END;
      } else asni_state = ASNI_CTRL_NONE;
      return;

    case ASNI_CTRL_COLOR:
      if (ch == ';') asni_state = ASNI_CTRL_SEMIC;
      else asni_state = ASNI_CTRL_NONE;
      return;

    case ASNI_CTRL_SEMIC:
      if (ch == '3') {
        asni_color_type = ASNI_CTRL_COLOR_FG;
        asni_state = ASNI_CTRL_FGBG;
      } else if (ch == '4') {
        asni_color_type = ASNI_CTRL_COLOR_BG;
        asni_state = ASNI_CTRL_FGBG;
      } else {
        asni_state = ASNI_CTRL_NONE;
      }
      return;

    case ASNI_CTRL_FGBG:
      if (ch >= '0' && ch <= '7') {
        if (asni_color_type == ASNI_CTRL_COLOR_FG) asni_set_fg((uint8_t)(ch - '0'));
        else asni_set_bg((uint8_t)(ch - '0'));
        asni_state = ASNI_CTRL_CODE;
      } else {
        asni_state = ASNI_CTRL_NONE;
      }
      return;

    case ASNI_CTRL_END:
    case ASNI_CTRL_CODE:
      asni_state = ASNI_CTRL_NONE;
      return;

    case ASNI_CTRL_NONE:
    default:
      break;
  }

  switch (ch) {
    case '\b':
      vga_backspace();
      return;
    case '\n':
      new_line();
      return;
    case '\33':
      asni_state = ASNI_CTRL_BEGIN;
      asni_color_type = ASNI_CTRL_COLOR_NONE;
      return;
    default:
      put_data = ((uint16_t)asni_color << 8) | (uint8_t)ch;
      vga_putch(put_data);
      return;
  }
}
