---
title: Incident Response Framework — NIST CSF, SANS PICERL, Detection Engineering
  & Post-Mortem
tags:
  - sops
  - cyber-security
  - incident-response
created: "2026-07-15"
updated: "2026-07-15"
status: operational
cssclasses: ""
---

# 🚨 Incident Response Framework — NIST CSF, SANS PICERL, Detection Engineering & Post-Mortem

> Panduan komprehensif incident response (IR) yang menyatukan kerangka kerja standar (NIST CSF, SANS PICERL, MITRE ATT&CK), detection engineering lifecycle, playbook execution, forensic acquisition, hingga post-mortem analysis. Nota ini adalah **hub sentral** yang mengikat semua SOP yang ada di vault ke dalam satu siklus IR yang terstruktur — dari preparation hingga lessons learned. Bisa digunakan sebagai acuan untuk SOC tim, blue team drills, dan maturity assessment.

> [!info] Hubungan ke Vault
> Nota ini adalah **hub** yang mengikat: [[arp-spoofing-mitigation]] (containment), [[forensic-imaging-analysis]] (acquisition), [[hpa-exorcism]] dan [[systemrescue-recovery]] (recovery), [[storage-refurbishing]] (eradication), [[endpoint-detection-playbook]] (triage), [[blueteam-detection-matrix]] dan [[blueteam-vs-enterprise-c2]] (detection), [[malware-analysis-reverse-engineering-playbook]] (analysis), serta [[threat-modeling-deepdive]] dan [[comprehensive-threat-directory]] (threat intel). Setiap SOP di vault ini dipetakan ke fase IR tertentu.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Incident Response — Mengapa Perlu Framework?

Tanpa framework, incident response cenderung reaktif, tidak konsisten, dan sulit diukur efektivitasnya. Framework memberikan:

| Manfaat           | Deskripsi                                                     |
| ----------------- | ------------------------------------------------------------- |
| **Struktur**      | Fase jelas: apa yang dilakukan, kapan, oleh siapa             |
| **Konsistensi**   | Setiap incident ditangani dengan proses yang sama             |
| **Efisiensi**     | Mengurangi waktu pengambilan keputusan (decision fatigue)     |
| **Akuntabilitas** | Setiap tindakan tercatat dan bisa diaudit                     |
| **Improvement**   | Post-mortem → feedback loop → perbaikan berkelanjutan         |
| **Compliance**    | Memenuhi persyaratan regulasi (PCI DSS, ISO 27001, GDPR, PBI) |

### Dua Framework Utama

#### NIST SP 800-61 Rev. 2 — Computer Security Incident Handling Guide

| Fase                                       | Deskripsi                                               | Output                                               |
| ------------------------------------------ | ------------------------------------------------------- | ---------------------------------------------------- |
| **1. Preparation**                         | Siapkan tools, playbook, training, communication plan   | IR plan, toolkit, contact list, SLAs                 |
| **2. Detection & Analysis**                | Deteksi, verifikasi, triage, dan analisis awal incident | Incident ticket, severity score, preliminary scope   |
| **3. Containment, Eradication & Recovery** | Isolasi, bersihkan, dan pulihkan sistem                 | Containment plan, eradication log, recovery timeline |
| **4. Post-Incident Activity**              | Post-mortem, lessons learned, report                    | Incident report, action items, updated playbook      |

#### SANS PICERL (6 Fase Praktis)

| Fase  | Nama                | Tujuan Utama                               | Waktu Target                             |
| ----- | ------------------- | ------------------------------------------ | ---------------------------------------- |
| **P** | **Preparation**     | Siapkan tools, training, team              | Berkelanjutan                            |
| **I** | **Identification**  | Deteksi, triage, tentukan scope & severity | <15 menit (severity), <1 jam (scope)     |
| **C** | **Containment**     | Isolasi — stop the bleeding                | Short-term: <30 menit; Long-term: <4 jam |
| **E** | **Eradication**     | Hapus root cause, malware, backdoor        | 1-24 jam tergantung severity             |
| **R** | **Recovery**        | Kembalikan operasi normal, validasi        | 1-48 jam                                 |
| **L** | **Lessons Learned** | Post-mortem, update playbook, training     | 1-14 hari pasca-incident                 |

Perbandingan: NIST lebih **strategic** (cocok untuk management dan compliance), PICERL lebih **operational** (cocok untuk SOC dan responder).

### Severity Classification

