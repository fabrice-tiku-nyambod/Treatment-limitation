# ---------------------------------------------------------------------------
# 13_forest_alluvial.R
#   Fix Figure 6 axis labels.
#   Figure 7  forest plot of adjusted odds ratios from the recalibration model.
#   Figure 8  alluvial of quartile movement, the headline result made visual.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(sandwich); library(lmtest)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
INK <- "#0b0b0b"; MUTED <- "#898781"; GRID <- "#e1e0d9"
PAL <- c("#00B6B3", "#007AA5", "#433864", "#200F1D"); ACC <- "#C81560"

tif <- function(p, name, w, h) {
  f <- file.path(sub, "figures", paste0(name, ".tiff"))
  ggsave(f, p, device = "tiff", width = w, height = h, units = "in",
         dpi = 600, compression = "lzw", bg = "white")
  cat(sprintf("  %-30s %.1f MB\n", basename(f), file.size(f)/1e6))
}

d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp := qlogis(pred)]
d[, cs := relevel(factor(lim_tier_24h), ref = "1")]
d[, cancer := factor(cancer_apache)]

# ---- Figure 6 rebuilt with readable axis ----------------------------------
smd <- fread(file.path(sub, "supplementary", "TableS3_covariate_balance.csv"))
setorder(smd, abs_smd)
smd[, variable := factor(variable, levels = variable)]
p6 <- ggplot(smd, aes(smd, variable)) +
  annotate("rect", xmin = -.1, xmax = .1, ymin = -Inf, ymax = Inf,
           fill = GRID, alpha = .55) +
  geom_vline(xintercept = 0, color = INK, linewidth = .3) +
  geom_vline(xintercept = c(-.1, .1), color = ACC, linetype = 2, linewidth = .3) +
  geom_segment(aes(x = 0, xend = smd, yend = variable), color = MUTED, linewidth = .3) +
  geom_point(size = 2.1, color = PAL[2]) +
  scale_x_continuous("Standardized mean difference",
                     limits = c(-.36, .36), breaks = seq(-.3, .3, .1),
                     labels = function(x) sprintf("%.1f", x)) +
  labs(y = NULL) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = GRID, linewidth = .25),
        axis.text.y = element_text(color = INK, size = 8.5),
        axis.text.x = element_text(color = MUTED, size = 8),
        axis.title.x = element_text(color = INK, size = 9))
tif(p6, "Figure6_balance", 6.2, 4.2)

# ---- Figure 7 forest plot --------------------------------------------------
m <- glm(died_hosp ~ lp + cs + cancer, data = d, family = binomial)
ct <- coeftest(m, vcov. = vcovCL(m, cluster = d$hospitalid))
pick <- c("cs0" = "No code status documented",
          "cs2" = "Do not resuscitate type",
          "cs3" = "Partial withdrawal",
          "cs4" = "Comfort measures only",
          "cancer1" = "Metastatic or hematologic cancer")
fp <- rbindlist(lapply(names(pick), function(k) {
  b <- ct[k,1]; se <- ct[k,2]
  data.table(term = pick[[k]], or = exp(b),
             lo = exp(b - 1.96*se), hi = exp(b + 1.96*se), p = ct[k,4])
}))
fp[, term := factor(term, levels = rev(unlist(pick)))]
fp[, lab := sprintf("%.2f (%.2f to %.2f)", or, lo, hi)]
print(fp[, .(term, or = round(or,3), lo = round(lo,3), hi = round(hi,3))],
      row.names = FALSE)

p7 <- ggplot(fp, aes(or, term)) +
  geom_vline(xintercept = 1, color = INK, linewidth = .3) +
  geom_errorbarh(aes(xmin = lo, xmax = hi), height = .14,
                 color = PAL[2], linewidth = .5) +
  geom_point(size = 2.4, color = PAL[2]) +
  geom_text(aes(x = 26, label = lab), hjust = 0, size = 2.8, color = INK) +
  scale_x_log10("Adjusted odds ratio for in hospital death (log scale)",
                breaks = c(1, 2, 5, 10, 20),
                limits = c(0.85, 90)) +
  labs(y = NULL) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = GRID, linewidth = .25),
        axis.text.y = element_text(color = INK, size = 9),
        axis.text.x = element_text(color = MUTED, size = 8),
        axis.title.x = element_text(color = INK, size = 9),
        plot.margin = margin(6, 8, 6, 6))
tif(p7, "Figure7_forest", 6.6, 2.9)

# ---- Figure 8 quartile movement -------------------------------------------
h <- fread(file.path(proj, "results", "hospital_reranking.csv"))
h[, `:=`(qA = cut(rankA, quantile(rankA, seq(0,1,.25)), include.lowest = TRUE, labels = 1:4),
         qB = cut(rankB, quantile(rankB, seq(0,1,.25)), include.lowest = TRUE, labels = 1:4))]
flow <- h[, .N, by = .(qA, qB)]
flow[, moved := qA != qB]

seg <- rbindlist(lapply(seq_len(nrow(flow)), function(i) {
  data.table(id = i, x = c(0, 1),
             y = c(as.integer(flow$qA[i]), as.integer(flow$qB[i])),
             n = flow$N[i], moved = flow$moved[i])
}))

p8 <- ggplot(seg, aes(x, y, group = id)) +
  geom_line(aes(linewidth = n, color = moved), alpha = .65,
            lineend = "round") +
  geom_point(data = data.table(x = rep(0:1, each = 4), y = rep(1:4, 2)),
             aes(x, y), inherit.aes = FALSE, size = 3, color = INK) +
  scale_linewidth_continuous(range = c(.4, 4.5), guide = "none") +
  scale_color_manual(NULL, values = c("FALSE" = GRID, "TRUE" = ACC),
                      labels = c("Same quartile", "Changed quartile")) +
  scale_x_continuous(NULL, breaks = 0:1,
                     labels = c("Current practice", "Limitation modeled"),
                     expand = expansion(c(.12, .12))) +
  scale_y_reverse("Quartile of risk adjusted mortality", breaks = 1:4,
                  labels = c("1 (lowest)", "2", "3", "4 (highest)")) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(color = GRID, linewidth = .25),
        axis.text = element_text(color = INK, size = 8.5),
        axis.title.y = element_text(color = INK, size = 9),
        legend.position = "bottom")
tif(p8, "Figure8_quartile_movement", 5.4, 4.2)

cat(sprintf("\nunits changing quartile: %d of %d (%.1f%%)\n",
            sum(flow[moved == TRUE, N]), sum(flow$N),
            100*sum(flow[moved == TRUE, N])/sum(flow$N)))
