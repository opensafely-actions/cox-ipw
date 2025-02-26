render:
    docker run --platform linux/amd64 --rm -v "/$PWD:/workspace" ghcr.io/opensafely-core/r:v2 -e "rmarkdown::render('README.Rmd')"

test:
    opensafely run run_all -f
test-1:
    opensafely run cox_ipw -f
test-2:
    opensafely run cox_ipw_2 -f
