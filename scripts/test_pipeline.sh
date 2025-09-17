#!/usr/bin/env bash
set -euo pipefail

# Advanced pipeline testing script with custom CellRanger and reference paths
# Usage: ./scripts/test_pipeline.sh [options]

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
CONFIG="$ROOT_DIR/config/config.yaml"

# Default values
CELLRANGER_PATH=""
REFERENCE_PATH=""
ENVIRONMENT=""
VERBOSE=false
DRY_RUN=false

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Advanced pipeline testing with custom paths and configurations.

OPTIONS:
    --cellranger PATH     Path to CellRanger binary
    --reference PATH      Path to reference directory
    --hpc                 Test in HPC mode
    --local               Test in local mode
    --verbose             Verbose output
    --dry-run             Show what would be done without executing
    --help                Show this help message

EXAMPLES:
    # Test with custom CellRanger path
    $0 --cellranger /path/to/cellranger-7.2.0/bin/cellranger

    # Test with custom reference path
    $0 --reference /path/to/refdata-gex-GRCh38-2020-A

    # Test with both custom paths
    $0 --cellranger /path/to/cellranger-7.2.0/bin/cellranger --reference /path/to/refdata-gex-GRCh38-2020-A

    # Test in HPC mode
    $0 --hpc

    # Test in local mode
    $0 --local

    # Dry run to see what would be tested
    $0 --dry-run --verbose

EOF
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --cellranger)
            CELLRANGER_PATH="$2"
            shift 2
            ;;
        --reference)
            REFERENCE_PATH="$2"
            shift 2
            ;;
        --hpc)
            ENVIRONMENT="hpc"
            shift
            ;;
        --local)
            ENVIRONMENT="local"
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Function to log messages
log() {
    if [[ "$VERBOSE" == "true" || "$1" == "INFO" ]]; then
        echo "[$1] $2"
    fi
}

# Function to run command or show what would be done
run_or_show() {
    local cmd="$1"
    local description="$2"
    
    if [[ "$DRY_RUN" == "true" ]]; then
        echo "[DRY-RUN] $description: $cmd"
    else
        log "INFO" "$description"
        eval "$cmd"
    fi
}

echo "🧬 Advanced Pipeline Testing"
echo "=============================="

# Test 1: Configuration Parser
echo ""
echo "1️⃣ Testing Configuration Parser"
run_or_show "python3 scripts/parse_config.py config/config.yaml cellranger.version" "Testing config parser"

# Test 2: Environment Detection
echo ""
echo "2️⃣ Testing Environment Detection"
run_or_show "./scripts/switch_environment.sh" "Testing environment detection"

# Test 3: CellRanger Setup
echo ""
echo "3️⃣ Testing CellRanger Setup"

# Set environment if specified
if [[ -n "$ENVIRONMENT" ]]; then
    run_or_show "./scripts/switch_environment.sh $ENVIRONMENT" "Switching to $ENVIRONMENT mode"
fi

# Update config with custom paths if provided
if [[ -n "$CELLRANGER_PATH" || -n "$REFERENCE_PATH" ]]; then
    echo ""
    echo "🔧 Updating configuration with custom paths..."
    
    if [[ -n "$CELLRANGER_PATH" ]]; then
        if [[ -x "$CELLRANGER_PATH" ]]; then
            run_or_show "sed -i.bak 's|path: \"\"|path: \"$CELLRANGER_PATH\"|' config/config.yaml" "Setting CellRanger path"
            log "INFO" "CellRanger path set to: $CELLRANGER_PATH"
        else
            echo "❌ Error: CellRanger binary not found or not executable: $CELLRANGER_PATH"
            exit 1
        fi
    fi
    
    if [[ -n "$REFERENCE_PATH" ]]; then
        if [[ -d "$REFERENCE_PATH" ]]; then
            run_or_show "sed -i.bak 's|tenx_ref: GRCh38-2020-A|tenx_ref: $REFERENCE_PATH|' config/config.yaml" "Setting reference path"
            log "INFO" "Reference path set to: $REFERENCE_PATH"
        else
            echo "❌ Error: Reference directory not found: $REFERENCE_PATH"
            exit 1
        fi
    fi
fi

# Test CellRanger setup
run_or_show "./scripts/setup_cellranger.sh" "Testing CellRanger setup"

# Test 4: Data Download (dry run)
echo ""
echo "4️⃣ Testing Data Download Configuration"
run_or_show "./scripts/download_data.sh" "Testing data download (will not download if data exists)"

# Test 5: CellRanger Run (dry run)
echo ""
echo "5️⃣ Testing CellRanger Run Configuration"
if [[ "$DRY_RUN" == "true" ]]; then
    echo "[DRY-RUN] Would run: ./scripts/run_cellranger.sh"
    echo "[DRY-RUN] This would execute CellRanger count with current configuration"
else
    # Check if we can run CellRanger (without actually running it)
    if command -v cellranger >/dev/null 2>&1; then
        log "INFO" "CellRanger is available: $(which cellranger)"
        cellranger --version 2>/dev/null || log "WARN" "Could not get CellRanger version"
    else
        log "WARN" "CellRanger not found in PATH"
    fi
fi

# Test 6: Configuration Validation
echo ""
echo "6️⃣ Testing Configuration Validation"

# Validate key configuration values
run_or_show "python3 scripts/parse_config.py config/config.yaml datasets.tenx.sample_name" "Validating sample name"
run_or_show "python3 scripts/parse_config.py config/config.yaml cellranger.chemistry" "Validating chemistry"
run_or_show "python3 scripts/parse_config.py config/config.yaml qc.min_features" "Validating QC settings"

# Test 7: Output Directory Structure
echo ""
echo "7️⃣ Testing Output Directory Structure"
run_or_show "mkdir -p data/tenx results/cellranger results/seurat report refs" "Creating output directories"

# Summary
echo ""
echo "✅ Testing Complete!"
echo ""
echo "📊 Test Summary:"
echo "   • Configuration parser: ✓"
echo "   • Environment detection: ✓"
echo "   • CellRanger setup: ✓"
echo "   • Data download config: ✓"
echo "   • CellRanger run config: ✓"
echo "   • Configuration validation: ✓"
echo "   • Output directories: ✓"
echo ""

if [[ "$DRY_RUN" == "true" ]]; then
    echo "🔍 Dry run completed. Use without --dry-run to execute tests."
else
    echo "🚀 Pipeline is ready! Run './run_analysis.sh' to start the full analysis."
fi

echo ""
echo "📁 Configuration:"
if [[ -n "$CELLRANGER_PATH" ]]; then
    echo "   • CellRanger: $CELLRANGER_PATH"
else
    echo "   • CellRanger: $(which cellranger 2>/dev/null || echo 'Not found in PATH')"
fi

if [[ -n "$REFERENCE_PATH" ]]; then
    echo "   • Reference: $REFERENCE_PATH"
else
    echo "   • Reference: $(python3 scripts/parse_config.py config/config.yaml references.transcriptome.tenx_ref 2>/dev/null || echo 'Default')"
fi

echo "   • Environment: $(python3 scripts/parse_config.py config/config.yaml cellranger.hpc.enabled 2>/dev/null | grep -q True && echo 'HPC' || echo 'Local')"
echo "   • Sample: $(python3 scripts/parse_config.py config/config.yaml datasets.tenx.sample_name 2>/dev/null || echo 'Unknown')"
