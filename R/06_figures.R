# 06_figures.R: figures and result tables for the report
# Inputs:  output/tables/trend_cost_barrier.csv        (from 03)
#          output/tables/primary_odds_ratios.csv        (from 04)
#          output/tables/robustness_models.rds          (from 05)
#          data/processed/analysis.rds                  (from 02)
# Outputs: output/figures/fig1_trend.png               (original)
#          output/figures/fig2_odds_ratios.png          (original, survey-design intervals)
#          output/figures/fig2b_odds_ratios_clustered.png
#          output/figures/fig3_event_study.png
#          output/figures/fig4_effect_estimates.png
#          output/tables/headline_estimates.csv, event_study.csv, pretrend_test.csv,
#          table_sample_composition.csv   (all read by analysis/final_report.qmd)

source(here::here("R", "00_setup.R"))

tbl_dir <- here::here("output", "tables")
fig_dir <- here::here("output", "figures")

rob_path <- file.path(tbl_dir, "robustness_models.rds")
if (!file.exists(rob_path)) stop("Run R/05_robustness.R first (robustness_models.rds not found).")
rob <- readRDS(rob_path)

trend <- readr::read_csv(file.path(tbl_dir, "trend_cost_barrier.csv"), show_col_types = FALSE)
or_tab <- readr::read_csv(file.path(tbl_dir, "primary_odds_ratios.csv"), show_col_types = FALSE)
primary <- readRDS(here::here("data", "processed", "analysis.rds"))

# ---- helpers -----------------------------------------------------------------
# Coefficients and 95% CIs from a fixest model (uses the model's own state-clustered vcov)
fx_tidy <- function(m) {
  ci <- confint(m)
  tibble::tibble(term = names(coef(m)), estimate = unname(coef(m)),
                 conf_low = unname(ci[, 1]), conf_high = unname(ci[, 2]))
}
get_term <- function(m, which_term) {
  tt <- fx_tidy(m)
  tt[tt$term == which_term, ]
}
null_na <- function(x) if (is.null(x)) NA_real_ else as.numeric(x)

col_pre  <- "#1B6B8A"
col_post <- "#D98E04"

# ==============================================================================
# ORIGINAL FIGURES
# ==============================================================================

# Figure 1: weighted cost-barrier rate by year and group
# Most expansions took effect in 2014; adjust the line if your timing differs.
fig1 <- ggplot(trend, aes(year, rate, color = group, fill = group)) +
  geom_ribbon(aes(ymin = rate_low, ymax = rate_upp), alpha = 0.15, color = NA) +
  geom_line(linewidth = 1) +
  geom_vline(xintercept = 2014, linetype = "dashed") +
  scale_y_continuous(labels = scales::percent) +
  scale_x_continuous(breaks = 2011:2019) +
  labs(title = "Cost-related forgone care among low-income adults",
       subtitle = "Survey-weighted BRFSS, ages 18-64; dashed line marks 2014",
       x = NULL, y = "Could not see a doctor due to cost", color = NULL, fill = NULL) +
  theme_project() + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "fig1_trend.png"), fig1, width = 8, height = 5, dpi = 300)

# Figure 2: odds ratios for the expansion effect (survey-design intervals; see note below)
fig2 <- ggplot(or_tab, aes(estimate, model)) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high)) +
  labs(title = "Association of expansion with cost-related forgone care",
       x = "Odds ratio (95% CI)", y = NULL) +
  theme_project()
ggsave(file.path(fig_dir, "fig2_odds_ratios.png"), fig2, width = 7, height = 3, dpi = 300)

# ==============================================================================
# CLUSTERED LOGIT (state-clustered standard errors)
# ==============================================================================
# The survey-design logit in 04_models.R does not account for correlation within states,
# so its intervals are too narrow. This refits the controlled logit with state clustering.
m_cl <- fixest::feglm(
  cost_barrier ~ treated_post + age_band + sex_cat + race_cat + educ_cat + employ_cat |
    state_fips + year,
  data = primary, family = "logit", weights = ~llcpwt, cluster = ~state_fips
)
cl <- get_term(m_cl, "treated_post")

# Figure 2b: odds ratios with survey-design and state-clustered intervals
or_all <- dplyr::bind_rows(
  or_tab |>
    dplyr::transmute(model = paste0(model, ", survey-design CI"),
                     estimate, conf.low, conf.high),
  tibble::tibble(model = "With controls, state-clustered CI",
                 estimate = exp(cl$estimate),
                 conf.low = exp(cl$conf_low), conf.high = exp(cl$conf_high))
)
fig2b <- ggplot(or_all, aes(estimate, forcats::fct_rev(forcats::fct_inorder(model)))) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high), color = col_pre) +
  labs(title = "Odds ratio for Medicaid expansion in effect",
       subtitle = "Clustering by state widens the interval; the conclusion does not change",
       x = "Odds ratio (95% CI); values below 1 mean lower odds of forgone care",
       y = NULL) +
  theme_project()
ggsave(file.path(fig_dir, "fig2b_odds_ratios_clustered.png"), fig2b,
       width = 8, height = 3.2, dpi = 300)

# ==============================================================================
# EVENT STUDY
# ==============================================================================
es_tab <- fx_tidy(rob$es) |>
  dplyr::mutate(rel_year = as.integer(sub("^rel_year_es::", "", term))) |>
  dplyr::select(rel_year, estimate, conf_low, conf_high)
# Add the omitted reference period (-1), fixed at zero
es_tab <- dplyr::bind_rows(
  es_tab,
  tibble::tibble(rel_year = -1L, estimate = 0, conf_low = 0, conf_high = 0)
) |>
  dplyr::arrange(rel_year) |>
  dplyr::mutate(period = dplyr::if_else(rel_year < 0, "Before expansion", "After expansion"))

