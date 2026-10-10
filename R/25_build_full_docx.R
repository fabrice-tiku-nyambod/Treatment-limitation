# ---------------------------------------------------------------------------
# 25_build_full_docx.R
#
# Complete Word manuscript for Journal of Intensive Care Medicine.
#
#   title page  ->  abstract and keywords  ->  body (justified)  ->  references
#   ->  tables  ->  figure legends
#
# Figures are not embedded: JICM takes them as separate TIFF uploads with the
# legends in the main document. Every top level section starts on a new page.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(officer); library(flextable); library(data.table)
})

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "Times New Roman"


# --- text properties -------------------------------------------------------
body_fp <- fp_text(font.family = FONT, font.size = 12)
bold_fp <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
h1_fp   <- fp_text(font.family = FONT, font.size = 13, bold = TRUE)
h2_fp   <- fp_text(font.family = FONT, font.size = 12, bold = TRUE, italic = TRUE)
cap_fp  <- fp_text(font.family = FONT, font.size = 10)
capb_fp <- fp_text(font.family = FONT, font.size = 10, bold = TRUE)

par_just <- fp_par(line_spacing = 1.5, text.align = "justify",
                   padding.top = 0, padding.bottom = 6)
par_abs  <- fp_par(line_spacing = 1.5, text.align = "justify",
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
# ---------------------------------------------------------------------------
# Passages changed since the author's own edited copy. Any paragraph containing
# one of these fragments is shaded yellow so the corrections can be located and
# transferred by hand. Set HIGHLIGHT <- character(0) to produce a clean copy.
# ---------------------------------------------------------------------------
HIGHLIGHT <- character(0)   # clean copy; see git history for the flagged version
HL_ON  <- length(HIGHLIGHT) > 0
hl_fp  <- if (HL_ON) fp_text(font.family = FONT, font.size = 12,
                             shading.color = "yellow") else body_fp
hlb_fp <- if (HL_ON) fp_text(font.family = FONT, font.size = 12, bold = TRUE,
                             shading.color = "yellow") else bold_fp
hlh_fp <- if (HL_ON) fp_text(font.family = FONT, font.size = 13, bold = TRUE,
                             shading.color = "yellow") else h1_fp
is_hl <- function(t) HL_ON && any(vapply(HIGHLIGHT,
                                         function(k) grepl(k, t, fixed = TRUE),
                                         logical(1)))

# render **bold** runs inside a paragraph, shading it if it is a changed passage
rich <- function(txt, fp_p) {
  hl <- is_hl(txt)
  bp <- if (hl) hl_fp  else body_fp
  bb <- if (hl) hlb_fp else bold_fp
  if (!grepl("\\*\\*", txt)) return(fpar(ftext(txt, prop = bp), fp_p = fp_p))
  seg <- strsplit(txt, "\\*\\*")[[1]]
  runs <- list()
  for (i in seq_along(seg)) {
    if (nchar(seg[i]) == 0) next
    runs[[length(runs) + 1]] <- ftext(seg[i], prop = if (i %% 2 == 0) bb else bp)
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
md <- readLines(file.path(proj, "MANUSCRIPT.md"), warn = FALSE, encoding = "UTF-8")
md <- md[!grepl("^---\\s*$", md)]
i0 <- grep("^## Abstract", md)[1]
i1 <- grep("^## Tables and figures", md)
if (!length(i1)) i1 <- length(md) + 1
md <- md[i0:(i1[1] - 1)]

# word counts from the markdown: abstract, and body from Introduction to
# the end of the Conclusion
wc <- function(lines) sum(vapply(strsplit(trimws(lines), "\\s+"), function(w) sum(nzchar(w)), integer(1)))
sec <- cumsum(grepl("^## ", md)); heads <- md[grepl("^## ", md)]
abs_lines  <- md[sec == which(grepl("^## Abstract", heads)) & !grepl("^#", md)]
kw <- grep("^\\*\\*Keywords", abs_lines)
if (length(kw)) abs_lines <- abs_lines[seq_len(kw - 1)]   # keywords paragraph is not abstract
abs_lines  <- sub("^\\*\\*[A-Za-z]+\\.\\*\\*", "", abs_lines)   # section labels are not words
body_lines <- md[sec >= which(grepl("^## 1\\.", heads)) & sec <= which(grepl("^## 5\\.", heads)) & !grepl("^#", md)]
n_abs <- wc(abs_lines); n_body <- wc(body_lines)
cat(sprintf("abstract %d words, body %d words\n", n_abs, n_body))
writeLines(as.character(c(n_abs, n_body)), file.path(proj, "results", "wordcounts.txt"))   # read by the cover letter builder

doc <- read_docx()

# ---- title page -----------------------------------------------------------
sup <- fp_text(font.family = FONT, font.size = 12, vertical.align = "superscript")
doc <- doc |>
  body_add_fpar(fpar(ftext(
    "Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units",
    prop = fp_text(font.family = FONT, font.size = 16, bold = TRUE)),
    fp_p = fp_par(line_spacing = 1.5, text.align = "left", padding.bottom = 14))) |>
  body_add_fpar(fpar(ftext("Fabrice T. Nyambod", prop = body_fp), ftext("1,*", prop = sup),
                     ftext(", January G. Msemakweli", prop = body_fp), ftext("2", prop = sup),
                     ftext(", Murishi Onesphore", prop = body_fp), ftext("3", prop = sup),
                     ftext(", Aja Claris", prop = body_fp), ftext("4", prop = sup),
                     ftext(", Victor Okpanachi", prop = body_fp), ftext("5", prop = sup),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 10)))
affil <- c(
  "Department of International Health, Johns Hopkins Bloomberg School of Public Health, Baltimore, MD, USA",
  "Department of Epidemiology, Johns Hopkins Bloomberg School of Public Health, Baltimore, MD, USA",
  "School-wide MPH Program, Johns Hopkins Bloomberg School of Public Health, Baltimore, MD, USA",
  "Independent Researcher, Baltimore, MD, USA",
  "Department of Environmental Health Sciences, Mel and Enid Zuckerman College of Public Health, University of Arizona, Tucson, AZ, USA")
for (i in seq_along(affil))
  doc <- body_add_fpar(doc, fpar(ftext(as.character(i), prop = sup), ftext(paste0(" ", affil[i]), prop = body_fp),
                                 fp_p = fp_par(line_spacing = 1.15, padding.bottom = 2)))
doc <- doc |>
  body_add_fpar(fpar(ftext("* Corresponding author. ", prop = bold_fp),
                     ftext("Fabrice T. Nyambod, MD, MPH. Department of International Health, Johns Hopkins Bloomberg School of Public Health, 615 N. Wolfe Street, Baltimore, MD 21205, USA. E-mail: ntiku2@jh.edu",
                           prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.top = 10, padding.bottom = 6))) |>
  body_add_fpar(fpar(ftext("ORCID. ", prop = bold_fp),
                     ftext("Fabrice T. Nyambod 0009-0006-6592-2673; January G. Msemakweli 0009-0007-6743-8479; Victor Okpanachi 0000-0001-5647-3534",
                           prop = body_fp),
                     fp_p = fp_par(line_spacing = 1.5, padding.bottom = 14)))
for (kv in list(c("Article type", "Original Research"),
                c("Running head", "Treatment limitation and ICU benchmarking"),
                c("Word count, abstract", as.character(n_abs)),
                c("Word count, body", as.character(n_body)),
                c("Tables", "3"), c("Figures", "3"),
                c("Supplementary material", "Figures S1 and S2, Tables S1 to S7, STROBE checklist"))) {
  chg <- FALSE
  doc <- body_add_fpar(doc, fpar(ftext(paste0(kv[1], ". "),
                                       prop = if (chg) hlb_fp else bold_fp),
                                 ftext(kv[2], prop = if (chg) hl_fp else body_fp),
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
    if (h != "Abstract") doc <- body_add_break(doc)   # each section on a new page
    doc <- body_add_fpar(doc, fpar(ftext(h, prop = h1_fp), fp_p = par_head))
  } else if (grepl("^### ", ln)) {
    doc <- flush(doc)
    doc <- body_add_fpar(doc, fpar(ftext(strip(sub("^### ", "", ln)), prop = h2_fp),
                                   fp_p = par_head))
  } else if (grepl("^\\s*$", ln)) {
    doc <- flush(doc)
  } else buf <- c(buf, ln)
}
doc <- flush(doc)

# ---- references -----------------------------------------------------------
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("References", prop = h1_fp), fp_p = par_head))

ama <- readLines(file.path(sub, "references_ama.txt"), warn = FALSE,
                 encoding = "UTF-8")
ama <- ama[nzchar(trimws(ama))]
cited <- paste(md, collapse = " ")
cn <- unique(as.integer(unlist(strsplit(gsub("[() ]", "", unlist(regmatches(
  cited, gregexpr("[(][0-9]+([,] ?[0-9]+)*[)]", cited)))), ","))))
refnum <- function(x) as.integer(regmatches(x, regexpr("^[0-9]+", x)))
for (ln in ama) {
  if (!(refnum(ln) %in% cn)) next
  doc <- body_add_fpar(doc, fpar(ftext(ln, prop = hl_fp),
    fp_p = fp_par(line_spacing = 1.15, text.align = "left", padding.bottom = 4)))
}
nref <- sum(vapply(ama, function(l) refnum(l) %in% cn, logical(1)))

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
             "Observed mortality, %","Standardized mortality ratio",
             "Malignancy, %","Immunosuppression, %","Ventilated day 1, %",
             "ICU stay, median hours")
