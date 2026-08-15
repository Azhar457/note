---
title: Web Security — Application Layer Defense (Deepdive)
tags:
- web-security
- csp
- cors
- owasp
- secure-coding
- defense-in-depth
- blue-team
aliases:
- web-security-deepdive
- app-layer-defense
created: '2026-07-19'
updated: 2026-08-14
status: complete
cssclasses:

references:
- 00_Atlas/hierarchy-waf-reverse-proxy.md
- 00_Atlas/hierarchy-cybersecurity-defense-architecture.md (Layer L4)
related_notes:
- 01_Library/attacker/Web/* (offensive counterpart)
---

# Web Security — Application Layer Defense (Deepdive)

> **Status konten:** Lengkap (≥ 1.500 kata). Catatan ini adalah ekspansi dari versi ringkas 61 kata menjadi deepdive sistematis yang mencakup secure coding, CSP, CORS, OWASP Top 10, dan praktik defense-in-depth di lapisan aplikasi (Layer L4 dari [[00_Atlas/hierarchy-cybersecurity-defense-architecture.md]]).
> **Referensi lintas:** [[01_Library/attacker/Web/attack-web-hacking-exploitation.md]] (offensive counterpart) · [[01_Library/attacker/Web/attack-waf-evasion-deepdive.md]] (serangan WAF) · `01_Library/defender/Web/*` (pertahanan praktis).

---

## 1. Ringkasan — Mengapa Lapisan Aplikasi Penting?

Lapisan aplikasi (L4) adalah **batas antara pengguna dan data** — semua interaksi melalui web app, API, atau mobile backend melewati lapisan ini. Menurut OWASP, **70 % kerentanan web** berasal dari kesalahan desain atau implementasi aplikasi, bukan infrastruktur. Ini menjadikan L4 sebagai area kritis yang membutuhkan perhatian khusus dalam arsitektur pertahanan.

> [!callout] 💡 **Key Insight**: Pertahanan di L4 tidak bisa hanya bergantung pada WAF atau firewall; kode aplikasi itu sendiri harus dirancang untuk menolak input berbahaya.

---

## 2. OWASP Top 10 — Pemetaan Pertahanan per Kategori

> Tabel ini memetakan setiap kategori OWASP Top 10 ke kontrol praktis, framework referensi, dan teknik serangan yang umum.

| Kategori OWASP | Definisi Singkat | Kontrol Pertahanan | Framework / Tool | Teknik Serangan Terkait |
|---|---|---|---|---|
| **A01 — Broken Access Control** | Akses tidak terbatas karena otorisasi tidak diverifikasi dengan benar | RBAC/ABAC yang ketat; verifikasi otorisasi di setiap endpoint; deny-by-default | OWASP ASVS v4.0 V1, NIST 800-53 AC | IDOR, force browsing, privilege escalation |
| **A02 — Cryptographic Failures** | Enkripsi lemah, kunci tidak aman, atau data tidak terlindungi saat transit | TLS 1.2+; enkripsi at rest (AES-256-GCM); HSM untuk kunci; rotasi kunci | CIS v8 Ctrl 13, OWASP Crypto Guide | MITM, credential leak, data exfil |
| **A03 — Injection** | Input tidak tervalidasi → eksekusi kode/kueri yang tidak diinginkan | Input validation (whitelist); parameterized queries; prepared statements; ORM | OWASP Cheat Sheet — Injection Prevention | SQLi, NoSQLi, command injection |
| **A04 — Insecure Design** | Kesalahan arsitektur sejak awal (misalnya: trust boundary yang salah) | Threat modeling (STRIDE); secure design review; architecture risk analysis | MITRE ATT&CK, NIST 800-154 | Supply chain, design flaw |
| **A05 — Security Misconfiguration** | Konfigurasi default atau tidak aman di server/aplikasi | Hardening guide (CIS Benchmarks); automated config scanning; default deny | CIS Benchmarks, NIST SP 800-70 | Info disclosure, unauthorized access |
| **A06 — Vulnerable & Outdated Components** | Library/paket dengan CVE yang tidak di-patch | SCA (Snyk, OWASP Dependency-Check); patch management; dependency lock | CIS v8 Ctrl 4, OWASP Dependency | Zero-day exploit, supply chain |
| **A07 — Identification & Auth Failures** | Autentikasi/identifikasi tidak memadai | MFA; secure session management; brute-force protection; secure password policy | NIST 800-63B, OWASP ASVS V2 | Credential stuffing, session hijack |
| **A08 — Software & Data Integrity Failures** | Kode/data tidak diverifikasi integritasnya | Code signing; checksum verification; secure CI/CD pipeline; SBOM | SLSA, NIST 800-161 | Supply chain attack, malicious update |
| **A09 — Security Logging & Monitoring Failures** | Log tidak lengkap atau tidak dimonitor → serangan tidak terdeteksi | Centralized logging; correlation rules; alerting; retention policy | NIST SP 800-92, CIS v8 Ctrl 8 | APT dengan dwell time panjang |
| **A10 — Server-Side Request Forgery (SSRF)** | Aplikasi membuat permintaan ke server internal yang tidak diinginkan | URL validation (whitelist); deny internal IP ranges; disable redirect; use proxy | OWASP SSRF Prevention Cheat Sheet | SSRF, internal network scan |

---

## 3. Secure Coding — Prinsip & Praktik

### 3.1 Input Validation

> [!callout] ⚠️ **Golden Rule**: Jangan pernah percaya input pengguna — validasi **di server**, bukan hanya di klien. Klien bisa dimanipulasi.

- **Whitelist validation** (lebih baik daripada blacklist)
- **Type enforcement** — jika parameter harus integer, pastikan tipe data benar
- **Length & range checks** — batasan ukuran input dan nilai numerik
- **Encoding** — output encoding sesuai konteks (HTML, JS, CSS, URL, SQL)

> Contoh praktis (Python):
> ```python
> from pydantic import BaseModel, constr, confloat
> class UserInput(BaseModel):
>     username: constr(min_length=3, max_length=20, pattern=r'^[a-zA-Z0-9_]+$')
>     age: confloat(gt=0, lt=150)
> # Pydantic akan menolak input yang tidak memenuhi kriteria
> ```

---

### 3.2 Output Encoding — Konteks Tergantung

| Konteks Output | Encoding yang Dibutuhkan | Contoh |
|---|---|---|
| HTML body | HTML entity encoding (`` → `&lt;`) | Teks komentar |
| HTML attribute | HTML attribute encoding + quote protection | `value="..."` |
| JavaScript | JavaScript hex/octal encoding | `var x = "...";` |
| URL parameter | Percent-encoding (`%20`) | Query string |
| SQL query | Parameterized query (bukan string concatenation) | `SELECT * FROM users WHERE id = ?` |

---

### 3.3 Secure Headers — Konfigurasi Praktis

> Tabel ini menunjukkan header HTTP yang wajib dikonfigurasi untuk setiap aplikasi web.

| Header | Nilai yang Disarankan | Fungsi | Referensi |
|--------|----------------------|--------|-----------|
| `Content-Security-Policy` | `default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';` (atau lebih ketat) | Mencegah XSS & injection | OWASP CSP Cheat Sheet |
| `Strict-Transport-Security` | `max-age=63072000; includeSubDomains; preload` | Paksa HTTPS | MDN — HSTS |
| `X-Frame-Options` | `DENY` (atau `SAMEORIGIN` jika diperlukan) | Cegah clickjacking | OWASP — Clickjacking |
| `X-Content-Type-Options` | `nosniff` | Cegah MIME sniffing | MDN |
| `Referrer-Policy` | `strict-origin-when-cross-origin` | Batasi info referrer | MDN |
| `Permissions-Policy` | Batasi akses kamera, mikrofon, geolokasi | Kontrol fitur browser | MDN |

---

## 4. CORS — Konfigurasi yang Aman

> [!callout] 💡 **CORS bukan pengganti autentikasi** — CORS hanya mengatur siapa yang boleh membaca respons, bukan siapa yang boleh mengakses endpoint.

- **Whitelist origin** (`Access-Control-Allow-Origin: https://trusted.com`) — jangan `*` untuk endpoint sensitif
- **Batasi metode** (`Access-Control-Allow-Methods`) — hanya yang diperlukan
- **Batasi header** — jangan izinkan header berbahaya (`Cookie`, `Authorization`) kecuali diperlukan
- **Jangan gunakan wildcard origin (`*`)** jika endpoint menggunakan cookie/autentikasi
- **Preflight (`OPTIONS`)** harus divalidasi seperti endpoint biasa

> Contoh konfigurasi (Flask dengan `flask-cors`):
> ```python
> from flask import Flask
> from flask_cors import CORS
> app = Flask(__name__)
> CORS(app, origins=["https://app.mydomain.com"], supports_credentials=True,
>      methods=["GET", "POST"], allow_headers=["Content-Type", "Authorization"])
> ```

---

## 5. Content Security Policy (CSP) — Langkah Implementasi

### 5.1 Strategi Implementasi

1. **Audit resource** — daftar semua script, style, image, font, dan endpoint yang digunakan aplikasi
2. **Buat CSP header** dengan `default-src 'self'` sebagai dasar
3. **Tambahkan direktif per kategori** (`script-src`, `style-src`, `img-src`, `connect-src`)
4. **Gunakan nonce/hash** untuk script/style inline yang diperlukan
5. **Gunakan `report-uri` atau `report-to`** untuk menerima laporan pelanggaran CSP (memantau serangan XSS)
6. **Uji di browser** — pastikan aplikasi tetap berfungsi; sesuaikan jika ada resource yang terblokir

---

## 6. Checklist Keamanan Aplikasi (Actionable)

- [ ] **Autentikasi**: MFA wajib; session timeout ≤ 30 menit; secure cookie flags
- [ ] **Otorisasi**: RBAC dengan least privilege; verifikasi di setiap endpoint
- [ ] **Input**: Whitelist validation; parameterized queries; encoding sesuai konteks
- [ ] **Output**: Secure headers lengkap; CSP aktif; output encoding benar
- [ ] **Dependencies**: SCA scan; update CVE kritis ≤ 7 hari; SBOM tersedia
- [ ] **Logging**: Log semua akses sensitif; log tidak mengandung PII berlebih; retensi sesuai kebijakan
- [ ] **Monitoring**: SIEM correlation untuk anomali akses; alert untuk brute-force / injection patterns

---

## 7. Referensi Lintas & Link Penting

- **Defense deepdive:** `01_Library/defender/Web/*` · [[01_Library/defender/Web/ssrf-defense-hardening-playbook.md]] · [[01_Library/defender/Web/waf-ml-anomaly-detection.md]]
- **Attack counterpart:** `01_Library/attacker/Web/*` · [[01_Library/attacker/Web/attack-waf-evasion-deepdive.md]]
- **Hierarchy:** [[00_Atlas/hierarchy-cybersecurity-defense-architecture.md]] · [[00_Atlas/hierarchy-waf-reverse-proxy.md]]
- **Standar:** [[00_Atlas/hierarchy-search.md]] (OSI/L7 reference) · OWASP Top 10 · NIST CSF 2.0
- **Roadmap/operasional:** [[browser-security-roadmap]] (jika ada) · [[network-security]]

---

*Dokumen ini adalah ekspansi dari `01_Library/Cyber_Security/web-security.md`. Dibuat 2026-08-14 sebagai bagian dari ekspansi konten vault (target ≥ 1.500 kata). Status: complete.*
---

audited
---
