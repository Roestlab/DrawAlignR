# General Settings Tab ----------------------------------------------------

GeneralSettingsTab <- shiny::tabPanel( title = "General Settings",
                                       
                                       br(),
                                       
                                       ## Switch for switching between using a working directory or applying individual files
                                       shiny::splitLayout(cellWidths = c("80%", "20%"),
                                       shinyWidgets::materialSwitch( inputId = "WorkingDirectoryInput", label = "Working Directory", status = "primary", value = TRUE, inline = FALSE ),
                                       bsButton("WorkingDirectoryInput_help", label = "?", size = "extra-small")
                                       ),
                                       shiny::tags$style(type='text/css', "#WorkingDirectoryInput { width:100%; margin-top: 0px;}"),
                                       shiny::tags$style(type='text/css', "#WorkingDirectoryInput_help { width:100%; margin-top: 0px;}"),  
                                       
                                       # shinyBS::bsTooltip( id = "WorkinDirectoryInput_help", title = "This is a working directory", placement = "right", trigger = "hover" ),
                                       
                                       # Primary File Input ------------------------------------------------------
                                       
                                       ##*************************************
                                       ## Indivdiual File Input
                                       ##*************************************
                                       
                                       conditionalPanel( condition = "input.WorkingDirectoryInput == 0",
                                                         # Chromatogram Input
                                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                                            #Select 1 or set of mzML files,
                                                                            # fileInput(inputId = "ChromatogramFile", "Choose a Chromatogram File(s)", multiple = TRUE, accept = c(".mzML", ".sqMass"), buttonLabel = icon("folder")  ),
                                                                            shinyFiles::shinyFilesButton( id = "ChromatogramFile", label = "Chromatogram Path(s)", title = "Choose a Chromatogram File(s)", multiple = TRUE, icon = shiny::icon("folder") ),
                                                                            ## Reset
                                                                            shiny::actionButton(inputId = "resetChromatogramFile", label = 'X')
                                                         ),
                                                         shiny::tags$style(type='text/css', "#ChromatogramFile { width:100%; margin-top: 25px;}"),
                                                         shiny::tags$style(type='text/css', "#resetChromatogramFile { width:100%; margin-top: 25px;}"),
                                                         
                                                         # Library File Input
                                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                                            #Select 1 or set of mzML files,
                                                                            # fileInput(inputId = "LibraryFile", "Choose a Library File", multiple = FALSE, accept = c(".pqp"), buttonLabel = icon("folder") ),
                                                                            shinyFiles::shinyFilesButton( id = "LibraryFile", label = "PQP Path", title = "Choose a Library File", multiple = FALSE, icon = shiny::icon("folder") ),
                                                                            ## Reset
                                                                            shiny::actionButton(inputId = "resetLibraryFile", label = 'X')
                                                         ),
                                                         shiny::tags$style(type='text/css', "#LibraryFile { width:100%; margin-top: 25px;}"),
                                                         shiny::tags$style(type='text/css', "#resetLibraryFile { width:100%; margin-top: 25px;}"),
                                                         
                                                         # OSW File Input
                                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                                            #Select 1 or set of mzML files,
                                                                            # fileInput(inputId = "OSWFile", "Choose a OSW File", multiple = FALSE, accept = c(".osw"), buttonLabel = icon("folder") ),
                                                                            shinyFiles::shinyFilesButton( id = "OSWFile", label = "OSW Path", title = "Choose a OSW File", multiple = TRUE, icon = shiny::icon("folder") ),
                                                                            ## Reset
                                                                            shiny::actionButton(inputId = "resetOSWFile", label = 'X')
                                                         ),
                                                         shiny::tags$style(type='text/css', "#OSWFile { width:100%; margin-top: 25px;}"),
                                                         shiny::tags$style(type='text/css', "#resetOSWFile { width:100%; margin-top: 25px;}")
                                                         
                                       ),
                                       
                                       ##*************************************
                                       ## Working Directory Input
                                       ##*************************************
                                       
                                       conditionalPanel( condition = "input.WorkingDirectoryInput == 1",
                                                         # Path to directory where mzml folder and osw folder are located. By default is set to the working directory.
                                                         shiny::splitLayout(cellWidths = c("17%", "83%"),
                                                                            ## GUI directroy selector
                                                                            shinyFiles::shinyDirButton( id = "interactiveWorkingDirectory", label = "",  title = "Set Working Directory (Location of mzML and osw folders)", icon = shiny::icon("folder") ),
                                                                            ## Text box for user to manually input working data path
                                                                            shiny::textInput(inputId = "WorkingDirectory", "Set Working Directory",
                                                                                             placeholder = "Set Working Directory")
                                                         ),
                                                         shiny::tags$style(type='text/css', "#interactiveWorkingDirectory { width:100%; margin-top: 50px;}"),
                                                         shiny::tags$style(type='text/css', "#WorkingDirectory { width:100%; margin-top: 25px;}")
                                       ),
                                       
                                       # Peptide and Charge Selection --------------------------------------------
                                       
                                       br(),
                                       conditionalPanel( condition = "output.chromTypes_available.length > 1 && output.chromTypes_available !== ''",
                                       shinyWidgets::awesomeRadio(
                                         inputId = "chromType_Choice", label = NULL, 
                                         choices = "", 
                                         inline = TRUE, 
                                         status = "primary",
                                         checkbox = TRUE
                                       ),
                                       br(),
                                       ),
                                       
                                       
                                       
                                       #Full peptide name including modifications
                                       shiny::selectizeInput('Mod', 'Peptide Name', choices = '', options = list(
                                         valueField = 'Unique Peptide string',
                                         labelField = 'name',
                                         searchField = 'name',
                                         options = list( ),
                                         create = FALSE, 
                                         multiple = FALSE,
                                         selected = NULL
                                         
                                       )),
                                       
                                       #Charge of desired peptide (Specific charge must be in data set)
                                       shiny::selectizeInput('Charge', 'Peptide Charge', choices = '', options = list(
                                         valueField = 'Unique Charge',
                                         labelField = 'name',
                                         searchField = 'name',
                                         options = list( ),
                                         create = FALSE, 
                                         multiple = FALSE,
                                         selected = NULL
                                         
                                       )),
                                       
                                       conditionalPanel( condition = "input.n_runs.length >= 1",
                                       #Number of plots to display
                                       shiny::checkboxGroupInput("n_runs", "Choose Runs to Display:",
                                                                 choices = NULL,
                                                                 selected = NULL,
                                                                 inline = T
                                       )
                                       ),
                                       
                                       #Off by default. Enabled if DIAlignR should be run and aligned chromatograms should be plotted.
                                       shiny::checkboxInput(inputId = "Align", "Plot Aligned", value = FALSE, width = NULL),
                                       
                                       #Name of the reference run if performing multiple pairwise alignments. Not required.
                                       shiny::selectizeInput('Reference', 'Select Reference Run for Alignment', choices = '', options = list(
                                         valueField = 'Run Name',
                                         labelField = 'name',
                                         searchField = 'name',
                                         options = list( ),
                                         create = FALSE, 
                                         multiple = FALSE,
                                         selected = NULL
                                       )),
                                       
                                       #Charge of desired peptide (Specific charge must be in data set)
                                       shiny::selectizeInput('Experiment', 'Experiment(s) to Align', choices = '', multiple = TRUE, options = list(
                                         valueField = 'Run Name',
                                         labelField = 'name',
                                         searchField = 'name',
                                         options = list( ),
                                         create = FALSE, 
                                         multiple = TRUE,
                                         selected = NULL
                                         
                                       )),
                                       
                                       #Plots to show
                                       shiny::checkboxInput(inputId = "OriginalRTAnnotation", "Show Original Peak Annotation", value = FALSE, width = NULL),

                                       
) # End of GeneralSettingsTab

