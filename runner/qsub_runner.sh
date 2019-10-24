#!/bin/bash

## generic runner to control qsub flow
## Author: Samir B. Amin, @sbamin

# usage
show_help() {
cat << EOF

Runner to batch submit jobs to HPC Helix

Usage: ${0##*/} -s <line number to begin> -e <line number to end> -f <path to file containing flowr commands, one per line>

    -h display this help and exit
    -s line number to begin (default: 2)
    -e line number to end (default: 3)
    -f path to file containing command or argument to submit, one per line (required)
    -n run type: YES for actual run (default: no)

Example: submit flowr jobs from line number 4 to 7
  cd <flowr directory>
  ${0##*/} -s 4 -e 7 -f ../ingest/input_cmds_args.txt -n YES

EOF
}

##### minimum 1 argument, -f is required #####
if [[ $# -lt 1 ]];then show_help;exit 1;fi

while getopts "s:e:f:n:h" opt; do
    case "$opt" in
        h) show_help;exit 0;;
        s) START=$OPTARG;;
		e) END=$OPTARG;;
		f) UUIDFILE=$OPTARG;;
		n) REALRUN=$OPTARG;;
       '?') show_help >&2 exit 1 ;;
    esac
done

## function to check active and all HPC jobs for a user
if [[ -s "${RVSETENV}"/confs/check_helix_health ]]; then
	. "${RVSETENV}"/confs/check_helix_health
	echo "Sourced check_helix_health from RVSETENV/confs with exit code: $?"
	check_job_status
	sleep 2
else
	echo "ERROR: Unable to source ${RVSETENV}/confs/check_helix_health"
	exit 1
fi


## parse user variables
START=${START:-2}
END=${END:-3}
UUIDFILE=${UUIDFILE:-"NONE"}
REALRUN=${REALRUN:-"NO"}

DIRID="$(basename "$(pwd)")"

if [[ "${DIRID}" != "flowr" ]]; then
	show_help
	printf	"\n## ERROR ##\nLooks like you are not in flowr directory where flowr_cgp_*.R along with conf and def files should be present\nCurrent work dir is: %s" "$(pwd)\n" >&2
	exit 1
fi

mkdir -p tmp
TMPFILE=$(printf "tmp/tmp_%s" "$RANDOM")

## check for input sample uuid file
if [[ ! -f "${UUIDFILE}" ]]; then
	show_help
	printf "\n## ERROR ##\nMissing or unable to read sample UUID file at %s\n" "${UUIDFILE}" >&2
	exit 1
fi

## Real or dry run
if [[ "$REALRUN" == "YES" ]]; then
	FLOWREXE=TRUE
	printf "\n## INFO ##\n\nUser argument -n is set to %s\nRunning in REAL mode\nflowr job will be submitted to HPC nodes\nCtrl-C to cancel\n\n" "${REALRUN}"
else
	FLOWREXE=FALSE
	printf "\n## INFO ##\n\nUser argument -n is set to %s\nRunning in DRY mode\nflowr job will not be submitted to HPC nodes\nUse -n YES for actual run\n\n" "${REALRUN}"	
fi

## avoid quotes here else sed command may misbehave
sed -n ${START},${END}p ${UUIDFILE} > "${TMPFILE}"

## set counter
COUNTER="${START}"

## enable strict error check
set -eo pipefail

