#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l ram=256G 
#$ -pe smp 2
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

NUMCPU=16;
let "NUM_THREADS=$NUMCPU * 3"; # Use MAX= 4X of $NUMCPU

DEMUXPEFILE="_demux-paired-end.qza"
VJOINFILE="_demux-vsearch-joined.qza"
VJOINQZV="_demux-vsearch-joined.qzv"
FILTFILE="_vsearch-joined-filtered.qza"
FILTSTATS="_vsearch-joined-filtered-stats.qza"
REPSEQS="_deblur-rep-seqs.qza"
DEBTAB="_deblur-table.qza"
DEBSTATS="_deblur-stats.qza"
DEBQZV="_deblur-table.qzv"

# Step 00: Join read pairs
echo;echo "######################################################";
echo "Step 00: Join read pairs: `date`";echo;
CMD="
qiime vsearch merge-pairs \
  --i-demultiplexed-seqs $DEMUXPEFILE \
  --o-merged-sequences $VJOINFILE
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 01: Viewing a summary of joined data with read quality
echo;echo "######################################################";
echo "Step 01: Viewing a summary of joined data with read quality: `date`";echo;
CMD="
qiime demux summarize \
  --i-data $VJOINFILE \
  --o-visualization $VJOINQZV
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 02: Quality control
echo;echo "######################################################";
echo "Step 02: Quality control: `date`";echo;
CMD="
qiime quality-filter q-score \
  --i-demux $VJOINFILE \
  --o-filtered-sequences $FILTFILE \
  --o-filter-stats $FILTSTATS
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};


# Step 03: Denoise using Deblur. Generate Feature Table and Feature Data
echo;echo "######################################################";
echo "Step 03: Denoise using Deblur. Generate Feature Table and Feature Data: `date`";echo;
CMD="
qiime deblur denoise-16S \
  --i-demultiplexed-seqs $FILTFILE \
  --p-trim-length 240 \
  --p-sample-stats \
  --o-representative-sequences $REPSEQS \
  --o-table $DEBTAB \
  --o-stats $DEBSTATS
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 04: View summary of Deblur feature table
echo;echo "######################################################";
echo "Step 04: View summary of Deblur feature table: `date`";echo;
CMD="
qiime feature-table summarize \
  --i-table $DEBTAB \
  --o-visualization $DEBQZV
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################


