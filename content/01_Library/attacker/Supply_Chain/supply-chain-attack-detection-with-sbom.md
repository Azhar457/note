---
title: Supply Chain Attack Detection with SBOM
tags: [devsecops, supply-chain, sbom, dependency-confusion, security]
aliases: [sbom-audit, dependency-attack-detection, software-bill-of-materials]
created: '2026-08-14'
updated: '2026-08-14'
status: pending
cssclasses:
  - wide-table
  - callout

references:
  - url: https://spdx.dev/
    title: SPDX Specification
  - url: https://cyclonedx.org/
    title: CycloneDX Standard
  - url: https://nvd.nist.gov/
    title: NVD — National Vulnerability Database
related_notes:
  - software-supply-chain-security-deepdive
  - dependency-confusion-deep-dive
  - devsecops-pipeline-sast-dast-sbom
---

# Supply Chain Attack Detection with SBOM — Deep Dive

> 💡 **Plot Twist — SBOM bukan sekadar "daftar file".** Di era `log4j` dan `xz-utils` backdoor, SBOM adalah *fingerprint* dari setiap komponen yang menyusun aplikasi kamu. Tanpa SBOM yang lengkap dan terverifikasi, kamu tidak bisa tahu apakah komponen baru adalah patch keamanan atau *trojan* yang diselipkan.

---

## 1. Konteks & Filosofi — Mengapa Supply Chain Jadi Vektor Paling Berbahaya?

Dependency modern bukan lagi "library kecil" — ini adalah *ekosistem* yang terdiri dari ribuan paket transitif. Satu paket populer seperti `express`, `lodash`, atau `requests` bisa memiliki puluhan dependensi, dan setiap dependensi itu bisa memiliki dependensinya sendiri. Ini menciptakan *attack surface* yang sangat luas.

> ⚠️ **Plot Twist — "Saya hanya pakai 3 library" adalah ilusi.** Di Python, `requests` saja menarik 4-6 paket. Di Node.js, `express` bisa membawa 50+ dependensi. Di Rust, `tokio` dan `serde` membawa ekosistem crates yang luas. Tanpa SBOM, kamu tidak tahu berapa banyak komponen yang sebenarnya berjalan di produksi.

Attack supply-chain modern tidak hanya *typosquatting* atau *dependency confusion*. Ini mencakup:

| Jenis Serangan | Mekanisme | Contoh Nyata |
|----------------|-----------|-------------|
|
 **Dependency Confusion** | Paket internal dengan nama sama di public registry | `npm` / `pypi` — attacker upload `internal-lib` yang lebih baru |
| **Typosquatting** | Nama paket mirip yang populer | `requests` → `reqeusts` |
| **Compromised Build Pipeline** | CI/CD yang diubah untuk menyisipkan kode | `SolarWinds` — `Orion` build server dikompromi |
| **Malicious Commit** | Contributor yang menyisipkan backdoor | `xz-utils` — backdoor di versi 5.6.0-5.6.1 |
| **Package Registry Poisoning** | Registry yang dikompromi atau mirror yang berbahaya | `npm` mirror tidak resmi |

---

## 2. SBOM — Apa Itu dan Kenapa Penting?

### 2.1 Definisi

**Software Bill of Materials (SBOM)** adalah dokumen formal yang berisi inventaris semua komponen perangkat lunak, termasuk:

- Nama komponen dan versi
- Hash kriptografis (SHA-256, SHA-512)
- Lisensi
- Hubungan dependensi (direct & transitive)
- Asal usul (repository, registry, build server)
- Status verifikasi (signed / unsigned)

> 💡 **Analogi Sederhana — SBOM seperti "label nutrisi" pada makanan kemasan.** Tanpa label, kamu tidak tahu apakah makanan itu mengandung alergen, pengawet berbahaya, atau bahan yang tidak kamu inginkan. SBOM adalah label nutrisi untuk software.

### 2.2 Format Standar

Ada dua format utama yang diakui industri:

| Format | Spesifikasi | Kelebihan | Kelemahan |
|--------|-------------|-----------|-----------|
|
 **SPDX** | `spdx.dev` | Standar ISO/IEC 5962, dukungan luas, format JSON/XML/YAML | Lebih kompleks, lebih detail |
| **CycloneDX** | `cyclonedx.org` | Ringan, dirancang untuk keamanan dan BOM, dukungan OWASP | Kurang detail lisensi dibanding SPDX |

Keduanya bisa digunakan bersamaan. Untuk audit keamanan, **CycloneDX** lebih praktis karena dirancang untuk *vulnerability analysis* dan *SBOM exchange*.

---

## 3. Implementasi SBOM — Tooling & Pipeline

