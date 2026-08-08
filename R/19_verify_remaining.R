# ---------------------------------------------------------------------------
# 19_verify_remaining.R
# Second pass for the 11 references E-utilities could not resolve by
# identifier. Searches PubMed by title, then merges into references.bib.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(httr); library(jsonlite)
})
proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
pause <- function() Sys.sleep(0.34)

targets <- data.table(
  ref = c(2, 5, 18, 20, 25, 28, 46, 47, 51, 52, 54),
  query = c(
    "APACHE II severity of disease classification system Knaus",
    "explained variance discriminant accuracy APACHE IVa severity scoring subgroups",
    "misspecification issues risk adjustment construction outcome based quality indicators",
    NA,  # CMS technical document, not indexed
    "Timing is everything early do-not-resuscitate orders intensive care unit patient outcomes",
    "Effect of timing of do-not-resuscitate orders clinical outcome critically ill patients",
    "eICU Collaborative Research Database freely available multi-center database critical care research",
    "Identifying early-measured variables associated with APACHE IVa incorrect in-hospital mortality predictions",
    "frequency of inaccurate or inadequate code status documentation",
    "Using the Electronic Medical Record to Address Code Status Documentation quality improvement",
    "Palliative care for terminally ill patients in the intensive care unit systematic review meta-analysis"))

esearch <- function(term) {
  r <- tryCatch(GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi",
                    query = list(db = "pubmed", retmode = "json",
                                 retmax = 3, term = term)),
                error = function(e) NULL)
  if (is.null(r) || status_code(r) != 200) return(character(0))
  fromJSON(content(r, "text", encoding = "UTF-8"))$esearchresult$idlist
}

summ <- function(pmid) {
  r <- GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi",
           query = list(db = "pubmed", retmode = "json", id = pmid))
  if (status_code(r) != 200) return(NULL)
  fromJSON(content(r, "text", encoding = "UTF-8"), simplifyVector = FALSE)$result[[pmid]]
}

found <- list()
for (i in seq_len(nrow(targets))) {
  tg <- targets[i]
  if (is.na(tg$query)) { cat(sprintf("ref %-2d  not indexed in PubMed, skipping\n", tg$ref)); next }
  hits <- esearch(tg$query); pause()
  if (!length(hits)) { cat(sprintf("ref %-2d  NO HIT\n", tg$ref)); next }
  s <- summ(hits[1]); pause()
  if (is.null(s)) { cat(sprintf("ref %-2d  summary failed\n", tg$ref)); next }
  au <- if (length(s$authors)) sapply(s$authors, function(a) a$name) else character(0)
  doi <- NA_character_
  if (length(s$articleids)) for (a in s$articleids)
    if (identical(a$idtype, "doi")) doi <- a$value
  found[[as.character(tg$ref)]] <- data.table(
    ref = tg$ref, pmid = hits[1],
    authors = paste(au, collapse = ", "),
    title = sub("\\.$", "", s$title),
    journal = s$source, year = substr(s$pubdate, 1, 4),
    volume = s$volume %||% "", issue = s$issue %||% "",
    pages = s$pages %||% "", doi = doi)
  cat(sprintf("ref %-2d  %s %s;%s(%s):%s\n", tg$ref, s$source,
              substr(s$pubdate,1,4), s$volume, s$issue, s$pages))
}
`%||%` <- function(a,b) if (is.null(a)) b else a

if (length(found)) {
  add <- rbindlist(found, fill = TRUE)
  fwrite(add, file.path(proj, "results", "reference_metadata_pass2.csv"))
  esc <- function(s) { s[is.na(s)] <- ""; gsub("([&%$#_])", "\\\\\\1", s) }
  lines <- c("", "% ---- second pass, resolved by title search ----", "")
  for (i in seq_len(nrow(add))) {
    r <- add[i]
    lines <- c(lines,
      sprintf("@article{ref%d,", r$ref),
      sprintf("  author  = {%s},", esc(gsub(", ", " and ", r$authors))),
      sprintf("  title   = {{%s}},", esc(r$title)),
      sprintf("  journal = {%s},", esc(r$journal)),
      sprintf("  year    = {%s},", r$year),
      if (r$volume != "") sprintf("  volume  = {%s},", r$volume),
      if (r$issue  != "") sprintf("  number  = {%s},", r$issue),
      if (r$pages  != "") sprintf("  pages   = {%s},", r$pages),
      if (!is.na(r$doi))  sprintf("  doi     = {%s},", r$doi),
      sprintf("  pmid    = {%s}", r$pmid), "}", "")
  }
  cat(lines, file = file.path(proj, "submission", "references.bib"),
      sep = "\n", append = TRUE)
  cat(sprintf("\nappended %d entries to references.bib\n", nrow(add)))
}

bib <- readLines(file.path(proj, "submission", "references.bib"))
cat(sprintf("total entries in references.bib: %d\n",
            sum(grepl("^@article", bib))))
