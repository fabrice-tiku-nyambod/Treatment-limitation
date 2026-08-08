# ===========================================================================
# run_all.R
#
# Reproduces the entire analysis and rebuilds every submission artifact.
#
# PREREQUISITE
#   data_private/analytic.csv must exist. It is not in this repository and
#   cannot be, because eICU-CRD is released under a PhysioNet data use
#   agreement that prohibits redistribution. To create it:
#
#     1. Complete CITI human subjects research training and sign the DUA at
#        https://physionet.org/content/eicu-crd/2.0/
#     2. Request BigQuery access on the same page
#     3. Run sql/02_build_analytic_dataset.sql and save the result as
#        data_private/analytic.csv
#
#   The query is deterministic, so step 3 reproduces the dataset exactly.
#
# USAGE
#   Rscript run_all.R
# ===========================================================================

proj <- normalizePath(".", winslash = "/")
options(warn = 1)

csv <- file.path(proj, "data_private", "analytic.csv")
if (!file.exists(csv))
  stop("data_private/analytic.csv not found. See the header of this file.")

need <- c("data.table","ggplot2","patchwork","lme4","sandwich","lmtest","pROC",
          "cobalt","WeightIt","officer","flextable","magick","colorspace",
          "scales","httr","jsonlite","pdftools","tinytex")
miss <- setdiff(need, rownames(installed.packages()))
if (length(miss)) {
  message("installing: ", paste(miss, collapse = ", "))
  install.packages(miss, repos = "https://cloud.r-project.org")
}

steps <- c(
  # --- analysis -----------------------------------------------------------
  "R/01_load_validate.R",            # load, verify against the BigQuery figures
  "R/02_recalibration_models.R",     # primary logistic recalibration
  "R/17_table2_overall.R",           # calibration by limitation stratum
  "R/03_calibration_hospital_timing.R", # ICI, unit variation, timing
  "R/05_discrimination.R",           # held out AUC and Brier
  "R/06_hospital_reranking.R",       # ranking with and without limitation
  "R/07_practice_vs_casemix.R",      # practice or case mix, and which remedy
  "R/14_cobalt_balance.R",           # inverse probability weighting, balance
  # --- outputs ------------------------------------------------------------
  "R/10_validate_palette.R",         # colour validation, reports only
  "R/35_flow_diagram.R",             # Figure S1, cohort derivation
  "R/15_build_panels.R",             # Figures 1 to 3, TIFF and vector PDF
  "R/11_submission_build.R",         # tables to Word
  "R/25_build_full_docx.R",          # manuscript, Word
  "R/32_build_supplement_docx.R",    # supplement, Word
  "R/24_compile_latex.R"             # manuscript PDF via TinyTeX
)

t0 <- Sys.time()
for (s in steps) {
  cat("\n", strrep("=", 70), "\n", s, "\n", strrep("=", 70), "\n", sep = "")
  t <- system.time(source(file.path(proj, s), echo = FALSE))
  cat(sprintf("\n[%s done in %.1fs]\n", basename(s), t[["elapsed"]]))
}
cat(sprintf("\n\nall steps complete in %.1f minutes\n",
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))

cat("\nartifacts:\n")
for (f in list.files(file.path(proj, "submission"), recursive = TRUE))
  cat("  submission/", f, "\n", sep = "")

cat("\nNOTE. The Word manuscript is written in British spelling by the builder\n")
cat("and converted afterwards. Run:\n")
cat("  powershell -File R/maintenance/27_americanize_docx.ps1\n")
cat("  powershell -File R/maintenance/34_number_headings.ps1\n")
cat("Both edit the document in place and preserve manual formatting.\n")
