#' Launches the shiny app for DrawAlignR - User facing function.
#'
#' @return None. Runs the Shiny webapp found in inst/available-shiny-apps/DrawAlignR/app.R
#'
#' @import shiny
#' @import shinyjs
#' @import shinyFiles 
#' @import plotly
#' @import DIAlignR
#' @import mstools
#'
#' @export
runDrawAlignR <- function() {
  appDir <- system.file("shiny-script",
                      package = "DrawAlignR")

  shiny::runApp(appDir = appDir, display.mode = "normal")
  return()
}
