#!/bin/bash

SAMPLE1=(HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1)
SAMPLE2=(HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2)
SAMPLES="HI.0640.005.Index_13.B_R1 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_14.C_R2"
SAMPLES_NAMES=(HI.0640.005.Index_13.B HI.0640.005.Index_14.C)
SAMPLES_NAMES_str="HI.0640.005.Index_13.B HI.0640.005.Index_14.C"



#SAMPLE1=(HI.0640.005.Index_14.C_R1)
#SAMPLE2=( HI.0640.005.Index_14.C_R2)
#SAMPLES="HI.0640.005.Index_14.C_R1 HI.0640.005.Index_14.C_R2"
#SAMPLES_NAMES=(HI.0640.005.Index_14.C)
#SAMPLES_NAMES_str="HI.0640.005.Index_14.C"




#SAMPLE1=(HI.0635.008.Index_12.A_R1 HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_15.D_R1 HI.0640.005.Index_16.E_R1 HI.0640.006.Index_18.F_R1 HI.0640.006.Index_19.G_R1 HI.0640.006.Index_20.H_R1 HI.0640.006.Index_21.I_R1 )

#SAMPLE2=(HI.0635.008.Index_12.A_R2 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2 HI.0640.005.Index_15.D_R2 HI.0640.005.Index_16.E_R2 HI.0640.006.Index_18.F_R2 HI.0640.006.Index_19.G_R2 HI.0640.006.Index_20.H_R2 HI.0640.006.Index_21.I_R2)

#SAMPLES="HI.0635.008.Index_12.A_R1 HI.0635.008.Index_12.A_R2 HI.0640.005.Index_13.B_R1 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_14.C_R2 HI.0640.005.Index_15.D_R1 HI.0640.005.Index_15.D_R2 HI.0640.005.Index_16.E_R1 HI.0640.005.Index_16.E_R2 HI.0640.006.Index_18.F_R1 HI.0640.006.Index_18.F_R2 HI.0640.006.Index_19.G_R1 HI.0640.006.Index_19.G_R2 HI.0640.006.Index_20.H_R1 HI.0640.006.Index_20.H_R2 HI.0640.006.Index_21.I_R1 HI.0640.006.Index_21.I_R2"  



function_name () {
  commands
}

run_fastp () {
    mkdir fastp_output_genome

    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data nanozoo/fastp:0.20.0--78a7c63 fastp -w 15 -i /data/"${SAMPLE1[i]}".fastq.gz -I /data/"${SAMPLE2[i]}".fastq.gz -o /data/fastp_output_genome/out_"${SAMPLE1[i]}".fastq.gz -O /data/fastp_output_genome/out_"${SAMPLE2[i]}".fastq.gz    

    done
}


run_fastqc_on_fastp_data (){

    mkdir fastqc_output_fastp_data
 
    for sample in $SAMPLES; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data  staphb/fastqc:0.11.9 fastqc -t 15 -o /data/fastqc_output_fastp_data /data/fastp_output_genome/out_${sample}.fastq.gz
    done
}

run_trimmomatic () {
    mkdir trimmomatic_output

    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data staphb/trimmomatic:0.39 trimmomatic PE /data/"${SAMPLE1[i]}".fastq.gz /data/"${SAMPLE2[i]}".fastq.gz /data/trimmomatic_output/"${SAMPLE1[i]}".trim.fastq.gz /data/trimmomatic_output/"${SAMPLE1[i]}"un.trim.fastq.gz /data/trimmomatic_output/"${SAMPLE2[i]}".trim.fastq.gz /data/trimmomatic_output/"${SAMPLE2[i]}"un.trim.fastq.gz ILLUMINACLIP:/Trimmomatic-0.39/adapters/TruSeq3-PE.fa:2:30:15 TRAILING:30 MINLEN:50
    done

   


}


run_fastqc_on_trimmomatic_data(){
    mkdir fastqc_output_trimmomatic_data

    for sample in $SAMPLES; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data  staphb/fastqc:0.11.9 fastqc -t 15  -o /data/fastqc_output_trimmomatic_data /data/trimmomatic_output/${sample}.trim.fastq.gz
    done
}


run_bfc_on_trimmomatic_data(){

    mkdir -p bfc_output/{bfc_with_trimmomatic_output,bfc_with_fastp_output}
    
    
   
    for sample in $SAMPLES; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data jfroula/bfc:181 bfc -s 180m -t 15 /data/trimmomatic_output/${sample}.trim.fastq.gz > bfc_corrected_trimmomatic_${sample}_1.fastq
    done
    
    mv bfc_corrected_trimmomatic_*.fastq bfc_output/bfc_with_trimmomatic_output
    

}


