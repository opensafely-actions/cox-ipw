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
