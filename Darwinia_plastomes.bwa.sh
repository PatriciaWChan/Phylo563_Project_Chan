#!/bin/bash
##args = $(CLUSTER) $(PROCESS) $(SAMPLE) $(READS1) $(READS2) $(READS3) $(READS4) $(REFERENCE)
### original script written by Nisa Karimi, adapted by Patricia Chan
CLUSTER=$1; shift
PROCESS=$1; shift

sample=$1; shift
reads1=$1; shift
reads2=$1; shift
reads3=$1; shift
reads4=$1; shift
referenceSeq=$1; shift

###############
####Unzip programs
###PATHS for each program needed here
tar zxf sam_bcf_tools.tar.gz
#tar zxf bcftools-1.14.tar.bz2 bwa-0.7.17.tar-1.bz2 samtools-1.14.tar.bz2
ls -lh
ls ./Trimmomatic-0.39

#export PATH=$(pwd)/Trimmomatic-0.39:$PATH
#export PATH=$(pwd)/sam_bcf_tools/vcftools_0.1.13/bin:$PATH
export PATH=$(pwd)/sam_bcf_tools/samtools-1.14:$PATH ###no longer requires ./samtools which refers to 1.3 in home
export PATH=$(pwd)/sam_bcf_tools/bcftools-1.14:$PATH

export PATH=$(pwd)/bwa-0.7.17:$PATH
#export PATH=$(pwd)/samtools-1.3.1:$PATH
#export PATH=$(pwd)/samtools:$PATH

#git clone https://github.com/lh3/seqtk.git
#cd seqtk
#make
#cd ..
##############

## stage file(s);
/bin/echo "Staging files.."
cp $reads1 ./
cp $reads2 ./
cp $reads3 ./
cp $reads4 ./

ls *.fastq

reads1=$(basename $reads1)
reads2=$(basename $reads2)
reads3=$(basename $reads3)
reads4=$(basename $reads4)

###################
##Program Commands

/bin/echo "Printing Args.."
ls $reads1
ls $reads3
echo $sample

/bin/echo "Starting Trimmomatic.."
#line 61 previously commented out by Nisa
#java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads1 $reads2 $sample_P1.fq.gz $sample_U1.fq.gz $sample_P2.fq.gz $sample_U2.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20
java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads1 $reads2 $sample_P1_L001.fq.gz $sample_U1_L001.fq.gz $sample_P2_L001.fq.gz $sample_U2_L001.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20
java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads3 $reads4 $sample_P1_L002.fq.gz $sample_U1_L002.fq.gz $sample_P2_L002.fq.gz $sample_U2_L002.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20

#additional files that Trimmomatic can generate, commented out on 11/30/2021
#java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads1 $reads2 -baseout $sample.trimA.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20
#java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads3 $reads4 -baseout $sample.trimB.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20

#what does -baseout $sample.fq.gz produce? what is in this file?

######################
/bin/echo "Starting BWA.."

bwa index $referenceSeq

#bwa mem $referenceSeq '<zcat *L001_R1_001.fastq.gz *L002_R1_001.fastq.gz' '<zcat *L001_R2_001.fastq.gz *L002_R2_001.fastq.gz' > $sample.sam
#bwa mem $referenceSeq  *L001_R1_001.fastq.gz *L001_R2_001.fastq.gz > $sample.sam


#concatenating P1 and P2 reads from each lane
#removed trimA, trimB in file names
#bwa mem $referenceSeq '<zcat $sample.trimA_1P.fq.gz $sample.trimA_2P.fq.gz' '<zcat $sample.trimB_1P.fq.gz $sample.trimB_2P.fq.gz' > $sample.sam
#this one worked last time
bwa mem $referenceSeq '<zcat $sample_P1_L001.fq.gz $sample_P2_L001.fq.gz' '<zcat $sample_P1_L002.fq.gz $sample_P2_L002.fq.gz' > $sample.sam
#if everything works but the output looks weird (low alignment numbers), revisit line 84 and change orders of the 4 files such that P1 files are first, P2 files second
#line below potentially puts them in different order, combining data from different lanes. didn't work 12/9 run
#bwa mem $referenceSeq '<zcat $sample_P1_L001.fq.gz <zcat $sample_P1_L002.fq.gz' '$sample_P2_L001.fq.gz $sample_P2_L002.fq.gz' > $sample.sam


