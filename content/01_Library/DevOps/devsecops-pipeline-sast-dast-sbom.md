---
title: "DevSecOps Pipeline — Deep Dive: SAST, DAST, SCA, SBOM, dan Secret Scanning"
tags:
  - devops
  - devsecops
  - library
created: "2026-07-15"
updated: "2026-07-15"
status: pending
cssclasses: ""
---

# 🚀 DevSecOps Pipeline — Deep Dive: SAST, DAST, SCA, SBOM, dan Secret Scanning

> Panduan implementasi keamanan di pipeline CI/CD — dari Static Application Security Testing (SAST), Dynamic Application Security Testing (DAST), Software Composition Analysis (SCA), Software Bill of Materials (SBOM), hingga secret scanning. Mencakup toolchain konkret (Semgrep, CodeQL, ZAP, Trivy, Syft, Grype, Gitleaks), integrasi di GitHub Actions/GitLab CI, pipeline gates berdasarkan severity, serta strategi shift-left vs shift-right dalam konteks DevSecOps modern.

> [!info] Hubungan ke Vault
> Nota ini terkait dengan [[cicd-shiftleft-shiftright]] untuk framework strategi keamanan di SDLC, [[cicd-guide]] sebagai panduan implementasi pipeline dasar, [[container-kubernetes-security-deepdive]] untuk container image scanning di pipeline (Trivy, cosign), [[cloud-security-posture-management]] untuk IaC scanning (Checkov, tfsec), [[software-supply-chain-security-deepdive]] untuk rantai pasok perangkat lunak, dan [[api-security-deep-dive]] untuk DAST fokus API.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Apa Itu DevSecOps?

DevSecOps adalah filosofi yang mengintegrasikan praktik keamanan ke dalam setiap fase DevOps — bukan sebagai gate di akhir siklus, tetapi sebagai bagian dari pipeline otomatis sejak commit pertama.

Perbandingan pendekatan:

| Pendekatan                                   | Kapan Testing Dilakukan                    | Biaya Perbaikan           | Dampak Tim                                            |
| -------------------------------------------- | ------------------------------------------ | ------------------------- | ----------------------------------------------------- |
| **Traditional (Waterfall + Security Audit)** | Setelah development selesai, sebelum rilis | 💰💰💰💰💰 (paling mahal) | Security team = bottleneck                            |
| **DevOps + Security Gate**                   | Setelah build, sebelum deploy              | 💰💰💰                    | Security = blocker, banyak false positive             |
| **DevSecOps (Shift-Left)**                   | Pada setiap commit (IDE → PR → Build)      | 💰                        | Developer bertanggung jawab, security sebagai enabler |
| **DevSecOps + Shift-Right**                  | Pada setiap commit + di production         | 💰 (paling murah)         | Monitoring kontinu memvalidasi asumsi                 |

### Jenis Testing Keamanan Otomatis

| Kategori                                | Fokus                                                                       | Kapan Dijalankan              | Contoh                                     |
| --------------------------------------- | --------------------------------------------------------------------------- | ----------------------------- | ------------------------------------------ |
| **SAST (Static Analysis)**              | Source code scanning — menemukan vulnerability di kode tanpa menjalankannya | Pre-commit hook, PR, build    | Semgrep, CodeQL, SonarQube                 |
| **DAST (Dynamic Analysis)**             | Runtime scanning — menemukan vulnerability di aplikasi yang berjalan        | Staging, production (careful) | OWASP ZAP, Burp Suite Enterprise, Acunetix |
| **SCA (Software Composition Analysis)** | Dependency scanning — library/package vulnerability + license compliance    | PR, build, scheduled          | Trivy, Grype, Snyk, Dependabot             |
| **IAST (Interactive Analysis)**         | Hybrid SAST+DAST — agent di runtime memonitor code execution                | Staging test                  | Contrast Security, Hdiv, Checkmarx IAST    |
| **Secret Scanning**                     | Mencari credentials, API keys, tokens hardcoded                             | Pre-commit, PR, build         | Gitleaks, GitGuardian, TruffleHog          |
| **Container Scanning**                  | Image vulnerability, misconfiguration, malware                              | Build, registry push          | Trivy, Clair, Anchore                      |
| **IaC Scanning**                        | Infrastruktur code (Terraform, CloudFormation) misconfiguration             | PR, build                     | Checkov, tfsec, KICS                       |

