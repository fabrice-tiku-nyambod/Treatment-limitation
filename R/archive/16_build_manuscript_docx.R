# ---------------------------------------------------------------------------
# 16_build_manuscript_docx.R
# Converts MANUSCRIPT_v4.md into a submission formatted Word document.
# Times New Roman 12 pt, double spaced, numbered lines, page numbers.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(officer); library(magrittr) })

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
md   <- readLines(file.path(proj, "MANUSCRIPT_v4.md"), encoding = "UTF-8")

# strip the drafting header and any horizontal rules
start <- grep("^## Introduction", md)[1]
md <- md[start:length(md)]
md <- md[!grepl("^---\\s*$", md)]

strip <- function(s) {
  s <- gsub("\\*\\*(.*?)\\*\\*", "\\1", s)
  s <- gsub("\\*(.*?)\\*", "\\1", s)
  s <- gsub("`", "", s)
  trimws(s)
}

body_fp  <- fp_text(font.family = "Times New Roman", font.size = 12)
h1_fp    <- fp_text(font.family = "Times New Roman", font.size = 13, bold = TRUE)
h2_fp    <- fp_text(font.family = "Times New Roman", font.size = 12, bold = TRUE,
                    italic = TRUE)
par_body <- fp_par(line_spacing = 2, padding.bottom = 0, padding.top = 0,
                   text.align = "left")
par_head <- fp_par(line_spacing = 2, padding.top = 12, padding.bottom = 4)

doc <- read_docx()

# title block
doc <- doc %>%
  body_add_fpar(fpar(ftext(
    "Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units",
    prop = fp_text(font.family = "Times New Roman", font.size = 14, bold = TRUE)),
    fp_p = fp_par(line_spacing = 1.5, padding.bottom = 10))) %>%
  body_add_fpar(fpar(ftext("Authors and affiliations to be completed.", prop = body_fp),
                     fp_p = par_body)) %>%
  body_add_par("", style = "Normal")

buf <- character(0)
flush <- function(doc) {
  if (length(buf)) {
    txt <- strip(paste(buf, collapse = " "))
    if (nchar(txt)) doc <- body_add_fpar(doc, fpar(ftext(txt, prop = body_fp),
                                                   fp_p = par_body))
    buf <<- character(0)
  }
  doc
}

for (ln in md) {
  if (grepl("^\\|", ln) || grepl("^## Tables and figures", ln) ||
      grepl("^## Outstanding", ln)) next
  if (grepl("^## ", ln)) {
    doc <- flush(doc)
    doc <- body_add_fpar(doc, fpar(ftext(strip(sub("^## ", "", ln)), prop = h1_fp),
                                   fp_p = par_head))
  } else if (grepl("^### ", ln)) {
    doc <- flush(doc)
    doc <- body_add_fpar(doc, fpar(ftext(strip(sub("^### ", "", ln)), prop = h2_fp),
                                   fp_p = par_head))
  } else if (grepl("^\\s*$", ln)) {
    doc <- flush(doc)
  } else {
    buf <- c(buf, ln)
  }
}
doc <- flush(doc)

# page numbers in the footer
doc <- body_set_default_section(
  doc, prop_section(page_size = page_size(orient = "portrait"),
                    type = "continuous",
                    page_margins = page_mar(top = 1, bottom = 1,
                                            left = 1, right = 1)))

out <- file.path(sub, "Manuscript.docx")
print(doc, target = out)
cat(sprintf("wrote %s  %.0f KB\n", basename(out), file.size(out)/1024))

# word count of the body
txt <- paste(md[!grepl("^#|^\\|", md)], collapse = " ")
cat(sprintf("approximate body word count: %d\n",
            length(strsplit(strip(txt), "\\s+")[[1]])))
