library(survival)

# Parameters -------------------------------------------------------------------

exposure = "exp_date_covid19_confirmed"
outcome = "out_date_vte"
strata = "cov_cat_region"
covariates = "cov_cat_sex;cov_num_age;cov_cat_ethnicity;cov_bin_vte;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_carehome_status"
subgroups = ""
cox_start = "pat_index_date"
cox_stop = "death_date;out_date_vte;vax_date_covid_1"
death_date = "death_date"
study_start = "2021-06-01"
study_stop = "2021-12-14"
cut_points = "28;197"
cut_points_reduced = "197"
controls_per_case = 10
total_event_threshold = 50
episode_event_threshold = 5
covariate_threshold = 2 # Remove covariates with less than 'covariate_threshold' people for each level of the binary covariate
age_spline = "TRUE"

# Source functions -------------------------------------------------------------

source("analysis/fn-ipw_sample.R")
source("analysis/fn-survival_data_setup.R")
source("analysis/fn-get_episode_info.R")
source("analysis/fn-check_covariates.R")
source("analysis/fn-fit_model.R")

# Separate list arguments ------------------------------------------------------

strata <- stringr::str_split(as.vector(strata), ";")[[1]]
covariates <- stringr::str_split(as.vector(covariates), ";")[[1]]
subgroups <- stringr::str_split(as.vector(subgroups), ";")[[1]]
cut_points <- as.numeric(stringr::str_split(as.vector(cut_points), ";")[[1]])
cut_points_reduced <- as.numeric(stringr::str_split(as.vector(cut_points_reduced), ";")[[1]])
cox_start <- stringr::str_split(as.vector(cox_start), ";")[[1]]
cox_stop <- stringr::str_split(as.vector(cox_stop), ";")[[1]]

# Identify core variables ------------------------------------------------------

variables <- colnames(readr::read_csv("output/input.csv", show_col_types = FALSE))

core <- variables
core <- core[!grepl("cov_",core)]
core <- core[!grepl("sub_",core)]

# Load data --------------------------------------------------------------------

input <- readr::read_csv("output/input.csv",
                         col_select = core,
                         show_col_types = FALSE)

# Give generic names to variables ----------------------------------------------

input <- dplyr::rename(input, 
                       "death_date" = death_date,
                       "outcome" = outcome,
                       "exposure" = exposure)

cox_start <- gsub(death_date,"death_date",cox_start)
cox_start <- gsub(outcome,"outcome",cox_start)
cox_start <- gsub(exposure,"exposure",cox_start)

cox_stop <- gsub(death_date,"death_date",cox_stop)
cox_stop <- gsub(outcome,"outcome",cox_stop)
cox_stop <- gsub(exposure,"exposure",cox_stop)

# Specify study dates ----------------------------------------------------------

input$study_start <- as.Date(study_start)
input$study_stop <- as.Date(study_stop)

# Specify follow-up dates ------------------------------------------------------

input$fup_start <- do.call(pmax, 
                           c(input[,c("study_start",cox_start)], list(na.rm=TRUE)))

input$fup_stop <- do.call(pmin, 
                          c(input[,c("study_stop",cox_stop)], list(na.rm=TRUE)))

input <- input[input$fup_stop>=input$fup_start,]

# Remove exposures and outcomes outside follow-up ------------------------------

input$exposure <- as.Date(ifelse(input$exposure>=input$fup_start & 
                                   input$exposure<=input$fup_stop,
                                 input$exposure, NA), 
                          origin = "1970-01-01")

input$outcome <- as.Date(ifelse(input$outcome>=input$fup_start & 
                                  input$outcome<=input$fup_stop,
                                input$outcome, NA), 
                         origin = "1970-01-01")

# Make indicator variable for outcome status -----------------------------------

input$outcome_status <- !is.na(input$outcome)

# Sample control population ----------------------------------------------------

input <- ipw_sample(df = input, controls_per_case = controls_per_case)

# Define episode labels --------------------------------------------------------

episode_labels <- data.frame(episode = 0:length(cut_points),
                             time_period = c("days_pre",paste0("days",c("0",cut_points[1:(length(cut_points)-1)]),"_",cut_points)),
                             stringsAsFactors = FALSE) 

# Survival data setup ----------------------------------------------------------

data_surv <- survival_data_setup(df = input, cut_points = cut_points, episode_labels = episode_labels)

# Calculate events in each time period -----------------------------------------

episode_info <- get_episode_info(df = data_surv, cut_points = cut_points, episode_labels = episode_labels)

# STOP if the total number of events is insufficient ---------------------------

if (sum(episode_info[episode_info$time_period!="days_pre",]$N_events)<total_event_threshold) {
  stop(paste0("The total number of post-exposure events is less than the prespecified limit (", total_event_threshold,")."))
}

# Collapse time periods if needed ----------------------------------------------

if (nrow(episode_info[which(episode_info$N_events==0),])>episode_event_threshold) {
  
  ## Update survival data setup ------------------------------------------------
  
  data_surv <- survival_data_setup(df = input, cut_points = cut_points_reduced)
  
  ## Update episode info -------------------------------------------------------
  
  episode_info <- get_episode_info(df = data_surv, cut_points = cut_points_reduced)
  
} 

# STOP if collapsing time periods still does not meet criteria -----------------

if (nrow(episode_info[which(episode_info$N_events==0),])>episode_event_threshold) {
  stop(paste0("Despite collapsing time periods, there remains time periods with fewer events than the prespecified limit (", episode_event_threshold,")."))
}

# Add covariate and strata information to data ---------------------------------

covar <- readr::read_csv("output/input.csv",
                         col_select = c("patient_id",covariates,strata),
                         show_col_types = FALSE)

data_surv <- merge(data_surv, covar, by = "patient_id", all.x = TRUE)

# Remove covariates with insufficient variation --------------------------------

tmp <- check_covariates(df = data_surv, covariate_threshold = covariate_threshold)

data_surv <- tmp$df
covariates_removed <- tmp$covariates_removed
covariates_collapsed <- tmp$covariates_collapsed
rm(tmp)

# Perform Cox modelling --------------------------------------------------------

results <- fit_model(data = data_surv, 
                     time_periods = episode_info$time_period,
                     covariates = setdiff(covariates, covariates_removed), 
                     strata = strata, 
                     age_spline = age_spline)
