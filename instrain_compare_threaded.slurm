#!/bin/bash
#SBATCH --job-name=instrain_compare
#SBATCH --output=logs/instrain_compare_%j.out
#SBATCH --error=logs/instrain_compare_%j.err
#SBATCH --time=96:00:00
#SBATCH --cpus-per-task=64
#SBATCH --mem=512G

# Load your conda environment
source ~/.bashrc
#conda activate instrain_env         # Replace with your actual env name

# Find valid inStrain profile folders
VALID_PROFILES=()
for d in *_IS; do
    if [ -f "$d/raw_data/covT.hd5" ]; then
        VALID_PROFILES+=("$d")
    else
        echo "Skipping incomplete profile: $d"
    fi
done

# Check if we have enough valid samples
if [ ${#VALID_PROFILES[@]} -lt 2 ]; then
    echo "Not enough valid profiles to run inStrain compare."
    exit 1
fi

# Run inStrain compare
inStrain compare -i "${VALID_PROFILES[@]}" \
  -o 97_all_compare_0904 \
  -p $SLURM_CPUS_PER_TASK \
  --min_cov 5 \
  --breadth 0.5

echo "inStrain compare finished!"
