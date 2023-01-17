survival_data_setup <- function(df, cut_points, episode_labels) {
  
  # Calculate where follow-up occurs in study period ---------------------------
  print("Calculate where follow-up occurs in study period")
  
  df$days_to_start <- as.numeric(df$fup_start-df$study_start)
  df$days_to_end <- as.numeric(df$fup_stop-df$study_start) + 1
  
  # Set survival data for the exposed ------------------------------------------
  print("Set survival data for the exposed")
  
  ## Filter data to exposed
  print("Filter data to exposed")
  exposed <- df[!is.na(df$exposure),]
  
  ## Calculate days to exposure
  print("Calculate days to exposure")
  exposed$days_to_exp <- as.numeric(exposed$exposure - exposed$study_start)
  
  ## Put into survival format
  print("Put into survival format (dataset d1)")
  d1 <- exposed[,!(colnames(exposed) %in% c("days_to_start", "days_to_exp", "days_to_end", "outcome_status"))]
  print(summary(d1))
  
  print("Put into survival format (dataset d2)")
  d2 <- exposed[,c("patient_id", "days_to_start", "days_to_exp", "days_to_end", "outcome_status")]
  print(summary(d2))
  
  print("Put into survival format (tmerge)")
  exposed <- survival::tmerge(data1=d1, 
                              data2=d2, 
                              id=patient_id,
                              outcome_status=event(days_to_end, outcome_status), 
                              tstart=days_to_start, 
                              tstop = days_to_end,
                              exposure_status=tdc(days_to_exp)) 
  print(summary(exposed))
  
  # Split post-exposure time for the exposed -----------------------------------
  print("Split post-exposure time for the exposed")
  
  ## Filter to post-exposure data
  print("Filter to post-exposure data")
  exposed_post <- exposed[exposed$exposure_status==1,]
  
  ## Format tstart and tstop
  print("Format tstart and tstop")
  exposed_post <- dplyr::rename(exposed_post, t0=tstart, t=tstop) 
  exposed_post$tstart <- 0 
  exposed_post$tstop <- exposed_post$t - exposed_post$t0
  
  ## Implement post-exposure cut points
  print("Implement post-exposure cut points")
  
  print(summary(exposed_post))
  
  exposed_post <- survival::survSplit(Surv(tstop, outcome_status) ~ ., 
                            exposed_post,
                            cut=cut_points,
                            episode="episode")
  
  print(summary(exposed_post))
  
  ## Account for pre-exposure time
  print("Account for pre-exposure time")
  
  exposed_post$tstart <- exposed_post$tstart + exposed_post$t0
  exposed_post$tstop <- exposed_post$tstop + exposed_post$t0
  exposed_post[,c("t0","t")] <- NULL
  
  print(summary(exposed_post))
  
  # Combine pre- and post-exposure time for the exposed ------------------------
  print("Combine pre- and post-exposure time for the exposed")
  
  ## Filter to pre-exposure data
  print("Filter to pre-exposure data")
  exposed_pre <- exposed[exposed$exposure_status==0,]
  
  ## Set pre-exposure to be episode 0
  print("Set pre-exposure to be episode 0")
  exposed_pre$episode <- 0
  
  print(summary(exposed_pre))
  
  ## Bind pre- and post-exposure time
  print("Bind pre- and post-exposure time")
  exposed <- plyr::rbind.fill(exposed_pre, exposed_post)
  
  print(summary(exposed))
  
  # Set survival data for the unexposed ----------------------------------------
  print("Set survival data for the unexposed")
  
  ## Filter data to unexposed
  print("Filter data to unexposed")
  unexposed <- df[is.na(df$exposure),]
  
  ## Rename variables to survival variable names
  print("Rename variables to survival variable names")
  
  unexposed <- dplyr::rename(unexposed,
                             "tstart" = "days_to_start",
                             "tstop" = "days_to_end")
  
  unexposed$exposure_status <- c(0)
  unexposed$episode <- c(0)
  unexposed$outcome_status <- as.numeric(unexposed$outcome_status)
  
  print(summary(unexposed))
  
  # Combine exposed and unexposed individuals ----------------------------------
  print("Combine exposed and unexposed individuals")
  
  exposed <- exposed[,intersect(colnames(unexposed), colnames(exposed))]
  unexposed <- unexposed[,intersect(colnames(unexposed), colnames(exposed))]
  df <- rbind(exposed,unexposed)
  
  print(summary(df))
  
  # Add indicators for episode -------------------------------------------------
  print("Add indicators for episode")
  
  for (i in 1:max(episode_labels$episode)) {
    
    preserve_cols <- colnames(df) 
    
    df$tmp <- as.numeric(df$episode==i)
    
    colnames(df) <- c(preserve_cols,episode_labels[episode_labels$episode==i,]$time_period)
    
  }
  
  print(summary(df))
  
  # Return dataset -------------------------------------------------------------
  
  return(df) 
  
}
