#!/bin/bash

# Specify directories
INPUT_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/fastp"       # Directory containing FASTQ files
OUTPUT_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/host_depletion"     # Directory to store processed FASTQ files
COMMANDS_FILE="bowtie_commands_unpaired.txt" # File to store the list of commands
SLURM_SCRIPT="bowtie_job_unpaired.slurm"   # SLURM submission script
INDEX="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/host_depletion/hg38"

# Clear commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for fastp
echo "Generating bowtie commands..."
for R1 in "$INPUT_DIR"/p23*_QC_R1.fastq.gz; do
  # Derive sample name (strip directory and extensions)
  SAMPLE=$(basename "$R1" | sed 's/_QC_R1.fastq.gz//')

  # Define output filenames
  UP1="$INPUT_DIR/${SAMPLE}_unpaired1.fastq.gz"
  UP2="$INPUT_DIR/${SAMPLE}_unpaired2.fastq.gz"
  UNPAIRED_SAM="${OUTPUT_DIR}/${SAMPLE}_unpaired_aligned.sam"
  SORTED_UNPAIRED_BAM="${OUTPUT_DIR}/${SAMPLE}_unpaired_aligned_sorted.bam"


  # Unpaired alignment command (for unpaired reads from R1 and R2)
  if [[ -f "$UP1" || -f "$UP2" ]]; then
    echo "bowtie2 -x $INDEX -U $UP1,$UP2 -S $UNPAIRED_SAM --threads 4 && \
samtools view -bS $UNPAIRED_SAM | samtools sort -o $SORTED_UNPAIRED_BAM && \
rm $UNPAIRED_SAM" >> "$COMMANDS_FILE"
  fi
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for parallel execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=bowtie_unpaired       # Job name
#SBATCH --output=bowtie_%A_%a.out       # Output file for each task
#SBATCH --error=bowtie_%A_%a.err        # Error file for each task
#SBATCH --ntasks=1                      # Number of tasks per job
#SBATCH --cpus-per-task=4               # Number of CPU cores per task
#SBATCH --mem=16G                       # Memory per job
#SBATCH --time=02:00:00                 # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs

# Load Bowtie 2 and SAMtools modules
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

echo "All Bowtie 2 jobs submitted for parallel execution."




