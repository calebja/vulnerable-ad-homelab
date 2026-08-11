<#
.SYNOPSIS
    Wraps SharpHound.exe with the collection flags used in this lab.
.DESCRIPTION
    Run this from a domain-joined but LOW-PRIVILEGED context (e.g. on
    WS02, logged in as a standard user) to simulate an attacker who has
    landed on a normal workstation — this is what makes the resulting
    BloodHound graph realistic.

    This script does not download or embed SharpHound. Get the official,
    signed release from the BloodHound project and place SharpHound.exe
    next to this script (or pass -SharpHoundPath) before running:

        https://github.com/SpecterOps/BloodHound
.PARAMETER SharpHoundPath
    Path to SharpHound.exe. Defaults to .\SharpHound.exe (same folder).
.PARAMETER OutputDir
    Where to write the collection zip. Defaults to .\collection.
.PARAMETER Domain
    Target domain. Defaults to lab.local.
.EXAMPLE
    .\Invoke-Collection.ps1 -SharpHoundPath C:\Tools\SharpHound.exe
#>

param(
    [string]$SharpHoundPath = ".\SharpHound.exe",
    [string]$OutputDir = ".\collection",
    [string]$Domain = "lab.local"
)

if (-not (Test-Path $SharpHoundPath)) {
    Write-Error "SharpHound.exe not found at '$SharpHoundPath'. Download the official release from https://github.com/SpecterOps/BloodHound and place it there, or pass -SharpHoundPath."
    return
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir | Out-Null
}

$stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$zipName = "lab_collection_$stamp.zip"

Write-Host "[*] Running SharpHound against $Domain (CollectionMethod: All)" -ForegroundColor Yellow

& $SharpHoundPath `
    -CollectionMethod All `
    --Domain $Domain `
    --OutputDirectory $OutputDir `
    --ZipFileName $zipName

Write-Host "`n[+] Collection complete: $OutputDir\$zipName" -ForegroundColor Green
Write-Host "    Import this zip into the BloodHound GUI to explore attack paths." -ForegroundColor DarkGray
