# ---------------------------------------------------------------------------
# 05_discrimination.R
# Tests the alternative framing: is code status a RECOVERABLE prognostic
# signal that adds predictive information beyond APACHE IVa?
#   - change in AUC
#   - change in Brier score
#   - calibration after recalibration with code status
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(pROC)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp := qlogis(pred)]
d[, cs := relevel(factor(lim_tier_24h), ref = "1")]
d[, cancer := factor(cancer_apache)]

set.seed(42)
idx   <- sample(nrow(d), floor(0.7 * nrow(d)))
train <- d[idx]; test <- d[-idx]
cat(sprintf("train %s / test %s\n\n", format(nrow(train), big.mark=","),
            format(nrow(test), big.mark=",")))

brier <- function(p, y) mean((p - y)^2)

# --- models ----------------------------------------------------------------
m_apache <- glm(died_hosp ~ lp,             data = train, family = binomial)
m_cancer <- glm(died_hosp ~ lp + cancer,    data = train, family = binomial)
m_cs     <- glm(died_hosp ~ lp + cs,        data = train, family = binomial)
m_both   <- glm(died_hosp ~ lp + cs + cancer, data = train, family = binomial)

mods <- list("APACHE IVa (raw)"        = NULL,
             "APACHE recalibrated"     = m_apache,
             "+ cancer"                = m_cancer,
             "+ code status"           = m_cs,
             "+ code status + cancer"  = m_both)

cat("=========================================================\n")
cat(" DISCRIMINATION AND ACCURACY (held-out 30%)\n")
cat("=========================================================\n")
res <- data.table()
for (nm in names(mods)) {
  p <- if (is.null(mods[[nm]])) test$pred else predict(mods[[nm]], test, type = "response")
  r <- roc(test$died_hosp, p, quiet = TRUE)
  res <- rbind(res, data.table(
    model = nm,
    AUC   = round(as.numeric(auc(r)), 4),
    AUC_lo = round(as.numeric(ci.auc(r))[1], 4),
    AUC_hi = round(as.numeric(ci.auc(r))[3], 4),
    Brier = round(brier(p, test$died_hosp), 5)))
}
print(res)

# --- formal test of added discrimination ----------------------------------
p_apache <- predict(m_apache, test, type = "response")
p_cs     <- predict(m_cs,     test, type = "response")
p_cancer <- predict(m_cancer, test, type = "response")

r_a <- roc(test$died_hosp, p_apache, quiet = TRUE)
r_c <- roc(test$died_hosp, p_cs,     quiet = TRUE)
r_k <- roc(test$died_hosp, p_cancer, quiet = TRUE)

cat("\n--- DeLong test: code status vs APACHE alone ---\n")
print(roc.test(r_a, r_c, method = "delong"))
cat("\n--- DeLong test: cancer vs APACHE alone ---\n")
print(roc.test(r_a, r_k, method = "delong"))

# --- how much of the deviance does each explain? --------------------------
cat("\n--- explained deviance (training) ---\n")
d0 <- m_apache$deviance
cat(sprintf("  APACHE alone            deviance %.0f\n", d0))
cat(sprintf("  + cancer                deviance %.0f  (reduction %.1f%%)\n",
            m_cancer$deviance, 100*(d0 - m_cancer$deviance)/d0))
cat(sprintf("  + code status           deviance %.0f  (reduction %.1f%%)\n",
            m_cs$deviance, 100*(d0 - m_cs$deviance)/d0))

# --- calibration before / after -------------------------------------------
cat("\n--- calibration intercept & slope on held-out data ---\n")
for (nm in c("APACHE IVa (raw)", "APACHE recalibrated", "+ code status")) {
  p <- if (nm == "APACHE IVa (raw)") test$pred else
       predict(mods[[nm]], test, type = "response")
  p <- pmin(pmax(p, 1e-6), 1 - 1e-6)
  cal <- glm(test$died_hosp ~ qlogis(p), family = binomial)
  cat(sprintf("  %-22s intercept %+.3f   slope %.3f\n",
              nm, coef(cal)[1], coef(cal)[2]))
}

fwrite(res, file.path(proj, "results", "table3_discrimination.csv"))
cat("\nsaved results/table3_discrimination.csv\n")
