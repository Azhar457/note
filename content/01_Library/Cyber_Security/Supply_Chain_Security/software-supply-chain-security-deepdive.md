---
title: Software Supply Chain Security Deepdive
tags:
- cyber-security
- library
- supply-chain-security
created: '2026-07-02'
updated: '2026-07-02'
status: pending
cssclasses: ''
---

# 🔗 SOFTWARE SUPPLY CHAIN — Deep Dive: Dari `npm install` sampai State-Sponsored Backdoor

> Di era 2026, hampir setiap aplikasi modern bergantung pada **ratusan library pihak ketiga** — satu `pip install`, satu `npm i`, satu `go get`, dan kamu sudah mengimpor kode dari puluhan maintainer yang tidak kamu kenal. Masalahnya: **trust tidak bisa diskalakan**. Supply chain attack bukan lagi teori — ini adalah vektor kompromi paling efektif yang digunakan APT, ransomware gangs, dan scammers. Dokumen ini membedah **setiap lapisan supply chain security**, dari dependency confusion sampai SLSA Level 4, dari SBOM sampai politik geopolitik backdoor.

> [!info] Hubungan ke Vault
> Ini adalah deep dive utama untuk topik Supply Chain. Terkait erat dengan [[cicd-shiftleft-shiftright|CI/CD Shift-Left/Right]] (DevSecOps pipeline), [[ebpf-kernel-security|eBPF Kernel Security]] (runtime verification), [[comprehensive-threat-directory|Threat Directory]] (profil threat actor), dan [[web-hacking-exploitation|Web Hacking]] (dependency confusion dalam konteks web).

---

## Daftar Isi

