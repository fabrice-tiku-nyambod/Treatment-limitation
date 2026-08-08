# ---------------------------------------------------------------------------
# 25_build_full_docx.R
#
# Complete Word manuscript. Replaces the earlier stub, which omitted the
# abstract, tables, figures and reference list, and left text ragged right.
#
#   title page  ->  abstract  ->  body (justified)  ->  tables  ->  figures
#   ->  references
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(officer); library(flextable); library(data.table); library(magick)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
FONT <- "Times New Roman"

# --- figures to PNG for embedding (Word handles TIFF poorly) ---------------
png_dir <- file.path(sub, "figures_png")
dir.create(png_dir, showWarnings = FALSE)
figs <- c("Figure1_model_performance", "Figure2_unit_variation",
          "Figure3_benchmarking")
for (f in figs) {
  src <- file.path(sub, "figures", paste0(f, ".tiff"))
  dst <- file.path(png_dir, paste0(f, ".png"))
  if (!file.exists(dst) || file.mtime(src) > file.mtime(dst))
    image_write(image_read(src), dst, format = "png")
}
cat("figure PNGs ready\n")

# --- text properties -------------------------------------------------------
body_fp <- fp_text(font.family = FONT, font.size = 12)
bold_fp <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
h1_fp   <- fp_text(font.family = FONT, font.size = 13, bold = TRUE)
h2_fp   <- fp_text(font.family = FONT, font.size = 12, bold = TRUE, italic = TRUE)
cap_fp  <- fp_text(font.family = FONT, font.size = 10)
capb_fp <- fp_text(font.family = FONT, font.size = 10, bold = TRUE)

# 1.15 line spacing, matching the format set by hand in the Word file
par_just <- fp_par(line_spacing = 1.15, text.align = "justify",
                   padding.top = 0, padding.bottom = 6)
par_abs  <- fp_par(line_spacing = 1.15, text.align = "justify",
                   padding.top = 0, padding.bottom = 6)
par_head <- fp_par(line_spacing = 1.5, padding.top = 14, padding.bottom = 6)
par_cap  <- fp_par(line_spacing = 1, text.align = "left",
                   padding.top = 4, padding.bottom = 10)
par_ctr  <- fp_par(text.align = "center", padding.top = 6, padding.bottom = 2)

strip <- function(s) {
  s <- gsub("\\*\\*(.*?)\\*\\*", "\\1", s)
  s <- gsub("\\*(.*?)\\*", "\\1", s)
  gsub("`", "", trimws(s))
}
# render **bold** runs inside a paragraph
rich <- function(txt, fp_p) {
  parts <- strsplit(txt, "(?=\\*\\*)", perl = TRUE)[[1]]
  runs <- list(); buf <- txt
  if (!grepl("\\*\\*", txt)) return(fpar(ftext(txt, prop = body_fp), fp_p = fp_p))
  seg <- strsplit(txt, "\\*\\*")[[1]]
  for (i in seq_along(seg)) {
    if (nchar(seg[i]) == 0) next
    runs[[length(runs) + 1]] <- ftext(seg[i],
                                      prop = if (i %% 2 == 0) bold_fp else body_fp)
  }
  do.call(fpar, c(runs, list(fp_p = fp_p)))
}

jft <- function(ft, w1, wr, note = NULL) {
  nc <- length(ft$col_keys)
  ft <- ft |> width(j = 1, width = w1) |> width(j = 2:nc, width = wr) |>
    height_all(height = 0.24, part = "body") |> hrule(rule = "exact", part = "body") |>
    font(fontname = FONT, part = "all") |> fontsize(size = 9, part = "all") |>
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
    fontsize(size = 8, part = "footer") |> italic(part = "footer") |>
    font(fontname = FONT, part = "footer")
  ft
}

# --- parse the markdown ----------------------------------------------------
md <- readLines(file.path(proj, "MANUSCRIPT_v4.md"), warn = FALSE, encoding = "UTF-8")
md <- md[!grepl("^---\\s*$", md)]
i0 <- grep("^## Abstract", md)[1]
i1 <- grep("^## Tables and figures", md)
if (!length(i1)) i1 <- length(md) + 1
md <- md[i0:(i1[1] - 1)]

doc <- read_docx()

# ---- title page -----------------------------------------------------------
sup <- fp_text(font.family = FONT, font.size = 12, vertical.align = "superscript")
doc <- doc |>
  body_add_fpar(fpar(ftext(
    "Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units",
    prop = fp_text(font.family = FONT, font.size = 14, bold = TRUE)),
    fp_p = fp_par(line_spacing = 1.5, text.align = "left", padding.bottom = 14))) |>
  body_add_fpar(fpar(ftext("Fabrice T. Nyambod, MD, MPH", prop = body_fp),
                     ftext("1", prop = sup),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 6))) |>
  body_add_fpar(fpar(ftext("1", prop = sup),
                     ftext(" Department of International Health, Johns Hopkins Bloomberg School of Public Health, Baltimore, Maryland, USA",
                           prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 14))) |>
  body_add_fpar(fpar(ftext("Corresponding author. ", prop = bold_fp),
                     ftext("Fabrice T. Nyambod, Department of International Health, Johns Hopkins Bloomberg School of Public Health, Baltimore, Maryland, USA. Email tikufabrice@gmail.com",
                           prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 6))) |>
  body_add_fpar(fpar(ftext("ORCID. ", prop = bold_fp),
                     ftext("0009-0006-6592-2673", prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 14)))
