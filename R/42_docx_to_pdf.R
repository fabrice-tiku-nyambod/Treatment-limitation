# ---------------------------------------------------------------------------
# 42_docx_to_pdf.R
#
# Exports the Word manuscript and supplement to PDF through Microsoft Word,
# so the PDF is always the same document the journal receives. Replaces the
# earlier LaTeX build, which had to be kept in sync with the markdown by hand.
# Skips quietly if Word is not installed.
# ---------------------------------------------------------------------------

proj <- normalizePath(".", winslash = "/")   # run from the project root
sub  <- file.path(proj, "submission_jicm")

ps <- file.path(tempdir(), "docx_to_pdf.ps1")
writeLines(c(
  '$files = $args',
  'try { $w = New-Object -ComObject Word.Application } catch { Write-Output "Word not available"; exit 0 }',
  '$w.Visible = $false',
  'foreach ($f in $files) {',
  '  $d = $w.Documents.Open($f, $false, $true)',
  '  $pdf = [System.IO.Path]::ChangeExtension($f, ".pdf")',
  '  $d.ExportAsFixedFormat($pdf, 17)   # 17 = wdExportFormatPDF',
  '  $d.Close($false)',
  '  Write-Output ("wrote " + $pdf)',
  '}',
  '$w.Quit()'), ps)

docs <- normalizePath(file.path(sub, c("Manuscript.docx", "Supplementary_Material.docx",
                                       "Cover_Letter.docx", "EQUATOR_Checklists.docx",
                                       "COI_Declaration.docx")), winslash = "\\", mustWork = FALSE)
docs <- docs[file.exists(docs)]
out <- system2("powershell", c("-NoProfile", "-ExecutionPolicy", "Bypass", "-File",
                               shQuote(ps), shQuote(docs)), stdout = TRUE)
cat(out, sep = "\n")
