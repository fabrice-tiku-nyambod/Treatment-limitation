# ---------------------------------------------------------------------------
# 01_load_validate.R
# Load the analytic dataset and reproduce the descriptive figures obtained
# directly from BigQuery, as a check that the extraction is faithful.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- fread(file.path(proj, "data_private", "analytic.csv"))

cat("=== cohort ===\n")
cat(sprintf("unit stays            : %s\n", format(nrow(d), big.mark = ",")))
cat(sprintf("unique patients       : %s\n", format(uniqueN(d$patienthealthsystemstayid), big.mark = ",")))
cat(sprintf("hospitals             : %s\n", uniqueN(d$hospitalid)))
cat(sprintf("cancer (APACHE flags) : %s (%.1f%%)\n",
            format(sum(d$cancer_apache), big.mark = ","),
            100 * mean(d$cancer_apache)))
cat(sprintf("cancer (diagnosis txt): %s (%.1f%%)\n",
            format(sum(d$cancer_dx), big.mark = ","),
            100 * mean(d$cancer_dx)))
cat(sprintf("in-hospital deaths    : %s (%.2f%%)\n",
            format(sum(d$died_hosp), big.mark = ","),
            100 * mean(d$died_hosp)))
cat(sprintf("mean predicted        : %.4f\n", mean(d$pred_hosp_mort)))

cat("\n=== code status at 24h, by cancer ===\n")
tab <- d[, .N, by = .(cancer_apache, lim_tier_24h)][order(cancer_apache, lim_tier_24h)]
tab[, pct := round(100 * N / sum(N), 2), by = cancer_apache]
print(tab)

cat("\n=== limitation (tier >= 2) prevalence ===\n")
prev <- d[, .(n = .N,
              n_lim = sum(lim_tier_24h >= 2),
              pct   = round(100 * mean(lim_tier_24h >= 2), 2)),
          by = cancer_apache][order(cancer_apache)]
print(prev)
cat(sprintf("ratio cancer:non-cancer = %.2fx\n",
            prev[cancer_apache == 1, pct] / prev[cancer_apache == 0, pct]))

cat("\n=== SMR by tier and cancer (should match BigQuery) ===\n")
smr <- d[, .(n        = .N,
             pred     = round(mean(pred_hosp_mort), 4),
             obs      = round(mean(died_hosp), 4),
             smr      = round(sum(died_hosp) / sum(pred_hosp_mort), 3)),
         by = .(cancer_apache, lim_tier_24h)][order(cancer_apache, lim_tier_24h)]
print(smr)

cat("\n=== overall SMR ===\n")
ov <- d[, .(n = .N, smr = round(sum(died_hosp) / sum(pred_hosp_mort), 3)),
        by = cancer_apache][order(cancer_apache)]
print(ov)

cat("\n=== ascertainment concordance (APACHE flags vs diagnosis text) ===\n")
print(d[, table(APACHE = cancer_apache, Diagnosis = cancer_dx)])

cat("\n=== missingness on model variables ===\n")
vars <- c("pred_hosp_mort","died_hosp","lim_tier_24h","cancer_apache",
          "age_num","gender","apachescore","hospitalid")
for (v in vars) {
  cat(sprintf("  %-18s %d missing\n", v, sum(is.na(d[[v]]))))
}

saveRDS(d, file.path(proj, "data_private", "analytic.rds"))
cat("\nsaved analytic.rds\n")
