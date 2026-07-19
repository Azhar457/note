---
title: "Blueteam Detection Matrix"
tags:
  - cyber-security
  - endpoint-detection
  - library
aliases:
  - "blueteam-detection-matrix"
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

# 🛡️ Blue Team Detection Matrix — C2 Level 0 sampai Level 4

> **Panduan ini memetakan setiap level C2 yang mungkin dihadapi tim, beserta deteksi, mitigasi, dan IR response yang sesuai.** Semakin tinggi level, semakin dalam deteksi harus masuk ke kernel dan firmware layer.

---

## Level 0 — Basic C2 (Script Kiddie / PoC)

### Karakteristik Attacker

- Single VPS, framework publik (Sliver, Empire, Havoc, Covenant)
- Reverse TCP/HTTP biasa, plain atau TLS sederhana
- Persistence basic: registry Run key, cron job
- Tidak ada evasion

### Deteksi — Relatif Mudah

**Yang harus dicari:**

- Koneksi keluar ke VPS asing di port non-standard (4444, 8080, 8443)
- Proses yang spawn reverse shell (cmd.exe/bash sebagai child dari proses aneh)
- Registry Run key baru dari path non-standard

**Sigma Rule — Reverse Shell**

```yaml
title: Suspicious Reverse Shell Spawned
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    ParentImage|endswith:
      - '\winword.exe'
      - '\excel.exe'
      - '\powerpnt.exe'
      - '\outlook.exe'
    Image|endswith:
      - '\cmd.exe'
      - '\powershell.exe'
      - '\wscript.exe'
  condition: selection
level: high
tags:
  - attack.execution
  - attack.t1059
```

**Firewall Rule:**

- Block outbound ke IP/ASN yang bukan whitelist
- Alert pada port non-standard (selain 80, 443, 53)

### IR Response Level 0

1. Isolate host via EDR
2. Kill proses implant
3. Hapus persistence (Run key / cron)
4. Rotate user credential
5. Scan lateral movement (apakah sudah spread?)

---

## Level 1 — Stealth C2 (Operational)

### Karakteristik Attacker

- Domain fronting via Cloudflare/Fastly
- TLS encryption + malleable C2 profile
- Multiple redirectors di cloud provider berbeda
- Implant dengan sleep + jitter
- Basic EDR bypass: direct syscall, shellcode injection

### Deteksi — Butuh SSL Inspection

**Yang harus dicari:**

- Domain baru yang resolve ke Cloudflare/CDN tapi tidak dikenal
- JA3 fingerprint anomali (bukan browser/OS standard)
- Proses inject ke proses lain (OpenProcess + WriteProcessMemory)

**Zeek JA3 Monitoring**

```zeek
event ssl_client_hello(c: connection, version: count, record_version: count,
                       possible_ts: time, client_random: string, session_id: string,
                       ciphers: index_vec, comp_methods: index_vec) {
    local ja3 = compute_ja3(c);
    if (ja3 !in known_ja3_whitelist)
        NOTICE([$note=Notice::ACTION_LOG,
                $msg=fmt("Unknown JA3: %s from %s", ja3, c$id$orig_h)]);
}
```

**Sigma Rule — Process Injection**

```yaml
title: Suspicious Process Memory Write (Potential Injection)
logsource:
  product: windows
  category: process_access
detection:
  selection:
    EventID: 10
    GrantedAccess|contains:
      - "0x1F0FFF"
      - "0x1F1FFF"
      - "0x40"
    TargetImage|endswith:
      - '\svchost.exe'
      - '\explorer.exe'
      - '\lsass.exe'
  condition: selection
level: high
tags:
  - attack.defense_evasion
  - attack.t1055
```

**Hardening:**

- Enable **PPL (Protected Process Light)** untuk LSASS
- Deploy **Credential Guard**
- SSL Inspection wajib di semua proxy egress

### IR Response Level 1

