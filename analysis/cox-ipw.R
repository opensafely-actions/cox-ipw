# # # # # # # # # # # # # # # # # # # # #
# This script:
# - defines its arguments
# - samples data and applies inverse probability weights
# - performs survival data setup
# - checks covariate variation
# - fits Cox model
# # # # # # # # # # # # # # # # # # # # #

# Define long flag style arguments using the optparse package ----
library(optparse)
option_list <- list(
  make_option("--df_input", type = "character", default = "input.csv",
              help = "Input dataset filename, including filepath [default %default]"),
  make_option("--ipw", type = "logical", default = TRUE,
              help = "Logical, indicating whether sampling and IPW are to be applied [default %default]"),
  make_option("--exposure", type = "character",
              default = "exp_date_covid19_confirmed",
              help = "Exposure variable name [default %default]"),
  make_option("--outcome", type = "character", default = "out_date_vte",
              help = "Outcome variable name [default %default]"),
  make_option("--strata", type = "character", default = "cov_cat_region",
              help = "Semi-colon separated list of variable names to be included as strata in the regression model [default %default]"),
  make_option("--covariate_sex", type = "character", default = "cov_cat_sex",
              help = "Variable name for the sex covariate [default %default]"),
  make_option("--covariate_age", type = "character", default = "cov_num_age",
              help = "Variable name for the age covariate [default %default]"),
  make_option("--covariate_other", type = "character",
              default = "cov_cat_ethnicity;cov_bin_vte;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_carehome_status",
              help = "Semi-colon separated list of other covariates to be included in the regression model; specify argument as NULL to run age, sex adjusted model only [default %default]"),
  make_option("--cox_start", type = "character", default = "pat_index_date",
              help = "Semi-colon separated list of variable used to define start of patient follow-up or single variable if already defined [default %default]"),
  make_option("--cox_stop", type = "character", default = "death_date;out_date_vte;vax_date_covid_1",
              help = "semicolon separated list of variable used to define end of patient follow-up or single variable if already defined [default %default]"),
  make_option("--study_start", type = "character", default = "2021-06-01",
              help = "Study start date; this is used to remove events outside study dates [default %default]"),
  make_option("--study_stop", type = "character", default = "2021-12-14",
              help = "Study end date; this is used to remove events outside study dates [default %default]"),
  make_option("--cut_points", type = "character", default = "28;197",
              help = "Semi-colon separated list of cut points to be used to define time post exposure [default %default]"),
  make_option("--cut_points_reduced", type = "character", default = "28;197",
              help = "Semi-colon separated list of cut points to be used to define time post exposure if insufficient events prevent first choice [default %default]"),
  make_option("--controls_per_case", type = "integer", default = 10L,
              help = "Number of controls to retain per case in the analysis [default %default]"),
  make_option("--total_event_threshold", type = "integer", default = 50L,
              help = "Number of events that must be present for any model to run [default %default]"),
  make_option("--episode_event_threshold", type = "integer", default = 5L,
              help = "Number of events that must be present in a time period; if threshold is not met, time periods are collapsed [default %default]"),
  make_option("--covariate_threshold", type = "integer", default = 2L,
              help = "Minimum number of individuals per covariate level for covariate to be retained [default %default]"),
  make_option("--age_spline", type = "logical", default = TRUE,
              help = "Logical, if age should be included in the model as a spline with knots at 0.1, 0.5, 0.9 [default %default]"),
  make_option("--df_output", type = "character", default = "results.csv",
              help = "Filename with filepath for output data [default %default]")
)
opt_parser <- OptionParser(usage = "cox-ipw: [options]", option_list = option_list)
opt <- parse_args(opt_parser)

# Record input arguments --------------------------------------------------------
print("Record input arguments")

record_args <- data.frame(argument = c("df_input",
                                       "ipw",
                                       "exposure",
                                       "outcome",
                                       "strata",
                                       "covariate_sex",
                                       "covariate_age",
                                       "covariate_other",
                                       "cox_start",
                                       "cox_stop",
                                       "study_start",
                                       "study_stop",
                                       "cut_points",
                                       "cut_points_reduced",
                                       "controls_per_case",
                                       "total_event_threshold",
                                       "episode_event_threshold",
                                       "covariate_threshold",
                                       "age_spline",
                                       "df_output"),
                          value = c(opt$df_input,
                                    opt$ipw,
                                    opt$exposure,
                                    opt$outcome,
                                    opt$strata,
                                    opt$covariate_sex,
                                    opt$covariate_age,
                                    opt$covariate_other,
                                    opt$cox_start,
                                    opt$cox_stop,
                                    opt$study_start,
                                    opt$study_stop,
                                    opt$cut_points,
                                    opt$cut_points_reduced,
                                    opt$controls_per_case,
                                    opt$total_event_threshold,
                                    opt$episode_event_threshold,
                                    opt$covariate_threshold,
                                    opt$age_spline,
                                    opt$df_output),
                          stringsAsFactors = FALSE)

