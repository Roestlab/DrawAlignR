#' Generate SQL query to fetch information from osw files.
#' @author Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}
#'
#' ORCID: 0000-0003-3500-8152
#'
#' License: (c) Author (2019) + MIT
#' Date: 2019-12-14
#' @param maxFdrQuery (numeric) value between 0 and 1. It is used to filter features from osw file which have SCORE_MS2.QVALUE less than itself.
#' @param oswMerged (logical) TRUE for experiment-wide FDR and FALSE for run-specific FDR by pyprophet.
#' @param analytes (vector of strings) transition_group_ids for which features are to be extracted. analyteInGroupLabel must be set according the pattern used here.
#' @param filename (string) as mentioned in RUN table of osw files..
#' @param runType (char) This must be one of the strings "DIA_proteomics", "DIA_Metabolomics", "DIA_Proteomics_ipf".
#' @param analyteInGroupLabel (logical) TRUE for getting analytes as PRECURSOR.GROUP_LABEL from osw file.
#' @param identifying logical value indicating the extraction of identifying transtions. (Default: FALSE)
#'
#' @return SQL query to be searched.
getQuery <- function(maxFdrQuery, oswMerged = TRUE, analytes = NULL,
                     filename = NULL, runType = "DIA_Proteomics", analyteInGroupLabel = FALSE,
		     identifying=FALSE, identifying.transitionPEPfilter=0.6
		    ){
  if(is.null(analytes)){
    selectAnalytes <- ""
  } else{
    selectAnalytes <- paste0(" AND transition_group_id IN ('", paste(analytes, collapse="','"),"')")
  }

  if(oswMerged){
    matchFilename <- paste0(" AND RUN.FILENAME ='", filename,"'")
  } else{
    matchFilename <- ""
  }

  if(analyteInGroupLabel == TRUE){
    transition_group_id <- " PRECURSOR.GROUP_LABEL AS transition_group_id"
  } else {
    transition_group_id <- " PEPTIDE.MODIFIED_SEQUENCE || '_' || PRECURSOR.CHARGE AS transition_group_id"
  }

  if(runType == "DIA_Metabolomics"){
    query <- paste0("SELECT RUN.ID AS id_run,
    COMPOUND.ID AS id_compound,
    COMPOUND.COMPOUND_NAME || '_' || COMPOUND.ADDUCTS AS transition_group_id,
    TRANSITION_PRECURSOR_MAPPING.TRANSITION_ID AS transition_id,
    RUN.ID AS run_id,
    RUN.FILENAME AS filename,
    FEATURE.EXP_RT AS RT,
    FEATURE.DELTA_RT AS delta_rt,
    PRECURSOR.LIBRARY_RT AS assay_RT,
    FEATURE.ID AS id,
    COMPOUND.SUM_FORMULA AS sum_formula,
    COMPOUND.COMPOUND_NAME AS compound_name,
    COMPOUND.ADDUCTS AS Adducts,
    PRECURSOR.CHARGE AS Charge,
    PRECURSOR.PRECURSOR_MZ AS mz,
    FEATURE_MS2.AREA_INTENSITY AS Intensity,
    FEATURE.LEFT_WIDTH AS leftWidth,
    FEATURE.RIGHT_WIDTH AS rightWidth,
    SCORE_MS2.RANK AS peak_group_rank,
    SCORE_MS2.QVALUE AS m_score
    FROM PRECURSOR
    INNER JOIN PRECURSOR_COMPOUND_MAPPING ON PRECURSOR.ID = PRECURSOR_COMPOUND_MAPPING.PRECURSOR_ID
    INNER JOIN COMPOUND ON PRECURSOR_COMPOUND_MAPPING.COMPOUND_ID = COMPOUND.ID
    INNER JOIN FEATURE ON FEATURE.PRECURSOR_ID = PRECURSOR.ID
    INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
    LEFT JOIN TRANSITION_PRECURSOR_MAPPING ON TRANSITION_PRECURSOR_MAPPING.PRECURSOR_ID = PRECURSOR.ID
    LEFT JOIN FEATURE_MS1 ON FEATURE_MS1.FEATURE_ID = FEATURE.ID
    LEFT JOIN FEATURE_MS2 ON FEATURE_MS2.FEATURE_ID = FEATURE.ID
    LEFT JOIN SCORE_MS2 ON SCORE_MS2.FEATURE_ID = FEATURE.ID
    WHERE COMPOUND.DECOY = 0 AND SCORE_MS2.QVALUE <  ", maxFdrQuery, selectAnalytes, matchFilename, "
    ORDER BY transition_group_id,
    peak_group_rank;")
  } else if (runType == "MRM_Proteomics"){
    query <- paste0("SELECT PEPTIDE.MODIFIED_SEQUENCE || '_' || PRECURSOR.CHARGE AS transition_group_id,
  RUN.FILENAME AS filename,
  FEATURE.EXP_RT AS RT,
  FEATURE.DELTA_RT AS delta_rt,
  PRECURSOR.LIBRARY_RT AS assay_RT,
  FEATURE_MS2.AREA_INTENSITY AS Intensity,
  FEATURE.LEFT_WIDTH AS leftWidth,
  FEATURE.RIGHT_WIDTH AS rightWidth,
  TRANSITION_PRECURSOR_MAPPING.TRANSITION_ID AS transition_id
  FROM PRECURSOR
  INNER JOIN PRECURSOR_PEPTIDE_MAPPING ON PRECURSOR.ID = PRECURSOR_PEPTIDE_MAPPING.PRECURSOR_ID AND PRECURSOR.DECOY=0
  INNER JOIN PEPTIDE ON PRECURSOR_PEPTIDE_MAPPING.PEPTIDE_ID = PEPTIDE.ID
  INNER JOIN FEATURE ON FEATURE.PRECURSOR_ID = PRECURSOR.ID
  INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
  INNER JOIN TRANSITION_PRECURSOR_MAPPING ON TRANSITION_PRECURSOR_MAPPING.PRECURSOR_ID = PRECURSOR.ID
  LEFT JOIN FEATURE_MS2 ON FEATURE_MS2.FEATURE_ID = FEATURE.ID
  ORDER BY transition_group_id;")
  } else if ( runType=="DIA_Proteomics_ipf" ) {
    if ( identifying ){
      ## Filter Identifying transitions for PEP level threshold, and keep detecting NULL transitions
      identifying_transition_filter_query <- sprintf("AND (SCORE_TRANSITION.PEP < %s OR (TRANSITION.DETECTING AND SCORE_TRANSITION.PEP IS NULL))", identifying.transitionPEPfilter)
    } else {
      identifying_transition_filter_query <- ''
    }
    query <- sprintf(
      "
      SELECT 
      %s, --- #transition_group_id
      PEPTIDE_ON_PREC.MODIFIED_SEQUENCE AS original_target_assay,
      RUN.FILENAME AS filename,
      FEATURE.ID as feature_id,
      FEATURE.EXP_RT AS RT,
      FEATURE.DELTA_RT AS delta_rt,
      PRECURSOR.LIBRARY_RT AS assay_RT,
      FEATURE_MS2.AREA_INTENSITY AS Intensity,
      FEATURE.LEFT_WIDTH AS leftWidth,
      FEATURE.RIGHT_WIDTH AS rightWidth,
      SCORE_MS2.RANK AS peak_group_rank,
      SCORE_MS2.QVALUE as ms2_m_score,
      SCORE_IPF.QVALUE AS m_score,
      TRANSITION.ID AS transition_id,
      TRANSITION.PRODUCT_MZ AS product_mz,
      ---SCORE_TRANSITION.FEATURE_ID AS score_transition_feature_id,
      ---SCORE_TRANSITION.TRANSITION_ID AS score_transition_id,
      ---SCORE_TRANSITION.PEP AS transition_pep,
      TRANSITION.DETECTING AS detecting_transitions,
      TRANSITION.IDENTIFYING AS identifying_transitions
      FROM SCORE_IPF
      INNER JOIN FEATURE ON FEATURE.ID = SCORE_IPF.FEATURE_ID
      INNER JOIN FEATURE_MS2 ON FEATURE_MS2.FEATURE_ID = FEATURE.ID
      INNER JOIN SCORE_MS2 ON SCORE_MS2.FEATURE_ID = FEATURE.ID
      INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
      INNER JOIN PEPTIDE ON PEPTIDE.ID = SCORE_IPF.PEPTIDE_ID
      INNER JOIN ( SELECT SCORE_IPF.FEATURE_ID, MIN(SCORE_IPF.QVALUE) AS MIN_QVALUE FROM SCORE_IPF GROUP BY SCORE_IPF.FEATURE_ID ) AS SCORE_IPF_MIN ON SCORE_IPF_MIN.FEATURE_ID = SCORE_IPF.FEATURE_ID
	    INNER JOIN TRANSITION_PRECURSOR_MAPPING ON TRANSITION_PRECURSOR_MAPPING.PRECURSOR_ID = FEATURE.PRECURSOR_ID
      INNER JOIN TRANSITION ON TRANSITION.ID = TRANSITION_PRECURSOR_MAPPING.TRANSITION_ID
	    INNER JOIN PRECURSOR ON PRECURSOR.ID = TRANSITION_PRECURSOR_MAPPING.PRECURSOR_ID
	    INNER JOIN PRECURSOR_PEPTIDE_MAPPING ON PRECURSOR_PEPTIDE_MAPPING.PRECURSOR_ID = PRECURSOR.ID
		  INNER JOIN PEPTIDE AS PEPTIDE_ON_PREC ON PEPTIDE_ON_PREC.ID = PRECURSOR_PEPTIDE_MAPPING.PEPTIDE_ID
		  LEFT JOIN SCORE_TRANSITION ON (SCORE_TRANSITION.TRANSITION_ID = TRANSITION.ID AND SCORE_TRANSITION.FEATURE_ID = FEATURE.ID)
      WHERE SCORE_IPF.QVALUE = SCORE_IPF_MIN.MIN_QVALUE
      AND SCORE_IPF.QVALUE < %s
      %s --- #identifying_transition_filter_query
      %s --- #selectAnalytes
      %s --- #matchFilename
      AND (
      TRANSITION.DETECTING=TRUE 
      OR TRANSITION.IDENTIFYING=%s --- #identifying
          ) ORDER BY transition_group_id,
      peak_group_rank;
      ", transition_group_id, maxFdrQuery, identifying_transition_filter_query, selectAnalytes, matchFilename, identifying
    )
   # cat( query ) 
  } else{
    query <- paste0("SELECT", transition_group_id,",
  RUN.FILENAME AS filename,
  FEATURE.ID as feature_id,
  FEATURE.EXP_RT AS RT,
  FEATURE.DELTA_RT AS delta_rt,
  PRECURSOR.LIBRARY_RT AS assay_RT,
  FEATURE_MS2.AREA_INTENSITY AS Intensity,
  FEATURE.LEFT_WIDTH AS leftWidth,
  FEATURE.RIGHT_WIDTH AS rightWidth,
  SCORE_MS2.RANK AS peak_group_rank,
  SCORE_MS2.QVALUE AS m_score,
  TRANSITION_PRECURSOR_MAPPING.TRANSITION_ID AS transition_id,
  TRANSITION.DETECTING AS detecting_transitions,
  TRANSITION.IDENTIFYING AS identifying_transitions
  FROM PRECURSOR
  INNER JOIN PRECURSOR_PEPTIDE_MAPPING ON PRECURSOR.ID = PRECURSOR_PEPTIDE_MAPPING.PRECURSOR_ID AND PRECURSOR.DECOY=0
  INNER JOIN PEPTIDE ON PRECURSOR_PEPTIDE_MAPPING.PEPTIDE_ID = PEPTIDE.ID
  INNER JOIN FEATURE ON FEATURE.PRECURSOR_ID = PRECURSOR.ID
  INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
  INNER JOIN TRANSITION_PRECURSOR_MAPPING ON TRANSITION_PRECURSOR_MAPPING.PRECURSOR_ID = PRECURSOR.ID
  INNER JOIN TRANSITION ON TRANSITION_PRECURSOR_MAPPING.TRANSITION_ID = TRANSITION.ID
  LEFT JOIN FEATURE_MS2 ON FEATURE_MS2.FEATURE_ID = FEATURE.ID
  LEFT JOIN SCORE_MS2 ON SCORE_MS2.FEATURE_ID = FEATURE.ID
  WHERE SCORE_MS2.QVALUE < ", maxFdrQuery, selectAnalytes, matchFilename, 
  " AND (
  TRANSITION.DETECTING=TRUE 
  OR TRANSITION.IDENTIFYING=", identifying,
  ") ORDER BY transition_group_id,
  peak_group_rank;")
  }
  return(query)
}


#' Generate SQL query to fetch limited information from osw files.
#' @author Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}
#'
#' ORCID: 0000-0003-3500-8152
#'
#' License: (c) Author (2019) + MIT
#' Date: 2019-12-14
#' @param maxFdrQuery (numeric) value between 0 and 1. It is used to filter features from osw file which have SCORE_MS2.QVALUE less than itself.
#' @param oswMerged (logical) TRUE for experiment-wide FDR and FALSE for run-specific FDR by pyprophet.
#' @param filename (string) as mentioned in RUN table of osw files..
#' @param runType (char) This must be one of the strings "DIA_proteomics", "DIA_Metabolomics".
#' @param analyteInGroupLabel (logical) TRUE for getting analytes as PRECURSOR.GROUP_LABEL from osw file.
#' @return SQL query to be searched.
#' @seealso \code{\link{getOswAnalytes}}
getAnalytesQuery <- function(maxFdrQuery, oswMerged = TRUE, filename = NULL,
                             runType = "DIA_Proteomics", analyteInGroupLabel = FALSE,
                             identifying=FALSE, identifying.transitionPEPfilter=0.6){
  if(oswMerged){
    matchFilename <- paste0(" AND RUN.FILENAME ='", filename,"'")
  } else{
    matchFilename <- ""
  }

  if(analyteInGroupLabel == TRUE){
    transition_group_id <- " PRECURSOR.GROUP_LABEL AS transition_group_id"
  } else {
    transition_group_id <- " PEPTIDE.MODIFIED_SEQUENCE || '_' || PRECURSOR.CHARGE AS transition_group_id"
  }

  if(runType == "DIA_Metabolomics"){
    query <- paste0("SELECT COMPOUND.ID AS compound_id,
    COMPOUND.COMPOUND_NAME || '_' || COMPOUND.ADDUCTS AS transition_group_id,
    RUN.FILENAME AS filename,
    SCORE_MS2.RANK AS peak_group_rank,
    SCORE_MS2.QVALUE AS m_score
    FROM PRECURSOR
    INNER JOIN PRECURSOR_COMPOUND_MAPPING ON PRECURSOR.ID = PRECURSOR_COMPOUND_MAPPING.PRECURSOR_ID
    INNER JOIN COMPOUND ON PRECURSOR_COMPOUND_MAPPING.COMPOUND_ID = COMPOUND.ID
    INNER JOIN FEATURE ON FEATURE.PRECURSOR_ID = PRECURSOR.ID
    INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
    LEFT JOIN SCORE_MS2 ON SCORE_MS2.FEATURE_ID = FEATURE.ID
    WHERE COMPOUND.DECOY = 0 AND SCORE_MS2.QVALUE <  ", maxFdrQuery, matchFilename, "
    ORDER BY transition_group_id,
    peak_group_rank;")
  } else if (runType == "MRM_Proteomics"){
    query <- paste0("SELECT PEPTIDE.MODIFIED_SEQUENCE || '_' || PRECURSOR.CHARGE AS transition_group_id,
  RUN.FILENAME AS filename,
  FEATURE.EXP_RT AS RT,
  FROM PRECURSOR
  INNER JOIN PRECURSOR_PEPTIDE_MAPPING ON PRECURSOR.ID = PRECURSOR_PEPTIDE_MAPPING.PRECURSOR_ID AND PRECURSOR.DECOY=0
  INNER JOIN PEPTIDE ON PRECURSOR_PEPTIDE_MAPPING.PEPTIDE_ID = PEPTIDE.ID
  INNER JOIN FEATURE ON FEATURE.PRECURSOR_ID = PRECURSOR.ID
  INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
  ORDER BY transition_group_id;")
  } else{
    query <- paste0("SELECT", transition_group_id,",
  RUN.FILENAME AS filename,
  SCORE_MS2.RANK AS peak_group_rank,
  SCORE_MS2.QVALUE AS m_score,
  TRANSITION_PRECURSOR_MAPPING.TRANSITION_ID AS transition_id
  FROM PRECURSOR
  INNER JOIN PRECURSOR_PEPTIDE_MAPPING ON PRECURSOR.ID = PRECURSOR_PEPTIDE_MAPPING.PRECURSOR_ID AND PRECURSOR.DECOY=0
  INNER JOIN PEPTIDE ON PRECURSOR_PEPTIDE_MAPPING.PEPTIDE_ID = PEPTIDE.ID
  INNER JOIN FEATURE ON FEATURE.PRECURSOR_ID = PRECURSOR.ID
  INNER JOIN RUN ON RUN.ID = FEATURE.RUN_ID
  INNER JOIN TRANSITION_PRECURSOR_MAPPING ON TRANSITION_PRECURSOR_MAPPING.PRECURSOR_ID = PRECURSOR.ID
  LEFT JOIN SCORE_MS2 ON SCORE_MS2.FEATURE_ID = FEATURE.ID
  WHERE SCORE_MS2.QVALUE < ", maxFdrQuery, matchFilename, "
  ORDER BY transition_group_id,
  peak_group_rank;")
  }
  return(query)
}
