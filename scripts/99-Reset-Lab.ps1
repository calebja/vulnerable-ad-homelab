<#
.SYNOPSIS
    Reverts all three intentional misconfigurations, leaving the domain
    structure and sample users/groups in place.
.DESCRIPTION
    Useful if you'd rather patch-and-verify than restore a VirtualBox
    snapshot. Run each attack path's "before" state check against
    docs/ATTACK-PATHS.md to confirm the fix removed the path in
    BloodHound.
.NOTES
    Run on DC01 as a Domain Admin.
#>

. "$PSScriptRoot\00-Variables.ps1"
Import-Module ActiveDirectory
Import-Module GroupPolicy

$cfg = $Global:LabConfig

Write-Host "[*] Reverting misconfiguration #1 (Kerberoastable svc-sql in Domain Admins)" -ForegroundColor Yellow
$svcName = $cfg.ServiceAccount.Name
if (Get-ADUser -Filter "SamAccountName -eq '$svcName'" -ErrorAction SilentlyContinue) {
    Remove-ADGroupMember -Identity "Domain Admins" -Members $svcName -Confirm:$false -ErrorAction SilentlyContinue
    setspn -D $cfg.ServiceAccount.SPN "$($cfg.DomainNetBIOS)\$svcName" | Out-Null
    Write-Host "    - Removed $svcName from Domain Admins and de-registered its SPN." -ForegroundColor Green
}

Write-Host "[*] Reverting misconfiguration #2 (unconstrained delegation on $($cfg.DelegationHost))" -ForegroundColor Yellow
$computer = Get-ADComputer -Filter "Name -eq '$($cfg.DelegationHost)'" -ErrorAction SilentlyContinue
if ($computer) {
    Set-ADAccountControl -Identity $computer.DistinguishedName -TrustedForDelegation $false
    Write-Host "    - Disabled TRUSTED_FOR_DELEGATION on $($cfg.DelegationHost)." -ForegroundColor Green
}

Write-Host "[*] Reverting misconfiguration #3 (GenericAll on GPO for $($cfg.HelpdeskGroup))" -ForegroundColor Yellow
if (Get-GPO -Name $cfg.GPOName -ErrorAction SilentlyContinue) {
    Set-GPPermission -Name $cfg.GPOName -TargetName $cfg.HelpdeskGroup -TargetType Group -PermissionLevel GpoRead
    Write-Host "    - Reduced $($cfg.HelpdeskGroup) permissions on the GPO to Read only." -ForegroundColor Green
}

Write-Host "`n[+] Lab reset complete. Re-run BloodHound collection to confirm all three edges are gone." -ForegroundColor Green
