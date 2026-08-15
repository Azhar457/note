---
title: Attack Perspective — Zero Trust Bypass (Red Team)
tags:
- attack
- red-team
- zero-trust
- ztna
- identity
- segmentation
- trust-broker
- bypass
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Zero Trust — Perspektif Penyerang (Bypass)

> Zero Trust = "never trust, always verify". Red team bypass: trust broker compromise (SPOF), identity theft (SSO), device trust bypass (MDM), micro-segmentation gap, BYOD gap, policy exception.

## 1. Zero Trust Attack Surface

| Komponen ZT | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|-------------|--------|----------|--------|---------|----------------|
| **Identity Provider (SSO)** | IdP compromise → forge auth | T1606 | Golden SAML, IdP key theft | Forged assertion = valid | IdP audit = rare |
| **Trust Broker (ZTNA)** | Broker compromise → all access | T1190 | Broker RCE, session hijack | Broker = trusted path | Broker audit = rare |
| **Device Trust** | MDM bypass, device spoof | T1556 | Frida hook, certificate clone | Device = "trusted" | Device attestation = partial |
| **MFA** | AiTM proxy, push fatigue, backup code | T1556 | Evilginx2, MFA fatigue | MFA = passed (proxy) | MFA bypass = legit login |
| **Micro-segmentation** | East-west gap, policy exception | T1570 | Unsegmented legacy, exception path | Exception = approved access | Policy exception = audit gap |
| **BYOD** | Unmanaged device → shadow access | T1078 | Personal device, no MDM | BYOD = out of policy scope | BYOD audit = rare |
| **Session** | Session token theft (cookie, OAuth) | T1539 | AiTM → token, cookie theft | Token = valid session | Session anomaly = partial |
| **API Gateway** | Gateway bypass, direct backend | T1190 | Origin IP discovery, backend direct | Direct = no ZT policy | Gateway audit = ingress only |

## 2. AiTM MFA Bypass (Zero Trust Core)

```
Setup: Evilginx2 → proxy ke IdP login
    ↓
Phishing:
  ├── Send link → victim login (proxy)
  ├── Victim: username + password → proxy
  ├── Victim: MFA code → proxy
  └→ Proxy: forward → real IdP → session token captured
    ↓
Session Theft:
  ├── Proxy captures session cookie (post-auth)
  ├── Attacker: use cookie → valid session
  └→ MFA = passed (by proxy) → ZT sees legit login
    ↓
Persistence: Refresh token → renew → long-term access
    ↓
Result: Zero Trust = "verified" identity = attacker
```

## 3. ZTNA Broker Bypass

```
Target: ZTNA broker (Cloudflare Access, Zscaler, Perimeter 81)
    ↓
Attack Option 1 — Broker RCE:
  ├── Broker vulnerability → RCE → control policy engine
  ├── Modify access policy → attacker = all access
  └→ Broker = trusted → policy change = legit
    ↓
Attack Option 2 — Session Hijack:
  ├── Session token theft → replay → access as user
  ├── JWT forge (weak key) → admin token
  └→ Broker sees valid session
    ↓
Attack Option 3 — Direct Backend:
  ├── Discover origin IP (DNS history, cert)
  ├── Direct request → bypass ZTNA entirely
  └→ Backend = no ZT enforcement (misconfig)
    ↓
Attack Option 4 — Client Bypass:
  ├── ZTNA client disable → direct network
  ├── Split tunnel → part of traffic unmanaged
  └→ Policy = client-side trust (weak)
```

## 4. Bypass Matrix

| ZT Kontrol | Bypass | Konkret |
|-----------|--------|---------|
| MFA | AiTM proxy | Evilginx2 → session token |
| Device attestation | Frida hook | Hook attestation API → return valid |
| Micro-segmentation | Policy exception | Legacy app exception → east-west gap |
| SSO | Golden SAML | Forge assertion with stolen IdP key |
| ZTNA broker | Direct origin | Origin IP → bypass broker |
| Session | Token theft | Cookie steal → valid session |
| Identity | Credential stuffing | Breach data → legit login |

## 5. Tool Stack

| Tool | Use |
|------|-----|
| **Evilginx2** | AiTM proxy (MFA bypass) |
| **Frida** | Device attestation bypass |
| **SecurityTrails** | Origin IP discovery |
| **AADInternals** | Azure AD token forge |
| **Golden SAML** | IdP assertion forge |
| **Burp Suite** | Session/token manipulation |

## 6. Referensi
- NIST 800-207 (Zero Trust) — https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-207.pdf
- Evilginx2 — https://github.com/kgretzky/evilginx2
- Golden SAML — https://www.fireeye.com/content/dam/...
- Cloudflare Access — https://www.cloudflare.com/zero-trust/
- ZT Bypass Research — https://www.blackhillsinfosec.com/...

## Konkret — Zero Trust Bypass Payload (Testable)

### Trust Broker Compromise

```bash
# 1. Phish admin SSO → impersonate trust broker
# 2. Tap token via ADFS / OAuth code injection
# 3. Cross-realm trust bypass: federated SAML ke realm B
#    SAML assertion modify → claim admin role realm B

# Forge SAML token (Golden SAML):
# 1. Extract IdP private key (ADFS etc)
# 2. For assertion: user=admin, audience=https://target.com/saml
# 3. Sign Assertion (GoldenSAML.py)
# 4. Access SP sebagai admin (no MFA, no password)
#    - bypass ZTNA broker -> ZTNA session hijack
```

### Enforcement Gap Exploitation

```
# ZTNA implementasi: enforcement di proxy / gateway
# Gap: jika proxy bypass, policy enforcement skipped

# Bypass via direct service access:
# 1. VPN / direct connect (legacy) masih aktif (jarang dipakai)
# 2. Service mesh internal (sidecar) tidak enforce ke legacy node
# 3. API gateway dengan undocumented backend endpoints
# 4. Load balancer direct IP → bypass broker

# Exploit:
# 1. Scan internal IP range (discovered via DNS / leaked)
# 2. Direct hit ke service-api:8080 (di belakang ZTNA proxy)
# 3. Bypass: proxy yang enforce policy, service tidak
```

### Identity-Based Lateral Movement

```bash
# ZT identify user/device — tapi pivot dari compromised device
# 1. Compromesasi workstation → kredensial/token di RAM
# 2. PRT (Primary Refresh Token) extract (AzureAD)
# 3. Token reply / refresh via PRT → access cloud resource

# Mimikatz PRT extract:
mimikatz sekurlsa::cloudap
# Output: PRT token → access AzureAD resource (semua)
```
---

audited
---
