#' Get mzML filenames from osw RUN table.
#'
#' @author Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}
#'
#' ORCID: 0000-0003-3500-8152
#'
#' License: (c) Author (2019) + MIT
#' Date: 2019-12-14
#' @param dataPath (char) path to mzml and osw directory.
#' @param pattern (char) must be either *.osw or *merged.osw .
#' @return A dataframe with single column.
#' @examples
#' dataPath <- system.file("extdata", package = "DIAlignR")
#' \dontrun{
#' filenamesFromOSW(dataPath, "*.osw")
#' filenamesFromOSW(dataPath, "*merged.osw")
#' }
filenamesFromOSW <- function(dataPath, pattern){
  # Fetch mzML filenames from RUN table.
  query <- "SELECT DISTINCT RUN.FILENAME AS filename FROM RUN"
  if(pattern == "*.osw"){
    message("Looking for .osw files.")
    # Look for .osw files in osw/ directory.
    temp <- list.files(path = file.path(dataPath, "osw"), pattern="*.osw")
    # Throw an error if no .osw files are found.
    if(length(temp) == 0){return(stop("No .osw files are found."))}
    filenames <- vapply(seq_along(temp), function(i){
      con <- DBI::dbConnect(RSQLite::SQLite(), dbname = file.path(dataPath, "osw", temp[i]))
      # Fetch mzML filenames from RUN table.
      tryCatch(expr = DBI::dbGetQuery(con, statement = query), finally = DBI::dbDisconnect(con))
    }, c(list))
    filenames <- as.data.frame(unique(unlist(filenames)))
    colnames(filenames) <-  c("filename")
    # Convert filename column from factor to character
    filenames$filename <- as.character(filenames$filename)
    message(nrow(filenames), " .osw files are found.")
  } else if (pattern == "*merged.osw") {
    message("Looking for merged.osw file.")
    # Look for merged.osw files in osw/ directory.
    if ( file_test("-d", as.character(dataPath)) ){
      temp <- list.files(path = file.path(dataPath, "osw"), pattern="*merged.osw", full.names = T)
    } else if ( file_test("-f", as.character(dataPath)) & tools::file_ext(dataPath)=='osw'  ) {
      temp <- as.character(dataPath)
    } else {
      temp <- NULL
      warning(sprintf("%s did not contain any osw file(s) matching pattern: %s\n", dataPath, pattern))
      return( NULL )
    }
    # Throw an error if no merged.osw files are found.
    if(length(temp) == 0){return(stop("No merged.osw file is found."))}
    con <- DBI::dbConnect(RSQLite::SQLite(), dbname = temp)
    # Fetch mzML filenames from RUN table.
    filenames <- tryCatch(expr = DBI::dbGetQuery(con, statement = query), finally = DBI::dbDisconnect(con))
    message(nrow(filenames), " runs are in ", basename(temp[1]), " file")
  } else {
    message("Only .osw and merged.osw files can be read.")
    filenames <- NULL
  }
  filenames
}

#' Get mzML filenames from the directory.
#'
#' Reads all mzML names avaialble in the directory.
#' @author Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}
#'
#' ORCID: 0000-0003-3500-8152
#'
#' License: (c) Author (2019) + MIT
#' Date: 2019-12-14
#' @param dataPath (char) Path to mzml and osw directory.
#' @param chrom_ext (char) Extension to search for chromatogram files in data directory. (Default: ".chrom.mzML")
#' @return A named vector.
#' @examples
#' dataPath <- system.file("extdata", package = "DIAlignR")
#' \dontrun{
#' filenamesFromMZML(dataPath)
#' }
filenamesFromMZML <- function(dataPath, chrom_ext=".chrom.mzML"){
  if ( any(file_test("-d", as.character(dataPath))) ){
    message(sprintf("[DrawAlignR::filenamesFromMZML] Parsing %s directory for chromatogram files of extension %s.\n", dataPath, chrom_ext))
    temp <- list.files(path = file.path(dataPath), pattern=paste0("*", chrom_ext), recursive = TRUE)
  } else if ( all(file_test("-f", as.character(dataPath))) & all(grepl(chrom_ext, as.character(dataPath)))  ) {
    message(sprintf("[DrawAlignR::filenamesFromMZML] Using Supplied chromatogram files %s of extension %s.\n", paste(as.character(dataPath), collapse = "\n"), chrom_ext))
    temp <- as.character(dataPath)
  } else {
    temp <- NULL
    warning(sprintf("%s did not contain any chromatogram files of extension: %s\n", dataPath, chrom_ext))
    return( NULL )
  }
   
  ## Get basename of file without pre-directory
  # temp <- basename(temp)
  message(sprintf("%s chromatogram files of extension %s are found.", length(temp), chrom_ext))
  mzMLfiles <- vapply(temp, function(x) basename(strsplit(x, split = chrom_ext)[[1]][1]), "")
  mzMLfiles
}

