---
title: Attack Perspective — AD & Windows (Red Team)
tags: [attack,red-team,ad,kerberos,dcsync,kerberoast,bloodhound,zerologon]
source: ad-windows-security.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Active Directory & Windows — Perspektif Penyerang

> AD = target utama enterprise compromise. Semua attack path bermuara ke DA. Red team: BloodHound mapping → Kerberoasting → AS-REP → delegation → AD CS → DCSync → Golden Ticket.

## 1. Attack Surface AD

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **Kerberos TGT/TGS** | Kerberoasting, AS-REP roast, delegation abuse | T1558.003 | Rubeus, Impacket | Kerberos = legit protocol | 4769 audit — tapi cert auth bypass |
| **AD CS** | ESC1-ESC14, Certifried, NTLM relay | T1649 | Certipy, PetitPotam | Cert = valid internal CA | CT log tidak cover internal CA |
| **DCSync** | Replication abuse → dump all hash | T1003.006 | secretsdump.py, Mimikatz | Replication = legit DC operation | 4662 audit — tapi SA = noisy |
| **NTLM Relay** | SMB relay, LDAP relay, AD CS relay | T1557.001 | ntlmrelayx, krbrelayup | Relay = legit auth flow | Relay detect = rare |
| **Group Policy** | GPO abuse → deploy backdoor | T1484 | Grouper2, SharpGPOAbuse | GPO = legit admin tool | GPO audit = rare |
| **Delegation** | Unconstrained → TGT theft, constrained → service abuse | T1558.002 | Rubeus, kekeo | Delegation = legit AD feature | 4769 — tapi delegation = normal |
| **Golden/Silver Ticket** | Forge TGT/TGS → persist access | T1558.001 | Mimikatz, ticketer | Forged ticket = valid format | Ticket audit = rare |
| **Trust Relationship** | Cross-forest trust abuse | T1482 | BloodHound trust path, sidHistory | Trust = legit auth | Trust audit = rare |

## 2. AD Attack Chain (BloodHound Path)

```
Recon: SharpHound collect → BloodHound visualize
  ├── Users, groups, sessions, ACL, trusts
  ├── Attack path: User → Computer → Group → DA
  └→ Shortest path to DA → prioritize
    ↓
Initial Access: Phishing / exploit → low-priv user
    ↓
Enum: BloodHound → identify escalation path
  ├── Kerberoasting: find SPN user → request TGS → crack
  ├── AS-REP: find no-preauth user → request TGT → crack
  ├── Delegation: unconstrained/constrained → ticket theft
  ├── AD CS: ESC1 (enrollment rights) → cert → DA
  └── GPO: writable GPO → deploy backdoor → DA
    ↓
Lateral: PsExec/WMI/WinRM → admin → more sessions
    ↓
DCSync: Replication → krbtgt hash → Golden Ticket
    ↓
Persistence: Golden Ticket / backdoor account / cert
```

## 3. Kerberoasting (Deepdive)

```
Prereq: Low-priv domain user
    ↓
Find SPN: GetUserSPNs.py / Rubeus kerberoast
  ├── User accounts with ServicePrincipalName (service accounts)
  ├── TGS ticket encrypted with service account hash
  └→ Request TGS → offline crack
    ↓
Crack: hashcat -m 13100 hash.txt rockyou.txt
  ├── Weak service account password → cracked
  └→ Plaintext → service account → privilege escalation
    ↓
Evasion: Kerberoasting = legit TGS request → no alert (if not monitored)
```

## 4. CVE AD Prioritas

| CVE | Impact | Red Team Value |
|-----|--------|----------------|
| CVE-2022-26923 (Certifried) | DA via cert | Critical |
| CVE-2021-36942 (PetitPotam) | NTLM relay → AD CS → DA | Critical (no creds) |
| CVE-2021-42287 (noPac) | DA via KDC | Critical |
| CVE-2020-1472 (Zerologon) | DA via Netlogon | Critical — unpatched DC masih ada |
| CVE-2023-21554 (QueueJumper) | MSMQ RCE → DA | High |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **BloodHound / SharpHound** | Attack path mapping |
| **Rubeus** | Kerberoast, AS-REP, ticket forge, delegation |
| **Impacket** | GetUserSPNs, secretsdump, ntlmrelayx, wmiexec |
| **Certipy** | AD CS abuse (ESC1-14) |
| **Mimikatz** | LSASS, Golden Ticket, DPAPI |
| **CrackMapExec** | SMB/WMI/WinRM lateral |
| **evil-winrm** | WinRM shell |

## 6. Referensi
- BloodHound — https://github.com/BloodHoundAD/BloodHound
- Rubeus — https://github.com/GhostPack/Rubeus
- Certipy — https://github.com/ly4k/Certipy
- HackTricks AD — https://book.hacktricks.xyz/windows-hardening/active-directory-methodology
- SpecterOps (AD Attacks) — https://posts.specterops.io/