### 3.1 Tool Produksi SBOM

Berikut adalah tooling yang terbukti dan aktif digunakan di ekosistem DevSecOps:

| Tool | Bahasa / Registry | Output | Catatan |
|------|-------------------|--------|---------|
|
 **Syft** | Container image, file system | SPDX / CycloneDX | Sangat cepat, bisa scan Docker image |
| **Trivy** | Container, filesystem, Git repo | SPDX / CycloneDX + vulnerability scan | Kombinasi SBOM + CVE scan |
| **Cyclonedx-python** | Python (`pip`, `poetry`, `pipenv`) | CycloneDX JSON | Integrasi mudah dengan `poetry` / `pip` |
| **Cyclonedx-gomod** | Go (`go mod`) | CycloneDX JSON | Scan `go.sum` |
| **Cyclonedx-npm** | Node.js (`package-lock.json`) | CycloneDX JSON | Scan semua dependensi transitif |

> ⚠️ **Pitfall — Banyak tool hanya menghasilkan SBOM "statis" (snapshot saat build).** Ini tidak cukup. Kamu perlu SBOM yang **dinamis** — diperbarui setiap kali ada perubahan dependensi, dan diverifikasi setiap kali deployment.

### 3.2 Pipeline CI/CD — Contoh GitHub Actions

Berikut contoh minimal workflow yang menghasilkan SBOM dan memverifikasi bahwa tidak ada perubahan yang tidak terotorisasi:

```yaml
name: Build & Verify SBOM
on:
  push:
    branches: [main]
  pull_request:

jobs:
  sbom:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Generate SBOM (CycloneDX)
        uses: anchore/sbom-action@v0.15.0
        with:
          format: cyclonedx-json
          output-file: sbom.json
      - name: Verify SBOM Integrity
        run: |
          # Pastikan hash SBOM tidak berubah sejak commit terakhir
          git diff HEAD~1 -- sbom.json || echo "SBOM changed — review required"
      - name: Upload SBOM Artifact
        uses: actions/upload-artifact@v4
        with:
          name: sbom-cyclonedx
          path: sbom.json
```

> 💡 **Catatan — Workflow ini minimal.** Untuk produksi, tambahkan langkah *signing* (Cosign / Notary), *vulnerability scanning* (Trivy), dan *policy enforcement* (OPA / Gatekeeper).

---

## 4. Deteksi Serangan Supply Chain — Strategi & Teknik

### 4.1 Deteksi Dependency Confusion

**Mekanisme Serangan:**
1. Attacker menemukan nama paket internal yang tidak ada di registry publik.
2. Attacker upload paket dengan nama sama (tapi versi lebih tinggi) ke registry publik (`npm`, `pypi`, `crates.io`).
3. Build server (jika salah konfigurasi) mengambil versi publik (lebih tinggi) alih-alih versi internal.
4. Kode berbahaya berjalan di produksi.

**Mitigasi:**

| Layer | Tindakan | Tool / Konfigurasi |
|-------|----------|---------------------|
|
 Registry | Gunakan registry privat (`nexus`, `artifactory`, `github packages`) | Konfigurasi `.npmrc`, `pip.conf` |
| Build | Lock versi (`package-lock.json`, `poetry.lock`, `Cargo.lock`) | Jangan gunakan `*` atau `^` tanpa verifikasi |
| CI/CD | Verifikasi hash (`sha256`) setiap dependensi | `npm ci --prefer-offline`, `pip install --require-hashes` |
| Audit | Bandingkan SBOM setiap build dengan SBOM baseline | `diff` SBOM JSON, alert jika ada komponen baru |

> ⚠️ **Pitfall — Lock file (`package-lock.json`) bukan jaminan keamanan.** Lock file hanya memastikan versi yang sama di-install. Itu tidak mencegah *dependency confusion* jika registry publik memiliki versi lebih tinggi yang belum terkunci. Solusinya: **gunakan registry privat sebagai mirror utama**, dan verifikasi setiap paket baru.

### 4.2 Deteksi Typosquatting

**Teknik Deteksi Otomatis:**

```python
# Contoh minimal — deteksi typosquatting berdasarkan Levenshtein distance
from Levenshtein import distance

POPULAR_PACKAGES = ["requests", "flask", "django", "numpy", "pandas"]

def detect_typosquatting(package_name: str) -> bool:
    for popular in POPULAR_PACKAGES:
        dist = distance(package_name, popular)
        if 1 <= dist <= 3:  # 1-3 karakter berbeda
            return True
    return False
```

