---
title: Attack Perspective — Cybersecurity Defense Architecture
tags:
  - attack
  - red-team
  - defense-in-depth
  - mitre-attack
  - cve
source: hierarchy-cybersecurity-defense-architecture.md
status: complete
created: 2026-08-14
updated: 2026-08-14
cssclasses:
  - wide-table
  - code-wrap
  - math-render
---

# 🔴 Attack Perspective: Cybersecurity Defense Architecture

> **Maksud dokumen ini:** Memetakan **9 lapis pertahanan** dari sudut pandang **penyerang (Red Team / Adversary)** — bagaimana setiap layer dijebol, teknik evasion konkret, CVE eksploitasi nyata, dan MITRE ATT&CK mapping. Bukan teori, tapi operational guidance untuk red team operator.

---

## 1. Threat Model & Assumptions

| Asumsi | Deskripsi |
|--------|-----------|
| **Attacker Capability** | Level 3-5 (Manual Exploiter → AD Attacker → C2 Operator) |
| **Initial Access** | Phishing (T1566), Exploit Public-Facing App (T1190), Valid Accounts (T1078) |
| **Goal** | Data exfil, ransomware, persistence, lateral movement, domain dominance |
| **OpSec Requirement** | Evade EDR/XDR/NDR, avoid IoC, blend with legit traffic |
| **Time Budget** | Weeks-months (APT-style), bukan smash-and-grab |

---

## 2. Layer-by-Layer Attack Mapping

### L9: Brand & Reputation → **TARGET: Crisis Comms & Disclosure Process**

| Attack Vector | Technique (MITRE) | CVE/Tool | Evasion |
|---------------|-------------------|----------|---------|
| Leak staged data pre-disclosure | T1656 (Impair Defenses: Disable/Modify Tools) | Custom script | Encrypt leak, use dead-drop |
| Hijack comms channel (email/social) | T1585.002 (Establish Accounts: Email Accounts) | Phishing kit | Compromise PR/legal email first |
| Stock manipulation via breach news | T1658 (Financial Theft) | N/A | Coordinate with insider trading |

**Red Team Note:** L9 bukan technical target — tapi **leverage point**. Kalau sudah dapat data (L3), gunakan L9 sebagai pressure untuk ransom/extortion.

---

### L8: Compliance & Legal → **TARGET: Audit Gaps & Evidence Destruction**

| Attack Vector | Technique | CVE/Tool | Evasion |
|---------------|-----------|----------|---------|
| Tamper audit logs | T1562.001 (Impair Defenses: Disable/Modify Tools) | `auditpol`, `wevtutil` | Clear specific Event IDs only |
| Forge compliance artifacts | T1656 (Impair Defenses) | Custom templates | Use valid certs from compromised CA |
| Exploit regulatory blind spots | N/A | Research | Operate in jurisdictions w/o extradition |

**Red Team Note:** Compliance ≠ Security. Banyak org "compliant" tapi **blind di L4-L6**. Audit scope biasanya limited — cari yang **di luar scope**.

---

### L7: Identity & Access (IAM) → **PRIMARY TARGET: Credential Access & Privilege Escalation**

| Attack Vector | MITRE Technique | CVE/Tool | Evasion |
|---------------|-----------------|----------|---------|
| **Kerberoasting** | T1558.003 | Rubeus, Impacket | Request RC4_HMAC, offline crack |
| **AS-REP Roasting** | T1558.004 | Rubeus, Impacket | Target accounts w/o preauth |
| **Pass-the-Hash** | T1550.002 | Mimikatz, CrackMapExec | Use NTLM relay (ntlmrelayx) |
| **Pass-the-Ticket** | T1550.003 | Rubeus | Export TGT, inject via sekurlsa |
| **Golden/Silver Ticket** | T1558.001 / T1558.002 | Mimikatz | Forge PAC, target specific SPN |
| **DCSync** | T1003.006 | Mimikatz (lsadump::dcsync) | Need DA/EA rights, low volume |
| **ACL Abuse** | T1550.003 | BloodHound, PowerView | GenericAll, WriteDACL, ForceChangePassword |
| **Shadow Credentials** | T1558.005 | Whisker, PyWhisker | msDS-KeyCredentialLink write |
| **Certifried (CVE-2022-26923)** | T1649 | Certipy, Certifried.py | ESC1-ESC14 templates |
| **PetitPotam (CVE-2021-36942)** | T1550.002 | PetitPotam.py | NTLM relay to AD CS |
| **noPac (CVE-2021-42287/42278)** | T1558.001 | noPac.py | SAM account name spoofing |

