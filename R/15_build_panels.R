# ---------------------------------------------------------------------------
# 15_build_panels.R
#
# Consolidates eight single figures into four multi panel figures.
#
#   Figure 1  study flow
#   Figure 2  model performance      A calibration   B adjusted odds ratios
#   Figure 3  between unit variation A limitation rate  B covariate balance
#   Figure 4  benchmarking impact    A rank shift    B funnel before and after
#
# Palette mako [0.05,0.70], validated against a white print surface.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({
  library(data.table); library(ggplot2); library(patchwork)
  library(sandwich); library(lmtest); library(cobalt); library(WeightIt)
})

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"
sub  <- file.path(proj, "submission")
PAL  <- c("Full therapy"="#00B6B3","DNR type"="#007AA5",
          "Partial withdrawal"="#433864","Comfort measures"="#200F1D")
INK <- "#0b0b0b"; MUTED <- "#898781"; GRID <- "#e1e0d9"; ACC <- "#C81560"

FONT <- "serif"   # journal typography, per standing preference

th <- function(base = 11) theme_minimal(base_size = base, base_family = FONT) +
  theme(text = element_text(family = FONT),
        panel.grid.minor = element_blank(),
        panel.grid.major = element_line(color = GRID, linewidth = .25),
        axis.text = element_text(color = MUTED, size = base - 1, family = FONT),
        axis.title = element_text(color = INK, size = base, family = FONT),
        legend.text = element_text(color = INK, size = base - 1, family = FONT),
        legend.title = element_text(color = INK, size = base, family = FONT),
        strip.text = element_text(color = INK, size = base, face = "bold",
                                  family = FONT),
        legend.position = "bottom", legend.key.height = unit(.32, "cm"))

tif <- function(p, name, w, h) {
  # TIFF for journal submission
  f <- file.path(sub, "figures", paste0(name, ".tiff"))
  ggsave(f, p, device = "tiff", width = w, height = h, units = "in",
         dpi = 600, compression = "lzw", bg = "white")
  # vector PDF for the LaTeX build, since pdflatex cannot read TIFF
  d <- file.path(sub, "figures_pdf")
  dir.create(d, showWarnings = FALSE)
  g <- file.path(d, paste0(name, ".pdf"))
  ggsave(g, p, device = cairo_pdf, width = w, height = h, units = "in",
         bg = "white")
  cat(sprintf("  %-34s %5.1f MB tiff | %4.0f KB pdf\n",
              basename(f), file.size(f)/1e6, file.size(g)/1024))
}

d <- readRDS(file.path(proj, "data_private", "analytic.rds"))
d[, pred := pmin(pmax(pred_hosp_mort, 1e-6), 1 - 1e-6)]
d[, lp := qlogis(pred)]
d[, cs := relevel(factor(lim_tier_24h), ref = "1")]
d[, cs_lab := factor(fifelse(lim_tier_24h==0,"Undocumented",
                     fifelse(lim_tier_24h==1,"Full therapy",
                     fifelse(lim_tier_24h==2,"DNR type",
                     fifelse(lim_tier_24h==3,"Partial withdrawal","Comfort measures")))),
                levels = c("Full therapy","DNR type","Partial withdrawal",
                           "Comfort measures","Undocumented"))]
h <- fread(file.path(proj, "results", "hospital_reranking.csv"))
cat("building panels\n")

# =========================== FIGURE 1 =======================================
st <- data.table(lab = c("eICU-CRD v2.0 unit stays\n200,859",
                         "APACHE IVa result linked to\npredictor table\n136,236",
                         "Hospitals represented\n190",
                         "Hospitals with 100 or more stays\n162 (135,325 stays)"),
                 y = 4:1)
f1 <- ggplot(st, aes(1, y)) +
  geom_tile(fill = "white", color = INK, linewidth = .3, width = .92, height = .66) +
  geom_text(aes(label = lab), size = 3.4, color = INK, lineheight = 1.05,
            family = FONT) +
  geom_segment(data = data.frame(y = c(3.67,2.67,1.67)),
               aes(x=1,xend=1,y=y,yend=y-.34), color = INK, linewidth = .3,
               arrow = arrow(length = unit(.13,"cm")), inherit.aes = FALSE) +
  coord_cartesian(xlim=c(.5,1.5), ylim=c(.5,4.5)) +
  theme_void(base_family = FONT)
tif(f1, "FigureS1_flow", 5.2, 6.4)

