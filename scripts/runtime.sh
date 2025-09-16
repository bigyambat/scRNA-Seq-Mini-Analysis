#!/usr/bin/env bash
set -euo pipefail

# Usage: runtime.sh "STEP NAME" command args...
STEP="$1"; shift
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOG="$ROOT_DIR/results/runtime.log"
mkdir -p "$ROOT_DIR/results"

start=$(date +%s)
/usr/bin/env time -f "peak_ram_mb=%M" -o "$ROOT_DIR/results/.time.tmp" "$@"
end=$(date +%s)
dur=$(( end - start ))
peak=$(grep peak_ram_mb "$ROOT_DIR/results/.time.tmp" | awk -F= '{print $2}')
echo -e "${STEP}\tseconds=${dur}\tpeak_ram_mb=${peak}" | tee -a "$LOG"
rm -f "$ROOT_DIR/results/.time.tmp"


