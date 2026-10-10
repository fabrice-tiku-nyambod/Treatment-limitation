# ---------------------------------------------------------------------------
# 45_submission_letter.R
#
# Submission letter for the Canadian Journal of Anesthesia, separate from the
# cover letter. The CJA Guide for Authors requires a letter signed by ALL authors
# recognizing that 1) each author contributed to the design and conduct of the
# work, 2) the manuscript was written, read and approved by all authors, and
# 3) the material has not been published and is not under consideration
# elsewhere, with financial support and conflicts of interest disclosed.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(officer); library(flextable) })

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "Times New Roman"

TITLE <- "Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units"

authors <- data.frame(
  Author = c("Fabrice T. Nyambod, MD, MPH", "January G. Msemakweli",
             "Murishi Onesphore", "Aja Claris", "Victor Okpanachi"),
  Affiliation = c(
    "Department of International Health, Johns Hopkins Bloomberg School of Public Health, Baltimore, MD, USA",
    "Department of Epidemiology, Johns Hopkins Bloomberg School of Public Health, Baltimore, MD, USA",
    "School-wide MPH Program, Johns Hopkins Bloomberg School of Public Health, Baltimore, MD, USA",
    "Independent Researcher, Baltimore, MD, USA",
    "Department of Environmental Health Sciences, Mel and Enid Zuckerman College of Public Health, University of Arizona, Tucson, AZ, USA"),
  Signature = "", Date = "",
  stringsAsFactors = FALSE)

body_fp <- fp_text(font.family = FONT, font.size = 12)
bold_fp <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
ital_fp <- fp_text(font.family = FONT, font.size = 12, italic = TRUE)
par_j   <- fp_par(line_spacing = 1.5, text.align = "justify", padding.bottom = 6)
par_l   <- fp_par(line_spacing = 1.5, text.align = "left",    padding.bottom = 6)
par_num <- fp_par(line_spacing = 1.5, text.align = "justify", padding.bottom = 4,
                  padding.left = 18)

p <- function(..., fp_p = par_j) fpar(..., fp_p = fp_p)
t <- function(x, prop = body_fp) ftext(x, prop = prop)

sig_tab <- flextable(authors) |>
  width(j = 1:4, width = c(1.7, 2.6, 1.4, 0.8)) |>
  height_all(height = 0.6) |> hrule(rule = "atleast", part = "body") |>
  font(fontname = FONT, part = "all") |> fontsize(size = 10, part = "all") |>
  bold(part = "header") |>
  align(align = "center", part = "header") |>
  align(align = "left", part = "body") |>
  valign(valign = "center", part = "all") |>
  border_remove() |>
  hline_top(border = fp_border(width = 1), part = "header") |>
  hline_bottom(border = fp_border(width = 1), part = "header") |>
  hline(border = fp_border(width = 0.5, color = "grey50"), part = "body")

doc <- read_docx() |>
  body_add_fpar(p(t("6 October 2026"), fp_p = par_l)) |>
  body_add_fpar(p(t("To the Editor-in-Chief"), fp_p = fp_par(text.align = "left"))) |>
  body_add_fpar(p(t("Canadian Journal of Anesthesia/Journal canadien d’anesthésie", ital_fp),
                  fp_p = par_l)) |>
  body_add_fpar(p(t("Submission letter", bold_fp), fp_p = par_l)) |>
  body_add_fpar(p(t("Manuscript title: ", bold_fp), t(TITLE))) |>
  body_add_fpar(p(t("Dear Editor,"), fp_p = par_l)) |>
  body_add_fpar(p(t(paste0(
    "We submit the manuscript \"", TITLE,
    "\" for publication in the Canadian Journal of Anesthesia. ",
    "By signing this letter, the authors confirm that:")))) |>
  body_add_fpar(p(t("1. Each author has contributed to the design and conduct of the work."),
                  fp_p = par_num)) |>
  body_add_fpar(p(t("2. The manuscript has been written, read, and approved by all authors."),
                  fp_p = par_num)) |>
  body_add_fpar(p(t(paste0(
    "3. The material has not been published, either whole or in part, ",
    "and is not under consideration for publication elsewhere.")), fp_p = par_num)) |>
  body_add_fpar(p(t("Financial support. ", bold_fp),
                  t("None. The study received no funding."))) |>
  body_add_fpar(p(t("Conflicts of interest. ", bold_fp),
                  t("None. The authors have no conflicts of interest to declare."))) |>
  body_add_fpar(p(t("Corresponding author. ", bold_fp),
                  t(paste0("Fabrice T. Nyambod, MD, MPH, Department of International Health, ",
                           "Johns Hopkins Bloomberg School of Public Health, 615 N. Wolfe Street, ",
                           "Baltimore, MD 21205, USA. E-mail: ntiku2@jh.edu. ORCID 0009-0006-6592-2673.")))) |>
  body_add_fpar(p(t("Signatures of all authors", bold_fp), fp_p = par_l)) |>
  body_add_flextable(sig_tab, align = "left") |>
  body_set_default_section(prop_section(page_size = page_size(orient = "portrait"),
                                        page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1)))

out <- file.path(sub, "Submission_Letter.docx")
print(doc, target = out)
cat("wrote Submission_Letter.docx\n")
