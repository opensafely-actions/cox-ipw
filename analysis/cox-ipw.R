# Specify arguments ------------------------------------------------------------

args = commandArgs(trailingOnly=TRUE)

if(length(args)==0) {
  outcome = "out_date_vte" # previously event_name
  cohort = "vaccinated"
  mdl = "mdl_agesex"
  subgroup = "prior_history_TRUE"
  stratify_by_subgroup = "cov_bin_vte"
  strata = "TRUE"
  prior_history_var = "cov_bin_vte"
  covar_names = "cov_bin_healthcare_worker;cov_num_age;cov_cat_ethnicity;cov_cat_region;cov_bin_carehome_status;cov_bin_vte;cov_cat_sex"
} else {
  outcome = args[[1]]
  cohort = args[[2]]
  mdl = args[[3]]
  subgroup = args[[4]]
  stratify_by_subgroup = args[[5]]
  strata = args[[6]]
  prior_history_var = args[[7]]
  covar_names = args[[8]]
}

## Select covariates of interest -----------------------------------------------

covar_names <- stringr::str_split(covar_names, ";")[[1]]
covar_names <- append(covar_names,"patient_id")
covar_names <- covar_names[!covar_names %in% c("cov_num_age","cov_cat_ethnicity","cov_cat_region","cov_cat_sex")]

# Source relevant files --------------------------------------------------------

source("analysis/02_pipe.R") # Prepare dataset for model
source("analysis/extra_functions_for_cox_models.R")
source("analysis/call_mdl.R") # Model specification

ls_events_missing <- analyses_to_run

# ------------------------------------ LAUNCH JOBS -----------------------------

lapply(split(ls_events_missing,seq(nrow(ls_events_missing))),
       function(ls_events_missing) 
         get_vacc_res(
           event=ls_events_missing$event,
           subgroup=ls_events_missing$subgroup,
           stratify_by_subgroup=ls_events_missing$stratify_by_subgroup,
           stratify_by=ls_events_missing$strata,
           mdl=ls_events_missing$mdl,
           input, cuts_days_since_expo,cuts_days_since_expo_reduced,covar_names)
)

#Save csv of analyses not run
write.csv(analyses_not_run, paste0("output/analyses_not_run_", event_name, "_", cohort, ".csv"), row.names = T)

#Combine all results into one .csv
source("analysis/format_tbls_HRs.R")

