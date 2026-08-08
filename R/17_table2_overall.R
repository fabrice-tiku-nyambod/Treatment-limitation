# Recompute calibration by limitation status for the whole cohort.
# The earlier table2 was stratified by cancer as well, so its ICI values
# describe the non-cancer subgroup only and must not be quoted as overall.
suppressPackageStartupMessages(library(data.table))
proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, cs := factor(fifelse(lim_tier_24h==0,"Undocumented",
                 fifelse(lim_tier_24h==1,"Full therapy",
                 fifelse(lim_tier_24h==2,"DNR type",
                 fifelse(lim_tier_24h==3,"Partial withdrawal","Comfort measures")))),
            levels=c("Full therapy","DNR type","Partial withdrawal",
                     "Comfort measures","Undocumented"))]

ici <- function(p, y) {
  if (length(unique(y)) < 2 || length(y) < 50) return(c(NA, NA))
  f <- tryCatch(loess(y ~ p, degree = 1, span = .9), error = function(e) NULL)
  if (is.null(f)) return(c(NA, NA))
  s <- pmin(pmax(predict(f), 0), 1)
  c(mean(abs(s - p), na.rm = TRUE), max(abs(s - p), na.rm = TRUE))
}

res <- d[, { v <- ici(pred, died_hosp)
  .(n = .N,
    pred = round(100*mean(pred), 1),
    obs  = round(100*mean(died_hosp), 1),
    smr  = round(sum(died_hosp)/sum(pred), 2),
    ICI  = round(v[1], 3),
    Emax = round(v[2], 3)) }, by = cs][order(cs)]
print(res)
fwrite(res, file.path(proj, "results", "table2_calibration_overall.csv"))
cat("\nsaved results/table2_calibration_overall.csv\n")
