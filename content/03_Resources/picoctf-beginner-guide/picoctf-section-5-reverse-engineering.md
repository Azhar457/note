---
tags:
- CTF
- Reverse-Engineering
- Java
- Python
- Hashing
aliases:
- PicoCTF RevEng
- SHA256 Indexing Guide
created: 2026-05-12
status: pending
title: Picoctf Section 5 Reverse Engineering
updated: '2026-07-01'
---

cssclasses:
  - wide-table
  - callout

# ⚙️ PICOCTF SECTION 5 — Reverse Engineering

> **Environment:** Java JDK, Python 3
> **Filosofi:** Pahami logikanya, temukan kuncinya, atau hancurkan pintunya.
> **Target:** Source Code (.java, .py), Compiled Bytecode, & License Key.

> [!tip] Golden Rule
> Password yang ditaruh di dalam Source Code (Hardcoded) adalah kerentanan fatal.

---

## FASE 1 — Java Source Analysis (VaultDoor)

Tantangan di mana password disembunyikan langsung di dalam fungsi `checkPassword`.

### 1.1 Compiled vs Interpreted
Berbeda dengan Python, Java harus dikompilasi ke bytecode sebelum bisa dijalankan.

```bash
# Tahap 1: Kompilasi (.java -> .class)
javac VaultDoorTraining.java

# Tahap 2: Eksekusi
java VaultDoorTraining
```

### 1.2 Analisis Logika `equals()` & `substring()`
```java
// Contoh potongan kode yang menjebak
String input = userInput.substring("picoCTF{".length(), userInput.length()-1);
if (input.equals("w4rm1ng_Up_w1tH_jAv4_...")) { ... }
```
> [!warning] Hati-hati
> Karena ada fungsi `substring()`, kamu harus memasukkan flag secara utuh dengan bungkusnya `picoCTF{...}` agar setelah dipotong hasilnya cocok dengan string target.

---

## FASE 2 — Python Reverse Engineering (Keygenme)

Tantangan di mana kunci lisensi dibuat secara dinamis menggunakan **SHA256 Hashing**.

### 2.1 Konsep SHA256 (Digital Blender)
*   **Satu Arah**: "BENNETT" jadi hash bisa, balik lagi nggak bisa.
*   **Sensitif**: Satu huruf beda (kapital/kecil), hasil hash berubah total.

### 2.2 Memahami "Indexing" & "Obfuscation"
Hasil SHA256 terdiri dari 64 karakter. Program seringkali hanya mengambil beberapa karakter di posisi tertentu (Index) secara acak untuk menyesatkan (Obfuscation).

**Langkah Eksekusi (Python One-Liner):**
```bash
# Ambil karakter indeks [4], [5], [3], [6], [2], [7], [1], [8] dari hash username "BENNETT"
python3 -c "import hashlib; u = b'BENNETT'; h = hashlib.sha256(u).hexdigest(); print(h[4] + h[5] + h[3] + h[6] + h[2] + h[7] + h[1] + h[8])"
```

---

## FASE 3 — Strategi Menembus "Pintu"

Dalam Reverse Engineering, kamu punya dua pilihan:

1.  **Opsi A (The Keygenner)**: Pelajari algoritma pembuatan kunci, buat kuncinya (Intended Way).
2.  **Opsi B (The Patcher)**: Hancurkan logikanya. Ubah `if (check_key)` menjadi `if (true)`.
    *   *Catatan:* Opsi B bisa gagal jika kunci tersebut juga digunakan sebagai kunci dekripsi (misal: Fernet) untuk data berikutnya.

---

## Quick Reference — Cheat Sheet

```bash
# ═══ JAVA ═══
javac File.java && java File           # Compile & Run

# ═══ PYTHON HASHING ═══
# Mencari hash SHA256 via terminal
echo -n "BENNETT" | sha256sum

# Python Indexing (Ambil karakter posisi 4)
python3 -c "import hashlib; print(hashlib.sha256(b'input').hexdigest()[4])"
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Memasukkan password tanpa bungkus `picoCTF{}` | Cek logika `substring` di kode |
| Menghitung indeks hash secara manual | Gunakan Python one-liner (Indeks mulai dari 0) |
| Patching logika sembarangan | Pastikan kunci tidak dipakai untuk dekripsi data |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-4-python-automation]] — Kembali ke Modul 4
- [[picoctf-section-5-binary-exploitation]] — Lanjut ke Modul 3

---

*PicoCTF Modul 2 | RevEng · Java · Python · SHA256*

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

### Tips Reverse Engineering (picoCTF)

| Tool | Use | Target |
|------|-----|--------|
| **Ghidra** | Decompile C → pseudocode | ELF binary |
| **IDA Free** | Disasm + decompile | ELF, PE |
| **gdb** | Dynamic analysis (breakpoint, mem inspect) | Runtime |
| **strace** | Syscall trace | Runtime |
| **ltrace** | Library call trace | Runtime |
| **strings** | Cari string di binary | Quick check |
| **radare2** | CLI disasm + analysis | ELF, PE |

### Workflow Solving RE Challenge

```
1. file vuln → ELF 32/64, stripped?
2. strings vuln | grep -i flag → quick check
3. Ghidra → import → auto-analyze → decompile main()
4. Baca pseudocode: apa input → apa kondisi → apa output
5. gdb: breakpoint di compare, inspect register/memory
6. Trace: strace/ltrace untuk liat syscall/library call
7. Patch bila perlu: ubah conditional jump (jne → je)
8. Run → dapat flag
```

### Commons Pattern di picoCTF RE

- Compare string: `strcmp(input, "picoCTF{...}")` — strings bisa tau
- Math check: input dioperasi → compare dengan konstanta — solve equation
- XOR decode: flag di-XOR dengan key — extract key + decode
- Flag di memory: inspect stack/heap saat runtime
