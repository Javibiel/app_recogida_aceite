$ErrorActionPreference = "Stop"

$root = Resolve-Path (Join-Path $PSScriptRoot "..")
$html = Join-Path $root "docs\tfg_serrma_memoria.html"
$pdf = Join-Path $root "docs\TFG_SERRMA_memoria_app.pdf"
$tempPdf = Join-Path $root "docs\TFG_SERRMA_memoria_app.tmp.pdf"
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
  if (Test-Path $tempPdf) {
    Remove-Item -LiteralPath $tempPdf -Force
  }

  $htmlUri = (New-Object System.Uri($html)).AbsoluteUri
  & $chrome `
    --headless `
    --disable-gpu `
    --no-sandbox `
    --disable-crash-reporter `
    --disable-breakpad `
    --user-data-dir="$profile" `
    --print-to-pdf="$tempPdf" `
    "$htmlUri"

  for ($attempt = 1; $attempt -le 20 -and -not (Test-Path $tempPdf); $attempt++) {
    Start-Sleep -Milliseconds 250
  }

  if (-not (Test-Path $tempPdf)) {
    throw "No se pudo generar el PDF temporal."
  }

  Move-Item -LiteralPath $tempPdf -Destination $pdf -Force
} finally {
  if (Test-Path $tempPdf) {
    Remove-Item -LiteralPath $tempPdf -Force -ErrorAction SilentlyContinue
  }

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
