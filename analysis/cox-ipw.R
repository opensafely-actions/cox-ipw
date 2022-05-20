# # # # # # # # # # # # # # # # # # # # #
# This script:
# samples data and applies inverse probability weights
# performs survival data setup
# checks covariate variation
# fits Cox model
#
# The script must be accompanied by the following arguments
# `df_input` - path for input data
# `ipw` - specify as "TRUE" if sampling and IPW are to be applied
# `exposure` - exposure variable in the regression model
# `outcome` - outcome variable in the regression model
# `strata` - semicolon separated list of variables to be included as strata in the regression model
# `covariate_sex` - variable name for the sex covariate
# `covariate_age` - variable name for the age covariate
# `covariate_other` - semicolon separated list of other covariates to be included in the regression model; specify argument as "NULL" to run age, sex adjusted model only
# `cox_start` - semicolon separated list of variable used to define start of patient follow-up or single variable if already defined
# `cox_stop` -  semicolon separated list of variable used to define end of patient follow-up or single variable if already defined
# `study_start` - study start date; this is used to remove events outside study dates
# `study_stop` - study end date; this is used to remove events outside study dates
# `cut_points` - cut points to be used to define time post exposure
# `cut_points_reduced` - cut points to be used to define time post exposure if insufficient events prevent first choice
# `controls_per_case` - number of controls to retain per case in the analysis
# `total_event_threshold` - number of events that must be present for any model to run
# `episode_event_threshold` - number of events that must be present in a time period; if threshold is not met, time periods are collapsed
# `covariate_threshold` - minimum number of individuals per covariate level for covariate to be retained
# `age_spline` - specify as "TRUE" if age should be included in the model as a spline with knots at 0.1, 0.5, 0.9
# `df_output` - path for output data
# # # # # # # # # # # # # # # # # # # # #

# Import command line arguments ------------------------------------------------

args <- commandArgs(trailingOnly=TRUE)

if(length(args)==0) {
  df_input <- "output/input.csv"
  ipw <- "TRUE"
  exposure <- "exp_date_covid19_confirmed"
  outcome <- "out_date_vte"
  strata <- "cov_cat_region"
  covariate_sex <- "cov_cat_sex"
  covariate_age <- "cov_num_age"
  covariate_other <- "cov_cat_ethnicity;cov_bin_vte;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_carehome_status"
  cox_start <- "pat_index_date"
  cox_stop <-  "death_date;out_date_vte;vax_date_covid_1"
  study_start <- "2021-06-01"
  study_stop <- "2021-12-14"
  cut_points <- "28;197"
  cut_points_reduced <- "28;197"
  controls_per_case <- "10"
  total_event_threshold <- "50"
  episode_event_threshold <- "5"
  covariate_threshold <- "2"
  age_spline <- "TRUE"
  df_output <- "output/results.csv"
} else {
  df_input <- args[[1]]
  ipw <- args[[2]]
  exposure <- args[[3]]
  outcome <- args[[4]]
  strata <- args[[5]]
  covariate_sex <- args[[6]]
  covariate_age <- args[[7]]
  covariate_other <- args[[8]]
  cox_start <- args[[9]]
  cox_stop <- args[[10]]
  study_start <- args[[11]]
  study_stop <- args[[12]]
  cut_points <- args[[13]]
  cut_points_reduced <- args[[14]]
  controls_per_case <- args[[15]]
  total_event_threshold <- args[[16]]
  episode_event_threshold <- args[[17]]
  covariate_threshold <- args[[18]]
  age_spline <- args[[19]]
  df_output <- args[[20]]
}

# Import libraries -------------------------------------------------------------

library(survival)

# Import functions -------------------------------------------------------------

source("analysis/fn-ipw_sample.R")
source("analysis/fn-survival_data_setup.R")
source("analysis/fn-get_episode_info.R")
source("analysis/fn-check_covariates.R")
source("analysis/fn-fit_model.R")

# Separate list arguments ------------------------------------------------------
print("Separate list arguments")

for (i in c("strata","covariate_other","cut_points","cut_points_reduced","cox_start","cox_stop")){
  tmp <- get(i)
  if (tmp[1]=="NULL") {
    assign(i, NULL)
  } else {
    tmp <- stringr::str_split(as.vector(tmp), ";")[[1]]
    assign(i, tmp)
  }
}

# Make numeric arguments numeric -----------------------------------------------
print("Make numeric arguments numeric")

cut_points <- as.numeric(cut_points)
cut_points_reduced <- as.numeric(cut_points_reduced)
controls_per_case <- as.numeric(controls_per_case)
total_event_threshold <- as.numeric(total_event_threshold)
episode_event_threshold <- as.numeric(episode_event_threshold)
covariate_threshold <- as.numeric(covariate_threshold)

# Identify core variables ------------------------------------------------------
print("Identify core variables")

core <- colnames(readr::read_csv(df_input, show_col_types = FALSE))
core <- core[!grepl("cov_",core)]
core <- core[!grepl("sub_",core)]

# Load data --------------------------------------------------------------------
print("Load data")

input <- readr::read_csv(df_input,
                         col_select = c(core),
                         show_col_types = FALSE)

