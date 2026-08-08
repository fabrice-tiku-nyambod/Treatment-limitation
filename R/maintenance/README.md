# Maintenance scripts

One-time operations already applied to the files committed in this repository.
They are kept for provenance, not because they need running again. Running them
a second time is either a no-op or will corrupt something.

## Reference verification

| Script | What it did |
|---|---|
| `18_verify_references.R` | Resolved 45 references to a PMID and pulled the authoritative record from NCBI E-utilities |
| `19_verify_remaining.R` | Title search for the 11 that had no identifier |
| `20_prune_bad_bib.R` | **Removed four entries that were the wrong paper.** The title search in script 19 returned a dental hygiene retraction study for a code status citation, among others. They looked structurally perfect and were caught only by printing the returned titles and reading them |
| `21_complete_bib.R` | Added the seven references verified individually against Crossref or the publisher record |
| `22_drop_unsourced_refs.R` | Removed six references the author could not source, and repaired the sentences that depended on them |
| `30_renumber_bib.R` | Renumbered keys to order of first citation |

The lesson from script 20 is recorded because it matters: PubMed relevance
ranking does not guarantee a title match. Any reference found by search must
have its returned title read and confirmed before use.

## Document surgery

| Script | What it did |
|---|---|
| `26_americanize.R` | British to American spelling across markdown, LaTeX and R sources |
| `27_americanize_docx.ps1` | Same, inside the Word file, in place via ZipArchive Update mode so manual formatting survives |
| `28_renumber.R` | Renumbered references to order of first appearance, moved three display items to the supplement |
| `31_restructure_tex_v2.R` | Rebuilt the LaTeX Tables and Figures sections. Two earlier attempts failed because a regex spanning `\begin`..`\end` always anchored on the first environment in the file |
| `33_split_supplement_tex.R` | Split the supplement into a standalone document |
| `34_number_headings.ps1` | Numbered the main section headings, in place |
| `36_sync_tex_content.R` | Brought the LaTeX back in line with the markdown |
| `23_fix_latex_bib.R` | Switched from a hand written bibliography to the verified `.bib` |

## Exploration

| Script | What it did |
|---|---|
| `10b_palette_search.R` | Searched 224 palette candidates for one clearing all four colour gates against a white print surface |

## Still useful

Two of these are worth running after any rebuild of the Word manuscript, since
the builder writes British spelling and unnumbered headings:

```
powershell -File R/maintenance/27_americanize_docx.ps1
powershell -File R/maintenance/34_number_headings.ps1
```

Both edit the document in place and preserve manual formatting such as line
spacing.
