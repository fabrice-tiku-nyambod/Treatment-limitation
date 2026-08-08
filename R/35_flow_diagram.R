# ---------------------------------------------------------------------------
# 35_flow_diagram.R
#
# CONSORT style cohort derivation with exclusion arms.
#
# The first version showed four boxes and no exclusions, which defeats the
# purpose of a flow diagram. Counts below come from BigQuery, not from the
# analytic file, so the numbers dropped before extraction are visible.
#
#   200,859 unit stays in eICU-CRD v2.0
#     - 52,327 no APACHE IVa result recorded
#   148,532 with an APACHE IVa result
#     - 12,296 predicted hospital mortality unavailable or zero
#   136,236 analytic cohort, 190 units
#     - 911 stays in 28 units contributing fewer than 100 stays
#   135,325 unit level analyses, 162 units
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(ggplot2); library(data.table) })

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
INK <- "#0b0b0b"; MUTED <- "#5a5a57"; FONT <- "serif"

main <- data.table(
  y = c(4, 3, 2, 1),
  lab = c(
    "Adult unit stays in the eICU Collaborative\nResearch Database version 2.0\nn = 200,859",
    "Unit stays with an APACHE IVa result\nn = 148,532",
    "Analytic cohort\nn = 136,236 stays in 190 units",
    "Unit level analyses\nn = 135,325 stays in 162 units"))

excl <- data.table(
  y = c(3.5, 2.5, 1.5),
  lab = c(
    "Excluded, no APACHE IVa\nresult recorded\nn = 52,327",
    "Excluded, APACHE IVa predicted\nmortality unavailable or zero\nn = 12,296",
    "Excluded from unit level analysis,\nunits contributing fewer than\n100 stays, 28 units\nn = 911"))

BX <- 0.0; BW <- 1.9; BH <- 0.62      # main column
EX <- 2.35; EW <- 1.75; EH <- 0.58    # exclusion column

p <- ggplot() +
  # vertical spine
  geom_segment(data = data.frame(y = c(4, 3, 2) - BH/2, yend = c(3, 2, 1) + BH/2),
               aes(x = BX, xend = BX, y = y, yend = yend),
               colour = INK, linewidth = .35,
               arrow = arrow(length = unit(.16, "cm"), type = "closed")) +
  # elbows out to the exclusion boxes
  geom_segment(data = excl, aes(x = BX, xend = EX - EW/2, y = y, yend = y),
               colour = MUTED, linewidth = .3,
               arrow = arrow(length = unit(.14, "cm"), type = "closed")) +
  # main boxes
  geom_tile(data = main, aes(x = BX, y = y), width = BW, height = BH,
            fill = "white", colour = INK, linewidth = .4) +
  geom_text(data = main, aes(x = BX, y = y, label = lab),
            family = FONT, size = 3.5, colour = INK, lineheight = 1.15) +
  # exclusion boxes
  geom_tile(data = excl, aes(x = EX, y = y), width = EW, height = EH,
            fill = "grey97", colour = MUTED, linewidth = .35) +
  geom_text(data = excl, aes(x = EX, y = y, label = lab),
            family = FONT, size = 3.1, colour = MUTED, lineheight = 1.15) +
  coord_cartesian(xlim = c(BX - BW/2 - .1, EX + EW/2 + .1),
                  ylim = c(0.55, 4.45), expand = FALSE) +
  theme_void(base_family = FONT)

for (fmt in c("tiff", "pdf")) {
  d <- if (fmt == "tiff") file.path(sub, "figures") else file.path(sub, "figures_pdf")
  f <- file.path(d, paste0("FigureS1_flow.", fmt))
  if (fmt == "tiff") {
    ggsave(f, p, device = "tiff", width = 7.2, height = 7.6, units = "in",
           dpi = 600, compression = "lzw", bg = "white")
  } else {
    ggsave(f, p, device = cairo_pdf, width = 7.2, height = 7.6, units = "in",
           bg = "white")
  }
  cat(sprintf("  %-28s %6.0f KB\n", basename(f), file.size(f)/1024))
}

suppressPackageStartupMessages(library(magick))
png <- file.path(sub, "figures_png", "FigureS1_flow.png")
image_write(image_read(file.path(sub, "figures", "FigureS1_flow.tiff")), png, format = "png")
prev <- file.path(proj, "figures", "previews", "FigureS1_flow.png")
image_write(image_scale(image_read(png), "1000x"), prev, format = "png")
cat("preview written\n")
