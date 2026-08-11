<#
.SYNOPSIS
    Populates the domain with sample users and groups so BloodHound has a
    non-trivial graph to reason about.
.DESCRIPTION
    Creates ~10 standard domain users, a "Helpdesk" security group with a
    couple of members, and a "Helpdesk-Admin" account used later by the
    unconstrained-delegation attack path.
.NOTES
    Run on DC01 as a Domain Admin, after 02-New-OUStructure.ps1.
#>

. "$PSScriptRoot\00-Variables.ps1"
Import-Module ActiveDirectory

$cfg = $Global:LabConfig
$domainDN = (Get-ADDomain).DistinguishedName
$usersDN  = "OU=$($cfg.OUs.Users),OU=$($cfg.OUs.Root),$domainDN"
$pwd = ConvertTo-SecureString $cfg.DefaultUserPassword -AsPlainText -Force

function New-LabUser {
    param([string]$SamAccountName, [string]$GivenName, [string]$Surname)
    if (Get-ADUser -Filter "SamAccountName -eq '$SamAccountName'" -ErrorAction SilentlyContinue) {
        Write-Host "[i] User already exists: $SamAccountName" -ForegroundColor DarkGray
        return
    }
    Write-Host "[*] Creating user: $SamAccountName" -ForegroundColor Yellow
    New-ADUser `
        -Name "$GivenName $Surname" `
        -GivenName $GivenName `
        -Surname $Surname `
        -SamAccountName $SamAccountName `
        -UserPrincipalName "$SamAccountName@$($cfg.DomainName)" `
        -Path $usersDN `
        -AccountPassword $pwd `
        -Enabled $true `
        -ChangePasswordAtLogon $false `
        -PasswordNeverExpires $true
}

# --- Standard sample users ---
foreach ($sam in $cfg.SampleUsers) {
    $given = ($sam -replace '[0-9]', '').Substring(0,1).ToUpper() + $sam.Substring(1)
    New-LabUser -SamAccountName $sam -GivenName $given -Surname "LabUser"
}

# --- Helpdesk group + members ---
if (-not (Get-ADGroup -Filter "Name -eq '$($cfg.HelpdeskGroup)'" -ErrorAction SilentlyContinue)) {
    Write-Host "[*] Creating group: $($cfg.HelpdeskGroup)" -ForegroundColor Yellow
    New-ADGroup -Name $cfg.HelpdeskGroup -GroupScope Global -GroupCategory Security -Path $usersDN
}

New-LabUser -SamAccountName "helpdesk-user04" -GivenName "Helpdesk" -Surname "User04"
Add-ADGroupMember -Identity $cfg.HelpdeskGroup -Members "helpdesk-user04" -ErrorAction SilentlyContinue

# --- Helpdesk-Admin: elevated support account used by Attack Path 2 ---
New-LabUser -SamAccountName "Helpdesk-Admin" -GivenName "Helpdesk" -Surname "Admin"
Add-ADGroupMember -Identity "Domain Admins" -Members "Helpdesk-Admin" -ErrorAction SilentlyContinue

Write-Host "`n[+] Sample users and groups created." -ForegroundColor Green