| Level     | Warna       | Kriteria                                                       | Contoh                             | Response Time     |
| --------- | ----------- | -------------------------------------------------------------- | ---------------------------------- | ----------------- |
| **SEV-1** | 🔴 Critical | Data breach, ransomware, system-wide outage, PII exfiltrated   | Ransomware encrypting file servers | <15 menit         |
| **SEV-2** | 🟠 High     | Lateral movement detected, malware outbreak di segmen terbatas | Emotet infection di 3 workstation  | <1 jam            |
| **SEV-3** | 🟡 Medium   | Single host compromise, phishing success tanpa lateral         | Malware downloaded (blocked by AV) | <4 jam            |
| **SEV-4** | 🔵 Low      | Scanning, probe, phishing attempt gagal                        | Port scan dari external IP         | <24 jam           |
| **SEV-5** | ⚪ Info     | False positive, user reported suspicious email                 | Phishing email reported (no click) | Next business day |

### IR Team Structure (RACI)

| Role                        | Tanggung Jawab                                  | SEV-1        | SEV-2     | SEV-3/4   |
| --------------------------- | ----------------------------------------------- | ------------ | --------- | --------- |
| **Incident Commander (IC)** | Decision maker, coordinator                     | On-call 24/7 | Lead      | Lead      |
| **SME — Network**           | Network containment, firewall                   | On-call      | Available | Available |
| **SME — Endpoint**          | Host forensics, EDR                             | On-call      | Lead      | Available |
| **SME — Cloud**             | Cloud IR, IAM, CSPM                             | On-call      | Available | Consult   |
| **Legal & Compliance**      | Regulatory obligation, data breach notification | On-call      | Consult   | Available |
| **Communications**          | Internal comms, PR                              | On-call      | Available | —         |
| **Management**              | Resource allocation, business decisions         | Informed     | Informed  | Informed  |

---

## Technical Deep-Dive

### Phase 1 — Preparation

#### IR Toolkit Minimum

```
☐ Endpoint:
  ☐ Live response: Velociraptor, CyLR (Collection) + EDR agent (CrowdStrike/Defender)
  ☐ Memory acquisition: winpmem, LiME (Linux Memory Extractor)
  ☐ Disk imaging: FTK Imager, dd, Guymager
  ☐ Triage: KAPE (Kroll Artifact Parser and Extractor), Chainsaw, Hayabusa
  ☐ Analysis: Volatility 3, FLOSS, CAPA
  ☐ Timeline: Plaso (log2timeline)

☐ Network:
  ☐ Packet capture: tcpdump, Wireshark, NetworkMiner
  ☐ Flow analysis: zeek (bro), nfdump
  ☐ DNS: dnscap, passive DNS tools
  ☐ Proxy: squid logs, mitmproxy

☐ Cloud:
  ☐ AWS: CloudTrail, GuardDuty, AWS Config
  ☐ Azure: Microsoft Sentinel, Azure Activity Log
  ☐ GCP: Cloud Audit Logs, Security Command Center

☐ SIEM & SOAR:
  ☐ SIEM: Wazuh (OSS), ELK Stack, Splunk, Sentinel
  ☐ SOAR: Shuffle (OSS), Splunk SOAR, Palo Alto XSOAR

☐ Communication:
  ☐ Secure chat: Signal, Slack (with war room)
  ☐ Ticketing: Jira, TheHive (OSS)
  ☐ Documentation: collaborative doc (Google Doc/Confluence dengan access control)
```

#### Playbook Template

Setiap playbook harus memiliki format standar:

```yaml
---
title: "Playbook: Ransomware Response"
id: IR-PB-001
version: 1.2
last_updated: 2026-07-15
severity: SEV-1
phases:
  - identification
  - containment
  - eradication
  - recovery
dependencies:
  - EDR logs
  - Network flow logs
  - Backup system access
trigger: "EDR alert: Ransomware behavior detected"
steps:
  identification:
    - "0-5m: Verify alert — is it real or FP?"
    - "5-15m: Determine scope: host, user, encryption type"
    - "15-30m: Check if backup is also encrypted"
  containment:
    - "0-10m: Isolate host (network disconnect or EDR containment)"
    - "10-30m: Block C2 IOCs at firewall/proxy"
    - "30-60m: Disable affected AD accounts"
  eradication:
    - "Reimage affected hosts from known-good image"
    - "Rotate all credentials in scope"
    - "Remove persistence: scheduled tasks, services, registry run keys"
  recovery:
    - "Restore from clean backup (verify timestamp pre-encryption)"
    - "Deploy updated EDR signatures"
    - "Monitor for re-infection for 48 hours"
  lessons_learned:
    - "Root cause analysis: how did initial access occur?"
    - "Gap analysis: what detection/prevention failed?"
---
```