1. Dump memory sebelum isolasi
2. Analisis JA3 fingerprint dari C2 — cari host lain yang connect ke fingerprint sama
3. Trace domain fronting: cari tahu domain asli via passive DNS
4. Scan seluruh environment untuk implant yang sama

---

## Level 2 — Resilient C2 (Red Team Professional)

### Karakteristik Attacker

- 3-tier architecture: redirector → staging → master C2
- Domain rotation tiap 24 jam, auto Let's Encrypt
- DNS over HTTPS (DoH) / DNS over TLS (DoT) sebagai fallback
- Fileless execution
- MBR Bootkit / UEFI Bootkit
- Kernel rootkit (Ring 0)

### Deteksi — Butuh Kernel Visibility

**Yang harus dicari:**

- DoH traffic ke resolver non-corporate (1.1.1.1, 8.8.8.8 via port 443)
- Domain yang sering rotate (TTL rendah, IP berubah setiap hari)
- Anomali di MBR/boot sector
- Driver yang baru di-load tanpa software deployment

**Block DoH di Luar Corporate Resolver**

```bash
# Firewall rule — block DoH ke non-corporate resolver
iptables -A OUTPUT -p tcp --dport 443 -d 1.1.1.1 -j DROP
iptables -A OUTPUT -p tcp --dport 443 -d 8.8.8.8 -j DROP
# Force semua DNS ke internal resolver
iptables -A OUTPUT -p udp --dport 53 ! -d 10.0.0.53 -j REDIRECT --to-port 53
```

**MBR Integrity Monitoring**

```powershell
# Baseline MBR hash
$mbr = (New-Object System.IO.BinaryReader([System.IO.File]::Open('\\.\PhysicalDrive0',
    [System.IO.FileMode]::Open,
    [System.IO.FileAccess]::Read,
    [System.IO.FileShare]::ReadWrite))).ReadBytes(512)
$hash = [System.BitConverter]==ToString([System.Security.Cryptography.SHA256]==Create().ComputeHash($mbr))
Write-Output "MBR Hash: $hash"

# Jalankan sebagai scheduled task harian, alert jika hash berubah
```

**Sigma Rule — Suspicious Driver Load**

```yaml
title: Unsigned or Rare Driver Loaded
logsource:
  product: windows
  category: driver_load
detection:
  selection:
    EventID: 6
  filter_signed:
    SignatureStatus: "Valid"
    Signed: "true"
    Company|startswith:
      - "Microsoft"
      - "Intel"
      - "NVIDIA"
      - "AMD"
  condition: selection and not filter_signed
level: high
tags:
  - attack.persistence
  - attack.t1547.006
```

**Hardening:**

- Enable **Secure Boot** di BIOS
- Enable **HVCI** (Hypervisor-Protected Code Integrity)
- Deploy **TPM 2.0** untuk boot integrity measurement
- Gunakan **EDR dengan kernel-level visibility**

### IR Response Level 2

1. Jangan boot ulang host yang suspect bootkit — preserve state
2. Gunakan forensic bootable USB untuk image disk
3. Check boot sector integrity (hash MBR/VBR vs baseline)
4. Jika UEFI rootkit suspect: flash BIOS dari vendor resmi
5. Rebuild dari scratch jika terkontaminasi

---

## Level 3 — Enterprise C2 (APT Grade)

### Karakteristik Attacker

- Full multi-platform implant (Windows, Linux, macOS, Android)
- RAG Poisoning via SharePoint/Confluence
- LLM exfiltration via internal AI tools
- Living-off-the-Land (LOLBins)
- Automated failover jika satu C2 cluster down
- Self-destruct + anti-forensic (timestomp, log wipe)

### Deteksi — Butuh Behavioral Analysis

**Yang harus dicari:**

- LOLBin abuse: certutil, mshta, regsvr32, rundll32 dengan argumen aneh
- Upload dokumen ke SharePoint dari endpoint yang tidak biasa
- LLM agent internal mengeluarkan response yang anomali
- Log gaps (indikasi log wipe)

