# helpers.R: constants and shared functions

STUDY_YEARS <- 2011:2019

# BRFSS variables (CDC canonical names). Verify with brfss_vars() before running.
CORE_VARS <- c(
  "_STATE",   # state FIPS
  "MEDCOST",  # could not see doctor in past 12 months due to cost
  "INCOME2",  # income category
  "HLTHPLN1", # any health coverage
  "_AGEG5YR", # age in 5-year bands
  "_RACEGR2", "_RACEGR3",  # five-level race/ethnicity: _RACEGR2 2011-2012, _RACEGR3 2013-2019
  "_EDUCAG",  # education category
  "EMPLOY1", "EMPLOY",  # employment: EMPLOY 2011-2012, EMPLOY1 2013 onward
  "SEX", "SEX1", "SEXVAR",  # respondent sex: SEX 2011-2017, SEX1 2018, SEXVAR 2019-2025
  "_LLCPWT", "_STSTR", "_PSU"  # survey design
)

# Recode BRFSS yes/no (1 = yes, 2 = no, 7/9 = don't know/refused) to 1/0/NA
yn_to_binary <- function(x) {
  dplyr::case_when(x == 1 ~ 1L, x == 2 ~ 0L, TRUE ~ NA_integer_)
}

# Weighted proportion by group using a survey design
weighted_rate <- function(df, outcome, ...) {
  df |>
    filter(!is.na({{ outcome }})) |>
    as_survey_design(ids = psu, strata = ststr, weights = llcpwt, nest = TRUE) |>
    group_by(...) |>
    summarise(rate = survey_mean({{ outcome }}, vartype = "ci"),
              n = unweighted(n()),
              .groups = "drop")
}

theme_project <- function() {
  theme_minimal(base_size = 12) +
    theme(panel.grid.minor = element_blank(),
          plot.title = element_text(face = "bold"))
}
