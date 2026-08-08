# ---------------------------------------------------------------------------
# 36_sync_tex_content.R
# Brings Manuscript.tex into line with the markdown, which had moved ahead.
#   - Methods cohort paragraph now carries the exclusion counts
#   - the three stub statements are replaced by a full Declarations section
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
tex  <- file.path(proj, "submission", "Manuscript.tex")
s <- paste(readLines(tex, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

rep1 <- function(from, to, label) {
  if (grepl(from, s, fixed = TRUE)) {
    s <<- sub(from, to, s, fixed = TRUE); cat(sprintf("  ok   %s\n", label))
  } else cat(sprintf("  MISS %s\n", label))
}

# --- Methods cohort ---------------------------------------------------------
old_cohort <- "We included adult unit stays with a valid APACHE IVa predicted hospital mortality\nlinked to the APACHE predictor table, yielding 136{,}236 stays at 190 units. Unit\nlevel analyses were restricted to the 162 units contributing 100 or more stays,\ncomprising 135{,}325 admissions. Figure~S1 shows the derivation."
new_cohort <- "Of 200{,}859 adult unit stays, 52{,}327 were excluded because no APACHE IVa result\nwas recorded and a further 12{,}296 because the predicted hospital mortality was\nunavailable or zero, leaving 136{,}236 stays at 190 units. Unit level analyses were\nrestricted to the 162 units contributing 100 or more stays, excluding 911 stays in\n28 smaller units and leaving 135{,}325 admissions. Figure~S1 shows the derivation."
rep1(old_cohort, new_cohort, "Methods cohort with exclusion counts")

# some builds wrap differently; try a looser single line form
if (!grepl("52{,}327", s, fixed = TRUE)) {
  m <- regmatches(s, regexpr("We included adult unit stays.{0,400}?derivation\\.", s, perl = TRUE))
  if (length(m)) { s <- sub(m, new_cohort, s, fixed = TRUE)
                   cat("  ok   Methods cohort matched on the loose form\n") }
}

# --- Declarations -----------------------------------------------------------
decl <- paste0(
"\\section*{5. Declarations}\n\n",
"\\noindent\\textbf{Funding.} No funding was received for conducting this study.\n\n",
"\\noindent\\textbf{Conflicts of interest.} The author declares no competing interests.\n\n",
"\\noindent\\textbf{Ethics approval.} Not required. This study analyzed only\n",
"de-identified data from the eICU Collaborative Research Database, for which the\n",
"original collection and release were approved with a waiver of informed consent. No\n",
"human participants were involved and no identifiable data were accessed. Access was\n",
"granted following completion of the CITI human subjects research training required by\n",
"PhysioNet and execution of the PhysioNet Credentialed Health Data Use Agreement.\n\n",
"\\noindent\\textbf{Consent to participate.} Not applicable.\n\n",
"\\noindent\\textbf{Consent for publication.} Not applicable.\n\n",
"\\noindent\\textbf{Protocol registration.} This analysis was not prospectively\n",
"registered. The exposure definition, the ordered limitation scale, the 24 hour window\n",
"and the decision thresholds used to judge feasibility were fixed before the\n",
"corresponding analyses were run and are recorded in the project repository. The\n",
"research question was, however, refined during exploratory work. An initial framing\n",
"around malignancy was abandoned when malignancy proved to contribute nothing to\n",
"prediction, and the benchmarking framing was adopted after preliminary calibration\n",
"results had been seen. Readers should weigh the findings accordingly. The confirmatory\n",
"analyses reported here, namely the weighted comparison of limitation quintiles and the\n",
"ranking comparison, were specified before they were run.\n\n",
"\\noindent\\textbf{Availability of data and material.} The eICU Collaborative Research\n",
"Database version 2.0 is available to credentialed investigators from PhysioNet at\n",
"\\url{https://physionet.org/content/eicu-crd/2.0/}. Access requires completion of human\n",
"subjects research training and execution of a data use agreement that prohibits\n",
"redistribution, so patient level data cannot be shared by the author. Investigators who\n",
"complete credentialing can reproduce the analytic dataset exactly using the extraction\n",
"query in the repository. Unit level aggregate results are provided as supplementary\n",
"files and contain no patient level information.\n\n",
"\\noindent\\textbf{Code availability.} The full analysis pipeline is publicly available\n",
"at \\url{https://github.com/fabrice-tiku-nyambod/Treatment-limitation}, released under\n",
"the MIT License. Analyses used R 4.6.0.\n\n",
"\\noindent\\textbf{Author contributions.} F.T.N. conceived the study, designed the\n",
"analysis, performed the data extraction and statistical analysis, generated the figures\n",
"and tables, and wrote the manuscript.\n\n",
"\\noindent\\textbf{Acknowledgements.} The author thanks the MIT Laboratory for\n",
"Computational Physiology and Philips Healthcare for developing and maintaining the eICU\n",
"Collaborative Research Database, and PhysioNet for hosting it.\n")

# remove the three stub sections if present
for (h in c("Data availability", "Funding", "Conflicts of interest")) {
  pat <- sprintf("(?s)\\\\section\\*\\{%s\\}.{0,600}?(?=\\\\section\\*|\\\\newpage)", h)
  m <- regmatches(s, regexpr(pat, s, perl = TRUE))
  if (length(m)) { s <- sub(m, "", s, fixed = TRUE); cat(sprintf("  ok   removed stub %s\n", h)) }
}

if (!grepl("5. Declarations", s, fixed = TRUE)) {
  s <- sub("\\newpage\n\\section*{Tables}", paste0(decl, "\n\\newpage\n\\section*{Tables}"),
           s, fixed = TRUE)
  cat("  ok   Declarations section inserted\n")
}

if (!grepl("\\usepackage{url}", s, fixed = TRUE) && !grepl("hyperref", s, fixed = TRUE))
  s <- sub("\\begin{document}", "\\usepackage{url}\n\\begin{document}", s, fixed = TRUE)

writeLines(strsplit(s, "\n")[[1]], tex, useBytes = TRUE)
cat(sprintf("\nexclusion counts present: %s\n", grepl("52{,}327", s, fixed = TRUE)))
cat(sprintf("Declarations present    : %s\n", grepl("5. Declarations", s, fixed = TRUE)))
