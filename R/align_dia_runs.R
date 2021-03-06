#' AlignObj for analytes between a pair of runs
#'
#' This function expects osw and mzml directories at dataPath. It first reads osw files and fetches chromatogram indices for each requested analyte.
#' It then align XICs of each analyte to its reference XICs. AlignObj is returned which contains aligned indices and cumulative score along the alignment path.
#' @author Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}
#'
#' ORCID: 0000-0003-3500-8152
#'
#' License: (c) Author (2019) + MIT
#' Date: 2019-12-14
#' @param analytes (vector of strings) transition_group_ids for which features are to be extracted. analyteInGroupLabel must be set according the pattern used here.
#' @param runs (A vector of string) Names of mzml file without extension.
#' @param dataPath (char) Path to mzml and osw directory.
#' @param alignType Available alignment methods are "global", "local" and "hybrid".
#' @param runType (char) This must be one of the strings "DIA_proteomics", "DIA_Metabolomics".
#' @param refRun (string)
#' @param analyteInGroupLabel (logical) TRUE for getting analytes as PRECURSOR.GROUP_LABEL from osw file.
#' @param identifying logical value indicating the extraction of identifying transtions. (Default: FALSE)
#' @param oswMerged (logical) TRUE for experiment-wide FDR and FALSE for run-specific FDR by pyprophet.
#' @param nameCutPattern (string) regex expression to fetch mzML file name from RUN.FILENAME columns of osw files.
#' @param chrom_ext (string) chromatoram file extension to expect
#' @param maxFdrQuery (numeric) A numeric value between 0 and 1. It is used to filter features from osw file which have SCORE_MS2.QVALUE less than itself.
#' @param maxFdrLoess (numeric) A numeric value between 0 and 1. Features should have m-score lower than this value for participation in LOESS fit.
#' @param analyteFDR (numeric) only analytes that have m-score less than this, will be included in the output.
#' @param spanvalue (numeric) Spanvalue for LOESS fit. For targeted proteomics 0.1 could be used.
#' @param normalization (character) Must be selected from "mean", "l2".
#' @param simMeasure (string) Must be selected from dotProduct, cosineAngle,
#' cosine2Angle, dotProductMasked, euclideanDist, covariance and correlation.
#' @param XICfilter (string) This must be one of the strings "sgolay", "none".
#' @param SgolayFiltOrd (integer) It defines the polynomial order of filer.
#' @param SgolayFiltLen (integer) Must be an odd number. It defines the length of filter.
#' @param goFactor (numeric) Penalty for introducing first gap in alignment. This value is multiplied by base gap-penalty.
#' @param geFactor (numeric) Penalty for introducing subsequent gaps in alignment. This value is multiplied by base gap-penalty.
#' @param cosAngleThresh (numeric) In simType = dotProductMasked mode, angular similarity should be higher than cosAngleThresh otherwise similarity is forced to zero.
#' @param OverlapAlignment (logical) An input for alignment with free end-gaps. False: Global alignment, True: overlap alignment.
#' @param dotProdThresh (numeric) In simType = dotProductMasked mode, values in similarity matrix higher than dotProdThresh quantile are checked for angular similarity.
#' @param gapQuantile (numeric) Must be between 0 and 1. This is used to calculate base gap-penalty from similarity distribution.
#' @param hardConstrain (logical) If FALSE; indices farther from noBeef distance are filled with distance from linear fit line.
#' @param samples4gradient (numeric) This parameter modulates penalization of masked indices.
#' @param samplingTime (numeric) Time difference between two data-points in each chromatogram. For hybrid and local alignment, samples are assumed to be equally time-spaced.
#' @param RSEdistFactor (numeric) This defines how much distance in the unit of rse remains a noBeef zone.
#' @param objType (char) Must be selected from light, medium and heavy.
#' @param mzPntrs A list of mzRpwiz.
#' @return A list of AlignObj. Each AlignObj is an S4 object. Three most-important slots are:
#' \item{indexA_aligned}{(integer) aligned indices of reference run.}
#' \item{indexB_aligned}{(integer) aligned indices of experiment run.}
#' \item{score}{(numeric) cumulative score of alignment.}
#' @seealso \code{\link{plotAlignedAnalytes}, \link{getRunNames}, \link{getOswFiles}, \link{getXICs4AlignObj}, \link{getAlignObj}}
#' @examples
#' dataPath <- system.file("extdata", package = "DIAlignR")
#' runs <- c("hroest_K120809_Strep0%PlasmaBiolRepl2_R04_SW_filt",
#'  "hroest_K120809_Strep10%PlasmaBiolRepl2_R04_SW_filt")
#' AlignObjOutput <- getAlignObjs(analytes = "QFNNTDIVLLEDFQK_3", runs, dataPath = dataPath)
#' plotAlignedAnalytes(AlignObjOutput)
#'
#' @references Gupta S, Ahadi S, Zhou W, Röst H. "DIAlignR Provides Precise Retention Time Alignment Across Distant Runs in DIA and Targeted Proteomics." Mol Cell Proteomics. 2019 Apr;18(4):806-817. doi: https://doi.org/10.1074/mcp.TIR118.001132 Epub 2019 Jan 31.
#'
#' @importFrom mstools getmzPntrs getsqMassPntrs 
#' @export
getAlignObjs <- function(analytes, runs, dataPath = ".", alignType = "hybrid",
                         runType = "DIA_Proteomics", refRun = NULL,
                         analyteInGroupLabel = FALSE, identifying = FALSE, oswMerged = TRUE, nameCutPattern = "(.*)(/)(.*)", chrom_ext=".chrom.mzML",
                         maxFdrQuery = 0.05, maxFdrLoess = 0.01, analyteFDR = 1.00, spanvalue = 0.1,
                         normalization = "mean", simMeasure = "dotProductMasked",
                         XICfilter = "sgolay", SgolayFiltOrd = 4, SgolayFiltLen = 9,
                         goFactor = 0.125, geFactor = 40,
                         cosAngleThresh = 0.3, OverlapAlignment = TRUE,
                         dotProdThresh = 0.96, gapQuantile = 0.5,
                         hardConstrain = FALSE, samples4gradient = 100,
                         samplingTime = 3.4,  RSEdistFactor = 3.5, objType = "light", mzPntrs = NULL){
  
  # message(getFunctionCallArgs( as.list( sys.call() ) ))
  tryCatch(
    expr = {
      if(length(runs) != 2){
        print("For pairwise alignment, two runs are required.")
        return(NULL)
      }
      
      if( (SgolayFiltLen %% 2) != 1){
        print("SgolayFiltLen can only be odd number")
        return(NULL)
      }
      ##### Get filenames from osw files and check if names are consistent between osw and mzML files. ######
      filenames <- getRunNames(dataPath = dataPath, oswMerged = oswMerged, nameCutPattern = nameCutPattern, chrom_ext=chrom_ext)
      filenames <- filenames[filenames$runs %in% runs,]
      missingRun <- setdiff(runs, filenames$runs)
      if(length(missingRun) != 0){
        return(stop(missingRun, " runs are not found."))
      }
      
      message("Following runs will be aligned:")
      message(filenames[, "runs"], sep = "\n")
      
      ## If using mzML files, cache data
      if ( grepl(".*mzML*", chrom_ext) ){
        if(is.null(mzPntrs)){
          ######### Collect pointers for each mzML file. #######
          runs <- filenames$runs
          names(runs) <- rownames(filenames)
          # Collect all the pointers for each mzML file.
          message("Collecting metadata from mzML files.")
          # mzPntrs <- getMZMLpointers(dataPath, runs)
          mzPntrs <- mstools::getmzPntrs(dataPath, runs)
          message("Metadata is collected from mzML files.")
          return_index <- "chromatogramIndex"
        }   
      } else if ( grepl(".*sqMass*", chrom_ext) ){
        if(is.null(mzPntrs)){
          ######### Collect pointers for each mzML file. #######
          runs <- filenames$runs
          names(runs) <- rownames(filenames)
          # Collect all the pointers for each mzML file.
          message("Collecting metadata from sqMass files.")
          # mzPntrs <- getMZMLpointers(dataPath, runs)
          mzPntrs <- mstools::getsqMassPntrs(dataPath, runs, nameCutPattern = nameCutPattern, chrom_ext = chrom_ext)
          message("Metadata is collected from sqMass files.")
          return_index <- "chromatogramIndex"
        }   
      }
      
      
      ######### Get Precursors from the query and respectve chromatogram indices. ######
      oswFiles <- getOswFiles(dataPath, filenames, maxFdrQuery = maxFdrQuery, analyteFDR = analyteFDR,
                              oswMerged = oswMerged, analytes = analytes, runType = runType,
                              analyteInGroupLabel = analyteInGroupLabel, identifying = identifying, mzPntrs = mzPntrs)
      
      # Report analytes that are not found
      # IF using ipf and analytes is supplied, need to use codename standard.. 
      # TODO: Make this more robust
      if ( tolower(runType)=="dia_proteomics_ipf" & !is.null(analytes) ) analytes <- mstools::unimodTocodename(analytes)
      refAnalytes <- getAnalytesName(oswFiles, analyteFDR, commonAnalytes = FALSE)
      analytesFound <- intersect(analytes, refAnalytes)
      analytesNotFound <- setdiff(analytes, analytesFound)
      if(length(analytesNotFound)>0){
        message(paste(analytesNotFound, "not found."))
      }
      analytes <- analytesFound
      
      ####################### Get XICs ##########################################
      runs <- filenames$runs
      names(runs) <- rownames(filenames)
      # Get Chromatogram for each peptide in each run.
      message("Fetching Extracted-ion chromatograms from runs")
      tictoc::tic("getting XICs for all analytes")
      XICs <- getXICs4AlignObj(dataPath, runs, oswFiles, analytes, XICfilter = XICfilter,
                               SgolayFiltOrd = SgolayFiltOrd, SgolayFiltLen = SgolayFiltLen,
                               mzPntrs = mzPntrs)
      tictoc::toc()
      ####################### Perfrom alignment ##########################################
      AlignObjs <- vector("list", length(analytes))
      names(AlignObjs) <- analytes
      loessFits <- list()
      message("Perfroming alignment")
      for(analyteIdx in seq_along(analytes)){
        analyte <- analytes[analyteIdx]
        # Select reference run based on m-score
        if(is.null(refRun)){
          refRunIdx <- getRefRun(oswFiles, analyte)
        } else{
          refRunIdx <- which(filenames$runs == refRun)
        }
        
        # Get XIC_group from reference run
        ref <- names(runs)[refRunIdx]
        exps <- setdiff(names(runs), ref)
        XICs.ref <- XICs[[ref]][[analyte]]
        
        # Align experiment run to reference run
        for(eXp in exps){
          # Get XIC_group from experiment run
          XICs.eXp <- XICs[[eXp]][[analyte]]
          if(!is.null(XICs.eXp)){
            # Get the loess fit for hybrid alignment
            pair <- paste(ref, eXp, sep = "_")
            if(any(pair %in% names(loessFits))){
              Loess.fit <- loessFits[[pair]]
            } else{
              
              # Loess.fit <- DIAlignR::getGlobalAlignment(oswFiles, ref, eXp, maxFdrLoess, spanvalue, fitType = "loess")
              maxFdrLoess_list <- seq(maxFdrLoess, 1, 0.01)
              i <- 1
              Loess.fit <- NULL
              while ( is.null(Loess.fit) & i<=length(maxFdrLoess_list) ) { 
                maxFdrLoess_i <- maxFdrLoess_list[i]
                Loess.fit <- tryCatch(
                  expr = { 
                    message( sprintf("Used maxFdrLoess: %s", maxFdrLoess_i))
                    Loess.fit <- DIAlignR::getGlobalAlignment(oswFiles, ref, eXp, maxFdrLoess_i, spanvalue, fitType = "loess")
                    
                  },
                  error = function(e){
                    message(sprintf("\rThe following error occured using maxFdrLoess %s: %s\n", maxFdrLoess_i, e$message))
                    Loess.fit <- NULL
                  }
                )
                i <- i + 1 
                ##TODO Add a stop condition, otherwise loop will for on forever
              }
              if ( is.null(Loess.fit) ) { 
                message(sprintf("Warn: Was unable to getGlobalAlignment even after permuting different maxFdrLoess thresholds...Skipping...%s\n", pair))
                next
              }
              
              loessFits[[pair]] <- Loess.fit
            }
            adaptiveRT <-  RSEdistFactor*Loess.fit$s # Residual Standard Error
            message(sprintf("adaptive RT: %s\n", adaptiveRT))
            # Fetch alignment object between XICs.ref and XICs.eXp
            tryCatch(
              expr = {
                AlignObj <- DIAlignR::getAlignObj(XICs.ref, XICs.eXp, Loess.fit, adaptiveRT = adaptiveRT, samplingTime,
                                                  normalization, simType = simMeasure, goFactor, geFactor,
                                                  cosAngleThresh, OverlapAlignment,
                                                  dotProdThresh, gapQuantile, hardConstrain, samples4gradient,
                                                  objType)
              }, error = function(e){
                message( sprintf("[DrawAlignR::getAlignObjs(#187)] There was an error that occured while getting aligned object from DIAlignR.\nLast error message was:\n%s\n", e$message) )
              }
            )
            
            tryCatch(
              expr = {
                AlignObjs[[analyte]] <- list()
                # Attach AlignObj for the analyte.
                AlignObjs[[analyte]][[pair]] <- AlignObj
                # Attach intensities of reference XICs.
                AlignObjs[[analyte]][[runs[ref]]] <- XICs.ref
                # Attach intensities of experiment XICs.
                AlignObjs[[analyte]][[runs[eXp]]] <- XICs.eXp
                # Attach peak boundaries to the object.
                AlignObjs[[analyte]][[paste0(pair, "_pk")]] <- oswFiles[[refRunIdx]] %>%
                  dplyr::filter(transition_group_id == analyte & peak_group_rank == 1) %>%
                  dplyr::select(leftWidth, RT, rightWidth) %>%
                  as.vector()
              }, error = function(e){
                message( sprintf("[DrawAlignR::getAlignObjs(#197)] There was an error that occured while storing AlignObjs information.\nLast error message was:\n%s\n", e$message) )
              }
            )
          }
          else {AlignObjs[[analyte]] <- NULL}
        }
      }
      
      ####################### Return AlignedObjs ##########################################
      message("Alignment done. Returning AlignObjs")
      AlignObjs
    }, error = function(e){
      message( sprintf("[DrawAlignR::getAlignObjs] There was an error that occured while executing alignment.\nLast error message was:\n%s\n", e$message) )
    }
  ) # Ent Top Level tryCatch
}