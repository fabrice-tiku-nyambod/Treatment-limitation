# ---------------------------------------------------------------------------
# 26_americanize.R
# Converts manuscript prose to American English spelling.
#
# references.bib is deliberately excluded. Its titles and journal names come
# from PubMed and Crossref and must stay exactly as published, even where they
# use British spelling.
# ---------------------------------------------------------------------------

proj <- "C:/Users/tikuf/Desktop/ICU-CodeStatus-Paper"

subs <- c(
  # -ise / -isation families
  "standardised"      = "standardized",
  "Standardised"      = "Standardized",
  "standardisation"   = "standardization",
  "Standardisation"   = "Standardization",
  "randomised"        = "randomized",
  "Randomised"        = "Randomized",
  "characterised"     = "characterized",
  "Characterised"     = "Characterized",
  "analysed"          = "analyzed",
  "Analysed"          = "Analyzed",
  "recognised"        = "recognized",
  "Recognised"        = "Recognized",
  "summarised"        = "summarized",
  "Summarised"        = "Summarized",
  "hypothesised"      = "hypothesized",
  "Hypothesised"      = "Hypothesized",
  "equalised"         = "equalized",
  "Equalised"         = "Equalized",
  "normalised"        = "normalized",
  "minimised"         = "minimized",
  "generalisation"    = "generalization",
  "Generalisation"    = "Generalization",
  "utilised"          = "utilized",
  "organised"         = "organized",
  "emphasised"        = "emphasized",
  "penalises"         = "penalizes",
  "penalised"         = "penalized",
  "Penalised"         = "Penalized",
  "prioritise"        = "prioritize",
  # doubled consonant before suffix
  "modelling"         = "modeling",
  "Modelling"         = "Modeling",
  "modelled"          = "modeled",
  "Modelled"          = "Modeled",
  "labelled"          = "labeled",
  "Labelled"          = "Labeled",
  "cancelled"         = "canceled",
  "signalling"        = "signaling",
  # -our
  "behaviour"         = "behavior",
  "Behaviour"         = "Behavior",
  "favourable"        = "favorable",
  "colour"            = "color",
  "Colour"            = "Color",
  "colours"           = "colors",
  # -re
  "centre"            = "center",
  "Centre"            = "Center",
  "centres"           = "centers",
  "Centres"           = "Centers",
  # misc
  "licence"           = "license",
  "Licence"           = "License",
  "defence"           = "defense",
  "judgement"         = "judgment",
  "Judgement"         = "Judgment",
  "ageing"            = "aging",
  "fulfil"            = "fulfill",
  "enrol"             = "enroll",
  "practise"          = "practice",
  "artefact"          = "artifact",
  "Artefact"          = "Artifact",
  "artefacts"         = "artifacts",
  "haematologic"      = "hematologic",
  "Haematologic"      = "Hematologic",
  "haematological"    = "hematological",
  "haemodynamic"      = "hemodynamic",
  "haemorrhage"       = "hemorrhage",
  "tumour"            = "tumor",
  "Tumour"            = "Tumor",
  "tumours"           = "tumors",
  "leukaemia"         = "leukemia",
  "Leukaemia"         = "Leukemia",
  "anaemia"           = "anemia",
  "oedema"            = "edema",
  "oesophag"          = "esophag",
  "paediatric"        = "pediatric",
  "anaesthe"          = "anesthe",
  "diarrhoea"         = "diarrhea",
  "greyscale"         = "grayscale",
  "Greyscale"         = "Grayscale",
  "programme"         = "program",
  "Programme"         = "Program",
  "programmes"        = "programs"
)

targets <- c("MANUSCRIPT_v4.md", "README.md", "RESULTS_SUMMARY.md",
             "ANALYSIS_PLAN.md", "REFERENCES.md",
             "submission/Manuscript.tex")

total <- 0
for (f in targets) {
  p <- file.path(proj, f)
  if (!file.exists(p)) { cat(sprintf("  %-28s missing\n", f)); next }
  s <- paste(readLines(p, warn = FALSE, encoding = "UTF-8"), collapse = "\n")
  n <- 0
  for (k in names(subs)) {
    hits <- lengths(regmatches(s, gregexpr(k, s, fixed = TRUE)))
    if (hits > 0) { s <- gsub(k, subs[[k]], s, fixed = TRUE); n <- n + hits }
  }
  if (n > 0) writeLines(strsplit(s, "\n")[[1]], p, useBytes = TRUE)
  cat(sprintf("  %-28s %3d replacements\n", f, n))
  total <- total + n
}
cat(sprintf("\ntotal: %d\n", total))
cat("references.bib untouched, published titles preserved\n")

# report any British spellings still present in the manuscript
s <- paste(readLines(file.path(proj, "MANUSCRIPT_v4.md"), warn = FALSE), collapse = " ")
left <- names(subs)[sapply(names(subs), function(k) grepl(k, s, fixed = TRUE))]
if (length(left)) {
  cat(sprintf("REMAINING: %s\n", paste(left, collapse = ", ")))
} else {
  cat("manuscript clean\n")
}
