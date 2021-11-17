#!/bin/bash

SAMPLES="HI.0635.008.Index_12.A_R1 HI.0640.005.Index_14.C_R2 HI.0640.006.Index_18.F_R1 HI.0640.006.Index_20.H_R2 HI.0635.008.Index_12.A_R2 HI.0640.005.Index_15.D_R1 HI.0640.006.Index_18.F_R2 HI.0640.006.Index_21.I_R1 HI.0640.005.Index_13.B_R1 HI.0640.005.Index_15.D_R2 HI.0640.006.Index_19.G_R1 HI.0640.006.Index_21.I_R2 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_16.E_R1 HI.0640.006.Index_19.G_R2 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_16.E_R2 HI.0640.006.Index_20.H_R1"  


mkdir fastqc_output_raw_data
 
for sample in $SAMPLES; do
	docker run --platform linux/amd64 -it --rm -v $(pwd):/data  staphb/fastqc:0.11.9 fastqc -t 22 -o /data/fastqc_output_raw_data /data/${sample}.fastq.gz
done


