# ---------------------------------------------------------------------------
# 11_submission_build.R
#
# Builds the submission package.
#   submission/figures/       TIFF, 600 dpi, LZW, validated palette
#   submission/tables/        Word tables, fixed widths, journal formatting
#   submission/supplementary/ supplementary tables
#
# Palette: mako [0.05, 0.70], validated in 10_validate_palette.R against a
# white print surface. Normal-vision dE 17.6, CVD dE 15.8, contrast 2.52,
# monotonic lightness for grayscale printing.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(officer); library(flextable)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
for (p in c(sub, file.path(sub, "figures"), file.path(sub, "tables"),
            file.path(sub, "supplementary"))) dir.create(p, showWarnings = FALSE)

PAL <- c("Full therapy"       = "#00B6B3",
         "DNR type"           = "#007AA5",
         "Partial withdrawal" = "#433864",
         "Comfort measures"   = "#200F1D")
INK   <- "#0b0b0b"; MUTED <- "#898781"; GRID <- "#e1e0d9"; ACCENT <- "#C81560"

theme_j <- function(base = 9) {
  theme_minimal(base_size = base, base_family = "sans") +
    theme(panel.grid.minor = element_blank(),
          panel.grid.major = element_line(color = GRID, linewidth = .25),
          axis.text  = element_text(color = MUTED, size = base - 1),
          axis.title = element_text(color = INK, size = base),
          legend.title = element_text(color = INK, size = base),
          legend.text  = element_text(color = INK, size = base - 1),
          strip.text = element_text(color = INK, size = base, face = "bold"),
          legend.position = "bottom", legend.key.height = unit(.35, "cm"))
}
tif <- function(p, name, w, h) {
  f <- file.path(sub, "figures", paste0(name, ".tiff"))
  ggsave(f, p, device = "tiff", width = w, height = h, units = "in",
         dpi = 600, compression = "lzw", bg = "white")
  cat(sprintf("  %-32s %5.1f MB\n", basename(f), file.size(f)/1e6))
}

d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, cs := factor(fifelse(lim_tier_24h == 0, "Undocumented",
                 fifelse(lim_tier_24h == 1, "Full therapy",
                 fifelse(lim_tier_24h == 2, "DNR type",
                 fifelse(lim_tier_24h == 3, "Partial withdrawal", "Comfort measures")))),
            levels = c("Full therapy","DNR type","Partial withdrawal",
                       "Comfort measures","Undocumented"))]
h <- fread(file.path(proj, "results", "hospital_reranking.csv"))

