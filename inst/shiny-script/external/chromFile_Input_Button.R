chromFile_Input_Button <- function( input, output, global, values, session ){
  
  observeEvent( input$ChromatogramFile, {
    tryCatch(
      expr = {
        ## ChromatogramFile
        shinyFileChoose(input, 'ChromatogramFile', roots = c( `Working Directory` =  "../", home = normalizePath("~"), root = .Platform$file.sep, `Recent Directory` = global$mostRecentDir ), defaultRoot = 'Recent Directory', defaultPath = .Platform$file.sep )
        ### Create a reactive object to store ChromatogramFile
        chromFile <- reactive(input$ChromatogramFile)
        values$ChromatogramFile <- renderText({  
          global$chromFile
        }) 
        if ( class(chromFile())[1]=='list' ){
          ## Get root directory based on used choice, working directory, home or root
          if ( chromFile()$root=='Working Directory' ){
            root_node <- dirname(getwd())
          } else if ( chromFile()$root == 'home' ) {
            root_node <- path.expand("~")
          } else if ( chromFile()$root=="Recent Directory" ) {
            root_node <- global$mostRecentDir
          } else {
            root_node <- .Platform$file.sep
          }
          ## Get chromFile working directroy of user selected directory
          global$chromFile <- lapply( chromFile()$files, function(x){ normalizePath( paste( root_node, file.path( paste( unlist(x), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) ) }) 
          
          names(global$chromFile) <- lapply(global$chromFile, function(file_path){gsub("\\..*", "", basename(file_path))} )
          
          ## Update global most recent directroy
          global$mostRecentDir <- dirname( dirname(global$chromFile[[1]]) )
          
          ## Store chromatogram file run names
          # values$chromnames <- gsub("\\.chrom\\.mzML$|\\.chrom\\.sqMass$", "", input$ChromatogramFile$name)
          values$chromnames <- gsub("\\.chrom\\.mzML$|\\.chrom\\.sqMass$", "", names(global$chromFile))
          ## Update Reference list
          updateSelectizeInput( session, inputId = "Reference", choices = as.list(values$chromnames) )
          ## Update Experiment list with first entry removed
          updateSelectizeInput( session, inputId = "Experiment", choices = as.list(values$chromnames[-1]), selected = as.list(values$chromnames[-1])  )
          ## Update n chroms input
          n_runs_index <- c(seq(1, length(values$chromnames)))
          names(n_runs_index) <-  paste( "Run ", seq(1, length((values$chromnames))), sep='')
          run_index_map <- c(seq(1, length(values$chromnames)))
          names(run_index_map) <- values$chromnames
          values$run_index_map <- run_index_map
          shiny::updateCheckboxGroupInput( session, inputId = "n_runs", choices = n_runs_index, selected = seq(1, length((values$chromnames))), inline = TRUE  )
        }
        
        ## Get File Extension Type
        # fileType <- gsub( '.*\\.', '', input$ChromatogramFile$name)
        fileType <- unique(gsub( ".*\\.", "", global$chromFile))
        if ( fileType=='mzML' | fileType=='mzML.gz'){
          ##*******************************
          ## Pre-Load mzML Files
          ##*******************************
          message("Cacheing mz objects")
          mzPntrs <- getmzPntrs( input, global  )
          ## Store mzPntrs container
          values$mzPntrs <- mzPntrs
        }
        
      },
      error = function(e){
        message(sprintf("[Observe Chromatogram Input Button] There was the following error that occured during Chromatogram Input Button observation: %s\n", e$message))
      }
    ) # End tryCatch
  })
  
  return(list(global=global, values=values))
  
}