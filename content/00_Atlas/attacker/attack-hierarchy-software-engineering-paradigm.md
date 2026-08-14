---
title: Attack Perspective — Software Engineering Paradigm (Red Team)
tags: [attack,red-team,software-engineering,paradigm,sdl,owasp,devsecops-gap]
source: hierarchy-software-engineering-paradigm.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Software Engineering Paradigm — Perspektif Penyerang

> Software engineering practice (SDLC, CI/CD, code review) = defense. Red team eksploitasi **gap di practice**: SAST miss, code review blind, dependency unverified, CI/CD no integrity check.

## 1. Attack Surface per SDLC Phase

| Phase SDLC | Defender Practice | Red Team Exploit Gap | MITRE ID | Teknik | Detection Gap |
|------------|------------------|----------------------|----------|--------|----------------|
| **Requirement** | Threat model | Threat model incomplete → unmodeled surface | T1590 | Attack unmodeled vector (WebSocket, GraphQL, gRPC) | Threat model = static document |
| **Design** | Architecture review | Architecture assumption (trusted internal) → east-west exfil | T1041 | Exploit trusted internal → lateral | Architecture review = one-time |
| **Coding** | Code style + review | Subtle injection in review → miss → production vuln | T1190 | Obfuscated SQLi/XSS → code review miss → prod | Human review = miss subtle pattern |
| **Build** | CI/CD pipeline | Dependency confusion, pipeline inject | T1195.002 | Malicious dependency → build → artifact | SBOM = generate, not verify behavior |
| **Test** | SAST/DAST + fuzz | SAST false negative → vuln shipped → prod | T1190 | Variant SAST blind (encoding, gadget) | SAST = pattern, not behavior |
| **Deploy** | Signed artifact | Signed artifact with stolen cert | T1195.002 | Stolen signing cert → sign malicious | Code signing = trust cert, not behavior |
| **Runtime** | RASP, monitoring | Runtime bypass → RASP = pattern | T1027 | Obfuscation → RASP blind | RASP = pattern, not behavior |
| **Maintain** | Patch management | Patch window delay → known CVE unpatched | T1190 | scan + exploit → pre-patch exploit | Patch delay > 30 days common |

## 2. SAST/DAST Bypass Chain

```
Recon: Identifikasi SAST/DAST tool (SonarQube, Checkmarx, Veracode)
 ↓
Bypass Method 1 — Encoding:
 ├── SAST: pattern match → change pattern → encode
 ├── SQLi: `' OR 1=1--` → SAST flag → `/**/OR/**/1=1/**/` → SAST miss
 ├── XSS: `<script>alert(1)</script>` → SAST flag → `<svg onload=...>` → miss
 └→ Impact: coded subtle → SAST pass → shipped → prod vuln
 ↓
Bypass Method 2 — Logic Flaw:
 ├── SAST = pattern, not logic → logic vulnerability = miss
 ├── IDOR: change /user/123 → /user/456 → no pattern → SAST blind
 ├── Race condition: concurrent request → SAST no concurrent → miss
 └→ Business logic flaw → SAST blind → prod vuln
 ↓
Bypass Method 3 — New Framework:
 ├── SAST rule = lag → new framework → no rule → miss
 ├── GraphQL injection → SAST no rule → miss → prod
 └→ WebSocket → DAST no WebSocket fuzz → miss → prod
 ↓
Bypass Method 4 — Gadget Chain:
 ├── SAST detect single sink → but chain combination → miss
 ├── Deserialization gadget → SAST no chain analysis → miss
 └→ Prototype pollution → SAST no JS prototype → miss
 ↓
Impact: Vuln shipped ke production → red team exploiting live target
```

## 3. Code Review Blindspot

| Blindspot | Konkret | Red Team Exploit |
|-----------|---------|------------------|
| **Subtle injection** | Unicode homoglyph (С vs C), zero-width char | Invisible char → code look legit but behave different |
| **Time-of-Check bug** | TOCTOU → review see single access → race exist | Race → privilege escalation |
| **Logic flaw** | Missing authorization check → review miss (not pattern) | IDOR → data accession |
| **Dependency** | Dependency update → review assume trusted → malicious | Supply chain via dependency |
| **Configuration** | Hardcoded secret in config → review miss config | Credential theft |
| **Race condition** | Concurrent access → review single-thread assume → race | Race → privilege escalation |

## 4. Patch Delay Exploit

```
CVE Published → Vendor patch release → Enterprise deploy patch
 ↑ ↑
 | |
 Red team operate Patch delay (30-90 days)
 (exploit pre-patch) (known CVE → unpatched)
 ↓
Attack:
 ├── Scan (Nuclei, Nmap NSE) → find unpatched service
 ├── Exploit (searchsploit, Metasploit) → known CVE → RCE
 └→ Patch delay window → guaranteed vulnerable target
 ↓
Evasion: Known CVE = signature exist, but:
 ├── Custom exploit (no framework) → no signature
 ├── Modify public exploit → change payload → AV signature miss
 └→ Slow exploitation → below threshold
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **SonarQube / Checkmarx** | SAST (defender — red team target to bypass) |
| **Nuclei** | Template-based scan → find known vuln |
| **searchsploit** | Known exploit → pre-patch target |
| **Semgrep** | Custom rule → variant detection |
| **Gitleaks** | Secret scan → hardcoded credential |

## 6. Referensi
- OWASP SDLC — https://owasp.org/www-project-secure-software-development-life-cycle/
- SLSA Framework — https://slsa.dev/
- Semgrep — https://semgrep.dev/
- Nuclei Templates — https://github.com/projectdiscovery/nuclei-templates
- Patch Delay (Vuln Management) — https://www.cisa.gov/known-exploited-vulnerabilities