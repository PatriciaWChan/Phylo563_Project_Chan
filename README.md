# Overview of plastome assembly and analysis workflow
### Patricia Chan, December 2021
#### Data Aquisition

1. download dataset from sequencing partners using Globus. Store backups on external hard drive and ResearchDrive. Dataset consists of 4 fastq files per sample (forward and reverse reads (R1 and R2) from two lanes(L001 and L002)). 

    Globus: https://www.globus.org/

        Example file name: I32489_S33_L001_R2_001.fastq
        sample/species ID: I32489_S33
        lane: L001
        read direction: R2

#### Quality Control

2. open several example .fastq files in the application FastQC for quality control. Note areas of concern including the presence of adaptor content.

    FastQC: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/

3. Contact sequencing partners to recieve exact propietary adaptor sequences for removal with Trimmomatic

        Adaptor file: Darwinia_adaptors.txt
#### Plastome Assembly

4. Prepare to run assembly pipeline: log into Center for High Throughput Computing CHTC remote server. Use scp to securely transfer all 54 sample.fastq files, adaptors, and reference Eucalyptus_albens.fasta into /staging folder. download and transfer zipped files for BCFtools, SAMtools, and Trimmomatic. Optional: install tools on local machine test run individual steps on one sample. 

        Rough test notes: Plastome_script_notes.md

    SAMtools and BCFtools: http://www.htslib.org/download
    Trimmomatic: http://www.usadellab.org/cms/?page=trimmomatic

    Off-campus use of CHTC: https://www.doit.wisc.edu/network/vpn/

5. Run assembly pipeline- Submit file queues all samples as simultaneous jobs, referring to input file. Start by running one test job, modify submit and executable files as needed. Utilize condor_q to check progress. Examine output, error, log files, as well as coverage.txt depth.txt and mappingstats.txt files. 

        ssh pwchan@submit1.chtc.wisc.edu
        condor_submit Darwinia_plastomes.sub

    Pipeline includes trimming, alignment to reference genome, variant calling, generation of consensus sequence.

        submit file: Darwinia_plastomes.sub
        executable: Darwinia_plastomes.bwa.sh
        input file: inputs.txt

    troubleshooting Condor: contact chtc@cs.wisc.edu, or attend office hours at go.wisc.edu/chtc-officehours

6. Data transfer: use Filezilla to transfer resulting .bam, .bam.bai and .fasta files to local machine and to ResearchDrive.

7. Download and Install Unipro UGene. Concatenate .fasta files and view all sequences in UGene.

    Ugene: http://ugene.net/
#### Multiple Sequence Alignment and Tree Building

8. Multiple Sequence Alignment- Option 1: Install MAFFT and follow prompts specifying input (.fasta) and output files using default parameters. 
    Option 2: use MAFFT implemented within UGene to same effect through GUI. 

    MAFFT: https://mafft.cbrc.jp/alignment/software/

        mafft --auto all_plastomes.fasta > aligned_plastomes.fasta

    convert .fasta to .phy files using online conversion tool: http://sequenceconversion.bugaco.com/converter/biology/sequences/fasta_to_phylip.php

9. Create Tree- Option 1: Install IQ-Tree. Implement ModelFinder to select substitution model. Utilize this to generate a maximum likelihood tree
    Option 2: use IQ-Tree and ModelFinder implemented within UGene to the same effect through GUI. 

    IQ-Tree: http://www.iqtree.org/

        iqtree -s aligned_plastomes.phy -m MFP
#### (Plan B) Hypothetical Tree Building

10. Throw hands in air in frustration. To have something to write about, hand-build parenthetical text tree and plot in R.

        Script: fabricated_phylogeny.R

11. Profit??