#!/bin/bash
#SBATCH --job-name=read_count
#SBATCH --array=1-85             # Adjust to match number of samples
#SBATCH --cpus-per-task=1
#SBATCH --mem=8G
#SBATCH --time=00:10:00
#SBATCH --output=logs/%A_%a.out
#SBATCH --error=logs/%A_%a.err

# Load any necessary modules (e.g., zlib for zcat if needed)
# module load ...

# Paths
FASTQ_DIR="fastq_files"
SAMPLE_LIST="sample_list.txt"
OUTPUT_DIR="read_counts"
mkdir -p "$OUTPUT_DIR"

# Get sample name for this task
sample=$(sed -n "${SLURM_ARRAY_TASK_ID}p" "$SAMPLE_LIST")

# Define files
r1="$FASTQ_DIR/${sample}_non_host_R1_formeta.fastq.gz"
r2="$FASTQ_DIR/${sample}_non_host_formeta_R2.fastq.gz"
unpaired="$FASTQ_DIR/${sample}_non_host_unpaired_formeta.fastq.gz"

# Fallback for uncompressed
[[ ! -f "$r1" ]] && r1="$FASTQ_DIR/${sample}_non_host_R1_formeta.fastq"
[[ ! -f "$r2" ]] && r2="$FASTQ_DIR/${sample}_non_host_R2_formeta.fastq"
[[ ! -f "$unpaired" ]] && unpaired="$FASTQ_DIR/${sample}_non_host_unpaired_formeta.fastq"

count_reads() {
    local file=$1
    if [[ -f "$file" ]]; then
        if [[ "$file" == *.gz ]]; then
            echo $(( $(zcat "$file" | wc -l) / 4 ))
        else
            echo $(( $(wc -l < "$file") / 4 ))
        fi
    else
        echo 0
    fi
}

r1_count=$(count_reads "$r1")
r2_count=$(count_reads "$r2")
unpaired_count=$(count_reads "$unpaired")
total=$((r1_count + r2_count + unpaired_count))

# Save output
echo -e "${sample}\t${total}" > "$OUTPUT_DIR/${sample}_reads.tsv"

