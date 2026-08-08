# ---------------------------------------------------------------------------
# 30_renumber_bib.R
#
# The manuscript was renumbered to sequential order of first citation, but
# references.bib and Manuscript.tex still carry the original arbitrary keys.
# That left the Word reference list mismatched, 42 entries against 46 citations.
#
# This rewrites both to the new numbering so every artefact agrees.
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
map  <- read.csv(file.path(proj, "results", "reference_renumber_map.csv"))
cat(sprintf("mapping %d references\n", nrow(map)))

# --- bibliography ------------------------------------------------------------
bibf <- file.path(proj, "submission", "references.bib")
file.copy(bibf, paste0(bibf, ".bak"), overwrite = TRUE)
b <- paste(readLines(bibf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

blocks <- regmatches(b, gregexpr("(?s)@\\w+\\{ref\\d+,.*?\\n\\}", b, perl = TRUE))[[1]]
key <- as.integer(gsub("\\D", "", regmatches(blocks, regexpr("ref\\d+", blocks))))
cat(sprintf("entries in bib: %d\n", length(blocks)))

keep <- data.frame(old = key, block = blocks, stringsAsFactors = FALSE)
keep <- merge(keep, map, by = "old")
keep <- keep[order(keep$new), ]
cat(sprintf("entries matched to a citation: %d\n", nrow(keep)))
missing <- setdiff(map$old, key)
if (length(missing))
  cat(sprintf("CITED BUT ABSENT FROM BIB: old %s\n", paste(missing, collapse = ", ")))

out <- c("% Renumbered to order of first citation by R/30_renumber_bib.R.",
         "% Field values are unchanged and remain as verified against PubMed",
         "% and Crossref. Only the citation keys were remapped.", "")
for (i in seq_len(nrow(keep))) {
  blk <- sub("\\{ref\\d+,", sprintf("{ref%d,", keep$new[i]), keep$block[i])
  out <- c(out, blk, "")
}
writeLines(out, bibf, useBytes = TRUE)
cat(sprintf("wrote references.bib with %d entries, keys 1 to %d\n",
            nrow(keep), max(keep$new)))

# --- LaTeX cite keys ---------------------------------------------------------
texf <- file.path(proj, "submission", "Manuscript.tex")
s <- paste(readLines(texf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# two stage swap through a placeholder, so remapped keys are not remapped again
for (i in seq_len(nrow(map)))
  s <- gsub(sprintf("ref%d\\b", map$old[i]), sprintf("TMPREF%d", map$new[i]), s, perl = TRUE)
s <- gsub("TMPREF", "ref", s, fixed = TRUE)
writeLines(strsplit(s, "\n")[[1]], texf, useBytes = TRUE)

cites <- unlist(regmatches(s, gregexpr("\\\\cite\\{[^}]+\\}", s)))
keys <- sort(unique(as.integer(gsub("\\D", "", unlist(
  strsplit(gsub("\\\\cite\\{|\\}", "", cites), ","))))))
cat(sprintf("tex cite keys now: %d, range %d to %d\n",
            length(keys), min(keys), max(keys)))

bibk <- sort(as.integer(gsub("\\D", "", regmatches(
  readLines(bibf, warn = FALSE),
  regexpr("ref\\d+", readLines(bibf, warn = FALSE))))))
bibk <- bibk[!is.na(bibk)]
orph <- setdiff(keys, bibk)
cat(sprintf("cited but not in bib: %s\n",
            if (length(orph)) paste(orph, collapse = ", ") else "none"))
