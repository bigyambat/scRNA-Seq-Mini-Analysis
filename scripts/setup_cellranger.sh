#!/usr/bin/env bash
set -euo pipefail

# Setup script for CellRanger 7.2.0
# Handles both HPC and local environments

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"

# Function to get config values
get_config() {
    local key="$1"
    python3 "$ROOT_DIR/scripts/parse_config.py" "$CONFIG" "$key"
}

# Get configuration
CELLRANGER_VERSION=$(get_config "cellranger.version")
HPC_ENABLED=$(get_config "cellranger.hpc.enabled")
LOCAL_ENABLED=$(get_config "cellranger.local.enabled")
LOCAL_PATH=$(get_config "cellranger.local.path")

echo "=== CellRanger 7.2.0 Setup ==="
echo "Version: $CELLRANGER_VERSION"
echo "HPC Mode: $HPC_ENABLED"
echo "Local Mode: $LOCAL_ENABLED"

# Check if running on HPC
if command -v module >/dev/null 2>&1; then
    echo "HPC environment detected (module command available)"
    IS_HPC=true
else
    echo "Local environment detected"
    IS_HPC=false
fi

# Setup based on environment
if [[ "$IS_HPC" == "true" && "$HPC_ENABLED" == "True" ]]; then
    echo "Setting up for HPC environment..."
    
    # Load CellRanger module
    MODULE_NAME=$(get_config "cellranger.hpc.module_name")
    echo "Loading module: $MODULE_NAME"
    
    if module load "$MODULE_NAME" 2>/dev/null; then
        echo "Module $MODULE_NAME loaded successfully"
    else
        echo "ERROR: Failed to load module $MODULE_NAME"
        echo "Please check if the module is available: module avail cellranger"
        exit 1
    fi
    
    # Verify CellRanger is available
    if command -v cellranger >/dev/null 2>&1; then
        echo "CellRanger is available: $(which cellranger)"
        cellranger --version
    else
        echo "ERROR: CellRanger not found after loading module"
        exit 1
    fi
    
elif [[ "$LOCAL_ENABLED" == "True" ]]; then
    echo "Setting up for local environment..."
    
    # Check if CellRanger is in PATH
    if command -v cellranger >/dev/null 2>&1; then
        echo "CellRanger found in PATH: $(which cellranger)"
        cellranger --version
    elif [[ -n "$LOCAL_PATH" && -x "$LOCAL_PATH" ]]; then
        echo "CellRanger found at specified path: $LOCAL_PATH"
        "$LOCAL_PATH" --version
        # Add to PATH for this session
        export PATH="$(dirname "$LOCAL_PATH"):$PATH"
    else
        echo "ERROR: CellRanger not found"
        echo "Please either:"
        echo "1. Install CellRanger and add it to your PATH, or"
        echo "2. Set the full path in config.yaml under cellranger.local.path"
        echo ""
        echo "To install CellRanger 7.2.0:"
        echo "1. Download from: https://support.10xgenomics.com/single-cell-gene-expression/software/downloads/latest"
        echo "2. Extract and add to PATH:"
        echo "   export PATH=\$PATH:/path/to/cellranger-7.2.0/bin"
        exit 1
    fi
    
else
    echo "ERROR: Neither HPC nor local mode is enabled"
    echo "Please enable either cellranger.hpc.enabled or cellranger.local.enabled in config.yaml"
    exit 1
fi

echo ""
echo "=== CellRanger Setup Complete ==="
echo "Environment: $([ "$IS_HPC" == "true" ] && echo "HPC" || echo "Local")"
echo "CellRanger: $(which cellranger 2>/dev/null || echo "Not in PATH")"
echo "Version: $(cellranger --version 2>/dev/null || echo "Unknown")"
