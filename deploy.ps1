<#
.SYNOPSIS
  Compila la web y la publica en GitHub Pages.

.DESCRIPTION
  Hace el pipeline de deploy en un solo paso. Existe sobre todo para dejar
  escrito UNA sola vez el flag --base-href=/cafecal/: sin el, el navegador
  pide los archivos en la raiz del dominio en vez de en /cafecal/ y la
  pagina sale en blanco (paso el 2026-10-15, cuando se compilo sin el flag).

  Pasos:
    1/7  flutter analyze
    2/7  flutter test
    3/7  leer .env (SUPABASE_URL / SUPABASE_ANON_KEY) - nunca se imprimen
    4/7  flutter build web --release --base-href=/cafecal/
    5/7  verificar base href y claves en build\web
    6/7  copiar a _deploy y pushear gh-pages   (se omite con -VerifyOnly)
    7/7  verificar que GitHub Pages sirva el bundle nuevo (sha256)

  Solo toca el repositorio gh-pages a traves de _deploy. main queda intacto.

.PARAMETER VerifyOnly
  Se detiene en el paso 5: compila y verifica sin tocar _deploy ni hacer push.
  Sirve para probar el script con seguridad.

.PARAMETER Message
  Mensaje del commit en gh-pages.

.EXAMPLE
  .\deploy.ps1 -VerifyOnly

.EXAMPLE
  .\deploy.ps1 -Message "deploy: arregla el reporte"
#>
[CmdletBinding()]
param(
  [switch]$VerifyOnly,
  [string]$Message = 'deploy: build web'
)

$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot

# Windows PowerShell 5.1 se niega a hablar TLS 1.2 por defecto en algunos
# equipos, y sin el no se puede leer GitHub Pages en el paso 7.
try {
  [Net.ServicePointManager]::SecurityProtocol =
    [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12
} catch { }

function Stop-Deploy([string]$why) {
  Write-Host ''
  Write-Host "FALLO: $why" -ForegroundColor Red
  exit 1
}

function Read-DotEnv([string]$path) {
  $table = @{}
  if (-not (Test-Path -LiteralPath $path)) { return $table }
  foreach ($line in (Get-Content -LiteralPath $path)) {
    $trimmed = $line.Trim()
    if (-not $trimmed) { continue }
    if ($trimmed.StartsWith('#')) { continue }
    $parts = $trimmed -split '=', 2
    if ($parts.Count -eq 2) { $table[$parts[0].Trim()] = $parts[1].Trim() }
  }
  return $table
}

# --- 1/7 analyze -------------------------------------------------------------

Write-Host '1/7  flutter analyze' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) { Stop-Deploy 'flutter analyze encontro problemas' }

# --- 2/7 test ----------------------------------------------------------------

Write-Host '2/7  flutter test' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) { Stop-Deploy 'flutter test fallo' }

# --- 3/7 .env ----------------------------------------------------------------

Write-Host '3/7  .env' -ForegroundColor Cyan
$vars = Read-DotEnv (Join-Path $PSScriptRoot '.env')
$supabaseUrl = $vars['SUPABASE_URL']
$supabaseKey = $vars['SUPABASE_ANON_KEY']

# Sin estas dos la app arranca en modo local y el login revienta. Los valores
# se leen aqui y solo viajan dentro de los argumentos de flutter: jamas se
# imprimen en pantalla ni en el log.
if (-not $supabaseUrl) { Stop-Deploy '.env sin SUPABASE_URL' }
if (-not $supabaseKey) { Stop-Deploy '.env sin SUPABASE_ANON_KEY' }

try {
  $projectRef = ([Uri]$supabaseUrl).Host.Split('.')[0]
} catch {
  Stop-Deploy 'SUPABASE_URL del .env no es una URL valida'
}

# flutter run y flutter build web comparten build\web. Si queda un servidor
# vivo, el build saldria sucio o directamente fallaria.
if (Get-Command Get-NetTCPConnection -ErrorAction SilentlyContinue) {
  $listening = Get-NetTCPConnection -LocalPort 8081 -State Listen -ErrorAction SilentlyContinue
  if ($listening) {
    Stop-Deploy 'el puerto 8081 esta ocupado (flutter run). Cierra ese servidor antes de desplegar.'
  }
}

# --- 4/7 build ---------------------------------------------------------------

Write-Host '4/7  flutter build web --release --base-href=/cafecal/' -ForegroundColor Cyan
$buildArgs = @(
  'build', 'web', '--release',
  '--base-href=/cafecal/',
  "--dart-define=SUPABASE_URL=$supabaseUrl",
  "--dart-define=SUPABASE_ANON_KEY=$supabaseKey"
)
& flutter @buildArgs
if ($LASTEXITCODE -ne 0) { Stop-Deploy 'flutter build web fallo' }

# --- 5/7 verificar el build --------------------------------------------------

Write-Host '5/7  verificar build' -ForegroundColor Cyan
$buildIndex = Join-Path $PSScriptRoot 'build\web\index.html'
$buildJs = Join-Path $PSScriptRoot 'build\web\main.dart.js'
if (-not (Test-Path -LiteralPath $buildIndex)) { Stop-Deploy 'no existe build\web\index.html' }
if (-not (Test-Path -LiteralPath $buildJs)) { Stop-Deploy 'no existe build\web\main.dart.js' }

$html = Get-Content -LiteralPath $buildIndex -Raw
if ($html -notmatch '<base href="/cafecal/">') {
  Stop-Deploy 'build\web\index.html no tiene <base href="/cafecal/">. Sin eso la pagina sale en blanco.'
}