### Phase 2 — Identification

#### Sumber Deteksi

| Sumber             | Contoh Alert                                          | Kecepatan      | False Positive Rate |
| ------------------ | ----------------------------------------------------- | -------------- | ------------------- |
| **EDR**            | Behavioral detection, process injection, LSASS access | Real-time      | Medium              |
| **SIEM**           | Correlation rule — multiple failed logon + success    | Near real-time | Medium-High         |
| **Network**        | DNS sinkhole hit, C2 beacon pattern                   | Real-time      | Low                 |
| **Cloud**          | GuardDuty, IAM anomaly, S3 public access              | Real-time      | Low-Medium          |
| **User report**    | Phishing report, unusual behavior                     | Manual         | Medium              |
| **3rd party**      | Takedown notice, threat intel feed                    | Hours-days     | Low                 |
| **Threat hunting** | Hypothesis-driven search                              | Proactive      | Variable            |

#### Triage — Diamond Model

Setiap incident harus dipetakan ke **Diamond Model** untuk memahami konteks:

```
                Adversary
                   ▲
                  / \
                 /   \
                /     \
               /       \
          Infrastructure ◄─────── Capability
               \       /
                \     /
                 \   /
                  \ /
                   ▼
                Victim
```

| Sisi Diamond       | Pertanyaan Kunci                                    |
| ------------------ | --------------------------------------------------- |
| **Adversary**      | Siapa? Known group? Motivasi? TTPs?                 |
| **Capability**     | Apa yang digunakan? Malware, exploit, phishing?     |
| **Infrastructure** | IP, domain, C2 server? Hosting provider?            |
| **Victim**         | Siapa yang terkena dampak? Data apa yang terekspos? |

#### Initial Triage Checklist (15 Menit)

```
☐ Verifikasi alert: cek log mentah, bukan sekedar alert summary
☐ Tentukan SEV level (1-5 berdasarkan dampak bisnis)
☐ Screenshot: timeline event, indicators, affected hosts
☐ Assign Incident Commander
☐ Notify stakeholders (sesuai RACI matrix)
☐ Create war room (secure chat + document)
☐ Open ticket with incident timeline
☐ Jika SEV-1: paging tree — semua on-call
```

### Phase 3 — Containment

#### Containment Strategies per Skenario

| Skenario                            | Short-Term Containment                                    | Long-Term Containment                           |
| ----------------------------------- | --------------------------------------------------------- | ----------------------------------------------- |
| **Ransomware (single host)**        | Network isolation + EDR kill process                      | Reimage host from known-good image              |
| **Ransomware (network-wide)**       | Disable AD accounts + block SMB outbound + firewall block | Restore from backup + rotate all credentials    |
| **C2 Beacon**                       | Network block C2 IP/domain at firewall                    | Forensik host → remove persistence → reimage    |
| **Data exfiltration (in progress)** | Block outbound traffic to unknown IPs + revoke IAM keys   | IAM audit + S3 bucket policy lockdown           |
| **Phishing credential theft**       | Force password reset + revoke session tokens              | MFA enrollment for all affected + investigation |
| **Insider threat**                  | Suspend AD account + revoke access + preserve evidence    | HR + Legal involved, forensic imaging           |
| **DDoS**                            | Blackhole routing + scrubbing center                      | WAF + rate limiting + CDN failover              |
| **Supply chain compromise**         | Disconnect affected vendor integrations                   | Vendor risk assessment + alternative vendor     |

#### Containment Commands — Quick Reference

**Linux:**

```bash
# Kill process
kill -9 $(pgrep -f malicious_process)

# Network isolation (iptables)
iptables -A INPUT -s 0.0.0.0/0 -j DROP
iptables -A OUTPUT -d 0.0.0.0/0 -j DROP

# Remove SSH key persistence
rm -rf ~/.ssh/authorized_keys
```

**Windows:**

```powershell
# Kill process
Stop-Process -Name "malicious" -Force

# Network isolation (Windows Firewall)
New-NetFirewallRule -Direction Outbound -RemoteAddress 0.0.0.0/0 -Block -Profile Any

# Disable AD account
Disable-ADAccount -Identity "compromised_user"
```

#### Chain of Custody

Setiap evidence yang dikumpulkan harus memiliki chain of custody:

