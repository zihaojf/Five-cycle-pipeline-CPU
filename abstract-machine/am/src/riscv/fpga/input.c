#include <am.h>
#include <arch/fpga.h>

static const uint8_t keycode2key_id[132] = {
  [0x01] = _KEY_F9,
  [0x03] = _KEY_F5,
  [0x04] = _KEY_F3,
  [0x05] = _KEY_F1,
  [0x06] = _KEY_F2,
  [0x07] = _KEY_F12,
  [0x09] = _KEY_F10,
  [0x0a] = _KEY_F8,
  [0x0b] = _KEY_F6,
  [0x0c] = _KEY_F4,
  [0x0d] = _KEY_TAB,
  [0x0e] = _KEY_GRAVE,
  [0x11] = _KEY_LALT,
  [0x12] = _KEY_LSIFHT,
  [0x14] = _KEY_LCTRL,
  [0x15] = _KEY_Q,
  [0x16] = _KEY_1,
  [0x1a] = _KEY_Z,
  [0x1b] = _KEY_S,
  [0x1c] = _KEY_A,
  [0x1d] = _KEY_W,
  [0x1e] = _KEY_2,
  [0x21] = _KEY_C,
  [0x22] = _KEY_X,
  [0x23] = _KEY_D,
  [0x24] = _KEY_E,
  [0x25] = _KEY_4,
  [0x26] = _KEY_3,
  [0x29] = _KEY_SPACE,
  [0x2a] = _KEY_V,
  [0x2b] = _KEY_F,
  [0x2c] = _KEY_T,
  [0x2d] = _KEY_R,
  [0x2e] = _KEY_5,
  [0x31] = _KEY_N,
  [0x32] = _KEY_B,
  [0x33] = _KEY_H,
  [0x34] = _KEY_G,
  [0x35] = _KEY_Y,
  [0x36] = _KEY_6,
  [0x3a] = _KEY_M,
  [0x3b] = _KEY_J,
  [0x3c] = _KEY_U,
  [0x3d] = _KEY_7,
  [0x3e] = _KEY_8,
  [0x41] = _KEY_COMMA,
  [0x42] = _KEY_K,
  [0x43] = _KEY_I,
  [0x44] = _KEY_O,
  [0x45] = _KEY_0,
  [0x46] = _KEY_9,
  [0x49] = _KEY_PERIOD,
  [0x4a] = _KEY_SLASH,
  [0x4b] = _KEY_L,
  [0x4c] = _KEY_SEMICOLON,
  [0x4d] = _KEY_P,
  [0x4e] = _KEY_MINUS,
  [0x52] = _KEY_APOSTROPHE,
  [0x54] = _KEY_LEFTBRACKET,
  [0x55] = _KEY_EQ,
  [0x58] = _KEY_CAPSLOCK,
  [0x59] = _KEY_RSHIFT,
  [0x5a] = _KEY_RETURN,
  [0x5b] = _KEY_RIGHTBRACKET,
  [0x5d] = _KEY_BACKSLASH,
  [0x66] = _KEY_BACKSPACE,
  [0x69] = _KEY_KP_1,
  [0x6b] = _KEY_KP_4,
  [0x6c] = _KEY_KP_7,
  [0x70] = _KEY_KP_0,
  [0x71] = _KEY_KP,
  [0x72] = _KEY_KP_2,
  [0x73] = _KEY_KP_5,
  [0x74] = _KEY_KP_6,
  [0x75] = _KEY_KP_8,
  [0x76] = _KEY_ESC,
  [0x77] = _KEY_NUM,
  [0x78] = _KEY_F11,
  [0x79] = _KEY_KP_PLUS,
  [0x7a] = _KEY_KP_3,
  [0x7b] = _KEY_KP_MINUS,
  [0x7c] = _KEY_KP_STAR,
  [0x7d] = _KEY_KP_9,
  [0x83] = _KEY_F7,
};

uint8_t KBD_RD(void) {
  static uint8_t key_break = 0;
  static bool key_sec = false;

  uint8_t keycode = inb(KBD_ADDR);
  if (!keycode) return _KEY_NONE;

  if (keycode == _KEYCODE_BREAK) {
    key_break = _KEYID_BREAK_MASK;
    return _KEY_NONE;
  }

  if (keycode == _KEYCODE_SECOND) {
    key_sec = true;
    return _KEY_NONE;
  }

  uint8_t ret = _KEY_NONE;

  if (key_sec) {
    switch (keycode) {
      case 0x1f: ret = _KEY_LGUI; break;
      case 0x14: ret = _KEY_RCTRL; break;
      case 0x27: ret = _KEY_RGUI; break;
      case 0x11: ret = _KEY_RALT; break;
      case 0x2f: ret = _KEY_FN; break;
      case 0x4a: ret = _KEY_KP_SLASH; break;
      case 0x5a: ret = _KEY_KP_EN; break;
      case 0x70: ret = _KEY_INSERT; break;
      case 0x6c: ret = _KEY_HOME; break;
      case 0x69: ret = _KEY_END; break;
      case 0x71: ret = _KEY_DELETE; break;
      case 0x7d: ret = _KEY_PAGEUP; break;
      case 0x7a: ret = _KEY_PAGEDOWN; break;
      case 0x75: ret = _KEY_UP; break;
      case 0x6b: ret = _KEY_LEFT; break;
      case 0x72: ret = _KEY_DOWN; break;
      case 0x74: ret = _KEY_RIGHT; break;
      default: ret = _KEY_NONE; break;
    }
  } else {
    if (keycode < sizeof(keycode2key_id)) {
      ret = keycode2key_id[keycode];
    }
  }

  ret |= key_break;
  key_break = 0;
  key_sec = false;
  return ret;
}

