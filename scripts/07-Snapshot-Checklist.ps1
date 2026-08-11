<#
.SYNOPSIS
    Prints a checklist of VirtualBox snapshots to take, so each attack
    path can be tested independently and re-run without rebuilding the
    domain from scratch.
.DESCRIPTION
    This script does not touch VirtualBox itself (snapshots are taken
    from the host, not the guest) — it just gives you a consistent
    checklist and reminds you what state the domain should be in at
    each point.
#>

Write-Host @"
VirtualBox snapshot checklist
==============================

Take snapshots FROM THE HOST (VirtualBox Manager or VBoxManage), at these points:

  [ ] 00-baseline
      - All 4 VMs installed, domain promoted, OUs + sample users created.
      - Run before: 04-Introduce-Kerberoasting.ps1

  [ ] 01-kerberoast-ready
      - svc-sql created, SPN registered, added to Domain Admins.
      - Run before attempting Attack Path 1.

  [ ] 02-delegation-ready
      - WS01 configured with TRUSTED_FOR_DELEGATION.
      - Run before attempting Attack Path 2.

  [ ] 03-gpo-abuse-ready
      - Helpdesk-Software-Install GPO created, linked, GenericAll granted.
      - Run before attempting Attack Path 3.

Command-line example (run on the HOST, not in the guest):

  VBoxManage snapshot "DC01" take "00-baseline" --description "Clean domain, no misconfigs"
  VBoxManage snapshot "DC01" restore "00-baseline"

"@ -ForegroundColor Cyan
