#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"
DATA_DIR="$ROOT_DIR/data/tenx"
REF_DIR="$ROOT_DIR/refs/refdata-gex"
OUT_DIR="$ROOT_DIR/results/cellranger"

mkdir -p "$OUT_DIR"

# Prefer local cellranger if available; else fallback to Docker
USE_DOCKER=0
if ! command -v cellranger >/dev/null 2>&1; then
  if command -v docker >/dev/null 2>&1; then
    USE_DOCKER=1
    echo "[cellranger] Using Docker fallback"
  else
    echo "Cell Ranger not found and Docker unavailable. Please install one of them."
    exit 1
  fi
fi

sample=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['datasets']['tenx']['sample_name'])
PY
"$CONFIG")

chem=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['cellranger']['chemistry'])
PY
"$CONFIG")

cores=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['cellranger']['localcores'])
PY
"$CONFIG")

mem=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['cellranger']['localmem'])
PY
"$CONFIG")

FASTQ_DIR="$DATA_DIR/fastqs_ds"
[[ -d "$FASTQ_DIR" ]] || FASTQ_DIR="$DATA_DIR/fastqs"

echo "[cellranger] Running count for $sample"
cd "$OUT_DIR"

if [[ "$USE_DOCKER" == "1" ]]; then
  # Build image if missing
  IMG="cellranger:9.0.1"
  if ! docker image inspect "$IMG" >/dev/null 2>&1; then
    docker build -f "$ROOT_DIR/Dockerfile.cellranger" \
      --build-arg CR_URL="https://cf.10xgenomics.com/releases/cell-exp/cellranger-9.0.1.tar.gz" \
      -t "$IMG" "$ROOT_DIR"
  fi
  docker run --rm -u $(id -u):$(id -g) \
    -v "$ROOT_DIR":"/work" -w "/work" \
    -v "$REF_DIR":"$REF_DIR" -v "$FASTQ_DIR":"$FASTQ_DIR" \
    "$IMG" -lc "cellranger count \
      --id='${sample}' \
      --transcriptome='$REF_DIR' \
      --fastqs='$FASTQ_DIR' \
      --sample='$sample' \
      --chemistry='$chem' \
      --localcores='$cores' \
      --localmem='$mem'"
else
  cellranger count \
    --id="${sample}" \
    --transcriptome="$REF_DIR" \
    --fastqs="$FASTQ_DIR" \
    --sample="$sample" \
    --chemistry="$chem" \
    --localcores="$cores" \
    --localmem="$mem"
fi

echo "[cellranger] Done"


