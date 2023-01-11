# # # # # # # # # # # # # # # # # # # # #
# This script:
# - defines its arguments
# - samples data and applies inverse probability weights
# - performs survival data setup
# - checks covariate variation
# - fits Cox model
# # # # # # # # # # # # # # # # # # # # #

# Define flag style arguments using the optparse package ----
library(optparse)
option_list <- list(
  make_option("--df_input", type = "character", default = "input.csv",
              help = "Input dataset csv filename (this is assumed to be within the output directory) [default %default]",
              metavar = "filename.csv"),
  make_option("--ipw", type = "logical", default = TRUE,
              help = "Logical, indicating whether sampling and IPW are to be applied [default %default]",
              metavar = "TRUE/FALSE"),
  make_option("--sample_exposed", type = "logical", default = FALSE,
              help = "Logical, indicating whether exposed individuals should be sampled [default %default]",
              metavar = "TRUE/FALSE"),
  make_option("--exposure", type = "character",
              default = "exp_date_covid19_confirmed",
              help = "Exposure variable name [default %default]",
              metavar = "exposure_varname"),
  make_option("--outcome", type = "character", default = "out_date_vte",
              help = "Outcome variable name [default %default]",
              metavar = "outcome_varname"),
  make_option("--strata", type = "character", default = "cov_cat_region",
              help = "Semi-colon separated list of variable names to be included as strata in the regression model [default %default]",
              metavar = "varname_1;varname_2;..."),
  make_option("--covariate_sex", type = "character", default = "cov_cat_sex",
              help = "Variable name for the sex covariate; specify argument as NULL to model without sex covariate [default %default]",
              metavar = "sex_varname"),
  make_option("--covariate_age", type = "character", default = "cov_num_age",
              help = "Variable name for the age covariate; specify argument as NULL to model without age covariate [default %default]",
              metavar = "age_varname"),
  make_option("--covariate_other", type = "character",
              default = "cov_cat_ethnicity;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_carehome_status",
              help = "Semi-colon separated list of other covariates to be included in the regression model; specify argument as NULL to run age, age squared, sex adjusted model only [default %default]",
              metavar = "varname_1;varname_2;..."),
  make_option("--cox_start", type = "character", default = "pat_index_date",
              help = "Semi-colon separated list of variable names used to define start of patient follow-up or single variable if already defined [default %default]",
              metavar = "varname_1;varname_2;..."),
  make_option("--cox_stop", type = "character", default = "death_date;out_date_vte;vax_date_covid_1",
              help = "semicolon separated list of variable names used to define end of patient follow-up or single variable if already defined [default %default]",
              metavar = "varname_1;varname_2;..."),
  make_option("--study_start", type = "character", default = "2021-06-01",
              help = "Study start date; this is used to remove events outside study dates [default %default]",
              metavar = "YYYY-MM-DD"),
  make_option("--study_stop", type = "character", default = "2021-12-14",
              help = "Study end date; this is used to remove events outside study dates [default %default]",
              metavar = "YYYY-MM-DD"),
  make_option("--cut_points", type = "character", default = "28;197",
              help = "Semi-colon separated list of cut points to be used to define time post exposure [default %default]",
              metavar = "cutpoint_1;cutpoint_2"),
  make_option("--controls_per_case", type = "integer", default = 20L,
              help = "Number of controls to retain per case in the analysis [default %default]",
              metavar = "integer"),
  make_option("--total_event_threshold", type = "integer", default = 50L,
              help = "Number of events that must be present for any model to run [default %default]",
              metavar = "integer"),
  make_option("--episode_event_threshold", type = "integer", default = 5L,
              help = "Number of events that must be present in a time period; if threshold is not met, time periods are collapsed [default %default]",
              metavar = "integer"),
  make_option("--covariate_threshold", type = "integer", default = 5L,
              help = "Minimum number of individuals per covariate level for covariate to be retained [default %default]",
              metavar = "integer"),
  make_option("--age_spline", type = "logical", default = TRUE,
              help = "Logical, if age should be included in the model as a spline with knots at 0.1, 0.5, 0.9 [default %default]",
              metavar = "TRUE/FALSE"),
  make_option("--df_output", type = "character", default = "results.csv",
              help = "Output data csv filename (this is assumed to be within the output directory) [default %default]",
              metavar = "filename.csv"),
  make_option("--seed", type = "integer", default = 137L,
              help = "Random number generator seed passed to IPW sampling [default %default]",
              metavar = "integer"),
  make_option("--save_analysis_ready", type = "logical", default = FALSE,
              help = "Logical, if analysis ready dataset should be saved [default %default]",
              metavar = "TRUE/FALSE")
)
opt_parser <- OptionParser(usage = "cox-ipw:[version] [options]", option_list = option_list)
opt <- parse_args(opt_parser)

