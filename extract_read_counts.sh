#!/bin/bash

# Directory containing fastq files
FASTQ_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/nonhost"  # Change this to your actual path

# Output file
OUTPUT_FILE="fastq_total_reads_summary.tsv"
echo -e "Sample\tTotal_Reads" > "$OUTPUT_FILE"

# Loop through all unique sample names
for r1_file in "$FASTQ_DIR"/*_R1*.fastq*; do
    # Extract sample name (everything before _R1)
    base_name=$(basename "$r1_file")
    sample=$(echo "$base_name" | sed -E 's/_non_host_R1_formeta.fastq.gz?$//')

    # Define expected file names
    r1="$FASTQ_DIR/${sample}_non_host_R1_formeta.fastq.gz"
    r2="$FASTQ_DIR/${sample}_non_host_R2_formeta.fastq.gz"
    unpaired="$FASTQ_DIR/${sample}_non_host_unpaired_formeta.fastq.gz"

    # Fallback for uncompressed files
    if [[ ! -f "$r1" ]]; then r1="$FASTQ_DIR/${sample}_non_host_R1_formeta.fastq"; fi
    if [[ ! -f "$r2" ]]; then r2="$FASTQ_DIR/${sample}_non_host_R2_formeta.fastq"; fi
    if [[ ! -f "$unpaired" ]]; then unpaired="$FASTQ_DIR/${sample}_non_host_unpaired_formeta.fastq"; fi

    # Count reads
    count_reads() {
        local file=$1
        if [[ -f "$file" ]]; then
            if [[ "$file" == *.gz ]]; then
                zcat "$file" | echo $(( $(wc -l) / 4 ))
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

    echo -e "$sample\t$total" >> "$OUTPUT_FILE"
done

echo "Done. Output saved to $OUTPUT_FILE"

