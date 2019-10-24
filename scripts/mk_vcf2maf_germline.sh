#!/bin/bash

## v 1.2

# usage
show_help() {
cat << EOF

Wrapper to run VEP on canine samples

Usage: ${0##*/} -p <Absolute path to vcf.gz file>
                -s <subject_barcode>
                -t <tumor_barcode>
                -n <normal_barcode>
                -f <VCF CALLER: GATK4HC, M2 or VS2 or SOMATICSEQ (default: GATK4HC)>
                -m <VCF MODE: paired, tonly, or normal (default: normal)>
                -c <cpu cores (default: 4)>
                -v <variant call type (default: germline_snp)>
EOF
}

if [[ $# -lt 4 ]];then show_help;exit 1;fi

while getopts "p:s:t:n:f:m:c:v:h" opt; do
    case "$opt" in
        h) show_help;exit 0;;
        p) VCFPATH=$OPTARG;;
        s) PT_BARCODE=$OPTARG;;
        t) TM_BARCODE=$OPTARG;;
        n) NR_BARCODE=$OPTARG;;
		f) VCF_FORMAT=$OPTARG;;
		m) MODE=$OPTARG;;
		c) NCORES=$OPTARG;;
		v) VARTYPE=$OPTARG;;
       '?') show_help >&2 exit 1 ;;
    esac
done

VCFPATH="${VCFPATH:-NONE}"
PT_BARCODE="${PT_BARCODE:-NONE}"
TM_BARCODE="${TM_BARCODE:-NONE}"
NR_BARCODE="${NR_BARCODE:-NONE}"
VCF_FORMAT="${VCF_FORMAT:-GATK4HC}"
MODE="${MODE:-normal}"
NCORES="${NCORES:-4}"
VARTYPE="${VARTYPE:-germline_snp}"


if [[ ! -s "${VCFPATH}" ]]; then
	echo -e "ERROR: zero-byte or inaccessible flowr path: ${VCFPATH}" >&2
	exit 1
fi

if [[ "${PT_BARCODE}" == "NONE" ]] || [[ "${NR_BARCODE}" == "NONE" ]]; then
	echo -e "ERROR: One or more of subject or normal barcodes is either empty or given NONE\n" >&2
	exit 1
fi

if [[ "${MODE}" == "paired" ]]; then
	if [[ "${PT_BARCODE}" == "NONE" ]] || [[ "${TM_BARCODE}" == "NONE" ]] || [[ "${NR_BARCODE}" == "NONE" ]]; then
		echo -e "ERROR: One or more of subject, tumor, or normal barcodes is either empty or given NONE\n" >&2
		exit 1
	fi	

	if [[ "${TM_BARCODE}" == "${NR_BARCODE}" ]]; then
		echo -e "ERROR: tumor and normal barcodes are identical.\nBoth barcodes must be unique.\n" >&2
		exit 1
	fi
fi

## workdir for qsub
WORKDIR=$(dirname "${VCFPATH}")

if [[ "$(pwd)" != "${WORKDIR}" ]]; then
	echo -e "\nWARN: Current work directory: $(pwd) is not identical to where input vcf file is located: ${WORKDIR}\n"
fi

## make name for intermediate uncompressed vcf and final maf file
INPUT_VCF=$(basename "$VCFPATH")
# INPUT_VCF=$(printf "%s_%s_variants_fmt%s_mode%s_v2.vcf" "${PT_BARCODE}" "${VARTYPE}" "${VCF_FORMAT}" "${MODE}")
OUTPUT_MAF=$(printf "%s_%s_variants_fmt%s_mode%s_v2.maf" "${PT_BARCODE}" "${VARTYPE}" "${VCF_FORMAT}" "${MODE}")

TSTAMP=$(date +%d%b%y_%H%M%S%Z)

if [[ -f "vep_stats.html" ]]; then
	OLDSTATS=$(printf "old_%s_vep_stats.html" "$TSTAMP")
	echo -e "\nINFO: moving previously created vep_stats.html file to ${OLDSTATS}\n"
fi

## path to store VEP scripts
VEP_PATH="${RVAPPS}"/vep/ensembl-vep
## path for annotations
VEP_DATA="${RVENV}"/core_annots/vep_core/vep

# load htslib enabled env
module load rvhtsenv/1.6
echo -e "\nUsing samtools binary at $(which samtools)\n$(samtools --version)\n"
echo -e "\nUsing bcftools binary at $(which bcftools)\n$(bcftools --version)\n"
echo -e "\nUsing vcf2maf.pl binary at $(which vcf2maf.pl)\n"

## extract vcf.gz to vcf, enable strict error check
if [[ ! -f "${INPUT_VCF}" ]]; then
	set -e
	gunzip -c "${VCFPATH}" >| "${INPUT_VCF}"
	set +e
fi

## check if extracted vcf is not zero-byte
if [[ ! -s "${INPUT_VCF}" ]]; then
	echo -e "ERROR: zero-byte or malformed extracted vcf from ${VCFPATH}" >&2
	ls -alh "${INPUT_VCF}" >&2
	exit 1
else
	echo -e "INFO: Extracted vcf from ${VCFPATH}"
	ls -alh "${INPUT_VCF}"
fi

