cacheAlignmentPlots <- function( input, output, global, values, session ){
  MazamaCoreUtils::logger.setLevel("FATAL")
  # observeEvent(input$Reference, {
  withProgress(message = sprintf('Generating and Cacheing Plots for %s runs...', length(input$Experiment)),
               detail = 'Generating aligned chromatogram plots, and alignment path plots...', value = 0, expr = {
                 for ( i in input$Experiment ) {
                   # Need local so that each item gets its own number. Without it, the value
                   # of i in the renderPlotly() will be the same across all instances, because
                   # of when the expression is evaluated
                   local({
                     message("Generating and Saving Plots\n")
                     # Define Experiment_i
                     current_experiment <- i
                     
                     # Get run Indec
                     run_index <- values$run_index_map[[ current_experiment ]]
                     # Get plot tag for chromatogram output
                     plotname <- paste("plot_run_", run_index, sep="")
                     # Get plot tag for alignment path plot
                     path_plotname <- paste("pathplot_run_", run_index, sep="")
                     message( sprintf("Current Exp: %s of %s with run_idx %s and chrom plot tag %s and alignment path plot tag %s\n", current_experiment, length(input$Experiment), run_index, plotname, path_plotname ) )
                     
                     tryCatch(
                       expr = { 
                         message( sprintf( "Class of AlignObj for run %s is %s with length %s\n", current_experiment, class(values$AlignObj_List[[current_experiment]]), length(values$AlignObj_List[[current_experiment]]) ))
                         # print( names(values$AlignObj_List[[current_experiment]]) )
                         ## Generate Plot
                         if ( class(values$AlignObj_List[[current_experiment]])!= "character" & length(values$AlignObj_List[[current_experiment]]) > 0 ){
                           message(sprintf("Generating Aligned Chromatogram from Current Exp: %s of %s with run_idx %s and plotname  %s\n", current_experiment, length(input$Experiment), run_index, plotname ))
                           ## Get Alignment Plots
                           alignedChromsPlot_errorhandle <- tryCatch(
                             expr = {
                             append_error_title <- ""
                             alignedChromsPlot <- plotAlignedAnalytes(AlignObjOutput = values$AlignObj_List[[current_experiment]], DrawAlignR = T, annotatePeak = T, annotateOrgPeak = input$OriginalRTAnnotation, global = global, input = input)
                             alignedChromsPlot_errorhandle <- list(alignedChromsPlot=alignedChromsPlot, append_error_title=append_error_title) 
                           }, error = function(e){
                             alignedChromsPlot <- list()
                             warning( sprintf("Alignment object was returned, but failed alignment plot generation.\nFalling back onto regular plotting\nLast error was %s:", e$message) )
                             append_error_title <- "Alignment Failed - "
                             chrom_input <- global$chromFile[[ which(grepl(paste0(".*", current_experiment, ".*"), names(global$chromFile))) ]]
                             osw_input <- global$oswFile[[1]]
                             peptide <- input$Mod
                             modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
                             naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
                             manual_annotation_coordinates <- NULL
                             
                             # cat( sprintf("chrom: %s\nosw: %s\nlib: %s\n", chrom_input, osw_input, global$libFile))
                             alignedChromsPlot$peXpA <- curateXICplot( pep=naked_peptide, 
                                                                       uni_mod=peptide,
                                                                       in_sqMass=chrom_input,  df_lib=values$lib_df, in_osw=osw_input, df_osw=values$osw_df,
                                                                       plotPrecursor=input$Precursor,
                                                                       plotDetecting=input$Detecting,
                                                                       plotIdentifying=input$Identifying_Unique,
                                                                       plotIdentifying.Unique=input$Identifying_Unique,
                                                                       plotIdentifying.Shared=F,
                                                                       plotIdentifying.Against=F,
                                                                       doFacetZoom=F,
                                                                       doPlot=T,
                                                                       Charge_State=input$Charge,
                                                                       printPlot=F,
                                                                       store_plots_subdir=NULL,
                                                                       use_top_trans_pep=F,
                                                                       transition_selection_list=values$transition_selection_list,
                                                                       show_n_transitions=input$nIdentifyingTransitions,
                                                                       show_transition_scores=input$ShowTransitionScores,
                                                                       show_all_pkgrprnk=input$ShowAllPkGrps,
                                                                       show_manual_annotation = manual_annotation_coordinates,
                                                                       show_peak_info_tbl=F,
                                                                       show_legend=T,
                                                                       mzPntrs=values$mzPntrs[[ current_experiment ]]
                             )
                             
                             chrom_input <- global$chromFile[[ which(grepl(paste0(".*", values$Reference, ".*"), names(global$chromFile))) ]]
                             osw_input <- global$oswFile[[1]]
                             peptide <- input$Mod
                             modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
                             naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
                             manual_annotation_coordinates <- NULL
                             
                             # cat( sprintf("chrom: %s\nosw: %s\nlib: %s\n", chrom_input, osw_input, global$libFile))
                             alignedChromsPlot$prefU <- curateXICplot( pep=naked_peptide, 
                                                                       uni_mod=peptide,
                                                                       in_sqMass=chrom_input,  df_lib=values$lib_df, in_osw=osw_input, df_osw=values$osw_df,
                                                                       plotPrecursor=input$Precursor,
                                                                       plotDetecting=input$Detecting,
                                                                       plotIdentifying=input$Identifying_Unique,
                                                                       plotIdentifying.Unique=input$Identifying_Unique,
                                                                       plotIdentifying.Shared=F,
                                                                       plotIdentifying.Against=F,
                                                                       doFacetZoom=F,
                                                                       doPlot=T,
                                                                       Charge_State=input$Charge,
                                                                       printPlot=F,
                                                                       store_plots_subdir=NULL,
                                                                       use_top_trans_pep=F,
                                                                       transition_selection_list=values$transition_selection_list,
                                                                       show_n_transitions=input$nIdentifyingTransitions,
                                                                       show_transition_scores=input$ShowTransitionScores,
                                                                       show_all_pkgrprnk=input$ShowAllPkGrps,
                                                                       show_manual_annotation = manual_annotation_coordinates,
                                                                       show_peak_info_tbl=F,
                                                                       show_legend=T,
                                                                       mzPntrs=values$mzPntrs[[ current_experiment ]]
                             )
                             return( list(alignedChromsPlot=alignedChromsPlot, append_error_title=append_error_title) )
                           })
                           # print("HERE")
                           # print( names(alignedChromsPlot) )
                           
                           ## Store Aligned Experiment Plot
                           pt1 <- plotly::ggplotly( (alignedChromsPlot_errorhandle$alignedChromsPlot$peXpA), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                             layout(title = list(text = paste0( paste0(alignedChromsPlot_errorhandle$append_error_title, alignedChromsPlot_errorhandle$alignedChromsPlot$peXpA$labels$title),
                                                                '<br>',
                                                                '<sup>',
                                                                gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', alignedChromsPlot_errorhandle$alignedChromsPlot$peXpA$labels$subtitle)),
                                                                '</sup>'))) %>%
                             event_register(event="plotly_relayout")
                           ## Store plot for experiment run
                           values$alignedChromsPlot[[plotname]] <- pt1
                           
                           ## Check and add Reference plot if not added yet
                           # message(sprintf("HERE REFERENCE PLOTTED?: %s\n", values$reference_plotted))
                           # if ( values$reference_plotted == FALSE ){
                           ref_plotname <- paste("plot_run_", values$run_index_map[[ values$Reference ]], sep="")
                           message(sprintf("Storing Reference plot taken from Current Exp: %s of %s with run_idx %s and plotname  %s\n", current_experiment, length(input$Experiment), run_index, ref_plotname ))
                           pt2 <- plotly::ggplotly( (alignedChromsPlot_errorhandle$alignedChromsPlot$prefU), tooltip = c("x", "y", "text"), dynamicTicks = T) %>%
                             layout(title = list(text = paste0( alignedChromsPlot_errorhandle$alignedChromsPlot$prefU$labels$title,
                                                                '<br>',
                                                                '<sup>',
                                                                gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', alignedChromsPlot_errorhandle$alignedChromsPlot$prefU$labels$subtitle)),
                                                                '</sup>'))) %>%
                             event_register(event="plotly_relayout")
                           ## Store plot for reference run
                           values$alignedChromsPlot[[ref_plotname]] <- pt2
                           # values$reference_plotted <- TRUE
                           # }
                           
                           ## Get Alignment Path Plot
                           alignmentPathPlot <- plotAlignmentPath( AlignObjOutput = values$AlignObj_List[[current_experiment]], title = sprintf("%s Aligned to %s", current_experiment, values$Reference) )
                           suppressWarnings(
                             pt3 <- plotly::ggplotly( (alignmentPathPlot), tooltip = c("all"), dynamicTicks = T) %>%
                               layout(title = list(text = paste0( paste0(alignmentPathPlot$labels$title),
                                                                  '<br>',
                                                                  '<sup>',
                                                                  gsub('\\\n', ' | ', alignmentPathPlot$labels$subtitle),
                                                                  '</sup>')))
                           )
                           ## Store plot for alignment path plot
                           values$alignmentPathPlot[[path_plotname]] <- pt3
                           
                           ref_path_plotname <- paste("pathplot_run_", values$run_index_map[[ values$Reference ]], sep="")
                           plot_text <- sprintf("This is the reference run.\nThere is no self alignment performed.\n ")
                           
                           values$alignmentPathPlot[[ref_path_plotname]] <- plotly::ggplotly( ggplot() +
                                                                                            annotate( "text", x = 4, y = 25, size = 8, label = plot_text ) +
                                                                                            ggtitle( sprintf("Reference Run: %s", values$Reference) ) +
                                                                                            theme_bw() + 
                                                                                            theme( panel.grid.major = element_blank(),
                                                                                                   panel.grid.minor = element_blank(),
                                                                                                   axis.title = element_blank(),
                                                                                                   axis.text = element_blank()
                                                                                            ) )
                           
                           if ( values$Previous_Reference!='' & values$Reference!=values$Previous_Reference ){
                             message( sprintf("Clearing Previous Reference Alignment Path Plot: %s\n", values$Previous_Reference) )
                             ref_path_plotname <- paste("plot_run_", values$run_index_map[[ values$Previous_Reference ]], sep="")
                             values$alignmentPathPlot[[ref_path_plotname]] <- plotly::ggplotly(ggplot())
                           }
                         } else {
                           
                           warning("Alignment Object was empty. Turning back onto default plotting\n")
                           
                           chrom_input <- global$chromFile[[ which(grepl(paste0(".*", current_experiment, ".*"), names(global$chromFile))) ]]
                           osw_input <- global$oswFile[[1]]
                           peptide <- input$Mod
                           modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
                           naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
                           manual_annotation_coordinates <- NULL
                           
                           # cat( sprintf("chrom: %s\nosw: %s\nlib: %s\n", chrom_input, osw_input, global$libFile))
                           out.plot.h <- curateXICplot( pep=naked_peptide, 
                                                        uni_mod=peptide,
                                                        in_sqMass=chrom_input,  df_lib=values$lib_df, in_osw=osw_input, df_osw=values$osw_df,
                                                        plotPrecursor=input$Precursor,
                                                        plotDetecting=input$Detecting,
                                                        plotIdentifying=input$Identifying_Unique,
                                                        plotIdentifying.Unique=input$Identifying_Unique,
                                                        plotIdentifying.Shared=F,
                                                        plotIdentifying.Against=F,
                                                        doFacetZoom=F,
                                                        doPlot=T,
                                                        Charge_State=input$Charge,
                                                        printPlot=F,
                                                        store_plots_subdir=NULL,
                                                        use_top_trans_pep=F,
                                                        transition_selection_list=values$transition_selection_list,
                                                        show_n_transitions=input$nIdentifyingTransitions,
                                                        show_transition_scores=input$ShowTransitionScores,
                                                        show_all_pkgrprnk=input$ShowAllPkGrps,
                                                        show_manual_annotation = manual_annotation_coordinates,
                                                        show_peak_info_tbl=F,
                                                        show_legend=T,
                                                        mzPntrs=values$mzPntrs[[ current_experiment ]]
                           )
                           values$alignedChromsPlot[[plotname]] <- plotly::ggplotly( p = (out.plot.h), source = plotname, tooltip = c("x", "y", "text"), dynamicTicks = T ) %>%
                             plotly::layout(title = list( text = unique(paste0( paste0("Alignment Failed - ", out.plot.h$labels$title),
                                                                                '<br>',
                                                                                '<sup>',
                                                                                gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', out.plot.h$labels$subtitle)),
                                                                                '</sup>')) ) ) %>%
                             event_register(event="plotly_relayout")
                           
                           chrom_input <- global$chromFile[[ which(grepl(paste0(".*", values$Reference, ".*"), names(global$chromFile))) ]]
                           osw_input <- global$oswFile[[1]]
                           peptide <- input$Mod
                           modification_labels <- regmatches(peptide, gregexpr("\\(.*?\\)", peptide))[[1]]
                           naked_peptide <-  gsub( paste(gsub('\\)','\\\\)',gsub('\\(','\\\\(',modification_labels)), collapse = '|'), '', peptide )
                           manual_annotation_coordinates <- NULL
                           
                           # cat( sprintf("chrom: %s\nosw: %s\nlib: %s\n", chrom_input, osw_input, global$libFile))
                           out.plot.h <- curateXICplot( pep=naked_peptide, 
                                                        uni_mod=peptide,
                                                        in_sqMass=chrom_input,  df_lib=values$lib_df, in_osw=osw_input, df_osw=values$osw_df,
                                                        plotPrecursor=input$Precursor,
                                                        plotDetecting=input$Detecting,
                                                        plotIdentifying=input$Identifying_Unique,
                                                        plotIdentifying.Unique=input$Identifying_Unique,
                                                        plotIdentifying.Shared=F,
                                                        plotIdentifying.Against=F,
                                                        doFacetZoom=F,
                                                        doPlot=T,
                                                        Charge_State=input$Charge,
                                                        printPlot=F,
                                                        store_plots_subdir=NULL,
                                                        use_top_trans_pep=F,
                                                        transition_selection_list=values$transition_selection_list,
                                                        show_n_transitions=input$nIdentifyingTransitions,
                                                        show_transition_scores=input$ShowTransitionScores,
                                                        show_all_pkgrprnk=input$ShowAllPkGrps,
                                                        show_manual_annotation = manual_annotation_coordinates,
                                                        show_peak_info_tbl=F,
                                                        show_legend=T,
                                                        mzPntrs=values$mzPntrs[[ current_experiment ]]
                           )
                           
                           ref_plotname <- paste("plot_run_", values$run_index_map[[ values$Reference ]], sep="")
                           values$alignedChromsPlot[[ref_plotname]] <- plotly::ggplotly( p = (out.plot.h + ggplot2::xlab("Reference RT")), source = plotname, tooltip = c("x", "y", "text"), dynamicTicks = T ) %>%
                             plotly::layout(title = list( text = unique(paste0( paste0("Alignment Failed - ", out.plot.h$labels$title),
                                                                                '<br>',
                                                                                '<sup>',
                                                                                gsub( ' \\| Precursor: \\d+ \\| Peptide: \\d+ \\| Charge: \\d+ | \\| ms2_m-score: .*' , ' ', gsub('\\\n', ' | ', out.plot.h$labels$subtitle)),
                                                                                '</sup>')) ) ) %>%
                             event_register(event="plotly_relayout")
                           
                           plot_text <- sprintf("There was an issue while performing alignment.\nWas unable to find an alignment path from similarity matrix.\n You can try adjust one of the alignment settings.\n ")
                           
                           values$alignmentPathPlot[[path_plotname]] <- plotly::ggplotly( ggplot() +
                                                                                            annotate( "text", x = 4, y = 25, size = 8, label = plot_text ) +
                                                                                            ggtitle( sprintf("Run: %s", current_experiment) ) +
                                                                                            theme_bw() + 
                                                                                            theme( panel.grid.major = element_blank(),
                                                                                                   panel.grid.minor = element_blank(),
                                                                                                   axis.title = element_blank(),
                                                                                                   axis.text = element_blank()
                                                                                            ) )
                           
                           ref_path_plotname <- paste("pathplot_run_", values$run_index_map[[ values$Reference ]], sep="")
                           plot_text <- sprintf("This is the reference run.\nThere is no self alignment performed.\n ")
                           
                           values$alignmentPathPlot[[ref_path_plotname]] <- plotly::ggplotly( ggplot() +
                                                                                                annotate( "text", x = 4, y = 25, size = 8, label = plot_text ) +
                                                                                                ggtitle( sprintf("Reference Run: %s", values$Reference) ) +
                                                                                                theme_bw() + 
                                                                                                theme( panel.grid.major = element_blank(),
                                                                                                       panel.grid.minor = element_blank(),
                                                                                                       axis.title = element_blank(),
                                                                                                       axis.text = element_blank()
                                                                                                ) )
                           
                         }
                         
                       }, 
                       error = function(e){
                         message(sprintf("[DrawAlignR::cacheAlignmentPlots] There was the following error that occured during cacheing plots: %s\n", e$message))
                       }
                     ) # End tryCatch
                   }) # End Local 477
                   incProgress(1/length(input$Experiment))
                 } # End for
               }) # End of Progress Tracker
  # }) # End observe
  
}