#include <klib.h>
#include <limits.h>

#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

typedef void (*emit_ch_fn)(char ch, void *ctx);

typedef struct {
  char *out;
  size_t n;
  size_t pos;
} str_ctx_t;

// Keep formatter arithmetic in machine word size.
// On fpga(rv32), this avoids slow/problematic 64-bit div/mod in printf path.
typedef unsigned long fmt_u_t;
typedef long fmt_s_t;

static void emit_console(char ch, void *ctx) {
  (void)ctx;
  putch(ch);
}

static void emit_string(char ch, void *ctx) {
  str_ctx_t *s = (str_ctx_t *)ctx;
  if (s->n == 0) {
    s->pos++;
    return;
  }
  if (s->pos + 1 < s->n) {
    s->out[s->pos] = ch;
  }
  s->pos++;
}

static int emit_repeat(emit_ch_fn emit, void *ctx, char ch, int cnt) {
  int i;
  for (i = 0; i < cnt; i++) emit(ch, ctx);
  return cnt;
}

static int utoa_base(fmt_u_t v, unsigned base, char *buf, int lowercase) {
  static const char *digits_l = "0123456789abcdef";
  static const char *digits_u = "0123456789ABCDEF";
  const char *digits = lowercase ? digits_l : digits_u;
  char tmp[sizeof(fmt_u_t) * 8];
  int i = 0, j;
  if (v == 0) {
    buf[0] = '0';
    return 1;
  }
  while (v > 0) {
    tmp[i++] = digits[v % base];
    v /= base;
  }
  for (j = 0; j < i; j++) {
    buf[j] = tmp[i - 1 - j];
  }
  return i;
}

static int format_signed(fmt_s_t sv, char *buf) {
  if (sv == 0) {
    buf[0] = '0';
    return 1;
  }
  if (sv < 0) {
    fmt_u_t uv;
    int n;
    uv = (fmt_u_t)(-(sv + 1));
    uv += 1;
    buf[0] = '-';
    n = utoa_base(uv, 10, buf + 1, 1);
    return n + 1;
  }
  return utoa_base((fmt_u_t)sv, 10, buf, 1);
}

static int kformat(emit_ch_fn emit, void *ctx, const char *fmt, va_list ap) {
  int written = 0;
  while (*fmt) {
    char ch = *fmt++;
    if (ch != '%') {
      emit(ch, ctx);
      written++;
      continue;
    }

    // Flags
    int flag_plus = 0;
    int flag_left = 0;
    char pad = ' ';
    while (*fmt == '+' || *fmt == '-' || *fmt == '0') {
      if (*fmt == '+') flag_plus = 1;
      else if (*fmt == '-') flag_left = 1;
      else if (*fmt == '0') pad = '0';
      fmt++;
    }

    // Width
    int width = 0;
    while (*fmt >= '0' && *fmt <= '9') {
      width = width * 10 + (*fmt - '0');
      fmt++;
    }

    // Length (support a single 'l')
    int long_flag = 0;
    if (*fmt == 'l') {
      long_flag = 1;
      fmt++;
    }

    char spec = *fmt ? *fmt++ : '\0';
    char field[96];
    const char *str_field = NULL;
    int len = 0;

    switch (spec) {
      case 'c': {
        int v = va_arg(ap, int);
        field[0] = (char)v;
        len = 1;
        break;
      }
      case 'd': {
        fmt_s_t v = long_flag ? va_arg(ap, long) : (fmt_s_t)va_arg(ap, int);
        len = format_signed(v, field);
        if (flag_plus && v >= 0 && len < (int)sizeof(field)) {
          int i;
          for (i = len; i > 0; i--) field[i] = field[i - 1];
          field[0] = '+';
          len++;
        }
        break;
      }
      case 'u': {
        fmt_u_t v = long_flag ? va_arg(ap, unsigned long) : (fmt_u_t)va_arg(ap, unsigned);
        len = utoa_base(v, 10, field, 1);
        break;
      }
      case 'x': {
        fmt_u_t v = long_flag ? va_arg(ap, unsigned long) : (fmt_u_t)va_arg(ap, unsigned);
        len = utoa_base(v, 16, field, 1);
        break;
      }
      case 'p': {
        fmt_u_t v = (fmt_u_t)(uintptr_t)va_arg(ap, void *);
        field[0] = '0';
        field[1] = 'x';
        len = 2 + utoa_base(v, 16, field + 2, 1);
        break;
      }
      case 's': {
        const char *s = va_arg(ap, const char *);
        if (!s) s = "(null)";
        str_field = s;
        while (s[len] != '\0') len++;
        break;
      }
      case '%': {
        field[0] = '%';
        len = 1;
        break;
      }
      case '\0': {
        return written;
      }
      default: {
        // Non-fatal fallback for unsupported format specifier.
        field[0] = '%';
        field[1] = spec;
        len = 2;
        break;
      }
    }

    if (!flag_left && width > len) {
      written += emit_repeat(emit, ctx, pad, width - len);
    }
    if (str_field) {
      for (int i = 0; i < len; i++) emit(str_field[i], ctx);
    } else {
      for (int i = 0; i < len; i++) emit(field[i], ctx);
    }
    written += len;
    if (flag_left && width > len) {
      written += emit_repeat(emit, ctx, ' ', width - len);
    }
  }
  return written;
}

