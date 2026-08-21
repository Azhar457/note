---
title: "Supply Chain Security Hierarchy"
tags:
  - atlas
  - supply-chain
  - devsecops
  - SLSA
  - dependency
aliases:
  - "hierarchy-supply-chain-security"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  
---


# 🔗 HIERARKI SUPPLY CHAIN SECURITY — Dari `npm install` (Level 0) sampai SLSA L4 + Formal Provenance (Level 5)

> Satu perintah `pip install`, `npm i`, atau `go get` — dan kamu mengimpor kode dari puluhan maintainer yang tidak kamu kenal. Supply chain attack adalah **vektor kompromi paling efektif 2024–2026**: satu backdoor di library populer bisa menjangkau 10.000+ project dalam jam. Hirarki ini memetakan evolusi proteksi dari "tidak ada verifikasi" sampai "build provenance terverifikasi kriptografis." Untuk taksonomi attack surface + SLSA framework, lihat [[software-supply-chain-security-deepdive]].

> [!info] Cara Baca
> Level 0 = tanpa proteksi (hanya `npm install` + doa). Level 5 = SLSA L4 + Sigstore + in-toto. Setiap level menambah lapisan verifikasi — semakin tinggi level, semakin sulit attacker menyusup, tapi semakin mahal untuk build infrastructure-nya.

---

## Tabel Utama — Level 0 sampai Level 5

| 🔗 Level | 🧠 Approach | ⚡ Mekanisme | ☠️ Tembok Kematian | 🎯 Kapan Cukup |
|---|---|---|---|---|
| **Level 0** — Trust by Default | `npm install`, `pip install` tanpa lockfile, tanpa audit. "Siapa pun bisa publish, siapa pun kita percaya" | Tidak ada verifikasi. Satu maintainer bisa overwrite version, inject backdoor, atau unpublish | **Solarwinds (2020), CodeCov (2021), 3CX (2023)** — semua attacker inject di pipeline/CI yang tidak diverifikasi. **100% exposure** | Development lokal, prototype, personal project tanpa data |
| **Level 1** — Lockfile & Integrity Check | `package-lock.json`, `pip freeze > requirements.txt`, `go.sum`, `yarn.lock`, `Cargo.lock` | Hash integrity setiap dependency. `npm ci` ketat: jika hash berbeda dari lockfile → install gagal. Deteksi perubahan tidak sengaja | Lockfile masih bisa di-poison (jika attacker compromise registry dan update package + resign hash). Tidak proteksi dari maintainer compromise | Startup, open source project, project dengan dependencies <50 |
| **Level 2** — Dependency Audit & SCA | `npm audit`, `pip audit`, Snyk, Dependabot, Renovate, Trivy, Grype, `osv-scanner` | **Software Composition Analysis**: scan known CVEs di dependency. Dependabot auto-PR update. Snyk: prioritasi berdasarkan reachability. `osv-scanner`: Google database CVE open-source | **Hanya CVE known.** Zero-day supply chain tidak terdeteksi. **Proteksi dari maintainer compromise → tidak di-cover → harus Level 3+. False positive tinggi** | Mid-size company, staging environment, SDLC tahap awal |
| **Level 3** — SBOM + Signature | SPDX/CycloneDX SBOM, Sigstore (Cosign, Fulcio, Rekor), `gitsign` | **SBOM (Software Bill of Materials)**: inventaris semua komponen. **Sigstore**: sign container/image dengan kunci ephemeral (Fulcio CA) + bukti publik di log Rekor (transparansi). **Cosign**: sign container image | Kunci ephemeral juga bisa expire. SBOM perlu update otomatis (masalah kebanyakan SBOM statis usang). Adopsi kontributor masih rendah | Regulated industry, compliance requirement, enterprise production |
| **Level 4** — SLSA L3 + Build Provenance | SLSA L3 (build platform terverifikasi), provenance attestation, hardened build pipeline | **SLSA L3**: build platform terverifikasi (isolasi, reproducibility, no custom steps). Provenance: klaim tentang bagaimana artifact dibangun — diverifikasi kriptografis. **in-toto**: attestation metadata sepanjang pipeline | SLSA L3 butuh CI/CD maturity tinggi. Reproducible build kadang sulit (Go bagus, C++ susah). Provenance membutuhkan infrastructure dedicated | Tech company mature, platform yang supply chain jadi competitive advantage |
| **☠️ Level 5** — SLSA L4 + Formal Provenance | SLSA L4 (two-person review, hermetic build, reproducible), formal provenance attestation | **SLSA L4**: perubahan hanya melalui two-person reviewed PR. Build hermetic (tidak bergantung pada source eksternal selain yang di-attest). Provenance di-verifikasi setiap deploy. Build bit-for-bit reproducible | **Mahal sekali.** Reproducible build untuk semua dependency (termasuk C, Rust dengan native code) hampir mustahil dalam praktik. Hanya organisasi dengan resources besar | Military, critical infrastructure, national security software |

