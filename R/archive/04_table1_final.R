# ---------------------------------------------------------------------------
# 04_table1_final.R
# Table 1, with variables screened for usability first.
#   - electivesurgery is 80% missing in this cohort -> reported with denominator
#   - readmit is constant (all 0) -> dropped
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))
proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, grp := fifelse(cancer_apache == 1, "Cancer", "No cancer")]

t1 <- d[, .(
  n                 = .N,
  age_median        = as.numeric(median(age_num, na.rm = TRUE)),
  age_iqr           = paste0(quantile(age_num, .25, na.rm=TRUE), "-",
                             quantile(age_num, .75, na.rm=TRUE)),
  age_over89_pct    = round(100 * mean(age_over_89), 1),
  female_pct        = round(100 * mean(gender == "Female", na.rm = TRUE), 1),
  apache_median     = as.numeric(median(apachescore, na.rm = TRUE)),
  aps_median        = as.numeric(median(acutephysiologyscore, na.rm = TRUE)),
  pred_mort_mean    = round(100 * mean(pred), 2),
  observed_mort_pct = round(100 * mean(died_hosp), 2),
  smr               = round(sum(died_hosp) / sum(pred), 3),
  vent_day1_pct     = round(100 * mean(ventday1 == 1), 1),
  diabetes_pct      = round(100 * mean(diabetes == 1), 1),
  cirrhosis_pct     = round(100 * mean(cirrhosis == 1), 1),
  immunosupp_pct    = round(100 * mean(immunosuppression == 1, na.rm = TRUE), 1),
  metastatic_n      = sum(metastaticcancer == 1, na.rm = TRUE),
  leukemia_n        = sum(leukemia == 1, na.rm = TRUE),
  lymphoma_n        = sum(lymphoma == 1, na.rm = TRUE),
  cs_documented_pct = round(100 * mean(lim_tier_24h >= 1), 1),
  lim24_pct         = round(100 * mean(lim_tier_24h >= 2), 1),
  comfort24_pct     = round(100 * mean(lim_tier_24h == 4), 2),
  icu_los_median_h  = round(as.numeric(median(unitdischargeoffset, na.rm=TRUE))/60, 1)
), by = grp][order(grp)]

out <- data.table(variable = names(t1)[-1],
                  Cancer    = unlist(t1[grp == "Cancer",    -1], use.names = FALSE),
                  NoCancer  = unlist(t1[grp == "No cancer", -1], use.names = FALSE))
print(out)
fwrite(out, file.path(proj, "results", "table1_cohort.csv"))

cat("\n--- variables screened OUT ---\n")
cat(sprintf("  electivesurgery : %.1f%% missing - unusable\n",
            100*mean(is.na(d$electivesurgery))))
cat(sprintf("  readmit         : constant (all %s) - unusable\n",
            unique(d$readmit)[1]))

cat("\nsaved results/table1_cohort.csv\n")