setnames(t1, "Undocumented", "Not documented")
# counts as integers with separators, the ratio to two decimals, the rest to one
fmt_row <- function(v, lab) {
  if (lab == "Stays, n") format(round(v), big.mark = ",")
  else if (lab == "Standardized mortality ratio") sprintf("%.2f", v)
  else sprintf("%.1f", v)
}
for (j in 2:ncol(t1))
  set(t1, j = j, value = mapply(fmt_row, t1[[j]], t1[[1]]))
doc <- addtab(doc, "Table 1. Characteristics of 136,236 intensive care admissions by treatment limitation status within 24 hours.",
              flextable(t1),
              "APACHE denotes Acute Physiology and Chronic Health Evaluation. Malignancy denotes metastatic solid tumor or hematologic malignancy.",
              2.2, .86)
doc <- body_add_break(doc)

t2 <- fread(file.path(proj, "results", "table2_calibration_overall.csv"))
setnames(t2, c("Code status","n","Predicted, %","Observed, %","SMR","ICI","Emax"))
t2[, n := format(n, big.mark = ",")]
t2[`Code status` == "Undocumented", `Code status` := "Not documented"]
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

# ---- figure legends -------------------------------------------------------
doc <- body_add_break(doc)
doc <- body_add_fpar(doc, fpar(ftext("Figure legends", prop = h1_fp), fp_p = par_head))

