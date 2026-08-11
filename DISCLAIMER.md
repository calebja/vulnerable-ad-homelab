# Disclaimer

This repository intentionally builds a **vulnerable** Active Directory
environment for personal, offline security education. It exists to help
one person (or a study group) learn how common AD misconfigurations are
identified and abused, using their own isolated lab.

By using anything in this repository you agree to the following:

- Run this **only** inside an isolated lab (host-only / internal VirtualBox
  network, no bridged adapter, no route to the internet or to any other
  network you do not fully own).
- Do **not** run these scripts against any domain, host, or account you do
  not own or do not have explicit written authorization to test.
- The scripts in `scripts/` deliberately weaken security settings
  (Kerberos delegation, GPO ACLs, service account privileges). Do not reuse
  them, even partially, against a real environment.
- The author(s) of this repository accept no responsibility for misuse.

If you are looking for guidance on securing a real Active Directory
environment against these techniques, see the "Risk Analysis & Remediation"
section of [`docs/WRITEUP.md`](docs/WRITEUP.md) instead.
