---
title: Attack Perspective — Military & Intelligence Tools (Red Team / APT)
tags:
- attack
- red-team
- military
- intel
- sigint
- spyware
- pegasus
- hardware-implant
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Military & Intel Tools — Perspektif APT / Nation-State

> Puncak offensive pyramid: zero-day custom, hardware implant, SIGINT global. Red team enterprise tiru TTP; nation-state jalankan operasi nyata.

## 1. Capability Tier

| Level | Kemampuan | Tool / Platform | Sumber | Red Team Use |
|-------|-----------|----------------|--------|--------------|
| L0 | OSINT | Google dork, Shodan, Maltego | Public | Recon |
| L1 | Pentest framework | Metasploit, Burp, Nmap | Commercial | Initial access |
| L2 | C2 & post-exploit | Cobalt Strike, Mythic, Sliver | Mixed | Persistence, lateral |
| L3 | Commercial spyware | Pegasus (NSO), Predator (Cytrox), FinSpy | Commercial | Zero-click mobile |
| L4 | SIGINT platform | XKEYSCORE, PRISM, TEMPORA | NSA/GCHQ | Passive interception |
| L5 | Nation-state platform | FoxAcid, QUANTUMINSERT, MUSCULAR | NSA | Active exploitation |
| L6 | Hardware implant | ANT Catalog (COTTONMOUTH, IRATEMONK) | NSA TAO | Supply chain implant |

## 2. Spyware Deepdive

| Spyware | Vendor | Target | Teknik | Detection |
|---------|--------|--------|--------|-----------|
| **Pegasus** | NSO Group | iOS, Android | Zero-click (iMessage) → kernel exploit | Post-fact (Citizen Lab) |
| **Predator** | Cytrox | iOS, Android | Zero/1-click → kernel exploit | Post-fact |
| **FinSpy** | FinFisher | Windows, Android, iOS | Trojan bundle, custom implant | RE by academia |
| **Hermit** | RCS Lab | iOS, Android | Custom implant | Post-fact |

## 3. SIGINT Platform

| Platform | Fungsi | Konkret | Evasion |
|----------|--------|---------|---------|
| **XKEYSCORE** | Passive filter | Query → past traffic | Pasif |
| **PRISM** | Tech company data | Direct access → user data | Legal demand |
| **TEMPORA** | Fiber tap | Bulk recording | Pasif |
| **FoxAcid** | Exploit server | MITM redirect → exploit | Redirect |
| **QUANTUMINSERT** | TCP inject | Race → inject packet | Fast redirect |
| **MUSCULAR** | Cloud intercept | Fiber between DC → internal | Pasif |

## 4. Hardware Implant (ANT Catalog)

| Implant | Target | Fungsi |
|---------|--------|--------|
| COTTONMOUTH-I | USB | RF C2 + exfil |
| COTTONMOUTH-III | USB hub | Network tap |
| IRATEMONK | HDD firmware | Survive format |
| GOURMETTROUGH | BIOS | Boot persistence |
| FEEDTROUGH | Router/switch | Network persistence |

## 5. Referensi
- ANT Catalog (Der Spiegel) — https://www.spiegel.de/international/world/
- Pegasus (Citizen Lab) — https://citizenlab.ca/2021/07/
- XKEYSCORE — https://en.wikipedia.org/wiki/XKeyscore
- Snowden Docs — https://en.wikipedia.org/wiki/Global_surveillance_disclosures
- FinFisher — https://en.wikipedia.org/wiki/FinFisher
---

audited
---
