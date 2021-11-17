#!/bin/bash

SAMPLE1=(HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1)
SAMPLE2=(HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2)


mkdir fastp_output_genome



for i in "${!SAMPLE1[@]}"; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data nanozoo/fastp:0.20.0--78a7c63 fastp -w 16 -i /data/"${SAMPLE1[i]}".fastq.gz -I /data/"${SAMPLE2[i]}".fastq.gz -o /data/fastp_output_genome/out_"${SAMPLE1[i]}".fastq.gz -O /data/fastp_output_genome/out_"${SAMPLE2[i]}".fastq.gz    

done


