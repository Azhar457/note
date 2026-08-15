---
title: WAF Internal Architecture Deepdive
tags: [security, web, architecture, waf]
aliases: [waf-internal-architecture-deepdive]
---
# WAF Internal Architecture Deepdive

WAF (Web Application Firewall) bekerja sebagai proxy antara client dan aplikasi web, memeriksa HTTP request terhadap ruleset (SQLi, XSS, file inclusion, path traversal). Arsitektur internal umumnya: request parser → rule engine → anomaly scoring → action (block/allow/log).

## Pipeline Internal

```
Client HTTP → Parser (request line, headers, body)
            → Normalisasi (URL decode, unicode, multipart)
            → Rule Engine (regex/expression per phase)
            → Anomaly Scoring (detection → score)
            → Action (pass/block/challenge/log)
            → Backend / Response
```

### 1. Request Parsing
- Request line: method, URL, version.
- Headers: parsing nama/nilai, batas ukuran, duplikat.
- Body: application/x-www-form-urlencoded, multipart/form-data, JSON, XML.
- Penting: parsing harus sama dengan backend, jika beda → bypass (parsing differential).

### 2. Normalisasi
- URL decode (`%41` → A), double decode, unicode normalization.
- Canonicalization: path traversal (`..`, `%2e%2e%2f`), backslashes.
- Multipart: boundary handling, filename encoding.
- Bypass umum terjadi di sini: encoding bertingkat, null byte, overlong UTF-8.

### 3. Rule Engine
- **ModSecurity + CRS (Core Rule Set)** — open source standard: 900+ rules, paranoia levels 1-4, categories (920 protocol, 930 LFI, 932 RCE, 941 XSS, 942 SQLi).
- **Coraza** — Go port ModSecurity ruleset, cocok integrasi modern.
- **NAXSI** — whitelist-based (Russia, dipakai banyak reverse proxy).
- **Cloud WAF** (Cloudflare/AWS WAF/Imperva) — ruleset managed + custom, machine learning anomaly.
- Rule matching: regex (PCRE2, dengan timeout/limits hindari ReDoS), expression tree, libinjection untuk SQLi/XSS detection struktural.

### 4. Anomaly Scoring
- Setiap rule punya weight; akumulasi threshold memicu action.
- Paranoia level menaikkan strictness: PL1 (default, FP rendah) → PL4 (agresif, FP tinggi).
- Exceptions: `SecRuleRemoveById`, `ctl:ruleRemoveById` per endpoint.

### 5. Action & Deployment Mode
- **Detection/Logging** — amati dulu, minimalkan false positive.
- **Enforcement** — block, challenge (CAPTCHA/JS challenge), delay, redirect.
- Deployment: reverse proxy inline (Nginx+ModSecurity), transparent bridge, DNS proxy, API gateway.

## Bypass Techniques (Red Team)

1. Encoding obfuscation: `%u0027`, overlong UTF-8, Mixed case, double URL encode.
2. HTTP parsing differential: `Content-Length` vs `Transfer-Encoding` (CL.TE/TE.CL request smuggling).
3. Parameter pollution: `?id=1&id=2'` — parser WAF lihat pertama, backend pakai kedua.
4. Multipart confusion: filename injection, boundary aneh.
5. JSON/XML nesting: payload dalam struktur kompleks yang tidak di-decode WAF.
6. Chunked transfer / HTTP/2 header compression.
7. WAF fingerprint (wafw00f) → cari ruleset yang known-bypass.

## Monitoring

- False positive rate < 5%; review log mingguan; korelasi alert dengan traffic normal.
- Metrics: request blocking rate, anomaly score distribution, bypass detection (payload block di log backend tapi lolos WAF).
- Alerting: spike blocking (mungkin serangan), spike anomaly (mungkin bypass attempt).

## Referensi

- ModSecurity Reference Manual, OWASP CRS GitHub
- PortSwigger Research — WAF bypass & request smuggling
- wafw00f, Coraza, Nginx + ModSecurity tutorials



## ModSecurity + CRS Studi Konfigurasi

```
# nginx + modsecurity conf
SecRuleEngine On
SecRequestBodyAccess On
SecResponseBodyAccess Off
SecAuditEngine RelevantOnly
SecAuditLog /var/log/modsec_audit.log
SecDefaultAction "phase:1,log,auditlog,pass"
# CRS
Include /etc/modsecurity/crs/crs-setup.conf
Include /etc/modsecurity/crs/rules/*.conf
# Tuning example: endpoint /api/v2/json — parse JSON
SecRule REQUEST_URI "@beginsWith /api/v2" "id:1001,phase:1,pass,nolog,ctl:requestBodyProcessor=JSON"
```

## CRS Ruleset Bagian Penting

| Rule Class | ID Range | Menangani |
|------------|----------|-----------|
| Protocol enforcement | 920xxx | HTTP version, headers, encoding |
| LFI/RFI | 930xxx | path traversal, file inclusion |
| RCE | 932xxx | command injection patterns |
| PHP injection | 933xxx | PHP function calls |
| XSS | 941xxx | script tags, event handlers |
| SQLi | 942xxx | SQL syntax, tautologi, union |
| Session fixation | 943xxx | cookie manipulation |

## Anomaly Scoring Detail

Default: `inbound_anomaly_score_threshold=5`, `paranoia_level=1`.
Jika request = 2 critical rule (masing-masing 5) → total 10 → block.
Konfigurasi: `SecAction "id:900110,phase:1,setvar:tx.inbound_anomaly_score_threshold=10"`.
Per-endpoint exception: `SecRule REQUEST_URI "@beginsWith /public" "id:9999,phase:1,pass,nolog,ctl:ruleRemoveById=932250"`.

## Cloud WAF Perbandingan

| WAF | Strength | Limitasi |
|-----|----------|----------|
| Cloudflare | global network, JS challenge, ML | rule custom terbatas di plan rendah; log terbatas |
| AWS WAF | integrasi ALB/CloudFront, managed rules | harga per rule; no regex di legacy? (regex didukung) |
| GCP Cloud Armor | edge security, adaptive protection | admin-heavy |
| Azure Front Door WAF | OWASP CRS managed, rate limit | config complex |
| Imperva/F5 | on-prem control penuh | harga mahal, maintain sendiri |

## Bypass WAF Testing Methodology

1. Identifikasi WAF: wafw00f, error messages, header unik (`server: cloudflare`, `x-sucuri-id`).
2. Fingerprint ruleset: kirim payload benign/agnostic, lihat apa yang diblokir.
3. Encoding fuzz: loop encoding (url, double-url, unicode, hex, base64, mixed case).
4. Teknik parsing: HTTP/2 → HTTP/1.1 downgrade, CL.TE/TE.CL, parameter pollution, multipart filename.
5. Payload alternatif: SQLi tanpa keyword (`1'||'2`), XSS via SVG/MathML, RCE via `$IFS`, waktu-based.
6. Document bypass: simpan sebagai artifact untuk laporan (PoC).

## Red Team Notes

- WAF dianggap "obstacle", bukan "ultimate defense" — selalu uji backend langsung bila ada jalur alternatif (API internal, subdomain non-proxied).
- Request smuggling ke backend bisa bypass WAF total (payload tidak terlihat oleh parser proksi).
- WAF log endpoint bisa jadi sumber intel: pola block = ketahui payload yang terdeteksi.

---

  audited
---