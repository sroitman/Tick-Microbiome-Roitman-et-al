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

conda activate bbmap

set -ue;

echo "Running script $0 on `hostname`";
echo "Running in folder `pwd`";
echo "Job is:"
################################################
cat $0;
################################################

NUMCPU=24;
let "NUM_THREADS=$NUMCPU * 3"; # Use MAX= 4X of $NUMCPU

cd /path/to/demultiplexed/fastq/


# Remove primers from FASTQ files
echo;echo "######################################################";
echo "Remove primers from FASTQ files: `date`";echo;
CMD="
for i in *_R1_001.fastq.gz
do
  SAMPLE=$(echo ${i} | sed "s/_R1\_001.fastq\.gz//")
  echo ${SAMPLE}_R1.fastq.gz ${SAMPLE}_R2.fastq.gz
  bbduk.sh -Xmx64g in=${SAMPLE}_R1_001.fastq.gz in2=${SAMPLE}_R2_001.fastq.gz out1=${SAMPLE}trimmed_R1_001.fastq.gz out2=${SAMPLE}trimmed_R2_001.fastq.gz literal=GTGYCAGCMGCCGCGGTAA,GGACTACNVGGGTWTCTAAT ktrim=l k=5 mink=11 hdist=1 minlength=50 tpe tbo ftm=5
done
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################


























