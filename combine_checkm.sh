#!/bin/bash

INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/MAG_stats"  # Directory containing seqkit files

for DIR in "${INPUT_DIR}"/*; do
  echo "$DIR"
  SAMPLE=$(basename "$DIR")
  echo "$SAMPLE"
  FILE="${DIR}/checkm_summary.txt"
  if [ -f "$FILE" ]; then
        echo "Processing: $file"
        HEAD=$(grep "N50" "$FILE" | awk -v header="sample_name" '{print $0,header}')
        OUT="${SAMPLE}_checkm_filtered.txt"
        OUTPATH=${INPUT_DIR}/$OUT
        > "$OUTPATH"
        HQ=$(more "$FILE" | grep "bin." | grep -v "Short" | grep -v "unbinned" | awk -v sample="$SAMPLE" 'NR==1 || ($7 >= 50 && $8 <= 10) {print $0, sample}')
        echo -e "$HEAD" >> $OUTPATH
        echo -e "$HQ" >> $OUTPATH
 fi
done