# =========================== FIGURE 2 =======================================
pd <- d[cs_lab != "Undocumented"]
pd[, bin := cut(pred, quantile(pred, seq(0,1,.05), na.rm=TRUE),
                include.lowest=TRUE, labels=FALSE), by = cs_lab]
cv <- pd[, .(x=mean(pred), y=mean(died_hosp), n=.N), by=.(cs_lab,bin)][n>=20]
f2a <- ggplot(cv, aes(x,y,color=cs_lab)) +
  geom_abline(slope=1,intercept=0,linetype=2,color=MUTED,linewidth=.3) +
  geom_line(stat="smooth", method="loess", span=1, se=FALSE, linewidth=.7) +
  geom_point(size=1.7) +
  scale_color_manual("Code status within 24 hours", values=PAL) +
  scale_x_continuous("APACHE IVa predicted mortality", labels=scales::percent) +
  scale_y_continuous("Observed mortality", labels=scales::percent) +
  guides(color = guide_legend(nrow=2, title.position="top")) + th()

m <- glm(died_hosp ~ lp + cs + factor(cancer_apache), data=d, family=binomial)
ct <- coeftest(m, vcov.=vcovCL(m, cluster=d$hospitalid))
pick <- c("cs0"="No code status documented","cs2"="Do not resuscitate type",
          "cs3"="Partial withdrawal","cs4"="Comfort measures only",
          "factor(cancer_apache)1"="Metastatic or hematologic cancer")
fp <- rbindlist(lapply(names(pick), function(k) data.table(
  term=pick[[k]], or=exp(ct[k,1]),
  lo=exp(ct[k,1]-1.96*ct[k,2]), hi=exp(ct[k,1]+1.96*ct[k,2]))))
fp[, term := factor(term, levels=rev(unlist(pick)))]
fp[, lab := sprintf("%.2f (%.2f-%.2f)", or, lo, hi)]
f2b <- ggplot(fp, aes(or, term)) +
  geom_vline(xintercept=1, color=INK, linewidth=.3) +
  geom_errorbar(aes(xmin=lo,xmax=hi), width=.14, color=PAL[2], linewidth=.5,
                orientation="y") +
  geom_point(size=2.6, color=PAL[2]) +
  geom_text(aes(x=30,label=lab), hjust=0, size=3.0, color=INK, family=FONT) +
  scale_x_log10("Adjusted odds ratio for in hospital death",
                breaks=c(1,2,5,10,20), limits=c(.85,150)) +
  labs(y=NULL) + th() +
  theme(panel.grid.major.y=element_blank(),
        axis.text.y=element_text(color=INK, size=10, family=FONT))

f2 <- (f2a | f2b) + plot_layout(widths=c(1,1.25)) +
  plot_annotation(tag_levels="A") &
  theme(plot.tag = element_text(face="bold", size=13, family=FONT))
tif(f2, "Figure1_model_performance", 9.5, 5.6)

# =========================== FIGURE 3 =======================================
f3a <- ggplot(h, aes(reorder(factor(hospitalid), lim_rate), lim_rate)) +
  geom_col(fill=PAL[2], width=.85) +
  scale_y_continuous("Treatment limitation rate within 24 hours",
                     labels=scales::percent, expand=expansion(c(0,.05))) +
  labs(x="Intensive care unit, ordered by limitation rate") + th() +
  theme(axis.text.x=element_blank(), panel.grid.major.x=element_blank())

hr <- d[, .(n=.N, lim_rate=mean(lim_tier_24h>=2)), by=hospitalid][n>=100]
hr[, q := cut(lim_rate, quantile(lim_rate, seq(0,1,.2)), include.lowest=TRUE,
              labels=paste0("Q",1:5))]
x <- merge(d, hr[, .(hospitalid,q)], by="hospitalid")[q %in% c("Q1","Q5")]
x[, `:=`(high_lim=as.integer(q=="Q5"),
         Age=as.numeric(fifelse(is.na(age_num),91L,age_num)),
         Female=as.integer(gender=="Female"),
         from_ed=as.integer(unitadmitsource=="Emergency Department"))]
x <- x[!is.na(from_ed)]
cv2 <- x[, .(Age, Female, `APACHE IVa score`=as.numeric(apachescore),
             `Acute physiology score`=as.numeric(acutephysiologyscore),
             `Predicted mortality`=pred,
             `Metastatic or hematologic cancer`=as.numeric(cancer_apache),
             Immunosuppression=as.numeric(immunosuppression==1),
             Cirrhosis=as.numeric(cirrhosis==1),
             `Hepatic failure`=as.numeric(hepaticfailure==1),
             Diabetes=as.numeric(diabetes==1),
             `Ventilated on day 1`=as.numeric(ventday1==1),
             `From emergency department`=from_ed)]
