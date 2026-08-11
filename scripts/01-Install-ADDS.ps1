<#
.SYNOPSIS
    Installs AD DS and promotes this Windows Server 2019 host to a new
    forest / domain controller for the lab.
.DESCRIPTION
    Run this on the machine that will become DC01. Requires a restart.
    This is a standard domain promotion; nothing here is intentionally
    insecure. The misconfigurations are introduced by later scripts.
.NOTES
    Run as: local Administrator, elevated PowerShell.
#>

. "$PSScriptRoot\00-Variables.ps1"

Write-Host "[*] Installing AD-Domain-Services and management tools..." -ForegroundColor Yellow
Install-WindowsFeature -Name AD-Domain-Services, RSAT-ADDS, RSAT-AD-PowerShell, RSAT-DNS-Server -IncludeManagementTools

Write-Host "[*] Promoting this host to a new forest: $($Global:LabConfig.DomainName)" -ForegroundColor Yellow

$safeModePwd = ConvertTo-SecureString $Global:LabConfig.SafeModePassword -AsPlainText -Force

Install-ADDSForest `
    -DomainName            $Global:LabConfig.DomainName `
    -DomainNetbiosName     $Global:LabConfig.DomainNetBIOS `
    -SafeModeAdministratorPassword $safeModePwd `
    -InstallDns            $true `
    -CreateDnsDelegation   $false `
    -DatabasePath          "C:\Windows\NTDS" `
    -LogPath               "C:\Windows\NTDS" `
    -SysvolPath             "C:\Windows\SYSVOL" `
    -ForestMode             "WinThreshold" `
    -DomainMode             "WinThreshold" `
    -NoRebootOnCompletion   $false `
    -Force:$true

# The host reboots automatically after this cmdlet completes.
# Continue with 02-New-OUStructure.ps1 once it comes back up and you have
# logged back in as a domain administrator.