| Field             | Isi                                       |
| ----------------- | ----------------------------------------- |
| **Evidence ID**   | E-001                                     |
| **Description**   | Memory dump host CORP-WKS-045             |
| **Source**        | IP 10.0.45.22, hostname CORP-WKS-045      |
| **Acquired by**   | J. Analyst (SOC Lead)                     |
| **Date/Time**     | 2026-07-15 14:30 UTC                      |
| **Method**        | winpmem_x64.exe mem.dmp                   |
| **Hash (MD5)**    | a1b2c3d4e5f6...                           |
| **Hash (SHA256)** | f9e8d7c6b5a4...                           |
| **Location**      | NAS://cases/IR-2026-007/evidence/         |
| **Transfer log**  | File copied via rsync to NAS at 14:35 UTC |
| **Handover to**   | A. Forensics Analyst (15:00 UTC, signed)  |

### Phase 4 — Eradication

Eradication berarti **menghilangkan root cause** dari lingkungan — bukan hanya mengembalikan sistem ke state operational.

| Root Cause                  | Eradication Action                                    |
| --------------------------- | ----------------------------------------------------- |
| **Malware dropper**         | Reimage host, clean all shared drives                 |
| **Weak credential**         | Force password reset + enable MFA                     |
| **Unpatched vulnerability** | Apply patch + verify other hosts same vulnerability   |
| **Misconfiguration**        | Fix config + IaC policy update + CSPM rule            |
| **Phishing**                | Block sender domain + training + email security rule  |
| **Insider**                 | Revoke access + HR action + forensic preservation     |
| **Supply chain**            | Remove vendor integration + incident report to vendor |

### Phase 5 — Recovery

Recovery adalah **mengembalikan operasi dengan aman** — bukan sekedar restore:

```
Recovery Checklist:
☐ Restore from clean backup (validated timestamp pre-compromise)
☐ Verify integrity: scan with updated signatures
☐ Network monitoring: enable extra logging on recovered hosts
☐ User access: restore with MFA + least privilege
☐ Validation: run security scan (SAST/DAST/SCA)
☐ Monitoring: enhanced monitoring for 48-72 hours post-recovery
☐ Stakeholder comms: status update "operasi normal kembali"
☐ Business verification: confirm key metrics (transactions, uptime, latency)
```

### Phase 6 — Lessons Learned (Post-Mortem)

Post-mortem harus dilakukan **dalam 1-14 hari** setelah incident — semakin cepat semakin baik, detail masih segar.

#### Post-Mortem Template

```markdown
# Post-Mortem Incident IR-2026-007

## Metadata

- **Incident ID:** IR-2026-007
- **Severity:** SEV-1 (Critical)
- **Date:** 2026-07-15
- **Duration:** 3h 24m (14:30 - 17:54 UTC)
- **Report Author:** J. Analyst
- **Response Team:** 5 persons (IC, Endpoint, Network, Cloud, Legal)

## Timeline

| Time (UTC) | Event                                                    |
| ---------- | -------------------------------------------------------- |
| 14:30      | EDR alert: Ransomware behavior detected on CORP-WKS-045  |
| 14:32      | IC assigned, severity upgraded to SEV-1                  |
| 14:35      | Host network-isolated                                    |
| 14:40      | Block C2 IP at firewall                                  |
| 14:50      | Memory + disk imaging started                            |
| 15:10      | IC determines: single host, no lateral movement detected |
| 15:30      | EDR scans all endpoints — 0 additional detections        |
| 16:00      | Containment confirmed successful                         |
| 16:30      | Forensic analysis: initial access via phishing email     |
| 17:00      | Host reimaged from known-good ISO                        |
| 17:30      | User credentials rotated + MFA enforced                  |
| 17:54      | Recovery verified — host back in production              |

## Root Cause Analysis

### Teknis

- **Initial Access:** Spear-phishing email dengan malicious Excel macro
- **Execution:** PowerShell download cradle → .NET assembly loaded in memory (fileless)
- **Persistence:** Scheduled task "OneDrive Sync" setiap 30 menit
- **Impact:** Single host encrypted (files di %USERPROFILE%), tidak ada network share terenkripsi

### Process

- Email security rule tidak menangkap phishing karena sender domain legitimate (compromised vendor account)
- User tidak melaporkan email (trained? no — user belum training phishing dalam 6 bulan)

## Action Items

| ID    | Action                                                        | Owner          | Due Date   | Status         |
| ----- | ------------------------------------------------------------- | -------------- | ---------- | -------------- |
| AI-01 | Update email security rule: block macro from external senders | Email Sec Team | 2026-07-20 | ✅ Done        |
| AI-02 | Mandatory phishing training untuk semua user                  | HR + IT Sec    | 2026-08-01 | 🟡 In Progress |
| AI-03 | Deploy ASR rule: block Office child process creation          | Endpoint Team  | 2026-07-18 | ✅ Done        |
| AI-04 | Update ransomware playbook (IR-PB-001)                        | IR Lead        | 2026-07-25 | 🔴 Not Started |

## Metrics

| Metric                                  | Value                                |
| --------------------------------------- | ------------------------------------ |
| Time to detection (from initial access) | 24 minutes                           |
| Time to containment                     | 20 minutes                           |
| Time to eradication                     | 1h 30m                               |
| Time to recovery                        | 3h 24m                               |
| Business impact                         | None (single host, no customer data) |
| False positives                         | 0 (alert was accurate)               |
```