samtools view -S -b $sample.sam > $sample.bam      ##-h flag in view to include the header

samtools sort $sample.bam -o $sample.sorted.bam #bai files not created with -n but needed for rmdup

samtools index $sample.sorted.bam

#####Remove PCR duplicates:
samtools sort -n $sample.bam -o $sample.sortedn.bam
samtools fixmate $sample.sortedn.bam $sample.fixmate.bam
samtools rmdup $sample.fixmate.bam $sample.rmdup.bam
samtools sort $sample.rmdup.bam -o $sample.sorted.rmdup.bam
samtools index $sample.sorted.rmdup.bam 

#RENAME FILE
mv $sample.sorted.rmdup.bam $sample.plastome.rmdup.bam
#mv $sample.sorted.bam $sample.plastome.bam

#Summary stats#########
#samtools flagstat $sample.sorted.bam > $sample.mappingstats.txt
samtools flagstat $sample.plastome.rmdup.bam > $sample.rmdup.mappingstats.txt
samtools depth $sample.sorted.bam > $sample.depth.txt
samtools coverage $sample.sorted.bam > $sample.coverage.txt

#############generate a consensus sequence######
#To generate a consensus sequence from a BAM: samtools/vcfutils gives ambiguity codes
	#samtools bam2fq $sample.sorted.bam | seqtk seq -A - > $sample.fa #STOUT broken pipe failed

#bcftools mpileup --max-depth 500 -f $referenceSeq $sample.sorted.bam | bcftools call -mv -Ob -o $sample.calls.vcf.gz   #Needs COORINDATE SORTED NOT N SORTED
#bcftools mpileup --max-depth 5000 -f $referenceSeq $sample.plastome.rmdup.bam | bcftools call -mv -Ob -o $sample.calls.vcf.gz   #Needs COORINDATE SORTED NOT N SORTED #original line Nisa gave
bcftools mpileup --max-depth 500 -A -f $referenceSeq $sample.plastome.rmdup.bam | bcftools call -mv -Oz -o $sample.calls.vcf.gz #more closely resembles Nisa's current code, -A read anomolous pairs
#if .vcf.gz file is small, check contents for void file

bcftools index $sample.calls.vcf.gz

	#bcftools norm -f $referenceSeq $sample.calls.vcf.gz -Ob -o calls.norm.bcf
	#bcftools filter --IndelGap 5 calls.norm.bcf -Ob -o calls.norm.flt-indels.bcf

#create consensus sequence by applying VCF variants to a reference fasta file
#bcftools consensus -f $referenceSeq $sample.calls.vcf.gz -o $sample.plastome.fasta
cat $referenceSeq | bcftools consensus $sample.calls.vcf.gz > $sample.plastome.fasta

#rename the sequence per the filename:
#commenting line 129 out, 12/18/21
awk '/^>/{print ">" substr(FILENAME,1,length(FILENAME)-15); next} 1' $sample.plastome.fasta

#####################
#remove files from execute node
rm $reads1
rm reads1*
rm $reads2
rm $reads
rm $reads4
rm I19704_as_reference.fasta.*
rm temp_*.fq.gz
rm ${sample}_1P.fq.gz 
rm ${sample}_2P.fq.gz
rm *.sam
rm *gz.csi
rm *sorted.bam.bai


#tar zcvf $sample.plastome.output.tar $sample.cns.fasta $sample.sorted.bam *txt $sample.calls.vcf.gz
#cp $sample.plastome.output.tar /staging/pwchan

#cp $sample.cns.rmdup.fasta /staging/pwchan
#hope files transfer automatically.!!


