# ---------------------------------------------------------------------------
# 40_limitation_timing.R
#
# Timing of limitation orders within the 24 hour window.
#
# An order documented within 24 hours of unit admission may be written at
# arrival, reflecting prognosis known on presentation or a prior preference,
# or after an initial period of full treatment that has failed. The two carry
# different meanings and the main exposure does not separate them. This
# script does, using tier specific offsets from sql/03_limitation_timing.sql.
#
#   A  when was the order at the stay's most restrictive tier first written
#   B  calibration by tier and timing, SMR with exact Poisson limits and ICI
#   C  recalibration model with the tiers split by timing
#   D  between unit variation in early orders only, unweighted and weighted
#   E  unit ranking when only early orders count, or only early comfort
#      measures admissions are excluded
#   F  Figure S2
#
# Early is defined as an order first documented within 4 hours of unit
# admission, including orders that predate admission. Four hours is inside
# the period of admission assessment and initial orders and precedes any
# sustained trial of treatment. One hour is reported as a stricter cut.
# A second definition uses the record itself: an order preceded by a Full
# therapy entry in the same 24 hours marks de-escalation after an initial
# decision to treat fully.
#
# This analysis was added after editorial review and was not prespecified.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(sandwich); library(lmtest); library(lme4)
  library(WeightIt); library(ggplot2); library(patchwork)
})

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
res  <- file.path(proj, "results")
dir.create(file.path(sub, "supplementary"), showWarnings = FALSE)

EARLY_MIN  <- 240   # primary cut, minutes from unit admission
STRICT_MIN <- 60    # stricter cut

d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
tm <- fread(file.path(proj, "data_private", "limitation_timing.csv"))
d <- merge(d, tm, by = "patientunitstayid", all.x = TRUE)

d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp := qlogis(pred)]
d[, cs := factor(lim_tier_24h, levels = 0:4,
                 labels = c("Undocumented", "Full therapy", "DNR type",
                            "Partial withdrawal", "Comfort measures"))]

# offset of the first order at the stay's own most restrictive tier
d[, tier_offset := fcase(lim_tier_24h == 2L, as.numeric(first_dnr_offset),
                         lim_tier_24h == 3L, as.numeric(first_partial_offset),
                         lim_tier_24h == 4L, as.numeric(first_cmo_offset),
                         default = NA_real_)]
stopifnot(d[lim_tier_24h >= 2, all(!is.na(tier_offset))])

d[, early  := lim_tier_24h >= 2 & tier_offset <= EARLY_MIN]
d[, strict := lim_tier_24h >= 2 & tier_offset <= STRICT_MIN]
# de-escalation: a Full therapy entry documented before the limitation
d[, deesc  := lim_tier_24h >= 2 & !is.na(first_full_offset) &
              first_full_offset < tier_offset]
# escalation within the window: comfort measures preceded by a DNR type order
d[, dnr_first := lim_tier_24h == 4L & !is.na(first_dnr_offset) &
                 first_dnr_offset < first_cmo_offset]

# ===========================================================================
cat(strrep("=", 70), "\n A  TIMING OF THE MOST RESTRICTIVE ORDER\n", strrep("=", 70), "\n", sep = "")
# ===========================================================================
tab_a <- d[lim_tier_24h >= 2, .(
  n            = .N,
  median_min   = as.numeric(median(tier_offset)),
  q25_min      = as.numeric(quantile(tier_offset, .25)),
  q75_min      = as.numeric(quantile(tier_offset, .75)),
  pct_before_admission = round(100 * mean(tier_offset <= 0), 1),
  pct_within_1h  = round(100 * mean(tier_offset <= STRICT_MIN), 1),
  pct_within_4h  = round(100 * mean(tier_offset <= EARLY_MIN), 1),
  pct_within_12h = round(100 * mean(tier_offset <= 720), 1),
  pct_after_full_therapy = round(100 * mean(deesc), 1),
  pct_dnr_first  = round(100 * mean(dnr_first), 1)
), by = cs][order(cs)]
print(tab_a)
fwrite(tab_a, file.path(res, "timing_by_tier.csv"))