**Sigma Rule — LOLBin Abuse**

```yaml
title: Suspicious Certutil Usage for Download
logsource:
  product: windows
  category: process_creation
detection:
  selection:
    Image|endswith: '\certutil.exe'
    CommandLine|contains:
      - "-urlcache"
      - "-decode"
      - "-encode"
      - "http"
  condition: selection
level: high
tags:
  - attack.defense_evasion
  - attack.t1218
```

**Sigma Rule — Timestomping**

```yaml
title: File Timestomp via PowerShell or Touch
logsource:
  product: windows
  category: process_creation
detection:
  selection_ps:
    Image|endswith: '\powershell.exe'
    CommandLine|contains: "LastWriteTime"
  selection_touch:
    Image|endswith: '\touch.exe'
  condition: selection_ps or selection_touch
level: medium
tags:
  - attack.defense_evasion
  - attack.t1070.006
```

**RAG Poisoning Detection**

```python
# Pattern matching untuk dokumen yang di-upload ke SharePoint
SUSPICIOUS_PATTERNS = [
    r"ignore (previous|prior|all) instructions",
    r"you are now",
    r"disregard (your|all|previous)",
    r"new (system|core) instruction",
    r"override (safety|policy|rules)",
    r"$$SYSTEM$$",
    r"$$INST$$",
]

def scan_document(content: str) -> bool:
    import re
    for pattern in SUSPICIOUS_PATTERNS:
        if re.search(pattern, content, re.IGNORECASE):
            return True  # Flag for review
    return False
```

**Log Integrity Monitoring**

```bash
# Detect log gaps (indikasi wipe)
# Expected: log setiap 5 menit
# Alert jika ada gap > 15 menit
python3 - <<'EOF'
import subprocess, datetime
result = subprocess.run(['wevtutil', 'qe', 'Security', '/count:1000', '/f:xml'],
                       capture_output=True, text=True)
# Parse timestamps dan cari gap
EOF
```

**Hardening:**

- **Forward semua log ke SIEM external** segera setelah dibuat — attacker tidak bisa hapus yang sudah di-forward
- Immutable logging (WORM storage)
- AI pipeline: sanitize semua dokumen sebelum masuk RAG

### IR Response Level 3

1. Prioritas: identifikasi semua asset yang terekspos ke RAG yang terpoisoned
2. Purge dan rebuild vector database dari dokumen yang sudah diverifikasi bersih
3. Audit semua LLM agent response dalam window kompromi
4. Trace implant ke semua platform (Windows, Linux, macOS)
5. Assume credentials compromised — mass rotation

---

## Level 4 — Nation-State C2

### Karakteristik Attacker

- Supply chain compromise (update pipeline)
- SMM Rootkit / Intel ME implant / UEFI persistent
- Polymorphic implant (signature berubah tiap eksekusi)
- C2 via legitimate SaaS (GitHub Issues, Notion, Discord)
- Kerberos Golden/Silver Ticket
- RF beacon / IMSI catcher (physical layer)
- Automated blue team deception (fake logs, honey tokens)

### Realita Deteksi Level Ini

Level ini **tidak bisa dicegah 100%** di endpoint. Fokus bergeser ke:

- **Assume breach posture** — assume attacker sudah di dalam
- **Blast radius reduction** — batasi dampak kalau sudah masuk
- **Detection via anomaly** — bukan signature

**Deteksi SaaS C2 (GitHub/Notion/Discord)**

```yaml
title: Suspicious Process Communicating with SaaS C2
logsource:
  category: proxy
detection:
  selection:
    cs-host|contains:
      - "api.github.com"
      - "api.notion.so"
      - "discord.com/api"
  filter_legit:
    cs-username|contains:
      - "developer"
      - "devops"
  suspicious_process:
    cs-user-agent|contains:
      - "Go-http-client"
      - "python-requests"
      - "curl"
  condition: selection and suspicious_process and not filter_legit
level: high
```

