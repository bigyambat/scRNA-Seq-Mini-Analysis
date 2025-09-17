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
    echo "ERROR: CellRanger not available after setup"
    echo "Please run: $ROOT_DIR/scripts/setup_cellranger.sh"
    exit 1
fi

echo "[cellranger] Using CellRanger: $(which cellranger)"

sample=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.tenx.sample_name")
chem=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.chemistry")
cores=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.localcores")
mem=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.localmem")
# CellRanger 9.0.1 requires explicit --create-bam flag
create_bam_raw=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.create_bam" 2>/dev/null || echo "False")
if [[ "$create_bam_raw" == "True" || "$create_bam_raw" == "true" ]]; then
    create_bam="true"
elif [[ "$create_bam_raw" == "False" || "$create_bam_raw" == "false" ]]; then
    create_bam="false"
else
    # default
    create_bam="false"
fi

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
echo "  Create BAM: $create_bam"

cellranger count \
  --id="${sample}" \
  --create-bam "$create_bam" \
  --transcriptome="$REF_DIR" \
  --fastqs="$FASTQ_DIR" \
  --sample="$sample" \
  --chemistry="$chem" \
  --localcores="$cores" \
  --localmem="$mem"

echo "[cellranger] Done"


