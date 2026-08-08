# ---------------------------------------------------------------------------
# 03_calibration_hospital_timing.R
# Secondary analyses: flexible calibration + ICI, hospital variation,
# timing of limitation, and Table 1.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(lme4)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, cs_lab := factor(fifelse(lim_tier_24h == 0, "Undocumented",
                     fifelse(lim_tier_24h == 1, "Full therapy",
                     fifelse(lim_tier_24h == 2, "DNR-type",
                     fifelse(lim_tier_24h == 3, "Partial withdrawal", "Comfort only")))),
                levels = c("Undocumented","Full therapy","DNR-type",
                           "Partial withdrawal","Comfort only"))]

# --- Integrated Calibration Index -----------------------------------------
ici <- function(p, y) {
  if (length(unique(y)) < 2 || length(y) < 50) return(c(NA, NA))
  fit <- tryCatch(loess(y ~ p, degree = 1, span = 0.9), error = function(e) NULL)
  if (is.null(fit)) return(c(NA, NA))
  s <- pmin(pmax(predict(fit), 0), 1)
  c(mean(abs(s - p), na.rm = TRUE), max(abs(s - p), na.rm = TRUE))
}

cat("==========================================================\n")
cat(" CALIBRATION BY CODE STATUS AND CANCER\n")
cat("==========================================================\n")
res <- d[, {
  v <- ici(pred, died_hosp)
  .(n = .N, pred = round(mean(pred),4), obs = round(mean(died_hosp),4),
    smr = round(sum(died_hosp)/sum(pred),3),
    ICI = round(v[1],4), Emax = round(v[2],4))
}, by = .(cs_lab, cancer = fifelse(cancer_apache==1,"Cancer","No cancer"))][order(cs_lab, cancer)]
print(res)
fwrite(res, file.path(proj, "results", "table2_calibration_by_codestatus.csv"))

# --- Figure 2: calibration curves -----------------------------------------
plotdat <- d[cs_lab != "Undocumented"]
plotdat[, bin := cut(pred, breaks = quantile(pred, seq(0,1,0.05), na.rm=TRUE),
                     include.lowest = TRUE, labels = FALSE), by = cs_lab]
curve <- plotdat[, .(x = mean(pred), y = mean(died_hosp), n = .N),
                 by = .(cs_lab, bin)][n >= 20]

p2 <- ggplot(curve, aes(x, y, color = cs_lab)) +
  geom_abline(slope = 1, intercept = 0, linetype = 2, color = "grey50") +
  geom_point(aes(size = n), alpha = .6) +
  geom_smooth(method = "loess", se = FALSE, span = 1, linewidth = .8) +
  scale_x_continuous("APACHE IVa predicted mortality", labels = scales::percent) +
  scale_y_continuous("Observed mortality", labels = scales::percent) +
  scale_size_continuous(guide = "none") +
  labs(color = "Code status at 24h",
       title = "APACHE IVa calibration by code status",
       subtitle = "Points are 5% risk bins; dashed line is perfect calibration") +
  theme_minimal(base_size = 11) + theme(legend.position = "bottom")
ggsave(file.path(proj, "figures", "fig2_calibration_by_codestatus.png"),
       p2, width = 8, height = 6, dpi = 600)
cat("\nsaved figures/fig2_calibration_by_codestatus.png\n")

# --- Hospital-level variation ---------------------------------------------
cat("\n==========================================================\n")
cat(" HOSPITAL-LEVEL VARIATION\n")
cat("==========================================================\n")
hosp <- d[, .(n = .N,
              lim_rate = mean(lim_tier_24h >= 2),
              smr = sum(died_hosp)/sum(pred),
              cancer_pct = mean(cancer_apache)), by = hospitalid][n >= 100]
cat(sprintf("hospitals with >=100 stays: %d\n", nrow(hosp)))
cat(sprintf("limitation rate: median %.3f  IQR %.3f-%.3f  range %.3f-%.3f\n",
            median(hosp$lim_rate), quantile(hosp$lim_rate,.25),
            quantile(hosp$lim_rate,.75), min(hosp$lim_rate), max(hosp$lim_rate)))
