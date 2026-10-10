# ---------------------------------------------------------------------------
# 43_strobe_checklist.R
#
# EQUATOR Network reporting checklists as one Word supplement: STROBE for the
# cohort study and TRIPOD for the assessment of the APACHE IVa model, each item
# mapped to the section and page of the final Manuscript.pdf. Page numbers are
# read from the PDF, so rebuild this after any change to the manuscript.
# ---------------------------------------------------------------------------

suppressPackageStartupMessages({ library(officer); library(flextable); library(data.table) })

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")
FONT <- "Times New Roman"

# --- page map from the final PDF ---------------------------------------------
txt <- pdftools::pdf_text(file.path(sub, "Manuscript.pdf"))
pg <- function(pattern, nth = 1) {
  p <- which(grepl(pattern, txt, fixed = TRUE))
  if (length(p) < nth) NA_integer_ else p[nth]
}
P <- list(
  abstract = pg("Abstract"), intro = pg("1. Introduction"), methods = pg("2. Methods"),
  design = pg("Study design and reporting"), data = pg("Data source"), cohort = pg("Cohort"),
  exposure = pg("Exposure"), timing_m = pg("Timing of limitation orders", 1), outcome = pg("Outcome"),
  stats = pg("Statistical analysis"), results = pg("3. Results"),
  calib = pg("APACHE IVa calibration depends"), variation = pg("Variation between units"),
  bench = pg("Consequences for benchmarking"), remedy = pg("A simpler remedy"),
  timing_r = pg("Timing of limitation orders", 2), discussion = pg("4. Discussion"),
  implications = pg("Implications"), limitations = pg("Limitations"), conclusion = pg("5. Conclusion"),
  declarations = pg("Statements and Declarations"), tables = pg("Tables", 2), legends = pg("Figure legends"))
loc <- function(section, key) sprintf("%s, p. %s", section, P[[key]])

