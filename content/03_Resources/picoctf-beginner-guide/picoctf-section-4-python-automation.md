---
tags:
- CTF
- Python
- Automation
- Password-Cracking
aliases:
- PicoCTF Section 4
- Python for CTF Basics
created: 2026-05-12
status: pending
title: Picoctf Section 4 Python Automation
updated: '2026-07-01'
---

cssclasses:
  - wide-table
  - callout

# 🐍 PICOCTF SECTION 4 — Python Automation

> **Environment:** Python 3
> **Filosofi:** Jangan kerjakan secara manual apa yang bisa dikerjakan oleh script.
> **Target:** `.py` scripts, Password Cracking, & Data Wrangling.

---

## FASE 1 — Menjalankan Script Python

Banyak tantangan memberikan file `.py` yang harus dijalankan untuk mendapatkan flag.

### 1.1 Eksekusi Dasar
```bash
python3 script.py
```

### 1.2 Menangani Argumen
Seringkali script membutuhkan file tambahan sebagai argumen (misal: data terenkripsi).
```bash
# Contoh: menjalankan script dengan file data pendukung
python3 script.py -d data.en.txt
```

---

## FASE 2 — Password Cracking Dasar

Tantangan series `PW Crack` mengajarkan cara menebak password yang ditaruh di dalam kode.

### 2.1 Hardcoded Password
Buka file `.py` menggunakan editor atau `cat`. Cari variabel seperti `pos_pw_list` atau `correct_pw`.
```bash
cat level1.py | grep "password"
```

### 2.2 Brute Force Sederhana
Jika password ada di dalam list (array), script biasanya akan mencocokkan input Anda dengan list tersebut.

---

## FASE 3 — Python One-Liner (Otomasi Cepat)

Anda tidak selalu perlu membuat file `.py`. Terkadang satu baris di terminal sudah cukup.

```bash
# Contoh: Melakukan kalkulasi cepat atau manipulasi string
python3 -c "print('A' * 50)"           # Mencetak huruf A 50 kali
python3 -c "print(0x42)"                # Konversi Hex ke Desimal
```

---

## Quick Reference — Cheat Sheet

```bash
# ═══ EXECUTION ═══
python3 [file].py                      # Jalankan script
python3 -c "[command]"                 # Run perintah Python di terminal

# ═══ COMMON TASKS ═══
cat [file].py | grep "flag"            # Intip variabel flag
ls -l *.py                             # Lihat daftar script di folder
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Mencoba menebak password secara manual | Baca source code scriptnya |
| Mengabaikan file `.txt` pendukung | Cek apakah script butuh argumen file `-d` |
| Menggunakan Python 2 | Selalu gunakan `python3` |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-3-linux-web-basics]] — Kembali ke Section 3
- [[picoctf-section-5-reverse-engineering]] — Lanjut ke Section 5

---

*PicoCTF Section 4 | Python Wrangling · PW Crack · Automation*

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

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)

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

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian: ada vs tidak ada kontrol, efektivitas, dokumentasi, repeatable.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Never trust, always verify |
| **MITRE ATT&CK** | Framework TTP serangan |
| **SIEM** | Security Information & Event Management |
| **EDR** | Endpoint Detection & Response |
| **SOAR** | Security Orchestration & Response |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **OIDC** | OpenID Connect |
| **PKCE** | Proof Key for Code Exchange |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/
- Cloud Native (CNCF) — https://www.cncf.io/

### Tips Python Automation (picoCTF)

| Task | Library | Use |
|------|---------|-----|
| **Socket** | `socket` | TCP/UDP connection |
| **HTTP** | `requests` | API/web interaction |
| **Crypto** | `pycryptodome` | AES, RSA, XOR |
| ** pwntools** | `pwntools` | CTF exploit framework |
| **Parsing** | `struct` | Binary data unpack |
| **Encoding** | `base64`, `binascii` | Base64, hex, binary |

### Template Automation

```python
import socket, struct

# Connect ke server picoCTF
s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('host.picoctf.com', 12345))

# Receive prompt
data = s.recv(1024)
print(data.decode())

# Send answer
s.send(b'answer\n')
response = s.recv(1024)
print(response.decode())
s.close()
```

### Checklist Automasi

1. Baca soak: apa yang diminta?
2. Tentukan protocol: TCP socket, HTTP, file?
3. Tulis script: connect → parse → answer → flag
4. Debug: print setiap step, cek format
5. Edge case: timeout, encoding, binary mode