# Record input arguments --------------------------------------------------------
print("Record input arguments")

record_args <- data.frame(argument = names(opt),
                          value = unlist(opt),
                          stringsAsFactors = FALSE)

row.names(record_args) <- NULL

print(record_args)

write.csv(record_args,
          file = paste0("output/args-", opt$df_output),
          row.names = FALSE)

# Import libraries -------------------------------------------------------------
print("Import libraries")

library(survival)
library(magrittr)

# Import functions -------------------------------------------------------------
print("Import functions")

source("analysis/fn-ipw_sample.R")
source("analysis/fn-survival_data_setup.R")
source("analysis/fn-get_episode_info.R")
source("analysis/fn-check_covariates.R")
source("analysis/fn-fit_model.R")

# Separate list arguments ------------------------------------------------------
print("Separate list arguments")

optlistargs <- c("strata", "covariate_other", "cut_points", "cox_start", "cox_stop")
for (i in seq_len(length(optlistargs))) {
  tmp <- opt[optlistargs[i]]
  if (tmp[1] == "NULL") {
    assign(optlistargs[i], NULL)
  } else {
    tmp <- stringr::str_split(as.vector(tmp), ";")[[1]]
    assign(optlistargs[i], tmp)
  }
}
rm(tmp)

# Make numeric arguments numeric -----------------------------------------------
print("Make numeric arguments numeric")

cut_points <- as.numeric(cut_points)
controls_per_case <- opt$controls_per_case
total_event_threshold <- opt$total_event_threshold
episode_event_threshold <- opt$episode_event_threshold
covariate_threshold <- opt$covariate_threshold

# Load data --------------------------------------------------------------------
print("Load data")

if (grepl(".csv",opt$df_input)) {
  data <- readr::read_csv(paste0("output/", opt$df_input))
}

if (grepl(".rds",opt$df_input)) {
  data <- readr::read_rds(paste0("output/", opt$df_input))
}

print(summary(data))

# Make binary variables logical ------------------------------------------------
print("Make binary variables logical")

var_bin <- colnames(data)[grepl("_bin_",colnames(data))]
data[,var_bin] <- lapply(data[,var_bin],as.logical)

# Make date variables dates ----------------------------------------------------
print("Make date variables dates")

var_date <- colnames(data)[grepl("_date",colnames(data))]
data[,var_date] <- lapply(data[,var_date], function(x) as.Date(x,origin="1970-01-01"))

# Make categorical variables factors -------------------------------------------
print("Make categorical variables factors")

var_cat <- colnames(data)[grepl("_cat_",colnames(data))]
data[,var_cat] <- lapply(data[,var_cat],as.factor)

# Make numerical variables numerical -------------------------------------------
print(" Make numerical variables numerical")

var_num <- colnames(data)[grepl("_num_",colnames(data))]
data[,var_num] <- lapply(data[,var_num],as.numeric)

# Restrict to core variables ---------------------------------------------------
print("Restrict to core variables")

core <- colnames(data)
core <- core[!grepl("cov_", core)]
core <- core[!grepl("sub_", core)]

input <- data[, core]

print(paste0("Core variables: ", paste0(core, collapse = ", ")))

# Give generic names to variables ----------------------------------------------
print("Give generic names to variables")

input <- dplyr::rename(input,
                       "outcome" = tidyselect::all_of(opt$outcome),
                       "exposure" = tidyselect::all_of(opt$exposure))

cox_start <- gsub(opt$outcome, "outcome", cox_start)
cox_start <- gsub(opt$exposure, "exposure", cox_start)

cox_stop <- gsub(opt$outcome, "outcome", cox_stop)
cox_stop <- gsub(opt$exposure, "exposure", cox_stop)

print(summary(input))

# Specify study dates ----------------------------------------------------------
print("Specify study dates")

input$study_start <- as.Date(opt$study_start)
input$study_stop <- as.Date(opt$study_stop)

print(summary(input))

# Specify follow-up dates ------------------------------------------------------
print("Specify follow-up dates")

input$fup_start <- do.call(pmax,
                           c(input[, c("study_start", cox_start)], list(na.rm = TRUE)))

