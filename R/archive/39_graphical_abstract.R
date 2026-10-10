# ---------------------------------------------------------------------------
# 39_graphical_abstract.R
#
# Graphical abstract. American Thoracic Society furniture, a title band,
# bordered sections with coloured header strips and a citation footer, but the
# sections are the three links of the argument rather than Methods, Results and
# Implications, and connectors carry the reader from one to the next:
#
#   1  the score has no term for limitation   SMR 0.62 to 1.87 by code status
#   2  balancing case mix does not remove it  16.5% against 5.7%, a 2.89 ratio
#   3  so the bend runs one way               rho = -0.689
#
# Three decisions worth recording
#   - the headline carries the finding, not the premise, because the title band
#     is the only element that survives at thumbnail size. It stops at the
#     empirical bend and says nothing about whether to adjust, since the paper
#     deliberately leaves that open
#   - panel 2 plots the weighted limitation rates themselves, 16.5 against 5.7
#     percent, rather than the ratio. A rate on a percentage scale reads faster
#     than a multiplier and sets the panel apart from panel 1
#   - panel 3 is a dumbbell rather than a count of units that move, because the
#     finding is directional. Under current benchmarking the lowest and highest
#     limitation quintiles look alike, 0.984 against 1.013. Once limitation is
#     in the model they separate, 1.027 against 0.876. The figure shows the bend
#
# Design constraints
#   - each section is drawn in its own 0 to 100 coordinate space, so the box,
#     the header strip and the artwork inside share one geometry
#   - one claim, one caption, one supporting fact per section, so the artwork
#     rather than the prose carries the weight
#   - mako palette, validated against a white print surface for colour vision
#     deficiency separation, contrast and monotonic lightness in grayscale
#   - serif throughout
#   - 900 dpi TIFF, above the 600 dpi requirement
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork)
})

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "serif"

PAL    <- c("#00B6B3", "#007AA5", "#433864", "#200F1D")
INK    <- "#0b0b0b"; MUTED <- "#6b6b68"; ACC <- "#C81560"
HDR    <- PAL[3]                 # header strip behind the section label
BAND   <- PAL[4]                 # title band
BORDER <- "#c9c8c1"; FILL <- "#fdfdfc"; RULE <- "#e4e3dc"; STRIP <- "#f1f0ea"
GREY   <- "#9a9a95"              # the benchmark as it is computed today

# section shell: white body, thin border, coloured header strip with the label
shell <- function(label) list(
  annotate("rect", xmin = 0, xmax = 100, ymin = 0, ymax = 100,
           fill = FILL, colour = NA),
  annotate("rect", xmin = 0, xmax = 100, ymin = 93.4, ymax = 100,
           fill = HDR, colour = NA),
  annotate("text", x = 3.5, y = 96.6, label = label, hjust = 0,
           family = FONT, fontface = "bold", size = 3.3, colour = "white"),
  annotate("rect", xmin = 0, xmax = 100, ymin = 0, ymax = 100,
           fill = NA, colour = BORDER, linewidth = .5))

# one claim, one caption, one supporting fact. everything else is artwork
claim   <- function(s) annotate("text", x = 50, y = 87, label = s, family = FONT,
                               fontface = "bold", size = 3.45, colour = INK)
caption <- function(s) annotate("text", x = 50, y = 80.5, label = s,
                               family = FONT, size = 2.75, colour = MUTED)
support <- function(s) list(
  annotate("segment", x = 6, xend = 94, y = 11, yend = 11,
           colour = RULE, linewidth = .5),
  annotate("text", x = 50, y = 6, label = s, family = FONT, size = 2.7,
           colour = MUTED))

sec <- theme_void(base_family = FONT) + theme(plot.margin = margin(0, 0, 0, 0))
box <- function(p) p +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) + sec

# ===================== 1. THE SCORE NEVER SEES IT ===========================
# SMR by code status. baseline at y0, one SMR unit is SC vertical units
y0 <- 22; SC <- 25
d1 <- data.table(x = c(15, 38, 61, 84), smr = c(0.62, 1.17, 1.22, 1.87),
                 fill = PAL,
                 lab = c("Full\ntherapy", "DNR\ntype",
                         "Partial\nwithdrawal", "Comfort\nmeasures"))

p1 <- box(ggplot() + shell("1  \u00b7  THE SCORE NEVER SEES IT") +
  claim("APACHE IVa has no term for treatment limitation") +
  caption("Standardized mortality ratio by code status at 24 hours") +
  annotate("segment", x = 6, xend = 94, y = y0 + SC, yend = y0 + SC,
           colour = INK, linewidth = .45) +
  annotate("text", x = 6, y = y0 + SC + 2.2, label = "perfect calibration",
           hjust = 0, family = FONT, size = 2.45, colour = MUTED) +
  annotate("rect", xmin = d1$x - 8.5, xmax = d1$x + 8.5, ymin = y0,
           ymax = y0 + d1$smr * SC, fill = d1$fill, colour = NA) +
  annotate("text", x = d1$x, y = y0 + d1$smr * SC + 2.6,
           label = sprintf("%.2f", d1$smr), family = FONT, fontface = "bold",
           size = 3.4, colour = INK) +
  annotate("text", x = d1$x, y = y0 - 2.4, label = d1$lab, vjust = 1,
           family = FONT, size = 2.75, colour = INK, lineheight = 1.05) +
  support("Integrated calibration index rises from 0.037 to 0.342 across the same strata"))

