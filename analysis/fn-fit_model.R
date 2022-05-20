fit_model <- function(df, time_periods, covariates, strata, age_spline, covariate_removed, covariate_collapsed) {
  
  # Define model formula ---------------------------------------------------------
  
  surv_formula <- paste0("Surv(tstart, tstop, outcome_status) ~ ",
                         paste(time_periods, collapse = " + "), 
                         " + cov_cat_sex + cov_num_age  +",
                         " + cluster(patient_id) + ",
                         paste(paste0("rms::strat(", strata, ")"), collapse = " + "))
  
  # Specify knot placement for age spline if applicable --------------------------
  
  if (age_spline=="TRUE") {
    
    knot_placement <- as.numeric(quantile(df$cov_num_age, probs=c(0.1,0.5,0.9)))
    
    surv_formula <- gsub("cov_num_age", "rms::rcs(cov_num_age, parms=knot_placement)", surv_formula)
    
  }
  
  # Fit Cox model ----------------------------------------------------------------
  
  dd <<- rms::datadist(df)
  
  options(datadist = "dd", contrasts = c("contr.treatment", "contr.treatment"))
  
  fit_cox_model <- rms::cph(formula = as.formula(surv_formula),
                            data = df, 
                            weight = df$cox_weights,
                            surv = TRUE,
                            x = TRUE,
                            y = TRUE)
  
  robust_fit_cox_model <- rms::robcov(fit_cox_model, 
                                      cluster = df$patient_id)
  
  # Format results ---------------------------------------------------------------
  
  results <- data.frame(term = robust_fit_cox_model$Design$colnames,
                        estimate = exp(robust_fit_cox_model$coefficients),
                        robust.se = exp(sqrt(diag(vcov(robust_fit_cox_model)))),
                        robust.conf.low = exp(confint(robust_fit_cox_model,level=0.95)[,1]),
                        robust.conf.high = exp(confint(robust_fit_cox_model,level=0.95)[,2]),
                        se = exp(sqrt(diag(vcov(fit_cox_model)))),
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
    
    surv_formula_adj <- paste0(surv_formula, " + ",
                               paste(covariates, collapse = " + "))
    
    # Fit Cox model ------------------------------------------------------------
    
    dd_adj <<- rms::datadist(df)
    
    options(datadist = "dd_adj", contrasts = c("contr.treatment", "contr.treatment"))
    
    fit_cox_model_adj <- rms::cph(formula = as.formula(surv_formula_adj),
                                  data = df, 
                                  weight = df$cox_weights,
                                  surv = TRUE,
                                  x = TRUE,
                                  y = TRUE)
    
    robust_fit_cox_model_adj <- rms::robcov(fit_cox_model_adj,
                                            cluster = df$patient_id)
    
    # Format results ---------------------------------------------------------------
    
    results_adj <- data.frame(term = robust_fit_cox_model_adj$Design$colnames,
                              estimate = exp(robust_fit_cox_model_adj$coefficients),
                              robust.se = exp(sqrt(diag(vcov(robust_fit_cox_model_adj)))),
                              robust.conf.low = exp(confint(robust_fit_cox_model_adj,level=0.95)[,1]),
                              robust.conf.high = exp(confint(robust_fit_cox_model_adj,level=0.95)[,2]),
                              se = exp(sqrt(diag(vcov(fit_cox_model_adj)))),
                              model = "mdl_max_adj",
                              surv_formula = surv_formula_adj,
                              covariate_removed = paste0(covariate_removed, collapse = ";"),
                              covariate_collapsed = paste0(covariate_collapsed, collapse = ";"),
                              stringsAsFactors = FALSE)
    
    row.names(results_adj) <- NULL
    
    # Bind to other results ----------------------------------------------------
    
    results <- rbind(results,results_adj)
    
  }
  
  # Return results -------------------------------------------------------------
  
  return(results)
  
}