#### IR Metrics Penting

| Metric                            | Target                          | Rumus                                     |
| --------------------------------- | ------------------------------- | ----------------------------------------- |
| **MTTD** (Mean Time to Detect)    | <30 menit untuk SEV-1           | Total waktu deteksi / jumlah incident     |
| **MTTC** (Mean Time to Contain)   | <1 jam untuk SEV-1              | Total waktu containment / jumlah incident |
| **MTTE** (Mean Time to Eradicate) | <4 jam untuk SEV-1              | Total waktu eradication / jumlah incident |
| **MTTR** (Mean Time to Recover)   | <8 jam untuk SEV-1              | Total waktu recovery / jumlah incident    |
| **False Positive Rate**           | <30% dari all alerts            | Total FP / total alerts                   |
| **Post-mortem completion**        | 100% untuk SEV-1/2 dalam 7 hari | Rata-rata hari penyelesaian               |

---

## Advanced

### Detection Engineering Lifecycle

Detection engineering adalah proses sistematis untuk menulis, menguji, dan memelihara detection rules:

```
Cycle:
1. Threat Intel (CVE, report, TTPs) atau Post-Mortem Gap
       │
       ▼
2. Hypothesis — "Bagaimana attacker akan beroperasi di env kita?"
       │
       ▼
3. Data Source Mapping — logs apa yang punya info relevan?
       │
       ▼
4. Rule Authoring — Sigma, YARA, KQL, Splunk SPL
       │
       ▼
5. Testing — Historical data + live simulation (Atomic Red Team, Stratus)
       │
       ▼
6. Tuning — Baseline untuk mengurangi FP, adjust threshold
       │
       ▼
7. Deployment — Deploy ke SIEM, EDR, atau WAF
       │
       ▼
8. Monitoring — Alert performance monitoring + periodic review
       │
       ▼
9. Feedback — Post-mortem findings → adjust detection gaps
```

#### Sigma Rule — Detection as Code

Sigma adalah format universal untuk detection rules (bisa di-export ke Splunk, QRadar, Elastic, ArcSight, dll):

```yaml
title: Suspicious PowerShell Download Cradle
id: 7c8d9e0f-1a2b-3c4d-5e6f-7a8b9c0d1e2f
status: experimental
description: Mendeteksi pola download PowerShell dari URL — sering digunakan oleh post-exploitation tools
references:
  - https://thedfirreport.com/2024/07/powershell-cradle/
tags:
  - attack.t1059.001 # PowerShell
  - attack.t1105 # Ingress Tool Transfer
logsource:
  product: windows
  category: ps_script
  definition: "Requires PowerShell Script Block Logging (EnableScriptBlockLogging)"
detection:
  selection_download:
    ScriptBlockText|contains:
      - "System.Net.WebClient"
      - "Invoke-WebRequest"
      - "Invoke-RestMethod"
      - "Start-BitsTransfer"
  selection_bypass:
    ScriptBlockText|contains:
      - "Bypass"
      - "-ExecutionPolicy"
      - "EncodedCommand"
  selection_obfuscation:
    ScriptBlockText|contains:
      - "[System.Text.Encoding]::UTF8.GetString"
      - "[System.Convert]::FromBase64String"
      - "-join"
  condition: (selection_download and selection_bypass) or (selection_download and selection_obfuscation)
level: high
falsepositives:
  - "Admin menggunakan PowerShell untuk legitimate download (rare)"
  - "Software update scripts"
```

### Atomic Red Team — Simulation Testing

Atomic Red Team (Red Canary) adalah library test case yang memetakan langsung ke MITRE ATT&CK:

