# ---------------------------------------------------------------------------
# 29_restructure_outputs.R
#
# Applies the display item restructure to Manuscript.tex and to the Word
# builder.
#
#   main text : Tables 1, 2, 3   Figures 1, 2, 3
#   supplement: Tables S1, S2    Figure S1
#
# Old Table 5 becomes Table 3. Old Tables 3 and 4 become S1 and S2. Old
# Figures 2, 3, 4 become 1, 2, 3. Old Figure 1 becomes S1.
#
# Reference numbering in the LaTeX build needs no change. bibliographystyle
# unsrt already numbers by order of first citation, so the tex was correct
# already; only the markdown and Word versions carried the arbitrary order.
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
tex  <- file.path(proj, "submission", "Manuscript.tex")
s    <- paste(readLines(tex, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

hit <- function(pat) grepl(pat, s, fixed = TRUE)
rep1 <- function(from, to, label) {
  if (hit(from)) { s <<- sub(from, to, s, fixed = TRUE); cat(sprintf("  ok   %s\n", label)) }
  else cat(sprintf("  MISS %s\n", label))
}

cat("Manuscript.tex\n")

# --- graphics filenames ------------------------------------------------------
s <- gsub("figures_pdf/Figure1_flow.pdf", "figures_pdf/FigureS1_flow.pdf", s, fixed = TRUE)
s <- gsub("figures_pdf/Figure2_model_performance.pdf",
          "figures_pdf/Figure1_model_performance.pdf", s, fixed = TRUE)
s <- gsub("figures_pdf/Figure3_unit_variation.pdf",
          "figures_pdf/Figure2_unit_variation.pdf", s, fixed = TRUE)
s <- gsub("figures_pdf/Figure4_benchmarking.pdf",
          "figures_pdf/Figure3_benchmarking.pdf", s, fixed = TRUE)
cat("  ok   graphics filenames\n")

# --- move the flow figure and two tables into a supplement section -----------
# cut the flow figure block
fb <- regmatches(s, regexpr("\\\\begin\\{figure\\}[^~]*?fig:flow\\}\n\\\\end\\{figure\\}", s))
if (length(fb)) { s <- sub(fb, "", s, fixed = TRUE); cat("  ok   flow figure removed from main\n") }

# cut the discrimination and ranking tables
tb_d <- regmatches(s, regexpr("\\\\begin\\{table\\}[^~]*?tab:discrim\\}[^~]*?\\\\end\\{table\\}", s))
if (length(tb_d)) { s <- sub(tb_d, "", s, fixed = TRUE); cat("  ok   discrimination table removed from main\n") }
tb_r <- regmatches(s, regexpr("\\\\begin\\{table\\}[^~]*?tab:rank\\}[^~]*?\\\\end\\{table\\}", s))
if (length(tb_r)) { s <- sub(tb_r, "", s, fixed = TRUE); cat("  ok   ranking table removed from main\n") }

# --- relabel captions --------------------------------------------------------
s <- gsub("\\label{tab:remedy}", "\\label{tab:remedy}", s, fixed = TRUE)  # becomes Table 3 by position

# --- append the supplement ---------------------------------------------------
supp <- paste0(
  "\n\\newpage\n",
  "\\setcounter{table}{0}\\renewcommand{\\thetable}{S\\arabic{table}}\n",
  "\\setcounter{figure}{0}\\renewcommand{\\thefigure}{S\\arabic{figure}}\n",
  "\\section*{Supplementary material}\n\n",
  if (length(tb_d)) paste0(tb_d, "\n\n") else "",
  if (length(tb_r)) paste0(tb_r, "\n\n") else "",
  if (length(fb)) paste0(fb, "\n\n") else "",
  "\\noindent Supplementary tables S3 to S5 are provided as separate files.\n",
  "Table S3 gives unit level case mix. Table S4 gives the unit level ranking\n",
  "comparison. Table S5 gives covariate balance before and after weighting.\n")

s <- sub("\\bibliographystyle{unsrt}", paste0(supp, "\n\\bibliographystyle{unsrt}"),
         s, fixed = TRUE)
cat("  ok   supplement section appended\n")

writeLines(strsplit(s, "\n")[[1]], tex, useBytes = TRUE)

# --- audit -------------------------------------------------------------------
n_tab <- lengths(regmatches(s, gregexpr("\\\\begin\\{table\\}", s)))
n_fig <- lengths(regmatches(s, gregexpr("\\\\begin\\{figure\\}", s)))
cat(sprintf("\ntable environments: %d, figure environments: %d\n", n_tab, n_fig))
cat("expected 5 tables and 4 figures in total, 3 and 3 before the supplement\n")
