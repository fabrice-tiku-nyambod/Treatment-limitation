# ---------------------------------------------------------------------------
# 18_verify_references.R
#
# Resolves every reference to a PMID and pulls the authoritative citation
# record from NCBI E-utilities. Writes references.bib and a report of what
# could not be resolved.
#
# Nothing is written from memory. Anything E-utilities does not return is
# reported as unresolved rather than filled in.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(httr); library(jsonlite)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
md   <- readLines(file.path(proj, "REFERENCES.md"), warn = FALSE)

# --- pull identifiers out of the library -----------------------------------
recs <- list(); cur <- NULL
for (ln in md) {
  m <- regmatches(ln, regexpr("^\\s*(\\d{1,2})\\.\\s", ln))
  if (length(m)) {
    n <- as.integer(gsub("[^0-9]", "", m))
    if (n >= 1 && n <= 56) { cur <- as.character(n); recs[[cur]] <- "" }
  }
  if (!is.null(cur)) recs[[cur]] <- paste(recs[[cur]], ln)
}

grab <- function(txt, pat) {
  m <- regmatches(txt, regexpr(pat, txt, perl = TRUE))
  if (length(m)) m else NA_character_
}

ids <- rbindlist(lapply(names(recs), function(k) {
  t <- recs[[k]]
  data.table(ref = as.integer(k),
             pmid = gsub("\\D", "", grab(t, "pubmed\\.ncbi\\.nlm\\.nih\\.gov/\\d+")),
             pmc  = toupper(grab(t, "PMC\\d+")),
             doi  = grab(t, "10\\.\\d{4,9}/[^\\s,;\\]]+"))
}))
ids[pmid == "", pmid := NA_character_]
ids[, doi := gsub("[.\\)]+$", "", doi)]
setorder(ids, ref)
cat(sprintf("references parsed: %d\n", nrow(ids)))
cat(sprintf("  with PMID %d, with PMC %d, with DOI %d\n",
            sum(!is.na(ids$pmid)), sum(!is.na(ids$pmc)), sum(!is.na(ids$doi))))

pause <- function() Sys.sleep(0.34)   # NCBI rate limit, 3 per second

# --- PMC -> PMID -----------------------------------------------------------
need <- ids[is.na(pmid) & !is.na(pmc)]
if (nrow(need)) {
  cat(sprintf("\nconverting %d PMC identifiers\n", nrow(need)))
  for (i in seq_len(nrow(need))) {
    r <- tryCatch(GET("https://www.ncbi.nlm.nih.gov/pmc/utils/idconv/v1.0/",
                      query = list(ids = need$pmc[i], format = "json")),
                  error = function(e) NULL)
    if (!is.null(r) && status_code(r) == 200) {
      j <- fromJSON(content(r, "text", encoding = "UTF-8"))
      if (!is.null(j$records$pmid)) ids[ref == need$ref[i], pmid := j$records$pmid[1]]
    }
    pause()
  }
}

# --- DOI -> PMID -----------------------------------------------------------
need <- ids[is.na(pmid) & !is.na(doi)]
if (nrow(need)) {
  cat(sprintf("searching PubMed for %d DOIs\n", nrow(need)))
  for (i in seq_len(nrow(need))) {
    r <- tryCatch(GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esearch.fcgi",
                      query = list(db = "pubmed", retmode = "json",
                                   term = paste0(need$doi[i], "[DOI]"))),
                  error = function(e) NULL)
    if (!is.null(r) && status_code(r) == 200) {
      j <- fromJSON(content(r, "text", encoding = "UTF-8"))
      il <- j$esearchresult$idlist
      if (length(il)) ids[ref == need$ref[i], pmid := il[1]]
    }
    pause()
  }
}

resolved <- ids[!is.na(pmid)]
cat(sprintf("\nresolved to PMID: %d of %d\n", nrow(resolved), nrow(ids)))

# --- bulk esummary ---------------------------------------------------------
fetch <- function(pmids) {
  r <- GET("https://eutils.ncbi.nlm.nih.gov/entrez/eutils/esummary.fcgi",
           query = list(db = "pubmed", retmode = "json",
                        id = paste(pmids, collapse = ",")))
  if (status_code(r) != 200) return(NULL)
  fromJSON(content(r, "text", encoding = "UTF-8"), simplifyVector = FALSE)$result
}

out <- list(); chunks <- split(resolved$pmid, ceiling(seq_len(nrow(resolved))/40))
for (ch in chunks) { out <- c(out, fetch(ch)); pause() }
out[["uids"]] <- NULL

meta <- rbindlist(lapply(names(out), function(p) {
  r <- out[[p]]
  au <- if (length(r$authors)) sapply(r$authors, function(a) a$name) else character(0)
  doi <- NA_character_
  if (length(r$articleids))
    for (a in r$articleids) if (identical(a$idtype, "doi")) doi <- a$value
  data.table(pmid = p,
             authors = paste(au, collapse = ", "),
             n_authors = length(au),
             title = sub("\\.$", "", r$title %||% NA),
             journal = r$source %||% NA,
             year = substr(r$pubdate %||% "", 1, 4),
             volume = r$volume %||% NA,
             issue = r$issue %||% NA,
             pages = r$pages %||% NA,
             doi = doi)
}), fill = TRUE)

`%||%` <- function(a, b) if (is.null(a)) b else a
setnames(ids, "doi", "doi_src")          # avoid a doi.x / doi.y collision
full <- merge(ids, meta, by = "pmid", all.x = TRUE)
full[is.na(doi) | doi == "", doi := doi_src]
setorder(full, ref)

ok <- full[!is.na(journal) & !is.na(year)]
cat(sprintf("citation records retrieved: %d\n", nrow(ok)))
cat(sprintf("with volume and pages     : %d\n",
            nrow(ok[!is.na(volume) & volume != "" & !is.na(pages) & pages != ""])))

fwrite(full, file.path(proj, "results", "reference_metadata.csv"))

# --- write BibTeX ----------------------------------------------------------
esc <- function(s) { s[is.na(s)] <- ""; gsub("([&%$#_])", "\\\\\\1", s) }
lines <- c("% Auto generated by R/18_verify_references.R from NCBI E-utilities.",
           "% Every field below comes from the PubMed record, not from memory.", "")
for (i in seq_len(nrow(full))) {
  r <- full[i]
  if (is.na(r$journal)) next
  lines <- c(lines,
    sprintf("@article{ref%d,", r$ref),
    sprintf("  author  = {%s},", esc(gsub(", ", " and ", r$authors))),
    sprintf("  title   = {{%s}},", esc(r$title)),
    sprintf("  journal = {%s},", esc(r$journal)),
    sprintf("  year    = {%s},", r$year),
    if (!is.na(r$volume) && r$volume != "") sprintf("  volume  = {%s},", r$volume),
    if (!is.na(r$issue)  && r$issue  != "") sprintf("  number  = {%s},", r$issue),
    if (!is.na(r$pages)  && r$pages  != "") sprintf("  pages   = {%s},", r$pages),
    if (length(r$doi) && !is.na(r$doi) && r$doi != "")
      sprintf("  doi     = {%s},", r$doi),
    sprintf("  pmid    = {%s}", r$pmid), "}", "")
}
writeLines(lines, file.path(proj, "submission", "references.bib"))
cat("\nwrote submission/references.bib\n")

unres <- full[is.na(journal), .(ref, pmid, pmc, doi = doi_src)]
if (nrow(unres)) {
  cat("\nUNRESOLVED, need manual completion:\n")
  print(unres, row.names = FALSE)
} else cat("\nall references resolved\n")
