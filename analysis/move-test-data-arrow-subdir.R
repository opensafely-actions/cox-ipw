R.utils::gunzip("dummy_tables/input.csv.gz")
if (!dir.exists("output/subdir")) dir.create("output/subdir") 
arrow::write_feather(readr::read_csv("dummy_tables/input.csv"), "output/subdir/input-5.arrow")