#### SAST vs DAST — Kapan Memilih?

| Kriteria                | SAST                                                                 | DAST                                                                  |
| ----------------------- | -------------------------------------------------------------------- | --------------------------------------------------------------------- |
| **False Positive Rate** | Tinggi (banyak false positive karena tidak punya context runtime)    | Rendah (menyerang aplikasi nyata)                                     |
| **False Negative Rate** | Rendah (bisa menemukan vulnerability yang sulit ditemukan DAST)      | Tinggi (hanya bisa menemukan apa yang bisa 'dilihat' dari luar)       |
| **Cakupan**             | Source code (SQL injection, XSS, buffer overflow, hardcoded secrets) | Running app (authentication, session management, CSRF, configuration) |
| **Kecepatan**           | Cepat (millions LOC dalam menit)                                     | Lambat (tergantung cakupan crawl + attack)                            |
| **Kebutuhan env**       | Tidak perlu env running                                              | Perlu staging/prod environment                                        |
| **Integrasi PR**        | Mudah (di CI pipeline)                                               | Sulit (harus deploy dulu)                                             |

**Rekomendasi:** SAST di pre-commit + PR gate, DAST di staging environment setelah deploy.

### Software Bill of Materials (SBOM)

SBOM adalah manifest terstruktur yang mendaftarkan setiap komponen/package/artifact yang digunakan dalam perangkat lunak. Format standar:

| Format                                    | Standar           | Struktur                                      |
| ----------------------------------------- | ----------------- | --------------------------------------------- |
| **SPDX** (Software Package Data Exchange) | ISO/IEC 5962:2021 | Berbasis tag-value atau JSON-LD               |
| **CycloneDX**                             | OWASP standard    | XML atau JSON, lebih ringan                   |
| **SWID** (ISO 19770-2)                    | ISO               | Tagging standar untuk software identification |

**Mengapa SBOM penting:**

- **Log4j (Dec 2021)** — ribuan tim tidak bisa mengidentifikasi apakah mereka menggunakan log4j yang rentan karena tidak punya SBOM.
- **Regulasi** — US Executive Order 14028 mewajibkan SBOM untuk software pemerintah; EU CRA (Cyber Resilience Act) mensyaratkan SBOM untuk produk digital.
- **Supply-chain transparency** — Anda tidak bisa melindungi apa yang tidak Anda ketahui.

**Perintah untuk menghasilkan SBOM dengan Syft:**

```bash
# Untuk container image
syft nginx:latest -o spdx-json > nginx-sbom.spdx.json

# Untuk file system
syft /app -o cyclonedx-json > app-sbom.cyclonedx.json
```

---

## Technical Deep-Dive

### Toolchain Lengkap dan Konfigurasi

#### 1. SAST — Semgrep

Semgrep adalah SAST engine open-source dengan dukungan 30+ bahasa dan ribuan rule community.

```bash
# Install
pip install semgrep

# Scan
semgrep --config auto --metrics=off .
```

**Konfigurasi GitHub Actions:**

```yaml
name: DevSecOps SAST
on:
  pull_request:
    branches: [main, develop]
jobs:
  semgrep-sast:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Semgrep SAST Scan
        uses: semgrep/semgrep-action@v1
        with:
          config: p/owasp-top-ten # OWASP Top 10 ruleset
          # config: r/python.lang.security  # Python specific
          # config: r/javascript.browser.security  # JS specific
      - name: Check for Critical Findings
        if: failure()
        run: |
          echo "::error::SAST menemukan critical vulnerability. Fix sebelum merge."
          exit 1
```

**Custom rule — Deteksi SQL Injection di Python (raw query):**

```yaml
rules:
  - id: python-sqli-raw
    patterns:
      - pattern: |
          cursor.execute("..." + $QUERY + "...")
      - pattern-not: |
          cursor.execute("SELECT * FROM t WHERE col = ?", [...])
    message: "Raw SQL query concatenation detected — possible SQL injection"
    languages: [python]
    severity: ERROR
```

#### 2. SAST — CodeQL (GitHub-native)

