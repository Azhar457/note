---
tags:
- CTF
- Cryptography
- Encoding
- CyberChef
aliases:
- PicoCTF Section 2
- Pattern Recognition for Encodings
created: 2026-05-12
status: pending
title: Picoctf Section 2 Cyberchef Encodings
updated: '2026-07-01'
---

cssclasses:
  - wide-table
  - callout

# 🧩 PICOCTF SECTION 2 — Encodings & CyberChef

> **Tools:** CyberChef, `base64`, `tr`
> **Filosofi:** Jangan tebak-tebak buah manggis. Kenali pola visualnya.
> **Target:** Base64, Hex, Base32, ROT13, & Binary.

---

## FASE 1 — Pattern Recognition (Pengenalan Pola)

Gunakan tabel ini untuk menebak jenis encoding hanya dalam sekali lirik:

| Jenis | Contoh Visual | Kunci Identitas |
|---|---|---|
| **Base64** | `YXpoYXI=` | Campur A-Z, a-z, 0-9. Sering ada `=` di akhir. |
| **Hex (B16)** | `61 7a 68 61 72` | Hanya `0-9` dan `A-F`. Awalan `0x`. |
| **Base32** | `MFRGGZJA` | Full CAPS. Angka hanya `2-7`. Tanpa 0, 1, 8, 9. |
| **Binary** | `01100001` | Hanya berisi angka `0` dan `1`. |
| **ROT13** | `cvpbPGS` | Terlihat seperti kata normal tapi berantakan. |

---

## FASE 2 — Manipulasi Data di Terminal

Seringkali lebih cepat menggunakan terminal daripada membuka browser.

### 2.1 Base64 Decoding
```bash
echo "bDNhcm5fdGgzX3IwcDM1" | base64 -d
```

### 2.2 ROT13 (Translate command)
```bash
# Me-rotate karakter A-Z dan a-z sebanyak 13 langkah
echo "cvpbPGS" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
```

---

## FASE 3 — CyberChef (The Magic Stick)

Untuk tantangan yang lebih kompleks, gunakan **CyberChef**.

### 3.1 Fitur "Magic"
Jika Anda menaruh input di CyberChef, klik ikon **Magic Wand** (tongkat sihir). Alat ini akan menebak jenis encoding secara otomatis.

### 3.2 Pemetaan "Base" ke Nama Umum
> [!tip] Kamus CyberChef
> - **Base 16** ➔ From Hex
> - **Base 64** ➔ From Base64
> - **Base 2** ➔ From Binary

---

## FASE 4 — Jebakan Padding & Binary

Saat mengonversi angka ke biner (misal: 42 ke biner):
*   **Manual**: `101010` (6 bit).
*   **8-bit Format**: `00101010` (8 bit).

> [!danger] Warning: Leading Zeros
> Di PicoCTF, jangan menambah `0` di depan (padding) kecuali instruksi memintanya. `picoCTF{101010}` ≠ `picoCTF{00101010}`.

---

## Quick Reference — Cheat Sheet

```bash
# ═══ TERMINAL DECODING ═══
echo "[STRING]" | base64 -d            # Decode Base64
echo "[STRING]" | xxd -r -p            # Decode Hex (Plain)

# ═══ IDENTIFIKASI ═══
# Base 16 = Hex (0-9, A-F)
# Base 32 = CAPS (A-Z, 2-7)
# Base 64 = Mix (A-Z, a-z, 0-9, =)
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Brute Force menebak manual | Gunakan tabel pola atau fitur "Magic" |
| Menambah `0` di depan biner | Masukkan biner murni tanpa padding |
| Bingung mencari "Base 16" | Cari kata kunci "Hexadecimal" |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-1-onboarding]] — Kembali ke Section 1
- [[picoctf-section-3-linux-web-basics]] — Lanjut ke Section 3

---

*PicoCTF Section 2 | Base64 · Hex · ROT13 · CyberChef*

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian: ada vs tidak ada kontrol, efektivitas, dokumentasi, repeatable.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Never trust, always verify |
| **MITRE ATT&CK** | Framework TTP serangan |
| **SIEM** | Security Information & Event Management |
| **EDR** | Endpoint Detection & Response |
| **SOAR** | Security Orchestration & Response |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **OIDC** | OpenID Connect |
| **PKCE** | Proof Key for Code Exchange |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/
- Cloud Native (CNCF) — https://www.cncf.io/

### Tips CyberChef & Encoding (picoCTF)

| Encoding | CyberChef Operation | Detect |
|----------|---------------------|--------|
| **Base64** | From Base64 | Akhiran `==`, charset A-Za-z0-9+/ |
| **Hex** | From Hex | Charset 0-9a-f |
| **Binary** | From Binary | Hanya 0 dan 1 |
| **ROT13** | ROT13 | Text mirip kata Inggris setelah decode |
| **URL** | URL Decode | `%XX` pattern |
| **Morse** | From Morse Code | `.` dan `-` |
| **Octal** | From Octal | Angka 0-7 |
| **Braille** | From Braille | Unicode Braille char |

### CyberChef Workflow

```
Input → "Magic" (auto-detect) → atau manual:
  From Base64 → From Hex → From Binary → text flag
```

### Multi-encoding Challenge

Seringkali picoCTF encoding challenge pakai multi-layer:
- Base64 → Hex → ASCII → flag
- Binary → Hex → ROT13 → flag

Gunakan "Magic" operation di CyberChef untuk auto-detect, atau buat recipe manual bertingkat.

### Tips

1. `file` command untuk tipe data
2. `xxd` untuk liat hex dump
3. CyberChef "Magic" untuk auto-detect encoding
4. Python `base64.b64decode()` untuk scripting