int vprintf(const char *fmt, va_list ap) {
  va_list aq;
  va_copy(aq, ap);
  int r = kformat(emit_console, NULL, fmt, aq);
  va_end(aq);
  return r;
}

int printf(const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vprintf(fmt, ap);
  va_end(ap);
  return r;
}

int vsnprintf(char *out, size_t n, const char *fmt, va_list ap) {
  str_ctx_t s = { .out = out, .n = n, .pos = 0 };
  va_list aq;
  va_copy(aq, ap);
  int r = kformat(emit_string, &s, fmt, aq);
  va_end(aq);
  if (n > 0) {
    size_t t = (s.pos < n) ? s.pos : (n - 1);
    out[t] = '\0';
  }
  return r;
}

int vsprintf(char *out, const char *fmt, va_list ap) {
  return vsnprintf(out, (size_t)-1, fmt, ap);
}

int snprintf(char *out, size_t n, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsnprintf(out, n, fmt, ap);
  va_end(ap);
  return r;
}

int sprintf(char *out, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsprintf(out, fmt, ap);
  va_end(ap);
  return r;
}

int puts(const char *str) {
  int n = 0;
  while (*str) {
    putch(*str++);
    n++;
  }
  putch('\n');
  return n + 1;
}

int __am_vsscanf_internal(const char *str, const char **end_pstr, const char *fmt, va_list ap) {
  const char *pstr = str;
  const char *pfmt = fmt;
  int item = -1;
  while (*pfmt) {
    char ch = *pfmt ++;
    if (isspace(ch)) {
      for (ch = *pfmt; isspace(ch); ch = *(++ pfmt));
      for (ch = *pstr; isspace(ch); ch = *(++ pstr));
      item ++;
      continue;
    }
    switch (ch) {
      case '%': break;
      default:
        if (*pstr == ch) { // match
          pstr ++;
          item ++;
          continue;
        }
        goto end; // fail
    }

    char *p;
    ch = *pfmt ++;
    switch (ch) {
      // conversion specifier
      case 'd':
        *(va_arg(ap, int *)) = strtol(pstr, &p, 10);
        if (p == pstr) goto end; // fail
        pstr = p;
        item ++;
        break;

      case 'c':
        *(va_arg(ap, char *)) = *pstr ++;
        item ++;
        break;

      default:
        printf("Unsupported conversion specifier '%c'\n", ch);
        assert(0);
    }
  }

end:
  if (end_pstr) {
    *end_pstr = pstr;
  }
  return item;
}

int vsscanf(const char *str, const char *fmt, va_list ap) {
  return __am_vsscanf_internal(str, NULL, fmt, ap);
}

int sscanf(const char *str, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsscanf(str, fmt, ap);
  va_end(ap);
  return r;
}

int __isoc99_sscanf(const char *str, const char *fmt, ...) {
  va_list ap;
  va_start(ap, fmt);
  int r = vsscanf(str, fmt, ap);
  va_end(ap);
  return r;
}

#endif
