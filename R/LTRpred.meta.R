#' @title Perform Meta-Analyses with LTRpred
#' @description Run \code{\link{LTRpred}} on several genomes (sequentially) that are stored in a given folder.
#' @param genome.folder file path to folder storing genome assembly files in \code{fasta} format.
#' @param output.folder path to the output folder storing \code{LTRpred.meta} results that will be generated. 
#' @param cores number of cores that shall be used for parallel processing.
#' @param \dots arguments that shall be passed to \code{\link{LTRpred}}.
#' @export

LTRpred.meta <- function(genome.folder,
                         output.folder,
                         cores = 1,
                         ...) {
  
  
  if (cores > parallel::detectCores())
    stop(
      "You sepcified more cores than are available on your machine. Please provide the correct number of cores.",
      call. = FALSE
    )
  
  if (!file.exists(genome.folder))
    stop(
      "Please provide a valid path to the genome folder. The folder '",
      genome.folder,
      "' does not seem to exist.",
      call. = FALSE
    )
  
  if (!file.exists(output.folder)) {
    dir.create(output.folder)
  } else {
    message(
      "The folder '",
      output.folder,
      "' exists already and will be used to store LTRpred.meta() results."
    )
  }
  
  assembly_files <- list.files(genome.folder)
  doc_file <- which(stringr::str_detect(assembly_files, "documentation"))
  
  if (length(doc_file) > 0)
    assembly_files <- assembly_files[-doc_file]
  
  assembly_files_chop <- str_chop_vec(assembly_files, pattern = "[.]")
  
  message("Starting LTRpred meta run on ", length(assembly_files_chop), " assembly files using ", cores ," cores: ", paste0(assembly_files_chop, collapse = ", "))
  
  # Setup cluster
  clust <- parallel::makeCluster(cores)
  
  res <- parallel::parLapply(clust, seq_len(length(assembly_files_chop)), function(i) {
    message("Processing species '", assembly_files_chop[i], "' ...")
    
    LTRpred(genome.file = file.path(genome.folder, assembly_files[i]),
            cores = 1,
            job_num = i,
            output.path = file.path(output.folder, paste0(assembly_files_chop[i], "_ltrpred")),
            ...)
  })
  
  parallel::stopCluster(clust)
  
  message("Finished LTRpred meta analysis! All results were stored in: ", output.folder)
  return(res)
}

