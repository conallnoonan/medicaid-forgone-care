# 05_robustness.R: LPM, placebo group, mechanism, event study
source(here::here("R", "00_setup.R"))

primary <- readRDS(here::here("data", "processed", "analysis.rds"))
all_inc <- readRDS(here::here("data", "processed", "analysis_all_incomes.rds"))

# 1. Linear probability model, state-clustered SEs (coefficient is in probability units)
lpm <- feols(cost_barrier ~ treated_post + age_band + race_cat + educ_cat + employ_cat |
               state_fips + year,
             data = primary, weights = ~llcpwt, cluster = ~state_fips)
print(summary(lpm))

# 2. Placebo: higher-income adults (INCOME2 codes 7-8, $50k+) should show little effect
placebo_data <- all_inc |>
  filter(income_cat %in% 7:8, !is.na(cost_barrier), !is.na(llcpwt))
placebo <- feols(cost_barrier ~ treated_post | state_fips + year,
                 data = placebo_data, weights = ~llcpwt, cluster = ~state_fips)
print(summary(placebo))

# 3. Mechanism: effect on health coverage among low-income adults
mech_data <- primary |> filter(!is.na(has_coverage))
mech <- feols(has_coverage ~ treated_post | state_fips + year,
              data = mech_data, weights = ~llcpwt, cluster = ~state_fips)
print(summary(mech))

# 4. Event study (leads and lags relative to first full exposure year)
# Never-expanded states get the reference period so they serve as controls.
es_data <- primary |>
  mutate(rel_year_es = case_when(
    is.na(rel_year) ~ -1L,
    TRUE ~ pmax(pmin(rel_year, 4L), -4L)   # bin tails
  ))
es <- feols(cost_barrier ~ i(rel_year_es, ref = -1) | state_fips + year,
            data = es_data, weights = ~llcpwt, cluster = ~state_fips)
print(summary(es))
iplot(es, main = "Event study: cost barrier (LPM)")

# 5. Extension (optional): staggered-adoption estimator
# library(did)  # Callaway and Sant'Anna; needs a state-year panel with group = first_full_year

saveRDS(list(lpm = lpm, placebo = placebo, mech = mech, es = es),
        here::here("output", "tables", "robustness_models.rds"))