- [[#Mengapa Supply Chain? — Kenapa Ini Vektor Paling Berbahaya]]
- [[#Layer 0 — Attack Surface: Titik Masuk Supply Chain]]
- [[#Layer 1 — Dependency Confusion & Typosquatting]]
- [[#Layer 2 — Compromised Package (Backdoor di Sumber)]]
- [[#Layer 3 — Build Pipeline & CI/CD Poisoning]]
- [[#Layer 4 — Package Registry Poisoning]]
- [[#Layer 5 — Hardware & Firmware Supply Chain]]
- [[#SLSA — Supply Chain Levels for Software Artifacts]]
- [[#SSDF — NIST Secure Software Development Framework]]
- [[#SBOM — Software Bill of Materials]]
- [[#in-toto & Sigstore — Verified Supply Chain]]
- [[#Deteksi & Proteksi — Tooling]]
- [[#Real-World Case Studies]]
- [[#Koneksi ke Vault]]

---

## Mengapa Supply Chain? — Kenapa Ini Vektor Paling Berbahaya

```
ATTACK SURFACE TRADISIONAL:
  Aplikasi → vulnerability di kode sendiri → exploit → kompromi

SUPPLY CHAIN ATTACK:
  Developer A publish library → Library di-download 10.000 project
  → Hanya 5% project yang audit dependency mereka
  → Attacker compromise satu maintainer / inject backdoor
  → Satu kompromi → 10.000 korban

EFISIENSI ATTACKER:
  Satu backdoor di paket populer → efek kaskade ke seluruh ekosistem
  Contoh: event-stream (npm) — 8M download/minggu, injected by social engineering
```

| Metrik | Angka |
|--------|-------|
| Rata-rata dependency per project (JS) | 1.200+ |
| Rata-rata dependency per project (Python) | 250+ |
| Package baru per hari (npm) | 1.700+ |
| Package baru per hari (PyPI) | 500+ |
| % developer yang audit dependency | < 5% |
| Supply chain attack increase (2020→2026) | 5.000%+ |

---

## Layer 0 — Attack Surface: Titik Masuk Supply Chain

Setiap titik di alur software development adalah vektor supply chain attack:

```
DEVELOPER        → REPOSITORY     → BUILD → REGISTRY → DEPLOY → RUNTIME
│                │                │       │          │        │
├─ Credential    ├─ Branch push   │       ├─ Malicious│       ├─ Runtime dep
│  compromise   ├─ PR injection   │       │  upload   │        │  loading
├─ Social        ├─ Git config    │       ├─ Registry ├─ CD    ├─ Update
│  engineering  │  poisoning     │       │  takeover │  hijack│  poisoning
├─ MFA bypass   ├─ Webhook       │       ├─ Name     │        ├─ Config
├─ Laptop theft  │  hijacking    │       │  squatting│        │  injection
                │                │       │           │        │
                └── CI/CD ───────┘       └───────────┘        └─────────
                      ↑
                Build cache poisoning
                Dependency confusion (internal)
                Test dependency injection
```

### Klasifikasi Berdasarkan Entry Point

| Layer | Entry Point | Contoh Kasus | Tingkat Kesulitan Attacker |
|-------|-------------|--------------|---------------------------|
| 0 | Developer machine | `npm` token dicuri, GPG signing key bocor | 🟢 Rendah—Sedang |
| 1 | Dependency resolution | Dependency confusion, typosquatting | 🟢 Rendah |
| 2 | Package content | Backdoor di source code library | 🟡 Sedang |
| 3 | Build pipeline | CI/CD script injection, cache poisoning | 🟡 Sedang—Tinggi |
| 4 | Package registry | Registry takeover, CDN cache poisoning | 🔴 Tinggi—Sangat Tinggi |
| 5 | Vendor/Manufacturer | Hardware backdoor, firmware implant | 🔴🔴 State-level |

---

## Layer 1 — Dependency Confusion & Typosquatting

### Dependency Confusion

```
PRINSIP:
  Package manager (pip, npm, gem, etc.) menggunakan urutan prioritas
  untuk resolve nama package:
  1. Private registry / internal
  2. Public registry (PyPI, npmjs.com, rubygems.org)

JIKA NAMA PAKET SAMA, PUBLIC BISA MENANG:
  - npm: public registry default
  - pip: --extra-index-url bisa di-prioritaskan
  - Attacker upload 'internal-sdk' ke PyPI → developer install dari public

EKSPLOITASI REAL:
  1. Attacker cari nama package internal perusahaan
     (dari leak, GitHub, Stack Overflow, job posting)
  2. Upload package dengan nama SAMA ke public registry
  3. Developer menjalankan `pip install` atau `npm install`
  4. Package manager mendownload dari public karena konfigurasi salah
  5. Kode attacker tereksekusi saat install (pre/post-install script)
```

#### Contoh Nyata: Uber Dependency Confusion (2022)

```
ATTACK:
  Researcher mengecek package.json library internal Uber
  → Upload 22 package dengan nama yang sama ke npm
  → npm install mendownload package milik researcher
  → Code execution di build server Uber

ROOT CAUSE:
  - npm registry scope (@uber/) tidak dikonfigurasi otentikasi
  - Package internal ter-expose di package.json (public repo)
  - npm install mix: campur public + private tanpa validasi
```

```json
// Contoh vulnerable package.json
{
  "dependencies": {
    "express": "^4.18.0",
    "@internal/auth-sdk": "^1.0.0",  // ← Nama bocor
    "@internal/crypto-utils": "^2.0.0"  // ← Attacker upload ke public
  }
}
```

### Typosquatting

```
PRINSIP:
  Attacker upload package dengan nama MIRIP dengan paket terkenal:
  - Typo umum: requets (vs requests), urlib3 (vs urllib3)
  - Homoglyph: уoutube-dl (Cyrillic 'у' vs 'y'), 'o' vs 'о'
  - Prefix/suffix:  requests-sdk, flask-extended
  - Domain mimic:  pip-install-flask

EKSEKUSI SAAT INSTALL:
  Python (setup.py): pre-install script
  npm: preinstall / postinstall hook
  Ruby gem: extconf.rb
  Rust crate: build.rs
```

#### Typosquatting Incident Tracker

| Ekosistem | Paket Palsu | Target | Download | Tahun |
|-----------|-------------|--------|----------|-------|
| PyPI | `urlib3` | `urllib3` | 10.000+ | 2022 |
| npm | `crossenv` | `cross-env` | 50.000+ | 2021 |
| npm | `electron-native-notify` | Telegram phishing | 100.000+ | 2023 |
| PyPI | `requests-httpx` | Credential theft | 5.000+ | 2024 |
| RubyGems | `typhoeus` (homoglyph) | `typhoeus` asli | 3.000+ | 2023 |

### Mitigasi Layer 1

```bash
# 1. PIN VERSI — jangan floating range
# ❌ Bad:
"express": "^4.x"
# ✅ Good:
"express": "4.18.2"

# 2. LOCKFILE — wajib di-commit
npm: package-lock.json
pip: requirements.txt + pip freeze > requirements.txt
go: go.sum
rust: Cargo.lock

# 3. PRIVATE REGISTRY ISOLATION
npm: --scope=@company --registry https://npm.internal.company.com
pip: --index-url https://pypi.internal.company.com/ --extra-index-url ...

# 4. VERIFY INTEGRITY
npm: npm audit + npm ci (gunakan lockfile)
pip: pip install --require-hashes
```

---

## Layer 2 — Compromised Package (Backdoor di Sumber)

```
PRINSIP:
  Paket populer yang SUDAH legitimate tiba-tiba mengandung backdoor
  karena:
  - Maintainer di-social engineering
  - Akun maintainer di-hack
  - Sertifikat signing dicuri
  - Dependency chain (backdoor di sub-dependency)

EKSEKUSI:
  - Pre/post install script
  - Runtime code execution
  - Prototype pollution (JS)
  - Deserialization attack
  - Hidden code di test file / contoh kode
```

### Chains of Trust Problem

```
Paket A (kamu install)
  └── Paket B (dependensi A)
       └── Paket C (dependensi B) ← backdoor ada DI SINI
            └── Paket D
                 └── Paket E
                      └── Paket F (tidak maintain sejak 2019)

Kamu tidak pernah lihat Paket C—F, mereka deep dependencies.
Satu backdoor di leaf package → compromise semua parent.
```

### Incident Besar

| Incident | Ekosistem | Dampak | Metode | Tahun |
|----------|-----------|--------|--------|-------|
| **event-stream** | npm | $8M/week download, Copay wallet drained $8M | Social engineering — attacker jadi maintainer | 2018 |
| **colors.js + faker.js** | npm | Ribuan project broken | Maintainer sengaja corrupt library | 2022 |
| **SolarWinds Orion** | Java/.NET | 18.000 organisasi, US Gov | Build pipeline compromise, signed trojan | 2020 |
| **Codecov Bash Uploader** | CI/CD | 30.000+ customer | Docker image credential leakage | 2021 |
| **3CX Desktop App** | Electron | 600.000+ organisasi | Supply chain di library trading (Caddy) | 2023 |
| **XZ Utils (liblzma)** | C/Linux | SSH backdoor (near-miss CVE-2024-3094) | 2 tahun social engineering maintainer | 2024 |

### XZ Utils — Paling Berbahaya yang Pernah Nyaris Terjadi

```
TIMELINE (2022–2024):
  2022-01: Github user "JiaT75" submit patch — memperbaiki bug
  2022-04: Menjadi co-maintainer setelah aktif bertahun-tahun
  2023-07: Inject backdoor di test file (bukan source code utama)
  2024-02: Backdoor aktif — modifikasi sshd (OpenSSH) via LD_PRELOAD
  2024-03: Terdeteksi oleh Andres Freund (Microsoft) — latency SSH

KRUSIAL:
  - 2 tahun infiltrasi
  - Backdoor di file .m4 (autoconf) — tidak di-review
  - Hampir masuk ke major distro (Debian, Fedora)
  - Jika berhasil: backdoor SSH global

LESSONS:
  - Review MAINTAINER sama penting dengan review CODE
  - Build artifact bisa berbeda dengan source code
  - Bus factor: 1 maintainer untuk library critical = risiko besar
```

### Mitigasi Layer 2

```bash
# 1. VULNERABILITY SCANNER — jangan skip
npm audit; pip-audit; cargo audit; grype .; trivy fs .
safety check -r requirements.txt

# 2. SCA (Software Composition Analysis)
#   Otomatis: Snyk, Dependabot, Renovate, Sonatype Nexus IQ
#   Deteksi: CVE, license risk, malware pattern

# 3. VENDOR REVIEW (untuk library kritis)
#   - Peer-reviewed source
#   - Maintainer reputation
#   - Update frequency
#   - OpenSSF Scorecard

# 4. ZERO TRUST DEPENDENCY
#   - Minimalize dependency (YAGNI untuk library juga!)
#   - Prefer stdlib / official SDK
#   - Audit sub-dependency chain
```

---

## Layer 3 — Build Pipeline & CI/CD Poisoning

```
PRINSIP:
  Serangan bukan di kode library, tapi di PIPELINE yang build kode:
  - Ganti script CI/CD (action, workflow)
  - Poison build cache
  - Compromise runner / agent
  - Inject artifact AFTER build (sebelum signing)

TAHAPAN EKSPLOITASI BUILD PIPELINE:
```

```
┌──────────────────┐     ┌──────────────────┐     ┌──────────────────┐
│  Developer Push  │────→│  CI/CD Runner    │────→│  Artifact        │
│                  │     │                  │     │  (binary/package)│
│  code            │     │  checkout        │     │                  │
│  action          │     │  install dep     │     │  signature: ✓    │
│  workflow        │     │  build           │     │  hash: SHA-256   │
│                  │     │  test            │     │                  │
└──────────────────┘     │  sign            │     └──────────────────┘
                         │  publish         │              ↑
                         │                  │       SERANGAN DISINI:
                         └──────────────────┘       - Inject setelah build
                              ↑                     - Replace artifact
                         SERANGAN DISINI:             - Tapi signature tetap valid
                         - Ganti action
                         - Poison cache
                         - Rogue runner
```

### Contoh Nyata

| Attack Vector | Contoh | Dampak |
|--------------|--------|--------|
| **GitHub Action poisoning** | `tj-actions/changed-files` compromised (2025) | 23.000+ repo terpapar credential leak |
| **Docker build cache poisoning** | Gunakan base image malicious | Setiap build ulang mengandung backdoor |
| **Runner compromise** | Access CI/CD agent → inject script | Code execution di pipeline |
| **Artefact replacement** | Ganti binary after build, before sign | Signed malware |
| **Pipeline-as-code hijack** | PR → edit `.github/workflows/` | Eksekusi arbitrary action |

### Mitigasi Layer 3

```yaml
# 1. PIN ACTIONS KE COMMIT SHA (bukan tag/version)
# ❌ Bad:
uses: actions/checkout@v4
# ✅ Good:
uses: actions/checkout@9bb56186c3b09b4f86b1c65136769dd318469633

# 2. WORKFLOW PERMISSION — minimal privilege
permissions:
  contents: read  # hanya baca
  packages: read

# 3. SIGNED COMMITS + CI/CD VERIFIKASI
git commit -S  # GPG sign
git tag -s v1.0.0

# 4. BUILD REPRODUCIBILITY
#   Heretic builds: binary yang sama persis dari source yang sama
#   Verifikasi: diffoscope antara binary hasil build lokal vs CI

# 5. PROVENANCE GENERATION
#   Generate SLSA provenance di setiap build
#   Simpan ke Rekor (sigstore) untuk audit trail
```

---

## Layer 4 — Package Registry Poisoning

```
PRINSIP:
  Menyerang REGISTRY tempat package di-hosting:
  - Registry takeover (npm.com, PyPI.com account squatting)
  - CDN cache poisoning (jsDelivr, UNPKG, cdnjs)
  - Mirror poisoning (registry.npmjs.org → mirror palsu)
  - Man-in-the-middle pada koneksi registry
```

### Registry Attack Vectors

| Attack | Target | Dampak |
|--------|--------|--------|
| **Account takeover** | Nama organization yang sudah tidak aktif | Semua user yang trust package ini |
| **Registry squatting** | Nama package yang sudah tidak di-maintain | Auto-update → backdoor |
| **CDN Poisoning** | jsDelivr, UNPKG, cdnjs | Semua site yang load dari CDN |
| **Typosquat registry URL** | `pypi-proxy.intenal.company.com` vs `pypi-proxy.internal.company.com` | Internal registry palsu |
| **Dependency proxy poisoning** | Artifactory/Nexus proxy ke public | Cache proxy bisa di-poison |

### Mitigasi Layer 4

```bash
# 1. MIRROR — verifikasi integrity
#   Gunakan registry official langsung (jangan mirror pihak ketiga)
npm config set registry https://registry.npmjs.org/
pip config set global.index-url https://pypi.org/simple/

# 2. SUBRESOURCE INTEGRITY (SRI) — untuk CDN
#   <script src="https://cdn.jsdelivr.net/npm/lodash@4.17.21/lodash.min.js"
#           integrity="sha384-..." crossorigin="anonymous">

# 3. PACKAGE SIGNING VERIFICATION
#   npm: npm audit signatures
#   Sigstore: cosign verify-blob ...
```

---

## Layer 5 — Hardware & Firmware Supply Chain

```
INI LEVEL PALING TINGGI — state-sponsored:
  - CPU/TPM backdoor di level silikon
  - BMC/iLO/iDRAC firmware compromise
  - UEFI BIOS injection
  - Network equipment backdoor (router, switch)
  - USB controller firmware trojan

CONTOH:
  - Supermicro BMC backdoor (Bloomberg 2018 — controversial)
  - Cisco router backdoor di kode VPN
  - Huawei equipment 5G — trust dispute geopolitik
  - AMD/Intel PSP/ME — closed-source firmware
```

Keterkaitan dengan [[hardware-hacking-re|Hardware Hacking & RE]] di vault.

---

## SLSA — Supply Chain Levels for Software Artifacts

```
FRAMEWORK DARI OpenSSF (Open Source Security Foundation):
  Level 0–4, mengukur seberapa TAHAN supply chain terhadap compromise.
```

### SLSA Levels

| Level | Nama | Persyaratan Utama | Proteksi Terhadap |
|-------|------|-------------------|-------------------|
| **L0** | No guarantees | Dokumentasi build | Tidak ada |
| **L1** | Build provenance | Provenance otomatis (source + build) | Retrospective audit |
| **L2** | Signed provenance | Provenance di-token/sign oleh build platform | Tamper evidence |
| **L3** | Hardened build | Build isolated, reproducible, no user-controlled steps | Tamper prevention |
| **L4** | Two-person review | L3 + setiap perubahan di-review oleh dua pihak | Insider threat |

### SLSA Build Provenance (format in-toto attestation)

```json
{
  "type": "https://in-toto.io/Statement/v1",
  "subject": [{
    "name": "app-linux-amd64",
    "digest": {"sha256": "abcd1234..."}
  }],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "buildType": "https://github.com/actions/build/gha/v1",
    "builder": {"id": "https://github.com/org/repo/.github/workflows/build.yml"},
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/org/repo@refs/heads/main",
        "digest": {"sha1": "deadbeef..."}
      }
    },
    "materials": [{
      "uri": "git+https://github.com/org/repo",
      "digest": {"sha1": "cafebabe..."}
    }]
  }
}
```

### Implementasi SLSA

```yaml
# Contoh GitHub Actions — SLSA Level 3
jobs:
  build:
    permissions:
      id-token: write
      contents: read
    steps:
      - uses: actions/checkout@9bb56186c3b09b4f86b1c65136769dd318469633
      - name: Build
        run: make build
      - name: Generate provenance
        uses: slsa-framework/slsa-github-generator/actions/delegator@v2.1.0
        with:
          provenance: true
      - name: Upload artifact + provenance
        uses: actions/upload-artifact@v4
        with:
          path: |
            dist/
            *.attestation
```

---

## SSDF — NIST Secure Software Development Framework

```
STANDAR RESMI US GOVERNMENT — SP 800-218:
  Response terhadap Executive Order 14028 (2021)
  Wajib untuk semua software yang dijual ke US Government.

4 PILLAR UTAMA:
  PO: Prepare Organization
  PS: Protect Software
  PW: Produce Well-Secured Software
  RV: Respond to Vulnerabilities
```

### SSDF Practices (Ringkasan)

| ID | Practice | Level |
|----|----------|-------|
| PO.1 | Define security requirements | Organization |
| PO.2 | Implement risk management | Organization |
| PO.3 | Implement secure software supply chain | Organization |
| PS.1 | Protect all forms of code | Code |
| PS.2 | Protect build pipeline | Build |
| PS.3 | Protect third-party components | Dependency |
| PW.1 | Design software to be secure | Design |
| PW.2 | Review design for security | Design |
| PW.3 | Reuse secure code | Code |
| PW.4 | Identify and handle vulnerabilities | Code |
| PW.5 | Verify software security | Test |
| PW.6 | Provide security headers | Deploy |
| RV.1 | Receive and analyze reports | Operation |
| RV.2 | Respond to vulnerabilities | Operation |
| RV.3 | Communicate results | Communication |

> [!tip] SSDF vs SLSA
> SSDF adalah **apa yang harus dilakukan** (framework kebijakan). SLSA adalah **bagaimana membuktikan bahwa kamu sudah melakukannya** (technical attestation). Keduanya komplementer.

---

## SBOM — Software Bill of Materials

```
DEFINISI:
  Inventaris formal dari semua komponen yang menyusun software:
  - Library (nama, versi, supplier)
  - Lisensi
  - Dependency tree
  - Known vulnerabilities (CVE mapping)

FORMAT STANDAR:
  - SPDX (ISO/IEC 5962:2021) — yang paling banyak diadopsi
  - CycloneDX (OWASP) — lebih kaya fitur (untuk security-native)
  - SWID (ISO/IEC 19770-2:2015)
```

### Contoh SBOM (CycloneDX Format)

```json
{
  "bomFormat": "CycloneDX",
  "specVersion": "1.5",
  "version": 1,
  "metadata": {
    "timestamp": "2026-07-02T00:00:00Z",
    "tools": [{
      "vendor": "Anchore",
      "name": "Syft",
      "version": "1.0.0"
    }],
    "component": {
      "name": "myapp",
      "version": "1.0.0",
      "type": "application"
    }
  },
  "components": [{
    "bom-ref": "pkg:pip/requests@2.31.0",
    "name": "requests",
    "version": "2.31.0",
    "purl": "pkg:pip/requests@2.31.0",
    "type": "library",
    "supplier": {
      "name": "Ken Reitz"
    },
    "licenses": [{
      "license": {
        "id": "Apache-2.0"
      }
    }]
  }]
}
```

### SBOM Workflow

```bash
# Generate SBOM
syft packages myapp:latest -o cyclonedx-json > sbom.json
# Generate SBOM untuk filesystem
syft dir:/project -o spdx-json > sbom-spdx.json

# Cek vulnerability dari SBOM
grype sbom:sbom.json
# Atau langsung dari image
trivy image myapp:latest --format cyclonedx > sbom-trivy.json

# Verifikasi signature SBOM
cosign verify-blob --signature sbom.json.sig --key cosign.pub sbom.json
```

### SBOM Mandatory Use Cases

```
2026 — SBOM SUDAH MANDATORY DI:
  - US Government (Executive Order 14028)
  - EU Cyber Resilience Act
  - Major cloud provider (AWS, GCP, Azure) — marketplace requirement
  - Startup akusisi due diligence
  - Insurance cyber security questionnaire

BEST PRACTICE:
  - Generate SBOM di setiap CI/CD build
  - Simpan SBOM sebagai artifact release
  - Sign SBOM signature (cosign)
  - Upload ke transparency log (Rekor)
  - Monitor SBOM diff antar versi
```

---

## in-toto & Sigstore — Verified Supply Chain

### in-toto

```
FRAMEWORK UNTUK VERIFIKASI INTEGRITAS SUPPLY CHAIN:
  - Layout: definisi step dan siapa yang berwenang
  - Link: metadata tiap step (dari mana, ke mana, hash)
  - Verification: cocokkan layout + link untuk autentikasi

STEP DALAM SUPPLY CHAIN (in-toto layout):
  source → build → test → package → sign → publish
   ↓        ↓       ↓       ↓         ↓        ↓
  Fungsi:  Fungsi: Fungsi: Fungsi:   Fungsi:  Fungsi:
  checkout  compile  run     package  sign     upload
                      test
```

### Sigstore

```
PROJECT OSS UNTUK CODE SIGNING + TRANSPARENCY:
  - Fulcio: Certificate Authority yang terintegrasi OIDC (GitHub/GitLab)
  - Rekor: Transparency log (tamper-proof, append-only)
  - Cosign: CLI untuk signing dan verification

ALUR SIGNING (TANPA MANAGE PRIVATE KEY!):
  1. Developer login ke GitHub
  2. Fulcio issue short-lived signing cert (via OIDC)
  3. Cosign sign artifact + cert
  4. Signing + cert di-log ke Rekor (permanent)
  5. Siapa pun bisa verify tanpa perlu public key (cukup trust Rekor)
```

```bash
# Sign container image
cosign sign ghcr.io/username/myapp:latest
# Verify
cosign verify ghcr.io/username/myapp:latest

# Sign SBOM
cosign attest --predicate sbom.json --type cyclonedx ghcr.io/username/myapp:latest
# Verify attestation
cosign verify-attestation --type cyclonedx ghcr.io/username/myapp:latest
```

---

## Deteksi & Proteksi — Tooling

### Scanner Supply Chain

| Tool | Fungsi | Ekosistem | Sumber |
|------|--------|-----------|--------|
| **Trivy** | Universal scanner (image, fs, SBOM, repo) | Semua | OpenSource |
| **Grype** | Vulnerability scanner untuk SBOM/images | Semua | OpenSource |
| **Syft** | SBOM generation | Semua | OpenSource |
| **OpenSSF Scorecard** | Health check repo GitHub | GitHub | OpenSource |
| **Dependency Check** | SCA untuk Java/.NET/Python | Java/.NET/Python | OWASP |
| **Snyk** | SCA + SAST + container | Semua | Commercial |
| **Socket.dev** | Deteksi malware/typessquatting di npm/PyPI | npm, PyPI | Commercial |
| **Renovate** | Auto update dependency + security PR | Semua | OpenSource |
| **Dependabot** | Auto dependency update (GitHub native) | GitHub | Free |
| **MurphySec** | Platform SSCS dengan SBOM, CVE, license | Java, Python, JS, Go | Commercial |

### OpenSSF Scorecard — Cek Repositori Pihak Ketiga

```bash
# Cek repo sebelum memakainya sebagai dependency
scorecard --repo=github.com/org/repo
# Output: 0-10 untuk tiap metrik
# - CI-Tests, CII-Best-Practices, Code-Review,
# - Contributors, Dependency-Update-Tool,
# - Maintained, Pinned-Dependencies, SAST,
# - Security-Policy, Signed-Releases, Token-Permissions
```

---

## Real-World Case Studies

### SolarWinds Orion (2020) — Paling Masif

```
METODE:
  1. ATTACKER (APT — kemungkinan Cozy Bear / APT29) compromise
     SolarWinds build pipeline
  2. Inject trojan di Orion.dll (signature tetap valid)
  3. SolarWinds sign build dengan trusted certificate
  4. Update dikirim ke 18.000+ organisasi (US Gov, Fortune 500)
  5. Backdoor: "Sunburst" — stealth C2 via HTTP

DAMPAK:
  - US Treasury, Commerce, Energy, DHS, DOD
  - Microsoft, FireEye (detector jadi korban)
  - FireEye mendeteksi sendiri di infra mereka
  - Estimated cost: > $100M (belum termasuk kerugian downstream)

TIMELINE:
  September 2019: Attacker mulai kompromi
  February 2020: Backdoor inject di build pipeline
  March 2020: Release Orion 2020.2 di-sign dan distribusi
  December 2020: FireEye/publik mengumumkan
  Total: 9 bulan undetected
```

### Codecov (2021) — Bash Uploader

```
METODE:
  1. Attacker compromise Codecov Docker image build
  2. Extract credential dari environment (CI/CD)
  3. Modify bash uploader (codecov/bash) — ekstrak env variable
  4. Setiap run CI/CD di customer → credential dikirim ke attacker

DAMPAK:
  30.000+ customer terpapar
  Kehilangan: GitHub tokens, cloud keys, npm tokens

LESSON:
  - Third-party CI/CD tools punya akses ke credential kamu
  - Environment variable di CI = sangat sensitif
  - Minimalize permission di CI/CD secrets
```

### XZ Utils / liblzma (2024) — Near-Miss Paling Berbahaya

```
- Backdoor di library kompresi yang digunakan oleh sshd (OpenSSH)
- Jika berhasil: remote SSH access tanpa autentikasi ke SEMUA server yang
  menggunakan systemd + OpenSSH
- Terdeteksi karena performance anomaly (latency SSH naik 500ms)
- Attacker spent 2 tahun maintain reputasi sebelum inject backdoor
- Backdoor di build artifact, bukan source code
```

### 3CX Desktop App (2023)

```
- VoIP app, Electron-based
- Installer yang di-sign legitimate
- Library trading (Caddy web server) compromised → supply chain masuk
- Backdoor exfiltrate data + C2 beacon
- 600.000+ organisasi terpapar
```

---

## Koneksi ke Vault

```
[[cicd-shiftleft-shiftright]]
  → CI/CD Shift-Left (keamanan di awal pipeline) adalah strategi utama
    untuk mendeteksi supply chain issue SEBELUM dependency masuk

[[comprehensive-threat-directory]]
  → Profil threat actor: APT29 (SolarWinds), Lazarus (3CX),
    UNC2565 (Codecov), JiaT75 (XZ)

[[ebpf-kernel-security]]
  → eBPF untuk runtime verification: deteksi anomali behavior
    dependency di production (Falco, Tetragon)

[[architectural-flaw-detection]]
  → Anti-pattern di dependency management:
    - Circular dependency
    - Unused import (dead weight)
    - Over-scoped dependency

[[web-hacking-exploitation]]
  → Dependency confusion sebagai vektor serangan ke web app

[[hierarchy-it-domain]]
  → Supply Chain Security sebagai sub-domain dari IT Security:
    Application Security → SCA / SBOM / Dependency Mgmt
    Infrastructure Security → Build / CICD Security
    Governance → SSDF / SLSA / Regulatory

[[hardware-hacking-re]]
  → Hardware supply chain — Layer 5 dari framework ini
```

### Mapping ke Master Index

Supply chain security duduk di **persimpangan antara**:

| Domain | Aspek Supply Chain |
|--------|-------------------|
| 🔐 **Application Security** | SCA, dependency audit, SBOM |
| 🏗️ **DevOps/Platform** | SLSA, build provenance, CI/CD hardening |
| 🛡️ **Infrastructure** | Registry security, eBPF runtime verification |
| ☁️ **Cloud Security** | Sigstore, Fulcio OIDC, Rekor transparency log |
| 📋 **Compliance** | SSDF, Cyber Resilience Act, EO 14028 |

---

>[!tip] Bottom Line
>Supply chain security bukan tentang **trust** — trust akan selalu di-exploit. Ini tentang **verification di setiap langkah**: signed provenance untuk setiap build, SBOM di setiap release, dan kemampuan untuk audit seluruh dependency tree sampai leaf terakhir. Satu library yang tidak di-maintain di kedalaman tree adalah satu titik kegagalan yang menunggu untuk dieksploitasi.
>
>Di era 2026, jika kamu tidak punya SBOM untuk aplikasi kamu — **kamu tidak tahu apa yang berjalan di production kamu.**
---

audited
---
