#!/bin/bash

## Filter germline variants
## Samir B. Amin, @sbamin

## Based on hard-filters
## https://gatkforums.broadinstitute.org/gatk/discussion/2806/howto-apply-hard-filters-to-a-call-set

## strict mode
set -euo pipefail

## Using gatk 4.0.9.0
module load rvgatk4/4.0.9.0
## load bcftools
module load rvhtsenv/1.6

WORKDIR="/fastscratch/amins/cgp/germline/gatk4_hc/combined_gvcfs"
cd "$WORKDIR" && echo "Workdir is $(pwd)"

REF_FASTA="/fastscratch/amins/ref/CanFam3_1.fa"

RAWVCF="cgp_gatk4_hc_merged_paired_genotyped_n56normals.vcf.gz"
RAWSNPS="$(basename "$RAWVCF" .vcf.gz)"_rawsnps.vcf.gz

TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "\nLOGGER\t%s\tSTART\trawSNPs\t%s\n" "$TSTAMP" "$RAWVCF"

if [[ ! -f "raw_snps.done" ]]; then
	gatk --java-options "-Xmx16g -Xms16g" \
	    SelectVariants \
	    -R "$REF_FASTA" \
	    -V "$RAWVCF" \
	    --select-type-to-include SNP \
	    -O "$RAWSNPS" && \
		exitstat1=$? && \
		TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
		printf "\nLOGGER\t%s\tEND\trawSNPs\t%s\n" "$TSTAMP" "$exitstat1" && \
	    touch "raw_snps.done"
else
	echo "INFO: Skip SelectVariants for SNP as raw_snps.done is present at $(pwd)"
fi

if [[ ! -f "filter_snps.done" ]]; then
	printf "\nLOGGER\t%s\tSTART\tfilterSNPs\t%s\n" "$TSTAMP" "$RAWSNPS"

	FILTSNPS="$(basename "$RAWSNPS" .vcf.gz)"_hardfilt_snps.vcf.gz

	gatk --java-options "-Xmx16g -Xms16g" \
	    VariantFiltration \
	    -R "$REF_FASTA" \
	    -V "$RAWSNPS" \
	    -O "$FILTSNPS" \
	    --filter-expression "QD < 2.0 || FS > 60.0 || MQ < 40.0 || MQRankSum < -12.5 || ReadPosRankSum < -8.0" \
	    --filter-name "GSNPFILT" && \
		exitstat2=$? && \
		TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
		printf "\nLOGGER\t%s\tEND\tfilterSNPs\t%s\n" "$TSTAMP" "$exitstat2" && \
	    touch "filter_snps.done"
else
	echo "INFO: Skip VariantFiltration for SNP as filter_snps.done is present at $(pwd)"
fi

echo "Germline SNP filtering done. Check logs for details."

## END ##
