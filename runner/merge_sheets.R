## Rscript by Sahil Seth
## merge_sheets x=sample_.mutect.txt outfile=sample_merged.mutect.tsv
## https://raw.githubusercontent.com/flow-r/ultraseq/glass/ultraseq/R/merge_sheets.R

merge_sheets <- function(x, outfile, .filter = NA, ...){
  tmp <- lapply(x, function(fl){
    message(".", appendLF = FALSE)
    tab = read_sheet(fl, ...)
    
    # convert all columns to character, fool proofing
    tab[] <- lapply(tab, as.character)
    dim(tab)

    # filtering each file, before merging
    if(!is.na(.filter)){
      tab2 = dplyr::filter_(tab, .filter)
      return(tab2)
    }else{
      return(tab)
    }
  })
  
  # mrgd = try(do.call(rbind, tmp))
  # if fails try using dplyr
  mrgd = try(bind_rows(tmp))
  
  if(!missing(outfile))
    write_sheet(mrgd, outfile)
  
  invisible(mrgd)
}
