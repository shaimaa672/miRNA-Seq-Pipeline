#!/bin/bash
# Automated miRNA-seq Pipeline for Illumina


set -e

echo "=== miRNA-seq Analysis Pipeline ==="
echo "Started: $(date)"

# Configuration
THREADS=30                       # adjust threads according to your PC specs
ADAPTER="TGGAATTCTCGGGTGCCAAGG"  # adapter sequence 
MIN_LEN=15
MAX_LEN=30

# Create output directories
mkdir -p {fastqc,trimmed_fastq,mapping,counts}

# Function to check and activate conda environments
activate_env() {
    local env_name=$1
    if conda env list | grep -q "$env_name"; then
        echo "Activating $env_name environment..."
        conda activate "$env_name"
    else
        echo "ERROR: Conda environment '$env_name' not found!"
        echo "Please create it using: conda create -n $env_name -c bioconda [packages]"
        exit 1
    fi
}

# Function to run command in specific conda environment
run_in_env() {
    local env_name=$1
    local command=$2
    echo "[$env_name] $command"
    activate_env "$env_name"
    eval "$command"
    conda deactivate
}

# Step 1: Quality Control (base environment)
echo "1. Quality control..."
activate_env "base"
for f in *.fastq.gz; do
    if [ -f "$f" ]; then
        echo "Processing $f with FastQC..."
        fastqc "$f" -o fastqc/ --threads $THREADS
    fi
done
conda deactivate

# Step 2: Adapter Trimming (base environment)  
echo "2. Adapter trimming..."
activate_env "base"
for f in *.fastq.gz; do
    if [ -f "$f" ]; then
        echo "Trimming $f..."
        cutadapt -a $ADAPTER \
                 -o "trimmed_fastq/${f%.fastq.gz}_trimmed.fastq.gz" \
                 --minimum-length $MIN_LEN \
                 --maximum-length $MAX_LEN \
                 --quality-cutoff 20 \
                 --cores $THREADS \
                 "$f"
    fi
done
conda deactivate

# Step 3: Post-trimming QC (base environment)
echo "3. Quality control after trimming..."
activate_env "base"
for f in trimmed_fastq/*_trimmed.fastq.gz; do
    if [ -f "$f" ]; then
        echo "QC for trimmed file: $f"
        fastqc "$f" -o fastqc/ --threads $THREADS
    fi
done
conda deactivate

# Step 4: Mapping with Bowtie2 (bowtie2 environment)
echo "4. Mapping with Bowtie2..."
activate_env "bowtie2"

# Check if Bowtie2 index exists
if [ ! -f "/path/to/bowtie2/index.1.bt2" ]; then
    echo "ERROR: Bowtie2 index not found at /path/to/bowtie2/index"
    echo "Please update the path in the script"
    exit 1
fi

for f in trimmed_fastq/*_trimmed.fastq.gz; do
    if [ -f "$f" ]; then
        sample=$(basename "$f" _trimmed.fastq.gz)
        echo "Mapping $sample..."
        
        bowtie2 --end-to-end --very-sensitive \
                --threads $THREADS \
                -x /path/to/bowtie2/index \
                -U "$f" \
                -S "mapping/${sample}.sam" \
                2> "mapping/${sample}_bowtie2.log"
        
        # Convert to BAM and sort
        samtools view -@ $THREADS -bhS "mapping/${sample}.sam" > "mapping/${sample}.bam"
        samtools sort -@ $THREADS "mapping/${sample}.bam" -o "mapping/${sample}_sorted.bam"
        samtools index "mapping/${sample}_sorted.bam"
        
        # Clean up
        rm "mapping/${sample}.sam" "mapping/${sample}.bam"
        
        echo "→ Alignment rate: $(grep 'overall alignment rate' "mapping/${sample}_bowtie2.log" | awk '{print $1}')"
    fi
done

conda deactivate

# Step 5: Feature Counting (featurecounts environment)
echo "5. Feature counting..."
activate_env "featurecounts"

# Check if GTF file exists
if [ ! -f "/path/to/annotation.gtf" ]; then
    echo "ERROR: GTF file not found at /path/to/annotation.gtf"
    echo "Please update the path in the script"
    exit 1
fi

# Get all BAM files
bam_files=(mapping/*_sorted.bam)

if [ ${#bam_files[@]} -eq 0 ]; then
    echo "ERROR: No BAM files found for feature counting!"
    exit 1
fi

echo "Counting features for ${#bam_files[@]} samples..."
featureCounts -T $THREADS \
              -s 2 \
              -a /path/to/annotation.gtf \
              -o "counts/miRNA_counts.txt" \
              "${bam_files[@]}"

conda deactivate

echo "=== Pipeline completed! ==="
echo "Finished: $(date)"
echo ""
echo "📊 OUTPUT SUMMARY:"
echo "✓ QC reports:          fastqc/"
echo "✓ Trimmed reads:       trimmed_fastq/" 
echo "✓ BAM files:           mapping/"
echo "✓ Count matrix:        counts/miRNA_counts.txt"
echo "✓ Alignment stats:     mapping/*_bowtie2.log"

