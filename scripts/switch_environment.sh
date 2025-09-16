#!/usr/bin/env bash
set -euo pipefail

# Environment switcher for CellRanger
# Usage: ./switch_environment.sh [hpc|local]

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"

ENVIRONMENT="${1:-}"

if [[ -z "$ENVIRONMENT" ]]; then
    echo "Usage: $0 [hpc|local]"
    echo ""
    echo "Current configuration:"
    HPC_ENABLED=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.hpc.enabled")
    LOCAL_ENABLED=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.local.enabled")
    echo "HPC mode: $HPC_ENABLED"
    echo "Local mode: $LOCAL_ENABLED"
    exit 1
fi

case "$ENVIRONMENT" in
    hpc|HPC)
        echo "Switching to HPC mode..."
        # Update config to enable HPC mode
        sed -i.bak 's/enabled: false  # Set to true when running on HPC/enabled: true  # Set to true when running on HPC/' "$CONFIG"
        sed -i.bak 's/enabled: true  # Set to true when using local installation/enabled: false  # Set to true when using local installation/' "$CONFIG"
        echo "✓ HPC mode enabled"
        echo "✓ Local mode disabled"
        echo ""
        echo "HPC configuration:"
        MODULE_NAME=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.hpc.module_name")
        JOB_MEMORY=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.hpc.job_memory")
        JOB_CPUS=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.hpc.job_cpus")
        JOB_TIME=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.hpc.job_time")
        echo "  Module: $MODULE_NAME"
        echo "  Memory: $JOB_MEMORY"
        echo "  CPUs: $JOB_CPUS"
        echo "  Time: $JOB_TIME"
        echo ""
        echo "To submit job: ./scripts/submit_cellranger_hpc.sh"
        ;;
    local|LOCAL)
        echo "Switching to local mode..."
        # Update config to enable local mode
        sed -i.bak 's/enabled: true  # Set to true when running on HPC/enabled: false  # Set to true when running on HPC/' "$CONFIG"
        sed -i.bak 's/enabled: false  # Set to true when using local installation/enabled: true  # Set to true when using local installation/' "$CONFIG"
        echo "✓ Local mode enabled"
        echo "✓ HPC mode disabled"
        echo ""
        echo "Local configuration:"
        LOCAL_PATH=$(python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "cellranger.local.path")
        if [[ -z "$LOCAL_PATH" ]]; then
            LOCAL_PATH="System PATH"
        fi
        echo "  Path: $LOCAL_PATH"
        echo ""
        echo "To run analysis: ./scripts/run_cellranger.sh"
        ;;
    *)
        echo "Error: Invalid environment '$ENVIRONMENT'"
        echo "Usage: $0 [hpc|local]"
        exit 1
        ;;
esac
