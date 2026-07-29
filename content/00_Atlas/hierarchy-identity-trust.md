---
tags:
  - hierarchy
  - cross-cutting
  - identity
  - trust
  - iam
  - zero-trust
aliases:
  - Identity and Trust Hierarchy
  - From Anonymous to Sovereign Identity
  - Trust Model Map
  - Authentication Levels
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# 🪪 Identity & Trust Hierarchy — Dari Anonim ke Self-Sovereign

> [!tip] Identitas digital adalah **fondasi trust** di internet. Catatan ini memetakan **7 lapisan identitas** dari anonim penuh hingga self-sovereign identity (SSI), dengan model trust (PKI, Web of Trust, ZKP), framework Zero Trust, dan regulasi (eIDAS 2.0, GDPR). Dengan analogi lintas domain: legal identity, medical identity, dan criminal forensics.

---

## Daftar Isi

1. [[#1. Premise — Trust Adalah Fondasi Internet]]
2. [[#2. Seven-Layer Identity Hierarchy]]
3. [[#3. Layer I0 — Anonymous]]
4. [[#4. Layer I1 — Pseudonymous]]
5. [[#5. Layer I2 — Verified Pseudonymous]]
6. [[#6. Layer I3 — Verified Human]]
7. [[#7. Layer I4 — Federated Identity]]
8. [[#8. Layer I5 — Sovereign Identity]]
9. [[#9. Layer I6 — Self-Sovereign Identity (SSI)]]
10. [[#10. Trust Models Comparison]]
11. [[#11. Zero Trust Architecture]]
12. [[#12. Cross-Reference ke Vault]]
13. [[#References]]

---

## 1. Premise — Trust Adalah Fondasi Internet

Tanpa identitas dan trust, internet adalah anarkisme murni — tidak bisa transaksi, tidak bisa authentication. Setiap layer identity trade-off: **privacy vs accountability**.

**Spektrum:**

```
Anonymous (0 trust, full privacy)
    ↓
Pseudonymous (beberapa sesi, bisa di-revoke)
    ↓
Verified Pseudonymous (KYC untuk alias)
    ↓
Verified Human (legal name verified)
    ↓
Federated (Google/Apple login — bawa trust dari penyedia)
    ↓
Sovereign (government-issued digital ID)
    ↓
Self-Sovereign (kontrol penuh user, kriptografi, ZKP)
```

---

## 2. Seven-Layer Identity Hierarchy

```
┌────────────────────────────────────────────────────────────┐
│ I6 │ Self-Sovereign (SSI / DID / Verifiable Credentials)  │ ← max control
├────────────────────────────────────────────────────────────┤
│ I5 │ Sovereign (Gov ID, eIDAS, Aadhaar)                   │
├────────────────────────────────────────────────────────────┤
│ I4 │ Federated (OIDC, SAML, Google/Apple login)           │
├────────────────────────────────────────────────────────────┤
│ I3 │ Verified Human (KYC, AML, biometric bind)            │
├────────────────────────────────────────────────────────────┤
│ I2 │ Verified Pseudonymous (SSH key, wallet address)       │
├────────────────────────────────────────────────────────────┤
│ I1 │ Pseudonymous (username, show name)                   │
├────────────────────────────────────────────────────────────┤
│ I0 │ Anonymous (no identity)                               │ ← max privacy
└────────────────────────────────────────────────────────────┘
```

---

## 3. Layer I0 — Anonymous

### 3.1 Karakteristik

| Aspek           | Deskripsi                             |
| --------------- | ------------------------------------- |
| **Identitas**   | Tidak ada persistent identifier       |
| **Linkability** | Sesi tidak bisa di-link ke sesi lain  |
| **Contoh**      | Tor browsing, incognito mode, 4chan   |
| **Trust level** | 0 (semua dianggap potensial attacker) |
| **Use case**    | Whistleblower, censorship avoidance   |

### 3.2 Risiko

- **Sybil attack** — satu orang membuat 1000 akun
- **No accountability** — spam, abuse, fraud
- **No recovery** — forget password = no account

---

## 4. Layer I1 — Pseudonymous

### 4.1 Karakteristik

| Aspek           | Deskripsi                                                |
| --------------- | -------------------------------------------------------- |
| **Identitas**   | Alias persistent di satu platform                        |
| **Linkability** | Dalam platform bisa di-track, antar platform belum tentu |
| **Contoh**      | Reddit username, Discord handle, HN account              |
| **Trust level** | Low (bisa saja bot atau sockpuppet)                      |

### 4.2 Trade-off

- **Pro:** Privacy tinggi, reputation dapat dibangun
- **Con:** Tidak ada legal recourse, tidak bisa digunakan untuk transaksi finansial

---

## 5. Layer I2 — Verified Pseudonymous

### 5.1 Karakteristik

| Aspek           | Deskripsi                                          |
| --------------- | -------------------------------------------------- |
| **Identitas**   | Cryptographic key pair — bukan identitas legal     |
| **Linkability** | Semua transaksi keypair linkable                   |
| **Contoh**      | SSH key, Bitcoin address, GPG key                  |
| **Trust level** | Medium (cryptographically verifiable, tapi anonim) |

### 5.2 Mitigasi

- Web of Trust (GPG signing parties)
- Reputation scores (GitHub contributions tied to SSH key)

---

## 6. Layer I3 — Verified Human

### 6.1 Karakteristik

| Aspek           | Deskripsi                                 |
| --------------- | ----------------------------------------- |
| **Identitas**   | Legal identity verified (KYC, AML)        |
| **Linkability** | Bisa cross-platform                       |
| **Contoh**      | Bank account, exchange, government portal |
| **Trust level** | High (verified by legal identity)         |
| **Biaya**       | KYC procedure, document scan              |

### 6.2 Regulasi

- **KYC** (Know Your Customer) — FATF, bank regulation
- **AML** (Anti-Money Laundering) — transaction monitoring
- **CDD** (Customer Due Diligence) — risk assessment

**Analogi hukum:** KTP/SIM sebagai identitas yang diverifikasi negara.

---

## 7. Layer I4 — Federated Identity

### 7.1 Karakteristik

| Aspek           | Deskripsi                                |
| --------------- | ---------------------------------------- |
| **Identitas**   | Bawa identitas dari penyedia ke aplikasi |
| **Protocol**    | OAuth 2.0, OIDC, SAML 2.0                |
| **Provider**    | Google, Apple, Microsoft, GitHub         |
| **Trust model** | Trust the provider (IdP)                 |
| **Contoh**      | "Login with Google", Azure AD SSO        |

### 7.2 Architecture

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│ Service     │ ──→ │ Identity    │ ←── │ User        │
│ (RP)        │     │ Provider    │     │ (Browser)   │
│             │     │ (IdP)       │     │             │
│ API: verify │     │ Has:        │     │ Has:        │
│ token       │     │ credentials │     │ password    │
└─────────────┘     └─────────────┘     └─────────────┘
```

---

## 8. Layer I5 — Sovereign Identity

### 8.1 Karakteristik

| Aspek           | Deskripsi                                                    |
| --------------- | ------------------------------------------------------------ |
| **Identitas**   | Government-issued, legal name                                |
| **Linkability** | Universal across all services                                |
| **Contoh**      | eIDAS (EU), Aadhaar (India), SingPass (SG), NIST 800-63 IAL3 |
| **Trust level** | Highest (state-backed)                                       |

### 8.2 eIDAS 2.0 (EU, 2024)

- **eIDAS 1.0** (2014) — notified eID cross-border
- **eIDAS 2.0** (2024) — EU Digital Identity Wallet
  - Qualified Electronic Signature (QES)
  - Qualified Electronic Attestation of Attributes (QEAA)
  - Voluntary, but mandatory for public services

### 8.3 Risiko Sovereign

| Risiko       | Contoh                          |
| ------------ | ------------------------------- |
| Surveillance | Government knows every login    |
| Data breach  | Aadhaar breach (1.1B records)   |
| No anonymity | Dissident cannot use his gov ID |

---

## 9. Layer I6 — Self-Sovereign Identity (SSI)

### 9.1 Karakteristik

| Aspek           | Deskripsi                                                    |
| --------------- | ------------------------------------------------------------ |
| **Identitas**   | User-controlled, cryptographic                               |
| **Linkability** | User decides what to share                                   |
| **Protocol**    | Decentralized Identifiers (DID), Verifiable Credentials (VC) |
| **Trust model** | Trust the cryptography (ZKP, BBS+)                           |
| **Contoh**      | ION (Sidetree on Bitcoin), cheqd, Hyperledger Indy           |

### 9.2 SSI Triangle

```
┌──────────────────────────────────────┐
│ Holder (User)                        │
│   ├─ Holds VC in wallet              │
│   ├─ Presents selectively via ZKP    │
│   └─ Controls DID                    │
└────────┬─────────────────────────────┘
         │ presents VC             │ issues VC
         ↓                         ↓
┌──────────────────┐      ┌──────────────────────┐
│ Verifier (RP)    │      │ Issuer (Authority)   │
│   └─ Verifies ZKP│      │   └─ Signs VC with   │
│     via DID doc  │      │     its DID          │
└──────────────────┘      └──────────────────────┘
```

### 9.3 Pro & Con SSI

| Pro                          | Con                                                  |
| ---------------------------- | ---------------------------------------------------- |
| User controls own data       | User must manage keys (risk of loss)                 |
| Selective disclosure via ZKP | Complex cryptographic standards (maturity 2024-2026) |
| No central point of failure  | Interoperability across DID methods (75+ DIDs)       |

---

## 10. Trust Models Comparison

| Model                  | Karakteristik              | Contoh                       |
| ---------------------- | -------------------------- | ---------------------------- |
| **Direct**             | A langsung tahu B          | Face-to-face, pre-shared key |
| **Third Party (PKI)**  | CA memverifikasi           | TLS, X.509                   |
| **Web of Trust (WoT)** | Collective signing         | GPG, PGP                     |
| **Federated**          | IdP verifikasi             | OIDC, SAML                   |
| **Reputation**         | History + rating           | eBay, Airbnb                 |
| **ZK Proof**           | Prove tanpa reveal         | SSI, anonymous credential    |
| **Zero Trust**         | Never trust, always verify | BeyondCorp                   |
| **Distributed (DLT)**  | Blockchain consensus       | Bitcoin, Ethereum            |

---

## 11. Zero Trust Architecture

### 11.1 Prinsip

```
Never trust, always verify:
- Every request is treated as hostile
- Every user must authenticate every time
- Every device must pass health check
- Access = least privilege, just-in-time
```

### 11.2 Implementasi

| Komponen                | Contoh                        |
| ----------------------- | ----------------------------- |
| Identity-aware proxy    | Cloudflare Access, Google IAP |
| Device posture check    | CrowdStrike, SentinelOne      |
| Context-aware policy    | BeyondCorp, zscaler           |
| Microsegmentation       | Cilium, Calico, NSX           |
| Continuous verification | Signal-based, risk score      |

**Koneksi ke Vault:**

- [[hierarchy-cybersecurity-defense-architecture]] — L7 (IAM) L6 (Zero Trust) full alignment
- [[hierarchy-llm-ai-systems]] — AI agent identity layer

---

## 12. Cross-Reference ke Vault

|  Layer  | Catatan Vault Terkait                                             |
| :-----: | ----------------------------------------------------------------- |
| **I0**  | [[hierarchy-osi...rf]] — OSINT intelligence dari footprint anonim |
| **I1**  | [[hierarchy-offensive]] — Red team social engineering             |
| **I2**  | [[hierarchy-cryptography]] — PKI key management                   |
| **I3**  | [[hierarchy-cybersecurity-defense-architecture]] — IAM L7         |
| **I4**  | [[hierarchy-it-domain]] — Federated identity di enterprise        |
| **I5**  | [[hierarchy-cybersecurity-defense-architecture]] — Compliance L8  |
| **I6**  | (masih baru, cross-link ke self-sovereign jika ada)               |
| **ZT**  | [[hierarchy-cybersecurity-defense-architecture]] — Zero Trust     |
| **All** | [[hierarchy-abstraction-layers]] — Identity di L9 (intent layer)  |

---

## References

1. NIST SP 800-63-4. _"Digital Identity Guidelines."_ 2023.
2. NIST SP 800-207. _"Zero Trust Architecture."_ 2020.
3. C. Allen. _"The Path to Self-Sovereign Identity."_ 2016.
4. W3C. _"Decentralized Identifiers (DIDs) v1.0."_ 2022.
5. W3C. _"Verifiable Credentials Data Model v1.1."_ 2022.
6. eIDAS 2.0 Regulation (EU) 2024/... _"European Digital Identity."_
7. Hardjono, T. _"Sovrin Architecture and DID Methods."_ 2018.
8. DIF. _"Decentralized Identity Foundation Specifications."_ 2023.
9. OpenID Foundation. _"OpenID Connect Core."_ 2014.
10. Internet Identity Workshop. _"SSI Meetup — DIDComm."_ 2020-2024.
