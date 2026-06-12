# 🛡️ Blue Team Playbook — Melawan Enterprise C2 Infrastructure

> **Dokumen ini dibuat untuk defensive security team.** Setiap teknik mitigasi di sini dirancang untuk melawan infrastruktur C2 enterprise-grade yang menggunakan multi-tier architecture, custom implant, dan advanced evasion.

---

## 1. Melawan Multi-Tier Redirector (Nginx + Cloudflare)

### Kenapa Susah Dideteksi

Traffic attacker masuk lewat Cloudflare/CDN dulu sebelum ke C2 asli. Block IP cuma block redirector, bukan core infrastructure. TLS 1.3 + domain legitimate membuat traffic keliatan normal.

### Mitigasi

**Network Layer**

- Deploy **SSL/TLS Inspection Proxy** (Zscaler, Palo Alto, Squid) — decrypt traffic sebelum keluar jaringan
- **Passive DNS Monitoring** — track domain muda (< 30 hari), low Alexa rank, resolving ke Cloudflare/shared hosting
- **Threat Intel Feed** otomatis — integrasikan URLhaus, abuse.ch, Emerging Threats ke firewall

**Detection Rule (Zeek)**

```zeek
# Deteksi domain baru yang tidak ada di baseline
event dns_request(c: connection, msg: dns_msg, query: string, qtype: count, qclass: count) {
    if (query !in known_domains && /[a-z0-9]{8,}\./ in query)
        NOTICE([$note=Notice::ACTION_LOG, $msg=fmt("Suspicious new domain: %s", query)]);
}
```

**Sigma Rule — Suspicious Cloudflare-Fronted C2**

```yaml
title: Outbound HTTPS to Recently Registered Domain
status: experimental
logsource:
  category: proxy
detection:
  selection:
    c-uri-scheme: https
    cs-host|re: '^[a-z0-9\-]{8,}\.(xyz|top|club|online|site|info)$'
  condition: selection
falsepositives:
  - Legitimate new SaaS tools
level: medium
```

---

## 2. Melawan Beaconing (Check-in Reguler + Jitter)

### Kenapa Susah Dideteksi

Interval 30–60 detik dengan jitter membuat traffic keliatan tidak mechanical. Pakai HTTPS ke domain legitimate-looking.

### Mitigasi

**SIEM Query (Splunk)**

```spl
index=proxy_logs
| stats count, avg(bytes_out), stdev(interval) as jitter by src_ip, dest_host
| where count > 20 AND jitter < 15
| sort - count
```

**Zeek Beacon Detection**

```zeek
# Hitung connection frequency per destination
redef record Conn::Info += {
    beacon_score: double &default=0.0;
};
```

**Sigma Rule — Beaconing Pattern**

```yaml
title: Potential C2 Beaconing via HTTP/S
logsource:
  category: proxy
detection:
  selection:
    EventID: network_connection
  timeframe: 1h
  condition: selection | count() by DestinationIp, SourceIp > 25
  filter:
    DestinationIp|cidr:
      - "8.8.8.8/32"
      - "1.1.1.1/32"
falsepositives:
  - Telemetry software, update clients
level: high
```

---

## 3. Melawan Registry Persistence

### Kenapa Susah Dideteksi

`HKCU\...\Run` tidak butuh admin privilege. Jalan otomatis setiap user login. Bisa dibuat oleh proses user-level mana pun.

### Mitigasi

**Endpoint Hardening**

- Deploy **Autoruns baseline** — bandingkan terhadap golden image setiap minggu
- **AppLocker/WDAC** — whitelist executable yang boleh jalan dari path non-standard

**Sysmon Config (Event ID 13)**

```xml
<RegistryEvent onmatch="include">
  <TargetObject condition="contains">\CurrentVersion\Run</TargetObject>
  <TargetObject condition="contains">\CurrentVersion\RunOnce</TargetObject>
  <TargetObject condition="contains">\Winlogon</TargetObject>
</RegistryEvent>
```

**Sigma Rule — Run Key Persistence**

