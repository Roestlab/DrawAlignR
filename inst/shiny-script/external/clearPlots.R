clearPlots <- function( input, output, global, values, session ){
  for ( i in seq(1,length(input$n_runs)) ) {
    local({
      
      ##********************************************************
      ##  Chromatogram Plot Output
      ##********************************************************
      run_index <- input$n_runs[[i]]
      plotname <- paste("plot_run_", run_index, sep="")
      message(sprintf("Clearing Aligned Chromatogram plot for %s\n", plotname))
      # values$alignedChromsPlot[[plotname]] <- plotly::ggplotly(ggplot())
      reset( plotname )
      
      ##********************************************************
      ##  pathPlot Output
      ##********************************************************
      path_plotname <- paste("pathplot_run_", run_index, sep="")
      message(sprintf("Clearing Alignment Path plot for %s\n", plotname))
      # values$alignmentPathPlot[[path_plotname]] <- plotly::ggplotly(ggplot())
      reset( path_plotname )
      
    }) # End Local
  } # End for
}