# Treatment limitation documentation and risk adjusted mortality benchmarking

Analysis code for a study of 136,236 adult intensive care admissions across 190 US
hospitals in the eICU Collaborative Research Database, asking whether between unit
variation in treatment limitation documentation reflects patient case mix or local
practice, and what it does to standardized mortality ratio benchmarking.

**Author.** Fabrice T. Nyambod, MD, MPH. Department of International Health, Johns
Hopkins Bloomberg School of Public Health, Baltimore, Maryland, USA.
ORCID [0009-0006-6592-2673](https://orcid.org/0009-0006-6592-2673).

---

## Reproducing the analysis

**No data are included here and none can be.** eICU-CRD v2.0 is released under the
PhysioNet Credentialed Health Data Use Agreement, which prohibits redistribution. Each
investigator must be credentialed individually.

1. Complete CITI human subjects research training and sign the DUA at
   [physionet.org/content/eicu-crd/2.0](https://physionet.org/content/eicu-crd/2.0/)
2. Request BigQuery access on the same page
3. Run `sql/02_build_analytic_dataset.sql` and save the result as
   `data_private/analytic.csv`
4. Then run everything:

```
Rscript run_all.R
```

`run_all.R` checks for the analytic file, installs any missing packages, and runs every
step in order. The extraction query is deterministic, so step 3 reproduces the dataset
exactly.

## Pipeline

Scripts in `R/` run in the order listed by `run_all.R`.

### Analysis

| Script | Purpose |
|---|---|
| `01_load_validate.R` | Load and reproduce the descriptive figures obtained directly from BigQuery |
| `02_recalibration_models.R` | Logistic recalibration of APACHE IVa, standard errors clustered on unit. The primary analysis |
| `17_table2_overall.R` | Calibration by limitation stratum, SMR, integrated calibration index |
| `03_calibration_hospital_timing.R` | Calibration curves, between unit variation, timing of limitation |
| `05_discrimination.R` | Held out AUC and Brier score, DeLong test |
| `06_hospital_reranking.R` | Unit ranking with and without limitation in the risk model |
| `07_practice_vs_casemix.R` | Whether variation is practice or case mix, and which remedy works |
| `14_cobalt_balance.R` | Inverse probability weighting and covariate balance |

### Outputs

| Script | Purpose |
|---|---|
| `10_validate_palette.R` | Validates the figure palette for color vision deficiency separation, contrast and grayscale printing |
| `35_flow_diagram.R` | Figure S1, cohort derivation with exclusion arms |
| `15_build_panels.R` | Figures 1 to 3, 600 dpi TIFF plus vector PDF |
| `11_submission_build.R` | Tables to Word |
| `25_build_full_docx.R` | Manuscript, Word |
| `32_build_supplement_docx.R` | Supplementary material, Word |
| `24_compile_latex.R` | Manuscript PDF via TinyTeX |

`R/maintenance/` holds one time operations already applied to the committed files, kept
for provenance. `R/archive/` holds superseded scripts. See `R/maintenance/README.md`.

## Key results

| | |
|---|---|
| Cohort | 136,236 stays, 190 units, 2014 to 2015 |
| Code status documented within 24h | 96.1% |
| Limitation beyond full therapy | 9.9% |
| SMR, full therapy to comfort measures | 0.62 to 1.87 |
| Integrated calibration index, same strata | 0.037 to 0.342 |
| Limitation rate, highest vs lowest quintile, after weighting | 2.89 fold, from 3.58 unweighted |
| Units changing quartile when limitation is modeled | 23.5% |
| Units changing outlier classification | 8.0% |
| Excluding comfort measures admissions only, 0.6% of the cohort | reclassifies 11.1% of units |

## What is deliberately excluded from this repository

- `data_private/` — patient level data under the DUA
- `results/models.rds` — fitted `glm` objects retain the full model frame, 136,236 rows
  in each of four models, so the file is patient level despite its name
- Reference PDFs and their extracted text — copyrighted, obtained via institutional access

Unit level aggregates in `results/` and `submission/supplementary/` carry no patient level
information and are safe to share.

## Environment

R 4.6.0. Packages: `data.table`, `ggplot2`, `patchwork`, `lme4`, `sandwich`, `lmtest`,
`pROC`, `cobalt`, `WeightIt`, `officer`, `flextable`, `magick`, `colorspace`, `scales`,
`httr`, `jsonlite`, `pdftools`, `tinytex`. LaTeX via TinyTeX. BigQuery access via the
Google Cloud SDK.

## Reproducibility notes

Decision thresholds for the feasibility probes were fixed before the corresponding
analyses were run and are recorded in `sql/01_feasibility_probe.sql`. The study question
was refined during exploratory work; an initial framing around malignancy was abandoned
when malignancy proved to add nothing to prediction. This is disclosed in the manuscript
under protocol registration.

Every reference was resolved against NCBI E-utilities or Crossref. A title search pass
returned the wrong article for four references, detected by reading the returned titles
and removed. `R/maintenance/20_prune_bad_bib.R` records that correction.

## License

Code released under the MIT License. The manuscript and figures are the author's work.
No eICU data are included under any license.
