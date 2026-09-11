#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"          # Directory containing sorted BAM files
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"      # Directory to store non-host FASTQ files
COMMANDS_FILE="bbmap_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="bbmap_job.slurm"       # SLURM script for job array

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for non-host read extraction..."
for R1 in "$OUTPUT_DIR"/*non_host_R1.fastq.gz; do
  # Derive sample name from BAM file name
  SAMPLE=$(basename "$R1" | sed 's/_non_host_R1.fastq.gz//')
  echo "$SAMPLE"

  # Define output file names
  UP="${OUTPUT_DIR}/${SAMPLE}_non_host_unpaired.fastq.gz"
  R2="${OUTPUT_DIR}/${SAMPLE}_non_host_R2.fastq.gz"
  OUT_R1="${OUTPUT_DIR}/${SAMPLE}_non_host_R1_formeta.fastq.gz"
  OUT_R2="${OUTPUT_DIR}/${SAMPLE}_non_host_R2_formeta.fastq.gz"
  OUT_UNPAIRED="${OUTPUT_DIR}/${SAMPLE}_non_host_unpaired_bbmap.fastq.gz"
  UP_META="${OUTPUT_DIR}/${SAMPLE}_non_host_unpaired_formeta.fastq.gz"

  # Create the command for extracting non-host reads and converting to FASTQ
  echo "repair.sh in1=$R1 in2=$R2 out1=$OUT_R1 out2=$OUT_R2 outsingle=$OUT_UNPAIRED && \ cat $UP $OUT_UNPAIRED > $UP_META" >> "$COMMANDS_FILE"

done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=bbmap      # Job name
#SBATCH --output=bbmap_%A_%a.out        # Output file for each task
#SBATCH --error=bbmap_%A_%a.err         # Error file for each task
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

