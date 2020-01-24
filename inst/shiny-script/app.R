#' Builds the shiny webapp for DrawAlignR
#'
#' @return None. Calling this script creates the Shiny webapp
#'
#' @import shiny
#' @import shinyjs
#' @import shinyFiles 
#' @import shinyWidgets
#' @import shinyBS
#' @import plotly
#' @import DIAlignR
#' @import mstools
#'
#' @source "GetXIC.r"
#' @source "getPepLibData.R"
#' @source "getChromatogramDatapoints.R"
#' @source "plot_aligned.R"
#' @source "plot_chrom_reference.R"
#' @source "helpers.R"
#' @source "uiTabs.R"
#' @source "getmzPntrs.R"

#Setting max file size
options(shiny.maxRequestSize=1000000*1024^2)

## This should be done only if the user does not have the package, otherwise it will install everytime the app is run, and will be very slow for installing large packages.
# if (!requireNamespace("BiocManager", quietly = TRUE))
#   install.packages("BiocManager")
# BiocManager::install("mzR") # Requires netcdf

## Some usefull functionality here
# install.packages("shinyjs")

## Cool Widgets
# install.packages("shinyWidgets")

## Extra Bootstrap controls
# install.packages("shinyBS")


### TODO in the future: Link zooming
### https://stackoverflow.com/questions/47933524/how-do-i-synchronize-the-zoom-level-of-multiple-charts-with-plotly-js


library(shiny)
library(shinyjs)
library(shinyFiles)
library(shinyWidgets)
library(shinyBS)
library(plotly)
library(mstools)
library(DIAlignR)

# withConsoleRedirect <- function(containerId, expr) {
#   # Change type="output" to type="message" to catch stderr
#   # (messages, warnings, and errors) instead of stdout.
#   txt <- capture.output(results <- expr, type = "output")
#   if (length(txt) > 0) {
#     insertUI(paste0("#", containerId), where = "beforeEnd",
#              ui = paste0(txt, "\n", collapse = "")
#     )
#   }
#   results
# }


source( "external/uiTabs.R", local = TRUE )
source( "external/server_help_description_text.R", local = TRUE )
source( "external/chromFile_Input_Button.R", local = TRUE )
source( "external/libFile_Input_Button.R", local = TRUE )
source( "external/oswFile_Input_Button.R", local = TRUE )
source( "external/workingDirectory_Input.R", local = TRUE )
ui <- fluidPage(
  
  useShinyjs(),  # Include shinyjs
  
  titlePanel( title=div( img(src="DIAlignR-logo.jpg", width = 80, height = 80, align="top" ), ( HTML(sprintf("DrawAlignR <h6 style='display:inline'>Ver: %s</h6>", packageVersion("DrawAlignR"))) ) ) ),
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        GeneralSettingsTab, 
        AlignmentSettingsTab,
        PlottingSettingsTab
      ) # End of tabsetPanel
    ), # End of sidebarPanel
    
    
    mainPanel(
      uiOutput("plots"),
      
      absolutePanel( id='log-pannel', draggable = TRUE,
                     ## Log
                     fluidRow(
                       
                       # log output
                       textOutput( 'log' )
                     )
      )
      
    ) # End of mainPanel
  ) # End of sidebarLayout
) # End of ui

