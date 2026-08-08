# Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units

**Draft v4, 2026-08-06.** Target *Annals of the American Thoracic Society*.
Reference numbers follow `REFERENCES.md`.

---

## Abstract

**Rationale.** Standardized mortality ratios from severity of illness scores are used to
compare intensive care unit performance. These scores estimate the probability of death
under full treatment and contain no term for treatment limitation.

**Objective.** To determine whether between unit variation in treatment limitation
documentation reflects patient case mix or local practice, and to quantify its effect on
risk adjusted mortality benchmarking.

**Methods.** Retrospective analysis of 136,236 adult admissions to 190 US intensive care
units in the eICU Collaborative Research Database, 2014 to 2015. Limitation documented
within 24 hours was classified from full therapy to comfort measures only. We assessed
APACHE IVa calibration within strata, compared the highest and lowest limitation
quintiles before and after inverse probability weighting, and ranked units with and
without limitation in the risk model.

**Measurements and Main Results.** Code status was documented in 96.1 percent of
admissions and 9.9 percent carried a limitation. The standardized mortality ratio rose
from 0.62 under full therapy to 1.87 under comfort measures, and the integrated
calibration index from 0.037 to 0.342. After weighting balanced all 13 covariates, units
in the highest quintile still documented limitation 2.89 times as often as the lowest,
against 3.58 unweighted. Adding limitation to the risk model changed quartile assignment
for 23.5 percent of units and reversed outlier classification for 8.0 percent, with
movement predicted by unit limitation rate (rho negative 0.689). Excluding the 878
comfort measures admissions, 0.6 percent, reclassified 11.1 percent of units.

**Conclusions.** Units differ severalfold in documenting treatment limitation and case
mix does not account for it. Benchmarking that ignores these decisions disadvantages
units documenting limitations more often.

---

## Introduction

End of life practice varies widely between intensive care units. Withdrawal of life
sustaining treatment among patients who die ranges from 0 to 84 percent across published
cohorts (31). The Ethicus-2 investigators found comparable variation across 199 units in
36 countries (32). Variation has been documented between countries, between regions and
between units within a single country (31, 36, 37). Two academic centers at opposite
extremes of treatment intensity differed in decision making norms rather than in patients
(34). Hospital level measures of end of life treatment intensity have been developed and
validated for precisely this reason (33). Hart and colleagues studied 277,693 admissions
to 141 US units and found the proportion admitted with existing treatment limitations
ranged from under 1 percent to 20.9 percent after risk adjustment (30). Measurable center
characteristics did not explain that variation (30).

Treatment limitation is common in critical illness. Do not resuscitate orders were
recorded in 13 percent of 24,790 admissions to one tertiary unit over 19 years (24), and
in 36.6 percent of a medical intensive care cohort when orders for life sustaining
treatment were included (22). Timing varies, with roughly a quarter of orders written
within 48 hours of admission and the remainder later (25). These orders carry substantial
prognostic weight. Mortality among patients with such orders is several times that of
patients without them (22, 26), and the association persists after propensity matching
(29). Placing an order also changes subsequent care, including the intensity of
interventions delivered (23).

Severity of illness scores estimate the probability of death under full treatment. The
APACHE method was introduced in 1985 and validated on 5,815 admissions from 13 hospitals
(2). The APACHE IVa model was derived from 110,558 admissions to 104 units during 2002
and 2003 (1). Its covariates describe
physiology, age, comorbidity and admission diagnosis (1). Comparable models including
SAPS 3 and the Simplified Acute Physiology Score share this structure (10, 11). No
covariate in any of them represents a decision to withhold resuscitation. An order not to
resuscitate alters the probability of death without altering any variable the model
observes.

The performance of these models is known to be unstable. Discrimination and calibration
deteriorate as practice changes, which is why successive versions have been required (6,
7). Performance also differs across ethnic groups within the same health system (9). Calibration is generally the first property to fail while
discrimination is preserved (6).

Standardized mortality ratios derived from these scores are the accepted currency of
intensive care benchmarking (12). Units are compared and ranked on observed deaths
divided by predicted deaths, and in some systems reimbursed on that basis (12). The
ratio is assumed to isolate quality of care once case mix is accounted for (12).
Several lines of evidence suggest the assumption is fragile. Glance and colleagues showed
that the choice of scoring system determines which units are labeled outliers (12).
Kramer and colleagues compared APACHE IVa against a National Quality Forum model across
89,353 admissions and found the two agreed on the direction and significance of the
standardized mortality ratio in only 45 percent of units (13). Admission patterns alone
alter mortality based performance measures (14). Risk adjusted mortality carries
conceptual limits that constrain its use as a quality signal, since a statistically
unexpected death is not the same as a preventable one (15). Model misspecification
introduces bias into the resulting quality measures (19), and alternative modeling
strategies produce materially different unit level estimates (16, 17).

