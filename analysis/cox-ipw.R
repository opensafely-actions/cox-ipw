library(survival)

# Parameters -------------------------------------------------------------------

exposure = "exp_date_covid19_confirmed"
outcome = "out_date_vte"
cox_start = "pat_index_date"
cox_stop = "death_date;out_date_vte;vax_date_covid_1"
death_date = "death_date"
study_start = "2021-06-01"
study_stop = "2021-12-14"
cut_points = "28;197"
controls_per_case = 10

# Source functions -------------------------------------------------------------

source("analysis/fn-survival_data_setup.R")

# Seperate list arguments ------------------------------------------------------

cut_points <- as.numeric(stringr::str_split(as.vector(cut_points), ";")[[1]])
cox_start <- stringr::str_split(as.vector(cox_start), ";")[[1]]
cox_stop <- stringr::str_split(as.vector(cox_stop), ";")[[1]]

# Load data --------------------------------------------------------------------

input <- readr::read_csv("output/input.csv", show_col_types = FALSE)
input <- input[,!grepl("cov_",colnames(input))]
input <- input[,!grepl("sub_",colnames(input))]

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

input$fup_start <- do.call(pmax, c(input[,c("study_start",cox_start)], list(na.rm=TRUE)))
input$fup_stop <- do.call(pmin, c(input[,c("study_stop",cox_stop)], list(na.rm=TRUE)))
input <- input[input$fup_stop>=input$fup_start,]

# Remove exposures and outcomes outside follow-up ------------------------------

input$exposure <- as.Date(ifelse(input$exposure>=input$fup_start & input$exposure<=input$fup_stop,
                                 input$exposure, NA), 
                          origin = "1970-01-01")

input$outcome <- as.Date(ifelse(input$outcome>=input$fup_start & input$outcome<=input$fup_stop,
                                input$outcome, NA), 
                         origin = "1970-01-01")

# Make indicator variable for outcome status -----------------------------------

input$outcome_status <- !is.na(input$outcome)

# Sample control population ----------------------------------------------------

set.seed(1)

control_weight <- controls_per_case
cases <- input[input$outcome_status==1,]
controls <- input[input$outcome_status==0,]

if (nrow(cases)*controls_per_case<nrow(controls)) {
  controls <- controls[sample(nrow(controls),nrow(cases)*controls_per_case),]
} else {
  control_weight <- 1
}

input_sampled <- rbind(cases,controls)

# Survival data setup ----------------------------------------------------------

tmp <- survival_data_setup(df = input_sampled,
                           cut_points = cut_points)

