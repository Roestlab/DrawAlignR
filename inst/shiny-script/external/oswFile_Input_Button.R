oswFile_Input_Button <- function(  input, output, global, values, session  ) {
  observeEvent( input$OSWFile, {
    
    tryCatch(
      expr = {
        
        ## OSWFile
        shinyFileChoose(input, 'OSWFile', roots = c( `Working Directory` =  "../", home = normalizePath("~"), root = .Platform$file.sep, `Recent Directory` = global$mostRecentDir  ), defaultRoot = 'Recent Directory', defaultPath = .Platform$file.sep  )
        ### Create a reactive object to store OSWFile
        oswFile <- reactive(input$OSWFile)
        
        values$OSWFile <- renderText({  
          global$oswFile
        }) 
        
        if ( class(oswFile())[1]=='list' ){
          ## Get root directory based on used choice, working directory, home or root
          if ( oswFile()$root=='Working Directory' ){
            root_node <- dirname(getwd())
          } else if ( oswFile()$root == 'home' ) {
            root_node <- path.expand("~")
          } else if ( oswFile()$root=="Recent Directory" ) {
            root_node <- global$mostRecentDir
          } else {
            root_node <- .Platform$file.sep
          }
          print(global$oswFile)
          ## Get oswFile working directroy of user selected directory
          global$oswFile <- lapply( oswFile()$files, function(x){ paste( root_node, file.path( paste( unlist(x), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) }) 
          names(global$oswFile) <- lapply(global$oswFile, basename)
          print(global$oswFile)
          ## Update global most recent directroy
          global$mostRecentDir <- dirname( dirname( global$oswFile[[1]] ) )
          ## Load OSW file
          use_ipf_score <- DrawAlignR:::Score_IPF_Present( global$oswFile[[1]] )
          tictoc::tic("Reading and Cacheing OSW File")
          osw_df <- mstools::getOSWData_( oswfile=global$oswFile[[1]], decoy_filter = TRUE, ms2_score = TRUE, ipf_score =  use_ipf_score)
          m_score_filter_var <- ifelse( length(grep( "m_score|mss_m_score", colnames(osw_df), value = T))==2, "m_score", "ms2_m_score" )
          osw_df %>%
            dplyr::filter( !is.na(m_score_filter_var)) -> osw_df
          values$osw_df <- osw_df
          tictoc::toc()
          print(osw_df)
          if ( dim(values$lib_df)[1]==0){
            ## Get list of unique modified peptides
            uni_peptide_list <- as.list(unique( osw_df$FullPeptideName ) )
            ## Update selection list with unique peptides
            updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list  )
          }
        }
        
      },
      error = function(e){
        message(sprintf("[Observe OSW Input Button] There was the following error that occured during OSW Input Button observation: %s\n", e$message))
      }
    ) # End tryCatch
    
  })
  return(list(global=global, values=values))
}