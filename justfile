render:
    docker run --platform linux/amd64 --rm -v "/$PWD:/workspace" ghcr.io/opensafely-core/r:v2 -e "rmarkdown::render('README.Rmd')"

test:
    opensafely run run_all -f
