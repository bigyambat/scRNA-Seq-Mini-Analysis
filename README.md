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
- Cell Ranger binary (see below). We do not redistribute it. Place it on PATH.

### Environment

Create the pinned environment with mamba/conda:

```bash
mamba env create -f environment.yml
conda activate scrna-mini
```

Additionally, install Cell Ranger (pinned):

1) Download Cell Ranger 7.2.0 from 10x Genomics and extract.
2) Add `cellranger-7.2.0` to your PATH, e.g.:

```bash
export PATH=/opt/cellranger-7.2.0:$PATH
```

The pipeline will verify availability with `cellranger --version`.

### Data provenance

Exact dataset URLs are defined in `config/config.yaml` and mirrored in `data/data_links.txt`.

- Core 10x dataset: a tiny PBMC 1k/3k-like set from public archives (FASTQs ≤2 GB after optional downsampling)
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


