
SAMPLES="HI.0640.005.Index_13.B_R1 HI.0640.005.Index_14.C_R1 HI.0640.005.Index_13.B_R2 HI.0640.005.Index_14.C_R2"


mkdir fastqc_output_fastp_data
 
for sample in $SAMPLES; do
    docker run --platform linux/amd64 -it --rm -v $(pwd):/data  staphb/fastqc:0.11.9 fastqc -t 20 -o /data/fastqc_output_fastp_data /data/fastp_output_genome/out_${sample}.fastq.gz
done