input$fup_stop <- do.call(pmin,
                          c(input[, c("study_stop", cox_stop)], list(na.rm = TRUE)))

input <- input[input$fup_stop >= input$fup_start, ]

print(summary(input))

# Remove exposures and outcomes outside follow-up ------------------------------
print("Remove exposures and outcomes outside follow-up")

print(paste0("Exposure data range: ", min(input$exposure, na.rm = TRUE), " to ", max(input$exposure, na.rm = TRUE)))
print(paste0("Outcome data range: ", min(input$outcome, na.rm = TRUE), " to ", max(input$outcome, na.rm = TRUE)))

input <- input %>% 
  dplyr::mutate(exposure = replace(exposure, which(exposure>fup_stop | exposure<fup_start), NA),
                outcome = replace(outcome, which(outcome>fup_stop | outcome<fup_start), NA))

print(paste0("Exposure data range: ", min(input$exposure, na.rm = TRUE), " to ", max(input$exposure, na.rm = TRUE)))
print(paste0("Outcome data range: ", min(input$outcome, na.rm = TRUE), " to ", max(input$outcome, na.rm = TRUE)))

# Make indicator variable for outcome status -----------------------------------
print("Make indicator variable for outcome status")

input$outcome_status <- input$outcome==input$fup_stop & !is.na(input$outcome) & !is.na(input$fup_stop)

print(table(input$outcome_status))

# Sample control population ----------------------------------------------------

N_total <- nrow(input)
print(paste0("N_total = ",N_total))

N_exposed <- nrow(input[!is.na(input$exposure),])
print(paste0("N_exposed = ",N_exposed))

if (opt$ipw == TRUE) {
  print("Sample control population")
  input <- ipw_sample(df = input,
                      controls_per_case = controls_per_case, 
                      seed = opt$seed,
                      sample_exposed = opt$sample_exposed)
  print(paste0("After sampling, N_total = ",nrow(input)))
}

print(summary(input))


# Define episode labels --------------------------------------------------------
print("Define episode labels")

episode_labels <- data.frame(episode = 0:length(cut_points),
                             time_period = c("days_pre",paste0("days", c("0", cut_points[1:(length(cut_points)-1)]),"_", cut_points)),
                             stringsAsFactors = FALSE)

print(episode_labels)

# Survival data setup ----------------------------------------------------------
print("Survival data setup")

data_surv <- survival_data_setup(df = input,
                                 cut_points = cut_points,
                                 episode_labels = episode_labels)

print(summary(data_surv))

# Calculate events in each time period -----------------------------------------
print("Calculate events in each time period")

episode_info <- get_episode_info(df = data_surv,
                                 cut_points = cut_points,
                                 episode_labels = episode_labels,
                                 ipw = opt$ipw)

print(episode_info)

# STOP if the total number of events is insufficient ---------------------------

