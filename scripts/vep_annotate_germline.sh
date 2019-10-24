#!/bin/bash

## Annotate filtered germline variants
## Samir B. Amin, @sbamin

## Using gatk 4.0.9.0
module load rvgatk4/4.0.9.0
## load bcftools
module load rvhtsenv/1.6

WORKDIR="/fastscratch/amins/cgp/germline/gatk4_hc/combined_gvcfs"
cd "$WORKDIR" && echo "Workdir is $(pwd)"

FILTSNP="cgp_gatk4_hc_merged_paired_genotyped_n56normals_rawsnps_hardfilt_snps.vcf.gz"
FILTINDEL="cgp_gatk4_hc_merged_paired_genotyped_n56normals_rawindels_hardfilt_indels.vcf.gz"

TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "\nLOGGER\t%s\tSTART\tPASSsnps\t%s\n" "$TSTAMP" "$FILTSNP"

## extract PASS calls but only output one of multi-sample vcf; do not update INFO fields as we extract one sample only for vcf2maf.pl to work
## sample-level FORMAT details are ignored in mafs.
bcftools view --threads 4 -S vep_samples.tsv -I -f PASS -O v -o cgp_gatk4_hc_merged_paired_genotyped_n56normals_pass_snps_hardfilt.vcf "${FILTSNP}" && \
	touch pass_snps.done && \
	~/pipelines/cgp_varcalls/scripts/mk_vcf2maf_germline.sh -s cgp -n S01-4990-T6-A2-B12 -f GATK4HC -m normal -c 4 -v germline_snp -p "$WORKDIR"/cgp_gatk4_hc_merged_paired_genotyped_n56normals_pass_snps_hardfilt.vcf > vep_germline_snp.log 2>&1 &

bcftools view --threads 4 -S vep_samples.tsv -I -f PASS -O v -o cgp_gatk4_hc_merged_paired_genotyped_n56normals_pass_indels_hardfilt.vcf "${FILTINDEL}" && \
	touch pass_indels.done && \
	~/pipelines/cgp_varcalls/scripts/mk_vcf2maf_germline.sh -s cgp -n S01-4990-T6-A2-B12 -f GATK4HC -m normal -c 4 -v germline_indel -p "$WORKDIR"/cgp_gatk4_hc_merged_paired_genotyped_n56normals_pass_indels_hardfilt.vcf > vep_germline_indel.log 2>&1 &

wait %1 %2

## END ##
