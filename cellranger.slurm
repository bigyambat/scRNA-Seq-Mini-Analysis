#!/bin/bash
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=64GB
#SBATCH --time=8:00:00
#SBATCH --partition=epyc-64

module purge
module load gcc/13.3.0 openmpi/5.0.5 cellranger/9.0.1



#module load legacy/CentOS7
#module load conda/24.3.0
#module load gcc/11.3.0

# Initializing mamba
#mamba init bash
#source ~/.bashrc

# Make conda available in batch jobs
source /spack/conda/miniforge3/24.3.0/etc/profile.d/conda.sh

# Activate environment
conda activate scrna-mini

# Switch environment to HPC
./scripts/switch_environment.sh hpc

/project2/weisenbe_1344/test-data/scRNA-Seq-Mini-Analysis/run_analysis.sh

