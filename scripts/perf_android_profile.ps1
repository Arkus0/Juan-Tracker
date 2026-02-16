param(
  [string]$DeviceId = '',
  [switch]$SkipPubGet
)

$ErrorActionPreference = 'Stop'

function Resolve-AndroidDeviceId {
  $devicesJson = flutter devices --machine | Out-String
  $devices = $devicesJson | ConvertFrom-Json
  $android = $devices |
    Where-Object { $_.targetPlatform -like 'android-*' } |
    Select-Object -First 1

  if (-not $android) {
    throw 'No se encontro dispositivo Android. Inicia un emulador o conecta un telefono.'
  }

  return $android.id
}

function Print-StartupSummary {
  param([string]$StartupJsonPath)

  try {
    $json = Get-Content -Raw -Encoding UTF8 $StartupJsonPath | ConvertFrom-Json
    Write-Host ''
    Write-Host 'Resumen startup:'
    $json.PSObject.Properties | ForEach-Object {
      Write-Host ("  {0}: {1}" -f $_.Name, $_.Value)
    }
  } catch {
    Write-Warning "No se pudo parsear $StartupJsonPath"
  }
}

$repoRoot = Resolve-Path (Join-Path $PSScriptRoot '..')
Set-Location $repoRoot

if (-not $SkipPubGet) {
  flutter pub get
  if ($LASTEXITCODE -ne 0) {
    throw 'flutter pub get fallo.'
  }
}

if ([string]::IsNullOrWhiteSpace($DeviceId)) {
  $DeviceId = Resolve-AndroidDeviceId
}

$timestamp = Get-Date -Format 'yyyyMMdd_HHmmss'
$outDir = Join-Path $repoRoot 'build\perf'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null

$startupLog = Join-Path $outDir "startup_run_$timestamp.log"

Write-Host "Usando dispositivo: $DeviceId"
Write-Host "Log startup: $startupLog"
Write-Host ''
Write-Host 'Ejecutando startup profile (--trace-startup)...'

flutter run -d $DeviceId --profile --trace-startup --no-resident *>&1 |
  Tee-Object -FilePath $startupLog

$runExit = $LASTEXITCODE
if ($runExit -ne 0) {
  Write-Warning "flutter run termino con codigo $runExit"
}

$startupFiles = Get-ChildItem -Path (Join-Path $repoRoot 'build') -Recurse -File -Filter 'start_up_info*.json' |
  Sort-Object LastWriteTime -Descending

if ($startupFiles.Count -gt 0) {
  $latest = $startupFiles[0]
  $copyPath = Join-Path $outDir "start_up_info_$timestamp.json"
  Copy-Item -Path $latest.FullName -Destination $copyPath -Force
  Write-Host "Startup JSON copiado a: $copyPath"
  Print-StartupSummary -StartupJsonPath $copyPath
} else {
  Write-Warning 'No se encontro start_up_info*.json. Revisa el log de startup.'
}

Write-Host ''
Write-Host 'Siguiente paso para jank/frame-time (manual):'
Write-Host "  flutter run -d $DeviceId --profile --trace-skia"
Write-Host 'Luego abre DevTools > Performance y recorre: Diario, Busqueda de alimentos, Entrenamiento.'

if ($runExit -ne 0 -and $startupFiles.Count -eq 0) {
  exit $runExit
}
