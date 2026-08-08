# Results — eICU code status / APACHE IVa calibration

Analysis run 2026-08-06. All numbers produced by the scripts in `R/`,
from `data_private/analytic.csv` extracted from `physionet-data.eicu_crd`.

---

## Cohort

136,236 ICU stays, **190 hospitals**. Cancer (APACHE IVa comorbidity flags):
4,326 (3.2%) — metastatic solid tumor 2,820, leukemia 1,017, lymphoma 579.

| | Cancer | No cancer |
|---|---|---|
| n | 4,326 | 131,910 |
| Age, median (IQR) | 67 (58–75) | 64 (52–75) |
| Female | 45.6% | 46.0% |
| APACHE score, median | 64 | 50 |
| Predicted mortality, mean | 20.67% | 11.52% |
| Observed mortality | 17.96% | 8.55% |
| **SMR** | **0.869** | **0.742** |
| Immunosuppression | 30.1% | 1.8% |
| Ventilated day 1 | 20.5% | 24.3% |
| **Code status documented ≤24h** | **97.7%** | **96.0%** |
| **Limitation (≥DNR) ≤24h** | **19.3%** | **9.6%** |
| Comfort measures only ≤24h | 1.39% | 0.62% |
| ICU LOS, median hours | 43.1 | 42.9 |

Screened out as unusable: `electivesurgery` (80.1% missing), `readmit` (constant).

## Primary analysis — logistic recalibration

SEs clustered on hospital. n = 136,236.

**M0 — APACHE IVa overall calibration**
- calibration slope **1.005** (1 = perfect)
- calibration intercept **−0.425** (0 = perfect)

> The score's problem is **purely an intercept shift**, not a slope problem.
> Discrimination scaling is essentially perfect; it is systematically
> over-predicting death across the whole risk range.

**Cancer coefficient, before and after code status**

| Model | Cancer OR | 95% CI | p |
|---|---|---|---|
| M1: `lp + cancer` | 1.224 | 1.104–1.357 | 0.0001 |
| M2: `lp + cancer + code status` | **1.148** | 1.032–1.277 | 0.0108 |

**Attenuation: 31.6% on the log-odds scale. The cancer effect does NOT vanish.**

**Code status effects (M2, reference = full therapy)**

| Code status | OR | 95% CI |
|---|---|---|
| Undocumented | 1.389 | 1.090–1.770 |
| DNR-type | 2.632 | 2.446–2.832 |
| Partial withdrawal | 2.966 | 2.189–4.020 |
| **Comfort measures only** | **15.301** | 12.136–19.291 |

**M3 — interaction**: cancer × any limitation OR 0.837 (0.679–1.032), **p = 0.095**.
Not significant. Consistent with the descriptive finding that within the DNR
stratum cancer and non-cancer calibration are near-identical (ratio 0.994).

LRT: adding cancer to M0 χ²=17.3 (p=3.1e-05); adding code status χ²=2,135.5
(p<2.2e-16). **Code status contributes ~123× more deviance than cancer.**

## Calibration by stratum (ICI = Integrated Calibration Index)

| Code status | Group | n | SMR | ICI | Emax |
|---|---|---|---|---|---|
| Full therapy | Cancer | 3,389 | 0.736 | 0.049 | 0.149 |
| Full therapy | No cancer | 113,988 | 0.612 | 0.039 | 0.248 |
| DNR-type | Cancer | 729 | 1.163 | 0.051 | 0.107 |
| DNR-type | No cancer | 11,200 | 1.170 | 0.037 | 0.046 |
| Partial | No cancer | 641 | 1.215 | 0.054 | 0.077 |
| **Comfort only** | Cancer | 60 | 1.700 | **0.299** | 0.447 |
| **Comfort only** | No cancer | 818 | 1.888 | **0.344** | 0.488 |

> In comfort-care patients the ICI is **7–9× larger** than any other stratum.
> APACHE IVa is not merely miscalibrated there — it is uninformative.

## Hospital-level variation

162 hospitals with ≥100 stays.

- limitation rate: median 10.5%, IQR 7.5–14.5%, **range 0.0–27.5%**
- SMR: median 0.720, IQR 0.603–0.847, range 0.113–1.557
- **ICC for limitation documentation = 0.084**
- **Spearman(limitation rate, SMR) = −0.066, p = 0.406 → NULL**

> Hospital limitation rate does **not** predict hospital SMR. The benchmarking-
> confounding hypothesis is not supported and must not be claimed.

## Timing

| | Cancer | No cancer |
|---|---|---|
| First limitation, median min | 135 | 130 |
| IQR | 35–575 | 36–514 |
| Within 6h | 65.9% | 69.0% |
| **Deepened after 24h** | **10.45%** | **6.70%** |

Timing of the *first* limitation is essentially identical. Cancer patients are
~56% more likely to have limitation **deepen** later in the stay.

## Cancer ascertainment concordance

| | Diagnosis text: no | Diagnosis text: yes |
|---|---|---|
| **APACHE flag: no** | 126,445 | 5,465 |
| **APACHE flag: yes** | 2,420 | 1,906 |

Only 1,906 stays are identified by both. The two instruments capture largely
different patients and this is a substantive limitation, not a footnote.

## What the data supports, and what it does not

**Supported**
1. APACHE IVa over-predicts, via intercept shift only (slope 1.005)
2. Code status is a powerful independent predictor beyond APACHE — up to OR 15.3
3. Cancer patients receive early limitation at 2.02× the rate
4. ~⅓ of the apparent cancer miscalibration is code-status composition
5. Calibration collapses in comfort-care patients (ICI 0.30–0.34)
6. Documentation varies widely between hospitals (0–27.5%, ICC 0.084)

**NOT supported**
1. ~~"Code status, not malignancy"~~ — cancer retains an independent effect
   (OR 1.148, p=0.011). The original title overclaims and must change.
2. ~~Hospital limitation rate confounds SMR benchmarking~~ — ρ=−0.066, p=0.41
3. ~~56% of the cancer effect is composition~~ — that figure is from SMR
   standardization. The regression estimate on the log-odds scale is **31.6%**.
   Both are defensible but they are different estimands and must not be
   conflated. Report the regression figure as primary.

## Revised framing

> **Code status is a stronger determinant of APACHE IVa miscalibration than
> malignancy in critically ill patients with cancer: an analysis of 190 US ICUs**

Practical recommendation, which is the paper's most useful output: severity
scores should not be applied to patients under comfort-care orders, and
code status should be recorded in any ICU benchmarking that uses SMR.

## Outputs

- `results/table1_cohort.csv`
- `results/table2_calibration_by_codestatus.csv`
- `results/hospital_level.csv`
- `results/models.rds`
- `figures/fig2_calibration_by_codestatus.png`
- `figures/fig3_hospital_variation.png`
