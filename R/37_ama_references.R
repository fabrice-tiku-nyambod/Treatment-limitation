# ---------------------------------------------------------------------------
# 37_ama_references.R
#
# Formats the bibliography in AMA style, which Journal of Intensive Care
# Medicine requires.
#
#   Surname AB, Surname CD, Surname EF. Title of article. Journal Abbrev.
#   Year;Volume(Issue):Pages. doi:10.xxxx/xxxxx
#
# AMA rules applied
#   - up to six authors listed in full; seven or more give the first three
#     followed by et al
#   - initials run together with no periods and no comma between them
#   - journal name as the NLM abbreviation, which is what E-utilities returns
#
# Writes references_ama.txt for the Word builder. references.bib is left
# untouched as the source of record.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
bib  <- paste(readLines(file.path(sub, "references.bib"), warn = FALSE,
                        encoding = "UTF-8"), collapse = "\n")

blocks <- regmatches(bib, gregexpr("(?s)@\\w+\\{ref\\d+,.*?\\n\\}", bib, perl = TRUE))[[1]]
cat(sprintf("parsed %d entries\n", length(blocks)))

fld <- function(b, f) {
  m <- regmatches(b, regexpr(sprintf("%s\\s*=\\s*\\{+[^}]*\\}+", f), b))
  if (!length(m)) return("")
  trimws(gsub("^\\{+|\\}+$", "", sub(sprintf("%s\\s*=\\s*", f), "", m)))
}

# "Knaus, William A" -> "Knaus WA"   |   "Barbash IJ" -> unchanged
to_ama <- function(a) {
  a <- trimws(a)
  if (grepl(",", a)) {
    p <- strsplit(a, ",")[[1]]
    surname <- trimws(p[1])
    given <- trimws(paste(p[-1], collapse = " "))
    inits <- paste(toupper(substr(strsplit(given, "\\s+")[[1]], 1, 1)), collapse = "")
    return(trimws(paste(surname, inits)))
  }
  a
}

fmt <- function(b, dash) {
  n  <- as.integer(gsub("\\D", "", regmatches(b, regexpr("ref\\d+", b))))
  au <- strsplit(fld(b, "author"), " and ")[[1]]
  au <- vapply(au, to_ama, character(1), USE.NAMES = FALSE)
  au <- au[nzchar(au)]
  authors <- if (length(au) > 6) paste0(paste(au[1:3], collapse = ", "), ", et al")
             else paste(au, collapse = ", ")
  ti <- sub("\\.$", "", fld(b, "title"))
  jo <- sub("\\.$", "", fld(b, "journal"))
  yr <- fld(b, "year"); vo <- fld(b, "volume")
  nu <- fld(b, "number"); pg <- gsub("--", dash, fld(b, "pages"))
  doi <- fld(b, "doi")
  s <- sprintf("%s. %s. %s. %s", authors, ti, jo, yr)
  if (nzchar(vo)) s <- paste0(s, ";", vo)
  if (nzchar(nu)) s <- paste0(s, "(", nu, ")")
  if (nzchar(pg)) s <- paste0(s, ":", pg)
  s <- paste0(s, ".")
  if (nzchar(doi)) s <- paste0(s, " doi:", doi)
  list(n = n, txt = s)
}

# --- plain text for the Word builder ----------------------------------------
recs <- lapply(blocks, fmt, dash = "-")
recs <- recs[order(sapply(recs, `[[`, "n"))]
txt <- vapply(recs, function(r) sprintf("%d. %s", r$n, r$txt), character(1))
writeLines(txt, file.path(sub, "references_ama.txt"), useBytes = TRUE)
cat(sprintf("wrote references_ama.txt, %d entries\n", length(txt)))

cat("\nfirst three, as they will appear\n")
for (i in 1:3) cat(sprintf("  %s\n", txt[i]))
cat("\nan entry with more than six authors\n")
long <- which(grepl("et al", txt))[1]
if (!is.na(long)) cat(sprintf("  %s\n", txt[long]))
