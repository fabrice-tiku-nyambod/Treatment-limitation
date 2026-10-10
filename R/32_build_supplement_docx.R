# ---------------------------------------------------------------------------
# 32_build_supplement_docx.R
#
# Builds Supplementary_Material.docx as a standalone upload, separate from the
# manuscript. Journals require the supplement as its own file.
#
#   Table S1   discrimination and accuracy on held out data
#   Table S2   effect of modeling limitation on unit ranking
#   Table S3   unit level case mix
#   Table S4   unit level ranking comparison
#   Table S5   covariate balance before and after weighting
#   Table S6   calibration by tier and timing of the order
#   Table S7   unit ranking under timing based strategies
#   Figure S1  study flow
#   Figure S2  timing of limitation orders and calibration by timing
#
# S3 to S5 are large per unit listings and are embedded here in full rather
# than shipped as loose CSVs, so a reader has everything in one document.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(officer); library(flextable); library(data.table); library(magick)
})

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "Times New Roman"

body_fp <- fp_text(font.family = FONT, font.size = 12)
bold_fp <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
h1_fp   <- fp_text(font.family = FONT, font.size = 13, bold = TRUE)
cap_fp  <- fp_text(font.family = FONT, font.size = 10)
capb_fp <- fp_text(font.family = FONT, font.size = 10, bold = TRUE)
par_txt <- fp_par(line_spacing = 1.15, text.align = "justify", padding.bottom = 8)
par_head<- fp_par(line_spacing = 1.5, padding.top = 12, padding.bottom = 6)
par_cap <- fp_par(line_spacing = 1, text.align = "left",
                  padding.top = 4, padding.bottom = 8)

jft <- function(ft, w1, wr, note = NULL, fs = 9) {
  nc <- length(ft$col_keys)
  ft <- ft |> width(j = 1, width = w1) |> width(j = 2:nc, width = wr) |>
    height_all(height = 0.22, part = "body") |> hrule(rule = "exact", part = "body") |>
    font(fontname = FONT, part = "all") |> fontsize(size = fs, part = "all") |>
    bold(part = "header") |>
    align(j = 2:nc, align = "center", part = "all") |>
    align(j = 1, align = "left", part = "all") |>
    padding(padding.top = 1, padding.bottom = 1, part = "all") |>
    border_remove() |>
    hline_top(border = fp_border(color = "black", width = 1), part = "header") |>
    hline_bottom(border = fp_border(color = "black", width = .75), part = "header") |>
    hline_bottom(border = fp_border(color = "black", width = 1), part = "body") |>
    set_table_properties(layout = "fixed")
  if (!is.null(note)) ft <- add_footer_lines(ft, note) |>
    fontsize(size = 8, part = "footer") |> italic(part = "footer") |>
    font(fontname = FONT, part = "footer")
  ft
}
addtab <- function(doc, cap, ft, note = NULL, w1 = 2.4, wr = .95, fs = 9) {
  doc <- body_add_fpar(doc, fpar(ftext(sub("\\..*", ".", cap), prop = capb_fp),
                                 ftext(sub("^[^.]*\\.", "", cap), prop = cap_fp),
                                 fp_p = par_cap))
  body_add_flextable(doc, jft(ft, w1, wr, note, fs))
}

doc <- read_docx()

# ---- title ----------------------------------------------------------------
doc <- doc |>
  body_add_fpar(fpar(ftext("Supplementary Material",
                           prop = fp_text(font.family = FONT, font.size = 14, bold = TRUE)),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 10))) |>
  body_add_fpar(fpar(ftext("Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units",
                           prop = fp_text(font.family = FONT, font.size = 12, italic = TRUE)),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 10))) |>
  body_add_fpar(fpar(ftext("Fabrice T. Nyambod, January G. Msemakweli, Murishi Onesphore, Aja Claris, Victor Okpanachi", prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 16))) |>
  body_add_fpar(fpar(ftext("Contents", prop = bold_fp), fp_p = par_head))