W <- weightit(high_lim ~ ., data=cbind(high_lim=x$high_lim, cv2),
              method="glm", estimand="ATE")
f3b <- love.plot(W, stats="mean.diffs", binary="std", abs=FALSE,
                 thresholds=c(m=.1), var.order="unadjusted", drop.distance=TRUE,
                 line=TRUE, colors=c(ACC, PAL[2]),
                 shapes=c("triangle filled","circle filled"), size=2.9,
                 sample.names=c("Unweighted","Weighted"), title=NULL,
                 themes=theme_minimal(base_size=9, base_family=FONT)) +
  labs(x="Standardized mean difference", y=NULL) +
  th() + theme(panel.grid.major.y=element_blank(),
               axis.text.y=element_text(color=INK, size=10, family=FONT),
               legend.title=element_blank())

f3 <- (f3a | f3b) + plot_layout(widths=c(1,1.15)) +
  plot_annotation(tag_levels="A") &
  theme(plot.tag=element_text(face="bold", size=13, family=FONT))
tif(f3, "Figure2_unit_variation", 9.5, 5.6)

# =========================== FIGURE 4 =======================================
f4a <- ggplot(h, aes(lim_rate, rank_shift)) +
  geom_hline(yintercept=0, color=MUTED, linewidth=.3) +
  geom_point(aes(size=n), alpha=.55, color=PAL[2]) +
  geom_smooth(method="lm", se=TRUE, color=ACC, fill=ACC, alpha=.12, linewidth=.7) +
  scale_x_continuous("Treatment limitation rate within 24 hours", labels=scales::percent) +
  scale_y_continuous("Change in rank when limitation is modeled") +
  scale_size_continuous("ICU stays", range=c(1,5)) + th()

fun <- rbind(data.table(e=h$eA, smr=h$smrA, panel="Current practice"),
             data.table(e=h$eB, smr=h$smrB, panel="Limitation modeled"))
fun[, panel := factor(panel, levels=c("Current practice","Limitation modeled"))]
g <- data.table(e=seq(max(1,min(fun$e)), max(fun$e), length.out=400))
lm_ <- rbind(g[, .(e, y=qchisq(.025,2*e)/2/e, band="95%")],
             g[, .(e, y=qchisq(.975,2*(e+1))/2/e, band="95%")],
             g[, .(e, y=qchisq(.001,2*e)/2/e, band="99.8%")],
             g[, .(e, y=qchisq(.999,2*(e+1))/2/e, band="99.8%")])
lm_[, grp := paste(band, y>1)]
lm_ <- rbind(copy(lm_)[, panel:="Current practice"],
             copy(lm_)[, panel:="Limitation modeled"])
lm_[, panel := factor(panel, levels=c("Current practice","Limitation modeled"))]
f4b <- ggplot() +
  geom_line(data=lm_, aes(e,y,group=grp,linetype=band), color=MUTED, linewidth=.3) +
  geom_hline(yintercept=1, color=INK, linewidth=.3) +
  geom_point(data=fun, aes(e,smr), alpha=.5, color=PAL[2], size=1.5) +
  facet_wrap(~panel) + coord_cartesian(ylim=c(0,2.2)) +
  scale_x_continuous("Expected deaths") +
  scale_y_continuous("Standardized mortality ratio") +
  scale_linetype_manual("Control limits", values=c("95%"=2,"99.8%"=3)) + th()

f4 <- (f4a | f4b) + plot_layout(widths=c(1,1.5)) +
  plot_annotation(tag_levels="A") &
  theme(plot.tag=element_text(face="bold", size=13, family=FONT))
tif(f4, "Figure3_benchmarking", 9.5, 5.4)

# remove superseded singles
old <- file.path(sub, "figures",
  paste0(c("Figure2_calibration","Figure3_variation","Figure4_rankshift",
           "Figure5_funnel","Figure6_balance","Figure7_forest",
           "Figure8_quartile_movement"), ".tiff"))
old <- old[file.exists(old)]
if (length(old)) invisible(file.remove(old))
cat("\nfinal figure set\n")
for (f in list.files(file.path(sub,"figures"))) cat("  ", f, "\n")
