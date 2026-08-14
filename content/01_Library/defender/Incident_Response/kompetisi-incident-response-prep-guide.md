---
title: "Incident Response — Kompetisi Prep Guide: IR Framework, Log Analysis, Threat Hunting, Malware Triage, Reporting"
tags:
  - cyber-security
  - incident-response
  - ctf
  - kompetisi
  - dfir
  - library
aliases:
  - "Incident Response Competition Guide"
  - "IR Blue Team Prep"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Panduan persiapan kompetisi **Incident Response** — mencakup IR framework (NIST 800-61), log analysis (ELK/Splunk), threat hunting (Osquery/Sysmon), malware triage, timeline reconstruction, dan reporting. Berdasarkan direktori riset di [[research-resource-directory-deep]] dan framework IR di [[incident-response-framework]]. Target: 20 menit per skenario IR, timeline akurat, root cause teridentifikasi.

**Cross-link:** [[research-resource-directory-deep]] → [[incident-response-framework]] → [[threat-hunting-methodology]] → [[blueteam-detection-matrix]] → [[siem-security-data-lake-architecture]] → [[soc-automation-playbook-dengan-soar]] → [[attack-defense-hardening-playbook]]

---

## Daftar Isi
- [[#S1 — IR Framework (NIST 800-61)]]
- [[#S2 — Log Analysis Fast Track]]
- [[#S3 — Threat Hunting dengan Osquery]]
- [[#S4 — Windows Event Log Analysis]]
- [[#S5 — Malware Triage]]
- [[#S6 — Timeline Reconstruction]]
- [[#S7 — IR Reporting Template]]
- [[#S8 — Tool Priority Matrix]]
- [[#S9 — Referensi Cepat]]

---

## S1 — IR Framework (NIST 800-61)

Setiap soal IR di kompetisi mengikuti siklus NIST 800-61:

```
1. PREPARATION    → Tools siap, playbook diingat
2. DETECTION      ↓ 
   & ANALYSIS     → Evidence diberikan, identifikasi insiden
        ↓
3. CONTAINMENT    → Isolate host, block IP
   ERADICATION    ↓
   & RECOVERY     → Hapus malware, restore service
        ↓
4. POST-INCIDENT → Writeup, rekomendasi
```

### Pertanyaan Kunci

| Tahap | Pertanyaan Kompetisi | Evidence |
|---|---|---|
| Detection | "Kapan first compromise?" | Log timestamp, alert time |
| Analysis | "Apa root cause?" | Vulnerability exploited, vector |
| Analysis | "Apa malware yang dipakai?" | Hash, filename, C2 domain |
| Containment | "IP attacker?" | Network log, firewall log |
| Eradication | "Bagaimana cara hapus?" | Artifact cleanup steps |
| Lesson | "Rekomendasi?" | Fix, prevent recurrence |

---

## S2 — Log Analysis Fast Track

### ELK Stack (Elasticsearch + Logstash + Kibana)

```bash
# KQL Query — cari event spesifik
process.name: "powershell.exe" AND process.args: "downloadstring"
source.ip: "10.10.10.*" AND event.action: "network-connection"
event.code: 4625 AND winlog.event_data.SubStatus: 0xC000006A  # Failed logon

# Timeline
@timestamp: [2026-07-01 TO 2026-07-28]
```

### Splunk SPL

```splunk
# Cari malware execution
index=windows sourcetype=WinEventLog:Security EventCode=4688
| search New_Process_Name=*powershell* OR New_Process_Name=*rundll32*
| stats count by New_Process_Name, User_Name

# Cari network connection mencurigakan
index=network sourcetype=flow
| search dest_ip=10.0.0.0/8 OR dest_ip=172.16.0.0/12
| stats sum(bytes_out) by src_ip, dest_ip

# Failed logins
index=windows EventCode=4625
| stats count by Target_User_Name, Source_Network_Address
| where count > 5
```

### Log Sources Priority

| Log Source | Windows | Linux |
|---|---|---|
| Authentication | Security (Event 4624/4625/4648) | `/var/log/auth.log` |
| Process | Sysmon Event 1 | auditd |
| Network | Sysmon Event 3 | `/var/log/syslog` |
| File change | Sysmon Event 11 | auditd/inotify |
| PowerShell | PowerShell Operational (Event 4104/4103) | N/A |

---

## S3 — Threat Hunting dengan Osquery

Osquery mengubah endpoint menjadi database SQL. Cocok untuk threat hunting cepat.

### Queries Penting

```sql
-- Process dengan network connection
SELECT p.pid, p.name, p.path, p.cmdline, p.parent
FROM processes p
JOIN process_open_sockets s ON p.pid = s.pid
WHERE s.remote_port != 0 AND s.remote_address NOT IN ('127.0.0.1', '0.0.0.0');

-- Scheduled tasks mencurigakan
SELECT * FROM scheduled_tasks
WHERE name LIKE '%updater%' OR name LIKE '%svchost%';

-- Autorun mencurigakan
SELECT * FROM startup_items
WHERE path LIKE '%temp%' OR path LIKE '%AppData%';

-- File di direktori temp
SELECT path, filename, size, datetime(atime,'unixepoch') as accessed
FROM file
WHERE directory LIKE 'C:\Users\%\AppData\Local\Temp\'
  AND filename LIKE '%.exe';

-- DNS query mencurigakan
SELECT * FROM dns_resolvers;
```

### Pack Hunting

```bash
# Osquery pack — kumpulan query untuk IR
osqueryi --pack incident_response

# Atau run manual
osqueryi "SELECT * FROM processes WHERE on_disk = 0;"
# → Process yang tidak ada di disk (injected/malware)
```

---

## S4 — Windows Event Log Analysis

### Event ID Penting

| Event ID | Deskripsi | Indikator |
|---|---|---|
| 4624 | Logon success | Successful authentication |
| 4625 | Logon failure | Brute force attempt |
| 4634 | Logoff | Session end time |
| 4648 | Explicit credential | RunAs, scheduled task |
| 4688 | Process creation | Execution timeline |
| 4689 | Process exit | Termination time |
| 4698 | Scheduled task created | Persistence |
| 4700 | Scheduled task enabled | Persistence |
| 4702 | Scheduled task updated | Modification |
| 4720 | User account created | New user |
| 4732 | User added to group | Privilege escalation |
| 5156 | Connection allowed | Network connection |
| 5157 | Connection blocked | Blocked connection |
| 7045 | Service installed | New service (persistence) |

### Timeline Analysis

```powershell
# PowerShell — cari execution dalam rentang waktu
Get-WinEvent -FilterHashtable @{
    LogName='Security'
    ID=4688
    StartTime='2026-07-01'
    EndTime='2026-07-02'
} | Select TimeCreated, @{n='Process';e={
    $_.Properties[5].Value
}}

# Sysmon — cari network connection
Get-WinEvent -FilterHashtable @{
    LogName='Microsoft-Windows-Sysmon/Operational'
    ID=3
} | Where-Object {$_.Properties[14].Value -notlike '192.168.*'} |
  Select TimeCreated,
         @{n='Src';e={$_.Properties[4].Value}},
         @{n='Dst';e={$_.Properties[14].Value}},
         @{n='Port';e={$_.Properties[16].Value}}
```

---

## S5 — Malware Triage

### Static Analysis (Cepat)

```bash
# Hash — cek di VirusTotal
sha256sum malware.exe
md5sum malware.exe

# Strings — cari IOC
strings malware.exe | grep -i "http://"
strings malware.exe | grep -i "https://"
strings malware.exe | grep -i "\.exe\|\.dll\|\.ps1"

# Detect packer
file malware.exe
# UPX packed, section names: UPX0, UPX1 → unpack dulu
upx -d malware.exe -o malware_unpacked.exe

# Imports — cari API mencurigakan
objdump -p malware.exe | grep "DLL Name"
# VirtualAlloc, CreateRemoteThread → injection
# URLDownloadToFile → downloader
```

### Dynamic Analysis (if environment allows)

```bash
# Process monitor
procmon.exe /backingfile malware_log.pml

# Network capture
tcpdump -i eth0 -w malware.pcap

# Registry changes
regshot
# Jalankan malware → compare regshot
```

### Malware Classification

| Type | Tujuan | Indicator |
|---|---|---|
| Keylogger | Capture keystrokes | `SetWindowsHookEx`, `GetAsyncKeyState` |
| Backdoor | Remote access | Reverse shell, port binding |
| Ransomware | Encrypt files | File extension change, ransom note |
| Downloader | Fetch payload | `URLDownloadToFile`, `WinHttpRequest` |
| Miner | Crypto mining | High CPU, `stratum+tcp://` |
| RAT | Full control | Persistence, keylogging, screen capture |
| Infostealer | Credential theft | Browser profile access, `mail` |

---

## S6 — Timeline Reconstruction

Timeline adalah kunci IR. Urutkan kejadian berdasarkan waktu.

### Timeline Tools

```bash
# Plaso (log2timeline) — timeline otomatis
log2timeline.py --storage-file timeline.plaso image.dd
psort.py -o l2tcsv -w timeline.csv timeline.plaso

# MFT Timelime
mft2csv.py -f \$MFT -o mft_timeline.csv
```

### Template Timeline

```text
[2026-07-01 08:00] Initial access → Phishing email diterima user
[2026-07-01 08:05] Execution → User buka attachment
[2026-07-01 08:06] Persistence → Registry Run key added
[2026-07-01 08:10] C2 → Connection to malicious domain
[2026-07-01 08:15] Lateral movement → RDP to server
[2026-07-01 08:30] Exfiltration → Large outbound data transfer
[2026-07-01 09:00] Detection → SOC alert triggered
```

### Key Artifact Timeline

| Waktu | Artifact | Informasi |
|---|---|---|
| $STANDARD_INFORMATION | MFT | Bisa dimodifikasi oleh attacker |
| $FILE_NAME | MFT | Tidak bisa dimodifikasi — source of truth |
| Prefetch | File | Waktu eksekusi program |
| USN Journal | Journal | Perubahan file berurutan |
| Event Log | .evtx | Authentication, process, service |
| Registry | Registry | System config change time |
| Browser history | SQLite | URL access timeline |
| ShellBags | Registry | Folder access time |

---

## S7 — IR Reporting Template

Template writeup untuk soal IR kompetisi:

```markdown
## Incident Summary
- **Title:** [Nama Insiden]
- **Date:** [YYYY-MM-DD HH:MM]
- **Severity:** [Critical/High/Medium/Low]
- **Status:** [Resolved/Mitigated/In Progress]

## Timeline
| Time | Event | Artifact |
|---|---|---|
| HH:MM | Initial compromise | [Log entry ref] |
| HH:MM | Malware execution | [File hash] |
| HH:MM | C2 beacon | [IP/Domain] |
| HH:MM | Data exfiltration | [Size, destination] |

## Indicators of Compromise (IOCs)
- **File:** [filename, hash]
- **Network:** [IP, domain, URL]
- **Registry:** [key, value]
- **Process:** [PID, name, parent]

## Root Cause Analysis
- **Vulnerability:** [CVE / misconfig]
- **Attack vector:** [Email / web / remote exploit]
- **Impact:** [What was compromised]

## Containment Steps
1. [Aksi yang diambil]
2. [Aksi yang diambil]

## Recommendations
1. [Fix jangka pendek]
2. [Fix jangka panjang]
```

---

## S8 — Tool Priority Matrix

| IR Task | Tool #1 | Tool #2 | Tool #3 |
|---|---|---|---|
| Log aggregation | ELK Stack | Splunk | Loki |
| Endpoint query | Osquery | WMI/PowerShell | WinRM SSH |
| Windows forensic | EZ Tools (Zimmerman) | Sysinternals Suite | KAPE |
| Timeline | Plaso (log2timeline) | MFTECmd | Timeline Explorer |
| Malware static | FLOSS | Detect It Easy (DiE) | pefile (Python) |
| Malware dynamic | CAPE Sandbox | ProcMon + Wireshark | Any.Run |
| Memory analysis | Volatility 3 | strings + grep | Rekall |
| Threat intel | MISP | VirusTotal API | AbuseIPDB |
| Network forensic | Wireshark | Zeek | tshark |
| Log query | KQL (Elastic) | SPL (Splunk) | grep/awk/jq |

---

## S9 — Referensi Cepat

- [[research-resource-directory-deep]] — sumber riset IR lengkap
- [[incident-response-framework]] — framework IR
- [[threat-hunting-methodology]] — hunting techniques
- [[blueteam-detection-matrix]] — detection mapping
- [[siem-security-data-lake-architecture]] — SIEM architecture
- [[soc-automation-playbook-dengan-soar]] — SOAR automation
- [[windows-forensics-artifact-analysis]] — Windows artifacts
- [[network-forensics-pcap-analysis]] — PCAP analysis
- [[memory-forensics-volatility-deepdive]] — memory forensic
- [[ebpf-kernel-security]] — kernel-level detection
