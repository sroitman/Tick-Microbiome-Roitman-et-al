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

cd /path/to/raw_fastq

cat *.1.fastq.gz > T16S_novaseq_R1.fastq.gz
cat *.2.fastq.gz > T16S_novaseq_R2.fastq.gz

READS1="/path/to/raw_fastq/T16S_novaseq_R1.fastq.gz";
READS2="/path/to/raw_fastq/T16S_novaseq_R2.fastq.gz";
PREFIX=`basename $READS1 .1.fastq.gz`".fbt"; # Add the "fbt" in prefix to clearly identify fbt-processed files  
echo "PREFIX = $PREFIX";

BBMAP_RESOURCES="/path/to/bbmap_resources";

OUT_STEP00=$PREFIX".step00.clumpified.r1r2.fq.gz";
TMP="tmp00."$PREFIX".r1r2.fq.gz";
echo "tmp = $TMP";
OUT_STEP01=$PREFIX".step01.filtered_by_tile.fq.gz";
OUT_STEP02=$PREFIX".step02.no-adapters.r1r2.fq.gz";
OUT_STEP03=$PREFIX".step03.no-phiX.r1r2.fq.gz";
OUT_STEP03_PHIX_STATS=$PREFIX".step03.phix-stats.txt";

OUT_STEP04=$PREFIX".step04.no-polyG.r1r2.fq.gz";
OUT_STEP05=$PREFIX".step05.no-polyC.r1r2.fq.gz";
OUT_STEP06=$PREFIX".step06.no-polyA.r1r2.fq.gz";
OUT_STEP07=$PREFIX".step07.no-polyT.r1r2.fq.gz";

OUT_STATS=$PREFIX".fbt-preprocessing.stats";

# Based on: https://jgi.doe.gov/data-and-tools/bbtools/bb-tools-user-guide/data-preprocessing/
#:<<'RUN_ONLY_FASTQC'
# Step 00: Clumpify reads to get rid of PCR/optical duplicates and other NextSeq artifacts. (Change to interleaved format first)
# See clumpify recommendations from Devon Ryan at : https://www.biostars.org/p/277013
echo;echo "######################################################";
echo "Step 00: Interleave: `date`";echo;
CMD="reformat.sh -Xmx64g in1=$READS1 in2=$READS2 out=$TMP";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "Step 00: Clumpify: `date`";echo;
echo;echo "######################################################";
CMD="clumpify.sh -Xmx64g in=$TMP out=$OUT_STEP00 markduplicates=f";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 01: Filter-by-Tile.
echo;echo "######################################################";
echo "Step 01: Use filter_by_tile to remove bad quality reads/tiles: `date`";echo;
CMD="filterbytile.sh -Xmx64g in=$TMP out=$OUT_STEP01";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 02: #Adapter trimming. Tool: BBDuk.
echo;echo "######################################################";
echo "Step 02: Adapter trimming, Quality-based trimming: `date`";echo;
CMD="bbduk.sh -Xmx64g in=$OUT_STEP01 out=$OUT_STEP02 ktrim=r k=23 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/truseq.fa.gz",$BBMAP_RESOURCES"/NEB_adapters.fa.gz" minlength=50 tpe tbo ftm=5";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 03: Contaminant filtering for synthetic molecules and spike-ins such as PhiX. Always recommended. Tool: BBDuk.
echo;echo "######################################################";
echo "Step 03: phiX rmoval: `date`";echo;
CMD="bbduk.sh -Xmx64g in=$OUT_STEP02 out=$OUT_STEP03 k=31 ref=$BBMAP_RESOURCES"/phix174_ill.ref.fa.gz",$BBMAP_RESOURCES"/sequencing_artifacts.fa.gz" stats=$OUT_STEP03_PHIX_STATS minlength=50 ordered cardinality";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo;echo "######################################################";
echo "Step 04: poly-G removal: `date`";echo;
CMD="bbduk.sh -Xmx64g in=$OUT_STEP03 out=$OUT_STEP04 ktrim=r k=13 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/poly-G.fa" qtrim=r trimq=10 minlength=50";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
echo;echo "######################################################";
echo "Step 05: poly-C removal: `date`";echo;
CMD="bbduk.sh -Xmx64g in=$OUT_STEP04 out=$OUT_STEP05 ktrim=r k=13 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/poly-C.fa" qtrim=r trimq=10 minlength=50";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
echo;echo "######################################################";
echo "Step 06: poly-A removal: `date`";echo;
CMD="bbduk.sh -Xmx64g in=$OUT_STEP05 out=$OUT_STEP06 ktrim=r k=13 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/poly-A.fa" qtrim=r trimq=10 minlength=50";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
echo;echo "######################################################";
echo "Step 07: poly-T removal: `date`";echo;
CMD="bbduk.sh -Xmx64g in=$OUT_STEP06 out=$OUT_STEP07 ktrim=r k=13 mink=11 hdist=1 ref=$BBMAP_RESOURCES"/poly-T.fa" qtrim=r trimq=10 minlength=50";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

CMD="rm -rf $TMP";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

conda activate seqkit

CMD="seqkit stats --threads $NUM_THREADS $PREFIX*.gz --out-file $OUT_STATS";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
#RUN_ONLY_FASTQC

#:<<'SKIP_FASTQC'
echo "Step 01-B: Run fastqc to see effect of filter_by_tile ?";
CMD="fastqc --nogroup -t $NUM_THREADS $OUT_STEP00";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
CMD="fastqc --nogroup -t $NUM_THREADS $OUT_STEP01";
echo;echo "Running: $CMD [`date`]";eval ${CMD};
#SKIP_FASTQC

echo "DONE: `date`";
############### END OF SCRIPT #################################