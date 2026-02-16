param(
  [switch]$SkipPubGet,
  [switch]$AnalyzeArm64
)

$ErrorActionPreference = 'Stop'

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

if (-not $SkipPubGet) {
  flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get fallo.'
  }
}

Write-Host 'Construyendo release APK split-per-abi...'
flutter build apk --release --split-per-abi
if ($LASTEXITCODE -ne 0) {
  throw 'flutter build apk --release --split-per-abi fallo.'
}

$outDir = Join-Path $repoRoot 'build\app\outputs\flutter-apk'
if (-not (Test-Path $outDir)) {
  throw "No existe output esperado: $outDir"
}

$apkFiles = Get-ChildItem -Path $outDir -File -Filter 'app-*-release.apk' |
  Where-Object { $_.Name -notlike 'app-release.apk' } |
  Sort-Object Name

if ($apkFiles.Count -eq 0) {
  throw 'No se encontraron APKs split por ABI.'
}

Write-Host ''
Write-Host 'APKs generados:'
foreach ($apk in $apkFiles) {
  $sizeMb = [math]::Round($apk.Length / 1MB, 2)
  Write-Host ("  {0}  ({1} MB)" -f $apk.Name, $sizeMb)
}

$universalApk = Join-Path $outDir 'app-release.apk'
if (Test-Path $universalApk) {
  $universalInfo = Get-Item $universalApk
  $universalMb = [math]::Round($universalInfo.Length / 1MB, 2)
  Write-Host ''
  Write-Host ("Referencia universal: app-release.apk ({0} MB)" -f $universalMb)
}

if ($AnalyzeArm64) {
  Write-Host ''
  Write-Host 'Ejecutando analisis de tamano arm64 (--analyze-size)...'
  flutter build apk --release --target-platform android-arm64 --analyze-size
  if ($LASTEXITCODE -ne 0) {
    throw 'Analisis arm64 fallo.'
  }
}

Write-Host ''
Write-Host 'Listo. Usa los APKs split para distribucion directa fuera de Play Store.'
Write-Host 'Para Play Store, preferir AAB: flutter build appbundle --release'