static int key_id_to_am_key(uint8_t keyid) {
  switch (keyid) {
    case _KEY_ESC: return AM_KEY_ESCAPE;
    case _KEY_F1: return AM_KEY_F1;
    case _KEY_F2: return AM_KEY_F2;
    case _KEY_F3: return AM_KEY_F3;
    case _KEY_F4: return AM_KEY_F4;
    case _KEY_F5: return AM_KEY_F5;
    case _KEY_F6: return AM_KEY_F6;
    case _KEY_F7: return AM_KEY_F7;
    case _KEY_F8: return AM_KEY_F8;
    case _KEY_F9: return AM_KEY_F9;
    case _KEY_F10: return AM_KEY_F10;
    case _KEY_F11: return AM_KEY_F11;
    case _KEY_F12: return AM_KEY_F12;

    case _KEY_GRAVE: return AM_KEY_GRAVE;
    case _KEY_1: return AM_KEY_1;
    case _KEY_2: return AM_KEY_2;
    case _KEY_3: return AM_KEY_3;
    case _KEY_4: return AM_KEY_4;
    case _KEY_5: return AM_KEY_5;
    case _KEY_6: return AM_KEY_6;
    case _KEY_7: return AM_KEY_7;
    case _KEY_8: return AM_KEY_8;
    case _KEY_9: return AM_KEY_9;
    case _KEY_0: return AM_KEY_0;
    case _KEY_MINUS: return AM_KEY_MINUS;
    case _KEY_EQ: return AM_KEY_EQUALS;
    case _KEY_BACKSPACE: return AM_KEY_BACKSPACE;

    case _KEY_TAB: return AM_KEY_TAB;
    case _KEY_Q: return AM_KEY_Q;
    case _KEY_W: return AM_KEY_W;
    case _KEY_E: return AM_KEY_E;
    case _KEY_R: return AM_KEY_R;
    case _KEY_T: return AM_KEY_T;
    case _KEY_Y: return AM_KEY_Y;
    case _KEY_U: return AM_KEY_U;
    case _KEY_I: return AM_KEY_I;
    case _KEY_O: return AM_KEY_O;
    case _KEY_P: return AM_KEY_P;
    case _KEY_LEFTBRACKET: return AM_KEY_LEFTBRACKET;
    case _KEY_RIGHTBRACKET: return AM_KEY_RIGHTBRACKET;
    case _KEY_BACKSLASH: return AM_KEY_BACKSLASH;

    case _KEY_CAPSLOCK: return AM_KEY_CAPSLOCK;
    case _KEY_A: return AM_KEY_A;
    case _KEY_S: return AM_KEY_S;
    case _KEY_D: return AM_KEY_D;
    case _KEY_F: return AM_KEY_F;
    case _KEY_G: return AM_KEY_G;
    case _KEY_H: return AM_KEY_H;
    case _KEY_J: return AM_KEY_J;
    case _KEY_K: return AM_KEY_K;
    case _KEY_L: return AM_KEY_L;
    case _KEY_SEMICOLON: return AM_KEY_SEMICOLON;
    case _KEY_APOSTROPHE: return AM_KEY_APOSTROPHE;
    case _KEY_RETURN: return AM_KEY_RETURN;

    case _KEY_LSIFHT: return AM_KEY_LSHIFT;
    case _KEY_RSHIFT: return AM_KEY_RSHIFT;
    case _KEY_Z: return AM_KEY_Z;
    case _KEY_X: return AM_KEY_X;
    case _KEY_C: return AM_KEY_C;
    case _KEY_V: return AM_KEY_V;
    case _KEY_B: return AM_KEY_B;
    case _KEY_N: return AM_KEY_N;
    case _KEY_M: return AM_KEY_M;
    case _KEY_COMMA: return AM_KEY_COMMA;
    case _KEY_PERIOD: return AM_KEY_PERIOD;
    case _KEY_SLASH: return AM_KEY_SLASH;

    case _KEY_LCTRL: return AM_KEY_LCTRL;
    case _KEY_LALT: return AM_KEY_LALT;
    case _KEY_RALT: return AM_KEY_RALT;
    case _KEY_RCTRL: return AM_KEY_RCTRL;
    case _KEY_SPACE: return AM_KEY_SPACE;

    case _KEY_UP: return AM_KEY_UP;
    case _KEY_DOWN: return AM_KEY_DOWN;
    case _KEY_LEFT: return AM_KEY_LEFT;
    case _KEY_RIGHT: return AM_KEY_RIGHT;
    case _KEY_INSERT: return AM_KEY_INSERT;
    case _KEY_DELETE: return AM_KEY_DELETE;
    case _KEY_HOME: return AM_KEY_HOME;
    case _KEY_END: return AM_KEY_END;
    case _KEY_PAGEUP: return AM_KEY_PAGEUP;
    case _KEY_PAGEDOWN: return AM_KEY_PAGEDOWN;

    case _KEY_LGUI:
    case _KEY_RGUI:
      return AM_KEY_APPLICATION;

    default:
      return AM_KEY_NONE;
  }
}

void __am_input_keybrd(AM_INPUT_KEYBRD_T *kbd) {
  uint8_t keycode = KBD_RD();

  if (keycode == _KEY_NONE) {
    kbd->keydown = false;
    kbd->keycode = AM_KEY_NONE;
    return;
  }

  bool down = (keycode & _KEYID_BREAK_MASK) == 0;
  uint8_t keyid = keycode & ~_KEYID_BREAK_MASK;
  int am_key = key_id_to_am_key(keyid);

  if (am_key == AM_KEY_NONE) {
    kbd->keydown = false;
    kbd->keycode = AM_KEY_NONE;
    return;
  }

  kbd->keydown = down;
  kbd->keycode = am_key;
}
