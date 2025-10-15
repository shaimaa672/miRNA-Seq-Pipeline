# miRNA-seq Analysis Pipeline

A simple, automated pipeline for miRNA sequencing data analysis from Illumina platforms.

## 🚀 Quick Start

```bash
# 1. Download this pipeline
git clone https://github.com/shaimaa672/miRNA-seq-pipeline.git
cd miRNA-seq-pipeline

# 2. Make script executable
chmod +x miRNA_pipeline.sh

# 3. Update paths in the script 
nano miRNA_pipeline.sh

# 4. Run the pipeline
./miRNA_pipeline.sh

#If you don't know your adapter sequence, use fastp for automatic adapter detection:
# Install fastp
conda install -c bioconda fastp
fastp -i input.fastq.gz -o trimmed.fastq.gz --detect_adapter_for_pe
