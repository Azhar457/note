---
title: "Research Resource Directory — Deep Technical Sources"
tags:
  - research
  - reference
  - digital-forensic
  - attack-defense
  - incident-response
  - learning-path
aliases:
  - "research-resource-directory-deep"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
---

# 📚 Research Resource Directory — Deep Technical Sources

> **Direktori sumber daya riset teknis mendalam** untuk keamanan siber — khusus Digital Forensic, Attack Defense, dan Incident Response. Bukan sekadar daftar link, tapi **peta sumber daya** dengan konteks penggunaannya. Dibuat dari riset Jina DeepResearch + kurasi manual. Untuk metodologi praktik, lihat [[ctf-competition-methodology-strategy]]. Untuk tools, lihat [[ctf-tool-arsenal-universal]].

---

## Daftar Isi

- [[#Fondasi Riset Lanskap]]
- [[#Digital Forensic — Tools & Framework]]
- [[#Digital Forensic — Metodologi & Studi Kasus]]
- [[#Attack Defense — Exploitation & Defense]]
- [[#Attack Defense — Metodologi & Latihan]]
- [[#Incident Response — Tools & Platform]]
- [[#Incident Response — Framework & Studi Kasus]]
- [[#Platform Latihan Multi-Kategori]]

---

## Fondasi Riset Lanskap

| Sumber                  | URL                                                        | Kapan Dipakai                                                          |
| ----------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------- |
| **MITRE ATT&CK**        | https://attack.mitre.org/                                  | Mapping TTP attacker — setiap kali analisis malware/APT                |
| **MITRE D3FEND**        | https://d3fend.mitre.org/                                  | Countermeasure mapping — defense technique against specific attack     |
| **SANS Reading Room**   | https://www.sans.org/reading-room/                         | Whitepaper teknis — forensic imaging, memory analysis, IR playbook     |
| **Black Hat Archives**  | https://www.blackhat.com/archives.html                     | Slide & video presentasi — 0day, teknik baru, research terdepan        |
| **DEF CON Archives**    | https://defcon.org/html/defcon-archive/defcon-archive.html | Sama — lebih ke komunitas & tool release                               |
| **Google Scholar**      | https://scholar.google.com/scholar?q=cyber+security        | Jurnal akademik — memory forensic techniques terbaru, ML untuk deteksi |
| **OWASP Top 10 + WSTG** | https://owasp.org/www-project-web-security-testing-guide/  | Web vulnerability reference — test case per kerentanan                 |
| **Exploit-DB**          | https://www.exploit-db.com/                                | PoC exploit — cari CVE spesifik, belajar teknik exploit                |
| **CVE Details**         | https://www.cvedetails.com/                                | Database CVE — severity, CWE, products affected                        |

---

## Digital Forensic — Tools & Framework

### Memory Forensic

| Tool                      | URL                                                 | Fungsi                                               |
| ------------------------- | --------------------------------------------------- | ---------------------------------------------------- |
| **Volatility Foundation** | https://www.volatilityfoundation.org/               | Framework utama — profile detection, plugin ekstensi |
| **Volatility 3 GitHub**   | https://github.com/volatilityfoundation/volatility3 | Source code + plugin komunitas                       |

**Deep skill:** inject detection (process hollowing, DLL injection), rootkit hidden process, credential extraction (NTLM hash dari lsass), network artifact reconstruction dari memory.

### Disk Forensic

| Tool                     | URL                                                    | Fungsi                                                      |
| ------------------------ | ------------------------------------------------------ | ----------------------------------------------------------- |
| **Autopsy / Sleuth Kit** | https://www.autopsy.com/                               | GUI + CLI — MFT analysis, timeline, keyword search, carving |
| **FTK Imager**           | https://www.exterro.com/ftk-imager/                    | Forensic imaging — bit-by-bit, preview, hashing             |
| **Magnet AXIOM**         | https://www.magnetforensics.com/products/magnet-axiom/ | All-in-one — disk + mobile + cloud artifact analysis        |

### Network Forensic

| Tool               | URL                        | Fungsi                                                            |
| ------------------ | -------------------------- | ----------------------------------------------------------------- |
| **Wireshark**      | https://www.wireshark.org/ | Display filter kompleks, stream reassembly, protocol deep-dive    |
| **Zeek (Bro IDS)** | https://zeek.org/          | Log-based traffic analysis — conn.log, dns.log, http.log, ssl.log |

### Mobile Forensic

| Tool                          | URL                              | Fungsi                                                |
| ----------------------------- | -------------------------------- | ----------------------------------------------------- |
| **Cellebrite**                | https://www.cellebrite.com/      | Ekstraksi fisik/logis — iOS/Android, bypass lock      |
| **Oxygen Forensic Detective** | https://www.oxygen-forensic.com/ | Analisis data aplikasi, cloud backup, timeline visual |

---

## Digital Forensic — Metodologi & Studi Kasus

| Sumber                                                  | URL                                                       | Isi                                                       |
| ------------------------------------------------------- | --------------------------------------------------------- | --------------------------------------------------------- |
| **NIST SP 800-86**                                      | https://csrc.nist.gov/publications/detail/sp/800-86/final | Integrasi forensik ke IR — standar pemerintah AS          |
| **DFIR Process (ident-preserv-collect-analyze-report)** | —                                                         | Chain of custody, write-blocker, hashing, imaging valid   |
| **CyberDefenders**                                      | https://cyberdefenders.org/                               | Tantangan DFIR — memory, disk, PCAP, malware analysis     |
| **TryHackMe DFIR Paths**                                | https://tryhackme.com/                                    | Room IR + forensik — skenario realistis, tools siap pakai |
| **Magnet Forensics CTF**                                | https://www.magnetforensics.com/blog/category/ctf/        | CTF forensic — writeup kompetisi sebelumnya               |
| **Verizon DBIR**                                        | https://www.verizon.com/business/resources/reports/dbir/  | Data breach real — statistik, root cause, lessons learned |

---

## Attack Defense — Exploitation & Defense

| Tool                     | URL                                                                     | Fungsi                                                                     |
| ------------------------ | ----------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| **Metasploit Framework** | https://www.metasploit.com/                                             | Exploit dev, payload crafting (reverse/bind), post-exploitation            |
| **Burp Suite**           | https://portswigger.net/burp/                                           | Web proxy — intercept, repeater, intruder, sequencer                       |
| **SQLMap**               | http://sqlmap.org/                                                      | SQL injection automation — boolean, time, error, out-of-band               |
| **Nmap + NSE**           | https://nmap.org/                                                       | Network scanning + scripting engine — vuln detection, backdoor scan, brute |
| **Ghidra**               | https://ghidra-sre.org/                                                 | Reverse engineering — decompiler, disassembler, scriptable (Java/Python)   |
| **IDA Free**             | https://hex-rays.com/ida-free/                                          | Disassembler — decompiler limited, tapi standar industri                   |
| **AFL / LibFuzzer**      | https://lcamtuf.coredump.cx/afl/ — https://llvm.org/docs/LibFuzzer.html | Fuzzing — bug hunting otomatis, coverage-guided                            |

---

## Attack Defense — Metodologi & Latihan

| Sumber                  | URL                                                 | Isi                                                     |
| ----------------------- | --------------------------------------------------- | ------------------------------------------------------- |
| **OSSTMM v3**           | https://www.isecom.org/OSSTMM.3.pdf                 | Standar pengujian keamanan — channel, class, vector     |
| **PTES**                | http://www.pentest-standard.org/index.php/Main_Page | Standar pentest — pre-engagement → reporting            |
| **Hack The Box**        | https://www.hackthebox.com/                         | Box realistis — active + retired, walkthrough komunitas |
| **TryHackMe Red Team**  | https://tryhackme.com/                              | Red team path — exploit dev, web hacking, AD            |
| **VulnHub**             | https://www.vulnhub.com/                            | VM vulnerable — download + run local, full pentest      |
| **PortSwigger Academy** | https://portswigger.net/web-security                | Lab interaktif web vuln — SQLi, XSS, SSRF, RCE          |
| **Project Zero Blog**   | https://googleprojectzero.blogspot.com/             | 0day deep-dive — teknik finding, exploitation chain     |
| **CTFTime Writeups**    | https://ctftime.org/writeups/                       | Solusi CTF global — filter by category, year, event     |

---

## Incident Response — Tools & Platform

| Tool                  | URL                                                             | Fungsi                                                              |
| --------------------- | --------------------------------------------------------------- | ------------------------------------------------------------------- |
| **ELK Stack**         | https://www.elastic.co/                                         | Log aggregation + search + dashboard — indeks milyaran log          |
| **Splunk**            | https://www.splunk.com/                                         | SIEM enterprise — SPL query language, correlation rules             |
| **Osquery**           | https://osquery.io/                                             | SQL-like endpoint query — threat hunting across fleet               |
| **Sysmon**            | https://learn.microsoft.com/en-us/sysinternals/downloads/sysmon | Windows logging advanced — process, network, registry, file change  |
| **MISP**              | https://www.misp-project.org/                                   | Threat intelligence sharing — IOC correlation, feed integration     |
| **SOAR (konseptual)** | —                                                               | Automation playbook — block IP, isolate host, collect forensic data |

---

## Incident Response — Framework & Studi Kasus

| Sumber                   | URL                                                                           | Isi                                                                                     |
| ------------------------ | ----------------------------------------------------------------------------- | --------------------------------------------------------------------------------------- |
| **NIST SP 800-61 Rev 2** | https://csrc.nist.gov/publications/detail/sp/800-61/rev-2/final               | Bible IR — preparation → detection/analysis → containment → eradication → post-incident |
| **Cyber Kill Chain**     | https://www.lockheedmartin.com/en-us/capabilities/cyber/cyber-kill-chain.html | 7 tahap serangan — recon → weaponize → deliver → exploit → install → C2 → exfil         |
| **CyberDefenders IR**    | https://cyberdefenders.org/                                                   | Tantangan IR — malware analysis, log analysis, threat hunting                           |
| **DFIR Report**          | https://thedfirreport.com/                                                    | Analisis insiden nyata — artefak, timeline, TTP, IOC                                    |
| **SANS IR Resources**    | https://www.sans.org/incident-response/                                       | Whitepaper, webcast, playbook — dari pelatihan SANS                                     |

---

## Platform Latihan Multi-Kategori

| Platform                  | URL                                  | Fokus             | Cocok Untuk                    |
| ------------------------- | ------------------------------------ | ----------------- | ------------------------------ |
| **CyberDefenders**        | https://cyberdefenders.org/          | DFIR              | Forensic + IR                  |
| **Hack The Box**          | https://www.hackthebox.com/          | Offensive         | Web, PWN, AD, Crypto           |
| **TryHackMe**             | https://tryhackme.com/               | Beginner-friendly | Semua kategori — learning path |
| **VulnHub**               | https://www.vulnhub.com/             | Offline VM        | Pentest full scope             |
| **PortSwigger Academy**   | https://portswigger.net/web-security | Web khusus        | Web vuln dari basic → advanced |
| **PicoCTF**               | https://picoctf.org/                 | Beginner CTF      | CTF pemula — kategori lengkap  |
| **CTFTime**               | https://ctftime.org/                 | Jadwal + writeup  | Semua event + solusi           |
| **Blue Team Labs Online** | https://blueteamlabs.online/         | Blue team         | Forensic, IR, SOC simulation   |

---

## Cross-Link

- **Atlas CTF Framework** → [[hierarchy-ctf-competition-framework]]
- **Methodology & Strategy** → [[ctf-competition-methodology-strategy]]
- **Tool Arsenal** → [[ctf-tool-arsenal-universal]]
- **Network Forensics** → [[hierarchy-network-forensics]]
- **Windows Forensics** → [[windows-forensics-artifact-analysis]]
- **File Carving** → [[file-carving-data-recovery-advanced]]
- **Attack-Defense Hardening** → [[attack-defense-hardening-playbook]]
- **Master Index** → [[master-index]]

---

_Research Resource Directory · Sumber Daya Universal — Tidak Terikat Event · Jina DeepResearch + Kurasi Manual · Baca Dulu, Praktik Kemudian_
