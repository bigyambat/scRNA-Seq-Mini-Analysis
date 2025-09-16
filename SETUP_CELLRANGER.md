# CellRanger 7.2.0 Setup Guide

This guide explains how to set up CellRanger 7.2.0 for both HPC and local environments.

## Quick Start

### For HPC Users
1. Enable HPC mode in config:
   ```bash
   # Edit config/config.yaml
   cellranger:
     hpc:
       enabled: true
   ```

2. Submit job:
   ```bash
   ./scripts/submit_cellranger_hpc.sh
   ```

### For Local Users
1. Install CellRanger 7.2.0:
   ```bash
   # Download from 10X Genomics
   wget https://cf.10xgenomics.com/releases/cell-exp/cellranger-7.2.0.tar.gz
   tar -xzf cellranger-7.2.0.tar.gz
   export PATH=$PATH:$(pwd)/cellranger-7.2.0/bin
   ```

2. Run analysis:
   ```bash
   ./scripts/run_cellranger.sh
   ```

## Configuration

### HPC Configuration
```yaml
cellranger:
  hpc:
    enabled: true
    module_name: "cellranger/7.2.0"  # Module to load
    job_memory: "32G"
    job_cpus: 6
    job_time: "4:00:00"
```

### Local Configuration
```yaml
cellranger:
  local:
    enabled: true
    path: ""  # Leave empty for PATH, or specify full path
```

## Environment Detection

The setup script automatically detects your environment:

- **HPC**: Detects `module` command and loads specified module
- **Local**: Uses system PATH or specified path

## Troubleshooting

### CellRanger Not Found
```bash
# Check if CellRanger is in PATH
which cellranger

# Check version
cellranger --version

# Run setup script
./scripts/setup_cellranger.sh
```

### HPC Module Issues
```bash
# Check available modules
module avail cellranger

# Load module manually
module load cellranger/7.2.0

# Check if loaded
module list
```

### Local Installation Issues
1. Download CellRanger 7.2.0 from 10X Genomics
2. Extract and add to PATH:
   ```bash
   export PATH=$PATH:/path/to/cellranger-7.2.0/bin
   ```
3. Or specify full path in config.yaml

## Data Requirements

- **Reference**: GRCh38-2020-A (will be downloaded automatically)
- **Data**: 10X PBMC 10k v3 dataset
- **Storage**: ~10GB for reference, ~5GB for data, ~20GB for results

## Output

Results will be saved to `results/cellranger/pbmc_10k_v3/`:
- `outs/filtered_feature_bc_matrix/` - Gene expression matrix
- `outs/web_summary.html` - QC report
- `outs/metrics_summary.csv` - Summary metrics
