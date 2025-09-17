#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"
DATA_DIR="$ROOT_DIR/data"
REF_DIR="$ROOT_DIR/refs"
RESULTS_DIR="$ROOT_DIR/results"

mkdir -p "$DATA_DIR/tenx" "$DATA_DIR/isoform" "$REF_DIR" "$RESULTS_DIR"

echo "[data] Parsing config for URLs"

# Check if using local FASTQ files
local_fastq_dir=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.tenx.local_fastq_dir" 2>/dev/null || echo "")

if [[ -n "$local_fastq_dir" && -d "$local_fastq_dir" ]]; then
    echo "[data] Using local FASTQ files from: $local_fastq_dir"
    tenx_url=""
    # Copy local FASTQs
    cp -r "$local_fastq_dir"/* "$DATA_DIR/tenx/fastqs/" 2>/dev/null || true
else
    tenx_url=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.tenx.urls" | head -1)
fi

tenx_frac=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.tenx.downsample_fraction")
iso_enabled=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.isoform.enabled")
iso_mode=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.isoform.mode" 2>/dev/null || echo "full_length")
iso_url=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "datasets.isoform.urls" 2>/dev/null | head -1 || echo "")
ref_url=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "references.transcriptome.url")

echo "[data] Processing 10x fastqs"
cd "$DATA_DIR/tenx"

if [[ -n "$tenx_url" ]]; then
    echo "[data] Downloading 10x fastqs from remote URL"
    if [[ ! -f fastqs.tar ]]; then
        curl -L "$tenx_url" -o fastqs.tar
    fi
    if [[ ! -d fastqs ]]; then
        mkdir -p fastqs
        tar -xf fastqs.tar -C fastqs --strip-components=1 || tar -xf fastqs.tar -C fastqs || true
    fi
else
    echo "[data] Using local FASTQ files"
    if [[ ! -d fastqs ]]; then
        mkdir -p fastqs
    fi
fi

echo "[data] Optional downsampling (seqtk) to fraction $tenx_frac"
if [[ ! -d fastqs_ds ]]; then
  mkdir -p fastqs_ds
    if [[ "$tenx_frac" == "1.0" ]]; then
      echo "[data] No downsampling needed (fraction=1.0), copying original files"
      cp fastqs/*.fastq.gz fastqs_ds/ 2>/dev/null || true
      cp fastqs/*_R1_*.gz fastqs_ds/ 2>/dev/null || true
      cp fastqs/*_R2_*.gz fastqs_ds/ 2>/dev/null || true
    else
      echo "[data] Downsampling to fraction $tenx_frac"
      for fq in fastqs/*.fastq.gz fastqs/*_R1_*.gz fastqs/*_R2_*.gz; do
        [[ -e "$fq" ]] || continue
        base=$(basename "$fq")
        if [[ ! -f fastqs_ds/$base ]]; then
          zcat "$fq" | seqtk sample -s100 - "$tenx_frac" | gzip -c > fastqs_ds/$base
        fi
    done
  fi
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

echo "[data] Isoform analysis enabled=$iso_enabled, mode=$iso_mode"
if [[ "$iso_enabled" == "True" ]]; then
  cd "$DATA_DIR/isoform"
  if [[ "$iso_mode" == "full_length" && -n "$iso_url" && ! -f reads.fastq.gz ]]; then
    echo "[data] Downloading full-length isoform dataset"
    curl -L "$iso_url" -o reads.fastq.gz || true
  elif [[ "$iso_mode" == "10x_fallback" ]]; then
    echo "[data] Using 10x data for limited isoform analysis (Option B)"
    echo "[data] Will analyze junction usage and transcript-end differences"
  fi
fi

echo "[data] Data download complete"


