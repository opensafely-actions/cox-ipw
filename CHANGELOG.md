# [v0.0.36](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.36)

- Positively code core variables to avoid variable name conflicts.

# [v0.0.35](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.35)

- Allow there to be no pre-exposure events.

# [v0.0.34](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.34)

- Specify analysis ready dataset name rather than deriving the name from df_input. This allows df_input to be read from a subdirectory and the analysis ready dataset to be saved to a subdirectory.
- Correct the model formula specification when no strata are provided.
- Check that there is at least one event before trying to summarise the events per episode.

# [v0.0.33](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.33)

- Fix potential race condition in tagging GitHub Actions workflow.

# [v0.0.32](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.32)

- Bump the [mathieudutour/github-tag-action](https://github.com/mathieudutour/github-tag-action) GitHub Action to version 6.2.
- Switch to using the new r:v2 image.
- Add a justfile with recipe to perform the rendering of README.Rmd to produce README.md.
- The test defined in _project.yaml_ now uses saved dummy data instead of using cohortextractor or ehrql.
- Add ability to specify options using a `config:` key in the YAML.
- Allow the input file to additionally be .csv.gz, .arrow, or .feather files (in addition to .csv and .rds).

# [v0.0.31](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.31)

- Save analysis ready now uses `foreign::write.dta()` so that output can be read directly into Stata.

# [v0.0.30](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.30)

- Add an observation warning that returns a message if the number of observations provided to the model differs from the number of observations used by the model.

# [v0.0.29](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.29)

- The r image has been reverted to use the old version of the **readr** package. Hence, the `path` argument is now used again in the calls to `readr::write_csv()`.
- Add a cron job to the GitHub Action workflow which runs the cox-ipw GitHub Actions test workflow once per week.
- Ran `opensafely codelists update` to update the codelists in this repo.

# [v0.0.28](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.28)

- Due to the upgrading of the **readr** package (from version 1.3.1 to 2.1.4) in the [r](https://github.com/opensafely-core/r-docker) image on 22/09/2023, update calls to `readr::write_csv()` to use the `file` argument instead of the deprecated `path` argument.
- In the GitHub Actions workflows update the actions/checkout action from the v3 to the v4 sliding tag as per the [README](https://github.com/actions/checkout/#readme)
- Refine the workflows in the test action

# [v0.0.27](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.27)

- Shorten analysis ready output file name further

# [v0.0.26](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.26)

- Shorten analysis ready output file name 

# [v0.0.25](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.25)

- Update follow-up end criteria to include outcome

# [v0.0.24](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.24)

- Save the anaylysis ready dataset in csv.gz format instead of rds

# [v0.0.23](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.23)

- Specify analysis ready data set as output in YAML
- Add option to not run analysis (i.e., just save analysis ready dataset and stop)

# [v0.0.22](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.22)

- Fix bug that occurred with episode labels if only one post-exposure time point was specified

# [v0.0.21](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.21)

- Various improvements to the code to fix linting warnings

# [v0.0.20](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.20)

- Fix weighting bug for models

# [v0.0.19](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.19)

- Tidy naming in ipw sample script

# [v0.0.18](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.18)

- Add origin for data converted to date format

# [v0.0.17](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.17)

- Further fix for the sampling bug for cases where the number of controls to be sampled is greater than the number available

# [v0.0.16](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.16)

- Collapse region from 9 into 3 regions when covariate thresholds are not met
- Fix sampling bug where exposed controls were being incorrectly handled
- Fix person time bug where Cox weights were not being appropriately applied

# [v0.0.15](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.15)

- Update `mathieudutour/github-tag-action` GitHub Action to v6.1 tag
- Set cox weights to one to calculate person-time in each episode if cox weights not otherwise provided
- Stop code removing strata variables and add warning for potentially low counts

# [v0.0.14](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.14)

- Fix typo that caused fatal error for fn-check_covariates.R
- In GitHub Actions workflows bump `actions/checkout` GitHub Action to v3 sliding tag

# [v0.0.13](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.13)

- Add option to sample exposed individuals. If not sampled, all exposed individuals are included regardless of case/control status.

# [v0.0.12](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.12)

- Print output to log at each stage of `fn-check_covariates.R` for better debugging
- For structured variable names, impose class (e.g., make variables containing '_date' into dates)

# [v0.0.11](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.11)

- Print output to log at each stage for better debugging

# [v0.0.10](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.10)

- Add `cox-ipw` version number to output
- Use Breslow method for ties in Cox model
- Add option to save analysis ready dataset
- Print `survival::tmerge()` inputs to log
- Make `outcome_time_median` include time from previous episodes

# [v0.0.9](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.9)

- Fix robust SEs so they are only applied when sampling is on
- Clarify ln(hr) versus hr
- Add code to calculate median time to outcome for each time period
- Add support for '.rds' as an input file

# [v0.0.8](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.8)

- Remove protected covariate feature due to lack of generalizability

# [v0.0.7](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.7)

- Fixed outcomes per episode calculation

# [v0.0.6](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.6)

- Added median person-time per episode to output
- Added CHANGELOG.md

# [v0.0.5](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.5)

- Added reporting of protected covariates that stop model running
- Updated defaults
- Updated how args are recorded
- Added error capturing so jobs always complete
- Increased population size so model runs on test data
- Tidied formatting

# [v0.0.4](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.4)

- Updated test action

# [v0.0.3](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.3)

- Removed automatic cut points

# [v0.0.2](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.2)

- Improved documentation

# [v0.0.1](https://github.com/opensafely-actions/cox-ipw/releases/tag/v0.0.1)