# source("../../R/helpers.R")
# source( "../../R/getmzPntrs.R")
# source( "../../R/curateXICplot.R")
server <- function(input, output, session) {
  
  server_help_description_text(input, output, session)
  
  ## reactive values object to store some re-usable stuff
  values <- reactiveValues()
  values$transition_selection_list <- list()
  values$lib_df <- NULL
  global <- reactiveValues(datapath = getwd(), chromFile = getwd(), libFile = getwd(), oswFile = getwd(), mostRecentDir = getwd(), foundChromFiles = list(mzml=list(), sqmass=list()), chromTypes_available = "" )
  output$chromTypes_available <- renderText({ '' })
  
  # TODO: Remove these clear buttons, they're not needed anymore? 
  ## Clear Chromatogram File input
  observeEvent( input$resetChromatogramFile, {
    shinyjs::reset('ChromatogramFile')
    
  } )
  
  ## Clear Library File input
  observeEvent( input$resetLibraryFile, {
    shinyjs::reset('LibraryFile')
  } )
  
  ## Clear OSW File input
  observeEvent( input$resetOSWFile, {
    shinyjs::reset('OSWFile')
  } )
  
  ## Observe Working Directory Input material switch.
  #   User may switch between using a working directory or
  #   supply each individual file
  observeEvent( input$WorkingDirectoryInput, {
    if ( input$WorkingDirectoryInput ){
      ## Observe interactive set working directory button
      workingDirectory_Input( input, output, global, values, session )
    } else {
      ## Observe input chromatogramfile 
      chromFile_Input_Button( input, output, global, values, session ) 
      
      ## Observe LibraryFile button
      libFile_Input_Button( input, output, global, values, session )
      
      ## Observe OSWFile button
      oswFile_Input_Button(  input, output, global, values, session  )
    }
  })
  
  ## If multiple chromatogram format types are found, check to see which fortmat user wants to use  
  observeEvent( input$chromType_Choice, {
    print(sprintf("Using chromtype: %s", input$chromType_Choice))
    tryCatch(
      expr = {
        if ( grepl(".*mzml", input$chromType_Choice) ){
          if ( input$WorkingDirectoryInput  ) {
            global$chromFile <- global$foundChromFiles$mzml
            
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
            
            ## Get File Extension Type
            # fileType <- gsub( '.*\\.', '', input$ChromatogramFile$name)
            fileType <- unique(gsub( ".*\\.", "", global$chromFile))
            if ( fileType=='mzML' | fileType=='mzML.gz'){
              ##*******************************
              ## Pre-Load mzML Files
              ##*******************************
              mzPntrs <- getmzPntrs( input, global  )
              ## Store mzPntrs container
              values$mzPntrs <- mzPntrs
            }
          }
          
        } else if ( grepl(".*sqmass", input$chromType_Choice) ){
          if ( input$WorkingDirectoryInput  ) {
            global$chromFile <- global$foundChromFiles$sqmass
            values$mzPntrs <- NULL
          }
        } else {
          warning(sprintf("There was an issue with the chromType, selection is not a currently supported format: %s", input$chromType_Choice))
        }
      },
      error = function(e){
        message(sprintf("[chromType_Choice:cache mzML] There was the following error that occured during Chromatogram Path Searching: %s\n", e$message))
      }
    ) # End tryCatch
    
  })
  
  ## Observe Reference input
  observeEvent( input$Reference, {
    ## Get Reference Run
    values$Reference <- input$Reference
    ## Get Experiments minuc Reference
    values$Experiments_to_Align <- values$chromnames[ !(values$chromnames %in% input$Reference) ]
    ## Update Experiment list with first entry removed
    updateSelectizeInput( session, inputId = "Experiment", choices = as.list(values$Experiments_to_Align), selected = as.list(values$Experiments_to_Align) )
  })
  
  ## Observe Peptide Selection
  observeEvent( input$Mod, {
    
    tryCatch(
      expr = {
        
        ## Check if there is no lib df returned from intial library load
        if ( !is.null( values$lib_df ) ){
          ## get unique charge state for current peptide selection
          values$lib_df %>%
            dplyr::filter( MODIFIED_SEQUENCE==input$Mod ) %>%
            dplyr::select( PRECURSOR_CHARGE ) %>%
            unique() %>%
            as.list() -> unique_charges
          names(unique_charges) <- unique_charges
          ## Update charge selection to charges available for currently selected peptide sequence.  
          updateSelectizeInput( session, inputId = 'Charge', choices = unique_charges )
        } else if ( !is.null(values$osw_df) ) {
          values$osw_df %>%
            dplyr::filter( FullPeptideName==input$Mod ) %>%
            dplyr::select( Charge ) %>%
            unique() %>%
            as.list() -> unique_charges
          names(unique_charges) <- unique_charges
          ## Update charge selection to charges available for currently selected peptide sequence.  
          updateSelectizeInput( session, inputId = 'Charge', choices = unique_charges )
        }
      },
      error = function(e){
        message(sprintf("[Updating Charge Drop Down List] There was the following error that occured during Charge Drop Down List: %s\n", e$message))
      }
    ) # End tryCatch
  } )
  
  
  ## transition_selection_list
  observeEvent( {input$yIdent
    input$bIdent }, {
      
      tryCatch(
        expr = {
          
          if ( input$yIdent!="" ){
            values$transition_selection_list$y <- c(DrawAlignR:::text2numericInput(input$yIdent))
          } else {
            values$transition_selection_list$y <- NULL
          }
          
          if ( input$bIdent!="" ){
            values$transition_selection_list$b <- c(DrawAlignR:::text2numericInput(input$bIdent))
          } else {
            values$transition_selection_list$b <- NULL
          }
        }, 
        error = function(e){
          message(sprintf("[Observe Identifying ions selection] There was the following error that occured during Identifying Ions Input Observation: %s\n", e$message))
        }
      ) # End tryCatch
    })
  
  
  #Generate set of variable plots
  
  output$plots <- renderUI({
    plot_output_list <- lapply(1:length(input$n_runs), function(i) {
      run_index <- input$n_runs[[i]]
      plotname <- paste("plot_run_", run_index, sep="")
      print(paste("Creating plot ", plotname, sep=""))
      plotlyOutput(plotname)
    })
    do.call(tagList, plot_output_list)
    
  })
  
  observeEvent( 
    {
      input$Mod
      input$Align 
    }, {
      if ( !(input$Align) ){
        cat("Alignment option was not selected\n")
        
        
        #Generate all plots. Max plots set to 10
        # NOTE: Should we loop over each chrom file input, or loop over each selected n runs input
        for ( i in seq(1,length(input$n_runs)) ) {
          local({
            my_i <- i
            run_index <- input$n_runs[[i]]
            plotname <- paste("plot_run_", run_index, sep="")
            
            output[[plotname]] <- renderPlotly({
              
              
              #If alignment is disabled, generate standard chromatogram plot.
              if ( !grepl(".*mzML$|.*sqMass$", global$chromFile) ){
                stop('A Chromgatogram file was not supplied or not found')
              }
              else if ( !grepl(".*pqp$", global$libFile) ){
                stop("A Library File was not supplied or not found")
              } else if ( !grepl(".*osw$", global$oswFile) ){
                stop("A Merged OSW Results File was not supplied or not found")
              }
              else if (is.null(input$Mod)){
                stop("There was no peptide found")
              }
              
              
              tryCatch(
                expr = {
                  chrom_input <- global$chromFile[[my_i]]
                  osw_input <- global$oswFile[[1]]
                  peptide <- input$Mod
                  modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
                  naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
                  current_run_id <- rownames(values$runs_filename_mapping )[ values$runs_filename_mapping $runs %in% gsub("\\.\\w+", "", basename(chrom_input)) ]
                  
                  # cat( sprintf("chrom: %s\nosw: %s\nlib: %s\n", chrom_input, osw_input, lib_input))
                  tictoc::tic("Plotting:")
                  out.plot.h <- DrawAlignR::curateXICplot( pep=naked_peptide, 
                                                           uni_mod=peptide,
                                                           in_sqMass=chrom_input,  df_lib=values$lib_df, in_osw=osw_input, df_osw=values$osw_df,
                                                           plotPrecursor=input$Precursor,
                                                           plotDetecting=input$Detecting,
                                                           plotIdentifying=input$Identifying_Unique,
                                                           plotIdentifying.Unique=input$Identifying_Unique,
                                                           plotIdentifying.Shared=F,
                                                           plotIdentifying.Against=F,
                                                           doFacetZoom=F,
                                                           doPlot=T,
                                                           Charge_State=input$Charge,
                                                           printPlot=F,
                                                           store_plots_subdir=NULL,
                                                           use_top_trans_pep=F,
                                                           transition_selection_list=values$transition_selection_list,
                                                           show_n_transitions=input$nIdentifyingTransitions,
                                                           show_transition_scores=input$ShowTransitionScores,
                                                           show_all_pkgrprnk=input$ShowAllPkGrps,
                                                           # show_manual_annotation = manual_annotation_coordinates,
                                                           show_peak_info_tbl=F,
                                                           show_legend=T,
                                                           mzPntrs=values$mzPntrs[[current_run_id]]
                  )
                  
                  tictoc::toc()
                  # )
                  # output$log <- renderText( paste(log, collapse = '\n') )
                  plotly::ggplotly( (out.plot.h), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                    layout(title = list(text = paste0(out.plot.h$labels$title,
                                                      '<br>',
                                                      '<sup>',
                                                      gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', out.plot.h$labels$subtitle)),
                                                      '</sup>')))
                  
                }, 
                error = function(e){
                  message(sprintf("[MasterXICPlotting] There was the following error that occured during XIC Plotting: %s\n", e$message))
                }
              ) # End tryCatch
              
              
            }) # End renderPlotly
          }) # End local
        } # End For
        
        
      } else {
        cat('Alignment Option was selected\n')
        
        AlignObj_List <- list()
        for ( i in input$Experiment ) {
          print("Start Experiment Alignment")
          print(paste("Current Exp: ", i, sep=""))
          
          # Define Experiment_i
          current_experiment <- i
          # Get run Indec
          run_index <- values$run_index_map[[ current_experiment ]]
          cat( sprintf("Working on Experiment %s with Run Index: %s\n", current_experiment, run_index) )
          
          #Ensuring at least two runs selected, not conducting alignment against same run
          if (!(input$Reference == gsub('...........$', '', current_experiment ))){
            
            
            tryCatch(
              expr = {  
                
                tictoc::tic("DIAlignR Elapsed Time")
                dataPath <- input$WorkingDirectory
                analytes <- paste(input$Mod, "_", toString(input$Charge), sep="")
                runs <- c(input$Reference, current_experiment)
                cat( sprintf( "Reference: %s\nExperiment: %s\n", input$Reference, current_experiment))
                # cat( sprintf( "Runs: %s\n", runs ) )
                mzPntrs <- values$mzPntrs
                suppressWarnings(
                  AlignObjOutput <- DrawAlignR::getAlignObjs(analytes = analytes, runs = runs, dataPath = dataPath, refRun = input$Reference, 
                                                             analyteInGroupLabel = input$analyteInGroupLabel, identifying = input$identifying, 
                                                             oswMerged = input$oswMerged, nameCutPattern = input$nameCutPattern,
                                                             maxFdrQuery = input$maxFdrQuery, maxFdrLoess = input$maxFdrLoess, analyteFDR = input$analyteFDR, 
                                                             spanvalue = input$spanvalue,  normalization = input$normalization, simMeasure = input$simMeasure,
                                                             XICfilter = input$XICfilter, SgolayFiltOrd = input$SgolayFiltOrd, SgolayFiltLen = input$SgolayFiltLen,
                                                             goFactor = input$goFactor, geFactor = input$geFactor, cosAngleThresh = input$cosAngleThresh, OverlapAlignment = input$OverlapAlignment,
                                                             dotProdThresh = input$dotProdThresh, gapQuantile = input$gapQuantile, hardConstrain = input$hardConstrain, 
                                                             samples4gradient = input$samples4gradient,  samplingTime = input$samplingTime,  RSEdistFactor = input$RSEdistFactor, 
                                                             objType = "light", mzPntrs = mzPntrs)
                )
                tictoc::toc()
                cat("\n")
                
                AlignObj_List[[current_experiment]] <- AlignObjOutput
                
              }, 
              error = function(e){
                message(sprintf("[Alignment] There was the following error that occured during Alignment: %s\n", e$message))
              }
            ) # End tryCatch
            
          }
        }
        
        # observeEvent( input$OriginalRTAnnotation, {
        
        for ( i in input$Experiment ) {
          # Need local so that each item gets its own number. Without it, the value
          # of i in the renderPlotly() will be the same across all instances, because
          # of when the expression is evaluated
          local({
            print("")
            print("START PLOTTING")
            # Define Experiment_i
            current_experiment <- i
            cat(sprintf("Current Exp: %s of :\n", current_experiment))
            
            # Get run Indec
            run_index <- values$run_index_map[[ current_experiment ]]
            cat(sprintf( "Current run index: %s\n", run_index))
            
            tryCatch(
              expr = { 
                print("Getting Plots...")
                cat( sprintf( "Names in AlignOPObjs: %s\n", names(AlignObj_List) ) )
                ## Generate Plot
                k <- DrawAlignR::plotAlignedAnalytes(AlignObjOutput = AlignObj_List[[current_experiment]], DrawAlignR = T, annotatePeak = T, annotateOrgPeak = input$OriginalRTAnnotation, global = global, input = input)
                # values$plot_i <- 1
                ## Plot Reference
                
                if ( values$run_index_map[[ input$Reference ]] %in% input$n_runs ){
                  local({
                    plotname <- paste("plot_run_", values$run_index_map[[ input$Reference ]], sep="")
                    cat(sprintf("Plotname: %s for run: %s\n", plotname, input$Reference))
                    output[[ plotname ]] <- renderPlotly({
                      
                      pt1 <- plotly::ggplotly( (k$prefU), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                        layout(title = list(text = paste0(k$prefU$labels$title,
                                                          '<br>',
                                                          '<sup>',
                                                          gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', k$prefU$labels$subtitle)),
                                                          '</sup>')))
                      
                      
                    }) # End renderPlotly
                    cat("Successfully plotted reference\n")
                  })
                }
                
                ## Plot aligned Experiment 
                if ( run_index %in% input$n_runs ){
                  local({
                    plotname <- paste("plot_run_", run_index, sep="")
                    cat(sprintf("Plotname: %s for run: %s\n", plotname, current_experiment))
                    output[[ plotname ]] <- renderPlotly({
                      
                      pt3 <- plotly::ggplotly( (k$peXpA), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                        layout(title = list(text = paste0(k$peXpA$labels$title,
                                                          '<br>',
                                                          '<sup>',
                                                          gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', k$peXpA$labels$subtitle)),
                                                          '</sup>')))
                      
                      
                    }) # End renderPlotly
                    cat( unique(k$peXpA$labels$subtitle),'\n')
                    cat(sprintf("Successfully Plotted Plotname: %s for run: %s\n", plotname, current_experiment))
                  })
                }
                
              }, 
              error = function(e){
                message(sprintf("[Plotting Alignment] There was the following error that occured during Plotting Alignment: %s\n", e$message))
              }
            ) # End tryCatch
          })
        }
        
        
        # }) # End ObserveEvent for showing original annotaiton
        
        
        
        
        
      } # End else plot alignment checkbox
      
      
    }) # End Observe Event
  
  
  ## Return gloval varialbles for UI to use
  outputOptions(output, "chromTypes_available", suspendWhenHidden = FALSE)
  
} ## End Server


shinyApp(ui = ui, server = server)

