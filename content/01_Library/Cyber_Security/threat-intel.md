---
title: Threat Intel
tags: [security, intel, cti]
aliases: [threat-intel]
---
# Threat Intelligence

Threat intelligence (TI) adalah proses pengumpulan, analisis, dan penyebaran informasi ancaman (IOC: hash malware, domain C2, teknik TTP sesuai MITRE ATT&CK). Tujuan: deteksi lebih cepat, respon insiden lebih tepat, dan keputusan keamanan berbasis data.

## Siklus TI

1. **Direction** — tentukan kebutuhan: apa yang dilindungi, aktor mana yang relevan, decision yang didukung.
2. **Collection** — kumpulkan dari feed (MISP, AlienVault OTX, VirusTotal, abuse.ch, CISA advisories), OSINT, dark web monitoring, telemetry internal (EDR, firewall, DNS logs).
3. **Processing** — normalisasi format (STIX/TAXII), deduplikasi, enrich (WHOIS, passive DNS, sandbox detonation).
4. **Analysis** — korelasi, analisis TTP, atribusi (hati-hati: jangan over-attribution), produksi intel report (TLP classified).
5. **Dissemination** — bagikan ke stakeholder dengan TLP (RED/AMBER/GREEN/CLEAR), integrasikan ke SIEM/EDR.
6. **Feedback** — ukur efektivitas: false positive, actionable intel, deteksi yang dihasilkan.

## Tipe Intel

| Tipe | Horizon | Contoh |
|------|---------|--------|
| Strategic | 1-3 tahun | risk assessment, trend landscape, threat actor profiles |
| Tactical | 1-6 bulan | TTP, toolset, kampanye |
| Operational | minggu-bulan | infrastruktur C2, domain baru, campaign signals |
| Technical/Indicator | real-time | IOC: hash, IP, domain, URL |

## Format & Standar

- **STIX 2.1** — bahasa representasi intel terstruktur (objects: indicator, malware, threat-actor, campaign).
- **TAXII 2.x** — protokol transport intel (channels: discovery, collection, poll).
- **MISP** — platform sharing + correlation (feed otomatis, event-based).
- **OpenCTI** — platform analisis intel (graph-based knowledge).
- **YARA rules** — deteksi pattern malware.
- **Sigma rules** — deteksi log generik (SIEM-agnostic).

## Integrasi Operasional

- Feed intel → SIEM (Splunk ES, Elastic, Wazuh) → correlation rules → alert.
- IOC enrichment otomatis: hash → VirusTotal/Local sandbox; domain → passive DNS.
- Threat hunting: gunakan intel untuk hipotesis hunting (misal: aktor X suka PowerShell obfuscation → cari di telemetry).

## Red Team Perspective

TI digunakan untuk meniru TTP adversary nyata (APT28, Lazarus, dll) agar simulasi lebih realistis — emulation plan dari MITRE ATT&CK + intel publik (Mandiant reports, CrowdStrike). Sebaliknya, blue team memakai intel untuk deteksi: buat Sigma/YARA rules dari IOC kampanye.

## Sumber Daya

- MITRE ATT&CK (attack.mitre.org) — TTP knowledge base
- abuse.ch (URLhaus, MalwareBazaar, ThreatFox) — IOC feeds
- CISA Known Exploited Vulnerabilities Catalog
- Talos, Mandiant, CrowdStrike blogs — threat research
- VirusTotal, AlienVault OTX — enrichment



## Studi Kasus Penggunaan TI dalam Insiden

**Ransomware Rapid Spread (LockBit):**
1. Feed TI mendeteksi IOC C2 LockBit baru (domain, IP).
2. IOC di-enrich: lihat kampanye sebelumnya (TTP: exploitation of RDP, PsExec deployment).
3. SIEM rule dibuat: deteksi PsExec dari host non-admin (Sigma rule) + outbound ke C2.
4. Monitoring: host A terdeteksi → proses di-network-isolate → containment.
5. Post-incident: YARA rule untuk varian enkripsi baru; report TLP:AMBER ke sektor.

**Supply Chain (SolarWinds):**
- Intel strategic: aktor menggunakan supply chain (SUNBURST DLL) — update policy: verifikasi hash vendor, code signing check.
- Intel tactical: query untuk process tree anomali `SolarWinds.BusinessLayerHost.exe` → network beacon pattern.
- Detection: telemetry query + IOC (domain avsvmcloud[.]com).

## Membangun CTI Minimal (Tim Kecil)

1. **Koleksi**: MISP (feed + sharing), VirusTotal API, abuse.ch feeds, CISA KEV (prioritas: known exploited), vendor advisories.
2. **Normalisasi**: script python untuk convert berbagai format → STIX/JSON internal; dedup by hash/domain.
3. **Enrichment pipeline**: hash → VT; domain → passive DNS (SecurityTrails, RiskIQ); IP → WHOIS/geolocation/ASN.
4. **Integrasi**: SIEM (Elastic/Wazuh) consume IOC list via API; firewall/DNS blocklist untuk malicious domains.
5. **Produser**: brief mingguan (1 halaman): aktor aktif, TTP baru, IOC baru, rekomendasi.
6. **UMO (Use, Measure, Optimize)**: berapa alert dari intel? berapa false positive? berapa incident dicegah/dipercepat?

## TLP (Traffic Light Protocol)

| Level | Makna | Contoh |
|-------|-------|--------|
| TLP:RED | Hanya individu/tim yang disebut | Info insiden spesifik |
| TLP:AMBER | Organisasi + need-to-know | IOC kampanye |
| TLP:GREEN | Komunitas luas | Advisories umum |
| TLP:CLEAR | Publik | Open reports |

## Tools Open Source

- **MISP** — threat sharing platform (events, attributes, correlation).
- **OpenCTI** — platform analisis (STIX graph).
- **TheHive / Cortex** — case management + enrichment (MISP integration).
- **IntelOwl** — enrichment engine (banyak analyzer: VT, Shodan, AbuseIPDB, YARA).
- **Sigma** — rule detection generic, convert ke query SIEM (sigmac).
- **YARA-X** — pattern matching malware.



## Perbedaan CTI vs OSINT vs Threat Hunting

| Disiplin | Fokus | Output |
|----------|-------|--------|
| OSINT | Info publik apa saja | profil organisasi/person, exposed assets |
| CTI | Ancaman terhadap organisasi | IOC, TTP, aktor, kampanye |
| Threat Hunting | Cari anomali di telemetry sendiri | hipotesis teruji, deteksi baru |

## Prioritization Framework

- **TLP + severity + relevansi**: intel tentang sektor/tech stack kita > intel umum.
- **CISA KEV**: known exploited vulnerabilities — patch SLA 2 minggu (wajib).
- **CVSS + exploitability**: gabungkan dengan intel exploitation in the wild.
- **Kampanye aktif**: apakah aktor sedang menyerang sektor kita? (ISAC sharing).
- **False positive management**: setiap IOC harus di-validasi sebelum blocking (jangan block tanpa konteks).

## Contoh Update Policy Intek

1. IOC list dari MISP di-push ke firewall/SIEM tiap 15 menit (daftar blokir domain/IP).
2. CISA KEV di-scan tiap minggu vs inventory asset → ticket patch otomatis.
3. YARA/Sigma rules baru dari komunitas (e.g. Florian Roth) di-review & import.
4. Brief mingguan ke tim (10 menit): aktor aktif, kampanye, TTP baru, action items.

---

  audited
---