CodeQL menggunakan query-based analysis:

```yaml
name: CodeQL
on:
  push:
    branches: [main]
  pull_request:
    branches: [main]
jobs:
  analyze:
    runs-on: ubuntu-latest
    permissions:
      actions: read
      contents: read
      security-events: write
    strategy:
      fail-fast: false
      matrix:
        language: ["python", "javascript", "go"]
    steps:
      - uses: actions/checkout@v4
      - uses: github/codeql-action/init@v3
        with:
          languages: ${{ matrix.language }}
      - uses: github/codeql-action/analyze@v3
```

**CodeQL Query — Find Hardcoded Passwords:**

```ql
import python

from Module m, Call c
where m.getName() = "hashlib"
and c.getFunc() = m.attr("pbkdf2_hmac")
and exists(|
  c.getArg(2).(StrConst).getValue() = "password" or
  c.getArg(2).(StrConst).getValue().regexpMatch("(?i).*password.*")
|)
select c, "Potential hardcoded password in pbkdf2 call"
```

#### 3. DAST — OWASP ZAP

ZAP adalah leading open-source DAST tool:

```yaml
name: DevSecOps DAST
on:
  deployment_status:
jobs:
  zap-scan:
    if: github.event.deployment_status.state == 'success'
    runs-on: ubuntu-latest
    steps:
      - name: ZAP Baseline Scan
        uses: zaproxy/action-baseline@v0.12.0
        with:
          target: ${{ github.event.deployment_status.environment_url }}
          rules_file_name: ".zap/rules.tsv"
          cmd_options: "-I" # Active scan
      - name: Upload ZAP Report
        uses: actions/upload-artifact@v4
        if: always()
        with:
          name: zap-report
          path: report_html/
```

**ZAP rule exclusion (untuk mengurangi false positive):**

```
# .zap/rules.tsv
10003	IGNORE	# Passive: Weak Authentication Method (false positive di apps tanpa auth endpoint sendiri)
10021	IGNORE	# Passive: X-Content-Type-Options (app sudah handle di reverse proxy)
10106	IGNORE	# Passive: HttpOnly Session Cookie (library default setting)
```

#### 4. SCA + Container Scanning — Trivy

Trivy (Aqua Security) adalah all-in-one vulnerability scanner:

```bash
# Scan filesystem
trivy filesystem /app --severity CRITICAL,HIGH --exit-code 1

# Scan container image
trivy image nginx:latest --severity CRITICAL --exit-code 1

# Scan IaC
trivy config --severity CRITICAL --exit-code 1 ./terraform/

# Generate SBOM
trivy image --format cyclonedx --output result.cdx.json nginx:latest
```

**GitHub Actions:**

```yaml
- name: Trivy Filesystem Scan
  uses: aquasecurity/trivy-action@master
  with:
    scan-type: "fs"
    scan-ref: "."
    format: "sarif"
    output: "trivy-results.sarif"
    severity: "CRITICAL,HIGH"
- name: Upload Trivy to GitHub Security
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: "trivy-results.sarif"
```

#### 5. SBOM Generation — Syft + Grype

```yaml
- name: Generate SBOM
  uses: anchore/sbom-action@v0
  with:
    image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ github.sha }}
    format: spdx-json
    output-file: sbom.spdx.json

- name: Upload SBOM
  uses: actions/upload-artifact@v4
  with:
    name: sbom
    path: sbom.spdx.json
```

#### 6. Secret Scanning — Gitleaks

```yaml
name: Secret Scanning
on: [pull_request]
jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
      - uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
```

**Custom Gitleaks rules:**

```toml
# .gitleaks.toml
`rules`
id = "custom-aws-key"
description = "AWS Access Key ID"
regex = '''(?i)(?:ak|sk|AWS)[\s:=]+(?:A3T[A-Z0-9]|AKIA|ASIA)[A-Z0-9]{16}'''
tags = ["aws", "credentials"]

`rules`
id = "custom-jwt"
description = "JWT Token (common pattern)"
regex = '''eyJ[A-Za-z0-9-_=]+\.[A-Za-z0-9-_=]+\.?[A-Za-z0-9-_.+/=]*'''
tags = ["jwt", "token"]
```

