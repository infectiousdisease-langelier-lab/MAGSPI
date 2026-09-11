#!/bin/bash

INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/sample_stats"  # Directory containing seqkit files
OUT="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/sample_stats/seqkit_summary.txt"
OUT2="seqkit_bysample.txt"

# Find all SeqKit output files
FILES=("$INPUT_DIR"/*stats.txt)

# Check if files exist
if [ ${#FILES[@]} -eq 0 ]; then
    echo "No SeqKit output files found in $INPUT_DIR"
    exit 1
fi

# Combine all output files into one
echo "Combining SeqKit outputs..."
head -n 1 "${FILES[0]}" > "$OUT"  # Copy header from the first file
tail -n +2 -q "$INPUT_DIR"/*stats.txt >> "$OUT"  # Append data from all files


echo "Combined file saved as $OUT"

# Initialize output file with headers
echo -e "Sample\tTotal_Reads\tR1_Unpaired_Reads\tR1_Only_Reads" > "$OUT2"

# Declare associative arrays for storing read counts
declare -A TOTAL_READS
declare -A R1_UNPAIRED_READS
declare -A R1_ONLY_READS

# Process each SeqKit output file
for FILE in "${INPUT_DIR}"/*stats.txt; do
    # Extract sample name (removes _R1, _R2, _unpaired and .stats.txt)
    BASENAME=$(basename "$FILE" | sed -E 's/(_R1|_R2|_unpaired)?_formeta_seqkit_stats\.txt$//')

    # Extract total reads (assuming it's in the second column)
    RAW_TOTAL_READS=$(awk 'NR==2 {print $4}' "$FILE")

    # Remove commas from numbers (e.g., "10,000" → "10000")
    TOTAL_READS_COUNT=$(echo "$RAW_TOTAL_READS" | tr -d ',')

    # Sum total reads for the sample
    if [[ -n "$TOTAL_READS_COUNT" ]]; then
        TOTAL_READS["$BASENAME"]=$((TOTAL_READS["$BASENAME"] + TOTAL_READS_COUNT))
    fi

    # If this file corresponds to R1 or unpaired, add to R1+unpaired metric
    if [[ "$FILE" =~ _R1_formeta_seqkit_stats.txt || "$FILE" =~ _unpaired_formeta_seqkit_stats.txt ]]; then
        R1_UNPAIRED_READS["$BASENAME"]=$((R1_UNPAIRED_READS["$BASENAME"] + TOTAL_READS_COUNT))
    fi

    # If this file corresponds to R1 only, add to R1-only metric
    if [[ "$FILE" =~ _R1_formeta_seqkit_stats.txt ]]; then
        R1_ONLY_READS["$BASENAME"]=$((R1_ONLY_READS["$BASENAME"] + TOTAL_READS_COUNT))
    fi
done

# Write results to the output file
for SAMPLE in "${!TOTAL_READS[@]}"; do
    echo -e "$SAMPLE\t${TOTAL_READS[$SAMPLE]}\t${R1_UNPAIRED_READS[$SAMPLE]}\t${R1_ONLY_READS[$SAMPLE]}" >> "$OUT2"
done

echo "Total reads combined and saved in $OUT2"