# Figure 3: event-study coefficients, in percentage points
fig3 <- ggplot(es_tab, aes(rel_year, estimate * 100, color = period)) +
  geom_hline(yintercept = 0, linetype = "dashed") +
  geom_vline(xintercept = -0.5, linetype = "dotted") +
  geom_pointrange(aes(ymin = conf_low * 100, ymax = conf_high * 100), linewidth = 0.6) +
  scale_color_manual(values = c("Before expansion" = col_pre, "After expansion" = col_post)) +
  scale_x_continuous(breaks = -4:4,
                     labels = c("-4 or\nearlier", "-3", "-2", "-1\n(reference)",
                                "0", "1", "2", "3", "4 or\nlater")) +
  labs(title = "Event study: cost-related forgone care around Medicaid expansion",
       subtitle = "Change in probability relative to the year before expansion (state-clustered 95% CI)",
       x = "Years since first full year of expansion",
       y = "Percentage points", color = NULL) +
  theme_project() + theme(legend.position = "bottom")
ggsave(file.path(fig_dir, "fig3_event_study.png"), fig3, width = 8, height = 5, dpi = 300)

# Joint test that the pre-expansion coefficients are zero
pre <- tryCatch(fixest::wald(rob$es, keep = "::-", print = FALSE), error = function(e) NULL)
pre_tab <- tibble::tibble(stat = null_na(pre$stat), p = null_na(pre$p),
                          df1 = null_na(pre$df1), df2 = null_na(pre$df2))

# ==============================================================================
# HEADLINE ESTIMATES ACROSS CHECKS
# ==============================================================================
mk_row <- function(id, label, m, type = "prob") {
  tt <- get_term(m, "treated_post")
  tibble::tibble(id = id, label = label, type = type, estimate = tt$estimate,
                 conf_low = tt$conf_low, conf_high = tt$conf_high, n = stats::nobs(m))
}
headline <- dplyr::bind_rows(
  mk_row("lpm_main",  "Main: cost barrier, low-income adults (LPM)", rob$lpm),
  mk_row("placebo",   "Placebo: cost barrier, higher-income adults", rob$placebo),
  mk_row("coverage",  "Mechanism: health coverage, low-income adults", rob$mech),
  tibble::tibble(id = "logit_clustered",
                 label = "Main: cost barrier, low-income adults (logit, odds ratio)",
                 type = "or", estimate = exp(cl$estimate),
                 conf_low = exp(cl$conf_low), conf_high = exp(cl$conf_high),
                 n = stats::nobs(m_cl))
)

# Figure 4: effect estimates across checks, in percentage points
chk <- headline |>
  dplyr::filter(type == "prob") |>
  dplyr::mutate(label = factor(label, levels = rev(label)))
fig4 <- ggplot(chk, aes(estimate * 100, label)) +
  geom_vline(xintercept = 0, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf_low * 100, xmax = conf_high * 100), color = col_pre) +
  labs(title = "Effect of Medicaid expansion across checks",
       subtitle = "Linear probability models with state and year fixed effects; state-clustered 95% CI",
       x = "Percentage points", y = NULL) +
  theme_project()
ggsave(file.path(fig_dir, "fig4_effect_estimates.png"), fig4, width = 9, height = 3.5, dpi = 300)

# ==============================================================================
# SAMPLE COMPOSITION (weighted shares, pooled across years; descriptive)
# ==============================================================================
# Labels follow standard BRFSS codebooks; confirm against the codebook for your years.
lab <- function(x, labels) factor(x, levels = seq_along(labels), labels = labels)
comp_data <- primary |>
  dplyr::mutate(
    `Age group` = lab(as.integer(as.character(age_band)),
                      c("18-24", "25-29", "30-34", "35-39", "40-44",
                        "45-49", "50-54", "55-59", "60-64")),
    Sex = sex_cat,
    `Race/ethnicity` = race_cat,
    Education = lab(as.integer(as.character(educ_cat)),
                    c("Did not finish high school", "High school graduate",
                      "Some college or technical school", "College graduate")),
    Employment = lab(as.integer(as.character(employ_cat)),
                     c("Employed for wages", "Self-employed", "Out of work 1+ year",
                       "Out of work under 1 year", "Homemaker", "Student",
                       "Retired", "Unable to work")),
    group = dplyr::if_else(ever_expanded, "Expansion states", "Non-expansion states")
  )

comp_vars <- c("Age group", "Sex", "Race/ethnicity", "Education", "Employment")
composition <- purrr::map_dfr(comp_vars, function(v) {
  comp_data |>
    dplyr::filter(!is.na(.data[[v]])) |>
    dplyr::group_by(group, level = .data[[v]]) |>
    dplyr::summarise(w = sum(llcpwt), .groups = "drop_last") |>
    dplyr::mutate(share = w / sum(w)) |>
    dplyr::ungroup() |>
    dplyr::mutate(level = as.character(level), variable = v)
}) |>
  dplyr::select(variable, level, group, share) |>
  tidyr::pivot_wider(names_from = group, values_from = share)

# ---- save tables for the report ------------------------------------------------
readr::write_csv(headline,    file.path(tbl_dir, "headline_estimates.csv"))
readr::write_csv(es_tab,      file.path(tbl_dir, "event_study.csv"))
readr::write_csv(pre_tab,     file.path(tbl_dir, "pretrend_test.csv"))
readr::write_csv(composition, file.path(tbl_dir, "table_sample_composition.csv"))

print(headline)
print(pre_tab)
message("Figures saved to output/figures/ and tables to output/tables/")
