#!/bin/bash
#SBATCH --job-name=profile_MAG99
#SBATCH --output=logs/profile_MAG99_%A_%a.out
#SBATCH --error=logs/profile_MAG99_%A_%a.err
#SBATCH --array=0-90             # Replace <N> with number of samples
#SBATCH --time=24:00:00
#SBATCH --cpus-per-task=32
#SBATCH --mem=256G

# Load modules
module load bowtie2
module load samtools

# Set input paths
MAG_FASTA=/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/DAS_Tool/Dereplicated_MAGs/derep_out97/deplicated_genomes/MAGs_renamed/ALL_MAGS_97.fasta
INDEX_PREFIX=/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/DAS_Tool/Dereplicated_MAGs/derep_out97/dereplicated_genomes/MAGs_renamed/ALL_MAGS_97        # without .fasta
READ_DIR=/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost
OUT_DIR=/hpc/projects/react/emory/InStrain/97_derep_MAGs

# Sample list: filenames without _R1/_R2
SAMPLES=( $(ls $READ_DIR/*_R1_formeta.fastq.gz | sed 's/_R1_formeta.fastq.gz//' | xargs -n1 basename) )
SAMPLE=${SAMPLES[$SLURM_ARRAY_TASK_ID]}

# Define input files
R1=${READ_DIR}/${SAMPLE}_R1_formeta.fastq.gz
R2=${READ_DIR}/${SAMPLE}_R2_formeta.fastq.gz
BAM=${SAMPLE}_99mag.bam
PROFILE_OUT=${OUT_DIR}/${SAMPLE}_97mag_IS

# Make output dir
mkdir -p $OUT_DIR logs

echo "Processing $SAMPLE..."

# Map reads
bowtie2 -x $INDEX_PREFIX -1 $R1 -2 $R2 --very-sensitive-local -p 32 | samtools view -bS -@ 4 - | samtools sort -@ 4 -o $BAM

samtools index $BAM

# Run inStrain profile
#inStrain profile $BAM $MAG_FASTA -o $PROFILE_OUT --processes $SLURM_CPUS_PER_TASK

echo "Done with $SAMPLE"

