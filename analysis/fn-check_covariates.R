check_covariates <- function(df, covariate_threshold) {
  
  # Idenfify non-numeric covariates to remove ----------------------------------
  
  covariates_removed <- NULL
  
  for (i in colnames(df)[grepl("cov_",colnames(df))]) {
    
    # Consider non-numeric covariates ------------------------------------------
    
    if (grepl("cov_bin_",i) | grepl("cov_cat_",i)) {
      
      # Calculate frequency for each level -------------------------------------
      
      tmp <- unique(df[df$exposure_status==1 & df$outcome_status==1,c("patient_id",i)])
      freq <- data.frame(table(tmp[,i]))
      
      # Add covariates to removal list -----------------------------------------  
      
      if (nrow(freq[freq$Freq<=covariate_threshold,])>0) {
        covariates_removed <- c(covariates_removed,i)
      }
      
    }
    
  }
  
  # Collapse special case covariates -------------------------------------------
  
  covariates_collapsed <- NULL
  
  ## Deprivation  
  
  if ("cov_cat_deprivation" %in% covariates_removed) {
    
    df <- df %>% 
      dplyr::mutate(cov_cat_deprivation = 
                      case_when(cov_cat_deprivation=="1-2 (most deprived)"~"1-4",
                                cov_cat_deprivation=="3-4"~"1-4",
                                cov_cat_deprivation=="5-6"~"5-6",
                                cov_cat_deprivation=="7-8"~"7-10",
                                cov_cat_deprivation=="9-10 (least deprived)"~"7-10"))
    
    df$cov_cat_deprivation <- ordered(df$cov_cat_deprivation, 
                                             levels = c("1-4","5-6","7-10"))
    
    covariates_removed <- setdiff(covariates_removed,"cov_cat_deprivation")
    covariates_collapsed <- c(covariates_collapsed, "cov_cat_deprivation")
    
  }
  
  # Smoking status -------------------------------------------------------------
  
  if ("cov_cat_smoking_status" %in% covariates_removed) {
    
    df <- df %>% 
      dplyr::mutate(cov_cat_smoking_status = 
                      case_when(cov_cat_smoking_status=="Never smoker"~"Never smoker",
                                cov_cat_smoking_status=="Ever smoker"~"Ever smoker",
                                cov_cat_smoking_status=="Current smoker"~"Ever smoker",
                                cov_cat_smoking_status=="Missing"~"Missing"))
    
    df$cov_cat_smoking_status <- ordered(df$cov_cat_smoking_status, 
                                                levels = c("Never smoker","Ever smoker","Missing"))
    
    covariates_removed <- setdiff(covariates_removed,"cov_cat_smoking_status")
    
  }
  
  # Remove covariates ----------------------------------------------------------
  
  df <- df[,!(colnames(df) %in% covariates_removed)]
  
  # Return data and list of removed covariates ---------------------------------
  
  output <- list(df = df, 
                 covariates_removed = covariates_removed, 
                 ovariates_collapsed = covariates_collapsed)
  
  return(output)
  
}