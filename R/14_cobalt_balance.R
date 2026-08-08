# ---------------------------------------------------------------------------
# 14_cobalt_balance.R
#
# Covariate balance between units in the highest and lowest quintile of
# treatment limitation rate, before and after inverse probability weighting.
#
# The argument: if case-mix explained the difference in limitation practice,
# then balancing case-mix should remove it. We test that directly.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(cobalt); library(WeightIt); library(ggplot2)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
PAL  <- c("#00B6B3", "#007AA5", "#433864", "#200F1D")
INK  <- "#0b0b0b"; MUTED <- "#898781"; GRID <- "#e1e0d9"; ACC <- "#C81560"

d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]

hr <- d[, .(n = .N, lim_rate = mean(lim_tier_24h >= 2)), by = hospitalid][n >= 100]
hr[, q := cut(lim_rate, quantile(lim_rate, seq(0,1,.2)),
              include.lowest = TRUE, labels = paste0("Q", 1:5))]
d <- merge(d, hr[, .(hospitalid, unit_lim_rate = lim_rate, q)], by = "hospitalid")

x <- d[q %in% c("Q1","Q5")]
x[, high_lim := as.integer(q == "Q5")]
x[, age_i   := as.numeric(fifelse(is.na(age_num), 91L, age_num))]
x[, female  := as.integer(gender == "Female")]
x[, from_ed := as.integer(unitadmitsource == "Emergency Department")]
x <- x[!is.na(from_ed)]

cat(sprintf("low limitation units  %d, %s stays, mean rate %.3f\n",
            hr[q=="Q1", .N], format(sum(x$high_lim==0), big.mark=","),
            hr[q=="Q1", mean(lim_rate)]))
cat(sprintf("high limitation units %d, %s stays, mean rate %.3f\n\n",
            hr[q=="Q5", .N], format(sum(x$high_lim==1), big.mark=","),
            hr[q=="Q5", mean(lim_rate)]))

covs <- x[, .(Age = age_i, Female = female,
              `APACHE IVa score` = as.numeric(apachescore),
              `Acute physiology score` = as.numeric(acutephysiologyscore),
              `Predicted mortality` = pred,
              `Metastatic or hematologic cancer` = as.numeric(cancer_apache),
              Immunosuppression = as.numeric(immunosuppression == 1),
              Cirrhosis = as.numeric(cirrhosis == 1),
              `Hepatic failure` = as.numeric(hepaticfailure == 1),
              Diabetes = as.numeric(diabetes == 1),
              `Ventilated on day 1` = as.numeric(ventday1 == 1),
              `Admitted from emergency department` = from_ed)]

# --- inverse probability weights -------------------------------------------
W <- weightit(high_lim ~ Age + Female + `APACHE IVa score` +
                `Acute physiology score` + `Predicted mortality` +
                `Metastatic or hematologic cancer` + Immunosuppression +
                Cirrhosis + `Hepatic failure` + Diabetes +
                `Ventilated on day 1` + `Admitted from emergency department`,
              data = cbind(high_lim = x$high_lim, covs),
              method = "glm", estimand = "ATE")

bt <- bal.tab(W, un = TRUE, thresholds = c(m = .1))
print(bt)

# --- Love plot --------------------------------------------------------------
lp <- love.plot(
  bt,
  stats       = "mean.diffs",
  abs         = FALSE,
  thresholds  = c(m = .1),
  var.order   = "unadjusted",
  drop.distance = TRUE,
  line        = TRUE,
  colors      = c(ACC, PAL[2]),
  shapes      = c("triangle filled", "circle filled"),
  size        = 2.6,
  sample.names = c("Unweighted", "Weighted"),
  title       = NULL,
  themes      = theme_minimal(base_size = 9)
) +
  annotate("rect", xmin = -.1, xmax = .1, ymin = -Inf, ymax = Inf,
           fill = GRID, alpha = .45) +
  labs(x = "Standardized mean difference, high minus low limitation units",
       y = NULL) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = GRID, linewidth = .25),
        axis.text.y  = element_text(color = INK, size = 8.5),
        axis.text.x  = element_text(color = MUTED, size = 8),
        axis.title.x = element_text(color = INK, size = 9),
        legend.position = "bottom", legend.title = element_blank())
lp$layers <- c(lp$layers[[length(lp$layers)]], lp$layers[-length(lp$layers)])

f <- file.path(sub, "figures", "Figure6_balance.tiff")
ggsave(f, lp, device = "tiff", width = 6.6, height = 4.6, units = "in",
       dpi = 600, compression = "lzw", bg = "white")
cat(sprintf("\nsaved %s  %.1f MB\n", basename(f), file.size(f)/1e6))

# --- does the limitation difference survive weighting? ----------------------
x[, w := W$weights]
cat("\n", strrep("=", 62), "\n", sep = "")
cat(" DOES THE PRACTICE DIFFERENCE SURVIVE CASE-MIX BALANCING\n")
cat(strrep("=", 62), "\n", sep = "")
raw <- x[, .(rate = mean(lim_tier_24h >= 2)), by = high_lim][order(high_lim)]
wtd <- x[, .(rate = weighted.mean(lim_tier_24h >= 2, w)), by = high_lim][order(high_lim)]
cat(sprintf("  unweighted  low %.3f  high %.3f  difference %+.3f  ratio %.2f\n",
            raw$rate[1], raw$rate[2], raw$rate[2]-raw$rate[1], raw$rate[2]/raw$rate[1]))
cat(sprintf("  weighted    low %.3f  high %.3f  difference %+.3f  ratio %.2f\n",
            wtd$rate[1], wtd$rate[2], wtd$rate[2]-wtd$rate[1], wtd$rate[2]/wtd$rate[1]))

bal <- as.data.table(bal.tab(W, un = TRUE)$Balance, keep.rownames = "variable")
fwrite(bal, file.path(sub, "supplementary", "TableS3_covariate_balance.csv"))
cat("\nsaved supplementary/TableS3_covariate_balance.csv\n")
