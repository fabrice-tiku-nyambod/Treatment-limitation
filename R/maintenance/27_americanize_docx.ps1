# ---------------------------------------------------------------------------
# 27_americanize_docx.ps1
#
# Converts British spellings inside Manuscript.docx WITHOUT rebuilding it, so
# hand-applied formatting (1.15 line spacing and any other edits) is preserved.
#
# Uses .NET ZipArchive in Update mode, which rewrites only the changed entry.
# A full unzip-and-rezip corrupts the package, because [Content_Types].xml
# contains glob metacharacters that the zip tooling does not round-trip.
#
# Pairs are held in an array, not a hashtable. PowerShell hashtable keys are
# case-insensitive, so 'standardised' and 'Standardised' would collide.
# ---------------------------------------------------------------------------

$doc = "C:\Users\tikuf\Desktop\ICU-CodeStatus-Paper\submission\Manuscript.docx"
$bak = "$doc.bak"

if (-not (Test-Path $doc)) { throw "not found: $doc" }
Copy-Item $doc $bak -Force
Write-Host "backup written to Manuscript.docx.bak"

$pairs = @(
  @('standardisation','standardization'), @('Standardisation','Standardization'),
  @('standardised','standardized'),       @('Standardised','Standardized'),
  @('randomised','randomized'),           @('Randomised','Randomized'),
  @('characterised','characterized'),     @('Characterised','Characterized'),
  @('analysed','analyzed'),               @('Analysed','Analyzed'),
  @('recognised','recognized'),           @('Recognised','Recognized'),
  @('summarised','summarized'),           @('Summarised','Summarized'),
  @('hypothesised','hypothesized'),       @('Hypothesised','Hypothesized'),
  @('equalised','equalized'),             @('normalised','normalized'),
  @('minimised','minimized'),             @('generalisation','generalization'),
  @('utilised','utilized'),               @('organised','organized'),
  @('emphasised','emphasized'),           @('penalises','penalizes'),
  @('penalised','penalized'),             @('Penalised','Penalized'),
  @('modelling','modeling'),              @('Modelling','Modeling'),
  @('modelled','modeled'),                @('Modelled','Modeled'),
  @('labelled','labeled'),                @('Labelled','Labeled'),
  @('panelled','paneled'),                @('cancelled','canceled'),
  @('behaviour','behavior'),              @('Behaviour','Behavior'),
  @('favourable','favorable'),            @('colours','colors'),
  @('colour','color'),                    @('Colour','Color'),
  @('centres','centers'),                 @('Centres','Centers'),
  @('centre','center'),                   @('Centre','Center'),
  @('licence','license'),                 @('defence','defense'),
  @('judgement','judgment'),              @('ageing','aging'),
  @('artefacts','artifacts'),             @('artefact','artifact'),
  @('haematologic','hematologic'),        @('Haematologic','Hematologic'),
  @('tumours','tumors'),                  @('tumour','tumor'),
  @('Tumour','Tumor'),                    @('leukaemia','leukemia'),
  @('Leukaemia','Leukemia'),              @('anaemia','anemia'),
  @('oedema','edema'),                    @('programmes','programs'),
  @('programme','program'),               @('Programme','Program'),
  @('greyscale','grayscale'),             @('practise','practice')
)

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$zip = [System.IO.Compression.ZipFile]::Open($doc, 'Update')
$total = 0
try {
  $targets = $zip.Entries | Where-Object {
    $_.FullName -match '^word/(document|footnotes|endnotes|header\d*|footer\d*)\.xml$'
  }
  foreach ($entry in $targets) {
    $sr = New-Object System.IO.StreamReader($entry.Open())
    $xml = $sr.ReadToEnd(); $sr.Close()

    $n = 0
    foreach ($p in $pairs) {
      $c = ([regex]::Matches($xml, [regex]::Escape($p[0]))).Count
      if ($c -gt 0) { $xml = $xml.Replace($p[0], $p[1]); $n += $c }
    }
    if ($n -gt 0) {
      $st = $entry.Open(); $st.SetLength(0)
      $sw = New-Object System.IO.StreamWriter($st, (New-Object System.Text.UTF8Encoding($false)))
      $sw.Write($xml); $sw.Flush(); $sw.Close(); $st.Close()
      Write-Host ("  {0,-26} {1,3} replacements" -f $entry.FullName, $n)
      $total += $n
    }
  }
} finally { $zip.Dispose() }

Write-Host ""
Write-Host "total replacements: $total"

# verify the package still opens and no British spellings remain
$check = [System.IO.Compression.ZipFile]::OpenRead($doc)
$de = $check.Entries | Where-Object { $_.FullName -eq 'word/document.xml' }
if (-not $de) { $check.Dispose(); Copy-Item $bak $doc -Force; throw "verification failed, restored from backup" }
$sr = New-Object System.IO.StreamReader($de.Open()); $body = $sr.ReadToEnd(); $sr.Close()
$check.Dispose()

$left = @()
foreach ($p in $pairs) { if ($body.Contains($p[0])) { $left += $p[0] } }
if ($left.Count -gt 0) {
  Write-Host ("REMAINING: " + ($left -join ', '))
} else {
  Write-Host "docx verified: readable, no British spellings remain"
}
