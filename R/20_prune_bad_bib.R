# ---------------------------------------------------------------------------
# 20_prune_bad_bib.R
#
# The title search in script 19 returned the wrong paper for four references.
# PubMed relevance ranking does not guarantee a title match, and an entry that
# looks structurally valid is still fabricated if it is the wrong article.
#
# This removes them and reports what remains outstanding. Refs 2, 28, 51 and 52
# must be completed by hand from the source record.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))
proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
bib  <- file.path(proj, "submission", "references.bib")

BAD <- c(2, 28, 51, 52)   # verified wrong by title inspection

lines  <- readLines(bib, warn = FALSE)
starts <- grep("^@article\\{", lines)
ends   <- sapply(starts, function(s) { j <- s; while (lines[j] != "}") j <- j + 1; j })
keys   <- as.integer(gsub("\\D", "", sub("^@article\\{ref", "", lines[starts])))

drop <- unlist(Map(function(s, e) s:e, starts[keys %in% BAD], ends[keys %in% BAD]))
if (length(drop)) lines <- lines[-drop]
writeLines(lines, bib)

kept <- as.integer(gsub("\\D", "", sub("^@article\\{ref", "",
                    lines[grep("^@article\\{", lines)])))
cat(sprintf("removed %d incorrect entries: %s\n", length(BAD),
            paste(BAD, collapse = ", ")))
cat(sprintf("entries remaining in references.bib: %d\n", length(kept)))

cited <- c(1,2,5,6,7,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,
           29,30,31,32,33,34,35,36,37,39,40,41,42,43,44,45,46,47,48,49,50,51,52,
           53,54,55,56)
missing <- setdiff(cited, kept)
cat(sprintf("\ncited in manuscript but NOT in bib: %d\n", length(missing)))
cat("  ", paste(missing, collapse = ", "), "\n")

lab <- c("2"  = "Knaus APACHE II 1985, Crit Care Med",
         "5"  = "APACHE IVa explained variance, Southwest J Pulm Crit Care (not PubMed indexed)",
         "18" = "Misspecification in risk adjustment, Health Serv Outcomes Res Methodol (not indexed)",
         "20" = "CMS Risk Adjustment in Quality Measurement (technical document, not indexed)",
         "28" = "Timing of DNR orders, Acute Crit Care",
         "51" = "Inaccurate or inadequate code status documentation, CHEST",
         "52" = "EMR code status documentation QI, J Healthc Qual")
cat("\nmanual completion required:\n")
for (m in as.character(missing))
  cat(sprintf("  ref %-3s %s\n", m, if (m %in% names(lab)) lab[[m]] else "see REFERENCES.md"))
