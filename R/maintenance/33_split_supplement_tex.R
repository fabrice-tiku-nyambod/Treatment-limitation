# ---------------------------------------------------------------------------
# 33_split_supplement_tex.R
# Moves the supplement out of Manuscript.tex into a standalone Supplementary.tex.
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
texf <- file.path(sub, "Manuscript.tex")
s <- paste(readLines(texf, warn = FALSE, encoding = "UTF-8"), collapse = "\n")

# --- extract environments by delimiter position (same approach as script 31) --
blocks <- function(txt, env) {
  b <- gregexpr(sprintf("\\begin{%s}", env), txt, fixed = TRUE)[[1]]
  e <- gregexpr(sprintf("\\end{%s}", env),   txt, fixed = TRUE)[[1]]
  if (b[1] == -1) return(list())
  elen <- nchar(sprintf("\\end{%s}", env)); out <- list()
  for (i in seq_along(b)) {
    close <- e[e > b[i]][1]
    blk <- substr(txt, b[i], close + elen - 1)
    lab <- regmatches(blk, regexpr("\\\\label\\{[^}]+\\}", blk))
    lab <- if (length(lab)) gsub("\\\\label\\{|\\}", "", lab) else paste0("x", i)
    out[[lab]] <- blk
  }
  out
}
TB <- blocks(s, "table"); FB <- blocks(s, "figure")
supp_items <- list(TB[["tab:discrim"]], TB[["tab:rank"]], FB[["fig:flow"]])
if (any(sapply(supp_items, is.null))) stop("supplementary environments not found")

# --- remove the whole supplement section from the manuscript -----------------
start <- regexpr("\\newpage\n\\setcounter{table}{0}", s, fixed = TRUE)
stop_ <- regexpr("\\bibliographystyle{unsrt}", s, fixed = TRUE)
if (start > 0 && stop_ > start) {
  s <- paste0(substr(s, 1, start - 1), "\n\\newpage\n", substr(s, stop_, nchar(s)))
  cat("supplement section removed from Manuscript.tex\n")
} else stop("supplement markers not found")

# front matter no longer advertises a supplement inside the manuscript
s <- sub("\\quad \\textbf{Supplementary.} 2 tables, 1 figure",
         "\\quad \\textbf{Supplementary.} separate file", s, fixed = TRUE)
writeLines(strsplit(s, "\n")[[1]], texf, useBytes = TRUE)

TB2 <- blocks(s, "table"); FB2 <- blocks(s, "figure")
cat(sprintf("manuscript now holds %d tables, %d figures: %s | %s\n",
            length(TB2), length(FB2),
            paste(names(TB2), collapse = ", "), paste(names(FB2), collapse = ", ")))

# --- build the standalone supplement -----------------------------------------
supp <- paste0(
"% Standalone supplementary material. Compile with pdflatex.\n",
"\\documentclass[12pt,a4paper]{article}\n",
"\\usepackage[margin=1in]{geometry}\n",
"\\usepackage{newtxtext,newtxmath}\n",
"\\usepackage{setspace}\n\\usepackage{graphicx}\n\\usepackage{booktabs}\n",
"\\usepackage{caption}\n\\usepackage{longtable}\n\\usepackage[hidelinks]{hyperref}\n",
"\\onehalfspacing\n",
"\\captionsetup{font=small,labelfont=bf,justification=raggedright,singlelinecheck=false}\n",
"\\renewcommand{\\thetable}{S\\arabic{table}}\n",
"\\renewcommand{\\thefigure}{S\\arabic{figure}}\n",
"\\graphicspath{{./}}\n\n",
"\\begin{document}\n\n",
"\\begin{center}\n",
"{\\Large\\bfseries Supplementary Material}\\\\[8pt]\n",
"{\\itshape Treatment Limitation Documentation and Risk Adjusted Mortality\n",
"Benchmarking in 190 US Intensive Care Units}\\\\[6pt]\n",
"Fabrice T. Nyambod, MD, MPH\n",
"\\end{center}\n\n",
"\\vspace{10pt}\n\\noindent\\textbf{Contents}\n\n",
"\\begin{itemize}\\setlength{\\itemsep}{0pt}\n",
"\\item Table S1. Discrimination and accuracy on held out data\n",
"\\item Table S2. Effect of modeling treatment limitation on unit ranking\n",
"\\item Table S3. Unit level case mix and limitation rate, provided as a data file\n",
"\\item Table S4. Unit level ranking comparison, provided as a data file\n",
"\\item Table S5. Covariate balance before and after weighting, provided as a data file\n",
"\\item Figure S1. Derivation of the study cohort\n",
"\\end{itemize}\n\n\\newpage\n\n",
supp_items[[1]], "\n\n", supp_items[[2]], "\n\n\\newpage\n\n",
supp_items[[3]], "\n\n",
"\\vfill\n\\noindent\\footnotesize Tables S3 to S5 accompany this document as\n",
"separate data files. They contain unit level aggregates only and no patient\n",
"level information.\n\n",
"\\end{document}\n")

sf <- file.path(sub, "Supplementary.tex")
writeLines(strsplit(supp, "\n")[[1]], sf, useBytes = TRUE)
cat(sprintf("wrote Supplementary.tex (%.0f KB)\n", file.size(sf)/1024))
