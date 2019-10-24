#!/bin/bash

## merge GVCFS generated using GATK4 HaplotypeCaller
## @sbamin

## Using gatk 4.0.9.0
module load rvgatk4/4.0.9.0

## location of gvcfs
BASEDIR="/projects/verhaak-lab/amins_cgp_level2/germline_calls/germline_flow_20180720/gatk4_hc"
REF_FASTA="/projects/verhaak-lab/DogWGSReference/CanFam3_1.fa"
CHRS="/projects/verhaak-lab/DogWGSReference/Chrom_List/gatk/gatk_int_chrs39.list"

TMPDIR="/fastscratch/amins/tmp"
mkdir -p "$TMPDIR" && export TMPDIR

OUTDIR="/fastscratch/amins/germline/gatk4_hc/combined_gvcfs"
mkdir -p "$OUTDIR" && cd "$OUTDIR"

################################ Combine GVCFs #################################

TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "\nLOGGER\t%s\tSTART\tCombineGVCFs\t0\n" "$TSTAMP"

gatk CombineGVCFs \
	-R "$REF_FASTA" \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-4990-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-99AF-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-A71E-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-AB3E-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-B2DC-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-D7EC-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-DCD0-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-FCD0-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S01-FECA-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S02-2C25-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S02-4BAC-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S02-81E2-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S02-8A0A-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S02-A974-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-03A6-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-05CA-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-1165-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-1793-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-2C4F-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-3688-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-49E6-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-6254-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-63FE-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-6638-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-66A9-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-6D5C-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-6E45-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-750B-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-8228-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-B3CE-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-B70F-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-C04D-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-E2CD-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-E7AB-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-E952-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-ED99-T6-A2-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-F840-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S03-FC65-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-0FF0-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-1166-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-157E-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-22C7-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-2EC9-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-3F8C-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-42D9-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-5CE5-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-607E-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-6561-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-92AC-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-B023-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-B02B-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-BF76-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-C3C0-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-D026-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-D756-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S04-E271-T6-A1-B12_PR_snp_calls.vcf.gz \
	--variant "$BASEDIR"/hc_germline_as_gvcf_S05-B813-T6-A2-B12_PR_snp_calls.vcf.gz \
	--tmp-dir "$TMPDIR" \
	-L "$CHRS" \
	-O "$OUTDIR"/gatk4_hc_combined_gvcfs_n57_merged_paired_bams.g.vcf.gz && \
TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
printf "\nLOGGER\t%s\tEND\tCombineGVCFs\t%s\n" "$TSTAMP" "$?"

########################### Genotype Combined GVCFs ############################

TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
printf "\nLOGGER\t%s\tSTART\tGenotypeCombinedGVCF\t0\n" "$TSTAMP"

gatk --java-options "-Xmx16g" GenotypeGVCFs \
   -R "$REF_FASTA" \
   -V "$OUTDIR"/gatk4_hc_combined_gvcfs_n57_merged_paired_bams.g.vcf.gz \
   --tmp-dir "$TMPDIR" \
   -L "$CHRS" \
   -O "$OUTDIR"/gatk4_hc_combined_gvcfs_n57_merged_paired_bams.genotyped.vcf.gz && \
TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
printf "\nLOGGER\t%s\tEND\tGenotypeCombinedGVCF\t%s\n" "$TSTAMP" "$?"
