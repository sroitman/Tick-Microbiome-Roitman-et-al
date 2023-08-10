# Pipeline description and scripts used in tick microbiome project (Roitman et al., in preparation)
- Description of pipelines and scripts used for analyzing 16S microbiome data sequenced from *Ixodes scapularis* samples.
- The scripts described here were run on an SGE / Grid Engine via qsub.
- All required software was installed using conda under various environments.
- Scripts in the R Markdown file (Tick16S_Analysis_Pipeline_20230810.Rmd) were run on RStudio v. 022.12.0+353 and R v. 4.1.1


## Authors:
- Sofia Roitman (New England Biolabs, Ipswich, MA, US)


## Processing and cleaning pipeline for 16S sequencing data (2x250, NovaSeq SP)

### Step 1: Clean reads using BBTools suite
- Script: job001-bbmap-preprocess.sh
- A list of what the BBMap pre-process script does, in order of operation:
  - CD into the folder containing the raw FastQ files output by the sequencer.
  - Combine all forward reads into one file using cat. Do the same for the reverse reads.
  - Assign variables.
  - Step 00: Interleaves the two read files.
  - Step 00: Clumpify. Clumpify rapidly groups overlapping reads into clumps, increasing file compression and helping to process the reads faster.
  - Step 01: Filter by Tile. This command removes bad quality reads/tiles.
  - Step 02: Adapter trimming. This step removes the adapters listed in the truseq.fa.gz and NEB_adapters.fa.gz files. There are several other options that are used in this command:
    - ktrim=r  : right-trimming of 3' adapters
    - k=23  : kmer size used. Must be at most the length of the adapters.
    - mink=11  : use shorter Khmers at the ends of the read, here 11 for the last 11 bases.
    - hdist=1  : hamming distance; allows one mismatch
    - minlength=50  : throws away reads that are less than 50bp after trimming.
    - tpe  : specifies to trim both reads to the same length in the event that an adapter kmer was only detected in one of them.
    - tbo  : specifies to also trim adapters based on pair overlap detection.
    - ftm=5  : f trim modulo. An explanation from the BBTools website: The reason for this is that with Illumina sequencing, normal runs are usually a multiple of 5 in length (50bp, 75bp, 100bp, etc), but sometimes they are generated with an extra base (51bp, 76bp, 151bp, etc). This last base is very inaccurate and has badly calibrated quality as well, so it’s best to trim it before doing anything else. But you don’t want to simply always trim the last base, because sometimes the last base will already be clipped by Illumina’s software. “ftm=5” will, for example, convert a 151bp read to 150bp, but leave a 150bp read alone.
  - Step 03: PhiX removal.
  - Step 04: Poly-g tail removal.
  - Step 05: Poly-C tail removal.
  - Step 06: Poly-A tail removal.
  - Step 07: Poly-T tail removal. The output of this step is the final output file from processing.
  - Remove the temporary files that were created.
  - Run SeqKit to get summary stats on all of the output files generated during processing.
  - Step 01-B: OPTIONAL, run FastQC to look at the effect of filter_by_tile.

FINAL WORKABLE OUTPUT FILE: ___.step07.no-polyT.r1r2.fq.gz

### Step 2: Prepare sequence file for import into QIIME2 qza format: demultiplex, repair, and deinterleave
- Script: job002-demux-repair-deinterleave.sh
- A list of what this script does, in order of operation:
  - Assign variables.
  - Step00: Demultiplex sequence file ___.step07.no-polyT.r1r2.fq.gz
  - Step01.1: Run for-loop to get names for all demultiplexed sample files and check to ensure names are correct.
  - Step01.2: Set prefix for file names.
  - Step01.3: Repair reads, then deinterleave repaired read file.

FINAL WORKABLE OUTPUT FILES: Paired-end read files for each sample.

- Script: job003-remove-primers.sh
- Removes primer sequences from reads.

### Step 3: Import sequence files into QIIME2 qza format
- Script: job004-QIIME2-import.sh
- A list of what this script does, in order of operation:
  - Assign variables.
  - Step00: Import FASTQ files into QIIME2 format.
  - Step01: Create a qzv vile for visualization of read quality using the QIIME2 viewer.

 FINAL WORKABLE OUTPUT FILES: _demux-paired-end.qza

### Step 4: Denoise data using Deblur
- Script: job005-Deblur.sh
- A list of what this script does, in order of operation:
  - Assign variables.
  - Step00: Merge paired-end reads using vsearch.
  - Step01: Create a qzv vile for visualization of the Vsearch-joined file using the QIIME2 viewer.
  - Step02: Filter reads based on q-scores.
  - Step03: Run Deblur on the filtered reads. Reads must be trimmed to the same exact length; 240bp was chosen. Any reads less than 240bp in length are discarded. The denoise-16S portion of the command indicates the use of a 16S reference database as a positive filter. The reference used is the 88% OTUs from Greengages 13_8. The reference is used to assess whether each sequence is likely to be 16S by a local alignment using SortMeRNA with a permissive e-value; the reference is not used to characterize sequences.
  - Step04: Create a qzv vile for visualization of the Deblur feature table using the QIIME2 viewer.

FINAL WORKABLE OUTPUT FILES: Deblur representative sequences (_deblur-rep-seqs.qza) and feature table (_deblur-table.qza)

### Step 5: Generate phylogenetic tree
- Script: job006-phylogenetic-tree.sh
- Creates tree using qiime phylogeny align-to-tree-mafft-fasttree command.

FINAL WORKABLE OUTPUT FILES: Rooted (_deblur-rooted-tree.qza) and unrooted (_deblur-unrooted-tree.qza) phylogenetic trees.

### Step 6: Assign taxonomy
- Script: job007-kraken2-assign-taxonomy.sh
- Assigns taxonomy to representative sequences using Kraken2 and formats output file into a taxonomy table using TaxonKit
- A list of what this script does, in order of operation:
  - Assign variables.
  - Step00: Export QIIME2 rep-seqs file to FASTA format
  - Step01: Run Kraken2 to assign taxonomy to representative sequences
  - Step02: Extract sequence taxonomy IDs from Kraken file
  - Step03: Get taxonomic lineage for each taxonomy ID
  - Step04: Reformat taxonkit lineage file to show canonical, tab-separated ranks
  - Step05: Add column names to taxonomy file

FINAL WORKABLE OUTPUT FILES: Taxonomy file (_kraken2_taxids_lineage_formatted_colnames.txt)

Deblur feature table, rooted phylogenetic tree, and taxonomy file were imported into R for further processing and analysis: see Tick16S_Analysis_Pipeline_20230810.Rmd file.
















