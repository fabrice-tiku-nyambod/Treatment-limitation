# ---------------------------------------------------------------------------
# 09_all_figures_tiff.R
# Regenerates every figure as TIFF, 600 dpi, LZW compressed, for submission.
# Supersedes the PNG output of scripts 03 and 08.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
fig  <- file.path(proj, "figures")

save_tiff <- function(plot, name, w, h) {
  f <- file.path(fig, paste0(name, ".tiff"))
  ggsave(f, plot, device = "tiff", width = w, height = h, units = "in",
         dpi = 600, compression = "lzw")
  cat(sprintf("  %-34s %6.1f MB\n", basename(f), file.size(f)/1e6))
}

d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, cs_lab := factor(fifelse(lim_tier_24h == 0, "Undocumented",
                     fifelse(lim_tier_24h == 1, "Full therapy",
                     fifelse(lim_tier_24h == 2, "DNR type",
                     fifelse(lim_tier_24h == 3, "Partial withdrawal", "Comfort measures")))),
                levels = c("Full therapy","DNR type","Partial withdrawal",
                           "Comfort measures","Undocumented"))]
h <- fread(file.path(proj, "results", "hospital_reranking.csv"))

cat("writing TIFF at 600 dpi, LZW\n")

# --- Figure 1: exclusion cascade -------------------------------------------
steps <- data.table(
  step = factor(1:4, labels = c(
    "eICU-CRD v2.0 unit stays\nn = 200,859",
    "APACHE IVa result available\nand linked to predictor table\nn = 136,236",
    "Hospitals represented\nn = 190",
    "Hospitals with 100 or more stays\nn = 162, comprising 135,325 stays")),
  y = 4:1)
p1 <- ggplot(steps, aes(x = 1, y = y)) +
  geom_tile(fill = "grey96", color = "grey40", width = .9, height = .68) +
  geom_text(aes(label = step), size = 3.3, lineheight = 1.05) +
  geom_segment(data = data.frame(y = c(3.66, 2.66, 1.66)),
               aes(x = 1, xend = 1, y = y, yend = y - .32),
               arrow = arrow(length = unit(.16, "cm")), inherit.aes = FALSE) +
  coord_cartesian(xlim = c(.5, 1.5), ylim = c(.5, 4.5)) +
  theme_void(base_size = 11)
save_tiff(p1, "fig1_flow", 5.2, 6)

# --- Figure 2: calibration by limitation status -----------------------------
pd <- d[cs_lab != "Undocumented"]
pd[, bin := cut(pred, breaks = quantile(pred, seq(0,1,.05), na.rm = TRUE),
                include.lowest = TRUE, labels = FALSE), by = cs_lab]
cv <- pd[, .(x = mean(pred), y = mean(died_hosp), n = .N), by = .(cs_lab, bin)][n >= 20]
p2 <- ggplot(cv, aes(x, y, color = cs_lab)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, color = "grey50") +
  geom_point(aes(size = n), alpha = .6) +
  geom_smooth(method = "loess", se = FALSE, span = 1, linewidth = .8) +
  scale_x_continuous("APACHE IVa predicted mortality", labels = scales::percent) +
  scale_y_continuous("Observed mortality", labels = scales::percent) +
  scale_size_continuous(guide = "none") +
  scale_color_brewer("Code status within 24 hours", palette = "Dark2") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
save_tiff(p2, "fig2_calibration", 7.5, 6)

# --- Figure 3: hospital variation -------------------------------------------
p3 <- ggplot(h, aes(reorder(factor(hospitalid), lim_rate), lim_rate)) +
  geom_col(fill = "#2b6a8f", width = .85) +
  scale_y_continuous("Treatment limitation rate within 24 hours",
                     labels = scales::percent) +
  labs(x = "Intensive care unit, ordered by limitation rate") +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank(),
        panel.grid.major.x = element_blank())
save_tiff(p3, "fig3_hospital_variation", 8.5, 5)

# --- Figure 4: rank shift ---------------------------------------------------
p4 <- ggplot(h, aes(lim_rate, rank_shift)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_point(aes(size = n), alpha = .55, color = "#2b6a8f") +
  geom_smooth(method = "lm", se = TRUE, color = "#c0392b", linewidth = .8) +
  scale_x_continuous("Treatment limitation rate within 24 hours", labels = scales::percent) +
  scale_y_continuous("Change in rank when limitation is modeled") +
  scale_size_continuous("ICU stays", range = c(1, 6)) +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
save_tiff(p4, "fig4_rank_shift", 7.5, 5.5)

# --- Figure 5: funnel plots -------------------------------------------------
mk  <- function(smr, e, lab) data.table(e = e, smr = smr, panel = lab)
fun <- rbind(mk(h$smrA, h$eA, "Current practice"),
             mk(h$smrB, h$eB, "Limitation modeled"))
fun[, panel := factor(panel, levels = c("Current practice","Limitation modeled"))]
grid <- data.table(e = seq(max(1, min(fun$e)), max(fun$e), length.out = 400))
lim <- rbind(
  grid[, .(e, y = qchisq(.025, 2*e)/2/e,     band = "95%")],
  grid[, .(e, y = qchisq(.975, 2*(e+1))/2/e, band = "95%")],
  grid[, .(e, y = qchisq(.001, 2*e)/2/e,     band = "99.8%")],
  grid[, .(e, y = qchisq(.999, 2*(e+1))/2/e, band = "99.8%")])
lim[, grp := paste(band, y > 1)]
lim <- rbind(copy(lim)[, panel := "Current practice"],
             copy(lim)[, panel := "Limitation modeled"])
lim[, panel := factor(panel, levels = c("Current practice","Limitation modeled"))]
p5 <- ggplot() +
  geom_line(data = lim, aes(e, y, group = grp, linetype = band), color = "grey45") +
  geom_hline(yintercept = 1, color = "grey20") +
  geom_point(data = fun, aes(e, smr), alpha = .55, color = "#2b6a8f", size = 1.7) +
  facet_wrap(~panel) +
  coord_cartesian(ylim = c(0, 2.2)) +
  scale_x_continuous("Expected deaths") +
  scale_y_continuous("Standardized mortality ratio") +
  scale_linetype_manual("Control limits", values = c("95%" = 2, "99.8%" = 3)) +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
save_tiff(p5, "fig5_funnel", 9, 5)

cat("\nremoving superseded PNG files\n")
invisible(file.remove(list.files(fig, pattern = "\\.png$", full.names = TRUE)))
print(data.table(file = list.files(fig)))