### Pipeline Gate Strategy — Severity-Based

```
PR Created
  ├── Pre-commit hooks (client-side)
  │   ├── gitleaks (secret scanning — langsung reject commit)
  │   └── pre-commit hooks (linting + basic SAST)
  │
  ├── CI Pipeline: Build Phase
  │   ├── SAST (Semgrep/CodeQL)
  │   ├── SCA (Trivy/Grype)
  │   ├── Secret Scanning (Gitleaks/TruffleHog)
  │   └── IaC Scanning (Checkov)
  │
  ├── GATE: Fail on CRITICAL/HIGH → block merge
  │
  ├── CI Pipeline: Deploy to Staging
  │   └── DAST (ZAP/Burp)
  │       └── GATE: Fail on CRITICAL → block deploy to prod
  │
  ├── CI Pipeline: Image Signing
  │   ├── SBOM generation (Syft)
  │   ├── Cosign signing
  │   └── Push to registry
  │
  ├── Deploy to Production
  │   └── Shift-right monitoring (runtime)
  │       ├── WAF detection
  │       ├── RASP agent
  │       └── SIEM anomaly
  │
  └── Scheduled Scans
      ├── Weekly: Full SAST + SCA (all severities)
      ├── Monthly: DAST full scan
      └── On-demand: Penetration testing
```

### False Positive Management

SAST/DAST tools menghasilkan false positive (FP) — tanpa manajemen FP, developer akan mengabaikan semua alert.

| Strategi                 | Deskripsi                                                     | Implementasi                                     |
| ------------------------ | ------------------------------------------------------------- | ------------------------------------------------ |
| **Baseline**             | Bandingkan hasil scan dengan baseline yang sudah diverifikasi | Semgrep: `semgrep --config auto --baseline main` |
| **Suppression comments** | Developer bisa mark FP di source code                         | `# nosemgrep` / `// semgrep-ignore`              |
| **Path exclusion**       | Exclude direktori test, vendor, generated code                | `.semgrepignore` / `.trivyignore`                |
| **Severity downgrade**   | Turunkan severity untuk rule dengan FP tinggi                 | ZAP rules file: `10003 WARN`                     |
| **Aging policy**         | FP yang tidak muncul di N cycle otomatis di-archive           | SIEM + Jira integration                          |
| **Daily triage**         | Security engineer review FP report harian                     | Dashboard Grafana + CSV export                   |

---

## Advanced

### Supply Chain Level for Software Artifacts (SLSA)

SLSA (Supply-chain Levels for Software Artifacts) adalah framework keamanan rantai pasok yang menentukan tingkat kepercayaan artifact berdasarkan 4 level:

| Level      | Deskripsi                          | Persyaratan Minimum                                                         |
| ---------- | ---------------------------------- | --------------------------------------------------------------------------- |
| **SLSA 1** | Build process documented           | Provenance (metadata who built what from what source)                       |
| **SLSA 2** | Build process tamper-resistant     | Signed provenance + host build service                                      |
| **SLSA 3** | Hardened build process             | No user-controlled build steps, isolation, provenance includes dependencies |
| **SLSA 4** | Two-person review + hermetic build | All dependencies declared, fully reproducible build, provenance by design   |

**Cara mencapai SLSA 3+ untuk container image:**

```yaml
# GitHub Actions — SLSA 3 provenance generation
- name: Generate SLSA Provenance
  uses: slsa-framework/slsa-github-generator/.github/workflows/generator_container_slsa3.yml@v2.0.0
  with:
    image: ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}
    digest: ${{ steps.build-and-push.outputs.digest }}
```

### Cryptographic Signing — Cosign

Cosign (Sigstore) memungkinkan signing container image tanpa perlu private key management (keyless signing via OIDC):

```bash
# Sign image (keyless — menggunakan GitHub OIDC token)
cosign sign ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build-and-push.outputs.digest }}

# Verify
cosign verify ${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}@${{ steps.build-and-push.outputs.digest }}
```

**Policy Controller (Connaisseur/Kyverno)** — verifikasi signature sebelum mengizinkan pod running:

