#!/bin/bash

# usage
show_help() {
cat << EOF

Run VarScan2 Caller - Germline Mode

Usage: ${0##*/} -b <path to bam> -s output_prefix -g <path to reference genome> -l <path to gene intervals bed file> -r <chromosome name>

        -h display this help and exit
        -b path to sample bam file
        -x path to additional bam files, if any
        -s output file prefix
        -g path to reference genome
        -r chromosomal name of region, i.e., 1 or 4 or X or MT

EOF
}

if [[ $# == 0 ]];then show_help;exit 1;fi

while getopts "b:x:s:g:r:h" opt; do
    case "$opt" in
        h) show_help;exit 0;;
        b) BAMPATH=$OPTARG;;
        x) XTRABAMS=$OPTARG;;
        s) OPATH=$OPTARG;;
        g) REFPATH=$OPTARG;;
        r) CHRPATH=$OPTARG;;
       '?') show_help >&2 exit 1 ;;
    esac
done

TSTAMP="$(date +%d%b%y_%H%M%S%Z)"

MYREFPATH=${REFPATH:-"/projects/verhaak-lab/DogWGSReference/CanFam3_1.fa"}
MYCHRPATH=${CHRPATH:-"NONE"}
printf "\n##### CHR REGION TO PROCESS as -r flag #####\n"
echo "${MYCHRPATH}"
printf "\n##################################\n"

MYBAM=${BAMPATH:-"NONE"}
MYXTRABAMS=${XTRABAMS:-"NONE"}

echo -e "\nUsing samtools binary at $(which samtools)\n$(samtools --version)\n"

if [[ "${MYXTRABAMS}" == "NONE" ]]; then
    MYBAM_MPILEUP=$(printf "samtools mpileup -q 10 -B -f %s -r %s %s" "$MYREFPATH" "$MYCHRPATH" "$MYBAM")
else
    echo -e "\n##### NOTE #####\nAdditional bam files supplied\n#########\n"
    MYBAM_MPILEUP=$(printf "samtools mpileup -q 10 -B -f %s -r %s %s %s" "$MYREFPATH" "$MYCHRPATH" "$MYBAM" "$MYXTRABAMS")
fi

MYOUTPREFIX=${OPATH:-$(printf "UNKNOWN_%s" "$TSTAMP")}

export MYBAM_MPILEUP
export MYOUTPREFIX

cat << EOF

        #### PRINT ARGS ####

        TIMESTAMP: "${TSTAMP}"
        SAMPLE_PREFIX: "${MYOUTPREFIX}"
        SAMPLE BAM: "${MYBAM}"
        Additional sample bams, if any: "${XTRABAMS}"

        REF_GENOME: "${MYREFPATH}"
        CHR_REGION: "${MYCHRPATH}"

        OUTPUT_PATH: "$(pwd)"

        ## COMMANDS ##

        SAMPLE_PILEUP: "${MYBAM_MPILEUP}"
    
        ## VarScan2 Command ##
        /projects/verhaak-lab/verhaak_env/verhaak_apps/java/jdk1.8.0_73/bin/java -Xmx4g -Djava.io.tmpdir=vs2_java_tmp -jar /projects/verhaak-lab/verhaak_env/verhaak_apps/varscan2/VarScan.v2.4.2.jar mpileup2cns <($MYBAM_MPILEUP) --min-coverage 8 --min-reads2 2 --min-avg-qual 15 --min-var-freq 0.01 --min-freq-for-hom 0.75 --strand-filter 1 --p-value 0.1 --output-vcf 1 --variants > "${MYOUTPREFIX}".vcf
        
        #### END INFO ####

EOF

mkdir -p vs2_java_tmp
sleep 2

/projects/verhaak-lab/verhaak_env/verhaak_apps/java/jdk1.8.0_73/bin/java -Xmx4g -Djava.io.tmpdir=vs2_java_tmp -jar /projects/verhaak-lab/verhaak_env/verhaak_apps/varscan2/VarScan.v2.4.2.jar mpileup2cns <($MYBAM_MPILEUP) --min-coverage 8 --min-reads2 2 --min-avg-qual 15 --min-var-freq 0.01 --min-freq-for-hom 0.75 --strand-filter 1 --p-value 0.1 --output-vcf 1 --variants > "${MYOUTPREFIX}".vcf

VS2_EXIT=$?
## do not put any command after varscan command to allow proper exit code to be transmitted to flowr
echo -e "\n##### INFO #####\nVarScan2 exited with exit status of ${VS2_EXIT}\n"
sleep 2
exit "$VS2_EXIT"

## END ##
