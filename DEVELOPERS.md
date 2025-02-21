# Notes for developers

## Arguments

This action's arguments are defined using the **optparse** package. This code is at the top of [_cox-ipw.R_](analysis/cox-ipw.R).

## README.md

_README.md_ is rendered from _README.Rmd_, simply install [just](https://just.systems/man/en/) and run

```bash
just render
```

Alternatively the rendering can be performed locally uusing the **rmarkdown** package in R. This can be done within R using

```r
rmarkdown::render("README.Rmd")
```

or from a shell using the following code.

```bash
R -e "rmarkdown::render('README.Rmd')"
```

## Environment

This is an R resuable action, run within the R container created from the [https://github.com/opensafely-core/r-docker](r-docker repository). The key points about the R container are as follows.

* Currently the `r:v2` image provides **R 4.4.2**.
* The container provides the packages, with their respective version numbers, listed in [v2/packages.md](https://github.com/opensafely-core/r-docker/blob/main/v2/packages.md).

For more information about reusable actions see [here](https://docs.opensafely.org/actions-reusable/).

## Test

Run the test defined in the _project.yaml_ with

```bash
just test
```
