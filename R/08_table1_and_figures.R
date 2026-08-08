# ---------------------------------------------------------------------------
# 08_table1_and_figures.R
# Table 1 restratified by limitation status, plus the two remaining figures.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, cs := factor(fifelse(lim_tier_24h == 0, "Undocumented",
                 fifelse(lim_tier_24h == 1, "Full therapy",
                 fifelse(lim_tier_24h == 2, "DNR type",
                 fifelse(lim_tier_24h == 3, "Partial withdrawal", "Comfort measures")))),
            levels = c("Full therapy","DNR type","Partial withdrawal",
                       "Comfort measures","Undocumented"))]

# ---------------- Table 1 by limitation status -----------------------------
t1 <- d[, .(
  n                = .N,
  pct              = round(100 * .N / nrow(d), 1),
  age_median       = as.numeric(median(age_num, na.rm = TRUE)),
  age_over89_pct   = round(100 * mean(age_over_89), 1),
  female_pct       = round(100 * mean(gender == "Female", na.rm = TRUE), 1),
  apache_median    = as.numeric(median(apachescore, na.rm = TRUE)),
  pred_mort_pct    = round(100 * mean(pred), 1),
  observed_pct     = round(100 * mean(died_hosp), 1),
  smr              = round(sum(died_hosp) / sum(pred), 2),
  cancer_pct       = round(100 * mean(cancer_apache), 1),
  immunosupp_pct   = round(100 * mean(immunosuppression == 1, na.rm = TRUE), 1),
  vent_pct         = round(100 * mean(ventday1 == 1), 1),
  icu_los_median_h = round(as.numeric(median(unitdischargeoffset, na.rm = TRUE)) / 60, 1)
), by = cs][order(cs)]

out <- data.table(variable = names(t1)[-1])
for (lv in levels(d$cs)) out[[lv]] <- unlist(t1[cs == lv, -1], use.names = FALSE)
print(out)
fwrite(out, file.path(proj, "results", "table1_by_limitation.csv"))

cat("\n--- overall ---\n")
cat(sprintf("n = %s, hospitals = %d\n", format(nrow(d), big.mark=","), uniqueN(d$hospitalid)))
cat(sprintf("code status documented: %.1f%%\n", 100*mean(d$lim_tier_24h >= 1)))
cat(sprintf("any limitation <=24h  : %s (%.1f%%)\n",
            format(sum(d$lim_tier_24h >= 2), big.mark=","),
            100*mean(d$lim_tier_24h >= 2)))
cat(sprintf("mean predicted %.2f%%, observed %.2f%%, SMR %.2f\n",
            100*mean(d$pred), 100*mean(d$died_hosp),
            sum(d$died_hosp)/sum(d$pred)))

# ---------------- Figure 4: rank shift vs limitation rate ------------------
h <- fread(file.path(proj, "results", "hospital_reranking.csv"))

p4 <- ggplot(h, aes(lim_rate, rank_shift)) +
  geom_hline(yintercept = 0, color = "grey60") +
  geom_point(aes(size = n), alpha = .55, color = "#2b6a8f") +
  geom_smooth(method = "lm", se = TRUE, color = "#c0392b", linewidth = .8) +
  scale_x_continuous("Treatment limitation rate within 24 hours",
                     labels = scales::percent) +
  scale_y_continuous("Change in rank when limitation is modeled\n(negative = improves)") +
  scale_size_continuous("ICU stays", range = c(1, 6)) +
  labs(title = "Units with higher limitation rates are penalised by current benchmarking",
       subtitle = "Spearman rho = -0.689, p = 3.7e-24, 162 units with 100 or more stays") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(proj, "figures", "fig4_rank_shift.png"), p4,
       width = 8, height = 5.5, dpi = 600)
cat("\nsaved figures/fig4_rank_shift.png\n")

# ---------------- Figure 5: funnel plots before and after ------------------
mk <- function(smr, e, lab) data.table(e = e, smr = smr, panel = lab)
fun <- rbind(mk(h$smrA, h$eA, "Current practice"),
             mk(h$smrB, h$eB, "Limitation modeled"))
fun[, panel := factor(panel, levels = c("Current practice","Limitation modeled"))]

grid <- data.table(e = seq(max(1, min(fun$e)), max(fun$e), length.out = 300))
lim <- rbind(
  grid[, .(e, y = qchisq(.025, 2*e)/2/e, band = "95%", panel = "Current practice")],
  grid[, .(e, y = qchisq(.975, 2*(e+1))/2/e, band = "95%", panel = "Current practice")],
  grid[, .(e, y = qchisq(.001, 2*e)/2/e, band = "99.8%", panel = "Current practice")],
  grid[, .(e, y = qchisq(.999, 2*(e+1))/2/e, band = "99.8%", panel = "Current practice")])
lim <- rbind(lim, copy(lim)[, panel := "Limitation modeled"])
lim[, panel := factor(panel, levels = c("Current practice","Limitation modeled"))]
lim[, grp := paste(band, y > 1)]

p5 <- ggplot() +
  geom_line(data = lim, aes(e, y, group = grp, linetype = band), color = "grey45") +
  geom_hline(yintercept = 1, color = "grey20") +
  geom_point(data = fun, aes(e, smr), alpha = .55, color = "#2b6a8f", size = 1.8) +
  facet_wrap(~panel) +
  coord_cartesian(ylim = c(0, 2.2)) +
  scale_x_continuous("Expected deaths") +
  scale_y_continuous("Standardized mortality ratio") +
  scale_linetype_manual("Control limits", values = c("95%" = 2, "99.8%" = 3)) +
  labs(title = "Funnel plots before and after modeling treatment limitation",
       subtitle = "8.0 percent of units change outlier classification") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(proj, "figures", "fig5_funnel.png"), p5,
       width = 9, height = 5, dpi = 600)
cat("saved figures/fig5_funnel.png\n")

# ---------------- Figure 1: exclusion cascade counts -----------------------
cat("\n--- exclusion cascade (for Figure 1) ---\n")
cat("a. eICU-CRD v2.0 unit stays                     200859\n")
cat(sprintf("b. with APACHE IVa result and predictor link      %s\n",
            format(nrow(d), big.mark = ",")))
cat(sprintf("c. hospitals represented                          %d\n", uniqueN(d$hospitalid)))
cat(sprintf("d. hospitals with >=100 stays (unit-level)        %d\n",
            nrow(d[, .N, by = hospitalid][N >= 100])))
cat(sprintf("   stays in those hospitals                       %s\n",
            format(sum(d[, .N, by = hospitalid][N >= 100, N]), big.mark = ",")))