caps <- list(
  c("Figure 1.", " APACHE IVa performance by treatment limitation status. (A) Calibration curves. Points are 5% risk bins and the dashed line indicates perfect calibration. (B) Adjusted odds ratios for in hospital death from a logistic recalibration model, with full therapy as reference and standard errors clustered on unit."),
  c("Figure 2.", " Between unit variation in treatment limitation. (A) Limitation rate within 24 hours across 162 units with 100 or more admissions, ordered. (B) Standardized mean differences in patient characteristics between units in the highest and lowest limitation quintile, before and after inverse probability weighting."),
  c("Figure 3.", " Effect of modeling treatment limitation on unit benchmarking. (A) Change in unit rank against limitation rate. Negative values indicate improvement. (B) Funnel plots of standardized mortality ratio against expected deaths under current practice and with limitation modeled, with 95% and 99.8% exact Poisson control limits."))
for (cp in caps)
  doc <- body_add_fpar(doc, fpar(ftext(cp[1], prop = capb_fp), ftext(cp[2], prop = cap_fp),
                                 fp_p = fp_par(line_spacing = 1.5, text.align = "justify", padding.bottom = 10)))

ftr <- block_list(fpar(run_word_field("PAGE"),
                       fp_p = fp_par(text.align = "center", padding.top = 6)))
doc <- body_set_default_section(doc, prop_section(
  page_size = page_size(orient = "portrait"),
  page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1),
  footer_default = ftr))

# Manuscript.docx is the author's hand finished submission copy and is never
# overwritten. To regenerate it from MANUSCRIPT.md, delete it first.
out <- file.path(sub, "Manuscript.docx")
if (file.exists(out)) {
  cat("Manuscript.docx exists and is hand finished; not overwritten. Delete it to rebuild.\n")
} else {
  print(doc, target = out)
  # Line numbering: officer has no API for w:lnNumType and injecting it by
  # rezipping corrupts the package. Enable it in Word: Layout > Line Numbers >
  # Continuous.
  chk <- tryCatch(nrow(officer::docx_summary(officer::read_docx(out))),
                  error = function(e) -1)
  if (chk <= 0) stop("docx failed to verify")
  cat(sprintf("docx verified readable, %d blocks\n", chk))
  cat(sprintf("wrote %s  %.0f KB\n", basename(out), file.size(out)/1024))
  cat(sprintf("references included: %d (AMA style)\n", nref))
}
