# 04_models.R: primary survey-weighted logit, difference-in-differences form
source(here::here("R", "00_setup.R"))

primary <- readRDS(here::here("data", "processed", "analysis.rds"))

des <- primary |>
  as_survey_design(ids = psu, strata = ststr, weights = llcpwt, nest = TRUE)

# Model 1: no controls, state and year fixed effects
m1 <- svyglm(cost_barrier ~ treated_post + factor(state_fips) + factor(year),
             design = des, family = quasibinomial())

# Model 2: add individual controls
m2 <- svyglm(cost_barrier ~ treated_post + age_band + sex_cat + race_cat + educ_cat + employ_cat +
               factor(income_cat) + factor(state_fips) + factor(year),
             design = des, family = quasibinomial())

# Odds ratio on the treatment term
tidy_or <- function(m) {
  broom::tidy(m, conf.int = TRUE, exponentiate = TRUE) |>
    filter(term == "treated_post")
}
or_tab <- bind_rows(`No controls` = tidy_or(m1), `With controls` = tidy_or(m2), .id = "model")
print(or_tab)
readr::write_csv(or_tab, here::here("output", "tables", "primary_odds_ratios.csv"))

# Average marginal effect in percentage points (can be slow with many fixed effects)
# ame <- marginaleffects::avg_comparisons(m2, variables = "treated_post")
# print(ame)

saveRDS(list(m1 = m1, m2 = m2), here::here("output", "tables", "primary_models.rds"))
