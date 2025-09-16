#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"
DATA_DIR="$ROOT_DIR/data/tenx"
REF_DIR="$ROOT_DIR/refs/refdata-gex"
OUT_DIR="$ROOT_DIR/results/cellranger"

mkdir -p "$OUT_DIR"

# Source the setup script to configure CellRanger
echo "[cellranger] Setting up CellRanger environment..."
source "$ROOT_DIR/scripts/setup_cellranger.sh"

# Check if CellRanger is available
if ! command -v cellranger >/dev/null 2>&1; then
    echo "✗ CellRanger not available after setup"
    echo "Please run: $ROOT_DIR/scripts/setup_cellranger.sh"
    exit 1
fi

echo "[cellranger] Using CellRanger: $(which cellranger)"

sample=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.tenx.sample_name")
chem=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.chemistry")
cores=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.localcores")
mem=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.localmem")

FASTQ_DIR="$DATA_DIR/fastqs_ds"
[[ -d "$FASTQ_DIR" ]] || FASTQ_DIR="$DATA_DIR/fastqs"

echo "[cellranger] Running count for $sample"
cd "$OUT_DIR"

# Run CellRanger count
echo "[cellranger] Running count for $sample"
echo "  Sample: $sample"
echo "  Chemistry: $chem"
echo "  Cores: $cores"
echo "  Memory: $mem GB"
echo "  Reference: $REF_DIR"
echo "  FASTQ directory: $FASTQ_DIR"

cellranger count \
  --id="${sample}" \
  --transcriptome="$REF_DIR" \
  --fastqs="$FASTQ_DIR" \
  --sample="$sample" \
  --chemistry="$chem" \
  --localcores="$cores" \
  --localmem="$mem"

echo "[cellranger] Done"


