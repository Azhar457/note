---
title: "Endpoint Detection Playbook"
tags:
  - cyber-security
  - endpoint-detection
  - library
aliases:
  - "endpoint-detection-playbook"
created: "2026-07-02"
updated: "2026-07-02"
status: operational
cssclasses: ""
---

# 🦠 Endpoint Detection Playbook — Workflow & Tactical Playbook

> Panduan operasional untuk incident detection & response di endpoint: detection lifecycle penuh dari alert hingga lessons learned, konfigurasi EDR tools, detection scenarios dengan playbook taktis, Sigma rules, live response procedure, dan case studies nyata. BUKAN ulasan arsitektur endpoint security — fokus di sini adalah **bagaimana mendeteksi dan merespons** ancaman di endpoint secara operasional.

> [!info] Hubungan ke Vault
> Melengkapi [[endpoint-security]] (CPU Ring & boot chain) dan [[blueteam-detection-matrix]] (C2 per level). Beririsan dengan [[blueteam-vs-enterprise-c2]] untuk lateral movement & persistence. Detection kernel terkait [[ebpf-kernel-security]]. Semua skenario mengikuti [[purple-team-osi-killchain]].

---

## Daftar Isi

- [[#Detection Lifecycle]]
- [[#EDR Tools Breakdown]]
- [[#Process Injection Detection]]
- [[#Persistence Mechanisms Detection]]
- [[#Lateral Movement Detection]]
- [[#Privilege Escalation Detection]]
- [[#Credential Access Detection]]
- [[#Ransomware Behavior Detection]]
- [[#Sigma Rules]]
- [[#Live Response Procedure]]
- [[#Correlation & FP Handling]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]

---

## Detection Lifecycle

Setiap insiden endpoint mengikuti 7 fase:

```
┌──────────────────────────────────────────────────────────────┐
│              ENDPOINT DETECTION LIFECYCLE                     │
├──────────┬───────────────────────────────────────────────────┤
│ Fase 1   │ ALERT — Rule/sensor fires (Sysmon/EDR/Sigma)      │
│ Fase 2   │ TRIAGE — Validasi process tree, cmdline, IOC      │
│ Fase 3   │ INVESTIGATE — Memory dump, timeline, artifacts    │
│ Fase 4   │ CONTAIN — Network isolate, kill process, block C2 │
│ Fase 5   │ ERADICATE — Remove persistence, delete binaries   │
│ Fase 6   │ RECOVER — Golden image rebuild, rotate creds      │
│ Fase 7   │ LESSONS LEARNED — Update rules, purple team       │
└──────────┴───────────────────────────────────────────────────┘
```

### Alert Severity Matrix

| Severity     | Contoh                                         | SLA Triage | SLA Contain |
| ------------ | ---------------------------------------------- | ---------- | ----------- |
| **CRITICAL** | Ransomware, LSASS dump, Golden Ticket          | 5 menit    | 15 menit    |
| **HIGH**     | Process injection, service/scheduled task      | 15 menit   | 1 jam       |
| **MEDIUM**   | LOLBin, registry persistence, unusual outbound | 1 jam      | 4 jam       |
| **LOW**      | User agent anomaly, USB insertion              | 24 jam     | —           |

### Decision Tree — TP vs FP

```
[ALERT FIRES]
├── Proses child legitimate dari parent? Yes→FP, No→lanjut
├── Cmdline normal? ex: -enc <base64> → MALICIOUS (TP)
├── Hash file dikenal malicious? (VirusTotal, Threat Intel)
├── Network connection ke known-bad IP/domain?
└── Jika ragu → isolate dulu, investigasi lanjutan
```

---

## EDR Tools Breakdown

### Perbandingan EDR Tools

| Tool                   | Tipe             | Detection                | Kelebihan                                      | Kelemahan                        | Biaya           |
| ---------------------- | ---------------- | ------------------------ | ---------------------------------------------- | -------------------------------- | --------------- |
| **Sysmon**             | OS-native sensor | ETW + kernel driver      | Gratis, native Windows, extremely configurable | Butuh SIEM, no built-in response | Free            |
| **Velociraptor**       | Forensic + EDR   | VQL, artifact collection | Live response built-in, fleksibel              | No real-time alerting            | Free            |
| **Wazuh**              | SIEM + XDR       | Log + FIM + rootcheck    | Full stack gratis, compliance                  | Agent overhead                   | Free            |
| **Elastic Security**   | SIEM + EDR       | Behavioral + ML + Sigma  | Stack terintegrasi, ML jobs                    | Resource-heavy                   | Free/Enterprise |
| **CrowdStrike Falcon** | Cloud-native EDR | Cloud ML + IOA + IOC     | Detection terbaik, zero-trust                  | Mahal ($10-15/endpoint)          | Commercial      |

### Sysmon — Event ID Penting

| ID    | Deskripsi          | Use Case                       |
| ----- | ------------------ | ------------------------------ |
| 1     | Process creation   | LOLBin, unusual parent-child   |
| 3     | Network connection | Beaconing, C2, data exfil      |
| 6     | Driver loaded      | BYOVD, kernel rootkit          |
| 7     | Image loaded       | DLL hijacking, reflective load |
| 8     | CreateRemoteThread | Process injection              |
| 10    | Process access     | LSASS dump, token theft        |
| 11    | File create        | Ransomware ext, dropper        |
| 12-14 | Registry event     | Run key persistence            |
| 19-21 | WMI event          | WMI persistence                |
| 22    | DNS query          | DNS exfil, C2 lookup           |
| 25    | Process tampering  | Process hollowing              |

### Sysmon Config Minimal

```xml
<Sysmon schemaversion="4.90">
  <EventFiltering>
    <ProcessCreate onmatch="exclude">
      <Image condition="is">C:\Windows\System32\conhost.exe</Image>
    </ProcessCreate>
    <NetworkConnect onmatch="include">
      <DestinationPort condition="is">443</DestinationPort>
      <DestinationPort condition="is">80</DestinationPort>
    </NetworkConnect>
    <DriverLoad onmatch="include">
      <Signature condition="not contains">Microsoft</Signature>
    </DriverLoad>
    <ProcessAccess onmatch="include">
      <TargetImage condition="contains">lsass.exe</TargetImage>
      <TargetImage condition="contains">winlogon.exe</TargetImage>
    </ProcessAccess>
    <CreateRemoteThread onmatch="include">
      <SourceImage condition="not contains">C:\Windows\System32\</SourceImage>
    </CreateRemoteThread>
  </EventFiltering>
</Sysmon>
```

### Velociraptor — VQL Hunting

```vql
-- Proses dengan parent-child tidak wajar
LET p = SELECT Pid, Ppid, Name, CommandLine FROM pslist()
WHERE Name =~ 'cmd\.exe|powershell\.exe|wscript\.exe|cscript\.exe'
   AND Ppid NOT IN (0, 4, 536, 876)
SELECT * FROM p
-- Process hollowing: svchost.exe di path salah
SELECT Pid, Name, Exe FROM pslist()
WHERE Name = 'svchost.exe' AND NOT Exe =~ 'C:\\\\Windows\\\\System32\\\\svchost\.exe'
```

### Elastic Security — EQL

```eql
// Office app spawns shell (macro → execution)
process where event.type == "start" and
  process.parent.name : ("winword.exe","excel.exe","powerpnt.exe") and
  process.name : ("cmd.exe","powershell.exe","wscript.exe","cscript.exe")
// LSASS access anomaly
api where process.name != "lsass.exe" and winlog.event_id == 10 and
  winlog.event_data.TargetImage : "*\\lsass.exe" and
  winlog.event_data.GrantedAccess : ("0x1F0FFF","0x1F1FFF")
```

### CrowdStrike — IOA Classes

| IOA Class            | Scenario                              |
| -------------------- | ------------------------------------- |
| `ProcessInjection`   | CreateRemoteThread, APC, hollowing    |
| `CredentialTheft`    | LSASS dump via DLL load pattern       |
| `RansomwareBehavior` | Mass file mod + shadow copy delete    |
| `Persistence`        | New autorun, WMI, service install     |
| `LateralMovement`    | WMI/WinRM exec, remote scheduled task |
| `BypassAttempt`      | ETW patch, AMSI bypass, driver unload |

---

## Process Injection Detection

### 1. CreateRemoteThread

`OpenProcess → VirtualAllocEx → WriteProcessMemory → CreateRemoteThread`

```yaml
title: CreateRemoteThread in LSASS
status: stable
logsource:
  product: windows
  category: create_remote_thread
detection:
  selection:
    EventID: 8
    TargetImage|endswith: '\lsass.exe'
  filter_legit:
    SourceImage|startswith:
      - 'C:\Windows\System32\'
      - 'C:\Program Files\'
  condition: selection and not filter_legit
level: critical
tags: [attack.defense_evasion, attack.t1055.001]
```

### 2. APC Injection

QueueUserAPC → shellcode di antrian thread, eksekusi saat alertable state.

```yaml
title: APC Injection via QueueUserAPC
status: experimental
logsource:
  product: windows
  category: create_remote_thread
detection:
  selection:
    EventID: 8
    StartModule|contains: "Unknown"
    SourceImage|endswith: ['\powershell.exe', '\wmic.exe', '\mshta.exe']
  condition: selection
level: high
tags: [attack.defense_evasion, attack.t1055.004]
```

### 3. Process Hollowing

`CreateProcess(suspended) → NtUnmapViewOfSection → VirtualAllocEx → WriteProcessMemory → SetThreadContext → ResumeThread`

```yaml
title: Process Hollowing
status: experimental
logsource:
  product: windows
  category: process_tampering
detection:
  selection:
    EventID: 25
    Type: "ProcessTampering"
  condition: selection
level: high
tags: [attack.defense_evasion, attack.t1055.012]
```

**Heuristics:** svchost.exe 1 thread, path ≠ System32, tidak punya service entry di registry.

### Playbook — Process Injection

| Step | Action                   | Tool                          |
| ---- | ------------------------ | ----------------------------- |
| 1    | Full memory dump         | WinPmem                       |
| 2    | Process + DLL list       | Velociraptor pslist()         |
| 3    | YARA scan memory regions | YARA                          |
| 4    | Dump target process      | Volatility memdump            |
| 5    | Analyze injected code    | Volatility malfind/hollowfind |
| 6    | Extract payload          | Volatility procdump + strings |
| 7    | Kill + isolate           | EDR isolate / taskkill        |

---

## Persistence Mechanisms Detection

### Registry Run Keys

```yaml
title: Suspicious Run Key Created
status: stable
logsource:
  product: windows
  category: registry_event
detection:
  selection:
    EventID: 13
    TargetObject|contains: ['\CurrentVersion\Run', '\CurrentVersion\RunOnce']
  filter_legit:
    Image|startswith: ['C:\Program Files\', 'C:\Windows\System32\']
  condition: selection and not filter_legit
level: high
tags: [attack.persistence, attack.t1547.001]
```

### Scheduled Tasks

```yaml
title: Scheduled Task by Non-Admin
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    Image|endswith: '\schtasks.exe'
    CommandLine|contains: "/create"
  filter_legit:
    User: ['NT AUTHORITY\SYSTEM', 'DOMAIN\Administrator']
  condition: selection and not filter_legit
level: high
tags: [attack.persistence, attack.t1053.005]
```

### WMI Event Subscription

```yaml
title: WMI Event Subscription Created
status: stable
logsource:
  product: windows
  category: wmi_event
detection:
  selection:
    EventID: [19, 20, 21]
  condition: selection
level: critical
tags: [attack.persistence, attack.t1546.003]
```

### Service Installation

```yaml
title: New Service Installed (Non-SYSTEM)
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    Image|endswith: '\sc.exe'
    CommandLine|contains: "create"
  filter_legit:
    User: 'NT AUTHORITY\SYSTEM'
  condition: selection and not filter_legit
level: high
tags: [attack.persistence, attack.t1543.003]
```

### Persistence Playbook

| Step | Action            | Tool                             |
| ---- | ----------------- | -------------------------------- |
| 1    | Autoruns baseline | autorunsc64.exe -a * -c -h -s -v |
| 2    | Scheduled tasks   | schtasks /query /fo CSV /v       |
| 3    | WMI subscriptions | Get-WmiObject __EventFilter      |
| 4    | Service audit     | sc query state= all              |
| 5    | Boot execute      | bcdedit /enum                    |

---

## Lateral Movement Detection

### RDP

```yaml
title: Inbound RDP from Unusual Source
status: experimental
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 4624
    LogonType: 10
  filter_legit:
    WorkstationName|startswith: ["ADMIN-PC", "JUMP-BOX"]
  condition: selection and not filter_legit
level: medium
tags: [attack.lateral_movement, attack.t1021.001]
```

### SMB/WMI Exec

```yaml
title: WMI Process Create — Lateral Movement
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    EventID: 4688
    ParentProcessName|endswith: ['\wmiprvse.exe', '\WmiPrvSE.exe']
    LogonId: "0x3e7"
  condition: selection
level: high
tags: [attack.lateral_movement, attack.t1047]
```

### Pass-the-Hash

```yaml
title: PtH via NTLM Logon
status: experimental
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 4624
    LogonType: 3
    AuthenticationPackageName: "NTLM"
    TargetUserName|endswith: "$"
  filter_admin:
    TargetUserName: ["DC01$", "SQL01$"]
  condition: selection and not filter_admin
level: medium
tags: [attack.lateral_movement, attack.t1550.002]
```

### Lateral Movement Playbook

| Step | Action                                         |
| ---- | ---------------------------------------------- |
| 1    | Event 4624 LogonType 3/10 → source IP, account |
| 2    | Service creation across hosts                  |
| 3    | Remote scheduled tasks (schtasks /create /s)   |
| 4    | WMI activity (WMIPRVSE.EXE as parent)          |
| 5    | NTLM auth logs Event 4776                      |

---

## Privilege Escalation Detection

### UAC Bypass

```yaml
title: UAC Bypass via Event Viewer
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    ParentImage|endswith: '\eventvwr.exe'
    Image|endswith: '\cmd.exe'
  condition: selection
level: high
tags: [attack.privilege_escalation, attack.t1548.002]
---
title: UAC Bypass via CMSTPLUA
status: experimental
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    ParentImage|endswith: '\cmstp.exe'
    Image|endswith: '\powershell.exe'
  condition: selection
level: high
tags: [attack.privilege_escalation, attack.t1548.002]
```

### BYOVD Detection

```yaml
title: Known Vulnerable Driver Load
status: experimental
logsource:
  product: windows
  category: driver_load
detection:
  selection:
    EventID: 6
    ImageLoaded|contains:
      - "gdrv.sys"
      - "capcom.sys"
      - "aswbidsh.sys"
      - "rzpnk.sys"
      - "iqvw64.sys"
  condition: selection
level: critical
tags: [attack.privilege_escalation, attack.t1068]
```

### Token Theft

Detection: Event 8 + proses source punya `SeImpersonatePrivilege`. Monitoring `AdjustTokenPrivileges` call.

### PrivEsc Playbook

| Step | Action                                          |
| ---- | ----------------------------------------------- |
| 1    | whoami /priv                                    |
| 2    | Enumerate writable services (sc query + icacls) |
| 3    | Check UAC level via registry                    |
| 4    | Scan loaded drivers (DriverQuery /SI)           |
| 5    | Block vulnerable driver paths (loldrivers.io)   |

---

## Credential Access Detection

### LSASS Dump

Deteksi via Sysmon Event 10 — proses non-legitimate mengakses LSASS dengan GrantedAccess full control.

```yaml
title: LSASS Access for Credential Dumping
status: stable
logsource:
  product: windows
  category: process_access
detection:
  selection:
    EventID: 10
    TargetImage|endswith: '\lsass.exe'
    GrantedAccess: ["0x1F0FFF", "0x1F1FFF", "0x40"]
  filter_legit:
    SourceImage|startswith:
      - 'C:\Windows\System32\lsass.exe'
      - 'C:\Windows\System32\svchost.exe'
  condition: selection and not filter_legit
level: critical
tags: [attack.credential_access, attack.t1003.001]
```

**Heuristics:** rundll32 → comsvcs.dll,MiniDump (dump tanpa procdump). Proses 32-bit akses LSASS 64-bit → suspicious.

### SAM Registry Dump

```yaml
title: SAM Registry Save
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    Image|endswith: '\reg.exe'
    CommandLine|contains: ["save", 'hklm\sam']
  condition: selection
level: critical
tags: [attack.credential_access, attack.t1003.002]
```

### Credential Access Playbook

| Step | Action                                                                         |
| ---- | ------------------------------------------------------------------------------ |
| 1    | Event 10 Sysmon/Security → LSASS access                                        |
| 2    | comsvcs.dll MiniDump calls                                                     |
| 3    | reg save hklm\sam activity                                                     |
| 4    | Enable PPL: reg add HKLM\SYSTEM\CurrentControlSet\Control\Lsa /v RunAsPPL /d 1 |
| 5    | Deploy Credential Guard via GPO                                                |
| 6    | Immediate password reset if dumping confirmed                                  |

---

## Ransomware Behavior Detection

### Timeline Serangan

```
T-15min: Recon (network scan, service enum)
T-5min:  Defense evasion (kill EDR, stop backup)
T-0:     ENCRYPTION START
T+0:     Shadow copy delete (vssadmin.exe)
T+1min:  File ext change (.encrypted)
T+2min:  Ransom note dropped
```

### Mass File Encryption

```yaml
title: Mass File Modification — Ransomware
status: stable
logsource:
  product: windows
  category: file_event
detection:
  selection:
    EventID: 11
  timeframe: 5m
  condition: selection | count() by Image > 100
  filter_legit:
    Image|startswith: ['C:\Program Files\', 'C:\Windows\']
  filter_system:
    User: 'NT AUTHORITY\SYSTEM'
  condition: selection and not filter_legit and not filter_system
level: critical
tags: [attack.impact, attack.t1486]
```

### Shadow Copy Deletion

```yaml
title: Volume Shadow Copy Deletion
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    Image|endswith: '\vssadmin.exe'
    CommandLine|contains: ["delete shadows", "Delete Shadows"]
  condition: selection
level: critical
tags: [attack.impact, attack.t1490]
```

### Additional Indicators

| Indicator                                 | Severity |
| ----------------------------------------- | -------- |
| vssadmin delete shadows /all              | Critical |
| bcdedit /set {default} recoveryenabled No | Critical |
| wbadmin delete catalog -quiet             | Critical |
| wmic shadowcopy delete                    | Critical |
| Mass file writes > 100/min                | Critical |
| EDR agent termination                     | Critical |

### Ransomware Playbook

| Step | Action                                    | Timeline          |
| ---- | ----------------------------------------- | ----------------- |
| 1    | Network isolate via EDR                   | Immediate         |
| 2    | Kill encryptor process tree               | < 30 detik        |
| 3    | Block C2 (firewall + DNS sinkhole)        | Immediate         |
| 4    | Check shadow copy (vssadmin list shadows) | Immediate         |
| 5    | Verify offline/immutable backup           | Immediate         |
| 6    | Memory dump before reboot                 | 5 menit           |
| 7    | Scan lateral movement (same IOC)          | 15 menit          |
| 8    | Restore from clean backup                 | After eradication |

---

## Sigma Rules

### Format Dasar

```yaml
title: <Name>
status: stable | experimental
logsource:
  product: windows
  category: process_creation | file_event | registry_event | network_connection
detection:
  selection: { Field: "value" }
  condition: selection
level: critical | high | medium | low
tags: [attack.<tactic>, attack.<technique_id>]
```

### Sigma — WMI Suspicious Parent

```yaml
title: WMI Process Create with Suspicious Parent
id: 2f8e5a9c-1b3d-4e7f-9a2b-5c3d7e8f1a2b
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    ParentImage|endswith: ['\WmiPrvSE.exe', '\wmiprvse.exe']
  filter_user:
    User: ['NT AUTHORITY\SYSTEM', 'NT AUTHORITY\LOCAL SERVICE', 'NT AUTHORITY\NETWORK SERVICE']
  filter_admin:
    Image|startswith: ['C:\Windows\System32\', 'C:\Windows\SysWOW64\']
    CommandLine|contains: "-Embedding"
  condition: selection and not filter_user and not filter_admin
level: high
tags: [attack.execution, attack.t1047]
```

### Sigma — Pastebin/Gist Download

```yaml
title: Script Download from Pastebin/GitHub Gist
status: stable
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    CommandLine|contains:
      - "pastebin.com"
      - "gist.githubusercontent.com"
      - "gist.github.com"
      - "paste.ee"
      - "rentry.co"
  condition: selection
level: high
tags: [attack.command_and_control, attack.t1105]
```

### Sigma — Office Network Connection

```yaml
title: Office Application Outbound Connection
status: stable
logsource:
  product: windows
  category: network_connection
detection:
  selection:
    Image|endswith: ['\WINWORD.EXE', '\EXCEL.EXE', '\POWERPNT.EXE', '\OUTLOOK.EXE']
  filter_internal:
    DestinationIp|cidr: ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"]
  condition: selection and not filter_internal
level: high
tags: [attack.execution, attack.t1204.002]
```

### Sigma — Unquoted Service Path

```yaml
title: Unquoted Service Path (PrivEsc)
status: experimental
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    Image|endswith: '\sc.exe'
    CommandLine|contains: "binPath="
  filter_quoted:
    CommandLine|contains: '"'
  filter_system:
    User: 'NT AUTHORITY\SYSTEM'
  condition: selection and not filter_quoted and not filter_system
level: medium
tags: [attack.privilege_escalation, attack.t1574.009]
```

---

## Live Response Procedure

### Phase 1 — Memory Acquisition

```bash
winpmem_mini_x64.exe --output memdump.raw
velociraptor.exe collect Windows.Memory.Acquisition
```

### Phase 2 — Process Tree

```bash
tasklist /v /fo csv
wmic process get Name,ProcessId,ParentProcessId,CommandLine /format:csv
```

### Phase 3 — Autoruns

```bash
autorunsc64.exe -a * -c -h -s -v -o autoruns.csv
reg query HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Run
reg query HKCU\Software\Microsoft\Windows\CurrentVersion\Run
schtasks /query /fo CSV /v | findstr "Ready"
wmic startup list full
```

### Phase 4 — Prefetch

```bash
# C:\Windows\Prefetch\*.pf — record of executed binaries
# Velociraptor:
LET p = SELECT * FROM glob(globs='C:\\Windows\\Prefetch\\*.pf')
SELECT Name, Size, ModTime FROM p
```

### Phase 5 — Event Logs

```bash
wevtutil epl Security C:\logs\security.evtx
wevtutil epl "Microsoft-Windows-Sysmon/Operational" C:\logs\sysmon.evtx
wevtutil epl "Windows PowerShell" C:\logs\powershell.evtx
wevtutil epl System C:\logs\system.evtx
```

### Phase 6 — Network

```bash
netstat -anob > connections.txt
ipconfig /displaydns > dnscache.txt
arp -a > arp_table.txt
route print > routing_table.txt
```

### Live Response Kit

| Item           | Tool                   | Priority |
| -------------- | ---------------------- | -------- |
| Memory         | WinPmem / Velociraptor | P0       |
| Process tree   | pslist                 | P0       |
| Network        | netstat -anob          | P0       |
| Autoruns       | Sysinternals Autoruns  | P1       |
| Prefetch       | Velociraptor           | P1       |
| Event logs     | wevtutil               | P1       |
| Registry hives | reg save               | P1       |
| YARA scan      | YARA                   | P2       |

---

## Correlation & FP Handling

### Alert Prioritization Matrix

Priority = Severity Teknikal + Asset Criticality + Threat Intel

| Kriteria                                  | Skor |
| ----------------------------------------- | ---- |
| **Severity:** Critical (Ransomware/LSASS) | 100  |
| High (Injection/Persistence)              | 50   |
| Medium (LOLBin)                           | 20   |
| Low                                       | 5    |
| **Asset:** Domain Controller              | 50   |
| Email/File Server                         | 30   |
| Workstation                               | 10   |
| **TI:** Known IOC match                   | 30   |
| No context                                | 0    |

**Priority:** 120-180 → P0 immediate, 80-119 → P1 high, 40-79 → P2 medium, 0-39 → P3 low.

### Common False Positives

| Pattern                      | Cause                  | Fix                       |
| ---------------------------- | ---------------------- | ------------------------- |
| AV scans trigger file events | Scheduled scans        | Exclude AV path in Sysmon |
| SCCM/PDQ deployment          | SYSTEM installers      | Filter by Company field   |
| Windows Update               | Legitimate MS activity | Filter wuauclt.exe        |
| Office DNS lookups           | Auto-update            | Threshold > 5/min         |
| Developer PowerShell         | Authorized admin       | Track by user             |

### Whitelist Strategy

**Whitelist approach:** baseline semua proses legitimate 2-4 minggu, hanya alert di luar whitelist.

```powershell
# Baseline mingguan
Get-WmiObject Win32_Process | Select Name, ExecutablePath, ProcessId,
   @{N="ParentPID";E={$_.ParentProcessId}},
   @{N="User";E={$_.GetOwner().User}}
| Export-Csv baseline_$(Get-Date -Format 'yyyy-MM-dd').csv
```

---

## Case Studies

### Case 1: SolarWinds Supply Chain (2020)

**Attribution:** APT29 (Cozy Bear / Russian SVR).

| Indicator   | Detail                                             |
| ----------- | -------------------------------------------------- |
| DLL         | SolarWinds.Orion.Core.BusinessLayer.dll — modified |
| Persistence | SolarWinds service auto-start                      |
| C2          | *.appsync-api.eu-west-1.avsvmcloud.com             |
| Beacon      | HTTP POST /WebResources/SCRIPT, 12h interval       |
| JA3         | 51c64c77e60f3980eea90869b68c58a8                   |

**Lessons:** Supply chain > signature detection. Behavioral detection (parent-child, DNS anomaly, file integrity) lebih penting. Sysmon Event 11 & 7 kritis.

### Case 2: Log4j Post-Exploitation (Dec 2021)

```
[1] LDAP: ldap://attacker:1389/Exploit.class
[2] JNDI redirect → Java class download
[3] JVM: download Cobalt Strike / PowerShell Empire
[4] Persistence: Run keys, fake "OneDrive Updater" task
[5] Post: whoami → systeminfo → net group
```

```yaml
title: Log4Shell JNDI LDAP Outbound
status: stable
logsource: { product: windows, category: network_connection }
detection: { selection: { Image|endswith: '\java.exe', DestinationPort: 1389 } }
level: critical
tags: [attack.initial_access, attack.t1190]
---
title: Suspicious Command via Java
status: experimental
logsource: { product: windows, category: process_creation }
detection:
  selection:
    ParentImage|endswith: '\java.exe'
    Image|endswith: ['\powershell.exe', '\cmd.exe']
level: high
tags: [attack.execution, attack.t1059]
```

**Lessons:** Java parent shell = red flag. LDAP 1389/389 outbound harus dimonitor.

### Case 3: Phishing-to-Beachhead

```
T+0min: WINWORD spawns cmd.exe (Sysmon E1)
T+1min: cmd.exe → C2 185.x.x.x:443 (Sysmon E3)
T+2min: notepad.exe loads malicious DLL (Sysmon E7)
T+3min: PROCESS_ACCESS ke lsass.exe (Sysmon E10)
T+5min: EDR isolate + block C2 IP
T+7min: Kill tree + remove persistence
```

**Learnings:** (1) Parent-child = sinyal paling awal, (2) Office + netconn = high-fidelity, (3) Attacker dumps creds < 3 menit, (4) SOAR diperlukan untuk response < 5 menit.

---

## Koneksi ke Vault

- [[endpoint-security]] — CPU Ring hierarchy & boot chain. Playbook fokus deteksi Ring 3 dan Ring 0.
- [[blueteam-detection-matrix]] — C2 detection per Level 0-4. Playbook berisi detection rule detail.
- [[blueteam-vs-enterprise-c2]] — Mitigasi enterprise C2. Playbook melengkapi dengan detection scenarios.
- [[ebpf-kernel-security]] — Kernel observability via eBPF sebagai detection layer alternatif.
- [[purple-team-osi-killchain]] — Kill-chain framework. Setiap detection scenario dipetakan ke fase.
- [[ids-ips-waf-nsm-comparison]] — EDR dalam konteks defense-in-depth.
- [[network-security]] — Network-layer detection melengkapi endpoint detection.

---

## References

1. [SwiftOnSecurity Sysmon Config](https://github.com/SwiftOnSecurity/sysmon-config)
2. [Sigma Rules](https://github.com/SigmaHQ/sigma)
3. [Velociraptor Docs](https://docs.velociraptor.app/)
4. [Elastic Detection Rules](https://github.com/elastic/detection-rules)
5. [MITRE ATT&CK](https://attack.mitre.org/)
6. [loldrivers.io](https://www.loldrivers.io)
7. [SolarWinds — Mandiant](https://www.mandiant.com/resources/supply-chain-analysis-solarwinds)
8. [Log4j — NCSC](https://www.ncsc.gov.uk/news/log4j-vulnerability)
9. [Volatility 3](https://volatility3.readthedocs.io/)

---

> [!tip] Bottom Line
> Kunci endpoint detection: (1) Sysmon + Windows Event Log sebagai foundation sensor termurah dan paling efektif, (2) Sigma rules untuk detection-as-code portable, (3) EDR behavioral (CrowdStrike/Elastic) untuk advanced scenarios, (4) Live response terstandardisasi siap pakai. Tanpa triage baik, EDR terbaik tenggelam dalam false positive. Detection tanpa response hanyalah noise.

_Endpoint Detection Playbook | v1.0 — 2026 | Operational | 6 detection scenarios, 15+ Sigma rules, 3 case studies_
