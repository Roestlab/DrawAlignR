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
                                                                            ## help button
                                                                            bsButton("ChromatogramFile_help", label = "?", size = "default")
                                                         ),
                                                         shiny::tags$style(type='text/css', "#ChromatogramFile { width:100%; margin-top: 0px;}"),
                                                         shiny::tags$style(type='text/css', "#ChromatogramFile_help { width:100%; margin-top: 0px;}"),
                                                         
                                                         # Library File Input
                                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                                            #Select 1 or set of mzML files,
                                                                            # fileInput(inputId = "LibraryFile", "Choose a Library File", multiple = FALSE, accept = c(".pqp"), buttonLabel = icon("folder") ),
                                                                            shinyFiles::shinyFilesButton( id = "LibraryFile", label = "PQP Path", title = "Choose a Library File", multiple = FALSE, icon = shiny::icon("folder") ),
                                                                            ## help button
                                                                            bsButton("LibraryFile_help", label = "?", size = "default")
                                                         ),
                                                         shiny::tags$style(type='text/css', "#LibraryFile { width:100%; margin-top: 0px;}"),
                                                         shiny::tags$style(type='text/css', "#LibraryFile_help { width:100%; margin-top: 0px;}"),
                                                         
                                                         # OSW File Input
                                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                                            #Select 1 or set of mzML files,
                                                                            # fileInput(inputId = "OSWFile", "Choose a OSW File", multiple = FALSE, accept = c(".osw"), buttonLabel = icon("folder") ),
                                                                            shinyFiles::shinyFilesButton( id = "OSWFile", label = "OSW Path", title = "Choose a OSW File", multiple = TRUE, icon = shiny::icon("folder") ),
                                                                            ## help button
                                                                            bsButton("OSWFile_help", label = "?", size = "default")
                                                         ),
                                                         shiny::tags$style(type='text/css', "#OSWFile { width:100%; margin-top: 0px;}"),
                                                         shiny::tags$style(type='text/css', "#OSWFile_help { width:100%; margin-top: 0px;}")
                                                         
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
                                                                                             placeholder = "Set Working Directory",
                                                                                             value="") # Debuggin with default value
                                                         ),
                                                         shiny::tags$style(type='text/css', "#interactiveWorkingDirectory { width:100%; margin-top: 50px;}"),
                                                         shiny::tags$style(type='text/css', "#WorkingDirectory { width:100%; margin-top: 25px;}")
                                       ),
                                       
                                       # Peptide and Charge Selection --------------------------------------------
                                       
                                       br(),
                                       conditionalPanel( condition = "output.chromTypes_available.length > 1 && output.chromTypes_available !== ''",
                                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                                            shinyWidgets::awesomeRadio(
                                                                              inputId = "chromType_Choice", label = NULL, 
                                                                              choices = "", 
                                                                              inline = TRUE, 
                                                                              status = "primary",
                                                                              checkbox = TRUE
                                                                            ),
                                                                            ## help button
                                                                            bsButton("chromType_Choice_help", label = "?", size = "small")
                                                         ),
                                                         shiny::tags$style(type='text/css', "#chromType_Choice { width:100%; margin-top: 0px;}"),
                                                         shiny::tags$style(type='text/css', "#chromType_Choice_help { width:100%; margin-top: 0px;}"),
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
                                       shiny::splitLayout(cellWidths = c("60%", "20%", "20%"),
                                                          #Select 1 or set of mzML files,
                                                          # shiny::checkboxInput(inputId = "Align", "Plot Aligned", value = FALSE, width = NULL),
                                                          # shinyWidgets::switchInput(inputId = 'Align', label = 'Align', value = FALSE, size = "normal"),
                                                          DrawAlignR::customswitchButton(inputId = "Align",
                                                                       label = HTML("<div class='textboxed'><h4><b>Execute<br>Alignment</b></h4></div>"),
                                                                       value = FALSE, col = "RG", type = "OO"),
                                                          ## refresh button
                                                          bsButton("refreshAlign", label = "", icon = icon("refresh"), size = "small"),
                                                          ## help button
                                                          bsButton("plotalign_help", label = "?", size = "small")
                                       ),
                                       shiny::tags$style(type='text/css', "#Align { width:100%; margin-top: 0px; background-color:red; border: 2px solid #dd4b39;}"),
                                       shiny::tags$style(type='text/css', "#refreshAlign { width:100%; margin-top: 0px;}"),
                                       shiny::tags$style(type='text/css', "#plotalign_help { width:100%; margin-top: 0px;}"),
                                       
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
                                       shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                          shinyWidgets::switchInput(inputId = 'OriginalRTAnnotation', label = 'Original Annotation', value = FALSE, onLabel = "TRUE", offLabel = "FALSE"),
                                                          # shiny::checkboxInput(inputId = "OriginalRTAnnotation", "Show Original Peak Annotation", value = FALSE, width = NULL),
                                                          ## help button
                                                          bsButton("OriginalRTAnnotation_help", label = "?", size = "small")
                                       ),
                                       shiny::tags$style(type='text/css', "#OriginalRTAnnotation { width:100%; margin-top: 0px;}"),
                                       shiny::tags$style(type='text/css', "#OriginalRTAnnotation_help { width:100%; margin-top: 0px;}"),
                                       
                                       actionButton("copy", "Copy File")
                                       
) # End of GeneralSettingsTab