run_bfc_on_raw_data(){

    mkdir -p bfc_output/bfc_with_raw_files
    
    
   
    for sample in $SAMPLES; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data jfroula/bfc:181 bfc -s 180m -t 15 /data/${sample}.fastq.gz > bfc_corrected_raw_${sample}.fastq.gz
    done
    
    mv bfc_corrected_*.fastq.gz bfc_output/bfc_with_raw_files
    

}



run_multiqc_on_fastqc_output_trimmomatic_data(){
    docker run -t -v $(pwd)/fastqc_output_trimmomatic_data:`pwd` -w `pwd` ewels/multiqc:v1.11

}

run_multiqc_on_fastp_output_trimmomatic_data(){
    docker run -t -v $(pwd)/fastqc_output_fastp_data:`pwd` -w `pwd` ewels/multiqc:v1.11

}



run_illumina_cleanup(){
    mkdir illumina_cleanup_output
    ./illumina-cleanup/bin/illumina-cleanup --fastqs /media/szymon/Dysk_1/comp_genomics/genomics_analysis4/IC_fastqs.txt --fastqs /media/szymon/Dysk_1/Genomes_analysis/illumina-cleanup/bin/IC_fastqs.txt --max_cpus 8
    mv /media/szymon/Dysk_1/Genomes_analysis/illumina-cleanup/bin/*_IC /media/szymon/Dysk_1/Genomes_analysis/illumina_cleanup_output
    # mv /media/szymon/Dysk_1/Genomes_analysis/*_IC /media/szymon/Dysk_1/Genomes_analysis/illumina_cleanup_output
}

run_subread_index(){
    mkdir subread_output
    mkdir subread_B10_index

    docker run --platform linux/amd64 -it --rm -v $(pwd):/data nanozoo/subread:2.0.2--53f5da6 subread-buildindex -o /data/subread_B10_index/subread_index /data/referencyjny_genom_b10/pb_b10_ill1.fasta


}


run_hisat_index(){
 
    
    mkdir hisat2_index

    docker run --platform linux/amd64 -it --rm -v $(pwd):/data makaho/hisat2-zstd hisat2-build -p 15 /data/referencyjny_genom_b10/pb_b10_ill1.fasta /data/hisat2_index/hisat2_index
     
}

run_bowtie_index()(
    mkdir bowtie_index
    
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexeyebi/bowtie2_samtools bowtie2-build  /data/referencyjny_genom_b10/pb_b10_ill1.fasta /data/bowtie_index/bowtie_index


)


run_bwa_index(){
    mkdir bwa_index
    #docker run --platform linux/amd64 -it --rm -v $(pwd):/data biocontainers/bwa:v0.7.17_cv1 bwa index  /data/referencyjny_genom_b10/pb_b10_ill1.fasta 

    docker run --platform linux/amd64 -it --rm -v $(pwd):/data biocontainers/bwa:v0.7.17_cv1 bwa index  /data/referencyjny_genom_b10/pb_b10_ill1.fasta 

    #mv referencyjny_genom_b10/*.ann referencyjny_genom_b10/*.amb referencyjny_genom_b10/*.bwt referencyjny_genom_b10/*.pac referencyjny_genom_b10/*.sa bwa_index
}

run_star_index(){
    mkdir star_index
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexdobin/star:2.6.1d STAR --runThreadN 15 --runMode genomeGenerate --genomeDir /data/star_index --genomeFastaFiles /data/referencyjny_genom_b10/pb_b10_ill1.fasta  #--sjdbGTFfile /data/referencyjny_genom_b10/annotation.gff 

}




run_hisat_mapping_raw_files(){
 
    mkdir hisat2_output
    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data makaho/hisat2-zstd hisat2 -p 15 -x /data/hisat2_index/hisat2_index -1 /data/"${SAMPLE1[i]}".fastq.gz -2 /data/"${SAMPLE2[i]}".fastq.gz -S /data/hisat2_output/"${SAMPLES_NAMES[i]}".sam
    done

}

run_bowtie_mapping_raw_files(){
    mkdir bowtie2_output_raw_data_B10
    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexeyebi/bowtie2_samtools bowtie2 -p 15 -t -x /data/bowtie_index/bowtie_index -1 /data/"${SAMPLE1[i]}".fastq.gz -2 /data/"${SAMPLE2[i]}".fastq.gz -S /data/bowtie2_output_raw_data_B10/"${SAMPLES_NAMES[i]}".sam
    done
}


run_bowtie_mapping_fastp_files(){
    mkdir bowtie2_output_fastp_data_B10
    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexeyebi/bowtie2_samtools bowtie2 -p 15 -t -x /data/bowtie_index/bowtie_index -1 /data/fastp_output_genome/out_"${SAMPLE1[i]}".fastq.gz -2 /data/fastp_output_genome/out_"${SAMPLE2[i]}".fastq.gz -S /data/bowtie2_output_fastp_data_B10/"${SAMPLES_NAMES[i]}".sam
    done
}





run_bwa_mapping_raw_files(){
    mkdir bwa_output_raw_data_B10
    for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data biocontainers/bwa:v0.7.17_cv1 bwa mem /data/referencyjny_genom_b10/pb_b10_ill1.fasta -t 15 /data/"${SAMPLE1[i]}".fastq.gz /data/"${SAMPLE2[i]}".fastq.gz -o /data/bwa_output_raw_data_B10/"${SAMPLES_NAMES[i]}".sam
    done
}


run_star_mapping_raw_files(){
    mkdir star_output_raw_data_B10
    for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexdobin/star:2.6.1d STAR --runMode alignReads --genomeLoad  LoadAndKeep --readFilesCommand zcat --genomeDir /data/star_index --readFilesIn /data/"${SAMPLE1[i]}".fastq.gz /data/"${SAMPLE2[i]}".fastq.gz --runThreadN 15 --outFileNamePrefix /data/star_output_raw_data_B10/"${SAMPLES_NAMES[i]}"
    done

}



run_star_mapping_fastp_files(){
    mkdir star_output_fastp_data_B10
    for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexdobin/star:2.6.1d STAR --runMode alignReads  --readFilesCommand zcat --genomeDir /data/star_index --readFilesIn /data/fastp_output_genome/out_"${SAMPLE1[i]}".fastq.gz /data/fastp_output_genome/out_"${SAMPLE2[i]}".fastq.gz --runThreadN 15 --outFileNamePrefix /data/star_output_fastp_data_B10/"${SAMPLES_NAMES[i]}"
    done

}


run_star_mapping_ic_files(){
    mkdir star_output_ic_data_B10
    for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexdobin/star:2.6.1d STAR --runMode alignReads  --readFilesCommand zcat --genomeDir /data/star_index --readFilesIn /data/illumina_cleanup_output/"${SAMPLES_NAMES[i]}"_IC/"${SAMPLES_NAMES[i]}"_IC_R1.fastq.gz /data/illumina_cleanup_output/"${SAMPLES_NAMES[i]}"_IC/"${SAMPLES_NAMES[i]}"_IC_R2.fastq.gz --runThreadN 15 --outFileNamePrefix /data/star_output_ic_data_B10/"${SAMPLES_NAMES[i]}"
    done

}


run_star_mapping_bfc_raw_files(){
    mkdir star_output_bfc_data_B10
    for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data alexdobin/star:2.6.1d STAR --runMode alignReads --genomeLoad  LoadAndKeep  --genomeDir /data/star_index --readFilesIn /data/bfc_output/bfc_with_raw_files/bfc_corrected_raw_"${SAMPLE1[i]}".fastq /data/bfc_output/bfc_with_raw_files/bfc_corrected_raw_"${SAMPLE2[i]}".fastq --runThreadN 15 --outFileNamePrefix /data/star_output_bfc_data_B10/"${SAMPLES_NAMES[i]}"
    done

}



run_bbmap_mapping_raw_files(){
    mkdir bbmap_output_raw_data_B10
    for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data cathrine98/bbmap bbmap.sh slow=f threads=15 in1=/data/"${SAMPLE1[i]}".fastq.gz in2=/data/"${SAMPLE2[i]}".fastq.gz out=/data/bbmap_output_raw_data_B10/"${SAMPLES_NAMES[i]}".sam ref=/data/referencyjny_genom_b10/pb_b10_ill1.fasta nodisk
    done

}


hisat_sam_to_bam(){
    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools view -@ 15 -bS  /data/${sample}.sam  -o /data/${sample}.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools sort -@ 15 /data/${sample}.bam  -o /data/${sample}_sorted.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools index -@ 15 /data/${sample}_sorted.bam

    done

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools idxstats -@ 15 /data/${sample}_sorted.bam > ${sample}_idxstats.txt

    done

    mv *.txt hisat2_output

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools stats -@ 15 /data/${sample}_sorted.bam > ${sample}_stats.txt

    done

    mv *.txt hisat2_output

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools flagstat -@ 15 /data/${sample}_sorted.bam > ${sample}_flagstat.txt

    done

    mv *.txt star_output_raw_data_B10

}

sam_to_bam(){ # $1 = output folder of mapping
    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools view -@ 15 -bS  /data/${sample}.sam  -o /data/${sample}.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools sort -@ 15 /data/${sample}.bam  -o /data/${sample}_sorted.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools index -@ 15 /data/${sample}_sorted.bam

    done

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools idxstats -@ 15 /data/${sample}_sorted.bam > ${sample}_idxstats.txt

    done

    mv *.txt $1

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools stats -@ 15 /data/${sample}_sorted.bam > ${sample}_stats.txt

    done

    mv *.txt $1

    
    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools flagstat -@ 15 /data/${sample}_sorted.bam > ${sample}_flagstat.txt

    done

    mv *.txt $1

    
}
star_sam_to_bam2(){ # $1 = output folder of mapping
    for sample in ${SAMPLES_NAMES_str}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools view -@ 15 -bS  /data/${sample}Aligned.out.sam  -o /data/${sample}.bam

    done


    for sample in ${SAMPLES_NAMES_str}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools sort -@ 15 /data/${sample}.bam  -o /data/${sample}_sorted.bam

    done


    for sample in ${SAMPLES_NAMES_str}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools index -@ 15 /data/${sample}_sorted.bam

    done

    for sample in ${SAMPLES_NAMES_str}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools idxstats -@ 15 /data/${sample}_sorted.bam > ${sample}_idxstats.txt

    done

    mv *.txt $1

    for sample in ${SAMPLES_NAMES_str}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools stats -@ 15 /data/${sample}_sorted.bam > ${sample}_stats.txt

    done

    mv *.txt $1

    
    for sample in ${SAMPLES_NAMES_str}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/$1:/data staphb/samtools:1.13 samtools flagstat -@ 15 /data/${sample}_sorted.bam > ${sample}_flagstat.txt

    done

    mv *.txt $1

    
}
star_sam_to_bam(){
    
    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/star_output_raw_data_B10:/data staphb/samtools:1.13 samtools view -@ 15 -bS  /data/${sample}Aligned.out.sam  -o /data/${sample}.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/star_output_raw_data_B10:/data staphb/samtools:1.13 samtools sort -@ 15 /data/${sample}.bam  -o /data/${sample}_sorted.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/star_output_raw_data_B10:/data staphb/samtools:1.13 samtools index -@ 15 /data/${sample}_sorted.bam

    done

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/star_output_raw_data_B10:/data staphb/samtools:1.13 samtools idxstats -@ 15 /data/${sample}_sorted.bam > ${sample}_idxstats.txt

    done

    mv *.txt star_output_raw_data_B10

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/star_output_raw_data_B10:/data staphb/samtools:1.13 samtools stats -@ 15 /data/${sample}_sorted.bam > ${sample}_stats.txt

    done

    mv *.txt star_output_raw_data_B10

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/star_output_raw_data_B10:/data staphb/samtools:1.13 samtools flagstat -@ 15 /data/${sample}_sorted.bam > ${sample}_flagstat.txt

    done

    mv *.txt star_output_raw_data_B10


}

main(){
    #run_fastp
    #run_fastqc_on_fastp_data
    #run_trimmomatic
    #run_fastqc_on_trimmomatic_data
###########################
    #run_bfc_on_trimmomatic_data #działa bardzo długo - sprawdzić multithreading - wyjściowe pliki ponad 10GB
    #run_bfc_on_raw_data
###########################    
    #run_multiqc_on_fastqc_output_trimmomatic_data
    #run_multiqc_on_fastp_output_trimmomatic_data
    #run_illumina_cleanup
 #########################   
    #run_subread_index - nie działa Check the integrity of provided reference sequences ERROR: A fasta file cannot have a line longer than 1000 bytes. You need to split a very long line into many lines.
 #########################   
    #run_hisat_index
    #run_hisat_mapping_raw_files
    #hisat_sam_to_bam
    #run_bowtie_index
    #run_bowtie_mapping_raw_files
    #sam_to_bam bowtie2_output_raw_data_B10
    #run_bwa_index
    #run_bwa_mapping_raw_files
    #sam_to_bam bwa_output_raw_data_B10
    #rm bwa_output_raw_data_B10/*sam
 ################################################   
    #run_star_index
    #run_star_mapping_raw_files
    #star_sam_to_bam
    #rm star_output_raw_data_B10/*sam

    #run_star_mapping_fastp_files
    #star_sam_to_bam2 star_output_fastp_data_B10
    #rm star_output_fastp_data_B10/*sam

   # run_star_mapping_ic_files
    #star_sam_to_bam2 star_output_ic_data_B10
    #rm star_output_ic_data_B10/*sam
################################################

    run_bowtie_mapping_fastp_files

    




######################################
    #run_bbmap_mapping_raw_files
    #star_sam_to_bam star_output_raw_data_B10
    
}
main

