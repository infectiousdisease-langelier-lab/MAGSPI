STB=contigs2bins.stb
LIST_DIR=mag_scaffold_lists

mkdir -p "$LIST_DIR"

# 710 MAG IDs (bin names)
cut -f2 "$STB" | sort -u > mag_ids.txt

# One scaffold list per MAG
while read -r MAG; do
  awk -v m="$MAG" 'BEGIN{FS="\t"} $2==m {print $1}' "$STB" > "$LIST_DIR/${MAG}.scaffolds.txt"
done < mag_ids.txt