# --- STROBE, cohort studies ---------------------------------------------------
strobe <- rbindlist(list(
  list("Title and abstract", "1a", "Indicate the study's design with a commonly used term in the title or the abstract", paste0(loc("Abstract", "abstract"), "; ", loc("Methods", "design"))),
  list("Title and abstract", "1b", "Provide in the abstract an informative and balanced summary of what was done and what was found", loc("Abstract", "abstract")),
  list("Background/rationale", "2", "Explain the scientific background and rationale for the investigation being reported", loc("Introduction", "intro")),
  list("Objectives", "3", "State specific objectives, including any prespecified hypotheses", sprintf("Introduction, final paragraph, p. %s", P$intro + 2)),
  list("Study design", "4", "Present key elements of study design early in the paper", loc("Methods, Study design and reporting", "design")),
  list("Setting", "5", "Describe the setting, locations, and relevant dates, including periods of recruitment, exposure, follow-up, and data collection", loc("Methods, Data source", "data")),
  list("Participants", "6a", "Give the eligibility criteria, and the sources and methods of selection of participants. Describe methods of follow-up", paste0(loc("Methods, Cohort", "cohort"), "; Figure S1")),
  list("Participants", "6b", "For matched studies, give matching criteria and number of exposed and unexposed", "Not applicable"),
  list("Variables", "7", "Clearly define all outcomes, exposures, predictors, potential confounders, and effect modifiers. Give diagnostic criteria, if applicable", paste0(loc("Methods, Exposure", "exposure"), "; ", loc("Timing of limitation orders", "timing_m"), "; ", loc("Outcome", "outcome"))),
  list("Data sources/measurement", "8", "For each variable of interest, give sources of data and details of methods of assessment (measurement). Describe comparability of assessment methods if there is more than one group", paste0(loc("Methods, Data source", "data"), "; ", loc("Exposure", "exposure"))),
  list("Bias", "9", "Describe any efforts to address potential sources of bias", paste0(loc("Methods, Timing of limitation orders", "timing_m"), "; ", loc("Statistical analysis", "stats"))),
  list("Study size", "10", "Explain how the study size was arrived at", loc("Methods, Cohort", "cohort")),
  list("Quantitative variables", "11", "Explain how quantitative variables were handled in the analyses. If applicable, describe which groupings were chosen and why", paste0(loc("Methods, Exposure", "exposure"), "; ", loc("Timing of limitation orders", "timing_m"))),
  list("Statistical methods", "12a", "Describe all statistical methods, including those used to control for confounding", loc("Methods, Statistical analysis", "stats")),
  list("Statistical methods", "12b", "Describe any methods used to examine subgroups and interactions", sprintf("Methods, Statistical analysis, p. %s", P$stats + 1)),
  list("Statistical methods", "12c", "Explain how missing data were addressed", sprintf("Methods, Statistical analysis, final paragraph, p. %s", P$stats + 1)),
  list("Statistical methods", "12d", "If applicable, explain how loss to follow-up was addressed", "Not applicable; in hospital outcome"),
  list("Statistical methods", "12e", "Describe any sensitivity analyses", paste0(sprintf("Methods, Statistical analysis, p. %s", P$stats + 1), "; ", loc("Results, A simpler remedy", "remedy"), "; ", loc("Timing of limitation orders", "timing_r"))),
  list("Participants", "13a", "Report numbers of individuals at each stage of study", paste0(loc("Methods, Cohort", "cohort"), "; Figure S1")),
  list("Participants", "13b", "Give reasons for non-participation at each stage", paste0(loc("Methods, Cohort", "cohort"), "; Figure S1")),
  list("Participants", "13c", "Consider use of a flow diagram", "Figure S1"),
  list("Descriptive data", "14a", "Give characteristics of study participants and information on exposures and potential confounders", paste0(loc("Results, Cohort", "results"), "; Table 1, p. ", P$tables)),
  list("Descriptive data", "14b", "Indicate number of participants with missing data for each variable of interest", paste0(sprintf("Methods, Statistical analysis, p. %s", P$stats + 1), "; ", loc("Results, Cohort", "results"))),
  list("Descriptive data", "14c", "Summarise follow-up time", "Not applicable; in hospital outcome"),
  list("Outcome data", "15", "Report numbers of outcome events or summary measures over time", paste0(loc("Results, Cohort", "results"), "; Table 2, p. ", P$tables + 1, "; Table S6")),
  list("Main results", "16a", "Give unadjusted estimates and, if applicable, confounder-adjusted estimates and their precision. Make clear which confounders were adjusted for and why they were included", sprintf("Results, pp. %s to %s; Tables 2 and 3; Figures 1 to 3", P$results, P$discussion - 1)),
  list("Main results", "16b", "Report category boundaries when continuous variables were categorized", paste0(loc("Methods, Exposure", "exposure"), "; ", loc("Timing of limitation orders", "timing_m"))),
  list("Main results", "16c", "If relevant, consider translating estimates of relative risk into absolute risk for a meaningful time period", loc("Results, Consequences for benchmarking", "bench")),
  list("Other analyses", "17", "Report other analyses done, such as analyses of subgroups and interactions, and sensitivity analyses", paste0(loc("Results, A simpler remedy", "remedy"), "; ", loc("Timing of limitation orders", "timing_r"), "; Tables S6 and S7")),
  list("Key results", "18", "Summarise key results with reference to study objectives", loc("Discussion, first paragraph", "discussion")),
  list("Limitations", "19", "Discuss limitations of the study, taking into account sources of potential bias or imprecision. Discuss both direction and magnitude of any potential bias", loc("Discussion, Limitations", "limitations")),
  list("Interpretation", "20", "Give a cautious overall interpretation of results considering objectives, limitations, multiplicity of analyses, results from similar studies, and other relevant evidence", sprintf("Discussion, pp. %s to %s", P$discussion, P$conclusion - 1)),
  list("Generalisability", "21", "Discuss the generalisability (external validity) of the study results", paste0(loc("Discussion, Implications", "implications"), "; ", loc("Limitations", "limitations"))),
  list("Funding", "22", "Give the source of funding and the role of the funders for the present study", loc("Statements and Declarations, Funding", "declarations"))))
setnames(strobe, c("Section", "Item", "Recommendation", "Reported in"))

