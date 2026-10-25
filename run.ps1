# ==============================================================================
# LISN-TUI Windows PowerShell Runner & Installer
# Automatically installs, updates, and launches LISN-TUI on Windows 10/11.
# ==============================================================================

$ErrorActionPreference = "Stop"

$Repo = "shdynila/lisn-tui-releases"
$InstallDir = Join-Path $env:LOCALAPPDATA "lisn-tui\bin"
$BinPath = Join-Path $InstallDir "lisn.exe"
$VersionFile = Join-Path $InstallDir "version.txt"

Write-Host "Checking for latest LISN-TUI release..." -ForegroundColor Cyan

$LatestTag = $null
try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
    $ReleaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "PowerShell" }
    $LatestTag = $ReleaseInfo.tag_name
} catch {
    Write-Host "Could not reach GitHub Releases API. Checking local installation..." -ForegroundColor Yellow
}

$CurrentTag = ""
if (Test-Path $VersionFile) {
    $CurrentTag = (Get-Content $VersionFile -Raw).Trim()
}

# If installed and up to date, launch directly
if ((Test-Path $BinPath) -and ($CurrentTag -eq $LatestTag) -and ($LatestTag -ne $null)) {
    & $BinPath $args
    exit $LASTEXITCODE
}

if ($null -eq $LatestTag) {
    if (Test-Path $BinPath) {
        Write-Host "Launching installed local binary..." -ForegroundColor Green
        & $BinPath $args
        exit $LASTEXITCODE
    } else {
        Write-Error "No local installation found and unable to reach GitHub."
    }
}

Write-Host "Installing / Updating LISN-TUI ($LatestTag) for Windows (x64)..." -ForegroundColor Cyan

if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$ZipUrl = "https://github.com/$Repo/releases/download/$LatestTag/lisn_windows_amd64.zip"
$ZipPath = Join-Path $InstallDir "lisn_download.zip"

Write-Host "Downloading $ZipUrl..." -ForegroundColor Gray
Invoke-WebRequest -Uri $ZipUrl -OutFile $ZipPath -UseBasicParsing

Write-Host "Extracting..." -ForegroundColor Gray
Expand-Archive -Path $ZipPath -DestinationPath $InstallDir -Force
Remove-Item -Path $ZipPath -Force

Set-Content -Path $VersionFile -Value $LatestTag

Write-Host "LISN-TUI $LatestTag installed successfully in $InstallDir" -ForegroundColor Green
Write-Host ""

& $BinPath $args
exit $LASTEXITCODE
