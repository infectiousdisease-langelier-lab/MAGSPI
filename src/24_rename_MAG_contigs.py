#!/usr/bin/env python3

import os
import sys
from pathlib import Path

def rename_contigs(input_dir, output_dir):
    input_dir = Path(input_dir)
    output_dir = Path(output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)

    for fasta_path in input_dir.glob("*.fa"):
        mag_name = fasta_path.stem  # filename without extension
        output_file = output_dir / fasta_path.name

        with open(fasta_path, "r") as infile, open(output_file, "w") as outfile:
            for line in infile:
                if line.startswith(">"):
                    contig = line.strip().lstrip(">")
                    new_contig = f">{mag_name}_{contig}"
                    outfile.write(new_contig + "\n")
                else:
                    outfile.write(line)

        print(f"Renamed contigs in {fasta_path.name} -> {output_file.name}")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: rename_MAG_contigs.py <input_folder> <output_folder>")
        sys.exit(1)

    rename_contigs(sys.argv[1], sys.argv[2])

