server_help_description_text <- function( input, output, session ){
# General Settings Tab ----------------------------------------------------
  
  ## popover help text for working directory/ individual file button switch toggle
  addPopover(session = session, 
             id = "WorkingDirectoryInput_help", 
             title = "Use a Working Directory?", 
             content = paste0("<p>You can use a general working directory that contains sub-folders osw, pqp, mzml and sqmass with respective files.</p><p>Or alternatively if you toggle the button off then you can select files individually using separate input buttons.</p>"), trigger = 'click') 
  ## popover help text for chromatogram file input
  addPopover(session = session, 
             id = "ChromatogramFile_help", 
             title = "Select Chromatogram File(s)", 
             content = paste0("<p>You can supply several chromatogram files using the *Chromatogram Path(s)* button. Accepted formats are: mzML and sqMass.</p><p> If you have an alternative format you would like to use, submit a feature request at Roestlab/DrawAlignR.</p>"), trigger = 'click')
  ## popover help text for pqp file input
  addPopover(session = session, id = "LibraryFile_help", 
             title = "Select a Library file", 
             content = paste0("<p>You can supply a Library File using the *PQP Path* button. Accepted formats are: pqp.</p><p> If you have an alternative format you would like to use, submit a feature request at Roestlab/DrawAlignR.</p>"), trigger = 'click') 
  ## popover help text for osw file input
  addPopover(session = session, id = "OSWFile_help", 
             title = "Select a merged OSW results file", 
             content = paste0("<p>You can supply several chromatogram files using the *OSW Path button*. Accepted formats are: osw.</p><p> If you have an alternative format you would like to use, submit a feature request at Roestlab/DrawAlignR.</p>"), trigger = 'click') 
  ## popover help text for chromatogram file input
  addPopover(session = session, id = "chromType_Choice_help", 
             title = "Select Chromatogram File Type", 
             content = paste0("<p>Select which chromatogram file type to use, if multiple are available. Accepted formats are: mzML or sqMass.</p><p> If you have an alternative format you would like to use, submit a feature request at Roestlab/DrawAlignR.</p>"), trigger = 'click') 
  ## popover help text for alignment button
  addPopover(session = session, id = "plotalign_help", 
             title = "Perform Alignment", 
             content = paste0("<p>Turn on the Alignment button to perform chromatogram-run alignment.</p><p>Press the Refresh button to re-run alignment with updated alignment parameters.</p>"), trigger = 'click') 
  ## popover help text for showing original annotation
  addPopover(session = session, id = "OriginalRTAnnotation_help", 
             title = "Show Original RT Assignment", 
             content = paste0("<p>Show the original RT assignment using a light blue shaded region.</p>"), trigger = 'click') 


# Alignment Settings Tab --------------------------------------------------

  ## popover help text for 
  addPopover(session = session, id = "runType_help", 
             title = "Type of Experiment", 
             content = paste0("<p>What type of experiment is your data? DIA proteomics?</p><p>If you have an alternative type of data acquisition scheme and would like support. Please submit a feature request at Roestlab/DrawAlignR, or submit a feature request at Roestlab/DIAlignR</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "analyteInGroupLabel_help", 
             title = "Group by Analyte ID", 
             content = paste0("<p>Extract OSW results using analyte group label (PRECUSOR_CHARGE_ID).</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "identifying_help", 
             title = "Extract Identifying Transitions", 
             content = paste0("<p>Extract identifying transitions as well if they are present.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "oswMerged_help", 
             title = "Use a merged OSW file", 
             content = paste0("<p>Is your results osw file a merged OSW file, or separate individual run OSW files?</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "nameCutPattern_help", 
             title = "OSW REGEX Pattern", 
             content = paste0("<p>Use Regular Expression pattern to search for osw file.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "maxFdrQuery_help", 
             title = "Max Feature FDR Threshold", 
             content = paste0("<p>Maximum FDR threshold to filter out bad peak-groups (features).</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "maxFdrLoess_help", 
             title = "Max Feature FDR Threshold for LOESSfit", 
             content = paste0("<p>Maximum FDR threshold peak-groups (features) to perform LOESS fit on.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "analyteFDR_help", 
             title = "FDR Threshold for Analytes", 
             content = paste0("<p>Maximum FDR threshold for analyte level. Only Analytes passing FDR threshold will be in output.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "spanvalue_help", 
             title = "Spanvalue", 
             content = paste0("<p>Span value used in Loess Fit, the degree of smoothing.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "normalization_help", 
             title = "Normalization", 
             content = paste0("<p>Must be selected from 'mean', 'l2'</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "simMeasure_help", 
             title = "Similarity Matrix Measure", 
             content = paste0("<p>Method for measuring similarity.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "cosAngleThresh_help", 
             title = "Cosine Angle Threshold", 
             content = paste0("<p>In simType = dotProductMasked mode, angular similarity should be higher than cosAngleThresh otherwise similarity is forced to zero.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "dotProdThresh_help", 
             title = "Dot-product Threshold", 
             content = paste0("<p>In simType = dotProductMasked mode, values in similarity matrix higher than dotProdThresh quantile are checked for angular similarity.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "XICfilter_help", 
             title = "XIC Smoothing Method", 
             content = paste0("<p>Method of chromatogram smoothing. Currently only accepts sgolay smoothing</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "SgolayFiltOrd_help", 
             title = "Sgolay Polynomial Order", 
             content = paste0("<p>The polynomial order function for sgolay smoothing.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "SgolayFiltLen_help", 
             title = "Sgolay Band Length", 
             content = paste0("<p>The band length (number of points to smooth) for sgolay smoothing.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "goFactor_help", 
             title = "Initial Gap Penalty", 
             content = paste0("<p>Penalty for introducing first gap in alignment. This value is multiplied by base gap-penalty.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "geFactor_help", 
             title = "Subsequent Gap Penalty", 
             content = paste0("<p>Penalty for introducing subsequent gaps in alignment. This value is multiplied by base gap-penalty.</p>"), trigger = 'click')  
  ## popover help text for 
  addPopover(session = session, id = "OverlapAlignment_help", 
             title = "Overlap Alignment", 
             content = paste0("<p>An input for alignment with free end-gaps. False: Global alignment, True: overlap alignment.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "gapQuantile_help", 
             title = "Gap Quantile", 
             content = paste0("<p>Must be between 0 and 1. This is used to calculate base gap-penalty from similarity distribution.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "hardConstrain_help", 
             title = "Hard Constrain", 
             content = paste0("<p>If FALSE; indices farther from noBeef distance are filled with distance from linear fit line.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "samples4gradient_help", 
             title = "Mask Penalty", 
             content = paste0("<p>This parameter modulates penalization of masked indices.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "samplingTime_help", 
             title = "Chromatogram Datapoints Sampling Time", 
             content = paste0("<p>Time difference between two data-points in each chromatogram. For hybrid and local alignment, samples are assumed to be equally time-spaced.</p>"), trigger = 'click') 
  ## popover help text for 
  addPopover(session = session, id = "RSEdistFactor_help", 
             title = "RSE Distance Factor", 
             content = paste0("<p>This defines how much distance in the unit of rse remains a noBeef zone.</p>"), trigger = 'click') 
  # ## popover help text for 
  # addPopover(session = session, id = "", 
  #            title = "", 
  #            content = paste0("<p></p>"), trigger = 'click') 
  # ## popover help text for 
  # addPopover(session = session, id = "", 
  #            title = "", 
  #            content = paste0("<p></p>"), trigger = 'click') 
  # ## popover help text for 
  # addPopover(session = session, id = "", 
  #            title = "", 
  #            content = paste0("<p></p>"), trigger = 'click') 
  

# Plot Settings Tab -------------------------------------------------------

  ## popover help text for chromatogram plot menu bar
  addPopover(session = session, id = "plotly_displayModeBar_help", 
             title = "Enable Menu Bar Above Plot", 
             content = paste0("<p>Do you want to display the menu bar above plot?</p>"), trigger = 'click')  
  
  ## popover help text for x link zooming
  addPopover(session = session, id = "plotly_linkedzooming_x_help", 
             title = "Enable x-axis linked zooming", 
             content = paste0("<p>Enable linked x-axis zooming across all plots.</p>"), trigger = 'click')  
  
  ## popover help text for y link zooming
  addPopover(session = session, id = "plotly_linkedzooming_y_help", 
             title = "Enable y-axis linked zooming", 
             content = paste0("<p>Enable linked y-axis zooming across all plots.</p>"), trigger = 'click')  
}
