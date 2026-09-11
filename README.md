# MAGSPI
MAG-based Strain Profiling and Identification (MAGSPI) Pipeline 

**MAGSPI** is a SLURM-based workflow for recovering, evaluating, dereplicating, taxonomically classifying, and profiling metagenome-assembled genomes (MAGs) from shotgun metagenomic sequencing data.

The workflow takes paired-end metagenomic reads through:

**read QC → host depletion → assembly → genome binning → bin refinement → MAG quality assessment → taxonomy → dereplication → strain-level profiling**

MAGSPI was developed for execution on a high-performance computing (HPC) cluster using SLURM. Most computationally intensive steps generate and submit SLURM jobs or job arrays so that samples can be processed in parallel.

---

## Workflow overview

```text
Raw paired-end FASTQ
        │
        ▼
      fastp
 Quality filtering
        │
        ▼
 Bowtie2 + SAMtools
    Host alignment
        │
        ▼
     SAMtools
 Non-host extraction
        │
        ▼
      BBMap
 Pair repair / preparation
        │
        ├────────────► SeqKit
        │              Read statistics
        ▼
   metaSPAdes
     Assembly
        │
        ├────────────► QUAST
        │              Assembly QC
        │
        ▼
 ┌────────────┬────────────┬────────────┐
 │  MetaBAT2  │  MaxBin2   │  CONCOCT   │
 └────────────┴────────────┴────────────┘
        │
        ▼
     DAS Tool
 Bin integration / refinement
        │
        ▼
      CheckM
 MAG quality assessment
        │
        ▼
   Extract MAGs
        │
        ├────────────► MAG summaries
        │
        ├────────────► GTDB-Tk
        │              Taxonomy
        ▼
       dRep
  MAG dereplication
        │
        ▼
 Rename contigs +
 build scaffold/MAG mappings
        │
        ▼
 Reference indexing
        │
        ▼
     inStrain
 Sample-level profiling
        │
        ▼
 MAG detection and
 strain-level comparison
```

---

# Repository structure

The scripts are numbered according to their approximate position in the workflow.

| Script                                   | Purpose                                                         |
| ---------------------------------------- | --------------------------------------------------------------- |
| `01_slurm_fastp.sh`                      | Quality control of paired-end reads with fastp                  |
| `02_slurm_host_align.sh`                 | Align paired reads to the host reference                        |
| `03_slurm_host_align_unpaired.sh`        | Align unpaired reads to the host reference                      |
| `04_slurm_host_extract.sh`               | Extract non-host paired and unpaired reads                      |
| `05_slurm_host_extract_unpaired.sh`      | Extract non-host unpaired reads                                 |
| `06_slurm_bbmap.sh`                      | Repair paired reads and combine singleton reads                 |
| `07_extract_read_counts.sh`              | Calculate FASTQ read counts                                     |
| `08_slurm_seqkit.sh`                     | Generate SeqKit statistics                                      |
| `09_combine_seqkit_files.sh`             | Combine sample-level SeqKit statistics                          |
| `10_slurm_assemble.sh`                   | Assemble metagenomes with metaSPAdes                            |
| `11_slurm_quast.sh`                      | Assess assemblies with QUAST                                    |
| `12_slurm_combine_quast.sh`              | Combine assembly statistics                                     |
| `13_slurm_metabat.sh`                    | Generate MetaBAT2 genome bins                                   |
| `14_slurm_maxbin.sh`                     | Generate MaxBin2 genome bins                                    |
| `15_slurm_concoct.sh`                    | Generate CONCOCT genome bins                                    |
| `16_slurm_build_dastool_input.sh`        | Convert binning outputs into DAS Tool input mappings            |
| `17_slurm_dastool.sh`                    | Integrate/refine bins with DAS Tool                             |
| `18_slurm_checkm.sh`                     | Evaluate MAG quality with CheckM                                |
| `19_combine_checkm.sh`                   | Filter/summarize CheckM results                                 |
| `20_extract_hq_genomes.py`               | Extract MAG FASTA files from DAS Tool results                   |
| `21_summmarize_hq_genomes.py`            | Combine and standardize DAS Tool MAG summaries                  |
| `22_slurm_gtdbtk_taxonomy.slurm`         | Assign MAG taxonomy with GTDB-Tk                                |
| `23_slurm_drep.sh`                       | Dereplicate recovered MAGs with dRep                            |
| `24_rename_MAG_contigs.py`               | Add MAG identifiers to contig FASTA headers                     |
| `25_slurm_index.sh`                      | Build Bowtie2 indices for MAG references                        |
| `26_InStrain_profile_97.slurm`           | Profile MAGs with inStrain                                      |
| `27_build_stb.sh`                        | Build a scaffold-to-bin (`.stb`) mapping                        |
| `28_build_maglist.sh`                    | Generate scaffold lists for individual MAGs                     |
| `29_derived_scaffolds.sh`                | Generate a derived scaffold-to-MAG table                        |
| `30_aggregate_instrain_detection.py`     | Aggregate inStrain profiles into sample × MAG detection results |
| `31_instrain_compare_710magarray.sbatch` | Perform inStrain strain comparisons                             |
| `make_saf.py`                            | Generate SAF annotations from MAG FASTA files                   |
| `make_stb.py`                            | Generate scaffold-to-bin mappings                               |

