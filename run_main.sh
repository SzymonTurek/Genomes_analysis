#!/bin/bash

SAMPLE1=(HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1)
SAMPLE2=(HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2)
SAMPLES="HI.0640.005.Index_13.B_R1 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_14.C_R2"


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
        docker run --platform linux/amd64 -it --rm -v $(pwd):/data staphb/trimmomatic:0.39 trimmomatic PE /data/"${SAMPLE1[i]}".fastq.gz /data/"${SAMPLE2[i]}".fastq.gz /data/trimmomatic_output/"${SAMPLE1[i]}".trim.fastq.gz /data/trimmomatic_output/"${SAMPLE1[i]}"un.trim.fastq.gz /data/trimmomatic_output/"${SAMPLE2[i]}".trim.fastq.gz /data/trimmomatic_output/"${SAMPLE2[i]}"un.trim.fastq.gz ILLUMINACLIP:/Trimmomatic-0.39/adapters/NexteraPE-PE.fa:2:40:15
    done

    #mv "${SAMPLE1[i]}".trim.fastq.gz "${SAMPLE1[i]}"un.trim.fastq.gz "${SAMPLE2[i]}".trim.fastq.gz "${SAMPLE2[i]}"un.trim.fastq.gz trimmomatic_output/
    #mv *.trim.fastq.gz *un.trim.fastq.gz trimmomatic_output/


}

main(){
    #run_fastp
    #run_fastqc_on_fastp_data
    run_trimmomatic

}

main

