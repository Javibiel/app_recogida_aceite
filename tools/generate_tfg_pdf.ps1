$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$html = Join-Path $root "docs\tfg_serrma_memoria.html"
$pdf = Join-Path $root "docs\TFG_SERRMA_memoria_app.pdf"
$chrome = "C:\Program Files\Google\Chrome\Application\chrome.exe"

if (-not (Test-Path $chrome)) {
  $chrome = "C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
}

if (-not (Test-Path $chrome)) {
  throw "No se encontro Chrome ni Edge para generar el PDF."
}

$profile = Join-Path $root ".chrome-pdf-profile"
New-Item -ItemType Directory -Force $profile | Out-Null

try {
  $htmlUri = (New-Object System.Uri($html)).AbsoluteUri
  & $chrome `
    --headless `
    --disable-gpu `
    --no-sandbox `
    --disable-crash-reporter `
    --disable-breakpad `
    --user-data-dir="$profile" `
    --print-to-pdf="$pdf" `
    "$htmlUri"
} finally {
  if (Test-Path $profile) {
    Start-Sleep -Milliseconds 1000
    for ($attempt = 1; $attempt -le 5; $attempt++) {
      try {
        Remove-Item -LiteralPath $profile -Recurse -Force
        break
      } catch {
        if ($attempt -eq 5) {
          Write-Warning "No se pudo eliminar el perfil temporal: $profile"
        } else {
          Start-Sleep -Milliseconds 500
        }
      }
    }
  }
}

Write-Host "PDF generado en $pdf"
