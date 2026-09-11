mkdir -p derived
python - <<'PY'
import glob, os

out = open("derived/scaffold_to_mag.tsv", "w")
out.write("scaffold\tmag\n")

for fp in sorted(glob.glob("mag_scaffold_lists/*")):
    if os.path.isdir(fp): 
        continue
    mag = os.path.basename(fp).split(".")[0]
    with open(fp) as f:
        for line in f:
            s = line.strip()
            if s:
                out.write(f"{s}\t{mag}\n")

out.close()
print("Wrote derived/scaffold_to_mag.tsv")
PY