> 💡 **Catatan — Ini hanya deteksi heuristik.** Untuk produksi, kombinasikan dengan database *known typosquatting packages* (seperti yang dipelihara oleh `Snyk` atau `OWASP Dependency-Check`).

---

## 5. Audit & Monitoring — Bagaimana Memastikan SBOM Tetap Valid?

### 5.1 Verifikasi Berkala

Setiap SBOM harus diverifikasi secara berkala. Ini bukan "sekali buat, lalu lupa". Berikut checklist audit minimal:

- [ ] **Hash Verifikasi** — Setiap komponen memiliki hash (`sha256`) yang cocok dengan registry resmi.
- [ ] **Versi Lock** — Tidak ada komponen yang berubah versi sejak build terakhir tanpa persetujuan eksplisit.
- [ ] **Lisensi Audit** — Setiap komponen memiliki lisensi yang kompatibel dengan kebijakan organisasi.
- [ ] **CVE Scan** — Setiap komponen dipindai terhadap database CVE (`NVD`, `OSV`, `GitHub Advisory`).
- [ ] **Source Verification** — Setiap komponen berasal dari registry yang terverifikasi (bukan mirror tidak resmi).

### 5.2 Dashboard Monitoring

Untuk organisasi yang sudah memiliki infrastruktur monitoring (`Prometheus`, `Grafana`), tambahkan metrik SBOM sebagai sumber data:

| Metrik | Deskripsi | Alert Threshold |
|--------|-----------|-----------------|
|
 `sbom_components_total` | Jumlah komponen di SBOM | — |
| `sbom_components_changed` | Komponen yang berubah sejak build terakhir | `> 0` → alert |
| `sbom_cve_count` | Jumlah CVE yang terdeteksi di komponen | `> 0` → alert (prioritas tinggi) |
| `sbom_unverified_sources` | Komponen dari sumber yang tidak terverifikasi | `> 0` → alert (prioritas kritis) |

> 💡 **Catatan — Metrik ini bisa diekspor sebagai Prometheus metrics** menggunakan script Python sederhana yang membaca `sbom.json` dan menghasilkan `.metrics` file untuk `node_exporter`.

---

## 6. Studi Kasus — Serangan Nyata dan Pelajaran

### 6.1 `log4j` (Log4Shell) — 2021

**Mekanisme:** Library `log4j` versi `2.14.1` memiliki kerentanan `JNDI` injection yang memungkinkan *remote code execution*.

**Pelajaran untuk SBOM:**
- Tanpa SBOM, organisasi tidak tahu berapa banyak aplikasi yang menggunakan `log4j`.
- SBOM memungkinkan *impact assessment* cepat — "aplikasi A, B, C menggunakan `log4j` → segera patch atau isolasi".
- SBOM juga memungkinkan *version tracking* — "apakah semua instance sudah di-upgrade ke `2.17.1`?"

> ⚠️ **Plot Twist — `log4j` bukan "hanya satu library".** Ini adalah *transitive dependency* dari ribuan aplikasi. Organisasi yang memiliki SBOM lengkap bisa mengidentifikasi semua aplikasi yang rentan dalam hitungan jam, bukan minggu.

### 6.2 `xz-utils` Backdoor — 2024

**Mekanisme:** Backdoor disisipkan dalam versi `5.6.0` dan `5.6.1` dari `xz-utils`, sebuah komponen sistem fundamental yang digunakan oleh `ssh` dan `systemd`.

**Pelajaran untuk SBOM:**
- Backdoor ini tidak terdeteksi oleh scanner CVE standar (karena belum ada CVE saat pertama kali disisipkan).
- SBOM dengan *hash verification* bisa mendeteksi perubahan — "hash `xz` tidak cocok dengan versi resmi dari registry".
- SBOM dengan *source verification* bisa mendeteksi asal — "paket ini berasal dari mirror tidak resmi atau build server yang tidak terverifikasi".

---

## 7. Roadmap Implementasi — Dari Nol Sampai Produksi

### 7.1 Fase 1 — Awareness & Inventory (Minggu 1-2)