# ===========================================================================
cat("\n", strrep("=", 70), "\n B  CALIBRATION BY TIER AND TIMING\n", strrep("=", 70), "\n", sep = "")
# ===========================================================================
ici <- function(p, y) {
  if (length(unique(y)) < 2 || length(y) < 50) return(NA_real_)
  f <- tryCatch(loess(y ~ p, degree = 1, span = .9), error = function(e) NULL)
  if (is.null(f)) return(NA_real_)
  mean(abs(pmin(pmax(predict(f), 0), 1) - p), na.rm = TRUE)
}
smr_ci <- function(o, e) c(qchisq(.025, 2 * o) / 2 / e, qchisq(.975, 2 * (o + 1)) / 2 / e)

d[, timing := fcase(lim_tier_24h < 2, "Reference",
                    early, sprintf("Within %d h", EARLY_MIN / 60),
                    default = sprintf("%d to 24 h", EARLY_MIN / 60))]
d[, timing := factor(timing, levels = c("Reference", sprintf("Within %d h", EARLY_MIN / 60),
                                        sprintf("%d to 24 h", EARLY_MIN / 60)))]

tab_b <- d[lim_tier_24h >= 1, {
  o <- sum(died_hosp); e <- sum(pred); ci <- smr_ci(o, e)
  .(n = .N, observed = o, predicted = round(e, 1),
    obs_pct = round(100 * mean(died_hosp), 1), pred_pct = round(100 * mean(pred), 1),
    smr = round(o / e, 2), smr_lo = round(ci[1], 2), smr_hi = round(ci[2], 2),
    ici = round(ici(pred, died_hosp), 3))
}, by = .(cs, timing)][order(cs, timing)]
print(tab_b)

# stricter one hour cut, comfort measures only, to show the answer is not
# sensitive to where the line is drawn
tab_b1 <- d[lim_tier_24h == 4, {
  o <- sum(died_hosp); e <- sum(pred); ci <- smr_ci(o, e)
  .(n = .N, smr = round(o / e, 2), smr_lo = round(ci[1], 2), smr_hi = round(ci[2], 2))
}, by = .(within_1h = strict)][order(-within_1h)]
cat("\ncomfort measures by 1 hour cut\n"); print(tab_b1)

# de-escalation definition
tab_b2 <- d[lim_tier_24h >= 2, {
  o <- sum(died_hosp); e <- sum(pred); ci <- smr_ci(o, e)
  .(n = .N, smr = round(o / e, 2), smr_lo = round(ci[1], 2), smr_hi = round(ci[2], 2),
    ici = round(ici(pred, died_hosp), 3))
}, by = .(cs, after_full_therapy = deesc)][order(cs, after_full_therapy)]
cat("\nby whether a Full therapy entry preceded the limitation\n"); print(tab_b2)

fwrite(tab_b,  file.path(sub, "supplementary", "TableS6_calibration_by_timing.csv"))
fwrite(tab_b2, file.path(res, "calibration_by_deescalation.csv"))

# ===========================================================================
cat("\n", strrep("=", 70), "\n C  RECALIBRATION MODEL, TIERS SPLIT BY TIMING\n", strrep("=", 70), "\n", sep = "")
# ===========================================================================
d[, cs_t := fifelse(lim_tier_24h >= 2, paste(as.character(cs), as.character(timing), sep = ", "),
                    as.character(cs))]
lv <- c("Full therapy",
        as.vector(t(outer(c("DNR type", "Partial withdrawal", "Comfort measures"),
                          levels(d$timing)[-1], paste, sep = ", "))),
        "Undocumented")
d[, cs_t := factor(cs_t, levels = lv)]