#' Get names of all runs
#'
#' Fetches all osw files, then, keeps only those runs which has corresponding mzML files.
#' mzML file names must match with RUN.FILENAME columns of osw files.
#'
#' @author Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}
#'
#' ORCID: 0000-0003-3500-8152
#'
#' License: (c) Author (2019) + MIT
#' Date: 2019-12-14
#' @param dataPath (char) Path to mzml and osw directory.
#' @param oswFiles (char) Path to OSW file(s) if supplied implicitly.
#' @param chromFiles (char) Path to chromatogram files if supplied implicitly.
#' @param oswMerged (logical) TRUE for experiment-wide FDR and FALSE for run-specific FDR by pyprophet.
#' @param nameCutPattern (string) regex expression to fetch mzML file name from RUN.FILENAME columns of osw files.
#' @param chrom_ext (char) Extension to search for chromatogram files in data directory. (Default: ".chrom.mzML")
#' @return (dataframe) it has two columns:
#' \item{filename}{(string) as mentioned in RUN table of osw files.}
#' \item{runs}{(string) contain respective mzML names without extension.}
#' @examples
#' dataPath <- system.file("extdata", package = "DIAlignR")
#' getRunNames(dataPath = dataPath)
#' @export
getRunNames <- function(dataPath=NULL, oswFiles=NULL, chromFiles=NULL, oswMerged = TRUE, nameCutPattern = "(.*)(/)(.*)", chrom_ext=".chrom.mzML"){
  # Get filenames from RUN table of osw files.
  if(oswMerged == FALSE & !is.null(dataPath) &  is.null(oswFiles)){
    filenames <- filenamesFromOSW(dataPath, pattern = "*.osw")
  } else if (oswMerged == TRUE & !is.null(dataPath) ){
    filenames <- filenamesFromOSW(dataPath, pattern = "*merged.osw")
  } else if ( oswMerged == FALSE & !is.null(oswFiles)  ) {
    filenames <- filenamesFromOSW(oswFiles, pattern = "*.osw") 
  } else if ( oswMerged == TRUE & !is.null(oswFiles) ) {
    filenames <- filenamesFromOSW(oswFiles, pattern = "*merged.osw")
  }
  # Get names of mzml files.
  runs <- vapply(filenames[,"filename"], function(x) gsub(nameCutPattern, replacement = "\\3", x), "")
  fileExtn <- strsplit(runs[[1]], "\\.")[[1]][2]
  fileExtn <- paste0(".", fileExtn)
  filenames$runs <- vapply(runs, function(x) strsplit(x, split = fileExtn)[[1]][1], "")
  
  if ( !is.null(dataPath) & is.null(chromFiles) ){
    mzMLfiles <- filenamesFromMZML(dataPath, chrom_ext=chrom_ext)
  } else if ( is.null(dataPath) & !is.null(chromFiles) ){
    mzMLfiles <- filenamesFromMZML(chromFiles, chrom_ext=chrom_ext)
  } 
  
  # Check if osw files have corresponding mzML file.
  runs <- intersect(filenames$runs, mzMLfiles)
  # print(filenames$runs)
  # print("mzMLfiles")
  # print(mzMLfiles)
  if(length(runs) != length(filenames$runs) & !is.null(mzMLfiles)){
    warning(sprintf( "Following files did not have their counterpart in %s directory:\n%s", unique(dirname(names(mzMLfiles))), setdiff(filenames$runs, mzMLfiles) ))
  }
  if(length(runs) == 0){
    message("Names in RUN table of osw files aren't matching to mzML filenames.")
    message("Check if you have correct file names.")
    return(warning("Name mismatch between osw and mzML files."))
  }
  filenames <- filenames[filenames$runs %in% runs,]
  rownames(filenames) <- paste0("run", 0:(nrow(filenames)-1), "")
  filenames
}
