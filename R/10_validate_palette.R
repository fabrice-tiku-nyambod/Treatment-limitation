# ---------------------------------------------------------------------------
# 10_validate_palette.R
#
# Colour validation for the manuscript figures. Ported from the dataviz skill's
# JS validator because node is not installed on this machine.
#
# Checks, against a WHITE surface since journals print on white:
#   1. OKLab dE between adjacent steps, normal vision   (floor 15)
#   2. OKLab dE between adjacent steps under deuteranopia, protanopia,
#      tritanopia                                        (target >= 8)
#   3. WCAG contrast of each step against white          (ordinal floor 2:1)
#   4. Monotonic lightness, so the ramp survives greyscale printing
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(colorspace))

# --- sRGB -> OKLab ---------------------------------------------------------
srgb2lin <- function(c) ifelse(c <= 0.04045, c/12.92, ((c + 0.055)/1.055)^2.4)

hex2oklab <- function(hex) {
  rgb <- t(col2rgb(hex))/255
  lin <- srgb2lin(rgb)
  l <- 0.4122214708*lin[,1] + 0.5363325363*lin[,2] + 0.0514459929*lin[,3]
  m <- 0.2119034982*lin[,1] + 0.6806995451*lin[,2] + 0.1073969566*lin[,3]
  s <- 0.0883024619*lin[,1] + 0.2817188376*lin[,2] + 0.6299787005*lin[,3]
  l_ <- l^(1/3); m_ <- m^(1/3); s_ <- s^(1/3)
  cbind(L = 0.2104542553*l_ + 0.7936177850*m_ - 0.0040720468*s_,
        a = 1.9779984951*l_ - 2.4285922050*m_ + 0.4505937099*s_,
        b = 0.0259040371*l_ + 0.7827717662*m_ - 0.8086757660*s_)
}

dE <- function(h1, h2) {
  a <- hex2oklab(h1); b <- hex2oklab(h2)
  100 * sqrt(rowSums((a - b)^2))
}

relL <- function(hex) {
  rgb <- t(col2rgb(hex))/255
  lin <- srgb2lin(rgb)
  0.2126*lin[,1] + 0.7152*lin[,2] + 0.0722*lin[,3]
}
contrast <- function(hex, surface = "#ffffff") {
  a <- relL(hex); b <- relL(surface)
  (pmax(a,b) + 0.05) / (pmin(a,b) + 0.05)
}

validate <- function(pal, labels, name) {
  cat("\n", strrep("=", 68), "\n", sep = "")
  cat(name, "\n")
  cat(strrep("=", 68), "\n", sep = "")
  cat(sprintf("  %-22s %-9s %8s %8s\n", "level", "hex", "contrast", "OKLab L"))
  ok_contrast <- TRUE
  for (i in seq_along(pal)) {
    cr <- contrast(pal[i]); Lv <- hex2oklab(pal[i])[, "L"]
    flag <- if (cr >= 2) "" else "  <-- FAIL 2:1"
    if (cr < 2) ok_contrast <- FALSE
    cat(sprintf("  %-22s %-9s %8.2f %8.3f%s\n", labels[i], pal[i], cr, Lv, flag))
  }

  cat("\n  adjacent-pair separation (OKLab dE x100)\n")
  cat(sprintf("  %-26s %8s %8s %8s %8s\n", "pair", "normal", "deutan", "protan", "tritan"))
  worst_n <- Inf; worst_c <- Inf
  for (i in 1:(length(pal)-1)) {
    p <- pal[i]; q <- pal[i+1]
    n  <- dE(p, q)
    d  <- dE(deutan(p), deutan(q))
    pr <- dE(protan(p), protan(q))
    tr <- dE(tritan(p), tritan(q))
    worst_n <- min(worst_n, n); worst_c <- min(worst_c, d, pr, tr)
    cat(sprintf("  %-26s %8.1f %8.1f %8.1f %8.1f\n",
                paste(i, "vs", i+1), n, d, pr, tr))
  }

  Ls <- hex2oklab(pal)[, "L"]
  mono <- all(diff(Ls) < 0) || all(diff(Ls) > 0)

  cat("\n  VERDICT\n")
  cat(sprintf("    worst normal-vision dE  %5.1f   %s (floor 15)\n",
              worst_n, ifelse(worst_n >= 15, "PASS", "FAIL")))
  cat(sprintf("    worst CVD dE            %5.1f   %s (target 8)\n",
              worst_c, ifelse(worst_c >= 8, "PASS", ifelse(worst_c >= 6, "WARN", "FAIL"))))
  cat(sprintf("    contrast vs white       %5s   %s\n", "",
              ifelse(ok_contrast, "PASS", "FAIL")))
  cat(sprintf("    monotonic lightness     %5s   %s (greyscale print)\n", "",
              ifelse(mono, "PASS", "FAIL")))
  invisible(list(worst_n = worst_n, worst_c = worst_c, mono = mono))
}

labs <- c("Full therapy", "DNR type", "Partial withdrawal", "Comfort measures")

# Candidate A: skill's blue ramp, ordinal steps 250/400/550/700
validate(c("#86b6ef", "#3987e5", "#1c5cab", "#0d366b"), labs,
         "A. Skill blue ordinal ramp (steps 250/400/550/700)")

# Candidate B: ColorBrewer Blues 4-class, the journal default
validate(c("#bdd7e7", "#6baed6", "#3182bd", "#08519c"), labs,
         "B. ColorBrewer Blues, 4-class")

# Candidate C: viridis 4-step
validate(c("#fde725", "#35b779", "#31688e", "#440154"), labs,
         "C. Viridis, 4-step")