m_ref <- glm(died_hosp ~ lp + cs,   data = d, family = binomial)
m_tim <- glm(died_hosp ~ lp + cs_t, data = d, family = binomial)
ct <- coeftest(m_tim, vcov. = vcovCL(m_tim, cluster = d$hospitalid))
or <- data.table(term = rownames(ct), or = exp(ct[, 1]),
                 lo = exp(ct[, 1] - 1.96 * ct[, 2]), hi = exp(ct[, 1] + 1.96 * ct[, 2]),
                 p = ct[, 4])[grepl("^cs_t", term)]
or[, term := sub("^cs_t", "", term)]
or[, c("or", "lo", "hi") := lapply(.SD, round, 2), .SDcols = c("or", "lo", "hi")]
print(or)
fwrite(or, file.path(res, "recalibration_or_by_timing.csv"))

# does splitting by timing improve on the ordered scale alone
lrt <- anova(m_ref, m_tim, test = "Chisq")
cat(sprintf("\nLR test, timing split vs ordered scale: chi2 = %.1f on %d df, p = %.3g\n",
            lrt$Deviance[2], lrt$Df[2], lrt$`Pr(>Chi)`[2]))

# Wald tests, early vs late within tier, cluster robust
V <- vcovCL(m_tim, cluster = d$hospitalid); b <- coef(m_tim)
for (tier in c("DNR type", "Partial withdrawal", "Comfort measures")) {
  a <- paste0("cs_t", tier, ", ", levels(d$timing)[2])
  z <- paste0("cs_t", tier, ", ", levels(d$timing)[3])
  diff <- b[a] - b[z]; se <- sqrt(V[a, a] + V[z, z] - 2 * V[a, z])
  cat(sprintf("  %-20s early vs late: OR ratio %.2f (%.2f to %.2f), p = %.3f\n",
              tier, exp(diff), exp(diff - 1.96 * se), exp(diff + 1.96 * se),
              2 * pnorm(-abs(diff / se))))
}

# ===========================================================================
cat("\n", strrep("=", 70), "\n D  BETWEEN UNIT VARIATION IN EARLY ORDERS\n", strrep("=", 70), "\n", sep = "")
# ===========================================================================
d[, lim := as.integer(lim_tier_24h >= 2)]
d[, lim_early := as.integer(early)]
d[, lim_late  := as.integer(lim_tier_24h >= 2 & !early)]

hr <- d[, .(n = .N, lim_rate = mean(lim), early_rate = mean(lim_early),
            late_rate = mean(lim_late),
            early_share = sum(lim_early) / pmax(sum(lim), 1)),
        by = hospitalid][n >= 100]
cat(sprintf("units %d\n", nrow(hr)))
cat(sprintf("early limitation rate: median %.1f%%, range %.1f to %.1f%%\n",
            100 * median(hr$early_rate), 100 * min(hr$early_rate), 100 * max(hr$early_rate)))
cat(sprintf("share of a unit's limitations that are early: median %.1f%%, IQR %.1f to %.1f%%\n",
            100 * median(hr$early_share), 100 * quantile(hr$early_share, .25),
            100 * quantile(hr$early_share, .75)))
cat(sprintf("Spearman, unit limitation rate vs early share: %.3f\n",
            cor(hr$lim_rate, hr$early_share, method = "spearman")))
cat(sprintf("Spearman, unit early rate vs late rate: %.3f\n",
            cor(hr$early_rate, hr$late_rate, method = "spearman")))

# quintiles by overall limitation rate, as in the main analysis
hr[, q := cut(lim_rate, quantile(lim_rate, seq(0, 1, .2)),
              include.lowest = TRUE, labels = paste0("Q", 1:5))]
x <- merge(d, hr[, .(hospitalid, q)], by = "hospitalid")[q %in% c("Q1", "Q5")]
x[, high_lim := as.integer(q == "Q5")]
x[, age_i   := as.numeric(fifelse(is.na(age_num), 91L, age_num))]
x[, female  := as.integer(gender == "Female")]
x[, from_ed := as.integer(unitadmitsource == "Emergency Department")]
x <- x[!is.na(from_ed)]

