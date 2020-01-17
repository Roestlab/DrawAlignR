GeneralSettingsTab <- shiny::tabPanel( title = "General Settings",
                                
                                # Chromatogram Input
                                shiny::splitLayout(cellWidths = c("80%", "20%"),
                                            #Select 1 or set of mzML files,
                                            # fileInput(inputId = "ChromatogramFile", "Choose a Chromatogram File(s)", multiple = TRUE, accept = c(".mzML", ".sqMass"), buttonLabel = icon("folder")  ),
                                            shinyFiles::shinyFilesButton( id = "ChromatogramFile", label = "Chromatogram(s) Path(s)", title = "Choose a Chromatogram File(s)", multiple = TRUE, icon = shiny::icon("folder") ),
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
                                shiny::tags$style(type='text/css', "#resetOSWFile { width:100%; margin-top: 25px;}"),
                                
                                # Path to directory where mzml folder and osw folder are located. By default is set to the working directory.
                                shiny::splitLayout(cellWidths = c("17%", "83%"),
                                            ## GUI directroy selector
                                            shinyFiles::shinyDirButton( id = "interactiveWorkingDirectory", label = "",  title = "Set Working Directory (Location of mzML and osw folders)", icon = shiny::icon("folder") ),
                                            ## Text box for user to manually input working data path
                                            shiny::textInput(inputId = "WorkingDirectory", "Set Working Directory (Location of mzML and osw folders)",
                                                      value = paste((gsub('............$', '', getwd())), 'extdata', sep = ''))
                                ),
                                shiny::tags$style(type='text/css', "#interactiveWorkingDirectory { width:100%; margin-top: 50px;}"),
                                shiny::tags$style(type='text/css', "#WorkingDirectory { width:100%; margin-top: 25px;}"),
                                
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
                                
                                #Number of plots to display
                                shiny::sliderInput("n", "Number of Plots", value=1, min=1, max=10),
                                
                                #Off by default. Enabled if DIAlignR should be run and aligned chromatograms should be plotted.
                                shiny::checkboxInput(inputId = "Align", "Plot Aligned", value = FALSE, width = NULL),
                                
                                #Name of the reference run if performing multiple pairwise alignments. Not required.
                                # textInput(inputId = "Reference", "Select Reference Run for Alignment", value = "chludwig_K150309_013_SW_0"),
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
                                shiny::selectizeInput('Experiment', 'Experiment to Align', choices = '', options = list(
                                  valueField = 'Run Name',
                                  labelField = 'name',
                                  searchField = 'name',
                                  options = list( ),
                                  create = FALSE, 
                                  multiple = FALSE,
                                  selected = NULL
                                  
                                )),
                                
                                #Plots to show
                                shiny::checkboxInput("ref", "Reference Plot", value = T),
                                shiny::checkboxInput("exp", "Experiment Plot", value = F),
                                shiny::checkboxInput("expAligned", "Experiment Aligned Plot", value = F)

) # End of GeneralSettingsTab

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
