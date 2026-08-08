# ---------------------------------------------------------------------------
# 28_renumber.R
#
# 1. Renumbers references sequentially by order of first appearance, so the
#    Introduction opens at 1 rather than 31.
# 2. Moves Figure 1, Table 3 and Table 4 to the supplement and renumbers the
#    survivors.
# 3. Rewrites every in-text reference to a table or figure to match.
#
# Nothing else in the manuscript is altered.
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
md   <- file.path(proj, "MANUSCRIPT_v4.md")
s    <- paste(readLines(md, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# --- 1. citation order -------------------------------------------------------
# body starts at Introduction; the abstract carries no citations
body_start <- regexpr("## Introduction", s, fixed = TRUE)
body <- substr(s, body_start, nchar(s))

m <- gregexpr("\\((\\d+(?:,\\s*\\d+)*)\\)", body, perl = TRUE)
hits <- regmatches(body, m)[[1]]
cat(sprintf("citation groups found: %d\n", length(hits)))

seen <- integer(0)
for (h in hits) {
  ns <- as.integer(strsplit(gsub("[()\\s]", "", h), ",")[[1]])
  for (n in ns) if (!(n %in% seen)) seen <- c(seen, n)
}
cat(sprintf("unique references: %d\n", length(seen)))
cat(sprintf("first ten in order of appearance: %s\n",
            paste(head(seen, 10), collapse = ", ")))

map <- setNames(seq_along(seen), as.character(seen))
write.csv(data.frame(old = seen, new = seq_along(seen)),
          file.path(proj, "results", "reference_renumber_map.csv"),
          row.names = FALSE)

# rewrite citation groups, whole-group at a time to avoid collisions
newbody <- body
locs <- regmatches(body, m)[[1]]
starts <- m[[1]]; lens <- attr(m[[1]], "match.length")
out <- character(0); prev <- 1
for (i in seq_along(starts)) {
  out <- c(out, substr(body, prev, starts[i] - 1))
  ns <- as.integer(strsplit(gsub("[()\\s]", "", locs[i]), ",")[[1]])
  out <- c(out, sprintf("(%s)", paste(map[as.character(ns)], collapse = ", ")))
  prev <- starts[i] + lens[i]
}
out <- c(out, substr(body, prev, nchar(body)))
newbody <- paste(out, collapse = "")

s <- paste0(substr(s, 1, body_start - 1), newbody)

# --- 2. tables and figures ---------------------------------------------------
# Table 5 -> Table 3, Table 3 -> Table S1, Table 4 -> Table S2
# Figure 2 -> Figure 1, Figure 3 -> Figure 2, Figure 4 -> Figure 3
# Figure 1 -> Figure S1
tf <- list(
  c("Table~\\ref{tab:remedy}", "TMP_T3"), c("Table 5", "TMP_T3"),
  c("Table~\\ref{tab:discrim}", "TMP_TS1"), c("Table 3", "TMP_TS1"),
  c("Table~\\ref{tab:rank}", "TMP_TS2"), c("Table 4", "TMP_TS2"),
  c("Figure~\\ref{fig:performance}", "TMP_F1"), c("Figure 2", "TMP_F1"),
  c("Figure~\\ref{fig:variation}", "TMP_F2"), c("Figure 3", "TMP_F2"),
  c("Figure~\\ref{fig:benchmarking}", "TMP_F3"), c("Figure 4", "TMP_F3"),
  c("Figure~\\ref{fig:flow}", "TMP_FS1"), c("Figure 1", "TMP_FS1")
)
for (p in tf) s <- gsub(p[1], p[2], s, fixed = TRUE)
final <- list(c("TMP_T3", "Table 3"), c("TMP_TS1", "Table S1"),
              c("TMP_TS2", "Table S2"), c("TMP_F1", "Figure 1"),
              c("TMP_F2", "Figure 2"), c("TMP_F3", "Figure 3"),
              c("TMP_FS1", "Figure S1"))
for (p in final) s <- gsub(p[1], p[2], s, fixed = TRUE)

writeLines(strsplit(s, "\n")[[1]], md, useBytes = TRUE)

# --- 3. verify ---------------------------------------------------------------
chk <- paste(readLines(md, warn = FALSE), collapse = "\n")
b <- substr(chk, regexpr("## Introduction", chk, fixed = TRUE), nchar(chk))
h2 <- regmatches(b, gregexpr("\\((\\d+(?:,\\s*\\d+)*)\\)", b, perl = TRUE))[[1]]
seq2 <- integer(0)
for (x in h2) for (n in as.integer(strsplit(gsub("[()\\s]", "", x), ",")[[1]]))
  if (!(n %in% seq2)) seq2 <- c(seq2, n)
cat(sprintf("\nafter renumbering, first ten: %s\n", paste(head(seq2, 10), collapse = ", ")))
cat(sprintf("sequential from 1: %s\n", identical(seq2, seq_along(seq2))))
cat(sprintf("max reference number: %d\n", max(seq2)))

cat("\ntable and figure mentions now present:\n")
for (k in c("Table 1", "Table 2", "Table 3", "Table S1", "Table S2",
            "Figure 1", "Figure 2", "Figure 3", "Figure S1")) {
  n <- lengths(regmatches(chk, gregexpr(k, chk, fixed = TRUE)))
  cat(sprintf("  %-10s %d\n", k, n))
}