print(record_args)

write.csv(record_args,
          file = paste0("output/args-", opt$df_output),
          row.names = FALSE)

# Import libraries -------------------------------------------------------------
print("Import libraries")

library(survival)

# Import functions -------------------------------------------------------------
print("Import functions")

source("analysis/fn-ipw_sample.R")
source("analysis/fn-survival_data_setup.R")
source("analysis/fn-get_episode_info.R")
source("analysis/fn-check_covariates.R")
source("analysis/fn-fit_model.R")

# Separate list arguments ------------------------------------------------------
print("Separate list arguments")

optlistargs <- c("strata", "covariate_other", "cut_points", "cut_points_reduced", "cox_start", "cox_stop")
for (i in 1:length(optlistargs)) {
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
cut_points_reduced <- as.numeric(cut_points_reduced)
controls_per_case <- opt$controls_per_case
total_event_threshold <- opt$total_event_threshold
episode_event_threshold <- opt$episode_event_threshold
covariate_threshold <- opt$covariate_threshold

# Load data --------------------------------------------------------------------
print("Load data")

data <- readr::read_csv(paste0("output/", opt$df_input))

# Restrict to core variables ---------------------------------------------------
print("Restrict to core variables")

core <- colnames(data)
core <- core[!grepl("cov_", core)]
core <- core[!grepl("sub_", core)]

input <- data[, core]

# Give generic names to variables ----------------------------------------------
print("Give generic names to variables")

input <- dplyr::rename(input,
                       "outcome" = tidyselect::all_of(opt$outcome),
                       "exposure" = tidyselect::all_of(opt$exposure))

cox_start <- gsub(opt$outcome, "outcome", cox_start)
cox_start <- gsub(opt$exposure, "exposure", cox_start)

cox_stop <- gsub(opt$outcome, "outcome", cox_stop)
cox_stop <- gsub(opt$exposure, "exposure", cox_stop)

# Specify study dates ----------------------------------------------------------
print("Specify study dates")

input$study_start <- as.Date(opt$study_start)
input$study_stop <- as.Date(opt$study_stop)

# Specify follow-up dates ------------------------------------------------------
print("Specify follow-up dates")

input$fup_start <- do.call(pmax,
                           c(input[, c("study_start", cox_start)], list(na.rm = TRUE)))

input$fup_stop <- do.call(pmin,
                          c(input[, c("study_stop", cox_stop)], list(na.rm = TRUE)))

input <- input[input$fup_stop >= input$fup_start, ]

# Remove exposures and outcomes outside follow-up ------------------------------
print("Remove exposures and outcomes outside follow-up")

input$exposure <- as.Date(ifelse(input$exposure<input$fup_start, NA, input$exposure), origin = "1970-01-01")
input$exposure <- as.Date(ifelse(input$exposure>input$fup_stop, NA, input$exposure), origin = "1970-01-01")

input$outcome <- as.Date(ifelse(input$outcome<input$fup_start,NA, input$outcome), origin = "1970-01-01")
input$outcome <- as.Date(ifelse(input$outcome>input$fup_stop,NA, input$outcome), origin = "1970-01-01")

# Make indicator variable for outcome status -----------------------------------
print("Make indicator variable for outcome status")

input$outcome_status <- input$outcome==input$fup_stop & !is.na(input$outcome) & !is.na(input$fup_stop)

# Sample control population ----------------------------------------------------

if (opt$ipw == TRUE) {
  print("Sample control population")
  input <- ipw_sample(df = input, controls_per_case = controls_per_case)
}

# Define episode labels --------------------------------------------------------
print("Define episode labels")

episode_labels <- data.frame(episode = 0:length(cut_points),
                             time_period = c("days_pre",paste0("days", c("0", cut_points[1:(length(cut_points)-1)]),"_", cut_points)),
                             stringsAsFactors = FALSE)

# Survival data setup ----------------------------------------------------------
print("Survival data setup")

data_surv <- survival_data_setup(df = input,
                                 cut_points = cut_points,
                                 episode_labels = episode_labels)

# Calculate events in each time period -----------------------------------------
print("Calculate events in each time period")

episode_info <- get_episode_info(df = data_surv,
                                 cut_points = cut_points,
                                 episode_labels = episode_labels)

# STOP if the total number of events is insufficient ---------------------------

if (sum(episode_info[episode_info$time_period != "days_pre", ]$N_events) < total_event_threshold) {
  stop(paste0("The total number of post-exposure events is less than the prespecified limit (", total_event_threshold, ")."))
}

# Collapse time periods if needed ----------------------------------------------

if (nrow(episode_info[which(episode_info$N_events == 0), ]) > episode_event_threshold) {

  ## Update survival data setup ------------------------------------------------
  print("Collapsed time periods: Update survival data setup to use")

  data_surv <- survival_data_setup(df = input,
                                   cut_points = cut_points_reduced)

  ## Update episode info -------------------------------------------------------
  print("Collapsed time periods: Update episode info")

  episode_info <- get_episode_info(df = data_surv,
                                   cut_points = cut_points_reduced)

}

# STOP if collapsing time periods still does not meet criteria -----------------

if (nrow(episode_info[which(episode_info$N_events == 0), ]) > episode_event_threshold) {
  stop(paste0("Despite collapsing time periods, there remains time periods with fewer events than the prespecified limit (", episode_event_threshold, ")."))
}

# Add strata information to data -----------------------------------------------
print("Add strata information to data")

data_strata <- data[, c("patient_id", strata)]
data_surv <- merge(data_surv, data_strata, by = "patient_id", all.x = TRUE)

# Add standard covariates (age and sex) ----------------------------------------
print("Add standard covariates (age and sex)")

data_covar <- data[, c("patient_id", opt$covariate_age, opt$covariate_sex)]

data_covar <- dplyr::rename(data_covar,
                            "cov_num_age" = tidyselect::all_of(opt$covariate_age),
                            "cov_cat_sex" = tidyselect::all_of(opt$covariate_sex))

data_surv <- merge(data_surv, data_covar, by = "patient_id", all.x = TRUE)

covariate_removed <- NULL
covariate_collapsed <- NULL

# If additional covariates are specified, add covariate data -------------------

if (!is.null(covariate_other)) {

  # Add covariate information to data ----------------------------------------
  print("Additional covariates specified: Add covariate information to data")

  data_covar <- data[, c("patient_id", covariate_other)]

  data_surv <- merge(data_surv, data_covar, by = "patient_id", all.x = TRUE)

  # Remove covariates with insufficient variation ----------------------------
  print("Additional covariates specified: Remove covariates with insufficient variation")

  tmp <- check_covariates(df = data_surv,
                          covariate_threshold = covariate_threshold)

  data_surv <- tmp$df
  covariate_removed <- tmp$covariate_removed
  covariate_collapsed <- tmp$covariate_collapsed
  rm(tmp)

}

# Perform Cox modelling --------------------------------------------------------
print("Perform Cox modelling")

data_surv[, c("study_start", "study_stop")] <- NULL

results <- fit_model(df = data_surv,
                     time_periods = episode_info[episode_info$time_period != "days_pre", ]$time_period,
                     covariates = covariate_other,
                     strata = strata,
                     age_spline = opt$age_spline,
                     covariate_removed = covariate_removed,
                     covariate_collapsed = covariate_collapsed)

# Merge results with number of events and person time --------------------------
print("Merge results with number of events and person time")

results <- merge(results,
                 episode_info[, c("time_period", "N_events", "person_time")],
                 by.x = "term",
                 by.y = "time_period",
                 all.x = TRUE)

tmp <- data.frame(term = "days_pre",
                  estimate = NA,
                  robust.se = NA,
                  robust.conf.low = NA,
                  robust.conf.high = NA,
                  se = NA,
                  model = c("mdl_age_sex", "mdl_max_adj"),
                  surv_formula = "",
                  covariate_removed = "",
                  covariate_collapsed = "",
                  N_events = episode_info[episode_info$time_period == "days_pre", ]$N_events,
                  person_time = episode_info[episode_info$time_period == "days_pre",]$person_time,
                  stringsAsFactors = FALSE)

results <- rbind(results, tmp)

# Tidy variables for outputting ------------------------------------------------
print("Tidy variables for outputting")

results$N_total <- sum(input$cox_weight)
results$N_exposed <- sum(input[!is.na(input$exposure), ]$cox_weight)

results$exposure <- exposure
results$outcome <- outcome

results <- results[order(results$model),
                   c("model", "exposure", "outcome", "term",
                     "estimate", "robust.conf.low", "robust.conf.high", "robust.se", "se",
                     "N_total", "N_exposed", "N_events", "person_time")]

# Save output ------------------------------------------------------------------
print("Save output")

write.csv(results, 
          file = paste0("output/",df_output), 
          row.names = FALSE)