if (sum(episode_info[episode_info$time_period != "days_pre", ]$N_events) < total_event_threshold) {
  
  results <- data.frame(error = paste0("The total number of post-exposure events is less than the prespecified limit (limit = ", total_event_threshold, ")."))
  print(results$error)
  
} else {
  
  # Add strata information to data ---------------------------------------------
  print("Add strata information to data")
  
  data_strata <- data[, c("patient_id", strata)]
  data_surv <- merge(data_surv, data_strata, by = "patient_id", all.x = TRUE)
  
  print(summary(data_surv))
  
  # Add age covariates ---------------------------------------------------------
  print("Add age covariates")
  
  if (opt$covariate_age!="NULL") {
    
    data_covar <- data[, c("patient_id", opt$covariate_age)]
    
    data_covar <- dplyr::rename(data_covar,
                                "cov_num_age" = tidyselect::all_of(opt$covariate_age))
    
    data_covar$cov_num_age_sq <- data_covar$cov_num_age^2
    
    data_surv <- merge(data_surv, data_covar, by = "patient_id", all.x = TRUE)
    
    print(summary(data_surv))
    
  }
  
  # Add sex covariate ----------------------------------------------------------
  print("Add sex covariate")
  
  if (opt$covariate_sex!="NULL") {
    
    data_covar <- data[, c("patient_id", opt$covariate_sex)]
    
    data_covar <- dplyr::rename(data_covar,
                                "cov_cat_sex" = tidyselect::all_of(opt$covariate_sex))
    
    data_surv <- merge(data_surv, data_covar, by = "patient_id", all.x = TRUE)
    
    print(summary(data_surv))
    
  }
  
  # If additional covariates are specified, add covariate data -----------------
  
  covariate_removed <- NULL
  covariate_collapsed <- NULL
  
  if (!is.null(covariate_other)) {
    
    # Add covariate information to data ----------------------------------------
    print("Additional covariates specified: Add covariate information to data")
    
    data_covar <- data[, c("patient_id", covariate_other)]
    
    data_surv <- merge(data_surv, data_covar, by = "patient_id", all.x = TRUE)
    
    # Remove covariates with insufficient variation ----------------------------
    print("Additional covariates specified: Remove covariates with insufficient variation")
    
    tmp <- check_covariates(df = data_surv,
                            covariate_threshold = covariate_threshold,
                            strata = strata)
    
    data_surv <- tmp$df
    covariate_removed <- tmp$covariate_removed
    covariate_collapsed <- tmp$covariate_collapsed
    strata_warning <- tmp$strata_warning
    rm(tmp)
    
    print(summary(data_surv))
    print(paste0("Removed covariates: ",paste0(covariate_removed)))
    print(paste0("Collapsed covariates: ",paste0(covariate_collapsed)))
    
  }
  
  # Save analysis ready dataset ------------------------------------------------
  print("Save analysis ready dataset")
  
  data_surv[, c("study_start", "study_stop")] <- NULL
  
  if (opt$save_analysis_ready == TRUE) {
    readr::write_rds(data_surv, 
                     file = paste0("output/analysis_ready-", gsub("\\...*","",opt$df_input),".rds"))
  }
  
  # Perform Cox modelling ----------------------------------------------------
  print("Perform Cox modelling")

  results <- fit_model(df = data_surv,
                       time_periods = episode_info[episode_info$time_period != "days_pre", ]$time_period,
                       covariates = covariate_other,
                       strata = strata,
                       age_spline = opt$age_spline,
                       covariate_removed = covariate_removed,
                       covariate_collapsed = covariate_collapsed,
                       ipw = opt$ipw)
  
  # Merge results with number of events and person time ----------------------
  print("Merge results with number of events and person time")
  
  results <- merge(results,
                   episode_info[, c("time_period", "N_events", "person_time_total",  "outcome_time_median")],
                   by.x = "term",
                   by.y = "time_period",
                   all.x = TRUE)
  
  print(summary(results))
  
  # Add dummy row for days_pre term --------------------------------------------
  print("Add dummy row for days_pre term")
  
  tmp <- data.frame(term = "days_pre",
                    lnhr = NA,
                    se_lnhr = NA,
                    model = c("mdl_age_sex", "mdl_max_adj"),
                    surv_formula = c(results[results$model=="mdl_age_sex",]$surv_formula[1], results[results$model=="mdl_max_adj",]$surv_formula[1]),
                    covariate_removed = "",
                    covariate_collapsed = "",
                    N_events = episode_info[episode_info$time_period == "days_pre", ]$N_events,
                    person_time_total = episode_info[episode_info$time_period == "days_pre",]$person_time_total,
                    outcome_time_median = episode_info[episode_info$time_period == "days_pre",]$outcome_time_median,
                    stringsAsFactors = FALSE)
  
  results <- rbind(results, tmp)
  
  print(summary(results))
  
  # Tidy variables for outputting --------------------------------------------
  print("Tidy variables for outputting")
  
  results$N_total <- N_total
  results$N_exposed <- N_exposed
  
  results$exposure <- opt$exposure
  results$outcome <- opt$outcome
  
  results$input <- opt$df_input
  
  results$hr <- exp(results$lnhr)
  results$conf_low <- exp(results$lnhr - qnorm(0.975)*results$se_lnhr)
  results$conf_high <- exp(results$lnhr + qnorm(0.975)*results$se_lnhr)
  
  results$strata_warning <- strata_warning
  
  results <- results[order(results$model),
                     c("model", "exposure", "outcome", "term",
                       "lnhr","se_lnhr", "hr","conf_low", "conf_high", 
                       "N_total", "N_exposed", "N_events", 
                       "person_time_total", "outcome_time_median",
                       "covariate_collapsed","strata_warning",
                       "surv_formula","input")]
  
}

# Save output ------------------------------------------------------------------
print("Save output")

results$cox_ipw <- "v0.0.18"

write.csv(results,
          file = paste0("output/", opt$df_output),
          row.names = FALSE)

print(summary(results))