W <- weightit(high_lim ~ age_i + female + apachescore + acutephysiologyscore + pred +
                cancer_apache + immunosuppression + cirrhosis + hepaticfailure +
                diabetes + ventday1 + from_ed,
              data = x, method = "glm", estimand = "ATE")
x[, w := W$weights]
# `wt` rather than `w`: inside the data.table call a bare `w` would resolve to
# the weight column, not the argument
ratio <- function(v, wt = NULL) {
  r <- x[, .(rate = if (is.null(wt)) mean(get(v)) else weighted.mean(get(v), wt[.I])),
         by = high_lim][order(high_lim)]$rate
  c(low = r[1], high = r[2], ratio = r[2] / r[1])
}
tab_d <- rbindlist(list(
  data.table(exposure = "Any limitation", weighting = "Unweighted", t(ratio("lim"))),
  data.table(exposure = "Any limitation", weighting = "Weighted",   t(ratio("lim", x$w))),
  data.table(exposure = "Early limitation", weighting = "Unweighted", t(ratio("lim_early"))),
  data.table(exposure = "Early limitation", weighting = "Weighted",   t(ratio("lim_early", x$w))),
  data.table(exposure = "Late limitation", weighting = "Unweighted", t(ratio("lim_late"))),
  data.table(exposure = "Late limitation", weighting = "Weighted",   t(ratio("lim_late", x$w)))))
tab_d[, c("low", "high") := lapply(.SD, function(v) round(100 * v, 1)), .SDcols = c("low", "high")]
tab_d[, ratio := round(ratio, 2)]
print(tab_d)

# mixed models, early orders only
d[, age_i := fifelse(is.na(age_num), 91L, age_num)]
icc_of <- function(m) { v <- as.numeric(VarCorr(m)$hospitalid); v / (v + pi^2 / 3) }
mor    <- function(m) exp(sqrt(2 * as.numeric(VarCorr(m)$hospitalid)) * qnorm(.75))
m0 <- glmer(lim_early ~ 1 + (1 | hospitalid), data = d, family = binomial, nAGQ = 0)
m1 <- glmer(lim_early ~ lp + age_i + gender + cancer_apache + immunosuppression +
              cirrhosis + diabetes + ventday1 + (1 | hospitalid),
            data = d, family = binomial, nAGQ = 0)
cat(sprintf("\nearly orders: ICC %.3f unadjusted, %.3f adjusted; MOR %.2f unadjusted, %.2f adjusted\n",
            icc_of(m0), icc_of(m1), mor(m0), mor(m1)))
tab_d <- rbind(tab_d, data.table(exposure = "Early limitation", weighting = "Mixed model",
                                 low = icc_of(m0), high = icc_of(m1), ratio = mor(m1)),
               fill = TRUE)
fwrite(tab_d, file.path(res, "variation_early_orders.csv"))

