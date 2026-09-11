python - <<'PY'
import glob, os

with open("scaffolds_to_bins.tsv","w") as out:
    for fp in sorted(glob.glob("mag_scaffold_lists/*")):
        if os.path.isdir(fp): 
            continue
        mag = os.path.basename(fp).split(".")[0]
        with open(fp) as f:
            for line in f:
                s = line.strip()
                if s:
                    out.write(f"{s}\t{mag}\n")
print("Wrote scaffolds_to_bins.tsv")
PY

