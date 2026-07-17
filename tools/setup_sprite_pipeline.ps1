param(
    [string]$Python = "python",
    [string]$VenvDir = ".venv-sprite-gen"
)

$ErrorActionPreference = "Stop"
$projectRoot = Split-Path -Parent $PSScriptRoot
$venvPath = if ([IO.Path]::IsPathRooted($VenvDir)) { $VenvDir } else { Join-Path $projectRoot $VenvDir }
$pythonPath = Join-Path $venvPath "Scripts\python.exe"

if (-not (Get-Command $Python -ErrorAction SilentlyContinue)) {
    throw "Python 3.10+ was not found. Install Python, then rerun this setup script."
}

if (-not (Test-Path $pythonPath)) {
    Write-Host "Creating $venvPath"
    & $Python -m venv $venvPath
    if ($LASTEXITCODE -ne 0) { throw "Could not create the Python virtual environment." }
}

Write-Host "Installing the pinned local sprite-gen package and Pillow"
& $pythonPath -m pip install --upgrade pip
& $pythonPath -m pip install -e (Join-Path $projectRoot "tools\sprite-gen")
if ($LASTEXITCODE -ne 0) { throw "Could not install sprite-gen dependencies." }

Write-Host "Sprite pipeline environment is ready: $pythonPath" -ForegroundColor Green
