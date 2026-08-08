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
#   Figure S1  study flow
#
# S3 to S5 are large per unit listings and are embedded here in full rather
# than shipped as loose CSVs, so a reader has everything in one document.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(officer); library(flextable); library(data.table); library(magick)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
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
  body_add_fpar(fpar(ftext("Fabrice T. Nyambod, MD, MPH", prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 16))) |>
  body_add_fpar(fpar(ftext("Contents", prop = bold_fp), fp_p = par_head))
for (l in c("Table S1. Discrimination and accuracy on held out data",
            "Table S2. Effect of modeling treatment limitation on unit ranking",
            "Table S3. Unit level case mix and limitation rate",
            "Table S4. Unit level ranking comparison",
            "Table S5. Covariate balance before and after weighting",
            "Figure S1. Derivation of the study cohort")) {
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

# ---- Figure S1 ------------------------------------------------------------
png_dir <- file.path(sub, "figures_png"); dir.create(png_dir, showWarnings = FALSE)
src <- file.path(sub, "figures", "FigureS1_flow.tiff")
dst <- file.path(png_dir, "FigureS1_flow.png")
if (!file.exists(dst) || file.mtime(src) > file.mtime(dst))
  image_write(image_read(src), dst, format = "png")
d <- image_info(image_read(dst)); w <- 6.0; h <- w * d$height / d$width
doc <- body_add_img(doc, dst, width = w, height = h, style = "centered")
doc <- body_add_fpar(doc, fpar(ftext("Figure S1.", prop = capb_fp),
  ftext(" Derivation of the study cohort from the eICU Collaborative Research Database version 2.0.",
        prop = cap_fp), fp_p = par_cap))

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
