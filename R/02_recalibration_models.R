# ---------------------------------------------------------------------------
# 02_recalibration_models.R
#
# Primary analysis: logistic recalibration of APACHE IVa, testing whether
# cancer independently alters calibration once code status is accounted for.
#
#   logit(P(death)) = b0 + b1*logit(pred) + b2*Cancer + b3*CodeStatus
#                        + b4*(Cancer x CodeStatus)
#
# b2 is the primary estimand. Pre-specified expectation: b2 attenuates towards
# the null once b3 enters the model.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(sandwich); library(lmtest)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))

# --- prepare ---------------------------------------------------------------
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp   := qlogis(pred)]                       # linear predictor from APACHE
d[, cancer := factor(cancer_apache, 0:1, c("No", "Yes"))]

# code status: reference = full therapy. Tier 0 (undocumented) kept separate,
# reported but not interpreted. Cancer tiers 3/4 are n=48/60, so collapse
# 2/3/4 into "any limitation" for the interaction model.
d[, cs := factor(fifelse(lim_tier_24h == 0, "0_undocumented",
                 fifelse(lim_tier_24h == 1, "1_full",
                 fifelse(lim_tier_24h == 2, "2_dnr",
                 fifelse(lim_tier_24h == 3, "3_partial", "4_comfort")))))]
d[, cs := relevel(cs, ref = "1_full")]
d[, any_lim := factor(fifelse(lim_tier_24h >= 2, "Yes", "No"), levels = c("No","Yes"))]

fmt <- function(m, label, terms) {
  ct <- coeftest(m, vcov. = vcovCL(m, cluster = d$hospitalid))
  cat("\n---", label, "---\n")
  for (tn in terms) {
    if (tn %in% rownames(ct)) {
      b <- ct[tn, 1]; se <- ct[tn, 2]; p <- ct[tn, 4]
      cat(sprintf("  %-22s OR %6.3f  (95%% CI %.3f-%.3f)  p %s\n",
                  tn, exp(b), exp(b - 1.96*se), exp(b + 1.96*se),
                  ifelse(p < 1e-4, "<0.0001", sprintf("%.4f", p))))
    }
  }
  invisible(ct)
}

cat("==========================================================\n")
cat(" PRIMARY ANALYSIS - logistic recalibration of APACHE IVa\n")
cat(sprintf(" n = %s stays, %d hospitals\n", format(nrow(d), big.mark=","),
            uniqueN(d$hospitalid)))
cat(" SEs clustered on hospital throughout\n")
cat("==========================================================\n")

# --- M0: calibration of APACHE IVa overall ---------------------------------
m0 <- glm(died_hosp ~ lp, data = d, family = binomial)
ct0 <- coeftest(m0, vcov. = vcovCL(m0, cluster = d$hospitalid))
cat("\n--- M0: overall calibration ---\n")
cat(sprintf("  calibration intercept  %+.3f   (0 = perfect)\n", ct0["(Intercept)",1]))
cat(sprintf("  calibration slope       %.3f   (1 = perfect)\n", ct0["lp",1]))

# --- M1: cancer effect WITHOUT code status ---------------------------------
m1 <- glm(died_hosp ~ lp + cancer, data = d, family = binomial)
ct1 <- fmt(m1, "M1: + cancer (code status NOT in model)", "cancerYes")

# --- M2: cancer effect WITH code status ------------------------------------
m2 <- glm(died_hosp ~ lp + cancer + cs, data = d, family = binomial)
ct2 <- fmt(m2, "M2: + cancer + code status  <-- PRIMARY",
           c("cancerYes","cs0_undocumented","cs2_dnr","cs3_partial","cs4_comfort"))

# --- M3: interaction -------------------------------------------------------
m3 <- glm(died_hosp ~ lp + cancer * any_lim, data = d, family = binomial)
ct3 <- fmt(m3, "M3: cancer x any limitation",
           c("cancerYes","any_limYes","cancerYes:any_limYes"))

# --- the headline: attenuation of the cancer coefficient -------------------
b1 <- ct1["cancerYes", 1]; b2 <- ct2["cancerYes", 1]
cat("\n==========================================================\n")
cat(" ATTENUATION OF THE CANCER COEFFICIENT\n")
cat("==========================================================\n")
cat(sprintf("  without code status : OR %.3f (p %s)\n", exp(b1),
            ifelse(ct1["cancerYes",4] < 1e-4, "<0.0001", sprintf("%.4f", ct1["cancerYes",4]))))
cat(sprintf("  with code status    : OR %.3f (p %s)\n", exp(b2),
            ifelse(ct2["cancerYes",4] < 1e-4, "<0.0001", sprintf("%.4f", ct2["cancerYes",4]))))
cat(sprintf("  attenuation on log-odds scale: %.1f%%\n", 100 * (b1 - b2) / b1))

cat("\n--- likelihood ratio tests ---\n")
print(anova(m0, m1, m2, test = "LRT"))

saveRDS(list(m0=m0, m1=m1, m2=m2, m3=m3), file.path(proj, "results", "models.rds"))
cat("\nsaved results/models.rds\n")
