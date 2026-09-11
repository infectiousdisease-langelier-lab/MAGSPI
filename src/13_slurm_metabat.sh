#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades"          # Directory containing sorted BAM files
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"      # Directory to store non-host FASTQ files
COMMANDS_FILE="metabat_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="metabat_job.slurm"       # SLURM script for job array  # Adjust path if needed

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for metabat..."
for FILE in "$INPUT_DIR"/*_assembly/contigs.fasta; do
  # Derive sample name from directory name
  DIR=$(basename "$(dirname "$FILE")")
  echo "$DIR"
  SAMPLE=$(echo "$DIR" | sed 's/_assembly$//')
  echo "$SAMPLE"
  BAM_DIR="${DIR}/bams"
  DEPTH="${DIR}/depth.txt"
  BIN_DIR="${DIR}/bins"
  R1="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_R1_formeta.fastq.gz"
  R2="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_R2_formeta.fastq.gz"
  UP="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_unpaired_formeta.fastq.gz"

  # Define output file names
  OUT="${OUTPUT_DIR}/${SAMPLE}_metabat"

  # Create the command for assembly of MAGs
  echo "mkdir -p $BIN_DIR $BAM_DIR && \
        bowtie2-build $FILE $DIR/contigs_index && \
        bowtie2 -x $DIR/contigs_index -1 $R1 -2 $R2 $UP -p 16 | samtools view -bS - > $BAM_DIR/${SAMPLE}.bam && \
        samtools sort -o $BAM_DIR/${SAMPLE}.sorted.bam $BAM_DIR/${SAMPLE}.bam && \
        samtools index $BAM_DIR/${SAMPLE}.sorted.bam && \
        rm $BAM_DIR/${SAMPLE}.bam && \ jgi_summarize_bam_contig_depths --outputDepth $DEPTH_FILE $BAM_DIR/*.sorted.bam && \
        metabat2 -i $FILE -a $DEPTH_FILE -o $BIN_DIR/bin -m 1500 --unbinned" >> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=metabat      # Job name
#SBATCH --output=metabat_%A_%a.out        # Output file for each task
#SBATCH --error=metabat_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=16                  # Number of CPU cores per task
#SBATCH --mem=128G                          # Memory per job
#SBATCH --time=24:00:00                    # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)

# Load necessary modules
module load anaconda
module load bowtie2
module load samtools

# Extract the command for this array task
COMMAND=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" $COMMANDS_FILE)

# Run the command
echo "Running task \$SLURM_ARRAY_TASK_ID: \$COMMAND"
eval \$COMMAND
EOL

echo "SLURM script written to $SLURM_SCRIPT."

# Submit the SLURM array job
echo "Submitting job array..."
sbatch "$SLURM_SCRIPT"

echo "All metabat jobs submitted for parallel execution."

