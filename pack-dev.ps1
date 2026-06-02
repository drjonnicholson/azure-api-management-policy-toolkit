# Copyright (c) Microsoft Corporation.
# Licensed under the MIT License.

# pack-dev.ps1
# Packs NuGet packages with a dev timestamp pre-release suffix.
# Produces filenames like: Microsoft.Azure.ApiManagement.PolicyToolkit.Testing.1.0.0-dev-20260602123456.nupkg
#
# Usage:
#   .\pack-dev.ps1           # build + pack
#   .\pack-dev.ps1 -NoBuild  # pack only (if already built)
#
# Packages are written to: .\output\

param(
    [switch]$NoBuild
)

$ErrorActionPreference = "Stop"

$repoRoot = $PSScriptRoot
$timestamp = (Get-Date).ToUniversalTime().ToString("yyyyMMddHHmmss")
$versionSuffix = "dev-$timestamp"

Write-Host "==> VersionSuffix: $versionSuffix"

# ---------------------------------------------------------------------------
# Step 1: Build the solution (skipped with -NoBuild)
# ---------------------------------------------------------------------------
if (-not $NoBuild) {
    Write-Host ""
    Write-Host "==> Building solution ..."
    & dotnet build "$repoRoot\apim-policy-toolkit.sln" --configuration Release
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Build failed. Aborting pack."
        exit $LASTEXITCODE
    }
}

# ---------------------------------------------------------------------------
# Step 2: Run tests
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Running tests ..."

& dotnet test "$repoRoot\apim-policy-toolkit.sln" `
    --configuration Release `
    --no-build `
    --logger "console;verbosity=minimal"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Tests failed. Aborting pack."
    exit $LASTEXITCODE
}

# ---------------------------------------------------------------------------
# Step 3: Pack the solution (projects with IsPackable=false are skipped automatically)
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "==> Packing solution ..."

& dotnet pack "$repoRoot\apim-policy-toolkit.sln" `
    --configuration Release `
    --no-build `
    /p:VersionSuffix=$versionSuffix

if ($LASTEXITCODE -ne 0) {
    Write-Error "Pack failed."
    exit $LASTEXITCODE
}

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
$outputDir = Join-Path $repoRoot "output"
Write-Host ""
Write-Host "==> Done! Packages in: $outputDir"
Write-Host ""
Get-ChildItem -Path $outputDir -Filter "*$versionSuffix*.nupkg" |
    Select-Object Name, @{N="Size (KB)"; E={ [math]::Round($_.Length / 1KB, 1) }} |
    Format-Table -AutoSize


