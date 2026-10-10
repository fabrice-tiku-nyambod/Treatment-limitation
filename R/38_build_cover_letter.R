# ---------------------------------------------------------------------------
# 38_build_cover_letter.R
# Builds Cover_Letter.docx from COVER_LETTER.md for upload.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(officer))

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "Times New Roman"

body_fp <- fp_text(font.family = FONT, font.size = 12)
bold_fp <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
h_fp    <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
par_b   <- fp_par(line_spacing = 1.15, text.align = "justify", padding.bottom = 8)
par_h   <- fp_par(line_spacing = 1.15, padding.top = 10, padding.bottom = 4)
par_p   <- fp_par(line_spacing = 1.15, padding.bottom = 2)

md <- readLines(file.path(proj, "COVER_LETTER.md"), warn = FALSE, encoding = "UTF-8")
md <- md[!grepl("^---\\s*$|^# Cover letter", md)]

# word counts written by 25_build_full_docx.R, so the letter never drifts from
# the manuscript title page
wc <- as.integer(readLines(file.path(proj, "results", "wordcounts.txt")))
n_abs <- wc[1]; n_body <- wc[2]
md <- gsub("WORDCOUNT_BODY", format(n_body, big.mark = ","), md)
md <- gsub("WORDCOUNT_ABS", n_abs, md)

strip <- function(s) trimws(gsub("\\*\\*", "", s))

rich <- function(txt, fp_p) {
  if (!grepl("\\*\\*", txt))
    return(fpar(ftext(txt, prop = body_fp), fp_p = fp_p))
  seg <- strsplit(txt, "\\*\\*")[[1]]
  runs <- list()
  for (i in seq_along(seg)) {
    if (nchar(seg[i]) == 0) next
    runs[[length(runs) + 1]] <- ftext(seg[i],
                                      prop = if (i %% 2 == 0) bold_fp else body_fp)
  }
  do.call(fpar, c(runs, list(fp_p = fp_p)))
}

doc <- read_docx()
buf <- character(0)
flush <- function(doc) {
  if (length(buf)) {
    t <- trimws(paste(buf, collapse = " "))
    if (nchar(t)) doc <- body_add_fpar(doc, rich(t, par_b))
    buf <<- character(0)
  }
  doc
}

sig <- FALSE
for (ln in md) {
  if (grepl("^\\*\\*Declarations required at submission\\*\\*", ln)) {
    doc <- flush(doc)
    doc <- body_add_fpar(doc, fpar(ftext("Declarations required at submission",
                                         prop = h_fp), fp_p = par_h))
    next
  }
  if (grepl("^Yours sincerely", ln)) { doc <- flush(doc); sig <- TRUE }
  if (grepl("^\\s*$", ln)) { doc <- flush(doc); next }
  if (sig) {
    doc <- body_add_fpar(doc, rich(strip(ln), par_p))
  } else buf <- c(buf, ln)
}
doc <- flush(doc)

doc <- body_set_default_section(doc, prop_section(
  page_size = page_size(orient = "portrait"),
  page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1)))

out <- file.path(sub, "Cover_Letter.docx")
print(doc, target = out)
chk <- tryCatch(nrow(docx_summary(read_docx(out))), error = function(e) -1)
cat(sprintf("wrote Cover_Letter.docx  %.0f KB, %d blocks\n", file.size(out)/1024, chk))

s <- docx_summary(read_docx(out))
txt <- paste(s$text, collapse = " ")
for (k in c("approved", "not under consideration", "no conflicting interests",
            "deidentified", "github.com")) {
  cat(sprintf("  %-26s %s\n", k,
              ifelse(grepl(k, txt, ignore.case = TRUE), "present", "MISSING")))
}
cat(sprintf("  %-26s %d\n", "word count",
            length(strsplit(trimws(txt), "\\s+")[[1]])))
