#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades"          # Directory containing sorted BAM files
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/assembly_stats"      # Directory to store non-host FASTQ files
COMMANDS_FILE="quast_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="quast_job.slurm"       # SLURM script for job array

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for quast..."
for FILE in "$INPUT_DIR"/*_assembly/contigs.fasta; do
  # Derive sample name from directory name
  SAMPLE=$(basename "$(dirname "$FILE")")
  echo "$SAMPLE"

  # Define output file names
  OUT="${OUTPUT_DIR}/${SAMPLE}_quast"

  # Create the command for assembly of MAGs
  echo "quast.py -o $OUT -t 16 $FILE" >> "$COMMANDS_FILE"

done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=quast      # Job name
#SBATCH --output=quast_%A_%a.out        # Output file for each task
#SBATCH --error=quast_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=16                  # Number of CPU cores per task
#SBATCH --mem=32G                          # Memory per job
#SBATCH --time=24:00:00                    # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)

# Load necessary modules
module load anaconda

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

echo "All quast jobs submitted for parallel execution."

