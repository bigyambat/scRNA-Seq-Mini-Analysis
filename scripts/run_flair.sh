#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"
ISO_DIR="$ROOT_DIR/data/isoform"
REF_FA=$(python - <<'PY'
import sys,yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['flair']['genome_fa'])
PY
"$CONFIG")
GTF=$(python - <<'PY'
import sys,yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['flair']['gtf'])
PY
"$CONFIG")
THREADS=$(python - <<'PY'
import sys,yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['flair']['threads'])
PY
"$CONFIG")

OUT_DIR="$ROOT_DIR/results/flair"
TMP_DIR="$OUT_DIR/tmp"
mkdir -p "$OUT_DIR" "$TMP_DIR"

reads="$ISO_DIR/reads.fastq.gz"
if [[ ! -f "$reads" ]]; then
  echo "[flair] No isoform reads found. Skipping (see README for Option B fallback)."
  exit 0
fi

if [[ ! -f "$REF_FA" || ! -f "$GTF" ]]; then
  echo "[flair] Missing genome or GTF in refs/. Please supply small GRCh38 subset."
  exit 0
fi

echo "[flair] Aligning with minimap2"
minimap2 -t "$THREADS" -ax splice -uf --secondary=no "$REF_FA" "$reads" | samtools sort -@ "$THREADS" -o "$TMP_DIR/reads.bam"
samtools index "$TMP_DIR/reads.bam"

echo "[flair] Running FLAIR collapse and quantify"
flair collapse -g "$REF_FA" -q "$TMP_DIR/reads.bam" -r "$reads" -f "$GTF" -o "$OUT_DIR/flair"
flair quantify -r "$reads" -i "$OUT_DIR/flair.isoforms.fa" -t "$THREADS" -o "$OUT_DIR/flair"

echo "[flair] Done"