---

# Pipeline stages

## 1. Read quality control

### `01_slurm_fastp.sh`

Raw paired-end reads are processed with **fastp**.

For each sample, the script produces:

* quality-controlled R1 and R2 reads
* reads that become unpaired during QC
* failed-QC reads
* an HTML fastp report

The current fastp command performs adapter detection, requires a minimum read length of 50 bp, and uses an expected error/phred-related setting of `-e 20` as specified in the script.

Input filenames are currently expected to follow a pattern similar to:

```text
<SAMPLE>_R1_combined.fastq.gz
<SAMPLE>_R2_combined.fastq.gz
```

The resulting paired reads follow:

```text
<SAMPLE>_QC_R1.fastq.gz
<SAMPLE>_QC_R2.fastq.gz
```

---

## 2. Host depletion

### `02_slurm_host_align.sh`

### `03_slurm_host_align_unpaired.sh`

Quality-controlled reads are aligned against a host reference using **Bowtie2**.

The current implementation uses an `hg38` Bowtie2 index and processes both paired and unpaired reads.

Alignments are converted from SAM to sorted BAM files using **SAMtools**.

Conceptually:

```text
QC FASTQ
   │
   ▼
Bowtie2 → host reference
   │
   ▼
sorted BAM
```

---

## 3. Non-host read extraction

### `04_slurm_host_extract.sh`

### `05_slurm_host_extract_unpaired.sh`

SAMtools is used to identify unmapped reads and convert them back into FASTQ format.

These reads represent the fraction of the sequencing data that did not align to the host reference and are carried forward for metagenomic assembly.

Outputs include paired non-host reads and non-host singleton reads.

---

## 4. Read repair and preparation

### `06_slurm_bbmap.sh`

**BBMap `repair.sh`** is used to ensure that R1 and R2 reads remain correctly paired after host depletion.

Reads that cannot be paired are written as singleton reads and combined with the existing non-host unpaired reads.

The resulting files used for assembly follow the pattern:

```text
<SAMPLE>_non_host_R1_formeta.fastq.gz
<SAMPLE>_non_host_R2_formeta.fastq.gz
<SAMPLE>_non_host_unpaired_formeta.fastq.gz
```

---

# Read statistics

## `07_extract_read_counts.sh`

Calculates total reads across the paired and unpaired non-host FASTQ files for each sample.

## `08_slurm_seqkit.sh`

Runs:

```bash
seqkit stats
```

on the processed non-host FASTQ files.

## `09_combine_seqkit_files.sh`

Combines individual SeqKit outputs and summarizes read counts by sample.

The summary includes total reads and metrics derived from the R1 and unpaired files.

---

# Metagenomic assembly

## `10_slurm_assemble.sh`

Metagenomic reads are assembled independently for each sample using **metaSPAdes**.

The current command is equivalent to:

```bash
metaspades.py \
    --meta \
    -1 SAMPLE_R1.fastq.gz \
    -2 SAMPLE_R2.fastq.gz \
    -s SAMPLE_unpaired.fastq.gz \
    -o SAMPLE_assembly \
    -t 16 \
    -m 128
```

Each sample therefore produces its own metaSPAdes assembly directory.

The downstream workflow primarily uses:

```text
<SAMPLE>_assembly/contigs.fasta
```

---

# Assembly quality assessment

## `11_slurm_quast.sh`

Assemblies are evaluated with **QUAST**.

For each sample, the corresponding metaSPAdes `contigs.fasta` is passed to QUAST using 16 threads.

## `12_slurm_combine_quast.sh`

Combines assembly-level statistics for downstream review.

---

# Genome binning

