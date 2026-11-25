# 03_descriptives.R: weighted descriptives and pre-trend check
source(here::here("R", "00_setup.R"))

primary <- readRDS(here::here("data", "processed", "analysis.rds"))

# Table 1: sample composition by expansion status (weighted, categorical shares)
design <- primary |>
  as_survey_design(ids = psu, strata = ststr, weights = llcpwt, nest = TRUE)

table1 <- primary |> 
  group_by(ever_expanded) |> 
  summarise(n = n(),
            cost_barrier = weighted.mean(cost_barrier, llcpwt, na.rm = TRUE),
            has_coverage = weighted.mean(has_coverage, llcpwt, na.rm = TRUE))
print(table1)
readr::write_csv(table1, here::here("output", "tables", "table1_by_expansion.csv"))

# Trend by year and group (feeds the main figure)
trend <- primary |>
  filter(!is.na(cost_barrier)) |>
  mutate(group = if_else(ever_expanded, "Expansion states", "Non-expansion states")) |>
  group_split(year) |>
  purrr::map_dfr(function(d) {
    d |>
      as_survey_design(ids = psu, strata = ststr, weights = llcpwt, nest = TRUE) |>
      group_by(year, group) |>
      summarise(rate = survey_mean(cost_barrier, vartype = "ci"),
                n = unweighted(n()))
  }) |>
  ungroup()
print(trend)
readr::write_csv(trend, here::here("output", "tables", "trend_cost_barrier.csv"))

# Check: missingness in key variables
primary |>
  summarise(across(c(cost_barrier, has_coverage, sex_cat, race_cat, educ_cat, employ_cat),
                   ~ mean(is.na(.x)))) |>
  print()

