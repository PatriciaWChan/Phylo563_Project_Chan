# Plastome assembly test script run on local machine

## original script written by Nisa Karimi and adapted by Patricia Chan

## build and install samtools and bcftools

```bash
/Users/pattychan/documents/Phd/Spring_2021/Phylo_563/bcftools-1.13
cd samtools-1.x    # and similarly for bcftools
./configure --prefix=/Users/pattychan/documents/Phd/Spring_2021/Phylo_563/bcftools-1.13
```

### I put this inside of the bcftools folder and I'm not sure if I should have

```bash
make
make install

cd bcftools-1.x
./configure --prefix=/Users/pattychan/documents/Phd/Spring_2021/Phylo_563

### put the installed file into this location (Phylo 563 folder)

make
make install
```

### change default shell to bash

`chsh -s bin/bash`

#### enter user password

### starting location, print working directory (pwd)

`pwd/Users/pattychan/Documents/PhD/Spring_2021/Phylo_563/data_files/All_data`

## ran trimmomatic to quality trim only, did not use adaptor file

```bash
java -jar ../Trimmomatic/trimmomatic-0.39.jar PE ../Darwinia_raw_reads/I32489_S33_L001_R1_001.fastq.gz ../Darwinia_raw_reads/I32489_S33_L001_R2_001.fastq.gz -baseout I32489_L001 SLIDINGWINDOW:5:20
```
### indexed reference genome of eucalyptus albens

```bash
./bwa-0.7.17/bwa index Eucalyptus_albens.fasta
bwa index $Eucalyptus_albens.fasta
```

## ran BWA using reference genome, specifed [reference],[read 1],[read 2] > [output]

`./bwa-0.7.17/bwa mem Eucalyptus_albens.fasta I32489_L001_1P I32489_L001_2P > sample.sam`

### makes a .bam file from the .sam file (I removed the [$] signs from Nisa's script)

#### (Nisa) -h flag in view to include the header

`./samtools-1.13/samtools view -S -b sample.sam > sample.bam`

#### (Nisa) bai files not created with -n but needed for rmdup
#### what did this step do?

./samtools-1.13/samtools sort sample.bam -o sample.sorted.bam
./samtools-1.13/samtools index sample.sorted.bam

## remove PCR duplicates

```bash
./samtools-1.13/samtools sort -n sample.bam -o sample.sortedn.bam
./samtools-1.13/samtools fixmate sample.sortedn.bam sample.fixmate.bam
./samtools-1.13/samtools rmdup sample.fixmate.bam sample.rmdup.bam
./samtools-1.13/samtools sort sample.rmdup.bam -o sample.sorted.rmdup.bam
./samtools-1.13/samtools index sample.sorted.rmdup.bam 
```

### rename file

`mv sample.sorted.rmdup.bam sample.plastome.rmdup.bam`

### summary stats

```bash
./samtools-1.13/samtools flagstat sample.plastome.rmdup.bam > sample.rmdup.mappingstats.txt
./samtools-1.13/samtools depth sample.sorted.bam > sample.depth.txt
./samtools-1.13/samtools coverage sample.sorted.bam > sample.coverage.txt
```

# generate a consensus sequence

## to generate a consensus sequence from a BAM: samtools/vcfutils gives ambiguity codes

#### what did this do?

#### dragged bcftools.exe into the folder with all the rest of the stuff

```bash
./bcftools mpileup --max-depth 5000 -f Eucalyptus_albens.fasta sample.plastome.rmdup.bam | ./bcftools call -mv -Ob -o sample.calls.vcf.gz

./bcftools index sample.calls.vcf.gz

./bcftools consensus -f Eucalyptus_albens.fasta sample.calls.vcf.gz -o sample.plastome.fasta
### rename the sequence per the filename
#### I think we have a plastome now??

awk '/^>/{print ">" substr(FILENAME,1,length(FILENAME)-15); next} 1’ sample.plastome.fasta'
```