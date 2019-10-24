## germline variant calling pipeline for CGP
# @sbamin

if(!require(flowr))
	stop("Requirements not met; unable to load library: flowr")

if(!require(ultraseq))
	stop("Requirements not met; unable to load library: ultraseq")

##### PRIMARY FUNCTION TO MAKE FLOWMAT #####

flowr_cgp_germline_calls <-function(my_bampath = my_bampath,
							sample_name = sample_name,
							mybam_others = "none"){

	# load configuration, command parameters from config file.
	opts_flow$load("flowr_cgp_germline_calls.conf", check = TRUE)
	
	my_logs = opts_flow$get("my_logs_path")

	if(!dir.exists(my_logs)){
		message("creating log dir, ", my_logs)
		dir.create(path = my_logs, recursive = TRUE, mode = "0775")
	}

	time_tag <- "\"$(date +%d%b%y_%H%M%S%Z)\""

	###################### Run VarScan2 ############################

	#### Parallel Step ####

	## Read GATK interval table: One record per line.
	## See https://www.broadinstitute.org/gatk/guide/tooldocs/org_broadinstitute_gatk_engine_CommandLineGATK.php#--intervals
	gatk_intervals = opts_flow$get("gatk_ref_chr_interval_path")
	gatk_int_chrs = read.delim(gatk_intervals, header = FALSE, stringsAsFactors = FALSE)[,1]

	## exit if parsed interval file is not a character vector
	if(!is.character(gatk_int_chrs)) stop(sprintf("\n#### ERROR ####\nGATK interval file, %s is not in a valid character vector format.\n\nWrite each chromosome or chromosomal region without column name and one entry per line, e.g.,\n\n1\nX\n...\n\nor\n\nchr1\nX\n...\n\nor\n\n1:100-200\n2:400-500\n...\n\nMake sure to end text file with unix style line break $\n\nPS: If you are using human_g1k_v37_decoy.fasta, then names of interval should be without chr prefix. For current run, you are using %s)", 
		gatk_intervals, opts_flow$get("genome_fasta_path")))

	print(sprintf("#### Parallelizing steps with interval list of length %s ####", length(gatk_int_chrs)))
	print(gatk_int_chrs)

	mybam = sub(pattern = "\\.bam$", replacement = "", basename(path = my_bampath))
	## make output file based on number of gatk_intervals, i.e., per chromosome
	outid = sprintf("varscan2_germline_%s_splitid_%s", sample_name, gatk_int_chrs)

	if(file.access(my_bampath, mode = 4) != 0) 
		stop(sprintf("\n##### ERROR #####\nbam file does not exist at %s or not accessible.", my_bampath))

	if(mybam_others == "none") {

	vs2_germline <- sprintf("%s/runner/varscan2_germline_runner.sh -b %s -s %s -g %s -r %s && bgzip -i %s.vcf && %s index -t %s.vcf.gz",
						opts_flow$get("mygit_path"),
						my_bampath,
						outid,
						opts_flow$get("genome_fasta_path"),
						gatk_int_chrs,
						outid,
						opts_flow$get("bcftools_path"),
						outid)
	} else {

	warning(sprintf("\n##### NOTE: #####\nUsing additional set of bam files for varscan2 germline caller\nThese files will be ignored for GATK commands, if any\nYou have supplied mybam_others argument as %s\n",
						mybam_others))

	vs2_germline <- sprintf("%s/runner/varscan2_germline_runner.sh -b %s -x %s -s %s -g %s -r %s && bgzip -i %s.vcf && %s index -t %s.vcf.gz",
						opts_flow$get("mygit_path"),
						my_bampath,
						mybam_others,
						outid,
						opts_flow$get("genome_fasta_path"),
						gatk_int_chrs,
						outid,
						opts_flow$get("bcftools_path"),
						outid)
	}

	######## merge vs2 germline calls and save in outdir/ #########
	chrwise_germline_snp = paste(sprintf("%s.vcf.gz", outid), collapse=" ")

	my_outdir = file.path("outdir")
	final_outid = sprintf("%s/varscan2_germline_%s", my_outdir, sample_name)

	merge_germline_snp <- sprintf("mkdir -p %s && %s concat %s %s --output %s && %s index -t %s && touch %s_vs2_germline.finished",
						my_outdir,
						opts_flow$get("bcftools_path"),
						opts_flow$get("bcftools_args1"),
						chrwise_germline_snp,
						sprintf("%s_snp_calls.vcf.gz", final_outid),
						opts_flow$get("bcftools_path"),
						sprintf("%s_snp_calls.vcf.gz", final_outid),
						sample_name)

	names(merge_germline_snp) <- "merge_germline_snp"

	############## haplotype caller ##############
	## make per chr vcf
	outid_hc = sprintf("hc_germline_%s_splitid_%s", sample_name, gatk_int_chrs)
	
	## confirm tmp dir, hc_java_tmp matches in conf file
	hc_germline <- sprintf("mkdir -p %s && mkdir -p hc_java_tmp && gatk --java-options \"%s\" HaplotypeCaller -R %s -I %s --dbsnp %s --comp %s -O %s.as.g.vcf -L %s %s && bgzip -i %s.as.g.vcf && %s index -t %s.as.g.vcf.gz",
						my_outdir,
						opts_flow$get("hccaller_java8_opts"),
						opts_flow$get("genome_fasta_path"),
						my_bampath,
						opts_flow$get("dbsnp_path"),
						opts_flow$get("known_indels_path"),
						outid_hc,
						gatk_int_chrs,
						opts_flow$get("hccaller_args2"),
						outid_hc,
						opts_flow$get("bcftools_path"),
						outid_hc)

	######## merge germline calls and save in outdir/ #########
	chrwise_hc_germline_snp = paste(sprintf("%s.as.g.vcf.gz", outid_hc), collapse=" ")

	my_outdir = file.path("outdir")
	final_outid_hc = sprintf("%s/hc_germline_as_gvcf_%s", my_outdir, sample_name)

	merge_hc_germline_snp <- sprintf("mkdir -p %s && %s concat %s %s --output %s && %s index -t %s && touch %s_hc_germline.finished",
						my_outdir,
						opts_flow$get("bcftools_path"),
						opts_flow$get("bcftools_args1"),
						chrwise_hc_germline_snp,
						sprintf("%s_snp_calls.vcf.gz", final_outid_hc),
						opts_flow$get("bcftools_path"),
						sprintf("%s_snp_calls.vcf.gz", final_outid_hc),
						sample_name)

	names(merge_hc_germline_snp) <- "merge_hc_germline_snp"

	############## CLEAN UP ###############
	## can replace mv with rm -f to remove chromosome wise vcfs; first, check if merged vcf looks ok.
	cleanup_data <- sprintf("%s/runner/stepcheck.sh -i %s -f %s -p %s && ls *_splitid*vcf* && mkdir -p chrwise_vcfs && mv *_splitid*vcf* chrwise_vcfs/ && sleep 60 && rm chrwise_vcfs/*_splitid*vcf* && touch cleanup.done",
						opts_flow$get("mygit_path"),
						my_bampath,
						sprintf("%s_snp_calls.vcf.gz", final_outid),
						sprintf("%s_snp_calls.vcf.gz", final_outid_hc))
	
	names(cleanup_data) <- "cleanup_data"

	## generate a master flowmat with all the elements
	flownames = c(rep("vs2_germline", length(gatk_int_chrs)),
					rep("hc_germline", length(gatk_int_chrs)),
					"merge_germline_snp",
					"merge_hc_germline_snp", 
					"cleanup_data")

	jobnames <- c(rep(flownames[1], length(gatk_int_chrs)),
					rep(flownames[length(gatk_int_chrs)+1], length(gatk_int_chrs)),
					flownames[(length(gatk_int_chrs)*2+1):length(flownames)])

	cmds <- unlist(c(vs2_germline, hc_germline, merge_germline_snp, merge_hc_germline_snp, cleanup_data))

	flowmaster <- data.frame(rep(sample_name, length(cmds)), jobnames, cmds, stringsAsFactors = FALSE)

	colnames(flowmaster) <- c("samplename", "jobname", "cmd")
	
	## give workflow a name: a UUID will be tagged by flowr to this name.
	flowid = sprintf("cgp_germline_calls_%s", sample_name)
	
	## make flowr compatible flowmat.
	myflowmat <- to_flowmat(x = flowmaster, samplename = sample_name)
	
	#rm(flownames, tm_table, nr_table, mutect, flowmaster)
	
	## save all RData into logs directory
	myreports = sprintf("%s/flowr_%s", my_logs, flowid)
	
	if(!dir.exists(myreports)){
	  message("creating log dir, ", myreports)
	  dir.create(path = myreports, recursive = TRUE, mode = "0775")
	}
	
	## pull flow def or sequence of commands to be run from code repository and plot workflow as pdf.
	flowdef = as.flowdef("flowr_cgp_germline_calls.def")
	#plot_flow(flowdef, pdf = TRUE, pdffile = file.path(myreports, sprintf("workflow_%s.pdf", flowid)))

	## make flowr compatible list containing flowname and flowmat. 
	## flowr will use this list to run actual analysis pipeline using flowr::to_flow function.
	final_flow_object = list(flowmat = myflowmat, flowname = flowid)
	
	timetag = make.names(format(Sys.time(),"t%d_%b_%y_%H%M%S%Z"))
	mysessioninfo = sessionInfo()

	myinfomaster = list(envinfo = mysessioninfo, flowrmat = myflowmat, flowname = flowid)

	saveRDS(object = final_flow_object, file = sprintf("%s/cgp_germline_calls_debug_flow_object_%s_%s.rds", myreports, flowid, timetag))
	saveRDS(object = myinfomaster, file = sprintf("%s/cgp_germline_calls_sampleinfo_%s_%s.rds", myreports, flowid, timetag))
	
	return(list(flowmat = myflowmat, flowname = flowid))
}

### END ###
