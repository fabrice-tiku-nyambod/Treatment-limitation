# ---------------------------------------------------------------------------
# 47_cja_3000_words.R
#
# Shortens the manuscript to the Canadian Journal of Anesthesia limits for a
# Report of Original Investigation (body 3,000 words, abstract 250 words with
# Purpose, Methods, Results, Conclusion; 2011 CJA Guide for Authors).
#
# Reads the hand edited Manuscript.docx (never written to) and writes
#   Manuscript_CJA_3000.docx           shortened manuscript, formatting kept
#   Appendix_S1_extended_methods.docx  the full original Methods and timing
#                                      Results, verbatim, for the supplement
#
# The central claim is kept intact: APACHE IVa calibration failed in proportion
# to documented limitation, unit variation in limitation was not explained by
# case mix, accounting for it moved one unit in four across ranking quartiles,
# and each finding held for orders written within 4 hours of admission.
# Every reference 1 to 48 is still cited and first cited in the same order, so
# the reference list and its numbering are unchanged.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(xml2); library(officer) })

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
src  <- file.path(sub, "Manuscript.docx")
out  <- file.path(sub, "Manuscript_CJA_3000.docx")
app  <- file.path(sub, "Appendix_S1_extended_methods.docx")

# ---- new text ---------------------------------------------------------------
# "h" = unnumbered subheading, "p" = body paragraph

implication <- paste(
  "Intensive care mortality benchmarks do not account for treatment limitation.",
  "In 190 US units, documented limitation varied severalfold for reasons case mix did not explain",
  "and moved one unit in four across ranking quartiles, so standardized mortality ratios may partly measure end of life practice.")

abstract <- list(
  c("Purpose.", paste(
    "Intensive care units are ranked by standardized mortality ratios from severity scores that contain no term for treatment limitation.",
    "We assessed whether APACHE IVa calibration depends on documented limitation, whether unit variation reflects case mix or practice, and whether rankings change when limitation is counted.")),
  c("Methods.", paste(
    "Retrospective cohort study of 136,236 adult admissions to 190 US intensive care units in the eICU Collaborative Research Database (2014-2015).",
    "The most restrictive limitation within 24 hours and its timing were classified from full therapy to comfort measures only.",
    "Units in the highest and lowest limitation quintiles were compared before and after inverse probability weighting on 12 characteristics.",
    "Units were ranked by standardized mortality ratio with and without limitation in the model.")),
  c("Results.", paste(
    "Limitation was documented in 9.9% of admissions.",
    "The standardized mortality ratio was 0.62 (95% CI, 0.60 to 0.63) under full therapy and 1.87 (1.73 to 2.02) under comfort measures, for orders within 4 hours (2.03) or later (1.84).",
    "The highest quintile documented limitation 3.58 times as often as the lowest before weighting and 2.89 times after.",
    "Modeling limitation changed quartile assignment for 23.5% of units and outlier status for 8.0%.",
    "Excluding comfort measures admissions, 0.6% of the cohort, reclassified 11.1% of units.")),
  c("Conclusion.", paste(
    "APACHE IVa calibration failed in proportion to documented treatment limitation, unit variation was not explained by measured case mix, and accounting for it moved one unit in four across ranking quartiles.",
    "Standardized mortality ratios may measure end of life practice alongside quality of care."))
)

