#!/usr/bin/env python3
import argparse, glob, os
import pandas as pd
import numpy as np

def sample_id_from_dir(d):
    b = os.path.basename(d.rstrip("/"))
    return b[:-3] if b.endswith("_IS") else b

def find_scaffold_info(d):
    out_dir = os.path.join(d, "output")
    if not os.path.isdir(out_dir):
        return None
    matches = glob.glob(os.path.join(out_dir, "*scaffold_info.tsv"))
    return matches[0] if matches else None

def pick_col(df, candidates):
    lower = {c.lower(): c for c in df.columns}
    for cand in candidates:
        if cand in lower:
            return lower[cand]
    return None

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--profiles_dir", required=True, help="dir containing *_IS folders")
    ap.add_argument("--scaffold_to_mag", required=True, help="TSV: scaffold, mag")
    ap.add_argument("--breadth_thresh", type=float, default=0.5)
    ap.add_argument("--cov_thresh", type=float, default=1.0)
    ap.add_argument("--out_prefix", default="mag_detection")
    args = ap.parse_args()

    map_df = pd.read_csv(args.scaffold_to_mag, sep="\t")
    map_df["scaffold"] = map_df["scaffold"].astype(str)

    sample_dirs = sorted(glob.glob(os.path.join(args.profiles_dir, "*_IS")))
    if not sample_dirs:
        raise SystemExit(f"No *_IS folders found under {args.profiles_dir}")

    rows = []
    missing = 0

    for sd in sample_dirs:
        sid = sample_id_from_dir(sd)
        fp = find_scaffold_info(sd)
        if fp is None:
            missing += 1
            continue

        df = pd.read_csv(fp, sep="\t", low_memory=False)

        scaf_col = pick_col(df, ["scaffold", "scaffold_name", "contig", "contig_name", "reference"])
        len_col  = pick_col(df, ["length", "len"])
        br_col   = pick_col(df, ["breadth", "breadth_0", "covered_fraction"])
        cov_col  = pick_col(df, ["coverage", "mean_coverage", "coverage_mean", "avg_coverage"])
        covbp_col= pick_col(df, ["covered_bases", "covered_bp", "covered"])

        if scaf_col is None or len_col is None or br_col is None:
            raise SystemExit(f"Missing required columns in {fp}. Need scaffold/length/breadth.")

        df[scaf_col] = df[scaf_col].astype(str)
        df[len_col] = pd.to_numeric(df[len_col], errors="coerce")
        df[br_col]  = pd.to_numeric(df[br_col], errors="coerce")
        if cov_col is not None:
            df[cov_col] = pd.to_numeric(df[cov_col], errors="coerce")
        if covbp_col is not None:
            df[covbp_col] = pd.to_numeric(df[covbp_col], errors="coerce")

        df = df.merge(map_df, how="left", left_on=scaf_col, right_on="scaffold")
        df = df.dropna(subset=["mag", len_col, br_col])

        # covered bases per scaffold
        if covbp_col is not None:
            df["_covered"] = df[covbp_col]
        else:
            df["_covered"] = df[br_col] * df[len_col]
        df["_len"] = df[len_col]

        # MAG breadth = sum(covered bases) / sum(length)
        mag = df.groupby("mag", as_index=False).agg(
            mag_length=("_len", "sum"),
            mag_covered=("_covered", "sum"),
        )
        mag["breadth"] = mag["mag_covered"] / mag["mag_length"]

        # MAG coverage = length-weighted mean scaffold coverage (if available)
        if cov_col is not None:
            cov_map = df.groupby("mag").apply(lambda x: np.average(x[cov_col].fillna(0), weights=x["_len"]))
            mag["coverage"] = mag["mag"].map(cov_map.to_dict())
            mag["detected"] = (mag["breadth"] >= args.breadth_thresh) & (mag["coverage"] >= args.cov_thresh)
        else:
            mag["coverage"] = np.nan
            mag["detected"] = (mag["breadth"] >= args.breadth_thresh)

        mag.insert(0, "sample", sid)
        rows.append(mag[["sample","mag","breadth","coverage","detected"]])

    per_sample = pd.concat(rows, ignore_index=True)
    per_mag = (per_sample.groupby("mag", as_index=False)
               .agg(n_samples=("sample","nunique"),
                    n_detected=("detected","sum"),
                    mean_breadth=("breadth","mean"),
                    mean_coverage=("coverage","mean"))
               .sort_values(["n_detected","mean_breadth"], ascending=False))

    per_sample.to_csv(f"{args.out_prefix}_per_sample.tsv", sep="\t", index=False)
    per_mag.to_csv(f"{args.out_prefix}_per_mag_summary.tsv", sep="\t", index=False)

    print(f"Samples found: {len(sample_dirs)}")
    print(f"Samples missing scaffold_info.tsv: {missing}")
    print(f"Wrote: {args.out_prefix}_per_sample.tsv")
    print(f"Wrote: {args.out_prefix}_per_mag_summary.tsv")

if __name__ == "__main__":
    main()