################################# RUN VCF2MAF ##################################
## group by VCF FORMAT (Mutect2, VarScan2 or SomaticSeq), and 
## MODE (paired or tonly)

if [[ "${VCF_FORMAT}" == "GATK4HC" && "${MODE}" == "normal" ]]; then
	## format for GATK4 HC GVCF, merged, genotyped, hard-filtered vcfs
	## Note: We pass normal sample barcode under tumor-id tags, i.e., run vcf2maf in tumor-only mode
	## Check vcf header for valid TUMOR, NORMAL names
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tGATK4HC\tnormal\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$NR_BARCODE" "$INPUT_VCF"	
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info AD,DP,GQ,GT,MIN_DP,PGT,PID,PL,RGQ,SB \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${NR_BARCODE}" \
				--vcf-tumor-id "${NR_BARCODE}"
elif [[ "${VCF_FORMAT}" == "M2" && "${MODE}" == "paired" ]]; then
	## format for Mutect2 vcf file
	## Check vcf header for valid TUMOR, NORMAL names
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tM2\tpaired\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF"	
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info DP,ECNT,NLOD,N_ART_LOD,POP_AF,P_GERMLINE,TLOD \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${TM_BARCODE}" \
				--vcf-tumor-id "${TM_BARCODE}" \
				--normal-id "${NR_BARCODE}" \
				--vcf-normal-id "${NR_BARCODE}"
elif [[ "${VCF_FORMAT}" == "VS2" && "${MODE}" == "paired" ]]; then
	## format for varscan2 vcf file
	## Check vcf header for valid TUMOR, NORMAL names
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tVS2\tpaired\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF"
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info DP,SOMATIC,SS,SSC,GPV,SPV \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${TM_BARCODE}" \
				--vcf-tumor-id TUMOR \
				--normal-id "${NR_BARCODE}" \
				--vcf-normal-id NORMAL
elif [[ "${VCF_FORMAT}" == "SOMATICSEQ" && "${MODE}" == "paired" ]]; then
	## format for somaticseq generated and TIER annotated vcf
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tSOMATICSEQ\tpaired\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF"
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info SOMATIC,MVL,NUM_TOOLS,AF,DP,ECNT,POP_AF,P_CONTAM,P_GERMLINE,REF_BASES,N_ART_LOD,NLOD,TLOD,DP4,VAF \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${TM_BARCODE}" \
				--vcf-tumor-id "${TM_BARCODE}" \
				--normal-id "${NR_BARCODE}" \
				--vcf-normal-id "${NR_BARCODE}"
elif [[ "${VCF_FORMAT}" == "M2" && "${MODE}" == "tonly" ]]; then
	## format for Mutect2 vcf file
	## Check vcf header for valid TUMOR name
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tM2\ttonly\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF"	
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info DP,ECNT,NLOD,N_ART_LOD,POP_AF,P_GERMLINE,TLOD \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${TM_BARCODE}" \
				--vcf-tumor-id "${TM_BARCODE}"

elif [[ "${VCF_FORMAT}" == "VS2" && "${MODE}" == "tonly" ]]; then
	## format for varscan2 vcf file
	## Check vcf header for valid TUMOR name
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tVS2\ttonly\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF"
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info DP,SOMATIC,SS,SSC,GPV,SPV \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${TM_BARCODE}" \
				--vcf-tumor-id TUMOR
elif [[ "${VCF_FORMAT}" == "SOMATICSEQ" && "${MODE}" == "tonly" ]]; then
	## format for somaticseq generated and TIER annotated vcf
	TSTAMP=$(date +%d%b%y_%H%M%S%Z)
	printf "LOGGER %s\t%s\tSOMATICSEQ\ttonly\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF"
	vcf2maf.pl --ref-fasta /projects/verhaak-lab/DogWGSReference/CanFam3_1.fa \
				--maf-center JAX --filter-vcf 0 --vep-forks "${NCORES}" \
				--species canis_familiaris --ncbi-build CanFam3.1 \
				--vep-path "${VEP_PATH}" \
				--vep-data "${VEP_DATA}" \
				--retain-info SOMATIC,MVL,NUM_TOOLS,AF,DP,ECNT,POP_AF,P_CONTAM,P_GERMLINE,REF_BASES,N_ART_LOD,NLOD,TLOD,DP4,VAF \
				--input-vcf "${INPUT_VCF}" \
				--output-maf "${OUTPUT_MAF}" \
				--tumor-id "${TM_BARCODE}" \
				--vcf-tumor-id "${TM_BARCODE}"
else
	echo -e "ERROR: Invalid vcf format at -f flag: ${VCF_FORMAT}\nIt must be either M2 or VS2 or SOMATICSEQ.\nOR Invalid vcf type at -m flag: ${MODE}\nIt must be either paired or tonly\n\n" >&2
	exit 1
fi

vep_exit=$?
TSTAMP=$(date +%d%b%y_%H%M%S%Z)
printf "LOGGER %s\t%s\tEND_VCF2MAF\tExit:%s\t%s\t%s\t%s\t%s\t%s\t%s\n" "$TSTAMP" "$PT_BARCODE" "$vep_exit" "$TM_BARCODE" "$NR_BARCODE" "$INPUT_VCF" "$VCF_FORMAT" "$MODE" "$VARTYPE"
exit "$vep_exit"

## END ##
