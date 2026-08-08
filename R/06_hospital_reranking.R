# ---------------------------------------------------------------------------
# 06_hospital_reranking.R
#
# THE DECISIVE TEST for the benchmarking claim.
#
# Rank hospitals by risk-adjusted mortality two ways:
#   A: expected deaths from APACHE IVa recalibrated        (current practice)
#   B: expected deaths from APACHE IVa + code status       (proposed)
# then measure how much the ranking moves.
#
# A null correlation between limitation rate and SMR does NOT imply stable
# rankings. Rank movement and change in outlier status are what actually
# matter to a hospital being benchmarked.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages(library(data.table))

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp := qlogis(pred)]
d[, cs := relevel(factor(lim_tier_24h), ref = "1")]

# --- two risk-adjustment models -------------------------------------------
mA <- glm(died_hosp ~ lp,      data = d, family = binomial)
mB <- glm(died_hosp ~ lp + cs, data = d, family = binomial)
d[, expA := predict(mA, type = "response")]
d[, expB := predict(mB, type = "response")]

# --- hospital-level SMRs ---------------------------------------------------
h <- d[, .(n   = .N,
           obs = sum(died_hosp),
           eA  = sum(expA),
           eB  = sum(expB),
           lim_rate = mean(lim_tier_24h >= 2)), by = hospitalid][n >= 100]
h[, `:=`(smrA = obs/eA, smrB = obs/eB)]
h[, `:=`(rankA = frank(smrA), rankB = frank(smrB))]
h[, `:=`(qA = cut(rankA, quantile(rankA, seq(0,1,.25)), include.lowest=TRUE, labels=1:4),
         qB = cut(rankB, quantile(rankB, seq(0,1,.25)), include.lowest=TRUE, labels=1:4))]
h[, rank_shift := rankB - rankA]

N <- nrow(h)
cat("=========================================================\n")
cat(sprintf(" HOSPITAL RE-RANKING  (n = %d hospitals, >=100 stays)\n", N))
cat("=========================================================\n\n")

cat(sprintf("Spearman correlation of SMRs   : %.4f\n",
            cor(h$smrA, h$smrB, method = "spearman")))
cat(sprintf("Spearman correlation of ranks  : %.4f\n",
            cor(h$rankA, h$rankB, method = "spearman")))
cat(sprintf("median |rank shift|            : %.1f positions\n",
            median(abs(h$rank_shift))))
cat(sprintf("max |rank shift|               : %.0f positions\n",
            max(abs(h$rank_shift))))
cat(sprintf("hospitals moving >10 positions : %d (%.1f%%)\n",
            sum(abs(h$rank_shift) > 10), 100*mean(abs(h$rank_shift) > 10)))
cat(sprintf("hospitals moving >20 positions : %d (%.1f%%)\n",
            sum(abs(h$rank_shift) > 20), 100*mean(abs(h$rank_shift) > 20)))

cat("\n--- QUARTILE MOVEMENT ---\n")
chg <- sum(h$qA != h$qB)
cat(sprintf("hospitals changing quartile    : %d of %d (%.1f%%)\n",
            chg, N, 100*chg/N))
print(table(Before = h$qA, After = h$qB))

# --- outlier status (funnel-plot style, exact Poisson CI) -----------------
h[, `:=`(loA = qchisq(.025, 2*obs)/2/eA, hiA = qchisq(.975, 2*(obs+1))/2/eA,
         loB = qchisq(.025, 2*obs)/2/eB, hiB = qchisq(.975, 2*(obs+1))/2/eB)]
h[, `:=`(flagA = fifelse(loA > 1, "high", fifelse(hiA < 1, "low", "as expected")),
         flagB = fifelse(loB > 1, "high", fifelse(hiB < 1, "low", "as expected")))]

cat("\n--- OUTLIER CLASSIFICATION (95% exact Poisson limits) ---\n")
print(table(Before = h$flagA, After = h$flagB))
recl <- sum(h$flagA != h$flagB)
cat(sprintf("\nhospitals RECLASSIFIED         : %d of %d (%.1f%%)\n",
            recl, N, 100*recl/N))
cat(sprintf("  flagged high before -> not after : %d\n",
            h[flagA=="high" & flagB!="high", .N]))
cat(sprintf("  not flagged high before -> after : %d\n",
            h[flagA!="high" & flagB=="high", .N]))

# --- who moves most? -------------------------------------------------------
cat("\n--- 10 largest rank shifts ---\n")
top <- h[order(-abs(rank_shift))][1:10,
        .(hospitalid, n, lim_rate = round(lim_rate,3),
          smrA = round(smrA,3), smrB = round(smrB,3),
          rankA = as.integer(rankA), rankB = as.integer(rankB),
          shift = as.integer(rank_shift))]
print(top)

cat(sprintf("\ncorrelation |rank shift| vs limitation rate: %.3f\n",
            cor(abs(h$rank_shift), h$lim_rate, method = "spearman")))

fwrite(h, file.path(proj, "results", "hospital_reranking.csv"))
cat("\nsaved results/hospital_reranking.csv\n")