```yaml
title: Suspicious Registry Run Key Created by Non-Standard Process
logsource:
  product: windows
  category: registry_set
detection:
  selection:
    EventID: 13
    TargetObject|contains:
      - '\SOFTWARE\Microsoft\Windows\CurrentVersion\Run'
      - '\SOFTWARE\Microsoft\Windows\CurrentVersion\RunOnce'
  filter_legit:
    Image|startswith:
      - 'C:\Program Files\'
      - 'C:\Program Files (x86)\'
      - 'C:\Windows\System32\'
  condition: selection and not filter_legit
level: high
tags:
  - attack.persistence
  - attack.t1547.001
```

---

## 4. Melawan WMI Event Subscription Persistence

### Kenapa Susah Dideteksi

WMI subscription survive reboot, berjalan di background tanpa proses yang visible, sulit terdeteksi tanpa telemetri khusus.

### Mitigasi

**Sysmon Event ID 19, 20, 21**

```xml
<WmiEvent onmatch="include">
  <Operation condition="is">Created</Operation>
</WmiEvent>
```

**Sigma Rule**

```yaml
title: WMI Event Subscription Created
logsource:
  product: windows
  category: wmi_event
detection:
  selection:
    EventID:
      - 19
      - 20
      - 21
  condition: selection
level: high
tags:
  - attack.persistence
  - attack.t1546.003
```

**Remediation Script**

```powershell
# Audit semua WMI subscription
Get-WMIObject -Namespace root\subscription -Class __EventFilter | Select Name, Query
Get-WMIObject -Namespace root\subscription -Class __EventConsumer
Get-WMIObject -Namespace root\subscription -Class __FilterToConsumerBinding

# Remove suspicious subscription
$filter = Get-WMIObject -Namespace root\subscription -Class __EventFilter -Filter "Name='SuspiciousName'"
$filter.Delete()
```

---

## 5. Melawan ETW/AMSI Bypass

### Kenapa Susah Dideteksi

Kalau ETW di-patch di memory, EDR kehilangan visibility ke PowerShell dan CLR activity. AMSI bypass memungkinkan malicious script lolos dari AV scanning.

### Mitigasi

**Kernel-Level Protection**

- Deploy EDR dengan **kernel callbacks** (CrowdStrike Falcon, Cortex XDR, SentinelOne) — tidak bisa di-bypass dari userland
- Enable **HVCI (Hypervisor-Protected Code Integrity)** di Windows Security settings

**Deteksi Patching**

```yaml
title: Suspicious Memory Write to Security DLL
logsource:
  product: windows
  category: process_access
detection:
  selection:
    EventID: 10
    TargetImage|endswith:
      - '\amsi.dll'
      - '\ntdll.dll'
    GrantedAccess: "0x40"
  condition: selection
level: critical
tags:
  - attack.defense_evasion
  - attack.t1562.001
```

**PowerShell Logging**

```powershell
# Enable Script Block Logging
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ScriptBlockLogging" `
  -Name "EnableScriptBlockLogging" -Value 1

# Enable Module Logging
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell\ModuleLogging" `
  -Name "EnableModuleLogging" -Value 1
```

---

## 6. Melawan BYOVD (Bring Your Own Vulnerable Driver)

### Kenapa Susah Dideteksi

Driver yang sudah signed bisa di-load oleh Windows, lalu dieksploitasi untuk Ring 0 access dan kill EDR process dari kernel level.

### Mitigasi

**Preventive**

- Enable **HVCI** — block loading driver yang tidak memenuhi code integrity policy
- Maintain **driver blocklist** dari [loldrivers.io](https://www.loldrivers.io)
- Enable **Secure Boot + TPM**

**Sysmon Event ID 6 — Driver Load**

```xml
<DriverLoad onmatch="include">
  <Signature condition="is not">Microsoft Windows</Signature>
  <Signature condition="is not">Microsoft Corporation</Signature>
</DriverLoad>
```

**Sigma Rule**

```yaml
title: Known Vulnerable Driver Loaded
logsource:
  product: windows
  category: driver_load
detection:
  selection:
    EventID: 6
    Hashes|contains:
      - "SHA256=aca3081cf0289371a9492fe068a5da7e" # contoh hash driver vulnerable
  condition: selection
level: critical
tags:
  - attack.privilege_escalation
  - attack.t1068
