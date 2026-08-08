# ---------------------------------------------------------------------------
# 00_preview_figures.R
# Renders submission TIFFs down to PNG previews for on screen checking.
# Kept in R so the whole pipeline is one language.
# Usage: Rscript 00_preview_figures.R [figure name without extension]
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(magick))

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
src  <- file.path(proj, "submission", "figures")
dest <- file.path(proj, "figures", "previews")
dir.create(dest, recursive = TRUE, showWarnings = FALSE)

args <- commandArgs(trailingOnly = TRUE)
files <- if (length(args)) file.path(src, paste0(args, ".tiff")) else
         list.files(src, pattern = "\\.tiff$", full.names = TRUE)

for (f in files) {
  im <- image_read(f)
  inf <- image_info(im)
  out <- file.path(dest, sub("\\.tiff$", ".png", basename(f)))
  image_write(image_scale(im, "1150x"), out, format = "png")
  cat(sprintf("  %-32s %5d x %-5d -> %s\n", basename(f),
              inf$width, inf$height, basename(out)))
}
cat("\npreviews in", dest, "\n")
