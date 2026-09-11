#!/bin/bash

# Directories
INPUT_DIR="/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"          # Directory containing sorted BAM files

for FILE in "$INPUT_DIR"/../metaspades/*_assembly/contigs.fasta; do
  # Derive sample name from directory name
  DIR=$(basename "$(dirname "$FILE")")
  echo "${DIR}"
  SAMPLE=$(echo "$DIR" | sed 's/_assembly$//')
  echo "${SAMPLE}"
  METABAT_DIR="${DIR}/bins"
  CONCOCT_DIR="${DIR}/concoct_bins"
  reg="^(3279_)"
if [[ $SAMPLE =~ ^p23220 ]]; then
  for BINFILE in ${METABAT_DIR}/bin.[0-9]*.fa; do
	bin_name=$(basename "$BINFILE" .fa)
	awk -v b="$bin_name" '/^>/{gsub(">","",$1); print $1 "\t" b}' "$BINFILE"
  done > ${DIR}/metabat2_contig2bin.tsv

  tail -n +2 ${CONCOCT_DIR}/merged_clustering.csv | sed 's/,/\t/' > ${DIR}/concoct_contig2bin.tsv
  
  for f in ${DIR}/maxbin2_bins*.fasta; do
  	bin_name=$(basename "$f" .fasta)
  	awk -v b="$bin_name" '/^>/{gsub(">","",$1); print $1 "\t" b}' "$f"
  done > ${DIR}/maxbin2_contig2bin.tsv
else
echo "skipping ${SAMPLE}"
fi
done