MAGSPI uses three independent binning approaches:

1. **MetaBAT2**
2. **MaxBin2**
3. **CONCOCT**

Using multiple binning algorithms allows the resulting bin assignments to subsequently be integrated with DAS Tool.

---

## MetaBAT2

### `13_slurm_metabat.sh`

Reads are mapped back to assembled contigs with Bowtie2, followed by BAM processing with SAMtools.

Contig depth information is generated using:

```text
jgi_summarize_bam_contig_depths
```

MetaBAT2 then uses the assembly and depth information to generate candidate genome bins.

The current minimum contig length passed to MetaBAT2 is:

```text
1500 bp
```

---

## MaxBin2

### `14_slurm_maxbin.sh`

MaxBin2 is run on the same metagenomic assemblies using contig abundance/depth information.

The script uses:

```text
run_MaxBin.pl
```

with 16 threads.

---

## CONCOCT

### `15_slurm_concoct.sh`

The CONCOCT workflow:

1. maps reads back to the assembly
2. sorts and indexes the resulting BAM
3. splits contigs into 10-kb chunks
4. calculates coverage
5. performs composition- and coverage-based binning with CONCOCT

The resulting clustering information is used in the DAS Tool integration stage.

---

# Bin integration with DAS Tool

## `16_slurm_build_dastool_input.sh`

The outputs of MetaBAT2, MaxBin2, and CONCOCT use different bin formats.

This script converts their assignments into standardized:

```text
contig<TAB>bin
```

mapping files for DAS Tool.

## `17_slurm_dastool.sh`

**DAS Tool** integrates the three independent binning results.

The workflow supplies:

```text
MetaBAT2
MaxBin2
CONCOCT
```

assignments together with the original assembly and uses DIAMOND as the search engine.

DAS Tool is run with 32 threads and configured to write the selected bins.

---

# MAG quality assessment

## `18_slurm_checkm.sh`

Recovered bins are evaluated with **CheckM** using:

```text
checkm lineage_wf
```

followed by:

```text
checkm qa
```

The workflow records estimates including genome completeness and contamination.

## `19_combine_checkm.sh`

CheckM results are filtered to retain bins satisfying:

```text
Completeness >= 50%
Contamination <= 10%
```

These thresholds correspond to the filtering implemented in the current script.

---

# MAG extraction and standardization

## `20_extract_hq_genomes.py`

This script extracts genome FASTA files represented in the DAS Tool summaries.

It recognizes bins originating from:

```text
MetaBAT2
MaxBin2
CONCOCT
```

and copies them into a common MAG directory using standardized filenames.

## `21_summmarize_hq_genomes.py`

DAS Tool summaries from multiple samples are combined into a single table.

MAG identifiers are standardized using:

```text
<SAMPLE>_<BINNING_TOOL>_<BIN_NUMBER>
```

For example:

```text
sample01_metabat2_12
sample01_maxbin2_3
sample01_concoct_7
```

The combined output retains the original bin identifier while adding:

```text
MAG_ID
sample
tool
bin_number
raw_bin
```

metadata.

---

# Taxonomic classification

## `22_slurm_gtdbtk_taxonomy.slurm`

Recovered MAGs are taxonomically classified with **GTDB-Tk**.

This provides standardized genome taxonomy for the MAG collection prior to or alongside downstream dereplication and ecological analyses.

> The exact database location, environment, and GTDB-Tk configuration are cluster-specific and should be reviewed before running this step.

---

# MAG dereplication

## `23_slurm_drep.sh`

MAGs are dereplicated with **dRep**.

The current workflow uses:

```bash
dRep dereplicate \
    drep_3518 \
    -g INPUT/*.fa \
    -p 64 \
    -comp 50 \
    -con 10 \
    -sa 0.97
```

This corresponds to:

```text
minimum completeness:     50%
maximum contamination:    10%
secondary ANI threshold:  97%
```

The resulting dereplicated genome collection can then be used as the MAG reference set for downstream profiling.

---

# Preparing MAGs for profiling

## `24_rename_MAG_contigs.py`

Contig identifiers are modified so that each contig contains the MAG identifier from which it originated.

For a MAG named:

```text
sample01_metabat2_12.fa
```

a contig such as:

```text
>NODE_1
```

becomes:

```text
>sample01_metabat2_12_NODE_1
```

This makes scaffold-to-MAG relationships explicit and reduces ambiguity when multiple MAGs are used together downstream.

Usage:

```bash
python 24_rename_MAG_contigs.py <input_folder> <output_folder>
```

