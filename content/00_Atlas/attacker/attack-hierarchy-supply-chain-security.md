---
title: Attack Perspective — Supply Chain Security (Red Team)
tags:
- attack
- red-team
- supply-chain
- dependency-confusion
- sbom
- ci-cd
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Supply Chain — Perspektif Penyerang

> Supply chain attack = **kompromi trusted channel** — bukan menyerang target langsung, tapi menyerang vendor/dependency yang target percaya. Tipe: dependency confusion, CI/CD poison, compromised update, typosquatting.

## 1. Attack Vector Supply Chain

| Vektor | MITRE ID | Konkret | Tool / CVE | Evasion | Detection Gap |
|--------|----------|---------|------------|---------|----------------|
| **Dependency Confusion** | T1195.001 | Internal package namespace hijack — publish ke public registry dengan nama yang sama | npm, pip, PyPI | Package = valid, signature = valid | SBOM audit jarang; dependency pinning tidak universal |
| **CI/CD Poison** | T1195.002 | Inject malicious code ke build pipeline → artifact terinfeksi | GitHub Actions, GitLab CI, Jenkins | Signed commit (stolen token) | CI/CD log audit jarang |
| **Compromised Update** | T1195.002 | Hijack update server → push malicious update | SolarWinds (SUNBURST), 3CX | Signed binary (stolen signing cert) | Code signing verification = trust cert, not behavior |
| **Typosquatting** | T1195.001 | Package name mirip (fastapi vs fast-api) | npm, PyPI, crates.io | Name = valid package | Developer tidak audit dependency name |
| **Malicious PR** | T1195.002 | Open source contribution → malicious code hidden | GitHub PR, merge review | Social engineering (fake identity) | Code review manusia = miss subtle injection |

## 2. Supply Chain Kill Chain

```
Recon: Identifikasi internal package namespace (package.json, requirements.txt)
 ↓
Dependency Confusion: Publish package publik dengan nama internal
 ↓
Build system: Package manager resolve ke public registry (ranking lebih tinggi)
 ↓
CI/CD: Build download malicious package → execute install script
 ↓
Persistence: Malicious code embed di artifact → deploy ke production
 ↓
C2: Artifact production → phone home → attacker access
 ↓
Lateral: CI/CD runner compromise → cloud creds → lateral
 ↓
Exfil: Source code, secrets, customer data
```

## 3. CVE & Kasus Nyata

| Kasus | Target | Impact | Teknik | Red Team Lesson |
|-------|--------|--------|--------|-----------------|
| **SolarWinds (SUNBURST)** | Orion Platform (18,000+ customer) | Global government + enterprise compromise | Compromised update server → signed malicious DLL | Code signing tidak cukup — need behavior monitoring |
| **3CX** | Desktop app (600,000+ install) | Second-stage malware (Lazarus) | Compromised dependency (X_Trader) → cascading compromise | Multi-stage supply chain — trust chain broken di dependency level |
| **Codecov** | CI bash uploader | Credential theft (npm tokens, API keys) | Modified bash uploader → exfil CI env vars | CI/token exfil = silent, env vars = no log |
| **event-stream (npm)** | npm package (millions of download) | Wallet theft (Copay) | Maintainer handed off to attacker → malicious update | Maintainer trust = single point of failure |
| **XZ Utils (CVE-2024-3094)** | xz library (Linux everywhere) | SSH backdoor | Multi-year social engineering → Jia Tan → backdoor in build | Build system compromise = trusted binary with backdoor |

## 4. Tool Stack Supply Chain Attack

| Tool | Use | Target |
|------|-----|--------|
| **confUSED** | Dependency confusion attack PoC | npm, PyPI |
| **trivy** | Scan dependency for known vuln (defender-side, red team untuk identify target) | Container, IaC, package |
| **grype** | Vulnerability scan (same as Trivy) | Container image |
| **Syft** | SBOM generation | Container, filesystem |
| **Sigstore / cosign** | Artifact signing (defender) | Container, binary |
| **GitLeaks / TruffleHog** | Secret scan (CI/CD token, API key) | Git history, repo |

## 5. Detection & Defense Gap

| Kontrol Defender | Gap | Red Team Exploit |
|-------------------|-----|------------------|
| **SBOM (CycloneDX/SPDX)** | Generate saja — tidak verify behavior | Inject code yang tidak match SBOM rule |
| **Code signing (Sigstore)** | Trust cert, bukan behavior | Steal signing cert → sign malicious |
| **Dependency pinning** | Tidak universal — banyak org tidak pin | Public package rank lebih tinggi = resolve ke malicious |
| **SAST/DAST** | Scan source code, bukan runtime behavior | Malicious code di install script (pre/post hook) — tidak di source |
| **Provenance (SLSA)** | Level 1-4 — level tinggi jarang di-adopsi | SLSA level 1 = basic, attacker bypass |

## 6. Referensi
- SLSA Framework — https://slsa.dev/
- Sigstore — https://www.sigstore.dev/
- CycloneDX (SBOM) — https://cyclonedx.org/
- SolarWinds SUNBURST — https://www.cisa.gov/news-events/cybersecurity-advisories/aa21-077a
- XZ Utils Backdoor (CVE-2024-3094) — https://nvd.nist.gov/vuln/detail/CVE-2024-3094
---

audited
---
