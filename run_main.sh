#!/bin/bash

SAMPLE1=(HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1)
SAMPLE2=(HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2)
SAMPLES="HI.0640.005.Index_13.B_R1 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_14.C_R2"
#SAMPLES_NAMES=(HI.0640.005.Index_13.B HI.0640.005.Index_14.C)
SAMPLES_NAMES=(HI.0640.005.Index_14.C)

#SAMPLE1=(HI.0635.008.Index_12.A_R1 HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_15.D_R1 HI.0640.005.Index_16.E_R1 HI.0640.006.Index_18.F_R1 HI.0640.006.Index_19.G_R1 HI.0640.006.Index_20.H_R1 HI.0640.006.Index_21.I_R1 )

#SAMPLE2=(HI.0635.008.Index_12.A_R2 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2 HI.0640.005.Index_15.D_R2 HI.0640.005.Index_16.E_R2 HI.0640.006.Index_18.F_R2 HI.0640.006.Index_19.G_R2 HI.0640.006.Index_20.H_R2 HI.0640.006.Index_21.I_R2)

#SAMPLES="HI.0635.008.Index_12.A_R1 HI.0635.008.Index_12.A_R2 HI.0640.005.Index_13.B_R1 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_14.C_R2 HI.0640.005.Index_15.D_R1 HI.0640.005.Index_15.D_R2 HI.0640.005.Index_16.E_R1 HI.0640.005.Index_16.E_R2 HI.0640.006.Index_18.F_R1 HI.0640.006.Index_18.F_R2 HI.0640.006.Index_19.G_R1 HI.0640.006.Index_19.G_R2 HI.0640.006.Index_20.H_R1 HI.0640.006.Index_20.H_R2 HI.0640.006.Index_21.I_R1 HI.0640.006.Index_21.I_R2"  



function_name () {
  commands
}

run_fastp () {
    mkdir fastp_output_genome

    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data nanozoo/fastp:0.20.0--78a7c63 fastp -w 16 -i /data/"${SAMPLE1[i]}".fastq.gz -I /data/"${SAMPLE2[i]}".fastq.gz -o /data/fastp_output_genome/out_"${SAMPLE1[i]}".fastq.gz -O /data/fastp_output_genome/out_"${SAMPLE2[i]}".fastq.gz    

    done
}


run_fastqc_on_fastp_data (){

    mkdir fastqc_output_fastp_data
 
    for sample in $SAMPLES; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data  staphb/fastqc:0.11.9 fastqc -t 20 -o /data/fastqc_output_fastp_data /data/fastp_output_genome/out_${sample}.fastq.gz
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
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data  staphb/fastqc:0.11.9 fastqc -t 20  -o /data/fastqc_output_trimmomatic_data /data/trimmomatic_output/${sample}.trim.fastq.gz
    done
}


run_bfc_on_trimmomatic_data(){

    mkdir -p bfc_output/{bfc_with_trimmomatic_output,bfc_with_fastp_output}
    
    
   
    for sample in $SAMPLES; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data jfroula/bfc:181 bfc -s 180m -t16 /data/trimmomatic_output/${sample}.trim.fastq.gz > bfc_corrected_trimmomatic_${sample}_1.fastq.gz
    done
    
    mv bfc_corrected_trimmomatic_*.fastq.gz bfc_output/bfc_with_trimmomatic_output
    

}

run_multiqc_on_fastqc_output_trimmomatic_data(){
    docker run -t -v $(pwd)/fastqc_output_trimmomatic_data:`pwd` -w `pwd` ewels/multiqc:v1.11

}

run_multiqc_on_fastp_output_trimmomatic_data(){
    docker run -t -v $(pwd)/fastqc_output_fastp_data:`pwd` -w `pwd` ewels/multiqc:v1.11

}