```

---

## 7. Melawan Data Exfiltration via HTTPS/Cloud

### Kenapa Susah Dideteksi

Upload ke domain yang mimic CDN/Slack/OneDrive, encrypted, volume kecil tapi konsisten sulit dibedakan dari traffic normal.

### Mitigasi

**DLP (Data Loss Prevention)**

- Pasang DLP di proxy layer — inspect content-type, flag upload volume anomali
- **CASB (Cloud Access Security Broker)** untuk visibility ke traffic ke SaaS (OneDrive, Slack, GitHub)

**Network Anomaly Detection**

```spl
index=proxy_logs action=upload
| stats sum(bytes_out) as total_upload by src_ip, dest_host, _time span=1h
| where total_upload > 52428800
| sort - total_upload
```

**DNS Exfil Detection (Zeek)**

```zeek
# Flag high-entropy subdomain (indikasi DNS tunneling)
event dns_request(c: connection, msg: dns_msg, query: string, ...) {
    local entropy = calculate_entropy(query);
    if (entropy > 3.5 && |query| > 40)
        NOTICE([$note=Notice::ACTION_LOG, $msg=fmt("High entropy DNS query: %s", query)]);
}
```

---

## 8. Melawan RAG Poisoning via SharePoint/Confluence

### Kenapa Berbahaya

Implant upload dokumen berisi prompt injection ke internal knowledge base. Internal LLM agent yang menggunakan RAG bisa ter-compromise dan bocorkan data atau jalankan perintah attacker.

### Mitigasi

**Document Scanning**

- Scan semua dokumen yang di-upload ke SharePoint/Confluence dengan pattern matching untuk instruksi mencurigakan
- Flag dokumen yang mengandung: `ignore previous`, `you are now`, `disregard`, `new instruction`

**AI/RAG Pipeline Hardening**

- Implement **input sanitization** sebelum dokumen masuk ke vector database
- **Privilege separation** — LLM agent hanya boleh akses data sesuai permission user yang query
- **Output monitoring** — log dan review semua response dari internal AI yang mengandung sensitive keywords

**SharePoint Audit**

```powershell
# Monitor upload dari endpoint yang tidak biasa
Search-UnifiedAuditLog -StartDate (Get-Date).AddDays(-1) `
  -EndDate (Get-Date) `
  -Operations FileUploaded `
  | Where-Object {$_.AuditData -match "suspicious_pattern"} `
  | Export-Csv audit_log.csv
```

---

## 9. IR Flow — Kalau C2 Aktif Terdeteksi

```
[1] ALERT FIRED
        ↓
[2] TRIAGE — Konfirmasi true positive
    - Cek beacon pattern di proxy logs
    - Validasi process tree di EDR
        ↓
[3] CONTAIN — Jangan shutdown dulu!
    - Network isolate via EDR (preserve memory)
    - Block C2 domain/IP di: Firewall + DNS Sinkhole + Proxy
        ↓
[4] COLLECT EVIDENCE
    - Memory dump (Volatility, WinPmem)
    - Disk image jika diperlukan
    - Export relevant logs (Sysmon, Windows Event, Proxy)
        ↓
[5] ANALYZE
    - Kapan implant pertama masuk? (patient zero)
    - Lateral movement ke host mana saja?
    - Data apa yang di-exfil?
        ↓
[6] ERADICATE
    - Hapus semua persistence points (registry, WMI, scheduled task, driver)
    - Cek SEMUA host yang pernah connect ke C2 yang sama
        ↓
[7] RECOVER
    - Rotate SEMUA credentials yang aktif selama window kompromi
    - Rebuild host dari golden image jika diperlukan
        ↓
[8] POST-INCIDENT
    - Update detection rules berdasarkan TTP yang ditemukan
    - Purple team exercise validasi coverage
    - Threat intel sharing (MISP internal)
```

---

## 10. Tool Stack Rekomendasi

| Layer           | Tool                                           |
| --------------- | ---------------------------------------------- |
| EDR             | CrowdStrike Falcon / SentinelOne / Cortex XDR  |
| SIEM            | Splunk / Elastic Security / Microsoft Sentinel |
| NDR             | Zeek + Suricata / Darktrace                    |
| DNS             | Pi-hole + RPZ / Infoblox                       |
| Proxy/DLP       | Zscaler / Palo Alto Prisma                     |
| Threat Intel    | MISP + abuse.ch + URLhaus + loldrivers.io      |
| Forensics       | Volatility + Velociraptor + Autopsy            |
| Detection Rules | Sigma (portable ke semua SIEM)                 |

---

_Dokumen ini untuk internal blue team use. Versi: 1.0 — 2026_
