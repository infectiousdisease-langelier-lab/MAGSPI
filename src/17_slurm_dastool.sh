#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades"
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"
COMMANDS_FILE="dastool_commands.txt"
SLURM_SCRIPT="dastool_job.slurm"

# Clear previous commands file
> "$COMMANDS_FILE"

echo "Generating commands..."
for FILE in "$INPUT_DIR"/*_assembly/contigs.fasta; do
  DIR=$(basename "$(dirname "$FILE")")
  SAMPLE=$(echo "$DIR" | sed 's/_assembly$//')
  META="${DIR}/metabat2_contig2bin.tsv"
  MAX="${DIR}/maxbin2_contig2bin.tsv"
  CON="${DIR}/concoct_contig2bin.tsv"

  echo "DAS_Tool -i ${META},${MAX},${CON} -l metabat2,maxbin2,concoct -c $FILE -o ${SAMPLE} --write_bins --search_engine=diamond --threads 32" >> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM script
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=dastool
#SBATCH --output=dastool_%A_%a.out
#SBATCH --error=dastool_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=32
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")

# Load modules
module load anaconda

# Run the command
COMMAND=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" $COMMANDS_FILE)
echo "Running task \$SLURM_ARRAY_TASK_ID: \$COMMAND"
eval \$COMMAND
EOL

echo "SLURM script written to $SLURM_SCRIPT."

# Submit the job
echo "Submitting job array..."
sbatch "$SLURM_SCRIPT"

echo "All DASTool jobs submitted!"
