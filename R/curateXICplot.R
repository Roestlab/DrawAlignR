#// **********************************************************************************************
#//                         curateXICplot.R
#// **********************************************************************************************
#//
#// 
#// **********************************************************************************************
#// @Maintainer: Justin Sing
#// @Author: Justin Sing

#' @export
#' @title Master Plotting function for plotting XIC's
#' @description This function can be used to draw XIC's by calling getXIC 
#' 
#' @param pep A character vector of a peptide sequence(s). 
#' @param uni_mod A character vector of a modified peptide sequence. (Default: NULL) If using this argument, pep must be a single peptide
#' @param in_sqMass A  character vector. Full path to chromatogram file.
#' @param df_lib A dataframe containing library information.
#' @param in_osw A character vector. Full path to an osw results file.
#' @param df_osw A dataframe containg OpenSwath Results Information
#' @param plotPrecursor A logical value. True will plot precursor chromatogram
#' @param plotDetecting A logcail value. True will plot detecting transitions.
#' @param plotIdentifying A logical value. True will plot identifying transitions.
#' @param plotIdentifying.Unique A logical value. True will plot unique identifying transitions.
#' @param plotIdentifying.Shared A logical value. True will plot shared identifying transitions. (Decaprecated)
#' @param plotIdentifying.Against A logical value. True will plot against identifying transitions. (Decaprecated)
#' @param smooth_chromatogram A list containing p (numeric) for the polynomial order for sgolay, and n (numeric) the bandwidth for sgolay. (Defualt: list(p=4, n=9)
#' @param doFacetZoom A logical valie. Should the plot be zoomed in. The default zooming operation is based on the max int divided by 4. (Default: FALSE)
#' @param FacetFcnCall A facet_zoom function with user defined parameters. i.e. FacetFcnCall = facet_zoom(xlim = c(7475, 7620), ylim = c(0, 4000) ). (Default: NULL)
#' @param doPlot A logical value. TRUE will perform steps to save the plot as a pdf.
#' @param Charge_State A numeric value. The target charge state. (Default: NULL)
#' @param store_plots_subdir A character vector. The location to store plots.
#' @param printPlot A logical value. TRUE will print plot in RStudio display.
#' @param use_top_trans_pep A logical value. TRUE will rank the transitions based on the posterior error probabilities.
#' @param transition_selection_list A list containing transitions to display for unique identifying. i.e. transition_selection_list <- list( y = c(3), b = c(8:10) )
#' @param show_n_transitions A numeric value. Show n number of transitions
#' @param show_transition_scores A logical value. If set to TRUE, will include TRANSITION PEPs as text tag when using interactive plotly.
#' @param annotate_best_pkgrp A logical value. Annotate Top Peak Group
#' @param show_all_pkgrprnk A logical value. Show all feature peak-group ranks. Usually 5. (Default: 5)
#' @param show_manual_annotation A dataframe with leftWidth and rightWidth retention time boundary values of a manually annotated peak. Will draw a transparent blue shaded rectangle indicating manual annotation. I.e data.frame(leftWidth=300, rightWidth=330)
#' @param show_legend A logical value. Display legend information for transition id, m/z and charge. (Default: TRUE)
#' 
#' @return A ggplot-grobs table of a XIC
#' 
#' @author Justin Sing \url{https://github.com/singjc}
#' @importFrom  tictoc tic toc
#' @importFrom crayon blue red underline magenta bold 
#' @importFrom parallel mclapply detectCores
#' @importFrom ggplot2 ggplot
#' @importFrom dplyr %>% filter select distinct arrange
#' @importFrom stringr str_replace_all
#' @importFrom MazamaCoreUtils logger.isInitialized logger.info logger.error logger.warn logger.trace
curateXICplot <- function( pep, 
                           uni_mod=NULL, 
                           in_sqMass,  df_lib, in_osw, df_osw,
                           plotPrecursor=T,
                           plotDetecting=T,
                           plotIdentifying=F,
                           plotIdentifying.Unique=F,
                           plotIdentifying.Shared=F,
                           plotIdentifying.Against=F,
                           smooth_chromatogram=list(p = 4, n = 9), 
                           doFacetZoom=F,
                           FacetFcnCall=NULL,
                           doPlot=T,
                           Charge_State=NULL,
                           store_plots_subdir = NULL,
                           printPlot=F,
                           use_top_trans_pep=F,
                           transition_selection_list=NULL,
                           show_n_transitions=NULL,
                           show_transition_scores=FALSE,
                           transition_dt=NULL,
                           annotate_best_pkgrp=TRUE,
                           show_all_pkgrprnk=T,
                           show_peak_info_tbl=F,
                           show_manual_annotation=NULL,
                           show_legend=T,
                           mzPntrs=NULL
) {
  
  # Get XICs for Modified Peptides  ---------------------------------------------------------------
  
  ## Check if logging has been initialized
  if( !MazamaCoreUtils::logger.isInitialized() ){
    mstools::log_setup()
  }
  
  tictoc::tic( paste('XIC plotting for ', pep, ' peptides took: ', sep=' '))
  
  run_name <- gsub('_osw_chrom[.]sqMass$|[.]chrom.mzML$|[.]chrom.sqMass$', '', basename(in_sqMass)) # Add a control statement here
  run <- gsub('_SW*|_SW_0|(*_-_SW[.]mzML[.]gz|[.]chrom[.]sqMass)', '', gsub('yanliu_I170114_\\d+_|chludwig_K150309_|lgillet_L\\d+_\\d+-Manchester_dirty_phospho_-_', '', run_name))
  
  MazamaCoreUtils::logger.info( paste( crayon::blue('@ Run: ', run),'\n', sep='' ) )
  
  plot_chrom_error <- tryCatch({
    
    ## Charge State
    Isoform_Target_Charge <- Charge_State
    
    m_score_filter_var <- ifelse( length(grep( "m_score|ms2_m_score", colnames(df_osw), value = T))==2, "m_score", "ms2_m_score" )
    df_osw %>%
      dplyr::filter( Sequence==pep ) %>%
      dplyr::filter( FullPeptideName==uni_mod ) %>%
      dplyr::filter( !is.na( !!rlang::sym(m_score_filter_var) ) ) %>%
      dplyr::filter( Charge==Isoform_Target_Charge ) %>%
      dplyr::filter( grepl(run_name, filename) ) -> tmp_osw_df
    
    if ( any(colnames(tmp_osw_df) %in% "ipf_FullPeptideName") ){
      tmp_osw_df %>%
        dplyr::filter( ipf_FullPeptideName==mstools::unimodTocodename(uni_mod) ) -> tmp_osw_df
    }
    
    
    # if ( dim(tmp_osw_df)[1]==0 ){ MazamaCoreUtils::logger.error(crayon::red(pep, ' was not found  in osw file!!!, skipping...\n'),sep=''); return(list()) }
    
    
    
    # Filter df_lib based on only the uni modifications with specified charge state found in OSW results
    df_lib %>%
      dplyr::filter( UNMODIFIED_SEQUENCE==pep ) %>%
      dplyr::filter( MODIFIED_SEQUENCE==uni_mod ) %>%
      dplyr::filter( PRECURSOR_CHARGE==Isoform_Target_Charge ) -> df_lib
    
    
    # Display other peak group rank features
    if ( show_all_pkgrprnk ){
      RT_pkgrps <- tmp_osw_df$RT
    } else {
      RT_pkgrps <- NULL
    }
    
    uni_mod_list <- NULL
    
    
    ##***********************************##
    ## Get TRANSITION SCORES INFO TABLE  ##
    ##***********************************##
    if ( show_transition_scores ){
      if ( is.null(transition_dt) ){
        transition_dt <- mstools::getTransitionScores_( oswfile = in_osw, run_name = "", precursor_id = "", peptide_id = "")
      } else { transition_dt <- NULL }
    } else {
      transition_dt <- NULL
    }
    
    MazamaCoreUtils::logger.info('   ~ Starting Plotting Action\n', sep='')
    max_Int <- 0
    mod <- uni_mod
    tictoc::tic("Plotting: ")
    MazamaCoreUtils::logger.info( crayon::green('   --- Peptidoform: ', mod), '\n', sep='')
    ##***********************##
    ##     PLOT PRECURSOR    ##
    ##***********************##
    if ( plotPrecursor==T ){
      
      g <- ggplot2::ggplot()
      g <- mstools::getXIC( graphic_obj = g, 
                            df_lib = df_lib, 
                            mod = mod, 
                            Isoform_Target_Charge = Isoform_Target_Charge,
                            chromatogram_file = in_sqMass,  
                            transition_type = 'precursor', 
                            uni_mod_list = NULL, 
                            max_Int = max_Int, 
                            in_osw=NULL, 
                            smooth_chromatogram=smooth_chromatogram, 
                            doFacetZoom=F, 
                            top_trans_mod_list=NULL, 
                            show_n_transitions=show_n_transitions,
                            transition_dt=transition_dt,
                            mzPntrs=mzPntrs )
      max_Int <- g$max_Int
      g <- g$graphic_obj
    } else {
      g <- ggplot2::ggplot()
    }
    
    ##*****************************##
    ##   DETECTING TRANSITIONS     ##
    ##*****************************##
    
    ## INTERSECTING
    if ( plotDetecting==T ){
      g <- mstools::getXIC( graphic_obj = g, 
                            df_lib = df_lib, 
                            mod = mod, 
                            Isoform_Target_Charge = Isoform_Target_Charge,
                            chromatogram_file = in_sqMass, 
                            transition_type = 'detecting', 
                            uni_mod_list = uni_mod_list, 
                            max_Int = max_Int, 
                            in_osw=NULL, 
                            smooth_chromatogram=smooth_chromatogram, 
                            doFacetZoom=F, 
                            top_trans_mod_list=NULL, 
                            show_n_transitions=show_n_transitions,
                            transition_dt=transition_dt,
                            mzPntrs=mzPntrs)
      max_Int <- g$max_Int
      g <- g$graphic_obj
    }
    
    ##*******************************##
    ##    IDENTIFYING TRANSITIONS    ##
    ##*******************************##
    if ( plotIdentifying==T ){
      g <- mstools:: getXIC( graphic_obj = g, 
                             df_lib = df_lib, 
                             mod = mod, 
                             Isoform_Target_Charge = Isoform_Target_Charge,
                             chromatogram_file = in_sqMass,  
                             transition_type='identifying', 
                             uni_mod_list = uni_mod_list, 
                             max_Int = max_Int, 
                             in_osw=NULL, 
                             smooth_chromatogram=smooth_chromatogram, 
                             doFacetZoom=F, 
                             top_trans_mod_list=NULL, 
                             transition_selection_list=transition_selection_list,
                             show_n_transitions=show_n_transitions, 
                             plotIdentifying.Unique=plotIdentifying.Unique, 
                             plotIdentifying.Shared=plotIdentifying.Shared, 
                             plotIdentifying.Against=plotIdentifying.Against,
                             transition_dt=transition_dt,
                             mzPntrs=mzPntrs)
      max_Int <- g$max_Int
      g <- g$graphic_obj
      
    } else {
      MazamaCoreUtils::logger.warn(crayon::red('-- Identifying Transitions were not found for: ', crayon::underline(mod)), '\n', sep='')
    }
    tictoc::toc()
    
    tryCatch(
      expr = {
        ##*******************************##
        ##     ADD OSW RESULTS INFO      ##
        ##*******************************##
        g <- mstools::getXIC( graphic_obj = g, 
                              df_lib = df_lib, 
                              mod = mod, 
                              Isoform_Target_Charge = Isoform_Target_Charge,
                              chromatogram_file = in_sqMass, 
                              transition_type='none', 
                              uni_mod_list = NULL, 
                              max_Int = max_Int, 
                              in_osw = in_osw, 
                              df_osw = tmp_osw_df,
                              annotate_best_pkgrp=annotate_best_pkgrp,
                              doFacetZoom=doFacetZoom, 
                              top_trans_mod_list=NULL, 
                              RT_pkgrps=RT_pkgrps, 
                              show_manual_annotation=show_manual_annotation, 
                              show_peak_info_tbl=show_peak_info_tbl,
                              FacetFcnCall=FacetFcnCall, 
                              show_legend = show_legend  )
        max_Int <- g$max_Int
        g <- g$graphic_obj
        
      }, 
      error = function(e){
        message(sprintf("[DrawAlignR::curateXICplot] There was the following error that occured while adding OSW results info: %s\n", e$message))
      }
    ) # End tryCatch
    
    graphics.off()
    
    return( g )
    
  }, error=function(e){
    
    MazamaCoreUtils::logger.error( paste(crayon::red('There was an issue trying to process ', crayon::underline(pep), ' from run: '), crayon::underline(run), '\n', sep='') )
    stop(e$message)
    
  })
  
}