# --- TRIPOD, validation of an existing model ---------------------------------
tripod <- rbindlist(list(
  list("Title", "1", "Identify the study as developing and/or validating a multivariable prediction model, the target population, and the outcome to be predicted", "Title, p. 1; Abstract, p. 2"),
  list("Abstract", "2", "Provide a summary of objectives, study design, setting, participants, sample size, predictors, outcome, statistical analysis, results, and conclusions", loc("Abstract", "abstract")),
  list("Background", "3a", "Explain the medical context and rationale for validating the model, including references to existing models", loc("Introduction", "intro")),
  list("Objectives", "3b", "Specify the objectives, including whether the study describes development or validation of the model", sprintf("Introduction, final paragraph, p. %s", P$intro + 2)),
  list("Source of data", "4a", "Describe the study design or source of data, separately for the development and validation data sets", loc("Methods, Data source", "data")),
  list("Source of data", "4b", "Specify the key study dates, including start of accrual, end of accrual, and end of follow-up", loc("Methods, Data source", "data")),
  list("Participants", "5a", "Specify key elements of the study setting including number and location of centres", loc("Methods, Data source", "data")),
  list("Participants", "5b", "Describe eligibility criteria for participants", loc("Methods, Cohort", "cohort")),
  list("Participants", "5c", "Give details of treatments received, if relevant", paste0(loc("Methods, Exposure", "exposure"), " (treatment limitation)")),
  list("Outcome", "6a", "Clearly define the outcome that is predicted by the prediction model, including how and when assessed", loc("Methods, Outcome", "outcome")),
  list("Outcome", "6b", "Report any actions to blind assessment of the outcome to be predicted", "Not applicable; outcome recorded in the database"),
  list("Predictors", "7a", "Clearly define all predictors used in developing or validating the model, including how and when they were measured", paste0(sprintf("Introduction, p. %s", P$intro + 1), " (APACHE IVa covariates); ", loc("Methods, Exposure", "exposure"))),
  list("Predictors", "7b", "Report any actions to blind assessment of predictors for the outcome and other predictors", "Not applicable; predictions recorded prospectively in the database"),
  list("Sample size", "8", "Explain how the study size was arrived at", loc("Methods, Cohort", "cohort")),
  list("Missing data", "9", "Describe how missing data were handled with details of any imputation method", sprintf("Methods, Statistical analysis, final paragraph, p. %s", P$stats + 1)),
  list("Statistical analysis", "10c", "For validation, describe how the predictions were calculated", paste0(loc("Methods, Outcome", "outcome"), "; ", loc("Statistical analysis", "stats"))),
  list("Statistical analysis", "10d", "Specify all measures used to assess model performance and, if relevant, to compare multiple models", loc("Methods, Statistical analysis", "stats")),
  list("Statistical analysis", "10e", "Describe any model updating (e.g., recalibration) arising from the validation, if done", loc("Methods, Statistical analysis", "stats")),
  list("Risk groups", "11", "Provide details on how risk groups were created, if done", "Not applicable"),
  list("Development vs validation", "12", "For validation, identify any differences from the development data in setting, eligibility criteria, outcome, and predictors", sprintf("Introduction, p. %s; Methods, Data source, p. %s", P$intro + 1, P$data)),
  list("Participants", "13a", "Describe the flow of participants through the study, including the number with and without the outcome and a summary of follow-up time", paste0(loc("Methods, Cohort", "cohort"), "; ", loc("Results, Cohort", "results"), "; Figure S1")),
  list("Participants", "13b", "Describe the characteristics of the participants, including the number with missing data for predictors and outcome", paste0(loc("Results, Cohort", "results"), "; Table 1, p. ", P$tables)),
  list("Participants", "13c", "For validation, show a comparison with the development data of the distribution of important variables", sprintf("Introduction, p. %s (development cohort); Table 1, p. %s", P$intro + 1, P$tables)),
  list("Model development", "14a, 14b, 15a, 15b", "Development studies only", "Not applicable; validation of an existing model"),
  list("Model performance", "16", "Report performance measures (with confidence intervals) for the prediction model", paste0(loc("Results, APACHE IVa calibration", "calib"), "; Table 2, p. ", P$tables + 1, "; Figure 1; Tables S1 and S6")),
  list("Model updating", "17", "If done, report the results from any model updating (i.e., model specification, model performance)", paste0(loc("Results, APACHE IVa calibration", "calib"), "; ", loc("Consequences for benchmarking", "bench"))),
  list("Limitations", "18", "Discuss any limitations of the study (such as nonrepresentative sample, few events per predictor, missing data)", loc("Discussion, Limitations", "limitations")),
  list("Interpretation", "19a", "For validation, discuss the results with reference to performance in the development data, and any other validation data", sprintf("Discussion, pp. %s to %s", P$discussion, P$conclusion - 1)),
  list("Interpretation", "19b", "Give an overall interpretation of the results, considering objectives, limitations, results from similar studies, and other relevant evidence", sprintf("Discussion, pp. %s to %s; Conclusion, p. %s", P$discussion, P$conclusion - 1, P$conclusion)),
  list("Implications", "20", "Discuss the potential clinical use of the model and implications for future research", loc("Discussion, Implications", "implications")),
  list("Supplementary information", "21", "Provide information about the availability of supplementary resources, such as study protocol, Web calculator, and data sets", loc("Statements and Declarations, Data and Code availability", "declarations")),
  list("Funding", "22", "Give the source of funding and the role of the funders for the present study", loc("Statements and Declarations, Funding", "declarations"))))
