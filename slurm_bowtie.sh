#!/bin/bash
#
#
# Example SLURM script to run a job on the HPC.
# The lines beginning #SBATCH set various queuing parameters.
#
# Set name of submitted job
#SBATCH --job-name=bowtie
#SBATCH --nodes=4
#SBATCH --cpus-per-task=4
# Submit with maximum 24 hour walltime HH:MM:SS
#SBATCH -t 24:00:00

echo 'Your job is running on node(s):'
echo $SLURM_JOB_NODELIST
echo 'Cores per node:'
echo $SLURM_TASKS_PER_NODE

module load anaconda
module load bowtie2

echo "Building index for hg38"
`bowtie2-build /hpc/reference/sequencing_alignment/fasta_references/human_gencode_v41.fa hg38`

echo "Index complete"



