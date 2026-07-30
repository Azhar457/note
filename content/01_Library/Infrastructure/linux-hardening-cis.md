---
title: "Linux Hardening CIS"
tags:
  - infrastructure
  - security
  - linux
  - hardening
  - cis-benchmark
aliases:
  - "Linux Server Hardening"
  - "CIS Benchmark Linux"
  - "Server Security Baseline"
created: "2026-07-11"
updated: "2026-07-11"
status: pending
cssclasses: ""
---

# 🔒 Linux Server Hardening — Security Baseline Progresif

> **Filosofi:** Hardening bukan checklist sekali jalan. Urutan penting — jangan UFW enable sebelum allow SSH, jangan set kernel params sebelum test reboot.

---

## Pendekatan Berlapis (Defense in Depth)

```
Layer 1: OS Hardening    → sysctl, user, service, password policy
Layer 2: Network Filter  → UFW / iptables, rate limiting
Layer 3: Intrusion Detection → AIDE, rkhunter, chkrootkit
Layer 4: Malware Scanner → ClamAV, LMD
Layer 5: Audit & Monitor → auditd, Lynis, logwatch
```

---

## Layer 1 — OS Hardening

### SSH Hardening

```bash
# /etc/ssh/sshd_config.d/hardening.conf
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers jars admin  # sesuaikan
```

| Setting | Efek |
|---------|------|
| `PermitRootLogin no` | Root gak bisa SSH langsung. `su` atau `sudo` aja |
| `PasswordAuthentication no` | Hanya key-based login |
| `MaxAuthTries 3` | Brute force 3× gagal → disconnect |

### System Hardening (sysctl)

```bash
# /etc/sysctl.d/99-hardening.conf

# Network hardening
net.ipv4.tcp_syncookies=1            # SYN flood protection
net.ipv4.tcp_rfc1337=1               # Better TIME-WAIT
net.ipv4.conf.all.rp_filter=1        # Reverse path filter
net.ipv4.conf.default.rp_filter=1
net.ipv4.conf.all.accept_source_route=0
net.ipv4.conf.default.accept_source_route=0
net.ipv6.conf.all.accept_source_route=0

# Disable IP forwarding (kecuali container host)
net.ipv4.ip_forward=0
net.ipv6.conf.all.forwarding=0

# Kernel hardening
kernel.randomize_va_space=2          # ASLR full
kernel.kptr_restrict=1               # Hidden kernel pointers
kernel.dmesg_restrict=1              # Root-only dmesg
fs.suid_dumpable=0                   # No core dump for SUID
kernel.core_uses_pid=1               # Core dump with PID
```

> [!warning] IP Forwarding
> Server yang jalanin Podman/Docker butuh `net.ipv4.ip_forward=1`. Jangan copy-paste dari hardening guide tanpa konteks.

### Password Policy

```bash
# Install
apt install libpam-pwquality

# /etc/pam.d/common-password
password requisite pam_pwquality.so retry=3 \
  minlen=12 difok=3 ucredit=-1 lcredit=-1 dcredit=-1

# /etc/login.defs
PASS_MAX_DAYS 90
PASS_MIN_DAYS 1
PASS_WARN_AGE 14
```

---

## Layer 2 — UFW

```bash
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh  # SEBELUM enable!
ufw enable
ufw status verbose
```

> [!tip] Double Firewall Trap
> Beberapa VPS provider (Contabo, dll) punya **hypervisor firewall sendiri** di panel kontrol. UFW dianggap allow → tapi traffic masih diblokir di level hypervisor. Cek panel! Kalau SSH timeout padahal UFW allow → 99% hypervisor firewall.

### Rate Limiting

```bash
ufw limit ssh  # 6 connection per 30s per IP
```

---

## Layer 3 — File Integrity Monitoring (AIDE)

```bash
# Install
apt install aide aide-common

# Init DB (first run — catat output fingerprint!)
sudo aideinit
mv /var/lib/aide/aide.db.new /var/lib/aide/aide.db

# Check
sudo aide --check

# Daily check via cron
sudo aide --check | mail -s "AIDE Report" admin@domain
```

| Tool | Fungsi | False Positive Rate |
|------|--------|-------------------|
| **AIDE** | File integrity (database-based) | Rendah |
| **rkhunter** | Rootkit detection | Sedang |
| **chkrootkit** | Rootkit detection | Rendah |

---

## Layer 4 — Malware Scanner

```bash
# ClamAV
apt install clamav clamav-daemon
freshclam  # update signatures
clamscan -r /home /var/www --bell -i

# LMD (Linux Malware Detect)
wget http://www.rfxn.com/downloads/maldetect-current.tar.gz
tar xzf maldetect-current.tar.gz && cd maldetect-*
./install.sh
```

---

## Layer 5 — Auditing

### Lynis — Security Audit

```bash
apt install lynis
lynis audit system
# Score awal rata-rata 60-70, target >75
```

| Area | Skor Rendah (<70) | Skor Medium (70-80) | Skor Tinggi (>80) |
|------|------------------|--------------------|--------------------|
| Firewall | UFW gak aktif | UFW aktif + allow minimal | UFW + iptables rules custom |
| File integrity | Gak ada AIDE | AIDE terinstall | AIDE + daily check |
| Kernel | Default kernel | sysctl hardening | + Kernel live patch |
| Auth | Password login | Key + password policy | + 2FA |

