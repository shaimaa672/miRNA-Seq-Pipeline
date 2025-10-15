# Configuration Notes

## Required Setup


### 1. Install samtools 

sudo apt-get install samtools

#### 2. Conda Environments
```bash
# Base environment 
conda install -c bioconda fastqc cutadapt

# Bowtie2 environment
conda create -n bowtie2 -c bioconda bowtie2 -y && conda activate bowtie2

# FeatureCounts environment  
conda create -n featurecounts -c bioconda subread -y



