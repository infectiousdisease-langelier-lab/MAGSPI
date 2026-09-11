#!/bin/bash
#SBATCH --job-name=gtdbtk_3518
#SBATCH --output=gtdbtk_%j.out
#SBATCH --error=gtdbtk_%j.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=512G
#SBATCH --time=72:00:00

# Load necessary modules or activate conda environment
module load anaconda
conda activate gtdbtk 
export GTDBTK_DATA_PATH=/hpc/reference/seq_databases/microbes/GTDB_Tk_db/release226

# Set input and output paths
INPUT_DIR=/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool/Extracted_MAGs_all
OUTPUT_DIR=/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool/MAG_taxonomy/all_3518

# Run GTDB-Tk
gtdbtk classify_wf \
  --genome_dir $INPUT_DIR \
  --out_dir $OUTPUT_DIR \
  --cpus 64 \
  --extension .fa \
  --skip_ani_screen

