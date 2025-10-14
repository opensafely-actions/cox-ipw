render:
    docker run --platform linux/amd64 --rm -v "/$PWD:/workspace" ghcr.io/opensafely-core/r:v2 -e "rmarkdown::render('README.Rmd')"

test:
    opensafely run run_all -f
test-1:
    opensafely run cox-ipw_using-args_input-csv -f
test-2:
    opensafely run cox-ipw_using_config-input_csv -f
test-3:
    opensafely run cox-ipw_using-args_input-csv-gz -f
test-4:
    opensafely run cox-ipw_using-args_input-arrow -f
test-5:
    opensafely run cox-ipw_using-args_input-arrow-subdir -f
test-6:
    opensafely run cox-ipw_covariate-other-filename -f
