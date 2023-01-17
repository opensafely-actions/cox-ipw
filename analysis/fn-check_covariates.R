check_covariates <- function(df, covariate_threshold, strata) {

  library(magrittr)

  # Identify non-numeric covariates to remove ----------------------------------
  print("Identify non-numeric covariates to remove")
  
  covariate_removed <- NULL
  
  for (i in unique(c(colnames(df)[grepl("cov_",colnames(df))], strata))) {
    
    # Consider non-numeric covariates ------------------------------------------
    
    if (grepl("cov_bin_",i) || grepl("cov_cat_",i)) {
      
      print(paste0("Covariate: ",i))
      
      # Calculate frequency for each level -------------------------------------
      print("Calculate frequency for each level")
      
      tmp <- unique(df[df$exposure_status==1 & df$outcome_status==1,c("patient_id",i)])
      freq <- data.frame(table(tmp[,i]))
      
      print(freq)
      
      # Add covariates to removal list if they fall below covariate threshold --
      
      if (nrow(freq[freq$Freq<=covariate_threshold  & freq$Var1!="Missing",])>0) {
        print("Add covariate to removal list")
        covariate_removed <- c(covariate_removed,i)
      }
      
      # Add covariates to removal list if the covariate has a single level -----
      
      if (nrow(freq)==1) {
        print("Add covariate to removal list")
        covariate_removed <- c(covariate_removed,i)
      }
      
    }
    
  }
  
  # Collapse special case covariates -------------------------------------------
  
  covariate_collapsed <- NULL
  
  ## Region  
  
  if ("cov_cat_region" %in% covariate_removed) {
    print("Collapsing region as special case")
    
    df <- df %>% 
      dplyr::mutate(cov_cat_region = 
                      dplyr::case_when(cov_cat_region=="North East"~"Northern England",
                                       cov_cat_region=="North West"~"Northern England",
                                       cov_cat_region=="Yorkshire and The Humber"~"Northern England",
                                       cov_cat_region=="London"~"Southern England",
                                       cov_cat_region=="South East"~"Southern England",
                                       cov_cat_region=="East Midlands"~"Midlands",
                                       cov_cat_region=="West Midlands"~"Midlands",
                                       cov_cat_region=="South West"~"Southern England",
                                       cov_cat_region=="East"~"Southern England"))
    
    df$cov_cat_region <- factor(df$cov_cat_region)
    df$cov_cat_region <- relevel(df$cov_cat_region, ref = "Southern England")
    
    covariate_removed <- setdiff(covariate_removed,"cov_cat_region")
    covariate_collapsed <- c(covariate_collapsed, "cov_cat_region")
    
  }
  
  ## Deprivation  
  
  if ("cov_cat_deprivation" %in% covariate_removed) {
    print("Collapsing deprivation as special case")
    
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
    print("Collapsing smoking status as special case")
    
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
  
  for (i in c("cov_cat_deprivation","cov_cat_smoking_status","cov_cat_region")) {
    
    if (i %in% colnames(df)) {
      
      print(paste0("Rechecking covariate: ", i))
      
      # Calculate frequency for each level among exposed with outcome ----------
      print("Calculate frequency for each level among exposed with outcome")
      
      tmp <- unique(df[df$exposure_status==1 & df$outcome_status==1,c("patient_id",i)])
      freq <- data.frame(table(tmp[,i]))
      
      print(freq)
      
      # Add covariates to removal list if they fall below covariate threshold --
      
      if (nrow(freq[freq$Freq<=covariate_threshold & freq$Var1!="Missing",])>0) {
        print("Add covariate to removal list")
        covariate_removed <- c(covariate_removed,i)
        covariate_collapsed <- setdiff(covariate_collapsed, i)
      }
      
      # Add covariates to removal list if the covariate has a single level -----
      
      if (nrow(freq)==1) {
        print("Add covariate to removal list")
        covariate_removed <- c(covariate_removed,i)
        covariate_collapsed <- setdiff(covariate_collapsed, i)
      }
      
    }
    
  }
  
  # Check strata variables meet covariate threshold ----------------------------
  print("Check strata variables meet covariate threshold")
  
  strata_warning <- ""
  
  if (length(intersect(covariate_removed,strata))>0) {
    strata_warning <- paste0(intersect(covariate_removed,strata), collapse = ";")
    for (i in intersect(covariate_removed,strata)) {
      tmp <- unique(df[df$exposure_status==1 & df$outcome_status==1,c("patient_id",i)])
      freq <- data.frame(table(tmp[,i]))
      print(paste0("Warning: strata variable '",i,"' does not meet covariate threshold"))
      print(freq)
    }
  } 
  
  # Remove covariates ----------------------------------------------------------
  print("Remove covariates")
  
  df <- df[,!(colnames(df) %in% setdiff(covariate_removed,strata))]
  
  # Return data and list of removed covariates ---------------------------------
  
  output <- list(df = df, 
                 covariate_removed = setdiff(covariate_removed,strata), 
                 covariate_collapsed = covariate_collapsed,
                 strata_warning = strata_warning)
  
  return(output)
  
}