run_illumina_cleanup(){
    mkdir illumina_cleanup_output
    ./illumina-cleanup/bin/illumina-cleanup --fastqs /media/szymon/Dysk_1/comp_genomics/genomics_analysis4/IC_fastqs.txt --fastqs /media/szymon/Dysk_1/Genomes_analysis/illumina-cleanup/bin/IC_fastqs.txt --max_cpus 10
    mv /media/szymon/Dysk_1/Genomes_analysis/illumina-cleanup/bin/*_IC /media/szymon/Dysk_1/Genomes_analysis/illumina_cleanup_output
    # mv /media/szymon/Dysk_1/Genomes_analysis/*_IC /media/szymon/Dysk_1/Genomes_analysis/illumina_cleanup_output
}

run_subread_index(){
    mkdir subread_output
    mkdir subread_B10_index

    docker run --platform linux/amd64 -it --rm -v $(pwd):/data nanozoo/subread:2.0.2--53f5da6 subread-buildindex -o /data/subread_B10_index/subread_index /data/referencyjny_genom_b10/pb_b10_ill1.fasta

    #mv index.00.b.array index.00.b.tab index.files index.log index.reads subread_B10_index


    #or i in "${!SAMPLE1[@]}"; do
    #    docker run --platform linux/amd64 -it --rm -v $(pwd):/data nanozoo/subread:2.0.2--53f5da6 subread-align -T 3 -t 1 -d 50 -D 600 -i /data/subread_index/index -r /data/bfc_corrected_trimmomatic_"${SAMPLE1[i]}".fastq.gz -R /data/bfc_corrected_trimmomatic_"${SAMPLE2[i]}".fastq.gz -o /data/subread_"${SAMPLE1[i]}"_PE.bam
    #done

    #mv *.bam *.vcf subread_output/

}

run_hisat_index(){
 
    mkdir hisat2_output
    mkdir hisat2_index

    docker run --platform linux/amd64 -it --rm -v $(pwd):/data makaho/hisat2-zstd hisat2-build -p 20 /data/referencyjny_genom_b10/pb_b10_ill1.fasta /data/hisat2_index/hisat2_index
     
}

run_hisat_mapping_raw_files(){
    #for i in "${!SAMPLE1[@]}"; do
    #    mv bfc_corrected_trimmomatic_"${SAMPLE1[i]}".fastq.gz bfc_corrected_trimmomatic_"${SAMPLE1[i]}".fastq
    #    mv bfc_corrected_trimmomatic_"${SAMPLE2[i]}".fastq.gz bfc_corrected_trimmomatic_"${SAMPLE2[i]}".fastq
    #done


    for i in "${!SAMPLE1[@]}"; do
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data makaho/hisat2-zstd hisat2 -p 20 -x /data/hisat2_index/hisat2_index -1 /data/"${SAMPLE1[i]}".fastq.gz -2 /data/"${SAMPLE2[i]}".fastq.gz -S /data/hisat2_output/"${SAMPLES_NAMES[i]}".sam
    done

#for i in "${!SAMPLE1[@]}"; do
#    mv bfc_corrected_trimmomatic_"${SAMPLE1[i]}".fastq bfc_corrected_trimmomatic_"${SAMPLE1[i]}".fastq.gz
#    mv bfc_corrected_trimmomatic_"${SAMPLE2[i]}".fastq bfc_corrected_trimmomatic_"${SAMPLE2[i]}".fastq.gz
#done                             
}

hisat_sam_to_bam(){
    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools view -@ 20 -bS  /data/${sample}.sam  -o /data/${sample}.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools sort -@ 20 /data/${sample}.bam  -o /data/${sample}_sorted.bam

    done


    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools index -@ 20 /data/${sample}_sorted.bam

    done

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools idxstats -@ 20 /data/${sample}_sorted.bam > ${sample}_idxstats.txt

    done

    mv *.txt hisat2_output

    for sample in ${SAMPLES_NAMES}; do
        docker run --platform linux/amd64 -it --rm -v $(pwd)/hisat2_output:/data staphb/samtools:1.13 samtools stats -@ 20 /data/${sample}_sorted.bam > ${sample}_stats.txt

    done

    mv *.txt hisat2_output

}

main(){
    #run_fastp
    #run_fastqc_on_fastp_data
    #run_trimmomatic
    #run_fastqc_on_trimmomatic_data
###########################
    #run_bfc_on_trimmomatic_data #działa bardzo długo - sprawdzić multithreading - wyjściowe pliki ponad 10GB
###########################    
    #run_multiqc_on_fastqc_output_trimmomatic_data
    #run_multiqc_on_fastp_output_trimmomatic_data
    #run_illumina_cleanup
 #########################   
    #run_subread_index - nie działa Check the integrity of provided reference sequences ERROR: A fasta file cannot have a line longer than 1000 bytes. You need to split a very long line into many lines.
 #########################   
    #run_hisat_index
    #run_hisat_mapping_raw_files
    hisat_sam_to_bam
}
main

