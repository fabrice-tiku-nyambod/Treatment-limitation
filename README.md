# Treatment limitation documentation and risk adjusted mortality benchmarking

Analysis code for a study of 136,236 adult intensive care admissions across 190 US
hospitals in the eICU Collaborative Research Database, examining whether between unit
variation in treatment limitation documentation reflects patient case mix or local
practice, and what it does to standardized mortality ratio benchmarking.

**Author.** Fabrice T. Nyambod, MD, MPH. Department of International Health, Johns
Hopkins Bloomberg School of Public Health, Baltimore, Maryland, USA.
ORCID [0009-0006-6592-2673](https://orcid.org/0009-0006-6592-2673).

---

## Data access

**No data are included in this repository and none can be.** eICU-CRD v2.0 is released
under the PhysioNet Credentialed Health Data Use Agreement, which prohibits
redistribution. Each investigator must be credentialed individually.

To reproduce the analysis:

1. Complete CITI human subjects research training and sign the data use agreement at
   [physionet.org/content/eicu-crd/2.0](https://physionet.org/content/eicu-crd/2.0/)
2. Request BigQuery access on the same page, or download the flat files
3. Run `sql/02_build_analytic_dataset.sql` to produce `data_private/analytic.csv`
4. Run the R scripts in numerical order

The extraction query is deterministic, so step 3 reproduces the analytic dataset exactly.

## Pipeline

| Script | Purpose |
|---|---|
| `sql/00_access_probe.sql` | confirm BigQuery access, zero byte queries |
| `sql/01_feasibility_probe.sql` | go / no go probes with decision rules fixed in advance |
| `sql/02_build_analytic_dataset.sql` | one row per unit stay, the analytic dataset |
| `R/01_load_validate.R` | load and reproduce the descriptive figures from BigQuery |
| `R/02_recalibration_models.R` | logistic recalibration, the primary analysis |
| `R/03_calibration_hospital_timing.R` | calibration by stratum, ICI, unit variation, timing |
| `R/05_discrimination.R` | held out AUC and Brier, DeLong test |
| `R/06_hospital_reranking.R` | ranking with and without limitation in the risk model |
| `R/07_practice_vs_casemix.R` | is the variation practice or case mix |
| `R/14_cobalt_balance.R` | inverse probability weighting and covariate balance |
| `R/15_build_panels.R` | the four panelled figures, TIFF and vector PDF |
| `R/17_table2_overall.R` | calibration table, whole cohort |
| `R/18` to `R/23` | reference verification against NCBI and Crossref |
| `R/24_compile_latex.R` | compile the LaTeX manuscript |
| `R/25_build_full_docx.R` | build the Word manuscript |

`R/10_validate_palette.R` validates the figure palette against a white print surface for
color vision deficiency separation, contrast, and monotonic lightness under grayscale
printing. The chosen ramp clears all four gates.

## What is deliberately excluded

- `data_private/` — patient level data under the DUA
- `results/models.rds` — fitted `glm` objects retain the full model frame, 136,236 rows
  per model, and are therefore patient level
- reference PDFs and their extracted text — copyrighted, obtained via institutional access

Unit level aggregates in `results/` and `submission/supplementary/` contain no patient
level information and are safe to share.

## Environment

R 4.6.0 with `data.table`, `ggplot2`, `patchwork`, `lme4`, `sandwich`, `lmtest`, `pROC`,
`cobalt`, `WeightIt`, `officer`, `flextable`, `magick`, `httr`, `jsonlite`, `colorspace`.
LaTeX via TinyTeX. BigQuery access via the Google Cloud SDK.

## Reproducibility notes

Decision thresholds for the feasibility probes were fixed before the corresponding
analyses were run and are recorded in `sql/01_feasibility_probe.sql`. The study question
was refined during exploratory work; an initial framing around malignancy was abandoned
when malignancy proved to add nothing to prediction. This is disclosed in the manuscript
under protocol registration.

Every reference was resolved against NCBI E-utilities or Crossref. A title search pass
returned the wrong article for four references, which were detected by reading the
returned titles and removed. `R/20_prune_bad_bib.R` records that correction.

## License

Code released under the MIT License. The manuscript and figures are the author's work.
No eICU data are included under any license.