```yaml
apiVersion: kyverno.io/v1
kind: ClusterPolicy
metadata:
  name: verify-image-signature
spec:
  validationFailureAction: Enforce
  rules:
    - name: check-signature
      match:
        any:
          - resources:
              kinds:
                - Pod
      verifyImages:
        - imageReferences:
            - "harbor.corp.internal/*"
          attestors:
            - entries:
                - keyless:
                    subject: "https://github.com/corp-org/*/.github/workflows/*.yml@refs/heads/main"
                    issuer: "https://token.actions.githubusercontent.com"
```

### IaC Scanning — Checkov (Policy as Code)

Checkov untuk menemukan misconfiguration di Terraform:

```yaml
- name: Checkov IaC Scan
  uses: bridgecrewio/checkov-action@v12
  with:
    directory: terraform/
    framework: terraform
    output_format: cli
    soft_fail: false # block on any fail
    quiet: true
    skip_check: CKV_AWS_53 # skip known false positive
```

### Full Pipeline Example — GitHub Actions (Monorepo)

```yaml
name: Full DevSecOps Pipeline
on:
  pull_request:
    branches: [main]
jobs:
  pre-commit-checks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pre-commit/action@v3.0.1
        with:
          extra_args: --all-files --show-diff-on-failure

  security-scan:
    needs: pre-commit-checks
    runs-on: ubuntu-latest
    strategy:
      matrix:
        scan: [sast, sca, secrets, iac]
    steps:
      - uses: actions/checkout@v4

      - name: SAST — Semgrep
        if: matrix.scan == 'sast'
        uses: semgrep/semgrep-action@v1
        with:
          config: p/owasp-top-ten
          severity: ERROR

      - name: SCA — Trivy
        if: matrix.scan == 'sca'
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          scan-ref: "."
          format: "sarif"
          severity: "CRITICAL,HIGH"
          exit-code: "1"

      - name: Secrets — Gitleaks
        if: matrix.scan == 'secrets'
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

      - name: IaC — Checkov
        if: matrix.scan == 'iac'
        uses: bridgecrewio/checkov-action@v12
        with:
          directory: terraform/
          soft_fail: false

  build-and-scan:
    needs: security-scan
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Build container
        run: docker build -t app:${{ github.sha }} .
      - name: Container scan — Trivy
        run: trivy image --severity CRITICAL,HIGH --exit-code 1 app:${{ github.sha }}
      - name: SBOM — Syft
        run: syft app:${{ github.sha }} -o spdx-json --file sbom.spdx.json
      - name: Sign — Cosign
        run: cosign sign --keyless app:${{ github.sha }}

  deploy-staging:
    needs: build-and-scan
    runs-on: ubuntu-latest
    environment: staging
    steps:
      - name: Deploy to Staging
        run: |
          kubectl set image deployment/app app=app:${{ github.sha }} -n staging

  dast-staging:
    needs: deploy-staging
    runs-on: ubuntu-latest
    steps:
      - name: ZAP DAST Scan
        uses: zaproxy/action-full-scan@v0.12.0
        with:
          target: https://staging.app.corp
          rules_file_name: ".zap/rules.tsv"
          allow_issue_writing: false
          fail_action: true
```

### Tool Benchmark (Performa dan Akurasi)

