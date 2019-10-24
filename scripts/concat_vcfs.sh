#!/bin/bash

## Concat VCFs
## Samir B. Amin, @sbamin

## load bcftools
module load rvhtsenv/1.6
command -v bcftools
bcftools --version || true

OUTDIR="/fastscratch/amins/cgp/germline/gatk4_hc/combined_gvcfs"
cd "$OUTDIR" || exit

OUTVCF="cgp_gatk4_hc_merged_paired_genotyped_n56normals.vcf.gz"

## swap TMPDIR
## Not needed unless ramdisk gets full
TMPDIR="/fastscratch/amins/tmp"
mkdir -p "$TMPDIR" && export TMPDIR

TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "\nLOGGER\t%s\tSTART\tConcatVCFs\t0\n" "$TSTAMP"

## Using 12 threads

bcftools concat \
	--output-type z --threads 12 \
	--output "${OUTVCF}" \
	"${OUTDIR}"/gatk4_hc_merged_paired_1.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_2.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_3.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_4.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_5.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_6.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_7.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_8.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_9.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_10.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_11.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_12.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_13.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_14.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_15.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_16.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_17.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_18.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_19.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_20.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_21.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_22.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_23.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_24.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_25.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_26.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_27.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_28.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_29.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_30.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_31.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_32.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_33.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_34.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_35.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_36.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_37.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_38.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_MT.genotyped.vcf.gz \
	"${OUTDIR}"/gatk4_hc_merged_paired_X.genotyped.vcf.gz && \
	touch bcftools_concat_n56.done

exitstat=$? && \
TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
printf "\nLOGGER\t%s\tEND\tConcatVCFs\t%s\n" "$TSTAMP" "$exitstat"

## END ##
