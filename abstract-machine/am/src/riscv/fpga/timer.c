#include <am.h>
#include <arch/fpga.h>

// Use millisecond counter as the time base for AM_TIMER_UPTIME on FPGA.
// Some boards show unstable/too-fast CLK_US behavior under heavy MMIO load,
// while CLK_MS is stable enough for gameplay pacing.
static uint32_t last_ms32 = 0;
static uint32_t ms_wrap_hi = 0;

void __am_timer_init() {
  last_ms32 = inl(CLK_MS_ADDR);
  ms_wrap_hi = 0;
}

void __am_timer_uptime(AM_TIMER_UPTIME_T *uptime) {
  uint32_t now_ms = inl(CLK_MS_ADDR);
  if (now_ms < last_ms32) {
    ms_wrap_hi++;
  }
  last_ms32 = now_ms;
  uptime->us = ((((uint64_t)ms_wrap_hi << 32) | now_ms) * 1000ull);
}

void __am_timer_rtc(AM_TIMER_RTC_T *rtc) {
  rtc->second = 0;
  rtc->minute = 0;
  rtc->hour   = 0;
  rtc->day    = 0;
  rtc->month  = 0;
  rtc->year   = 1900;
}