Whether treatment limitation practice distorts these comparisons has not been tested.
Hart and colleagues proposed that advance care planning norms contribute to variation in
intensive care use and demonstrated the mechanism by simulation (35). Feng and Dubin
identified variables associated with incorrect APACHE IVa predictions in a multicenter
database and included the frequency of care limitation change among them, but examined
classification error rather than calibration (47). No study has measured the consequence
for risk adjusted mortality benchmarking in observed data.

We examined 136,236 admissions to 190 US intensive care units. We asked whether APACHE
IVa calibration depends on documented treatment limitation, whether between unit
variation in limitation survives balancing of patient case mix, and whether accounting
for limitation changes how units are ranked.

---

## Methods

### Data source

We analyzed the eICU Collaborative Research Database version 2.0, which contains 200,859
unit stays at 208 US hospitals participating in a tele critical care program during
2014 and 2015 (46). The database carries vital signs, laboratory values, care plan
documentation, severity scores and outcomes (46), and has been characterized in detail
elsewhere (49). It is deidentified and was accessed under a data use agreement following
completion of human subjects research training (46). Institutional review board approval
was waived for analysis of this deidentified resource. Reporting follows the TRIPOD
recommendations for studies evaluating prediction models (44, 45).

### Cohort

We included adult unit stays with a valid APACHE IVa predicted hospital mortality linked
to the APACHE predictor table, yielding 136,236 stays at 190 units. Unit level analyses
were restricted to the 162 units contributing 100 or more stays, comprising 135,325
admissions. Figure 1 shows the derivation.

### Exposure

Treatment limitation was taken from structured care plan documentation. For each stay we
recorded the most restrictive value documented within 24 hours of unit admission on an
ordered scale. Full therapy formed the reference. Limitation of resuscitation type
comprised do not resuscitate, no cardiopulmonary resuscitation, no intubation and no
cardioversion. Partial withdrawal comprised no vasopressors or inotropes, no augmentation
of care, no blood products and no blood draws. Comfort measures only formed the most
restrictive category. Stays with no entry were retained as an undocumented category and
reported but not interpreted.

The 24 hour window follows prior work distinguishing early from late limitation orders
(25) and limits the degree to which the exposure reflects deterioration occurring
later in the stay.

### Outcome

In hospital mortality was compared against APACHE IVa predicted hospital mortality.

### Statistical analysis

Calibration was assessed by logistic recalibration, regressing observed mortality on the
logit of predicted mortality. A slope of 1 and an intercept of 0 indicate perfect
calibration. Within strata we report the standardized mortality ratio and the integrated
calibration index, the mean absolute difference between a smoothed observed risk and the
predicted risk (39, 40). Standard errors were clustered on unit throughout.

The independent contribution of limitation status was estimated by adding it to a
recalibration model containing the APACHE linear predictor. Malignancy was included to
test whether an established source of miscalibration behaves similarly (48).
Discrimination was assessed on a random 30 percent holdout of 40,871 admissions by area
under the receiver operating characteristic curve with DeLong's test and by Brier score.

To distinguish practice from case mix we compared units in the highest and lowest
quintile of limitation rate. Patient characteristics were balanced by inverse probability
of treatment weighting estimated by logistic regression, following recommended practice
(56). Balance was assessed by standardized mean differences against a threshold of 0.1
(56). We then compared limitation rates between quintiles before and after weighting. If
case mix accounted for the difference, balancing case mix should remove it. Between unit
variation was additionally summarized by the intraclass correlation coefficient and the
median odds ratio from mixed effects models with a unit random intercept (42, 43).

To quantify the benchmarking consequence, expected deaths per unit were computed twice.
The first used a recalibrated APACHE IVa model representing current practice. The second
added limitation status. Units were ranked by standardized mortality ratio under each and
compared on rank shift, quartile change and outlier status using exact Poisson 95 percent
limits following Spiegelhalter (41). We additionally evaluated two simpler strategies,
excluding admissions under comfort measures orders and excluding all admissions with any
limitation.

Analyses used R version 4.6.0.

---

## Results

### Cohort

Among 136,236 admissions, mean APACHE IVa predicted mortality was 11.8 percent against
observed mortality of 8.85 percent, giving an overall standardized mortality ratio of
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
the entire risk range. This pattern of preserved discrimination with failed calibration
matches that described for severity scores in contemporary cohorts (6).

Calibration differed sharply by limitation status (Figure 2A). The standardized mortality
ratio was 0.62 under full therapy, 1.17 with resuscitation limitation, 1.22 with partial
withdrawal and 1.87 under comfort measures only. The integrated calibration index was
0.039, 0.037 and 0.054 in the first three strata and 0.34 under comfort measures. In that
stratum the model is not miscalibrated but uninformative.

