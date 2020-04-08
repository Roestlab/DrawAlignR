#' Capture output from console
#' @param containerId A character vector for UI container id to send text to.
#' @param expr An expression/function to wrap around that spits out messages
#' @return A chracter vector with console output reversed
#' @export
withConsoleRedirect <- function(containerId, expr) {
  # Change type="output" to type="message" to catch stderr
  # (messages, warnings, and errors) instead of stdout.
  txt <- capture.output( results <- expr, type = c("message") )
  if (length(txt) > 0) {
    insertUI(paste0("#", containerId), where = "afterBegin",
             ui = paste0(rev(txt), "\n", collapse = "")
    )
  }
  results
}