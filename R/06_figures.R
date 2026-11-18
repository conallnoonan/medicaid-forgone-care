# 06_figures.R: final figures
source(here::here("R", "00_setup.R"))

trend <- readr::read_csv(here::here("output", "tables", "trend_cost_barrier.csv"),
                         show_col_types = FALSE)
or_tab <- readr::read_csv(here::here("output", "tables", "primary_odds_ratios.csv"),
                          show_col_types = FALSE)

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
ggsave(here::here("output", "figures", "fig1_trend.png"), fig1, width = 8, height = 5, dpi = 300)

# Figure 2: odds ratios for the expansion effect
fig2 <- ggplot(or_tab, aes(estimate, model)) +
  geom_vline(xintercept = 1, linetype = "dashed") +
  geom_pointrange(aes(xmin = conf.low, xmax = conf.high)) +
  labs(title = "Association of expansion with cost-related forgone care",
       x = "Odds ratio (95% CI)", y = NULL) +
  theme_project()
ggsave(here::here("output", "figures", "fig2_odds_ratios.png"), fig2, width = 7, height = 3, dpi = 300)

message("Figures saved to output/figures/")
