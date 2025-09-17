#!/usr/bin/env bash
set -euo pipefail

# Usage: runtime.sh "STEP NAME" command args...
STEP="$1"; shift
ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
LOG="$ROOT_DIR/results/runtime.log"
mkdir -p "$ROOT_DIR/results"

start=$(date +%s)

# Try different time command options for HPC compatibility
if command -v time >/dev/null 2>&1; then
    # Try GNU time with format string
    if time -f "peak_ram_mb=%M" -o "$ROOT_DIR/results/.time.tmp" "$@" 2>/dev/null; then
        peak=$(grep peak_ram_mb "$ROOT_DIR/results/.time.tmp" | awk -F= '{print $2}')
        rm -f "$ROOT_DIR/results/.time.tmp"
    else
        # Fallback: run command without time tracking
        echo "Warning: time command not available, running without memory tracking"
        "$@"
        peak="unknown"
    fi
else
    # No time command available, run without tracking
    echo "Warning: time command not found, running without memory tracking"
    "$@"
    peak="unknown"
fi

end=$(date +%s)
dur=$(( end - start ))
echo -e "${STEP}\tseconds=${dur}\tpeak_ram_mb=${peak}" | tee -a "$LOG"