setnames(tripod, c("Section", "Item", "Recommendation", "Reported in"))

# --- document ------------------------------------------------------------------
mk <- function(d) flextable(d) |>
  width(j = 1, width = 1.45) |> width(j = 2, width = 0.55) |> width(j = 3, width = 2.8) |> width(j = 4, width = 1.7) |>
  font(fontname = FONT, part = "all") |> fontsize(size = 9, part = "all") |>
  bold(part = "header") |> align(align = "left", part = "body") |> align(align = "center", part = "header") |>
  valign(valign = "top", part = "body") |>
  padding(padding.top = 2, padding.bottom = 2, part = "all") |>
  border_remove() |>
  hline_top(border = fp_border(color = "black", width = 1), part = "header") |>
  hline_bottom(border = fp_border(color = "black", width = .75), part = "header") |>
  hline_bottom(border = fp_border(color = "black", width = 1), part = "body") |>
  set_table_properties(layout = "fixed")

h1 <- fp_text(font.family = FONT, font.size = 14, bold = TRUE)
h2 <- fp_text(font.family = FONT, font.size = 12, bold = TRUE)
tx <- fp_text(font.family = FONT, font.size = 11)
TITLE <- "Treatment Limitation Documentation and Risk Adjusted Mortality Benchmarking in 190 US Intensive Care Units"

doc <- read_docx() |>
  body_add_fpar(fpar(ftext("EQUATOR Network reporting checklists", prop = h1), fp_p = fp_par(line_spacing = 1.5, padding.bottom = 4))) |>
  body_add_fpar(fpar(ftext(TITLE, prop = fp_text(font.family = FONT, font.size = 11, italic = TRUE)), fp_p = fp_par(line_spacing = 1.5, padding.bottom = 8))) |>
  body_add_fpar(fpar(ftext("Page numbers refer to the submitted manuscript. Supplementary tables and figures are in the separate supplementary file.", prop = tx), fp_p = fp_par(line_spacing = 1.15, padding.bottom = 12))) |>
  body_add_fpar(fpar(ftext("STROBE Statement: checklist of items for reports of cohort studies", prop = h2), fp_p = fp_par(line_spacing = 1.5, padding.bottom = 6))) |>
  body_add_flextable(mk(strobe)) |>
  body_add_break() |>
  body_add_fpar(fpar(ftext("TRIPOD Statement: checklist for a study validating an existing prediction model", prop = h2), fp_p = fp_par(line_spacing = 1.5, padding.bottom = 6))) |>
  body_add_flextable(mk(tripod)) |>
  body_set_default_section(prop_section(page_size = page_size(orient = "portrait"),
                                        page_margins = page_mar(top = 1, bottom = 1, left = 1, right = 1)))

out <- file.path(sub, "EQUATOR_Checklists.docx")
print(doc, target = out)
cat(sprintf("wrote EQUATOR_Checklists.docx: STROBE %d items, TRIPOD %d items\n", nrow(strobe), nrow(tripod)))
if (anyNA(unlist(P))) cat("WARNING: some section pages not found:", names(P)[is.na(unlist(P))], "\n")

# this script runs after the general PDF export, so it exports its own PDF
ps <- file.path(tempdir(), "one_pdf.ps1")
writeLines(c('try { $w = New-Object -ComObject Word.Application } catch { Write-Output "Word not available"; exit 0 }',
             '$d = $w.Documents.Open($args[0], $false, $true)',
             '$d.ExportAsFixedFormat([System.IO.Path]::ChangeExtension($args[0], ".pdf"), 17)',
             '$d.Close($false); $w.Quit(); Write-Output "wrote EQUATOR_Checklists.pdf"'), ps)
cat(system2("powershell", c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", shQuote(ps),
                            shQuote(normalizePath(out, winslash = "\\"))), stdout = TRUE), sep = "\n")