---

## Peta Visual — Proteksi vs Coverage

```
Proteksi ↑
L5 ─ SLSA L4 + Formal Provenance     ●──●● Security coverage
L4 ─ SLSA L3 + Build Provenance     ●──●●
L3 ─ SBOM + Signature               ●──●
L2 ─ Dependency Audit + SCA        ●──●
L1 ─ Lockfile (Integrity)          ●─
L0 ─ Trust by Default              ●
    └──────────────────────────→ Attack surface coverage
         │               │                 │
    Dependency      Maintainer         Build
    confusion       compromise         pipeline
```

> [!warning] Level 2 (SCA) Adalah Baseline Minimum 2026
> Di 2026, tidak ada alasan untuk tidak menjalankan SCA. `npm audit` + Dependabot gratis untuk GitHub. `osv-scanner` gratis untuk semua. **Level 0 adalah reckless** untuk project yang digunakan orang lain atau menyimpan data. Level 2 adalah minimum viable security.

---

## Kenapa Hirarki Ini Penting

### 1. Supply Chain Attack Tidak Bisa Dideteksi Di Aplikasi

Backdoor di library populer akan:
- Lolos code review (reviewer tidak audit full library — hanya API call yang dipakai)
- Lolos SAST (static analysis tidak deteksi backdoor intent)
- Lolos unit test (backdoor path tidak dipanggil di test — hanya di production)
- Lolos runtime monitoring (sampai beacon call out)

Satu-satunya pencegahan adalah **preventive controls di pipeline**: signed artifact, provenance, SLSA.

### 2. Attack Surface Bukan Cuma Open Source Dependency

| Vector | Contoh | Level Mitigasi |
|---|---|---|
| Typosquatting | `requets` vs `requests` | L1 (lockfile) |
| Maintainer takeover | Compromise developer npm account | L3 (signature + SBOM) |
| Build pipeline CI/CD | Inject di GitHub Actions workflow | L4 (SLSA L3) |
| Hardware supply chain | Malicious chip di server | L5+ (beyond scope) |
| Registry compromise | npm/PyPI attacked directly | L3 (signature) |
| Dependency confusion | Internal package name diambil attacker di public registry | L1 (lockfile + prefix) |

### 3. SLSA = Standar Emas Untuk Supply Chain

SLSA (Supply-chain Levels for Software Artifacts) adalah framework yang dipakai Google, GitHub, OpenSSF. Empat level:

| SLSA | Build Requirement | Proteksi Dari |
|---|---|---|
| L1 | Documentation of build process | — (awareness only) |
| L2 | Hosted build + signed provenance | Dependency confusion |
| L3 | Hardened build (isolation, no custom steps) | Build pipeline poisoning |
| L4 | Two-person review + hermetic + reproducible | Maintainer compromise |

