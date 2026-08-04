---
title: "OWASP CRS — Rule Structure Analysis: Request Phase, Response Phase, Paranoia Levels, Anomaly Scoring"
tags:
  - cyber-security
  - waf
  - crs
  - modsecurity
  - owasp
  - library
aliases:
  - "OWASP CRS Rule Structure"
  - "CRS Phase Analysis"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> OWASP Core Rule Set (CRS) adalah kumpulan aturan deteksi serangan untuk WAF yang menjadi standar industri. CRS v4 terdiri dari 50+ file rule yang diorganisir per phase (request/response), kategori serangan, dan paranoia level. Memahami struktur CRS penting untuk mengembangkan rule engine jarsWAF yang kompatibel dan efektif.

**Cross-link:** [[waf-reverse-proxy-deepdive]] → WAF architecture deepdive (privat) → [[waf-evasion-techniques-encyclopedia]] → [[hierarchy-waf-reverse-proxy]] → [[ctf-tool-arsenal-universal]]

---

## Daftar Isi
- [[#1. CRS File Organization]]
- [[#2. Request Phase Rules (REQUEST-9XX)]]
- [[#3. Response Phase Rules (RESPONSE-9XX)]]
- [[#4. Data Files (.data)]]
- [[#5. Exclusion Rules]]
- [[#6. Paranoia Levels]]
- [[#7. Anomaly Scoring]]
- [[#8. Implikasi untuk jarsWAF]]

---

## 1. CRS File Organization

CRS v4 mengorganisir rules dalam format:

```
REQUEST-9XX-CATEGORY.conf
RESPONSE-9XX-CATEGORY.conf
```

### File per Phase

| File | Fungsi | Contoh Rule |
|---|---|---|
| `REQUEST-901-INITIALIZATION` | Setup awal | Init vars, anomaly scores |
| `REQUEST-905-COMMON-EXCEPTIONS` | Whitelist umum | Exclude monitoring tools |
| `REQUEST-911-METHOD-ENFORCEMENT` | Method restriction | GET, POST only |
| `REQUEST-913-SCANNER-DETECTION` | Scanner detection | Nmap, nessus, sqlmap |
| `REQUEST-920-PROTOCOL-ENFORCEMENT` | Protocol compliance | HTTP version, headers |
| `REQUEST-921-PROTOCOL-ATTACK` | Protocol attack | Request smuggling |
| `REQUEST-930-LFI` | File inclusion | `../../etc/passwd` |
| `REQUEST-931-RFI` | Remote file inclusion | `http://evil.com/shell` |
| `REQUEST-932-RCE` | Remote command execution | `cmd.exe`, `/bin/sh` |
| `REQUEST-933-PHP` | PHP injection | `php://`, `assert` |
| `REQUEST-934-GENERIC` | Generic injection | Charset, encoding |
| `REQUEST-941-XSS` | Cross-site scripting | `<script>`, `onerror` |
| `REQUEST-942-SQLI` | SQL injection | `' OR 1=1`, `UNION` |
| `REQUEST-943-SESSION-FIXATION` | Session fixation | `Cookie:` manipulation |
| `REQUEST-944-JAVA` | Java attacks | OGNL, deserialization |
| `REQUEST-949-BLOCKING-EVALUATION` | Blocking decision | Anomaly score threshold |

---

## 2. Request Phase Rules

Setiap rule file berisi aturan spesifik untuk satu kategori serangan.

### Struktur Rule CRS

```apache
# Rule ID: 942100
# Severity: CRITICAL
# Paranoia Level: 2

SecRule REQUEST_COOKIES|REQUEST_COOKIES_NAMES|REQUEST_HEADERS|ARGS_NAMES|ARGS|XML:/* "@pm from-file sqli-data.data" \
    "id:942100,\
    phase:2,\
    block,\
    t:urlDecodeUni,\
    msg:'SQL Injection Detected via libinjection',\
    logdata:'Matched Data: %{TX.0} found within %{MATCHED_VAR_NAME}: %{MATCHED_VAR}',\
    tag:'application-multi',\
    tag:'language-multi',\
    tag:'platform-multi',\
    tag:'attack-sqli',\
    tag:'paranoia-level/2',\
    tag:'OWASP_CRS',\
    ver:'OWASP_CRS/4.0.0',\
    severity:'CRITICAL',\
    setvar:'tx.anomaly_score_pl2=+%{tx.critical_anomaly_score}'"
```

### Komponen

| Komponen | Fungsi |
|---|---|
| **Target variable** | `ARGS`, `REQUEST_COOKIES`, `REQUEST_HEADERS` |
| **Operator** | `@pm` (pattern match), `@rx` (regex), `@within` |
| **Transform function** | `t:urlDecodeUni`, `t:lowercase`, `t:removeNulls` |
| **Anomaly score** | `setvar:'tx.anomaly_score_pl2=+CRITICAL'` |
| **Paranoia level** | `tag:'paranoia-level/2'` |

---

## 3. Response Phase Rules (RESPONSE-9XX)

Rule yang memeriksa response dari backend, bukan request.

| File | Fungsi |
|---|---|
| `RESPONSE-950-DATA-LEAKAGES` | Data leakage generic |
| `RESPONSE-951-DATA-LEAKAGES-SQL` | SQL error messages |
| `RESPONSE-952-DATA-LEAKAGES-JAVA` | Java stack traces |
| `RESPONSE-953-DATA-LEAKAGES-PHP` | PHP error messages |
| `RESPONSE-954-DATA-LEAKAGES-IIS` | IIS error messages |
| `RESPONSE-955-WEB-SHELLS` | Webshell detection |
| `RESPONSE-956-DATA-LEAKAGES-RUBY` | Ruby error messages |
| `RESPONSE-959-BLOCKING-EVALUATION` | Blocking decision |
| `RESPONSE-980-CORRELATION` | Correlation rules |

---

## 4. Data Files (.data)

CRS menggunakan file `.data` untuk payload database — text file berisi daftar pattern yang di-load via `@pm` operator.

```bash
# Contoh: lfi-os-files.data
/etc/passwd
/etc/shadow
/etc/hosts
/etc/issue
/proc/self/environ
/usr/local/apache/conf/httpd.conf
/usr/local/apache2/conf/httpd.conf
...
```

### Data Files di CRS v4

```text
ai-critical-artifacts.data    lfi-os-files.data            scanners-user-agents.data
asp-dotnet-errors.data        php-errors.data              sql-errors.data
iis-errors.data               php-function-names-933150.data  ssrf.data
java-classes.data             php-variables.data           ssrf-no-scheme.data
restricted-files.data         unix-shell.data              web-shells-asp.data
restricted-upload.data        unix-shell-aliases.data      web-shells-php.data
ruby-errors.data              unix-shell-builtins.data      windows-powershell-commands.data
```

---

## 5. Exclusion Rules

Aturan pengecualian untuk mengurangi false positive:

```txt
REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf.example
REQUEST-999-COMMON-EXCEPTIONS-AFTER-CRS.conf
REQUEST-999-EXCLUSION-RULES-AFTER-CRS.conf.example
```

---

## 6. Paranoia Levels

| Level | Nama | Risiko FP | Coverage |
|---|---|---|---|
| **PL1** | Default | Rendah | Serangan umum |
| **PL2** | Advanced | Sedang | Bypass techniques |
| **PL3** | High | Tinggi | Obfuscation & encoding |
| **PL4** | Paranoid | Sangat tinggi | Semua varian |

### Perbedaan per Level

```text
PL1: ' OR '1'='1 (SQLi basic)
PL2: ' OR '1'='1' -- (SQLi with comment)
PL3: %27%20OR%201%3D1%20-- (URL encoded SQLi)
PL4: %25%32%37%20%4F%52%20%31%3D%31 (Double encoded)
```

---

## 7. Anomaly Scoring

### Skema Scoring

```apache
# Set anomaly score per severity
setvar:'tx.critical_anomaly_score=5'
setvar:'tx.error_anomaly_score=4'
setvar:'tx.warning_anomaly_score=3'
setvar:'tx.notice_anomaly_score=2'

# Threshold
setvar:'tx.inbound_anomaly_score_threshold=5'  # Default PL1
setvar:'tx.outbound_anomaly_score_threshold=4'
```

### Scoring Flow

```
Request → Rule1 (Critical, +5) → Rule2 (Warning, +3) → Total=8
→ Threshold PL1=5 → BLOCKED (8 >= 5)
```

---

## 8. Implikasi untuk jarsWAF

| Konsep CRS | Implementasi di jarsWAF | Status |
|---|---|---|
| Rule phases | `headers.rs`, `body.rs`, `evasion.rs` | ✅ Ada |
| Anomaly scoring | `anomaly.rs` + `scoring_mode` | ✅ Ada (accumulate/threshold) |
| Paranoia levels | Belum ada level system | 🎯 Bisa adopsi |
| Data files | Belum ada `@pm` operator | 🎯 Bisa via `.data` files |
| Exclusion rules | Custom rules via `config.toml` | ✅ Ada |
| Transform functions | `t:urlDecodeUni` → normalize di engine | ✅ Parsial |
| Per-phase blocking | `REQUEST-949` → blocking decision phase | 🔄 Bisa ditambah |

**Lokasi CRS:** `/mnt/data_d/Projects/Reference/owasp-coreruleset/`
