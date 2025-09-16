#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)

echo "[run_all] Starting end-to-end pipeline"

# 1) Data (FASTQs + reference)
bash "$ROOT_DIR/scripts/runtime.sh" "data" bash "$ROOT_DIR/scripts/download_data.sh"

# 2) Cell Ranger (Docker fallback if needed)
bash "$ROOT_DIR/scripts/runtime.sh" "cellranger" bash "$ROOT_DIR/scripts/run_cellranger.sh"

# 3) Seurat (QC, clustering, annotation, trajectory)
bash "$ROOT_DIR/scripts/runtime.sh" "seurat" bash "$ROOT_DIR/scripts/run_seurat.sh"

# 4) Report (HTML)
bash "$ROOT_DIR/scripts/runtime.sh" "report" bash "$ROOT_DIR/scripts/build_report.sh"

# 5) Isoform (optional; script will no-op if disabled/missing)
bash "$ROOT_DIR/scripts/runtime.sh" "flair" bash "$ROOT_DIR/scripts/run_flair.sh" || true

echo "[run_all] Done. See report/report.html and results/"


