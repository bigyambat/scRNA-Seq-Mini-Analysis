#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"
DATA_DIR="$ROOT_DIR/data"
REF_DIR="$ROOT_DIR/refs"
RESULTS_DIR="$ROOT_DIR/results"

mkdir -p "$DATA_DIR/tenx" "$DATA_DIR/isoform" "$REF_DIR" "$RESULTS_DIR"

echo "[data] Parsing config for URLs"

tenx_url=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['datasets']['tenx']['urls'][0])
PY
"$CONFIG")

tenx_frac=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['datasets']['tenx']['downsample_fraction'])
PY
"$CONFIG")

iso_enabled=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(str(cfg['datasets']['isoform']['enabled']).lower())
PY
"$CONFIG")

iso_url=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['datasets']['isoform']['urls'][0])
PY
"$CONFIG") || true

ref_url=$(python - <<'PY'
import sys, yaml
cfg=yaml.safe_load(open(sys.argv[1]))
print(cfg['references']['transcriptome']['url'])
PY
"$CONFIG")

echo "[data] Downloading 10x fastqs"
cd "$DATA_DIR/tenx"
if [[ ! -f fastqs.tar ]]; then
  curl -L "$tenx_url" -o fastqs.tar
fi
if [[ ! -d fastqs ]]; then
  mkdir -p fastqs
  tar -xf fastqs.tar -C fastqs --strip-components=1 || tar -xf fastqs.tar -C fastqs || true
fi

echo "[data] Optional downsampling (seqtk) to fraction $tenx_frac"
if [[ ! -d fastqs_ds ]]; then
  mkdir -p fastqs_ds
  for fq in fastqs/*.fastq.gz fastqs/*_R1_*.gz fastqs/*_R2_*.gz; do
    [[ -e "$fq" ]] || continue
    base=$(basename "$fq")
    if [[ ! -f fastqs_ds/$base ]]; then
      zcat "$fq" | seqtk sample -s100 - "$tenx_frac" | gzip -c > fastqs_ds/$base
    fi
  done
fi

echo "[data] Downloading 10x reference (may be large)"
cd "$REF_DIR"
if [[ ! -f refdata.tar.gz ]]; then
  curl -L "$ref_url" -o refdata.tar.gz
fi
if [[ ! -d refdata-gex ]]; then
  mkdir -p refdata-gex
  tar -xf refdata.tar.gz -C refdata-gex --strip-components=1 || tar -xf refdata.tar.gz -C refdata-gex || true
fi

echo "[data] Isoform dataset enabled=$iso_enabled"
if [[ "$iso_enabled" == "true" ]]; then
  cd "$DATA_DIR/isoform"
  if [[ "$iso_url" != "" && ! -f reads.fastq.gz ]]; then
    curl -L "$iso_url" -o reads.fastq.gz || true
  fi
fi

echo "[data] Data download complete"


