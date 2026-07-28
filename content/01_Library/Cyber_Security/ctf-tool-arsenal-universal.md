---
title: "CTF Tool Arsenal — Universal Reference"
tags:
  - ctf
  - tools
  - cheat-sheet
  - forensic-tools
  - exploitation
  - reverse-engineering
aliases:
  - "ctf-tool-arsenal-universal"
created: "2026-07-28"
updated: "2026-07-28"
status: active
---

# 🛠️ CTF Tool Arsenal — Universal Reference

> **Kumpulan tools per kategori kompetisi** yang universal dan tidak terikat event tertentu. Setiap tool disertai: cara install, command dasar, dan kapan pakainya. Untuk metodologi lengkap, lihat [[ctf-competition-methodology-strategy]]. Untuk level kompetisi, lihat [[hierarchy-ctf-competition-framework]].

> [!tip] Tool Tier System
> **Tier 1** = Default, langsung jalan, minimal setup. **Tier 2** = Spesifik, butuh instalasi. **Tier 3** = Advanced, butuh waktu/sumber daya besar. **Gunakan Tier 1 dulu — jika gagal, baru Tier 2, lalu Tier 3.**

---

## Daftar Isi

- [[#Universal — Semua Kategori]]
- [[#Digital Forensic]]
- [[#Network Forensic]]
- [[#Memory Forensic]]
- [[#Binary Exploitation (PWN)]]
- [[#Web Exploitation]]
- [[#Cryptography]]
- [[#Reverse Engineering]]
- [[#Steganography]]
- [[#OSINT]]
- [[#Attack Defense — Hardening & Monitoring]]
- [[#Incident Response]]
- [[#Scripting & Automation]]
- [[#Environment Setup — Docker Images]]

---

## Universal — Semua Kategori

### 🧰 CyberChef (Tier 1)

Tool paling serbaguna di CTF. **Buka di browser — tidak perlu install.**

| Fungsi               | Recipe                                        |
| -------------------- | --------------------------------------------- |
| Auto-detect encoding | `Magic` — biarkan CyberChef detect otomatis   |
| From Base64          | `From Base64`                                 |
| XOR Brute Force      | `XOR Brute Force` — coba semua key length 1-4 |
| Extract strings      | `Extract Strings`                             |
| Hex dump             | `To Hex` / `From Hex`                         |
| ROT13                | `ROT13` — atau `ROT Brute Force`              |
| JSON/XML format      | `Syntax Highlighter`                          |
| Regex extract        | `Regular expression` — `CTF\{[^}]+\}`         |

> **Install:** https://gchq.github.io/CyberChef/ (web) atau `docker run --rm -p 8080:80 ghcr.io/gchq/CyberChef:latest`

### 🧰 Command Line Essentials (Tier 1 — already installed)

```bash
file          # Cek tipe file
strings -n 6  # Extract string minimal 6 karakter
xxd | head    # Hex dump
hexdump -C    # Canonical hex dump
head/tail     # Baca awal/akhir file
wc -l         # Hitung baris
sort | uniq -c # Unique sort + count
grep -r       # Cari string recursif
sed -n '10,20p' # Print line range
awk '{print $1}' # Column extraction
diff          # Bandingkan dua file
sha256sum     # Hash verification
base64        # Encode/decode base64
tr            # Character translation
od            # Octal/hex dump alternatif
```

---

## Digital Forensic

### 💽 Sleuth Kit (Tier 1)

Tool suite analisis filesystem — **wajib install**.

| Command                           | Fungsi                  | Contoh                       |
| --------------------------------- | ----------------------- | ---------------------------- |
| `mmls image.dd`                   | List partition table    | Identifikasi offset partisi  |
| `fls -o OFFSET image.dd`          | List file dalam partisi | Cari file yang ada + deleted |
| `icat -o OFFSET image.dd INODE`   | Extract file by inode   | Baca file spesifik           |
| `istat -o OFFSET image.dd INODE`  | Metadata inode          | Timestamp, size, permission  |
| `srch_strings -o OFFSET image.dd` | Strings dalam partisi   | Cari flag di partisi mentah  |
| `fsstat -o OFFSET image.dd`       | Filesystem statistics   | Informasi detail filesystem  |

> **Install:** `sudo apt install sleuthkit` / `brew install sleuthkit`

### 💽 Autopsy (Tier 2)

GUI framework forensik — wrapper Sleuth Kit dengan timeline + keyword search.

> **Install:** `sudo apt install autopsy` atau download dari https://www.autopsy.com/

### 💽 Foremost (Tier 1)

File carving berdasarkan magic bytes signature. **Recover file yang dihapus.**

```bash
foremost -T -i evidence.dd -o output/
```

> **Install:** `sudo apt install foremost`

### 💽 Scalpel (Tier 2)

File carving yang lebih configurable daripada foremost.

```bash
# Edit /etc/scalpel/scalpel.conf dulu — uncomment file types yang dicari
scalpel evidence.dd -o output/
```

> **Install:** `sudo apt install scalpel`

### 💽 Photorec / TestDisk (Tier 1)

PhotoRec = carving media (foto, dokumen). TestDisk = partition recovery.

```bash
sudo photorec /path/to/image.dd   # Interactive — pilih destination
testdisk /path/to/image.dd        # Recover partition table
```

> **Install:** `sudo apt install testdisk`

### 💽 Binwalk (Tier 1)

**Ekstrak embedded file** dari firmware/image/binary.

```bash
binwalk -Me firmware.bin    # Extract semua embedded file recursive
binwalk -Me file            # Auto extract ke folder _file.extracted/
```

> **Install:** `pip install binwalk` atau `sudo apt install binwalk`

### 💽 Plaso / log2timeline (Tier 3)

**Timeline analysis** — buat timeline dari semua file dalam image. Output ke Elasticsearch atau CSV.

```bash
log2timeline --storage timeline.plaso evidence.dd
psort -o l2tcsv -w timeline.csv timeline.plaso
```

> **Install:** `pip install plaso` atau `docker run log2timeline/plaso`

### 💽 Registry Analyzer — regripper (Tier 2)

Windows Registry analysis.

```bash
# Extract registry dari image
icat -o OFFSET image.dd INODE > SYSTEM
# Parse dengan regripper
rip.pl -r SYSTEM -f system
```

> **Install:** `git clone https://github.com/keydet89/RegRipper3.0`

### 💽 Windows Artifact Analysis

```bash
# Prefetch parser (PECmd)
PECmd.exe -f C:\Windows\Prefetch\*.pf --csv output.csv

# Jump List parser (JLECmd)
JLECmd.exe -f "C:\Users\user\AppData\...\*.automaticDestinations-ms"

# Recent file parser (RECmd)
RECmd.exe --dv C:\Users\user\ --nl output.csv
```

> **Sumber:** Eric Zimmerman tools — https://ericzimmerman.github.io/

---

## Network Forensic

### 🌐 Wireshark / TShark (Tier 1)

**Wajib untuk PCAP analysis.**

```bash
# Statistik capture
capinfos capture.pcap

# Filter + export HTTP objects
tshark -r capture.pcap --export-objects http,output/

# Follow TCP stream — cari flag
tshark -r capture.pcap -z follow,tcp,ascii,0

# Cari DNS query tertentu
tshark -r capture.pcap -Y "dns.qry.name contains flag"

# HTTP request dengan method GET
tshark -r capture.pcap -Y "http.request.method == GET"

# Export file via SMB
tshark -r capture.pcap --export-objects smb,output/
```

### 🌐 Tcpdump (Tier 1 — already installed)

Live capture + analisis.

```bash
# Capture ke file
tcpdump -i eth0 -w capture.pcap

# Baca file dengan filter
tcpdump -r capture.pcap -X

# Filter port dan protocol
tcpdump -r capture.pcap port 80 or port 443
```

### 🌐 NetworkMiner (Tier 2)

GUI network forensic tools — **extract file dari PCAP secara otomatis.**

> **Install:** Download dari https://www.netresec.com/?page=NetworkMiner
> **Linux:** `mono NetworkMiner.exe -r capture.pcap`

### 🌐 Zeek / Bro (Tier 3)

**Network monitoring framework** — log semua koneksi.

```bash
zeek -r capture.pcap
# Output: conn.log, dns.log, http.log, ssl.log, etc.
cat conn.log | zeek-cut uid proto service duration
```

> **Install:** `sudo apt install zeek`

---

## Memory Forensic

### 🧠 Volatility 3 (Tier 1)

**Tool utama memory forensic.** Versi 3 adalah rewrite Python — tidak butuh profile.

```bash
# Info image
python3 vol.py -f memory.raw windows.info

# Process list
python3 vol.py -f memory.raw windows.psscan

# Network connections
python3 vol.py -f memory.raw windows.netscan

# Command line history per process
python3 vol.py -f memory.raw windows.cmdline

# Cari hidden/malicious process
python3 vol.py -f memory.raw windows.malfind

# Registry hive di memory
python3 vol.py -f memory.raw windows.registry.hivelist

# Hashdump (SAM + SYSTEM)
python3 vol.py -f memory.raw windows.hashdump

# Dump specific process memory
python3 vol.py -f memory.raw windows.dumpfiles --pid 1234

# Strings dari memory — cari flag
python3 vol.py -f memory.raw windows.strings --string "flag" --pattern "CTF"
```

> **Install:** `git clone https://github.com/volatilityfoundation/volatility3`

### 🧠 LiME (Tier 2)

**Acquire RAM dump** dari Linux.

```bash
# Compile kernel module
git clone https://github.com/504ensicsLabs/LiME
cd LiME/src && make

# Dump RAM
insmod lime.ko "path=/tmp/ram.dump format=lime"
```

### 🧠 WinPmem (Tier 2)

**Acquire RAM dump** dari Windows (live).

```bash
winpmem_mini_x64_rc2.exe memory.raw
```

### 🧠 Rekall (Tier 3)

Alternatif Volatility — fokus ke live analysis.

> **Install:** `pip install rekall`

---

## Binary Exploitation (PWN)

### 🔧 pwntools (Tier 1)

**Python framework untuk exploit development.** Wajib.

```python
from pwn import *

# Koneksi remote
r = remote('host', port)
r.sendline(b'payload')
r.recvuntil(b'flag:')
flag = r.recvline()
print(flag)

# Local binary
e = ELF('./binary')
offset = cyclic_find('aaaabaaacaaa')  # Cari offset

# ROP chain
rop = ROP(e)
rop.call('system', [next(e.search(b'/bin/sh'))])
```

> **Install:** `pip install pwntools`

### 🔧 checksec (Tier 1)

Cek security protection binary.

```bash
checksec --file=binary
# Output: NX, PIE, RELRO, Stack Canary, ASLR
```

> **Install:** `pip install pwntools` (include)

### 🔧 GDB + pwndbg (Tier 1)

**Debugger dengan plugin pwn.**

```bash
gdb -q ./binary
# pwndbg commands:
# cyclic 200    → generate pattern
# run           → jalankan binary
# pattern offset  → cari offset ke RIP
# vmmap         → lihat memory mapping
```

> **Install:** `sudo apt install gdb` + `git clone https://github.com/pwndbg/pwndbg`

### 🔧 Ghidra (Tier 2)

Decompiler + disassembler dari NSA. **Best-in-class untuk reverse + patch.**

```bash
# Headless mode — export decompiled C
./ghidraRun headless /tmp/project -import binary -postScript DecompileToCSource.java
```

> **Install:** Download dari https://ghidra-sre.org/

### 🔧 ROPgadget (Tier 1)

Cari ROP gadgets dalam binary.

```bash
ROPgadget --binary binary
ROPgadget --binary binary --ropchain  # Auto generate ROP chain
```

> **Install:** `pip install ROPgadget`

### 🔧 one_gadget (Tier 2)

Cari one-shot RCE (execve("/bin/sh")) di libc.

```bash
one_gadget /lib/x86_64-linux-gnu/libc.so.6
```

> **Install:** `gem install one_gadget` (Ruby required)

---

## Web Exploitation

### 🌍 Burp Suite (Tier 1)

**Proxy intercept + repeater + intruder.** Wajib.

| Fitur    | Fungsi                               |
| -------- | ------------------------------------ |
| Proxy    | Intercept HTTP/HTTPS request         |
| Repeater | Send ulang request dengan modifikasi |
| Intruder | Brute force parameter, fuzzing       |
| Decoder  | URL/Base64/hex encode-decode         |

> **Install:** Download Community Edition dari https://portswigger.net/burp

### 🌍 gobuster (Tier 1)

**Directory/file discovery.**

```bash
gobuster dir -u http://target -w /usr/share/wordlists/dirb/common.txt
gobuster dir -u http://target -w wordlist.txt -x php,html,txt
gobuster dns -d target.com -w subdomains.txt
```

> **Install:** `sudo apt install gobuster`

### 🌍 ffuf (Tier 1)

**Parameter fuzzing** — cepat, multi-threaded.

```bash
# Directory fuzzing
ffuf -u http://target/FUZZ -w wordlist.txt

# Parameter fuzzing
ffuf -u http://target/page?FUZZ=test -w params.txt

# Value fuzzing
ffuf -u http://target/page?param=FUZZ -w values.txt

# POST data fuzzing
ffuf -u http://target/login -X POST -d "user=FUZZ&pass=test" -H "Content-Type: application/x-www-form-urlencoded" -w users.txt
```

> **Install:** `go install github.com/ffuf/ffuf@latest`

### 🌍 sqlmap (Tier 1)

**SQL Injection automation.**

```bash
# Auto-detect + extract DB
sqlmap -u "http://target/?id=1" --batch --dump

# Request from file (dari Burp)
sqlmap -r request.txt --batch --dump

# Bypass WAF
sqlmap -u "http://target/?id=1" --tamper=space2comment --batch

# OS shell
sqlmap -u "http://target/?id=1" --os-shell
```

> **Install:** `sudo apt install sqlmap`

### 🌍 curl / wget (Tier 1 — already installed)

```bash
# Basic GET
curl -v http://target:port

# POST data
curl -X POST -d "user=admin&pass=admin" http://target/login

# With cookies
curl -b "session=abc123" http://target/dashboard

# Follow redirect
curl -L http://target

# Save response
curl -o output.html http://target
```

### 🌍 jwt_tool (Tier 2)

**JWT analysis + attack.**

```bash
# Decode JWT
jwt_tool token.jwt

# None algorithm attack
jwt_tool token.jwt -X a

# Brute key
jwt_tool token.jwt -C -d wordlist.txt
```

> **Install:** `git clone https://github.com/ticarpi/jwt_tool`

### 🌍 git-dumper (Tier 2)

**Extract exposed .git repository.**

```bash
git-dumper http://target/.git/ output/
```

> **Install:** `pip install git-dumper`

---

## Cryptography

### 🔐 CyberChef Magic (Tier 1)

**Deteksi encoding/encryption otomatis.** Tanpa install — web.

> Recipe: `Magic` → pilih intensitas (High untuk brute force singkat)

### 🔐 RsaCtfTool (Tier 2)

**Automated RSA attack.**

```bash
# Dari modulus n, exponent e, ciphertext c
python RsaCtfTool.py -n 123456 -e 65537 --uncipher 987654

# Dari dua key dengan common prime
python RsaCtfTool.py --key key1.pub --key key2.pub

# Attack modes: wiener, smallfraction, commonfactor, hastad, etc
```

> **Install:** `git clone https://github.com/RsaCtfTool/RsaCtfTool`

### 🔐 xortool (Tier 1)

**XOR key length detection + brute force.**

```bash
# Cari key length
xortool cipher.bin

# Brute dengan key length tertentu
xortool cipher.bin -l 5 -b
```

> **Install:** `pip install xortool`

### 🔐 hash-identifier (Tier 1)

**Identifikasi tipe hash.**

```bash
hashid hash.txt
hash-identifier 5d41402abc4b2a76b9719d911017c592
# Output: MD5
```

> **Install:** `sudo apt install hashid hash-identifier`

### 🔐 hashcat (Tier 2)

**GPU-accelerated hash cracking.**

```bash
# MD5 brute force
hashcat -m 0 -a 3 hash.txt ?a?a?a?a?a?a

# SHA256 with wordlist
hashcat -m 1400 hash.txt wordlist.txt

# NTLM with rules
hashcat -m 1000 hash.txt wordlist.txt -r /usr/share/hashcat/rules/best64.rule
```

> **Install:** `sudo apt install hashcat` atau download dari https://hashcat.net/

### 🔐 John the Ripper (Tier 1)

**CPU-based hash cracking.**

```bash
# Auto-detect hash type
john hash.txt

# With wordlist
john --wordlist=wordlist.txt hash.txt

# Show cracked
john --show hash.txt
```

> **Install:** `sudo apt install john`

### 🔐 OpenSSL (Tier 1 — already installed)

```bash
# Decrypt RSA
openssl rsautl -decrypt -inkey private.pem -in ciphertext.bin

# Base64 decode
openssl enc -base64 -d -in encoded.txt

# AES decrypt
openssl enc -aes-256-cbc -d -in encrypted.bin -out decrypted.txt -pass pass:key
```

---

## Reverse Engineering

### 🔍 strings / file (Tier 1 — already installed)

```bash
strings binary | grep -i flag
file binary
```

### 🔍 Ghidra (Tier 2)

**Decompiler paling kuat dari NSA.** Headless mode:

```bash
./ghidraRun headless /tmp/project -import binary -postScript DecompileToCSource.java
```

### 🔍 radare2 / cutter (Tier 1)

**CLI + GUI disassembler/decompiler.**

```bash
# Analyze binary
r2 binary
> aaaa        # Full analysis
> afl         # List functions
> pdb @ main  # Debug main function
> V           # Visual mode

# Cutter = GUI version of radare2
cutter binary
```

> **Install:** `sudo apt install radare2 cutter`

### 🔍 objdump / readelf (Tier 1 — already installed)

```bash
# Disassemble
objdump -d binary | head -100

# Sections
objdump -x binary

# Symbols
nm binary | grep -i flag

# ELF info
readelf -a binary | head -50
```

### 🔍 dnSpy / ILSpy (Tier 2 — Windows)

**.NET decompiler.** Buka .NET DLL/EXE langsung.

> **Install:** https://github.com/dnSpy/dnSpy

---

## Steganography

### 🖼️ zsteg (Tier 1)

**Deteksi steganografi PNG/BMP.**

```bash
zsteg image.png
zsteg -a image.png  # Extended analysis
```

> **Install:** `gem install zsteg`

### 🖼️ steghide (Tier 1)

**JPEG/BMP steganography.**

```bash
# Extract data
steghide extract -sf image.jpg

# With passphrase
steghide extract -sf image.jpg -p password

# Info
steghide info image.jpg
```

> **Install:** `sudo apt install steghide`

### 🖼️ stegsolve (Tier 2)

**GUI steganography tool** — plane analysis, LSB, bit shift, color filter.

```bash
java -jar stegsolve.jar
```

> **Install:** Download dari https://github.com/zardus/ctf-tools/blob/master/stegsolve/install

### 🖼️ binwalk (Tier 1)

**Cari file embedded dalam image.**

```bash
binwalk -Me image.png   # Extract embedded files
```

### 🖼️ exiftool (Tier 1)

**Metadata extraction.**

```bash
exiftool image.jpg
# Cek: GPS, author, software, comment, timestamps
```

> **Install:** `sudo apt install exiftool`

### 🖼️ Audacity / Sonic Visualiser (Tier 2)

**Audio steganography** — spectrogram, reverse audio, hidden channel.

> **Install:** `sudo apt install audacity`

---

## OSINT

### 🔎 Google Dorking (Tier 1)

```bash
site:target.com "flag" OR "ctf"
site:pastebin.com "nama_kompetisi"
filetype:pdf "nama_tim"
```

### 🔎 exiftool (Tier 1)

```bash
exiftool -a image.jpg   # Semua metadata termasuk GPS
```

### 🔎 theHarvester (Tier 2)

**Email/subdomain discovery.**

```bash
theHarvester -d target.com -b google
```

> **Install:** `sudo apt install theharvester`

---

## Attack Defense — Hardening & Monitoring

### 🛡️ Nmap (Tier 1)

```bash
# Scan semua port
nmap -p- target

# Service detection
nmap -sV -p 80,443 target

# OS detection
nmap -O target

# Script scan
nmap --script=vuln target
```

### 🛡️ iptables / nftables (Tier 1)

```bash
# Allow specific port
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT
iptables -A INPUT -j DROP  # Drop all other

# Rate limit (10 req/detik)
iptables -A INPUT -p tcp --dport 80 -m limit --limit 10/s -j ACCEPT

# Save rules
iptables-save > /etc/iptables/rules.v4
```

### 🛡️ fail2ban (Tier 1)

```bash
# Install & start
sudo apt install fail2ban
sudo systemctl enable --now fail2ban

# Custom jail
cat /etc/fail2ban/jail.local
[sshd]
enabled = true
maxretry = 3
bantime = 3600
```

### 🛡️ Lynis (Tier 2)

**System security audit.**

```bash
sudo lynis audit system
```

> **Install:** `sudo apt install lynis`

---

## Incident Response

### 🚨 Sysinternals Suite (Tier 1 — Windows)

```bash
# List running processes
pslist.exe

# Autoruns — startup programs
autorunsc.exe -a

# Process explorer — detailed process info
procexp.exe

# TCP connections
tcpview.exe

# Handle viewer
handle.exe
```

> **Download:** https://learn.microsoft.com/en-us/sysinternals/

### 🚨 Wazuh (Tier 3)

**Open source SIEM + EDR.**

> **Install:** `docker-compose up -d` (https://documentation.wazuh.com/)

### 🚨 YARA (Tier 2)

**Malware classification rules.**

```bash
# Scan dengan rule
yara rule.yar suspicious_file

# Cari rule untuk malware tertentu
git clone https://github.com/Yara-Rules/rules
```

> **Install:** `sudo apt install yara`

### 🚨 Sigma (Tier 2)

**Generic SIEM detection rule.**

```bash
# Convert Sigma rule ke format SIEM
sigmac -t splunk rule.yml
sigmac -t elk rule.yml
```

> **Install:** `pip install sigma` (https://github.com/SigmaHQ/sigma)

---

## Scripting & Automation

### 🐍 Python (Tier 1 — already installed)

Template script untuk kompetisi:

```python
#!/usr/bin/env python3
import sys, os, re, subprocess, socket, requests, json, base64, hashlib, struct
from pwn import *  # Jika pwntools terinstall

def get_flag(input_data):
    """Template fungsi extract flag"""
    match = re.search(r'CTF\{[^}]+\}', input_data)
    return match.group(0) if match else None

def solve():
    """Main solve function"""
    # Read file
    with open('attachment', 'r') as f:
        data = f.read()
    flag = get_flag(data)
    print(f"Flag: {flag}")

if __name__ == '__main__':
    solve()
```

### 🐚 Bash one-liners

```bash
# Cari flag recursive — semua file
grep -roE "CTF\{[^}]+\}" .

# Cari flag dalam file — case insensitive
grep -ri "flag\|ctf\|key\|secret" .

# Cari base64 string dalam binary
strings file | grep -E "^[A-Za-z0-9+/]{32,}={0,2}$"

# Cari URL dalam file
grep -oE 'https?://[^ ]+' file

# Cari IP address
grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' file

# Recursive extract archive
for f in *.zip; do unzip -o "$f"; done

# Base64 decode inline
echo "ZmxhZ..." | base64 -d
```

---

## Environment Setup — Docker Images

Image Docker yang siap pakai untuk CTF lab:

```bash
# Kali Linux — semua tools terinstall
docker pull kalilinux/kali-rolling
docker run -it kalilinux/kali-rolling
# Di dalam: apt update && apt install kali-linux-headless

# CTF Platform lokal (FBCTF, CTFd)
docker run -d -p 8000:8000 ctfd/ctfd

# Tool-specific containers
docker run --rm -it remnux/remnux:latest  # Reverse engineering + malware analysis
docker run --rm -it ctfhub/base  # CTFHub base environment

# Multi-tool container
docker pull python:3.11-slim
docker run -it python:3.11-slim bash
pip install pwntools requests pycryptodome
```

---

## Cross-Link

- **Methodology & Strategy** → [[ctf-competition-methodology-strategy]]
- **Hierarchy Level Kompetisi** → [[hierarchy-ctf-competition-framework]]
- **Digital Evidence Acquisition** → [[hierarchy-digital-evidence-acquisition]]
- **Attack-Defense Range** → [[hierarchy-cyber-range-adversary-emulation]]
- **PicoCTF Beginner Guide** → [[picoctf-master-index]]
- **Master Index** → [[master-index]]

---

_CTF Tool Arsenal Universal · Tier 1 → Tier 3 per Kategori · Belajar dulu command dasarnya, baru tool canggih · Environment Setup = Hari Pertama, Tool Mastery = Selamanya_
