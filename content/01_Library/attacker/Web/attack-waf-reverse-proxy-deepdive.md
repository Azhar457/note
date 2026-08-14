---
title: Attack Perspective — WAF Reverse Proxy (Red Team Deepdive)
tags:
- attack
- red-team
- waf
- reverse-proxy
- desync
- smuggling
- origin-bypass
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# WAF & Reverse Proxy — Perspektif Penyerang (Deepdive)

> Reverse proxy = gerbang tunggal → bypass = akses langsung ke backend. Red team: HTTP desync (smuggling), origin IP discovery, protocol mismatch, request splitting.

## 1. Proxy Chain Attack Surface

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **Nginx** | CL.TE/TE.CL desync | T1190 | Smuggling → backend request WAF tidak lihat | Framing mismatch | Proxy audit = rare |
| **HAProxy** | TE.TE confusion | T1190 | TE chunked double-decode | TE.TE = variant | Proxy audit = rare |
| **Cloudflare** | Origin discovery, direct backend | T1190 | DNS history → origin IP | Direct = bypass WAF | Origin protect = partial |
| **AWS ALB** | H2 desync, header case | T1190 | HTTP/2 → backend interpret beda | H2 framing | ALB audit = rare |
| **ModSecurity** | Encoding, rule bypass | T1190 | Payload encode chain | Rule = pattern | CRS update = lag |
| **API Gateway** | Direct service access | T1190 | Service discovery → direct call | Bypass gateway | Service audit = rare |

## 2. HTTP Request Smuggling

```
Prereq: Front-end + back-end interpret framing berbeda
    ↓
CL.TE (Content-Length vs Transfer-Encoding):
  ├── Request: CL: 100 + TE: chunked
  ├── Front-end: process CL (100 bytes)
  ├── Back-end: process TE (chunked) → smuggle
  └→ Backend process request kedua (smuggled) → WAF tidak lihat
    ↓
TE.CL:
  ├── Request: TE: chunked + CL: 100
  ├── Front-end: process TE (chunked)
  ├── Back-end: process CL → smuggle
  └→ Same effect
    ↓
TE.TE:
  ├── Multiple TE header → front/back parse beda
  └→ Obscured TE → one side ignore
    ↓
Impact:
  ├── Bypass WAF (smuggled = no inspect)
  ├── Poison cache (front-end cache request 2)
  ├── Session hijack (smuggle user request → capture)
  └→ Internal SSRF (smuggle to internal endpoint)
```

## 3. Origin IP Bypass

```
Discovery:
  ├── DNS history (SecurityTrails) → past A record
  ├── Certificate search (crt.sh) → origin in cert
  ├── Subdomain → non-CDN subdomain (mail., api.)
  ├── Email headers (SPF record → mail server IP)
  └→ Shodan → search cert/SSL → origin
    ↓
Verify: curl https://ORIGIN_IP -H "Host: target.com" → response?
  ├── Ya → origin = direct access
  ├── 403/404 → different IP → iterate
  └→ Success → bypass WAF entirely
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Burp Suite** | Smuggling test (CL.TE/TE.CL) |
| **Smuggler** | Automated desync detection |
| **SecurityTrails** | DNS history → origin IP |
| **crt.sh** | Cert search → origin |
| **CloudFlair** | Cloudflare origin discovery |
| **ffuf** | Endpoint fuzz via origin |

## 5. Referensi
- PortSwigger Smuggling — https://portswigger.net/web-security/request-smuggling
- Smuggler — https://github.com/defparam/smuggler
- CloudFlair — https://github.com/christophetd/CloudFlair
- HTTP Desync (James Kettle) — https://portswigger.net/research/http-desync-attacks-request-smuggling-reborn