SLSA L4 + Sigstore + in-toto = **gold standard**. Tapi SLSA L2 + signature sudah mencegah 90% supply chain attack.

---

## Plot Twists

> [!danger] Plot Twist 1: Solarwinds (2020) Adalah Bukti SLSA L4 Penting
> Solarwinds: attacker inject backdoor di build pipeline (not source code). Produk Orion di-sign certificate resmi — signature valid, tapi binary berisi backdoor. Jika SLSA L4 di-enforce: two-person review + hermetic build → inject di pipeline mustahil karena perubahan ke build system harus lewat PR reviewed. **SLSA L4 bukan teori — dampak langsung ke real incident.**

> [!tip] Plot Twist 2: SBOM (L3) Wajib Secara Regulasi di 2025+
> US Executive Order 14028 (2021): semua software yang dijual ke government harus punya SBOM. EU Cyber Resilience Act (2024): supply chain transparency wajib. **SBOM bukan opsional lagi untuk regulated industry.** Indonesia? Belum — tapi global trend tidak terhindarkan untuk export/global product.

> [!warning] Plot Twist 3: Open Source Maintainer Burnout → Attack Surface Naik
> 58% open source maintainer unpaid (2024 survey). Satu maintainer handle 10+ library. Burnout → security update lambat → attacker exploit window. **Supply chain security harus di-support organisasi yang bergantung padanya** — via sponsorship, contribution, atau dedicated security team. xz utils backdoor (2024) nyaris sukses karena maintainer tunggal yang kewalahan.

> [!info] Plot Twist 4: Reproducible Build Susah — Tapi Paling Powerful
> Reproducible build: source yang sama → always binary yang identik (bit-for-bit). Jika build tidak reproducible, attacker bisa inject di kompilasi tanpa terdeteksi. Go, Rust bagus untuk reproducible. C/C++ (makro, __DATE__, PCH) sangat sulit. **Tapi reproducible build adalah ultimate verification bahwa build kamu bersih.**

---

## Rekomendasi Minimum per Profile

| Profil | Level Minimum | Alasan |
|---|---|---|
| **Personal project** | L1 (lockfile) | Gratis, proteksi dari accidental change |
| **Open source library** | L2 (SCA) + publish dengan signature | Tanggung jawab ke konsumen library |
| **Startup MVP** | L2 (SCA) + Dependabot | Proteksi dari known CVEs |
| **Enterprise production** | L3 (SBOM + Sigstore) | Compliance + incident response |
| **Regulated / Fintech** | L4 (SLSA L3 + provenance) | Audit requirement + risk management |
| **Critical infrastructure** | L5 (SLSA L4 + formal) | Zero trust supply chain |

---

## Sumber & Telusur Lebih Lanjut

- **Deep Dive Supply Chain** → [[software-supply-chain-security-deepdive]] (830 baris — attack surface, SLSA, Sigstore, in-toto)
- **CI/CD Pipeline** → [[cicd-shiftleft-shiftright]] (DevSecOps integration)
- **Container Security (Image Signing)** → [[cloud-infrastructure]] (Level 3–4, container supply chain)
- **Threat Directory** → [[comprehensive-threat-directory]] (supply chain threat actors)
- **Hardware Supply Chain** → [[hierarchy-hardware-hacking]] (Level 6–7 hardware backdoor)
- **Master Index** → [[master-index]]

---

> Hirarki supply chain security adalah **biaya trust**. Level 0 gratis — tapi membayar dengan trust buta. Level 5 mahal — tapi feedback-nya: "setiap baris kode yang masuk ke production bisa diverifikasi asal-usulnya." Pilih level yang sepadan dengan risiko yang bisa ditoleransi.

*Supply Chain Security Hierarchy | Level 0 (`npm install` + Doa) → Level 5 (SLSA L4 + Formal Provenance) · Semakin Tinggi, Semakin Terverifikasi Asal-Usul Kode*

audited
---