---

## `25_slurm_index.sh`

Builds **Bowtie2 indices** for the dereplicated MAG reference genomes.

These indices support read mapping for downstream strain-level profiling.

---

# inStrain analysis

MAGSPI includes downstream utilities for evaluating the occurrence and strain-level variation of recovered MAGs across metagenomic samples.

## `26_InStrain_profile_97.slurm`

Runs **inStrain profiling** against the MAG reference set.

The resulting profiles contain scaffold-level coverage, breadth, and population-genetic information used by later stages of the workflow.

---

# Scaffold-to-MAG mappings

Several helper scripts create mappings between individual scaffolds and their parent MAGs.

## `27_build_stb.sh`

Builds:

```text
contigs2bins.stb
```

with records of the form:

```text
scaffold_ID    MAG_ID
```

This mapping is generated directly from the MAG FASTA headers.

## `28_build_maglist.sh`

Extracts the unique MAG identifiers from the `.stb` file and creates one scaffold list per MAG.

Example:

```text
mag_scaffold_lists/
├── MAG_001.scaffolds.txt
├── MAG_002.scaffolds.txt
└── MAG_003.scaffolds.txt
```

## `29_derived_scaffolds.sh`

Combines the per-MAG scaffold lists into:

```text
derived/scaffold_to_mag.tsv
```

containing:

```text
scaffold    mag
```

---

# MAG detection across samples

## `30_aggregate_instrain_detection.py`

This script combines scaffold-level inStrain results with the scaffold-to-MAG mapping to calculate MAG-level detection statistics for each sample.

For each MAG, breadth is calculated as:

```text
             Σ covered bases
breadth = ─────────────────────
             Σ scaffold length
```

When scaffold coverage is available, MAG coverage is calculated as a length-weighted mean.

By default, a MAG is considered detected when:

```text
breadth  >= 0.50
coverage >= 1.0
```

These thresholds are configurable.

Example:

```bash
python 30_aggregate_instrain_detection.py \
    --profiles_dir /path/to/instrain/profiles \
    --scaffold_to_mag derived/scaffold_to_mag.tsv \
    --breadth_thresh 0.5 \
    --cov_thresh 1.0 \
    --out_prefix mag_detection
```

Outputs include:

```text
mag_detection_per_sample.tsv
mag_detection_per_mag_summary.tsv
```

The per-sample table contains:

```text
sample
mag
breadth
coverage
detected
```

The MAG summary includes:

```text
n_samples
n_detected
mean_breadth
mean_coverage
```

---

# Strain comparison

## `31_instrain_compare_710magarray.sbatch`

This SLURM workflow performs downstream **inStrain comparisons** across the MAG profiles.

This stage is intended for strain-level comparisons after sample-level profiling and MAG detection have been completed.

Because the current script was written for a specific MAG/profile collection, review its array dimensions, paths, and resource settings before applying it to a new dataset.

---

# Supporting utilities

## `make_stb.py`

Creates a scaffold-to-bin mapping from the individual MAG scaffold lists:

```text
scaffold    MAG
```

This provides an alternative/helper route for generating mappings required by downstream analyses.

## `make_saf.py`

Creates a **SAF (Simplified Annotation Format)** representation of the MAG collection.

Usage:

```bash
python make_saf.py /path/to/MAG_FASTAs > mags.saf
```

The output contains:

```text
GeneID    Chr    Start    End    Strand
```

where each MAG acts as the feature identifier and each contig is represented across its full sequence length.

---

# Software requirements

MAGSPI uses the following bioinformatics software across its workflow:

| Software            | Purpose                                           |
| ------------------- | ------------------------------------------------- |
| fastp               | Read QC and adapter/quality filtering             |
| Bowtie2             | Host and reference read alignment                 |
| SAMtools            | Alignment processing and non-host read extraction |
| BBMap               | Paired-read repair                                |
| SeqKit              | FASTQ statistics                                  |
| metaSPAdes / SPAdes | Metagenomic assembly                              |
| QUAST               | Assembly QC                                       |
| MetaBAT2            | Genome binning                                    |
| MaxBin2             | Genome binning                                    |
| CONCOCT             | Genome binning                                    |
| DAS Tool            | Integration/refinement of genome bins             |
| DIAMOND             | DAS Tool search backend                           |
| CheckM              | MAG quality assessment                            |
| GTDB-Tk             | MAG taxonomic classification                      |
| dRep                | MAG dereplication                                 |
| inStrain            | Population and strain-level profiling             |

