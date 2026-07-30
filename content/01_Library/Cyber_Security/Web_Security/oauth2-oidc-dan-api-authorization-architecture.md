---
title: "OAuth 2.0 & OpenID Connect — Grant Types, Token Exchange, Implementation Flaws, OAuth vs SAML vs OIDC"
tags:
  - web-security
  - oauth
  - oidc
  - authentication
  - api-security
  - library
aliases:
  - "OAuth 2.0 Deep Dive"
  - "OIDC Authorization Code PKCE"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> OAuth 2.0 adalah protokol delegasi akses yang memungkinkan aplikasi mendapatkan akses terbatas ke resource milik user tanpa mengekspos credential. OpenID Connect (OIDC) adalah lapisan identitas di atas OAuth 2.0 untuk autentikasi. Catatan ini membahas grant types, token exchange, JWT validation, implementation flaws umum, serta perbandingan OAuth vs SAML vs OIDC.

**Domain Terkait:** [[api-security-deep-dive]] (fondasi) → [[identity-and-access-management]] (IAM) → [[web-security]] (konteks web) → [[active-directory-windows-security-deepdive]] (enterprise IdP) → [[zero-trust-security]] (framework keamanan)

---

## Daftar Isi
- [[#1. OAuth 2.0 — Arsitektur & Roles]]
- [[#2. Grant Types — Flow Lengkap]]
- [[#3. OpenID Connect — Lapisan Identitas]]
- [[#4. Token Exchange & Refresh Token Rotation]]
- [[#5. JWT Structure & Validation]]
- [[#6. Common Implementation Flaws]]
- [[#7. OAuth untuk First-Party vs Third-Party Apps]]
- [[#8. OAuth vs SAML vs OIDC — Comparison]]
- [[#9. Tools untuk Testing OAuth]]
- [[#10. Referensi]]

---

## 1. OAuth 2.0 — Arsitektur & Roles

OAuth 2.0 mendefinisikan 4 roles (RFC 6749):

```
┌─────────────┐        ┌──────────────┐
│  Resource   │        │   Resource   │
│  Owner      │◄──────▶│   Server     │
│  (User)     │        │  (API)       │
└──────┬──────┘        └──────┬───────┘
       │                      │
       │   Authorization      │
       │      Grant           │
       ▼                      │
┌──────────────┐             │
│  Client      │─────────────▶│
│  (App)       │  Access Token│
└──────┬───────┘             │
       │                      │
       ▼                      │
┌──────────────┐             │
│ Authorization │             │
│   Server     │◄─────────────┘
│  (IdP)       │
└──────────────┘
```

| Role | Deskripsi | Contoh |
|---|---|---|
| **Resource Owner** | Entitas yang memiliki resource | User dengan fotonya di Google Photos |
| **Resource Server** | Server yang menyimpan resource | API Google Photos |
| **Client** | Aplikasi yang minta akses | Aplikasi edit foto pihak ketiga |
| **Authorization Server** | Server yang mengeluarkan token | Google Accounts |

---

## 2. Grant Types — Flow Lengkap

### Authorization Code Grant (PKCE)

Grant type paling aman untuk aplikasi native/web. PKCE (Proof Key for Code Exchange) mencegah authorization code interception.

```
┌────────┐      ┌────────┐      ┌────────┐
│ Client │      │   IdP  │      │  User  │
└───┬────┘      └───┬────┘      └───┬────┘
    │               │               │
    │ 1. Auth Req   │               │
    │ + code_challenge──────────────▶│
    │               │               │
    │               │   2. Login    │
    │               │◄──────────────┤
    │               │               │
    │ 3. Auth Code  │               │
    │◄──────────────┤               │
    │               │               │
    │ 4. Code +     │               │
    │ code_verifier─▶               │
    │               │               │
    │ 5. Token      │               │
    │◄──────────────┤               │
```

**Flow detail:**

```python
# Step 1: Generate code challenge
import hashlib, base64, secrets

code_verifier = secrets.token_urlsafe(64)
code_challenge = base64.urlsafe_b64encode(
    hashlib.sha256(code_verifier.encode()).digest()
).rstrip("=")

# Step 2: Redirect user ke IdP
auth_url = (
    f"https://idp.example.com/auth?"
    f"response_type=code&client_id=myapp"
    f"&redirect_uri=https://myapp.com/callback"
    f"&code_challenge={code_challenge}"
    f"&code_challenge_method=S256"
)

# Step 3: Exchange code untuk token
token_resp = requests.post("https://idp.example.com/token", json={
    "grant_type": "authorization_code",
    "code": received_code,
    "code_verifier": code_verifier,
    "redirect_uri": "https://myapp.com/callback",
    "client_id": "myapp"
})
```

### Client Credentials Grant

Untuk machine-to-machine tanpa user involvement.

```bash
curl -X POST https://idp.example.com/token \
  -H "Content-Type: application/json" \
  -d '{
    "grant_type": "client_credentials",
    "client_id": "service-1",
    "client_secret": "secret123"
  }'
```

### Device Code Grant

Untuk device tanpa browser (smart TV, CLI).

```
User buka URL: https://device-auth.example.com/activate
Masukkan code: ABCD-1234
Device polling: POST /token → pending → ... → success
```

### Grant Type Comparison

| Grant Type | Use Case | Security Level | Refresh Token |
|---|---|---|---|
| Authorization Code + PKCE | Web/Native apps | Tertinggi | ✅ |
| Client Credentials | Service-to-service | Tinggi | ❌ (self-contained) |
| Device Code | Headless devices | Sedang | ✅ |
| Implicit (deprecated) | SPA (legacy) | Rendah | ❌ |
| Resource Owner Password | Legacy trust apps | Rendah | ✅ |

> **Catatan:** Implicit grant sudah deprecated sejak RFC 8252. SPA wajib pakai Authorization Code + PKCE.

---

## 3. OpenID Connect — Lapisan Identitas

OIDC menambahkan lapisan autentikasi di atas OAuth 2.0 dengan **ID Token** (JWT).

| OAuth 2.0 | OpenID Connect |
|---|---|
| `access_token` — akses ke API | `access_token` + `id_token` — identitas user |
| Scope: `read`, `write` | Scope: `openid`, `profile`, `email` |
| No user info format | `sub` claim sebagai user identifier wajib |
| Resource Server verifikasi token | Client verifikasi ID Token sendiri |

### OIDC Flow

```python
# OIDC Discovery URL
discovery = requests.get("https://idp.example.com/.well-known/openid-configuration").json()

# Verifikasi ID Token (JWT)
from jose import jwt

jwks = requests.get(discovery["jwks_uri"]).json()
claims = jwt.decode(
    id_token,
    jwks,
    audience="myapp",
    issuer="https://idp.example.com",
    options={"verify_at_hash": True}
)
# claims = {
#   "sub": "user-123",
#   "email": "user@example.com",
#   "name": "John Doe",
#   "iat": 1680000000,
#   "exp": 1680003600
# }
```

### OIDC Scopes & Claims

| Scope | Claims | Penggunaan |
|---|---|---|
| `openid` | `sub` | Wajib, unique user ID |
| `profile` | `name`, `family_name`, `picture` | Profil user |
| `email` | `email`, `email_verified` | Verifikasi email |
| `address` | `address` | Alamat terformat |
| `phone` | `phone_number` | Nomor telepon |

---

## 4. Token Exchange & Refresh Token Rotation

### Token Exchange (RFC 8693)

Menukar satu token dengan token lain (downscoping, delegation):

```
POST /token HTTP/1.1
Content-Type: application/json

{
  "grant_type": "urn:ietf:params:oauth:grant-type:token-exchange",
  "subject_token": "ACCESS_TOKEN_ASD",
  "subject_token_type": "urn:ietf:params:oauth:token-type:access_token",
  "requested_token_type": "urn:ietf:params:oauth:token-type:access_token",
  "scope": "read_only"
}
```

### Refresh Token Rotation

Setiap kali refresh token digunakan, server mengeluarkan **refresh token baru** dan **mencabut yang lama**. Ini mencegah refresh token theft.

```
┌────────┐           ┌────────┐
│ Client │           │  IdP   │
└───┬────┘           └───┬────┘
    │ POST /token        │
    │ grant_type=refresh │
    │ refresh_token=R1   │
    ├────────────────────▶│
    │                    │
    │ access_token=A2   │
    │ refresh_token=R2  │← R1 revoked
    │◄───────────────────┤
```

Implementasi di backend:

```python
class TokenService:
    def refresh_token(self, old_refresh: str):
        # Validate old refresh token
        token = self.db.get_refresh_token(old_refresh)
        if not token or token.revoked:
            raise InvalidTokenError()
        
        # Revoke old, issue new
        self.db.revoke_token(old_refresh)
        new_token = self.db.create_refresh_token(user_id=token.user_id)
        
        return {
            "access_token": self.create_access_token(token.user_id),
            "refresh_token": new_token,
            "token_type": "Bearer"
        }
```

---

## 5. JWT Structure & Validation

### Struktur

```
header.payload.signature

header: {"alg": "RS256", "kid": "key-1", "typ": "JWT"}
payload: {"sub": "user-123", "iat": 1680000000, "exp": 1680003600, "aud": "myapp"}
signature: RSA(private_key, header + "." + payload)
```

### Validasi Checklist

| Check | Mengapa | Jika Gagal |
|---|---|---|
| **Signature** | Verifikasi integrity token | Tolak |
| **Expiration (exp)** | Token expired | Minta refresh |
| **Issuer (iss)** | Hanya trust IdP yang dikenal | Tolak |
| **Audience (aud)** | Token untuk app ini | Tolak |
| **Not Before (nbf)** | Token belum aktif | Tolak jika signifikan |
| **Algorithm (alg)** | Cegah alg confusion attack | Tolak jika `none` |

### Algorithm Confusion Attack

Serangan klasik: attacker ubah `alg` dari `RS256` ke `HS256` (symmetric), lalu sign dengan public key yang bisa didapat.

**Defense:** Wajib whitelist algorithm di validation.

```python
# ❌ Vulnerable
jwt.decode(token, public_key)

# ✅ Safe
jwt.decode(token, public_key, algorithms=["RS256"], audience="myapp")
```

---

## 6. Common Implementation Flaws

| Flaw | Dampak | Fix |
|---|---|---|
| **CSRF di redirect URI** | Attacker exchange code miliknya | PKCE + state parameter |
| **Token leakage via Referer** | Token di URL → Referer header ke third-party | Authorization Code bukan Implicit |
| **Scope escalation** | Client upgrade scope tanpa otorisasi | Server-side scope validation |
| **Refresh token theft** | Attacker bisa refresh token terus | Rotation + revocation |
| **Missing audience validation** | Token untuk service A dipakai di service B | Wajib cek `aud` claim |
| **Open redirect abuse** | `redirect_uri` wildcard → phishing | Exact match whitelist redirect URI |

### Contoh: Redirect URI Bypass

```python
# ❌ Vulnerable — pattern matching longgar
if "example.com" in redirect_uri:
    allow()

# ✅ Safe — exact match
ALLOWED_URIS = ["https://myapp.com/callback", "https://myapp.com/alt"]
if redirect_uri not in ALLOWED_URIS:
    deny()
```

---

## 7. OAuth untuk First-Party vs Third-Party Apps

| Aspek | First-Party | Third-Party |
|---|---|---|
| **Trust level** | Tinggi (app + IdP satu org) | Rendah |
| **Client secret** | Bisa disimpan aman | Public client (no secret) |
| **PKCE** | Opsional | Wajib |
| **Token lifetime** | Bisa lama | Pendek |
| **Scope** | Full | Minimal |
| **Consent screen** | Opsional | Wajib |

---

## 8. OAuth vs SAML vs OIDC — Comparison

| Fitur | OAuth 2.0 | SAML 2.0 | OIDC |
|---|---|---|---|
| **Purpose** | Delegasi akses | SSO enterprise | SSO modern |
| **Token format** | JWT (Bearer) | XML (SAML Assertion) | JWT (ID Token) |
| **Transport** | JSON/REST | HTTP Redirect/POST/SOAP | JSON/REST |
| **Mobile support** | ✅ Excellent | ❌ Buruk | ✅ Excellent |
| **Federation** | ❌ Tidak built-in | ✅ Ya | ✅ Ya (via OAuth) |
| **Single Logout** | ❌ Tidak | ✅ Ya (SLO) | ✅ Ya (OpenID SLO) |
| **Maturity** | 2012 (RFC 6749) | 2005 | 2014 |
| **Adoption** | API, mobile, IoT | Enterprise, pemerintah | Web, mobile, startup |

**Keputusan:** OIDC untuk aplikasi baru, SAML hanya jika integrasi dengan legacy enterprise.

---

## 9. Tools untuk Testing OAuth

| Tool | Fungsi |
|---|---|
| **oauth2c** | CLI OAuth client untuk testing flow |
| **jwt.io** | Debug JWT token |
| **Burp Suite + OAuth plugin** | Intercept & manipulate OAuth flow |
| **OAuth 2.0 Playground** | Google's interactive OAuth debugger |
| **oidc-token-hunter** | Cari token leakage di logs |

---

## 10. Referensi

- RFC 6749 — OAuth 2.0 Authorization Framework
- RFC 6750 — Bearer Token Usage
- RFC 7519 — JSON Web Token (JWT)
- RFC 7636 — PKCE
- RFC 8252 — OAuth for Native Apps
- RFC 8693 — Token Exchange
- OpenID Connect Core 1.0

**Cross-link vault:**
- [[api-security-deep-dive]] — API security konteks OAuth
- [[identity-and-access-management]] — IAM framework
- [[web-security]] — web security umum
- [[active-directory-windows-security-deepdive]] — enterprise IdP konteks
- [[zero-trust-security]] — zero trust architecture