**Blue Team Detection Gaps:**
- Kerberoasting: Detect via 4769 (RC4) + high entropy SPN
- DCSync: 4662 (Directory Service Access) + specific GUID
- Shadow Creds: 5136 (Directory Service Changes) + msDS-KeyCredentialLink
- Certifried: 4769 + 4776 + cert request anomalies

---

### L6: Application Security → **TARGET: Initial Access, RCE, Supply Chain**

| Attack Vector | MITRE Technique | CVE/Tool | Evasion |
|---------------|-----------------|----------|---------|
| **SQL Injection** | T1190 | sqlmap, custom payloads | WAF bypass (encoding, comments, HTTP parameter pollution) |
| **SSRF** | T1190 | Gopherus, custom | Cloud metadata bypass (169.254.169.254, IPv6, DNS rebind) |
| **Deserialization (Java/.NET/PHP)** | T1190 | ysoserial, ysoserial.net, PHPGGC | Gadget chain selection, encoding |
| **Log4Shell (CVE-2021-44228)** | T1190 | JNDIExploit, log4shell-poc | Obfuscated JNDI, WAF bypass |
| **Spring4Shell (CVE-2022-22965)** | T1190 | spring4shell-poc | Data binding + class.module.classLoader |
| **ProxyShell (CVE-2021-34473/34523/31207)** | T1190 | ProxyShell.py | Exchange RCE chain |
| **ProxyLogon (CVE-2021-26855/26857/26858/27065)** | T1190 | ProxyLogon.py | SSRF → RCE via deserialization |
| **Supply Chain (Dependency Confusion)** | T1195.001 | Custom packages | Internal namespace hijack |
| **Supply Chain (CI/CD Poison)** | T1195.002 | GitHub Actions worm, Jenkins exploit | Compromise runner, inject artifact |

**WAF Evasion Techniques (L4 bypass untuk L6):**
- Encoding: URL, double URL, Unicode, Base64, Hex
- HTTP Parameter Pollution (HPP)
- Chunked transfer encoding
- Case variation, whitespace manipulation
- JSON/XML payload obfuscation
- Multipart/form-data boundary abuse

**CVE Priority untuk Red Team (2024-2026):**

| CVE | CVSS | Target | Reliability |
|-----|------|--------|-------------|
| CVE-2024-3400 (PAN-OS) | 10.0 | Palo Alto GlobalProtect | High |
| CVE-2024-21410 (Exchange) | 9.8 | Exchange NTLM Relay | High |
| CVE-2024-27198 (JetBrains TeamCity) | 9.8 | TeamCity RCE | High |
| CVE-2023-4911 (Looney Tunables) | 7.8 | glibc Local PrivEsc | High |
| CVE-2023-38646 (Metabase) | 9.8 | Pre-auth RCE | High |
| CVE-2023-22515 (Confluence) | 10.0 | Broken Access Control | High |
| CVE-2023-20273 (Cisco IOS XE) | 10.0 | Web UI RCE | High |

---

### L5: Endpoint Security (EDR/XDR) → **TARGET: Evasion, Persistence, Defense Evasion**

| Attack Vector | MITRE Technique | Tool/Method | Evasion |
|---------------|-----------------|-------------|---------|
| **Direct Syscalls** | T1055.012 | SysWhispers3, HellsGate, FreshyCalls | Bypass userland hooks |
| **Indirect Syscalls** | T1055.012 | SysWhispers2, DInvoke | Spoof return address |
| **Module Stomping** | T1055.009 | Custom loader | Overwrite legit module memory |
| **Process Hollowing / Doppelgänging** | T1055.012 / T1055.013 | Custom, DONUT | Transactional NTFS (TxF) |
| **PPID Spoofing** | T1055.001 | `CreateProcess` w/ `PROC_THREAD_ATTRIBUTE_PARENT_PROCESS` | Spoof to explorer.exe/winlogon |
| **AMSI Bypass** | T1562.001 | AmsiScanBuffer patch, reflection | Memory patch, not disk |
| **ETW Bypass** | T1562.001 | EtwEventWrite patch, ntdll.dll patch | Silent, no telemetry |
| **EDR Sensor Tamper** | T1562.001 | PSEXEC + driver unload, CVE-2024-21410 | Requires admin |
| **Living off the Land (LOLBins)** | T1218 | certutil, mshta, regsvr32, rundll32, wmic | Signed Microsoft binaries |
| **BOF (Beacon Object Files)** | T1055 | Cobalt Strike BOF, custom | In-memory, no disk touch |
| **DLL Sideloading** | T1574.002 | Legit signed exe + malicious DLL | Legit binary, Microsoft signed |
| **COM Hijacking** | T1546.015 | InprocServer32 redirect | Userland persistence |
| **WMI Event Subscription** | T1546.003 | `__EventFilter` + `__FilterToConsumerBinding` | Stealthy, no file |
| **Scheduled Task (Hidden)** | T1053.005 | `schtasks` / COM handler | Run as SYSTEM, hidden |
| **Service Installation** | T1543.003 | `sc create` / `CreateService` | Persistent, SYSTEM |
| **Kernel Driver (BYOVD)** | T1068 | Vulnerable driver + exploit | CVE-2023-20269, CVE-2024-21410 |

