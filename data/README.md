# Data folder

- `raw/`: BRFSS extract written by `R/01_download_data.R` (git-ignored).
- `processed/`: analysis-ready files written by `R/02_clean_data.R` (git-ignored).
- `external/expansion_dates.csv`: hand-entered. One row per state and DC (FIPS codes). Fill `expansion_date` (YYYY-MM-DD) from the KFF Medicaid expansion tracker. Leave blank for states that had not expanded by the end of 2019.

BRFSS is public-domain U.S. government data. Do not commit extracts.
