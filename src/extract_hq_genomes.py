import os
import shutil
import glob
import pandas as pd
import re

# Set the paths
summary_dir = "/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool"       # Folder containing *_DASTool_summary.tsv files
assemblies_base = "/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/binned_contigs"   # Folder containing genome_name_assembly folders
output_dir = "/hpc/projects/react/emory/00.MetagenomeRawData/MAGs/DAS_Tool/Extracted_MAGs"        # Destination folder to copy genomes into

os.makedirs(output_dir, exist_ok=True)

# Process each summary file
for summary_file in glob.glob(os.path.join(summary_dir, "*_DASTool_summary.tsv")):
    genome_name = os.path.basename(summary_file).replace("_DASTool_summary.tsv", "")
    assembly_path = os.path.join(assemblies_base, f"{genome_name}_assembly")

    df = pd.read_csv(summary_file, sep="\t", comment="#", header=0)

    for _, row in df.iterrows():
        raw_bin = str(row.iloc[0]).strip()

        # Remove _sub suffix if present
        raw_bin_clean = re.sub(r'_sub$', '', raw_bin)

        # Parse tool and bin number
        if raw_bin_clean.startswith("bin."):
            tool = "metabat2"
            bin_number = raw_bin_clean.replace("bin.", "")
            src_path = os.path.join(assembly_path, f"bins/bin.{bin_number}.fa")

        elif raw_bin_clean.startswith("maxbin2_bins."):
            tool = "maxbin2"
            bin_number = raw_bin_clean.replace("maxbin2_bins.", "")
            src_path = os.path.join(assembly_path, f"maxbin2_bins.{bin_number}.fasta")

        elif re.match(r"^\d+$", raw_bin_clean):
            tool = "concoct"
            bin_number = raw_bin_clean
            src_path = os.path.join(assembly_path, f"concoct_bins/extracted/{bin_number}.fa")

        else:
            print(f"WARNING: Could not parse bin ID: '{raw_bin}'")
            continue

        # Copy if file exists
        if os.path.exists(src_path):
            dst_name = f"{genome_name}_{tool}_bin{bin_number}.fa"
            dst_path = os.path.join(output_dir, dst_name)
            shutil.copy(src_path, dst_path)
            print(f"Copied: {src_path} -> {dst_path}")
        else:
            print(f"WARNING: File not found: {src_path}")