In a recalibration model with full therapy as reference, the adjusted odds of death were
2.63 with resuscitation limitation, 2.97 with partial withdrawal and 15.30 under comfort
measures only (Figure 2B). Metastatic or hematologic malignancy carried an adjusted odds
ratio of 1.15. Adding limitation status reduced model deviance by 3.6 percent against 0.0
percent for malignancy, and the likelihood ratio statistic was 2,136 against 17.

On held out data, adding limitation status improved the area under the curve from 0.8657
to 0.8760, significant by DeLong's test at p less than 0.001, and reduced the Brier score
from 0.0621 to 0.0579. Adding malignancy changed the area under the curve by 0.0001,
which was not significant.

### Variation between units is not explained by case mix

Across 162 units, limitation rates ranged from 0 to 27.5 percent with a median of 10.5
percent (Figure 3A). One unit documented no limitation across more than 100 admissions.

Units in the highest limitation quintile differed from those in the lowest on two of 13
measured characteristics before weighting. Patients were older, with a standardized mean
difference of 0.197, and more often admitted from the emergency department, at 0.149.
Severity was near identical, at negative 0.006 for the APACHE IVa score and 0.008 for
predicted mortality.

After inverse probability weighting all 13 covariates balanced within the 0.1 threshold
(Figure 3B). Age fell to negative 0.004 and admission from the emergency department to
0.004. Despite complete balance on measured characteristics, units in the highest
quintile documented limitation in 16.5 percent of admissions against 5.7 percent in the
lowest, a ratio of 2.89. The unweighted ratio was 3.58. Approximately four fifths of the
difference in practice survived balancing of patient case mix.

Mixed effects models gave the same answer. The intraclass correlation was 0.084 before
adjustment and 0.104 after adjustment for case mix. The median odds ratio rose from 1.69
to 1.80, indicating that moving a patient between randomly chosen units changes the odds
of documented limitation by close to twofold (43).

### Consequences for benchmarking

Adding limitation status to the risk model preserved the overall ordering of units, with
a Spearman correlation of 0.949, while moving individual units substantially. The median
absolute rank shift was 7.5 positions of 162. Sixty two units moved more than 10
positions and 24 moved more than 20.

Thirty eight units, or 23.5 percent, changed quartile. Thirteen units, or 8.0 percent,
changed outlier classification against exact Poisson limits (41). Four units previously
flagged as high mortality became unremarkable and three previously unremarkable units
became outliers (Figure 4B).

Movement was systematic. The signed rank shift correlated with a unit's limitation rate
at a Spearman coefficient of negative 0.689 (Figure 4A). Units in the lowest limitation
quintile moved from a standardized mortality ratio of 0.984 to 1.027. Units in the
highest quintile moved from 1.013 to 0.876. Under current benchmarking these quintiles
appear equivalent. After accounting for limitation they do not.

### A simpler remedy

Excluding the 878 admissions under comfort measures orders, 0.6 percent of the cohort,
reclassified 18 units across quartiles, or 11.1 percent. Full adjustment for the ordered
limitation scale reclassified 38 units, or 23.5 percent. Excluding all 13,496 admissions
with any limitation reclassified 46 units, or 28.4 percent. Excluding the smallest group
recovered roughly half the effect of full adjustment.

---

## Discussion

APACHE IVa calibration depends on a decision the model does not observe. The standardized
mortality ratio was 0.62 among patients receiving full therapy and 1.87 among patients
under comfort measures. The integrated calibration index in that stratum was nine times
larger than elsewhere (39). The model is not merely displaced in these patients. It is
uninformative.

Documentation of limitation varied severalfold between units and patient case mix did not
account for it. This extends Hart and colleagues, who reported comparable variation after
regression adjustment in a different database a decade earlier (30). Our design equalized
the covariate distributions rather than adjusting for them (56), and roughly four fifths
of the practice difference persisted. Limitation rates were higher in our cohort than in
theirs, 10.5 percent against 4.0 percent, consistent with the expansion of palliative
care services over the intervening period. Palliative care consultation more than doubles
transition to limitation orders in randomized comparison, from 23.4 to 50.5 percent (53),
and integration of palliative care into critical care alters both process and outcome
measures (54, 55). Units therefore differ in limitation rate partly because they differ
in service configuration, which is a property of the unit rather than of its patients
(34).

