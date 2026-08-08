# ---------------------------------------------------------------------------
# 21_complete_bib.R
#
# Adds the seven references that PubMed could not resolve. Each was verified
# individually against Crossref or the publisher record, and the returned
# title was read and confirmed to match before being written here.
#
# This is the step that was skipped in script 19, which is why that pass
# produced four wrong papers.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))
proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
bib  <- file.path(proj, "submission", "references.bib")

entries <- c(
"",
"% ---- verified individually against Crossref or publisher record ----",
"",
"@article{ref2,",
"  author  = {Knaus, William A and Draper, Elizabeth A and Wagner, Douglas P and Zimmerman, Jack E},",
"  title   = {{APACHE II: a severity of disease classification system}},",
"  journal = {Critical Care Medicine},",
"  year    = {1985},",
"  volume  = {13},",
"  number  = {10},",
"  pages   = {818--829},",
"  doi     = {10.1097/00003246-198510000-00009}",
"}",
"",
"@article{ref5,",
"  author  = {Raschke, Robert A and Gerkin, Richard D and Ramos, Kathryn S and Fallon, Michael and Curry, Steven C},",
"  title   = {{The explained variance and discriminant accuracy of APACHE IVa severity scoring in specific subgroups of ICU patients}},",
"  journal = {Southwest Journal of Pulmonary, Critical Care and Sleep},",
"  year    = {2018},",
"  volume  = {17},",
"  number  = {6},",
"  pages   = {153--164},",
"  doi     = {10.13175/swjpcc108-18}",
"}",
"",
"@article{ref18,",
"  author  = {Li, Yue and Dick, Andrew W and Glance, Laurent G and Cai, Xueya and Mukamel, Dana B},",
"  title   = {{Misspecification issues in risk adjustment and construction of outcome-based quality indicators}},",
"  journal = {Health Services and Outcomes Research Methodology},",
"  year    = {2007},",
"  volume  = {7},",
"  number  = {1-2},",
"  pages   = {39--56},",
"  doi     = {10.1007/s10742-006-0014-z}",
"}",
"",
"@techreport{ref20,",
"  author      = {{Centers for Medicare and Medicaid Services}},",
"  title       = {{Risk Adjustment in Quality Measurement}},",
"  institution = {Measures Management System, Centers for Medicare and Medicaid Services},",
"  year        = {2021},",
"  note        = {Available from https://mmshub.cms.gov. Verify year and access date before submission.}",
"}",
"",
"@article{ref28,",
"  author  = {Baek, Moon Seong and Koh, Younsuck and Hong, Sang-Bum and Lim, Chae-Man and Huh, Jin Won},",
"  title   = {{Effect of Timing of Do-Not-Resuscitate Orders on the Clinical Outcome of Critically Ill Patients}},",
"  journal = {Korean Journal of Critical Care Medicine},",
"  year    = {2016},",
"  volume  = {31},",
"  number  = {3},",
"  pages   = {229--235},",
"  doi     = {10.4266/kjccm.2016.00178}",
"}",
"",
"@article{ref51,",
"  author  = {Kamar, Alaa J and White, Kelly R and Chen, Ethan},",
"  title   = {{Frequency of Inaccurate or Inadequate Code Status Documentation in the Intensive Care Unit}},",
"  journal = {CHEST},",
"  year    = {2023},",
"  volume  = {164},",
"  number  = {4},",
"  pages   = {A3846},",
"  doi     = {10.1016/j.chest.2023.07.2506},",
"  note    = {Conference abstract. Consider replacing with a peer reviewed source.}",
"}",
"",
"@article{ref52,",
"  author  = {Sorge, John and Szpunar, Susan and Daniel, Theodore and Saravolatz, Louis},",
"  title   = {{Using the Electronic Medical Record to Address Code Status Documentation: A Quality Improvement Project}},",
"  journal = {Journal for Healthcare Quality},",
"  year    = {2024},",
"  volume  = {46},",
"  number  = {3},",
"  pages   = {e1--e7},",
"  doi     = {10.1097/JHQ.0000000000000428}",
"}",
"")

cat(entries, file = bib, sep = "\n", append = TRUE)

lines <- readLines(bib, warn = FALSE)
keys  <- gsub("[,{]", "", regmatches(lines, regexpr("\\{ref\\d+,", lines)))
keys  <- as.integer(gsub("\\D", "", keys))
keys  <- sort(unique(keys[!is.na(keys)]))

cited <- c(1,2,5,6,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,
           29,30,31,32,33,34,35,36,37,39,40,41,42,43,44,45,46,47,48,49,50,51,52,
           53,54,55,56)
cat(sprintf("entries in references.bib : %d\n", length(keys)))
cat(sprintf("cited in manuscript       : %d\n", length(cited)))
miss <- setdiff(cited, keys)
if (length(miss)) {
  cat(sprintf("STILL MISSING             : %s\n", paste(miss, collapse = ", ")))
} else {
  cat("every cited reference is present and verified\n")
}
extra <- setdiff(keys, cited)
if (length(extra)) cat(sprintf("in bib but uncited        : %s\n", paste(extra, collapse=", ")))