intro <- list(
  c("p", paste(
    "End of life practice varies widely between intensive care units.",
    "Withdrawal of life sustaining treatment among patients who die ranges from 0 to 84% across published cohorts (1), with comparable variation across 199 units in 36 countries (2) and between regions and units within single countries (1, 3, 4).",
    "Two academic centers at opposite extremes of treatment intensity differed in decision making norms rather than in patients (5), and hospital level measures of end of life treatment intensity have been validated for this reason (6).",
    "Hart and colleagues studied 277,693 admissions to 141 US units and found the proportion admitted with existing treatment limitations ranged from under 1% to 20.9% after risk adjustment, variation that measurable center characteristics did not explain (7).")),
  c("p", paste(
    "Treatment limitation is common in critical illness, with do not resuscitate orders recorded in 13% of admissions to one tertiary unit (8) and in 36.6% of a medical intensive care cohort when orders for life sustaining treatment were included (9).",
    "Roughly a quarter of orders are written within 48 hours of admission (10).",
    "Mortality among patients with such orders is several times that of patients without them (9, 11), the association persists after propensity matching (12), and placing an order changes the intensity of subsequent care (13).",
    "The orders are not homogeneous.",
    "A limitation written at admission may record a preference expressed before critical illness or a prognosis evident on presentation.",
    "A limitation written after a period of full treatment may record the outcome of a time limited trial of intensive care (14), the arrival of a family member, or the communication practice of the clinician or unit, and may in part reflect the care delivered.")),
  c("p", paste(
    "Severity of illness scores estimate the probability of death under full treatment (15).",
    "The APACHE IVa model was derived from 110,558 admissions to 104 units, and its covariates describe first day physiology, age, comorbidity and admission diagnosis (16); SAPS 3 and the Simplified Acute Physiology Score share this structure (17, 18).",
    "No covariate in any of them represents a decision to withhold resuscitation, so an order not to resuscitate alters the probability of death without altering any variable the model observes.",
    "Calibration of these models deteriorates as practice changes and differs between populations, and it generally fails before discrimination does (19-21).")),
  c("p", paste(
    "Standardized mortality ratios derived from these scores are the standard measure in intensive care benchmarking.",
    "Units are ranked, and in some systems reimbursed, on the assumption that the ratio isolates quality of care once case mix is accounted for (22).",
    "The assumption is fragile: the choice of scoring system determines which units are labeled outliers (22, 23), admission patterns alter the measure (24), a statistically unexpected death is not the same as a preventable one (25), and model misspecification and modeling strategy change unit level estimates (26-28).",
    "Whether treatment limitation practice distorts these comparisons has been examined only by simulation (29) and through classification error rather than calibration (30).")),
  c("p", paste(
    "We examined 136,236 admissions to 190 US intensive care units.",
    "We asked whether APACHE IVa calibration depends on documented treatment limitation, whether between unit variation in limitation survives balancing of patient case mix, whether accounting for limitation changes how units are ranked, and whether each answer holds when only orders written at or near admission are counted."))
)

