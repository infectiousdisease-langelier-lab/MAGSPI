LIST_DIR="/home/abigail.glascock/react/00.MetagenomeRawData/MAGs/DAS_Tool/Dereplicated_MAGs/drep_3518/dereplicated_genomes/MAGs_renamed"
OUT="contigs2bins.stb"

: > "$OUT"

for f in "$LIST_DIR"/*.fa; do
  mag=$(basename "$f" .fa)
  grep '^>' "$f" | sed 's/^>//' | awk -v mag="$mag" '{print $1 "\t" mag}' >> "$OUT"
done

