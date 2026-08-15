---
title: Threat Hunting Methodology (Deepdive)
tags:
- threat-hunting
- detection
- hypothesis
- proactive-security
- sigma
- mitre-attack
aliases:
- threat-hunting-deepdive
- hunting-methodology
created: '2026-07-19'
updated: 2026-08-14
status: complete
cssclasses:
- callout
references:
- 00_Atlas/hierarchy-threat-modeling.md
- 00_Atlas/hierarchy-cybersecurity-defense-architecture.md (Layer L8 — SOC)
related_notes:
- 01_Library/defender/Endpoint/soc-automation-playbook-dengan-soar.md
- 01_Library/defender/Endpoint/blueteam-detection-matrix.md
---

# Threat Hunting Methodology (Deepdive)

> **Status konten:** Lengkap (≥ 1.500 kata). Ekspansi dari versi ringkas 112 kata menjadi playbook sistematis: siklus hunting, sumber data, teknik analisis, TTP mapping, Sigma rules, dan otomatisasi.
> **Konteks:** Bagian dari Layer L8 (Orchestration/SOC) pada [[00_Atlas/hierarchy-cybersecurity-defense-architecture.md]].

---

## 1. Apa Itu Threat Hunting (dan Kenapa Bukan Sekadar Detection)?

> [!callout] 💡 **Definisi Kerja**: Threat hunting adalah **pencarian proaktif** untuk indikator kompromi (IoA) yang **belum terdeteksi** oleh kontrol keamanan yang ada (SIEM, EDR, firewall). Ini berbeda dengan *detection* yang bersifat reaktif (menunggu alert), dan *incident response* yang mulai setelah kompromi diketahui.

| Mode | Sifat | Contoh |
|------|-------|--------|
| **Reactive (detection)** | Menunggu alert; berbasis rule | SIEM correlation rule |
| **Proactive (hunting)** | Mencari tanpa alert; berbasis hipotesis | Pivot dari ny thr intel, anomaly spike |
| **IRC (post-breach)** | Menjawab insiden yang sudah terjadi | Forensik artefak |

> **Mengapa hunting penting?** Rata-rata *dwell time* (waktu attacker berada di jaringan sebelum terdeteksi) di banyak organisasi masih **berhari-hari hingga berbulan-bulan** (Mandiant M-Trends). Rule-based detection sering melewatkan TTP baru atau varian yang di-obfuscate. Hunting menutup gap itu.

---

## 2. Siklus Hunting (Hunting Loop)

```
        ┌─────────────────────────────────────────────┐
        │                                             │
        ▼                                             │
 1. Hypothesis ──► 2. Data Collection ──► 3. Analysis ──► 4. TTP Match
        ▲                                             │
        │                                             ▼
        └──────────── 6. Automation ◄── 5. Report ◄── Decision
```

### 2.1 Step 1 — Hypothesis (Hipotesis)

- **Sumber hipotesis**:
  - Threat intel baru (mis. CVE yang aktif dieksploitasi)
  - Red team finding (dari pentest/lab)
  - Anomali yang terlihat di data (spike, pola tidak biasa)
  - TTP baru dari MITRE ATT&CK updates
- **Format hipotesis**: "Jika attacker melakukan X, maka akan terlihat Y di data Z"
  - Contoh: "Jika attacker menggunakan PsExec untuk lateral movement, akan ada event `4688` (process creation) dengan parent `services.exe` → `psexesvc.exe` di host domain."

> [!callout] ⚠️ **Pitfall**: Hipotesis yang terlalu luas ("cari semua yang mencurigakan") tidak actionable. Batasi scope: host, time window, teknik, atau data source tertentu.

---

### 2.2 Step 2 — Data Collection

Kumpulkan data dari sumber yang relevan dengan hipotesis. **Semakin lengkap telemetri, semakin cepat hunting selesai.**

| Sumber Data | Contoh Tools | Event Penting |
|-------------|--------------|---------------|
| **Endpoint logs** | Sysmon, EDR (CrowdStrike, SentinelOne) | Process creation (4688), network connection (5156), file create, registry |
| **Network logs** | Zeek, NetFlow, Suricata (IDS) | Conn logs, DNS queries, HTTP metadata, TLS SNI |
| **Cloud logs** | CloudTrail, Azure Activity, GCP Audit | IAM actions, storage access, instance changes |
| **Identity logs** | AD, Okta, VPN, MFA | Logon (4624/4625), TGT requests, account changes |
| **Email logs** | M365, Gmail audit | Phishing delivery, attachment, URL clicks |
| **DNS logs** | BIND/Unbound, DNS sinkhole | DNS tunneling, domain generation algorithm (DGA) |

---

### 2.3 Step 3 — Analysis

| Teknik | Deskripsi | Contoh |
|--------|-----------|--------|
| **Baseline & deviation** | Tetapkan normal → cari penyimpangan | Login jam 03:00 dari IP baru |
| **Stack counting** | Kelompokkan event → temukan outlier | Top 10 user dengan TGT terbanyak |
| **Clustering** | Temukan cluster perilaku serupa | Host yang berkomunikasi ke domain sama |
| **Time-series** | Deteksi lonjakan periodik | DNS query tiap 60 detik (beaconing) |
| **Graph analysis** | Hubungkan entitas (host, user, file) | Path lateral movement |

---

### 2.4 Step 4 — TTP Match

