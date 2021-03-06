% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/align_dia_runs.R
\name{getAlignObjs}
\alias{getAlignObjs}
\title{AlignObj for analytes between a pair of runs}
\usage{
getAlignObjs(
  analytes,
  runs,
  dataPath = ".",
  alignType = "hybrid",
  runType = "DIA_Proteomics",
  refRun = NULL,
  analyteInGroupLabel = FALSE,
  identifying = FALSE,
  oswMerged = TRUE,
  nameCutPattern = "(.*)(/)(.*)",
  chrom_ext = ".chrom.mzML",
  maxFdrQuery = 0.05,
  maxFdrLoess = 0.01,
  analyteFDR = 1,
  spanvalue = 0.1,
  normalization = "mean",
  simMeasure = "dotProductMasked",
  XICfilter = "sgolay",
  SgolayFiltOrd = 4,
  SgolayFiltLen = 9,
  goFactor = 0.125,
  geFactor = 40,
  cosAngleThresh = 0.3,
  OverlapAlignment = TRUE,
  dotProdThresh = 0.96,
  gapQuantile = 0.5,
  hardConstrain = FALSE,
  samples4gradient = 100,
  samplingTime = 3.4,
  RSEdistFactor = 3.5,
  objType = "light",
  mzPntrs = NULL
)
}
\arguments{
\item{analytes}{(vector of strings) transition_group_ids for which features are to be extracted. analyteInGroupLabel must be set according the pattern used here.}

\item{runs}{(A vector of string) Names of mzml file without extension.}

\item{dataPath}{(char) Path to mzml and osw directory.}

\item{alignType}{Available alignment methods are "global", "local" and "hybrid".}

\item{runType}{(char) This must be one of the strings "DIA_proteomics", "DIA_Metabolomics".}

\item{refRun}{(string)}

\item{analyteInGroupLabel}{(logical) TRUE for getting analytes as PRECURSOR.GROUP_LABEL from osw file.}

\item{identifying}{logical value indicating the extraction of identifying transtions. (Default: FALSE)}

\item{oswMerged}{(logical) TRUE for experiment-wide FDR and FALSE for run-specific FDR by pyprophet.}

\item{nameCutPattern}{(string) regex expression to fetch mzML file name from RUN.FILENAME columns of osw files.}

\item{chrom_ext}{(string) chromatoram file extension to expect}

\item{maxFdrQuery}{(numeric) A numeric value between 0 and 1. It is used to filter features from osw file which have SCORE_MS2.QVALUE less than itself.}

\item{maxFdrLoess}{(numeric) A numeric value between 0 and 1. Features should have m-score lower than this value for participation in LOESS fit.}

\item{analyteFDR}{(numeric) only analytes that have m-score less than this, will be included in the output.}

\item{spanvalue}{(numeric) Spanvalue for LOESS fit. For targeted proteomics 0.1 could be used.}

\item{normalization}{(character) Must be selected from "mean", "l2".}

\item{simMeasure}{(string) Must be selected from dotProduct, cosineAngle,
cosine2Angle, dotProductMasked, euclideanDist, covariance and correlation.}

\item{XICfilter}{(string) This must be one of the strings "sgolay", "none".}

\item{SgolayFiltOrd}{(integer) It defines the polynomial order of filer.}

\item{SgolayFiltLen}{(integer) Must be an odd number. It defines the length of filter.}

\item{goFactor}{(numeric) Penalty for introducing first gap in alignment. This value is multiplied by base gap-penalty.}

\item{geFactor}{(numeric) Penalty for introducing subsequent gaps in alignment. This value is multiplied by base gap-penalty.}

\item{cosAngleThresh}{(numeric) In simType = dotProductMasked mode, angular similarity should be higher than cosAngleThresh otherwise similarity is forced to zero.}

\item{OverlapAlignment}{(logical) An input for alignment with free end-gaps. False: Global alignment, True: overlap alignment.}

\item{dotProdThresh}{(numeric) In simType = dotProductMasked mode, values in similarity matrix higher than dotProdThresh quantile are checked for angular similarity.}

\item{gapQuantile}{(numeric) Must be between 0 and 1. This is used to calculate base gap-penalty from similarity distribution.}

\item{hardConstrain}{(logical) If FALSE; indices farther from noBeef distance are filled with distance from linear fit line.}

\item{samples4gradient}{(numeric) This parameter modulates penalization of masked indices.}

\item{samplingTime}{(numeric) Time difference between two data-points in each chromatogram. For hybrid and local alignment, samples are assumed to be equally time-spaced.}

\item{RSEdistFactor}{(numeric) This defines how much distance in the unit of rse remains a noBeef zone.}

\item{objType}{(char) Must be selected from light, medium and heavy.}

\item{mzPntrs}{A list of mzRpwiz.}
}
\value{
A list of AlignObj. Each AlignObj is an S4 object. Three most-important slots are:
\item{indexA_aligned}{(integer) aligned indices of reference run.}
\item{indexB_aligned}{(integer) aligned indices of experiment run.}
\item{score}{(numeric) cumulative score of alignment.}
}
\description{
This function expects osw and mzml directories at dataPath. It first reads osw files and fetches chromatogram indices for each requested analyte.
It then align XICs of each analyte to its reference XICs. AlignObj is returned which contains aligned indices and cumulative score along the alignment path.
}
\examples{
dataPath <- system.file("extdata", package = "DIAlignR")
runs <- c("hroest_K120809_Strep0\%PlasmaBiolRepl2_R04_SW_filt",
 "hroest_K120809_Strep10\%PlasmaBiolRepl2_R04_SW_filt")
AlignObjOutput <- getAlignObjs(analytes = "QFNNTDIVLLEDFQK_3", runs, dataPath = dataPath)
plotAlignedAnalytes(AlignObjOutput)

}
\references{
Gupta S, Ahadi S, Zhou W, Röst H. "DIAlignR Provides Precise Retention Time Alignment Across Distant Runs in DIA and Targeted Proteomics." Mol Cell Proteomics. 2019 Apr;18(4):806-817. doi: https://doi.org/10.1074/mcp.TIR118.001132 Epub 2019 Jan 31.
}
\seealso{
\code{\link{plotAlignedAnalytes}, \link{getRunNames}, \link{getOswFiles}, \link{getXICs4AlignObj}, \link{getAlignObj}}
}
\author{
Shubham Gupta, \email{shubh.gupta@mail.utoronto.ca}

ORCID: 0000-0003-3500-8152

License: (c) Author (2019) + MIT
Date: 2019-12-14
}
