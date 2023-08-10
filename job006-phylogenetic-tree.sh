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
# #$ -q long.q
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

REPSEQS="_deblur-rep-seqs.qza"
ALGNMT="deblur-aligned-rep-seqs.qza"
MALGNMT="_deblur-masked-aligned-rep-seqs.qza"
UTREE="_deblur-unrooted-tree.qza"
RTREE="_deblur-rooted-tree.qza"

# Here we will be generating a tree for phylogenetic diversity analyses

echo;echo "######################################################";
echo "The following command was executed  to generate a tree: `date`";echo;
CMD="
qiime phylogeny align-to-tree-mafft-fasttree \
  --i-sequences $REPSEQS \
  --o-alignment $ALGNMT \
  --o-masked-alignment $MALGNMT \
  --o-tree $UTREE \
  --o-rooted-tree $RTREE
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};

echo "DONE: `date`";
############### END OF SCRIPT #################################