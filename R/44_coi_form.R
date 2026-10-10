# ---------------------------------------------------------------------------
# 44_coi_form.R
#
# Conflict of interest declaration as a separate upload. One sentence, nothing
# else, at the author's request.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(officer))

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "Times New Roman"

doc <- read_docx() |>
  body_add_fpar(fpar(ftext(
    "The authors declare no competing financial interests or personal relationships that could have appeared to influence the work reported in this paper.",
    prop = fp_text(font.family = FONT, font.size = 12)),
    fp_p = fp_par(line_spacing = 1.5, text.align = "justify"))) |>
  body_set_default_section(prop_section(page_size = page_size(orient = "portrait"),
                                        page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1)))

out <- file.path(sub, "COI_Declaration.docx")
print(doc, target = out)
cat("wrote COI_Declaration.docx\n")
