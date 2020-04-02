workingDirectory_Input <- function( input, output, global, values, session ) {
  observeEvent( 
    {
      input$interactiveWorkingDirectory
      input$WorkingDirectory
    }, {
      if ( input$WorkingDirectoryInput  ) {
        
        ##*********************************
        ##    Working Directory
        ##*********************************
        tryCatch(
          expr = {
            ## Define Roots
            roots <- c( getwd(), path.expand("~"), .Platform$file.sep, global$mostRecentDir )
            names(roots) <- c("Working Directory", "home", "root", "Recent Directory")
            roots <- c(roots, values$drives()) 
            ## Get working directory contain data files
            shinyDirChoose(input=input, id='interactiveWorkingDirectory', roots = roots, defaultRoot = 'root', defaultPath = .Platform$file.sep, session=session  )
            ## Resetting Textbox input for working directory if interactive working directory button is selected.
            if( is.numeric(input$interactiveWorkingDirectory) ){
              message("[DrawAlignR::WorkingDirectoryInput] Working Directory button pressed. Resetting textbox\n")
              reset("WorkingDirectory")
            }
            if ( input$WorkingDirectory!="" ) {
              # print("Using test working directory input")
              global$datapath <- normalizePath( input$WorkingDirectory )
              ## Get mapping of runs to filename
              values$runs_filename_mapping <- getRunNames(global$datapath, oswMerged = TRUE, chrom_ext = ".chrom.mzML|.chrom.sqMass")
              ## Search working directory for osw file, mzml files, pqpfiles
              subDirs <- normalizePath( list.dirs( path = global$datapath, full.names = T, recursive = F ) )
            } else {
              # print("Using interactive button working directory input")
              ### Create a reactive object to store working directory
              dir <- reactive( input$interactiveWorkingDirectory )
              values$WorkingDirectory <- renderText({  
                global$datapath
              })  
              
              if ( class(dir())[1]=='list' ){
                ## Get root directory based on used choice, working directory, home or root
                root_node <- roots[ which( names(roots) %in% dir()$root ) ]
                ## Get full working directroy of user selected directory
                global$datapath <- normalizePath( paste( normalizePath(root_node), file.path( paste( unlist(dir()$path[-1]), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) )
                if ( global$datapath!=global$previous_datapath & global$previous_datapath!='' ){
                  message(sprintf("Previous working directory: %s --> New working directory: %s\n", global$previous_datapath, global$datapath ))
                }
                global$previous_datapath <- global$datapath
                ## Get mapping of runs to filename
                values$runs_filename_mapping <- getRunNames(global$datapath, oswMerged = TRUE, chrom_ext = ".chrom.mzML|.chrom.sqMass")
                ## Update global most recent directroy
                global$mostRecentDir <- global$datapath
                ## Update Working Directory Text Box
                updateTextInput( session = session, inputId = 'WorkingDirectory', value = global$datapath  )
              }
            }
            
            ## Search working directory for osw file, mzml files, pqpfiles
            subDirs <- normalizePath( list.dirs( path = global$datapath, full.names = T, recursive = F ) )
          },
          error = function(e){
            message(sprintf("[DrawAlignR::WorkingDirectoryInput] There was the following error that occured while obtaining working directory: %s\n", e$message))
          }
        ) # End tryCatch
        ## Search working directory for osw file, mzml files, pqpfiles
        subDirs <- normalizePath( list.dirs( path = global$datapath, full.names = T, recursive = F ) )

        ##*********************************
        ##    OSW Path Search
        ##*********************************
        ##*********************************
        tryCatch(
          expr = {
            if ( "osw" %in% basename(subDirs) ) {
              target_subdir <- normalizePath( paste(global$datapath ,'osw/',sep = .Platform$file.sep) )
              if ( any(grepl("\\.osw", list.files(subDirs))) ) {
                ## Search for OSW folder
                files_in_osw_dir <- normalizePath( list.files( target_subdir, pattern = "*osw$" ,full.names = T ) )
                if ( length(files_in_osw_dir) > 1 ){
                  warning( sprintf("There were %s osw files found, taking first file!!")) # TODO: If user uses non merged osw file?
                  files_in_osw_dir <- normalizePath( files_in_osw_dir[1] )
                }
                global$oswFile <- files_in_osw_dir
                
                ## Load OSW file
                use_ipf_score <- Score_IPF_Present( global$oswFile[[1]] )
                tictoc::tic("Reading and Cacheing OSW File")
                ### TODO : Need to make sure that this is extracting the correct information from the osw file when using the ipf scores
                osw_df <- mstools::getOSWData_( oswfile=global$oswFile[[1]], decoy_filter = TRUE, ms2_score = TRUE, ipf_score =  use_ipf_score)
                m_score_filter_var <- ifelse( length(grep( "m_score|mss_m_score", colnames(osw_df), value = T))==2, "m_score", "ms2_m_score" )
                osw_df %>%
                  dplyr::filter( !is.na(m_score_filter_var)) -> osw_df
                values$osw_df <- osw_df
                tictoc::toc()
                if (  is.null( values$lib_df ) ){
                  ## Get list of unique modified peptides
                  uni_peptide_list <- as.list(unique( osw_df$FullPeptideName ) )
                  ## Update selection list with unique peptides
                  updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list, selected = uni_peptide_list[1]  )
                  # input$Mod <- uni_peptide_list[1]
                }
              } else {
                warning( sprintf("There was no osw file found in osw directory:\n%s\n", target_subdir) )
              }
            } else {
              warning( sprintf("There was no osw folder found in working directory:\n%s\n", global$datapath) )
            }
          },
          error = function(e){
            message(sprintf("[WorkingDirectoryInput:findOSW] There was the following error that occured during OSW Path Searching: %s\n", e$message))
          }
        ) # End tryCatch
        
        ##*********************************
        ##    PQP Path Search
        ##*********************************
        tryCatch(
          expr = {
            if ( "pqp" %in% basename(subDirs)  ) {
              target_subdir <- normalizePath( paste(global$datapath ,'pqp/',sep = .Platform$file.sep) )
              if ( any(grepl("\\.pqp", list.files(subDirs))) ){
                ## Search for PQP folder
                find_file <- normalizePath( list.files( target_subdir, pattern = "*pqp$" ,full.names = T ) )
                if ( length(find_file) > 1 ){
                  warning( sprintf("There were %s pqp files found, taking first file!!")) # TODO: If user uses non merged osw file?
                  find_file <- find_file[1]
                }
                global$libFile <- find_file
                ## Read in library and Cache Library onto disk
                tictoc::tic("Reading and Cacheing Library File")
                lib_df <- mstools::getPepLibData_( global$libFile[[1]] )
                values$lib_df <- lib_df
                tictoc::toc()
                ## Get list of unique modified peptides
                uni_peptide_list <- as.list(unique( lib_df$MODIFIED_SEQUENCE )) 
                ## Update slection list with unique peptides
                updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list, selected = uni_peptide_list[1]  )
                # input$Mod <- uni_peptide_list[1]
              } else {
                warning( sprintf("There was no pqp file found in pqp directory:\n%s\n", target_subdir) )
              }
            } else {
              warning( sprintf("There was no pqp folder found in working directory:\n%s\n", global$datapath) )
            }
          },
          error = function(e){
            message(sprintf("[WorkingDirectoryInput:findPQP] There was the following error that occured during PQP Path Searching: %s\n", e$message))
          }
        ) # End tryCatch
        
        ##*********************************
        ##    Chromatogram Files
        ##*********************************
        tryCatch(
          expr = {
            if ( "mzml" %in% basename(subDirs) | "sqmass" %in% basename(subDirs) ) {
              chromTypes_available <- grep("mzml|sqmass", basename(subDirs), value=TRUE)
              output$chromTypes_available <- renderText({ chromTypes_available })
              global$chromTypes_available <- chromTypes_available
              chromTypes_available_list <- list()
              chromTypes_available_list <- (paste("Use ", chromTypes_available, sep=""))
              names(chromTypes_available_list) <- (paste("Use ", chromTypes_available, sep=""))
              shinyWidgets::updateAwesomeRadio(session = session, 
                                               inputId = "chromType_Choice",
                                               choices = chromTypes_available_list,
                                               inline = TRUE, 
                                               status = "primary",
                                               checkbox = TRUE
              )
              if ( "mzml" %in% basename(subDirs) ) {
                message("Searching mzml folder")
                target_subdir <- normalizePath( paste(global$datapath ,'mzml/',sep = .Platform$file.sep) )
                if ( any(grepl("\\.mzML", list.files(subDirs))) ){
                  ## Search for OSW folder
                  find_file <- normalizePath( list.files( target_subdir, pattern = "*mzML$" ,full.names = T ) )
                  
                  global$foundChromFiles$mzml <- find_file
                  names(global$foundChromFiles$mzml) <- lapply(global$foundChromFiles$mzml, function(file_path){gsub("\\..*", "", basename(file_path))} )
                } else {
                  warning( sprintf("There was no mzml file found in mzml directory:\n%s\n", target_subdir) )
                }
              }
              
              if ( "sqmass" %in% basename(subDirs) ) {
                message("Searching sqmass folder")
                target_subdir <- normalizePath( paste(global$datapath ,'sqmass/',sep = .Platform$file.sep) )
                if ( any(grepl("\\.sqMass", list.files(subDirs))) ){
                  ## Search for OSW folder
                  find_file <- normalizePath( list.files( target_subdir, pattern = "*sqMass$" ,full.names = T ) )
                  
                  global$foundChromFiles$sqmass <- find_file
                  names(global$foundChromFiles$sqmass) <- lapply(global$foundChromFiles$sqmass, function(file_path){gsub("\\..*", "", basename(file_path))} )
                  
                } else {
                  warning( sprintf("There was no sqmass file found in sqmass directory:\n%s\n", target_subdir) )
                }
              }
              
            } else {
              warning( sprintf("There was no mzml or sqmass folder found in working directory:\n%s\n", global$datapath) )
            }
            
          },
          error = function(e){
            message(sprintf("[WorkingDirectoryInput:findChroms] There was the following error that occured during Chromatogram Path Searching: %s\n", e$message))
          }
        ) # End tryCatch
        message("Finished workingDirectory Input parsing")
      }
    })
  return(list(global=global, values=values))
}
