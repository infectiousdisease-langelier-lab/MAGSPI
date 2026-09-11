#!/bin/bash
#SBATCH -J is_cmp_710mag
#SBATCH -c 32
#SBATCH --mem=256G
#SBATCH -t 48:00:00
#SBATCH --array=1-710%6
#SBATCH -o logs/%x_%A_%a.out
#SBATCH -e logs/%x_%A_%a.err

set -euo pipefail

# Activate env
# module load instrain
# or:
# source ~/.bashrc
#conda activate instrain_env

IS_LIST="IS_profiles.txt"      # 500 lines, each = path/to/sample.IS
MAG_IDS="mag_ids.txt"          # 19 lines
LIST_DIR="mag_scaffold_lists"
OUTROOT="compare_by_mag_710"

mkdir -p logs "$OUTROOT"

MAG=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$MAG_IDS")
SCAF_LIST="${LIST_DIR}/${MAG}.scaffolds.txt"
OUTDIR="${OUTROOT}/${MAG}.IS.compare"

if [[ ! -s "$SCAF_LIST" ]]; then
  echo "Empty scaffold list for $MAG; exiting"
  exit 0
fi

# Read the 500 IS profile dirs
mapfile -t IS_PROFILES < "$IS_LIST"

# Run compare restricted to this MAG
inStrain compare \
  -i "${IS_PROFILES[@]}" \
  -sc "$SCAF_LIST" \
  -p 32 \
  -o "$OUTDIR"

