R.utils::gunzip("dummy_tables/input.csv.gz")
arrow::write_feather(readr::read_csv("dummy_tables/input.csv"), "output/input-4.arrow")
