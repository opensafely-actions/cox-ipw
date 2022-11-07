survival_data_setup <- function(df, cut_points, episode_labels) {
  
  # Calculate where follow-up occurs in study period ---------------------------
  
  df$days_to_start <- as.numeric(df$fup_start-df$study_start)
  df$days_to_end <- as.numeric(df$fup_stop-df$study_start) + 1
  
  # Set survival data for the exposed ------------------------------------------
  
  ## Filter data to exposed
  exposed <- df[!is.na(df$exposure),]
  
  ## Calculate days to exposure
  exposed$days_to_exp <- as.numeric(exposed$exposure - exposed$study_start)
  
  ## Put into survival format
  d1 <- exposed[,!(colnames(exposed) %in% c("days_to_start", "days_to_exp", "days_to_end", "outcome_status"))]
  print("Survival format, d1")
  print(head(d1))
  
  d2 <- exposed[,c("patient_id", "days_to_start", "days_to_exp", "days_to_end", "outcome_status")]
  print("Survival format, d2")
  print(head(d2))
  
  exposed <- survival::tmerge(data1=d1, 
                              data2=d2, 
                              id=patient_id,
                              outcome_status=event(days_to_end, outcome_status), 
                              tstart=days_to_start, 
                              tstop = days_to_end,
                              exposure_status=tdc(days_to_exp)) 
  
  # Split post-exposure time for the exposed -----------------------------------
  
  ## Filter to post-exposure data
  exposed_post <- exposed[exposed$exposure_status==1,]
  
  ## Format tstart and tstop
  exposed_post <- dplyr::rename(exposed_post, t0=tstart, t=tstop) 
  exposed_post$tstart <- 0 
  exposed_post$tstop <- exposed_post$t - exposed_post$t0
  
  ## Implement post-exposure cut points
  exposed_post <- survSplit(Surv(tstop, outcome_status) ~ ., 
                            exposed_post,
                            cut=cut_points,
                            episode="episode")
  
  ## Account for pre-exposure time
  exposed_post$tstart <- exposed_post$tstart + exposed_post$t0
  exposed_post$tstop <- exposed_post$tstop + exposed_post$t0
  exposed_post[,c("t0","t")] <- NULL
  
  # Combine pre- and post-exposure time for the exposed ------------------------
  
  ## Filter to pre-exposure data
  exposed_pre <- exposed[exposed$exposure_status==0,]
  
  ## Set pre-exposure to be episode 0
  exposed_pre$episode <- 0
  
  ## Bind pre- and post-exposure time
  exposed <- plyr::rbind.fill(exposed_pre, exposed_post)
  
  # Set survival data for the unexposed ----------------------------------------
  
  ## Filter data to unexposed
  unexposed <- df[is.na(df$exposure),]
  
  ## Rename variables to survival variable names
  
  unexposed <- dplyr::rename(unexposed,
                             "tstart" = "days_to_start",
                             "tstop" = "days_to_end")
  
  unexposed$exposure_status <- c(0)
  unexposed$episode <- c(0)
  unexposed$outcome_status <- as.numeric(unexposed$outcome_status)
  
  # Combine exposed and unexposed individuals ----------------------------------
  
  exposed <- exposed[,intersect(colnames(unexposed), colnames(exposed))]
  unexposed <- unexposed[,intersect(colnames(unexposed), colnames(exposed))]
  df <- rbind(exposed,unexposed)
  
  # Add indicators for episode -------------------------------------------------
  
  for (i in 1:max(episode_labels$episode)) {
    
    preserve_cols <- colnames(df) 
    
    df$tmp <- as.numeric(df$episode==i)
    
    colnames(df) <- c(preserve_cols,episode_labels[episode_labels$episode==i,]$time_period)
    
  }
  
  # Return dataset -------------------------------------------------------------
  
  return(df) 
  
}
