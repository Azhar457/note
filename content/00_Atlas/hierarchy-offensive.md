---
tags:
  - hierarchy
  - offensive-security
  - skill-progression
  - red-team
  - apt
aliases:
  - Offensive Hierarchy
  - Red Team Levels
  - Skill Progression Matrix
created: 2026-04-30
---

# ☠️ Hierarchy Offensive Security — Level 0 sampai APT Simulator

&gt; Hierarki skill progression untuk offensive security practitioner. Dari tool runner sampai custom implant developer. Setiap level punya cara kerja, tembok yang menghentikan, counter Blue Team, dan cara naik ke level berikutnya.

---

## Level 0 — Script Kiddie

| Aspek                    | Detail                                                                                      |
| ------------------------ | ------------------------------------------------------------------------------------------- |
| **Cara Kerja**           | Menjalankan tool tanpa paham mekanisme. Copy-paste command dari tutorial.                   |
| **Tool Contoh**          | SQLMap dengan `--dump-all` tanpa paham SQL, Metasploit dengan `exploit` tanpa paham payload |
| **Tembok**               | Tool gagal → tidak tahu kenapa. Firewall block → tidak tahu alternatif.                     |
| **🔵 Blue Team Counter** | Signature-based detection, WAF rule, IDS default alert                                      |
| **🔴 Red Team Advance**  | Paham output tool. Baca error message. Paham parameter yang dipakai.                        |

---

## Level 1 — Tool Operator

| Aspek                    | Detail                                                                                  |
| ------------------------ | --------------------------------------------------------------------------------------- |
| **Cara Kerja**           | Paham parameter, output, dan limitasi tool. Bisa tuning untuk target spesifik.          |
| **Tool Contoh**          | Nmap dengan NSE script custom, Burp Suite dengan extension, SQLMap dengan tamper script |
| **Tembok**               | Tool tidak support edge case. Butuh manual exploit untuk CVE baru.                      |
| **🔵 Blue Team Counter** | Behavioral detection (anomali scanning pattern), rate limiting, honeypot                |
| **🔴 Red Team Advance**  | Baca source code tool. Paham protokol di balik tool. Bisa exploit tanpa framework.      |

---

## Level 2 — Manual Exploiter

| Aspek                    | Detail                                                                                                 |
| ------------------------ | ------------------------------------------------------------------------------------------------------ |
| **Cara Kerja**           | Bisa exploit tanpa Metasploit/Burp. Paham protokol HTTP/TCP/UDP secara mendalam. Craft payload manual. |
| **Tool Contoh**          | Custom Python exploit dengan `requests`/`socket`, manual SQLi union-based, buffer overflow PoC         |
| **Tembok**               | OS-level defense: ASLR, DEP, stack canary. Network-level: firewall stateful, IPS.                      |
| **🔵 Blue Team Counter** | EDR behavioral analysis, memory protection, network segmentation                                       |
| **🔴 Red Team Advance**  | Paham OS internals. Paham memory layout. Baca assembly. Kernel-level thinking.                         |

---

## Level 3 — Privilege Escalation Specialist

| Aspek                    | Detail                                                                                         |
| ------------------------ | ---------------------------------------------------------------------------------------------- |
| **Cara Kerja**           | Dari user shell → root/system. Abuse OS internals: token, ACL, kernel driver, scheduled tasks. |
| **Tool Contoh**          | Mimikatz, BloodHound, LinPEAS/WinPEAS, Potato family, custom kernel exploit                    |
| **Tembok**               | Windows Defender Credential Guard, LSA protection, UAC max, AppLocker, SELinux                 |
| **🔵 Blue Team Counter** | EDR kernel callback, ETW (Event Tracing for Windows), Sysmon, privileged access management     |
| **🔴 Red Team Advance**  | Paham Windows AD. Kerberos protocol. Trust relationship. Enterprise architecture.              |

---

## Level 4 — Active Directory Attacker

