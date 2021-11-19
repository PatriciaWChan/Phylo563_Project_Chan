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
#java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads1 $reads2 $sample_P1.fq.gz $sample_U1.fq.gz $sample_P2.fq.gz $sample_U2.fq.gz ILLUMINACLIP:Calochortus.adaptors.txt:2:30:10: SLIDINGWINDOW:5:20
java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads1 $reads2 -baseout $sample.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20

java -jar ./Trimmomatic-0.39/trimmomatic-0.39.jar PE $reads3 $reads4 -baseout temp.fq.gz ILLUMINACLIP:Darwinia_adaptors.txt:2:30:10: SLIDINGWINDOW:5:20


######################
/bin/echo "Starting BWA.."

bwa index $referenceSeq

#bwa mem $referenceSeq '<zcat *L001_R1_001.fastq.gz *L002_R1_001.fastq.gz' '<zcat *L001_R2_001.fastq.gz *L002_R2_001.fastq.gz' > $sample.sam
#bwa mem $referenceSeq  *L001_R1_001.fastq.gz *L001_R2_001.fastq.gz > $sample.sam

bwa mem $referenceSeq '<zcat $sample.1P.fq.gz $sample.2P.fq.gz' '<zcat temp.1P.fq.gz temp.2P.fq.gz' > $sample.sam

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
bcftools mpileup --max-depth 5000 -f $referenceSeq $sample.plastome.rmdup.bam | bcftools call -mv -Ob -o $sample.calls.vcf.gz   #Needs COORINDATE SORTED NOT N SORTED

bcftools index $sample.calls.vcf.gz

	#bcftools norm -f $referenceSeq $sample.calls.vcf.gz -Ob -o calls.norm.bcf
	#bcftools filter --IndelGap 5 calls.norm.bcf -Ob -o calls.norm.flt-indels.bcf

bcftools consensus -f $referenceSeq $sample.calls.vcf.gz -o $sample.plastome.fasta

#rename the sequence per the filename:
awk '/^>/{print ">" substr(FILENAME,1,length(FILENAME)-15); next} 1' $sample.plastome.fasta

#####################
#rm files from execute node
rm $reads1
rm reads1*
rm $reads2
rm $reads3
rm $reads4
rm I19704_as_reference.fasta.*
rm temp_*.fq.gz
rm ${sample}_1P.fq.gz 
rm ${sample}_2P.fq.gz
rm *.sam
rm *gz.csi
rm *sorted.bam.bai


#tar zcvf $sample.plastome.output.tar $sample.cns.fasta $sample.sorted.bam *txt $sample.calls.vcf.gz
#cp $sample.plastome.output.tar /staging/nkarimi

#cp $sample.cns.rmdup.fasta /staging/nkarimi
#hope files transfer automatically.!!


