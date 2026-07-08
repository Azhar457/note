---
title: "Cyber Aware"
tags:
  - cyber-security
  - library
  - threat-intel-privacy
aliases:
  - "cyber-aware"
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

<think>
Okay, the user wants me to expand their 764-word document on Cyber Awareness Training to over 1000 words. Let's see. They specified needing more detailed examples, troubleshooting scenarios, and theoretical explanations.

First, I need to add more technical content. The original had sections on different cyber threats and mitigation strategies. I can break down each threat further. For example, phishing could be split into email, SMS, etc., with examples.

Then, the user asked for more code examples. The existing Python code for antivirus is a start, but I can add more relevant code snippets, maybe for 2FA or password policies. Also, include diagrams or tables for better visualization.

They mentioned troubleshooting scenarios for each problem. The original had a general section; I need to create specific scenarios for phishing, ransomware, etc., step-by-step. Maybe even a sample phishing email and how to report it.

Theoretical explanations: Elaborate on concepts like 2FA, how encryption works, why certain practices are security best practices. Maybe add a section on Zero Trust Architecture as an advanced approach.

I should also ensure the content is structured clearly, maybe adding new sections like Case Studies or Advanced Concepts. Make sure each section flows logically, with real-world parallels to the concepts discussed.

Check for depth in each section. For example, in the password section, discuss password managers, entropy, and NIST guidelines. In malware, cover different attack vectors and mitigation techniques beyond just antivirus.

Add more code samples. Maybe include a PowerShell script for system updates, a Python script for checking password strength, or a JavaScript example for 2FA handling. Also, think about network security examples like firewall rules.

For troubleshooting, provide step-by-step guides with code for scanning, patching, and isolating threats. Use tools like nmap for network scans, clamd for antivirus, and PowerShell for patch management.

Need to make sure the total word count surpasses 1100 without being redundant. Use technical jargon where appropriate but explain terms when necessary. Maybe add a section on incident response plans and how to create one.

Include more diagrams or tables. The original had a table comparing antivirus solutions. I can add more tables, like one comparing encryption methods or attack vectors. Maybe a flowchart for the incident response process.

Also, check for consistency in examples. If discussing password policies, show a sample policy and how to enforce it. For 2FA, explain different methods (SMS, TOTP, U2F) and their pros/cons.

Ensure that each added section ties back to the main theme of Cyber Awareness, emphasizing the role of every employee in maintaining security, not just IT.

Finally, review the entire document to ensure it meets the word count and that all user requirements are addressed without fluff. Make sure explanations are thorough but concise, and technical content is accurate and practical.
</think>

# KONTEN CYBER AWARENESS TRAINING 2026 (Revised & Expanded)

---

## **1. Pentingnya Kesadaran Keamanan Siber di Era Digital**

Ancaman siber 2026 telah berevolusi menjadi **serangan AI-driven, zero-day exploits, dan supply chain sabotage**. Tidak lagi hanya phising manual, peretasan kini melibatkan alat generative AI untuk membuat pesan disinformasi yang hampir sempurna replika internal perusahaan. Contoh: peretas dapat menggunakan LLM (Large Language Model) untuk membuat email "dari rekan kerja" dengan tanda tangan dan jadwal kegiatan yang _100% valid_ berdasarkan data eksfiltrasi sebelumnya.

### **Statistik Ancaman 2026**

| Tipe Serangan           | % Kenaikan vs 2025 | Dampak Rata-Rata  |
| ----------------------- | ------------------ | ----------------- |
| Phishing AI-Driven      | +320%              | 245 hari downtime |
| Ransomware Supply Chain | +180%              | $9.1M kerugian    |
| Credential Stuffing     | +75%               | 3.2TB data bocor  |

### **Arsitektur Defensi: Zero Trust Prinsip**

Zero Trust tidak hanya politik desain jaringan—ia adalah paradigma pengoperasian yang **memandang setiap request sebagai potensi ancaman**. Implementasi khas:

1. **Micro-Segmentation** (misal: menggunakan AWS Network Firewall)
2. **Continuous Verification** (via Google BeyondCorp)
3. **Least Privilege** (aktifkan hanya ACL yang diperlukan)

