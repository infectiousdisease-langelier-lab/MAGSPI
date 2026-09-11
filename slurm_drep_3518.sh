#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool/Extracted_MAGs_all"
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool/Dereplicated_MAGs"
COMMANDS_FILE="drep_commands_3518.txt"
SLURM_SCRIPT="drep_job_3518.slurm"

# Clear previous commands file
> "$COMMANDS_FILE"

echo "Generating commands..."
echo "dRep dereplicate drep_3518 -g ${INPUT_DIR}/*.fa -p 64 -comp 50 -con 10 -sa 0.97" >> "$COMMANDS_FILE"

echo "Commands written to $COMMANDS_FILE."

# Create SLURM script
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=drep
#SBATCH --output=drep_%A_%a.out
#SBATCH --error=drep_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=64
#SBATCH --mem=512G
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

echo "dRep job submitted!"