methods <- list(
  c("h", "Study design and data source"),
  c("p", paste(
    "This was a retrospective cohort study reported according to the STROBE recommendations (31) and, for the assessment of APACHE IVa, the TRIPOD recommendations (32, 33).",
    "Appendix S1 gives full methodological detail.",
    "We analyzed the eICU Collaborative Research Database version 2.0, which contains 200,859 unit stays at 208 US hospitals, from small community hospitals to large academic centers, participating in a tele critical care program in 2014 and 2015 (34, 35).",
    "The database is deidentified and its release was exempt from institutional review board approval (34).",
    "It was accessed under a data use agreement, and institutional review board approval was not required for this analysis.")),
  c("h", "Cohort"),
  c("p", paste(
    "Of 200,859 adult unit stays, 52,327 had no APACHE IVa result, partly because the scoring rules exclude readmissions, admissions from another unit, burns and stays shorter than 4 hours (16), and 12,296 had no usable predicted mortality, leaving 136,236 stays at 190 units (Figure S1).",
    "Unit level analyses were restricted to the 162 units contributing 100 or more stays (135,325 admissions).",
    "The unit of analysis was the unit stay, with standard errors clustered on unit.")),
  c("h", "Exposure and timing"),
  c("p", paste(
    "Treatment limitation was taken from structured care plan documentation, which records a care limitation value with a time stamp.",
    "For each stay we recorded the most restrictive value documented within 24 hours of admission, the period over which APACHE IVa collects its physiological inputs (10, 16).",
    "Full therapy formed the reference.",
    "Resuscitation limitation comprised do not resuscitate, no cardiopulmonary resuscitation, no intubation and no cardioversion; partial withdrawal comprised no vasopressors or inotropes, no augmentation of care, no blood products and no blood draws; comfort measures only was the most restrictive category.",
    "Stays with no entry were reported but not interpreted.")),
  c("p", paste(
    "Each limited stay was classified by the time of the first order at its most restrictive tier as early, within 4 hours of admission including orders documented before admission, or late, between 4 and 24 hours.",
    "Four hours falls within admission assessment and precedes any sustained trial of treatment; 1 hour was examined as a stricter cut.",
    "A record based definition identified orders preceded by a full therapy entry, which marks de-escalation after an initial decision to treat.",
    "The timing analyses were added after the primary analyses were complete and were not prespecified.")),
  c("h", "Outcome and statistical analysis"),
  c("p", paste(
    "The outcome was in hospital mortality, compared with APACHE IVa predicted hospital mortality.",
    "Calibration was assessed by logistic recalibration of observed mortality on the logit of predicted mortality and, within strata, by the standardized mortality ratio with exact Poisson 95% confidence intervals and the integrated calibration index (36, 37).",
    "The independent contribution of limitation status was estimated by adding it to a recalibration model containing the APACHE linear predictor, with malignancy, an established source of miscalibration, as a comparator (38).",
    "Discrimination was assessed on a random 30% holdout by the area under the receiver operating characteristic curve and the Brier score.")),
  c("p", paste(
    "To distinguish practice from case mix we compared units in the highest and lowest quintiles of limitation rate before and after inverse probability of treatment weighting of 12 patient characteristics (Appendix S1), with balance assessed against a standardized mean difference of 0.1 (39).",
    "If case mix accounted for the difference, balancing case mix should remove it.",
    "Between unit variation was also summarized by the intraclass correlation coefficient and the median odds ratio from mixed effects models with a unit random intercept (40, 41).")),
  c("p", paste(
    "To quantify the benchmarking consequence, expected deaths per unit were computed from a recalibrated APACHE IVa model with and without limitation status.",
    "Units were ranked by standardized mortality ratio under each and compared on rank shift, quartile change and outlier status against exact Poisson limits (42).",
    "We also evaluated excluding comfort measures admissions and excluding all admissions with any limitation, refitting the model on the retained cohort.",
    "Each analysis was repeated by timing of the order, including a ranking that counted only early orders with late orders recoded to full therapy.",
    "Age, censored above 89 years, was set to 91; no imputation was performed.",
    "Analyses used R version 4.6 with the data.table, lme4, sandwich, WeightIt and cobalt packages."))
)

