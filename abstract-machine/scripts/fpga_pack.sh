#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ] || [ "$#" -gt 4 ]; then
  echo "Usage: $0 <elf> <imem_hex> <dmem_hex> [objcopy]" >&2
  exit 1
fi

elf="$1"
imem_hex="$2"
dmem_hex="$3"
objcopy_bin="${4:-${OBJCOPY:-riscv32-unknown-elf-objcopy}}"

if [ ! -f "$elf" ]; then
  echo "ELF not found: $elf" >&2
  exit 1
fi

tmp_verilog=$(mktemp)
trap 'rm -f "$tmp_verilog"' EXIT

"$objcopy_bin" -O verilog "$elf" "$tmp_verilog"

: > "$imem_hex"
: > "$dmem_hex"

awk -v IMEM_OUT="$imem_hex" -v DMEM_OUT="$dmem_hex" '
function flush_code_word(  i) {
  if (code_n == 0) return;
  while (code_n < 4) {
    code_b[code_n] = "00";
    code_n++;
  }
  printf("%s%s%s%s\n", code_b[3], code_b[2], code_b[1], code_b[0]) >> IMEM_OUT;
  code_n = 0;
}

BEGIN {
  region = 0;   # 1: code, 2: data
  code_n = 0;
}

{
  for (i = 1; i <= NF; i++) {
    tok = $i;
    gsub("\r", "", tok);

    if (tok ~ /^@/) {
      flush_code_word();

      addr = strtonum("0x" substr(tok, 2));
      if (addr < 0x01000000) {
        region = 1;
        printf("@%08x\n", int(addr / 4)) >> IMEM_OUT;
      } else {
        region = 2;
        printf("@%08x\n", addr - 0x01000000) >> DMEM_OUT;
      }
      continue;
    }

    if (region == 1) {
      code_b[code_n] = tok;
      code_n++;
      if (code_n == 4) {
        printf("%s%s%s%s\n", code_b[3], code_b[2], code_b[1], code_b[0]) >> IMEM_OUT;
        code_n = 0;
      }
    } else if (region == 2) {
      printf("%s\n", tok) >> DMEM_OUT;
    }
  }
}

END {
  flush_code_word();
}
' "$tmp_verilog"