for (kv in list(c("Running head", "Treatment limitation and ICU benchmarking"),
                c("Word count, body", "2704"),
                c("Tables", "3"), c("Figures", "3"),
                c("Keywords", "intensive care, benchmarking, standardized mortality ratio, treatment limitation, code status, risk adjustment"))) {
  doc <- body_add_fpar(doc, fpar(ftext(paste0(kv[1], ". "), prop = bold_fp),
                                 ftext(kv[2], prop = body_fp),
                                 fp_p = fp_par(line_spacing = 1.5, padding.bottom = 2)))
}
doc <- body_add_break(doc)

# ---- body -----------------------------------------------------------------
buf <- character(0); in_abstract <- FALSE
flush <- function(doc) {
  if (length(buf)) {
    t <- trimws(paste(buf, collapse = " "))
    if (nchar(t)) doc <- body_add_fpar(doc, rich(t, if (in_abstract) par_abs else par_just))
    buf <<- character(0)
  }
  doc
}
for (ln in md) {
  if (grepl("^\\|", ln)) next
  if (grepl("^## ", ln)) {
    doc <- flush(doc)
    h <- strip(sub("^## ", "", ln)); in_abstract <<- (h == "Abstract")
    doc <- body_add_fpar(doc, fpar(ftext(h, prop = h1_fp), fp_p = par_head))
    if (h == "Introduction") doc <- body_add_break(doc)
  } else if (grepl("^### ", ln)) {
    doc <- flush(doc)
    doc <- body_add_fpar(doc, fpar(ftext(strip(sub("^### ", "", ln)), prop = h2_fp),
                                   fp_p = par_head))
  } else if (grepl("^\\s*$", ln)) {
    doc <- flush(doc)
  } else buf <- c(buf, ln)
}
doc <- flush(doc)

# ---- tables ---------------------------------------------------------------
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Tables", prop = h1_fp), fp_p = par_head))

addtab <- function(doc, cap, ft, note = NULL, w1 = 2.4, wr = .95) {
  doc <- body_add_fpar(doc, fpar(ftext(sub("\\..*", ".", cap), prop = capb_fp),
                                 ftext(sub("^[^.]*\\.", "", cap), prop = cap_fp),
                                 fp_p = par_cap))
  body_add_flextable(doc, jft(ft, w1, wr, note))
}

t1 <- fread(file.path(proj, "results", "table1_by_limitation.csv"))
names(t1)[1] <- "Characteristic"
t1[[1]] <- c("Stays, n","Percent of cohort","Age, median years","Age over 89, %",
             "Female, %","APACHE IVa score, median","Predicted mortality, %",
             "Observed mortality, %","Standardised mortality ratio",
             "Malignancy, %","Immunosuppression, %","Ventilated day 1, %",
             "ICU stay, median hours")
doc <- addtab(doc, "Table 1. Characteristics of 136,236 intensive care admissions by treatment limitation status within 24 hours.",
              flextable(t1),
              "APACHE denotes Acute Physiology and Chronic Health Evaluation. Malignancy denotes metastatic solid tumor or hematologic malignancy.",
              2.6, .92)
doc <- body_add_break(doc)

t2 <- fread(file.path(proj, "results", "table2_calibration_overall.csv"))
setnames(t2, c("Code status","n","Predicted, %","Observed, %","SMR","ICI","Emax"))
doc <- addtab(doc, "Table 2. APACHE IVa calibration by treatment limitation status.",
              flextable(t2),
              "SMR denotes standardized mortality ratio. ICI denotes integrated calibration index. Emax denotes maximum absolute calibration error.",
              2.0, .85)
doc <- body_add_break(doc)

t5 <- data.table(Strategy = c("Current practice, APACHE IVa alone","Adjust for limitation status",
    "Exclude comfort measures only","Exclude any limitation"),
  `Admissions affected` = c("0","0","878 (0.6%)","13,496 (9.9%)"),
  `Units changing quartile` = c("reference","38 (23.5%)","18 (11.1%)","46 (28.4%)"),
  `Correlation with current` = c("1.000","0.949","0.986","0.878"))
doc <- addtab(doc, "Table 3. Comparison of remediation strategies.",
              flextable(t5),
              "Correlation is the Spearman rank correlation of standardized mortality ratios against current practice.",
              2.4, 1.35)

# ---- figures --------------------------------------------------------------
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Figures", prop = h1_fp), fp_p = par_head))

