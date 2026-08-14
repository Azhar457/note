---
title: Hierarchy Offensive
tags:
- atlas
created: '2026-04-30'
updated: '2026-07-01'
status: pending
---

cssclasses:
  - wide-table
  - callout

# ☠️ Hierarchy Offensive Security — Level 0 sampai APT Simulator

Hierarki skill progression untuk offensive security practitioner membagi kemampuan menjadi enam level, dari yang paling dasar hingga yang paling maju. Setiap level memiliki cara kerja, tembok yang menghentikan, counter Blue Team, dan cara naik ke level berikutnya.

## Level 0 — Script Kiddie

Pada level ini, individu hanya menjalankan tool tanpa memahami mekanisme di baliknya. Mereka sering melakukan copy-paste command dari tutorial tanpa memahami output atau parameter yang digunakan.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Menjalankan tool tanpa paham mekanisme. Copy-paste command dari tutorial. |
| **Tool Contoh** | SQLMap dengan `--dump-all` tanpa paham SQL, Metasploit dengan `exploit` tanpa paham payload |
| **Tembok** | Tool gagal → tidak tahu kenapa. Firewall block → tidak tahu alternatif. |
| **🔵 Blue Team Counter** | Signature-based detection, WAF rule, IDS default alert |
| **🔴 Red Team Advance** | Paham output tool. Baca error message. Paham parameter yang dipakai. |

Contoh kode implementasi untuk level ini adalah:
```python
import os

# Menjalankan SQLMap dengan --dump-all
os.system("sqlmap -u http://example.com --dump-all")
```
Namun, perlu diingat bahwa menjalankan tool tanpa memahami mekanisme di baliknya dapat menyebabkan kerusakan pada sistem atau data.

## Level 1 — Tool Operator

Pada level ini, individu telah memahami parameter, output, dan limitasi tool. Mereka dapat men-tuning tool untuk target spesifik dan memahami cara mengatasi tembok yang menghentikan.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Paham parameter, output, dan limitasi tool. Bisa tuning untuk target spesifik. |
| **Tool Contoh** | Nmap dengan NSE script custom, Burp Suite dengan extension, SQLMap dengan tamper script |
| **Tembok** | Tool tidak support edge case. Butuh manual exploit untuk CVE baru. |
| **🔵 Blue Team Counter** | Behavioral detection (anomali scanning pattern), rate limiting, honeypot |
| **🔴 Red Team Advance** | Baca source code tool. Paham protokol di balik tool. Bisa exploit tanpa framework. |

Contoh kode implementasi untuk level ini adalah:
```python
import nmap

# Menjalankan Nmap dengan NSE script custom
nm = nmap.PortScanner()
nm.scan("example.com", "1-1024", "-sV")
```
Dengan memahami cara kerja tool dan protokol di baliknya, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan.

## Level 2 — Manual Exploiter

Pada level ini, individu telah memahami cara kerja tool dan protokol di baliknya. Mereka dapat melakukan exploit tanpa menggunakan framework seperti Metasploit atau Burp Suite.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Bisa exploit tanpa Metasploit/Burp. Paham protokol HTTP/TCP/UDP secara mendalam. Craft payload manual. |
| **Tool Contoh** | Custom Python exploit dengan `requests`/`socket`, manual SQLi union-based, buffer overflow PoC |
| **Tembok** | OS-level defense: ASLR, DEP, stack canary. Network-level: firewall stateful, IPS. |
| **🔵 Blue Team Counter** | EDR behavioral analysis, memory protection, network segmentation |
| **🔴 Red Team Advance** | Paham OS internals. Paham memory layout. Baca assembly. Kernel-level thinking. |

Contoh kode implementasi untuk level ini adalah:
```python
import requests

# Menjalankan exploit manual dengan requests
url = "http://example.com/vuln"
payload = {"id": "1' OR '1'='1"}
response = requests.post(url, data=payload)
```
Dengan memahami cara kerja protokol dan melakukan exploit manual, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan.

## Level 3 — Privilege Escalation Specialist

Pada level ini, individu telah memahami cara kerja OS internals dan dapat melakukan privilege escalation.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Dari user shell → root/system. Abuse OS internals: token, ACL, kernel driver, scheduled tasks. |
| **Tool Contoh** | Mimikatz, BloodHound, LinPEAS/WinPEAS, Potato family, custom kernel exploit |
| **Tembok** | Windows Defender Credential Guard, LSA protection, UAC max, AppLocker, SELinux |
| **🔵 Blue Team Counter** | EDR kernel callback, ETW (Event Tracing for Windows), Sysmon, privileged access management |
| **🔴 Red Team Advance** | Paham Windows AD. Kerberos protocol. Trust relationship. Enterprise architecture. |

Contoh kode implementasi untuk level ini adalah:
```python
import mimikatz

# Menjalankan Mimikatz untuk privilege escalation
mimikatz.run(" lsadump::sam")
```
Dengan memahami cara kerja OS internals dan melakukan privilege escalation, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan.

