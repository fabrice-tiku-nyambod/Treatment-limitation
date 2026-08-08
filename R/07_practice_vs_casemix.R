# ---------------------------------------------------------------------------
# 07_practice_vs_casemix.R
#
# Two analyses, both serving the single objective.
#
# PART A -- Is between-hospital variation in limitation documentation driven
#           by PATIENTS or by PRACTICE? If it survives case-mix adjustment it
#           is practice, and benchmarking that ignores it penalises culture.
#
# PART B -- Which fix actually works? Compare four benchmarking strategies
#           and see which recovers the effect with least complexity.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(lme4)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp := qlogis(pred)]
d[, cs := relevel(factor(lim_tier_24h), ref = "1")]
d[, lim := as.integer(lim_tier_24h >= 2)]
d[, age_i := fifelse(is.na(age_num), 91L, age_num)]

# ===========================================================================
cat("=========================================================\n")
cat(" PART A -- practice or case-mix?\n")
cat("=========================================================\n")

icc_of <- function(m) { v <- as.numeric(VarCorr(m)$hospitalid); v/(v + pi^2/3) }

m_null <- glmer(lim ~ 1 + (1|hospitalid), data = d, family = binomial, nAGQ = 0)
m_adj  <- glmer(lim ~ lp + age_i + gender + cancer_apache + immunosuppression +
                     cirrhosis + diabetes + ventday1 + (1|hospitalid),
                data = d, family = binomial, nAGQ = 0)

cat(sprintf("\nunadjusted ICC                 : %.4f\n", icc_of(m_null)))
cat(sprintf("case-mix adjusted ICC          : %.4f\n", icc_of(m_adj)))
cat(sprintf("proportion of between-hospital variance surviving adjustment: %.1f%%\n",
            100 * as.numeric(VarCorr(m_adj)$hospitalid) /
                  as.numeric(VarCorr(m_null)$hospitalid)))

# median odds ratio -- how different are two randomly chosen hospitals?
mor <- function(m) exp(sqrt(2 * as.numeric(VarCorr(m)$hospitalid)) * qnorm(0.75))
cat(sprintf("\nMedian Odds Ratio, unadjusted   : %.2f\n", mor(m_null)))
cat(sprintf("Median Odds Ratio, adjusted     : %.2f\n", mor(m_adj)))
cat("  (MOR = median increase in odds of limitation when moving a patient\n")
cat("   from a lower- to a higher-limitation hospital; 1.0 = no variation)\n")

# observed vs case-mix-expected limitation rate per hospital
d[, exp_lim := predict(m_adj, re.form = NA, type = "response")]
hl <- d[, .(n = .N, obs_rate = mean(lim), exp_rate = mean(exp_lim)),
        by = hospitalid][n >= 100]
hl[, ratio := obs_rate / exp_rate]
cat(sprintf("\nobserved:case-mix-expected limitation ratio across %d hospitals:\n", nrow(hl)))
cat(sprintf("  median %.2f, IQR %.2f-%.2f, range %.2f-%.2f\n",
            median(hl$ratio), quantile(hl$ratio,.25), quantile(hl$ratio,.75),
            min(hl$ratio), max(hl$ratio)))
cat(sprintf("  %.1f-fold difference between least and most limiting hospital,\n",
            max(hl$ratio)/min(hl$ratio)))
cat("  AFTER accounting for patient case-mix.\n")

# ===========================================================================
cat("\n=========================================================\n")
cat(" PART B -- which fix works?\n")
cat("=========================================================\n")

strategies <- list(
  "A. current (APACHE only)"        = list(f = died_hosp ~ lp,      sub = quote(TRUE)),
  "B. adjust for full code status"  = list(f = died_hosp ~ lp + cs, sub = quote(TRUE)),
  "C. exclude comfort-care only"    = list(f = died_hosp ~ lp,      sub = quote(lim_tier_24h != 4)),
  "D. exclude any limitation"       = list(f = died_hosp ~ lp,      sub = quote(lim_tier_24h < 2))
)

ranks <- list(); keep <- NULL
for (nm in names(strategies)) {
  s   <- strategies[[nm]]
  sub <- d[eval(s$sub)]
  m   <- glm(s$f, data = sub, family = binomial)
  sub[, e := predict(m, type = "response")]
  hh  <- sub[, .(n = .N, obs = sum(died_hosp), e = sum(e)), by = hospitalid]
  hh  <- hh[hospitalid %in% unique(d[, .N, by = hospitalid][N >= 100, hospitalid])]
  hh[, smr := obs/e]
  setorder(hh, hospitalid)
  ranks[[nm]] <- hh[, .(hospitalid, smr, rank = frank(smr), n)]
  cat(sprintf("\n%-32s stays retained %s (%.1f%%)\n", nm,
              format(nrow(sub), big.mark=","), 100*nrow(sub)/nrow(d)))
}

base <- ranks[["A. current (APACHE only)"]]
cat("\n--- movement relative to current practice ---\n")
cat(sprintf("%-32s %8s %10s %10s\n", "strategy", "medianD", "quartileD", "outlierD"))
for (nm in names(ranks)[-1]) {
  m <- merge(base[, .(hospitalid, r0 = rank, s0 = smr)],
             ranks[[nm]][, .(hospitalid, r1 = rank, s1 = smr, n)], by = "hospitalid")
  m[, `:=`(q0 = cut(r0, quantile(r0, seq(0,1,.25)), include.lowest=TRUE, labels=1:4),
           q1 = cut(r1, quantile(r1, seq(0,1,.25)), include.lowest=TRUE, labels=1:4))]
  cat(sprintf("%-32s %8.1f %9.1f%% %9s\n", nm,
              median(abs(m$r1 - m$r0)),
              100*mean(m$q0 != m$q1),
              sprintf("%.3f", cor(m$s0, m$s1, method="spearman"))))
}
cat("\n  medianD  = median absolute rank shift (positions, of 162)\n")
cat("  quartileD= %% of hospitals changing quartile\n")
cat("  outlierD = Spearman correlation of SMRs with current practice\n")

fwrite(hl, file.path(proj, "results", "hospital_limitation_casemix.csv"))
cat("\nsaved results/hospital_limitation_casemix.csv\n")
