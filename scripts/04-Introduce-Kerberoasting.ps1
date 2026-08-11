<#
.SYNOPSIS
    MISCONFIGURATION #1 — creates an over-privileged, Kerberoastable
    service account.
.DESCRIPTION
    Creates svc-sql, registers a Service Principal Name against it (which
    makes it Kerberoastable by any authenticated domain user), and adds it
    to Domain Admins to simulate a common real-world shortcut.

    This intentionally recreates a well-known AD weakness for lab study.
    Do not do this in a production domain. See ../DISCLAIMER.md.
.NOTES
    Run on DC01 as a Domain Admin, after 03-New-LabUsersAndGroups.ps1.
#>

. "$PSScriptRoot\00-Variables.ps1"
Import-Module ActiveDirectory

$cfg = $Global:LabConfig
$domainDN = (Get-ADDomain).DistinguishedName
$svcDN = "OU=$($cfg.OUs.ServiceAccounts),OU=$($cfg.OUs.Root),$domainDN"
$svcName = $cfg.ServiceAccount.Name
$pwd = ConvertTo-SecureString $cfg.DefaultUserPassword -AsPlainText -Force

if (-not (Get-ADUser -Filter "SamAccountName -eq '$svcName'" -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Creating service account: $svcName" -ForegroundColor Yellow
    New-ADUser `
        -Name $svcName `
        -SamAccountName $svcName `
        -UserPrincipalName "$svcName@$($cfg.DomainName)" `
        -Path $svcDN `
        -AccountPassword $pwd `
        -Enabled $true `
        -PasswordNeverExpires $true
} else {
    Write-Host "[i] Service account already exists: $svcName" -ForegroundColor DarkGray
}

Write-Host "[*] Registering SPN '$($cfg.ServiceAccount.SPN)' on $svcName (makes it Kerberoastable)" -ForegroundColor Yellow
setspn -A $cfg.ServiceAccount.SPN "$($cfg.DomainNetBIOS)\$svcName"

Write-Host "[*] Adding $svcName to Domain Admins (intentional over-privilege)" -ForegroundColor Yellow
Add-ADGroupMember -Identity "Domain Admins" -Members $svcName

Write-Host "`n[+] Misconfiguration #1 in place: $svcName is Kerberoastable and is a Domain Admin." -ForegroundColor Green
Write-Host "    Verify with:  setspn -L $svcName" -ForegroundColor DarkGray
