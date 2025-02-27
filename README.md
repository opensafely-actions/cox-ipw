
<!-- README.md is generated from README.Rmd. 
Please edit that file and run `just render` -->

# cox-ipw

This is the code and configuration for `cox-ipw`, which is an R reusable
action for the OpenSAFELY framework.

The action:

  - Samples data and applies inverse probability weights
  - Performs survival data setup
  - Checks covariate variation
  - Fits the specified Cox model

## Usage

### Options

The available options for the action can be specified using the flags
style (i.e., `--argname=argvalue`) or the config style (i.e., `config:
argname: argvalue`). The available options (using the flags style) are
as follows:

    Usage: cox-ipw:[version] [options]
    
    
    Options:
    --df_input=FILENAME.CSV
    Input dataset. csv, csv.gz, rds, arrow, or a feather filename (this is assumed
    to be within the output directory) [default input.csv]
    
    --ipw=TRUE/FALSE
    Logical, indicating whether sampling and IPW are to be applied [default TRUE]
    
    --sample_exposed=TRUE/FALSE
    Logical, indicating whether exposed individuals should be sampled [default
    FALSE]
    
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
    
    --controls_per_case=INTEGER
    Number of controls to retain per case in the analysis [default 20]
    
    --total_event_threshold=INTEGER
    Number of events that must be present for any model to run [default 50]
    
    --episode_event_threshold=INTEGER
    Number of events that must be present in a time period; if threshold is not
    met, time periods are collapsed [default 5]
    
    --covariate_threshold=INTEGER
    Minimum number of individuals per covariate level for covariate to be retained
    [default 5]
    
    --age_spline=TRUE/FALSE
    Logical, if age should be included in the model as a spline with knots at 0.1,
    0.5, 0.9 [default TRUE]
    
    --df_output=FILENAME.CSV
    Output data csv filename (this is assumed to be within the output directory)
    [default results.csv]
    
    --seed=INTEGER
    Random number generator seed passed to IPW sampling [default 137]
    
    --save_analysis_ready=TRUE/FALSE
    Logical, if analysis ready dataset for Stata should be saved [default FALSE]
    
    --run_analysis=TRUE/FALSE
    Logical, if analysis should be run [default TRUE]
    
    --config=
    Config parsed from the YAML
    
    -h, --help
    Show this help message and exit

### Action with options set to default

The action can be specified in the `project.yaml` with its options at
their default values as follows, where you should replace `[version]`
with the latest tag from
[here](https://github.com/opensafely-actions/cox-ipw/tags), e.g.,
`v0.0.1`. Note that no space is allowed between `cox-ipw:` and
`[version]`.

``` yaml
cox_ipw:
  run: cox-ipw:[version]
  needs:
  - generate-dataset
  outputs:
    moderately_sensitive:
      arguments: output/args-results.csv
      estimates: output/results.csv
```

### Action with options specified as arguments

The action ccan be specified in the `project.yaml` with its options
specified as arguments as follows, where you should replace `[version]`
with the latest tag from
[here](https://github.com/opensafely-actions/cox-ipw/tags), e.g.,
`v0.0.1`. Note in YAML `>` indicates that the subsequent nested lines
should be treated as a single line.

``` yaml
cox_ipw:
  run: >
    cox-ipw:[version]
      --df_output=results.csv
  needs:
  - generate-dataset
  outputs:
    moderately_sensitive:
      arguments: output/args-results.csv
      estimates: output/results.csv
```

### Actions with options specified using config

The action can be specified in the `project.yaml` with its options
specified using a `config:` key in the YAML as follows, where you should
replace `[version]` with the latest tag from
[here](https://github.com/opensafely-actions/cox-ipw/tags), e.g.,
`v0.0.1`. Note that options specified in the config overwrite those
specified at the command line.

``` yaml
  cox_ipw:
    run: cox-ipw:[version]
    config:
      df_output: results.csv
    needs:
    - generate-dataset
    outputs:
      moderately_sensitive:
        arguments: output/args-results.csv
        estimates: output/results.csv
```

### Recording of options

A csv file of argument values is automatically named with `args-`
prepended to the name of the output data csv file. Hence, both the
output data file and the file of argument values should be listed as
`moderately_sensitive` outputs as shown in the above example.

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
