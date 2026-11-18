# Medicaid expansion and cost-related forgone care

Did states that expanded Medicaid under the ACA see a larger drop in the share of low-income adults who skipped needed care because of cost, compared with non-expansion states?

Final project for a graduate intro to applied social statistics course (R). Design: survey-weighted logistic regression in a difference-in-differences framework using BRFSS 2011-2019.

The full written plan is in [`docs/project_plan.html`](docs/project_plan.html).

## Repository layout

```
medicaid-forgone-care/
├── README.md
├── .gitignore
├── medicaid-forgone-care.Rproj
├── run_all.R                  # runs the whole pipeline in order
├── R/
│   ├── 00_setup.R             # install and load packages, set options
│   ├── helpers.R              # shared functions and constants
│   ├── 01_download_data.R     # pull BRFSS with brfssdata
│   ├── 02_clean_data.R        # recode, restrict sample, merge expansion dates
│   ├── 03_descriptives.R      # weighted tables and trend checks
│   ├── 04_models.R            # primary survey-weighted logit DiD
│   ├── 05_robustness.R        # LPM, placebo, mechanism, event study
│   └── 06_figures.R           # final figures
├── analysis/
│   └── final_report.qmd       # Quarto write-up
├── data/
│   ├── raw/                   # BRFSS extract (not committed)
│   ├── processed/             # analysis-ready data (not committed)
│   └── external/
│       └── expansion_dates.csv   # YOU FILL THIS IN (see below)
├── output/
│   ├── figures/
│   └── tables/
└── docs/
    └── project_plan.html
```

## Setup

1. Open `medicaid-forgone-care.Rproj` in RStudio.
2. Run `source("R/00_setup.R")` to install and load packages (consider `renv::init()` afterward to lock versions).
3. Fill in `data/external/expansion_dates.csv` (below).
4. Run `source("run_all.R")`, or run each script in `R/` in order.

## Required manual step: expansion dates

`data/external/expansion_dates.csv` lists every state and DC by FIPS code with an empty `expansion_date` column. Fill it from the KFF Medicaid expansion tracker (date the expansion took effect, `YYYY-MM-DD`). Leave blank for states that had not expanded by the end of 2019. Add early expanders (for example, CA, CT, DC, MN, NJ, WA expanded before 2014) with their actual dates and decide how to treat them (see `R/02_clean_data.R`).

## Data

| Source | Use | Where |
|---|---|---|
| BRFSS (CDC), via the `brfssdata` R package | Outcome, income, coverage, demographics, survey design | Downloaded by `R/01_download_data.R` and cached locally |
| KFF Medicaid expansion tracker | Treatment timing | `data/external/expansion_dates.csv` |
| ACS state covariates (optional) | State-level controls | `tidycensus`, add to `R/02_clean_data.R` |

Cite the data: run `brfssdata::brfss_citation(2011:2019)`, and cite the CDC BRFSS as well.

## Key analytic decisions (edit as the project evolves)

- Sample: adults ages 18-64 (BRFSS 5-year age bands cannot isolate age 19), income under $25,000 as a proxy for near 138% of poverty.
- Years: 2011-2019 (comparable weighting; avoids pandemic-era changes).
- Outcome: could not see a doctor in the past 12 months because of cost (`MEDCOST`).
- Treatment: state expansion status by year (time-varying), with state and year fixed effects.
- Survey design: `_LLCPWT`, `_STSTR`, `_PSU`.

## Reproducibility

- Raw and processed data are git-ignored; scripts regenerate them.
- Run scripts from the project root (the `.Rproj` handles this).
- Record package versions with `renv` before submitting.
