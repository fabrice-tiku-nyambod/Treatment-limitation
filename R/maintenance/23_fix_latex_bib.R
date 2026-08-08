# ---------------------------------------------------------------------------
# 23_fix_latex_bib.R
#
# Brings Manuscript.tex into line with the verified bibliography.
#   - switches from the hand written inline list to references.bib
#   - removes citations to the six dropped references
#   - restores ref 2 with the detail read from the source PDF
#   - deletes the stale inline bibliography file
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
tex  <- file.path(proj, "submission", "Manuscript.tex")
s    <- paste(readLines(tex, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

sub1 <- function(from, to, label) {
  if (grepl(from, s, fixed = TRUE)) {
    s <<- sub(from, to, s, fixed = TRUE); cat(sprintf("  ok    %s\n", label))
  } else cat(sprintf("  MISS  %s\n", label))
}

cat("editing Manuscript.tex\n")

# ref 2 restored, with the figure verified from the scanned source
sub1("The APACHE method was introduced in 1985 \\cite{ref2} and the APACHE\nIVa model was derived from 110{,}558 admissions to 104 units during 2002 and 2003\n\\cite{ref1}.",
     "The APACHE method was introduced in 1985 and validated on 5815 admissions\nfrom 13 hospitals \\cite{ref2}. The APACHE IVa model was derived from 110{,}558\nadmissions to 104 units during 2002 and 2003 \\cite{ref1}.",
     "ref2 restored with validation cohort")

# ref 5 dropped
sub1("Performance also differs across patient\nsubgroups \\cite{ref5} and across ethnic groups within the same health system\n\\cite{ref9}.",
     "Performance also differs across ethnic groups within the same health\nsystem \\cite{ref9}.",
     "ref5 removed")

# ref 20 dropped from the reimbursement sentence
sub1("that basis \\cite{ref12,ref20}.", "that basis \\cite{ref12}.", "ref20 removed, reimbursement")

# ref 18 dropped, ref 19 carries misspecification
sub1("quality measures \\cite{ref18,ref19}, and alternative modeling strategies produce",
     "quality measures \\cite{ref19}, and alternative modeling strategies produce",
     "ref18 removed, introduction")
sub1("recognised source of bias in quality measurement \\cite{ref18,ref19}.",
     "recognised source of bias in quality measurement \\cite{ref19}.",
     "ref18 removed, discussion")
sub1("hazards of mediator adjustment \\cite{ref18}.",
     "hazards of mediator adjustment.",
     "ref18 removed, limitations")

# ref 28 dropped
sub1("limitation orders \\cite{ref25,ref28} and limits the degree",
     "limitation orders \\cite{ref25} and limits the degree",
     "ref28 removed, methods")
sub1("intensity of interventions delivered \\cite{ref23,ref28}.",
     "intensity of interventions delivered \\cite{ref23}.",
     "ref28 removed, introduction")

# ref 20 dropped from the exclusion feasibility claim
sub1("Adding one narrow exclusion is feasible within existing\npractice \\cite{ref20}.",
     "Adding one narrow exclusion is feasible within existing practice.",
     "ref20 removed, remedy")

# refs 51 and 52 dropped
sub1("locate or internally contradictory \\cite{ref50,ref51}, and quality improvement\nwork has been required to correct it \\cite{ref52}. Units may limit treatment",
     "locate or internally contradictory \\cite{ref50}. Units may limit treatment",
     "ref51 and ref52 removed")

# switch to the verified BibTeX file
sub1("\\bibliographystyle{unsrt}\n\\input{references_inline}",
     "\\bibliographystyle{unsrt}\n\\bibliography{references}",
     "bibliography source switched to references.bib")

writeLines(strsplit(s, "\n")[[1]], tex, useBytes = TRUE)

# --- audit ------------------------------------------------------------------
cites <- unlist(regmatches(s, gregexpr("\\\\cite\\{[^}]+\\}", s)))
keys  <- sort(unique(as.integer(gsub("\\D", "", unlist(
  strsplit(gsub("\\\\cite\\{|\\}", "", cites), ","))))))
bib   <- readLines(file.path(proj, "submission", "references.bib"), warn = FALSE)
bibk  <- sort(unique(as.integer(gsub("\\D", "", regmatches(
  bib, regexpr("ref\\d+", bib))))))

cat(sprintf("\n\\cite keys in tex : %d\n", length(keys)))
cat(sprintf("entries in bib    : %d\n", length(bibk)))
gone <- intersect(keys, c(5, 18, 20, 28, 51, 52))
cat(sprintf("dropped refs cited: %s\n",
            if (length(gone)) paste(gone, collapse = ", ") else "none"))
orph <- setdiff(keys, bibk)
cat(sprintf("cited, not in bib : %s\n",
            if (length(orph)) paste(orph, collapse = ", ") else "none"))

old <- file.path(proj, "submission", "references_inline.tex")
if (file.exists(old) && !length(gone) && !length(orph)) {
  file.remove(old); cat("\ndeleted stale references_inline.tex\n")
} else if (file.exists(old)) {
  cat("\nkept references_inline.tex, resolve the issues above first\n")
}