# Give generic names to variables ----------------------------------------------
print("Give generic names to variables")

input <- dplyr::rename(input, 
                       "outcome" = outcome,
                       "exposure" = exposure)

cox_start <- gsub(outcome,"outcome",cox_start)
cox_start <- gsub(exposure,"exposure",cox_start)

cox_stop <- gsub(outcome,"outcome",cox_stop)
cox_stop <- gsub(exposure,"exposure",cox_stop)

# Specify study dates ----------------------------------------------------------
print("Specify study dates")

input$study_start <- as.Date(study_start)
input$study_stop <- as.Date(study_stop)

# Specify follow-up dates ------------------------------------------------------
print("Specify follow-up dates")

input$fup_start <- do.call(pmax, 
                           c(input[,c("study_start",cox_start)], list(na.rm=TRUE)))

input$fup_stop <- do.call(pmin, 
                          c(input[,c("study_stop",cox_stop)], list(na.rm=TRUE)))

input <- input[input$fup_stop>=input$fup_start,]

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

if (ipw==TRUE) {
  print("Sample control population")
  input <- ipw_sample(df = input, controls_per_case = controls_per_case)
}

# Define episode labels --------------------------------------------------------
print("Define episode labels")

episode_labels <- data.frame(episode = 0:length(cut_points),
                             time_period = c("days_pre",paste0("days",c("0",cut_points[1:(length(cut_points)-1)]),"_",cut_points)),
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

if (sum(episode_info[episode_info$time_period!="days_pre",]$N_events)<total_event_threshold) {
  stop(paste0("The total number of post-exposure events is less than the prespecified limit (", total_event_threshold,")."))
}

# Collapse time periods if needed ----------------------------------------------

if (nrow(episode_info[which(episode_info$N_events==0),])>episode_event_threshold) {
  
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

if (nrow(episode_info[which(episode_info$N_events==0),])>episode_event_threshold) {
  stop(paste0("Despite collapsing time periods, there remains time periods with fewer events than the prespecified limit (", episode_event_threshold,")."))
}

# Add strata information to data -----------------------------------------------
print("Add strata information to data")

data_strata <- readr::read_csv(df_input,
                               col_select = c("patient_id",strata),
                               show_col_types = FALSE)

data_surv <- merge(data_surv, data_strata, by = "patient_id", all.x = TRUE)

# Add standard covariates (age and sex) ----------------------------------------
print("Add standard covariates (age and sex)")

data_covar <- readr::read_csv(df_input,
                              col_select = c("patient_id", covariate_age, covariate_sex),
                              show_col_types = FALSE)

data_covar <- dplyr::rename(data_covar,
                            "cov_num_age" = covariate_age,
                            "cov_cat_sex" = covariate_sex)

data_surv <- merge(data_surv, data_covar, by = "patient_id", all.x = TRUE)

covariate_removed <- NULL
covariate_collapsed <- NULL

# If additional covariates are specified, add covariate data -------------------

if (!is.null(covariate_other)) {
  
  # Add covariate information to data ----------------------------------------
  print("Additional covariates specified: Add covariate information to data")
  
  data_covar <- readr::read_csv(df_input,
                                col_select = c("patient_id",covariate_other),
                                show_col_types = FALSE)
  
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

data_surv[,c("study_start","study_stop")] <- NULL

results <- fit_model(df = data_surv, 
                     time_periods = episode_info[episode_info$time_period!="days_pre",]$time_period,
                     covariates = covariate_other, 
                     strata = strata, 
                     age_spline = age_spline,
                     covariate_removed = covariate_removed,
                     covariate_collapsed = covariate_collapsed)


# Merge results with number of events and person time --------------------------
print("Merge results with number of events and person time")

results <- merge(results, 
                 episode_info[,c("time_period","N_events","person_time")], 
                 by.x = "term",
                 by.y = "time_period", 
                 all.x = TRUE)

tmp <- data.frame(term = "days_pre",
                  estimate = NA,
                  robust.se = NA,
                  robust.conf.low = NA,
                  robust.conf.high = NA,
                  se = NA,
                  model = c("mdl_age_sex","mdl_max_adj"),
                  surv_formula = "",
                  covariate_removed = "",
                  covariate_collapsed = "",
                  N_events = episode_info[episode_info$time_period=="days_pre",]$N_events,
                  person_time = episode_info[episode_info$time_period=="days_pre",]$person_time,
                  stringsAsFactors = FALSE)

results <- rbind(results, tmp)

# Tidy variables for outputting ------------------------------------------------
print("Tidy variables for outputting")

results$N_total <- sum(input$cox_weight)
results$N_exposed <- sum(input[!is.na(input$exposure),]$cox_weight)

results$exposure <- exposure
results$outcome <- outcome

results <- results[order(results$model),
                   c("model", "exposure", "outcome", "term",
                     "estimate", "robust.conf.low", "robust.conf.high", "robust.se", "se",
                     "N_total", "N_exposed", "N_events", "person_time")]

# Save output ------------------------------------------------------------------
print("Save output")

write.csv(results, 
          file = df_output, 
          row.names = FALSE)