The consequence for benchmarking is substantial. Accounting for limitation moved 23.5
percent of units across quartiles and reversed outlier classification for 8.0 percent.
Kramer and colleagues found that substituting an entirely different risk model changed
the direction and significance of the standardized mortality ratio in 55 percent of units
(13). Glance and colleagues reached a similar conclusion comparing scoring systems (12),
and admission patterns alone have been shown to shift these measures (14). We find that a
single variable already recorded in 96 percent of charts moves a quarter of quartile
assignments. The intervention is far smaller and the effect is of comparable order.

Whether to adjust for limitation status is a genuine question and we do not resolve it.
Adjustment treats limitation as patient preference and therefore as case mix. Withholding
adjustment treats it as modifiable unit behavior. Both positions are defensible. Nerenz
and colleagues framed the identical dilemma for social risk factors, where adjustment may
conceal real differences in care while omission penalizes institutions serving different
populations (21). The parallel is exact. Misspecification of the adjustment model is
itself a recognized source of bias in quality measurement (19). Our contribution is
not to settle the question but to show that the answer changes the rank of one unit in
four, and that the choice is currently made by default.

A simpler remedy exists. Excluding admissions under comfort measures orders affects six
patients in every thousand and recovers half the effect. Benchmarking programs already
exclude categories of patient from severity scoring, and the National Quality Forum model
excludes 27.9 percent of admissions against 10.6 percent for APACHE IVa (13). Adding one
narrow exclusion is feasible within existing practice.

This study has limitations. We observed documentation and not practice. Code status
documentation in electronic records is frequently incomplete, difficult to locate or
internally contradictory (50). Units may limit treatment without recording it, which would understate
true variation. The data describe 2014 and 2015 and derive from units participating in a
single tele critical care program (46). Limitation status is partly a consequence of
prognosis. Clinicians write these orders because they expect death, so limitation encodes
information the score lacks and no causal interpretation is available. This same
dependency has been shown to bias mortality based effect estimates in trauma (27).
Adjusting for a variable partly under unit control carries the hazards of mediator
adjustment. Weighting balanced measured characteristics only and unmeasured
differences between units may remain (56). Cancer ascertainment relied on APACHE
comorbidity flags and captured metastatic solid tumor and hematologic malignancy only
(48).

Intensive care units are ranked on mortality. Mortality depends on whether treatment is
given. Whether treatment is given depends on a decision that varies severalfold between
units for reasons unrelated to patients. Benchmarking that ignores this decision measures
end of life practice alongside quality of care.

---

## Declarations

**Funding.** No funding was received for conducting this study.

**Conflicts of interest.** The author declares no competing interests.

**Ethics approval.** Not required. This study analyzed only de-identified data from the
eICU Collaborative Research Database, for which the original collection and release were
approved with a waiver of informed consent. No human participants were involved and no
identifiable data were accessed. Access was granted following completion of the CITI
human subjects research training required by PhysioNet and execution of the PhysioNet
Credentialed Health Data Use Agreement.

**Consent to participate.** Not applicable.

**Consent for publication.** Not applicable.

**Protocol registration.** This analysis was not prospectively registered. The exposure
definition, the ordered limitation scale, the 24 hour window and the decision thresholds
used to judge feasibility were fixed before the corresponding analyses were run and are
recorded in the project repository. The research question was, however, refined during
exploratory work. An initial framing around malignancy was abandoned when malignancy
proved to contribute nothing to prediction, and the benchmarking framing was adopted
after preliminary calibration results had been seen. Readers should weigh the findings
accordingly. The confirmatory analyses reported here, namely the weighted comparison of
limitation quintiles and the ranking comparison, were specified before they were run.

**Availability of data and material.** The eICU Collaborative Research Database version
2.0 is available to credentialed investigators from PhysioNet at
https://physionet.org/content/eicu-crd/2.0/. Access requires completion of human subjects
research training and execution of a data use agreement that prohibits redistribution, so
patient level data cannot be shared by the author. Investigators who complete
credentialing can reproduce the analytic dataset exactly using the extraction query in the
repository. Unit level aggregate results, including the per unit limitation rates,
standardized mortality ratios and ranking data underlying Figures 3 and 4, are provided as
supplementary files and contain no patient level information.

**Code availability.** The full analysis pipeline is publicly available at [repository URL
to be inserted at submission], released under the MIT License. It covers cohort
extraction, the ordered limitation classification, calibration assessment, inverse
probability weighting, the unit ranking comparison, and all table and figure generation.
Analyses used R 4.6.0. The repository records the decision thresholds that were fixed in
advance, together with a record of the deviations described under protocol registration.

**Author contributions.** F.T.N. conceived the study, designed the analysis, performed the
data extraction and statistical analysis, generated the figures and tables, and wrote the
manuscript.

**Acknowledgements.** The author thanks the MIT Laboratory for Computational Physiology
and Philips Healthcare for developing and maintaining the eICU Collaborative Research
Database, and PhysioNet for hosting it.
