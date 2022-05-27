
<!-- README.md is generated from README.Rmd. 
Please edit that file and rerun in R `rmarkdown::render('README.Rmd')` -->

# cox-ipw

This is the code and configuration for `cox-ipw`, which is an R reusable
action for the OpenSAFELY framework.

The action:

-   Samples data and applies inverse probability weights
-   Performs survival data setup
-   Checks covariate variation
-   Fits the specified Cox model

## Usage

The arguments to the action are specified using the flags style (i.e.,
`--argname=argvalue`), the arguments are as follows.

    Usage: cox-ipw: [options]


    Options:
    --df_input=FILEPATH/FILENAME.CSV
    Input dataset filename, including filepath [default input.csv]

    --ipw=TRUE/FALSE
    Logical, indicating whether sampling and IPW are to be applied [default TRUE]

    --exposure=EXPOSURE_VARNAME
    Exposure variable name [default exp_date_covid19_confirmed]

    --outcome=OUTCOME_VARNAME
    Outcome variable name [default out_date_vte]

    --strata=VARNAME_1;VARNAME_2;...
    Semi-colon separated list of variable names to be included as strata in the
    regression model [default cov_cat_region]

    --covariate_sex=SEX_VARNAME
    Variable name for the sex covariate; specify argument as NULL to model without
    sex covariate [default cov_cat_sex]

    --covariate_age=AGE_VARNAME
    Variable name for the age covariate; specify argument as NULL to model without
    age covariate [default cov_num_age]

    --covariate_other=VARNAME_1;VARNAME_2;...
    Semi-colon separated list of other covariates to be included in the regression
    model; specify argument as NULL to run age, age squared, sex adjusted model
    only [default
    cov_cat_ethnicity;cov_num_consulation_rate;cov_bin_healthcare_worker;cov_bin_carehome_status]

    --covariate_protect=VARNAME_1;VARNAME_2;...
    Semi-colon separated list of protected covariates - if checks indicate one of
    these variables is to be removed from the regression model then an error is
    returned [default cov_cat_ethnicity;cov_cat_region;cov_cat_sex;cov_num_age]

    --cox_start=VARNAME_1;VARNAME_2;...
    Semi-colon separated list of variable names used to define start of patient
    follow-up or single variable if already defined [default pat_index_date]

    --cox_stop=VARNAME_1;VARNAME_2;...
    semicolon separated list of variable names used to define end of patient
    follow-up or single variable if already defined [default
    death_date;out_date_vte;vax_date_covid_1]

    --study_start=YYYY-MM-DD
    Study start date; this is used to remove events outside study dates [default
    2021-06-01]

    --study_stop=YYYY-MM-DD
    Study end date; this is used to remove events outside study dates [default
    2021-12-14]

    --cut_points=CUTPOINT_1;CUTPOINT_2
    Semi-colon separated list of cut points to be used to define time post exposure
    [default 28;197]

    --cut_points_reduced=CUTPOINT_1;CUTPOINT_2
    Semi-colon separated list of cut points to be used to define time post exposure
    if insufficient events prevent first choice [default 28;197]

    --controls_per_case=INTEGER
    Number of controls to retain per case in the analysis [default 10]

    --total_event_threshold=INTEGER
    Number of events that must be present for any model to run [default 50]

    --episode_event_threshold=INTEGER
    Number of events that must be present in a time period; if threshold is not
    met, time periods are collapsed [default 5]

    --covariate_threshold=INTEGER
    Minimum number of individuals per covariate level for covariate to be retained
    [default 2]

    --age_spline=TRUE/FALSE
    Logical, if age should be included in the model as a spline with knots at 0.1,
    0.5, 0.9 [default TRUE]

    --df_output=FILEPATH/FILENAME.CSV
    Filename with filepath for output data [default results.csv]

    --seed=INTEGER
    Random number generator seed passed to IPW sampling [default 137]

    -h, --help
    Show this help message and exit

This action can be specified in the `project.yaml` with its default
values as follows.

``` yaml
my_cox_ipw:
  run: cox-ipw:
```

This action can be run specifying arguments as follows (in YAML `>`
indicates to treat the subsequent nested lines as a single line).

``` yaml
my_cox_ipw:
  run: >
    cox-ipw: 
      --df_input=other_input_file.csv
      --df_output=other_output_file.csv
```

## Notes for developers

Please see [*DEVELOPERS.md*](DEVELOPERS.md).

For more information about reusable actions see
[here](https://docs.opensafely.org/actions-reusable/).

# About the OpenSAFELY framework

The OpenSAFELY framework is a Trusted Research Environment (TRE) for
electronic health records research in the NHS, with a focus on public
accountability and research quality.

Read more at [OpenSAFELY.org](https://opensafely.org).

# Licences

As standard, research projects have a MIT license.