| Tool          | Speed (1000 LOC)      | FP Rate                     | Coverage Bahasa                                                     | Harga                                |
| ------------- | --------------------- | --------------------------- | ------------------------------------------------------------------- | ------------------------------------ |
| **Semgrep**   | ~2 detik              | Medium                      | 30+                                                                 | Open source (community), Paid (team) |
| **CodeQL**    | ~5 detik              | Low (query-based)           | 12 (C/C++, C#, Java, JS, Python, Go, Ruby, Swift, Kotlin, Rust, TS) | Free for public repos                |
| **SonarQube** | ~10 detik             | Medium-High                 | 30+                                                                 | Community Edition gratis             |
| **Trivy**     | N/A (image: ~5 detik) | Low                         | OS packages + language packages                                     | Open source                          |
| **Grype**     | N/A                   | Low                         | Similar to Trivy                                                    | Open source                          |
| **ZAP**       | Depends on app size   | Medium (baseline lowers it) | Web/API                                                             | Open source                          |
| **Gitleaks**  | ~1 detik              | Low (with custom rules)     | Git history + filesystem                                            | Open source                          |
| **Checkov**   | ~3 detik              | Medium                      | Terraform, CloudFormation, K8s, ARM                                 | Open source                          |

### Hardening Checklist — DevSecOps Pipeline

```
☐ Pre-commit hook: gitleaks + basic linting
☐ PR gate: SAST (Semgrep/CodeQL) — fail on any CRITICAL/HIGH
☐ PR gate: SCA (Trivy/Grype) — fail on any CRITICAL
☐ PR gate: IaC scanning (Checkov) — fail on any misconfiguration
☐ PR gate: Secret scanning (Gitleaks/TruffleHog)
☐ Build: Trivy container scan — fail on CRITICAL
☐ Build: SBOM generation (Syft) — upload to artifact store
☐ Build: Image signing (Cosign) — keyless via OIDC
☐ Deploy to staging: DAST scan (ZAP/Burp) — fail on CRITICAL
☐ Deploy to staging: post-deployment validation test (non-functional)
☐ Deploy to prod: require SLSA 3 provenance
☐ Scheduled: weekly full SAST + SCA scan
☐ Scheduled: monthly full DAST scan
☐ Scheduled: SBOM diff analysis (new vuln detection)
☐ Incident: rapid patching pipeline (auto-trigger for disclosed CVEs)
```

---

## Case Studies

| Studi Kasus                             | Konteks                                                                 | Temuan Kunci                                                                                                                                                                                                                               | Mitigasi Diimplementasi                                                                                                                                                                                                        |
| --------------------------------------- | ----------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Log4j CVE-2021-44228 (Dec 2021)**     | Ribuan organisasi tidak tahu menggunakan log4j yang rentan              | 1. Tidak ada SCA — tim tidak punya visibility dependency mana yang mengandung log4j. 2. SBOM belum ada — manual triage butuh waktu berminggu-minggu. 3. Pipeline tidak bisa "block" build otomatis untuk versi log4j.                      | 1. Deploy SCA (Trivy) dengan block rule untuk semua CVE-critical. 2. Generate SBOM untuk semua service. 3. Automated pipeline untuk emergency patch (auto-bump dependency + build + deploy dalam <1 jam).                      |
| **Codecov Breach (2021)**               | Pipeline CI/CD tool compromise → supply-chain attack                    | 1. Codecov Bash Uploader terkena credential theft. 2. Attacker modify uploader → exfiltrate CI environment variables. 3. Ribuan organization exposed: cloud credentials, API keys, tokens.                                                 | 1. Gunakan OIDC-based auth (no static keys). 2. Rotate CI secrets. 3. Audit CI runner artifacts. 4. Minimum IAM untuk CI jobs.                                                                                                 |
| **Dependency Confusion (2021)**         | Internal package name sama dengan public — npm/yarn prioritaskan public | 1. Internal package `corp-auth` → attacker publish `corp-auth` ke npm dengan version lebih tinggi. 2. Pipeline auto-download dependency dari npm — malicious code executed. 3. POC: 35+ perusahaan besar terkena.                          | 1. Scoped registry: `@corp/` prefix. 2. Resolver strict — hanya dari private registry. 3. Integrity check (package lock + hash verification). 4. SCA yang mendeteksi dependency confusion.                                     |
| **SolarWinds Orion (2020)**             | Build pipeline compromise — malware di signed artifact SLSA 0           | 1. Attacker compromise build server → inject Sunburst backdoor ke Orion source code. 2. Code review tidak mendeteksi karena injeksi stealth dan legitimate signing. 3. 18,000+ customers menerima backdoor via update.                     | 1. SLSA 4 — hermetic build, two-person review. 2. Reproducible build — deteksi drift binary. 3. Immutable build environment. 4. Code signing + attestation. 5. ADR: diversifikasi supply chain.                                |
| **Simulated CI Pipeline Attack (2024)** | Penetration test — SAST + DAST + SCA integration                        | 1. SAST menemukan SQL injection di endpoint /search (query concatenation). 2. SCA menemukan 2 HIGH vuln di library `requests` (old version). 3. Secret scanning menemukan 3 AWS Access Keys di file .env.example (committed 2 tahun lalu). | 1. Pipeline block + developer notified via GitHub Security Alerts. 2. Rotate exposed keys in <30 menit. 3. Auto-approve PR untuk fix SAST/SEC findings. 4. Git history rewrite untuk remove secrets (force push with caution). |

---

## Koneksi ke Vault

- [[cicd-shiftleft-shiftright]] — framework strategis yang menjadi pijakan pipeline DevSecOps
- [[cicd-guide]] — panduan implementasi pipeline CI/CD yang sekarang diperkuat dengan layer keamanan
- [[container-kubernetes-security-deepdive]] — container scanning dan signing di pipeline
- [[software-supply-chain-security-deepdive]] — supply chain security yang diimplementasikan lewat SBOM, SLSA, dan Cosign
- [[cloud-security-posture-management]] — IaC scanning sebagai bagian dari pipeline
- [[api-security-deep-dive]] — fokus DAST untuk REST API dan GraphQL
- [[waf-reverse-proxy-deepdive]] — shift-right detection setelah deploy ke production
- [[comprehensive-threat-directory]] — taksonomi ancaman yang menjadi target scanning tools
- [[threat-modeling-deepdive]] — identifikasi ancaman yang harus di-cover oleh pipeline testing
- [[data-engineering]] — pipeline data juga perlu DevSecOps (schema validation, data quality)
- [[autonomous-system-design]] — DevSecOps untuk sistem otonom/agentic

---

## Referensi

1. OWASP. _Application Security Verification Standard (ASVS) 4.0_. https://owasp.org/www-project-application-security-verification-standard/
2. OWASP. _Software Component Verification Standard (SCVS)_. https://owasp.org/www-project-software-component-verification-standard/
3. Semgrep. _Semgrep Documentation_. https://semgrep.dev/docs/
4. GitHub. _CodeQL Documentation_. https://docs.github.com/en/code-security/codeql-cli/
5. OWASP ZAP. _ZAP Getting Started_. https://www.zaproxy.org/getting-started/
6. Aqua Security. _Trivy Documentation_. https://trivy.dev/latest/
7. Anchore. _Syft & Grype Documentation_. https://github.com/anchore/syft
8. Gitleaks. _Gitleaks Documentation_. https://gitleaks.io/
9. Bridgecrew/Prisma Cloud. _Checkov Documentation_. https://www.checkov.io/
10. Sigstore. _Cosign Documentation_. https://docs.sigstore.dev/cosign/overview/
11. OpenSSF. _SLSA Framework_. https://slsa.dev/
12. OWASP. _CycloneDX SBOM Standard_. https://cyclonedx.org/
13. SPDX. _SPDX Specification_. https://spdx.dev/
14. US Executive Order 14028. _Improving the Nation's Cybersecurity_. 2021. https://www.whitehouse.gov/briefing-room/presidential-actions/2021/05/12/executive-order-on-improving-the-nations-cybersecurity/
15. CISA. _Software Bill of Materials_. https://www.cisa.gov/sbom
16. OpenSSF. _Scorecard_. https://securityscorecards.dev/
17. Sonatype. _2024 State of the Software Supply Chain_. https://www.sonatype.com/state-of-the-software-supply-chain
18. Snyk. _2024 Open Source Security Report_. https://snyk.io/reports/
19. GitGuardian. _2024 State of Secrets Sprawl_. https://www.gitguardian.com/report
20. Contrast Security. _IAST vs SAST vs DAST_. https://www.contrastsecurity.com/knowledge-hub/what-is-iast

> [!tip] Bottom Line
> DevSecOps bukan tentang tool — ini tentang **shift-left mindset** yang diotomatisasi. Tool tanpa proses hanya menghasilkan noise; proses tanpa tool hanya menghasilkan bottleneck. Kunci sukses: (1) **Pipeline gate berbasis severity** — hanya CRITICAL/HIGH yang block, sisanya informasional. (2) **False positive management** — baseline + suppression agar developer tidak lelah. (3) **SBOM + Signing** sebagai syarat deploy ke production. (4) **Emergency pipeline** untuk zero-day seperti Log4j — auto-bump + rebuild + deploy dalam <1 jam. Mulai dari pre-commit gitleaks dan SCA — dua langkah dengan ROI tertinggi di DevSecOps.
