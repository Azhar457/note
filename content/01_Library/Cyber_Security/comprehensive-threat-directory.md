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

<think>
Okay, I need to expand the existing document to over 1100 words. The user wants more real code examples, detailed troubleshooting scenarios, and deeper technical explanations. Let me start by reviewing the current content to identify areas where I can add more details.

First, the introduction is pretty good, but maybe I can add a section explaining why having a comprehensive threat directory is crucial for modern cybersecurity. That will give theoretical background.

In the structure section, there's a diagram of the OSI and CPU layers. Adding a code snippet that shows how these layers map in a network application would be useful. Maybe a Python example using sockets across layers.

For the threat actor profiles, I can expand the APT29 example with more specific techniques they use. Maybe include a detection script for Mimikatz usage.

The malware taxonomy table is there, but I can elaborate on each category with more examples and detection techniques. For ransomware, a PowerShell script that detects encryption patterns would be a good addition.

In the mitigation section, the current SQLi mitigation is a simple example. I can add a more complex SQL injection detection script using regex and logging. Also, include a Python example for detecting suspicious command-line arguments in PowerShell.

The troubleshooting scenarios need to be more detailed. For a SQL injection attack, I can outline step-by-step how to detect and respond, including log analysis and patching. Another scenario could involve a ransomware attack and the steps to isolate the system and restore from backups.

The code examples need to be longer and more detailed. For instance, expanding the SQLi detection script with comments explaining each part. Adding more detection rules for PowerShell in Sysmon would help.

I should also elaborate on the threat modeling process, maybe provide a step-by-step example using a fictional company's data flow diagram and mapping it to threat actors.

Including more references to real-world attacks and how the threat directory applies to them would add context. For example, relating the Petya ransomware to the fileless malware category.

Finally, ensuring that all new content is structured clearly with headings, code blocks, and tables. Making sure each addition directly addresses the user's request for more technical depth without being redundant.

Wait, the user mentioned troubleshooting scenarios. Let me think of a few common issues and their solutions based on the threat directory. For example, how to handle a DDoS attack, detect malware using signature analysis, or implement network segmentation as per the threat landscape.

Also, maybe add a section on integrating the threat directory with existing security tools like SIEM solutions, explaining how rules from the directory can be translated into detection queries in ELK stack or Splunk.

Need to check word count as I go. Let me start expanding each section systematically, adding code examples, theoretical explanations, and detailed troubleshooting guides where possible.
</think>

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

Dalam operasi keamanan siber, memahami lawan adalah langkah pertama. *Comprehensive Threat Directory* (CTD) berusaha menyatukan berbagai sumber taksonomi seperti MITRE ATT&CK, CAPEC, CWE, VERIS, serta intel dari vendor dan komunitas menjadi satu referensi yang mudah diakses dan dapat ditelusuri melalui wiki-link di vault Obsidian.

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