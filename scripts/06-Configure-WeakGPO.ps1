<#
.SYNOPSIS
    MISCONFIGURATION #3 — grants a low-privileged group full control over
    a GPO linked to the workstations.
.DESCRIPTION
    Creates the "Helpdesk-Software-Install" GPO, links it to the
    Workstations OU, and grants the low-privileged "Helpdesk" security
    group GenericAll (Edit settings, delete, modify security) over that
    GPO — a misconfiguration commonly caused by over-scoped delegation
    during GPO creation.

    This intentionally recreates a well-known AD weakness for lab study.
    Do not do this in a production domain. See ../DISCLAIMER.md.
.NOTES
    Run on DC01 as a Domain Admin. Requires the GroupPolicy PowerShell
    module (installed with GPMC / RSAT-GPMC).
#>

. "$PSScriptRoot\00-Variables.ps1"
Import-Module ActiveDirectory
Import-Module GroupPolicy

$cfg = $Global:LabConfig
$domainDN = (Get-ADDomain).DistinguishedName
$computersDN = "OU=$($cfg.OUs.Computers),OU=$($cfg.OUs.Root),$domainDN"
$workstationsDN = "OU=$($cfg.WorkstationsOUName),$computersDN"

if (-not (Get-GPO -Name $cfg.GPOName -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Creating GPO: $($cfg.GPOName)" -ForegroundColor Yellow
    New-GPO -Name $cfg.GPOName | Out-Null
} else {
    Write-Host "[i] GPO already exists: $($cfg.GPOName)" -ForegroundColor DarkGray
}

Write-Host "[*] Linking GPO to $workstationsDN" -ForegroundColor Yellow
New-GPLink -Name $cfg.GPOName -Target $workstationsDN -ErrorAction SilentlyContinue | Out-Null

Write-Host "[*] Granting '$($cfg.HelpdeskGroup)' GenericAll (Edit settings, delete, modify security) on the GPO" -ForegroundColor Yellow
Set-GPPermission `
    -Name $cfg.GPOName `
    -TargetName $cfg.HelpdeskGroup `
    -TargetType Group `
    -PermissionLevel GpoEditDeleteModifySecurity

Write-Host "`n[+] Misconfiguration #3 in place: '$($cfg.HelpdeskGroup)' has GenericAll over a GPO linked to Workstations." -ForegroundColor Green
Write-Host "    Verify with:  Get-GPPermission -Name '$($cfg.GPOName)' -All" -ForegroundColor DarkGray
