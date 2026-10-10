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
#     4. Run sql/03_limitation_timing.sql and save the result as
#        data_private/limitation_timing.csv
#
#   Both queries are deterministic, so steps 3 and 4 reproduce the dataset
#   exactly.
#
# USAGE
#   Rscript run_all.R
# ===========================================================================

proj <- normalizePath(".", winslash = "/")
options(warn = 1)

for (f in c("analytic.csv", "limitation_timing.csv"))
  if (!file.exists(file.path(proj, "data_private", f)))
    stop("data_private/", f, " not found. See the header of this file.")

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
  "R/40_limitation_timing.R",        # timing of orders within 24 h, Figure S2, Tables S6 and S7
  # --- outputs ------------------------------------------------------------
  "R/10_validate_palette.R",         # colour validation, reports only
  "R/35_flow_diagram.R",             # Figure S1, cohort derivation
  "R/15_build_panels.R",             # Figures 1 to 3, TIFF and vector PDF
  "R/11_submission_build.R",         # tables to Word
  "R/37_ama_references.R",           # AMA reference list from references.bib
  "R/25_build_full_docx.R",          # manuscript, Word
  "R/32_build_supplement_docx.R",    # supplement, Word
  "R/38_build_cover_letter.R",       # cover letter, Word
  "R/44_coi_form.R",                 # conflict of interest declaration, Word
  "R/42_docx_to_pdf.R",              # PDFs through Word, for reading
  "R/43_strobe_checklist.R"          # EQUATOR checklists with page numbers read from Manuscript.pdf, Word and PDF
)

t0 <- Sys.time()
for (step in steps) {
  cat("\n", strrep("=", 70), "\n", step, "\n", strrep("=", 70), "\n", sep = "")
  # each script runs in its own environment so its variables cannot collide
  # with this driver or with one another
  t <- system.time(source(file.path(proj, step), echo = FALSE,
                          local = new.env(parent = globalenv())))
  cat(sprintf("\n[%s done in %.1fs]\n", basename(step), t[["elapsed"]]))
}
cat(sprintf("\n\nall steps complete in %.1f minutes\n",
            as.numeric(difftime(Sys.time(), t0, units = "mins"))))

cat("\nartifacts:\n")
for (f in list.files(file.path(proj, "submission_jicm"), recursive = TRUE))
  cat("  submission_jicm/", f, "\n", sep = "")

cat("\nNOTE. Enable continuous line numbering in Word before upload:\n")
cat("  Layout > Line Numbers > Continuous\n")
