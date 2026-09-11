#!/bin/bash

INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"  # Directory containing sorted fastq.gz files
COMMANDS_FILE="seqkit_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="seqkit_job.slurm"       # SLURM script for job array

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for seqkit..."
for FILE in "$INPUT_DIR"/*formeta.fastq.gz; do
  # Derive sample name from file name
  SAMPLE=$(basename "$FILE" | sed 's/.fastq.gz//')
  echo "$SAMPLE"

  # Define output file names
  FILE2="${INPUT_DIR}/${SAMPLE}_seqkit_stats.txt"

  # Create the command
  echo "seqkit stats $FILE > $FILE2" >> "$COMMANDS_FILE"

done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=seqkit      # Job name
#SBATCH --output=seqkit_%A_%a.out        # Output file for each task
#SBATCH --error=seqkit_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=1                  # Number of CPU cores per task
#SBATCH --mem=8G                          # Memory per job
#SBATCH --time=02:00:00                    # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)


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

echo "All seqkit jobs submitted for parallel execution."
