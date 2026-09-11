#!/usr/bin/env python3
import sys, gzip
from pathlib import Path

def openmaybe(p):
    return gzip.open(p, 'rt') if str(p).endswith(('.gz','.bgz','.gz2')) else open(p, 'r')

def fasta_iter(fp):
    name, seq = None, []
    for line in fp:
        if line.startswith('>'):
            if name is not None:
                yield name, ''.join(seq)
            name = line[1:].strip().split()[0]  # contig id up to first whitespace
            seq = []
        else:
            seq.append(line.strip())
    if name is not None:
        yield name, ''.join(seq)

# Usage: python make_saf.py MAG_FASTAs > mags.saf
mag_dir = Path(sys.argv[1])
print("GeneID\tChr\tStart\tEnd\tStrand")
for fa in sorted(mag_dir.glob("*.fa*")):  # .fa, .fasta, .fa.gz, etc.
    mag_id = fa.stem  # e.g., S1_metabat2_12 from S1_metabat2_12.fa
    with openmaybe(fa) as fh:
        for contig, seq in fasta_iter(fh):
            print(f"{mag_id}\t{contig}\t1\t{len(seq)}\t.")

