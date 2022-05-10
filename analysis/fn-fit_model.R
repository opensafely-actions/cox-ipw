fit_model <- function(data, time_periods, covariates, strata, age_spline) {
  
  # Define model formula ---------------------------------------------------------
  
  surv_formula <- paste0("Surv(tstart, tstop, outcome_status) ~ ",
                         paste(time_periods, collapse = " + "), " + ",
                         paste(covariates, collapse = " + "), 
                         " + cluster(patient_id) + ",
                         paste(paste0("rms::strat(", strata, ")"), collapse = " + "))
  
  # Specify knot placement for age spline if applicable --------------------------
  
  if (age_spline=="TRUE") {
    
    knot_placement <- as.numeric(quantile(data_surv$cov_num_age, probs=c(0.1,0.5,0.9)))
    
    surv_formula <- gsub("cov_num_age", "rms::rcs(cov_num_age, parms=knot_placement)", surv_formula)
    
  }
  
  # Fit Cox model ----------------------------------------------------------------
  
  dd <- rms::datadist(data_surv)
  
  options(datadist = "dd", contrasts = c("contr.treatment", "contr.treatment"))
  
  fit_cox_model <- rms::cph(formula = as.formula(surv_formula),
                            data = data_surv, 
                            weight = data_surv$cox_weights,
                            surv = TRUE,
                            x = TRUE,
                            y = TRUE)
  
  robust_fit_cox_model <- rms::robcov(fit_cox_model, 
                                      cluster = data_surv$patient_id)
  
  # Format results ---------------------------------------------------------------
  
  results <- data.frame(term = robust_fit_cox_model$Design$colnames,
                        estimate = exp( robust_fit_cox_model$coefficients),
                        robust.se = exp(sqrt(diag(vcov(robust_fit_cox_model)))),
                        robust.conf.low = exp(confint(robust_fit_cox_model,level=0.95)[,1]),
                        robust.conf.high = exp(confint(robust_fit_cox_model,level=0.95)[,2]),
                        se = exp(sqrt(diag(vcov(fit_cox_model)))),
                        surv_formula = surv_formula,
                        covariates_removed = paste0(covariates_removed, collapse = ";"),
                        covariates_collapsed = paste0(covariates_collapsed, collapse = ";"),
                        stringsAsFactors = FALSE)
  
  row.names(results) <- NULL
  
  # Return results -------------------------------------------------------------
  
  return(results)
  
}