cat(sprintf("SMR:             median %.3f  IQR %.3f-%.3f  range %.3f-%.3f\n",
            median(hosp$smr), quantile(hosp$smr,.25), quantile(hosp$smr,.75),
            min(hosp$smr), max(hosp$smr)))
ct <- cor.test(hosp$lim_rate, hosp$smr, method = "spearman")
cat(sprintf("Spearman lim_rate vs SMR: rho = %+.3f, p = %.3f\n",
            ct$estimate, ct$p.value))
fwrite(hosp, file.path(proj, "results", "hospital_level.csv"))

p3 <- ggplot(hosp, aes(reorder(factor(hospitalid), lim_rate), lim_rate)) +
  geom_col(fill = "steelblue", width = .8) +
  labs(x = "Hospital (ordered)", y = "Treatment limitation rate at 24h",
       title = "Between-hospital variation in early treatment limitation",
       subtitle = sprintf("%d hospitals with >=100 ICU stays", nrow(hosp))) +
  scale_y_continuous(labels = scales::percent) +
  theme_minimal(base_size = 11) +
  theme(axis.text.x = element_blank(), axis.ticks.x = element_blank())
ggsave(file.path(proj, "figures", "fig3_hospital_variation.png"),
       p3, width = 9, height = 5, dpi = 600)
cat("saved figures/fig3_hospital_variation.png\n")

# --- ICC from random-intercept model --------------------------------------
cat("\n--- ICC for limitation documentation (hospital random intercept) ---\n")
g <- tryCatch(
  glmer(I(lim_tier_24h >= 2) ~ 1 + (1 | hospitalid), data = d,
        family = binomial, nAGQ = 0),
  error = function(e) NULL)
if (!is.null(g)) {
  v <- as.numeric(VarCorr(g)$hospitalid)
  cat(sprintf("  between-hospital variance %.4f, ICC = %.3f\n", v, v/(v + pi^2/3)))
} else cat("  model failed to converge\n")

# --- Timing ----------------------------------------------------------------
cat("\n==========================================================\n")
cat(" TIMING OF FIRST LIMITATION (minutes from ICU admission)\n")
cat("==========================================================\n")
tim <- d[!is.na(first_lim_offset), .(
  n = .N,
  median_min = as.numeric(median(first_lim_offset)),
  q25 = as.numeric(quantile(first_lim_offset,.25)),
  q75 = as.numeric(quantile(first_lim_offset,.75)),
  within_6h = round(mean(first_lim_offset <= 360),3)
), by = .(cancer = fifelse(cancer_apache==1,"Cancer","No cancer"))]
print(tim)

cat("\n--- deepening after 24h (tier_ever vs tier_24h) ---\n")
deep <- d[, .(n = .N, deepened = sum(lim_tier_ever > lim_tier_24h),
              pct = round(100*mean(lim_tier_ever > lim_tier_24h),2)),
          by = .(cancer = fifelse(cancer_apache==1,"Cancer","No cancer"))]
print(deep)

# --- Table 1 ---------------------------------------------------------------
cat("\n==========================================================\n")
cat(" TABLE 1 - cohort characteristics\n")
cat("==========================================================\n")
t1 <- d[, .(
  n              = .N,
  age_median     = median(age_num, na.rm = TRUE),
  age_over89_pct = round(100*mean(age_over_89),1),
  female_pct     = round(100*mean(gender == "Female", na.rm = TRUE),1),
  apache_median  = median(apachescore, na.rm = TRUE),
  pred_mean      = round(mean(pred),4),
  died_pct       = round(100*mean(died_hosp),2),
  vent_pct       = round(100*mean(ventday1 == 1, na.rm = TRUE),1),
  elective_pct   = round(100*mean(electivesurgery == 1, na.rm = TRUE),1),
  lim24_pct      = round(100*mean(lim_tier_24h >= 2),1)
), by = .(cancer = fifelse(cancer_apache==1,"Cancer","No cancer"))][order(cancer)]
print(t(t1))
fwrite(t1, file.path(proj, "results", "table1_cohort.csv"))
cat("\nsaved results/table1_cohort.csv\n")
