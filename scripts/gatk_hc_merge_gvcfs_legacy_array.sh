#!/bin/bash

## merge GVCFS generated using GATK4 HaplotypeCaller
## @sbamin

## Using gatk 4.0.9.0
module load rvgatk4/4.0.9.0

## location of gvcfs
CODEDIR="/home/amins/pipelines/cgp_varcalls"
BASEDIR="/fastscratch/amins/staged/gatk4_gvcfs"
REF_FASTA="/fastscratch/amins/ref/CanFam3_1.fa"
## Override CHRLIST if supplied while submitting array jobs in qsub script
CHRLIST="${CHRLIST:-"${CODEDIR}/scripts/canfam_chrs.list"}"

if [[ -z "${PBS_ARRAYID}" || ! -f "$CHRLIST" ]]; then
	echo -e "\nERROR: Either PBS array ID is not available as ${PBS_ARRAYID}\nJob must be run in array mode\nOR\nchromsosome list file is not accessible at $CHRLIST\n" >&2
	exit 1
else
	echo -e "\nUsing chromosome list from a file: $CHRLIST\nExtracting line based on PBS_ARRAYID value: $PBS_ARRAYID\n"
	## avoid quoting PBS_ARRAYID in sed command
	CHR=$(sed -n ${PBS_ARRAYID}p "${CHRLIST}")

	if [[ ! -z "$CHR" ]]; then
		echo -e "\nProcessing PBS_ARRAYID: $PBS_ARRAYID and CHR: $CHR\n"
	else
		echo -e "\nERROR: While processing PBS_ARRAYID: $PBS_ARRAYID, found an incorrect parsing of interval file: $CHRLIST\nParsed interval or chromosome is: $CHR\n" >&2
		exit 1
	fi
fi

## swap TMPDIR
## Not needed unless ramdisk gets full
TMPDIR="/fastscratch/amins/tmp"
mkdir -p "$TMPDIR" && export TMPDIR

## GenomicsDBImport: threads to read vcf file
# THREADS=4

OUTDIR="/fastscratch/amins/cgp/germline/gatk4_hc/combined_gvcfs"
mkdir -p "$OUTDIR" && cd "$OUTDIR" && echo "Workdir is $(pwd)"

## output dir/files
#### for genomicsDBImport ####
# OUTGVCFDB="${OUTDIR}"/gatk4_hc_cgp_merged_paired_genomicsdb_chr"${CHR}"
## Disable making output dir if using GenomicsDBImport

#### Using legacy combinedgvcfs ####
OUTVCF="$OUTDIR"/gatk4_hc_combined_gvcfs_merged_paired_bams_"$CHR".g.vcf.gz

## final genotyped vcf
OUTVCFGT="$OUTDIR"/gatk4_hc_merged_paired_"$CHR".genotyped.vcf.gz

################################ Combine GVCFs #################################

TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "\nLOGGER\t%s\tSTART\tCombineGVCFs\tchr%s\t0\n" "$TSTAMP" "$CHR"

if [[ ! -f combinegvcfs_"${CHR}".done ]]; then
	gatk --java-options "-Xmx24g -Xms24g" \
		CombineGVCFs \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-4990-T6-A2-B12_PR_snp_calls.vcf.gz \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-99AF-T6-A2-B12_PR_snp_calls.vcf.gz \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-A71E-T6-A1-B12_PR_snp_calls.vcf.gz \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-AB3E-T6-A2-B12_PR_snp_calls.vcf.gz \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-B2DC-T6-A2-B12_PR_snp_calls.vcf.gz \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-D7EC-T6-A2-B12_PR_snp_calls.vcf.gz \
		--variant "$BASEDIR"/hc_germline_as_gvcf_S01-DCD0-T6-A2-B12_PR_snp_calls.vcf.gz \
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
		-R "$REF_FASTA" \
		--output "$OUTVCF" \
		--tmp-dir "${TMPDIR}" \
		--seconds-between-progress-updates 60 \
		-L "$CHR" && \
	exitstat=$? && \
	TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
	printf "\nLOGGER\t%s\tEND\tCombineGVCFs\tchr%s\t%s\n" "$TSTAMP" "$CHR" "$exitstat" && \
	touch combinegvcfs_"${CHR}".done
else
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	echo -e "\nINFO: Looks like CombineGVCFs step is already done!\nRemove $(pwd)/combinegvcfs_$CHR.done to redo CombineGVCFs step\n"
	exitstat=$?
	printf "\nLOGGER\t%s\tSKIP\tCombineGVCFs\tchr%s\t%s\n" "$TSTAMP" "$CHR" "$exitstat"
fi

#### SKIP genotyping if merge returns an error
if [[ "$exitstat" != 0 ]] || [[ ! -f combinegvcfs_"${CHR}".done ]]; then
	echo -e "\nERROR: Something went wrong with CombineGVCFs step\nExit code is non-zero: $exitstat or\ncombinegvcfs_$CHR.done file is not present at $(pwd)\n" >&2
	exit 1
fi

########################### Genotype Combined GVCFs ############################

if [[ ! -f genotypegvcfs_"${CHR}".done ]]; then
	TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
	printf "\nLOGGER\t%s\tSTART\tGenotypeCombinedGVCF\tchr%s\t0\n" "$TSTAMP" "$CHR"

	## suppress redundant stderr log
	## Read https://github.com/broadinstitute/gatk/issues/2689 for details

	gatk --java-options "-Xmx24g -Xms24g" GenotypeGVCFs \
	   -R "$REF_FASTA" \
	   -V "$OUTVCF" \
	   --tmp-dir "$TMPDIR" \
	   -L "$CHR" \
	   --seconds-between-progress-updates 60 \
	   -O "${OUTVCFGT}" |& grep -Ev "No valid combination operation found for INFO field"

	exitstat2=$? && \
	TSTAMP=$(date +%d%b%y_%H%M%S%Z) && \
	printf "\nLOGGER\t%s\tEND\tGenotypeCombinedGVCF\tchr%s\t%s\n" "$TSTAMP" "$CHR" "$exitstat2" && \
	touch genotypegvcfs_"${CHR}".done

	exit "$exitstat2"
else
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	echo -e "\nINFO: Looks like GenotypeCombinedGVCF step is already done!\nRemove $(pwd)/genotypegvcfs_$CHR.done to redo GenotypeCombinedGVCF step\n"
	exitstat=$?
	printf "\nLOGGER\t%s\tSKIP\tGenotypeCombinedGVCF\tchr%s\t%s\n" "$TSTAMP" "$CHR" "$exitstat"
fi

## END ##
