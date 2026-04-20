#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <app_dir> [make_args...]" >&2
  echo "Example: $0 ./am_kernel/myterm" >&2
  exit 1
fi

script_dir=$(cd "$(dirname "$0")" && pwd)
am_home=$(cd "$script_dir/.." && pwd)
app_dir="$1"
shift || true

if [ ! -d "$app_dir" ]; then
  echo "App directory not found: $app_dir" >&2
  exit 1
fi

# Clean app build outputs first to avoid incremental app artifacts.
make -C "$app_dir" ARCH=fpga MYCPU_AM_HOME="$am_home" clean "$@"
make -C "$app_dir" ARCH=fpga MYCPU_AM_HOME="$am_home" update_fpga "$@"


echo "DONE: images updated to $(cd "$am_home/../fpga" && pwd)/{Test_8_Instr.dat,prog1.hex,prog1_word.hex}"
