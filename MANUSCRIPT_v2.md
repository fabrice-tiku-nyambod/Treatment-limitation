# Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units

**Draft v2, 2026-08-06.** Target journal *Annals of the American Thoracic Society*.
Style follows Hart et al, *JAMA Intern Med* 2015. Short declarative sentences. One
claim per sentence. Citations carried by every assertion of fact.

---

## Introduction

End of life practice varies widely between intensive care units. Withdrawal of life
sustaining treatment among patients who die ranges from 0 to 84 percent across published
cohorts (31). The Ethicus-2 investigators found similar variation across 199 units in 36
countries (32). Hart and colleagues studied 277,693 admissions to 141 US units and found
that the proportion admitted with existing treatment limitations ranged from under 1
percent to 20.9 percent after risk adjustment (30). Measurable center characteristics did
not explain that variation (30). The authors concluded that unit culture and physician
practice style drive it (30).

Severity of illness scores estimate the probability of death under full treatment. The
APACHE IVa model was derived from 110,558 admissions to 104 units during 2002 and 2003
(1). Its covariates describe physiology, age, comorbidity and admission diagnosis (1). No
term represents a decision to withhold resuscitation. A do not resuscitate order changes
the probability of death without changing any variable the model observes.

Standardized mortality ratios derived from these scores are the accepted currency of
intensive care benchmarking (12). Units are compared, ranked and in some systems paid on
the basis of observed deaths divided by predicted deaths (12). The ratio is assumed to
isolate quality of care once case mix is accounted for (12). Kramer and colleagues showed
that this assumption is fragile. Comparing APACHE IVa against a National Quality Forum
model across 89,353 admissions, the two methods agreed on the direction and significance
of the standardized mortality ratio in only 45 percent of units (13).

Whether treatment limitation practice distorts these comparisons has not been tested.
Hart and colleagues hypothesized that advance care planning norms contribute to variation
in intensive care use, and demonstrated the mechanism by simulation (35). No study has
measured the consequence for risk adjusted mortality benchmarking using observed data.

We examined 136,236 admissions to 190 US intensive care units. We asked whether APACHE
IVa calibration depends on documented treatment limitation, and whether accounting for
limitation changes how units are ranked.

---

## Discussion

APACHE IVa calibration depends on a decision the model does not observe. The
standardized mortality ratio was 0.61 among patients receiving full therapy and 1.89
among patients under comfort measures. The integrated calibration index was 0.34 in the
comfort measures stratum and 0.04 elsewhere. In that group the model is not miscalibrated
but uninformative.

Documentation of limitation varied several fold between units and case mix did not
explain it. The intraclass correlation was 0.084 before adjustment and 0.104 after. The
median odds ratio rose from 1.69 to 1.80. Units differed 4.8 fold in adjusted limitation
propensity between the fifth and ninety fifth percentiles. These findings replicate Hart
and colleagues in a different database, a different decade and a different definition of
limitation (30). Limitation rates were higher in our cohort than in theirs, 10.5 percent
against 4.0 percent, which is consistent with the growth of palliative care services over
the intervening period (53).

The consequence for benchmarking is substantial. Accounting for limitation moved 23.5
percent of units across quartiles. It reversed outlier classification for 8.0 percent.
Four units previously flagged as high mortality became unremarkable and three previously
unremarkable units became outliers. Movement was systematic. The direction of change
correlated with a unit's limitation rate at rho of negative 0.689. Units in the lowest
quintile of limitation moved from a standardized mortality ratio of 0.984 to 1.027. Units
in the highest quintile moved from 1.013 to 0.876. Under current benchmarking these
quintiles appear equivalent. They are not.

Whether to adjust for limitation status is a genuine question and we do not resolve it.
Adjustment treats limitation as patient preference and therefore as case mix. Withholding
adjustment treats it as modifiable unit behavior. Both positions are defensible. Nerenz
and colleagues framed the same dilemma for social risk factors, where adjustment may mask
real differences in care while omission penalizes institutions serving different
populations (21). The parallel is exact. Our contribution is not to settle the question.
Our contribution is to show that the answer changes the rank of one unit in four, and
that the choice is currently made by default.

A simpler remedy exists. Excluding the 878 admissions under comfort measures orders, six
in every thousand, reclassified 11.1 percent of units. That is half the effect of full
adjustment at a fraction of the complexity. Benchmarking programs already exclude
categories of patient from severity scoring (13). Adding one more is feasible.

Our findings extend rather than contradict prior work. Feng and Dubin identified
variables associated with incorrect APACHE IVa predictions in this database and included
the frequency of care limitation change among them (47). They examined classification
error rather than calibration and did not consider benchmarking (47). They also reported
APACHE IVa predicting 11.96 percent mortality against 9.91 percent observed, which
corroborates the over prediction we describe (47). Glance and colleagues showed that the
choice of scoring system alters which units are labeled outliers (12). We show that a
single variable already recorded in 96 percent of charts does the same.

This study has limitations. We observed documentation and not practice. Units may limit
treatment without recording it, which would understate true variation. The data describe
2014 and 2015 and derive from units participating in a single tele critical care program
(46). Limitation status is partly a consequence of prognosis. Clinicians write these
orders because they expect death, so limitation encodes information the score lacks and
no causal interpretation is available. Adjusting for a variable partly under unit control
carries the hazards of mediator adjustment. Cancer ascertainment relied on APACHE
comorbidity flags and captured metastatic solid tumor and hematologic malignancy only.

Intensive care units are ranked on mortality. Mortality depends on whether treatment is
given. Whether treatment is given depends on a decision that varies several fold between
units for reasons unrelated to patients. Benchmarking that ignores this decision measures
end of life practice alongside quality of care.

---

## Notes on remaining work

**Style rules applied.** No colons. No semicolons. No dashes. One claim per sentence.
Citations on every factual assertion. Numbers written out where a sentence would
otherwise open with a digit.

**Target journal.** *Annals of the American Thoracic Society*. Rationale below.

| Journal | Fit | Odds |
|---|---|---|
| *Annals ATS* | Halpern group publishes there. Kramer analogue published there (14). Benchmarking methodology is core remit. | ~35% |
| *JAMA Internal Medicine* | Where Hart 2015 appeared (30). Higher bar. Would need the cancer angle dropped entirely, which it now is. | ~12% |
| *Critical Care Medicine* | Where Kramer (13) and Glance (12) appeared. Strong fit. | ~30% |
| *Journal of Critical Care* | Safe. | ~65% |

Submit to *Annals ATS* first.

**Sections still to write.** Methods and Results are drafted in `MANUSCRIPT_DRAFT.md`
with all numbers verified. They need converting to this style. Abstract needs rewriting
to match.

**Restructuring decision taken.** The between hospital variation analysis is now
confirmatory of Hart (30) rather than a primary finding. It occupies one Discussion
paragraph and moves to the supplement. The benchmarking consequence is the contribution.

**Figures.** Three exist. Two remain, the rank shift scatter and the before and after
funnel plot following Spiegelhalter (41).
