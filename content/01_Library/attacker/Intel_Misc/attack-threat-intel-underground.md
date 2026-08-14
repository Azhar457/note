---
title: Attack Perspective — Threat Intel Underground (Red Team)
tags:
- attack
- red-team
- threat-intel
- underground
- forum
- marketplace
- telegram
- osint
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Threat Intel Underground — Perspektif Penyerang

> Underground = pasar intel (credential, exploit, tools, service). Red team pakai sebagai research source: pelajari TTP, beli intel target, monitor APT discourse.

## 1. Underground Ecosystem

| Layer | Platform | Konten | Red Team Use | Stealth |
|-------|----------|--------|-------------|---------|
| **Forum** | Exploit.in, XSS.is, RAMP, Carding forum | Exploit, tools, tutorial | TTP research, tool source | Tor/VPN |
| **Marketplace** | Genesis, Russian Market | Credential, session, fingerprint | Credential stuffing source | Monero payment |
| **Telegram** | Private channel, bot | Data leak, tools, C2-as-service | OSINT, IOC monitoring | Burner account |
| **C2-as-Service** | Commercial C2 (Colossus, Warzone) | Infrastructure rental | Cheap infra | API access |
| **RaaS** | Ransomware affiliate | Access brokerage, negotiation | TTP mimicry | Affiliate program |
| **Leak Site** | Ransomware blog | Victim data dump | PII research, password reuse | Passive view |
| **Exploit Market** | Zero-day broker | 0-day sale ($50K-$2.5M) | Capability purchase | Broker trust |

## 2. Credential Stuffing via Underground

```
Buy: Credential dump (forum/marketplace)
  ├── Target + password hash → crack (hashcat)
  ├── Session cookie (Genesis) → direct session
  └→ Fingerprint (browser profile) → bypass device trust
    ↓
Validate:
  ├── OpenBullet / Storm → config → auto login test
  ├── Rate: low per IP (proxy) → below threshold
  └→ Proxy rotation → distributed
    ↓
Exploit:
  ├── Password reuse → email/login → lateral
  ├── Session replay → no MFA prompt
  └→ Fingerprint replay → device trust bypass
```

## 3. Intel Collection (Red Team Research)

```
Monitoring:
  ├── Telegram channel → leak announcement → early access
  ├── Forum thread → TTP evolution → detection gap
  ├── Leak site → victim data → password reuse pattern
  └→ RaaS affiliate → access brokerage → target intel
    ↓
Apply:
  ├── New tool → RE → capability → emulate
  ├── New CVE discussion → exploit pattern → build before patch
  ├── Victim data → credential pattern → spray
  └→ Broker intel → target access → initial foothold
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **Tor** | Forum access (anonymity) |
| **Telegram API** | Channel monitoring (telegra.ph, bot) |
| **hashcat** | Hash crack (credential dump) |
| **OpenBullet / Storm** | Credential validation |
| **Proxychains** | Proxy chaining (underground access) |
| **Monero wallet** | Payment privacy |

## 5. Referensi
- Flashpoint — https://flashpoint.io/
- Recorded Future Intel — https://www.recordedfuture.com/
- DarkOwl — https://www.darkowl.com/
- RAMP forum research — https://www.recordedfuture.com/resources/ramp-up
- Pegasus/NSO intel — https://citizenlab.ca/