**EDR/XDR Evasion Matrix:**

| EDR | Key Weakness | Bypass Method |
|-----|--------------|---------------|
| Defender for Endpoint | AMSI/ETW heavy | Direct syscalls + AMSI patch |
| CrowdStrike Falcon | Kernel callbacks | BYOVD (CVE-2024-21410) or userland stomping |
| SentinelOne | Behavioral ML | Delay execution, environment checks |
| Cortex XDR | Multi-source correlation | Fragment TTPs across time/hosts |
| Elastic Defend | eBPF + userland | Indirect syscalls + memory encryption |
| Trend Micro Apex One | Pattern + heuristic | Heavy obfuscation + LOLBins |

---

### L4: Network Security → **TARGET: C2, Lateral Movement, Data Exfil**

| Attack Vector | MITRE Technique | Tool/CVE | Evasion |
|---------------|-----------------|----------|---------|
| **C2 over HTTPS (Malleable)** | T1071.001 | Cobalt Strike, Havoc, Sliver, Mythic | Domain fronting, CDN, JA3 spoof |
| **C2 over DNS** | T1071.004 | dnscat2, iodine, dnstt | Subdomain encoding, high entropy |
| **C2 over Cloud APIs** | T1102 | Azure/AWS/GCP APIs | Legit cloud traffic blend |
| **C2 over WebSocket** | T1071.001 | Custom, Sliver | Full duplex, bypass HTTP inspect |
| **C2 over Email (SMTP/IMAP)** | T1102.001 | Custom, GTR | Legit mail flow |
| **C2 over Social Media** | T1102.002 | Twitter, GitHub, Telegram API | Blend with user traffic |
| **VPN/SSH Pivot** | T1090.001 | SSHuttle, Chisel, ligolo-ng | Encrypted tunnel, legit port |
| **SOCKS/HTTP Proxy Chain** | T1090.002 | Proxychains, reGeorg, Neo-reGeorg | Multi-hop, internal only |
| **Kerberos Delegation Abuse** | T1550.003 | Rubeus (s4u), KrbRelayUp | Constrained/unconstrained delegation |
| **NTLM Relay** | T1557.001 | ntlmrelayx, KrbRelay | MitM + relay to LDAP/SMB/HTTP |
| **Pass-the-Hash (Network)** | T1550.002 | CrackMapExec, evil-winrm | Lateral via SMB/WMI/WinRM |
| **SMB/ADMIN$ Lateral** | T1021.002 | PsExec, smbexec, wmiexec | Service creation, file copy |
| **WMI Lateral** | T1047 | wmiexec, Invoke-WMIMethod | DCOM/RPC, no SMB |
| **RDP Hijacking** | T1021.001 | tscon, RDP session shadow | No creds needed, SYSTEM |
| **SSH Key Pivot** | T1021.004 | SSH agent forwarding | Linux/Unix lateral |
| **DCOM Lateral** | T1021.003 | Invoke-DCOM, SharpDCOM | MMC20.Application, ShellWindows |
| **Data Exfil over C2** | T1041 | Built-in C2 upload | Chunked, encrypted, timed |
| **Data Exfil over DNS** | T1048.003 | dnscat2, custom | Small chunks, high entropy |
| **Data Exfil over Cloud Storage** | T1537 | rclone, AWS CLI, azcopy | Legit service, encrypted |

