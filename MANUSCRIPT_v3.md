# Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units

**Draft v3, complete. 2026-08-06.** Target *Annals of the American Thoracic Society*.

Style follows Hart et al, *JAMA Intern Med* 2015. Short declarative sentences. One
claim per sentence. No colons, semicolons or dashes. Every factual assertion carries a
citation. Reference numbers correspond to `REFERENCES.md`.

---

## Abstract

**Rationale.** Standardised mortality ratios derived from severity of illness scores are
used to compare intensive care unit performance. These scores estimate the probability of
death under full treatment and contain no term for treatment limitation. Units differ in
how often such limitations are documented.

**Objective.** To determine whether between unit variation in treatment limitation
documentation reflects patient case mix or local practice, and to quantify its
consequences for risk adjusted mortality benchmarking.

**Methods.** Retrospective analysis of 136,236 adult admissions to 190 US intensive care
units in the eICU Collaborative Research Database during 2014 and 2015. Treatment
limitation documented within 24 hours of admission was classified on an ordered scale
from full therapy to comfort measures only. We assessed APACHE IVa calibration within
limitation strata. We compared patient characteristics between units in the highest and
lowest quintile of limitation rate before and after inverse probability weighting. We
then ranked units by standardised mortality ratio with and without limitation status in
the risk model.

**Measurements and Main Results.** Code status was documented in 96.1 percent of
admissions. A limitation beyond full therapy was present in 9.9 percent. The APACHE IVa
calibration slope was 1.005 with an intercept of negative 0.425. The standardised
mortality ratio rose from 0.62 under full therapy to 1.87 under comfort measures only.
The integrated calibration index was 0.34 in the comfort measures stratum and 0.04
elsewhere. After weighting until all 13 measured covariates balanced, units in the
highest limitation quintile still documented limitation 2.89 times as often as units in
the lowest quintile, compared with 3.58 times before weighting. Adding limitation status
to the risk model changed quartile assignment for 23.5 percent of units and reversed
mortality outlier classification for 8.0 percent. The direction of movement was predicted
by a unit's limitation rate with a Spearman correlation of negative 0.689. Excluding the
878 admissions under comfort measures orders, six in every thousand, reclassified 11.1
percent of units.

**Conclusions.** Units differ severalfold in how often treatment limitation is
documented and patient case mix does not account for it. Risk adjusted mortality
benchmarking that ignores these decisions systematically disadvantages units that
document limitations more often.

---

## Introduction

End of life practice varies widely between intensive care units. Withdrawal of life
sustaining treatment among patients who die ranges from 0 to 84 percent across published
cohorts (31). The Ethicus-2 investigators found comparable variation across 199 units in
36 countries (32). Hart and colleagues studied 277,693 admissions to 141 US units and
found that the proportion admitted with existing treatment limitations ranged from under
1 percent to 20.9 percent after risk adjustment (30). Measurable centre characteristics
did not explain that variation (30). The authors concluded that unit culture and
physician practice style contribute to it (30).

Severity of illness scores estimate the probability of death under full treatment. The
APACHE IVa model was derived from 110,558 admissions to 104 units during 2002 and 2003
(1). Its covariates describe physiology, age, comorbidity and admission diagnosis (1). No
covariate represents a decision to withhold resuscitation. An order not to resuscitate
alters the probability of death without altering any variable the model observes.

Standardised mortality ratios derived from these scores are the accepted currency of
intensive care benchmarking (12). Units are compared and ranked on observed deaths
divided by predicted deaths, and in some systems reimbursed on that basis (12). The ratio
is assumed to isolate quality of care once case mix is accounted for (12). Kramer and
colleagues showed the assumption is fragile. Comparing APACHE IVa against a National
Quality Forum model across 89,353 admissions, the two methods agreed on the direction and
significance of the standardised mortality ratio in only 45 percent of units (13).

Whether treatment limitation practice distorts these comparisons has not been tested.
Hart and colleagues proposed that advance care planning norms contribute to variation in
intensive care use and demonstrated the mechanism by simulation (35). No study has
measured the consequence for risk adjusted mortality benchmarking in observed data.

