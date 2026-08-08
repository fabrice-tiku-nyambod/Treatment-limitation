# ---------------------------------------------------------------------------
# 34_number_headings.ps1
#
# Numbers the main section headings across the markdown, the LaTeX and the
# Word file. The Abstract stays unnumbered, which is conventional.
#
#   1. Introduction   2. Methods   3. Results   4. Discussion   5. Declarations
#
# The Word file is edited in place through ZipArchive Update mode, so no
# formatting is touched. Subsection headings are left alone.
# ---------------------------------------------------------------------------

$proj = "C:\Users\tikuf\Desktop\ICU-CodeStatus-Paper"
$sub  = "$proj\submission"

$heads = @(
  @('Introduction','1. Introduction'),
  @('Methods','2. Methods'),
  @('Results','3. Results'),
  @('Discussion','4. Discussion'),
  @('Declarations','5. Declarations')
)

# --- markdown ---------------------------------------------------------------
$md = "$proj\MANUSCRIPT_v4.md"
$t  = Get-Content $md -Raw
$n = 0
foreach ($h in $heads) {
  $from = "## $($h[0])"
  if ($t -match [regex]::Escape($from) + "\r?\n") {
    $t = $t -replace ("(?m)^" + [regex]::Escape($from) + "$"), "## $($h[1])"
    $n++
  }
}
Set-Content $md -Value $t -Encoding UTF8 -NoNewline
Write-Host "markdown: $n headings numbered"

# --- LaTeX ------------------------------------------------------------------
$tex = "$sub\Manuscript.tex"
$t = Get-Content $tex -Raw
$n = 0
foreach ($h in $heads) {
  $from = "\section*{$($h[0])}"
  if ($t.Contains($from)) { $t = $t.Replace($from, "\section*{$($h[1])}"); $n++ }
}
Set-Content $tex -Value $t -Encoding UTF8 -NoNewline
Write-Host "latex: $n headings numbered"

# --- Word, in place ---------------------------------------------------------
$doc = "$sub\Manuscript.docx"
Copy-Item $doc "$doc.bak" -Force
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::Open($doc, 'Update')
$n = 0
try {
  $entry = $zip.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
  $sr = New-Object System.IO.StreamReader($entry.Open())
  $xml = $sr.ReadToEnd(); $sr.Close()

  foreach ($h in $heads) {
    # match the heading only where it is the whole run, so body prose that
    # happens to contain the word is left alone
    $from = ">$($h[0])</w:t>"
    $to   = ">$($h[1])</w:t>"
    $c = ([regex]::Matches($xml, [regex]::Escape($from))).Count
    if ($c -gt 0) { $xml = $xml.Replace($from, $to); $n += $c }
  }
  if ($n -gt 0) {
    $st = $entry.Open(); $st.SetLength(0)
    $sw = New-Object System.IO.StreamWriter($st, (New-Object System.Text.UTF8Encoding($false)))
    $sw.Write($xml); $sw.Flush(); $sw.Close(); $st.Close()
  }
} finally { $zip.Dispose() }
Write-Host "word: $n headings numbered"

# verify the package still opens
$chk = [System.IO.Compression.ZipFile]::OpenRead($doc)
$ok = ($chk.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }).Count -eq 1
$chk.Dispose()
if ($ok) { Write-Host "docx verified readable" }
else { Copy-Item "$doc.bak" $doc -Force; throw "docx failed, restored from backup" }