results <- list(
  c("h", "Cohort"),
  c("p", paste(
    "Among 136,236 admissions, mean APACHE IVa predicted mortality was 11.8% against observed mortality of 8.85%, an overall standardized mortality ratio of 0.75.",
    "Code status was documented within 24 hours in 96.1% of admissions.",
    "A limitation was present in 13,496 admissions (9.9%): a resuscitation limitation in 11,929 (8.8%), partial withdrawal in 689 (0.5%) and comfort measures only in 878 (0.6%).",
    "Patients with any limitation were older and more severely ill (Table 1).")),
  c("h", "APACHE IVa calibration depends on treatment limitation"),
  c("p", paste(
    "The overall calibration slope was 1.005 with an intercept of negative 0.425; the model discriminated well but over predicted death across the entire risk range.",
    "Calibration differed sharply by limitation status (Table 2, Figure 1A).",
    "The standardized mortality ratio was 0.62 (95% CI, 0.60-0.63) under full therapy, 1.17 with resuscitation limitation, 1.22 with partial withdrawal and 1.87 (1.73-2.02) under comfort measures only.",
    "The integrated calibration index was 0.34 under comfort measures against 0.04 to 0.05 in the other strata.")),
  c("p", paste(
    "Relative to full therapy, the adjusted odds of death were 2.63 with resuscitation limitation, 2.97 with partial withdrawal and 15.30 under comfort measures only, against 1.15 for malignancy (Figure 1B).",
    "Adding limitation status reduced model deviance by 3.6% against 0.0% for malignancy.",
    "On held out data it improved the area under the curve from 0.866 to 0.876 (DeLong P < .001) and reduced the Brier score from 0.062 to 0.058 (Table S1).")),
  c("h", "Variation between units is not explained by case mix"),
  c("p", paste(
    "Across 162 units, limitation rates ranged from 0 to 27.5% with a median of 10.5% (Figure 2A).",
    "Before weighting, units in the highest limitation quintile differed from those in the lowest on two of 13 measured characteristics, age (standardized mean difference 0.197) and admission from the emergency department (0.149), while severity was near identical (negative 0.006 for the APACHE IVa score).",
    "After weighting all 12 covariates balanced within the 0.1 threshold (Figure 2B).",
    "Despite this balance, the highest quintile documented limitation in 16.5% of admissions against 5.7% in the lowest, a ratio of 2.89, against 3.58 unweighted.",
    "Approximately four fifths of the difference in practice survived balancing of patient case mix.",
    "In mixed effects models the median odds ratio rose from 1.69 to 1.80 after adjustment for case mix.")),
  c("h", "Consequences for benchmarking"),
  c("p", paste(
    "Adding limitation status preserved the overall ordering of units (Spearman correlation 0.949) while moving individual units substantially, with a median absolute rank shift of 7.5 positions of 162 (Table S2).",
    "Thirty eight units (23.5%) changed quartile and 13 (8.0%) changed outlier classification; four units flagged as high mortality became unremarkable and three unremarkable units became outliers (Figure 3B).",
    "Movement was systematic: the signed rank shift correlated with a unit's limitation rate at a Spearman coefficient of negative 0.689 (Figure 3A).",
    "Units in the lowest limitation quintile moved from a standardized mortality ratio of 0.984 to 1.027 and those in the highest from 1.013 to 0.876.")),
  c("p", paste(
    "Excluding the 878 admissions under comfort measures orders, 0.6% of the cohort, reclassified 18 units (11.1%) across quartiles, roughly half the effect of full adjustment, and excluding all 13,496 admissions with any limitation reclassified 46 units (28.4%) (Table 3).")),
  c("h", "Timing of limitation orders"),
  c("p", paste(
    "Comfort measures orders were documented a median of 666 minutes after unit admission (interquartile range 288 to 1052), with 21.3% within 4 hours, and resuscitation limitations at a median of 120 minutes (Figure S2A).",
    "A full therapy entry preceded 62.3% of comfort measures orders.",
    "Calibration failed at both timings (Table S6, Figure S2B).",
    "Among comfort measures admissions the standardized mortality ratio was 2.03 (95% CI, 1.69-2.43) for early and 1.84 (1.69-2.00) for late orders, and the adjusted odds of death, 12.90 and 16.25, did not differ (P = .28).",
    "Results were similar with a 1 hour cut and by whether a full therapy entry preceded the order (Appendix S1).",
    "For resuscitation limitation, late orders carried higher adjusted odds than early ones (3.25 against 2.31, P < .001).")),
  c("p", paste(
    "Between unit variation was larger for early orders.",
    "After weighting, units in the highest limitation quintile documented early limitation 3.53 times as often as those in the lowest (4.48 before weighting), against 2.20 for late orders.",
    "Counting only early orders, with later orders treated as full therapy, changed quartile assignment for 16 units (9.9%) and outlier classification for 6 (3.7%), and rank shift correlated with a unit's early limitation rate at a Spearman coefficient of negative 0.698 (Table S7)."))
)