$js = Get-Content -LiteralPath $buildJs -Raw
if (-not $js.Contains($projectRef)) {
  Stop-Deploy 'el bundle no contiene el project ref de Supabase: quedaria en modo local.'
}
if (-not $js.Contains($supabaseKey)) {
  Stop-Deploy 'el bundle no contiene la anon key: el login revienta.'
}

# Huella del artefacto. sirve para confirmar que lo publicado NO es el build
# anterior que quedo en la cache del navegador o del CDN.
$hash = (Get-FileHash -LiteralPath $buildJs -Algorithm SHA256).Hash
$bytes = (Get-Item -LiteralPath $buildJs).Length
$lines = ([System.IO.File]::ReadAllLines($buildJs)).Count
Write-Host "      base href y claves : OK"
Write-Host "      sha256             : $hash"
Write-Host "      bytes / lineas     : $bytes / $lines"

if ($VerifyOnly) {
  Write-Host ''
  Write-Host 'VerifyOnly: build verificado. No se toco _deploy y no hubo push.' -ForegroundColor Yellow
  exit 0
}

# --- 6/7 copiar a _deploy y pushear ------------------------------------------

Write-Host '6/7  copiar a _deploy y pushear gh-pages' -ForegroundColor Cyan
if (-not (Test-Path -LiteralPath '_deploy\.git')) {
  Stop-Deploy '_deploy no es un repositorio git'
}

Get-ChildItem -LiteralPath '_deploy' -Force |
  Where-Object { $_.Name -ne '.git' } |
  Remove-Item -Recurse -Force

Copy-Item -Path 'build\web\*' -Destination '_deploy' -Recurse -Force

$deployedHtml = Get-Content -LiteralPath '_deploy\index.html' -Raw
if ($deployedHtml -notmatch '<base href="/cafecal/">') {
  Stop-Deploy '_deploy\index.html quedo sin el base href correcto'
}

# Excepcion acordada: en _deploy si se stagea todo, porque solo contiene
# artefacto de build.
git -C _deploy add .
if ($LASTEXITCODE -ne 0) { Stop-Deploy 'git add en _deploy fallo' }

$staged = @(git -C _deploy diff --cached --name-only)
if ($staged.Count -eq 0 -or [string]::IsNullOrWhiteSpace(($staged -join ' '))) {
  Write-Host 'Sin cambios: gh-pages ya tiene este build.' -ForegroundColor Yellow
  exit 0
}

git -C _deploy commit -m $Message
if ($LASTEXITCODE -ne 0) { Stop-Deploy 'git commit en _deploy fallo' }

git -C _deploy push origin gh-pages
if ($LASTEXITCODE -ne 0) { Stop-Deploy 'git push de gh-pages fallo' }

# --- 7/7 verificar publicacion -----------------------------------------------

Write-Host '7/7  esperar a GitHub Pages' -ForegroundColor Cyan
# Antes se comprobaba que el index publicado siguiera conteniendo el
# <base href="/cafecal/">. Eso no comprueba NADA: TODOS los builds lo
# contienen, el nuevo y el viejo, asi que la condicion pasaba con el archivo
# que fuera y el script celebraba un deploy que aun no se habia publicado.
# Paso el 2026-10-16: imprimio «Publicado y verificado en produccion» unos
# 75 segundos antes de que fuera cierto, con Pages sirviendo el build
# anterior.
#
# Lo que se compara ahora es la huella del bundle que acaba de compilarse
# ($hash, del paso 5) contra la huella del bundle que esta sirviendo Pages.
# Si no coinciden, no esta publicado, y ahi si se cae en rojo.
#
# El marcador de consulta rompe la cache del CDN: sin el, se puede leer el
# archivo viejo durante minutos y creer que el deploy no sirvio.
$probe = 'https://miguelalbisortiz.github.io/cafecal/main.dart.js'
$published = $false
$servedHash = $null
for ($attempt = 1; $attempt -le 12; $attempt++) {
  Start-Sleep -Seconds 15
  $tmp = $null
  try {
    $cb = [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
    $tmp = Join-Path ([System.IO.Path]::GetTempPath()) "cafecal-probe-$cb.js"
    Invoke-WebRequest -Uri ("${probe}?cb=$cb") -OutFile $tmp -UseBasicParsing -TimeoutSec 60
    $servedHash = (Get-FileHash -LiteralPath $tmp -Algorithm SHA256).Hash
    if ($servedHash -eq $hash) {
      $published = $true
      break
    }
    $corto = $servedHash.Substring(0, 12)
    Write-Host "      intento ${attempt}/12: aun sirve otro build ($corto)"
  } catch {
    Write-Host "      intento ${attempt}/12: sin respuesta"
  } finally {
    if ($tmp -and (Test-Path -LiteralPath $tmp)) {
      Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
  }
}

if (-not $published) {
  if ($servedHash) {
    Stop-Deploy "GitHub Pages tras 3 minutos sigue sirviendo $servedHash y no $hash. El deploy NO esta publicado."
  }
  Stop-Deploy 'GitHub Pages no respondio en 3 minutos. No se puede confirmar el deploy; revisa la pestana Actions/Pages del repo.'
}

Write-Host ''
Write-Host 'Publicado y verificado en produccion.' -ForegroundColor Green
Write-Host "      main.dart.js en produccion : $hash" -ForegroundColor Green