| Aspek                    | Detail                                                                                               |
| ------------------------ | ---------------------------------------------------------------------------------------------------- |
| **Cara Kerja**           | Enterprise environment attack. Kerberoasting, AS-REP Roasting, Pass-the-Hash, DCSync, Golden Ticket. |
| **Tool Contoh**          | BloodHound (attack path), CrackMapExec, Impacket (ntlmrelayx, secretsdump), Rubeus                   |
| **Tembok**               | AD hardening: Protected Users group, Authentication Policy Silo, SID filtering, smart card           |
| **🔵 Blue Team Counter** | Microsoft Defender for Identity, ATA (Advanced Threat Analytics), AD anomaly detection               |
| **🔴 Red Team Advance**  | Long-term ops. Stealth. C2 infrastructure. Malleable traffic. Evasion engineering.                   |

---

## Level 5 — C2 Operator (Red Team)

| Aspek                    | Detail                                                                                             |
| ------------------------ | -------------------------------------------------------------------------------------------------- |
| **Cara Kerja**           | Long-term covert operation. Custom C2 profile. Sleep obfuscation. Domain fronting. Anti-forensics. |
| **Tool Contoh**          | Cobalt Strike (malleable C2), Sliver, Havoc, Mythic, custom implant Nim/Go/Rust                    |
| **Tembok**               | NGFW with SSL inspection, EDR memory scanning, threat hunting, deception technology                |
| **🔵 Blue Team Counter** | Purple Team exercise, threat hunting (IoC + IoA), behavioral analytics, deception (honey tokens)   |
| **🔴 Red Team Advance**  | Custom malware development. Zero-day research. Supply chain attack. Hardware implant.              |

---

## Level 6 — APT Simulator / Nation-State Level

| Aspek                    | Detail                                                                                                                        |
| ------------------------ | ----------------------------------------------------------------------------------------------------------------------------- |
| **Cara Kerja**           | Full spectrum cyber operation. Custom toolchain. Zero-day exploit. Supply chain poison. Hardware implant. SIGINT integration. |
| **Tool Contoh**          | Custom C++ implant, position-independent shellcode, UEFI bootkit, malicious USB firmware, PCIe DMA                            |
| **Tembok**               | Air-gapped network, hardware security module, TEMPEST shielding, strict supply chain verification                             |
| **🔵 Blue Team Counter** | Air gap, out-of-band monitoring, hardware attestation, insider threat program, counterintelligence                            |
| **🔴 Red Team Advance**  | N/A — ini batas praktis untuk individual. Memerlukan organisasi dengan resource nation-state.                                 |

---

## Peta Posisi — Visual

Level 0 │ Script Kiddie → Tool runner, copy-paste Level 1 │ Tool Operator → Paham parameter & output Level 2 │ Manual Exploiter → Craft exploit tanpa framework Level 3 │ PrivEsc Specialist→ OS internals, token abuse Level 4 │ AD Attacker → Enterprise, Kerberos, trust Level 5 │ C2 Operator → Stealth, long-term, evasion Level 6 │ APT Simulator → Custom malware, zero-day, hardware

---

## Dual-Use Framework (Cara Berpikir)

| Pertanyaan                  | Level 0-2         | Level 3-4             | Level 5-6                 |
| --------------------------- | ----------------- | --------------------- | ------------------------- |
| "Apa yang saya pahami?"     | Tool output       | OS/protocol internals | Behavioral pattern        |
| "Apa yang saya bisa build?" | Script automation | Custom exploit        | Custom implant            |
| "Apa yang Blue Team lihat?" | Signature alert   | Behavioral anomaly    | IoA (Indicator of Attack) |
| "Apa yang saya bisa evade?" | Basic AV          | EDR behavioral        | Memory forensics          |

---

## 🔗 Lihat Juga

- [[application|Master Arsenal]] — HTML arsenal tool reference
- [[offensive-security|Offensive Security Roadmap]] — Learning path 10 bulan
- [[network-security|Network Security]] — OSI Layer threat landscape
- [[underground-knowledge|Underground Knowledge]] — Cheat Engine & Dark Web hierarchy
- [[01_library/cyber_security/endpoint-security|Endpoint_Security]] — CPU Ring & boot chain
- [[01_Library/military-and-intelligence-tools/military-and-intelligence-tools-hub|military-and-intelligence-tools-hub]] — Peta alat Shadow Arsenal Level 0–6
- [[01_Library/military-and-intelligence-tools/military-intelligence-tools-hierarchy|military-and-intelligence-tools Hierarchy]] — Deep dive cara kerja & deteksi alat militer/intelijen

---

_Hierarchy Offensive Security | Level 0 (Script Kiddie) → Level 6 (APT Simulator)_