discussion <- list(
  c("p", paste(
    "This retrospective cohort study of 136,236 admissions to 190 US intensive care units found that APACHE IVa calibration depended on a decision the model does not observe.",
    "The standardized mortality ratio was 0.62 among patients receiving full therapy and 1.87 among patients under comfort measures.",
    "Documentation of limitation varied severalfold between units, patient case mix did not account for the variation, and accounting for limitation moved one unit in four across quartiles of the ranking.",
    "Each finding held when only orders written within 4 hours of admission were counted, and the between unit variation was largest for those early orders.")),
  c("h", "Timing of the order"),
  c("p", paste(
    "A comfort measures order within 24 hours may be written at admission or after a full initial effort, and most in this cohort followed a documented decision to treat fully.",
    "The heterogeneity did not change the answers to the questions the study asked.",
    "The model was equally uninformative for early and late comfort measures orders, as would be expected if the order records a decision rather than a physiological state, since the decision changes what is done regardless of when it is made (13).",
    "Later resuscitation limitations were associated with higher mortality than earlier ones, possibly because they more often follow deterioration that the score captures only in part.",
    "Counting only early orders, the most conservative check against adjusting for a consequence of care, reduced the benchmarking effect by roughly half but did not remove it.",
    "Early orders are the least able to reflect care delivered in the unit, and the practice difference between units was largest for them, which suggests that the variation reflects how units approach goals of care at admission rather than how their patients fare during the first day.")),
  c("h", "Practice or case mix"),
  c("p", paste(
    "These results extend Hart and colleagues, who reported comparable variation after regression adjustment in a different database a decade earlier (7).",
    "Our design equalized the covariate distributions rather than adjusting for them (39).",
    "Limitation rates were higher in our cohort, 10.5% against 4.0%, consistent with the expansion of palliative care services.",
    "Service configuration offers a plausible mechanism: early palliative care consultation more than doubled transition to limitation orders in randomized comparison (43), and integration of palliative care into critical care alters process and outcome measures (44, 45).",
    "The eICU database carries no information on palliative care staffing or goals of care protocols, so the mechanism remains a hypothesis consistent with our data rather than a finding from it.")),
  c("h", "Consequences for benchmarking"),
  c("p", paste(
    "Kramer and colleagues found that substituting an entirely different risk model changed the direction and significance of the standardized mortality ratio in 55% of units (23).",
    "In this study a single variable already recorded in 96% of charts moved a quarter of quartile assignments.",
    "Whether to adjust for limitation status is an open question that this study does not resolve.",
    "Adjustment treats limitation as patient preference and therefore as case mix; withholding adjustment treats it as modifiable unit behavior.",
    "An order written after an initial trial of treatment may in part be a product of that treatment, and adjusting for it risks crediting a unit for outcomes its own care produced.",
    "The same dilemma has been described for social risk factors (46), and misspecification of the adjustment model is itself a recognized source of bias (26).",
    "The choice is currently made by default, and it changed the rank of one unit in four.")),
  c("p", paste(
    "Code status is a routine element of the admission record but enters neither the APACHE IVa model nor its exclusion rules.",
    "Benchmarking programs already exclude categories of patients, and the National Quality Forum model excludes 27.9% of admissions against 10.6% for APACHE IVa (23).",
    "Options include excluding comfort measures orders written at admission, which affects one or two patients in a thousand and still reclassified 3.7% of units; excluding all comfort measures admissions, six in a thousand, which recovered half the effect; or reporting limitation rates alongside standardized mortality ratios.",
    "None of these requires new data collection.",
    "SAPS 3 and the Simplified Acute Physiology Score share the same structure (17, 18) and may behave similarly, although this was not tested.")),
  c("h", "Limitations"),
  c("p", paste(
    "This study has limitations.",
    "We observed documentation and not practice; code status documentation in electronic records is frequently incomplete or contradictory (47), and delays in charting may misclassify some early orders as late.",
    "The data describe 2014 and 2015 and derive from units in a single tele critical care program (34).",
    "Limitation status is partly a consequence of prognosis, a dependency shown to bias mortality based estimates in trauma (48), so no causal interpretation is available, and the timing analyses bound rather than eliminate the hazard of mediator adjustment.",
    "These analyses were not prespecified and should be read as exploratory.",
    "Weighting balanced measured characteristics only (39), and cancer ascertainment relied on APACHE comorbidity flags (38).",
    "The code and extraction queries are public."))
)

