#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l ram=256G
#$ -pe smp 4 
# To get an e-mail when the job is done:
#$ -m e
#$ -M useremail@useraddress
# Long-running jobs (>30 minutes) should be submitted with:
#$ -q long.q
# export all environment variables to SGE
#$ -V


set -ue;

echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################

NUMCPU=24;
let "NUM_THREADS=$NUMCPU * 3"; # Use MAX= 4X of $NUMCPU

BBTOOLSOUT="/path/to/_.step07.no-polyT.r1r2.fq.gz";
BARCODES="/path/to/barcodesfile.txt";

# Step 00: Demultiplex seqence file using Demultiplex program
echo;echo "######################################################";
echo "Step 00: Demultiplex seqence file using Demultiplex program: `date`";echo;
CMD="demultiplex demux $BARCODES $BBTOOLSOUT";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 01: Repair and deinterleave paired-end files
echo;echo "######################################################";
echo "Step 01.1: Get names for all demultiplexed sample files, check to ensure names are correct: `date`";echo;
CMD="
for i in *.fastq.gz.fbt.step07.no-polyT.r1r2.fq.gz
do
	SAMPLE=$(echo ${i})
	echo ${SAMPLE}
done
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "######################################################";
echo "Step 01.2: Set prefix for file names: `date`";echo;
CMD="
PREFIX=$(echo $SAMPLE | sed "s/\.fastq.gz.fbt.step07.no-polyT.r1r2.fq.gz//");
echo "prefix=$PREFIX";
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "######################################################";
echo "Step 01.3: Repair reads, then deinterleave repaired read file: `date`";echo;
CMD="
for i in *.fastq.gz.fbt.step07.no-polyT.r1r2.fq.gz
do
	SAMPLE=$(echo ${i})
	PREFIX=$(echo $SAMPLE | sed "s/\.fastq.gz.fbt.step07.no-polyT.r1r2.fq.gz//")
	repair.sh in=$SAMPLE out=$PREFIX.fixed.r1r2.fq.gz outs=$PREFIX.singletons.r1r2.fq.gz repair
	reformat.sh in=$PREFIX.fixed.r1r2.fq.gz out1=$PREFIX.R1.fq.gz out2=$PREFIX.R2.fq.gz
done
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################


