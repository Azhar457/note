---
title: "Comprehensive Threat Directory — Deep Dive: Taksonomi Ancaman, Teknik Eksploitasi, dan Profil Threat Actor"
tags:
  - cyber-security
  - library
aliases:
  - "comprehensive-threat-directory"
created: "2026-07-02"
updated: "2026-07-02"
status: operational
cssclasses: ""
---

# 🗂️ Comprehensive Threat Directory — Deep Dive: Taksonomi Ancaman, Teknik Eksploitasi, dan Profil Threat Actor

> Ringkasan satu-paragraf menjelaskan bahwa direktori ini merupakan kumpulan terstruktur dari ancaman siber, teknik eksploitasi (TTP), malware, dan profil threat actor global yang dapat digunakan sebagai referensi untuk threat modeling, deteksi, dan respons insiden.

> [!info] Hubungan ke Vault  
> Nota ini menyajikan pandangan tinggi dan cara menggunakan direktori yang lebih lengkap yang terdapat di `01_Library/Cyber_Security/Threat_Intel_Privacy/comprehensive-threat-directory.md`. Hubungkan ke [[threat-modeling-deepdive]] untuk penerapan dalam modeling ancaman, serta ke [[zero-trust-security]] untuk mengatur kontrol berdasarkan ancaman yang teridentifikasi.

---

## Daftar Isi

- [[#Pengantar]]
- [[#Struktur Direktori]]
- [[#Kategori Utama]]
- [[#Cara Menggunakan dalam Threat Modeling]]
- [[#Contoh Entri]]
- [[#Koneksi ke Vault]]
- [[#Referensi]]

---

## Pengantar

Dalam operasi keamanan siber, memahami lawan adalah langkah pertama. _Comprehensive Threat Directory_ (CTD) berusaha menyatukan berbagai sumber taksonomi seperti MITRE ATT&CK, CAPEC, CWE, VERIS, serta intel dari vendor dan komunitas menjadi satu referensi yang mudah diakses dan dapat ditelusuri melalui wiki-link di vault Obsidian.

CTD memiliki 3 komponen utama:

1. **Taksonomi Ancaman**: Pemetaan struktural ancaman berdasarkan lapisan OSI, CPU Ring, dan vector attack.
2. **TTPs (Tactics, Techniques, Procedures)**: Katalog eksplorasi teknik eksploitasi dengan ID standar (mis: T1059.001), deteksi, dan mitigasi.
3. **Profil Threat Actor**: Analisis demografi dan taktik operasional aktor ancaman (APT, penjahat, hacktivist).

---

## Struktur Direktori

File lengkap berada di:

```
01_Library/Cyber_Security/Threat_Intel_Privacy/comprehensive-threat-directory.md
```

### Visualisasi Lapisan Ancaman

```text
OSI Layer 7 (Application)       ↔ CPU Ring 3 (User Space)
    ↓                                ↓
OSI Layer 5-6 (Session/Presentation) ↔ CPU Ring 2 (OS Services)
    ↓                                ↓
OSI Layer 4 (Transport)           ↔ CPU Ring 1 (Driver Stack)
    ↓                                ↓
OSI Layer 1-3 (Physical/Network)  ↔ CPU Ring 0 (Kernel)
```

### Tabel Klasifikasi Ancaman

Contoh implementasi dalam JSON untuk sistem otomatisasi ancaman:

```json
{
  "id": "T1562.001",
  "name": "Browser Exec",
  "tactic": ["Execution", "Persistence", "Privilege Escalation"],
  "layer": "L7",
  "detection": {
    "sysmon": {
      "event_id": 1,
      "command_line": "\\browser.exe --flag='--disable-encryption'"
    },
    "edr": {
      "log_type": "ProcessCreation",
      "keywords": ["browser.exe", "disable-encryption"]
    }
  }
}
```

---

## Kategori Utama

### 1. **Physical & Hardware Layer**

- **Contoh Ancaman**:
  - Cold boot attack pada memori RAM
  - Firmware rootkit di BIOS/UEFI
- **Deteksi Rekomendasi**:

```bash
# Mendeteksi perubahan firmware menggunakan tripwire
sudo apt install tripwire
tripwire -m d --config /etc/tripwire/twpol.txt
tripwire -m c --config /etc/tripwire/twpol.txt
```

### 2. **Network & Routing**

#### Exploit VLAN Hopping

```python
# Skrip pemindaian VLAN menggunakan scapy
from scapy.all import Ether, Dot1Q

def vlan_hopping_test():
    packets = sniff(count=100)
    for p in packets:
        if p.haslayer(Dot1Q):
            print(f"Traced VLAN tag: {p[Dot1Q].vlan}")
            if p[Dot1Q].vlan not in [10, 20]:  # VLAN yang diizinkan
                alert(f"Abnormal VLAN {p[Dot1Q].vlan} detected")
```

### 3. **Operating System & Kernel**

#### Deteksi Kernel Rootkit

```bash
# Deteksi menggunakan rkhunter
sudo apt install rkhunter
sudo rkhunter --check --sk --cronjob
# Output: [ Warning ] Possible rootkit detection in /dev
```

### 4. **Application & Logic**

#### Deteksi SQL Injection

Script reguler ekspresi untuk deteksi awal:

```powershell
# PowerShell regex scan untuk parameter SQL Injection
$inputQuery = $_.Request.RawUrl
$malformed = $inputQuery -match "';|UNION SELECT|xp_|xp_"
if ($malformed) {
    Write-Output "Suspicious query $inputQuery"
}
```

### 5. **Session & Presentation**

#### Eksploitasi TLS Downgrade Attack

```bash
# Test TLS 1.0 support with ssllabs
openssl s_client -connect example.com:443 -tls1
# Expected response: Unsupported protocol error
```

### 6. **Human & Social**

#### Analisis Email Phishing

Contoh penanda ancaman dalam log EDR:

```json
{
  "type": "suspicious_email_attachment",
  "details": {
    "sender": "urgent@bank-fake.com",
    "subject": "Verification Required",
    "attachment": "invoice.exe"
  },
  "mitigation": {
    "action": "block_sender",
    "rule": "phishing_attacks"
  }
}
```

---

## Cara Menggunakan dalam Threat Modeling

### 1. **Modeling Threat pada Web App Financial**

Contoh skenario threat modeling:

```mermaid
graph TD
    A[User] -->|HTTPS| B[API Gateway]
    B -->|Encrypted Query| C[Database]
    C -->|Log to SIEM| D[Security Stack]
    subgraph Attacks
        B -->|SS
```
