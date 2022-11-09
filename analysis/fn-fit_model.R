fit_model <- function(df, time_periods, covariates, strata, age_spline, covariate_removed, covariate_collapsed, ipw) {
  
  # Define model formula -------------------------------------------------------
  print("Define model formula")
  
  surv_formula <- paste0("Surv(tstart, tstop, outcome_status) ~ ",
                         paste(time_periods, collapse = " + "), 
                         ifelse("cov_cat_sex" %in% colnames(df), " + cov_cat_sex", ""),
                         paste(" +", paste0("rms::strat(", strata, ")"), collapse = " + "),
                         ifelse(ipw==TRUE, " + cluster(patient_id)", ""))
  
  # Add age covariate, specifying knot placement for age spline if applicable --
  
  if ("cov_num_age" %in% colnames(df)) {
    
    print("Add age covariate")
    
    if (age_spline=="TRUE") {
      
      print("Specify knot placement for age spline")
      
      knot_placement <- as.numeric(quantile(df$cov_num_age, probs=c(0.1,0.5,0.9)))
      
      print(paste0("Knots will be placed at: ", paste0(knot_placement, collapse = ", ")))
      
      surv_formula <- paste0(surv_formula, " + rms::rcs(cov_num_age, parms=knot_placement)")
      
    } else {
      
      surv_formula <- paste0(surv_formula, " + cov_num_age + cov_num_age_sq")
      
    }
    
  }
  
  print(surv_formula)
  
  # Fit Cox model ----------------------------------------------------------------
  print("Fit Cox model")
  
  dd <<- rms::datadist(df)
  
  withr::local_options(list(datadist = "dd", contrasts = c("contr.treatment", "contr.treatment")))

  if (ipw==TRUE) {
    
    fit_cox_model <- rms::cph(formula = as.formula(surv_formula),
                              data = df, 
                              weight = df$cox_weights,
                              method = "breslow",
                              surv = TRUE,
                              x = TRUE,
                              y = TRUE)
    
  } else {
    
    fit_cox_model <- rms::cph(formula = as.formula(surv_formula),
                              data = df, 
                              method = "breslow",
                              surv = TRUE,
                              x = TRUE,
                              y = TRUE)
    
  }
  
  print(fit_cox_model)
  
  # Format results ---------------------------------------------------------------
  print("Format results")
  
  results <- data.frame(term = names(fit_cox_model$coefficients),
                        lnhr = fit_cox_model$coefficients,
                        se_lnhr = sqrt(diag(vcov(fit_cox_model))),
                        model = "mdl_age_sex",
                        surv_formula = surv_formula,
                        covariate_removed = "", 
                        covariate_collapsed = "",
                        stringsAsFactors = FALSE)
  
  row.names(results) <- NULL
  
  # If covariates are specified, run an additional model including them --------
  
  covariates <- setdiff(covariate_other, covariate_removed)
  
  if (!is.null(covariates) & length(covariates)>0) {
    
    # Add covariates to model formula ------------------------------------------
    print("Add covariates to model formula")
    
    surv_formula_adj <- paste0(surv_formula, " + ",
                               paste(covariates, collapse = " + "))
    
    print(surv_formula_adj)
    
    # Fit Cox model ------------------------------------------------------------
    print("Fit Cox model with covariates")
    
    dd_adj <<- rms::datadist(df)
    
    withr::local_options(list(datadist = "dd_adj", contrasts = c("contr.treatment", "contr.treatment")))

    if (ipw==TRUE) {
      
      fit_cox_model_adj <- rms::cph(formula = as.formula(surv_formula_adj),
                                data = df, 
                                weight = df$cox_weights,
                                method = "breslow",
                                surv = TRUE,
                                x = TRUE,
                                y = TRUE)
      
    } else {
      
      fit_cox_model_adj <- rms::cph(formula = as.formula(surv_formula_adj),
                                data = df, 
                                method = "breslow",
                                surv = TRUE,
                                x = TRUE,
                                y = TRUE)
      
    }
    
    print(fit_cox_model_adj)
    
    # Format results ---------------------------------------------------------------
    print("Format results")
    
    results_adj <- data.frame(term = names(fit_cox_model_adj$coefficients),
                              lnhr = fit_cox_model_adj$coefficients,
                              se_lnhr = sqrt(diag(vcov(fit_cox_model_adj))),
                              model = "mdl_max_adj",
                              surv_formula = surv_formula_adj,
                              covariate_removed = paste0(covariate_removed, collapse = ";"),
                              covariate_collapsed = paste0(covariate_collapsed, collapse = ";"),
                              stringsAsFactors = FALSE)
    
    row.names(results_adj) <- NULL
    
    # Bind to other results ----------------------------------------------------
    print("Bind to other results")
    
    results <- rbind(results,results_adj)
    
  }
  
  # Return results -------------------------------------------------------------
  print("Return results")  
  
  return(results)
  print(summary(results))
  
}
