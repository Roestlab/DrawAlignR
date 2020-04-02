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