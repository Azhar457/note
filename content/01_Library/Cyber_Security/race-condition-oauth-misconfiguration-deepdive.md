---
title: "Race Condition & OAuth Misconfiguration — Vulnerabilities Web: TOCTOU, OAuth Flaws, Case Studies"
tags:
  - cyber-security
  - race-condition
  - oauth
  - web-security
  - api-security
  - library
aliases:
  - "Race Condition OAuth Guide"
  - "OAuth Implementation Flaws"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Race condition dan OAuth misconfiguration adalah dua kelas kerentanan web yang sering muncul di aplikasi modern. Race condition mengeksploitasi concurrent request untuk memanipulasi state. OAuth misconfiguration mengeksploitasi kesalahan implementasi flow otentikasi/delegasi. Keduanya bisa menyebabkan account takeover, privilege escalation, dan data breach.

**Cross-link:** [[oauth2-oidc-dan-api-authorization-architecture]] → [[race-condition-web-exploitation]] → [[api-security-deep-dive]] → [[web-hacking-exploitation]]

---

## Daftar Isi
- [[#Bagian 1: OAuth Misconfiguration]]
- [[#1. Redirect URI Bypass]]
- [[#2. State Parameter Missing]]
- [[#3. CSRF on OAuth Flow]]
- [[#4. Scope Escalation]]
- [[#5. Token Leakage]]
- [[#6. PKCE Missing]]
- [[#Bagian 2: Race Condition OAuth]]
- [[#7. OAuth + Race Condition]]
- [[#8. Defense]]

---

## Bagian 1: OAuth Misconfiguration

### 1. Redirect URI Bypass

Redirect URI adalah parameter paling kritis di OAuth. Jika validation longgar, attacker bisa mendapatkan authorization code.

```http
GET /oauth/authorize?
  response_type=code&
  client_id=app123&
  redirect_uri=https://attacker.com/  # ❌ Bisa redirect ke attacker
```

**Bypass Techniques:**

```bash
# Subdomain manipulation
https://target.com.evil.com/oauth-callback
https://evil.com/target.com/oauth-callback

# Path traversal
https://target.com/oauth/../evil.com/callback

# Open redirect
https://target.com/oauth/callback?redirect=https://evil.com

# Wildcard abuse
https://evil.com/  # jika whitelist *.target.com
https://evil.com%40target.com/  # @ confusion
```

### 2. State Parameter Missing

State parameter adalah CSRF token untuk OAuth flow. Jika tidak ada, attacker bisa melakukan CSRF login.

```http
# ❌ Tanpa state — attacker bisa:
# 1. Mulai OAuth flow dengan akun attacker
# 2. Dapatkan code
# 3. Buat korban mengakses redirect dengan code tersebut
# 4. Akun korban ter-link ke akun attacker

GET /oauth/authorize?response_type=code&client_id=app123
```

### 3. CSRF on OAuth Flow

Tanpa state parameter, CSRF pada OAuth memungkinkan attacker mengikat akunnya ke akun korban.

```html
<img src="https://target.com/oauth/link?code=ATTACKER_CODE">
<!-- Korban mengakses → akun korban ter-link ke akun attacker -->
```

### 4. Scope Escalation

Scope escalation terjadi ketika aplikasi meminta scope lebih tinggi dari yang seharusnya.

```http
# Aplikasi minta scope: read_profile
# Attacker modifikasi jadi:
GET /oauth/authorize?scope=read_profile%20admin%20write_posts
# Jika server tidak validasi scope sesuai yang diregister → escalation
```

### 5. Token Leakage via Referer

```http
# OAuth flow dengan implicit grant
# Token ada di URL fragment (#access_token=...)

# Jika halaman redirect mengandung resource external (gambar, script)
# Referer header bisa bocorkan URL lengkap (tanpa fragment)
# Tapi beberapa browser kirim path via Referer-Policy
```

### 6. PKCE Missing

```javascript
// Authorization Code tanpa PKCE
// Attacker dengan akses ke authorization code bisa exchange ke token
// PKCE mencegah ini dengan code_verifier + code_challenge

// ❌ Vulnerable: Authorization Code tanpa PKCE
// ✅ Safe: Authorization Code + PKCE (S256)
```

---

## Bagian 2: Race Condition OAuth

### 7. OAuth + Race Condition

Race condition bisa terjadi di beberapa titik OAuth flow:

```http
# 1. Token redemption race — redeem code berkali-kali
# Biasanya 1 code cuma bisa 1x redeem.
# Tapi dengan race condition:
POST /oauth/token
code=AUTHORIZATION_CODE  # × 10 requests concurrent
# Jika tidak ada locking → 10 token valid dari 1 code
```

```http
# 2. Account binding race
# Saat binding akun OAuth ke akun lokal
# Format: POST /oauth/bind?provider=google&code=CODE

# Race condition:
# Kirim 10 request binding bersamaan dengan user session yang berbeda
# → Multiple account binding → takeover
```

---

## 8. Defense

| OAuth Issue | Defense |
|---|---|
| Redirect URI | Exact match whitelist, jangan pakai regex |
| State | Wajib state parameter dengan CSRF token |
| Scope | Validasi scope sesuai registrasi aplikasi |
| PKCE | Wajib S256 PKCE untuk public clients |
| Race condition | Database locking + idempotency key untuk token redemption |

**Referensi:** PayloadsAllTheThings `/Ref/PayloadsAllTheThings/OAuth Misconfiguration/`