## iterate through TMPFILE
while read -r mycmd_arg; do
	
	printf "\n## INFO ##\nProcessing line: %s with UUID: %s\n###########\n\n" "$START" "$mycmd_arg"

	check_job_status
	## reenable strict error check
	set -e
	sleep 2

	## pass envrionment variables and bash confligs on-the-fly while job is running
	if [[ -s "${HOME}"/bin/flowrvars_loop.sh && -x "${HOME}"/bin/flowrvars_loop.sh ]]; then
	# source by prefix . else env variable may not get exported to parent script
	  . "${HOME}"/bin/flowrvars_loop.sh
	  echo -e "\nSourced ${HOME}/bin/flowrvars_loop.sh\n"
	fi

	## run not more than n number of jobs at a time
	RUNNING_JOBS=${RUNNING_JOBS:-590}
	
	## must be less than 20
	ALL_JOBS=${ALL_JOBS:-700}

	## limit long queue jobs: max 5 running jobs, 50 queued jobs allowed on helix
	LIMIT_LONG_ACTIVE=${LIMIT_LONG_ACTIVE:-5}
	LIMIT_BATCH_ACTIVE=${LIMIT_BATCH_ACTIVE:-590}	
	LIMIT_LONG_ALL=${LIMIT_LONG_ALL:-10}
	LIMIT_BATCH_ALL=${LIMIT_BATCH_ALL:-700}
	HELIX_JOBSTAT=${HELIX_JOBSTAT:-"NA"}

	echo -e "\nMaximum allowed running/all jobs are ${RUNNING_JOBS}/${ALL_JOBS}\n"

	## pause job submission if hardlimits are reached
	## debug to check which condition is being met
	set -x

	## while [[ "${RUNCNT}" -gt "${RUNNING_JOBS}" ]] || [[ "${ALLCNT}" -gt "${ALL_JOBS}" ]] || [[ "${LONG_ACTIVE}" -gt "${LIMIT_LONG_ACTIVE}" ]] || [[ "${LONG_ALL}" -gt "${LIMIT_LONG_ALL}" ]] || [[ "${BATCH_ACTIVE}" -gt "${LIMIT_BATCH_ACTIVE}" ]] || [[ "${BATCH_ALL}" -gt "${LIMIT_BATCH_ALL}" ]]; do

	while [[ "${BATCH_ACTIVE}" -gt "${LIMIT_BATCH_ACTIVE}" ]] || [[ "${BATCH_ALL}" -gt "${LIMIT_BATCH_ALL}" ]]; do
		# disable debug mode
		set +x

		echo -e "\nbatch stats\nactive: ${BATCH_ACTIVE}\nall: ${BATCH_ALL}\nlimit active: ${LIMIT_BATCH_ACTIVE}\nlimit all: ${LIMIT_BATCH_ALL}\n"
		
		## time to wait in seconds if job exceeds hard limits
		SLEEPTIME=300

		# printf "\nWait for %s seconds at %s\nRunning/all jobs are %s/%s\nMaximum allowed running/active jobs are %s/%s\n\n%s\n\n" "$SLEEPTIME" "$(date)" "${RUNCNT}" "${ALLCNT}" "${RUNNING_JOBS}" "${ALL_JOBS}" "${HELIX_JOBSTAT}" | slacktee -t "cgp_varcalls pair to be submitted $COUNTER"

		printf "\nWait for %s seconds at %s\nRunning/all jobs are %s/%s\nMaximum allowed running/active jobs are %s/%s\n\n%s\nLine paused at: %s\n" "$SLEEPTIME" "$(date)" "${RUNCNT}" "${ALLCNT}" "${RUNNING_JOBS}" "${ALL_JOBS}" "${HELIX_JOBSTAT}" "${COUNTER}"

		sleep "$SLEEPTIME"
		
		check_job_status
		## reenable strict error check
		set -e
		sleep 2

		## pass envrionment variables and bash confligs on-the-fly while job is running
		if [[ -s "${HOME}"/bin/flowrvars_loop.sh && -x "${HOME}"/bin/flowrvars_loop.sh ]]; then
		# source by prefix . else env variable may not get exported to parent script
		  . "${HOME}"/bin/flowrvars_loop.sh
		  echo -e "\nSourced ${HOME}/bin/flowrvars_loop.sh\n"
		fi

		## run not more than n number of jobs at a time
		RUNNING_JOBS=${RUNNING_JOBS:-590}
		
		## must be less than 20
		ALL_JOBS=${ALL_JOBS:-700}

		## limit long queue jobs: max 5 running jobs, 50 queued jobs allowed on helix
		LIMIT_LONG_ACTIVE=${LIMIT_LONG_ACTIVE:-5}
		LIMIT_BATCH_ACTIVE=${LIMIT_BATCH_ACTIVE:-590}	
		LIMIT_LONG_ALL=${LIMIT_LONG_ALL:-10}
		LIMIT_BATCH_ALL=${LIMIT_BATCH_ALL:-700}
		HELIX_JOBSTAT=${HELIX_JOBSTAT:-"NA"}

		echo -e "\nMaximum allowed running/active jobs are ${RUNNING_JOBS}/${ALL_JOBS}\nFor batch queue: ${LIMIT_BATCH_ACTIVE}/${LIMIT_BATCH_ALL}\n"
	
	done

	## stop debug
	set +x

	#### SUBMIT JOB TO HPC ####

	## if needed, format flowr command with required arguments
	MYCMD=$(printf "%s" "$mycmd_arg")
	printf "\n## INFO ##\nCommand to run\n\n%s\n\n" "$MYCMD"

	## run command (submit flowr job)
	eval "${MYCMD}"
	EXITSTAT=$?

	WAITSEC="$(shuf -i 90-180 -n 1)"

	printf "Now running %s with exit code: %s\n%s\nwaiting %s seconds\nTotal active/all jobs: %s/%s\n" "$COUNTER" "$EXITSTAT" "$MYCMD" "$WAITSEC" "$RUNCNT" "$ALLCNT"

	# printf "Now running %s with exit code: %s\n%s\nwaiting %s seconds\nTotal active/all jobs: %s/%s\n" "$COUNTER" "$EXITSTAT" "$MYCMD" "$WAITSEC" "$RUNCNT" "$ALLCNT" | slacktee -t "starting flowr for pair $COUNTER"

    sleep "$WAITSEC"

    check_job_status
	## reenable strict error check
	set -e
	sleep 2

	COUNTER=$(( COUNTER + 1 ))
done< "${TMPFILE}"

mv "${TMPFILE}" "${TMPFILE}".done

## END ##
