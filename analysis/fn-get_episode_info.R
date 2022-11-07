get_episode_info <- function(df, cut_points, episode_labels) {

  # Calculate number of events per episode -------------------------------------

  events <- df[df$outcome_status==1, c("patient_id","episode")]
  
  events <- aggregate(episode ~ patient_id, data = events, FUN = max)
  
  events <- data.frame(table(events$episode), 
                       stringsAsFactors = FALSE)
  
  events <- dplyr::rename(events, "episode" = "Var1", "N_events" = "Freq")
  
  # Add number of events to episode info table ---------------------------------
  
  episode_info <- merge(episode_labels, events, by = "episode", all.x = TRUE)
  episode_info$N_events <- ifelse(is.na(episode_info$N_events),0,episode_info$N_events)
  
  # Calculate person-time in each episode --------------------------------------
  
  tmp <- df[,c("episode","tstart","tstop","cox_weight")]
  
  tmp$person_time_total <- (tmp$tstop - tmp$tstart)*tmp$cox_weight
  
  tmp[,c("tstart","tstop","cox_weight")] <- NULL
  
  tmp <- aggregate(person_time_total ~ episode, data = tmp, FUN = sum)
  
  episode_info <- merge(episode_info, tmp, by = "episode", all.x = TRUE)
  
  # Calculate median person-time -----------------------------------------------
  
  tmp <- df[df$outcome_status==1,c("episode","tstart","tstop")]
  
  tmp$outcome_time <- tmp$tstop - tmp$tstart
  
  tmp <- tmp %>%
    dplyr::group_by(episode) %>%
    dplyr::mutate(outcome_time_median = median(outcome_time)) %>%
    dplyr::ungroup(episode)
  
  tmp <- unique(tmp[,c("episode","outcome_time_median")])
  
  episode_info <- merge(episode_info, tmp, by = "episode", all.x = TRUE)
  
  # Add time from previous episodes to median person-time -----------------------
  
  episode_info$add <- as.numeric(gsub("days","",gsub("_.*","",episode_info$time_period)))
  episode_info$add <- ifelse(is.na(episode_info$add),0,episode_info$add)
  episode_info$outcome_time_median <- episode_info$outcome_time_median + episode_info$add
  episode_info$add <- NULL
  
  # Return episode_info table --------------------------------------------------
  
  return(episode_info)
  
}
