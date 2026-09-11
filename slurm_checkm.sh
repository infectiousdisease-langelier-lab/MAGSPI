#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"      # Directory to store non-host FASTQ files
COMMANDS_FILE="checkm_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="checkm_job.slurm"       # SLURM script for job array  # Adjust path if needed

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for checkm..."
for DIR in "$INPUT_DIR"/*_assembly; do
  # Derive sample name from directory name
  echo "$DIR"
  SAMPLE=$(basename "$DIR" | sed 's/_assembly$//')
  echo "$SAMPLE"
  BIN_DIR="${DIR}/bins"
  OUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/MAG_stats/${SAMPLE}"
  # Create the command for assembly of MAGs
  echo "checkm lineage_wf -x fa -t 16 --pplacer_threads 16 $BIN_DIR $OUT_DIR && checkm qa $OUT_DIR/lineage.ms $OUT_DIR -o 2 > $OUT_DIR/checkm_summary.txt" >> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=checkm      # Job name
#SBATCH --output=checkm_%A_%a.out        # Output file for each task
#SBATCH --error=checkm_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=16                  # Number of CPU cores per task
#SBATCH --mem=64G                          # Memory per job
#SBATCH --time=24:00:00                    # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)

# Load necessary modules
module load anaconda
source /home/abigail.glascock/.bashrc
export CHECKM_DATA_PATH=/hpc/reference/seq_databases/microbes/CheckM_db

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

echo "All checkm jobs submitted for parallel execution."

