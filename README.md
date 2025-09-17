## scRNA-Seq Mini Analysis (FASTQ → counts → QC → clustering → annotation → trajectory → isoform)

This repo provides a fast, end-to-end, reproducible pipeline using Cell Ranger, Seurat (R), and FLAIR.

### 🚀 One-Command Analysis

**Run complete analysis with a single command:**

```bash
./run_analysis.sh
```

This will analyze the [10X Genomics PBMC dataset](https://www.10xgenomics.com/datasets/pbmcs-3p_heparin_sepmate-3-1-standard) (~3,663 cells) and generate a comprehensive HTML report.

### 🧪 Test the Pipeline

**Quick test (basic components):**
```bash
./scripts/test_pipeline.sh
```

**Advanced test with custom paths:**
```bash
# Test with custom CellRanger binary
./scripts/test_pipeline.sh --cellranger /path/to/cellranger-7.2.0/bin/cellranger

# Test with custom reference directory
./scripts/test_pipeline.sh --reference /path/to/refdata-gex-GRCh38-2020-A

# Test both custom paths
./scripts/test_pipeline.sh --cellranger /path/to/cellranger-7.2.0/bin/cellranger --reference /path/to/refdata-gex-GRCh38-2020-A

# Dry run to see what would be tested
./scripts/test_pipeline.sh --dry-run --verbose
```

### Quick start (alternative commands)

**Complete Analysis (Recommended):**
```bash
./run_analysis.sh
```

**Manual Pipeline:**
```bash
bash scripts/run_all.sh
```

The `run_analysis.sh` script provides a complete analysis experience:
- **Interactive setup**: Tests pipeline components and asks for confirmation
- **Comprehensive analysis**: Downloads data, runs CellRanger, performs Seurat analysis
- **Progress tracking**: Shows what's happening at each step
- **Results summary**: Displays where to find outputs and how to view them

**Manual pipeline** (`scripts/run_all.sh`) runs all tasks end-to-end:
- Download 10X PBMC dataset and references
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

## Setup and Testing

### CellRanger Setup

The pipeline supports both HPC and local environments with automatic detection:

```bash
# Test and setup CellRanger environment
./scripts/setup_cellranger.sh

# Switch between environments
./scripts/switch_environment.sh hpc    # For HPC systems
./scripts/switch_environment.sh local  # For local systems
```

### Testing the Pipeline

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

### Advanced Testing with Custom Paths

Test with custom CellRanger binary and reference paths:

```bash
# Test with custom CellRanger path
./scripts/test_pipeline.sh --cellranger /path/to/cellranger-7.2.0/bin/cellranger

# Test with custom reference path
./scripts/test_pipeline.sh --reference /path/to/refdata-gex-GRCh38-2020-A

# Test with both custom paths
./scripts/test_pipeline.sh --cellranger /path/to/cellranger-7.2.0/bin/cellranger --reference /path/to/refdata-gex-GRCh38-2020-A

# Test with HPC mode
./scripts/test_pipeline.sh --hpc

# Test with local mode
./scripts/test_pipeline.sh --local
```

For detailed testing instructions, see `TESTING_GUIDE.md`.

## Configuration Options

### FASTQ Input Options

You can configure different datasets in `config/config.yaml`:

```yaml
datasets:
  tenx:
    # Use your own FASTQ files
    local_fastq_dir: "/path/to/your/fastqs"  # Set this to use local FASTQs
    # OR use remote dataset
    urls:
      - https://cf.10xgenomics.com/samples/cell-exp/3.0.0/pbmc_10k_v3/pbmc_10k_v3_fastqs.tar
    downsample_fraction: 1.0  # Downsample to keep FASTQs ≤2GB
    sample_name: pbmc_heparin_sepmate
```

### Output Directory Settings

```yaml
# Customize output directories
output_dirs:
  data: "data"           # Raw data storage
  results: "results"     # Analysis results
  report: "report"       # HTML reports
  refs: "refs"          # Reference genomes
```

### Quality Control Filtering

```yaml
qc:
  min_features: 200      # Minimum genes per cell
  max_mt_percent: 15     # Maximum mitochondrial gene percentage
  n_hvgs: 2000          # Number of highly variable genes
  min_cells: 3          # Minimum cells expressing a gene
  max_genes: 5000       # Maximum genes per cell (remove doublets)
```

### CellRanger Settings

```yaml
cellranger:
  chemistry: auto        # Auto-detect or specify (e.g., "SC3Pv3")
  localcores: 6         # Number of CPU cores
  localmem: 32          # Memory in GB
  # HPC settings
  hpc:
    enabled: false
    module_name: "cellranger/7.2.0"
    job_memory: "32G"
    job_cpus: 6
    job_time: "4:00:00"
```

### Dataset Information

**Primary Dataset:** [PBMCs from Heparin-Treated Blood Collection Tubes Isolated via SepMate-Ficoll Gradient](https://www.10xgenomics.com/datasets/pbmcs-3p_heparin_sepmate-3-1-standard)

- **Source**: 10X Genomics official dataset
- **Cells detected**: 3,663 PBMCs
- **Median genes per cell**: 1,886
- **Median UMIs per cell**: 6,685
- **Chemistry**: 3' v3.1 (Dual Index)
- **Sequencing**: Illumina NovaSeq 6000
- **Donor**: Healthy female
- **License**: Creative Commons Attribution 4.0 International (CC BY 4.0)

### Dataset Options

**Option A: Use Your Own FASTQ Files**
```yaml
datasets:
  tenx:
    local_fastq_dir: "/path/to/your/fastqs"  # Set this to use local FASTQs
    downsample_fraction: 1.0  # Adjust to keep FASTQs ≤2GB
```

**Option B: Use Remote Datasets**
- **Primary**: [10X PBMC dataset](https://www.10xgenomics.com/datasets/pbmcs-3p_heparin_sepmate-3-1-standard) (3,663 cells)
- **Alternative**: Any small 10X dataset with <5k cells
- **Tiny datasets**: Use `downsample_fraction: 0.2` to keep FASTQs ≤2GB

### Isoform Analysis Options

**Option A (Preferred)**: Full-length single-cell dataset
```yaml
isoform:
  enabled: true
  mode: "full_length"
  urls:
    - https://example.org/smartseq2_tiny.fastq.gz
  read_type: smartseq2
```

**Option B (Fallback)**: Limited analysis with 10X data
```yaml
isoform:
  enabled: true
  mode: "10x_fallback"  # Acknowledges 3' bias limitations
  loci: ["LMNA", "PTPRC", "CD3D", "CD19", "MS4A1", "CD14"]
```

**Note**: Option B performs limited splicing/isoform exploration acknowledging 3′ bias and discusses limitations in the report.

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


