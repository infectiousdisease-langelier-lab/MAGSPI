#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/host_depletion"          # Directory containing sorted BAM files
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"      # Directory to store non-host FASTQ files
COMMANDS_FILE="non_host_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="non_host_job.slurm"       # SLURM script for job array

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for non-host read extraction..."
for BAM_FILE in "$INPUT_DIR"/*_unpaired_aligned_sorted.bam; do
  # Derive sample name from BAM file name
  SAMPLE=$(basename "$BAM_FILE" | sed 's/_unpaired_aligned_sorted.bam//')
  echo "$SAMPLE"

  # Define output file names
  SINGLE_NONHOST_BAM="${OUTPUT_DIR}/${SAMPLE}_non_host_unpaired.bam"
  NON_HOST_SINGLE="${OUTPUT_DIR}/${SAMPLE}_non_host_unpaired.fastq.gz"

  # Create the command for extracting non-host reads and converting to FASTQ
  echo "samtools view -b -f 4 $BAM_FILE > $SINGLE_NONHOST_BAM && \
samtools fastq -@ 4 $SINGLE_NONHOST_BAM > $NON_HOST_SINGLE && \
rm  $SINGLE_NONHOST_BAM" >> "$COMMANDS_FILE"

done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=non_host_extraction      # Job name
#SBATCH --output=non_host_%A_%a.out        # Output file for each task
#SBATCH --error=non_host_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=4                  # Number of CPU cores per task
#SBATCH --mem=16G                          # Memory per job
#SBATCH --time=02:00:00                    # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)

# Load necessary modules
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

echo "All non-host extraction jobs submitted for parallel execution."

