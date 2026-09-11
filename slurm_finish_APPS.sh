#!/bin/bash
module load anaconda
module load bowtie2
module load samtools

# Specify directories
INPUT_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/host_depletion"       # Directory containing FASTQ files
OUTPUT_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/nonhost"     # Directory to store processed FASTQ files
COMMANDS_FILE="bowtie_commands_APPS.txt" # File to store the list of commands
SLURM_SCRIPT="bowtie_job_APPS.slurm"   # SLURM submission script

# Clear commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for fastp
echo "Generating bowtie commands..."
for SAM in "$INPUT_DIR"/APPS*.sam; do
  # Derive sample name (strip directory and extensions)
  SAMPLE=$(basename "$SAM" | sed 's/_paired_aligned.sam//')

  # Define output filenames
  SORTED_PAIRED_BAM="${OUTPUT_DIR}/${SAMPLE}_paired_aligned_sorted.bam"


  # Paired alignment command
  if [[ -f "$SAM" ]]; then
    echo "samtools view -bS $SAM | samtools sort -o $SORTED_PAIRED_BAM && \
rm $SAM" >> "$COMMANDS_FILE"
  fi

done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for parallel execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=bowtie_sort       # Job name
#SBATCH --output=bowtie_%A_%a.out       # Output file for each task
#SBATCH --error=bowtie_%A_%a.err        # Error file for each task
#SBATCH --ntasks=1                      # Number of tasks per job
#SBATCH --cpus-per-task=6               # Number of CPU cores per task
#SBATCH --mem=32G                       # Memory per job
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