We examined 136,236 admissions to 190 US intensive care units. We asked whether APACHE
IVa calibration depends on documented treatment limitation, whether between unit
variation in limitation survives balancing of patient case mix, and whether accounting
for limitation changes how units are ranked.

---

## Methods

### Data source

We analysed the eICU Collaborative Research Database version 2.0, which contains 200,859
unit stays at 208 US hospitals participating in a tele critical care programme during
2014 and 2015 (46). The database is deidentified and was accessed under a data use
agreement following completion of human subjects research training (46). Institutional
review board approval was waived for analysis of this deidentified resource.

### Cohort

We included adult unit stays with a valid APACHE IVa predicted hospital mortality linked
to the APACHE predictor table. This yielded 136,236 stays at 190 units. Unit level
analyses were restricted to the 162 units contributing 100 or more stays, comprising
135,325 admissions. Figure 1 shows the derivation.

### Exposure

Treatment limitation was taken from structured care plan documentation. For each stay we
recorded the most restrictive value documented within 24 hours of unit admission on an
ordered scale. Full therapy formed the reference. Limitation of resuscitation type
comprised do not resuscitate, no cardiopulmonary resuscitation, no intubation and no
cardioversion. Partial withdrawal comprised no vasopressors or inotropes, no augmentation
of care, no blood products and no blood draws. Comfort measures only formed the most
restrictive category. Stays with no entry were retained as an undocumented category and
reported but not interpreted.

The 24 hour window follows prior work on early limitation orders (25) and limits the
degree to which limitation reflects deterioration occurring later in the stay.

### Outcome

In hospital mortality was compared against APACHE IVa predicted hospital mortality.

### Statistical analysis

Calibration was assessed by logistic recalibration, regressing observed mortality on the
logit of predicted mortality. A slope of 1 and an intercept of 0 indicate perfect
calibration. Within strata we report the standardised mortality ratio and the integrated
calibration index, the mean absolute difference between a smoothed observed risk and
predicted risk (39). Standard errors were clustered on unit throughout.

The independent contribution of limitation status was estimated by adding it to a
recalibration model containing the APACHE linear predictor. Malignancy was included to
test whether an established source of miscalibration behaves similarly. Discrimination
was assessed on a random 30 percent holdout of 40,871 admissions by area under the
receiver operating characteristic curve with DeLong's test and by Brier score.

To distinguish practice from case mix we compared units in the highest and lowest
quintile of limitation rate. Patient characteristics were balanced by inverse probability
of treatment weighting estimated by logistic regression, with balance assessed by
standardised mean differences against a threshold of 0.1 (42). We then compared limitation
rates between quintiles before and after weighting. If case mix accounted for the
difference, balancing case mix should remove it. Between unit variation was additionally
summarised by the intraclass correlation coefficient and the median odds ratio from mixed
effects models with a unit random intercept (42, 43).

To quantify the benchmarking consequence, expected deaths per unit were computed twice.
The first used a recalibrated APACHE IVa model representing current practice. The second
added limitation status. Units were ranked by standardised mortality ratio under each and
compared on rank shift, quartile change and outlier status using exact Poisson 95 percent
limits following Spiegelhalter (41). We additionally evaluated two simpler strategies,
excluding admissions under comfort measures orders and excluding all admissions with any
limitation.

Analyses used R version 4.6.0. Analysis code is available at the repository cited in the
data availability statement.

---

## Results

### Cohort

Among 136,236 admissions, mean APACHE IVa predicted mortality was 11.8 percent against
observed mortality of 8.85 percent, giving an overall standardised mortality ratio of
0.75. Code status was documented within 24 hours in 96.1 percent of admissions. A
limitation beyond full therapy was present in 13,496 admissions, or 9.9 percent.

Table 1 shows cohort characteristics by limitation status. Patients with any limitation
were older, with a median age of 77 years in the resuscitation limitation group against
63 years under full therapy. They were more severely ill, with a median APACHE IVa score
of 66 against 49. Patients under comfort measures orders had a median APACHE IVa score of
85 and a median unit stay of 18.2 hours.