Python helper scripts additionally require **Python 3** and, depending on the script:

```text
pandas
numpy
```

---

# HPC requirements

The workflow was designed for a **SLURM-managed HPC environment**.

Many scripts dynamically generate a commands file and a corresponding SLURM job-array script before calling:

```bash
sbatch
```

Typical resource requirements vary substantially by stage.

For example, the current workflow requests up to:

```text
metaSPAdes:   16 CPUs / 128 GB
MetaBAT2:     16 CPUs / 128 GB
MaxBin2:      16 CPUs / 128 GB
CONCOCT:      16 CPUs / 128 GB
DAS Tool:     32 CPUs / 128 GB
CheckM:       16 CPUs / 64 GB
dRep:         64 CPUs / 512 GB
```

These values reflect the current scripts and should be adjusted for the dataset and computing environment.

---

# Configuration before running

**The scripts are not currently plug-and-play across computing environments.**

Many contain absolute paths specific to the environment in which MAGSPI was developed, for example:

```text
/hpc/projects/...
/home/...
```

Before running MAGSPI on another system, review each script and modify:

```text
INPUT_DIR
OUTPUT_DIR
reference genome/index paths
database paths
Conda environments
module names
SLURM resource requests
sample filename patterns
SLURM array sizes
```

In particular, host depletion currently references an **hg38** Bowtie2 index. This should be replaced with the appropriate host reference when analyzing samples from another host.

---

# Input naming conventions

Several scripts infer sample identifiers directly from filenames.

The current workflow expects conventions resembling:

```text
<SAMPLE>_R1_combined.fastq.gz
<SAMPLE>_R2_combined.fastq.gz
```

After QC:

```text
<SAMPLE>_QC_R1.fastq.gz
<SAMPLE>_QC_R2.fastq.gz
```

After host depletion/read repair:

```text
<SAMPLE>_non_host_R1_formeta.fastq.gz
<SAMPLE>_non_host_R2_formeta.fastq.gz
<SAMPLE>_non_host_unpaired_formeta.fastq.gz
```

If your input files use another convention, the glob and `sed` expressions that derive `SAMPLE` must be updated accordingly.

---

# Running MAGSPI

The workflow is currently implemented as a collection of scripts rather than a workflow manager such as Nextflow or Snakemake.

A typical run follows the numbered scripts:

```text
01–06   Read QC and host depletion
07–09   Read statistics
10–12   Assembly and assembly QC
13–15   Independent genome binning
16–17   DAS Tool integration
18–19   MAG quality assessment
20–21   MAG extraction and summary
22      GTDB-Tk taxonomy
23      dRep dereplication
24–29   Prepare MAG/scaffold references
30–31   MAG detection and inStrain comparison
```

Run each stage only after confirming that the required outputs from the preceding stage were generated successfully.

For scripts that generate and submit SLURM jobs, running:

```bash
bash <script>
```

may immediately submit jobs to the cluster.

**Review the paths, commands, and SLURM parameters before execution.**

---

# Key outputs

Depending on which portions of MAGSPI are run, major outputs include:

```text
Quality-controlled FASTQ files
Non-host FASTQ files
Read-count / SeqKit summaries
metaSPAdes assemblies
QUAST assembly statistics
MetaBAT2 bins
MaxBin2 bins
CONCOCT bins
DAS Tool refined bins
CheckM quality estimates
Standardized MAG FASTA files
Combined MAG metadata
GTDB-Tk taxonomy
Dereplicated MAGs
Scaffold-to-MAG mappings
inStrain profiles
Sample × MAG detection tables
MAG prevalence summaries
Strain-level comparisons
```

---

# Important notes

MAGSPI currently represents the analysis workflow used during development rather than a fully containerized or environment-independent software package.

Before using the repository on a new dataset:

1. inspect all hard-coded paths;
2. confirm the required software and databases are available;
3. check sample naming conventions;
4. adjust SLURM resources and array sizes;
5. verify intermediate outputs before advancing to the next stage.

Some scripts also retain dataset-specific filenames, sample patterns, output names, or array dimensions from the analyses for which they were originally written. These should be treated as configuration points rather than universal MAGSPI defaults.

---

# Citation

If you use MAGSPI in published work, please cite this repository and the individual software packages used by the workflow.

A formal citation for MAGSPI can be added here if/when one becomes available.

---

# License

Add the repository license here.

---

# Contact

For questions, issues, or suggestions, please open an issue in this repository.
