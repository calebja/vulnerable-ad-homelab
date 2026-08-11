<#
.SYNOPSIS
    Creates the OU structure used throughout the rest of the lab.
.DESCRIPTION
    Builds:
        lab.local
        └── LabLocal
            ├── Users
            ├── Computers
            │   └── Workstations
            └── ServiceAccounts
.NOTES
    Run on DC01 as a Domain Admin, after the domain has finished promoting.
#>

. "$PSScriptRoot\00-Variables.ps1"
Import-Module ActiveDirectory

$domainDN = (Get-ADDomain).DistinguishedName
$cfg = $Global:LabConfig

function New-OUIfMissing {
    param([string]$Name, [string]$ParentDN)
    $ouDN = "OU=$Name,$ParentDN"
    if (-not (Get-ADOrganizationalUnit -Filter "DistinguishedName -eq '$ouDN'" -ErrorAction SilentlyContinue)) {
        Write-Host "[*] Creating OU: $ouDN" -ForegroundColor Yellow
        New-ADOrganizationalUnit -Name $Name -Path $ParentDN -ProtectedFromAccidentalDeletion $false
    } else {
        Write-Host "[i] OU already exists: $ouDN" -ForegroundColor DarkGray
    }
    return $ouDN
}

$rootDN       = New-OUIfMissing -Name $cfg.OUs.Root -ParentDN $domainDN
$usersDN      = New-OUIfMissing -Name $cfg.OUs.Users -ParentDN $rootDN
$computersDN  = New-OUIfMissing -Name $cfg.OUs.Computers -ParentDN $rootDN
$svcDN        = New-OUIfMissing -Name $cfg.OUs.ServiceAccounts -ParentDN $rootDN
$workstationsDN = New-OUIfMissing -Name $cfg.WorkstationsOUName -ParentDN $computersDN

Write-Host "`n[+] OU structure ready:" -ForegroundColor Green
Write-Host "    $rootDN"
Write-Host "    $usersDN"
Write-Host "    $computersDN"
Write-Host "    $workstationsDN"
Write-Host "    $svcDN"