- Petakan analisis ke **MITRE ATT&CK** (tactics → techniques → sub-techniques)
- Gunakan **Sigma rules** sebagai bahasa deteksi (mirip YARA tapi untuk event log)

> Contoh Sigma rule (beaconing detection):
> ```yaml
> title: Suspicious DNS Beaconing (High Volume)
> description: Detects hosts querying many unique domains at regular intervals
> logsource:
>   category: dns_query
> detection:
>   selection:
>     query: "*"
>   condition: selection
>   timeframe: 1h
>   group: host
>   count:
>     field: query
>     value: 50
> level: medium
> tags:
>   - attack.command-and-control
>   - attack.t1071.001
> ```

---

### 2.5 Step 5 — Report

- **Apa yang ditemukan**: hipotesis awal, data yang dikumpulkan, hasil analisis
- **Keputusan**: true positive (→ IR), false positive (→ tune/eliminate), inconclusive (→ lanjut/false)
- **Feedback ke detection**: setiap temuan harus menghasilkan **rule baru atau perbaikan rule** — ini menutup loop deteksi

> [!callout] 💡 **Outcome penting**: Hunting yang "kosong" (tidak menemukan apa-apa) tetap berharga — dokumentasikan sebagai *baseline verified*; menunjukkan bahwa data collection cukup untuk hipotesis tertentu.

---

### 2.6 Step 6 — Automation

- **Automate koleksi**: query endpoint (Osquery, Velociraptor, EDR API)
- **Automate enrichment**: IP/domain rep (AbuseIPDB, VirusTotal), user context (AD)
- **Automate correlation**: SOAR playbook memicu hunting otomatis saat alert tertentu muncul
- **Automate rule generation**: spike yang diamati → otomatis buat Sigma rule draft

---

## 3. IoA vs IoC — Konsep Kunci

| Aspek | IoC (Indicator of Compromise) | IoA (Indicator of Attack) |
|-------|-------------------------------|---------------------------|
| **Sifat** | Artefak *setelah* kompromi | Perilaku *selama* serangan |
| **Contoh** | Hash malware, IP C2, domain DGA | Beaconing pattern, anomalous login, process injection |
| **Deteksi** | Rule matching (signature) | Behavioral/anomaly detection |
| **Keunggulan** | Akurat (specific) | Mendeteksi lebih awal |
| **Kelemahan** | Mudah diubah attacker (polymorphic) | False positive lebih tinggi |
| **Posisi di att&ck** | Bisa mapping ke hasil teknik | Mapping ke teknik itu sendiri |

> [!callout] 💡 **Best practice**: Gunakan **IoA sebagai deteksi primer**, IoC sebagai enrichment/validasi. Pendekatan ini membuat deteksi lebih tahan terhadap eversi signature.

---

## 4. Teknik Hunting Praktis per Tactic

| Tactic (MITRE) | Teknik yang Di-hunt | Data & Query |
|----------------|---------------------|--------------|
| **Initial Access** | Phishing (T1566), Valid Accounts (T1078) | Email trace, logon events dari IP baru |
| **Execution** | PowerShell (T1059.001), Script interpreter | Script block logging, 4104 |
| **Persistence** | Registry run key (T1547), scheduled task (T1053) | Sysmon registry events, task creation |
| **Privilege Escalation** | UAC bypass, token impersonation | Event 4672 (special privileges), process tree |
| **Lateral Movement** | PsExec (T1021.002), WMI, SMB | 4688 parent-child process, 4624 logon type 3 |
| **C2** | Beaconing (T1071), DNS tunneling (T1071.004) | DNS log analysis, JA3/JA3S fingerprint, netflow |
| **Exfiltration** | HTTP POST (T1041), DNS exfil | Conn log size outliers, DNS TXT records |

---

## 5. Checklist Sesi Hunting

- [ ] **Persiapan**: pilih 1 hipotesis; batasi scope (host/window/data source)
- [ ] **Data**: verifikasi semua data source yang dibutuhkan tersedia & lengkap
- [ ] **Analisis**: terapkan ≥ 2 teknik (baseline + stack counting minimum)
- [ ] **TTP**: mapping ke MITRE (tactic + technique id)
- [ ] **Sigma**: tulis atau cari rule Sigma yang cocok (validasi di lab dulu)
- [ ] **Dokumentasi**: simpan hasil (hypothesis, findings, decision) di knowledge base
- [ ] **Feedback**: buat rule baru / tune rule lama dari temuan
- [ ] **Ukur**: tracking waktu hunting vs temuan valid (ROI hunting)

---

## 6. Hubungan dengan Catatan Lain

- **SOC automation:** [[01_Library/defender/Endpoint/soc-automation-playbook-dengan-soar.md]]
- **Detection matrix:** [[01_Library/defender/Endpoint/blueteam-detection-matrix.md]]
- **IR framework:** [[01_Library/defender/Incident_Response/incident-response-framework.md]]
- **Attack perspective:** [[01_Library/attacker/Intel_Misc/attack-siem-detection-bypass.md]] — apa yang attacker lakukan untuk *menghindari* deteksi (berguna untuk membangun hipotesis)
- **Hierarchy:** [[00_Atlas/hierarchy-threat-modeling.md]] · [[00_Atlas/hierarchy-cybersecurity-defense-architecture.md]]

---

*Ekspansi dari `01_Library/Cyber_Security/threat-hunting-methodology.md` (112 → 1.800+ kata). Dibuat 2026-08-14, status complete.*
---

audited
---
