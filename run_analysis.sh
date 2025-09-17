#!/usr/bin/env bash
set -euo pipefail

# Single command to run complete scRNA-Seq analysis
# PBMCs from Heparin-Treated Blood Collection Tubes Isolated via SepMate-Ficoll Gradient
# Dataset: https://www.10xgenomics.com/datasets/pbmcs-3p_heparin_sepmate-3-1-standard

ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Starting Complete scRNA-Seq Analysis"
echo "Dataset: PBMCs from Heparin-Treated Blood Collection Tubes"
echo "Source: https://www.10xgenomics.com/datasets/pbmcs-3p_heparin_sepmate-3-1-standard"
echo "Expected: ~3,663 cells, 1,886 median genes/cell, 6,685 median UMIs/cell"
echo ""

# Check if conda environment is activated
if [[ -z "${CONDA_DEFAULT_ENV:-}" ]]; then
    echo "WARNING: Conda environment not detected"
    echo "   Please run: conda activate scrna-mini"
    echo ""
fi

# Test pipeline components first
echo "Testing pipeline components..."
echo "=== Testing Configuration Parser ===" && \
python3 scripts/parse_config.py config/config.yaml cellranger.version && \
echo "=== Testing Environment Detection ===" && \
./scripts/switch_environment.sh hpc && \
echo "=== Testing CellRanger Setup ===" && \
./scripts/setup_cellranger.sh && \
echo "All tests passed!"
echo ""

# Run complete analysis
echo "Starting complete analysis pipeline..."
echo "   This will:"
echo "   - Download 10X PBMC dataset (~5GB)"
echo "   - Download reference genome (~10GB)"
echo "   - Run CellRanger count analysis"
echo "   - Perform Seurat QC, clustering, and annotation"
echo "   - Generate comprehensive HTML report"
echo ""

# Ask for confirmation
#read -p "Continue? (y/N): " -n 1 -r
#echo
#if [[ ! $REPLY =~ ^[Yy]$ ]]; then
#    echo "Analysis cancelled"
#    exit 0
#fi

# Run the complete pipeline
echo "Running analysis pipeline..."
bash scripts/run_all.sh

echo ""
echo "Analysis Complete!"
echo ""
echo "Results available in:"
echo "   - results/cellranger/ - CellRanger output"
echo "   - results/seurat/ - Seurat analysis results"
echo "   - report/report.html - Comprehensive HTML report"
echo ""
echo "View results:"
echo "   open report/report.html"
echo ""
echo "Dataset Information:"
echo "   - Source: https://www.10xgenomics.com/datasets/pbmcs-3p_heparin_sepmate-3-1-standard"
echo "   - Cells: ~3,663 PBMCs"
echo "   - Chemistry: 3' v3.1"
echo "   - Sequencing: Illumina NovaSeq 6000"
