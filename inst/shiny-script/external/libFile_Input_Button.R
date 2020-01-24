libFile_Input_Button <- function( input, output, global, values, session ) {
  observeEvent( input$LibraryFile, {
    tryCatch(
      expr = {
        ## LibraryFile
        shinyFileChoose(input, 'LibraryFile', roots = c( `Working Directory` =  "../", home = normalizePath("~"), root = .Platform$file.sep, `Recent Directory` = global$mostRecentDir ), defaultRoot = 'Recent Directory', defaultPath = .Platform$file.sep  )
        ### Create a reactive object to store LibraryFile
        libFile <- reactive(input$LibraryFile)
        
        values$LibraryFile <- renderText({  
          global$libFile
        }) 
        if ( class(libFile())[1]=='list' ){
          ## Get root directory based on used choice, working directory, home or root
          if ( libFile()$root=='Working Directory' ){
            root_node <- dirname(getwd())
          } else if ( libFile()$root == 'home' ) {
            root_node <- path.expand("~")
          } else if ( libFile()$root=="Recent Directory" ) {
            root_node <- global$mostRecentDir
          } else {
            root_node <- .Platform$file.sep
          }
          ## Get libFile working directroy of user selected directory
          global$libFile <- lapply( libFile()$files, function(x){ paste( root_node, file.path( paste( unlist(x), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) }) 
          names(global$libFile) <- lapply(global$libFile, basename)
          ## Update global most recent directroy
          global$mostRecentDir <- dirname( dirname( global$libFile[[1]] ) )
          ## Read in library and Cache Library onto disk
          tictoc::tic("Reading and Cacheing Library File")
          lib_df <- mstools::getPepLibData_( global$libFile[[1]] )
          values$lib_df <- lib_df
          tictoc::toc()
          ## Get list of unique modified peptides
          uni_peptide_list <- as.list(unique( lib_df$MODIFIED_SEQUENCE )) 
          ## Update slection list with unique peptides
          updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list  )
        }
        
      },
      error = function(e){
        message(sprintf("[Observe Library Input Button] There was the following error that occured during Library Input Button observation: %s\n", e$message))
      }
    ) # End tryCatch
    
  })
  return(list(global=global, values=values))
}