```powershell
# Install
IEX (IWR 'https://raw.githubusercontent.com/redcanaryco/invoke-atomicredteam/master/install-atomicredteam.ps1');
Install-AtomicRedTeam -getAtomics

# Run single test
Invoke-AtomicTest T1059.001 -TestName "Powershell Download Cradle" -GetPrereqs

# Run against entire technique
Invoke-AtomicTest T1059.001

# Run with cleanup
Invoke-AtomicTest T1059.001 -Cleanup
```

**Pro tip:** Schedule Atomic Red Team di test environment **secara otomatis setiap minggu** untuk memvalidasi bahwa detection rules Anda masih berfungsi.

### Purple Team Framework

Purple Team bukan peran — ini **aktivitas kolaborasi** antara Red (attack) dan Blue (defense):

```
Purple Team Exercise Cycle:
1. Select TTP dari MITRE ATT&CK (prioritas: yang belum terdeteksi atau incident gap)
2. Red Team execute attack technique
3. Blue Team observe: apakah detection rule triggered?
   ┌─ Yes → dokumentasikan sebagai "detected"
   └─ No  → identifikasi gap:
           ├─ Log source tidak tersedia?
           ├─ Log source ada tapi rule tidak tertulis?
           └─ Rule ada tapi threshold tidak cocok?
4. Create/update detection rule
5. Test ulang dengan teknik yang sama
6. Dokumentasikan dan masukkan ke knowledge base
```

### Maturity Model — IR Capability Assessment

| Level       | Nama       | Karakteristik                                                                                                         |
| ----------- | ---------- | --------------------------------------------------------------------------------------------------------------------- |
| **Level 0** | Ad-hoc     | Tidak ada playbook, incident ditangani "by heroes", dokumentasi minim                                                 |
| **Level 1** | Initial    | Ada IR policy dasar, satu dua orang tahu prosedur, tools tidak terintegrasi                                           |
| **Level 2** | Defined    | IR policy tertulis, playbook untuk SEV-1/2, basic SIEM + EDR                                                          |
| **Level 3** | Managed    | Metrics dikumpulkan (MTTD, MTTR), purple team exercise berkala, SOAR untuk SEV-3/4                                    |
| **Level 4** | Optimizing | Detection engineering lifecycle berjalan, threat intel feed integrated, automated IR untuk SEV-3/4, join ISAC/FS-ISAC |

**Assessment:** Gunakan checklist NIST CSF untuk self-assessment tiap kuartal.

### Mapping SOP di Vault ke Fase IR

| SOP / Note                                        | Fase IR                                 | Tujuan                                                           |
| ------------------------------------------------- | --------------------------------------- | ---------------------------------------------------------------- |
| [[arp-spoofing-mitigation]]                       | **C** — Containment                     | Isolasi serangan ARP spoofing di jaringan lokal                  |
| [[forensic-imaging-analysis]]                     | **I** — Identification                  | Akuisisi bit-stream untuk analisis forensik                      |
| [[hpa-exorcism]]                                  | **E** — Eradication                     | Bersihkan HPA/DCO dari media penyimpanan                         |
| [[systemrescue-recovery]]                         | **R** — Recovery                        | Recovery OS dari SystemRescue live CD                            |
| [[storage-refurbishing]]                          | **E** — Eradication (then R — Recovery) | Wipe & recondition storage media                                 |
| [[laptop-qc-procurement]]                         | **P** — Preparation                     | Standardisasi hardware sebelum deploy (reduce supply chain risk) |
| [[printer-maintenance-reset]]                     | **R** — Recovery                        | Reset printer (low-severity but operational IT)                  |
| [[quartz-setup-windows]]                          | **P** — Preparation                     | Setup Quartz engine untuk monitoring                             |
| [[endpoint-detection-playbook]]                   | **I** — Identification                  | Triage endpoint — RAM dump, Volatility, persistence              |
| [[blueteam-detection-matrix]]                     | **I** — Identification                  | Detection rules dan C2 detection matrix                          |
| [[blueteam-vs-enterprise-c2]]                     | **I** — Identification                  | Deteksi C2 enterprise-grade                                      |
| [[malware-analysis-reverse-engineering-playbook]] | **A** — Analysis (cross-phase)          | Analisis malware: triage, static, dynamic, memory, RE            |
| [[threat-modeling-deepdive]]                      | **P** — Preparation                     | Identifikasi ancaman preventif sebelum incident                  |
| [[comprehensive-threat-directory]]                | **P** — Preparation                     | Threat intel knowledge base                                      |

### Detection Engineering — KQL Query Examples

#### Failed Logon Spike (Potential Password Spray)