for (l in c("Table S1. Discrimination and accuracy on held out data",
            "Table S2. Effect of modeling treatment limitation on unit ranking",
            "Table S3. Unit level case mix and limitation rate",
            "Table S4. Unit level ranking comparison",
            "Table S5. Covariate balance before and after weighting",
            "Table S6. APACHE IVa calibration by limitation tier and timing of the order",
            "Table S7. Unit ranking under strategies that count only early orders",
            "Figure S1. Derivation of the study cohort",
            "Figure S2. Timing of limitation orders and calibration by timing")) {
  doc <- body_add_fpar(doc, fpar(ftext(l, prop = body_fp),
                                 fp_p = fp_par(line_spacing = 1.15, padding.bottom = 2)))
}
doc <- body_add_break(doc)

# ---- Table S1 -------------------------------------------------------------
t1 <- fread(file.path(proj, "results", "table3_discrimination.csv"))
doc <- addtab(doc, "Table S1. Discrimination and accuracy on held out data.",
              flextable(t1),
              "Held out sample n = 40,871. AUC denotes area under the receiver operating characteristic curve. Adding limitation status improved the AUC (p < 0.001, DeLong). Adding malignancy did not (p = 0.16).",
              2.2, .95)
doc <- body_add_break(doc)

# ---- Table S2 -------------------------------------------------------------
t2 <- data.table(Measure = c("Spearman correlation of ranks","Median absolute rank shift",
    "Units moving more than 10 positions","Units moving more than 20 positions",
    "Units changing quartile","Units changing outlier classification",
    "High mortality outlier to as expected","As expected to high mortality outlier"),
  Value = c("0.949","7.5 of 162","62 (38.3%)","24 (14.8%)","38 (23.5%)","13 (8.0%)","4","3"))
doc <- addtab(doc, "Table S2. Effect of modeling treatment limitation on unit ranking.",
              flextable(t2),
              "Based on 162 units with 100 or more admissions. Outlier status from exact Poisson 95 percent limits.",
              3.4, 1.6)
doc <- body_add_break(doc)

# ---- Table S3 -------------------------------------------------------------
t3 <- fread(file.path(sub, "supplementary", "TableS1_hospital_casemix.csv"))
setnames(t3, c("hospitalid","n","obs_rate","exp_rate","ratio"),
         c("Unit","Stays","Observed rate","Expected rate","Observed / expected"),
         skip_absent = TRUE)
num <- names(t3)[sapply(t3, is.numeric)]
t3[, (num) := lapply(.SD, function(x) round(x, 3)), .SDcols = num]
doc <- addtab(doc, "Table S3. Unit level limitation rate against case mix expectation.",
              flextable(t3),
              sprintf("All %d units with 100 or more admissions. Expected rate from a mixed effects model adjusted for the APACHE linear predictor, age, sex, malignancy, immunosuppression, cirrhosis, diabetes and day 1 ventilation.", nrow(t3)),
              1.1, 1.1, 8)
doc <- body_add_break(doc)

# ---- Table S4 -------------------------------------------------------------
t4 <- fread(file.path(sub, "supplementary", "TableS2_hospital_reranking.csv"))
keep <- intersect(c("hospitalid","n","lim_rate","smrA","smrB","rankA","rankB","rank_shift"),
                  names(t4))
t4 <- t4[, ..keep]
setnames(t4, keep, c("Unit","Stays","Limitation rate","SMR current","SMR adjusted",
                     "Rank current","Rank adjusted","Rank shift")[seq_along(keep)])
num <- names(t4)[sapply(t4, is.numeric)]
t4[, (num) := lapply(.SD, function(x) round(x, 3)), .SDcols = num]
doc <- addtab(doc, "Table S4. Unit level ranking with and without treatment limitation in the risk model.",
              flextable(t4),
              "SMR denotes standardized mortality ratio. A negative rank shift indicates the unit improved when limitation was modeled.",
              0.9, 0.95, 8)
doc <- body_add_break(doc)

# ---- Table S5 -------------------------------------------------------------
t5 <- fread(file.path(sub, "supplementary", "TableS3_covariate_balance.csv"))
num <- names(t5)[sapply(t5, is.numeric)]
t5[, (num) := lapply(.SD, function(x) round(x, 4)), .SDcols = num]
doc <- addtab(doc, "Table S5. Covariate balance between the highest and lowest limitation quintile, before and after inverse probability weighting.",
              flextable(t5),
              "Threshold for balance is a standardized mean difference of 0.1. All covariates balanced after weighting.",
              2.6, .95, 8)