### APACHE IVa calibration depends on treatment limitation

The overall calibration slope was 1.005 with an intercept of negative 0.425. The model
ranks patients almost perfectly and is uniformly displaced, over predicting death across
the entire risk range.

Calibration differed sharply by limitation status (Figure 2A). The standardised mortality
ratio was 0.62 under full therapy, 1.17 with resuscitation limitation, 1.22 with partial
withdrawal and 1.87 under comfort measures only. The integrated calibration index was
0.039, 0.037 and 0.054 in the first three strata and 0.34 under comfort measures. In that
stratum the model is not miscalibrated but uninformative.

In a recalibration model with full therapy as reference, the adjusted odds of death were
2.63 with resuscitation limitation, 2.97 with partial withdrawal and 15.30 under comfort
measures only (Figure 2B). Metastatic or haematologic malignancy carried an adjusted odds
ratio of 1.15. Adding limitation status reduced model deviance by 3.6 percent against 0.0
percent for malignancy, and the likelihood ratio statistic was 2,136 against 17.

On held out data, adding limitation status improved the area under the curve from 0.8657
to 0.8760, a difference significant by DeLong's test at p less than 0.001, and reduced
the Brier score from 0.0621 to 0.0579. Adding malignancy changed the area under the curve
by 0.0001, which was not significant.

### Variation between units is not explained by case mix

Across 162 units, limitation rates ranged from 0 to 27.5 percent with a median of 10.5
percent (Figure 3A). One unit documented no limitation across more than 100 admissions.

Units in the highest limitation quintile differed from those in the lowest on two of 13
measured characteristics before weighting. Patients were older, with a standardised mean
difference of 0.197, and more often admitted from the emergency department, with a
standardised mean difference of 0.149. Severity was near identical, with standardised
mean differences of negative 0.006 for the APACHE IVa score and 0.008 for predicted
mortality.

After inverse probability weighting all 13 covariates balanced within the 0.1 threshold
(Figure 3B). Age fell to negative 0.004 and admission from the emergency department to
0.004. Despite complete balance, units in the highest quintile documented limitation in
16.5 percent of admissions against 5.7 percent in the lowest, a ratio of 2.89. The
unweighted ratio was 3.58. Approximately four fifths of the difference in practice
survived balancing of patient case mix.

Mixed effects models gave the same answer. The intraclass correlation was 0.084 before
adjustment and 0.104 after adjustment for case mix. The median odds ratio rose from 1.69
to 1.80.

### Consequences for benchmarking

Adding limitation status to the risk model preserved the overall ordering of units, with
a Spearman correlation of 0.949, while moving individual units substantially. The median
absolute rank shift was 7.5 positions of 162. Sixty two units moved more than 10
positions and 24 moved more than 20.

Thirty eight units, or 23.5 percent, changed quartile. Thirteen units, or 8.0 percent,
changed outlier classification. Four units previously flagged as high mortality became
unremarkable and three previously unremarkable units became outliers (Figure 4B).

Movement was systematic. The signed rank shift correlated with a unit's limitation rate
at a Spearman coefficient of negative 0.689 (Figure 4A). Units in the lowest limitation
quintile moved from a standardised mortality ratio of 0.984 to 1.027. Units in the
highest quintile moved from 1.013 to 0.876. Under current benchmarking these quintiles
appear equivalent. After accounting for limitation they do not.

### A simpler remedy

Excluding the 878 admissions under comfort measures orders, 0.6 percent of the cohort,
reclassified 18 units across quartiles, or 11.1 percent. Full adjustment for the ordered
limitation scale reclassified 38 units, or 23.5 percent. Excluding all 13,496 admissions
with any limitation reclassified 46 units, or 28.4 percent. Excluding the smallest group
therefore recovered roughly half the effect of full adjustment.

---

## Discussion

APACHE IVa calibration depends on a decision the model does not observe. The standardised
mortality ratio was 0.62 among patients receiving full therapy and 1.87 among patients
under comfort measures. The integrated calibration index in that stratum was nine times
larger than elsewhere. The model is not merely displaced in these patients. It is
uninformative.

