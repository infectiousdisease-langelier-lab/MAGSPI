#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades"
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs/maxbin"
COMMANDS_FILE="maxbin2_commands.txt"
SLURM_SCRIPT="maxbin2_job.slurm"

# Clear previous commands file
> "$COMMANDS_FILE"

echo "Generating commands for MaxBin2..."
for FILE in "$INPUT_DIR"/*_assembly/contigs.fasta; do
  DIR=$(basename "$(dirname "$FILE")")
  SAMPLE=$(echo "$DIR" | sed 's/_assembly$//')
  BAM_DIR="${DIR}/bams"
  BIN_DIR="${DIR}/maxbin2_bins"
  DEPTH_FILE="${DIR}/depth_maxbin.txt"
  SORTED_BAM="${BAM_DIR}/${SAMPLE}.sorted.bam"

  R1="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_R1_formeta.fastq.gz"
  R2="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_R2_formeta.fastq.gz"
  UP="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_unpaired_formeta.fastq.gz"

  echo "jgi_summarize_bam_contig_depths --outputDepth $DEPTH_FILE $SORTED_BAM && \
        mkdir -p $BIN_DIR/${SAMPLE}_maxbin2
        run_MaxBin.pl -contig $FILE -abund $DEPTH_FILE -out $BIN_DIR/${SAMPLE}_maxbin2 -thread 16" >> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM script
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=maxbin2
#SBATCH --output=maxbin2_%A_%a.out
#SBATCH --error=maxbin2_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")

# Load modules
module load anaconda
module load bowtie2
module load samtools
#module load maxbin2  # Load your system's MaxBin2 module, or use conda if preferred

# Run the command
COMMAND=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" $COMMANDS_FILE)
echo "Running task \$SLURM_ARRAY_TASK_ID: \$COMMAND"
eval \$COMMAND
EOL

echo "SLURM script written to $SLURM_SCRIPT."

# Submit the job
echo "Submitting job array..."
sbatch "$SLURM_SCRIPT"

echo "All MaxBin2 jobs submitted!"
