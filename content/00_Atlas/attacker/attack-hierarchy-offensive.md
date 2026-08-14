---
title: Attack Perspective — Offensive Security (Level 0-6 Red Team)
tags: [attack,red-team,offensive,apt,c2,zero-day]
source: hierarchy-offensive.md
status: complete
---
cssclasses:
  - wide-table
  - callout

# Offensive Security — Perspektif Penyerang per Level

> Source hierarchy-offensive.md sudah punya struktur Level 0-6. Versi attack ini menambahkan CVE konkret, tool spesifik, dan detection gap per level.

## 1. Per-Level Attack Upgrade

| Level | Capability | CVE Konkret | Tool Stack | Evasion | Detection Gap |
|-------|-----------|-------------|------------|---------|---------------|
| **L0** Script Kiddie | sqlmap --dump-all, Metasploit exploit | Tidak perlu CVE (tool publik) | sqlmap, Metasploit, nmap default | Tidak ada (tool signature = AV trivial detect) | AV/EDR signature catch cepat |
| **L1** Tool Operator | Nmap NSE custom, Burp extension, SQLMap tamper | CVE scanning (searchsploit) | nmap NSE, Burp Suite Pro, SQLMap tamper script | Delay scan, random user-agent, proxy chain | Behavioral scan detection — tapi low rate = below threshold |
| **L2** Manual Exploiter | Custom Python exploit, manual SQLi, buffer overflow PoC | CVE-2021-3156 (sudo), CVE-2022-0847 (Dirty Pipe), CVE-2023-4911 (Looney Tunables) | pwntools, requests, socket, manual payload | No framework signature — custom code = no IoC | EDR tidak kenali custom exploit — perlu behavioral detection |
| **L3** PrivEsc Specialist | Mimikatz, BloodHound, LinPEAS, Potato family, kernel exploit | CVE-2023-4911, CVE-2024-1086 (nf_tables UAF), CVE-2022-0847 | Mimikatz (custom build), BloodHound, LinPEAS, GodPotato | Direct syscall, PPL bypass (CVE-2024-21410), AMSI/ETW patch | EDR kernel callback — tapi direct syscall + BYOVD = bypass |
| **L4** AD Attacker | Kerberoasting, DCSync, Golden Ticket, NTLM relay, AD CS abuse | CVE-2022-26923 (Certifried), CVE-2021-36942 (PetitPotam), CVE-2021-42287 (noPac) | Rubeus, Certipy, Impacket, CrackMapExec, ntlmrelayx | Kerberos traffic = legit, cert auth = no password audit, relay = no creds | 4769/4662/5136 monitoring — tapi cert-based auth = invisible ke password audit |
| **L5** C2 Operator | Custom C2 profile, sleep obfuscation, domain fronting, anti-forensics | Tidak perlu CVE publik (custom implant) | Cobalt Strike, Havoc, Sliver, Mythic, custom Nim/Go/Rust | JA3 spoof, traffic shaping, BOF in-memory, module stomping | NGFW SSL inspection — tapi domain fronting + custom JA3 = bypass |
| **L6** APT Simulator | Custom C++ implant, UEFI bootkit, supply chain poison, hardware implant | Zero-day (custom, tidak publik), CVE-2022-0001 (Boot Guard bypass), BlackLotus (UEFI rootkit) | Custom toolchain, UEFI implant, PCIe DMA, SIGINT integration | Pre-OS execution, firmware persistence, hardware-level = no EDR signal | Air-gap, hardware attestation — tapi firmware implant = survive all |

## 2. Kill Chain per Level (L0 → L6 Escalation)

```
L0: sqlmap --dump-all → dapat credential → login
L1: nmap -sV → identify service → searchsploit → public exploit
L2: custom exploit (CVE-2023-4911) → root → upload payload
L3: Mimikatz → LSASS dump → hash → pass-the-hash → lateral
L4: BloodHound → attack path → Kerberoasting → DCSync → domain admin
L5: Cobalt Strike → Malleable C2 → domain fronting → stealth persistence
L6: UEFI implant (BlackLotus) → survive reinstall → hardware persistence → SIGINT
```

## 3. Blue Team Detection Matrix (Gap per Level)

| Level | Blue Team Kontrol Utama | Gap Deteksi |
|-------|------------------------|-------------|
| L0-L1 | AV signature, WAF rule, IDS default | Custom payload = no signature |
| L2 | EDR behavioral, memory protection | Custom exploit = no IoC, butuh behavioral baseline |
| L3 | EDR kernel callback, ETW, Sysmon | Direct syscall + BYOVD = bypass kernel callback |
| L4 | 4769/4662/5136, Defender for Identity | Cert auth + delegation = legit traffic pattern |
| L5 | NGFW SSL inspect, threat hunting, deception | Domain fronting + custom JA3 = blend, honey token = dapat skip |
| L6 | Air gap, hardware attestation, counter-intel | Firmware implant = EDR blind, air gap = physical only |

## 4. Referensi
- MITRE ATT&CK Enterprise — https://attack.mitre.org/
- Atomic Red Team — https://github.com/redcanaryco/atomic-red-team
- The DFIR Report — https://thedfirreport.com/
- SpecterOps (AD Security) — https://posts.specterops.io/
- BlackLotus UEFI Bootkit — https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/