# miRNA-Seq Pipeline

An automated upstream analysis pipeline for small RNA-seq (miRNA-seq) data from Illumina sequencers. Takes raw FASTQ files through quality control, adapter trimming, alignment, and feature counting to produce a ready-to-use count matrix for downstream differential expression or biomarker analysis.

## Overview

This pipeline was built for processing miRNA-seq data in a pediatric cancer research context, where consistent, reproducible preprocessing is essential before differential expression and pathway enrichment analysis. It automates the steps that are usually repeated by hand for every sample:

1. **Quality control** on raw reads (FastQC)
2. **Adapter trimming** with length filtering for mature miRNAs (Cutadapt)
3. **Post-trim quality control** (FastQC)
4. **Alignment** to a reference genome or miRNA index (Bowtie2)
5. **Feature counting** to generate a sample-by-miRNA count matrix (featureCounts)

## Requirements

- Conda (Miniconda or Anaconda)
- Three conda environments (see `environment_base.yml`, `environment_bowtie2.yml`, `environment_featurecounts.yml`):
  - `base`: fastqc 0.12.1, cutadapt 4.4, multiqc 1.14
  - `bowtie2`: bowtie2 2.5.1, samtools 1.17
  - `featurecounts`: subread 2.0.6 (featureCounts)
- A Bowtie2 index built for your reference genome/miRBase reference
- A GTF annotation file matching your reference

## Setup

```bash
# Clone the repo
git clone https://github.com/shaimaa672/miRNA-Seq-Pipeline.git
cd miRNA-Seq-Pipeline

# Create the three environments
conda env create -f environment_base.yml
conda env create -f environment_bowtie2.yml
conda env create -f environment_featurecounts.yml
```

The pipeline script activates each environment as needed for its corresponding step (`conda activate base`, `conda activate bowtie2`, `conda activate featurecounts`).

Before running, edit `miRNA_pipeline.sh` and update:
- `THREADS` to match your available CPU cores
- The Bowtie2 index path (currently `/path/to/bowtie2/index`)
- The GTF annotation path (currently `/path/to/annotation.gtf`)

## Usage

Place your raw `.fastq.gz` files in the working directory, then run:

```bash
bash miRNA_pipeline.sh
```

## Output

```
fastqc/           # QC reports, pre- and post-trimming
trimmed_fastq/    # Adapter-trimmed, length-filtered reads (15-30 nt)
mapping/          # Sorted, indexed BAM files + Bowtie2 alignment logs
counts/           # Final count matrix (miRNA_counts.txt)
multiqc/          # Aggregated QC report across all samples (MultiQC)
```

The final `counts/miRNA_counts.txt` file is a sample-by-feature count matrix ready to load directly into R (e.g. `edgeR`, `DESeq2`) or Python for downstream differential expression and pathway enrichment analysis.

## Notes

- Adapter sequence defaults to the Illumina small RNA adapter (`TGGAATTCTCGGGTGCCAAGG`); change in the script if using a different library prep kit.
- Length filtering (15-30 nt) is tuned for mature miRNAs; adjust `MIN_LEN`/`MAX_LEN` for other small RNA species.
- See `CONFIG_NOTES.md` for additional configuration details.
- MultiQC lives in the `base` environment alongside FastQC and Cutadapt, since it's typically run right after the QC steps.

## License

MIT License, see `LICENSE`.
