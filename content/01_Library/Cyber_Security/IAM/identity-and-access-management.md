---
title: Identity & Access Management (IAM)
tags:
- cyber-security
- iam
- library
created: '2026-07-02'
updated: '2026-07-02'
status: operational
cssclasses: ''
---

# 🪪 Identity & Access Management (IAM)

> [!info] Hubungan ke Vault
> IAM adalah fondasi dari [[network-security]] dan [[endpoint-security]]. Konsep least privilege dan RBAC di sini terkait erat dengan [[blueteam-detection-matrix]] dan [[purple-team-osi-killchain]].

## Daftar Isi
1. [Konsep Dasar IAM](#konsep-dasar-iam)
2. [Authentication vs Authorization](#authentication-vs-authorization)
3. [Faktor Authentication](#faktor-authentication)
4. [MFA — Multi-Factor Authentication](#mfa--multi-factor-authentication)
5. [SSO — Single Sign-On](#sso--single-sign-on)
6. [Federated Identity](#federated-identity)
7. [OAuth 2.0 & OpenID Connect](#oauth-20--openid-connect)
8. [SAML](#saml)
9. [LDAP & Active Directory](#ldap--active-directory)
10. [RBAC — Role-Based Access Control](#rbac--role-based-access-control)
11. [ABAC — Attribute-Based Access Control](#abac--attribute-based-access-control)
12. [PAM — Privileged Access Management](#pam--privileged-access-management)
13. [Zero Trust & IAM](#zero-trust--iam)
14. [Passwordless Authentication](#passwordless-authentication)
15. [Session Management](#session-management)
16. [Token-Based Auth](#token-based-auth)
17. [API Authentication](#api-authentication)
18. [IAM Architecture Patterns](#iam-architecture-patterns)
19. [Threats & Mitigations](#threats--mitigations)
20. [Compliance & Standards](#compliance--standards)
21. [Tools Comparison](#tools-comparison)
22. [Bottom Line](#bottom-line)

---

## Konsep Dasar IAM

**Identity & Access Management (IAM)** — framework kebijakan dan teknologi yang memastikan *the right people* punya akses ke *the right resources* di *the right time* dan *the right reason*.

**Tiga pilar IAM:**

| Pilar | Deskripsi | Contoh |
|-------|-----------|--------|
| **Identification** | Klaim identitas | Username, email, UUID |
| **Authentication** | Verifikasi klaim | Password, biometric, OTP |
| **Authorization** | Izin setelah verifikasi | RBAC, ACL, policy engine |

**Tujuan IAM:**
- Least privilege — user hanya punya akses minimum yang dibutuhkan
- Segregation of duties — pisahin peran antagonis (admin vs auditor)
- Auditability — setiap akses tercatat
- Lifecycle management — provisioning → review → deprovisioning

---

## Authentication vs Authorization

| Aspek | Authentication (AuthN) | Authorization (AuthZ) |
|-------|----------------------|----------------------|
| **Pertanyaan** | "Siapa kamu?" | "Kamu boleh apa?" |
| **Mekanisme** | Password, biometric, OTP | RBAC, ABAC, ACL, policy |
| **Output** | Identity token / session | Access token / permission set |
| **Contoh Protocol** | OIDC, SAML AuthnRequest | OAuth 2.0, XACML, AWS IAM Policy |
| **Flow** | Login | Setelah login, setiap request |

> Kerangka NIST SP 800-63 — membedain AuthN strength level (IAL/AAL/FAL).

---

## Faktor Authentication

**Tiga faktor utama (NIST SP 800-63B):**

| Faktor | Jenis | Contoh |
|--------|-------|--------|
| **Something you know** | Knowledge | Password, PIN, security question |
| **Something you have** | Possession | OTP app, hardware token (YubiKey), SMS, smart card |
| **Something you are** | Inherence | Fingerprint, face ID, iris, voice |

**Faktor tambahan (diusulkan):**
- **Somewhere you are** (location-based) — geolocation, IP range
- **Something you do** (behavioral) — typing pattern, mouse movement

**Autentikasi Multi-Faktor (MFA)** — mewajibkan dua+ faktor dari kategori berbeda.

---

## MFA — Multi-Factor Authentication

### Metode MFA

| Metode | Security | Convenience | Faktor |
|--------|----------|-------------|--------|
| SMS/Phone OTP | ❌ Lemah | ✅ Tinggi | Possession (rentan SIM swap) |
| TOTP (Google Auth, Authy) | ✅ Kuat | ✅ Tinggi | Possession |
| Push Notification | ✅ Kuat | ✅✅ Sangat tinggi | Possession |
| Hardware Token (YubiKey, Titan) | ✅✅ Sangat kuat | ⚠️ Medium | Possession (phishing-resistant) |
| FIDO2/WebAuthn | ✅✅ Sangat kuat | ✅✅ Sangat tinggi | Possession + Inherence |
| Biometric only | ⚠️ Medium | ✅✅ Tinggi | Inherence |
| Backup Codes | ⚠️ Medium | ✅✅ Tinggi | Knowledge |

### Phishing-Resistant MFA (FIDO2/WebAuthn)

Mekanisme U2F/FIDO2 nggak bisa di-phish karena:
- Challenge-response dengan origin-bound key pair
- Private key never leaves device
- Attestation — server verify device manufacturer

```
┌──────────┐  challenge   ┌──────────┐
│  Server   │─────────────>│ Browser  │
│          │<─────────────│          │
│          │  signature +  │  WebAuthn│
│          │  credentialId │  API     │
└──────────┘              └──────────┘
                                  │
                          ┌───────┴───────┐
                          │   Authenticator │
                          │   (TPM/Secure   │
                          │   Enclave/Yubi) │
                          └───────────────┘
```

### Best Practices MFA
- Wajib MFA untuk: admin, VPN, remote access, API keys
- Rate-limit MFA attempts — prevent brute force 6-digit TOTP
- Fallback mechanism: recovery codes, backup TOTP
- Monitor: MFA fatigue attack — push spamming sampe user approve
- **Never use SMS as primary MFA** — NIST deprecating SMS OTP (NIST SP 800-63B)

---

## SSO — Single Sign-On

**SSO** memungkinkan satu kredensial untuk akses ke banyak aplikasi.

### Arsitektur SSO

```
┌──────┐     Login     ┌──────────┐    Token     ┌──────────┐
│User  │──────────────>│   IdP    │─────────────>│   SP 1   │
│      │<──────────────│ (Keycloak│<─────────────│          │
│      │   SAML/OIDC   │  Okta/   │  validate    │   SP 2   │
│      │               │  AzureAD)│─────────────>│          │
└──────┘               └──────────┘    Token     └──────────┘
```

**Komponen SSO:**
- **IdP (Identity Provider)** — nyimpen & verifikasi identitas (Keycloak, Okta, Azure AD, Google)
- **SP (Service Provider)** — aplikasi yang nerima identitas
- **Federation Protocol** — SAML 2.0, OIDC, WS-Federation

### Keuntungan SSO
- Satu password lebih kuat daripada banyak password lemah
- Password rotation lebih jarang
- Centralized user lifecycle — disable one account revokes all access
- MFA applied once at IdP, applies everywhere

### Kerugian SSO
- **Single point of failure** — IdP down = semua aplikasi nggak bisa diakses
- **Lateral movement risk** — compromised IdP = complete domain compromise
- **Privilege escalation** — misconfigured attribute mapping bisa kasih akses berlebih

---

## Federated Identity

**Federated Identity** = IdP yang berbeda organisasi trust satu sama lain (cross-domain SSO).

### Federation Trust Models

| Model | Deskripsi | Contoh |
|-------|-----------|--------|
| **Direct Federation** | Dua organisasi punya trust bilateral | Partner VPN access |
| **Brokered Federation** | IdP broker antara banyak SP | Login with Google/GitHub |
| **Hub & Spoke** | One central IdP, many SPs | Enterprise: Okta → SaaS apps |
| **Mesh Federation** | Banyak IdP, many-to-many trust | eduGAIN (universitas global) |

### Federation Protocols
- **SAML 2.0** — enterprise, government
- **OpenID Connect** — modern web & mobile
- **WS-Federation** — legacy .NET apps
- **SCIM** (System for Cross-domain Identity Management) — user provisioning API

---

## OAuth 2.0 & OpenID Connect

### OAuth 2.0

Framework authorization — bukan authentication. Delegated access untuk resource owner.

**Grant Types:**

| Grant Type | Use Case | Security |
|------------|----------|----------|
| **Authorization Code** | Web app (server-side) | ✅ Secure (+PKCE) |
| **Authorization Code + PKCE** | Mobile/SPA | ✅✅ Secure |
| **Client Credentials** | Machine-to-machine | ✅ No user context |
| **Device Code** | TV/CLI devices | ⚠️ Medium |
| **Implicit** (deprecated) | Legacy SPA | ❌ Insecure |
| **Resource Owner Password** (deprecated) | Legacy migration | ❌ Insecure |

**OAuth 2.1** — menyederhanakan: hanya Authorization Code + PKCE dan Client Credentials.

**Flow Authorization Code + PKCE:**

```
┌─────┐  Auth Request +         ┌──────┐      ┌──────────┐
│Client│  code_challenge         │  Auth │     │  Resource │
│ SP   │────────────────────────>│Server │      │  Server   │
│      │<────────────────────────│       │      │          │
│      │  Auth Code              └──────┘      │          │
│      │                                            │
│      │  Auth Code +                              │
│      │  code_verifier                            │
│      │─────────────────────────────────────────>│          │
│      │<─────────────────────────────────────────│          │
│      │  Access + Refresh Token                    └──────────┘
└─────┘
```

### OpenID Connect (OIDC)

Lapisan identity di atas OAuth 2.0. Adds:

| Component | Fungsi |
|-----------|--------|
| **ID Token** | JWT berisi identity claims (sub, name, email, email_verified) |
| **UserInfo Endpoint** | API untuk dapetin profile claims |
| **Discovery** | `/.well-known/openid-configuration` — semua endpoint di satu URL |

**OIDC Flows:**
- **Authorization Code Flow** — server-side web apps
- **Implicit Flow** (deprecated) — legacy SPA
- **Hybrid Flow** — sebagian claims langsung di auth response
- **CIBA** (Client Initiated Backchannel Auth) — passwordless push

### Best Practices Token
- Access token: short-lived (15-60 menit)
- Refresh token: longer-lived, bound to client
- JWT signing: RS256 (asymmetric) > HS256 (symmetric)
- JWT validation: verify signature, issuer, audience, expiry, nbf
- Token binding (DPoP / mTLS) — prevent token replay

---

## SAML

**Security Assertion Markup Language 2.0** — XML-based protocol untuk SSO, dominan di enterprise & government.

### SAML Flow (SP-Initiated)

```
┌──────┐  Req resource     ┌──────┐    AuthnRequest     ┌──────────┐
│User  │─────────────────> │  SP  │────────────────────>│   IdP    │
│      │<──────────────── │      │<────────────────────│          │
│      │  resource         │      │    Assertion/Resp   │          │
│      │                   └──────┘                     └──────────┘
```

### SAML Components

| Component | Deskripsi |
|-----------|-----------|
| **Assertion** | XML statement: Authentication, Attribute, Authorization Decision |
| **Subject** | `<saml:Subject>` → NameID (user identifier) |
| **Conditions** | NotBefore, NotOnOrAfter, AudienceRestriction |
| **AuthnContextClassRef** | Authentication strength (password, MFA, X.509) |
| **SingleLogout** | Logout dari semua SP sekaligus |

### SAML vs OIDC

| Aspek | SAML 2.0 | OIDC |
|-------|----------|------|
| **Format** | XML | JSON |
| **Transport** | HTTP Redirect/POST POST Artifact | HTTP GET/POST, AJAX |
| **Token** | XML Assertion | JWT |
| **Binding** | Browser redirect, SOAP, PAOS | REST API |
| **Maturity** | Enterprise 20+ tahun | Modern web/mobile (~10 tahun) |
| **Complexity** | Tinggi (XML parsing, signing) | Rendah (JSON, simple) |
| **Session** | IdP-initiated logout | RP-initiated + session management |
| **Ecosystem** | Legacy enterprise stacks | Modern stacks (OAuth ecosystem) |

---

## LDAP & Active Directory

**LDAP (Lightweight Directory Access Protocol)** — protocol akses directory service (RFC 4511).

**Active Directory** — Microsoft's directory service, pakai LDAP + Kerberos + DNS.

### LDAP Structure

```
dn: cn=jars,ou=Users,dc=azharmtq,dc=com
cn: jars
uid: jars
mail: azhar@example.com
objectClass: inetOrgPerson
memberOf: cn=admin,ou=Groups,dc=azharmtq,dc=com
```

### LDAP Operations

| Operation | Fungsi | Contoh |
|-----------|--------|--------|
| **Bind** | Authentication | Username + password |
| **Search** | Query directory | `(&(objectClass=user)(mail=*))` |
| **Compare** | Check attribute value | `memberOf` membership |
| **Add/Modify/Delete** | CRUD entries | User provisioning |

### Binding dengan AD

Strategi aman LDAP:
- **LDAPS** (port 636) — wajib, avoid LDAP (389, plaintext)
- **StartTLS** — upgrade koneksi ke encrypted
- **Service Account** dengan limited scope, bukan admin credentials
- Channel binding + LDAP signing — prevent LDAP relay attack

### AD Attack Vectors (relevant untuk blue team)

| Attack | Deskripsi | Mitigasi |
|--------|-----------|----------|
| **Kerberoasting** | Request TGS untuk service account, crack offline | Complex service account passwords, Managed Service Accounts (gMSA) |
| **AS-REP Roasting** | User tanpa pre-auth Kerberos, crackable hash | Enable pre-authentication (default) |
| **Golden Ticket** | Forge KRBTGT hash → domain admin forever | Frequent KRBTGT password rotation, monitor event ID 4672/4624 |
| **Silver Ticket** | Forge TGS untuk service | Limit service account privileges, monitor Kerberos TGS events |
| **DCSync** | Replicate directory via DRSUAPI | Protect Replication ACL, monitor event ID 4662 |
| **Pass-the-Hash** | Use NTLM hash instead of password | Enable Credential Guard, disable NTLM where possible |
| **LDAP Relay** | Relay LDAP auth to escalate | LDAP signing + channel binding, SMB signing |
| **ACL Abuse** | Modify ACL (AdminCount, GenericAll) | Monitor AD ACL changes (event 5136) |

---

## RBAC — Role-Based Access Control

NIST SP 800-162 — akses berdasarkan peran, bukan per-user.

### Komponen RBAC

```
                 ┌─────────────┐
                 │   Roles     │
                 │  admin      │
                 │  developer  │
                 │  auditor    │
                 │  viewer     │
                 └──────┬──────┘
                        │
    ┌───────────────────┼───────────────────┐
    │                   │                   │
    ▼                   ▼                   ▼
┌────────┐       ┌───────────┐       ┌──────────────┐
│ Users  │       │ Permissions│       │  Sessions     │
│  (User │  has  │  Resources │  can  │  (activated   │
│  Role  │       │  CRUD      │  be   │  role subset) │
│  Mappings)     │  Actions   │       │               │
└────────┘       └───────────┘       └──────────────┘
```

### RBAC Models

| Model | Deskripsi |
|-------|-----------|
| **Flat RBAC** | User → Role → Permission (langsung) |
| **Hierarchical RBAC** | Role inheritance (admin inherits viewer) |
| **Constrained RBAC** | SSD (Static Separation of Duty) & DSD (Dynamic) |
| **Session-based RBAC** | Role aktif dipilih per session |

### Best Practices RBAC
- Minimal role count — jangan bikin role per individual
- Role naming standard — `{domain}.{level}` → `network.admin`, `logs.viewer`
- Principle of least privilege — start with no access
- Regular access review — quarterly recertification
- Role mining — analisis existing permissions buat cluster peran

---

## ABAC — Attribute-Based Access Control

NIST SP 800-162 — akses berdasarkan **attributes** (user, resource, environment), bukan role saja.

### Attribute Categories

| Category | Contoh |
|----------|--------|
| **Subject Attributes** | department=security, clearance=top-secret, location=ID |
| **Resource Attributes** | classification=confidential, owner=security-team |
| **Action Attributes** | method=DELETE, time=working-hours |
| **Environment Attributes** | ip=192.168.x.x, network=vpn, device=managed |

### Policy ABAC

```
Policy: "Allow delete hanya jika"
  subject.department == "admin"
  AND
  resource.classification != "critical"
  AND
  environment.ip in [10.0.0.0/8, 172.16.0.0/12]
  AND
  environment.time between "08:00" and "18:00"
```

Tool: AWS IAM Policy, OPA/Rego, XACML, Cedar (AWS), Oso.

### RBAC vs ABAC

| Aspek | RBAC | ABAC |
|-------|------|------|
| **Granularity** | Coarse (by role) | Fine-grained (by attribute) |
| **Management** | Role explosion | Policy complexity |
| **Flexibility** | Static, need new role per exception | Dynamic, policy-based exceptions |
| **Performance** | Fast (simple lookup) | Slower (attribute resolution) |
| **Audit** | Clear role assignments | Complex policy evaluation trace |
| **Best for** | Uniform access patterns | Fine-grained, context-aware |

---

## PAM — Privileged Access Management

**PAM** — subset IAM yang fokus pada privileged accounts (admin, root, service accounts).

### Privileged Account Types

| Account Type | Risiko | Mitigasi |
|--------------|--------|----------|
| **Local Admin** (root/Administrator) | Direct system compromise | Local admin password solution (LAPS) |
| **Domain Admin** | Full AD compromise | Tier 0 admin, jump box only |
| **Service Account** | Unmanaged, password never rotates | gMSA/managed service account |
| **Application Account** | Hardcoded creds | Secret vault (HashiCorp Vault) |
| **Emergency Account** | Backdoor risk | Break-glass procedure, MFA, monitoring |
| **API Token** | Long-lived, token theft | Short-lived, scoped, rotate constantly |

### PAM Architecture

```
                    ┌──────────────────────┐
                    │    PAM Vault          │
                    │  (CyberArk/Delinea/   │
                    │   HashiCorp Vault)    │
                    │                      │
                    │  ┌───────┐ ┌──────┐  │
                    │  │ Secre-│ │Sessn │  │
                    │  │ t Stor│ │ Mgmt │  │
                    │  └───────┘ └──────┘  │
                    └──────────┬───────────┘
                               │
            ┌──────────────────┼──────────────────┐
            │                  │                  │
            ▼                  ▼                  ▼
     ┌──────────┐       ┌──────────┐       ┌──────────┐
     │  Session │       │  Admin   │       │  Service │
     │  Record  │       │  Checkout│       │  Account │
     │  (video) │       │  (JIT)   │       │  Rotation│
     └──────────┘       └──────────┘       └──────────┘
```

### PAM Best Practices
- **JIT (Just-In-Time)** — privilege elevation on-demand, selalu expire
- **Session Recording** — record SSH/RDP/REST session buat audit
- **Password Rotation** — auto-rotate after checkout
- **Credential Checkout** — admin harus "checkout" akun, traceable
- **Zero Standing Privileges** — no permanent privileged access
- **Break Glass** — emergency account dengan notifikasi + MFA
- **Approval Workflow** — request → approve (or deny) → grant

---

## Zero Trust & IAM

Prinsip Zero Trust untuk IAM (NIST SP 800-207):

| Prinsip | Implementasi IAM |
|---------|-----------------|
| **Never trust, always verify** | AuthN every request, never assume network perimeter |
| **Least privilege** | JIT & fine-grained authorization |
| **Assume breach** | Micro-segmentation, risk-based conditional access |
| **Continuous verification** | Session risk scoring → re-auth on anomaly |

### IAM Arsitektur Zero Trust

```
┌─────┐   ┌──────────┐   ┌──────────┐   ┌──────────┐
│User  │──>│  Policy  │──>│  IdP +   │──>│  Apps     │
│      │   │  Engine  │   │  AuthZ   │   │          │
└─────┘   │  (PEP)   │   │  (PDP)   │   └──────────┘
          └────┬─────┘   └────┬─────┘
               │               │
               │   ┌───────────┴───────────────┐
               │   │  Context: device posture,  │
               │   │  location, behavior, time, │
               │   │  risk score                │
               │   └───────────────────────────┘
               ▼
          ┌──────────┐
          │ Logs + SIEM│
          └──────────┘
```

### Conditional Access

Policy engine evaluates every auth request against context:

```
Subject + Device + Location + Behavior + Risk = Access Decision
   │        │        │          │          │
   │        │        │          │          │
   ▼        ▼        ▼          ▼          ▼
Allow(step-up MFA) | Deny | Block | Require approval
```

---

## Passwordless Authentication

**Passwordless** — authentication tanpa password statis.

### Methods

| Method | How It Works | Security Level |
|--------|-------------|----------------|
| **Magic Link** | Email dengan one-time login link | ⚠️ Medium (email compromise) |
| **OTP** | One-time password (TOTP/HOTP) | ✅ Kuat (possession factor) |
| **Push Auth** | Phone notification → approve | ✅ Kuat (phishing-resistant) |
| **FIDO2/WebAuthn** | Public key crypto, bound to device | ✅✅ Sangat kuat |
| **Biometric** | Fingerprint/FaceID on device | ✅✅ Kuat (local validation) |
| **Passkeys** | FIDO2 credential sync via cloud | ✅✅ Sangat kuat + convenience |

### Passkeys (Apple/Google/Microsoft standard)

- FIDO2 credential sync via iCloud Keychain / Google Password Manager / MS Authenticator
- Cross-device tetapi origin-bound — phishing-resistant
- Replaces password entirely — no server-side secret

---

## Session Management

### Session Lifecycle

| Fase | Deskripsi | Best Practice |
|------|-----------|---------------|
| **Creation** | Session ID generated after AuthN | Secure random CSPRNG, HttpOnly, Secure, SameSite |
| **Maintenance** | Send session cookie on each request | Sliding expiry, refresh before expiry |
| **Validation** | Server check session validity | Validate IP, user-agent, fingerprint |
| **Termination** | Logout / timeout / revoke | Explicit logout, idle timeout, absolute timeout |

### Session Attack Vectors

| Attack | Mitigasi |
|--------|----------|
| **Session Fixation** | Regenerate session ID after login |
| **Session Hijacking** | HttpOnly + Secure + SameSite cookies, channel binding |
| **CSRF** | Anti-CSRF token, SameSite=Strict/Lax |
| **Session Prediction** | CSPRNG-based session IDs, minimum 128-bit |
| **Concurrent Session** | Limit concurrent session per user, kill old session on re-auth |
| **Session Timeout Bypass** | Enforce server-side timeout, not just client-side timer |

---

## Token-Based Auth

### JWT (JSON Web Token) Structure

```
BASE64(Header) . BASE64(Payload) . Signature
```

**Header:**
```json
{"alg": "RS256", "typ": "JWT", "kid": "key-id-1"}
```

**Payload (claims):**
```json
{
  "sub": "user-abc-123",
  "iss": "https://auth.azharmtq.com",
  "aud": "https://api.azharmtq.com",
  "exp": 1767298800,
  "iat": 1767212400,
  "nbf": 1767212400,
  "jti": "unique-token-id",
  "email": "azhar@example.com",
  "roles": ["admin", "network-operator"]
}
```

### JWT Best Practices

| Practice | Detail |
|----------|--------|
| **Use asymmetric signing** | RS256/ES256 > HS256 (shared secret lebih rentan) |
| **Short expiry** | 15 menit access token, refresh token 7-30 hari |
| **Validate all claims** | sub, iss, aud, exp, nbf, iat, jti |
| **Token binding (DPoP)** | Binding token ke client private key — prevent replay |
| **Revocation** | Token blacklist (redis) atau short-lived + refresh rotation |
| **Don't store secrets in JWT** | JWT payload is base64 encoded, NOT encrypted by default |
| **JWE for sensitive claims** | Encrypted JWT (JWE) jika payload mengandung PII |

### Refresh Token Rotation

```
Auth → Access(15m) + Refresh(7d)
  When access expires:
    Exchange Refresh → New Access(15m) + New Refresh(7d) + Old Refresh invalidated
  If refresh stolen & used:
    Both tokens revoked → user must re-auth
```

---

## API Authentication

### API Auth Methods

| Method | Use Case | Security |
|--------|----------|----------|
| **API Key** | Public APIs, developer access | ❌ Low (static, easy to leak) |
| **Bearer Token** (JWT) | User-context API | ✅ High (short-lived, signed) |
| **OAuth 2.0 Client Credentials** | M2M API | ✅ High (scoped, client secret) |
| **mTLS** | High-security internal APIs | ✅✅ Very high (certificate-based) |
| **HMAC Signature** | Financial APIs | ✅✅ Tamper-proof (AWS SigV4) |
| **Basic Auth** | Legacy (never use) | ❌ Dangerous |

### API Auth Best Practices
- Rate limiting per API key/identity — prevent abuse
- API key rotation — auto-rotate keys berkala
- Scope-based tokens — `read:logs` ≠ `write:logs`
- Audit logging setiap API auth attempt (success & failure)
- Block leaked keys — monitor GitHub secret scanning

---

## IAM Architecture Patterns

### Pattern 1: Centralized IdP

```
               ┌──────────┐
               │  IdP     │
               │ (Okta/   │
               │  Keycloak│
               │  AzureAD)│
               └────┬─────┘
                    │
     ┌──────────────┼──────────────┐
     │              │              │
     ▼              ▼              ▼
┌──────────┐  ┌──────────┐  ┌──────────┐
│ App 1    │  │ App 2    │  │ App 3    │
│ (Web)    │  │ (Mobile) │  │ (API)    │
└──────────┘  └──────────┘  └──────────┘
```

**Cocok untuk:** Enterprise dengan banyak aplikasi, SSO requirement.

### Pattern 2: API Gateway Auth

```
User → API Gateway → Auth Service → Token → Gateway → Microservice
          │                                              │
          │  Validate JWT at Gateway (PEP)               │
          │  Forward sub/permissions as header           │
          └──────────────────────────────────────────────┘
```

**Cocok untuk:** Microservices, zero-trust architecture.

### Pattern 3: Decentralized (Self-Contained)

```
App ──→ Local Policy Engine ──→ DB (local RBAC table)
       ↑
  Each app manages own authz
```

**Cocok untuk:** Small-scale, simple role model.

### Pattern 4: Externalized (PDP/PEP)

```
User → [PEP] → PDP (OPA/Cedar/AWS) → [PEP] → Resource
         ↑                               ↑
    Policy Decision Point          Policy Enforcement Point
```

---

## Threats & Mitigations

### IAM Attack Categories

| Attack | IAM Component | Dampak | Mitigasi |
|--------|---------------|--------|----------|
| **Credential Stuffing** | AuthN | Account takeover | Rate limit, CAPTCHA, MFA, credential monitoring |
| **Phishing** | AuthN | Credential theft | FIDO2 (phishing-resistant) MFA, Security Keys |
| **SIM Swap** | MFA (SMS) | MFA bypass | Deprecate SMS, use TOTP/Push/FIDO |
| **Token Replay** | AuthZ (token) | Session hijack | DPoP/mTLS token binding, short expiry |
| **Privilege Escalation** | AuthZ (RBAC/ABAC) | Unauthorized access | Regular access review, JIT privilege, tiered admin |
| **IDOR** | AuthZ (API) | Access other user's data | Object-level authorization, not just API-level |
| **MFA Fatigue** | AuthN (push) | MFA bypass via user approval | Number matching, rate-limit push, geo-fencing |
| **Session Fixation** | Session Mgmt | Session hijack | Regenerate session ID on login |
| **OAuth Misconfiguration** | OAuth/OIDC | Token theft | PKCE, proper redirect URI validation, state parameter |
| **Token Theft (offline)** | Token storage | Persistent access | Secure storage (Keychain/DPAPI), biometric unlock |
| **Insider Threat** | IAM policy | Data exfiltration | DLP, UEBA, monitoring, least privilege |
| **Backdoor Account** | Provisioning | Undetected access | Periodic audit, automated discovery, disable dormant accounts |

---

## Compliance & Standards

| Standard | Fokus | IAM Requirement |
|----------|-------|-----------------|
| **NIST SP 800-63** | Identity Assurance | Authentication strength levels (AAL1/2/3) |
| **NIST SP 800-207** | Zero Trust | Continuous verification, micro-segmentation |
| **SOC 2** | Access Control | Authentication, authorization, access review |
| **PCI DSS v4.0** | AuthN | MFA for admin access to CDE (Req 8.4) |
| **ISO 27001** | A.9 Access Control | Access control policy, user access provisioning |
| **GDPR** | Data Privacy | Pseudonymization, access log, right to erasure |
| **HIPAA** | Healthcare PHI | Unique user IDs, automatic logoff, audit controls |
| **SOX** | Financial controls | Access management, SoD (segregation of duties) |
| **FedRAMP** | US Government | FICAM, PIV/CAC integration, continuous monitoring |
| **EE.UU. ITE** | Indonesia | Perlindungan data pribadi (PDP Bill), access logging |

---

## Tools Comparison

### IdP / SSO Solutions

| Tool | Type | Open Source | Multi-Tenant | FIDO2 | SCIM | Notes |
|------|------|-------------|--------------|-------|------|-------|
| **Keycloak** | IdP | ✅ (Apache 2.0) | ✅ | ✅ | ✅ | Community, feature-rich |
| **Okta** | IdP | ❌ | ✅ | ✅ | ✅ | Enterprise, expensive |
| **Azure AD** | IdP | ❌ | ✅ | ✅ | ✅ | Microsoft ecosystem, hybrid AD |
| **Google Workspace** | IdP | ❌ | ✅ | ✅ | ✅ | GWS ecosystem |
| **Auth0** | IdP | ❌ | ✅ | ✅ | ✅ | Developer-friendly, CIAM |
| **Gluu** | IdP | ✅ | ✅ | ✅ | ✅ | Open-source, certified |
| **Ping Identity** | IdP | ❌ | ✅ | ✅ | ✅ | Enterprise, very mature |
| **Authentik** | IdP | ✅ | ✅ | ✅ | ✅ | Modern, focused on automation |

### PAM Solutions

| Tool | Type | Open Source | Session Recording | JIT | Secrets | Notes |
|------|------|-------------|-------------------|-----|---------|-------|
| **CyberArk** | PAM | ❌ | ✅ | ✅ | ✅ | Market leader, expensive |
| **Delinea (Thycotic)** | PAM | ❌ | ✅ | ✅ | ✅ | Mid-range PAM |
| **HashiCorp Vault** | Secrets | ✅ (BSL) | ❌ | ✅ | ✅ | Secrets-focused, integrate with PAM |
| **Teleport** | PAM | ✅ | ✅ | ✅ | ✅ | SSH/k8s/database access |
| **Border0** | PAM | ❌ | ✅ | ✅ | ❌ | Zero Trust access |
| **wallix** | PAM | ❌ | ✅ | ✅ | ✅ | European PAM |
| **ManageEngine PAM360** | PAM | ❌ | ✅ | ✅ | ✅ | Mid-market |

### Auth Libraries (Developer)

| Library | Protocol | Language | Notes |
|---------|----------|----------|-------|
| **OIDC Client (npm)** | OIDC | Node.js | Relying Party library |
| **OAuth2 Proxy** | OAuth/OIDC | Go | Reverse proxy auth |
| **Spring Security** | OAuth/SAML | Java | Full-stack security |
| **Devise + OmniAuth** | OAuth | Ruby | Rails standard |
| **python-social-auth** | OAuth/SAML | Python | Django/Flask |
| **oauthlib** | OAuth | Python | Low-level OAuth |
| **PyJWT** | JWT | Python | JWT encode/decode |
| **dex** | IdP | Go | Kubernetes-native IdP |
| **Casdoor** | IdP | Go | Modern open-source IdP |

---

## Bottom Line

> [!tip] Bottom Line
> IAM bukan cuma soal login. Di level minimum, setiap service harus punya:
> 1. **MFA** untuk privileged access — phishing-resistant (FIDO2) preferred
> 2. **Least privilege** — RBAC atau ABAC, bukan wildcard permission
> 3. **Short-lived tokens** — JWT 15m access, refresh rotation
> 4. **Audit trail** — every auth attempt logged, SIEM-integrated
> 5. **Lifecycle automation** — provisioning → review → deprovision, zero standing privileges
>
> Untuk jarsWAF: IAM relevant pas implementasi **admin dashboard**, **API authentication**, dan **multi-tenant isolation**. PAM techniques (JIT credential, short-lived keys) jadi inspirasi buat API token management di WAF control plane.

---

## Referensi & Lanjutan

- [NIST SP 800-63 Rev 5 — Digital Identity](https://pages.nist.gov/800-63-4/)
- [NIST SP 800-207 — Zero Trust Architecture](https://csrc.nist.gov/publications/detail/sp/800-207/final)
- [OAuth 2.0 Authorization Framework (RFC 6749)](https://datatracker.ietf.org/doc/html/rfc6749)
- [OpenID Connect Core 1.0](https://openid.net/specs/openid-connect-core-1_0.html)
- [FIDO2/WebAuthn (W3C)](https://www.w3.org/TR/webauthn-3/)
- [SAML V2.0 (OASIS)](https://docs.oasis-open.org/security/saml/Post2.0/sstc-saml-tech-overview-2.0.html)
- [OAuth 2.1 (RFC in progress)](https://datatracker.ietf.org/doc/html/draft-ietf-oauth-security-topics)
- [OWASP Authentication Cheatsheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [[network-security]] — network-layer access control
- [[endpoint-security]] — endpoint detection & IAM integration
- [[blueteam-detection-matrix]] — detection rules untuk IAM attacks
