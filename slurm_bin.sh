#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"      # Directory to store non-host FASTQ files
COMMANDS_FILE="binning_commands.txt"   # File to store the list of commands
SLURM_SCRIPT="binning_job.slurm"       # SLURM script for job array  # Adjust path if needed

# Clear previous commands file if it exists
> "$COMMANDS_FILE"

# Generate commands for extracting non-host reads
echo "Generating commands for CONCOCT and MaxBin..."
for DIR in "$INPUT_DIR"/*_assembly; do
  # Derive sample name from directory name
  echo "$DIR"
  SAMPLE=$(basename "$DIR" | sed 's/_assembly$//')
  echo "$SAMPLE"
  BAM_DIR="${DIR}/bams"
  DEPTH="${DIR}/depth.txt"
  COV="coverage.txt"
  BAM="${SAMPLE}.sorted.bam"
  BIN_DIR="${DIR}/bins"
  CONTIGS="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades/${SAMPLE}_assembly/contigs.fasta" 

  # Create the command for assembly of MAGs
  echo "samtools depth $BAM_DIR/$BAM > $BAM_DIR/$COV" >> "$COMMANDS_FILE"
  echo "maxbin2 -contig $CONTIGS -o $BIN_DIR/maxbin -min_contig_len 1500 -keep_unbinned" >> "$COMMANDS_FILE"
  echo "concoct --assembly $CONTIGS --coverage $BAM_DIR/$COV --output $BIN_DIR/concoct --min_contig_length 1500" >> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM batch script for job array execution
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=binning      # Job name
#SBATCH --output=binning_%A_%a.out        # Output file for each task
#SBATCH --error=binning_%A_%a.err         # Error file for each task
#SBATCH --ntasks=1                         # Number of tasks per job
#SBATCH --cpus-per-task=4                  # Number of CPU cores per task
#SBATCH --mem=32G                          # Memory per job
#SBATCH --time=24:00:00                    # Time limit
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")  # Number of array jobs (one per command)

# Load necessary modules
module load anaconda
module load python
module load bowtie2
module load samtools
source /home/abigail.glascock/.bashrc

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

echo "All maxbin and concoct jobs submitted for parallel execution."

