<#
.SYNOPSIS
    MISCONFIGURATION #2 — enables unconstrained Kerberos delegation on a
    workstation computer object.
.DESCRIPTION
    Sets TRUSTED_FOR_DELEGATION on the WS01 computer account, simulating a
    legacy application server that was configured for unconstrained
    delegation without a business justification. Any account that later
    authenticates to WS01 has its Kerberos TGT exposed to whoever controls
    that host.

    This intentionally recreates a well-known AD weakness for lab study.
    Do not do this in a production domain. See ../DISCLAIMER.md.
.NOTES
    Run on DC01 as a Domain Admin, after WS01 has been joined to the domain.
#>

. "$PSScriptRoot\00-Variables.ps1"
Import-Module ActiveDirectory

$cfg = $Global:LabConfig
$hostName = $cfg.DelegationHost

$computer = Get-ADComputer -Filter "Name -eq '$hostName'" -ErrorAction SilentlyContinue
if (-not $computer) {
    Write-Error "Computer object '$hostName' not found. Join it to the domain first, then re-run this script."
    return
}

Write-Host "[*] Enabling unconstrained delegation (TRUSTED_FOR_DELEGATION) on $hostName" -ForegroundColor Yellow
Set-ADAccountControl -Identity $computer.DistinguishedName -TrustedForDelegation $true

Write-Host "`n[+] Misconfiguration #2 in place: $hostName is trusted for unconstrained delegation." -ForegroundColor Green
Write-Host "    Verify with:  Get-ADComputer $hostName -Properties TrustedForDelegation" -ForegroundColor DarkGray