# Alignment Settings Tab --------------------------------------------------

AlignmentSettingsTab <- shiny::tabPanel( title = "Alignment Settings",
                                         
                                         ##***********************************************
                                         ##    Alignment Parameters
                                         ##***********************************************
                                         
                                         ## simMeasure
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                         shiny::selectizeInput('runType', 'Experiment Type', selected = 'DIA_Proteomics', choices = c('DIA_Proteomics', 'DIA_Proteomics_ipf', 'MRM_Proteomics', 'DIA_Metabolomics'), 
                                                               options = list(
                                                                 valueField = 'runType',
                                                                 labelField = 'name',
                                                                 searchField = 'name',
                                                                 options = list( ),
                                                                 create = FALSE, 
                                                                 multiple = FALSE,
                                                                 selected = NULL
                                                               )
                                         ),
                                         ## help button
                                         bsButton("runType_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#runType { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#runType_help { width:100%; margin-top: 0px;}"),
                                         shiny::tags$head(shiny::tags$style(HTML(".shiny-split-layout > div {overflow: visible;}"))),
                                         
                                         ## analyteInGroupLabel
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shinyWidgets::switchInput(inputId = 'analyteInGroupLabel', label = 'Analyte Group Label', value = FALSE, onLabel = "TRUE", offLabel = "FALSE"),
                                                            # shiny::checkboxInput('analyteInGroupLabel', 'Use Analyte Group Label', value = FALSE),
                                                            ## help button
                                                            bsButton("analyteInGroupLabel_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#analyteInGroupLabel { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#analyteInGroupLabel_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## identifying
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shinyWidgets::switchInput(inputId = 'identifying', label = 'Use Identifying', value = FALSE, onLabel = "TRUE", offLabel = "FALSE"),
                                                            # shiny::checkboxInput('identifying', 'Include Identiyfying Transitions', value = FALSE),
                                                            ## help button
                                                            bsButton("identifying_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#identifying { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#identifying_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## oswMerged
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shinyWidgets::switchInput(inputId = 'oswMerged', label = 'Merged OSW', value = TRUE, onLabel = "TRUE", offLabel = "FALSE"),       
                                                            # shiny::checkboxInput('oswMerged', 'Merged OSW File', value = TRUE),
                                                            ## help button
                                                            bsButton("oswMerged_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#oswMerged { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#oswMerged_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## nameCutPattern
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::textInput("nameCutPattern", "REGEX string for mzML filename", value = "(.*)(/)(.*)"),
                                                            ## help button
                                                            bsButton("nameCutPattern_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#nameCutPattern { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#nameCutPattern_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## SgolayFiltOrd
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("maxFdrQuery", "OSW Extraction m-score threshold", value=1, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("maxFdrQuery_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#maxFdrQuery { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#maxFdrQuery_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## maxFdrLoess
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("maxFdrLoess", "Feature m-score threshold for LOESS fit", value=1, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("maxFdrLoess_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#maxFdrLoess { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#maxFdrLoess_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## analyteFDR
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("analyteFDR", "Analyte m-score threshold", value=1, min = 0, max = 1, step = NA),
                                                            ## help button
                                                            bsButton("analyteFDR_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#analyteFDR { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#analyteFDR_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## spanvalue
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("spanvalue", "Span Value for LOESS fit", value=1, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("spanvalue_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#spanvalue { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#spanvalue_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## normalization
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
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
                                                            ## help button
                                                            bsButton("normalization_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#normalization { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#normalization_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## simMeasure
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
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
                                                            ## help button
                                                            bsButton("simMeasure_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#simMeasure { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#simMeasure_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## cosAngleThresh
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("cosAngleThresh", "Cosine Angle Threshold", value=0.3, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("cosAngleThresh_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#cosAngleThresh { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#cosAngleThresh_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## dotProdThresh
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("dotProdThresh", "dot-product Threshold", value=0.96, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("dotProdThresh_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#dotProdThresh { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#dotProdThresh_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## XICfilter
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
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
                                                            ## help button
                                                            bsButton("XICfilter_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#XICfilter { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#XICfilter_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## SgolayFiltOrd
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("SgolayFiltOrd", "Sgolay Poly Order", value=4, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("SgolayFiltOrd_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#SgolayFiltOrd { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#SgolayFiltOrd_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## SgolayFiltLen
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("SgolayFiltLen", "Sgolay Frame Length", value=9, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("SgolayFiltLen_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#SgolayFiltLen { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#SgolayFiltLen_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## goFactor
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("goFactor", "Initial Gap Penalty", value=0.125, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("goFactor_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#goFactor { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#goFactor_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## geFactor
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("geFactor", "Subsequent Gap Penalty", value=40, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("geFactor_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#geFactor { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#geFactor_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## OverlapAlignment
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shinyWidgets::switchInput(inputId = 'OverlapAlignment', label = 'Overlap Alignment', value = TRUE, onLabel = "TRUE", offLabel = "FALSE"),
                                                            # shiny::checkboxInput('OverlapAlignment', 'Overlap Alignment', value = TRUE),
                                                            ## help button
                                                            bsButton("OverlapAlignment_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#OverlapAlignment { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#OverlapAlignment_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## gapQuantile
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("gapQuantile", "Gap Quantile", value=0.5, min = 0, max = 1, step = NA),
                                                            ## help button
                                                            bsButton("gapQuantile_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#gapQuantile { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#gapQuantile_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## hardConstrain
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shinyWidgets::switchInput(inputId = 'hardConstrain', label = 'Hard Constrain', value = FALSE, onLabel = "TRUE", offLabel = "FALSE"),
                                                            # shiny::checkboxInput('hardConstrain', 'Hard Constrain', value = FALSE),
                                                            ## help button
                                                            bsButton("hardConstrain_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#hardConstrain { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#hardConstrain_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## samples4gradient
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("samples4gradient", "Mask Penalty", value=100, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("samples4gradient_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#samples4gradient { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#samples4gradient_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## samplingTime
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("samplingTime", "Datapoints Sampling Time", value=3.4, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("samplingTime_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#samplingTime { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#samplingTime_help { width:100%; margin-top: 0px;}"),
                                         
                                         ## RSEdistFactor
                                         shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                            shiny::numericInput("RSEdistFactor", "RSE Distance Factor", value=3.5, min = NA, max = NA, step = NA),
                                                            ## help button
                                                            bsButton("RSEdistFactor_help", label = "?", size = "small")
                                         ),
                                         shiny::tags$style(type='text/css', "#RSEdistFactor { width:100%; margin-top: 0px;}"),
                                         shiny::tags$style(type='text/css', "#RSEdistFactor_help { width:100%; margin-top: 0px;}")
                                         
                                         
                                         
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
                                        shiny::checkboxInput('ShowTransitionScores', 'Show Transition Scores (hover tooltip)', value = TRUE),
                                        
                                        ## ShowAllPkGrps
                                        shiny::checkboxInput('ShowAllPkGrps', 'Show All Peak-Groups', value = FALSE),
                                        
                                        ##### Plotly Options
                                        
                                        ## Display Bar
                                        shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                           shinyWidgets::switchInput(inputId = 'plotly.displayModeBar', label = 'Menu Bar', value = TRUE),
                                                           bsButton("plotly_displayModeBar_help", label = "?", size = "small")
                                        ),
                                        shiny::tags$style(type='text/css', "#plotly.displayModeBar { width:100%; margin-top: 0px;}"),
                                        shiny::tags$style(type='text/css', "#plotly_displayModeBar_help { width:100%; margin-top: 0px;}"), 
                                        
                                        h4('Experimental Settings'),
                                        
                                        'The setting below are under development. They are currently disabled.',
                                        
                                        br(),
                                        
                                        ## Enanle Linked Zooming
                                        shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                           shinyWidgets::switchInput(inputId = 'plotly.linkedzooming.x', label = 'Link Zoom X', value = FALSE, disabled = TRUE),
                                                           bsButton("plotly_linkedzooming_x_help", label = "?", size = "small")
                                        ),
                                        shiny::tags$style(type='text/css', "#plotly.linkedzooming.x { width:100%; margin-top: 0px;}"),
                                        shiny::tags$style(type='text/css', "#plotly_linkedzooming_x_help { width:100%; margin-top: 0px;}"), 
                                        
                                        shiny::splitLayout(cellWidths = c("80%", "20%"),
                                                           shinyWidgets::switchInput(inputId = 'plotly.linkedzooming.y', label = 'Link Zoom Y', value = FALSE, disabled = TRUE),
                                                           bsButton("plotly_linkedzooming_y_help", label = "?", size = "small")
                                        ),
                                        shiny::tags$style(type='text/css', "#plotly.linkedzooming.y { width:100%; margin-top: 0px;}"),
                                        shiny::tags$style(type='text/css', "#plotly_linkedzooming_y_help { width:100%; margin-top: 0px;}"),
                                        
                                        extendShinyjs(text = "shinyjs.resetDoubleClick = function() { Shiny.onInputChange('plotly_doubleclick-plot_run_1', 'null'); }", functions = "resetDoubleClick" )
                                        
) # End of AlignmentSettingsTab
