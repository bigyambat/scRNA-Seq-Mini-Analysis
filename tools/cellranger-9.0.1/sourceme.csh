#
# Copyright (c) 2020 10x Genomics, Inc. All rights reserved.
#
# Source this file before running.
#
set SOURCE=($_)
if ( "$SOURCE" != "" ) then
    set SOURCE=`readlink -f "$SOURCE[2]"`
else
    set SOURCE=`readlink -f "$0"`
endif
set DIR=`dirname $SOURCE`
#
# Source user's own environment first.
#
# Note .login is for login shells only.
source ~/.cshrc
#
# Modify the prompt to indicate user is in 10X environment.
#

#
# Set aside environment variables if they may conflict with 10X environment
#

if ( ! $?_TENX_LD_LIBRARY_PATH ) then
    setenv _TENX_LD_LIBRARY_PATH "$LD_LIBRARY_PATH"
    setenv LD_LIBRARY_PATH ""
endif

#
# Unset environment variables if they may conflict with 10X environment
#

if ( $?_CONDA_PYTHON_SYSCONFIGDATA_NAME ) then
    unsetenv _CONDA_PYTHON_SYSCONFIGDATA_NAME
endif

if ( $?_PYTHON_SYSCONFIGDATA_NAME ) then
    unsetenv _PYTHON_SYSCONFIGDATA_NAME
endif

if ( $?CDPATH ) then
    unsetenv CDPATH
endif

if ( $?PYTHONPATH ) then
    unsetenv PYTHONPATH
endif

if ( $?PYTHONHOME ) then
    unsetenv PYTHONHOME
endif

if ( $?LC_ALL ) then
    unsetenv LC_ALL
endif

if ( $?LC_COLLATE ) then
    unsetenv LC_COLLATE
endif

if ( $?LD_PRELOAD ) then
    unsetenv LD_PRELOAD
endif

if ( $?MROPATH ) then
    unsetenv MROPATH
endif

if ( $?MPLCONFIGDIR ) then
    unsetenv MPLCONFIGDIR
endif

#
# Add module binary paths to PATH
#

if ( ! $?PATH ) then
    setenv PATH "$DIR/bin"
else
    setenv PATH "$DIR/bin:$PATH"
endif

if ( ! $?PATH ) then
    setenv PATH "$DIR/bin/tenkit"
else
    setenv PATH "$DIR/bin/tenkit:$PATH"
endif

if ( ! $?PATH ) then
    setenv PATH "$DIR/external/anaconda/bin"
else
    setenv PATH "$DIR/external/anaconda/bin:$PATH"
endif

if ( ! $?PATH ) then
    setenv PATH "$DIR/external/martian/bin"
else
    setenv PATH "$DIR/external/martian/bin:$PATH"
endif

if ( ! $?PATH ) then
    setenv PATH "$DIR/lib/bin"
else
    setenv PATH "$DIR/lib/bin:$PATH"
endif

if ( ! $?PYTHONPATH ) then
    setenv PYTHONPATH "$DIR/external/martian/adapters/python"
else
    setenv PYTHONPATH "$DIR/external/martian/adapters/python:$PYTHONPATH"
endif

if ( ! $?PYTHONPATH ) then
    setenv PYTHONPATH "$DIR/lib/python"
else
    setenv PYTHONPATH "$DIR/lib/python:$PYTHONPATH"
endif

if ( ! $?MROPATH ) then
    setenv MROPATH "$DIR/mro"
else
    setenv MROPATH "$DIR/mro:$MROPATH"
endif

#
# Module-specific env vars
#
setenv HDF5_USE_FILE_LOCKING "FALSE"
setenv LANG "C"
setenv LC_CTYPE "en_US.UTF-8"
setenv MKL_CBWR "COMPATIBLE"
setenv NPY_DISABLE_CPU_FEATURES "AVX512F"
setenv PYTHONNOUSERSITE "1"
setenv RUST_BACKTRACE "1"

