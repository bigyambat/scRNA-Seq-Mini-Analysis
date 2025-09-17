#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
RMD="$ROOT_DIR/src/report.Rmd"
OUT_DIR="$ROOT_DIR/report"
mkdir -p "$OUT_DIR"

Rscript -e "rmarkdown::render('$RMD', output_file='report.html', output_dir='$OUT_DIR')"
echo "[report] Wrote $OUT_DIR/report.html"


