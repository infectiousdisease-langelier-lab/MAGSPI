#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/metaspades"
OUTPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"
COMMANDS_FILE="concoct_commands.txt"
SLURM_SCRIPT="concoct_job.slurm"

# Clear previous commands file
> "$COMMANDS_FILE"

echo "Generating commands for CONCOCT..."
for FILE in "$INPUT_DIR"/*_assembly/contigs.fasta; do
  DIR=$(basename "$(dirname "$FILE")")
  SAMPLE=$(echo "$DIR" | sed 's/_assembly$//')
  BAM_DIR="${DIR}/concoct_bams"
  BIN_DIR="${DIR}/concoct_bins"
  WORK_DIR="${DIR}/concoct_work"
  DEPTH_FILE="${DIR}/depth_concoct.txt"
  CHUNKS_FILE="${WORK_DIR}/contigs_10K.fa"
  CUTUP_FILE="${WORK_DIR}/contigs_10K.cutup.fa"
  MERGED_BAM="${BAM_DIR}/${SAMPLE}.sorted.bam"
  COVERAGE_TABLE="${WORK_DIR}/coverage_table.tsv"

  R1="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_R1_formeta.fastq.gz"
  R2="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_R2_formeta.fastq.gz"
  UP="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost/${SAMPLE}_non_host_unpaired_formeta.fastq.gz"

  echo "mkdir -p $BIN_DIR $BAM_DIR $WORK_DIR && \
        bowtie2-build $FILE ${WORK_DIR}/contigs_index && \
        bowtie2 -x ${WORK_DIR}/contigs_index -1 $R1 -2 $R2 $UP -p 16 | samtools view -bS - > $BAM_DIR/${SAMPLE}.bam && \
        samtools sort -o $MERGED_BAM $BAM_DIR/${SAMPLE}.bam && \
        samtools index $MERGED_BAM && \
        rm $BAM_DIR/${SAMPLE}.bam && \
        cut_up_fasta.py $FILE -c 10000 -o 0 --merge_last -b $CHUNKS_FILE > $CUTUP_FILE && \
        concoct_coverage_table.py $CHUNKS_FILE $MERGED_BAM > $COVERAGE_TABLE && \
        concoct --composition_file $CUTUP_FILE --coverage_file $COVERAGE_TABLE -b $BIN_DIR" >> "$COMMANDS_FILE"
done

echo "Commands written to $COMMANDS_FILE."

# Create SLURM script
echo "Creating SLURM script..."
cat > "$SLURM_SCRIPT" <<EOL
#!/bin/bash
#SBATCH --job-name=concoct
#SBATCH --output=concoct_%A_%a.out
#SBATCH --error=concoct_%A_%a.err
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=16
#SBATCH --mem=128G
#SBATCH --time=24:00:00
#SBATCH --array=1-$(wc -l < "$COMMANDS_FILE")

# Load modules
module load anaconda
module load bowtie2
module load samtools
#source activate concoct_env  # Replace with your conda env if different

# Run the command
COMMAND=\$(sed -n "\${SLURM_ARRAY_TASK_ID}p" $COMMANDS_FILE)
echo "Running task \$SLURM_ARRAY_TASK_ID: \$COMMAND"
eval \$COMMAND
EOL

echo "SLURM script written to $SLURM_SCRIPT."

# Submit
echo "Submitting job array..."
sbatch "$SLURM_SCRIPT"

echo "All CONCOCT jobs submitted!"

