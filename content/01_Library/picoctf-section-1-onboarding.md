---
title: PicoCTF Section 1 — Onboarding Guide
tags:
  - picoctf
  - ctf
  - beginner
  - learning
  - cybersecurity
created: '2026-08-01'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Panduan singkat memulai **PicoCTF** (CTF edukasi dari Carnegie Mellon) untuk pemula. Catatan ini terintegrasi dengan [[cyber-security-foundations]] dan [[learning-resources-ctf]] untuk menyiapkan environment, toolset, dan workflow standar.
>
> **Domain:** Capture The Flag / Education
> **Tags:** #picoCTF #ctf #learning #beginner #cybersecurity

## 1. Ringkasan Eksekutif
PicoCTF menyediakan tantangan **beginner-friendly** dalam enam kategori (General Skills, Web, Crypto, Reverse, Binary, Forensics). Onboarding meliputi **registrasi**, **setup environment** (Linux/WSL), **installasi tool**, dan **workflow standar** untuk menyelesaikan tantangan secara efisien. Penggunaan *writeup template* memudahkan pencatatan proses, mempersiapkan kompetisi tim, dan mengintegrasikan pembelajaran ke dalam vault.

## 2. Threat Model / Konteks
| Aktor | Vektor | Dampak Potensial |
|-------|--------|------------------|
| Penyerang (challenge) | Payload berbahaya, binary sandbox escape | Memungkinkan exploit pada host jika tidak di‑sandbox dengan baik |
| Insider (user) | Penggunaan tool tidak aman (e.g., `curl -O http://malicious`) | Kompromi sistem lokal, pencurian flag |
| Platform (PicoCTF) | Server down, data loss | Menghambat progres belajar |

**Mitigasi**: gunakan **isolasi** (Docker, VM, WSL) untuk mengeksekusi binary, jangan jalankan script dari sumber tidak terpercaya tanpa review.

## 3. Langkah-Langkah Teknik Detail
### 3.1 Registrasi & Setup
1. Buka https://play.picoctf.org/ dan **daftar** menggunakan GitHub, Google, atau email.
2. Aktivasi akun melalui email verification.
3. Pilih **Practice → Gym** → kategori **General Skills** untuk memulai.

### 3.2 Tools Wajib (Linux/WSL)
| Tool | Fungsi | Install Command |
|------|--------|-----------------|
| `nc` (netcat) | Koneksi TCP/UDP | `sudo dnf install nmap-ncat` |
| `python3` | Scripting, exploit dev | pre‑installed |
| `gdb` + `pwndbg` | Debug binary | `pipx install pwndbg` |
| `pwntools` | Exploit framework | `pipx install pwntools` |
| `binwalk`, `foremost` | Forensik file | `sudo dnf install binwalk foremost` |
| `wireshark` / `tshark` | Analisis PCAP | `sudo dnf install wireshark-cli` |
| `exiftool` | Metadata file | `sudo dnf install perl-Image-ExifTool` |
| `steghide`, `zsteg` | Steganography | `sudo dnf install steghide` + `gem install zsteg` |
| `ghidra` / `ida-free` | Reverse engineering | Download binary dari situs resmi |

### 3.3 Workflow Standar Soal
1. **Recon** – Baca deskripsi, unduh file, jalankan `file`, `strings`, `exiftool`.
2. **Analisis** – Cari pola flag `picoCTF{...}`; identifikasi tipe soal.
3. **Eksploitasi** – Gunakan tool yang sesuai (web → Burp, binary → gdb/pwntools, crypto → python/sage).
4. **Submit** – Paste flag ke web, verifikasi scoreboard.
5. **Writeup** – Simpan catatan di folder `writeups/` dengan format markdown (template tersedia).

### 3.4 Contoh Skrip Automasi (Python)
```python
import requests, re

URL = "https://play.picoctf.org/api/v1/flags/submit"
FLAG = "picoCTF{example}"
TOKEN = "YOUR_SESSION_TOKEN"

resp = requests.post(URL, json={"flag": FLAG}, headers={"Authorization": f"Bearer {TOKEN}"})
print("Submitted", FLAG, "=>", resp.json()["message"]) if resp.ok else print("Error", resp.text)
```

## 4. Contoh Praktis
```bash
# 1. Enumerasi simple web challenge
curl -s "http://picoctf.org/challenge?file=../etc/passwd" | grep picoCTF

# 2. Binary exploitation – buffer overflow (pwntools template)
cat <<'EOF' > exploit.py
from pwn import *

p = remote('picoctf.org', 31337)
p.recvuntil('Input:')
p.sendline(b'A'*64 + p64(0xdeadbeef))
print(p.recvall().decode())
EOF
python3 exploit.py
```

## 5. Checklist Mitigasi untuk Onboarding
- [ ] Jalankan semua binary di **sandbox** (Docker/VM) untuk menghindari host compromise
- [ ] Verifikasi **hash** file challenge (jika disediakan) sebelum eksekusi
- [ ] Simpan **session token** di password manager, jangan hardcode dalam repo publik
- [ ] Gunakan **writeup template** untuk dokumentasi yang dapat dibagikan
- [ ] Batu loncatan: review [[cyber-security-foundations]] untuk konsep dasar sebelum melanjutkan ke challenge lanjutan

## 6. Referensi Lintas
- [[cyber-security-foundations]]
- [[learning-resources-ctf]]
- [[binary-exploitation-gadgets]]
- [[web-hacking-exploitation]]
- [[crypto-challenges]]

---

### 📚 Referensi
1. https://play.picoctf.org/
2. https://github.com/picoCTF/picoCTF
3. https://picoctf.org/resources/
4. https://medium.com/@ctfguide/picoctf-beginners-guide-2024

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian dilakukan berdasarkan: ada vs tidak ada kontrol, efektivitas, dan dokumentasi.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Model keamanan: never trust, always verify |
| **Supply Chain** | Serangan ke rantai dependency dan tooling |
| **MITRE ATT&CK** | Framework TTP untuk klasifikasi serangan |
| **SIEM** | Security Information and Event Management |
| **EDR** | Endpoint Detection and Response |
| **SOAR** | Security Orchestration, Automation and Response |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **OIDC** | OpenID Connect (identity layer) |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/
