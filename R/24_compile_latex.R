# ---------------------------------------------------------------------------
# 24_compile_latex.R
# Compiles the LaTeX manuscript with TinyTeX. Missing packages are installed
# on demand. Uses the vector PDF figures rather than the submission TIFFs,
# since pdflatex cannot read TIFF.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(tinytex))

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
tex  <- file.path(sub, "Manuscript.tex")

# point graphics at the PDF versions for the build
s <- paste(readLines(tex, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
if (grepl("figures/Figure1_flow.tiff", s, fixed = TRUE)) {
  s <- gsub("figures/(Figure[0-9]_[A-Za-z_]+)\\.tiff", "figures_pdf/\\1.pdf", s)
  writeLines(strsplit(s, "\n")[[1]], tex, useBytes = TRUE)
  cat("graphics switched to figures_pdf/*.pdf for the LaTeX build\n")
}

owd <- setwd(sub); on.exit(setwd(owd))

cat("compiling, installing missing packages on demand\n")
ok <- tryCatch({
  latexmk(basename(tex), engine = "pdflatex", install_packages = TRUE)
  TRUE
}, error = function(e) { cat("FAILED:", conditionMessage(e), "\n"); FALSE })

pdf <- file.path(sub, "Manuscript.pdf")
if (ok && file.exists(pdf)) {
  cat(sprintf("\ncompiled Manuscript.pdf  %.0f KB\n", file.size(pdf)/1024))
  log <- file.path(sub, "Manuscript.log")
  if (file.exists(log)) {
    l <- readLines(log, warn = FALSE)
    p <- grep("^Output written", l, value = TRUE)
    if (length(p)) cat(p[1], "\n")
    w <- grep("Warning: Citation|undefined", l, value = TRUE)
    if (length(w)) { cat("\nwarnings:\n"); cat(head(unique(w), 12), sep = "\n") }
    else cat("no citation or reference warnings\n")
  }
} else cat("\nno PDF produced\n")