# ================= 2. AND IT IS NOT THEIR PATIENTS ==========================
# the weighted rates themselves, on a percentage scale from zero
b0 <- 22; PS <- 2.3              # y at 0 percent, and vertical units per point
d2 <- data.table(x = c(30, 70), rate = c(5.7, 16.5),
                 fill = c(PAL[1], PAL[2]),
                 lab = c("Lowest\nquintile", "Highest\nquintile"))

p2 <- box(ggplot() + shell("2  \u00b7  AND IT IS NOT THEIR PATIENTS") +
  claim("Balancing case mix does not remove the difference") +
  caption("Limitation documented, after weighting on 12 covariates") +
  annotate("segment", x = 6, xend = 94, y = b0, yend = b0, colour = INK,
           linewidth = .45) +
  annotate("rect", xmin = d2$x - 12, xmax = d2$x + 12, ymin = b0,
           ymax = b0 + d2$rate * PS, fill = d2$fill, colour = NA) +
  annotate("text", x = d2$x, y = b0 + d2$rate * PS + 2.6,
           label = sprintf("%.1f%%", d2$rate), family = FONT, fontface = "bold",
           size = 4.1, colour = INK) +
  annotate("text", x = d2$x, y = b0 - 2.4, label = d2$lab, vjust = 1,
           family = FONT, size = 2.75, colour = INK, lineheight = 1.05) +
  # the surviving gap, bracketed between the two bar tops
  annotate("segment", x = 42.5, xend = 57.5, y = 66, yend = 66, colour = ACC,
           linewidth = .55, arrow = arrow(length = unit(.12, "cm"),
                                          type = "closed")) +
  annotate("text", x = 50, y = 70.5, label = "2.89\u00d7", family = FONT,
           fontface = "bold", size = 4, colour = ACC) +
  support("Unweighted the ratio is 3.58; four fifths of the practice gap survives balancing"))

# ==================== 3. SO THE RANKING BENDS ===============================
# dumbbell. two quintiles that look alike under the benchmark as computed
# today, and separate once limitation is in the model
sx <- function(v) 14 + (v - 0.84) / (1.06 - 0.84) * 76
d3 <- data.table(
  y    = c(48, 31),
  from = c(0.984, 1.013),
  to   = c(1.027, 0.876),
  col  = c(PAL[2], ACC),
  lab  = c("Lowest limitation quintile", "Highest limitation quintile"),
  hj   = c(0, 1),                        # value labels pushed away from travel
  note = c("flattered today", "penalized today"))

p3 <- box(ggplot() + shell("3  \u00b7  SO THE RANKING BENDS") +
  claim("The bend runs one way, not at random") +
  caption("Standardized mortality ratio, before and after limitation is modeled") +
  annotate("segment", x = sx(1), xend = sx(1), y = 20, yend = 60,
           colour = BORDER, linewidth = .45, linetype = "22") +
  annotate("segment", x = 14, xend = 90, y = 17, yend = 17,
           colour = MUTED, linewidth = .4) +
  annotate("segment", x = sx(c(0.9, 1.0, 1.05)), xend = sx(c(0.9, 1.0, 1.05)),
           y = 17, yend = 15.4, colour = MUTED, linewidth = .4) +
  annotate("text", x = sx(c(0.9, 1.0, 1.05)), y = 13.8,
           label = c("0.90", "1.00", "1.05"), vjust = 1, family = FONT,
           size = 2.5, colour = MUTED) +
  # the travel
  annotate("segment", x = sx(d3$from), xend = sx(d3$to), y = d3$y, yend = d3$y,
           colour = d3$col, linewidth = .95,
           arrow = arrow(length = unit(.14, "cm"), type = "closed")) +
  annotate("point", x = sx(d3$from), y = d3$y, size = 2.9, shape = 21,
           fill = "white", colour = GREY, stroke = 1) +
  annotate("point", x = sx(d3$to), y = d3$y, size = 2.9, colour = d3$col) +
  annotate("text", x = sx(d3$from), y = d3$y + 3.6,
           label = sprintf("%.3f", d3$from), family = FONT, size = 2.6,
           colour = MUTED) +
  annotate("text", x = sx(d3$to) + c(3.8, -3.8), y = d3$y,
           label = sprintf("%.3f", d3$to), hjust = d3$hj, family = FONT,
           fontface = "bold", size = 3.1, colour = d3$col) +
  annotate("text", x = 14, y = d3$y + 9, label = d3$lab, hjust = 0,
           family = FONT, size = 2.75, colour = INK) +
  annotate("text", x = 90, y = d3$y + 9, label = d3$note, hjust = 1,
           family = FONT, fontface = "italic", size = 2.6, colour = d3$col) +
  # what the two marks mean
  annotate("point", x = 17, y = 72, size = 2.4, shape = 21, fill = "white",
           colour = GREY, stroke = 1) +
  annotate("text", x = 20.5, y = 72, label = "benchmark as computed today",
           hjust = 0, family = FONT, size = 2.5, colour = MUTED) +
  annotate("point", x = 17, y = 67, size = 2.4, colour = INK) +
  annotate("text", x = 20.5, y = 67, label = "with limitation in the model",
           hjust = 0, family = FONT, size = 2.5, colour = MUTED) +
  support("\u03c1 = \u22120.689  \u00b7  23.5% of units change quartile  \u00b7  8.0% change outlier status"))

