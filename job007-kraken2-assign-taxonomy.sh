#!/bin/bash
#$ -cwd
#$ -j y
#$ -S /bin/bash
#$ -l ram=128G 
#$ -pe smp 4 
# To get an e-mail when the job is done:
#$ -m e
#$ -M sroitman@neb.com
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

REPSEQS="_deblur-rep-seqs.qza";
REPSEQSFOLDER="output/path/to/repseqs/fasta/folder"
DBNAME="/path/to/kraken_db_standard_20230314";
FASTA="path/to/_deblur-rep-seqs.fasta";
PREFIX=`basename $FASTA .fasta`;
echo "prefix=$PREFIX";

KRAKENOUT=$PREFIX".kraken2";
KRAKENREPORT=$PREFIX".kraken2report";

KRAKTAXIDS=$PREFIX"_kraken2_taxids.txt";
KRAKLIN=$PREFIX"_kraken2_taxids_lineage.txt";
KRAKLINFORM=$PREFIX"_kraken2_taxids_lineage_formatted.txt";
KRAKLINFORMCOL=$PREFIX"_kraken2_taxids_lineage_formatted_colnames.txt";

conda activate qiime2-2023.2

# Step 00: Export QIIME2 rep-seqs file to FASTA format
echo;echo "######################################################";
echo "Step 00: Export QIIME2 rep-seqs file to FASTA format: `date`";echo;
CMD="
qiime tools export --input-path $REPSEQS --output-path $REPSEQSFOLDER
"
echo;echo "Running: $CMD [`date`]";eval ${CMD};


conda activate kraken2

# Step 01: Run Kraken2 to assign taxonomy to representative sequences
echo;echo "######################################################";
echo "Step 01: Run Kraken2 to assign taxonomy to representative sequences: `date`";echo;
CMD="kraken2 --db $DBNAME --threads $NUMCPU --report $KRAKENREPORT --output $KRAKENOUT $FASTA";
echo;echo "Running: $CMD [`date`]";eval ${CMD};


conda activate taxonkit

# Step 02: Extract sequence taxonomy IDs from kraken file
echo;echo "######################################################";
echo "Step 02: Extract sequence taxonomy IDs from kraken file: `date`";echo;
CMD="awk '{print $3}' $KRAKENOUT > $KRAKTAXIDS";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 03: Get taxonomic lineage for each taxonomy ID
echo;echo "######################################################";
echo "Step 03: Get taxonomic lineage for each taxonomy ID: `date`";echo;
CMD="taxonkit lineage $KRAKTAXIDS > $KRAKLIN";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 04: Reformat taxonkit lineage file to show canonical, tab-separated ranks
echo;echo "######################################################";
echo "Step 04: Reformat taxonkit lineage file to show canonical, tab-separated ranks: `date`";echo;
CMD="cat $KRAKLIN | taxonkit reformat | csvtk -H -t cut -f 1,3 | csvtk -H -t sep -f 2 -s ';' -R > $KRAKLINFORM";
echo;echo "Running: $CMD [`date`]";eval ${CMD};

# Step 05: Add column names to taxonomy file
echo;echo "######################################################";
echo "Step 05: Add column names to taxonomy file: `date`";echo;
CMD="echo -e "taxid\tKingdom\tPhylum\tClass\tOrder\tFamily\tGenus\tSpecies" | cat - $KRAKLINFORM > $KRAKLINFORMCOL"
echo;echo "Running: $CMD [`date`]";eval ${CMD};


echo "DONE: `date`";
############### END OF SCRIPT #################################

