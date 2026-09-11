#!/bin/bash
module load anaconda

# Specify directories
INPUT_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/combined_lanes"       # Directory containing FASTQ files
OUTPUT_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/fastp"     # Directory to store processed FASTQ files
COMMANDS_FILE="fastp_commands.txt" # File to store the list of commands
SLURM_SCRIPT="fastp_job.slurm"   # SLURM submission script

# Clear commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for fastp
echo "Generating fastp commands..."
for R1 in "$INPUT_DIR"/p23*_R1_combined.fastq.gz; do
  # Derive sample name (strip directory and extensions)
  SAMPLE=$(basename "$R1" | sed 's/_R1_combined.fastq.gz//')

  # Define output filenames
  R2="$INPUT_DIR/${SAMPLE}_R2_combined.fastq.gz"
  OUTPUT_R1="$OUTPUT_DIR/${SAMPLE}_QC_R1.fastq.gz"
  OUTPUT_R2="$OUTPUT_DIR/${SAMPLE}_QC_R2.fastq.gz"
  REPORT_HTML="$OUTPUT_DIR/${SAMPLE}_fastp.html"
  UP1="$OUTPUT_DIR/${SAMPLE}_unpaired1.fastq.gz"
  UP2="$OUTPUT_DIR/${SAMPLE}_unpaired2.fastq.gz"
  FAIL="$OUTPUT_DIR/${SAMPLE}_failedqc.fastq.gz"
  # Generate the fastp command
  echo "fastp -i $R1 -I $R2 -o $OUTPUT_R1 -O $OUTPUT_R2 -c -h $REPORT_HTML --unpaired1 $UP1 --unpaired2 $UP2 --failed_out $FAIL --detect_adapter_for_pe -e 20 -l 50 -3">> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for parallel execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=fastp_parallel      # Job name
#SBATCH --output=fastp_%A_%a.out      # Output file for each task
#SBATCH --error=fastp_%A_%a.err       # Error file for each task
#SBATCH --ntasks=1                    # Number of tasks per job
#SBATCH --cpus-per-task=4             # Number of CPU cores per task
#SBATCH --mem=16G                     # Memory per job
#SBATCH --time=01:00:00               # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)

# Load any necessary modules (e.g., fastp)
module load fastp

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

echo "All fastp jobs submitted for parallel execution."



