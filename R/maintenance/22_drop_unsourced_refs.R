# ---------------------------------------------------------------------------
# 22_drop_unsourced_refs.R
#
# Removes seven references the author could not source, and repairs the
# manuscript sentences that depended on them.
#
# NOTE: ref 2 (Knaus APACHE II 1985) was verified from the scanned PDF in the
# project folder. It is removed here on instruction, not because it failed
# verification. Restoring it means re-adding the bib entry and the citation in
# Introduction paragraph 3.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))
proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
DROP <- c(2, 5, 18, 20, 28, 51, 52)

# --- 1. strip from references.bib ------------------------------------------
bib <- file.path(proj, "submission", "references.bib")
L   <- readLines(bib, warn = FALSE)
st  <- grep("^@(article|techreport)\\{", L)
en  <- sapply(st, function(s) { j <- s; while (!grepl("^\\}", L[j])) j <- j + 1; j })
ky  <- as.integer(gsub("\\D", "", regmatches(L[st], regexpr("ref\\d+", L[st]))))
kill <- which(ky %in% DROP)
if (length(kill)) L <- L[-unlist(Map(`:`, st[kill], en[kill]))]
writeLines(L, bib)
left <- sort(as.integer(gsub("\\D", "", regmatches(
  L[grep("^@", L)], regexpr("ref\\d+", L[grep("^@", L)])))))
cat(sprintf("references.bib: removed %d, %d entries remain\n",
            length(kill), length(left)))

# --- 2. repair the manuscript ----------------------------------------------
mf <- file.path(proj, "MANUSCRIPT_v4.md")
m  <- readLines(mf, warn = FALSE, encoding = "UTF-8")
txt <- paste(m, collapse = "\n")

# sentences whose ONLY support was a dropped reference
fix <- list(
  # ref 5 was the sole support; ref 9 covers subgroup performance
  c("Performance also differs across patient\nsubgroups (5) and across ethnic groups within the same health system\n(9).",
    "Performance also differs across ethnic groups within the same health\nsystem (9)."),
  # ref 28 dropped, ref 25 carries the 24 hour window
  c("The 24 hour window follows prior work distinguishing early from late\nlimitation orders (25, 28) and limits",
    "The 24 hour window follows prior work distinguishing early from late\nlimitation orders (25) and limits"),
  # ref 20 dropped from the reimbursement claim
  c("divided by predicted deaths, and in some systems reimbursed on that basis (12, 20). The",
    "divided by predicted deaths, and in some systems reimbursed on that basis (12). The"),
  # ref 18 dropped, ref 19 carries misspecification
  c("Model misspecification introduces bias into the resulting\nquality measures (18, 19), and",
    "Model misspecification introduces bias into the resulting\nquality measures (19), and"),
  c("Misspecification of the adjustment model is\nitself a recognised source of bias in quality measurement (18, 19).",
    "Misspecification of the adjustment model is\nitself a recognised source of bias in quality measurement (19)."),
  c("Adjusting for a variable partly under unit\ncontrol carries the hazards of mediator adjustment (18).",
    "Adjusting for a variable partly under unit\ncontrol carries the hazards of mediator adjustment."),
  # ref 20 dropped from the exclusion feasibility claim
  c("Adding one narrow exclusion is feasible within existing\npractice (20).",
    "Adding one narrow exclusion is feasible within existing practice."),
  # refs 51 and 52 dropped; ref 50 carries documentation quality
  c("Code\nstatus documentation in electronic records is frequently incomplete, difficult to\nlocate or internally contradictory (50, 51), and quality improvement\nwork has been required to correct it (52). Units",
    "Code\nstatus documentation in electronic records is frequently incomplete, difficult to\nlocate or internally contradictory (50). Units"),
  # ref 2 dropped from the APACHE lineage sentence
  c("The APACHE method was introduced in 1985 (2) and the APACHE\nIVa model was derived from",
    "The APACHE IVa model was derived from")
)

applied <- 0
for (f in fix) {
  if (grepl(f[1], txt, fixed = TRUE)) {
    txt <- sub(f[1], f[2], txt, fixed = TRUE); applied <- applied + 1
  } else cat("  NOT FOUND, fix by hand:", substr(f[1], 1, 60), "...\n")
}
writeLines(strsplit(txt, "\n")[[1]], mf, useBytes = TRUE)
cat(sprintf("manuscript: %d of %d repairs applied\n", applied, length(fix)))

# --- 3. audit ---------------------------------------------------------------
mm <- paste(readLines(mf, warn = FALSE), collapse = "\n")
cit <- unique(as.integer(unlist(lapply(
  regmatches(mm, gregexpr("\\(([0-9]+(,\\s*[0-9]+)*)\\)", mm))[[1]],
  function(s) strsplit(gsub("[()\\s]", "", s), ",")[[1]]))))
cit <- sort(cit[!is.na(cit) & cit <= 56])
cat(sprintf("\nunique references now cited: %d\n", length(cit)))
still <- intersect(cit, DROP)
if (length(still)) cat(sprintf("STILL CITING DROPPED REFS: %s\n", paste(still, collapse=", ")))
orph <- setdiff(cit, left)
if (length(orph)) cat(sprintf("cited but absent from bib: %s\n", paste(orph, collapse=", ")))
if (!length(still) && !length(orph)) cat("clean: every citation resolves to a verified entry\n")