### auditd — Audit Trail

```bash
apt install auditd
auditctl -w /etc/passwd -p wa -k passwd_changes
auditctl -w /etc/ssh/sshd_config -p wa -k ssh_changes
ausearch -k ssh_changes  # lihat log
```

---

## Fast Recovery — Rollback Steps

| Yang Dirubah | Rollback |
|-------------|----------|
| sysctl | `sysctl -p /etc/sysctl.d/99-hardening.conf` (kembali ke default OS) |
| UFW lockout | Console/VNC → `ufw disable` |
| SSH config salah | Console → `ssh -o PermitRootLogin=yes` (sementara) |
| AIDE false positive | `aide --update` (rebuild DB) |

---

## Scoring Progression Pipeline (Lynis)

```
Before:  66 ─▶ OS hardening + SSH + UFW       ─▶ 70
         70 ─▶ Malware scanner + AIDE          ─▶ 73
         73 ─▶ sysctl hardening + auditd       ─▶ 76
         76 ─▶ Password policy + kernel params ─▶ 78+
```

---

---

## 🧠 Berpikir — Metodologi Penyusunan Catatan

Catatan ini disusun melalui proses berpikir terstruktur sebagai berikut:

### 1. Thinking Type yang Digunakan

| Type | Kenapa | Bagian |
|------|--------|--------|
| **Analysis Thinking** | Memecah hardening jadi 5 layer independen (OS → Network → IDS → Malware → Audit), tiap layer punya fungsi spesifik tanpa overlap | Seluruh struktur 5 layer |
| **Strategic Thinking** | Urutan penting — SSH dulu sebelum UFW, sysctl sebelum reboot, AIDE init sebelum check. Salah urut = lockout | Warning di tiap layer |
| **Concrete Thinking** | Command exact untuk setiap tool — copy-paste safe. Konfig file hardening dengan nilai spesifik | Semua box konfigurasi |
| **Futures Thinking** | Lynis scoring progression — dari 66 ke 78+ — menunjukkan path perbaikan bertahap, bukan checklist sekali jalan | Scoring Pipeline |

### 2. Background Knowledge (Pra-Penulisan)

- **VPS2 hardening real experience**: skor Lynis naik 66→76 setelah tambah malware scanner, AIDE, sysctl hardening, password policy, disable core dump
- **Contabo double firewall**: pengalaman SSH timeout karena hypervisor firewall terlewat — documented di UFW tip
- **sysctl interaction**: `net.ipv4.ip_forward=0` di hardening guide akan break container networking — peringatan di box warning
- **AIDE init**: DB pertama kali harus di-create sebelum check. File `.db.new` perlu di-rename — common tripping point
- **Rollback priority**: tahu mana yang bisa di-revert (sysctl, UFW) dan mana yang permanent (password policy)

### 3. RAG Vault — Dokumen yang Dikonsultasi

| Dokumen | Kontribusi |
|---------|-----------|
| [[infrastructure-administrator|Infrastructure Administrator]] | Server layout — konteks server mana yang di-hardening |
| [[podman-networking-ufw|Podman Networking & UFW]] | Interaksi UFW dengan container — `ip_forward` warning |
| [[network-security|Network Security]] | OSI layer — dimana tiap alat keamanan beroperasi |
| [[devops|DevOps Roadmap]] | Production deployment context |

### 4. Sintesis — Bagian  Bagian Bergabung

```
Background Knowledge (hardening from real VPS ops + container awareness)
    │
    ▼
RAG Vault (konteks infrastructure existing)
    │
    ▼
Strategic:   5 layers in sequence — urutan penting, jangan skip
    │
    ▼
Analytical:  Each layer decomposed → tool selection → compare options
    │
    ▼
Concrete:    Exact config files → commands → verification steps
    │
    ▼
Futures:     Scoring progression → from 66 to 78+ → continuous improvement path
    │
    ▼
Critical:    Rollback plan → mana yang reversible, mana yang butuh console
```

### 5. Sequential Thinking Steps

```
Thought 1 (Strategic):   "Hardening bukan checklist. Urutan penting — SSH dulu, baru UFW."
Thought 2 (Analytical):  "Harus 5 layer. Jangan cuma firewall. OS + Network + IDS + Malware + Audit."
Thought 3 (Strategic):   "Layer 1 dulu — OS hardening. SSH config + sysctl + password policy."
Thought 4 (Concrete):    "Exact SSH hardening config. Exact sysctl values. Exact PAM config."
Thought 5 (Systems):     "Tapi sysctl ip_forward=0 bakal break container. Kasih warning."
Thought 6 (Futures):     "Lynis scoring: 66→70→73→76→78+. Setiap milestone jelas next step."
Thought 7 (Critical):    "Apa yang terjadi kalau SSH lockout? Rollback via console. Dokumentasiin."
```

---

## 🔗 Lihat Juga

- [[infrastructure-administrator|Infrastructure Administrator]] — Server overall layout
- [[podman-networking-ufw|Podman Networking & UFW]] — Firewall specifics for containers
- [[network-security|Network Security]] — OSI layer context
- [[devops|DevOps Roadmap]] — Production deployment