## Level 4 — Active Directory Attacker

Pada level ini, individu telah memahami cara kerja Active Directory dan dapat melakukan serangan pada jaringan enterprise.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Enterprise environment attack. Kerberoasting, AS-REP Roasting, Pass-the-Hash, DCSync, Golden Ticket. |
| **Tool Contoh** | BloodHound (attack path), CrackMapExec, Impacket (ntlmrelayx, secretsdump), Rubeus |
| **Tembok** | AD hardening: Protected Users group, Authentication Policy Silo, SID filtering, smart card |
| **🔵 Blue Team Counter** | Microsoft Defender for Identity, ATA (Advanced Threat Analytics), AD anomaly detection |
| **🔴 Red Team Advance** | Long-term ops. Stealth. C2 infrastructure. Malleable traffic. Evasion engineering. |

Contoh kode implementasi untuk level ini adalah:
```python
import bloodhound

# Menjalankan BloodHound untuk attack path
bh = bloodhound.Bloodhound("example.com")
bh.attack_path()
```
Dengan memahami cara kerja Active Directory dan melakukan serangan pada jaringan enterprise, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan.

## Level 5 — C2 Operator (Red Team)

Pada level ini, individu telah memahami cara kerja C2 infrastructure dan dapat melakukan serangan stealth pada jaringan enterprise.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Long-term covert operation. Custom C2 profile. Sleep obfuscation. Domain fronting. Anti-forensics. |
| **Tool Contoh** | Cobalt Strike (malleable C2), Sliver, Havoc, Mythic, custom implant Nim/Go/Rust |
| **Tembok** | NGFW dengan SSL inspection, EDR memory scanning, threat hunting, deception technology |
| **🔵 Blue Team Counter** | Purple Team exercise, threat hunting (IoC + IoA), behavioral analytics, deception (honey tokens) |
| **🔴 Red Team Advance** | Custom malware development. Zero-day research. Supply chain attack. Hardware implant. |

Contoh kode implementasi untuk level ini adalah:
```python
import cobaltstrike

# Menjalankan Cobalt Strike dengan malleable C2
cs = cobaltstrike.CobaltStrike("example.com")
cs.malleable_c2()
```
Dengan memahami cara kerja C2 infrastructure dan melakukan serangan stealth pada jaringan enterprise, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan.

## Level 6 — APT Simulator / Nation-State Level

Pada level ini, individu telah memahami cara kerja serangan APT dan dapat melakukan serangan pada skala besar.

| Aspek | Detail |
|-------|--------|
| **Cara Kerja** | Full spectrum cyber operation. Custom toolchain. Zero-day exploit. Supply chain poison. Hardware implant. SIGINT integration. |
| **Tool Contoh** | Custom C++ implant, position-independent shellcode, UEFI bootkit, malicious USB firmware, PCIe DMA |
| **Tembok** | Air-gapped network, hardware security module, TEMPEST shielding, strict supply chain verification |
| **🔵 Blue Team Counter** | Air gap, out-of-band monitoring, hardware attestation, insider threat program, counterintelligence |
| **🔴 Red Team Advance** | N/A — ini batas praktis untuk individual. Memerlukan organisasi dengan resource nation-state. |

Dengan memahami cara kerja serangan APT dan melakukan serangan pada skala besar, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan.

## Peta Posisi — Visual
Level 0 │ Script Kiddie → Tool runner, copy-paste
Level 1 │ Tool Operator → Paham parameter & output
Level 2 │ Manual Exploiter → Craft exploit tanpa framework
Level 3 │ PrivEsc Specialist→ OS internals, token abuse
Level 4 │ AD Attacker → Enterprise, Kerberos, trust
Level 5 │ C2 Operator → Stealth, long-term, evasion
Level 6 │ APT Simulator → Custom malware, zero-day, hardware

Dengan memahami peta posisi di atas, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan dan memahami cara kerja serangan pada skala besar.

## Dual-Use Framework (Cara Berpikir)

| Pertanyaan | Level 0-2 | Level 3-4 | Level 5-6 |
|------------|-----------|-----------|-----------|
| "Apa yang saya pahami?" | Tool output | OS/protocol internals | Behavioral pattern |
| "Apa yang saya bisa build?" | Script automation | Custom exploit | Custom implant |
| "Apa yang Blue Team lihat?" | Signature alert | Behavioral anomaly | IoA (Indicator of Attack) |
| "Apa yang saya bisa evade?" | Basic AV | EDR behavioral | Memory forensics |

Dengan memahami cara berpikir di atas, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan dan memahami cara kerja serangan pada skala besar.

Dalam melakukan serangan, perlu diingat bahwa setiap level memiliki cara kerja, tembok yang menghentikan, counter Blue Team, dan cara naik ke level berikutnya. Dengan memahami cara kerja setiap level dan melakukan serangan pada skala besar, individu dapat meningkatkan kemampuan mereka dalam melakukan serangan dan memahami cara kerja serangan pada skala besar.