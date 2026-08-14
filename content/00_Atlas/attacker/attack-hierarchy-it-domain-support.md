---
title: Attack Perspective — IT Domain & IT Support Model (Red Team)
tags:
- attack
- red-team
- it-domain
- helpdesk
- service-desk
- ad
- lateral-movement
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# IT Domain & Support Model — Perspektif Penyerang

> IT support = path privilege escalation paling natural. Helpdesk punyaadmin creds, remote management tools, ticket system dengan credential. Red team menyerang helpdesk untuk pivot ke admin domain.

## 1. Attack Surface IT Support

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **Helpdesk Credential** | Password reset → admin creds → ticket system | T1078 | Social engineering, phishing helpdesk | Helpdesk = motivated to assist → trusting | Helpdesk action = legit operation |
| **Remote Management (RDP/SCCM)** | RDP hijack (tscon), SCCM site server takeover | T1021.001 | tscon #session, SCCM exploit (CVE-2023-XXXX) | tscon = legit Windows feature | RDP audit = connection only |
| **Ticket System** | Credential in ticket, API key in comment, SNMP string | T1552 | Jira/ServiceNow API abuse | API token = legit auth | Ticket audit = rare |
| **Service Account** | Helpdesk service account → admin tool execution | T1078 | Credential theft, token impersonation | SA = legit run context | SA audit = noisy |
| **AD OU Delegation** | OU admin → group policy modify → pwn OU member | T1484 | GPO abuse, ADUC delegation | GPO = legit admin tool | GPO audit = rare real-time |
| **Password Reset Token** | Token theft → reset target password → access | T1098 | Token intercept, reset abuse | Reset = legit helpdesk action | Reset audit = rare |
| **MIM (e.g., Azure AD Connect)** | Sync account compromise → AD → cloud | T1098 | Azure AD Connect sync account → DCSync | Sync = legit infrastructure | AD Connect audit = rare |

## 2. Helpdesk Attack Chain

```
Recon: Identifikasi helpdesk staff (LinkedIn, OSINT, org chart)
 ↓
Social Engineering:
 ├── Phishing helpdesk → credential capture
 ├── Vishing (call helpdesk → impersonate employee → password reset)
 └── Ticket injection → create fake urgent ticket → helpdesk action
 ↓
Credential Acquisition:
 ├── Helpdesk creds → RDP/SCCM/ADUC access
 ├── Password reset → target user → login as target
 └── Ticket system → API key → automate actions
 ↓
Lateral:
 ├── RDP ke admin workstation → Mimikatz → domain creds
 ├── SCCM site server → deploy application → pwn all client
 └── ADUC → reset Domain Admin password → login as DA
 ↓
Persistence:
 ├── GPO → backdoor script (AutoLogon credential harvest)
 ├── SCCM → malicious application → periodic re-deploy
 └── Helpdesk ticket bot → automated persistence
```

## 3. RDP Hijack (tscon)

```
Enumerate: query user → list active RDP session
 ↓
Target: Session dengan admin context (ID 2, admin user)
 ↓
Privilege Check: Apakah current user punya SE_TCB_NAME (SYSTEM)?
 ├── Ya → tscon 2 /dest:console → hixack ke session
 └── Tidak → PrivEsc dulu → SYSTEM → tscon
 ↓
Hijack: tscons <session_id> /dest:<current_session>
 ↓
Result: Attacker = admin session → no credential, no login event
 ↓
Evasion: tscon = legit Windows feature → no alert
```

## 4. SCCM Attack

| Attack | Teknik | Impact |
|--------|--------|--------|
| **Site Server Compromise** | SQL injection ke SCCM DB → application tamper | Deploy malicious app ke semua client |
| **NAH Site Takeover** | Compromise primary site → control hierarchy | Full SCCM hierarchy compromise |
| **PXE Abuse** | Boot PXE → image capture → credential in image | Credential theft dari captured image |
| **Application Deploy** | Push malicious application → client client | Automatic backdoor semua managed device |
| **Credential Relay** | NTLM relay SCCM site server → AD CS → DA | Domain admin via cert |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **tscon** | RDP session hijack (Windows built-in) |
| **SCCMHunter** | SCCM reconnaissance + abuse |
| **MalSCCM** | Malicious SCCM application deploy |
| **BloodHound** | AD attack path (helpdesk → DA) |
| **Rubeus** | Kerberos abuse (helpdesk → DC) |
| **Evilginx2** | AiTM phishing (helpdesk credential capture) |

## 6. Referensi
- SCCM Attacks — https://github.com/subat0mik/Misconfiguration-SCCM
- RDP Hijack (tscon) — https://attack.mitre.org/techniques/T1021/001/
- BloodHound — https://github.com/BloodHoundAD/BloodHound
- Azure AD Connect (DCSync) — https://blog.netwrix.com/2023/03/09/...