# ========================== CONNECTORS ======================================
link <- function(word) ggplot() +
  annotate("text", x = 50, y = 57, label = word, family = FONT,
           fontface = "italic", size = 3.4, colour = HDR) +
  annotate("segment", x = 16, xend = 84, y = 48, yend = 48, colour = HDR,
           linewidth = .6, arrow = arrow(length = unit(.13, "cm"),
                                         type = "closed")) +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) + sec

# ========================== FRAME ===========================================
# the band is the only element that survives at thumbnail size, so it carries
# the finding. it stops at the bend and takes no position on the remedy
band <- ggplot() +
  annotate("rect", xmin = 0, xmax = 100, ymin = 0, ymax = 100,
           fill = BAND, colour = NA) +
  annotate("text", x = 2.2, y = 66, hjust = 0, family = FONT,
           fontface = "bold", size = 6.4, colour = "white",
           label = "Where treatment is limited, the benchmark bends") +
  annotate("text", x = 2.2, y = 23, hjust = 0, family = FONT, size = 3.4,
           colour = "#cfcdd6",
           label = "Treatment limitation documentation and risk adjusted mortality benchmarking in 190 US intensive care units") +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) + sec

strip <- ggplot() +
  annotate("rect", xmin = 0, xmax = 100, ymin = 0, ymax = 100,
           fill = STRIP, colour = NA) +
  annotate("text", x = 1.4, y = 50, hjust = 0, family = FONT,
           fontface = "bold", size = 2.8, colour = HDR, label = "METHODS") +
  annotate("text", x = 9, y = 50, hjust = 0, family = FONT, size = 2.8,
           colour = INK,
           label = "136,236 admissions  \u00b7  190 US intensive care units  \u00b7  eICU Collaborative Research Database, 2014 to 2015  \u00b7  APACHE IVa recalibration with errors clustered on unit  \u00b7  inverse probability weighting on 12 covariates") +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) + sec

foot <- ggplot() +
  annotate("text", x = 0.4, y = 50, hjust = 0, family = FONT, size = 2.8,
           colour = MUTED,
           label = "Nyambod FT et al.  \u00b7  Johns Hopkins Bloomberg School of Public Health") +
  annotate("text", x = 99.6, y = 50, hjust = 1, family = FONT,
           fontface = "italic", size = 2.8, colour = MUTED,
           label = "Excluding the 0.6% under comfort measures orders reclassifies 11.1% of units") +
  scale_x_continuous(limits = c(0, 100), expand = c(0, 0)) +
  scale_y_continuous(limits = c(0, 100), expand = c(0, 0)) + sec

row <- wrap_plots(p1, link("and"), p2, link("so"), p3, nrow = 1,
                  widths = c(1, .12, 1, .12, 1))

ga <- band / strip / row / foot +
  plot_layout(heights = c(0.145, 0.048, 1, 0.05)) &
  theme(plot.background = element_rect(fill = "white", colour = NA))

# ---- deliverables: TIFF for submission, vector PDF as the archival master ----
W <- 11.5; H <- 6.6
f <- file.path(sub, "figures", "Graphical_Abstract.tiff")
ggsave(f, ga, device = "tiff", width = W, height = H, units = "in",
       dpi = 900, compression = "lzw", bg = "white")
cat(sprintf("  %-28s %5.1f MB   %.0f x %.0f px @ 900 dpi\n", basename(f),
            file.size(f)/1e6, W*900, H*900))

g2 <- file.path(sub, "figures_pdf", "Graphical_Abstract.pdf")
ggsave(g2, ga, device = cairo_pdf, width = W, height = H, units = "in", bg = "white")
cat(sprintf("  %-28s %5.0f KB   vector\n", basename(g2), file.size(g2)/1024))

# inspection copy only, written outside the submission tree
suppressPackageStartupMessages(library(magick))
im <- image_read(f)
cat(sprintf("  verified: %s\n", paste(image_info(im)$format,
      image_info(im)$width, "x", image_info(im)$height)))
prev <- file.path(Sys.getenv("TEMP"), "GA_preview.png")
image_write(image_scale(im, "1500x"), prev, format = "png")
cat(sprintf("  inspection copy: %s\n", prev))