cat("figures are built by 15_build_panels.R, skipping here
")

# ---------------------------------------------------------------------------
# TABLES - fixed widths, journal formatting
# ---------------------------------------------------------------------------
cat("\nTABLES, Word, fixed width\n")

jft <- function(ft, w_first = 2.4, w_rest = 0.95, note = NULL) {
  nc <- length(ft$col_keys)
  ft <- ft |>
    width(j = 1, width = w_first) |>
    width(j = 2:nc, width = w_rest) |>
    height_all(height = 0.24, part = "body") |>
    hrule(rule = "exact", part = "body") |>
    font(fontname = "Times New Roman", part = "all") |>
    fontsize(size = 9, part = "all") |>
    bold(part = "header") |>
    align(j = 2:nc, align = "center", part = "all") |>
    align(j = 1, align = "left", part = "all") |>
    padding(padding.top = 2, padding.bottom = 2, part = "all") |>
    border_remove() |>
    hline_top(border = fp_border(color = "black", width = 1), part = "header") |>
    hline_bottom(border = fp_border(color = "black", width = .75), part = "header") |>
    hline_bottom(border = fp_border(color = "black", width = 1), part = "body") |>
    set_table_properties(layout = "fixed")
  if (!is.null(note)) ft <- add_footer_lines(ft, note) |>
    fontsize(size = 8, part = "footer") |> italic(part = "footer")
  ft
}

doc <- read_docx()

# Table 1
t1 <- fread(file.path(proj, "results", "table1_by_limitation.csv"))
names(t1)[1] <- "Characteristic"
t1[[1]] <- c("Stays, n","Percent of cohort","Age, median years","Age over 89, %",
             "Female, %","APACHE IVa score, median","Predicted mortality, %",
             "Observed mortality, %","Standardized mortality ratio",
             "Metastatic or hematologic malignancy, %","Immunosuppression, %",
             "Ventilated day 1, %","ICU stay, median hours")
doc <- doc |>
  body_add_par("Table 1. Characteristics of 136,236 intensive care admissions by treatment limitation status within 24 hours", style = "heading 2") |>
  body_add_flextable(jft(flextable(t1), 2.6, 0.92,
    "APACHE denotes Acute Physiology and Chronic Health Evaluation.")) |>
  body_add_break()

# Table 2
t2 <- fread(file.path(proj, "results", "table2_calibration_by_codestatus.csv"))
doc <- doc |>
  body_add_par("Table 2. APACHE IVa calibration by treatment limitation status", style = "heading 2") |>
  body_add_flextable(jft(flextable(t2), 2.0, 0.85,
    "ICI denotes integrated calibration index. Emax denotes maximum absolute calibration error.")) |>
  body_add_break()

# Table 3
t3 <- fread(file.path(proj, "results", "table3_discrimination.csv"))
doc <- doc |>
  body_add_par("Table 3. Discrimination and accuracy on held out data", style = "heading 2") |>
  body_add_flextable(jft(flextable(t3), 2.2, 0.95,
    "Held out sample n = 40,871. AUC denotes area under the receiver operating characteristic curve."))

print(doc, target = file.path(sub, "tables", "Tables_1_to_3.docx"))
cat("  Tables_1_to_3.docx\n")

# Table 4 - benchmarking impact
t4 <- data.table(
  Measure = c("Spearman correlation of ranks","Median absolute rank shift",
              "Units moving more than 10 positions","Units moving more than 20 positions",
              "Units changing quartile","Units changing outlier classification",
              "High mortality outlier to as expected","As expected to high mortality outlier"),
  Value = c("0.949","7.5 of 162","62 (38.3%)","24 (14.8%)","38 (23.5%)","13 (8.0%)","4","3"))
t5 <- data.table(
  Strategy = c("Current practice, APACHE IVa alone","Adjust for limitation status",
               "Exclude comfort measures only","Exclude any limitation"),
  `Admissions affected` = c("0","0","878 (0.6%)","13,496 (9.9%)"),
  `Units changing quartile` = c("reference","38 (23.5%)","18 (11.1%)","46 (28.4%)"),
  `Correlation with current` = c("1.000","0.949","0.986","0.878"))

doc2 <- read_docx() |>
  body_add_par("Table 4. Effect of modeling treatment limitation on unit ranking", style = "heading 2") |>
  body_add_flextable(jft(flextable(t4), 3.4, 1.6,
    "Based on 162 units with 100 or more admissions. Outlier status from exact Poisson 95 percent limits.")) |>
  body_add_break() |>
  body_add_par("Table 5. Comparison of remediation strategies", style = "heading 2") |>
  body_add_flextable(jft(flextable(t5), 2.4, 1.35,
    "Correlation is Spearman rank correlation of standardized mortality ratios against current practice."))
print(doc2, target = file.path(sub, "tables", "Tables_4_to_5.docx"))
cat("  Tables_4_to_5.docx\n")

# Supplementary
hl <- fread(file.path(proj, "results", "hospital_limitation_casemix.csv"))
fwrite(hl, file.path(sub, "supplementary", "TableS1_hospital_casemix.csv"))
fwrite(h,  file.path(sub, "supplementary", "TableS2_hospital_reranking.csv"))
cat("  supplementary/TableS1, TableS2\n")

cat("\nsubmission package:\n")
for (f in list.files(sub, recursive = TRUE)) cat("  ", f, "\n")
