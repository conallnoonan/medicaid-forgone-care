# 00_setup.R: install (if needed) and load packages

pkgs <- c(
  "tidyverse",       # wrangling and plotting
  "janitor",         # clean_names()
  "haven",           # optional: labelled data
  "survey", "srvyr", # design-based estimation
  "fixest",          # fixed effects, clustered SEs, event studies
  "marginaleffects", # predicted probabilities, marginal effects
  "broom",           # tidy model output
  "modelsummary",    # regression tables
  "patchwork", "scales",
  "here",
  "quarto"
)

missing <- setdiff(pkgs, rownames(installed.packages()))
if (length(missing)) install.packages(missing)

# brfssdata: CRAN release, or GitHub development version
if (!requireNamespace("brfssdata", quietly = TRUE)) {
  tryCatch(
    install.packages("brfssdata"),
    error = function(e) {
      install.packages("pak")
      pak::pak("muntasirmasum/brfssdata")
    }
  )
}

suppressPackageStartupMessages({
  library(tidyverse)
  library(janitor)
  library(survey)
  library(srvyr)
  library(fixest)
  library(brfssdata)
  library(here)
})

# Treat single-PSU strata sensibly in survey designs
options(survey.lonely.psu = "adjust")

source(here("R", "helpers.R"))