# Alignment Settings Tab --------------------------------------------------

AlignmentSettingsTab <- shiny::tabPanel( title = "Alignment Settings",
                                         
                                         ##***********************************************
                                         ##    Alignment Parameters
                                         ##***********************************************
                                         
                                         ## analyteInGroupLabel
                                         shiny::checkboxInput('analyteInGroupLabel', 'Use Analyte Group Label', value = FALSE),
                                         
                                         ## identifying
                                         shiny::checkboxInput('identifying', 'Include Identiyfying Transitions', value = FALSE),
                                         
                                         ## oswMerged
                                         shiny::checkboxInput('oswMerged', 'Merged OSW File', value = TRUE),
                                         
                                         ## nameCutPattern
                                         shiny::textInput("nameCutPattern", "REGEX string for mzML filename", value = "(.*)(/)(.*)"),
                                         
                                         ## SgolayFiltOrd
                                         shiny::numericInput("maxFdrQuery", "OSW Extraction m-score threshold", value=0.05, min = NA, max = NA, step = NA),
                                         
                                         ## maxFdrLoess
                                         shiny::numericInput("maxFdrLoess", "Feature m-score threshold for LOESS fit", value=0.01, min = NA, max = NA, step = NA),
                                         
                                         ## analyteFDR
                                         shiny::numericInput("analyteFDR", "Analyte m-score threshold", value=1, min = 0, max = 1, step = NA),
                                         
                                         ## spanvalue
                                         shiny::numericInput("spanvalue", "Span Value for LOESS fit", value=0.1, min = NA, max = NA, step = NA),
                                         
                                         ## normalization
                                         shiny::selectizeInput('normalization', 'Normalization', selected = 'mean', choices = c('mean', 'l2'), 
                                                               options = list(
                                                                 valueField = 'normalization',
                                                                 labelField = 'name',
                                                                 searchField = 'name',
                                                                 options = list( ),
                                                                 create = FALSE, 
                                                                 multiple = FALSE,
                                                                 selected = NULL
                                                               )
                                         ),
                                         
                                         ## simMeasure
                                         shiny::selectizeInput('simMeasure', 'Similarity Measure', selected = 'dotProductMasked', choices = c('dotProduct', 'cosineAngle', 'cosine2Angle', 'dotProductMasked', 'euclideanDist', 'covariance', 'correlation'), 
                                                               options = list(
                                                                 valueField = 'simMeasure',
                                                                 labelField = 'name',
                                                                 searchField = 'name',
                                                                 options = list( ),
                                                                 create = FALSE, 
                                                                 multiple = FALSE,
                                                                 selected = NULL
                                                               )
                                         ),
                                         
                                         ## cosAngleThresh
                                         shiny::numericInput("cosAngleThresh", "Cosine Angle Threshold", value=0.3, min = NA, max = NA, step = NA),
                                         
                                         ## dotProdThresh
                                         shiny::numericInput("dotProdThresh", "dot-product Threshold", value=0.96, min = NA, max = NA, step = NA),
                                         
                                         ## XICfilter
                                         shiny::selectizeInput('XICfilter', 'XIC smoothing', selected = 'sgolay', choices = c('sgolay', 'none'), 
                                                               options = list(
                                                                 valueField = 'XICfilter',
                                                                 labelField = 'name',
                                                                 searchField = 'name',
                                                                 options = list( ),
                                                                 create = FALSE, 
                                                                 multiple = FALSE,
                                                                 selected = NULL
                                                               )
                                         ),
                                         
                                         ## SgolayFiltOrd
                                         shiny::numericInput("SgolayFiltOrd", "Sgolay Poly Order", value=4, min = NA, max = NA, step = NA),
                                         
                                         ## SgolayFiltLen
                                         shiny::numericInput("SgolayFiltLen", "Sgolay Frame Length", value=9, min = NA, max = NA, step = NA),
                                         
                                         ## goFactor
                                         shiny::numericInput("goFactor", "Initial Gap Penalty", value=0.125, min = NA, max = NA, step = NA),
                                         
                                         ## geFactor
                                         shiny::numericInput("geFactor", "Subsequent Gap Penalty", value=40, min = NA, max = NA, step = NA),
                                         
                                         ## OverlapAlignment
                                         shiny::checkboxInput('OverlapAlignment', 'Overlap Alignment', value = TRUE),
                                         
                                         ## gapQuantile
                                         shiny::numericInput("gapQuantile", "Gap Quantile", value=0.5, min = 0, max = 1, step = NA),
                                         
                                         ## hardConstrain
                                         shiny::checkboxInput('hardConstrain', 'Hard Constrain', value = FALSE),
                                         
                                         ## samples4gradient
                                         shiny::numericInput("samples4gradient", "Mask Penalty", value=100, min = NA, max = NA, step = NA),
                                         
                                         ## samplingTime
                                         shiny::numericInput("samplingTime", "Chromatogram Datapoints Sampling Time", value=3.4, min = NA, max = NA, step = NA),
                                         
                                         ## RSEdistFactor
                                         shiny::numericInput("RSEdistFactor", "RSE Distance Factor", value=3.5, min = NA, max = NA, step = NA)
                                         
                                         
                                         
) # End of AlignmentSettingsTab


