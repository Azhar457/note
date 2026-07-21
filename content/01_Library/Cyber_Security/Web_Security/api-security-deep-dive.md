---
title: "API Security Deep Dive"
tags:
  - web-security
  - api
  - authentication
  - jwt
  - oauth
  - rate-limiting
aliases:
  - "REST API Security"
  - "JWT OAuth Best Practices"
  - "API Protection Layer"
created: "2026-07-11"
updated: "2026-07-11"
status: active
cssclasses: ""
---

# 🔐 API Security — From Auth to Rate Limiting

> **Filosofi:** API security bukan cuma "pake JWT". Banyak bocor di layer yg gak terduga — CORS misconfigured, rate limit gak ada, pagination tanpa auth boundary.

---

## Threat Model — API Attack Surface

```
                    Attacker
                       │
        ┌──────────────┼──────────────┐
        ▼              ▼              ▼
┌────────────┐ ┌────────────┐ ┌────────────┐
| Auth       | | Input      | | Business   |
| Layer      | | Layer      | | Logic      |
|            | |            | |            |
| • JWT leak | | • SQLi     | | • IDOR     |
| • OAuth    | | • XSS      | | • Missing  |
|   redirect | | • SSRF     | |   pagination|
| • Token    | | • Injection| | • Race     |
|   storage  | └────────────┘ |   condition|
└────────────┘                └────────────┘
```

---

## Authentication — Token Strategy

### JWT (JSON Web Token)

```
Header:  {"alg":"RS256","typ":"JWT"}
Payload: {"sub":"user123","iat":1680000000,"exp":1680086400}
Sign:    RSA private key (RS256) atau HMAC secret (HS256)
```

| Aspek | Best Practice | Jangan |
|-------|--------------|--------|
| **Algorithm** | RS256 (asymmetric) | HS256 — secret harus dishare, gak bisa revoke per-service |
| **Expiry** | Access: 15-60 menit. Refresh: 7-30 hari | Token gak expire |
| **Storage** | `httpOnly` cookie (web) / memory (mobile) | `localStorage` — exposed ke XSS |
| **Claims** | Minimal: `sub`, `iat`, `exp`. Tambah: `iss`, `aud` | Jangan taruh password / PII di payload |
| **Secret rotation** | Rotate signing key tiap 90 hari | Key statis |

> [!warning] HS256 + Public API = Risk
> Kalau pake HS256, secret ada di backend dan di consumer (microservice). Satu service bocor → semua service bisa forge token. Pake RS256.

### OAuth 2.0 — Authorization Framework

```
┌─────────┐         ┌─────────┐         ┌─────────┐
│  Client  │────────▶│  Auth    │────────▶│  Resource│
│  App     │ 1.auth  │  Server  │ 2.token │  Server  │
│          │◀────────│          │◀────────│          │
└─────────┘  3.code └─────────┘  4.data └─────────┘
```

| Flow | Use Case | Security Consideration |
|------|---------|----------------------|
| **Authorization Code** | Web app with backend | Wajib + PKCE (Proof Key for Code Exchange) |
| **PKCE** | Mobile / SPA | Mencegah authorization code interception |
| **Client Credentials** | Server-to-server | Simple — client_id + client_secret |
| **Implicit** (deprecated) | Legacy SPA | **Jangan dipakai** — token di URL redirect |

---

## Authorization — Beyond Auth

### IDOR (Insecure Direct Object Reference)

```http
# ❌ Rentan — user bisa ganti ID
GET /api/users/123/orders

# ✅ Ownership check required
# Backend harus verifikasi: req.user.id === order.user_id
```

| Celah | Deteksi | Fix |
|-------|---------|-----|
| `/api/profile?user_id=456` | Ganti angka — lihat data orang | Ambil user_id dari session/token, bukan parameter |
| `/api/invoices/INV-001` | Enumeration | UUID instead of sequential, + owner check |
| Admin-only field in response | Inspect response body | Jangan kirim field yang gak di-request |

### Rate Limiting

```go
// Pseudocode — sliding window
type RateLimiter struct {
    Requests map[string][]time.Time
    Max      int           // 100 request
    Window   time.Duration // per 15 menit
}
```

| Layer | Rate Limit | Contoh |
|-------|-----------|--------|
| **Global** | Per IP | 1000 req/menit |
| **Per endpoint** | Per user | Login: 5 req/menit |
| **Per user** | Per API key | 100 req/menit |
| **Concurrent** | Max simultan | 10 req/detik |

> [!tip] Rate Limit Response
> Return `429 Too Many Requests` dengan header `Retry-After: <seconds>`. Jangan hang atau drop silent — client gak tahu harus nunggu berapa lama.

---

## Input Validation — Defense Layer 1

