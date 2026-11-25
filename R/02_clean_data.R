# 02_clean_data.R: recode, restrict sample, merge expansion dates
# Input:  data/raw/brfss_raw.rds, data/external/expansion_dates.csv
# Output: data/processed/analysis.rds, data/processed/analysis_all_incomes.rds

source(here::here("R", "00_setup.R"))

raw <- readRDS(here::here("data", "raw", "brfss_raw.rds")) |>
  janitor::clean_names()
# After clean_names: state, medcost, income2, hlthpln1, ageg5yr, racegr2, racegr3, educag,
# employ, employ1, sex, sex1, sexvar, llcpwt, ststr, psu, year. Check with names(raw).

exp_dates <- readr::read_csv(here::here("data", "external", "expansion_dates.csv"),
                             show_col_types = FALSE) |>
  mutate(expansion_date = as.Date(expansion_date),
         exp_year  = lubridate::year(expansion_date),
         exp_month = lubridate::month(expansion_date),
         # First calendar year fully exposed: expansions on Jan 1 count that year,
         # later dates count from the following year.
         first_full_year = if_else(exp_month == 1, exp_year, exp_year + 1L)) |>
  select(state_fips, state_abbr = state, expansion_date, first_full_year)

if (all(is.na(exp_dates$expansion_date))) {
  stop("data/external/expansion_dates.csv has no dates yet. Fill it in from the KFF tracker.")
}

analysis <- raw |>
  filter(as.integer(state) %in% exp_dates$state_fips) |>   # keep 50 states + DC; drop GU, PR, VI
  # Sample: adults 18-64 (_AGEG5YR bands 1-9; band 10 is 65-69), low-income proxy
  # (INCOME2 codes 1-4, under $25k)
  filter(ageg5yr %in% 1:9) |>
  mutate(
    cost_barrier = yn_to_binary(medcost),
    has_coverage = yn_to_binary(hlthpln1),
    income_cat   = if_else(income2 %in% 1:8, income2, NA_real_),
    low_income   = income_cat %in% 1:4,
    # Sex: three names, one per era (SEX 2011-2017, SEX1 2018, SEXVAR 2019-2025).
    # Verify 1 = male, 2 = female in each with brfss_labels() before trusting this.
    sex_raw      = dplyr::coalesce(as.numeric(sex), as.numeric(sex1), as.numeric(sexvar)),
    sex_cat      = factor(if_else(sex_raw %in% 1:2, sex_raw, NA_real_),
                          levels = 1:2, labels = c("Male", "Female")),
    # Race: five-level variable, _RACEGR2 (2011-2012) and _RACEGR3 (2013-2019).
    # Verify the codes match with brfss_labels() before trusting the labels.
    race_raw     = dplyr::coalesce(as.numeric(racegr3), as.numeric(racegr2)),
    race_cat     = factor(if_else(race_raw %in% 1:5, race_raw, NA_real_),
                          levels = 1:5,
                          labels = c("White non-Hispanic", "Black non-Hispanic",
                                     "Other non-Hispanic", "Multiracial non-Hispanic",
                                     "Hispanic")),
    educ_cat     = factor(if_else(educag %in% 1:4, educag, NA_real_)),
    # Employment: EMPLOY (2011-2012), EMPLOY1 (2013 onward)
    employ_raw   = dplyr::coalesce(as.numeric(employ1), as.numeric(employ)),
    employ_cat   = factor(if_else(employ_raw %in% 1:8, employ_raw, NA_real_)),
    age_band     = factor(ageg5yr),
    state_fips   = as.integer(state),
    # Year-specific strata: BRFSS strata/PSU codes repeat across years, so pooled designs
    # need the year in the stratum ID.
    strata_yr    = paste(year, ststr, sep = "_")
  ) |>
  left_join(exp_dates, by = "state_fips") |>
  mutate(
    ever_expanded = !is.na(first_full_year) & first_full_year <= max(STUDY_YEARS),
    # Time-varying treatment: 1 if the state's expansion was fully in effect that year
    treated_post  = as.integer(ever_expanded & year >= first_full_year),
    rel_year      = if_else(ever_expanded, year - first_full_year, NA_integer_)
  )

# DECISION POINT: early expanders (expansion before 2014, e.g., CA, CT, DC, MN, NJ, WA)
# Option A (default): keep them with their actual dates (staggered adoption).
# Option B: drop them for a cleaner 2014 vs. never-expanded comparison:
# analysis <- analysis |> filter(is.na(first_full_year) | first_full_year >= 2014)

# Primary analytic sample: low-income, outcome observed, design variables present
primary <- analysis |>
  filter(low_income, !is.na(cost_barrier), !is.na(llcpwt), !is.na(ststr), !is.na(psu))

saveRDS(analysis, here::here("data", "processed", "analysis_all_incomes.rds"))
saveRDS(primary,  here::here("data", "processed", "analysis.rds"))

message("All adults 18-64: ", nrow(analysis), " | low-income analytic sample: ", nrow(primary))
