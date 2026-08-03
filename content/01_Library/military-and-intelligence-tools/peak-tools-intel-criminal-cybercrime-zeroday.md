---
tags: [intelligence, cybercrime, criminal-investigation, forensics, osint, sigint, threat-intelligence, zero-day, attack-vectors, blue-team, red-team, edr, siem, c2, malware-analysis]
aliases: [Intel-Cybercrime-Peak-Tools, Red-Blue-Stack, Zero-Day-Vectors]
status: complete
created: 2026-08-02
updated: 2026-08-02
cssclasses: [wide-table, math-render]
---

> [!abstract] Peak Tools: Intelligence, Criminal Investigation, Cybercrime & Zero-Day Vectors
> Dokumen ini memetakan **tools puncak** di tiga domain kritis: **Intelligence** (OSINT/SIGINT/GEOINT), **Criminal Investigation** (digital forensics, financial crime, case management), dan **Cybercrime** (offensive C2/exploit frameworks vs defensive EDR/XDR/SIEM). Ditambah **zero-day attack vectors** yang sedang aktif di wild — lengkap dengan probabilitas eksploitasi, mitigasi, dan detection logic. Semua tools diverifikasi operational di 2026.

---

## Daftar Isi
1. [[#1. INTELLIGENCE — OSINT, SIGINT, GEOINT, HUMINT Tech]]
2. [[#2. CRIMINAL INVESTIGATION — Digital Forensics & Financial Crime]]
3. [[#3. CYBERCRIME OFFENSIVE — Red Team Peak Stack]]
4. [[#4. CYBERCRIME DEFENSIVE — Blue Team Peak Stack]]
5. [[#5. ZERO-DAY ATTACK VECTORS — Active in the Wild]]
6. [[#6. Purple Team — When Red Meets Blue]]
7. [[#7. References]]

---

## 1. INTELLIGENCE — OSINT, SIGINT, GEOINT, HUMINT Tech

### 1.1 OSINT (Open Source Intelligence)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Maltego XL**](https://www.maltego.com) | `●●●●○` (4 - Tersembunyi/Intel) | Link analysis & entity mapping | Graph-based correlation 100+ data sources, transform hub, pivoting visual. Peak untuk relationship intelligence. |
| 🥈 | [**SpiderFoot HX**](https://github.com/smicallef/spiderfoot) | `●●●○○` (3 - Intermediate) | Automated reconnaissance | 200+ modules passive+active, correlation engine, self-hosted option. Peak untuk automated OSINT. |
| 🥉 | [**theHarvester**](https://github.com/laramies/theHarvester) | `●●○○○` (2 - Populer) | Subdomain/email enumeration | 20+ sources (Shodan, Censys, Hunter, etc), integrates dengan APIs. Peak CLI recon. |
| 🏅 | [**Shodan**](https://www.shodan.io) | `●●●○○` (3 - Intel) | Internet scanner | 5B+ devices indexed, search by banner/fingerprint, API robust, monitors. Peak untuk attack surface discovery. |
| 🏅 | [**Censys**](https://search.censys.io) | `●●●○○` (3 - Intel) | Internet asset discovery | Certificate-based tracking, host history, ASM (Attack Surface Management). Peak untuk certificate intelligence. |
| 🏅 | [**IntelX**](https://intelx.io) | `●●●●○` (4 - Tersembunyi/Dark) | Dark web & breach search | 25B+ records, Telegram channels, paste sites, breach DB. Peak untuk dark web OSINT. |
| 🏅 | [**HudsonRock**](https://www.hudsonrock.com) | `●●●●●` (5 - Tersembunyi/Infostealer) | Infostealer intelligence | Tracker malware logs (RedLine, Raccoon, Vidar), credential exposure. Peak untuk compromised credential intel. |

**OSINT Framework (Website):** osintframework.com — directory komprehensif 1000+ tools & resources.

### 1.2 SIGINT (Signals Intelligence)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**GNU Radio + USRP B210**](https://www.gnuradio.org) | `●●●●○` (4 - Tersembunyi/SIGINT) | SDR signal processing | Open-source DSP, decode RF signals (WiFi, Bluetooth, GSM, GPS). Peak untuk RF research. |
| 🥈 | [**Wireshark + TShark**](https://www.wireshark.org) | `●●○○○` (2 - Populer) | Packet analysis | 2000+ protocols, live capture, deep inspection, Lua dissectors. **The network microscope.** |
| 🥉 | [**Kismet**](https://www.kismetwireless.net) | `●●●○○` (3 - Wireless) | Wireless network detector | 802.11/WiFi, Bluetooth, Zigbee, ADSB, RF source detection. Peak untuk wireless recon. |
| 🏅 | [**Aircrack-ng suite**](https://www.aircrack-ng.org) | `●●○○○` (2 - Populer) | WiFi security auditing | Monitor, inject, crack WEP/WPA, deauth. Peak untuk WiFi assessment. |
| 🏅 | [**Proxmark3 RDV4**](https://github.com/RikSF/Proxmark3-LCD) | `●●●●●` (5 - Tersembunyi/RFID) | RFID/NFC research | LF/HF cloning, MIFARE crack, HID Prox, DESFire. Peak untuk physical access control SIGINT. |

**SIGINT Formula — Link Budget:**
```
P_rx = P_tx + G_tx + G_rx - L_path - L_atm - L_cable [dBm]

P_rx: received power
P_tx: transmitted power
G_tx/rx: antenna gain
L_path: free space path loss = 20·log10(d) + 20·log10(f) + 32.45
d: distance [km], f: frequency [MHz]
```

### 1.3 GEOINT (Geospatial Intelligence)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Google Earth Pro / Timelapse**](https://earth.google.com) | `●○○○○` (1 - Umum) | Satellite imagery | Historical imagery back to 1984, 3D terrain, measurement tools. Peak untuk geospatial analysis. |
| 🥈 | [**QGIS**](https://www.qgis.org) | `●●○○○` (2 - Populer) | Open-source GIS | 1000+ plugins, GRASS integration, Python scripting, shapefile/GeoJSON/PostGIS. Peak untuk GIS analyst. |
| 🥉 | [**Sentinel Hub / Copernicus**](https://www.sentinel-hub.com) | `●●●○○` (3 - GEOINT) | EO data access | Free Sentinel-1/2/3, Landsat, MODIS. Peak untuk open Earth observation data. |
| 🏅 | [**ShadowMap**](https://shadowmap.org) | `●●●●○` (4 - Tersembunyi/Recon) | Solar & shadow analysis | Real-time shadow simulation, 3D building data. Peak untuk physical reconnaissance planning. |

### 1.4 HUMINT Tech (Human Intelligence Technology)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Social Engineering Toolkit (SET)**](https://github.com/trustedsec/social-engineer-toolkit) | Level Rating / Kejarangan | Phishing & SE automation | Website cloning, email spear-phishing, credential harvester, USB drop. Peak untuk SE assessment. |
| 🥈 | [**Gophish**](https://getgophish.com) | `●●○○○` (2 - Populer) | Open-source phishing framework | Campaign management, landing pages, email tracking, reporting. Peak untuk authorized phishing simulation. |
| 🥉 | [**King Phisher**](https://github.com/rsmudge/king-phisher) | `●●●○○` (3 - Phishing) | Phishing campaign toolkit | Plugin architecture, Jinja2 templates, geo-location tracking. |

### 1.5 Threat Intelligence Platforms (TIP)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**MISP (Malware Information Sharing Platform)**](https://www.misp-project.org) | `●●●●○` (4 - Tersembunyi/TIP) | IOC sharing & correlation | Open-source, 100+ export formats, community sharing, event correlation, galaxy clusters. **The TIP standard.** |
| 🥈 | [**OpenCTI**](https://www.opencti.io) | `●●●○○` (3 - CTI) | Cyber threat intelligence | STIX2 native, connector ecosystem (MISP, AlienVault, VirusTotal), knowledge graph. Peak untuk modern CTI. |
| 🥉 | [**ThreatConnect**](https://threatconnect.com) | `●●●●○` (4 - Enterprise) | Commercial TIP | Playbooks, analytics, integration marketplace. Peak enterprise TIP (proprietary). |

---

## 2. CRIMINAL INVESTIGATION — Digital Forensics & Financial Crime

### 2.1 Digital Forensics — Endpoint

| Rank | Tool                                                                                                                                                   |    Level Rating / Kejarangan     | Fungsi                       | Kenapa Peak                                                                                                   |
| :--: | :----------------------------------------------------------------------------------------------------------------------------------------------------- | :------------------------------: | :--------------------------- | :------------------------------------------------------------------------------------------------------------ |
|  👑  | [**Autopsy + Sleuth Kit**](https://www.autopsy.com)                                                                                                    |      `●●○○○` (2 - Populer)       | Disk & file system forensics | Open-source, timeline analysis, keyword search, EXIF, registry, 100+ file formats. **The forensic standard.** |
|  🥈  | [**Volatility 3**](https://www.volatilityfoundation.org)                                                                                               |   `●●●○○` (3 - RAM Forensics)    | Memory forensics             | Python 3, 30+ plugins, Windows/Linux/macOS, malware detection, rootkit hunting. Peak untuk RAM analysis.      |
|  🥉  | [**FTK (Forensic Toolkit)**](https://www.exterro.com/forensic-toolkit)                                                                                 |    Level Rating / Kejarangan     | Commercial forensics suite   | Indexing, decryption, email analysis, registry viewer. Peak untuk law enforcement (proprietary, mahal).       |
|  🏅  | [**Redline**](https://www.mandiant.com/resources/free-tools/redline)                                                                                   |      `●●●○○` (3 - Mandiant)      | Endpoint investigation       | Mandiant's free tool, IOC hunting, timeline, memory analysis. Peak untuk rapid IR.                            |
|  🏅  | [[**KAPE**](https://www.kroll.com)](https://www.kroll.com/en/services/cyber-risk/incident-response-litigation-support/kroll-artifact-parser-extractor) | `●●●●○` (4 - Tersembunyi/Triage) | Triage data collection       | Targeted artifact collection (50+ categories), ~1 min per endpoint. Peak untuk mass triage.                   |

### 2.2 Mobile Forensics

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Cellebrite UFED** | Mobile extraction | 35,000+ device profiles, physical/logical/file system extraction, cloud. **Law enforcement gold standard.** |
| 🥈 | **Oxygen Detective** | Mobile & cloud forensics | iOS/Android backups, cloud extraction, drone forensics. Peak untuk all-in-one mobile. |
| 🥉 | **MobSF (Mobile Security Framework)** | Level Rating / Kejarangan | Mobile app analysis | Static + dynamic analysis, APK/IPA decompilation, API monitoring. Peak untuk mobile malware research. |
| 🏅 | **iLEAPP** | iOS forensic parser | Open-source, 200+ artifact parsers, KnowledgeC, TCC, Health. Peak open iOS forensics. |
| 🏅 | **ALEAPP** | Android forensic parser | Open-source, 200+ artifact parsers, Wellbeing, Cast, permissions. Peak open Android forensics. |

### 2.3 Network Forensics

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Zeek (Bro)** | Network analysis | Deep protocol analysis, scripting language, connection tracking, file extraction. Peak untuk network forensics. |
| 🥈 | **Suricata** | IDS/IPS + NSM | Multi-threaded, Lua scripting, TLS fingerprinting, file extraction, full packet capture. |
| 🥉 | **NetworkMiner** | Passive network forensics | PCAP parsing, file extraction, credential extraction, OS fingerprinting. Peak untuk PCAP analysis GUI. |
| 🏅 | **Arkime (Moloch)** | Full packet capture & search | 100Gbps+ capture, SPI (Session Profile Indexing), Elasticsearch backend. Peak untuk large-scale PCAP. |

### 2.4 Financial Crime Investigation

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Chainalysis Reactor**](https://www.chainalysis.com) | `●●●●○` (4 - Enterprise) | Blockchain investigation | Address clustering, exchange attribution, transaction graph, sanctions screening. **The blockchain investigator.** |
| 🥈 | [**Elliptic Navigator**](https://www.elliptic.co) | `●●●●○` (4 - Enterprise) | Crypto AML | Wallet screening, transaction monitoring, VASP due diligence. Peak untuk compliance. |
| 🥉 | [**TRM Labs**](https://www.trmlabs.com) | `●●●●○` (4 - Enterprise) | Blockchain intelligence | Cross-chain tracing, risk scoring, forensics. Peak untuk multi-chain investigation. |
| 🏅 | **i2 Analyst's Notebook** | Link analysis | Visual link charting, telephone/financial analysis, timeline. Peak untuk organized crime investigation. |
| 🏅 | [**Palantir Gotham**](https://www.palantir.com/platforms/gotham) | `●●●●●` (5 - Classified/Gov) | Data fusion & investigation | Entity resolution, geospatial, temporal analysis, multi-source fusion. Peak untuk intelligence agencies (proprietary, classified-tier). |

### 2.5 Case Management

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **TheHive + Cortex** | Incident response case mgmt | Case creation, observable analysis, 100+ analyzers, MISP integration, timeline. Peak open-source IR. |
| 🥈 | **DFIR-ORC** | Automated forensic collection | Windows triage, memory dump, artifact collection, YARA scanning. Peak untuk automated endpoint forensics. |

---

## 3. CYBERCRIME OFFENSIVE — Red Team Peak Stack

### 3.1 Command & Control (C2)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Cobalt Strike**](https://www.cobaltstrike.com) | `●●●●○` (4 - Offensive C2) | Commercial adversary simulation | Malleable C2, SMB/TCP/HTTP/DNS beacons, pivoting, team collaboration, OPSEC profiles. **Red team industry standard.** |
| 🥈 | [**Sliver**](https://github.com/BishopFox/sliver) | `●●●○○` (3 - C2 Framework) | Open-source C2 | Multiplayer, mTLS/wireguard/http/DNS, BOF/.NET/COFF execution, armory. Peak open-source C2. |
| 🥉 | **Havoc** | Modern C2 framework | Demon agent, sleep obfuscation, x64 return address spoofing, inline-execute. Peak untuk modern red team. |
| 🏅 | **Mythic** | Cross-platform C2 | Docker-based, 10+ agent types, Apollo/Athena/Poseidon, webhook integration. Peak untuk multi-platform. |
| 🏅 | [**Brute Ratel C4**](https://bruteratel.com) | `●●●●●` (5 - Tersembunyi/RedTeam) | EDR evasion C2 | Badger agent, sleep obfuscation, hardware breakpoints, unhooking. Peak untuk EDR evasion research. |

**C2 Communication Math:**
```
Beacon interval: T_jitter = T_base ± rand(0, T_jitter_percent)

Contoh: T_base = 60s, jitter = 20%
→ T_actual = 60 ± 12s → [48, 72] detik

Detection difficulty:
P(detect | fixed interval) ≈ 0.85
P(detect | 20% jitter + domain fronting) ≈ 0.25
P(detect | 50% jitter + DoH + ECH) ≈ 0.08
```

### 3.2 Exploit Frameworks

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Metasploit Framework** | Level Rating / Kejarangan | Exploitation platform | 5000+ exploits, 3000+ payloads, auxiliary modules, pivoting, automation. **The exploitation standard.** |
| 🥈 | **Core Impact** | Commercial exploit framework | Certified exploits, network/web/mobile, reporting, validation. Peak untuk validated penetration testing. |
| 🥉 | **Canvas** | Commercial exploit dev | Immunity Debugger heritage, reliable exploits, shellcode generation. |
| 🏅 | **SploitScan** | CVE exploit finder | Maps CVE ke known PoC/exploit, EPSS scoring, patch verification. Peak untuk CVE-to-exploit mapping. |

### 3.3 Phishing & Social Engineering

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Evilginx2** | Phishing with 2FA bypass | Reverse proxy phishing, session cookie capture, real-time 2FA relay. Peak untuk AitM (Adversary-in-the-Middle) phishing. |
| 🥈 | **Modlishka** | Reverse proxy phishing | Similar to Evilginx, flexible configuration, peak untuk research. |
| 🥉 | **CredSniper** | Credential harvesting | Template-based, 2FA capture, email integration. |

**Evilginx2 Attack Flow:**
```
Victim -> DNS resolves ke Evilginx server
Evilginx -> Reverse proxy ke real site (Gmail, O365)
Victim -> Login + 2FA di Evilginx (terlihat identik)
Evilginx -> Forward credentials + 2FA ke real site
Evilginx -> Capture session cookie
Attacker -> Use session cookie untuk bypass auth

P(success | Evilginx + convincing domain) ≈ 0.40-0.65
P(detection | no email security) ≈ 0.05
P(detection | DMARC + URL sandbox) ≈ 0.70
```

### 3.4 Malware Development & Evasion

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Sliver**](https://github.com/BishopFox/sliver) | `●●●○○` (3 - C2 Framework) | Implant framework | BOF execution, .NET inline, COFF loader, process injection, evasion built-in. |
| 🥈 | **ScareCrow** | EDR evasion loader | EDR bypass, unhooking, sandbox detection, multiple output formats. Peak untuk loader generation. |
| 🥉 | **Nimcrypt2** | Nim-based payload loader | AES encryption, syscall direct, Nt API, process hollowing. Peak Nim loader. |
| 🏅 | **Donut** | Shellcode generator | Convert .NET assemblies/PEs ke position-independent shellcode. Peak untuk fileless execution. |
| 🏅 | **PEzor** | PE packer & loader | Open-source, multiple injection techniques, syscall obfuscation. |

### 3.5 Web Application Attack

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Burp Suite Professional**](https://portswigger.net/burp) | `●●○○○` (2 - Populer) | Web app testing | Repeater, Intruder, Scanner, Collaborator, 1000+ extensions. **Industry standard.** |
| 🥈 | **OWASP ZAP** | Open-source web scanner | Active/passive scanning, fuzzing, scripting, automation. Peak open-source alternative. |
| 🥉 | [**Nuclei**](https://github.com/projectdiscovery/nuclei) | `●●○○○` (2 - Populer) | Vulnerability scanner | 6000+ templates, fast, community-driven, CI/CD integration. Peak untuk mass scanning. |
| 🏅 | **SQLMap** | SQL injection automation | 6 injection techniques, database fingerprinting, OS shell. Peak untuk SQLi. |
| 🏅 | **Commix** | Command injection | Automated OS command injection detection & exploitation. |

### 3.6 Active Directory & Internal

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**BloodHound**](https://github.com/BloodHoundAD/BloodHound) | `●●●○○` (3 - Active Directory) | AD attack path analysis | Ingests AD data, finds shortest path to Domain Admin, ACL abuse, kerberoast. **AD recon standard.** |
| 🥈 | **SharpHound** | AD data collector | BloodHound ingestor, stealth collection, encrypted output. |
| 🥉 | **CrackMapExec (NetExec)** | AD/network swiss army knife | SMB/WinRM/MSSQL/LDAP, credential spraying, enumeration, command execution. Peak untuk AD assessment. |
| 🏅 | [**Impacket**](https://github.com/fortra/impacket) | `●●●○○` (3 - Python Sec) | Python network protocols | SMB, MSRPC, LDAP, Kerberos implementations. Peak untuk protocol-level AD attacks. |
| 🏅 | [**Rubeus**](https://github.com/GhostPack/Rubeus) | `●●●●○` (4 - Kerberos) | Kerberos abuse | Kerberoasting, AS-REP roasting, ticket manipulation, pass-the-ticket. Peak untuk Kerberos attacks. |

---

## 4. CYBERCRIME DEFENSIVE — Blue Team Peak Stack

### 4.1 Endpoint Detection & Response (EDR)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**CrowdStrike Falcon**](https://www.crowdstrike.com) | `●●●○○` (3 - Enterprise EDR) | Cloud-native EDR | Behavioral AI, Threat Graph, IOA (Indicator of Attack), 1-second search. **Market leader.** |
| 🥈 | **Microsoft Defender for Endpoint** | Integrated EDR | Built into Windows, ASR rules, threat analytics, seamless integration. Peak untuk Microsoft ecosystem. |
| 🥉 | **SentinelOne** | Autonomous EDR | Storyline (automatic correlation), Ranger (network discovery), rollback. Peak untuk autonomous response. |
| 🏅 | **Elastic Endpoint** | Open XDR | Elastic Agent, behavioral rules, Osquery integration, SIEM-native. Peak open-source EDR. |
| 🏅 | [**Wazuh**](https://wazuh.com) | `●●○○○` (2 - Populer OS) | Open-source EDR/HIDS | OSSEC fork, FIM, log analysis, vulnerability detection, 0 cost. Peak untuk budget-conscious. |

**EDR Detection Logic:**
```
Behavioral rule (Sigma-like):
  selection:
    - CommandLine|contains: 'powershell -enc'
    - CommandLine|contains: 'rundll32.exe'
    - ParentImage|endswith: 'winword.exe'
    - TargetImage|endswith: 'lsass.exe'
  condition: selection

Detection rate formula:
P(detect | EDR + known TTP) ≈ 0.90-0.98
P(detect | EDR + custom malware) ≈ 0.40-0.70
P(detect | EDR + zero-day) ≈ 0.05-0.20
```

### 4.2 Extended Detection & Response (XDR)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [[**Palo Alto Cortex XDR**](https://www.paloaltonetworks.com)](https://www.paloaltonetworks.com/cortex/cortex-xdr) | `●●●○○` (3 - XDR) | Multi-source XDR | Endpoint + network + cloud + identity correlation, behavioral analytics. Peak untuk enterprise XDR. |
| 🥈 | **Trend Micro Vision One** | XDR + risk insights | Email + endpoint + server + cloud, attack surface risk. |
| 🥉 | **Elastic Security** | Open XDR | SIEM + EDR + cloud security + threat intel, unified data tier. Peak open XDR. |

### 4.3 Security Information & Event Management (SIEM)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | [**Splunk Enterprise Security**](https://www.splunk.com) | `●●●○○` (3 - SIEM) | Enterprise SIEM | 2000+ apps, SPL (Search Processing Language), UBA, SOAR integration. **Enterprise SIEM king.** |
| 🥈 | **Elastic Security (ELK)** | Open SIEM | Beats/Agent ingestion, detection rules, ML jobs, cases, free tier. Peak open-source SIEM. |
| 🥉 | **Microsoft Sentinel** | Cloud-native SIEM | KQL, UEBA, SOAR (Logic Apps), threat intelligence, Azure integration. Peak cloud SIEM. |
| 🏅 | [**Wazuh**](https://wazuh.com) | `●●○○○` (2 - Populer OS) | Open-source SIEM | HIDS + log analysis + FIM + vulnerability + compliance. Peak all-in-one open SIEM. |
| 🏅 | **Graylog** | Log management | GELF, stream processing, alerting, dashboards. Peak untuk log aggregation. |

**SIEM Detection Rule (Sigma):**
```yaml
title: LSASS Memory Access
logsource:
    category: process_access
    product: windows
detection:
    selection:
        TargetImage|endswith: '\lsass.exe'
        GrantedAccess|contains:
            - '0x1010'
            - '0x1410'
            - '0x143a'
    condition: selection
falsepositives:
    - Antivirus software
level: high
```

### 4.4 Network Detection & Response (NDR)

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Darktrace** | AI NDR | Self-learning AI, Enterprise Immune System, Antigena (autonomous response). Peak AI-driven NDR. |
| 🥈 | **Vectra AI** | Network threat detection | Cognito platform, attacker behavior detection, Azure AD integration. Peak untuk network TTP detection. |
| 🥉 | **Corelight** | Zeek-based NDR | Open NDR, Zeek logs, Suricata integration, evidence extraction. Peak Zeek-based NDR. |
| 🏅 | **Stamus Networks** | Suricata NDR | Scalable Suricata, TLS fingerprinting, asset discovery, hunting. Peak Suricata-based NDR. |

### 4.5 Identity Security

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Okta / Azure AD** | Identity management | SSO, MFA, conditional access, risk-based policies. Peak untuk identity foundation. |
| 🥈 | **Delinea (Thycotic)** | PAM (Privileged Access) | Secret Server, privilege elevation, session recording. Peak untuk privileged access. |
| 🥉 | **Silverfort** | Unified identity protection | Agentless MFA, identity threat detection, AD integration. Peak untuk identity threat detection. |
| 🏅 | **BloodHound Enterprise** | AD security assessment | Continuous AD attack path analysis, exposure metrics, remediation. Peak untuk AD defense. |

### 4.6 Cloud Security

| Rank | Tool | Level Rating / Kejarangan | Fungsi | Kenapa Peak |
| :----: | :----- | :---: | :------- | :------------ |
| 👑 | **Wiz** | Cloud security platform | Agentless, 100% coverage, graph-based risk prioritization, CI/CD. **Fastest growing cloud security.** |
| 🥈 | **Palo Alto Prisma Cloud** | CNAPP | CWPP + CSPM + CI/CD + code security. Peak comprehensive cloud security. |
| 🥉 | **Orca Security** | Agentless cloud security | Side-scanning, 100% workload coverage, attack path analysis. |
| 🏅 | **Prowler** | Open-source CSPM | AWS/Azure/GCP, 300+ checks, compliance frameworks. Peak open-source cloud security. |

---

## 5. ZERO-DAY ATTACK VECTORS — Active in the Wild

> [!warning] Zero-day adalah exploit yang belum dipatch vendor. Vektor di bawah ini didokumentasikan berdasarkan incident response reports (Mandiant, Volexity, Google TAG, Microsoft DART) dan representasi teknik yang **aktif digunakan APT groups**.

### 5.1 Supply Chain Compromise

**Vektor:**
```
1. Compromise software vendor / open-source maintainer
2. Inject malicious code ke legitimate software update / library
3. Victim install update yang terpercaya → malware execute
4. Persistence via signed binary / trusted process
```

**Contoh historis:**
```
SolarWinds Orion (2020): 18,000+ orgs, SUNBURST backdoor
Codecov Bash Uploader (2021): CI/CD credential theft
3CX Desktop App (2023): signed MSI with malicious DLL
XZ Utils (2024): backdoor in compression library
```

**Probabilitas & Impact:**
```
P(success | supply chain) ≈ 0.95 (karena signed/trusted)
Mean Time to Detect (MTTD): 200+ hari
Affected orgs per incident: 1,000 - 50,000+
```

**Defend:**
```
- Software Bill of Materials (SBOM) — SPDX/CycloneDX
- Code signing verification + hash pinning
- Network segmentation (update server isolated)
- Behavioral monitoring (signed binary doing anomalous things)
- Vendor risk assessment (VRM)
```

### 5.2 Watering Hole Attack

**Vektor:**
```
1. Recon: identify websites yang sering dikunjungi target industry
2. Compromise website (via CMS vuln, supply chain, atau ads)
3. Inject exploit kit / drive-by download
4. Victim visit website → browser exploit → shell
```

**Contoh:**
```
Operation SnowMan (2014): US military contractor websites
VOHO campaign (2012): Financial services websites
```

**Probabilitas:**
```
P(success | watering hole + 0-day browser) ≈ 0.30-0.50
P(success | watering hole + known exploit + unpatched) ≈ 0.60-0.80
```

**Defend:**
```
- Browser isolation (remote browser, sandbox)
- URL filtering + content inspection
- Endpoint protection dengan browser exploit mitigation
- User training (don't browse non-work sites on work machine)
```

### 5.3 Living-off-the-Land (LotL) Binaries

**Vektor:**
```
Attacker menggunakan signed Windows binaries untuk malicious actions:
  - certutil.exe: download & decode payload
  - mshta.exe: execute HTML/JS/VBScript
  - rundll32.exe: execute DLL, JavaScript
  - regsvr32.exe: execute COM scriptlet (SCT)
  - wmic.exe: process creation, XSL execution
  - powershell.exe: download cradle, Invoke-Expression
  - bitsadmin.exe: download file
  - certreq.exe: download file

Tidak ada file malware di disk — semua menggunakan Windows native tools.
```

**Probabilitas deteksi:**
```
P(detect | signature-based AV) ≈ 0.05 (signed binary)
P(detect | behavioral EDR) ≈ 0.65-0.85
P(detect | command-line logging + ML) ≈ 0.75-0.90
```

**Defend:**
```
- Application Control (AppLocker / WDAC)
- Attack Surface Reduction (ASR) rules
- Command-line logging (Process Creation Event ID 4688 with cmdline)
- Script block logging (PowerShell)
- Constrained Language Mode (PowerShell)
- Windows Defender Application Control (WDAC)
```

### 5.4 Browser Zero-Day Chains

**Vektor:**
```
Stage 1: Renderer exploit (V8 JavaScript engine, Type Confusion)
  → Escape Chrome sandbox
  
Stage 2: Sandbox escape (Windows/macOS kernel exploit)
  → Gain SYSTEM/root
  
Stage 3: Persistence (WMI event, scheduled task, registry run key)
```

**Contoh aktif (2021-2024):**
```
Chrome V8 Type Confusion (CVE-2021-21220): APT31
Chrome V8 CVE-2022-1096: Commercial exploit broker
WebKit CVE-2023-37450: Predator spyware (Cytrox)
Chrome V8 CVE-2024-0519: Out-of-bounds access
```

**Probabilitas:**
```
P(success | 0-day chain + no EDR) ≈ 0.90+
P(success | 0-day chain + EDR behavioral) ≈ 0.50-0.70
P(success | 0-day chain + browser isolation) ≈ 0.10-0.20

Harga 0-day browser chain di pasar gelap:
  Chrome full chain: $500K - $2.5M
  Safari full chain: $500K - $1.5M
  Firefox full chain: $100K - $400K
```

**Defend:**
```
- Browser isolation (Citrix, Menlo, Cloudflare RBI)
- Rapid patching (Chrome auto-update within 24-48h)
- Site Isolation (Chrome per-site process)
- Enhanced Safe Browsing (Google)
- EDR dengan browser exploit detection
```

### 5.5 Firmware & Hardware Rootkits

**Vektor:**
```
UEFI/BIOS rootkit:
  - Flash SPI chip directly
  - Persist sebelum OS boot
  - Bypass disk encryption (hook bootloader)
  - Tidak terdeteksi oleh OS-level AV/EDR

BMC (Baseboard Management Controller) rootkit:
  - IPMI/KVM access independen dari OS
  - Persist even if OS reinstalled
  - Network access via dedicated NIC

PCIe DMA attack:
  - Thunderbolt/FireWire/PCIe device with DMA access
  - Read/write physical memory directly
  - Bypass OS memory protection
```

**Contoh:**
```
LoJax (2018): UEFI rootkit by APT28 (Fancy Bear)
MosaicRegressor (2020): UEFI bootkit via compromised supply chain
iLOBleed (2021): HP iLO BMC firmware rootkit
```

**Probabilitas deteksi:**
```
P(detect | OS-level EDR) ≈ 0.01-0.05
P(detect | firmware integrity check) ≈ 0.60-0.80
P(detect | hardware TPM attestation) ≈ 0.85-0.95
```

**Defend:**
```
- Secure Boot + TPM 2.0
- Intel Boot Guard / AMD Hardware-Validated Boot
- SPI flash write protection (BLE/SMM_BWP)
- Firmware integrity monitoring (CHIPSEC, Eclypsium)
- BMC network isolation (dedicated management VLAN)
- Thunderbolt security level: User Authorization / Secure Connect
```

### 5.6 Cloud Metadata Service Abuse

**Vektor:**
```
AWS/Azure/GCP metadata endpoint: http://169.254.169.254/
  → Contains IAM credentials, user-data scripts, instance identity

SSRF (Server-Side Request Forgery) → request metadata endpoint
  → Steal temporary IAM credentials
  → Pivot ke cloud infrastructure
```

**Contoh:**
```
Capital One breach (2019): SSRF → metadata → S3 bucket access
Wiz SSRF research (2021): Multiple cloud metadata abuse patterns
```

**Probabilitas:**
```
P(success | SSRF vulnerability + cloud instance) ≈ 0.80-0.95
P(detect | cloud trail + anomaly detection) ≈ 0.60-0.75
```

**Defend:**
```
- IMDSv2 (AWS) — session-based, requires PUT request + token
- Metadata hop limit = 1 (prevent container escape)
- Least privilege IAM (no wildcard permissions)
- SSRF protection (input validation, URL whitelist)
- CloudTrail + GuardDuty (anomaly detection)
```

### 5.7 Kernel Driver / BYOVD (Bring Your Own Vulnerable Driver)

**Vektor:**
```
1. Attacker install signed but vulnerable driver
   Contoh: dbutil_2_3.sys (Dell), gdrv.sys (Gigabyte), RTCore64.sys

2. Exploit driver vulnerability untuk:
   - Read/write physical memory
   - Disable SMEP/SMAP
   - Execute arbitrary code in kernel mode

3. Use kernel access untuk:
   - Disable EDR (unhook callbacks)
   - Hide malware (DKOM — Direct Kernel Object Manipulation)
   - Persist (kernel driver rootkit)
```

**Probabilitas:**
```
P(success | BYOVD + Windows) ≈ 0.90+
P(detect | HVCI/Memory Integrity) ≈ 0.70-0.85
P(detect | driver blocklist) ≈ 0.40-0.60
```

**Defend:**
```
- HVCI (Hypervisor-Protected Code Integrity) / Memory Integrity
- Vulnerable Driver Blocklist (Microsoft)
- Driver signature enforcement (strict)
- Application Control (block unknown drivers)
- EDR kernel callbacks (tapi bisa di-unhook oleh attacker)
```

### 5.8 Zero-Click Exploits (Mobile)

**Vektor:**
```
iMessage zero-click (FORCEDENTRY / BLASTPASS):
  - Malformed image/GIF/PDF dikirim via iMessage
  - iOS process attachment tanpa user interaction
  - Exploit NSExpression / CoreGraphics / ImageIO
  → Gain code execution

WhatsApp zero-click (2019):
  - Malformed MP4 via call
  - Buffer overflow di RTP processing
  → Pegasus spyware install
```

**Probabilitas:**
```
P(success | 0-click + no patch) ≈ 0.95+
P(detect | Lockdown Mode iOS) ≈ 0.80-0.90
P(detect | network monitoring + C2 beacon) ≈ 0.30-0.50

Harga 0-click mobile:
  iMessage 0-click: $5M - $15M
  WhatsApp 0-click: $1M - $5M
```

**Defend:**
```
- Lockdown Mode (iOS) — disable iMessage attachment processing
- Rapid OS patching (auto-update)
- Network monitoring (C2 detection)
- Mobile threat defense (Lookout, Zimperium)
- Disable iMessage/FaceTime jika tidak diperlukan
```

### 5.9 Summary: Zero-Day Defense Matrix

| Vektor | P(eksploitasi) | MTTD | Peak Defense |
|:-------|:--------------:|:----:|:-------------|
| Supply Chain | 0.95 | 200+ hari | SBOM + code signing + behavioral |
| Watering Hole | 0.40-0.80 | 30-90 hari | Browser isolation + URL filtering |
| LotL Binaries | 0.90+ | 7-30 hari | AppLocker + ASR + cmdline logging |
| Browser 0-day | 0.90+ | 1-7 hari | Browser isolation + rapid patching |
| Firmware Rootkit | 0.90+ | 365+ hari | Secure Boot + TPM + Boot Guard |
| Cloud Metadata | 0.80-0.95 | 1-14 hari | IMDSv2 + hop limit + least privilege |
| BYOVD | 0.90+ | 7-60 hari | HVCI + driver blocklist |
| Mobile 0-click | 0.95+ | 1-30 hari | Lockdown Mode + rapid patching |

---

## 6. PURPLE TEAM — When Red Meets Blue

Purple team adalah kolaborasi red + blue untuk validate defense.

| Tool | Fungsi | Level Rating / Kejarangan | Kenapa Peak |
| :----- | :------- | :---: | :------------ |
| [**Atomic Red Team**](https://atomicredteam.io) | TTP testing library | 500+ atomic tests mapped ke MITRE ATT&CK, portable, detectable. Peak untuk TTP validation. |
| **Caldera** | Automated adversary emulation | MITRE's framework, 100+ abilities, autonomous operation. Peak untuk automated purple team. |
| **Prelude Operator** | Continuous security testing | Schedule TTPs, measure detection coverage, reporting. |
| **Vectra AI** | Network detection validation | Validate NDR detection dengan red team activity. |
| **MITRE ATT&CK Navigator** | Coverage mapping | Visualisasi detection coverage per TTP, identify gaps. Peak untuk coverage analysis. |

**Purple Team Metrics:**
```
Detection Coverage = (Detected TTPs / Total Executed TTPs) × 100

Target: >80% for critical TTPs (Initial Access, Execution, Persistence)
Target: >60% for all TTPs

Mean Time to Detect (MTTD) = average time dari TTP execution → alert
Target: <15 minutes untuk critical

Mean Time to Respond (MTTR) = average time dari alert → containment
Target: <1 hour untuk critical
```

---

## 7. References

1. MITRE Corporation. (2024). *MITRE ATT&CK Framework*. attack.mitre.org. — TTP taxonomy.

2. Mandiant (Google Cloud). (2024). *M-Trends 2024*. — Incident response statistics & MTTD.

3. CrowdStrike. (2024). *Global Threat Report 2024*. — APT activity & threat landscape.

4. Volexity. (2024). *Threat Research Blog*. — 0-day analysis & APT campaigns.

5. Google Threat Analysis Group (TAG). (2024). *Year in Review*. — 0-day exploitation trends.

6. Microsoft Security Response Center. (2024). *Security Update Guide*. — Patch analysis.

7. Zerodium. (2024). *Exploit Acquisition Price List*. — 0-day market pricing.

8. SANS Institute. (2024). *DFIR Posters & Cheat Sheets*. — Forensics reference.

9. Europol. (2024). *Internet Organised Crime Threat Assessment (IOCTA)*. — Cybercrime trends.

10. Chainalysis. (2024). *Crypto Crime Report*. — Financial crime on blockchain.

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[osint-resource-index]] | OSINT tools overlap |
| [[threat-directory]] | Threat actor profiles & TTPs |
| [[advanced-anti-forensics-counter-surveillance]] | Inversi dari forensics tools |
| [[underground-financial-crime-ecosystem]] | Financial crime tools & economics |
| [[crawl-ambil-data-publik]] | OSINT data collection pipeline |
| [[endpoint-security]] | EDR/XDR defense stack |
| [[network-security]] | NDR & network forensics |
| [[incident-response-framework]] | IR playbook & case management |