# Plot Settings Tab -------------------------------------------------------

PlottingSettingsTab <- shiny::tabPanel( title = "Plot Settings",
                                        
                                        ## Precursor
                                        shiny::checkboxInput('Precursor', 'Plot Precursor Trace', value = FALSE),
                                        
                                        ## Detecting
                                        shiny::checkboxInput('Detecting', 'Plot Detecting Traces', value = TRUE),
                                        
                                        ## Unique Identifying
                                        shiny::checkboxInput('Identifying_Unique', 'Plot Unique Identifying Traces', value = FALSE),
                                        
                                        ## nIdentifyingTransitions
                                        shiny::numericInput("nIdentifyingTransitions", "Show n Identifying Traces", value=6, min = 0, max = Inf, step = NA),
                                        
                                        # y-Ions
                                        shiny::textInput( inputId = "yIdent", label = "identifying y-ions", placeholder = "Enter values separated by a comma..."),
                                        
                                        # b-Ions
                                        shiny::textInput(inputId = "bIdent", label = "identifying b-ions", placeholder = "Enter values separated by a comma..."),                    
                                        
                                        ## ShowTransitionScores
                                        shiny::checkboxInput('ShowTransitionScores', 'Show Transition Scores (hover tooltip)', value = FALSE),
                                        
                                        ## ShowAllPkGrps
                                        shiny::checkboxInput('ShowAllPkGrps', 'Show All Peak-Groups', value = FALSE),
                                        
) # End of AlignmentSettingsTab
