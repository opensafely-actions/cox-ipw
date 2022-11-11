ipw_sample <- function(df, controls_per_case, seed = 137, sample_exposed) {
  
  # Set seed -------------------------------------------------------------------
  print("Set seed")
  
  set.seed(seed)
  
  # Split cases and controls ---------------------------------------------------
  print("Split cases and controls")
  
  cases <- df[df$outcome_status==TRUE,]
  
  controls <- df[df$outcome_status==FALSE,]

  if (sample_exposed==FALSE) {
    print("Seperate exposed controls so they are not sampled")
    controls <- controls[is.na(controls$exposure),]
    exposed <- controls[!is.na(controls$exposure),]
    exposed$cox_weight <- 1
  } 

  print("Cases:")
  print(summary(cases))
  
  print("Controls:")
  print(summary(controls))
  
  # Sample controls if more than enough, otherwise retain all controls ---------
  
  if (nrow(cases)*controls_per_case<nrow(controls)) {
    print("Sample controls")
    controls <- controls[sample(1:nrow(controls), nrow(cases)*controls_per_case, replace = FALSE),]
    controls$cox_weight <- (nrow(df)-nrow(cases))/nrow(controls)
    print(paste0(nrow(controls), " controls sampled"))
    print(summary(controls$cox_weight))
  } else {
    print("Retain all controls")
    controls$cox_weight <- 1
  }
  
  if (sample_exposed==FALSE) {
    print("Add exposed control individuals back to control dataset")
    controls <- rbind(controls,exposed)
    print(summary(controls))
  } 
  
  # Specify cox weight for cases -----------------------------------------------
  print("Specify cox weight for cases")
  
  cases$cox_weight <- 1
  
  # Recombine cases and controls -----------------------------------------------
  print("Recombine cases and controls")
  
  df <- rbind(cases,controls)
  
  # Return dataset -------------------------------------------------------------
  
  return(df) 
  
}
