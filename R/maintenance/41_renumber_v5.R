# ---------------------------------------------------------------------------
# 41_renumber_v5.R
#
# One time. Renumbers references in MANUSCRIPT.md to order of first
# appearance and remaps references.bib to match. The two references added for
# the JICM revision (STROBE, time limited trials) were appended as 47 and 48
# and are cited early in the text, so everything after them shifts.
#
# Run from the project root. Then run R/37_ama_references.R.
# ---------------------------------------------------------------------------

proj <- normalizePath(".", winslash = "/")
md   <- file.path(proj, "MANUSCRIPT.md")
bibf <- file.path(proj, "submission_jicm", "references.bib")

s <- paste(readLines(md, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
body_start <- regexpr("## 1. Introduction", s, fixed = TRUE)
stopifnot(body_start > 0)
body <- substr(s, body_start, nchar(s))

# citation groups are "(n)" or "(n, m, ...)" with nothing but digits, commas
# and spaces inside, which excludes confidence intervals and P values
m     <- gregexpr("\\((\\d+(?:,\\s*\\d+)*)\\)", body, perl = TRUE)
hits  <- regmatches(body, m)[[1]]
seen  <- integer(0)
for (h in hits) {
  ns <- as.integer(strsplit(gsub("[()\\s]", "", h, perl = TRUE), ",")[[1]])
  for (n in ns) if (!(n %in% seen)) seen <- c(seen, n)
}
cat(sprintf("citation groups %d, unique references %d\n", length(hits), length(seen)))
map <- setNames(seq_along(seen), as.character(seen))
changed <- seen[seen != seq_along(seen)]
cat(sprintf("references changing number: %s\n",
            if (length(changed)) paste(changed, collapse = ", ") else "none"))

starts <- m[[1]]; lens <- attr(m[[1]], "match.length")
out <- character(0); prev <- 1
for (i in seq_along(starts)) {
  out <- c(out, substr(body, prev, starts[i] - 1))
  ns  <- as.integer(strsplit(gsub("[()\\s]", "", hits[i], perl = TRUE), ",")[[1]])
  out <- c(out, sprintf("(%s)", paste(map[as.character(ns)], collapse = ", ")))
  prev <- starts[i] + lens[i]
}
out <- c(out, substr(body, prev, nchar(body)))
s <- paste0(substr(s, 1, body_start - 1), paste(out, collapse = ""))
writeLines(strsplit(s, "\n")[[1]], md, useBytes = TRUE)

# --- bibliography ------------------------------------------------------------
b <- paste(readLines(bibf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
blocks <- regmatches(b, gregexpr("(?s)@\\w+\\{ref\\d+,.*?\\n\\}", b, perl = TRUE))[[1]]
key <- as.integer(gsub("\\D", "", regmatches(blocks, regexpr("ref\\d+", blocks))))
missing <- setdiff(seen, key)
if (length(missing)) stop("cited but absent from bib: ", paste(missing, collapse = ", "))
uncited <- setdiff(key, seen)
if (length(uncited)) cat(sprintf("in bib but not cited, dropped: %s\n", paste(uncited, collapse = ", ")))

keep <- data.frame(old = key, block = blocks, stringsAsFactors = FALSE)
keep <- keep[keep$old %in% seen, ]
keep$new <- map[as.character(keep$old)]
keep <- keep[order(keep$new), ]
hdr <- c("% Renumbered to order of first citation in MANUSCRIPT.md by",
         "% R/maintenance/41_renumber_v5.R. Field values are unchanged and remain",
         "% as verified against PubMed and Crossref. Only the keys were remapped.", "")
outb <- hdr
for (i in seq_len(nrow(keep)))
  outb <- c(outb, sub("\\{ref\\d+,", sprintf("{ref%d,", keep$new[i]), keep$block[i]), "")
writeLines(outb, bibf, useBytes = TRUE)
cat(sprintf("wrote references.bib with %d entries, keys 1 to %d\n", nrow(keep), max(keep$new)))
write.csv(data.frame(old = seen, new = seq_along(seen)),
          file.path(proj, "results", "reference_renumber_map_v5.csv"), row.names = FALSE)
