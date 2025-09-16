#
# Copyright (c) 2020 10x Genomics, Inc. All rights reserved.
#
# Source this file before running.
#
# Determine path to this script; resolve symlinks
SOURCE="${BASH_SOURCE[0]}"
while [ -h "$SOURCE" ]; do
    DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
    SOURCE="$(readlink "$SOURCE")"
    [[ $SOURCE != /* ]] && SOURCE="$DIR/$SOURCE"
done
DIR="$( cd -P "$( dirname "$SOURCE" )" > /dev/null && pwd )"
#
# Source user's own environment first.
#
# Only source .bashrc if we're being sourced from shell10x script.
# Otherwise, we could end up in an infinite loop if user is
# sourcing this file from their .bashrc.
# Note: .bash_profile is for login shells only.
if [ ! -z $_RUN10X ] && [ -e ~/.bashrc ]; then
    source ~/.bashrc
fi
#
# Modify the prompt to indicate user is in 10X environment.
#
if [ ! -z $_10X_MODPROMPT ]; then
    ORIG_PROMPT=$PS1
    PREFIX=$TENX_PRODUCT
    if [ ! -z $_10XDEV_BRANCH_PROMPT ]; then
        command -v git >/dev/null 2>&1 || { echo >&2 "Error: git is required but not found."; exit 1; }
        PREFIX="10X:\`pushd $(echo $MROPATH | cut -d : -f1) > /dev/null;git rev-parse --abbrev-ref HEAD;popd > /dev/null\`"
    fi
    export PS1="\[\e[0;34m\]$PREFIX\[\e[m\]>$ORIG_PROMPT"
fi
#
# Set aside environment variables if they may conflict with 10X environment
#

if [ -z "$_TENX_LD_LIBRARY_PATH" ]; then
    export _TENX_LD_LIBRARY_PATH="$LD_LIBRARY_PATH"
    export LD_LIBRARY_PATH=""
fi

#
# Unset environment variables if they may conflict with 10X environment
#

if [ ! -z "$_CONDA_PYTHON_SYSCONFIGDATA_NAME" ]; then
    unset _CONDA_PYTHON_SYSCONFIGDATA_NAME
fi

if [ ! -z "$_PYTHON_SYSCONFIGDATA_NAME" ]; then
    unset _PYTHON_SYSCONFIGDATA_NAME
fi

if [ ! -z "$CDPATH" ]; then
    unset CDPATH
fi

if [ ! -z "$PYTHONPATH" ]; then
    unset PYTHONPATH
fi

if [ ! -z "$PYTHONHOME" ]; then
    unset PYTHONHOME
fi

if [ ! -z "$LC_ALL" ]; then
    unset LC_ALL
fi

if [ ! -z "$LC_COLLATE" ]; then
    unset LC_COLLATE
fi

if [ ! -z "$LD_PRELOAD" ]; then
    unset LD_PRELOAD
fi

if [ ! -z "$MROPATH" ]; then
    unset MROPATH
fi

if [ ! -z "$MPLCONFIGDIR" ]; then
    unset MPLCONFIGDIR
fi

#
# Add module binary paths to PATH
#

if [ -z "$PATH" ]; then
    export PATH="$DIR/bin"
else
    export PATH="$DIR/bin:$PATH"
fi

if [ -z "$PATH" ]; then
    export PATH="$DIR/bin/tenkit"
else
    export PATH="$DIR/bin/tenkit:$PATH"
fi

if [ -z "$PATH" ]; then
    export PATH="$DIR/external/anaconda/bin"
else
    export PATH="$DIR/external/anaconda/bin:$PATH"
fi

if [ -z "$PATH" ]; then
    export PATH="$DIR/external/martian/bin"
else
    export PATH="$DIR/external/martian/bin:$PATH"
fi

if [ -z "$PATH" ]; then
    export PATH="$DIR/lib/bin"
else
    export PATH="$DIR/lib/bin:$PATH"
fi

if [ -z "$PYTHONPATH" ]; then
    export PYTHONPATH="$DIR/external/martian/adapters/python"
else
    export PYTHONPATH="$DIR/external/martian/adapters/python:$PYTHONPATH"
fi

if [ -z "$PYTHONPATH" ]; then
    export PYTHONPATH="$DIR/lib/python"
else
    export PYTHONPATH="$DIR/lib/python:$PYTHONPATH"
fi

if [ -z "$MROPATH" ]; then
    export MROPATH="$DIR/mro"
else
    export MROPATH="$DIR/mro:$MROPATH"
fi

#
# Module-specific env vars
#
export HDF5_USE_FILE_LOCKING="FALSE"
export LANG="C"
export LC_CTYPE="en_US.UTF-8"
export MKL_CBWR="COMPATIBLE"
export NPY_DISABLE_CPU_FEATURES="AVX512F"
export PYTHONNOUSERSITE="1"
export RUST_BACKTRACE="1"

