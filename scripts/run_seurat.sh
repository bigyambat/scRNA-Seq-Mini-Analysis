#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
R_SCRIPT="$ROOT_DIR/src/seurat_analysis.R"

mkdir -p "$ROOT_DIR/results/seurat" "$ROOT_DIR/report"

echo "[seurat] Running Seurat analysis"
Rscript "$R_SCRIPT"
echo "[seurat] Done"


