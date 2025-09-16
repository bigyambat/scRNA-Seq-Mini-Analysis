SHELL := /bin/bash

.PHONY: all env data cellranger seurat flair report clean

all: env data cellranger seurat flair report

env:
	@echo "[env] Creating/activating conda env scrna-mini"
	@mamba env create -f environment.yml || true
	@echo "Activate with: conda activate scrna-mini"

data:
	@bash scripts/download_data.sh

cellranger:
	@bash scripts/runtime.sh "cellranger" bash scripts/run_cellranger.sh

seurat:
	@bash scripts/runtime.sh "seurat" bash scripts/run_seurat.sh

flair:
	@bash scripts/runtime.sh "flair" bash scripts/run_flair.sh

report:
	@bash scripts/runtime.sh "report" bash scripts/build_report.sh

clean:
	rm -rf results/cellranger/*/outs
	rm -rf results/flair/tmp
	find results -name "*.tmp" -delete


