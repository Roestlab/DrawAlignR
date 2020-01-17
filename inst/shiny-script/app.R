#' Builds the shiny webapp for DrawAlignR
#'
#' @return None. Calling this script creates the Shiny webapp
#'
#' @import shiny
#' @import shinyjs
#' @import shinyFiles 
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


### TODO in the future: Link zooming
### https://stackoverflow.com/questions/47933524/how-do-i-synchronize-the-zoom-level-of-multiple-charts-with-plotly-js

source( "../../R/helpers.R" )
source( "../../R/uiTabs.R" )
source( "../../R/getmzPntrs.R")
library(shiny)
library(shinyjs)
library(shinyFiles)
library(plotly)
library(mstools)
library(DIAlignR)

withConsoleRedirect <- function(containerId, expr) {
  # Change type="output" to type="message" to catch stderr
  # (messages, warnings, and errors) instead of stdout.
  txt <- capture.output(results <- expr, type = "output")
  if (length(txt) > 0) {
    insertUI(paste0("#", containerId), where = "beforeEnd",
             ui = paste0(txt, "\n", collapse = "")
    )
  }
  results
}

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
      ),
      
    ) # End of mainPanel
  ) # End of sidebarLayout
) # End of ui

server <- function(input, output, session) {
  
  ## reactive values object to store some re-usable stuff
  values <- reactiveValues()
  values$transition_selection_list <- list()
  global <- reactiveValues(datapath = getwd(), chromFile = getwd(), libFile = getwd(), oswFile = getwd())
  
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
  
  ## Observe input chromatogramfile  
  observeEvent( input$ChromatogramFile, {
    tryCatch(
      expr = {
        ## ChromatogramFile
        shinyFileChoose(input, 'ChromatogramFile', roots = c( `Working Directory` =  "../", home = "~", root = "/" ), defaultRoot = 'Working Directory', defaultPath = '/' )
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
            root_node <- "~"
          } else {
            root_node <- .Platform$file.sep
          }
          ## Get chromFile working directroy of user selected directory
          global$chromFile <- lapply( chromFile()$files, function(x){ paste( root_node, file.path( paste( unlist(x), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) })
          names(global$chromFile) <- lapply(global$chromFile, basename)
          
          ## Store chromatogram file run names
          # values$chromnames <- gsub("\\.chrom\\.mzML$|\\.chrom\\.sqMass$", "", input$ChromatogramFile$name)
          values$chromnames <- gsub("\\.chrom\\.mzML$|\\.chrom\\.sqMass$", "", names(global$chromFile))
          print(values$chromnames)
          ## Update Reference list
          updateSelectizeInput( session, inputId = "Reference", choices = as.list(values$chromnames))
          ## Update Experiment list with reverse order
          updateSelectizeInput( session, inputId = "Experiment", choices = as.list(rev(values$chromnames)))
          
        }
        
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
        
      },
      error = function(e){
        message(sprintf("[Observe Chromatogram Input Button] There was the following error that occured during Chromatogram Input Button observation: %s\n", e$message))
      }
    ) # End tryCatch
  })
  
  
  ## Observe interactive set working directory button
  observeEvent( input$interactiveWorkingDirectory, {
    tryCatch(
      expr = {
        ## Working Directory
        shinyDirChoose(input, 'interactiveWorkingDirectory', roots = c( `Working Directory` =  "../", home = "~", root = "/" ), defaultRoot = 'Working Directory', defaultPath = '/' )
        ### Create a reactive object to store working directory
        dir <- reactive(input$interactiveWorkingDirectory)
        
        values$WorkingDirectory <- renderText({  
          global$datapath
        })  
        
        if ( class(dir())[1]=='list' ){
          ## Get root directory based on used choice, working directory, home or root
          if ( dir()$root=='Working Directory' ){
            root_node <- dirname(getwd())
          } else if ( dir()$root == 'home' ) {
            root_node <- "~"
          } else {
            root_node <- .Platform$file.sep
          }
          ## Get full working directroy of user selected directory
          global$datapath <- paste( root_node, file.path( paste( unlist(dir()$path[-1]), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep )
          ## Update Working Directory Text Box
          updateTextInput( session = session, inputId = 'WorkingDirectory', value = global$datapath  )
          if ( "osw" %in% list.files(global$datapath) ){
          ## Search for OSW folder
          files_in_osw_dir <- list.files( paste(global$datapath ,'osw/',sep='/'), pattern = "*osw$" ,full.names = T )
          if ( length(files_in_osw_dir) > 1 ){
            warning( sprintf("There were %s osw files found, taking first file!!")) # TODO: If user uses non merged osw file?
            files_in_osw_dir <- files_in_osw_dir[1]
          }
          global$oswFile <- files_in_osw_dir
          }
          
          
          
        }
        
      },
      error = function(e){
        message(sprintf("[Observe Iteractive Set Working Directory] There was the following error that occured during Interactive Set Working Directory Button observation: %s\n", e$message))
      }
    ) # End tryCatch
  })
  
  
  
  ## Observe LibraryFile button
  observeEvent( input$LibraryFile, {
    tryCatch(
      expr = {
        ## LibraryFile
        shinyFileChoose(input, 'LibraryFile', roots = c( `Working Directory` =  "../", home = "~", root = "/" ), defaultRoot = 'Working Directory', defaultPath = '/' )
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
            root_node <- "~"
          } else {
            root_node <- .Platform$file.sep
          }
          ## Get libFile working directroy of user selected directory
          global$libFile <- lapply( libFile()$files, function(x){ paste( root_node, file.path( paste( unlist(x), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) })
          names(global$libFile) <- lapply(global$libFile, basename)
          
        }
        
      },
      error = function(e){
        message(sprintf("[Observe Library Input Button] There was the following error that occured during Library Input Button observation: %s\n", e$message))
      }
    ) # End tryCatch
    
  })
  
  
  ## Observe OSWFile button
  observeEvent( input$OSWFile, {
    
    tryCatch(
      expr = {
        
        ## OSWFile
        shinyFileChoose(input, 'OSWFile', roots = c( `Working Directory` =  "../", home = "~", root = "/" ), defaultRoot = 'Working Directory', defaultPath = '/' )
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
            root_node <- "~"
          } else {
            root_node <- .Platform$file.sep
          }
          ## Get oswFile working directroy of user selected directory
          global$oswFile <- lapply( oswFile()$files, function(x){ paste( root_node, file.path( paste( unlist(x), collapse = .Platform$file.sep ) ), sep = .Platform$file.sep ) })
          names(global$oswFile) <- lapply(global$oswFile, basename)
          
          ## Load OSW file
          osw_df <- mstools::getOSWData_( oswfile=global$oswFile[[1]], decoy_filter = TRUE, ms2_score = TRUE, ipf_score =  FALSE)
          values$osw_df <- osw_df
        }
        
      },
      error = function(e){
        message(sprintf("[Observe OSW Input Button] There was the following error that occured during OSW Input Button observation: %s\n", e$message))
      }
    ) # End tryCatch
    
  })
  
  observeEvent( {
    input$LibraryFile
    input$OSWFile
    input$WorkingDirectory
    input$interactiveWorkingDirectory
  }
  , {
    
    tryCatch(
      expr = {
        
        ## If Library File is supplied, file modification list with peptide values
        if( !is.null(input$LibraryFile) & input$LibraryFile!=0 ) {
          message("A Library file was supplied, populating peptide and charge dropdown list based on library information") 
          print(input$LibraryFile[[1]])
          ## Load Librady file into data frame
          # lib_df <- mstools::getPepLibData_( input$LibraryFile$datapath ) 
          lib_df <- mstools::getPepLibData_( global$libFile[[1]] ) 
          ## Store library data.frame into a re-usable  object
          values$lib_df <- lib_df
          ## Get list of unique modified peptides
          uni_peptide_list <- as.list(unique( lib_df$MODIFIED_SEQUENCE )) 
          ## Update slection list with unique peptides
          updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list  )
        } else {
          # If an explicit path to an oswfile is supplied
          if( !is.null(input$OSWFile) & input$OSWFile!=0 ){
            if ( class(oswFile())[1]=='list' ){
              message("An OSW file was supplied, populating peptide and charge dropdown list based on osw information") 
              # osw_df <- mstools::getOSWData_( input$OSWFile$datapath, decoy_filter = TRUE, ms2_score = TRUE, ipf_score = FALSE ) 
              osw_df <- mstools::getOSWData_( global$oswFile[[1]], decoy_filter = TRUE, ms2_score = TRUE, ipf_score = FALSE ) 
              values$osw_df <- osw_df
              ## Get list of unique modified peptides
              uni_peptide_list <- as.list(unique( osw_df$FullPeptideName ) )
              ## Update selection list with unique peptides
              updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list  )
            }
          }  else if ( !is.null(input$WorkingDirectory) ) {
            items_in_wd <- list.files( input$WorkingDirectory )
            if( "osw" %in% items_in_wd ){
              message("An OSW directory was found in supplied working directory, populating peptide and charge dropdown list based on OSW information") 
              files_in_osw_dir <- list.files( paste(input$WorkingDirectory,'osw/',sep='/'), pattern = "*osw$" ,full.names = T )
              if ( length(files_in_osw_dir) > 1 ){
                warning( sprintf("There were %s osw files found, taking first file!!")) # TODO: If user uses non merged osw file?
                files_in_osw_dir <- files_in_osw_dir[1]
              }
              osw_df <- mstools::getOSWData_( files_in_osw_dir, decoy_filter = TRUE, ms2_score = TRUE, ipf_score = FALSE )
              values$osw_df <- osw_df
              uni_peptide_list <- as.list( unique( osw_df$FullPeptideName ) )
              ## Update slection list with unique peptides
              updateSelectizeInput( session, inputId = 'Mod', choices = uni_peptide_list  )
            }
          } else {
            warning("There was no library file, osw file or working directory supplied!.")
          }
          
        }
        
      },
      error = function(e){
        message(sprintf("[Populating Peptide and Charge Drop Down List] There was the following error that occured during Populating Peptide and Charge Drop Down List: %s\n", e$message))
      }
    ) # End tryCatch
    
  } )
  
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
    })
  
  
  #Generate set of variable plots
  
  output$plots <- renderUI({
    plot_output_list <- lapply(1:input$n, function(i) {
      plotname <- paste("plot", i, sep="")
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
        
        for (i in 1:10) {
          local({
            my_i <- i
            plotname <- paste("plot", my_i, sep="")
            
            output[[plotname]] <- renderPlotly({
              
              
              #If alignment is disabled, generate standard chromatogram plot.
              
              if (is.null(input$ChromatogramFile)){
                stop('A Chromgatogram file was not supplied')
              }
              # else if (is.null(input$LibraryFile)){
              #   stop("A Library File was not supplied")
              # }
              else if (is.null(input$Mod)){
                stop("There was no peptide found")
              }
              
              # chrom_input <- input$ChromatogramFile$datapath[[my_i]]
              # lib_input <- input$LibraryFile$datapath
              # osw_input <- input$OSWFile$datapath
              chrom_input <- global$chromFile[[my_i]]
              lib_input <- global$libFile[[1]]
              osw_input <- global$oswFile[[1]]
              peptide <- input$Mod
              modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
              naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
              
              cat(
                sprintf("chrom_input: %s\nlib_input: %s\nosw_input: %s\npeptide: %s\nmodification_labels: %s\nnaked_peptide: %s\n", chrom_input, lib_input, osw_input, peptide, modification_labels, naked_peptide)
              )
              cat(
                sprintf("\nprecursor: %sdetecting: %s\nidentifing: %s\ntransition_list: %s\nn_transitions: %s\nshow_transition_scores: %s\nshow_all_pkgrps: %s\n", 
                        input$Precursor, input$Detecting, input$Identifying_Unique, values$transition_selection_list, input$nIdentifyingTransitions, input$ShowTransitionScores, input$ShowAllPkGrps)
              ) 
              # lib <- getPepLibData_(lib_input$datapath, peptide_id = '')
              # log <- capture.output(
              # g.out <- getXIC(graphic_obj = ggplot(), chromatogram_file = chrom_input,
              # df_lib = lib, mod = peptide, Isoform_Target_Charge = input$Charge)
              
             print(values$transition_selection_list) 
              out.plot.h <- mstools::XICMasterPlotFcn_( naked_peptide, 
                                                        peptide,
                                                        chrom_input,  lib_input, osw_input, 
                                                        plotPrecursor=input$Precursor,
                                                        plotIntersectingDetecting=input$Detecting,
                                                        plotUniqueDetecting=F,
                                                        plotIdentifying=input$Identifying_Unique,
                                                        plotIdentifying.Unique=input$Identifying_Unique,
                                                        plotIdentifying.Shared=F,
                                                        plotIdentifying.Against=F,
                                                        doFacetZoom=F,
                                                        # FacetFcnCall = NULL,
                                                        doPlot=T,
                                                        # RT_padding=90000,
                                                        Charge_State=input$Charge,
                                                        N_sample = 1,
                                                        # idx_draw_these = c(8),
                                                        printPlot=T,
                                                        use_top_trans_pep=F,
                                                        transition_selection_list=values$transition_selection_list,
                                                        show_n_transitions=input$nIdentifyingTransitions,
                                                        show_transition_scores=input$ShowTransitionScores,
                                                        show_all_pkgrprnk=input$ShowAllPkGrps,
                                                        # show_manual_annotation = manual_annotation_coordinates,
                                                        show_peak_info_tbl=F,
                                                        show_legend=T )
              
              
              # )
              # output$log <- renderText( paste(log, collapse = '\n') )
              plotly::ggplotly( (out.plot.h), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                layout(title = list(text = paste0(out.plot.h$labels$title,
                                                  '<br>',
                                                  '<sup>',
                                                  gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', out.plot.h$labels$subtitle)),
                                                  '</sup>')))
              
            }) # End renderPlotly
          }) # End local
        } # End For
        
        
      } else {
        cat('Alignment Option was selected\n')
        #Ensuring at least two runs selected, not conducting alignment against same run
        print( global$chromFile )
        print( global$datapath )
        print( global$libFile )
        print( global$oswFile )
        if (!(input$Reference == gsub('...........$', '', input$Experiment ))){
          
          if ( F ){
            my_i <- 2
            values <- list()
            dataPath <- "/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/"
            analytes <- "ANSS(UniMod:21)PTTNIDHLK(UniMod:259)_2"
            input <- list()
            input$WorkingDirectory <- "/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/"
            input$Mod <- "ANSS(UniMod:21)PTTNIDHLK(UniMod:259)"
            input$Charge <- 2
            # input$ChromatogramFile$datapath <- '/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/mzml/chludwig_K150309_013_SW_0.chrom.mzML' 
            input$ChromatogramFile <- data.frame(name=c("chludwig_K150309_013_SW_0.chrom.mzML", "chludwig_K150309_007b_SW_1_6.chrom.mzML"),
                                                 datapath=c('/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/mzml/chludwig_K150309_013_SW_0.chrom.mzML' ,
                                                            '/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/mzml/chludwig_K150309_007b_SW_1_6.chrom.mzML'),
                                                 stringsAsFactors=F)
            input$Reference <- "chludwig_K150309_013_SW_0"
            input$Experiment <- "chludwig_K150309_007b_SW_1_6"
            input$LibraryFile$datapath <- '/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/pqp/psgs_phospho_optimized_decoys.pqp'
            input$OSWFile$datapath <- '/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/osw/merged.merged.osw'     
            input$analyteInGroupLabel=FALSE; input$identifying=FALSE; 
            input$oswMerged=TRUE; input$nameCutPattern="(.*)(/)(.*)";
            input$maxFdrQuery=0.05; input$maxFdrLoess=0.01; input$analyteFDR=1; 
            input$spanvalue=0.5;  input$normalization="mean"; input$simMeasure="dotProductMasked";
            input$XICfilter="sgolay"; input$SgolayFiltOrd=4; input$SgolayFiltLen=9;
            input$goFactor=0.125; input$geFactor=40; input$cosAngleThresh=0.3; input$OverlapAlignment=TRUE;
            input$dotProdThresh=0.96; input$gapQuantile=0.5; input$hardConstrain=FALSE; 
            input$samples4gradient=100;  input$samplingTime=3.4;  input$RSEdistFactor=3.5
            input$Precursor <- T
            input$Detecting <- T
            input$Identifying_Unique <- T
            values$transition_selection_list <- list(b=c(3), y=c(8, 9, 10))
            input$nIdentifyingTransitions <- 6
            input$ShowTransitionScores <- T
            input$ShowAllPkGrps <- T
            global <- list()
            global$chromFile <- list(`chludwig_K150309_007b_SW_1_6.chrom.mzML`="/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst//extdata/Synthetic_Dilution_Phosphoproteomics/mzml/chludwig_K150309_007b_SW_1_6.chrom.mzML",
                                     `chludwig_K150309_013_SW_0.chrom.mzML`="/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst//extdata/Synthetic_Dilution_Phosphoproteomics/mzml/chludwig_K150309_013_SW_0.chrom.mzML")
            global$oswFile <- "/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Synthetic_Dilution_Phosphoproteomics/osw//merged.merged.osw"
            
            ## Spyogenes
            values <- list()
            dataPAth <- "/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Spyogenes/"
            analytes <- "GEANVELTPELAFK_2"
            input <- list()
            input$WorkingDirectory <- "/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Spyogenes/"
            input$Mod <- "GEANVELTPELAFK"
            input$Charge <- 2
            # input$ChromatogramFile$datapath <- '/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/mzml/chludwig_K150309_013_SW_0.chrom.mzML' 
            input$ChromatogramFile <- data.frame(name=c("hroest_K120808_Strep10%PlasmaBiolRepl1_R03_SW_filt.chrom.mzML", "hroest_K120809_Strep10%PlasmaBiolRepl2_R04_SW_filt.chrom.mzML"),
                                                 datapath=c('/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Spyogenes/mzml/hroest_K120808_Strep10%PlasmaBiolRepl1_R03_SW_filt.chrom.mzML' ,
                                                            '/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Spyogenes/mzml/hroest_K120809_Strep10%PlasmaBiolRepl2_R04_SW_filt.chrom.mzML'),
                                                 stringsAsFactors=F)
            input$Experiment <- "hroest_K120808_Strep10%PlasmaBiolRepl1_R03_SW_filt"
            input$Reference <- "hroest_K120809_Strep10%PlasmaBiolRepl2_R04_SW_filt"
            input$LibraryFile$datapath <- NULL
            input$OSWFile$datapath <- "/media/justincsing/ExtraDrive1/Documents2/Roest_Lab/Github/DrawAlignR/inst/extdata/Spyogenes/osw/merged.osw"
            
            
          }
          tryCatch(
            expr = {  
              tictoc::tic("DIAlignR Elapsed Time")
              dataPath <- input$WorkingDirectory
              analytes <- paste(input$Mod, "_", toString(input$Charge), sep="")
              runs <- c(input$Reference, input$Experiment)
              cat( sprintf( "Reference: %s\nExperiment: %s\n", input$Reference, input$Experiment))
              # cat( sprintf( "Runs: %s\n", runs ) )
              mzPntrs <- values$mzPntrs
              print(input$spanvalue)
              AlignObjOutput <- getAlignObjs(analytes = analytes, runs = runs, dataPath = dataPath, refRun = input$Reference, 
                                                       analyteInGroupLabel = input$analyteInGroupLabel, identifying = input$identifying, 
                                                       oswMerged = input$oswMerged, nameCutPattern = input$nameCutPattern,
                                                       maxFdrQuery = input$maxFdrQuery, maxFdrLoess = input$maxFdrLoess, analyteFDR = input$analyteFDR, 
                                                       spanvalue = input$spanvalue,  normalization = input$normalization, simMeasure = input$simMeasure,
                                                       XICfilter = input$XICfilter, SgolayFiltOrd = input$SgolayFiltOrd, SgolayFiltLen = input$SgolayFiltLen,
                                                       goFactor = input$goFactor, geFactor = input$geFactor, cosAngleThresh = input$cosAngleThresh, OverlapAlignment = input$OverlapAlignment,
                                                       dotProdThresh = input$dotProdThresh, gapQuantile = input$gapQuantile, hardConstrain = input$hardConstrain, 
                                                       samples4gradient = input$samples4gradient,  samplingTime = input$samplingTime,  RSEdistFactor = input$RSEdistFactor, 
                                                       objType = "light", mzPntrs = mzPntrs)
              tictoc::toc()
              
              ## Generate Plot
              k <- plotAlignedAnalytes(AlignObjOutput = AlignObjOutput, DrawAlignR = T, annotatePeak = T, global = global, input = input)
              values$plot_i <- 1
              observeEvent( input$ref, {
                
                if (input$ref) { 
                  if ( values$plot_i != input$n ){
                    updateSliderInput(session, 'n', value=values$plot_i)
                  }
                  output[[ paste0('plot', values$plot_i) ]] <- renderPlotly({
                    x <- 1+2 
                    pt1 <- plotly::ggplotly( (k$prefU), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                      layout(title = list(text = paste0(k$prefU$labels$title,
                                                        '<br>',
                                                        '<sup>',
                                                        gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', k$prefU$labels$subtitle)),
                                                        '</sup>')))
                    
                  }) # End renderPlotly
                  values$plot_i <- values$plot_i + 1
                } else {
                  pt1 <- NULL
                }
              })
              
              observeEvent( input$exp, {
                if (input$exp){
                  if ( values$plot_i != input$n ){
                    updateSliderInput(session, 'n', value=values$plot_i)
                  }
                  output[[ paste0('plot', values$plot_i) ]] <- renderPlotly({
                    
                    pt2 <- plotly::ggplotly( (k$peXpU), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                      layout(title = list(text = paste0(k$peXpU$labels$title,
                                                        '<br>',
                                                        '<sup>',
                                                        gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', k$peXpU$labels$subtitle)),
                                                        '</sup>')))
                    
                  }) # End renderPlotly
                  values$plot_i <- values$plot_i + 1
                } else {
                  pt2 <- NULL
                }
              })
              
              observeEvent( input$expAligned, {
                if (input$expAligned) {
                  if ( values$plot_i != input$n ){
                    updateSliderInput(session, 'n', value=values$plot_i)
                  }
                  output[[ paste0('plot', values$plot_i) ]] <- renderPlotly({
                    
                    pt3 <- plotly::ggplotly( (k$peXpA), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                      layout(title = list(text = paste0(k$peXpA$labels$title,
                                                        '<br>',
                                                        '<sup>',
                                                        gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', k$peXpA$labels$subtitle)),
                                                        '</sup>')))
                    
                  }) # End renderPlotly
                  values$plot_i <- values$plot_i + 1
                } else {
                  pt3 <- NULL
                }
              })
              # # Store plots in a list
              # ptlist <- list(pt1, pt2, pt3)
              # # remove the null plots from ptlist and wtlist
              # to_delete <- !sapply(ptlist,is.null)
              # ptlist <- ptlist[to_delete] 
              # 
              # if (length(ptlist)==0) return(NULL)
              # 
            }, 
            error = function(e){
              message(sprintf("[Alignment] There was the following error that occured during Alignment: %s\n", e$message))
            }
          ) # End tryCatch
          
          
          
        } # End if !input$Reference != input$Experiment
        
        
      } # End else
      
      
    }) # End Observe Event
  
  
  
  
  
} ## End Server


shinyApp(ui = ui, server = server)

