#' Get a list of mz Objects 
#' @param input A shiny input variable that contains Working Directory Information
#' @param global A list variable containing paths to chromatogram files
#' @return (A list of mzRpwiz)
getmzPntrs <- function( input, global  ){
  
  ##*******************************
  ## Pre-Load mzML Files
  ##*******************************
  
  ## Get filenames from osw files and check if names are consistent between osw and mzML files. ######
  filenames <- DIAlignR::getRunNames( input$WorkingDirectory, oswMerged=TRUE)
  # runs <- c(input$Reference, gsub('...........$', '', input$ChromatogramFile[,'name']))
  # filenames <- filenames[filenames$runs %in% runs,]
  filenames <- filenames[grepl(paste(filenames$runs, collapse = "|"), names(global$chromFile)),]
  tictoc::tic('Pre-Loading mzML Chromatogram Files onto disk')
  mzPntrs <- list()
  for ( chromatogram_input_index_num in seq(1, length(filenames$runs)) ){
    run <- rownames(filenames)[ chromatogram_input_index_num ]
    current_filename <- filenames$runs[ chromatogram_input_index_num ]
    message(sprintf("Cacheing mzML for %s of %s runs", run, length(filenames$runs)))
    ## Get path for current chromatogram file
    chromatogram_file_i <-  global$chromFile[ grepl(current_filename, names(global$chromFile)) ][[1]]
    # Create an mzR object that stores all header information, and use ProteoWizard api to access data from MzML file
    mz <- mzR::openMSfile(chromatogram_file_i, backend = "pwiz", verbose = T)
    ## Get table of chromatogram incidces and respective transtion ids
    chromHead <- mzR::chromatogramHeader(mz)
    ## Store run id and mz object into master list
    mzPntrs[[run]] <- list()
    mzPntrs[[run]]$mz <- mz
    mzPntrs[[run]]$chromHead <- chromHead
  }
  tictoc::toc()
  
  return( mzPntrs )
  
}