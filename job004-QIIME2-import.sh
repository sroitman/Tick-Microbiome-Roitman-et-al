#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l ram=80G
#$ -pe smp 4 
# To get an e-mail when the job is done:
#$ -m e
#$ -M useremail@useraddress
# Long-running jobs (>30 minutes) should be submitted with:
#$ -q long.q
# export all environment variables to SGE
#$ -V

conda activate qiime2-2023.2

set -ue;

echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################

NUMCPU=4;
let "NUM_THREADS=$NUMCPU * 2"; # Use MAX= 4X of $NUMCPU


# This file details the commands use to import the 16S tick data to QIIME2

# Files must be uploaded using the Casava 1.8 Demultiplexed Unpaired format, since it is the only format that allows for uploading the demultiplexed unpaired files belonging to each sample

# Following commands were used for upload

FASTQPATH="/path/to/fastqfolder"
QZAFILE="_demux-paired-end.qza"
QZVFILE="_demux-paired-end.qzv"

echo;echo "######################################################";
echo "Step00: Import FASTQ files into QIIME2 format: `date`";echo;
CMD="
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path $FASTQPATH \
  --input-format CasavaOneEightSingleLanePerSampleDirFmt \
  --output-path $QZAFILE
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Unpaired reads have been imported as _demux-paired-end.qza

echo;echo "######################################################";
echo "Step01: Create a qzv vile for visualization of read quality using the QIIME2 viewer: `date`";echo;
CMD="
qiime demux summarize \
--i-data $QZAFILE \
--o-visualization $QZVFILE
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################
