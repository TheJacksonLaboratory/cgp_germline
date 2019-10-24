## Germline callers for Canine Glioma Project

@sbamin  
[Verhaak Lab](https://verhaaklab.com)  

### Using GATK4 HC and VarScan2

*   Using VarScan v2.4.2 and GATK 4.0.6.0 Haplotype Caller, GVCF mode.
*   Note that multiple samples at-once is supported only for VarScan2
*   HaplotypeCaller GVCF based on multiple sample bam files is **not supported** for now but can be run as a separate script once flowr outputs sample-wise GVCFs.
*   Provide multiple bams for `mybam_others=` as a character string with path to each bam separated by a space. Existence of multiple files is NOT checked before running varscan2 command.

```sh
flowr run x=flowr_cgp_germline_calls my_bampath="/path/to/sample1.bam" mybam_others="/path/to/sample2.bam /path/to/sample3.bam /path/to/sampleN.bam" sample_name="sample1toN" execute=FALSE
```

*   Once sample-wise GVCFs are generated, use following command to merge GVCFs across samples and then get joint genotyped vcf.
    -   Using legacy CombinedGVCfs over GenomicsDBImport as the latter gave several errors.
    -   Using chromosome-wise scatter approach and only using canonical chromosomes to speed up combining GVCFs.
    -   Following is qsub scripts optimized for Helix HPC at JAX GM and Verhaak Env. Please check `scripts/gatk_hc_merge_gvcfs_legacy_array.sh` for actual steps related to merging GVCFs and then genotyping merged, chr-wise vcfs.

```sh
## for smaller chrs
qsub array_gatk_hc_merge_gvcfs_n15.qsub
## for larger chrs: long queue
qsub array_gatk_hc_merge_gvcfs_n25.qsub
```

>Despite submitting large chrs in long queue, all of 40 chromosomes finished in ~ 24 hours with exit code 0.  

*   Concat chr-wise, genotyped vcfs using `bcftools concat`

```sh
./scripts/concat_vcfs.sh
```

*   Then, filter using hard filters based on [GATK ## 2806](https://gatkforums.broadinstitute.org/gatk/discussion/2806/howto-apply-hard-filters-to-a-call-set). VQSR step is preferred but we do not have a golden set to use as reference for true positive and true negative variants.
    -   ToDO: We can use Broad's 735 Dog snp panel or Dog10K panel, per breed/clade to determine clade or breed specific MAF in normal population. Such MAF value should then be used as cut-off to label potential germline variant in canine glioma cases, i.e., a germline variant in multiple cases but with MAF **less than** that of calculated from population snp panel. This should be further supported by constrained regions across species, CADD, PolyPhen2, etc. metrics, and cancer gene sets, ClinVar database, etc.

_END_