| Attack | Input Pattern | Defense |
|--------|--------------|---------|
| **SQLi** | `' OR 1=1 --` | Parameterized query / ORM. JANGAN string concatenation |
| **XSS** | `<script>alert(1)</script>` | Output encoding + Content-Type header |
| **NoSQLi** | `{"$gt":""}` | Type validation, sanitize operator keys |
| **SSRF** | URL ke internal IP | Allowlist domain, block private IP ranges |
| **Path traversal** | `../../../etc/passwd` | Path normalization, whitelist karakter |

---

## GraphQL Deep Inspection & Security

GraphQL menawarkan fleksibilitas query bagi client, namun fleksibilitas ini memperkenalkan *attack surface* baru yang unik di mana query tunggal dapat melumpuhkan server.

### GraphQL Query Complexity & Depth Analysis
Penyerang dapat mengirimkan query bersarang (*nested query*) secara rekursif untuk memicu kehabisan memori atau CPU pada server database (*DoS via Circular Queries*):

```graphql
# ❌ Malicious Nested Query (Circular Reference)
query {
  user(id: "1") {
    friends {
      friends {
        friends {
          friends {
            name
          }
        }
      }
    }
  }
}
```

**Pertahanan (WAF / API Gateway Layer):**
- **Query Depth Limiting**: Batasi kedalaman sarang maksimum (misal: `max_depth = 5`).
- **Query Complexity Analysis**: Berikan bobot biaya (*complexity score*) pada setiap field (misal: field relasi = 5, field skalar = 1). Tolak query jika total skor melebihi batas (misal: `max_complexity = 100`).

### Introspection Blocking
Introspection query (`__schema`, `__type`) memungkinkan siapa pun menelusuri skema API internal Anda dan memetakan struktur database secara instan.

**Pertahanan:**
- **Nonaktifkan Introspection di Production**: Pastikan introspection hanya aktif di lingkungan development.
- **WAF Rule blocking**: Blokir request HTTP POST yang mengandung kata kunci `__schema` atau `__type` di level proxy sebelum mencapai GraphQL parser.

### Alias-based Rate Limit Bypass (Batching Attack)
Penyerang dapat mengirimkan ratusan panggilan API yang berbeda di dalam satu HTTP request menggunakan *GraphQL aliases*, melewati filter *rate limiting* berbasis HTTP request konvensional:

```graphql
# ❌ Batching Attack Bypass HTTP Rate Limiting
query {
  first: getUser(id: "1") { name }
  second: getUser(id: "2") { name }
  third: getUser(id: "3") { name }
  # ... 100 aliases dalam satu request
}
```

**Pertahanan:**
- **Alias Limiting**: Batasi jumlah maksimum alias di dalam satu query (misal: `max_aliases = 10`).
- **Object/Field Rate Limiting**: Hitung rate limiting berdasarkan jumlah field pengaksesan objek aktual, bukan berdasarkan jumlah HTTP request.

### GraphQL Pentesting Checklist (Red Team)
- [ ] Lakukan pemetaan skema via Introspection Query (`POST /graphql` dengan query `__schema`).
- [ ] Uji kerentanan DOS dengan mengirim circular reference query (kedalaman > 15 tingkat).
- [ ] Kirim bulk query menggunakan alias untuk melewati rate limiting IP standar.
- [ ] Coba injeksi SQLi/NoSQLi pada argumen input query GraphQL.

---

## CORS — Sering Salah

```http
# ❌ Terlalu longgar
Access-Control-Allow-Origin: *

# ✅ Specific origin — kalau perlu
Access-Control-Allow-Origin: https://app.domain.com
Access-Control-Allow-Credentials: true

# Kalau multiple origin → parse Origin header, match allowlist
```

| Misconfig | Dampak |
|-----------|--------|
| `Access-Control-Allow-Origin: *` | Siapapun bisa read response via JS |
| `Access-Control-Allow-Credentials: true` + wildcard | **Invalid** — browser tolak |
| `Access-Control-Allow-Origin: null` | Mudah diforge via `data:` URI atau sandbox iframe |
| No Vary: Origin | Cache poisoning — proxy kirim response ke origin salah |

---

## API Key Management

| Praktik | Keterangan |
|---------|-----------|
| **Prefix identifikasi** | `sk_live_...` vs `sk_test_...` — bedain environment |
| **Hashed storage** | Simpan bcrypt hash, bukan plaintext |
| **Scope** | Batasi permission: read-only vs read-write |
| **Rotate** | Force rotate tiap 90 hari atau setelah bocor |
| **Revoke** | Endpoint `DELETE /api/v1/keys/:id` |

---

---

## 🧠 Berpikir — Metodologi Penyusunan Catatan

