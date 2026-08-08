# ---------------------------------------------------------------------------
# 12_love_plot.R
#
# Covariate balance between units in the highest and lowest quintile of
# treatment limitation rate. Standardized mean differences.
#
# Purpose: make visible the claim that units differ in limitation practice
# for reasons unrelated to their patients. If the covariates sit inside the
# conventional 0.1 threshold, the units are treating comparable patients.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]

# unit-level limitation rate, restricted to units with >= 100 stays
hr <- d[, .(n = .N, lim_rate = mean(lim_tier_24h >= 2)), by = hospitalid][n >= 100]
hr[, q := cut(lim_rate, quantile(lim_rate, seq(0,1,.2)),
              include.lowest = TRUE, labels = paste0("Q", 1:5))]
d <- merge(d, hr[, .(hospitalid, lim_rate, q)], by = "hospitalid")

cmp <- d[q %in% c("Q1", "Q5")]
cmp[, grp := fifelse(q == "Q5", 1, 0)]
cat(sprintf("Q1 units %d (%s stays), Q5 units %d (%s stays)\n",
            hr[q == "Q1", .N], format(nrow(cmp[grp == 0]), big.mark = ","),
            hr[q == "Q5", .N], format(nrow(cmp[grp == 1]), big.mark = ",")))
cat(sprintf("Q1 mean limitation rate %.3f, Q5 %.3f\n",
            hr[q == "Q1", mean(lim_rate)], hr[q == "Q5", mean(lim_rate)]))

vars <- list(
  "Age, years"                       = quote(as.numeric(fifelse(is.na(age_num), 91L, age_num))),
  "Female"                           = quote(as.numeric(gender == "Female")),
  "APACHE IVa score"                 = quote(as.numeric(apachescore)),
  "Acute physiology score"           = quote(as.numeric(acutephysiologyscore)),
  "APACHE IVa predicted mortality"   = quote(pred),
  "Metastatic or hematologic cancer"= quote(as.numeric(cancer_apache)),
  "Immunosuppression"                = quote(as.numeric(immunosuppression == 1)),
  "Cirrhosis"                        = quote(as.numeric(cirrhosis == 1)),
  "Hepatic failure"                  = quote(as.numeric(hepaticfailure == 1)),
  "Diabetes"                         = quote(as.numeric(diabetes == 1)),
  "Ventilated on day 1"              = quote(as.numeric(ventday1 == 1)),
  "Admitted from emergency dept"     = quote(as.numeric(unitadmitsource == "Emergency Department"))
)

smd <- rbindlist(lapply(names(vars), function(v) {
  x <- eval(vars[[v]], cmp)
  a <- x[cmp$grp == 1]; b <- x[cmp$grp == 0]
  a <- a[!is.na(a)];    b <- b[!is.na(b)]
  s <- sqrt((var(a) + var(b)) / 2)
  data.table(variable = v, smd = (mean(a) - mean(b)) / s,
             mean_hi = mean(a), mean_lo = mean(b))
}))
smd[, abs_smd := abs(smd)]
setorder(smd, abs_smd)
smd[, variable := factor(variable, levels = variable)]

cat("\nstandardized mean differences, highest vs lowest limitation quintile\n")
print(smd[order(-abs_smd), .(variable, smd = round(smd, 3),
                             mean_hi = round(mean_hi, 3),
                             mean_lo = round(mean_lo, 3))], row.names = FALSE)
cat(sprintf("\nvariables exceeding |SMD| 0.10 : %d of %d\n",
            sum(smd$abs_smd > .1), nrow(smd)))
cat(sprintf("maximum |SMD|                   : %.3f\n", max(smd$abs_smd)))

INK <- "#0b0b0b"; MUTED <- "#898781"; GRID <- "#e1e0d9"
PT  <- "#007AA5"; ACC <- "#C81560"

p <- ggplot(smd, aes(smd, variable)) +
  annotate("rect", xmin = -.1, xmax = .1, ymin = -Inf, ymax = Inf,
           fill = GRID, alpha = .55) +
  geom_vline(xintercept = 0, color = INK, linewidth = .3) +
  geom_vline(xintercept = c(-.1, .1), color = ACC, linetype = 2, linewidth = .3) +
  geom_segment(aes(x = 0, xend = smd, yend = variable), color = MUTED, linewidth = .3) +
  geom_point(size = 2.1, color = PT) +
  scale_x_continuous("Standardized mean difference",
                     limits = c(-.36, .36), breaks = seq(-.3, .3, .1)) +
  labs(y = NULL) +
  theme_minimal(base_size = 9) +
  theme(panel.grid.minor = element_blank(),
        panel.grid.major.y = element_blank(),
        panel.grid.major.x = element_line(color = GRID, linewidth = .25),
        axis.text.y = element_text(color = INK, size = 8.5),
        axis.text.x = element_text(color = MUTED, size = 8),
        axis.title.x = element_text(color = INK, size = 9))

f <- file.path(sub, "figures", "Figure6_balance.tiff")
ggsave(f, p, device = "tiff", width = 6.2, height = 4.2, units = "in",
       dpi = 600, compression = "lzw", bg = "white")
cat(sprintf("\nsaved %s  %.1f MB\n", basename(f), file.size(f)/1e6))
fwrite(smd, file.path(sub, "supplementary", "TableS3_covariate_balance.csv"))
