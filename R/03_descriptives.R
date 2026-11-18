# 03_descriptives.R: weighted descriptives and pre-trend check
source(here::here("R", "00_setup.R"))

primary <- readRDS(here::here("data", "processed", "analysis.rds"))

# Table 1: sample composition by expansion status (weighted, categorical shares)
design <- primary |>
  as_survey_design(ids = psu, strata = ststr, weights = llcpwt, nest = TRUE)

table1 <- design |>
  group_by(ever_expanded) |>
  summarise(n = unweighted(n()),
            cost_barrier = survey_mean(cost_barrier, vartype = "ci"),
            has_coverage = survey_mean(has_coverage, na.rm = TRUE, vartype = "ci"))
print(table1)
readr::write_csv(table1, here::here("output", "tables", "table1_by_expansion.csv"))

# Trend by year and group (feeds the main figure)
trend <- primary |>
  mutate(group = if_else(ever_expanded, "Expansion states", "Non-expansion states")) |>
  weighted_rate(cost_barrier, year, group)
print(trend)
readr::write_csv(trend, here::here("output", "tables", "trend_cost_barrier.csv"))

# Check: missingness in key variables
primary |>
  summarise(across(c(cost_barrier, has_coverage, race_cat, educ_cat, employ_cat),
                   ~ mean(is.na(.x)))) |>
  print()
