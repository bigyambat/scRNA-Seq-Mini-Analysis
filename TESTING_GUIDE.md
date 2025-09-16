# Testing Guide for scRNA-Seq Pipeline

This guide shows you how to test each component of the pipeline to ensure everything works correctly.

## Prerequisites

1. **Activate the conda environment:**
   ```bash
   conda activate scrna-mini
   ```

2. **Check Python dependencies:**
   ```bash
   python3 --version
   ```

## Testing Steps

### 1. Test Configuration Parser

First, let's test if the configuration parser works:

```bash
# Test basic config reading
python3 scripts/parse_config.py config/config.yaml cellranger.version

# Test nested config reading
python3 scripts/parse_config.py config/config.yaml datasets.tenx.sample_name

# Test boolean values
python3 scripts/parse_config.py config/config.yaml cellranger.local.enabled
```

**Expected output:**
- `7.2.0`
- `pbmc_10k_v3`
- `True`

### 2. Test Environment Detection

Test the environment detection and setup:

```bash
# Test current configuration
./scripts/switch_environment.sh

# Test switching to HPC mode
./scripts/switch_environment.sh hpc

# Test switching back to local mode
./scripts/switch_environment.sh local
```

### 3. Test CellRanger Setup

Test the CellRanger setup script:

```bash
# Test setup (will show "not found" if CellRanger not installed - this is expected)
./scripts/setup_cellranger.sh
```

**Expected behavior:**
- Shows current configuration
- Detects environment (HPC vs local)
- Shows appropriate error message if CellRanger not installed

### 4. Test HPC Job Script (if on HPC)

If you're on an HPC system:

```bash
# Test HPC job submission (dry run)
./scripts/submit_cellranger_hpc.sh test_job

# Check if job script was created
ls -la job_test_job.sh
```

### 5. Test Data Download

Test the data download functionality:

```bash
# Test data download script
./scripts/download_data.sh
```

**Note:** This will download the 10X PBMC dataset (~5GB), so only run if you have space and bandwidth.

### 6. Test Full Pipeline (Dry Run)

Test the complete pipeline without actually running CellRanger:

```bash
# Test the main run script (will fail at CellRanger step if not installed)
./scripts/run_all.sh
```

## Troubleshooting

### Common Issues

1. **"ModuleNotFoundError: No module named 'yaml'"**
   - Solution: The custom parser doesn't need PyYAML, this shouldn't happen

2. **"CellRanger not found"**
   - Expected if CellRanger not installed
   - Install CellRanger 7.2.0 or use HPC mode

3. **"Permission denied"**
   - Solution: Make scripts executable:
     ```bash
     chmod +x scripts/*.sh
     ```

4. **"No such file or directory"**
   - Solution: Run from project root directory:
     ```bash
     cd /path/to/scRNA-Seq-Mini-Analysis
     ```

### Testing on Different Systems

#### Local Machine
```bash
# Switch to local mode
./scripts/switch_environment.sh local

# Test setup
./scripts/setup_cellranger.sh
```

#### HPC System
```bash
# Switch to HPC mode
./scripts/switch_environment.sh hpc

# Test setup
./scripts/setup_cellranger.sh

# Submit test job
./scripts/submit_cellranger_hpc.sh test_run
```

## Validation Checklist

- [ ] Configuration parser works
- [ ] Environment switching works
- [ ] Setup script detects environment correctly
- [ ] HPC job script creates valid job file (if on HPC)
- [ ] Data download works (optional)
- [ ] All scripts are executable
- [ ] No Python import errors

## Next Steps

Once testing passes:

1. **For Local Users:** Install CellRanger 7.2.0
2. **For HPC Users:** Submit the job script
3. **Run Full Analysis:** Execute the complete pipeline

## Quick Test Command

Run this single command to test everything:

```bash
echo "=== Testing Configuration Parser ===" && \
python3 scripts/parse_config.py config/config.yaml cellranger.version && \
echo "=== Testing Environment Detection ===" && \
./scripts/switch_environment.sh && \
echo "=== Testing CellRanger Setup ===" && \
./scripts/setup_cellranger.sh && \
echo "=== All Tests Complete ==="
```
