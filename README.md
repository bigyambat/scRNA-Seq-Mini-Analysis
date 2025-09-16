## scRNA-Seq Mini Analysis (FASTQ → counts → QC → clustering → annotation → trajectory → isoform)

This repo provides a fast, end-to-end, reproducible pipeline using Cell Ranger, Seurat (R), and FLAIR.

### Quick start (single command)

```bash
bash scripts/run_all.sh
```

This single tool runs all tasks end-to-end:
- Download tiny public FASTQs (configurable) and references
- Optionally downsample reads to stay ≤2 GB total
- Run Cell Ranger to generate counts
- Run Seurat QC, clustering, annotation, and simple trajectory
- Run a tiny FLAIR isoform demo on a small full-length dataset (or 10x-limited fallback)
- Render a concise HTML report with figures

### Requirements

- Linux or macOS with Conda/Mamba, GNU Make, and 40–60 GB free disk (temporary Cell Ranger/ref files)
- Cell Ranger 7.2.0 (see setup instructions below)

### Environment Setup

#### 1. Create Conda Environment

```bash
mamba env create -f environment.yml
conda activate scrna-mini
```

#### 2. CellRanger Setup

The pipeline supports both HPC and local environments:

**For HPC Users:**
```bash
# Switch to HPC mode
./scripts/switch_environment.sh hpc

# Submit job
./scripts/submit_cellranger_hpc.sh
```

**For Local Users:**
```bash
# Install CellRanger 7.2.0
wget https://cf.10xgenomics.com/releases/cell-exp/cellranger-7.2.0.tar.gz
tar -xzf cellranger-7.2.0.tar.gz
export PATH=$PATH:$(pwd)/cellranger-7.2.0/bin

# Switch to local mode
./scripts/switch_environment.sh local

# Run analysis
./scripts/run_cellranger.sh
```

**Automatic Detection:**
The pipeline automatically detects your environment and configures CellRanger accordingly.

See `SETUP_CELLRANGER.md` for detailed setup instructions.

## Testing the Pipeline

Before running the full analysis, test the pipeline components:

```bash
# Quick test of all components
echo "=== Testing Configuration Parser ===" && \
python3 scripts/parse_config.py config/config.yaml cellranger.version && \
echo "=== Testing Environment Detection ===" && \
./scripts/switch_environment.sh && \
echo "=== Testing CellRanger Setup ===" && \
./scripts/setup_cellranger.sh && \
echo "=== All Tests Complete ==="
```

**Expected Results:**
- Configuration parser: `7.2.0`
- Environment detection: Shows current HPC/Local mode
- CellRanger setup: Detects environment and shows appropriate message

For detailed testing instructions, see `TESTING_GUIDE.md`.

### Data provenance

Exact dataset URLs are defined in `config/config.yaml` and mirrored in `data/data_links.txt`.

- Core 10x dataset: 10X PBMC 10k v3 dataset from public archives (full dataset for comprehensive analysis)
- Isoform dataset (preferred): a very small Smart‑seq2/long‑read single‑cell set (20–100 cells)
- Fallback (if only 10x): limited splicing/isoform exploration acknowledging 3′ bias

You may update the URLs in `config/config.yaml` to use any equally small public dataset.

### Alternative

You can also use Make targets if you prefer:

```bash
make all    # same as scripts/run_all.sh
```

Runtime notes (wall-clock and peak RAM) are logged to `results/runtime.log` and summarized in the report.

### Outputs

- `results/cellranger/` matrices
- `results/seurat/` RDS object and figures
- `results/flair/` isoform tables and locus plots
- `report/report.html`

### Configuration

See `config/config.yaml` for:
- Dataset URLs
- Optional downsampling fractions
- Reference genome/gtf (small GRCh38 subset for speed where possible)
- Cell Ranger sample/run IDs
- QC thresholds for Seurat

### Limitations & Notes

- This is a minimal, resource-light screen. Results are for demonstration.
- Trajectory is a simple, defensible approach implemented entirely in Seurat to avoid heavy extra deps.
- FLAIR demo is kept tiny by restricting to a small dataset and optionally to a single chromosome locus.

### License

Code is MIT. Do not commit raw reads. Cell Ranger is subject to 10x Genomics license.


