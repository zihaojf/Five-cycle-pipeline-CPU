#include <klib.h>
#include <klib-macros.h>
#include <stdint.h>

#define loop1(op) op;
#define loop2(op) loop1(op); loop1(op);
#define loop4(op) loop2(loop2(op));
#define loop8(op) loop2(loop4(op));


#if !defined(__ISA_NATIVE__) || defined(__NATIVE_USE_KLIB__)

size_t strlen(const char *s) {
  size_t res=0;
  for(;*s;s++)res++;
  return res;
}

char *strcpy(char *dst, const char *src) {
  char *res = dst;
  while(*src){
    *(dst++)=*(src++);
  };
  *dst='\0';
  return res;
}

char *strncpy(char *dst, const char *src, size_t n) {
  char *res = dst;
  while(n && *src) {
    *(dst++)=*(src++); 
    n--;
  }
  while(n--) *(dst++) = '\0';
  return res;
}

char *strcat(char *dst, const char *src) {
  char *res = dst;
  while(*dst) dst++;
  while(*src) {
    *dst = *src;
    dst++;
    src++;
  }
  *dst = '\0';
  return res;
}

int strcmp(const char *s1, const char *s2) {
  while(*s1 && *s2){
    if(*s1 != *s2)return *s1 - *s2;
    s1++, s2++;
  }
  return *s1 - *s2;
}

int strncmp(const char *s1, const char *s2, size_t n) {
  while(n && *s1 && *s2){
    if(*s1 != *s2)return *s1 - *s2;
    s1++, s2++;
    n--;
  }
  return *s1 - *s2;
}

void *memset(void *s, int c, size_t n) {
  if((size_t)s & 0x3){
    unsigned char *ptr = s;
    while (n--)*(ptr++) = (char)c;
    return s;
  }
  uint8_t *pcs = s;
  // while(n){
  //   *(pcs++) = c; 
  //   n--;
  // }
  uint32_t data = c & 0xff;
  size_t un_align = n & 0x3;
  n >>= 2;
  data = data | (data << 8);
  data = data | (data << 16);
  if(n & 1) {
    *(uint32_t *)pcs = data, pcs += 4;
  } //4bytes
  n >>= 1;
  if(n & 1) {
    loop2(*(uint32_t *)pcs = data; pcs += 4;);
  } //8bytes
  n >>= 1;
  if(n & 1) {
    loop4(*(uint32_t *)pcs = data; pcs += 4;);
  } //16bytes
  n >>= 1;
  while(n) {
    loop8(*(uint32_t *)pcs = data; pcs += 4;);
    n--;
  } //32bytes
  //uint32_t datab = c & 0xff;
  //, datal = datab | (datab << 8);
  if(un_align & 0x2) {
    *(uint16_t *)pcs = data, pcs += 2;
  } //2bytes
  if(un_align & 0x1) {
    *(uint8_t *)pcs = data, pcs += 1;
  } //1byte
  return s;
}

void *memmove(void *dst, const void *src, size_t n) {
  char *pcdst = dst;
  const char *pcsrc = src;
  if(dst < src){
    while(n--) {*(pcdst++) = *(pcsrc++);}
  }else if(dst > src){
    pcdst += n - 1;
    pcsrc += n - 1; 
    while(n--) {*(pcdst--) = *(pcsrc--);}
  }
  return dst;
}

void *memcpy(void *out, const void *in, size_t n) {
  if((((size_t)out) & 0x3) != 0 || (((size_t)in) & 0x3) != 0){
    char *pcout = out;
    const char *pcin = in;
    while(n--) {*(pcout++) = *(pcin++);}
    return out;
  }
  uint8_t *pcout = (uint8_t *)out;
  const uint8_t *pcin = (uint8_t *)in;
  size_t un_align = n & 0x3;
  n >>= 2;
  if(n & 1) {
    *(uint32_t *)pcout = *(uint32_t *)pcin;
    pcout += 4; pcin += 4;
  } //4bytes
  n >>= 1;
  if(n & 1) {
    loop2(
      *(uint32_t *)pcout = *(uint32_t *)pcin;
      pcout += 4; pcin += 4;
    );
  } //8bytes
  n >>= 1;
  if(n & 1) {
    loop4(
      *(uint32_t *)pcout = *(uint32_t *)pcin;
      pcout += 4; pcin += 4;
    );
  } //16bytes
  n >>= 1;
  while(n) {
    loop8(
      *(uint32_t *)pcout = *(uint32_t *)pcin;
      pcout += 4; pcin += 4;
    );
    n--;
  } //32bytes
  if(un_align & 0x2) {
    *(uint16_t *)pcout = *(uint16_t *)pcin;
    pcout += 2; pcin += 2;
  } //2bytes
  if(un_align & 0x1) {
    *(uint8_t *)pcout = *(uint8_t *)pcin;
    pcout += 1; pcin += 1;
  } //1byte
  return out;
}

int memcmp(const void *s1, const void *s2, size_t n) {
  const char *p1 = (const char *)s1;
  const char *p2 = (const char *)s2;
  while(n--) {
    if(*p1 != *p2) return *p1 - *p2;
    p1++;
    p2++;
  }
  return 0;
}

char *strchr(const char *s, int c) {
  do {
    if (*s == c) return (char *)s;
    if (*s == '\0') break;
    s ++;
  } while (1);
  return NULL;
}

char *strrchr(const char *s, int c) {
  const char *p = s + strlen(s) + 1;
  do {
    if (*p == c) return (char *)p;
    if (s == p) break;
    p --;
  } while (1);
  return NULL;
}

#endif
