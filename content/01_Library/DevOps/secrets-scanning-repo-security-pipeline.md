---
title: "Secrets Scanning & Repo Security Pipeline — Gitleaks, truffleHog, Pre-commit Hooks, Secret Rotation Playbook"
tags:
  - devops
  - security
  - secrets
  - cicd
  - git-security
  - library
aliases:
  - "Secrets Detection Pipeline"
  - "Git Secrets Scanning"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Secrets scanning adalah proses mendeteksi credential, token, API key, dan informasi sensitif lain yang secara tidak sengaja ter-commit ke repository Git. Dampak kebocoran secrets sangat serius — dari account takeover hingga data breach. Catatan ini mencakup perbandingan tools scanning (Gitleaks, truffleHog, detect-secrets, ggshield), integrasi pre-commit hooks, CI/CD gate, serta incident response playbook untuk leaked secrets.

**Domain Terkait:** [[devsecops-pipeline-sast-dast-sbom]] (CI/CD security) → [[cicd-shiftleft-shiftright]] (shift-left) → [[cicd-guide]] (pipeline) → [[incident-response-framework]] (respon) → [[software-supply-chain-security-deepdive]] (supply chain) → [[dependency-confusion-supply-chain-attacks-praktik]] (dependency)

---

## Daftar Isi
- [[#1. Mengapa Secrets Scanning Penting]]
- [[#2. Perbandingan Tools]]
- [[#3. Gitleaks — Git-Secrets Scanner]]
- [[#4. truffleHog — Deep Git Scanning]]
- [[#5. detect-secrets — Pre-commit Focus]]
- [[#6. Pre-commit Hooks Setup]]
- [[#7. CI/CD Gate Integration]]
- [[#8. False Positive Management]]
- [[#9. Incident Response — Leaked Secrets]]
- [[#10. Secret Detection Regex Patterns]]
- [[#11. Encrypted Secrets Storage (SOPS, age, Vault)]]
- [[#12. Referensi]]

---

## 1. Mengapa Secrets Scanning Penting

### Dampak Kebocoran Secrets

| Incident | Dampak | Year |
|---|---|---|
| AWS keys di GitHub public repo | $500K+ bill untuk mining crypto | 2022 |
| Slack token leaked via .env | Full channel access | 2023 |
| GitHub OAuth token di commit | Source code exfil | 2024 |
| OpenAI API key di pastebin | $100K+ usage dalam 3 jam | 2024 |

### Statistik

- **> 50%** dari organisasi mengalami leaked secrets setidaknya 1×
- **~1M** secrets baru terdeteksi di GitHub public per tahun
- **Rata-rata deteksi** setelah leak: 47 hari (dengan scanning otomatis: < 1 jam)

### Attack Vector

```
Developer commit .env → GitHub → Attacker scrape commit → Key aktif → Abuse API
        ↑                                ↑
    Waktu: +30 menit              Waktu: +5 menit (scanner otomatis)
```

---

## 2. Perbandingan Tools

| Tool | Bahasa | Git History | Regex | Entropy | ML | CI/CD |
|---|---|---|---|---|---|---|
| **Gitleaks** | Go | ✅ Full | ✅ Ya | ✅ Ya | ❌ | ✅ GitHub Actions, GitLab CI |
| **truffleHog** | Python | ✅ Full | ✅ Ya | ✅ Ya | ✅ (v3+) | ✅ GitHub Action |
| **detect-secrets** | Python | ⚠️ Diffs only | ✅ Ya | ✅ Ya | ❌ | ✅ (plugin) |
| **ggshield** (GitGuardian) | Python | ✅ Full | ✅ Ya | ✅ Ya | ✅ Cloud | ✅ |
| **SecretScanner** (Deepfence) | Go | ✅ Full | ✅ Ya | ✅ Ya | ❌ | ❌ Standalone |
| **GitLeaks Enterprise** | SaaS | ✅ Full | Custom | AI | ✅ | ✅ |

**Rekomendasi:**
- **Gitleaks** — tool all-rounder, cepat (Go), CI/CD ready, komunitas besar
- **truffleHog** — untuk scan deep git history dengan ML-enhanced detection
- **detect-secrets** — untuk pre-commit hooks ringan

---

## 3. Gitleaks — Git-Secrets Scanner

Gitleaks adalah tool scanning secrets berbasis Go — cepat, akurat, dan mudah diintegrasikan.

### Instalasi

```bash
# Fedora/Ubuntu
go install github.com/gitleaks/gitleaks/v8@latest

# Atau binary langsung
curl -sSfL https://github.com/gitleaks/gitleaks/releases/latest/download/gitleaks-linux-amd64 -o /usr/local/bin/gitleaks
chmod +x /usr/local/bin/gitleaks
```

### Scan Dasar

```bash
# Scan repo secara rekursif
gitleaks detect --source . -v

# Scan branch spesifik
gitleaks detect --source . --branch main

# Scan git history FULL (termasuk commit lama)
gitleaks detect --source . --log-opts="--all"

# Output JSON untuk processing
gitleaks detect --source . --report-path secrets-report.json --report-format json
```

### Config Custom (.gitleaks.toml)

```toml
title = "Custom Secrets Config"
extend_ignore_path = ".gitleaksignore"

[allowlist]
paths = [
  "node_modules/",
  "vendor/",
  "*.test.js",
  "*.spec.ts",
  "test/fixtures/"
]

[[rules]]
id = "myapp-custom-key"
description = "MyApp API Key"
regex = '''myapp_[a-zA-Z0-9]{32}'''
tags = ["myapp", "api-key"]
secret_group = 0
```

### Gitleaks Ignore

```bash
# Untuk false positive, tambahkan ke .gitleaksignore
gitleaks detect --source . --report-path report.json
# Parse hash dari report → tambahkan ke .gitleaksignore
echo "abc123def456hash:path/to/file:line:rule-id" >> .gitleaksignore
```

---

## 4. truffleHog — Deep Git Scanning

truffleHog v3 menggunakan entropy detection + ML untuk menemukan secrets.

### Instalasi

```bash
pip install truffleHog
```

### Scan

```bash
# Scan repo lokal
trufflehog git file://. --results=verified,unverified

# Scan GitHub org
trufflehog github --org=[REDACTED] --token=$GH_TOKEN

# Scan dengan only-verified (kurangi false positive)
trufflehog git file://. --only-verified
```

### JSON Output

```bash
trufflehog git file://. --json > truffle-report.json
```

Format output:

```json
{
  "SourceMetadata": {
    "Data": {
      "Git": {
        "commit": "abc123...",
        "file": "backend/.env",
        "email": "dev@example.com",
        "timestamp": "2026-07-01 12:00:00"
      }
    }
  },
  "SourceID": 1,
  "SourceType": "GIT",
  "SourceName": "repo-name",
  "DetectorName": "AWS Key",
  "DetectorType": 2,
  "Verified": true,
  "Raw": "AKIAIOSFODNN7EXAMPLE",
  "Redacted": "AKIAIOS******"
}
```

---

## 5. detect-secrets — Pre-commit Focus

detect-secrets dari Yelp adalah tool yang dirancang untuk **pre-commit** scanning — ringan, plugin-based.

### Instalasi

```bash
pip install detect-secrets
```

### Init Baseline

```bash
# Buat baseline (secrets yang sudah ada dianggap known)
detect-secrets scan > .secrets.baseline

# Audit baseline
detect-secrets audit .secrets.baseline
```

### Pre-commit Setup

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: 'package-lock.json|yarn.lock|*.lock'
```

---

## 6. Pre-commit Hooks Setup

### .pre-commit-config.yaml lengkap

```yaml
repos:
  # Gitleaks
  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks

  # detect-secrets sebagai backup
  - repo: https://github.com/Yelp/detect-secrets
    rev: v1.4.0
    hooks:
      - id: detect-secrets
        args: ['--baseline', '.secrets.baseline']
        exclude: '\.(lock|min\.js|map)$'
```

### Instalasi

```bash
pip install pre-commit
pre-commit install
pre-commit run --all-files  # Test semua file
```

---

## 7. CI/CD Gate Integration

### GitHub Actions

```yaml
# .github/workflows/secrets-scan.yml
name: Secrets Scan
on:
  push:
    branches: [main, staging, dev]
  pull_request:
    branches: [main]

jobs:
  gitleaks:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0  # Full history untuk scan

      - name: Gitleaks Scan
        uses: gitleaks/gitleaks-action@v2
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}

  trufflehog:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: truffleHog Scan
        uses: trufflesecurity/trufflehog@main
        with:
          extra_args: --only-verified
```

### GitLab CI

```yaml
secrets-scan:
  stage: security
  script:
    - apt-get update && apt-get install -y golang
    - go install github.com/gitleaks/gitleaks/v8@latest
    - gitleaks detect --source . --report-path gl-secrets.json
  artifacts:
    paths: [gl-secrets.json]
  only:
    - main
    - staging
```

### Block Policy

| Severity | Action |
|---|---|
| Verified secret | 🛑 **Block pipeline** |
| Unverified high entropy | ⚠️ Warning + manual review |
| Known false positive | ✅ Allow (via `.gitleaksignore`) |
| Baseline secret | ✅ Allow (known) |

---

## 8. False Positive Management

### Sumber False Positive

| Sumber | Contoh | Mitigasi |
|---|---|---|
| Test fixtures | `test/fixtures/tokens.json` | `.gitleaksignore` |
| Documentation | `README.md` contoh key | Path allowlist |
| Binary/vendor | `node_modules/`, `vendor/` | `paths` di config |
| Hash values | SHA256 di commit logs | Entropy threshold tuning |

### Entropy Threshold

```toml
# .gitleaks.toml
[entropy]
  # Default: 3.5 — naikkan untuk mengurangi FP
  # Turunkan untuk deteksi lebih agresif
  word = 4.0
```

---

## 9. Incident Response — Leaked Secrets

Ketika secret terdeteksi sudah terlanjur di-commit ke publik:

### Playbook

```
1. DETECT → Gitleaks/truffleHog report
2. TRIAGE → Apakah secret masih aktif? Bisa diverifikasi?
3. CONTAIN → Revoke key sekarang juga
4. REMEDIATE → Hapus dari git history
5. VERIFY → Scan ulang untuk confirm removal
6. POST-MORTEM → Root cause, prevent recurrence
```

### Step-by-step

#### Step 1: Revoke Sekarang

```bash
# AWS Key
aws iam delete-access-key --access-key-id AKIAIOSFODNN7EXAMPLE

# GitHub Token → Revoke via Settings → Developer Settings → Tokens

# Generic API Key → Login ke dashboard provider → Revoke
```

#### Step 2: Hapus dari Git History

```bash
# Opsi 1: BFG Repo-Cleaner (lebih cepat)
java -jar bfg.jar --delete-files .env repo.git

# Opsi 2: git filter-branch
git filter-branch --force --index-filter \
  "git rm --cached --ignore-unmatch .env" \
  --prune-empty --tag-name-filter cat -- --all

# Opsi 3: GitGuardian — paid, comprehensive
```

#### Step 3: Force Push

```bash
git push origin --force --all
git push origin --force --tags
```

#### Step 4: Rotate

```bash
# Generate key baru
openssl rand -base64 32
# Update di semua tempat yang memakai
```

#### Step 5: Cek GitHub Secret Scanning

```bash
# GitHub sendiri sudah scan public repos secara otomatis
# Cek: https://github.com/settings/security-alerts
```

---

## 10. Secret Detection Regex Patterns

| Secret Type | Pattern Example |
|---|---|
| AWS Access Key | `AKIA[0-9A-Z]{16}` |
| GitHub Token | `ghp_[a-zA-Z0-9]{36}` |
| GitLab Token | `glpat-[a-zA-Z0-9\-]{20,}` |
| Slack Token | `xox[baprs]-[a-zA-Z0-9\-]{10,}` |
| OpenAI API Key | `sk-[a-zA-Z0-9]{20,}` |
| JWT Token | `eyJ[a-zA-Z0-9\-_]+\.eyJ[a-zA-Z0-9\-_]+\.[a-zA-Z0-9\-_]+` |
| Generic Base64 | `(?:[A-Za-z0-9+/]{40,}={0,2})` |
| Private Key | `-----BEGIN (RSA\|EC\|OPENSSH\|DSA) PRIVATE KEY-----` |
| Password in URL | `https://user:password@host` |
| .env assignment | `[A-Z_]+=[A-Za-z0-9\-_]{8,}` |

---

## 11. Encrypted Secrets Storage (SOPS, age, vault)

### Mozilla SOPS + age

```bash
# Generate age key
age-keygen -o ~/.config/sops/age/key.txt

# Encrypt .env
sops --encrypt .env > .env.enc

# Decrypt
sops --decrypt .env.enc > .env
```

### Git Integration

```yaml
# .sops.yaml
creation_rules:
  - path_regex: \.env\.enc
    age: <age-public-key>
```

### HashiCorp Vault (untuk production)

```bash
# Store
vault kv put secret/myapp DB_PASSWORD=supersecret

# Read
vault kv get -field=DB_PASSWORD secret/myapp
```

---

## 12. Referensi

- **Gitleaks:** https://github.com/gitleaks/gitleaks
- **truffleHog:** https://github.com/trufflesecurity/trufflehog
- **detect-secrets:** https://github.com/Yelp/detect-secrets
- **BFG Repo-Cleaner:** https://rtyley.github.io/bfg-repo-cleaner/
- **SOPS (Mozilla):** https://github.com/getsops/sops
- **HashiCorp Vault:** https://www.vaultproject.io/
- **GitHub Secret Scanning:** https://docs.github.com/en/code-security/secret-scanning

**Cross-link vault:**
- [[devsecops-pipeline-sast-dast-sbom]] — CI/CD security framework
- [[cicd-shiftleft-shiftright]] — shift-left security
- [[cicd-guide]] — pipeline guide
- [[incident-response-framework]] — respon leaked secrets
- [[software-supply-chain-security-deepdive]] — supply chain risk
- [[dependency-confusion-supply-chain-attacks-praktik]] — dependency
- [[00_Atlas/hierarchy-package-managers]] — package manager
---

audited
---
