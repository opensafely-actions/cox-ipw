check_covariates <- function(df, covariate_threshold) {
  
  # Idenfify non-numeric covariates to remove ----------------------------------
  
  covariate_removed <- NULL
  
  for (i in colnames(df)[grepl("cov_",colnames(df))]) {
    
    # Consider non-numeric covariates ------------------------------------------
    
    if (grepl("cov_bin_",i) | grepl("cov_cat_",i)) {
      
      # Calculate frequency for each level -------------------------------------
      
      tmp <- unique(df[df$exposure_status==1 & df$outcome_status==1,c("patient_id",i)])
      freq <- data.frame(table(tmp[,i]))
      
      # Add covariates to removal list if they fall below covariate threshold --
      
      if (nrow(freq[freq$Freq<=covariate_threshold  & freq$Var1!="Missing",])>0) {
        covariate_removed <- c(covariate_removed,i)
      }
      
      # Add covariates to removal list if the covariate has a single level -----
      
      if (nrow(freq)==1) {
        covariate_removed <- c(covariate_removed,i)
      }
      
    }
    
  }
  
  # Collapse special case covariates -------------------------------------------
  
  covariate_collapsed <- NULL
  
  ## Deprivation  
  
  if ("cov_cat_deprivation" %in% covariate_removed) {
    
    df <- df %>% 
      dplyr::mutate(cov_cat_deprivation = 
                      dplyr::case_when(cov_cat_deprivation=="1-2 (most deprived)"~"1-4",
                                cov_cat_deprivation=="3-4"~"1-4",
                                cov_cat_deprivation=="5-6"~"5-6",
                                cov_cat_deprivation=="7-8"~"7-10",
                                cov_cat_deprivation=="9-10 (least deprived)"~"7-10"))
    
    df$cov_cat_deprivation <- ordered(df$cov_cat_deprivation, 
                                             levels = c("1-4","5-6","7-10"))
    
    covariate_removed <- setdiff(covariate_removed,"cov_cat_deprivation")
    covariate_collapsed <- c(covariate_collapsed, "cov_cat_deprivation")
    
    
    
  }
  
  # Smoking status -------------------------------------------------------------
  
  if ("cov_cat_smoking_status" %in% covariate_removed) {
    
    df <- df %>% 
      dplyr::mutate(cov_cat_smoking_status = 
                      dplyr::case_when(cov_cat_smoking_status=="Never smoker"~"Never smoker",
                                cov_cat_smoking_status=="Ever smoker"~"Ever smoker",
                                cov_cat_smoking_status=="Current smoker"~"Ever smoker",
                                cov_cat_smoking_status=="Missing"~"Missing"))
    
    df$cov_cat_smoking_status <- ordered(df$cov_cat_smoking_status, 
                                                levels = c("Never smoker","Ever smoker","Missing"))
    
    covariate_removed <- setdiff(covariate_removed,"cov_cat_smoking_status")
    
  }
  
  # Check special case collapsed covariates ------------------------------------
  
  for (i in c("cov_cat_deprivation","cov_cat_smoking_status")) {
    
    if (i %in% colnames(df)) {
      
      # Calculate frequency for each level -------------------------------------
      
      tmp <- unique(df[df$exposure_status==1 & df$outcome_status==1,c("patient_id",i)])
      freq <- data.frame(table(tmp[,i]))
      
      # Add covariates to removal list if they fall below covariate threshold --
      
      if (nrow(freq[freq$Freq<=covariate_threshold & freq$Var1!="Missing",])>0) {
        covariate_removed <- c(covariate_removed,i)
        covariate_collapsed <- setdiff(covariate_collapsed, i)
      }
      
      # Add covariates to removal list if the covariate has a single level -----
      
      if (nrow(freq)==1) {
        covariate_removed <- c(covariate_removed,i)
        covariate_collapsed <- setdiff(covariate_collapsed, i)
      }
      
    }
    
  }
  
  
  # Remove covariates ----------------------------------------------------------
  
  df <- df[,!(colnames(df) %in% covariate_removed)]
  
  # Return data and list of removed covariates ---------------------------------
  
  output <- list(df = df, 
                 covariate_removed = covariate_removed, 
                 covariate_collapsed = covariate_collapsed)
  
  return(output)
  
}
