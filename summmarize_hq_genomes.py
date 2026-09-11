#!/usr/bin/env python3
import os
import re
import glob
import pandas as pd

# --------- paths (edit as needed) ----------
summary_dir  = "/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool"
combined_out = os.path.join(summary_dir, "combined_DASTool_summary_1223.tsv")
# -------------------------------------------

def parse_bin(raw_bin: str):
    """
    Remove trailing '_sub' then detect tool & bin number.
    Returns (tool, bin_number) or (None, None) if unrecognized.
    """
    rb = str(raw_bin).strip()
    rb = re.sub(r'_sub$', '', rb)

    if rb.startswith("bin."):  # e.g., bin.12
        return "metabat2", rb.replace("bin.", "")

    if rb.startswith("maxbin2_bins."):  # e.g., maxbin2_bins.3
        return "maxbin2", rb.replace("maxbin2_bins.", "")

    if re.fullmatch(r"\d+", rb):  # concoct integers, e.g., 7
        return "concoct", rb

    return None, None

def main():
    summary_files = sorted(glob.glob(os.path.join(summary_dir, "*_DASTool_summary.tsv")))
    if not summary_files:
        raise SystemExit(f"No summary files found in {summary_dir}")

    combined_rows = []
    warnings = []

    for path in summary_files:
        sample = os.path.basename(path).replace("_DASTool_summary.tsv", "")
        # Read the summary (skips comment lines starting with '#')
        df = pd.read_csv(path, sep="\t", comment="#", header=0)

        # First column is assumed to be the raw bin identifier (mirrors your script)
        bin_col = df.columns[0]

        for _, row in df.iterrows():
            raw = str(row[bin_col])
            tool, bin_number = parse_bin(raw)
            if tool is None:
                warnings.append(f"[WARN] Could not parse bin ID '{raw}' in {path}")
                continue

            mag_id = f"{sample}_{tool}_{bin_number}"

            # Build output row:
            out = row.to_dict()
            out["raw_bin"]   = raw
            out["MAG_ID"]    = mag_id
            out["sample"]    = sample
            out["tool"]      = tool
            out["bin_number"]= str(bin_number)

            # Overwrite the original bin column with standardized MAG_ID
            out[bin_col] = mag_id

            combined_rows.append(out)

    if not combined_rows:
        raise SystemExit("No rows produced. Check parsing rules and inputs.")

    combined_df = pd.DataFrame(combined_rows)

    # Nice column order: MAG metadata first, then the rest
    first_cols = ["MAG_ID", "sample", "tool", "bin_number", "raw_bin"]
    rest = [c for c in combined_df.columns if c not in first_cols]
    combined_df = combined_df[first_cols + rest]

    combined_df.to_csv(combined_out, sep="\t", index=False)
    print(f"[OK] Wrote: {combined_out}")

    for w in warnings:
        print(w)

if __name__ == "__main__":
    main()

