#!/usr/bin/env bash
set -euo pipefail

# HPC job submission script for CellRanger
# Usage: ./submit_cellranger_hpc.sh [job_name]

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"

# Function to get config values
get_config() {
    local key="$1"
    python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "$key"
}

# Get job parameters
JOB_NAME="${1:-pbmc_cellranger}"
MODULE_NAME=$(get_config "cellranger.hpc.module_name")
JOB_MEMORY=$(get_config "cellranger.hpc.job_memory")
JOB_CPUS=$(get_config "cellranger.hpc.job_cpus")
JOB_TIME=$(get_config "cellranger.hpc.job_time")

echo "=== HPC Job Submission ==="
echo "Job Name: $JOB_NAME"
echo "Module: $MODULE_NAME"
echo "Memory: $JOB_MEMORY"
echo "CPUs: $JOB_CPUS"
echo "Time: $JOB_TIME"

# Create job script
JOB_SCRIPT="$ROOT_DIR/job_${JOB_NAME}.sh"

cat > "$JOB_SCRIPT" << EOF
#!/bin/bash
#SBATCH --job-name=$JOB_NAME
#SBATCH --output=$ROOT_DIR/logs/${JOB_NAME}_%j.out
#SBATCH --error=$ROOT_DIR/logs/${JOB_NAME}_%j.err
#SBATCH --time=$JOB_TIME
#SBATCH --mem=$JOB_MEMORY
#SBATCH --cpus-per-task=$JOB_CPUS
#SBATCH --partition=standard

# Load modules
module load $MODULE_NAME

# Set up environment
cd $ROOT_DIR

# Create logs directory
mkdir -p logs

# Run CellRanger
echo "Starting CellRanger analysis at \$(date)"
echo "Job ID: \$SLURM_JOB_ID"
echo "Node: \$SLURM_NODELIST"
echo "CPUs: \$SLURM_CPUS_PER_TASK"
echo "Memory: \$SLURM_MEM_PER_NODE"

# Run the analysis
$ROOT_DIR/scripts/run_cellranger.sh

echo "CellRanger analysis completed at \$(date)"
EOF

# Make job script executable
chmod +x "$JOB_SCRIPT"

# Submit job
echo "Submitting job..."
if command -v sbatch >/dev/null 2>&1; then
    JOB_ID=$(sbatch "$JOB_SCRIPT" | awk '{print $4}')
    echo "✓ Job submitted successfully!"
    echo "  Job ID: $JOB_ID"
    echo "  Job script: $JOB_SCRIPT"
    echo ""
    echo "To check job status:"
    echo "  squeue -j $JOB_ID"
    echo ""
    echo "To view job output:"
    echo "  tail -f $ROOT_DIR/logs/${JOB_NAME}_${JOB_ID}.out"
    echo "  tail -f $ROOT_DIR/logs/${JOB_NAME}_${JOB_ID}.err"
elif command -v qsub >/dev/null 2>&1; then
    JOB_ID=$(qsub "$JOB_SCRIPT")
    echo "✓ Job submitted successfully!"
    echo "  Job ID: $JOB_ID"
    echo "  Job script: $JOB_SCRIPT"
    echo ""
    echo "To check job status:"
    echo "  qstat $JOB_ID"
else
    echo "✗ No job scheduler found (sbatch or qsub)"
    echo "Please run the job script manually: $JOB_SCRIPT"
fi
