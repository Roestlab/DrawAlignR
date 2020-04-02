drawAlignedPlots <- function( input, output, global, values, session ){
  withProgress(message = sprintf('Drawing Plots for %s runs...', length(input$n_runs)),
               detail = 'Draw chromatogram and alignment path plots...', value = 0, expr = {
## Observe zoom
# output[['plot_run_']] <<- NULL
for ( i in seq(1,length(input$n_runs)) ) {
  local({
    
    ##********************************************************
    ##  Chromatogram Plot Output
    ##********************************************************
    run_index <- input$n_runs[[i]]
    plotname <- paste("plot_run_", run_index, sep="")
    
    output[[plotname]] <- renderPlotly({
      # output$log <- renderText( paste(log, collapse = '\n') )
      
      if ( (input$plotly.linkedzooming.x==FALSE & input$plotly.linkedzooming.y==FALSE) || (global$plotly.autorange.x==TRUE & global$plotly.autorange.y==TRUE)  ){
        cat("\nNo Link Zoom/reset\n")
        # global$unzoom_double_click <- NULL
        # js$resetDoubleClick()
        values$alignedChromsPlot[[plotname]] %>% 
          plotly::config( displayModeBar = input$plotly.displayModeBar )
        
      } else {
        cat( sprintf("\nLink Zoom:\nautorange.x=%s\nautorange.y=%s\n%s\n", global$plotly.autorange.x[1], global$plotly.autorange.y[1], listTostring(reactiveValuesToList( global$link_zoom_range_current[[plotname]]))) )
        values$alignedChromsPlot[[plotname]] %>% 
          plotly::config( displayModeBar = input$plotly.displayModeBar ) %>%
          plotly::layout(
            xaxis = list( autorange=global$plotly.autorange.x[1], range=as.double(c(reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`xaxis.range[0]`[1], reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`xaxis.range[1]`[1])) ), 
            yaxis = list( autorange=global$plotly.autorange.y[1], range=as.double(c(reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`yaxis.range[0]`[1], reactiveValuesToList( global$link_zoom_range_current[[plotname]])$`yaxis.range[1]`[1])) )
          ) 
      }
      
    }) # End renderPlotly
    
    ## Get zoom events and unzoom events for linked zooming
    linkZoomEvent( input, output, values, global, session, plotname )
    
    ##********************************************************
    ##  pathPlot Output
    ##********************************************************
    path_plotname <- paste("pathplot_run_", run_index, sep="")
    
    output[[path_plotname]] <- renderPlotly({
      # output$log <- renderText( paste(log, collapse = '\n') )
      
        values$alignmentPathPlot[[path_plotname]] %>% 
          plotly::config( displayModeBar = input$plotly.displayModeBar )
      
    }) # End renderPlotly
    
    ##********************************************************
    ##  oswTable Output
    ##********************************************************
    ## Get Table tag id            
    tablename <- paste("oswtable_run_", run_index, sep="")
    ## Get current filename to filter table
    ms_file_runname <- values$runs_filename_mapping$filename[ values$runs_filename_mapping$runs %in% gsub("\\.\\w+", "", basename(global$chromFile[[i]])) ]
    ## Render Table            
    output[[tablename]] <- DT::renderDataTable(
      values$osw_df %>%
        dplyr::filter( FullPeptideName==input$Mod & Charge==input$Charge ) %>%
        dplyr::mutate( filename = basename(filename) ) %>%
        dplyr::filter( filename== basename(ms_file_runname) ) %>%
        dplyr::select( "filename", "Charge", "mz", "Intensity", "RT", "assay_rt", "leftWidth", "rightWidth", dplyr::contains("ms2_pep"), dplyr::contains("peak_group_rank"), dplyr::contains("d_score"), dplyr::contains("ms2_m_score"), dplyr::contains("m_score"), dplyr::contains("original_assay") ) 
    )
    
  }) # End Local
  incProgress(1/length(input$n_runs))
} # End for
               }) # End of Progress Tracker
}