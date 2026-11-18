# Run the full pipeline from the project root.
# Prerequisite: data/external/expansion_dates.csv is filled in.

scripts <- c(
  "R/00_setup.R",
  "R/01_download_data.R",
  "R/02_clean_data.R",
  "R/03_descriptives.R",
  "R/04_models.R",
  "R/05_robustness.R",
  "R/06_figures.R"
)

for (s in scripts) {
  message("Running ", s)
  source(s, echo = FALSE)
}

message("Done. Render the report with: quarto::quarto_render('analysis/final_report.qmd')")
