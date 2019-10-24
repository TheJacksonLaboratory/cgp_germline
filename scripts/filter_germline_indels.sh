#!/bin/bash

## Filter germline variants indels
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
RAWINDELS="$(basename "$RAWVCF" .vcf.gz)"_rawindels.vcf.gz

TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "\nLOGGER\t%s\tSTART\trawINDELs\t%s\n" "$TSTAMP" "$RAWVCF"

if [[ ! -f "raw_indels.done" ]]; then
	gatk --java-options "-Xmx16g -Xms16g" \
	    SelectVariants \
	    -R "$REF_FASTA" \
	    -V "$RAWVCF" \
	    --select-type-to-include INDEL \
	    -O "$RAWINDELS" && \
		exitstat1=$? && \
		TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
		printf "\nLOGGER\t%s\tEND\trawINDELs\t%s\n" "$TSTAMP" "$exitstat1" && \
	    touch "raw_indels.done"
else
	echo "INFO: Skip SelectVariants for INDEL as raw_indels.done is present at $(pwd)"
fi

if [[ ! -f "filter_indels.done" ]]; then
	printf "\nLOGGER\t%s\tSTART\tfilterINDELs\t%s\n" "$TSTAMP" "$RAWINDELS"

	FILTINDELS="$(basename "$RAWINDELS" .vcf.gz)"_hardfilt_indels.vcf.gz

	gatk --java-options "-Xmx16g -Xms16g" \
	    VariantFiltration \
	    -R "$REF_FASTA" \
	    -V "$RAWINDELS" \
	    -O "$FILTINDELS" \
	    --filter-expression "QD < 2.0 || FS > 200.0 || ReadPosRankSum < -20.0" \
	    --filter-name "GINDELFILT" && \
		exitstat2=$? && \
		TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
		printf "\nLOGGER\t%s\tEND\tfilterINDELs\t%s\n" "$TSTAMP" "$exitstat2" && \
	    touch "filter_indels.done"
else
	echo "INFO: Skip VariantFiltration for INDEL as filter_indels.done is present at $(pwd)"
fi

echo "Germline INDEL filtering done. Check logs for details."

## END ##
