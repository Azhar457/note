---
title: Software Supply Chain Security — SLSA, In-toto, Sigstore & Dependency Attacks
tags:
  - supply-chain
  - slsa
  - in-toto
  - sigstore
  - sbom
  - dependency-confusion
  - reproducible-builds
created: "2026-07-19"
updated: "2026-07-19"
status: growing
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Supply chain security adalah lapisan keamanan yang melindungi **proses dari kode sampai deploy**. Catatan ini melengkapi [[devsecops-pipeline-sast-dast-sbom]] dengan framework SLSA, in-toto attestation, dan Sigstore signing. Juga relevan dengan [[exploit-development]] karena supply chain attack (SolarWinds, Log4j, xz) adalah salah satu vector paling efektif saat ini.
>
> **Domain:** Cyber Security / Supply Chain
> **Tags:** #supply-chain #slsa #in-toto #sigstore #sbom #dependency-confusion

## Daftar Isi

1. [Supply Chain Landscape](#1-supply-chain-landscape)
2. [SLSA Framework](#2-slsa-framework)
3. [In-toto Attestation](#3-in-toto-attestation)
4. [Sigstore & Code Signing](#4-sigstore--code-signing)
5. [Dependency Confusion Attacks](#5-dependency-confusion-attacks)
6. [Reproducible Builds](#6-reproducible-builds)
7. [SBOM — Software Bill of Materials](#7-sbom--software-bill-of-materials)
8. [Case Studies](#8-case-studies)
9. [Koneksi ke Vault](#9-koneksi-ke-vault)

## 1. Supply Chain Landscape

### 1.1 Trust Boundaries in Software Delivery

```
Developer                              Package Registry
┌────────┐    ┌───────┐    ┌──────┐    ┌──────────┐
│ Commit │───→│ Build │───→│ Test │───→│ Publish  │───→ Consumer
└────────┘    └───────┘    └──────┘    └──────────┘
    ↑            ↑            ↑            ↑
 1. Code      2. Build     3. CI/CD     4. Registry
 Poison       Hijack       Compromise   Compromise

Runtime
┌──────────┐
│ Install  │ ←── 5. Dependency confusion
│ & Run    │     6. Typo-squatting
└──────────┘     7. Malicious update
```

### 1.2 Attack Vectors per Phase

| Phase          | Attack                   | Example                              |
| -------------- | ------------------------ | ------------------------------------ |
| **Code**       | Backdoor in source       | SolarWinds (code injection in build) |
| **Build**      | Compromised build server | Codecov (build image poisoned)       |
| **Dependency** | Malicious package        | Event-stream (copay wallet hijack)   |
| **Registry**   | Account takeover         | npm account hijack                   |
| **Install**    | Dependency confusion     | Internal package vs public registry  |
| **Update**     | Compromised update       | CCleaner (signed trojan)             |
| **Runtime**    | Dynamic loading          | DLL sideloading                      |
| **Hardware**   | Firmware backdoor        | Supermicro BMC                       |

## 2. SLSA Framework

### 2.1 SLSA Levels

SLSA (Supply-chain Levels for Software Artifacts) — framework untuk meningkatkan kepercayaan artifacts.

| Level  | Name              | Requirements                                   | Implication              |
| ------ | ----------------- | ---------------------------------------------- | ------------------------ |
| **L1** | Build provenance  | Package has provenance (who, what, when built) | Minimal trust            |
| **L2** | Hosted build      | Build runs on hosted CI (not dev machine)      | Trust the build platform |
| **L3** | Hardened build    | Hermetic build + no user-controlled steps      | Hard to tamper           |
| **L4** | Two-person review | All changes reviewed + reproducible build      | Maximum assurance        |

### 2.2 SLSA Build Provenance (In-toto format)

```json
{
  "_type": "https://in-toto.io/Statement/v1",
  "subject": [{ "name": "app:v1.0.0", "digest": { "sha256": "abc123..." } }],
  "predicateType": "https://slsa.dev/provenance/v1",
  "predicate": {
    "builder": { "id": "https://github.com/org/repo/.github/workflows/build.yml" },
    "buildType": "https://github.com/actions/workflow/v1",
    "invocation": {
      "configSource": {
        "uri": "git+https://github.com/org/repo.git@refs/heads/main",
        "digest": { "sha1": "git-commit-hash-here" }
      }
    },
    "materials": [
      { "uri": "git+https://github.com/org/repo", "digest": { "sha1": "abc" } },
      { "uri": "pkg:docker/alpine@3.19", "digest": { "sha256": "def" } }
    ]
  }
}
```

### 2.3 SLSA Generation with GitHub Actions

```yaml
# .github/workflows/build.yml
jobs:
  build:
    permissions:
      id-token: write # Needed for OIDC (keyless signing)
      contents: read
    steps:
      - uses: actions/checkout@v4

      - uses: slsa-framework/slsa-github-generator/.github/actions/generate-provenance@v2
        with:
          base64-subjects: "${{ needs.build.outputs.digests }}"

      - uses: slsa-framework/slsa-github-generator/.github/actions/upload-provenance@v2
```

## 3. In-toto Attestation

### 3.1 How In-toto Works

In-toto mendefinisikan **layout** (siapa boleh ngapain) dan menghasilkan **link metadata** (bukti bahwa step dijalankan).

```
Layout (signed by project owner):
┌────────────────────────────────┐
│ Step 1: tag v1.0 (by maintainer)│
│ Step 2: build (by CI)          │
│ Step 3: package (by release mgr)│
│ Step 4: test (by CI)           │
└────────────────────────────────┘
         ↓
Each step produces link metadata:
link-tag.json  → proves "maintainer" ran "tag"
link-build.json → proves "CI" ran "build"
link-package.json → proves "release-mgr" ran "package"
link-test.json  → proves "CI" ran "test"
         ↓
Verification: verify ALL links match layout → artifact trusted
```

```bash
# Create in-toto layout
cat > layout.json << 'EOF'
{
  "signatures": [...],
  "steps": [
    {"name": "build", "expected_command": ["make"], "threshold": 1},
    {"name": "test", "expected_command": ["make test"], "threshold": 1}
  ],
  "inspect": [
    {"name": "verify-bin", "expected_materials": [["CREATE", "Dockerfile"]]}
  ]
}
EOF

# Generate link metadata after running step
in-toto-run --step-name build --materials src/ --products build/ -- make

# Link verification
in-toto-verify --layout layout.json --layout-key owner.pub
```

## 4. Sigstore & Code Signing

### 4.1 Sigstore Architecture

Sigstore menyederhanakan code signing dengan **keyless signing** menggunakan OIDC identity.

```
Developer                    Fulcio (CA)                Rekor (Transparency Log)
    │                           │                             │
    │── OIDC token (GitHub) ──→│                             │
    │                           │── Verify identity          │
    │←── Short-lived cert ─────│                             │
    │                           │                             │
    │── Sign artifact + cert ──│─────────── Entry ──────────→│
    │                           │                             │
    │←─────────────────────── Signed entry hash ─────────────│
    │                           │                             │
    │ Publish artifact + sig    │                             │
```

### 4.2 Cosign Usage

```bash
# Keyless signing (OIDC — no key management!)
cosign sign ghcr.io/user/app:v1.0.0

# Verify
cosign verify ghcr.io/user/app:v1.0.0

# Key-based signing
cosign generate-key-pair
cosign sign --key cosign.key ghcr.io/user/app:v1.0.0
cosign verify --key cosign.pub ghcr.io/user/app:v1.0.0

# Verify with identity policy
cosign verify \
  --certificate-identity-regexp ".*@example.com" \
  --certificate-oidc-issuer https://accounts.google.com \
  ghcr.io/user/app:v1.0.0
```

### 4.3 Comparison: Signing Methods

| Method                 | Key Management      | Trust Model      | Best For             |
| ---------------------- | ------------------- | ---------------- | -------------------- |
| **GPG**                | Manual key pairs    | Web of trust     | Open source projects |
| **Cosign (key-based)** | Store keys securely | Key ownership    | Internal/enterprise  |
| **Cosign (keyless)**   | None (OIDC)         | Identity-based   | CI/CD pipelines      |
| **Notary**             | TUF delegation      | Signed timestamp | Docker content trust |
| **Sig store**          | KMS                 | Cloud HSM        | High-security        |

## 5. Dependency Confusion Attacks

### 5.1 How It Works

```
Internal package:    @mycompany/auth-lib
Public npm registry: auth-lib (by attacker)

When pip/npm/yarn resolve dependency:
1. Check internal registry
2. Check public (npmjs.org, PyPI)
3. If internal name matches public → public wins!

Attack: publish auth-lib to npm → pip install → attacker's package runs
```

### 5.2 Defense

```bash
# npm: force scope
npm config set @mycompany:registry https://internal-npm.mycompany.com

# pip: extra-index-url vs index-url
# ❌ Dangerous: checks PyPI FIRST, then internal
pip install --extra-index-url https://internal-pypi.mycompany.com auth-lib

# ✅ Safe: only check internal
pip install --index-url https://internal-pypi.mycompany.com auth-lib --no-deps

# Ruby: namespacing with Gem::Specification
# All internal gems should have company prefix (internal-auth-lib)
```

## 6. Reproducible Builds

### 6.1 Concept

```
Same source → Same build environment → Same binary
                    ↓
Trust: you don't need to trust me — rebuild and compare!
```

### 6.2 Achieving Reproducibility

```python
# Sources of non-determinism in builds:
NON_DETERMINISTIC = [
    "Build timestamps (__DATE__, __TIME__ in C)",
    "Filesystem ordering (readdir order)",
    "CPU architecture (SIMD)",
    "Locale (collation order)",
    "Randomness (hash seed, ASLR)",
    "Network access (download versions)",
    "User/group IDs",
    "Build path (__FILE__ absolute path)",
    "Parallelism (non-deterministic merge)",
]

# Fix: strip timestamps
strip -X -K __DATE__ -K __TIME__ binary
# Or use SOURCE_DATE_EPOCH
export SOURCE_DATE_EPOCH=1704067200  # 2024-01-01
```

### 6.3 .buildinfo File

```bash
# Debian .buildinfo example
Format: 1.0
Source: python3-requests 2.31.0-1
Binary: python3-requests
Architecture: amd64
Build-Origin: Debian
Installed-Build-Depends: debhelper (>= 13), python3-all, python3-setuptools
Build-Environment:
  base-files (= 12.4),
  base-passwd (= 3.6.3),
  bash (= 5.2.15-2+b7),
  binutils (= 2.41-6)
Checksums-Sha256:
  abc123... 2024 python3-requests_2.31.0-1_all.deb
```

## 7. SBOM — Software Bill of Materials

### 7.1 SBOM Format: CycloneDX vs SPDX

| Aspect              | CycloneDX                        | SPDX                       |
| ------------------- | -------------------------------- | -------------------------- |
| **Focus**           | Security (vulns, pedigree)       | Licensing, compliance      |
| **Components**      | Direct + transitive dependencies | Same                       |
| **Vulnerabilities** | Native vulnerability model       | External reference         |
| **Formats**         | JSON, XML, Protobuf              | JSON, RDF, XLSX, tag:value |
| **Tooling**         | Syft, Trivy, Dependency-Track    | FOSSology, SPDX tools      |
| **Ecosystem**       | OWASP, OWTF                      | Linux Foundation           |

### 7.2 SBOM Generation Tools

```bash
# Syft — fast, modern (supports both formats)
syft packages alpine:latest -o cyclonedx-json > sbom.cdx.json
syft packages alpine:latest -o spdx-json > sbom.spdx.json

# Trivy — scanning + SBOM (image, filesystem, repo)
trivy image --format cyclonedx --output trivy.sbom alpine:latest
trivy repo --format spdx-json https://github.com/user/repo

# Gradle plugin for Android/Java
plugins {
    id("org.cyclonedx.bom") version "1.7.30"
}
./gradlew cyclonedxBom  # → build/reports/bom.json

# npm SBOM (CycloneDX)
npm install -g @cyclonedx/bom
cyclonedx-bom -o sbom.json
```

### 7.3 PURL (Package URL)

Standard format untuk identify package:

```
scheme:type/namespace/name@version?qualifiers#subpath

pkg:deb/debian/curl@7.50.3-1?arch=i386
pkg:docker/alpine@sha256:abc123
pkg:golang/github.com/gin-gonic/gin@v1.7.0
pkg:github/actions/checkout@v4
pkg:maven/org.apache.logging.log4j/log4j-core@2.17.0
pkg:npm/lodash@4.17.21
pkg:pypi/requests@2.31.0
```

## 8. Case Studies

### 8.1 SolarWinds (SUNBURST) — 2020

| Aspect          | Detail                                                 |
| --------------- | ------------------------------------------------------ |
| **Impact**      | 18,000+ customers compromised (US gov, Fortune 500)    |
| **Method**      | Build server compromise → inject trojan into Orion DLL |
| **Persistence** | Signed with SolarWinds cert → bypass all security      |
| **Detection**   | FireEye discovered after 8 months                      |
| **Root cause**  | Weak build server security, no SLSA provenance         |

### 8.2 Log4j (Log4Shell) — 2021

| Aspect              | Detail                                                     |
| ------------------- | ---------------------------------------------------------- |
| **Impact**          | ~10M affected instances, CVSS 10.0                         |
| **Method**          | JNDI injection via Log4j → RCE                             |
| **Fix delay**       | Months to patch entire supply chain                        |
| **SBOM importance** | Organizations took weeks to inventory where Log4j was used |

### 8.3 xz-utils Backdoor — 2024

| Aspect        | Detail                                                     |
| ------------- | ---------------------------------------------------------- |
| **Impact**    | Backdoor in SSH (Libsystem) — nearly shipped to millions   |
| **Method**    | 2-year social engineering → malicious binary in test files |
| **Detection** | Performance regression noticed by Microsoft engineer       |
| **SLSA**      | Would have caught: no provenance, no reproducible build    |

### 8.4 Other Notable

| Year | Attack       | Method                                | Impact                  |
| ---- | ------------ | ------------------------------------- | ----------------------- |
| 2017 | CCleaner     | Build server → signed trojan          | 2.27M users infected    |
| 2018 | Event-stream | Malicious dependency (flatmap-stream) | Copay wallet hijack     |
| 2019 | Webmin       | Backdoor in source code               | 130K servers            |
| 2021 | Codecov      | Docker image credential leak          | All customers exposed   |
| 2022 | PyTorch      | Dependency confusion (torch-nightly)  | Build chain compromised |
| 2024 | XZ           | YEARS-long social engineering         | Critical SSH backdoor   |

## 9. Koneksi ke Vault

| Note                                              | Hubungan                                          |
| ------------------------------------------------- | ------------------------------------------------- |
| [[devsecops-pipeline-sast-dast-sbom]]             | SAST/DAST/SCA + SBOM dalam pipeline CI/CD         |
| [[exploit-development]]                           | Supply chain attack sebagai initial access vector |
| [[comprehensive-threat-directory]]                | Threat actor profile (APT supply chain attacks)   |
| [[incident-response-framework]]                   | IR playbook untuk supply chain compromise         |
| [[zero-trust-security]]                           | Zero-trust untuk build and deploy pipeline        |
| [[cloud-security-posture-management]]             | K8s admission control, image signing policy       |
| [[malware-analysis-reverse-engineering-playbook]] | Analyzing trojanized packages                     |

---

### 📚 Referensi

1. SLSA Framework: [https://slsa.dev/](https://slsa.dev/)
2. In-toto: [https://in-toto.io/](https://in-toto.io/)
3. Sigstore: [https://www.sigstore.dev/](https://www.sigstore.dev/)
4. Reproducible Builds: [https://reproducible-builds.org/](https://reproducible-builds.org/)
5. CycloneDX: [https://cyclonedx.org/](https://cyclonedx.org/)
6. SPDX: [https://spdx.dev/](https://spdx.dev/)
7. SolarWinds analysis: Mandiant report
8. "Securing the Software Supply Chain" — CNCF TAG Security
