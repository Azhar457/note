---
title: Attack Perspective — Military & Intelligence Tools (Red Team / APT)
tags:
- attack
- red-team
- military
- intel
- sigint
- apt
- nation-state
- spyware
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Military & Intel Tools — Perspektif APT / Nation-State

> Tool militer/intelijen adalah **puncak piramida offensive** — zero-day custom, hardware implant, SIGINT global. Red team enterprise meniru TTP ini; nation-state menjalankan operasi nyata.

## 1. Capability Tier (Level 0-6)

| Level | Kemampuan | Tool / Platform | Sumber | Red Team Use |
|-------|-----------|----------------|--------|--------------|
| **L0** OSINT | Google dorks, Shodan, public record | Google, Shodan, Maltego | Public | Reconnaissance — map target |
| **L1** Pentest framework | Metasploit, Burp Suite, Nmap | Rapid7, PortSwigger | Commercial | Initial access, web exploit |
| **L2** C2 & post-exploit | Cobalt Strike, Mythic, Sliver, Havoc | Commercial + OSS | Mixed | Persistence, lateral, exfil |
| **L3** Commercial spyware | Pegasus (NSO), Predator (Cytrox), FinSpy (FinFisher) | NSO Group, Cytrox, FinFisher | Commercial (regulated) | Zero-click exploit, mobile target |
| **L4** SIGINT platform | XKEYSCORE, PRISM, UPSTREAM/TEMPORA | NSA/GCHQ | Snowden leak | Passive global interception |
| **L5** Nation-state platform | FoxAcid, QUANTUMINSERT, IC-REACH, MUSCULAR | NSA | Snowden leak | Active exploitation + cloud intercept |
| **L6** Hardware implant | ANT Catalog (COTTONMOUTH, IRATEMONK), custom firmware | NSA TAO | Snowden leak | Supply chain implant, persistent hardware |

## 2. Spyware Deepdive (L3)

| Spyware | Vendor | Target | Teknik | CVE / Zero-day | Detection |
|---------|--------|--------|--------|-----------------|-----------|
| **Pegasus** | NSO Group (Israel) | iOS, Android | Zero-click (iMessage, WhatsApp) → kernel exploit → full device | CVE-2023-XXXX (iMessage), ForcedEntry (Citizen Lab) | Citizen Lab, Amnesty Tech — but detection = post-fact |
| **Predator** | Cytrox (Greece) | iOS, Android | Zero-click + 1-click → kernel exploit | CVE-2024-XXXX (IntelenceX) | Amnesty Tech — post-fact |
| **FinSpy** | FinFisher (Germany) | Windows, Android, iOS | Trojan bundle, custom implant | Custom — no public CVE | Reverse engineering by academia |
| ** Reign** | unknown | Linux server | Kernel rootkit | Zero-day custom | Server hardening — detect via memory |

## 3. SIGINT Platform (L4-L5)

| Platform | Fungsi | Sumber | Konkret | Evasion |
|----------|--------|--------|---------|---------|
| **XKEYSCORE** | Passive packet filter — email, chat, browsing | NSA (Snowden) | Query selector (email address, keyword) → pull past traffic | Passive — no interaction |
| **PRISM** | Data request ke tech company (Google, Facebook, Apple, Microsoft) | NSA (Snowden) | Direct access ke server → user data | Legal demand — no hack |
| **UPSTREAM/TEMPORA** | Fiber optic tap (undersea cable) | NSA/GCHQ (Snowden) | Physical tap → bulk traffic recording | Passive — no interaction |
| **FoxAcid** | Exploit server (MITM redirect) | NSA (Snowden) | Redirect target → FoxAcid → exploit → implant | Redirect = BGP/DNS hijack |
| **QUANTUMINSERT** | TCP injection (MITM) | NSA (Snowden) | Race legitimate response → inject exploit packet | TCP race = fast redirect |
| **IC-REACH** | Cross-database query (SIGINT + HUMINT) | NSA (Snowden) | Fuse all database → unified persona profile | N/A — analysis platform |
| **MUSCULAR** | Google/Yahoo cloud intercept | NSA/GCHQ (Snowden) | Tap fiber between datacenter → unencrypted internal traffic | Passive — exploit internal trust |

## 4. Hardware Implant (L6)

| Implant | ANT Catalog | Target | Fungsi | Detection |
|---------|------------|--------|--------|-----------|
| **COTTONMOUTH-I** | USB implant with radio | USB port | Radio frequency C2, exfil via covert channel | Physical audit (x-ray, teardown) |
| **COTTONMOUTH-III** | USB hub implant | USB hub | Network tap + C2 | Hardware audit |
| **IRATEMONK** | Firmware implant (hard drive) | HDD firmware | Persistent across format/reinstall | HDD firmware audit (rare) |
| **GOURMETTROUGH** | BIOS firmware implant | BIOS/UEFI | Boot-level persistence | BIOS audit (rare) |
| **ANGRY NEIGHBOR** | RFID implant | RFID-enabled device | Covert monitoring | RF sweep |
| **FEEDTROUGH** | Firewall/router firmware | Juniper, Cisco, Huawei | Network-level persistence + exfil | Firmware audit (rare) |

## 5. Red Team Emulation Chain (Nation-State TTP)

```
Recon (L0): OSINT → identify target (employee, infra, tech stack)
 ↓
Initial Access (L1-L3): Phishing + Zero-day (Pegasus-style) → kernel exploit → full device
 ↓
Persistence (L4-L6): Firmware implant (IRATEMONK-style) → survive reinstall
 ↓
C2 (L5): Custom implant + domain fronting + SIGINT-style passive channel
 ↓
Collection (L4): XKEYSCORE-style — passive traffic recording + active device exploit
 ↓
Exfiltration (L6): Covert channel (RF, firmware, USB) → offline exfil
 ↓
Impact: Long-term intelligence gathering (months-years) — tidak rusak target
```

## 6. Referensi
- NSA ANT Catalog (Der Spiegel) — https://www.spiegel.de/international/world/
- Snowden Documents — https://en.wikipedia.org/wiki/Global_surveillance_disclosures_(2013%E2%80%93present))
- Pegasus (Citizen Lab) — https://citizenlab.ca/2021/07/
- Predator (Amnesty) — https://amnesty.tech/
- XKEYSCORE (Wikipedia) — https://en.wikipedia.org/wiki/XKeyscore
- QUANTUMINSERT — https://en.wikipedia.org/wiki/Quantum_insert
- FinFisher (FinSpy) — https://en.wikipedia.org/wiki/FinFisher
---

audited
---