Documentation of limitation varied severalfold between units and patient case mix did not
account for it. This extends Hart and colleagues, who reported comparable variation after
regression adjustment in a different database a decade earlier (30). Our design equalised
the covariate distributions rather than adjusting for them, and roughly four fifths of the
practice difference persisted. Limitation rates were higher in our cohort than in theirs,
10.5 percent against 4.0 percent, which is consistent with the expansion of palliative
care services over the intervening period (53).

The consequence for benchmarking is substantial. Accounting for limitation moved 23.5
percent of units across quartiles and reversed outlier classification for 8.0 percent.
Kramer and colleagues found that substituting an entirely different risk model changed
the direction and significance of the standardised mortality ratio in 55 percent of units
(13). We find that a single variable already recorded in 96 percent of charts moves a
quarter of quartile assignments. The intervention is far smaller and the effect is of
comparable order.

Whether to adjust for limitation status is a genuine question and we do not resolve it.
Adjustment treats limitation as patient preference and therefore as case mix. Withholding
adjustment treats it as modifiable unit behaviour. Both positions are defensible. Nerenz
and colleagues framed the identical dilemma for social risk factors, where adjustment may
conceal real differences in care while omission penalises institutions serving different
populations (21). The parallel is exact. Our contribution is not to settle the question
but to show that the answer changes the rank of one unit in four, and that the choice is
currently made by default.

A simpler remedy exists. Excluding admissions under comfort measures orders affects six
patients in every thousand and recovers half the effect. Benchmarking programmes already
exclude categories of patient from severity scoring (13). Adding one more is feasible.

Our findings extend rather than contradict prior work in this database. Feng and Dubin
identified variables associated with incorrect APACHE IVa predictions and included the
frequency of care limitation change among them (47). They examined classification error
rather than calibration and did not consider benchmarking (47). They also reported APACHE
IVa predicting 11.96 percent mortality against 9.91 percent observed, which corroborates
the over prediction we describe (47). Glance and colleagues showed that the choice of
scoring system alters which units are labelled outliers (12). We show that a variable
absent from every scoring system does the same.

This study has limitations. We observed documentation and not practice. Units may limit
treatment without recording it, which would understate true variation. The data describe
2014 and 2015 and derive from units participating in a single tele critical care
programme (46). Limitation status is partly a consequence of prognosis. Clinicians write
these orders because they expect death, so limitation encodes information the score lacks
and no causal interpretation is available. Adjusting for a variable partly under unit
control carries the hazards of mediator adjustment (18). Weighting balanced measured
characteristics only and unmeasured differences between units may remain. Cancer
ascertainment relied on APACHE comorbidity flags and captured metastatic solid tumour and
haematologic malignancy only.

Intensive care units are ranked on mortality. Mortality depends on whether treatment is
given. Whether treatment is given depends on a decision that varies severalfold between
units for reasons unrelated to patients. Benchmarking that ignores this decision measures
end of life practice alongside quality of care.

---

## Tables and figures

| Item | File |
|---|---|
| Table 1 cohort characteristics by limitation status | `submission/tables/Tables_1_to_3.docx` |
| Table 2 calibration by limitation status | same |
| Table 3 discrimination on held out data | same |
| Table 4 effect on unit ranking | `submission/tables/Tables_4_to_5.docx` |
| Table 5 comparison of remediation strategies | same |
| Figure 1 study flow | `submission/figures/Figure1_flow.tiff` |
| Figure 2 model performance, panels A and B | `Figure2_model_performance.tiff` |
| Figure 3 between unit variation, panels A and B | `Figure3_unit_variation.tiff` |
| Figure 4 benchmarking impact, panels A and B | `Figure4_benchmarking.tiff` |
| Table S1 unit level case mix | `submission/supplementary/` |
| Table S2 unit level reranking | same |
| Table S3 covariate balance | same |

## Outstanding

1. Google Scholar cited by sweep of reference 46 for code status and care limitation.
   The one novelty check that cannot be run from here.
2. Full bibliographic detail for references not yet verified individually.
3. Data availability statement and code repository URL.
4. Author list, affiliations, funding, conflicts.
