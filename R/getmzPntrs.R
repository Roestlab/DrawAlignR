#' Get a list of mz Objects 
#' @param input A shiny input variable that contains Working Directory Information
#' @param global A list variable containing paths to chromatogram files
#' @param progress A logical value to track progress of cached files
#' @return (A list of mzRpwiz)
#' @export
getmzPntrs <- function( input, global, progress=FALSE  ){
  
  ##*******************************
  ## Pre-Load mzML Files
  ##*******************************
  
  ## Get filenames from osw files and check if names are consistent between osw and mzML files. ######
  filenames <- DrawAlignR::getRunNames( dataPath = input$WorkingDirectory, oswMerged=TRUE)
  # runs <- c(input$Reference, gsub('...........$', '', input$ChromatogramFile[,'name']))
  # filenames <- filenames[filenames$runs %in% runs,]
  filenames <- filenames[ grepl( paste(paste0('*', gsub("\\.\\w*", '', names(global$chromFile)), '*'), collapse = "|"), filenames$runs ), ]
  mzPntrs <- list()
  for ( chromatogram_input_index_num in seq(1, length(filenames$runs)) ){
    tryCatch(
      expr = {
        tictoc::tic()
        run <- rownames(filenames)[ chromatogram_input_index_num ]
        current_filename <- filenames$runs[ chromatogram_input_index_num ]
        # message(sprintf("Cacheing mzML for index %s -> %s (%s) of %s runs", chromatogram_input_index_num, run, current_filename, length(filenames$runs)))
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
        ## End timer
        exec_time <- tictoc::toc(quiet = T)
        message(sprintf("[DrawAlignR::getmzPntrs] Caching mzML for %s (%s) of %s runs: Elapsed Time = %s sec", run, current_filename, length(filenames$runs), round(exec_time$toc - exec_time$tic, 3) )) 
        ## Progress counter for visual pop-up
        if( progress ){
          incProgress(1/length(filenames$runs))
        }
        
      },
      error = function(e){
        message(sprintf("[DrawAlignR::getmzPntrs] There was an issue caching %s, skipping...:\nThe corresponding chromatogram file (%s) was most likely not in data directory. The last traceback call was: %s\n", current_filename, current_filename, e$message))
        mzPntrs[[run]] <- list()
        mzPntrs[[run]]$mz <- NULL
        mzPntrs[[run]]$chromHead <- NULL
      }
    ) # End tryCatch
  }
  
  return( mzPntrs )
  
}