```kusto
// Azure Sentinel / Microsoft 365 Defender
SigninLogs
| where TimeGenerated > ago(1h)
| where ResultType == "50057" // User account is disabled
    or ResultType == "50053" // Account locked
    or ResultType == "50126" // Invalid username or password
| summarize FailedAttempts = count() by UserPrincipalName, IPAddress
| where FailedAttempts > 10
| join kind=inner (
    SigninLogs
    | where ResultType == "0" // Success
    | summarize SuccessfulLogon = count() by UserPrincipalName
) on UserPrincipalName
| project UserPrincipalName, IPAddress, FailedAttempts, SuccessfulLogon
| order by FailedAttempts desc
```

#### Suspicious Outbound DNS Query (DGA)

```kusto
// Zeek DNS logs
dns
| where query_type == "A"
| where timestamp > ago(1h)
| extend domain_length = strlen(query)
| where domain_length >= 8 and domain_length <= 20
| extend entropy =
    countof(query, @'[a-z]') * 0.4 +
    countof(query, @'[0-9]') * 0.6
| where entropy > 0.6
| summarize count() by query
| top 10 by count_ desc
```

---

## Case Studies

| Studi Kasus                                   | Fase IR                  | Temuan Kunci                                                                                                                                                                                                                                                                                                         | Action Items                                                                                             |
| --------------------------------------------- | ------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| **Ransomware LockBit (Skenario Single Host)** | I → C → E → R            | 1. Detection: EDR alert process injection → svchost.exe unusual child. 2. Containment: 20 menit — network isolate. 3. Eradication: reimage from ISO. 4. Recovery: restore user profile from backup. 5. Post-mortem: initial access via Excel macro.                                                                  | 1. Block Office child process. 2. User phishing training. 3. Enhance email security rule.                |
| **Data Exfiltration via Cloud (2023)**        | I → C → E → R            | 1. Detection: Cloud DLP alert — 10GB data upload ke non-corporate cloud storage. 2. Containment: revoke IAM keys + disable user account. 3. Eradication: remove unauthorized IAM user + cross-account role. 4. Recovery: enable CloudTrail + GuardDuty. 5. Post-mortem: compromised contractor credentials — no MFA. | 1. MFA enforce ALL external users. 2. SCP untuk restrict data exfil. 3. DLP policy: block upload >100MB. |
| **APT29 (Nobelium) Supply Chain (2020)**      | Full PICERL, multi-month | 1. Detection: threat intel — SolarWinds Orion signature. 2. Containment: disconnect Orion from network. 3. Eradication: reimage all affected servers + rotate golden SAML key. 4. Recovery: months-long remediation. 5. Lessons: zero-trust, federated identity monitoring, SBOM.                                    | 1. SLSA 3+ build pipeline. 2. Federated identity anomaly detection. 3. Supply chain vendor SLA.          |
| **Insider Threat — IP Theft**                 | I → C → L                | 1. Detection: VPN session from unusual location + bulk download dari code repository. 2. Containment: suspend AD account, revoke VPN certificate. 3. Eradication: not applicable (data already exfiltrated). 4. Recovery: not applicable. 5. Lessons: DLP data classification maturity.                              | 1. Data classification + DLP. 2. UEBA untuk user behavior. 3. Just-in-Time access untuk sensitive repo.  |
| **Web App Compromise (SQL Injection)**        | I → C → E → R            | 1. Detection: WAF alert — SQL injection pattern. 2. Containment: WAF block rule + temporary application takedown. 3. Eradication: SAST menemukan query concatenation. 4. Recovery: deploy fix + verify via DAST. 5. Lessons: no parameterized query in CI gate.                                                      | 1. SAST pipeline block. 2. WAF managed SQL injection rule. 3. DAST in staging.                           |

---

## Koneksi ke Vault

- [[arp-spoofing-mitigation]] → Containment phase: SOP mitigasi ARP spoofing
- [[forensic-imaging-analysis]] → Identification phase: akuisisi bit-stream
- [[hpa-exorcism]] → Eradication phase: HPA/DCO removal
- [[systemrescue-recovery]] → Recovery phase: SystemRescue live CD recovery
- [[storage-refurbishing]] → Eradication → Recovery phase: wipe & recondition
- [[laptop-qc-procurement]] → Preparation phase: standardisasi hardware
- [[printer-maintenance-reset]] → Recovery phase: operational recovery
- [[quartz-setup-windows]] → Preparation phase: monitoring setup
- [[endpoint-detection-playbook]] → Identification phase: triage & forensics
- [[blueteam-detection-matrix]] → Identification phase: C2 detection
- [[blueteam-vs-enterprise-c2]] → Identification phase: enterprise C2 detection
- [[malware-analysis-reverse-engineering-playbook]] → Analysis (cross-phase): malware RE
- [[threat-modeling-deepdive]] → Preparation phase: preventive threat identification
- [[comprehensive-threat-directory]] → Preparation phase: threat intelligence
- [[active-directory-windows-security-deepdive]] → ALL phases: Windows AD security in IR context
- [[devsecops-pipeline-sast-dast-sbom]] → Preparation phase: pipeline security gate
- [[cloud-security-posture-management]] → ALL phases: cloud security in IR context
- [[system-design]] → Preparation phase: resilient architecture design
- [[zero-trust-security]] → Preparation + Containment: microsegmentation, least privilege

