---
title: Attack Perspective — Intelligence Sources Ecosystem (Red Team Recon)
tags:
- attack
- red-team
- intelligence
- sources
- recon
- datamining
- fusion
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Intelligence Sources Ecosystem — Perspektif Penyerang (Recon Fusion)

> Intelligence ecosystem = sumber data yang bisa di-fuse untuk profiling target. Red team pakai: OSINT fusion, breach database, social media footprinting, Shodan/Censys infrastructure mapping, Sigma/HumINT.

## 1. Intelligence Source → Attack Mapping

| Sumber | Data | Red Team Use | MITRE ID | Stealth | Detection Gap |
|--------|------|-------------|----------|---------|----------------|
| **OSINT** (public) | Employee, tech stack, infra | Phishing target, CVE selection | T1591/T1589 | Pasif — no interaction | Tidak bisa deteksi |
| **Breach DB** | Credential dump | Credential stuffing, password spray | T1110.004 | Pasif — third party | Tidak bisa deteksi |
| **Shodan/Censys** | Exposed service, port, banner | Exploit target selection | T1590.004 | Pasif — pre-indexed | Tidak ada log di target |
| **Social Media** | Employee, role, location, pattern | Social engineering, physical recon | T1589 | Pasif (public) | Tidak bisa deteksi |
| **CT Logs** | Subdomain, cert history | Attack surface mapping | T1590.002 | Pasif — public | Tidak bisa deteksi |
| **DNS History** | Past record, IP history | Origin IP discovery (bypass CDN) | T1590.002 | Pasif — third party | Tidak bisa deteksi |
| **GitHub/GitLab** | Source code, config, credential | Credential theft, vuln discovery | T1552 | Pasif — public repo | Tidak bisa deteksi |
| **Court/Public Record** | Legal doc, corporate filing | Target identification, relationship mapping | T1591 | Pasif — public | Tidak bisa deteksi |
| **SigINT** (nation-state) | Communication intercept | Passive traffic recording, target tracking | T1590 | Pasif — no interaction | Tidak bisa deteksi |
| **HUMINT** | Insider, social engineering | Credential theft, insider threat enablement | T1589 | Active (social engineering) | Deteksi = behavioral baseline |

## 2. OSINT Fusion Chain

```
Phase 1 — Domain/Infrastructure:
 ├── crt.sh → subdomain enumeration
 ├── Shodan → exposed service, port
 ├── SecurityTrails → DNS history, origin IP
 ├── GitHub dork → credential, source code
 └── Wappalyzer → tech stack identification
 ↓
Phase 2 — Employee/People:
 ├── LinkedIn → employee, role, tech stack
 ├── theHarvester → email format
 ├── HaveIBeenPwned → breach data
 ├── Maltego → entity graph, relationship
 └→ Social media → photo, location, pattern
 ↓
Phase 3 — Fusion:
 ├── Correlate: employee ↔ infra ↔ credential
 ├── Infer: email format, password pattern, tech stack
 ├── Model: target profile (role, access, behavior)
 └→ Plan: phishing target, exploit vector, social engineering
 ↓
Phase 4 — Active Attack:
 ├── Phishing (AiTM) → credential + session token
 ├── Password spray → email format + breach data
 ├── Exploit → exposed service (Shodan target)
 └→ Social engineering → social media profile
```

## 3. Tool Stack Intelligence

| Tool | Source | Use |
|------|--------|-----|
| **Maltego** | Multi-source | Entity graph, relationship mapping |
| **Spiderfoot** | Multi-source | Automated OSINT collection |
| **theHarvester** | Email, subdomain | Email format, employee identification |
| **Shodan / Censys** | Infrastructure | Exposed service, port, banner |
| **SecurityTrails** | DNS history | Origin IP discovery, DNS history |
| **HaveIBeenPwned / DeHashed** | Breach | Credential dump lookup |
| **GitHub dork / Gitleaks** | Source code | Credential, config, source code |
| **Wappalyzer** | Web tech | Tech stack identification |
| **linge image search** | Image | Photo identification, location inference |

## 4. Referensi
- OSINT Framework — https://osintframework.com/
- Maltego — https://www.maltego.com/
- Shodan — https://www.shodan.io/
- HaveIBeenPwned — https://haveibeenpwned.com/
- Spiderfoot — https://www.spiderfoot.net/
---

audited
---
