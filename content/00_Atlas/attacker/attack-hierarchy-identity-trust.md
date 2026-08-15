---
title: Attack Perspective — Identity & Trust (Red Team)
tags:
- attack
- red-team
- identity
- iam
- sso
- mfa
- zero-trust
- sso
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Identity & Trust — Perspektif Penyerang

> Identity adalah perimeter baru. Red team tidak menyerang firewall — mereka menyerang **trust model**: SSO, MFA, federation, certificate, biometric.

## 1. Attack Surface Identity

| Komponen | Vektor | MITRE ID | Tool / CVE | Evasion | Detection Gap |
|----------|--------|----------|------------|---------|----------------|
| **SSO (SAML/OAuth/OIDC)** | Token forge, assertion injection, relay attack | T1606 | SAMLForge, Golden SAML, OAuth consent phish | Assertion = legitimate format, cert = stolen | SSO audit jarang real-time |
| **MFA** | AiTM (Adversary-in-the-Middle), push fatigue, SIM swap | T1556 | Evilginx2, Modlishka, MFA fatigue script | AiTM = real proxy, user tidak tahu | MFA bypass = looks like legit login |
| **FIDO2/WebAuthn** | Downgrade attack, clone detection bypass | T1556 | Browser downgrade, Frida (mobile) | Downgrade ke SMS/TOTP jika fallback available | FIDO2 audit tidak universal |
| **Kerberos** | Kerberoasting, AS-REP, Golden/Silver Ticket, delegation | T1558 | Rubeus, Impacket, KrbRelayUp | Kerberos = legit protocol traffic | 4769 audit — tapi cert auth bypass |
| **Federation** | Federation trust poisoning, shadow corp, Azure AD guest | T1136 | Azure AD guest abuse, shadow tenant | Trust = established, activity = legit | Federation audit jarang |
| **Biometric** | Presentation attack (spoof), Frida hook bypass, template theft | T1556 | Silicone fingerprint, deepfake face, Frida anti-root | Spoof = physical, Frida = software bypass | Liveness detection imperfect |
| **Service Account** | Token theft, krb5 replay, JWT replay | T1528 | kubectl (SA token), Impacket (TGT replay) | Token = valid, use = legit application | SA token audit = noisy |
| **Certificate Auth** | Certifried (CVE-2022-26923), PetitPotam relay | T1649 | Certipy, PetitPotam.py | Cert = valid from internal CA | CT log tidak cover internal CA |

## 2. Identity Attack Chain

```
Recon: Identifikasi IdP (Okta, Azure AD, On-Prem AD), federation, MFA type
 ↓
Credential Phishing: AiTM proxy (Evilginx2) → user login → intercept credential + session token
 ↓
MFA Bypass: AiTM proxy → MFA passed via proxy → session token captured → bypass MFA
 ↓
Session Hijack: Inject session token → browser → access aplikasi → silent persistence
 ↓
Persistence: OAuth grants (create malicious app consent), Azure AD service principal (backdoor)
 ↓
Privilege Escalation: IAM abuse (PassRole/AssumeRole), AD attack (Kerberoasting → DCSync)
 ↓
Lateral: Kerberos delegation, NTLM relay, cloud role chaining
 ↓
Impact: Domain admin, cloud admin, data exfil, ransomware deployment
```

## 3. Golden SAML Attack (Federation Compromise)

```
Prereq: Compromise IdP signing key (ADF5, Azure AD Connect, AD FS)
 ↓
Forge SAML assertion: buat assertion dengan identity = admin user
 ↓
Sign with stolen IdP key: assertion = valid signature
 ↓
Send ke SP (Service Provider): SharePoint, Salesforce, AWS console
 ↓
SP validate signature → valid → grant access → attacker = admin
 ↓
Evasion: Tidak ada login dari attacker (assertion = forged) — log menunjukkan legit user
```

## 4. CVE & Teknik Identity

| CVE / Teknik | Target | Impact | Red Team Value |
|--------------|--------|--------|-----------------|
| CVE-2022-26923 (Certifried) | AD CS | Domain admin via cert | Critical — persistent |
| CVE-2021-36942 (PetitPotam) | MS-EFSRPC | NTLM relay → AD CS → DA | High — no creds needed |
| Golden SAML | AD FS / Azure AD | Forge authentication | Critical — stealthy |
| OAuth Consent Phishing | Azure AD / Google | API access via consent | High — user unknowing grants access |
| AiTM (Evilginx2) | Any SSO | Session token theft | High — bypass MFA |

## 5. Tool Stack Identity Attack

| Tool | Use |
|------|-----|
| **Evilginx2** | AiTM phishing proxy (credential + session token) |
| **Rubeus** | Kerberoasting, AS-REP, ticket forge, delegation abuse |
| **Certipy** | AD CS abuse (ESC1-14, Certifried) |
| **PetitPotam.py** | NTLM relay ke AD CS |
| **TOKENIMPERSONATOR** | Azure AD token forge + inject |
| **AADInternals** | Azure AD attack toolkit (guest, app, backdoor) |
| **Frida** | Mobile biometric bypass (anti-root, liveness bypass) |

## 6. Referensi
- Evilginx2 — https://github.com/kgretzky/evilginx2
- Rubeus — https://github.com/GhostPack/Rubeus
- Certipy — https://github.com/ly4k/Certipy
- AADInternals — https://github.com/Gerenios/AADInternals
---

audited
---
