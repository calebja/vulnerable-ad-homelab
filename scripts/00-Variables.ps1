<#
.SYNOPSIS
    Shared configuration for the vulnerable-ad-homelab scripts.
.DESCRIPTION
    Dot-source this file at the top of every other script so the whole
    lab is configured from one place:

        . .\00-Variables.ps1

    Adjust the values below to match your own environment before running
    anything else.
#>

$Global:LabConfig = @{
    DomainName         = "lab.local"
    DomainNetBIOS      = "LAB"
    SafeModePassword   = "ChangeMe-DSRM-P@ss1!"   # DSRM password, change before use
    DefaultUserPassword = "ChangeMe-Lab-P@ss1!"    # sample user password, change before use

    OUs = @{
        Root            = "LabLocal"
        Users           = "Users"
        Computers       = "Computers"
        ServiceAccounts = "ServiceAccounts"
    }

    ServiceAccount = @{
        Name = "svc-sql"
        SPN  = "MSSQLSvc/dc01.lab.local:1433"
    }

    DelegationHost = "WS01"

    HelpdeskGroup  = "Helpdesk"
    GPOName        = "Helpdesk-Software-Install"
    WorkstationsOUName = "Workstations"

    SampleUsers = @(
        "jsmith", "agarcia", "mchen", "rpatel", "kwilliams",
        "tjohnson", "lrodriguez", "dkim", "sbrown", "nmartinez"
    )
}

Write-Host "[i] Loaded lab config for domain '$($Global:LabConfig.DomainName)'" -ForegroundColor Cyan
