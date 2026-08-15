---
title: "CTF & Cyber Competition — Methodology & Strategy"
tags:
  - ctf
  - methodology
  - strategy
  - cyber-competition
  - time-triage
  - penetration-testing
created: '2026-07-28'
updated: '2026-07-28'
status: pending
cssclasses:
  - wide-table
  

---

# 🏆 CTF & Cyber Competition — Methodology & Strategy

> **Panduan** metodologi, time triage, dan strategy untuk menghadapi kompetisi keamanan siber — dari jeopardy CTF sampai attack-defense, dari digital forensic sampai incident response. **Fokus pada yang universal dan tidak terikat event tertentu.** Untuk gambaran besar level kompetisi, lihat [[hierarchy-ctf-competition-framework]]. Untuk tools reference, lihat [[ctf-tool-arsenal-universal]].

> [!tip] Prinsip Golden
> **"Score the lowest-hanging fruit first, then work up."** Di kompetisi, poin sama nilainya apakah Anda mendapatkannya dalam 5 menit atau 5 jam. Prioritaskan soal yang cepat diselesaikan, lalu investasikan sisa waktu untuk soal yang kompleks.

---

## Daftar Isi

- [[#Fase Pra-Kompetisi — Persiapan & Recon]]
- [[#Metodologi Jeopardy CTF (L1-L2)]]
- [[#Metodologi Attack-Defense CTF (L3)]]
- [[#Metodologi Digital Forensic & Incident Response]]
- [[#Metodologi Topikal — Per Kategori]]
- [[#Time Triage — Strategi Menit ke Menit]]
- [[#Teamwork & Komunikasi]]
- [[#Tools Prioritization — Fallback Chain]]
- [[#Post-Mortem & Knowledge Base]]

---

## Fase Pra-Kompetisi — Persiapan & Recon

### H-7 sampai H-1

| Periode | Aktivitas | Output |
|---------|-----------|--------|
| **H-7** | Baca rulebook, scoring system, format flag | Paham: flag format (CTF{...}), tiebreaker (first blood? time?), peraturan anti-cheat |
| **H-3** | Test koneksi ke platform, VPN/auth setup | Cache login. Pastikan VM/container bisa diakses |
| **H-1** | Team sync: siapa handle kategori apa, komunikasi channel mana | RACI matrix per kategori + backup person |
| **H-0 (30 menit sebelum)** | Cek tools terinstall, internet stabil, backup comms (WA vs Discord vs Telegram) | Semua siap, no last-minute tool install |

### Team Role Assignment (sudah harus fix sebelum mulai)

Kompetisi tim (3–5 orang):

| Role | Handle | Kompetensi | Backup |
|------|--------|------------|--------|
| **Web/PWN** | Exploit & web challenge | Web security, binary exploitation, reverse engineering | Crypto person |
| **Forensic/RE** | File analysis, memory dump, binary reverse | Forensik, malware analysis, steganography | Anyone |
| **Crypto/Misc** | Cipher, encoding, logika | Cryptography, encoding, logic puzzles | Web person |
| **Attack (A/D)** | Exploit service lawan | Network scanning, exploit dev, service monitoring | Semua anggota |
| **Defense (A/D)** | Patch service sendiri | Hardening, patch management, checker script | Semua anggota |

**Untuk tim 2–3 orang:** tiap orang pegang 2 kategori. Prioritas pada strength masing-masing.

---

## Metodologi Jeopardy CTF (L1-L2)

### Anatomi Soal CTF

Setiap soal CTF memiliki struktur yang sama:

```
Soal = Description + Attachment (optional) + Target/Endpoint + Flag
```

**Flow umum menyelesaikan soal:**

```
Read Description → Identifikasi Kategori → Cari Tool Default
→ Eksekusi Tool → Analyze Output → Dapat Flag
```

### The 5-Minute Rule

Jika dalam **5 menit pertama** Anda belum tau harus mulai dari mana:

1. Baca description lagi — **80% clue ada di description**, bukan di attachment
2. Google judul soal + "CTF writeup" — mungkin soal lama yang di-recycle
3. Jalankan **CyberChef Magic** — deteksi encoding/encryption otomatis
4. `strings`, `binwalk`, `file`, `exiftool` pada attachment
5. Skip — tandai sebagai "butuh revisit", kerjakan soal lain dulu

### Flowchart Pemecahan Soal Per Kategori

```
Menerima Soal
    │
    ├── Ada attachment?
    │   ├── Ya → file, strings, binwalk, exiftool
    │   │   └── Hasil? → Flag langsung? → Submit
    │   │       └── Tidak → Analisis lebih lanjut (RE/decompile/carving)
    │   └── Tidak → Cek koneksi ke endpoint
    │       ├── Web → curl/nmap/dirb
    │       ├── PWN → nc/netcat, checksec
    │       └── Misc → Ikuti petunjuk
    │
    └── 5 menit? Tidak dapat progress?
        └── Skip. Tandai. Kembali nanti.
```

---

## Metodologi Attack-Defense CTF (L3)

### Fase-Fase Attack-Defense

Setiap ronde Attack-Defense memiliki siklus yang sama:

```
┌─────────────────────────────────────────────────────┐
│ Start Ronde                                         │
├─────────────────────────────────────────────────────┤
│ 1. SCAN & RECON (2–5 menit)                         │
│    nmap -p- team_lawan → Cari service terbuka       │
│                                                     │
│ 2. PATCH & HARDEN (2–5 menit)                       │
│    Cek service sendiri → Tutup celah → Restart      │
│    Service harus jalan + checker harus lulus        │
│                                                     │
│ 3. ATTACK (sisa waktu)                              │
│    Exploit service lawan → Inject flag → Submit     │
│    Monitor checker: service sendiri masih health?   │
│                                                     │
│ 4. RECOVER (menit terakhir)                         │
│    Jika service down → restart + re-patch           │
└─────────────────────────────────────────────────────┘
```

### Golden Rules Attack-Defense

| Rule | Penjelasan |
|------|------------|
| **Hardening dulu, attack kedua** | Jika service Anda sendiri tidak jalan, Anda dapat 0 poin defense + lawan dapat attack points. Harden service sendiri dulu baru attack |
| **Checker script > exploit** | Kalau checker script tidak lulus, skor defense Anda hilang. Pastikan checker bisa jalan terus. **Monitor checker output** adalah prioritas #1 |
| **Satu service, satu orang** | Attack person fokus ke 1 service — jangan gonta-ganti. Defense person monitor checker dan log |
| **Restart policy** | `while true; do ./service; done` bukan solusi — service harus restart dengan state yang valid. Pastikan flag di-inject ulang setelah restart |
| **Exploit sederhana > exploit keren** | Buffer overflow yang reliable > ROP chain yang kadang crash. Yang penting flag masuk, bukan elegance |
| **Backup service binary** | Sebelum patch, backup service binary. Jika crash setelah patch, restore dari backup |

### Script Starter untuk Attack-Defense

```python
#!/usr/bin/env python3
"""Checker script template untuk Attack-Defense CTF"""
import requests
import sys
import time

TEAM_ID = sys.argv[1]
TARGET = f"http://10.0.{TEAM_ID}.3:8080"

def check_service():
    """Pastikan service berjalan & return status"""
    try:
        r = requests.get(f"{TARGET}/health", timeout=5)
        return r.status_code == 200
    except:
        return False

def submit_flag(flag):
    """Submit flag ke server"""
    r = requests.post("http://scoreboard/submit",
                      json={"flag": flag, "team": TEAM_ID})
    return r.json().get("status") == "ok"

# Main loop
while True:
    if not check_service():
        print(f"[!] Service DOWN! Restarting...")
        # Panggil restart script di sini
    else:
        print(f"[+] Service OK")
    time.sleep(30)
```

---

## Metodologi Digital Forensic & Incident Response

### Universal Forensic Triage

Ketika dapat soal forensic / incident response:

```
1. Cek file type → file command atau header magic bytes
2. Cek strings → strings file | grep -iE "flag|ctf|key|secret|password"
3. Cek metadata → exiftool
4. Cek embedded file → binwalk -Me
5. Cari hidden data → foremost/scalpel/photorec
6. Analisis spesifik → tergantung kategori (lihat kategori forensic di bawah)
```

### Urutan Analisis Berdasarkan File Type

**Disk Image (.dd, .e01, .img, .vmdk, .vhd)**
```
file → mmls (partition table) → fls (file listing) → icat (file content)
Timeline: log2timeline/plaso
File carving: foremost, scalpel, photorec
Registry: regripper (Windows)
```

**Memory Dump (.raw, .vmem, .mem, dumpit)**
```
imageinfo (Volatility 3) → psscan → netscan → cmdline/malfind
String ekstraksi: volatility windows.strings
YARA scan: yara dengan malware signature
```

**PCAP (.pcap, .pcapng)**
```
Statistics: capinfos, wireshark statistics
Filter: HTTP objects → File → Export Objects → HTTP
DNS: dns query — cari exfiltration
TLS: SSL/TLS handshake — cek certificate, cipher, SNI
TCP follow stream — cari flag dalam teks
```

**Binary (.exe, .bin, .elf)**
```
strings → file → binwalk → objdump/readelf
Decompile: Ghidra, IDA Free, radare2, cutter
YARA: custom rule
Hash cek: VirusTotal, Hybrid Analysis
```

### Cold-Start Playbook untuk Soal Forensic

Ketika baru buka soal forensic dan **belum tahu harus mulai dari mana**:

```
strings file | grep -i "flag\|CTF\|KEY\|secret\|password\|htb"
```
→ Jika hasil positif → Submit flag. Selesai.

```
exiftool file
```
→ Cek metadata: author, camera, GPS, software, timestamps.

```
file + binwalk -Me file
```
→ Cek tipe file. Jika archive (zip/tar/gz) → extract.

```
foremost -T -i file -o output/
```
→ File carving. Cari file tersembunyi.

```
strings file | grep -E "^[A-Za-z0-9+/]{20,}={0,2}$"
```
→ Cek base64 string dalam file.

```
hexdump -C file | grep -v "00 00 00" | head -50
```
→ Cek struktur non-null — mungkin ada data anomali.

---

## Metodologi Topikal — Per Kategori

### 🔹 Web Exploitation

| Step | Tool | Command |
|------|------|---------|
| Recon | curl, wget, nmap | `curl -v http://target:port` |
| Directory busting | dirb/gobuster/dirsearch | `gobuster dir -u http://target -w wordlist.txt` |
| Parameter fuzzing | ffuf | `ffuf -u http://target/FUZZ -w wordlist.txt` |
| SQL Injection | sqlmap | `sqlmap -u "http://target/?id=1" --batch --dump` |
| Cookie/session | dev tools / jwt.io | Baca cookie, decode JWT |
| Source code | `view-source:` | Cek komentar HTML, JS, hidden input |
| API endpoint | Postman, Burp Suite | Repeater, Intruder |

**Checklist Web:**
- [ ] robots.txt — sering ada endpoint tersembunyi
- [ ] .git/config — git exposed (git-dumper)
- [ ] /admin, /api, /swagger, /graphql
- [ ] parameter pollution (WAF bypass)
- [ ] JWT none algorithm attack
- [ ] SSTI (Server-Side Template Injection) — {{7*7}}
- [ ] LFI/RFI — /../../../../etc/passwd
- [ ] File upload — .php, .phtml, .php5, .phar

### 🔹 Binary Exploitation (PWN)

| Step | Tool | Command |
|------|------|---------|
| Cek proteksi | checksec | `checksec --file=binary` |
| Disassemble | objdump, Ghidra, radare2 | `objdump -d binary` |
| Find gadgets | ROPgadget | `ROPgadget --binary binary` |
| Test overflow | Python/pwntools | `cyclic(100)` → gdb pattern offset |
| Exploit | pwntools | `p = remote('host', port)` |

**Checklist PWN:**
- [ ] checksec: NX, PIE, RELRO, Stack Canary, ASLR
- [ ] Cari fungsi yang terlihat vulnerable (gets, strcpy, sprintf, scanf %s)
- [ ] Coba buffer overflow dengan cyclic pattern
- [ ] Hitung offset ke RIP/EIP
- [ ] ROP chain jika NX enabled
- [ ] ret2libc/ret2system jika ada libc leak
- [ ] one-gadget jika RCE tujuan

### 🔹 Cryptography

| Step | Tool | Command |
|------|------|---------|
| Auto-detect | CyberChef Magic | Magic recipe → detect otomatis |
| Frequency analysis | quipqiup.com | Substitution cipher solver |
| RSA | RsaCtfTool | `python RsaCtfTool.py -n N -e e --uncipher c` |
| XOR brute | xortool | `xortool cipher.bin` |
| Hash identify | hash-identifier | `hashid hash.txt` |

**Checklist Crypto:**
- [ ] Cek encoding dulu: base64, base32, base16, hex, ascii85
- [ ] Cek cipher klasik: Caesar, ROT13, Vigenere, Atbash
- [ ] XOR key length → xortool brute
- [ ] RSA: small N (factordb), small e (Coppersmith), common modulus
- [ ] AES/block cipher: ECB mode (copy-paste block), CBC bit flipping
- [ ] Padding oracle attack jika ada endpoint decrypt
- [ ] Hash: rainbow table (crackstation.net), google hash

### 🔹 Reverse Engineering

| Step | Tool | Command |
|------|------|---------|
| Metadata | file, strings, exiftool | `strings binary \| grep -i flag` |
| Disassemble | objdump, radare2, Ghidra | `objdump -d binary` |
| Decompile | Ghidra, IDA Free, cutter | Import binary → decompile |
| Debugger | gdb, x64dbg (Windows) | `gdb ./binary` |
| .NET/DLL | dnSpy, ILSpy | Buka .NET binary langsung |

**Checklist RE:**
- [ ] `strings` dulu — sering flag langsung ada di string table
- [ ] Cek fungsi compare/strcmp/strncmp — mungkin flag dibanding langsung
- [ ] Trace input/output: coba input berbeda, lihat behavior
- [ ] Patch conditional jump (JNZ → JZ) untuk bypass check
- [ ] Angry XOR: cari XOR dengan key tertentu, atau auto-XOR brute
- [ ] UPX packed? `upx -d`

### 🔹 Digital Forensic

| Step | Tool | Command |
|------|------|---------|
| File type | file | `file evidence.bin` |
| Strings | strings | `strings evidence \| grep -i flag` |
| Disk partisi | mmls (sleuth kit) | `mmls disk.dd` |
| File listing | fls | `fls -o OFFSET disk.dd` |
| File content | icat | `icat -o OFFSET disk.dd INODE` |
| Timeline | plaso/log2timeline | `log2timeline --storage timeline.plaso disk.dd` |
| Registry | regripper | `rip.pl -r SYSTEM -f system` |

**Checklist Forensic:**
- [ ] strings dulu — jangan lupa grepping case-insensitive
- [ ] binwalk — cek embedded file dalam image
- [ ] foremost — file carving mencari file yang dihapus
- [ ] $MFT analysis — cari file dihapus, timestamp anomali
- [ ] $Recycle.Bin — file apa yang dihapus
- [ ] Prefetch — program apa yang pernah dijalankan
- [ ] Event Log — login/logoff, service start/stop
- [ ] Browser history — apa yang diakses user
- [ ] Volume Shadow Copy — file versi sebelumnya (sering luput)

### 🔹 Attack Defense — Infrastruktur & Hardening

| Step | Tool | Command |
|------|------|---------|
| Scan service sendiri | nmap | `nmap -p- localhost` |
| Cek port listening | netstat/ss | `ss -tlnp` |
| Cek proses berjalan | ps, htop | `ps aux \| grep service` |
| Patch permission | chmod, chown | `chmod 755 /opt/service` |
| Firewall | iptables/nftables | `iptables -A INPUT -p tcp --dport 8080 -j ACCEPT` |
| Monitor | tail, journalctl | `tail -f /var/log/service.log` |

**Checklist Hardening Cepat (menit-menit pertama):**
- [ ] Non-root user untuk service — jangan jalan sebagai root
- [ ] Bind ke localhost dulu — `Listen 127.0.0.1:PORT`
- [ ] Firewall — hanya port yang dibutuhkan
- [ ] Rate limiting — `limit_req` untuk Nginx
- [ ] Input validation — semua input = malicious sampai terbukti aman
- [ ] Hapus debug mode / verbose error
- [ ] Rotate credentials — ganti default password
- [ ] Backup binary sebelum patch
- [ ] Test checker script — pastikan jalan valid

---

## Time Triage — Strategi Menit ke Menit

### Jeopardy (24+ jam)

```
0–30 menit  → Scan semua soal, kategorisasi: easy/hard, cari "first blood"
30–60 menit → Kerjakan semua "easy" soal — 1 soal per 10 menit maks
1–4 jam     → Kerjakan soal "medium" — kolaborasi 2 orang per soal jika stuck
4–12 jam    → Istirahat 15 menit per 2 jam. Kerjakan "hard"
12–24 jam   → Review soal yang di-skip — mungkin ada clue baru dari soal lain
24+ jam     → Final push: cari flag fragment, cari unintended solution
```

### Attack-Defense (6–10 jam)

```
5 menit pertama:
    - Scan service sendiri → identifikasi service apa yang jalan
    - Patch service sendiri → nonaktifkan debug/endpoint berbahaya
    - Cek checker script → pastikan checker lulus
    
Setiap ronde (30–60 menit):
    - 5 menit: scan service lawan → port/service baru?
    - 5 menit: cek service sendiri → masih jalan?
    - Sisa waktu: attack
    
Akhir ronde:
    - 2 menit: restart service jika crash
    - 1 menit: submit flag yang didapat
```

### Incident Response (Live Exercise, 2–5 hari)

```
Hari 1 — Triage & Containment:
    - Identifikasi scope: apa yang terkena, apa yang tidak
    - Isolate: disconnect dari network jika lateral movement terdeteksi
    - Collect volatile evidence: RAM, network, process (L0-L2)
    
Hari 2 — Analysis & Eradication:
    - Analisis malware/malicious artifact
    - Hapus persistence mechanism
    - Patch vulnerability yang dieksploitasi
    
Hari 3 — Recovery & Lessons Learned:
    - Restore service dari backup bersih
    - Monitoring post-recovery — apakah attacker kembali?
    - Dokumentasi timeline + TTP untuk laporan
```

---

## Teamwork & Komunikasi

### Communication Protocol (dalam tim)

| Situasi | What to Say | What NOT to Say |
|---------|-------------|-----------------|
| **Stuck di soal >30 menit** | "Saya stuck di X, butuh bantuan Y" | "Ini susah banget" |
| **Ada clue baru** | "Di soal Z ada clue: ..." | (diam saja) |
| **First blood** | "Soal X solved, flag di spreadsheet" | "Gampang kali" |
| **Service down (A/D)** | "Service Y down, restarting..." | "Waduh kacau" |
| **Dapet flag besar** | "Flag X dapet, submit ya" | (langsung submit tanpa info tim) |

### Shared Resources

Tim harus punya **satu spreadsheet bersama** (Google Sheets / Notion) dengan:

| Soal | Kategori | Points | Status | Assigned | Notes |
|------|----------|:------:|:------:|:--------:|-------|
| Forensic 1 | Forensics | 100 | ✅ Solved | Alice | strings → base64 decode |
| Web 1 | Web | 200 | 🔴 Stuck | Bob | SQL injection butuh bypass WAF |
| Crypto 1 | Crypto | 300 | ⏸️ Skipped | — | RSA, N besar → factordb? |

**Format flag:**
```
flag{nama_soal_flag}
```

---

## Tools Prioritization — Fallback Chain

Untuk setiap kategori, punya **3 tier tool**:

| Tier | Arti | Contoh |
|:----:|------|--------|
| **Tier 1** | Default — langsung jalan | CyberChef, strings, file, exiftool, nmap |
| **Tier 2** | Spesifik — butuh setup minimal | Volatility, Ghidra, foremost, sqlmap |
| **Tier 3** | Advanced — butuh waktu setup | Plaso, custom script, IDA Pro |

**Aturan:** Jika Tier 1 gagal, jangan langsung Tier 3 — coba **Tier 2** dulu untuk 15 menit. Jika masih gagal, baru Tier 3.

### Tool Fallback per Kategori

**Forensics:** exiftool → strings → foremost → binwalk → Volatility 3 → plaso
**Web:** curl → nmap → gobuster → sqlmap → Burp Suite
**PWN:** checksec → objdump → gdb → pwntools → ROPgadget
**Crypto:** CyberChef Magic → hash-identifier → xortool → RsaCtfTool
**RE:** strings → file → objdump → Ghidra → gdb

---

## Post-Mortem & Knowledge Base

### Setelah Kompetisi Selesai

Dalam 24 jam setelah kompetisi, lakukan **writeup**:

1. **Tulis setiap soal yang solved** — langkah, tool, command, flag
2. **Tulis setiap soal yang NOT solved** — analisis: kurang tool? waktu? skill?
3. **Simpan attachment soal** — karena biasanya ditutup setelah event
4. **Catat insight unik** — mis: "di soal forensic ternyata ada hidden NTFS stream"

### Writeup Template

```markdown
# [Nama Kompetisi] — [Soal Nama]

**Kategori:** [Forensic / Web / PWN / Crypto / RE / Misc]
**Points:** [100]
**Status:** ✅ Solved | ❌ Not Solved

## Deskripsi Soal
[Copy paste deskripsi dari soal]

## Attachment
[Path ke attachment yang disimpan]

## Solusi

### Langkah 1: ...
Command: `...`
Output: `...`

### Langkah 2: ...
...

## Flag
```
flag{...}
```

## Key Takeaway
[Apa yang dipelajari dari soal ini]
```

### Knowledge Base dari Writeup

Kumpulkan writeup di folder `03_Resources/[nama-event]/`. Link ke [[ctf-tool-arsenal-universal]] jika ada tool baru yang dipelajari. Update tool arsenal jika ada tool yang ternyata berguna.

**Yang wajib dicatat:**
- Command yang berhasil — jangan lupa flag path
- Tool version — tool update bisa ubah behavior
- One-liner yang berguna — untuk reuse di event berikutnya

---

## Quick Reference — One-Liners Penting

```bash
# Cari flag dalam semua file
grep -r "CTF{" .

# Cari string base64: minimal 32 char, alphanumeric
strings file | grep -E "^[A-Za-z0-9+/]{32,}={0,2}$"

# Cek magic bytes file
xxd file | head -1

# Extract semua string ASCII printable
strings -n 6 file

# Carving dengan foremost
foremost -T -i file -o output/

# Binwalk extract semua embedded file
binwalk -Me file

# Volatility 3: cari process anomali
python3 vol.py -f memory.dump windows.psscan

# Ekstrak file dari PCAP HTTP
tshark -r capture.pcap --export-objects http,output/
```

---

## Cross-Link

- **Hierarchy Level Kompetisi** → [[hierarchy-ctf-competition-framework]]
- **Attack-Defense Range** → [[hierarchy-cyber-range-adversary-emulation]]
- **Digital Evidence Acquisition** → [[hierarchy-digital-evidence-acquisition]]
- **Tool Arsenal Lengkap** → [[ctf-tool-arsenal-universal]]
- **PicoCTF Beginner Guide** → [[picoctf-master-index]]
- **Master Index** → [[master-index]]

---

*CTF Methodology & Strategy · Universal — tidak terikat event · Triage > Brute Force · Team Communication = Force Multiplier*
---

audited
---