conclusion <- list(
  c("p", paste(
    "In 190 US intensive care units, APACHE IVa calibration failed in proportion to documented treatment limitation, units differed severalfold in documenting limitation for reasons measured case mix did not explain, and accounting for limitation moved one unit in four across quartiles of the ranking, or one in ten counting early orders alone.",
    "Risk adjusted mortality benchmarking may therefore measure end of life practice alongside quality of care.",
    "Excluding admissions under comfort measures orders requires no new data and recovers half the effect, and reporting unit limitation rates alongside the ratio would make the remainder visible."))
)

# ---- word counts -----------------------------------------------------------
wc <- function(s) length(strsplit(trimws(s), "[[:space:]]+")[[1]])
body_wc <- sum(vapply(c(intro, methods, results, discussion, conclusion),
                      function(x) if (x[1] == "p") wc(x[2]) else 0, 0))
abs_wc  <- sum(vapply(abstract, function(x) wc(paste(x, collapse = " ")), 0))
imp_wc  <- wc(implication)

# ---- check citation order is unchanged -------------------------------------
all_text <- paste(vapply(c(intro, methods, results, discussion, conclusion), `[`, "", 2), collapse = " ")
cites <- regmatches(all_text, gregexpr("\\(([0-9]+(-[0-9]+)?(, [0-9]+(-[0-9]+)?)*)\\)", all_text))[[1]]
nums <- unlist(lapply(cites, function(ci) {
  parts <- strsplit(gsub("[()]", "", ci), ", ")[[1]]
  unlist(lapply(parts, function(p) { r <- as.integer(strsplit(p, "-")[[1]]); if (length(r) == 2) r[1]:r[2] else r }))
}))
first <- unique(nums)
stopifnot("every reference 1-48 cited" = setequal(first, 1:48),
          "first citations in order"    = identical(first, 1:48))

# ---- rebuild document.xml --------------------------------------------------
tmp <- tempfile(); dir.create(tmp); unzip(src, exdir = tmp)
docxml <- file.path(tmp, "word", "document.xml")
doc <- read_xml(docxml); ns <- xml_ns(doc)
body <- xml_find_first(doc, "//w:body", ns)
ptext <- function(p) paste(xml_text(xml_find_all(p, ".//w:r/w:t", ns)), collapse = "")
paras <- function() xml_find_all(doc, "//w:body/w:p", ns)
find_p <- function(prefix) { ps <- paras(); ps[[which(startsWith(vapply(ps, ptext, ""), prefix))[1]]] }

set_text <- function(p, txt, run = 1) {
  t <- xml_find_all(p, ".//w:r/w:t", ns)[[run]]
  xml_text(t) <- txt; xml_set_attr(t, "xml:space", "preserve")
}

tpl_p <- find_p("End of life practice varies")            # plain justified body paragraph
tpl_h <- find_p("Study design and reporting")             # bold italic subheading
tpl_l <- find_p("Background.")                            # bold label + text
tpl_H <- find_p("Abstract")                               # section heading

replace_section <- function(heading, next_heading, blocks) {
  ps <- paras(); tx <- vapply(ps, ptext, "")
  s <- which(tx == heading); e <- which(tx == next_heading)
  # keep the paragraph holding the page break before the next heading
  between <- ps[(s + 1):(e - 2)]
  anchor <- ps[[s]]
  for (b in blocks) {
    node <- xml_add_sibling(anchor, if (b[1] == "h") tpl_h else tpl_p, .where = "after")
    set_text(node, b[2]); anchor <- node
  }
  for (p in between) xml_remove(p)
}

# the section templates are copied (inside the document, so the w namespace
# stays bound) before their sections are replaced, and removed at the end
tpl_p <- xml_add_child(body, tpl_p, .where = 0)
tpl_h <- xml_add_child(body, tpl_h, .where = 0)