- [ ] Identifikasi semua repository yang aktif.
- [ ] Buat SBOM statis untuk setiap repository menggunakan `Syft` atau `Trivy`.
- [ ] Dokumentasikan semua komponen utama (`requests`, `express`, `tokio`, dst).`

### 7.2 Fase 2 — Pipeline Integration (Minggu 3-4)

- [ ] Integrasikan `SBOM generation` ke setiap `pull request` dan `merge`.
- [ ] Tambahkan `hash verification` untuk semua dependensi baru.
- [ ] Buat `baseline SBOM` untuk setiap cabang utama (`main`, `release`).

### 7.3 Fase 3 — Audit & Alert (Minggu 5-6)

- [ ] Aktifkan `CVE scanning` otomatis (`Trivy` / `Snyk` / `OWASP Dependency-Check`).
- [ ] Buat `dashboard Grafana` untuk metrik SBOM.
- [ ] Konfigurasi `alerting` (Slack / Email / PagerDuty) untuk setiap perubahan SBOM yang tidak terotorisasi.

### 7.4 Fase 4 — Continuous Improvement (Bulan 2+)

- [ ] Perbarui `policy enforcement` (`OPA` / `Gatekeeper`) untuk memblokir deployment jika SBOM tidak valid.
- [ ] Integrasi `SBOM signing` (`Cosign` / `Notary`) untuk memastikan integritas.
- [ ] Audit berkala — setiap bulan, verifikasi semua SBOM terhadap registry resmi dan database CVE terbaru.

---

## 8. Checklist Praktis — Sebelum Deployment

- [ ] SBOM sudah dihasilkan (`cyclonedx.json` atau `spdx.json`).
- [ ] Semua komponen memiliki hash (`sha256`) yang cocok dengan registry resmi.
- [ ] Tidak ada komponen baru yang tidak terverifikasi (`unverified_sources == 0`).
- [ ] Semua CVE terdeteksi sudah memiliki *mitigation plan* (patch, isolasi, atau penggantian).
- [ ] SBOM sudah di-*sign* (`Cosign`) dan diverifikasi sebelum deployment.
- [ ] Log audit tersedia (`audit.log`) untuk setiap perubahan SBOM.

---

## 9. Koneksi ke Catatan Lain

Catatan ini berkaitan erat dengan beberapa topik lain di vault:

- **[[dependency-confusion-deep-dive|Dependency Confusion Deep Dive]]** — mekanisme serangan yang dicegah oleh SBOM.
- **[[software-supply-chain-security-deepdive|Software Supply Chain Security Deep Dive]]** — gambaran besar serangan rantai pasokan.
- **[[devsecops-pipeline-sast-dast-sbom|DevSecOps Pipeline]]** — integrasi SBOM dalam pipeline CI/CD.
- **[[incident-response-framework|Incident Response Framework]]** — prosedur tanggap saat SBOM mendeteksi anomali.
- **[[master-index|Master Index]]** — navigasi utama vault.

---

## 10. Referensi & Bacaan Lanjutan

### Dokumen Resmi

- [SPDX Specification](https://spdx.dev/) — spesifikasi lengkap SBOM SPDX.
- [CycloneDX Standard](https://cyclonedx.org/) — spesifikasi lengkap SBOM CycloneDX.
- [NIST SP 800-161 Rev. 1](https://csrc.nist.gov/publications/detail/sp/800-161/rev-1/final) — *Cybersecurity Supply Chain Risk Management Practices*.
- [CISA SBOM Guide](https://www.cisa.gov/sbom) — panduan praktis dari CISA.

### Tools & Repository

- [Syft](https://github.com/anchore/syft) — generator SBOM cepat untuk container.
- [Trivy](https://github.com/aquasecurity/trivy) — scanner kerentanan + SBOM generator.
- [Cyclonedx-python](https://github.com/CycloneDX/cyclonedx-python) — library Python untuk SBOM.
- [Dependency-Check](https://owasp.org/www-project-dependency-check/) — scanner OWASP untuk dependensi.

### Artikel & Analisis

- [How to Use SBOMs for Security](https://example.com/sbom-security-guide) — panduan praktis (contoh referensi).
- [Log4j Impact Assessment with SBOM](https://example.com/log4j-sbom-case-study) — studi kasus `log4j`.
- [xz-utils Backdoor Analysis](https://example.com/xz-backdoor-analysis) — analisis backdoor `xz-utils`.

---

> ⚠️ **Peringatan Akhir — SBOM bukan "solusi ajaib".** Ini adalah *salah satu lapisan pertahanan* dalam strategi keamanan rantai pasokan. Tanpa verifikasi berkala, tanpa audit, dan tanpa respons cepat saat anomali terdeteksi, SBOM hanya menjadi dokumen statis yang tidak berguna. Gunakan SBOM sebagai bagian dari *defense-in-depth* bersama dengan registry privat, signing, dan audit berkelanjutan.

---

*Catatan ini dibuat sebagai bagian dari *Vault Audit* — referensi file asli (`TESTFROMDARKNET` — `DARKNETFORUM.txt`, `PROMPT INJECTION.txt`, dst) tetap tidak diubah (`mtime` asli), dan semua referensi `.md` di dalam catatan ini merujuk ke file yang sudah ada di vault. Status: **pending** — siap untuk verifikasi dan audit lebih lanjut.*