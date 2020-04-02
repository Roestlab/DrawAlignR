linkZoomEvent <- function( input, output, values, global, session, plotname ){
  
  setAutoRange <- function(  global, unzoom_double_click, axis ){
    if ( is.null(unzoom_double_click) ){
      global[[axis]] <- FALSE 
    } else {
      global[[axis]] <- TRUE 
      unzoom_double_click <<- NULL
      rm(unzoom_double_click)
    }
  }
  
  observe({
    if( plotname!="plot_run_" ){
    # print( sprintf("Getting source data for %s", plotname) )
    ## Get event data for relayout events (zooming data)
    link_zoom_ranges <- event_data(event = "plotly_relayout", source = plotname, session=session)
    # message( sprintf("linked_zoom event data:\n%s\n", listTostring(link_zoom_ranges)) )
    ## Get event data for double click events
    unzoom_double_click <- event_data(event = "plotly_doubleclick", source = plotname, session=session)
    # message( sprintf("unzoom_double_click: %s\n", as_character_null(unzoom_double_click)) )
    
    
    if ( ( !is.null(link_zoom_ranges) || ifelse( is.null(link_zoom_ranges), FALSE, tryCatch({names(link_zoom_ranges[1]) %in% c("xaxis.autorange", "yaxis.autorange", "width")},error=function(e){FALSE}) ) ) & 
         (input$plotly.linkedzooming.x | input$plotly.linkedzooming.y) ){
      if ( !is.null(link_zoom_ranges$`xaxis.range[0]`[1]) ){
        
        
        for ( i in seq(1,length(input$n_runs)) ) {
          local({
            run_index <- input$n_runs[[i]]
            plotname_inner <- paste("plot_run_", run_index, sep="")
            
            ## x-axis limits
            if ( input$plotly.linkedzooming.x ){
              ## Set x-axis limits to current zoom events x-limits
              x_limits <- c(link_zoom_ranges$`xaxis.range[0]`[1], link_zoom_ranges$`xaxis.range[1]`[1])
              setAutoRange( global = global, unzoom_double_click = unzoom_double_click, axis = 'plotly.autorange.x' )
            } else {
              ## Set x-axis limits to original plots x-axis
              x_limits <- c(values$plots_org[[plotname_inner]]$x$layout$xaxis$range[1], values$plots_org[[plotname_inner]]$x$layout$xaxis$range[2])
              setAutoRange( global = global, unzoom_double_click = unzoom_double_click, axis = 'plotly.autorange.x' )
            }
            ## y-axis limits
            if ( input$plotly.linkedzooming.y ){
              ## Set y-axis limits to current zoom events y-limits
              y_limits <- c(link_zoom_ranges$`yaxis.range[0]`[1], link_zoom_ranges$`yaxis.range[1]`[1])
              setAutoRange( global = global, unzoom_double_click = unzoom_double_click, axis = 'plotly.autorange.y' )
            } else {
              ## Set y-axis limits to original plots y-axis
              y_limits <- c(values$plots_org[[plotname_inner]]$x$layout$yaxis$range[1], values$plots_org[[plotname_inner]]$x$layout$yaxis$range[2])
              setAutoRange( global = global, unzoom_double_click = unzoom_double_click, axis = 'plotly.autorange.y' )
            }
            
            link_zoom_ranges <- reactiveValues( `xaxis.range[0]`=x_limits[1], `xaxis.range[1]`=x_limits[2], 
                                                `yaxis.range[0]`=y_limits[1], `yaxis.range[1]`=y_limits[2] )
            
            # message( sprintf("Updating %s link zoom with current event data from: %s\n", plotname_inner, plotname) )
            # cat( sprintf("autorange.x=%s\nautorange.y=%s\n%s\n", global$plotly.autorange.x[1], global$plotly.autorange.y[1], listTostring(reactiveValuesToList(link_zoom_ranges) ) ))
            global$link_zoom_range_current[[plotname_inner]] <<- link_zoom_ranges
          })
        }
        # unzoom_double_click <- NULL
      } 
      # cat( sprintf("LINE 559:global$plotly.autorange: %s \n link_zoom_ranges$`xaxis.range[0]`[1]: %s\nlink_zoom_ranges$`xaxis.range[1]`[1]: %s\nlink_zoom_ranges$`yaxis.range[0]`[1]: %s\nlink_zoom_ranges$`yaxis.range[1]`[1]: %s\n",
      # global$plotly.autorange, as.character.null(link_zoom_range_current$`xaxis.range[0]`[1]), as.character.null(link_zoom_range_current$`xaxis.range[1]`[1]), as.character.null(link_zoom_range_current$`yaxis.range[0]`[1]), as.character.null(link_zoom_range_current$`yaxis.range[1]`[1]) ) )
    }
    }
  })
  
}