---

## Referensi

1. NIST. _SP 800-61 Rev. 2: Computer Security Incident Handling Guide_. 2012. https://nvlpubs.nist.gov/nistpubs/SpecialPublications/NIST.SP.800-61r2.pdf
2. NIST. _SP 800-86: Guide to Integrating Forensic Techniques into Incident Response_. 2006. https://csrc.nist.gov/publications/detail/sp/800-86/final
3. SANS Institute. _Incident Handling Steps (PICERL)_. https://www.sans.org/white-papers/incident-handlers-handbook/
4. FIRST. _PSIRT Services Framework_. https://www.first.org/standards/frameworks/psirts/psirt_services_framework_v1.1
5. MITRE ATT&CK. _Enterprise Matrix_. https://attack.mitre.org/
6. MITRE ATT&CK. _Detection, Response, and Recovery Framework_. https://attack.mitre.org/resources/getting-started/
7. NIST. _CSF 2.0: Cybersecurity Framework_. 2024. https://www.nist.gov/cyberframework
8. SANS. _SEC504: Hacker Techniques, Exploits & Incident Handling_. https://www.sans.org/cyber-security-courses/hacker-techniques-incident-handling/
9. The DFIR Report. _Real Intrusion Incidents_. https://thedfirreport.com/
10. Red Canary. _Atomic Red Team_. https://atomicredteam.io/
11. Sigma HQ. _Sigma Detection Rules_. https://github.com/SigmaHQ/sigma
12. Elastic. _Security Detection Rules_. https://github.com/elastic/detection-rules
13. Splunk. _Security Essentials_. https://www.splunk.com/en_us/software/splunk-security-essentials.html
14. CrowdStrike. _Incident Response Services_. https://www.crowdstrike.com/services/incident-response/
15. Mandiant. _Incident Response Services_. https://www.mandiant.com/services/incident-response
16. Velocidex. _Velociraptor — Endpoint Visibility_. https://docs.velociraptor.app/
17. KAPE (Kroll). _Kroll Artifact Parser and Extractor_. https://www.kroll.com/en/services/cyber-risk/incident-response-forensics/kape
18. Plaso (log2timeline). _Plaso Documentation_. https://plaso.readthedocs.io/en/latest/
19. TheHive Project. _TheHive — IR Platform_. https://thehive-project.org/
20. Shuffle. _Shuffle SOAR_. https://shuffler.io/
21. CISA. _Incident Response Training_. https://www.cisa.gov/incident-response
22. Verizon. _2024 Data Breach Investigations Report_. https://www.verizon.com/business/resources/reports/dbir/
23. OWASP. _Incident Response Guide_. https://owasp.org/www-project-incident-response-guide/
24. ENISA. _Incident Response in the EU_. https://www.enisa.europa.eu/topics/incident-response
25. FIRST. _CVSS v4.0 Calculator_. https://www.first.org/cvss/calculator/4.0

> [!tip] Bottom Line
> Incident Response bukan tentang tool canggih — ini tentang **proses yang terstruktur, dilatih, dan terus diperbaiki**. Kunci IR yang efektif: (1) **Preparation adalah fase termahal jika diabaikan** — playbook harus ditulis, dilatih, dan diuji dengan simulasi (tabletop atau Atomic Red Team). (2) **Containment adalah fase paling penting** — stop the bleeding sebelum mencari root cause. (3) **Post-mortem adalah investasi** — tanpa lessons learned, Anda hanya mengulang incident yang sama setiap 6 bulan. (4) **Semua SOP di vault ini terikat ke satu siklus IR** — masing-masing punya tempat dan waktunya dalam fase PICERL. Gunakan framework ini sebagai "map" untuk menavigasi incident — dari preparation hingga recovery — dan jadikan post-mortem sebagai alat untuk mendorong perbaikan organisasi secara kontinu.