**Kerberos Golden/Silver Ticket Detection**

```yaml
title: Kerberos Ticket with Abnormal Lifetime
logsource:
  product: windows
  service: security
detection:
  selection:
    EventID: 4769
    TicketEncryptionType: "0x17" # RC4 — legacy, sering dipakai attacker
  filter_normal:
    ServiceName|endswith: "$"
  condition: selection and not filter_normal
level: high
tags:
  - attack.credential_access
  - attack.t1558.001
```

**Honey Token Strategy**

```powershell
# Deploy fake credentials di registry — alert kalau ada yang akses
$regPath = "HKLM:\SOFTWARE\FakeCredentials"
New-Item -Path $regPath -Force
Set-ItemProperty -Path $regPath -Name "DBPassword" -Value "HoneyToken_SuperSecret123"
# Configure audit policy untuk alert saat key ini dibaca
auditpol /set /subcategory:"Registry" /success:enable /failure:enable
```

**Firmware Integrity**

- Enroll ke **Microsoft UEFI CA** dan aktifkan Secure Boot enforcement
- Monitor **Intel ME firmware version** — alert jika berubah di luar patch cycle
- Deploy **platform attestation** via TPM (Azure Attestation, AWS Nitro)

**Supply Chain Defense**

- **Software bill of materials (SBOM)** untuk semua software internal
- Verifikasi signature semua update sebelum deploy
- Isolated update staging environment — test dulu sebelum production
- Monitor network traffic dari update server (volume, destination, timing)

### IR Response Level 4

1. **Activate full incident response retainer** — ini bukan kerjaan SOC biasa
2. Engage external IR firm (Mandiant, CrowdStrike Services, dll)
3. Asumsi seluruh Active Directory compromised — Kerberos ticket reset (krbtgt password 2x)
4. Audit firmware di semua server critical
5. Hardware replacement jika ME/BIOS implant dikonfirmasi
6. Law enforcement notification (jika nation-state, ada implikasi legal)

---

## Summary Matrix

| Level | Nama          | Tool Deteksi Utama           | Kesulitan Deteksi | Waktu Respons |
| ----- | ------------- | ---------------------------- | ----------------- | ------------- |
| 0     | Basic C2      | Firewall + basic EDR         | Mudah             | < 1 jam       |
| 1     | Stealth C2    | SSL Inspection + JA3         | Sedang            | 1–4 jam       |
| 2     | Resilient C2  | Kernel EDR + MBR monitor     | Tinggi            | 4–24 jam      |
| 3     | Enterprise C2 | SIEM + Behavioral + RAG scan | Sangat Tinggi     | 1–7 hari      |
| 4     | Nation-State  | Assume breach + Attestion    | Ekstrem           | Minggu–bulan  |

---

## Prinsip Umum Blue Team

1. **Log everything, forward immediately** — attacker yang wipe log lokal tidak bisa wipe SIEM eksternal
2. **Assume breach** — selalu desain kontrol dengan asumsi attacker sudah di dalam
3. **Least privilege everywhere** — implant yang dapet user token biasa harus ketemu banyak hambatan
4. **Defense in depth** — tidak ada single point of failure di sisi defensive
5. **Purple team regularly** — validasi detection coverage sebelum attacker yang memvalidasinya

---

## Tool Stack per Level

| Level | Prevention                       | Detection                           | Response      |
| ----- | -------------------------------- | ----------------------------------- | ------------- |
| 0–1   | AppLocker, Firewall              | Sysmon, Basic SIEM                  | EDR Isolate   |
| 2     | HVCI, Secure Boot                | Kernel EDR, MBR Monitor             | Forensic Boot |
| 3     | Immutable Logging, RAG Sanitizer | Behavioral Analytics, Canary Tokens | Full IR       |
| 4     | Platform Attestation, SBOM       | Anomaly Detection, Honey Tokens     | Retainer + LE |

---

_Dokumen ini untuk internal blue team use. Versi: 1.0 — 2026_
