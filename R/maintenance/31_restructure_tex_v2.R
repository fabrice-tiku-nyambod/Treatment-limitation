# ---------------------------------------------------------------------------
# 31_restructure_tex_v2.R
#
# Rebuilds the Tables and Figures sections of Manuscript.tex.
#
# Two earlier attempts failed because a single regex spanning \begin..\end
# always anchored on the FIRST \begin in the file, swallowing everything up to
# the target label. This version finds the delimiter positions, pairs them, and
# extracts each block by index. No regex spans an environment boundary.
#
#   main       : Table 1 cohort, Table 2 calibration, Table 3 remedy
#                Figure 1 performance, Figure 2 variation, Figure 3 benchmarking
#   supplement : Table S1 discrimination, Table S2 ranking, Figure S1 flow
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
texf <- file.path(proj, "submission", "Manuscript.tex")
s <- paste(readLines(texf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# --- cite keys, only if not already renumbered -------------------------------
map <- read.csv(file.path(proj, "results", "reference_renumber_map.csv"))
mx <- suppressWarnings(max(as.integer(gsub("\\D", "", unlist(
  regmatches(s, gregexpr("ref[0-9]+", s))))), na.rm = TRUE))
if (is.finite(mx) && mx > 46) {
  for (i in seq_len(nrow(map)))
    s <- gsub(paste0("ref", map$old[i], "(?![0-9])"),
              paste0("TMPREF", map$new[i]), s, perl = TRUE)
  s <- gsub("TMPREF", "ref", s, fixed = TRUE)
  cat("cite keys renumbered to 1..46\n")
} else cat("cite keys already sequential, max ref", mx, "\n")

# --- extract environments by delimiter position ------------------------------
blocks <- function(txt, env) {
  b <- gregexpr(sprintf("\\begin{%s}", env), txt, fixed = TRUE)[[1]]
  e <- gregexpr(sprintf("\\end{%s}", env),   txt, fixed = TRUE)[[1]]
  if (b[1] == -1) return(list())
  elen <- nchar(sprintf("\\end{%s}", env))
  out <- list()
  for (i in seq_along(b)) {
    close <- e[e > b[i]][1]
    txtblk <- substr(txt, b[i], close + elen - 1)
    lab <- regmatches(txtblk, regexpr("\\\\label\\{[^}]+\\}", txtblk))
    lab <- if (length(lab)) gsub("\\\\label\\{|\\}", "", lab) else paste0("unlabelled", i)
    out[[lab]] <- txtblk
  }
  out
}

TB <- blocks(s, "table"); FB <- blocks(s, "figure")
cat(sprintf("\nfound %d tables: %s\n", length(TB), paste(names(TB), collapse = ", ")))
cat(sprintf("found %d figures: %s\n", length(FB), paste(names(FB), collapse = ", ")))

need <- c("tab:cohort","tab:calibration","tab:discrim","tab:rank","tab:remedy")
needf <- c("fig:flow","fig:performance","fig:variation","fig:benchmarking")
miss <- c(setdiff(need, names(TB)), setdiff(needf, names(FB)))
if (length(miss)) stop("missing environments: ", paste(miss, collapse = ", "))

# remove every extracted block from the body
for (b in c(TB, FB)) s <- sub(b, "", s, fixed = TRUE)

# strip the old section headers and collapse blank runs
for (h in c("\\section*{Tables}", "\\section*{Figures}"))
  s <- gsub(h, "", s, fixed = TRUE)
s <- gsub("\n{4,}", "\n\n", s)

# --- reassemble --------------------------------------------------------------
main <- paste0("\n\\newpage\n\\section*{Tables}\n\n",
               TB[["tab:cohort"]], "\n\n",
               TB[["tab:calibration"]], "\n\n",
               TB[["tab:remedy"]], "\n\n",
               "\\newpage\n\\section*{Figures}\n\n",
               FB[["fig:performance"]], "\n\n",
               FB[["fig:variation"]], "\n\n",
               FB[["fig:benchmarking"]], "\n")

supp <- paste0("\n\\newpage\n",
               "\\setcounter{table}{0}\\renewcommand{\\thetable}{S\\arabic{table}}\n",
               "\\setcounter{figure}{0}\\renewcommand{\\thefigure}{S\\arabic{figure}}\n",
               "\\section*{Supplementary material}\n\n",
               TB[["tab:discrim"]], "\n\n",
               TB[["tab:rank"]], "\n\n",
               FB[["fig:flow"]], "\n\n",
               "\\noindent Tables S3 to S5 are provided as separate files. ",
               "Table S3 gives unit level case mix. Table S4 gives the unit level ",
               "ranking comparison. Table S5 gives covariate balance before and ",
               "after weighting.\n")

s <- sub("\\bibliographystyle{unsrt}",
         paste0(main, supp, "\n\\newpage\n\\bibliographystyle{unsrt}"),
         s, fixed = TRUE)
writeLines(strsplit(s, "\n")[[1]], texf, useBytes = TRUE)

# --- audit -------------------------------------------------------------------
TB2 <- blocks(s, "table"); FB2 <- blocks(s, "figure")
cat(sprintf("\nrebuilt: %d tables, %d figures\n", length(TB2), length(FB2)))
cat("order:\n")
labs <- regmatches(s, gregexpr("\\\\label\\{(tab|fig):[a-z]+\\}", s, perl = TRUE))[[1]]
for (i in seq_along(labs))
  cat(sprintf("  %2d. %s\n", i, gsub("\\\\label\\{|\\}", "", labs[i])))
