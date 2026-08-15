---
title: OWASP API Security Top 10
tags: [security, web, api]
aliases: [owasp-api-security-top-10]
---
# OWASP API Security Top 10

APIs (REST/GraphQL) adalah permukaan serangan modern terbesar — setiap aplikasi web/mobile hampir pasti punya API. OWASP API Security Top 10 (2023) menggantikan fokus klasik web (OWASP Top 10) untuk konteks API: auth flaws, object-level authorization, rate limit, data exposure.

## Daftar 10 Risiko (API Security Top 10 — 2023)

| # | Risiko | Deskripsi Singkat |
|---|--------|-------------------|
| 1 | **API1: Broken Object Level Authorization (BOLA)** | Akses objek milik user lain via ID (IDOR). Paling umum & kritis. |
| 2 | **API2: Broken Authentication** | AuthN lemah: session fixation, credential stuffing, token tidak di-revoke. |
| 3 | **API3: Broken Object Property Level Authorization (BOPLA)** | Mass assignment: user set `isAdmin=true`, `role=admin` di payload. |
| 4 | **API4: Unrestricted Resource Consumption** | Rate limit tidak ada → DoS, cost exhaustion. |
| 5 | **API5: Broken Function Level Authorization** | Endpoint admin dipanggil user biasa (missing role check). |
| 6 | **API6: Unrestricted Access to Sensitive Business Flows** | Abuse fitur bisnis (mis. undian, ticketing bot). |
| 7 | **API7: Server Side Request Forgery (SSRF)** | API mem-fetch URL user → akses internal. |
| 8 | **API8: Security Misconfiguration** | CORS salah, verbose error, default creds, missing security headers. |
| 9 | **API9: Improper Inventory Management** | API lama (v1) masih online, shadow endpoints, debug route. |
| 10 | **API10: Unsafe Consumption of APIs** | Aplikasi mengkonsumsi API pihak ketiga tanpa validasi → poisoning/indirect attack. |

## Deep-dive: BOLA (API1) — contoh & testing

IDOR/BOLA: endpoint `GET /api/user/{id}` — jika id milik user lain bisa diakses → BOLA.

```bash
# Test: ganti id milik user lain
curl -H "Authorization: Bearer TOKEN" https://api/app/users/1001
curl -H "Authorization: Bearer TOKEN" https://api/app/users/1002  # user lain? leak!
```

- UUID bukan pengaman: enum keamanan ≠ authz. Jika UUID bocor (log, share), endpoint tetap harus memeriksa ownership.
- GraphQL: nested queries → akses object terkait melebihi izin.
- Mitigasi: object-level authorization di service layer (bukan cuma di router); ownership check selalu (current_user.id == obj.owner_id).

## Deep-dive: Broken Authentication (API2)

- Session/token tidak di-invalidasi saat password change/logout.
- JWT: algoritma downgrade (alg:none), expired token tidak di-check, signature lemah.
- Credential stuffing: rate limit login + MFA wajib.
- Token storage client: localStorage rentan XSS; prefer HttpOnly cookie.
- Revocation: short-lived access token (15 menit) + refresh token rotate.

## OWASP API Top 10 di Sisi Pengujian (Whitebox)

1. Fuzz setiap endpoint: otorisasi di cek (role switching).
2. Enumerate object IDs: apakah akses lintas-user.
3. Method abuse: POST → PUT? privilege function di GET?
4. Mass assignment: tambahkan field extra ke payload.
5. Rate limit: kirim 1000 request, cek 429.
6. CORS: origin jahat diterima?
7. Shadow endpoint: fuzz path (v1, admin, debug, docs, staging).
8. SSRF: parameter URL/vendor — test ke localhost/metadata (169.254.169.254).

## API Security Checklist (Implementasi)

- [ ] AuthN kuat: MFA, token lifetime pendek, revoke support.
- [ ] AuthZ per object & per function (BOLA+BOPLA+BFLA).
- [ ] Rate limiting & quota per user/endpoint; cost control.
- [ ] Input validation (schema) semua field — no mass assignment.
- [ ] Error tidak verbose; security headers (CORS whitelist).
- [ ] Inventory: semua endpoint didokumentasi; nonaktifkan versi lama.
- [ ] SSRF protection: block private IP/network ranges, metadata IP.
- [ ] Logging & monitoring API (audit log, anomaly).

## Artifact & Testing Tools

- **Postman/Bruno** — collection test manual + automation.
- **Burp Suite** — proxy, Intruder (fuzz), extension (Autorize untuk BOLA/BFLA).
- **OWASP ZAP** — free scanning.
- **ffuf** — endpoint & parameter fuzz.
- **Insomnia** — testing GraphQL.
- **GraphQL introspection tools** — playground, Altair, voyager.
- **rate-limit scripts** (custom) — uji threshold.

## Red Team Notes

BOLA adalah temuan "crown" dalam API pentest hari ini — banyak aplikasi modern aman untuk XSS klasik tapi lupa object ownership. Prioritaskan: (1) resource-level IDOR (BOLA), (2) authN flaw, (3) shadow endpoints (API9), (4) SSRF. Hunter-friendly: tanpa pembelian memperlihatkan impact (data user lain) = critical.

## Koneksi ke Vault

- [[js-framework-vulnerabilities]] — API konsumsi frontend.
- [[wiod-reverse-proxy-deepdive]] — API di belakang proxy (rate limit, CORS).
- [[threat-modeling-stride-dread]] — modelkan endpoint API per trust boundary.



## GraphQL API Specific Risks

- **Introspection enabled** — bocorkan schema penuh (semua query/mutation, types). Nonaktifkan di produksi (atau batasi via middleware).
- **N+1 query / deep nesting** — cost exhaustion (API4): batasi depth & complexity (graphql-depth-limit, graphql-validation-complexity).
- **Over-fetching** — restitusi data berlebih: field-level authorization (graphql-shield / custom resolvers) — jangan andalkan cuma schema.
- **Batch query attack** — alias berulang memicu DoS.
- Red team: `GET /graphql?query={__schema{types{name}}}` — hapus introspection di produksi!

## OAuth2 / JWT di API (AuthN Deep Dive)

- **JWT**: short expiry (15-30 menit access), refresh token rotate + revoke; jangan `alg: none`; verifikasi issuer & audience; `kid` header jangan dari input tak tepercaya (key confusion).
- **OAuth2**: state parameter wajib (anti-CSRF), redirect_uri exact-match, PKCE untuk public clients (mobile/SPA), scope minimal.
- **Token storage**: HttpOnly cookie (bukan localStorage) untuk browser; secure storage di mobile.
- **Servis-to-servis**: mTLS atau signed JWT (not shared secret di query).

## API Inventory & Documentasi (API9 Mitigation)

1. Semua endpoint didokumentasikan (OpenAPI spec) dan versi-kan (`/v1`, `/v2`).
2. Sunset policy: nonaktifkan endpoint lama setelah migrasi — jangan biarkan `api/v1/deprecated` online.
3. Shadow discovery: fuzz path (ffuf wordlist API), cek swagger/openapi JSON, cek `/api-docs`, `/swagger`, `/graphql`, `/actuator` (Spring).
4. Monitoring: alert untuk endpoint tidak dikenal yang aktif (404 flood = probing).

---

  audited
---