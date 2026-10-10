# ---------------------------------------------------------------------------
# 46_cja_redundancy_pass.R
#
# First shortening pass for the Canadian Journal of Anesthesia: removes only
# text that repeats something stated elsewhere in the manuscript. Reads the
# hand edited Manuscript.docx (never written to) and writes a copy in which each
# deletion is a Word tracked change, highlighted yellow, for the author to
# review and accept. No deletion removes the only citation of a reference, so
# the reference numbering is unchanged.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(xml2))

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
src  <- file.path(sub, "Manuscript.docx")
out  <- file.path(sub, "Manuscript_CJA_pass1_redundancy.docx")

AUTHOR <- "Fabrice T. Nyambod"
DATE   <- "2026-10-06T00:00:00Z"

# Each entry is an exact substring of one paragraph; it must occur once.
cuts <- c(
  # Results repeat the Introduction's point about calibration failing first (19)
  " This pattern of preserved discrimination with failed calibration matches that described for severity scores in contemporary cohorts (19).",
  # 38 units, 23.5% is already reported under Consequences for benchmarking
  " Full adjustment for the ordered limitation scale reclassified 38 units, or 23.5%.",
  # Interpretation repeated in the Discussion, Timing of the order
  " Most comfort measures orders in the first day therefore followed an initial decision to treat.",
  # Median odds ratios for any limitation already given in the mixed effects paragraph
  ", against 1.69 and 1.80 for any limitation",
  # Introduction already lists what early and late orders may signify
  ", and the two may signify different things: a poor prognosis evident on arrival, the immediate availability of a family member, the communication practice of the clinician or unit, or a failed intervention",
  # Restates the sentence before it
  " A comfort measures order carried a mortality far beyond what the score predicted whether it was written on arrival or after an initial trial of treatment.",
  # Ratios already reported in Results, Timing of limitation orders
  " Units in the highest limitation quintile documented early limitation 3.5 times as often as those in the lowest after case mix was balanced, against 2.2 times for late orders.",
  # Four fifths already reported in Results
  ", and roughly four fifths of the practice difference persisted",
  # Ref 5 already made the same point in the Introduction
  ", and units at opposite extremes of treatment intensity have been shown to differ in decision making norms rather than in the patients they admit (5)",
  # Restated two sentences later in the same paragraph and in the opening paragraph
  "Accounting for limitation moved 23.5% of units across quartiles and reversed outlier classification for 8.0%. ",
  # Glance (22) and admission patterns (24) already cited in the Introduction
  " Glance and colleagues reached a similar conclusion comparing scoring systems (22), and admission patterns alone have been shown to shift these measures (24).",
  # Opening sentence of the paragraph already says the study does not resolve it
  "does not settle the question. It ",
  # Repeated in Implications and the Conclusion
  " Excluding admissions under comfort measures orders affects six patients in every thousand and recovers half the effect."
)

tmp <- tempfile(); dir.create(tmp)
unzip(src, exdir = tmp)
docxml <- file.path(tmp, "word", "document.xml")
doc <- read_xml(docxml)
ns  <- xml_ns(doc)

paras <- xml_find_all(doc, "//w:body//w:p", ns)
ptext <- vapply(paras, function(p)
  paste(xml_text(xml_find_all(p, ".//w:r/w:t", ns)), collapse = ""), "")

next_id <- 9000L

# Split run `r` so that characters [a, b] (1-based, within the run) sit in their own run.
split_run <- function(r, a, b) {
  t <- xml_find_first(r, "w:t", ns); s <- xml_text(t); n <- nchar(s)
  pieces <- list(c(1, a - 1), c(a, b), c(b + 1, n))
  mid <- NULL
  for (k in seq_along(pieces)) {
    lo <- pieces[[k]][1]; hi <- pieces[[k]][2]
    if (hi < lo) next
    nr <- xml_add_sibling(r, r, .where = "before")
    nt <- xml_find_first(nr, "w:t", ns)
    xml_text(nt) <- substr(s, lo, hi)
    xml_set_attr(nt, "xml:space", "preserve")
    if (k == 2) mid <- nr
  }
  xml_remove(r)
  mid
}

mark_deleted <- function(r) {
  rpr <- xml_find_first(r, "w:rPr", ns)
  if (inherits(rpr, "xml_missing")) rpr <- xml_add_child(r, "w:rPr", .where = 0)
  hl <- xml_find_first(rpr, "w:highlight", ns)
  if (inherits(hl, "xml_missing")) xml_add_child(rpr, "w:highlight", "w:val" = "yellow")
  else xml_set_attr(hl, "w:val", "yellow")
  t <- xml_find_first(r, "w:t", ns); xml_set_name(t, "delText")   # keeps the w namespace
  del <- xml_add_sibling(r, "w:del", .where = "before")
  xml_set_attrs(del, c("w:id" = as.character(next_id), "w:author" = AUTHOR, "w:date" = DATE))
  next_id <<- next_id + 1L
  xml_add_child(del, r); xml_remove(r)
}

removed_words <- 0
for (cut in cuts) {
  hits <- which(vapply(ptext, function(s) grepl(cut, s, fixed = TRUE), TRUE))
  if (length(hits) != 1) stop("expected one paragraph for: ", substr(cut, 1, 60), " (found ", length(hits), ")")
  if (lengths(regmatches(ptext[hits], gregexpr(cut, ptext[hits], fixed = TRUE))) != 1)
    stop("cut occurs more than once: ", substr(cut, 1, 60))
  p <- paras[[hits]]
  start <- regexpr(cut, ptext[hits], fixed = TRUE)[1]; end <- start + nchar(cut) - 1

  runs <- xml_find_all(p, ".//w:r[w:t]", ns)
  lens <- nchar(vapply(runs, function(r) xml_text(xml_find_first(r, "w:t", ns)), ""))
  ends <- cumsum(lens); starts <- ends - lens + 1
  for (j in rev(which(ends >= start & starts <= end))) {
    a <- max(start, starts[j]) - starts[j] + 1
    b <- min(end, ends[j]) - starts[j] + 1
    mark_deleted(split_run(runs[[j]], a, b))
  }
  ptext[hits] <- paste0(substr(ptext[hits], 1, start - 1), substr(ptext[hits], end + 1, nchar(ptext[hits])))
  removed_words <- removed_words + length(strsplit(trimws(cut), "[[:space:]]+")[[1]])
}

write_xml(doc, docxml, options = "as_xml")   # no reformatting of whitespace
if (file.exists(out)) file.remove(out)
zip::zip(out, files = list.files(tmp, recursive = TRUE, all.files = TRUE), root = tmp)
cat(sprintf("wrote %s: %d tracked deletions, about %d words\n", basename(out), length(cuts), removed_words))
