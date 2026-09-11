#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"          # Directory containing sorted BAM files
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades"      # Directory to store non-host FASTQ files
COMMANDS_FILE="assembly_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="assembly_job.slurm"       # SLURM script for job array

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for assembly..."
for R1 in "$INPUT_DIR"/*_non_host_R1_formeta.fastq.gz; do
  # Derive sample name from BAM file name
  SAMPLE=$(basename "$R1" | sed 's/_non_host_R1_formeta.fastq.gz//')
  echo "$SAMPLE"

  # Define output file names
  R2="${INPUT_DIR}/${SAMPLE}_non_host_R2_formeta.fastq.gz"
  UP="${INPUT_DIR}/${SAMPLE}_non_host_unpaired_formeta.fastq.gz"
  OUT="${OUTPUT_DIR}/${SAMPLE}_assembly"

  # Create the command for assembly of MAGs
  echo "metaspades.py --meta -1 $R1 -2 $R2 -s $UP -o $OUT -t 16 -m 128" >> "$COMMANDS_FILE"

done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=metaspades      # Job name
#SBATCH --output=metaspades_%A_%a.out        # Output file for each task
#SBATCH --error=metaspades_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=16                  # Number of CPU cores per task
#SBATCH --mem=128G                          # Memory per job
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

echo "All assembly jobs submitted for parallel execution."

