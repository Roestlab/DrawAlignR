#' Launches the shiny app for DrawAlignR - User facing function.
#'
#' @return None. Runs the Shiny webapp found in inst/shiny-script/app.R
#'
#' @import shiny
#' @import shinyjs
#' @import shinyFiles 
#' @import shinyWidgets
#' @import shinyBS
#' @import plotly
#' @importFrom  DIAlignR getGlobalAlignment getAlignObj 
#' @importFrom  mstools getXIC getTransitionScores_ unimodTocodename codenameTounimod getChromatogramDataPoints_ getPepLibData_ getOSWData_ log_setup  getmzPntrs getsqMassPntrs
#'
#' @export
runDrawAlignR <- function() {
  ## Find local installed directory of DrawAlignR, to get the shiny app file
  appDir <- system.file("shiny-script", package = "DrawAlignR")
  ## Run the app
  shiny::runApp(appDir = appDir, display.mode = "normal")
  return()
}
