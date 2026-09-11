#!/bin/bash
#SBATCH --job-name=bowtie_index
#SBATCH --cpus-per-task=4
#SBATCH --mem=4G
#SBATCH --time=01:00:00
#SBATCH --array=1-1331
#SBATCH --output=logs/bowtie_index_%A_%a.out
#SBATCH --error=logs/bowtie_index_%A_%a.err

# Load bowtie2 module or activate your environment
module load bowtie2   # or: conda activate your_env

# Read genome filename from list
for FILE in /hpc/projects/react/emory/00.MetagenomeRawData/MAGs/dereplicated_MAGs_99/derep_out/dereplicated_genomes/*.fna; do
	BASENAME=$(basename "$FILE")
	bowtie2-build $FILE 99/${BASENAME}
done