doc <- body_add_break(doc)

# ---- Table S6 -------------------------------------------------------------
t6 <- fread(file.path(sub, "supplementary", "TableS6_calibration_by_timing.csv"))
t6[, timing := fifelse(timing == "Reference", "", as.character(timing))]
t6[, smr := sprintf("%.2f (%.2f-%.2f)", smr, smr_lo, smr_hi)]
t6 <- t6[, .(`Limitation tier` = cs, `Timing of order` = timing, Admissions = n,
             `Observed deaths` = observed, `Predicted deaths` = predicted,
             `SMR (95% CI)` = smr, ICI = ici)]
doc <- addtab(doc, "Table S6. APACHE IVa calibration by limitation tier and timing of the first order at that tier.",
              flextable(t6),
              "Timing is measured from unit admission to the first order at the stay's most restrictive tier. SMR denotes standardized mortality ratio with exact Poisson limits. ICI denotes integrated calibration index.",
              1.2, .88, 8)
doc <- body_add_break(doc)

# ---- Table S7 -------------------------------------------------------------
t7 <- fread(file.path(sub, "supplementary", "TableS7_reranking_by_timing.csv"))
t7 <- t7[, .(Strategy = strategy,
             `Spearman correlation with current` = sprintf("%.3f", spearman_smr),
             `Median absolute rank shift` = median_abs_shift,
             `Units changing quartile` = sprintf("%d (%.1f%%)", quartile_change_n, quartile_change_pct),
             `Units changing outlier status` = sprintf("%d (%.1f%%)", outlier_change_n, outlier_change_pct),
             `Rank shift against unit early limitation rate, rho` = sprintf("%.3f", rho_shift_vs_early_rate))]
doc <- addtab(doc, "Table S7. Unit ranking under strategies that count only orders written within 4 hours of admission, or exclude comfort measures admissions by timing.",
              flextable(t7),
              "Based on 162 units with 100 or more admissions. Early denotes an order first documented within 4 hours of unit admission. Exclusion strategies refit the recalibration model on the retained cohort.",
              2.3, .85, 8)
doc <- body_add_break(doc)

# ---- Figures S1 and S2 ----------------------------------------------------
png_dir <- file.path(sub, "figures_png"); dir.create(png_dir, showWarnings = FALSE)
figS <- list(
  c("FigureS1_flow", "Figure S1.", " Derivation of the study cohort from the eICU Collaborative Research Database version 2.0.", "6.0"),
  c("FigureS2_timing", "Figure S2.", " Timing of limitation orders and calibration by timing. (A) Cumulative proportion of admissions at each tier by hours from unit admission to the first order at that tier. The dashed line marks 4 hours. (B) Standardized mortality ratio by tier and timing of the order, with exact Poisson 95% limits.", "6.5"))
for (i in seq_along(figS)) {
  f <- figS[[i]]
  src <- file.path(sub, "figures", paste0(f[1], ".tiff"))
  dst <- file.path(png_dir, paste0(f[1], ".png"))
  if (!file.exists(dst) || file.mtime(src) > file.mtime(dst))
    image_write(image_read(src), dst, format = "png")
  d <- image_info(image_read(dst)); w <- as.numeric(f[4]); h <- w * d$height / d$width
  doc <- body_add_img(doc, dst, width = w, height = h, style = "centered")
  doc <- body_add_fpar(doc, fpar(ftext(f[2], prop = capb_fp), ftext(f[3], prop = cap_fp), fp_p = par_cap))
  if (i < length(figS)) doc <- body_add_break(doc)
}

doc <- body_set_default_section(doc, prop_section(
  page_size = page_size(orient = "portrait"),
  page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1),
  footer_default = block_list(fpar(run_word_field("PAGE"),
                                   fp_p = fp_par(text.align = "center")))))

out <- file.path(sub, "Supplementary_Material.docx")
print(doc, target = out)
chk <- tryCatch(nrow(docx_summary(read_docx(out))), error = function(e) -1)
cat(sprintf("wrote Supplementary_Material.docx  %.0f KB, %d blocks\n",
            file.size(out)/1024, chk))
cat(sprintf("  Table S3 rows %d, Table S4 rows %d, Table S5 rows %d\n",
            nrow(t3), nrow(t4), nrow(t5)))
