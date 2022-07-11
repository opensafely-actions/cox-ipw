# Notes for developers

## Arguments

This action's arguments are defined using the **optparse** package. This code is at the top of [_cox-ipw.R_](analysis/cox-ipw.R).

## README.md

_README.md_ is rendered from _README.Rmd_ using the **rmarkdown** package in R. This can be done within R using

```r
rmarkdown::render("README.Rmd")
```

or from a shell using the following code.

```bash
R -e "rmarkdown::render('README.Rmd')"
```

## Environment

This is an R resuable action, run within the R container created from the [https://github.com/opensafely-core/r-docker]() repository. The key points about the R container are as follows.

* Currently the container provides **R 4.0.2**.
* The container provides the packages, with their respective version numbers, listed in [_packages.csv_](packages.csv) which is a copy of [_packages.csv_](https://github.com/opensafely-core/r-docker/blob/master/packages.csv) in the R image repository.

For more information about reusable actions see [here](https://docs.opensafely.org/actions-reusable/).
