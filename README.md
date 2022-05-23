
<!-- README.md is generated from README.Rmd. 
Please edit that file and rerun in R `rmarkdown::render('README.Rmd')` -->

# cox-ipw

This is the code and configuration for cox-ipw, which is an R action for
the OpenSAFELY framework.

The action:

-   Samples data and applies inverse probability weights
-   Performs survival data setup
-   Checks covariate variation
-   Fits the specified Cox model

## Usage

The arguments to the action are specified using the long flags style
(i.e., `--argname=argvalue`), the arguments are as follows.

    Usage: cox-ipw: [options]


    Options:
    --df_input=DF_INPUT
    Input dataset filename, including filepath [default input.csv]

    --ipw=IPW
    Logical, indicating whether sampling and IPW are to be applied [default TRUE]

    --exposure=EXPOSURE
    Exposure variable name [default exp_date_covid19_confirmed]

    --outcome=OUTCOME
    Outcome variable name [default out_date_vte]

    --strata=STRATA
    Semi-colon separated list of variable names to be included as strata in the
    regression model [default cov_cat_region]

    --covariate_sex=COVARIATE_SEX
    Variable name for the sex covariate [default cov_cat_sex]

    --covariate_age=COVARIATE_AGE
    Variable name for the age covariate [default cov_num_age]

    --covariate_other=COVARIATE_OTHER
    Semi-colon separated list of other covariates to be included in the regression
    model; specify argument as NULL to run age, sex adjusted model only [default
    cov_cat_ethnicity;cov_bin_vte;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_carehome_status]

    --cox_start=COX_START
    Semi-colon separated list of variable used to define start of patient follow-up
    or single variable if already defined [default pat_index_date]

    --cox_stop=COX_STOP
    semicolon separated list of variable used to define end of patient follow-up or
    single variable if already defined [default
    death_date;out_date_vte;vax_date_covid_1]

    --study_start=STUDY_START
    Study start date; this is used to remove events outside study dates [default
    2021-06-01]

    --study_stop=STUDY_STOP
    Study end date; this is used to remove events outside study dates [default
    2021-12-14]

    --cut_points=CUT_POINTS
    Semi-colon separated list of cut points to be used to define time post exposure
    [default 28;197]

    --cut_points_reduced=CUT_POINTS_REDUCED
    Semi-colon separated list of cut points to be used to define time post exposure
    if insufficient events prevent first choice [default 28;197]

    --controls_per_case=CONTROLS_PER_CASE
    Number of controls to retain per case in the analysis [default 10]

    --total_event_threshold=TOTAL_EVENT_THRESHOLD
    Number of events that must be present for any model to run [default 50]

    --episode_event_threshold=EPISODE_EVENT_THRESHOLD
    Number of events that must be present in a time period; if threshold is not
    met, time periods are collapsed [default 5]

    --covariate_threshold=COVARIATE_THRESHOLD
    Minimum number of individuals per covariate level for covariate to be retained
    [default 2]

    --age_spline=AGE_SPLINE
    Logical, if age should be included in the model as a spline with knots at 0.1,
    0.5, 0.9 [default TRUE]

    --df_output=DF_OUTPUT
    Filename with filepath for output data [default results.csv]

    -h, --help
    Show this help message and exit

This action can be specified in the `project.yaml` with its default
values as follows.

``` yaml
my_cox_ipw:
  run: cox-ipw:
```

This action can be run specifying arguments as follows (`>` indicates to
treat the subsequent nested lines as a single line.)

``` yaml
my_cox_ipw:
  run: >
    cox-ipw: 
      --df_input=other_input_file.csv
      --df_output=other_output_file.csv
```

## Notes for developers

Please see [*DEVELOPERS.md*](DEVELOPERS.md).

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for
electronic health records research in the NHS, with a focus on public
accountability and research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences

As standard, research projects have a MIT license.
