# Build Guide

Full steps to stand up the lab from a blank VirtualBox install through to
a domain with all three misconfigurations in place.

## 1. Provision the VMs

| VM | OS | RAM | vCPU | Disk |
|---|---|---|---|---|
| DC01 | Windows Server 2019 | 4 GB | 2 | 60 GB |
| WS01 | Windows 10 | 4 GB | 2 | 60 GB |
| WS02 | Windows 10 | 4 GB | 2 | 60 GB |
| KALI01 | Kali Linux (current) | 4 GB | 2 | 40 GB |

Create an **internal (host-only) network** in VirtualBox — no bridged
adapter, no NAT to the internet — and attach all four VMs to it. Static IPs
used throughout this repo:

| Host | IP |
|---|---|
| DC01 | 10.10.10.10 |
| WS01 | 10.10.10.21 |
| WS02 | 10.10.10.22 |
| KALI01 | 10.10.10.66 |

## 2. Promote the domain controller

On DC01:

```powershell
. .\scripts\00-Variables.ps1
.\scripts\01-Install-ADDS.ps1
```

The host reboots automatically. Log back in as `LAB\Administrator`.

## 3. Build the OU structure and sample users

Still on DC01:

```powershell
.\scripts\02-New-OUStructure.ps1
.\scripts\03-New-LabUsersAndGroups.ps1
```

## 4. Join WS01 and WS02 to the domain

On each workstation: set DNS to `10.10.10.10`, then

```powershell
Add-Computer -DomainName lab.local -Credential (Get-Credential) -Restart
```

## 5. Take the baseline snapshot

From the **host** (not inside any guest):

```powershell
.\scripts\07-Snapshot-Checklist.ps1   # prints the checklist below
VBoxManage snapshot "DC01" take "00-baseline" --description "Clean domain, no misconfigs"
```

Repeat for WS01, WS02, and KALI01 so the whole environment can be rolled
back together.

## 6. Introduce the three misconfigurations

On DC01, one at a time — snapshot after each if you want to test the
paths independently:

```powershell
.\scripts\04-Introduce-Kerberoasting.ps1
.\scripts\05-Enable-UnconstrainedDelegation.ps1
.\scripts\06-Configure-WeakGPO.ps1
```

## 7. Collect with BloodHound

Download the official SharpHound collector from the
[BloodHound repo](https://github.com/SpecterOps/BloodHound) and place
`SharpHound.exe` on WS02. Log in as a standard domain user (not an admin),
then:

```powershell
.\bloodhound\Invoke-Collection.ps1
```

Import the resulting zip into the BloodHound desktop GUI on KALI01 and
run the built-in **Shortest Paths to Domain Admins** query.

## 8. Exploit

Follow [`ATTACK-PATHS.md`](ATTACK-PATHS.md) for the exact commands used
against each of the three paths from KALI01.

## 9. Reset or roll back

```powershell
.\scripts\99-Reset-Lab.ps1
```

or restore the `00-baseline` VirtualBox snapshot on every VM.
