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
#' @importFrom  DIAlignR getGlobalAlignment getAlignObj 
#' @importFrom mstools getXIC getTransitionScores_ unimodTocodename codenameTounimod getChromatogramDataPoints_ getPepLibData_ getOSWData_ log_setup getmzPntrs getsqMassPntrs
#'

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
library(DrawAlignR)
# library(mstools)
# library(DIAlignR)



source( "external/uiTabs.R", local = TRUE )
source( "external/server_help_description_text.R", local = TRUE )
source( "external/chromFile_Input_Button.R", local = TRUE )
source( "external/libFile_Input_Button.R", local = TRUE )
source( "external/oswFile_Input_Button.R", local = TRUE )
source( "external/workingDirectory_Input.R", local = TRUE )
source( "external/linkZoomEvent.R", local = TRUE )
source( "external/cacheAlignmentPlots.R", local = TRUE )
source( "external/drawAlignedPlots.R", local = TRUE )
source( "external/clearPlots.R", local = TRUE )
source( "external/withConsoleRedirect.R", local = TRUE )

# UI ----------------------------------------------------------------------

ui <- fluidPage(
  
  useShinyjs(),  # Include shinyjs
  
  titlePanel( title=div( img(src="DIAlignR-logo.jpg", width = 80, height = 80, align="top" ), ( HTML(sprintf("DrawAlignR <h6 style='display:inline'>Ver: %s</h6>", tryCatch(expr={ver<-packageVersion("DrawAlignR")}, error = function(e){ ver<-'0' }) )) ) ) ),
  sidebarLayout(
    sidebarPanel(
      tabsetPanel(
        GeneralSettingsTab, 
        AlignmentSettingsTab,
        PlottingSettingsTab
      ) # End of tabsetPanel
    ), # End of sidebarPanel
    
    
    mainPanel(
      verbatimTextOutput("brushing"),
      
      # Output: Tabset with Chromatogram Plots, Path Plots and Tables
      tabsetPanel(type = "tabs", id="output_tabs",
                  tabPanel( "chromPlot", uiOutput("plots") ),
                  tabPanel( "pathPlot", uiOutput("pathplots") ),
                  tabPanel( "oswTable", uiOutput("oswtables" ) ),
                  tabPanel( "logs", 
                            fluidPage(
                              tags$style(HTML("
                  #console {
                    height:800px;
                    overflow-y:scroll
                  }
                  ")),
                              pre(id = "console")
                            )
                  )
      ),
      ## Cacheing Progress Bar
      plotOutput("bar") 
      
      # absolutePanel( id='log-pannel', draggable = TRUE,
      #                ## Log
      #                fluidRow(
      #                  
      #                  # log output
      #                  textOutput( 'log' )
      #                )
      # )
      
    ), # End of mainPanel
    
  ) # End of sidebarLayout
) # End of ui


# SERVER ------------------------------------------------------------------

## TODO: REMOVE THE LINE BELOW WHEN DEPLOYING STABLE VERSION
# print(list.files( getwd(), full.names = T, recursive = T) )
# lapply(list.files("./R/", full.names = T), function( source_file ) { message(sprintf("Loading Source File: %s\n", source_file)); source(source_file, local = TRUE) } )
# unzoom_double_click <<- NULLi
server <- function(input, output, session) {
  
  # Server Help Annotations -------------------------------------------------
  
  server_help_description_text(input, output, session)
  
  
  # Server Reactive Values --------------------------------------------------
  
  ## reactive values object to store some re-usable stuff
  values <- reactiveValues(
    Reference = '',
    Previous_Reference = '',
    Experiments_to_Align = '',
    transition_selection_list = list(),
    lib_df = NULL,
    reference_plotted = FALSE,
    drives = shinyFiles::getVolumes(),
    plots = list(),
    alignedChromsPlot = list(),
    alignmentPathPlot = list(),
    mzPntrs = NULL,
    start_plotting = FALSE
  )
  global <- reactiveValues(
    datapath = '', 
    previous_datapath = '',
    chromFile = '', 
    libFile = '', 
    oswFile = '', 
    mostRecentDir = getwd(), 
    foundChromFiles = list(mzml=list(), sqmass=list()), 
    chromTypes_available = "",
    plotly.autorange.x = T,
    plotly.autorange.y = T,
    link_zoom_range_current = list(),
    unzoom_double_click = NULL
  )
  output$chromTypes_available <- renderText({ '' })
  # link_zoom_ranges  <- reactiveValues(x = NULL, y = NULL)
  brush <- NULL
  makeReactiveBinding("brush")
  n_runs_index <- NULL
  out.plot.h <- NULL
  # link_zoom_ranges <- reactiveValues(`xaxis.range[0]`=NULL, `xaxis.range[1]`=NULL, `yaxis.range[0]`=NULL, `yaxis.range[1]`=NULL)
  # link_zoom_range_current <- reactiveValues(`xaxis.range[0]`=NULL, `xaxis.range[1]`=NULL, `yaxis.range[0]`=NULL, `yaxis.range[1]`=NULL)
  # link_zoom_range_current <- reactiveValues()
  # link_zoom_ranges <- list(`xaxis.range[0]`=1650, `xaxis.range[1]`=1900, `yaxis.range[0]`=0, `yaxis.range[1]`=15000)
  
  
  # Show/Hide Output Tabs ---------------------------------------------------
  observe( {
    if (input$Align==TRUE){
      showTab(inputId = "output_tabs", target = "pathPlot")
    } else {
      hideTab(inputId = "output_tabs", target = "pathPlot")
    }
  })
  
  # File Input Events -------------------------------------------------------
  
  ## Observe Working Directory Input material switch.
  #   User may switch between using a working directory or
  #   supply each individual file
  observeEvent( input$WorkingDirectoryInput, {
    withConsoleRedirect("console", {
    message("Welcome! Have fun Aligning! =)")
    if ( input$WorkingDirectoryInput ){
      # cat("values$drives: ", names(values$drives()), "\n", sep="")
      # cat("global$datapath: ", global$datapath, "\n", sep="")
      ## Observe interactive set working directory button
      workingDirectory_Input( input, output, global, values, session )
      # if ( global$datapath!='' & global$chromFile!=''  ){
      # values$start_plotting <- TRUE
      # }
    } else {
      ## Observe input chromatogramfile 
      chromFile_Input_Button( input, output, global, values, session ) 
      
      ## Observe LibraryFile button
      libFile_Input_Button( input, output, global, values, session )
      
      ## Observe OSWFile button
      oswFile_Input_Button(  input, output, global, values, session  )
      
    }
    })
  })
  
  ## Get mapping of runs to filename
  observeEvent( {
    global$oswFile
    global$chromFile
    input$chromType_Choice
  },{
    if ( input$chromType_Choice!='' | length(input$chromType_Choice) > 0){
      ## Get mapping of runs to filename
      if ( grepl(".*mzml", input$chromType_Choice) ){
        use_chrom_ext <- "*.mzML|.chrom.mzML"
      } else if ( grepl(".*sqmass", input$chromType_Choice) ){
        use_chrom_ext <- "*.sqMass|.chrom.sqMass"
      } else {
        use_chrom_ext <- NULL
      }
      if ( !is.null(use_chrom_ext) & global$oswFile!='' & all(global$chromFile!='') ){
        values$runs_filename_mapping <- getRunNames(oswFiles = global$oswFile, chromFiles = global$chromFile, oswMerged = TRUE, chrom_ext = use_chrom_ext)
      }
    }
  })
  
  # Chromatogram File Cacheing Events ---------------------------------------
  
  ## If multiple chromatogram format types are found, check to see which fortmat user wants to use  
  observeEvent( {
    input$chromType_Choice
    global$datapath
  } , {
    withConsoleRedirect("console", {
    if ( input$chromType_Choice!='' ){
      message( sprintf("Using chromtype: %s", input$chromType_Choice) )
      tryCatch(
        expr = {
          if ( grepl(".*mzml", input$chromType_Choice) ){
            if ( input$WorkingDirectoryInput  ) {
              global$chromFile <- global$foundChromFiles$mzml
              
              ## Store chromatogram file run names
              # values$chromnames <- gsub("\\.chrom\\.mzML$|\\.chrom\\.sqMass$", "", input$ChromatogramFile$name)
              values$chromnames <- gsub("\\.chrom\\.mzML$|\\.chrom\\.sqMass$", "", names(global$chromFile))
              if ( !is.null(values$osw_df) | dim(values$osw_df)[1]>0 ){
                values$osw_df %>%
                  dplyr::select( filename ) %>%
                  dplyr::group_by( filename ) %>%
                  dplyr::add_count() %>%
                  unique() %>%
                  dplyr::ungroup() %>%
                  dplyr::filter( n == max(n) ) %>%
                  dplyr::select( filename ) %>%
                  as.character() %>%
                  basename() %>%
                  strsplit("\\.") %>% unlist() %>% dplyr::nth(1) -> run_with_most_features
              } else {
                run_with_most_features <- values$chromnames[1]
              }
              ## Update Reference list
              updateSelectizeInput( session, inputId = "Reference", choices = as.list(values$chromnames), selected = as.list(run_with_most_features) )
              ## Update Experiment list with first entry removed
              updateSelectizeInput( session, inputId = "Experiment", choices = as.list(values$chromnames[-(match(run_with_most_features, values$chromname))]), selected = as.list(values$chromnames[-(match(run_with_most_features, values$chromname))]) )
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
              if ( tolower(fileType)=='mzml' | tolower(fileType)=='mzml.gz' ){
                ##*******************************
                ## Pre-Load mzML Files
                ##*******************************
                output$bar <- renderPlot({
                  withProgress(message = sprintf('Cacheing %s mzML Chromatogram File(s)...', length(n_runs_index)),
                               detail = 'This might take a while for large chromatogram files...', value = 0, expr = {
                                 values$mzPntrs <- DrawAlignR::getmzPntrs( input, global, progress=TRUE  )
                               })
                })
                # print(mzPntrs)
                ## Store mzPntrs container
                # values$mzPntrs <- mzPntrs
                
              } 
              
            }
            
          } else if ( grepl(".*sqmass", input$chromType_Choice) ){
            if ( input$WorkingDirectoryInput  ) {
              global$chromFile <- global$foundChromFiles$sqmass
              
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
              if ( tolower(fileType)=='sqmass' ){
                ##*******************************
                ## Pre-Load sqMass Files
                ##*******************************
                ## Get filenames from osw files and check if names are consistent between osw and mzML files. 
                filenames <- getRunNames( input$WorkingDirectory, oswMerged=TRUE, chrom_ext=".chrom.sqMass")
                runs <- filenames$runs
                names(runs) <- rownames(filenames)
                output$bar <- renderPlot({
                  withProgress(message = sprintf('Cacheing %s mzML Chromatogram File(s)...', length(n_runs_index)),
                               detail = 'This might take a while for large chromatogram files...', value = 0, {
                                 values$mzPntrs <- DrawAlignR::getsqMassPntrs(dataPath=input$WorkingDirectory, runs)
                               })
                })
                # values$mzPntrs <- mzPntrs
              }
            }
          } else {
            warning(sprintf("There was an issue with the chromType, selection is not a currently supported format: %s", input$chromType_Choice))
          }
        },
        error = function(e){
          message(sprintf("[chromType_Choice:cache mzML] There was the following error that occured during Chromatogram Path Searching: %s\n", e$message))
        }
      ) # End tryCatch
    }
  }) # end withConsoleRedirect
  }) # End observer
  
  # Reference and Experiment Input Events -----------------------------------
  
  
  ## Observe Reference input
  observeEvent( input$Reference, {
    withConsoleRedirect("console", {
    ## Get Reference Run
    values$Reference <- input$Reference
    if ( values$Reference!=values$Previous_Reference & values$Previous_Reference!='' ){
      message(sprintf("Previous Reference: %s --> New Reference: %s\n", values$Previous_Reference, values$Reference ))
      # values$reference_plotted <- FALSE
      # ref_plotname <- paste("plot_run_", values$run_index_map[[ values$Previous_Reference ]], sep="")
      # clearPlots( input, output, global, values, session )
    }
    values$Previous_Reference <- input$Reference
    ## Get Experiments minuc Reference
    values$Experiments_to_Align <- values$chromnames[ !(values$chromnames %in% input$Reference) ]
    ## Update Experiment list with first entry removed
    updateSelectizeInput( session, inputId = "Experiment", choices = as.list(values$Experiments_to_Align), selected = as.list(values$Experiments_to_Align) )
    
    ##TODO HERE
    shiny::updateCheckboxGroupInput( session, inputId = "n_runs", choices = n_runs_index, selected = seq(1, length((values$chromnames))), inline = TRUE  )
    }) # End withConsoleRedirect
  }) # End observer
  
  # Peptide Selection Event -------------------------------------------------
  
  ## Observe Peptide Selection
  observeEvent( input$Mod, {
    withConsoleRedirect("console", {
    tryCatch(
      expr = {
        
        ## Check if there is no lib df returned from intial library load
        if ( !is.null( values$lib_df ) ){
          values$start_plotting <- TRUE
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
          values$start_plotting <- TRUE
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
  }) # End withConsoleRedirect
  }) # End observer
  
  
  # Plot Settings Tab Events ------------------------------------------------
  
  ## transition_selection_list
  observeEvent( {input$yIdent
    input$bIdent }, {
      withConsoleRedirect("console", {
      tryCatch(
        expr = {
          
          if ( input$yIdent!="" ){
            values$transition_selection_list$y <- c(text2numericInput(input$yIdent))
          } else {
            values$transition_selection_list$y <- NULL
          }
          
          if ( input$bIdent!="" ){
            values$transition_selection_list$b <- c(text2numericInput(input$bIdent))
          } else {
            values$transition_selection_list$b <- NULL
          }
        }, 
        error = function(e){
          message(sprintf("[Observe Identifying ions selection] There was the following error that occured during Identifying Ions Input Observation: %s\n", e$message))
        }
      ) # End tryCatch
    }) # End withConsoleRedirect
    })# End observer
  
  
  # Plot Control Events -----------------------------------------------------
  
  
  observeEvent(input$n_runs,{
    withConsoleRedirect("console", {
    #Generate set of variable plots
    output$plots <- renderUI({
      
      plot_output_list <- lapply(1:length(input$n_runs), function(i) {
        run_index <- input$n_runs[[i]]
        
        plotname <- paste("plot_run_", run_index, sep="")
        message(sprintf("Creating Plot: %s\n", plotname))
        # plotOutput(plotname,
        #            dblclick = "link_zoom_dblclick",
        #            brush = brushOpts(
        #              id = "link_zoom_brush",
        #              resetOnNew = TRUE
        #            ),
        #            hover = hoverOpts(
        #              id = paste0(plotname, "_hover")
        #            )
        # ) # End of plotlyOutput
        plotlyOutput(plotname)
        
      })
      do.call(tagList, plot_output_list)
      
    })
    
    #Generate set of variable plots for path plots
    output$pathplots <- renderUI({
      
      path_plot_output_list <- lapply(1:length(input$n_runs), function(i) {
        run_index <- input$n_runs[[i]]
        
        path_plotname <- paste("pathplot_run_", run_index, sep="")
        message(sprintf("Creating Path Plot: %s\n", path_plotname))
        plotlyOutput(path_plotname)
        
      })
      do.call(tagList, path_plot_output_list)
      
    })
    }) # End withConsoleRedirect
  }) # End observer
  
  
  # When a double-click happens, check if there's a brush on the plot.
  # If so, zoom to the brush bounds; if not, reset the zoom.
  observeEvent(input$link_zoom_brush, {
    brush <- input$link_zoom_brush
    if (!is.null(brush)) {
      link_zoom_ranges$x <- c(brush$xmin, brush$xmax)
      link_zoom_ranges$y <- c(brush$ymin, brush$ymax)
      
    } else {
      link_zoom_ranges$x <- NULL
      link_zoom_ranges$y <- NULL
    }
  })
  
  observeEvent(input$link_zoom_dblclick, {
    print("Resetting brush")
    session$resetBrush("link_zoom_brush")
    brush <<- NULL
    link_zoom_ranges$x <- NULL
    link_zoom_ranges$y <- NULL
  })
  
  
  # oswTable Output ---------------------------------------------------------
  
  observeEvent(input$n_runs,{
    withConsoleRedirect("console", {
    #Generate set of variable oswtables
    output$oswtables <- renderUI({
      
      datatable_output_list <- lapply(1:length(input$n_runs), function(i) {
        run_index <- input$n_runs[[i]]
        
        tablename <- paste("oswtable_run_", run_index, sep="")
        message(sprintf("Creating osw table: %s\n", tablename))
        
        DT::dataTableOutput(tablename)
        
      })
      do.call(tagList, datatable_output_list)
      
    })
  }) # End withConsoleRedirect
  }) # End observer
  
  # Main Observation Event --------------------------------------------------
  
  observeEvent( 
    {
      input$Mod
      input$Align 
      input$refreshAlign
      values$start_plotting
    }, {
      
      withConsoleRedirect("console", { 
        if ( !(input$Align)  ){
          if ( !is.null(input$n_runs) ) {
            
            withProgress(message = sprintf('Generating Chromatogram Plots for  %s runs...', length(input$n_runs)),
                         detail = 'Extracting Ion Chromatogram Traces...', value = 0, expr = {
                           #Generate all plots.
                           # NOTE: Should we loop over each chrom file input, or loop over each selected n runs input
                           for ( i in seq(1,length(input$n_runs)) ) {
                             local({
                               my_i <- i
                               run_index <- input$n_runs[[i]]
                               plotname <- paste("plot_run_", run_index, sep="")
                               
                               
                               #If alignment is disabled, generate standard chromatogram plot.
                               ## Warning Handles
                               if (  all(unlist(lapply( unique(basename(unlist(global$chromFile))), function(x){!grepl(".*mzML$|.*sqMass$", x)}))) ) {
                                 warning('A Chromgatogram file(s) was not supplied or not found')
                               } else if ( !grepl(".*pqp$", global$libFile) ){
                                 warning("A Library File was not supplied or not found")
                               } else if ( !grepl(".*osw$", global$oswFile) ){
                                 warning("A Merged OSW Results File was not supplied or not found")
                               } else if (is.null(input$Mod)){
                                 warning("There was no peptide(s) found")
                               }
                               
                               
                               tryCatch(
                                 expr = {
                                   chrom_input <- global$chromFile[[my_i]]
                                   osw_input <- global$oswFile[[1]]
                                   peptide <- input$Mod
                                   modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
                                   naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
                                   current_run_id <- rownames( values$runs_filename_mapping )[ values$runs_filename_mapping$runs %in% gsub("\\.\\w+", "", basename(chrom_input)) ]
                                   manual_annotation_coordinates <- NULL
                                   
                                   # cat( sprintf("chrom: %s\nosw: %s\nlib: %s\n", chrom_input, osw_input, global$libFile))
                                   tictoc::tic("Plotting:")
                                   out.plot.h <- curateXICplot( pep=naked_peptide, 
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
                                                                show_manual_annotation = manual_annotation_coordinates,
                                                                show_peak_info_tbl=F,
                                                                show_legend=T,
                                                                mzPntrs=values$mzPntrs[[current_run_id]]
                                   )
                                   
                                   tictoc::toc()
                                 }, 
                                 error = function(e){
                                   message(sprintf("[curateXICplot] There was the following error that occured during curateXICplot function call: %s\n", e$message))
                                 }
                               ) # End tryCatch
                               
                               tryCatch(
                                 expr = {    
                                   
                                   ## Old method using plotly
                                   plotly::ggplotly( p = (out.plot.h), source = plotname, tooltip = c("x", "y", "text"), dynamicTicks = T ) %>%
                                     plotly::layout(title = list( text = unique(paste0( out.plot.h$labels$title,
                                                                                        '<br>',
                                                                                        '<sup>',
                                                                                        gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', out.plot.h$labels$subtitle)),
                                                                                        '</sup>')) ) ) %>%
                                     event_register(event="plotly_relayout") -> p.out
                                   
                                   values$plots[[plotname]] <- p.out
                                   
                                   values$plots_org[[plotname]] <- p.out 
                                   
                                   global$link_zoom_range_current[[plotname]] <<- reactiveValues(`xaxis.range[0]`=values$plots_org[[plotname]]$x$layout$xaxis$range[1], `xaxis.range[1]`=values$plots_org[[plotname]]$x$layout$xaxis$range[2],
                                                                                                 `yaxis.range[0]`=values$plots_org[[plotname]]$x$layout$yaxis$range[1], `yaxis.range[1]`=values$plots_org[[plotname]]$x$layout$yaxis$range[2])
                                   
                                   global$unzoom_double_click[[plotname]] <- NULL
                                 }, 
                                 error = function(e){
                                   message(sprintf("[rendering XIC] There was the following error that occured during XIC rendering: %s\n", e$message))
                                 }
                               ) # End tryCatch
                               
                               
                               
                             }) # End local
                             ## Track progress
                             incProgress(1/length(input$n_runs))
                           } # End For
                           
                         }) # End of Progress Tracker
            
            ## Observe zoom
            withProgress(message = sprintf('Drawing Chromatogram Plots for  %s runs...', length(input$n_runs)),
                         detail = 'Draw Extracted Ion Chromatograms...', value = 0, expr = {
                           # output[['plot_run_']] <<- NULL
                           for ( i in seq(1,length(input$n_runs)) ) {
                             local({
                               
                               ##********************************************************
                               ##  Chromatogram Plot Output
                               ##********************************************************
                               run_index <- input$n_runs[[i]]
                               plotname <- paste("plot_run_", run_index, sep="")
                               
                               output[[plotname]] <- renderPlotly({
                                 output$log <- renderText( paste(log, collapse = '\n') )
                                 
                                 if ( (input$plotly.linkedzooming.x==FALSE & input$plotly.linkedzooming.y==FALSE) || (global$plotly.autorange.x==TRUE & global$plotly.autorange.y==TRUE)  ){
                                   cat("\nNo Link Zoom/reset\n")
                                   # global$unzoom_double_click <- NULL
                                   # js$resetDoubleClick()
                                   values$plots[[plotname]] %>% 
                                     plotly::config( displayModeBar = input$plotly.displayModeBar )
                                   
                                 } else {
                                   cat( sprintf("\nLink Zoom:\nautorange.x=%s\nautorange.y=%s\n%s\n", global$plotly.autorange.x[1], global$plotly.autorange.y[1], listTostring(reactiveValuesToList( global$link_zoom_range_current[[plotname]]))) )
                                   values$plots[[plotname]] %>% 
                                     plotly::config( displayModeBar = input$plotly.displayModeBar ) %>%
                                     plotly::layout(
                                       xaxis = list( autorange=global$plotly.autorange.x[1], range=as.double(c(reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`xaxis.range[0]`[1], reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`xaxis.range[1]`[1])) ), 
                                       yaxis = list( autorange=global$plotly.autorange.y[1], range=as.double(c(reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`yaxis.range[0]`[1], reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`yaxis.range[1]`[1])) )
                                     ) 
                                 }
                                 
                               }) # End renderPlotly
                               
                               ## Get zoom events and unzoom events for linked zooming
                               linkZoomEvent( input, output, values, global, session, plotname )
                               
                               
                               
                               ##********************************************************
                               ##  oswTable Output
                               ##********************************************************
                               ## Get Table tag id            
                               tablename <- paste("oswtable_run_", run_index, sep="")
                               ## Get current filename to filter table
                               ms_file_runname <- values$runs_filename_mapping$filename[ values$runs_filename_mapping$runs %in% gsub("\\.\\w+", "", basename(global$chromFile[[i]])) ]
                               ## Render Table            
                               output[[tablename]] <- DT::renderDataTable(
                                 values$osw_df %>%
                                   dplyr::filter( FullPeptideName==input$Mod & Charge==input$Charge ) %>%
                                   dplyr::mutate( filename = basename(filename) ) %>%
                                   dplyr::filter( filename== basename(ms_file_runname) ) %>%
                                   dplyr::select( "filename", "Charge", "mz", "Intensity", "RT", "assay_rt", "leftWidth", "rightWidth", dplyr::contains("ms2_pep"), dplyr::contains("peak_group_rank"), dplyr::contains("d_score"), dplyr::contains("ms2_m_score"), dplyr::contains("m_score"), dplyr::contains("original_assay") ) 
                               )
                               
                             }) # End Local
                             incProgress(1/length(input$n_runs))
                           } # End for
                         }) # End of Progress Tracker
            
            
          } # End !is.null(input$n_runs)
        } else {
          cat('Alignment Option was selected\n')
          
          withProgress(message = sprintf('Performing alignment for  %s runs...', length(input$Experiment)),
                       detail = 'Dynamic Programming Alignment...', value = 0, expr = {
                         AlignObj_List <- list()
                         values$AlignObj_List <- AlignObj_List
                         for ( i in input$Experiment ) {
                           local({
                             
                             # print("Start Experiment Alignment")
                             # print(paste("Current Exp: ", i, sep=""))
                             
                             # Define Experiment_i
                             current_experiment <- i
                             # Get run Indec
                             run_index <- values$run_index_map[[ current_experiment ]]
                             cat( sprintf("Working on Experiment %s with Run Index: %s\n", current_experiment, run_index) )
                             
                             #Ensuring at least two runs selected, not conducting alignment against same run
                             if ( !(input$Reference == gsub('...........$', '', current_experiment )) ) {
                               
                               
                               tryCatch(
                                 expr = {  
                                   
                                   tictoc::tic("DIAlignR Elapsed Time")
                                   dataPath <- input$WorkingDirectory
                                   analytes <- paste( input$Mod, "_", toString(input$Charge), sep="") 
                                   runs <- c(input$Reference, current_experiment)
                                   cat( sprintf( "analytes: %s\nReference: %s\nExperiment: %s\n", analytes, input$Reference, current_experiment))
                                   
                                   # suppressWarnings(
                                   AlignObjOutput <- DrawAlignR::getAlignObjs(analytes = analytes, runs = runs, dataPath = dataPath, refRun = input$Reference, 
                                                                              analyteInGroupLabel = input$analyteInGroupLabel, identifying = input$identifying, 
                                                                              oswMerged = input$oswMerged, nameCutPattern = input$nameCutPattern, chrom_ext=".chrom.mzML",
                                                                              maxFdrQuery = input$maxFdrQuery, maxFdrLoess = input$maxFdrLoess, analyteFDR = input$analyteFDR, 
                                                                              spanvalue = input$spanvalue,  normalization = input$normalization, simMeasure = input$simMeasure,
                                                                              XICfilter = input$XICfilter, SgolayFiltOrd = input$SgolayFiltOrd, SgolayFiltLen = input$SgolayFiltLen,
                                                                              goFactor = input$goFactor, geFactor = input$geFactor, cosAngleThresh = input$cosAngleThresh, OverlapAlignment = input$OverlapAlignment,
                                                                              dotProdThresh = input$dotProdThresh, gapQuantile = input$gapQuantile, hardConstrain = input$hardConstrain, 
                                                                              samples4gradient = input$samples4gradient,  samplingTime = input$samplingTime,  RSEdistFactor = input$RSEdistFactor, 
                                                                              objType = "medium ", mzPntrs = values$mzPntrs, runType = input$runType)
                                   # )
                                   tictoc::toc()
                                   cat("\n")
                                   
                                   values$AlignObj_List[[current_experiment]] <- AlignObjOutput
                                   cat( sprintf("Added %s to list of aligned objects.\n Total in list now: %s\n", current_experiment, paste(names( values$AlignObj_List), collapse=", ") ) )
                                 }, 
                                 error = function(e){
                                   message(sprintf("[Alignment] There was the following error that occured during Alignment: %s\n", e$message))
                                   values$AlignObj_List[[current_experiment]] <<- e$message
                                 }
                               ) # End tryCatch
                               
                             }
                           }) # End of local
                           ## Track progress
                           incProgress(1/length(input$Experiment))
                         } # End for loop
                         
                       }) # End of Progress Tracker
          
          
          
          ##***********************************************
          ##    Alignment Plotting Events
          ##***********************************************
          ## Clear Plots
          clearPlots( input, output, global, values, session )
          ## Cache Algined Plots
          cacheAlignmentPlots( input, output, global, values, session ) 
          ## Draw Aligned Results
          drawAlignedPlots( input, output, global, values, session ) 
          
          
          
          # }) # End ObserveEvent for showing original annotaiton
          
          
          
          
          
        } # End else plot alignment checkbox
        
      }) ## With Consolde redirect
      
    }) # End Observe Event
  
  
  ## Return gloval varialbles for UI to use
  outputOptions(output, "chromTypes_available", suspendWhenHidden = FALSE)
  
} ## End Server


shinyApp(ui = ui, server = server)