# ===========================================================================
cat("\n", strrep("=", 70), "\n E  RANKING WHEN ONLY EARLY ORDERS COUNT\n", strrep("=", 70), "\n", sep = "")
# ===========================================================================
rank_units <- function(dd, expB_col) {
  h <- dd[, .(n = .N, obs = sum(died_hosp), eA = sum(expA), eB = sum(get(expB_col)),
              early_rate = mean(lim_early), lim_rate = mean(lim)), by = hospitalid][n >= 100]
  h[, `:=`(smrA = obs / eA, smrB = obs / eB)]
  h[, `:=`(rankA = frank(smrA), rankB = frank(smrB))]
  h[, `:=`(qA = cut(rankA, quantile(rankA, seq(0, 1, .25)), include.lowest = TRUE, labels = 1:4),
           qB = cut(rankB, quantile(rankB, seq(0, 1, .25)), include.lowest = TRUE, labels = 1:4))]
  h[, `:=`(loA = qchisq(.025, 2 * obs) / 2 / eA, hiA = qchisq(.975, 2 * (obs + 1)) / 2 / eA,
           loB = qchisq(.025, 2 * obs) / 2 / eB, hiB = qchisq(.975, 2 * (obs + 1)) / 2 / eB)]
  h[, `:=`(flagA = fifelse(loA > 1, "high", fifelse(hiA < 1, "low", "as expected")),
           flagB = fifelse(loB > 1, "high", fifelse(hiB < 1, "low", "as expected")))]
  h
}
summ <- function(h, label) {
  data.table(strategy = label, units = nrow(h),
             spearman_smr = round(cor(h$smrA, h$smrB, method = "spearman"), 3),
             median_abs_shift = median(abs(h$rankB - h$rankA)),
             quartile_change_n = sum(h$qA != h$qB),
             quartile_change_pct = round(100 * mean(h$qA != h$qB), 1),
             outlier_change_n = sum(h$flagA != h$flagB),
             outlier_change_pct = round(100 * mean(h$flagA != h$flagB), 1),
             rho_shift_vs_early_rate = round(cor(h$rankB - h$rankA, h$early_rate, method = "spearman"), 3),
             rho_shift_vs_lim_rate   = round(cor(h$rankB - h$rankA, h$lim_rate, method = "spearman"), 3))
}

mA <- glm(died_hosp ~ lp, data = d, family = binomial)
d[, expA := predict(mA, type = "response")]

# 1 full ordered scale, as in the main analysis
d[, cs_ref := relevel(factor(lim_tier_24h), ref = "1")]
mB1 <- glm(died_hosp ~ lp + cs_ref, data = d, family = binomial)
d[, expB1 := predict(mB1, type = "response")]

# 2 early orders only: late orders recoded to full therapy
d[, tier_early := fifelse(lim_tier_24h >= 2 & !early, 1L, lim_tier_24h)]
d[, cs_early := relevel(factor(tier_early), ref = "1")]
mB2 <- glm(died_hosp ~ lp + cs_early, data = d, family = binomial)
d[, expB2 := predict(mB2, type = "response")]

# 3 tiers split by timing
mB3 <- glm(died_hosp ~ lp + cs_t, data = d, family = binomial)
d[, expB3 := predict(mB3, type = "response")]

tab_e <- rbindlist(list(
  summ(rank_units(d, "expB1"), "Adjust, ordered scale (main analysis)"),
  summ(rank_units(d, "expB2"), sprintf("Adjust, orders within %d h only", EARLY_MIN / 60)),
  summ(rank_units(d, "expB3"), "Adjust, tiers split by timing")))

# exclusion strategies: the reference ranking uses the full cohort under model
# A; the comparison ranking refits the recalibration on the retained cohort,
# as in 07_practice_vs_casemix.R
excl <- function(keep, label) {
  h_full <- rank_units(d, "expA")[, .(hospitalid, smrA, rankA, qA, flagA)]
  dd <- d[keep]
  dd[, eX := predict(glm(died_hosp ~ lp, data = dd, family = binomial), type = "response")]
  h_ex   <- dd[, .(n = .N, obs = sum(died_hosp), eB = sum(eX),
                   early_rate = mean(lim_early), lim_rate = mean(lim)), by = hospitalid]
  h <- merge(h_full, h_ex, by = "hospitalid")[n >= 100]
  h[, smrB := obs / eB]; h[, rankB := frank(smrB)]
  h[, qB := cut(rankB, quantile(rankB, seq(0, 1, .25)), include.lowest = TRUE, labels = 1:4)]
  h[, `:=`(loB = qchisq(.025, 2 * obs) / 2 / eB, hiB = qchisq(.975, 2 * (obs + 1)) / 2 / eB)]
  h[, flagB := fifelse(loB > 1, "high", fifelse(hiB < 1, "low", "as expected"))]
  summ(h, label)
}
tab_e <- rbind(tab_e,
  excl(d$lim_tier_24h != 4, "Exclude all comfort measures admissions"),
  excl(!(d$lim_tier_24h == 4 & d$early), sprintf("Exclude comfort measures within %d h only", EARLY_MIN / 60)),
  excl(!(d$lim_tier_24h == 4 & !d$early), sprintf("Exclude comfort measures %d to 24 h only", EARLY_MIN / 60)))
