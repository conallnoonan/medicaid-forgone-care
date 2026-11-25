# 01_download_data.R: pull BRFSS 2011-2019 with brfssdata
# Run from the project root. Output: data/raw/brfss_raw.rds

source(here::here("R", "00_setup.R"))

# Search before you read: names move across years
# brfss_vars("cost|income|coverage|health plan|sex")
# brfss_years()

# Optional: pre-fetch every year (about 29 MB each, cached after first download)
brfss_download(STUDY_YEARS)

# Core variables (a name that matches nothing raises an error)
core <- read_brfss(STUDY_YEARS, vars = CORE_VARS)

# Sex changes name by era: SEX (2011-2017), SEX1 (2018), SEXVAR (2019-2025). All three are in
# CORE_VARS and are coalesced into sex_cat in 02_clean_data.R.

saveRDS(core, here::here("data", "raw", "brfss_raw.rds"))
message("Saved ", nrow(core), " rows to data/raw/brfss_raw.rds")

# Citations for the write-up
print(brfss_citation(STUDY_YEARS))
