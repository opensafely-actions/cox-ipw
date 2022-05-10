ipw_sample <- function(df, controls_per_case) {
  
  # Set seed -------------------------------------------------------------------
  
  set.seed(137)
  
  # Split cases and controls ---------------------------------------------------
  
  cases <- df[df$outcome_status==TRUE,]
  controls <- df[df$outcome_status==FALSE,]
  
  # Sample controls if more than enough, otherwise retain all controls ---------
  
  if (nrow(cases)*controls_per_case<nrow(controls)) {
    controls <- controls[sample(nrow(controls),nrow(cases)*controls_per_case),]
    controls$cox_weight  <- controls_per_case
  } else {
    controls$cox_weight <- 1
  }
  
  # Specify cox weight for cases -----------------------------------------------
  
  cases$cox_weight <- 1
  
  # Recombine cases and controls -----------------------------------------------
  
  df <- rbind(cases,controls)
  
  # Return dataset -------------------------------------------------------------
  
  return(df) 
  
}