caps <- list(
  c("Figure 1.", " APACHE IVa performance by treatment limitation status. (A) Calibration curves. Points are 5 percent risk bins and the dashed line indicates perfect calibration. (B) Adjusted odds ratios for in hospital death from a logistic recalibration model, with full therapy as reference and standard errors clustered on unit.", 6.5),
  c("Figure 2.", " Between unit variation in treatment limitation. (A) Limitation rate within 24 hours across 162 units with 100 or more admissions, ordered. (B) Standardized mean differences in patient characteristics between units in the highest and lowest limitation quintile, before and after inverse probability weighting.", 6.5),
  c("Figure 3.", " Effect of modeling treatment limitation on unit benchmarking. (A) Change in unit rank against limitation rate. Negative values indicate improvement. (B) Funnel plots of standardized mortality ratio against expected deaths under current practice and with limitation modeled, with 95 and 99.8 percent exact Poisson control limits.", 6.5))

for (i in seq_along(figs)) {
  p <- file.path(png_dir, paste0(figs[i], ".png"))
  d <- image_info(image_read(p))
  w <- as.numeric(caps[[i]][3]); h <- w * d$height / d$width
  doc <- body_add_img(doc, p, width = w, height = h, style = "centered")
  doc <- body_add_fpar(doc, fpar(ftext(caps[[i]][1], prop = capb_fp),
                                 ftext(caps[[i]][2], prop = cap_fp), fp_p = par_cap))
  if (i < length(figs)) doc <- body_add_break(doc)
}

# ---- references -----------------------------------------------------------
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("References", prop = h1_fp), fp_p = par_head))

bib <- paste(readLines(file.path(sub, "references.bib"), warn = FALSE), collapse = "\n")
blocks <- regmatches(bib, gregexpr("(?s)@\\w+\\{ref\\d+,.*?\\n\\}", bib, perl = TRUE))[[1]]
if (!length(blocks)) stop("no bibtex entries parsed from references.bib")
fld <- function(b, f) {
  m <- regmatches(b, regexpr(paste0(f, "\\s*=\\s*\\{+[^}]*\\}+"), b))
  if (!length(m)) return("")
  gsub("^\\{+|\\}+$", "", sub(paste0(f, "\\s*=\\s*"), "", m))
}
ref <- rbindlist(lapply(blocks, function(b) data.table(
  n = as.integer(gsub("\\D", "", regmatches(b, regexpr("ref\\d+", b)))),
  au = gsub(" and ", ", ", fld(b, "author")), ti = fld(b, "title"),
  jo = fld(b, "journal"), yr = fld(b, "year"), vo = fld(b, "volume"),
  nu = fld(b, "number"), pg = fld(b, "pages"))))
setorder(ref, n)
cited <- paste(md, collapse = " ")
cn <- unique(as.integer(unlist(strsplit(gsub("[() ]", "", unlist(regmatches(
  cited, gregexpr("[(][0-9]+([,] ?[0-9]+)*[)]", cited)))), ","))))
ref <- ref[n %in% cn]

for (i in seq_len(nrow(ref))) {
  r <- ref[i]
  cit <- sprintf("%s. %s. %s%s%s%s%s", r$au, r$ti, r$jo,
                 ifelse(r$yr != "", paste0(". ", r$yr), ""),
                 ifelse(r$vo != "", paste0(";", r$vo), ""),
                 ifelse(r$nu != "", paste0("(", r$nu, ")"), ""),
                 ifelse(r$pg != "", paste0(":", gsub("--", "-", r$pg), "."), "."))
  doc <- body_add_fpar(doc, fpar(
    ftext(sprintf("%d. ", r$n), prop = body_fp), ftext(cit, prop = body_fp),
    fp_p = fp_par(line_spacing = 1.5, text.align = "left", padding.bottom = 4)))
}

ftr <- block_list(fpar(run_word_field("PAGE"),
                       fp_p = fp_par(text.align = "center",
                                     padding.top = 6)))
doc <- body_set_default_section(doc, prop_section(
  page_size = page_size(orient = "portrait"),
  page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1),
  footer_default = ftr))

out <- file.path(sub, "Manuscript.docx")
print(doc, target = out)

# --- line numbering ---------------------------------------------------------
# officer has no API for w:lnNumType. Injecting it by unzipping and rezipping
# corrupts the package, because [Content_Types].xml contains glob metacharacters
# that neither utils::zip nor zip::zip round-trips reliably. Enable it in Word
# instead: Layout > Line Numbers > Continuous. Three clicks, no risk to the file.
chk <- tryCatch(nrow(officer::docx_summary(officer::read_docx(out))),
                error = function(e) -1)
if (chk > 0) {
  cat(sprintf("docx verified readable, %d blocks\n", chk))
} else {
  stop("docx failed to verify")
}

cat(sprintf("\nwrote Manuscript.docx  %.0f KB\n", file.size(out)/1024))
cat(sprintf("references included: %d\n", nrow(ref)))
