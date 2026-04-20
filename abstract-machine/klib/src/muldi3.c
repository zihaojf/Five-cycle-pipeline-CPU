#include <stdint.h>

typedef int64_t di_int;
typedef uint64_t du_int;
typedef uint32_t su_int;

static inline du_int mul_u32_u32(su_int a, su_int b) {
  su_int a0 = a & 0xffffu;
  su_int a1 = a >> 16;
  su_int b0 = b & 0xffffu;
  su_int b1 = b >> 16;

  du_int p0 = (du_int)(a0 * b0);
  du_int p1 = (du_int)(a0 * b1);
  du_int p2 = (du_int)(a1 * b0);
  du_int p3 = (du_int)(a1 * b1);

  return p0 + ((p1 + p2) << 16) + (p3 << 32);
}

// Minimal compiler-rt compatible helper for RV32 builds without libgcc.
di_int __muldi3(di_int a, di_int b) {
  du_int ua = (du_int)a;
  du_int ub = (du_int)b;

  su_int a_lo = (su_int)ua;
  su_int a_hi = (su_int)(ua >> 32);
  su_int b_lo = (su_int)ub;
  su_int b_hi = (su_int)(ub >> 32);

  du_int lo = mul_u32_u32(a_lo, b_lo);
  du_int cross = mul_u32_u32(a_lo, b_hi) + mul_u32_u32(a_hi, b_lo);

  return (di_int)(lo + (cross << 32));
}