replace_section("1. Introduction", "2. Methods", intro)
replace_section("2. Methods", "3. Results", methods)
replace_section("3. Results", "4. Discussion", results)
replace_section("4. Discussion", "5. Conclusion", discussion)
replace_section("5. Conclusion", "6. Statements and Declarations", conclusion)

# abstract: relabel and replace the four structured paragraphs
labels_old <- c("Background.", "Methods.", "Results.", "Conclusions.")
for (k in 1:4) {
  p <- find_p(labels_old[k])
  set_text(p, abstract[[k]][1], 1); set_text(p, paste0(" ", abstract[[k]][2]), 2)
}

# implication statement ahead of the abstract
abs_head <- find_p("Abstract")
ih <- xml_add_sibling(abs_head, tpl_H, .where = "before"); set_text(ih, "Implication statement")
ip <- xml_add_sibling(abs_head, tpl_p, .where = "before"); set_text(ip, implication)

# title page counts and article type
set_text(find_p("Article type."), "Reports of Original Investigation", 2)
set_text(find_p("Word count, abstract."), as.character(abs_wc), 2)
set_text(find_p("Word count, body."), format(body_wc, big.mark = ","), 2)
set_text(find_p("Supplementary material."), "Appendix S1, Figures S1 and S2, Tables S1 to S7, STROBE checklist", 2)

xml_remove(tpl_p); xml_remove(tpl_h)
write_xml(doc, docxml, options = "as_xml")
if (file.exists(out)) file.remove(out)
zip::zip(out, files = list.files(tmp, recursive = TRUE, all.files = TRUE), root = tmp)

# ---- Appendix S1: original Methods and timing Results, verbatim ------------
orig <- docx_summary(read_docx(src))
orig <- orig[orig$content_type == "paragraph" & nzchar(trimws(orig$text)), "text"]
grab <- function(from, to) orig[(which(orig == from)[1]):(which(orig == to)[1] - 1)]
meth <- grab("Study design and reporting", "3. Results")
meth <- meth[meth != "2. Methods"]
tim  <- grab("Timing of limitation orders", "4. Discussion")
tim  <- tim[seq(which(tim == "Timing of limitation orders")[2] %||% 1, length(tim))]
heads <- c("Study design and reporting", "Data source", "Cohort", "Exposure", "Timing of limitation orders",
           "Outcome", "Statistical analysis")

FONT <- "Times New Roman"
fp_b <- fp_text(font.family = FONT, font.size = 12)
fp_h <- fp_text(font.family = FONT, font.size = 12, bold = TRUE, italic = TRUE)
fp_t <- fp_text(font.family = FONT, font.size = 13, bold = TRUE)
pj <- fp_par(line_spacing = 1.5, text.align = "justify", padding.bottom = 6)
a <- read_docx() |>
  body_add_fpar(fpar(ftext("Appendix S1. Extended methods and timing results", fp_t), fp_p = pj)) |>
  body_add_fpar(fpar(ftext("Full text of the methods and of the timing results summarized in the main manuscript. Reference numbers refer to the main reference list.", fp_b), fp_p = pj)) |>
  body_add_fpar(fpar(ftext("Extended methods", fp_t), fp_p = pj))
for (s in meth) a <- body_add_fpar(a, fpar(ftext(s, if (s %in% heads) fp_h else fp_b), fp_p = pj))
a <- body_add_fpar(a, fpar(ftext("Extended timing results", fp_t), fp_p = pj))
for (s in tim[tim != "Timing of limitation orders"]) a <- body_add_fpar(a, fpar(ftext(s, fp_b), fp_p = pj))
a <- body_set_default_section(a, prop_section(page_size = page_size(orient = "portrait"),
                                              page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1)))
print(a, target = app)

cat(sprintf("wrote %s\n  body %d words, abstract %d words, implication statement %d words\nwrote %s\n",
            basename(out), body_wc, abs_wc, imp_wc, basename(app)))