**Network Detection Evasion:**
- **JA3/JA3S Spoofing**: Match legit browser/client fingerprint
- **TLS Certificate**: Use valid Let's Encrypt / compromised cert
- **Domain Fronting**: Cloudflare, Azure, AWS CloudFront (dying)
- **CDN Hopping**: Rotate edge IPs
- **Traffic Shaping**: Jitter, bandwidth limits, business hours only
- **Protocol Mimicry**: HTTP/2, gRPC, QUIC framing
- **Encrypted Payload**: AES-256-GCM + custom framing

---

### L3: Data Security & Cryptography → **TARGET: Key Extraction, Cryptographic Attacks**

| Attack Vector                        | MITRE Technique | Tool/CVE                                | Evasion                                      |
| ------------------------------------ | --------------- | --------------------------------------- | -------------------------------------------- |
| **LSASS Memory Dump**                | T1003.001       | `comsvcs.dll`, `procdump`, `PPLdump`    | Bypass PPL (CVE-2024-21410), direct syscalls |
| **DPAPI Master Key Extract**         | T1003.004       | Mimikatz (dpapi::masterkey), SharpDPAPI | Need user context, offline decrypt           |
| **Chrome/Edge Cookie Theft**         | T1555.003       | SharpChromium, CookieMonster            | Decrypt via DPAPI master key                 |
| **Certificate/Key Theft (PFX/JKS)**  | T1552.001       | Certutil, custom enum                   | Find in filesystem, memory, registry         |
| **KMS/Key Vault Access**             | T1552.004       | Cloud CLI, metadata service             | Compromise workload identity                 |
| **Weak Crypto (DES/RC4/MD5/SHA1)**   | T1558.003       | Hashcat, John, custom                   | Downgrade via protocol negotiation           |
| **Padding Oracle**                   | T1190           | PadBuster, custom                       | Error-based, timing                          |
| **Bleichenbacher (RSA PKCS#1 v1.5)** | T1190           | custom                                  | SSL/TLS handshake                            |
| **Logjam (Weak DH)**                 | T1190           | custom                                  | Export-grade DH                              |
| **ROBOT (RSA Oracle)**               | T1190           | robot-detector                          | TLS server                                   |
| **Certificate Transparency Abuse**   | T1590.005       | crt.sh, certspotter                     | Recon, not direct attack                     |

**Post-Quantum Note:** CRYSTALS-Kyber/ML-KEM-768 deployment di 2024-2026 — **classic RSA/ECDH vulnerable to harvest-now-decrypt-later**. Target long-term secrets now.

---

### L2: Cloud & Infrastructure → **TARGET: IAM Abuse, Container Escape, Metadata Service**

| Attack Vector | MITRE Technique | Tool/CVE | Evasion |
|---------------|-----------------|----------|---------|
| **IMDSv1/v2 (169.254.169.254)** | T1590.005 | curl, cloud-cli | SSRF → metadata creds |
| **IAM Privilege Escalation** | T1078.004 | Pacu, CloudSploit, custom | Enumerate `iam:PassRole`, `sts:AssumeRole` |
| **S3 Bucket Misconfig** | T1530 | bucket_finder, s3scanner | Public read/write, ACL abuse |
| **Container Escape (CVE-2024-21626)** | T1611 | runc exploit | Rootless bypass |
| **Container Escape (CVE-2019-5736)** | T1611 | runc exploit | Host filesystem access |
| **K8s RBAC Abuse** | T1078.004 | kubectl, rbac-lookup | `impersonate`, `bind` verbs |
| **K8s Admission Webhook Bypass** | T1548.001 | Mutating webhook race | Time-of-check bypass |
| **Service Account Token Theft** | T1528 | `/var/run/secrets/kubernetes.io/serviceaccount/token` | Mounted in every pod |
| **Cloud Shell / Serial Console** | T1059.004 | Browser-based shell | Legit admin access |
| **CI/CD Pipeline Poison** | T1195.002 | GitHub Actions, GitLab CI, Jenkins | Compromise runner, inject artifact |
| **Terraform State Theft** | T1530 | S3 backend, local state | Contains secrets, outputs |
| **Secrets in Code/Config** | T1552.001 | TruffleHog, GitLeaks, grep | Public/private repos |

**Cloud CVE Priority (2024-2026):**
| CVE | Service | Impact |
|-----|---------|--------|
| CVE-2024-21626 | runc | Container escape |
| CVE-2023-50244 | containerd | Privilege escalation |
| CVE-2023-38646 | Metabase | Pre-auth RCE (often cloud-hosted) |
| CVE-2023-22515 | Confluence | Broken AC (cloud/on-prem) |
| CVE-2024-21410 | Exchange | NTLM relay → Domain Admin |

---

### L1: Physical & Hardware → **TARGET: Firmware, Boot, Side-Channel**

| Attack Vector | MITRE Technique | Tool/CVE | Feasibility |
|---------------|-----------------|----------|-------------|
| **BIOS/UEFI Implant** | T1542.001 | UEFI rootkit, LoJax | High skill, physical/remote flash |
| **Bootkit (MBR/VBR)** | T1542.002 | Mebromi, custom | Pre-OS, persistent |
| **DMA Attack (PCIe/Thunderbolt)** | T1542.003 | PCILeech, Inception | Physical access, <5 min |
| **TPM Key Extraction** | T1552.001 | TPM2.0 TPM_FAILOVER, voltage glitch | Lab conditions |
| **Intel ME / AMD PSP Exploit** | T1542.001 | INTEL-SA-00086, CVE-2017-5705 | Ring -3, persistent |
| **Rowhammer / RAMBleed** | T1542.004 | Blacksmith, Half-Double | Bit flip, ECC bypass |
| **Spectre/Meltdown (Transient Execution)** | T1542.005 | Spectre v1-v4, Meltdown | Speculative execution |
| **USB Firmware Implant** | T1542.001 | BadUSB, Rubber Ducky | HID emulation |
| **Network Card Firmware** | T1542.001 | SeaSpy, custom | Persistent network tap |

---

### L0: Threat Intelligence & Governance → **TARGET: Intel Gaps, Blind Spots**

| Attack Vector | Technique | Description |
|---------------|-----------|-------------|
| **Intel Feed Poisoning** | T1585.002 | Inject false IoCs to waste blue team cycles |
| **Threat Actor Attribution Misdirection** | T1036.005 | False flags: reuse known APT tools/TTPs |
| **Governance Blind Spot Exploit** | N/A | Target orgs w/o threat intel program |
| **Supply Chain Intel Compromise** | T1195 | Compromise intel vendor → downstream consumers |

---

## 3. Attack Path Chaining (Kill Chain Integration)

```
INITIAL ACCESS (L6/L7)
    │
    ├── Phishing + Credential Phishing (T1566) → Valid Accounts (T1078)
    ├── Exploit Public App (CVE-2024-3400, CVE-2023-38646) → Webshell
    └── Supply Chain (T1195) → Compromised Dependency
    │
    ▼
EXECUTION & PERSISTENCE (L5/L7)
    │
    ├── LOLBin Execution (T1218) → AMSI/ETW Bypass
    ├── Direct Syscalls → Shellcode Injection (T1055)
    ├── DLL Sideloading / COM Hijack → Persistence (T1546)
    └── Scheduled Task / Service → Persistence (T1053/T1543)
    │
    ▼
PRIVILEGE ESCALATION (L5/L7)
    │
    ├── Local: Token Manipulation (T1134), Kernel Exploit (CVE-2023-4911)
    ├── Domain: Kerberoasting → DCSync → DA (T1558/T1003.006)
    └── Cloud: IMDS → IAM Escalation (T1590.005 → T1078.004)
    │
    ▼
DEFENSE EVASION (L4/L5)
    │
    ├── Indirect Syscalls + Module Stomping
    ├── EDR Sensor Unload (BYOVD)
    ├── Timestamp Manipulation (Timestomp)
    └── Log Tampering (Event Log, CloudTrail)
    │
    ▼
CREDENTIAL ACCESS (L7/L3)
    │
    ├── LSASS Dump → DPAPI → Browser Creds
    ├── AD CS Abuse (Certifried, PetitPotam, ESC1-14)
    ├── Cloud Credential Harvest (Metadata, CI/CD, Configs)
    └── Keylogger / Clipboard Monitor
    │
    ▼
DISCOVERY & LATERAL MOVEMENT (L4/L2/L6)
    │
    ├── BloodHound / SharpHound (AD)
    ├── Cloud Enum (Pacu, CloudSploit)
    ├── Network Scan (Masscan, Nmap, Ldapdomaindump)
    ├── SMB/WMI/WinRM/SSH/DCOM/RDP Lateral
    └── Kerberos Delegation / NTLM Relay
    │
    ▼
COLLECTION & EXFILTRATION (L3/L4)
    │
    ├── File/DB/Email Collection
    ├── Staging (Encrypted, Compressed)
    ├── Exfil over C2 (HTTPS/DNS/Cloud API)
    └── Exfil over Physical (if air-gap)
    │
    ▼
IMPACT (L9/L8/L1)
    │
    ├── Ransomware (T1486)
    ├── Data Destruction (T1485)
    ├── Firmware Implant (T1542)
    └── Extortion via L9 (Brand/Reputation)
```

---

## 4. MITRE ATT&CK Coverage Map (Red Team Focus)

| Tactic | Techniques Prioritized | Detection Gap |
|--------|------------------------|---------------|
| **Reconnaissance** | T1590.005, T1590.001, T1598.002 | Passive DNS, cert transparency — low detection |
| **Resource Development** | T1585.002, T1587.001, T1588.002 | Infrastructure setup — pre-engagement |
| **Initial Access** | T1190, T1566.002, T1078.001 | Phishing click → hard to detect pre-exploit |
| **Execution** | T1059.001, T1059.003, T1204.002 | LOLBins, script block logging gaps |
| **Persistence** | T1546.015, T1546.003, T1053.005 | Registry/COM/WMI — noisy but often unmonitored |
| **Privilege Escalation** | T1558.003, T1558.004, T1003.006 | Kerberos/AD CS — high value, variable detection |
| **Defense Evasion** | T1562.001, T1055.012, T1027.009 | AMSI/ETW bypass, direct syscalls — signature gap |
| **Credential Access** | T1003.001, T1555.003, T1552.001 | LSASS, DPAPI, browser — high impact |
| **Discovery** | T1018, T1082, T1083, T1069.002 | AD/Cloud enum — blend with admin activity |
| **Lateral Movement** | T1021.002, T1021.004, T1550.002 | SMB/SSH/PtH — NTLM relay hard to detect |
| **Collection** | T1005, T1039, T1114.001 | File/DB/Email — staged locally first |
| **Command & Control** | T1071.001, T1071.004, T1102 | HTTPS/DNS/Cloud — encrypted, legit-looking |
| **Exfiltration** | T1041, T1048.003, T1537 | C2/DNS/Cloud — chunked, timed |
| **Impact** | T1486, T1485, T1529 | Ransomware, wipe, shutdown — final phase |

---

## 5. CVE Intelligence for Red Team (2024-2026 Active)

| CVE | CVSS | Component | Exploit Maturity | Red Team Value |
|-----|------|-----------|------------------|----------------|
| CVE-2024-3400 | 10.0 | PAN-OS GlobalProtect | Public PoC | RCE, pre-auth, wide deploy |
| CVE-2024-21410 | 9.8 | Exchange | Public PoC | NTLM relay → DA |
| CVE-2024-27198 | 9.8 | JetBrains TeamCity | Public PoC | RCE, CI/CD access |
| CVE-2024-21626 | 8.6 | runc | Public PoC | Container escape |
| CVE-2023-4911 | 7.8 | glibc (Looney Tunables) | Public PoC | Local root, most Linux |
| CVE-2023-38646 | 9.8 | Metabase | Public PoC | Pre-auth RCE, data access |
| CVE-2023-22515 | 10.0 | Confluence | Public PoC | Broken AC → admin |
| CVE-2023-20273 | 10.0 | Cisco IOS XE | Public PoC | Web UI RCE, implant |
| CVE-2022-26923 | 8.1 | AD CS (Certifried) | Public PoC | Domain Admin via cert |
| CVE-2021-36942 | 7.8 | MS-EFSRPC (PetitPotam) | Public PoC | NTLM relay to AD CS |
| CVE-2021-42287/42278 | 7.5 | noPac (SAM spoof) | Public PoC | DA via Kerberos |

**Weaponization Checklist per CVE:**
- [ ] Reliable PoC (not DoS)
- [ ] Pre-auth or low-priv
- [ ] Stable across versions
- [ ] EDR bypass compatible
- [ ] C2 integration ready
- [ ] OpSec safe (no crash, no loud logs)

---

## 6. Tooling Stack (Red Team Operator Level 3-5)

| Category | Tools | Notes |
|----------|-------|-------|
| **C2 Framework** | Havoc, Sliver, Mythic, Cobalt Strike (licensed) | Malleable profiles, BOF support |
| **Post-Exploitation** | Rubeus, Certipy, PetitPotam, noPac, KrbRelayUp | AD-focused |
| **Lateral Movement** | CrackMapExec, evil-winrm, Impacket, SharpDCOM | SMB/WMI/DCOM/WinRM |
| **Credential Access** | Mimikatz (custom build), SharpDPAPI, SharpChromium | LSASS, DPAPI, browser |
| **Defense Evasion** | SysWhispers3, HellsGate, FreshyCalls, Donut, sRDI | Direct syscalls, shellcode |
| **Enumeration** | BloodHound/SharpHound, Pacu, CloudSploit, ldapdomaindump | AD/Cloud/Network |
| **Persistence** | SharpStay, Registry/COM/WMI/ScheduledTask modules | Multiple vectors |
| **Exfiltration** | rclone, dnscat2, custom HTTPS/DNS exfil | Chunked, encrypted |
| **Infrastructure** | Terraform, Ansible, Docker, Redirectors (nginx/Caddy) | OpSec: dedicated, ephemeral |

---

## 7. Operational Security (OpSec) Rules

1. **No tool drops to disk** — in-memory only (BOF, DONUT, sRDI, direct syscalls)
2. **No default profiles** — custom Malleable C2, custom JA3, custom User-Agent
3. **Infrastructure separation** — redirectors per campaign, burner domains, cloud VPS
4. **Traffic shaping** — jitter (30-300s), business hours, bandwidth caps
5. **Credential hygiene** — per-target creds, rotate daily, no reuse
6. **Logging discipline** — no stdout/stderr to disk, structured JSON to C2 only
7. **Attribution misdirection** — false flags, reuse known APT artifacts selectively
8. **Cleanup automation** — scheduled task to remove artifacts on exit/crash
9. **Comms encryption** — AES-256-GCM + custom framing, key rotation
10. **No interactive shells on target** — scripted, asynchronous, event-driven

---

## 8. Blue Team Detection Recommendations (Purple Team Output)

| Layer | Detection Priority | Sigma/Query |
|-------|-------------------|-------------|
| L7 | Kerberoasting (4769 RC4 + high entropy) | `EventID=4769 AND TicketEncryptionType=0x17` |
| L7 | DCSync (4662 + DS-Replication-Get-Changes-All) | `EventID=4662 AND ObjectGUID={1131f6aa-9c07-454f-abbc-03773c9628b7}` |
| L7 | AD CS Abuse (Certifried/PetitPotam) | `EventID=4769 AND ServiceName="krbtgt" AND TargetUserName="$*"` |
| L5 | AMSI Bypass (AmsiScanBuffer patch) | ETW `Microsoft-Antimalware-Scan-Interface/Operational` |
| L5 | ETW Bypass (EtwEventWrite patch) | ETW `Microsoft-Windows-DotNETRuntime/Operational` |
| L5 | Direct Syscalls (unusual syscall pattern) | Sysmon 255 (Driver Load) + syscall monitoring |
| L5 | Module Stomping (PE header mismatch) | Memory scan: `GetModuleHandle` vs actual PE |
| L4 | NTLM Relay (4624 Type 3 + 4624 Type 3 from diff IP) | Correlation: Source IP ≠ Target IP for NTLM |
| L4 | C2 Beacon (periodic, same size, high entropy) | Zeek/Suricata: `ssl.ja3` mismatch, beaconing detection |
| L2 | IMDS Access (non-AWS IP → 169.254.169.254) | VPC Flow Logs + CloudTrail |
| L2 | Container Escape (runc CVE-2024-21626) | Falco/Tetragon: `open_by_handle_at` + `setns` |
| L3 | LSASS Access (OpenProcess + PROCESS_VM_READ) | Sysmon 10 (Process Access) + TargetImage=lsass.exe |

---

## 9. References

- MITRE ATT&CK Enterprise Matrix v15+
- CVE Details (NVD, MITRE, vendor advisories)
- The DFIR Report (thedfirreport.com)
- Red Canary Atomic Red Team
- Cobalt Strike Malleable C2 Profiles (public)
- Havoc / Sliver / Mythic documentation
- SpecterOps blog (AD security)
- Black Hat / DEF CON proceedings (2020-2026)
- Project Zero blog (Google)
- Microsoft Security Blog (AD CS, Exchange, Kerberos)

---

*Generated: 2026-08-14 | Source: hierarchy-cybersecurity-defense-architecture.md | For authorized red team operations only*