Catatan ini disusun melalui proses berpikir terstruktur sebagai berikut:

### 1. Thinking Type yang Digunakan

| Type | Kenapa | Bagian |
|------|--------|--------|
| **Analytical Thinking** | Threat model decomposition — memecah API attack surface jadi 3 layer (Auth, Input, Business Logic) | Threat Model diagram |
| **Systems Thinking** | Memetakan interaksi CORS → browser → server → proxy — bagaimana misconfig bisa cascade ke cache poisoning | CORS section |
| **Concrete Thinking** | Best practice tables dengan exact "Do this" / "Don't do that" — JWT config, rate limit values | JWT, Rate Limiting, Input Validation tables |
| **Critical Thinking** | Mempertanyakan asumsi umum — "JWT is secure" (HS256 gak aman untuk public API), "CORS * is fine untuk public API" | Warnings, CORS misconfig |
| **Design Thinking** | Menentukan rate limiting strategy dari perspektif user— jangan silent drop, kasih Retry-After header | Rate Limit Response tip |

### 2. Background Knowledge (Pra-Penulisan)

- **JWT alg confusion attack**: attacker ubah `alg` dari `RS256` ke `HS256`, server pake public key sebagai HMAC secret — bisa forge token
- **OAuth implicit flow deprecated** sejak RFC 9700 (2025) — semua rekomendasi pake Authorization Code + PKCE
- **CORS `null` origin**: bisa diforge via `data:` URI, `file:` protocol, atau sandboxed iframe — sering lupa di-block
- **Rate limiting headers**: `X-RateLimit-Limit`, `X-RateLimit-Remaining`, `Retry-After` — standard dari RFC 6585
- **NoSQL injection via operators**: `{"$gt":""}`, `{"$ne":""}`, `{"$where": "..."}` — MongoDB/LesanDB vulnerable kalau gak sanitize
- **IDOR dari pengalaman real**: `/api/profile?user_id=` — lupa ambil dari token, ambil dari params = data semua user bocor

### 3. RAG Vault — Dokumen yang Dikonsultasi

| Dokumen | Kontribusi |
|---------|-----------|
| [[web-security]] | Web application security secara umum |
| [[cloudflare-ruleset-engine-phases|Cloudflare Ruleset Engine]] | WAF layer — API protection at CDN level |
| [[cyber-security|Cyber Security Roadmap]] | Red/Blue team perspective — bagaimana attacker exploit API |
| [[network-security|Network Security]] | Port filtering, connection-layer security |

### 4. Sintesis — Bagaimana Bagian Bergabung

```
Background Knowledge (JWT internals, OAuth flows, CORS behavior, rate limiting)
    │
    ▼
RAG Vault (web security context existing)
    │
    ▼
Analytical:  Threat model → 3 attack surfaces → break down per layer
    │
    ▼
Systems:     CORS misconfig → cache poisoning chain → browser security model
    │
    ▼
Critical:    JWT assumptions → HS256 risk, OAuth implicit deprecated, CORS null
    │
    ▼
Concrete:    Best practice tables → exact config values → code samples
    │
    ▼
Design:      Rate limiting from user perspective → proper 429 response
```

### 5. Sequential Thinking Steps

```
Thought 1 (Analytical):  "API security bukan cuma JWT. Ada 3 layer: Auth, Input, Business Logic."
                          "Buat threat model diagram biar visual."
Thought 2 (Critical):    "JWT RS256 vs HS256. HS256 gak aman buat public API — secret dishare."
                          "Tambah alg confusion attack warning."
Thought 3 (Systems):     "CORS misconfig cascade: wildcard + credentials = browser reject."
                          "Tapi origin di-allow semua = data bisa dibaca sitep lain."
                          "Cache poisoning via missing Vary: Origin."
Thought 4 (Concrete):    "Rate limiting: 1000 req/menit global, 5 req/menit login. Exact values."
                          "Return 429 + Retry-After. Jangan silent drop."
Thought 5 (Analytical):  "Input validation: 5 attack types (SQLi, XSS, NoSQLi, SSRF, Path traversal)."
                          "Masing-masing punya defense spesifik."
Thought 6 (Critical):    "LocalStorage for tokens? No. httpOnly cookie atau memory."
Thought 7 (Design):      "Bagaimana user tahu kena rate limit? Retry-After header. Jangan tebak-tebak."
```

---

## 🔗 Lihat Juga

- [[web-security]] — Broader web application security
- [[cloudflare-ruleset-engine-phases|Cloudflare Ruleset Engine]] — WAF layer protection
- [[cyber-security|Cyber Security Roadmap]] — Blue/Red team context
- [[network-security|Network Security]] — OSI layer, port filtering