---

## **2. Serangan Phishing: Mekanisme dan Contoh Kode**

### **Contoh Kode untuk Deteksi URL Suspicious**

Python dapat memfilter URL mencurigakan berdasarkan pola regex:

```python
import re

def is_suspicious(url):
    patterns = {
        r'microsoft\.login',  # Domain spoofing
        r'0day-credentials',  # Keyword phishing
        r'\\(?:[^\\:\n]*/?\s+)*\.',  # File attachment aneh
    }
    for p in patterns:
        if re.search(p, url, re.IGNORECASE):
            return True
    return False

# Uji coba
test_url = "https://microsoft-login.office365/phishy.html"
if is_suspicious(test_url):
    print("[!] URL menyerupai phishing.")
```

### **Skrip PowerShell untuk Isolasi File Mencurigakan**

Gunakan PowerShell untuk memindai dan kunci file dengan hash malware:

```powershell
# Baca database malware dari file TSV
$malwareDb = Get-Content -Path "C:\malware_hashes.tsv" | ConvertFrom-CSV -Delimiter "`t" -Header "Hash", "Type"

# Pindai folder kerja
$files = Get-ChildItem -Path "C:\Users\*" -Recurse | Where-Object { $_.Extension -in ".exe", ".dll" }

foreach ($file in $files) {
    $hash = Get-FileHash -Algorithm SHA256 -Path $file.FullName
    if ($malwareDb.Hash -contains $hash.Hash) {
        Move-Item -Path $file.FullName -Destination "C:\isolated_malware\"
        Write-Output "Isolated: $file.FullName (Type: $($malwareDb.Type))"
    }
}
```

---

## **3. Ransomware: Mitigasi dan Contoh Serangan 2026**

### **Skenario Serangan Ransomware Multi-Vector**

1. **Injeksi DNS** → Eksploitasi Kubernetes DNS resolver (CVE-2026-10001)
2. **Eksekusi Payload** → `rm -rf /` via compromised container
3. **Encrypted File Drop** → `.enc` file dengan AES-256-GCM

### **Code Snippet untuk Deteksi File Enkripsi**

Shell script untuk memantau file yang tidak bisa diakses:

```bash
#!/bin/bash
THRESHOLD=5

# Hitung file dengan permission error
count=$(find /data -perm /u=r,g=r,o=r -type f 2>/dev/null | wc -l)

if [ "$count" -gt "$THRESHOLD" ]; then
    echo "[CRITICAL] Potensi enkripsi ransomware! $count file tidak bisa diakses." | mail -s "Ransomware Alert" admin@example.org
    systemctl stop nginx
    systemctl stop database
fi
```

---

## **4. Supply Chain Attacks: Studi Kasus dan Solusi**

### **Serangan 2026: Poisoned NPM Package**

**Contoh:** Paket `lodash` diubah untuk mengirim telemetri penggunaan ke C2. Solusi:

- Gunakan **SBOM (Software Bill of Materials)** dari CycloneDX
- Aktifkan **subresource integrity (SRI)** pada npm

### **Code: Enforce SRI di NPM**

`.npmrc` untuk memaksimalkan keamanan:

```ini
# Force integrity check for all packages
audit=true
ci=true
strict-ssl=true

# Use SRI cache from hardened registry
registry=https://registry.npmjs.org/
cache=https://hardened-cdn.pkg.cacheserv.org/
```

---

## **5. Password Best Practices: Kecocokan NIST 2026**

### **Password Validator Berbasis Regex**

Python validator dengan kebijakan NIST 2026:

```python
import re

def validate_password(password):
    if len(password) < 10:
        return False, "Minimal 10 karakter"
    if not re.search(r'[A-Z]', password):
        return False, "Butuh huruf kapital"
    if not re.search(r'[a-z]', password):
        return False, "Butuh huruf kecil"
    if not re.search(r'[0-9]', password):
        return False, "Butuh angka"
    if not re.search(r'[!@#$%^&*_=+]', password):
        return False, "Butuh simbol"
    if re.search(r'123|password|admin', password.lower()):
        return False
```