print(tab_e)
fwrite(tab_e, file.path(sub, "supplementary", "TableS7_reranking_by_timing.csv"))

# ===========================================================================
cat("\n", strrep("=", 70), "\n F  FIGURE S2\n", strrep("=", 70), "\n", sep = "")
# ===========================================================================
PAL  <- c("DNR type" = "#007AA5", "Partial withdrawal" = "#433864", "Comfort measures" = "#200F1D")
INK <- "#0b0b0b"; MUTED <- "#898781"; GRID <- "#e1e0d9"; ACC <- "#C81560"
FONT <- "serif"
th <- function(base = 10) theme_minimal(base_size = base, base_family = FONT) +
  theme(text = element_text(family = FONT),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = GRID, linewidth = .25),
        axis.text  = element_text(color = MUTED, size = base - 1, family = FONT),
        axis.title = element_text(color = INK, size = base, family = FONT),
        legend.text = element_text(color = INK, size = base - 1, family = FONT),
        legend.title = element_blank(), legend.position = "bottom",
        plot.tag = element_text(face = "bold", size = 12, family = FONT))

# A cumulative timing of the most restrictive order, by tier
cd <- d[lim_tier_24h >= 2, .(hours = pmax(tier_offset, 0) / 60, cs = droplevels(cs))]
pA <- ggplot(cd, aes(hours, color = cs)) +
  stat_ecdf(linewidth = .8) +
  geom_vline(xintercept = EARLY_MIN / 60, linetype = "dashed", color = MUTED, linewidth = .4) +
  scale_color_manual(values = PAL) +
  scale_x_continuous(breaks = c(0, 4, 8, 12, 16, 20, 24), limits = c(0, 24)) +
  scale_y_continuous(labels = scales::percent) +
  labs(x = "Hours from unit admission to first order at that tier",
       y = "Cumulative proportion of admissions", tag = "A") + th()

# B SMR by tier and timing, with exact Poisson limits
sb <- tab_b[cs != "Full therapy"]
sb[, cs := droplevels(cs)]
pB <- ggplot(sb, aes(x = timing, y = smr, color = cs)) +
  geom_hline(yintercept = 1, color = MUTED, linewidth = .4) +
  geom_pointrange(aes(ymin = smr_lo, ymax = smr_hi), position = position_dodge(width = .5),
                  size = .5, linewidth = .6) +
  scale_color_manual(values = PAL) +
  labs(x = "Timing of the most restrictive order", y = "Standardized mortality ratio", tag = "B") +
  th() + guides(color = "none")   # panel A carries the shared legend

pS2 <- pA + pB
f_tiff <- file.path(sub, "figures", "FigureS2_timing.tiff")
f_pdf  <- file.path(sub, "figures_pdf", "FigureS2_timing.pdf")
dir.create(dirname(f_pdf), showWarnings = FALSE)
ggsave(f_tiff, pS2, device = "tiff", width = 7.2, height = 3.6, units = "in",
       dpi = 600, compression = "lzw", bg = "white")
ggsave(f_pdf, pS2, device = cairo_pdf, width = 7.2, height = 3.6, units = "in", bg = "white")
cat(sprintf("saved %s (%.1f MB) and %s\n", basename(f_tiff), file.size(f_tiff) / 1e6, basename(f_pdf)))

saveRDS(list(timing = tab_a, calibration = tab_b, cmo_1h = tab_b1, deesc = tab_b2,
             or = or, variation = tab_d, reranking = tab_e),
        file.path(res, "timing_results.rds"))
cat("\nsaved results/timing_results.rds\n")
