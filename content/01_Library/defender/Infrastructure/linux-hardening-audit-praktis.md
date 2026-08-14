---
title: Linux System Hardening & Audit Praktis
tags:
  - devops
  - linux
  - hardening
  - auditd
  - security
  - selinux
  - apparmor
  - library
aliases:
  - Linux Hardening Commands
  - Auditd Setup Guide
  - SELinux AppArmor Praktik
created: "2026-07-30"
updated: "2026-07-30"
status: pending
cssclasses:
  - wide-table
---

# 🔒 Linux System Hardening & Audit Praktis

> Panduan hardening Linux production dari SSH hardening, auditd configuration, SELinux/AppArmor policy, systemd security, kernel parameter tuning, sampai file integrity monitoring. Setiap bagian berisi command yang bisa langsung di-copy-paste, bukan teori doang. Vault udah punya [[linux-hardening-cis]] (referensi CIS benchmark) dan [[linux-fundamentals-deepdive]] (fundamental OS) — catatan ini jembatin keduanya ke implementasi praktis.

> [!tip] Root Cause
> Catatan ini lahir dari auditd yang "kosong" di Fedora 44 — ternyata `-a task,never` di default rules.d + auditd disabled + kernel tanpa `audit=1`. Hard knowledge gap antara konsep hardening dan implementasi.

## Daftar Isi

1. [[#1. SSH Hardening — First Line Defense]]
2. [[#2. Auditd — Kernel-Level Audit Trail]]
3. [[#3. SELinux & AppArmor — Mandatory Access Control]]
4. [[#4. Systemd Security — Service Isolation]]
5. [[#5. Kernel Hardening — Sysctl Parameters]]
6. [[#6. Fail2ban — Brute-Force Protection]]
7. [[#7. File Integrity Monitoring — AIDE]]
8. [[#8. CIS Benchmark — Automated Hardening]]
9. [[#9. Koneksi ke Vault]]

---

## 1. SSH Hardening — First Line Defense

SSH adalah pintu masuk utama ke server. Konfigurasi minimal yang WAJIB:

```ini
# /etc/ssh/sshd_config
Port 22
Protocol 2
PermitRootLogin prohibit-password      # atau no kalo gak perlu root SSH
PubkeyAuthentication yes
PasswordAuthentication no              # 🔑 Kunci utama: disable password auth
AuthenticationMethods publickey
MaxAuthTries 3
MaxSessions 10
ClientAliveInterval 300
ClientAliveCountMax 0
AllowUsers dev admin                   # whitelist user
# (Opsional) AllowGroups ssh-users
```

**Verifikasi**
```bash
sudo sshd -t                             # test config sebelum restart
sudo systemctl restart sshd
sudo grep "Failed password" /var/log/auth.log | wc -l  # jumlah brute-force attempt
```

### SSH Key dengan Passphrase (Zero Trust)

```bash
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/id_ed25519   # ED25519 > RSA4096
ssh-copy-id -i ~/.ssh/id_ed25519.pub user@host

# ssh-agent biar passphrase cuma sekali
eval $(ssh-agent)
ssh-add ~/.ssh/id_ed25519
```

### Fail2Ban untuk SSH

```ini
# /etc/fail2ban/jail.local
[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/auth.log
maxretry = 3
bantime = 3600
findtime = 600
```

---

## 2. Auditd — Kernel-Level Audit Trail

### 2.1. Root Cause Auditd "Kosong"

Di Fedora 44+, auditd sering "nganggur" karena 3 masalah berantai:

| Masalah | Akibat | Fix |
|---------|--------|-----|
| `auditd` disabled di systemd | Service gak start otomatis | `systemctl enable auditd --now` |
| Kernel tanpa `audit=1` | Audit subsystem inactive saat boot | Tambah `audit=1` di `GRUB_CMDLINE_LINUX` |
| Rules `-a task,never` | Semua syscall di-skip | Hapus file rules.d dengan `-a task,never` |

### 2.2. Aktifasi Lengkap

```bash
# 1. Kernel audit parameter
sudo sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="audit=1 /' /etc/default/grub
sudo grub2-mkconfig -o /boot/grub2/grub.cfg   # BIOS
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg  # UEFI Fedora

# 2. Hapus rules yang nge-block semua
sudo mv /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules.disabled

# 3. Install default rules dari distro
# Fedora: sample rules ada di /usr/share/audit/sample-rules/
sudo cp /usr/share/audit/sample-rules/10-base-config.rules /etc/audit/rules.d/
sudo cp /usr/share/audit/sample-rules/30-stig.rules /etc/audit/rules.d/  # opsional

# 4. Enable & start
sudo systemctl enable auditd --now
sudo auditctl -e 1   # enable kernel audit subsystem

# 5. Verifikasi
sudo auditctl -s | grep enabled   # harus "enabled 1"
sudo aureport --summary            # liat event summary
sudo ausearch -m USER_LOGIN -ts today  # login events hari ini
```

### 2.3. Custom Rules — Yang Paling Vital

```bash
# /etc/audit/rules.d/custom.rules
# Time changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change

# User/group modification
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k privilege

# Network config changes
-w /etc/hosts -p wa -k network
-w /etc/sysconfig/network -p wa -k network
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network

# Kernel module loading
-w /usr/sbin/insmod -p x -k modules
-w /usr/sbin/rmmod -p x -k modules
-w /usr/sbin/modprobe -p x -k modules

# Privileged commands (detect semua SUID)
# find / -xdev -type f -perm -4000 -o -type f -perm -2000 2>/dev/null
-a always,exit -F path=/usr/bin/su -F perm=x -F auid>=1000 -F auid!=unset -k privileged

# File deletion tracking
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=unset -k delete

# Immutable rule — PALING AKHIR
-e 2
```

### 2.4. Audit Log Management

```bash
# /etc/audit/auditd.conf
max_log_file = 128        # MB per file
num_logs = 10             # rotasi simpan 10 file
max_log_file_action = ROTATE
space_left = 75           # % disk
space_left_action = SYSLOG
admin_space_left = 50
admin_space_left_action = SUSPEND
disk_full_action = SUSPEND

# Tools audit
sudo aureport --summary                # ringkasan event
sudo aureport -m                       # per event type
sudo ausearch --start today -k identity# event dengan key tertentu
sudo ausearch -ul dev                  # event dari user tertentu
sudo aulast                            # login history dari audit log
```

---

## 3. SELinux & AppArmor — Mandatory Access Control

### 3.1. Cek Status MAC

```bash
# SELinux
getenforce                  # Enforcing / Permissive / Disabled
sudo sestatus               # detail lengkap
sudo semanage boolean -l    # lihat semua boolean
sudo seinfo -u              # lihat semua user SELinux

# AppArmor (Ubuntu/Debian)
sudo aa-status              # profiles loaded
sudo apparmor_status        # alternatif
```

### 3.2. SELinux Praktik

```bash
# Mengganti mode (tanpa reboot)
sudo setenforce 0   # Permissive — log doang, gak block
sudo setenforce 1   # Enforcing — block + log

# Troubleshooting — AVC denials
sudo ausearch -m avc -ts today    # audit log AVC denial
sudo sealert -a /var/log/audit/audit.log  # baca denial + saran fix
sudo grep AVC /var/log/messages    # alternative log

# Membuat policy module dari denial
sudo audit2allow -a -M mymodule    # generate .pp module
sudo semodule -i mymodule.pp       # install module

# Manage context file
sudo ls -Z /etc/passwd               # lihat SELinux context
sudo chcon -t httpd_sys_content_t /var/www/html -R  # ganti context web
sudo restorecon -Rv /var/www/html    # restore default context

# Samba / HTTP / Custom port
sudo semanage port -l | grep http
sudo semanage port -a -t http_port_t -p tcp 8080
sudo semanage fcontext -a -t httpd_sys_content_t "/srv/web(/.*)?"
sudo restorecon -Rv /srv/web
```

### 3.3. AppArmor Praktik (Ubuntu)

```bash
# Mode
sudo aa-complain /usr/bin/someapp   # complain mode (log doang)
sudo aa-enforce /usr/bin/someapp    # enforce

# Profiles
ls /etc/apparmor.d/
sudo aa-genprof /usr/bin/firefox    # generate profile interactively
sudo aa-logprof                     # scan audit log + suggest rules

# Reload
sudo systemctl reload apparmor
```

### 3.4. Kapan Pilih Yang Mana?

| Faktor | SELinux | AppArmor |
|--------|---------|----------|
| Label-based | ✅ Setiap file/process punya context | ❌ Path-based |
| Granularity | Sangat detail (types, roles, users) | Medium (path profiles) |
| Learning curve | Curam | Landai |
| Distro default | Fedora, RHEL, CentOS | Ubuntu, Debian, SUSE |
| Container support | ✅ Container SELinux labels | ❌ Limited |

---

## 4. Systemd Security — Service Isolation

Setiap service unit bisa di-hardening dengan directive:

```ini
# /etc/systemd/system/myapp.service
[Service]
# 🔒 Hardening
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
SystemCallFilter=~@clock @cpu-emulation @debug @module @mount @obsolete @raw-io
MemoryMax=512M
TasksMax=100

# Verifikasi
systemd-analyze security myapp.service
# Output: exposure level — coba tekan sampai 🟢 SAFE
```

### Hardening Levels

```bash
# Level minimum (production) — wajib
ProtectSystem=full
PrivateTmp=yes
NoNewPrivileges=yes

# Level medium
ProtectHome=yes
ProtectKernelTunables=yes
ProtectKernelModules=yes
ProtectControlGroups=yes
PrivateDevices=yes
RestrictAddressFamilies=AF_INET AF_INET6 AF_UNIX

# Level maximum (zero-compromise)
SystemCallArchitectures=native
SystemCallFilter=~@clock @debug @module @mount @obsolete @privileged @raw-io
CapabilityBoundingSet=
MemoryDenyWriteExecute=yes
LockPersonality=yes
RestrictRealtime=yes
```

Cek status:
```bash
systemd-analyze security myapp.service   # Skor exposure
systemd-analyze security --offline=false myapp.service # realtime check
```

---

## 5. Kernel Hardening — Sysctl Parameters

```bash
# /etc/sysctl.d/99-hardening.conf

# 🛡️ IP Spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 🛡️ SYN Flood
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 5
net.ipv4.tcp_synack_retries = 5

# 🛡️ Source Routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# 🛡️ ICMP Redirect
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# 🛡️ Martians
net.ipv4.conf.all.log_martians = 1

# 🛡️ Hardened TCP
net.ipv4.tcp_rfc1337 = 1               # time-wait assassination
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_timestamps = 0            # gak perlu, kurangi overhead

# Kernel
kernel.randomize_va_space = 2          # ASLR full
kernel.kptr_restrict = 1               # /proc/kallsyms restricted
kernel.dmesg_restrict = 1              # non-root gak bisa dmesg
kernel.perf_event_paranoid = 3         # non-root gak bisa perf
kernel.yama.ptrace_scope = 1           # hanya parent bisa ptrace child

# Apply
sudo sysctl --system
```

---

## 6. Fail2ban — Brute-Force Protection

```bash
# Install
sudo dnf install fail2ban   # Fedora
sudo apt install fail2ban   # Ubuntu

# Konfigurasi
sudo cp /etc/fail2ban/fail2ban.conf /etc/fail2ban/fail2ban.local

# /etc/fail2ban/jail.local
[DEFAULT]
bantime = 1h
findtime = 10m
maxretry = 5
ignoreip = 127.0.0.1/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log

# Verifikasi
sudo fail2ban-client status
sudo fail2ban-client status sshd          # banned IP list
sudo fail2ban-client set sshd unbanip 1.2.3.4  # manual unban
```

---

## 7. File Integrity Monitoring — AIDE

```bash
# Install
sudo dnf install aide   # Fedora
sudo apt install aide   # Ubuntu

# Init database (PERTAMA KALI)
sudo aideinit
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Konfigurasi
# /etc/aide.conf — atur apa yang di-monitor
/ R                     # root full
/etc p+i+n+u+g+s+md5   # /etc dengan checksum md5
/bin p+i+n+u+g+sha512  # /bin dengan sha512

# Check
sudo aide --check

# Update setelah perubahan legitimate
sudo aide --update
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Cron untuk daily check
# 0 6 * * * /usr/bin/aide --check | mail -s "AIDE Report" root
```

**Alternatif:** `tripwire` (lebih kompleks), `osquery` (real-time), Samhain (client-server).

---

## 8. CIS Benchmark — Automated Hardening

Tool auto-hardening berbasis CIS:

```bash
# Lynis — audit (read-only)
sudo lynis audit system

# OpenSCAP — compliance scan
sudo oscap xccdf eval   --profile xccdf_org.ssgproject.content_profile_cis   --results-arf results.xml   --report report.html   /usr/share/xml/scap/ssg/content/ssg-fedora-ds.xml

# Ansible Hardening
# ansible-galaxy install devsec.hardening
# ansible-playbook -i inventory playbook.yml
```

### Checklist Minimal Production

| Item | Command | Status |
|------|---------|--------|
| SSH password auth off | `grep PasswordAuthentication /etc/ssh/sshd_config` | ❌/✅ |
| auditd active | `systemctl is-active auditd` | ❌/✅ |
| SELinux enforcing | `getenforce` | ❌/✅ |
| Kernel ASLR | `sysctl kernel.randomize_va_space` (harus 2) | ❌/✅ |
| Fail2ban running | `systemctl is-active fail2ban` | ❌/✅ |
| Unattended upgrades | `systemctl status unattended-upgrades` | ❌/✅ |
| UFW enabled | `ufw status` | ❌/✅ |
| No root login SSH | `grep PermitRootLogin /etc/ssh/sshd_config` | ❌/✅ |

## 9. Extended SSH Hardening — Deep Dive

### 9.1. Key Types dan Algoritma

ED25519 dipilih sebagai default karena performa kriptografi yang setara RSA 4096 tapi dengan key size jauh lebih kecil (256 bit vs 4096 bit) dan verification speed yang lebih cepat. Urutan preferensi key type:

| Prioritas | Key Type | Bit Strength | Kecepatan Auth | Catatan |
|-----------|----------|-------------|----------------|---------|
| 1 🥇 | ED25519 | 128-bit | Tercepat | OpenSSH 6.5+, recommended |
| 2 🥈 | ECDSA (NIST P-256) | 128-bit | Cepat | FIPS compliant |
| 3 🥉 | RSA (4096) | 128-bit | Lambat | Kompatibilitas maksimal |
| ❌ | DSA | 80-bit | — | Disabled di OpenSSH 7.0+ |

### 9.2. Host Key Rotation

Host key server harus di-rotate secara periodik dan diverifikasi fingerprint-nya. Risiko host key statis: kompromi satu host → MitM semua session sebelumnya (no forward secrecy untuk host key).

```bash
# Generate fresh host keys (setelah migrasi/reimage)
sudo rm /etc/ssh/ssh_host_*
sudo ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ""
sudo ssh-keygen -t ecdsa -f /etc/ssh/ssh_host_ecdsa_key -N ""
sudo systemctl restart sshd

# Catat fingerprint untuk verifikasi
ssh-keygen -l -f /etc/ssh/ssh_host_ed25519_key.pub
```

### 9.3. SSHFP DNS Records

Publikasikan fingerprint host key di DNS via SSHFP record sehingga client bisa verify otomatis dengan `VerifyHostKeyDNS yes`:

```bash
# Generate SSHFP dari host key
ssh-keygen -r server.domain.com -f /etc/ssh/ssh_host_ed25519_key.pub
# Output: server.domain.com IN SSHFP 4 1 <hash> — tambahkan ke zone DNS

# Di client ~/.ssh/config
Host server.domain.com
    VerifyHostKeyDNS yes
```

### 9.4. ssh-audit — Automated Scanner

Gunakan `ssh-audit` untuk memindai konfigurasi SSH server sendiri:

```bash
git clone https://github.com/jtesta/ssh-audit
cd ssh-audit
python ssh-audit.py localhost

# Output akan menunjukkan: algoritma key exchange yang lemah,
# cipher tua (CBC, 3DES-CBC), MAC algorithm yang usang (HMAC-MD5)
# Rekomendasi: disable semua cipher dan MAC yang rated "weak"
```

### 9.5. Crypto Policy Hardening (Fedora/RHEL)

```bash
# Lihat policy aktif
update-crypto-policies --show  # FUTURE / DEFAULT / LEGACY

# Set ke mode paling ketat — disable SHA-1, DH params kecil, CBC
sudo update-crypto-policies --set FUTURE
sudo reboot
# Cek dampak: legacy SSH clients (OpenSSH <7.4) dan tool lama akan gagal konek
```

> [!warning] FUTURE policy memutus klien SSH lawas (OpenSSH < 7.4) — tes dulu di staging sebelum apply ke production.

## 10. Auditd Rules Deep-Dive — Penjelasan Setiap Syscall Group

### 10.1. Time Changes (`-k time-change`)

```bash
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change
```

**Mengapa diaudit:** Serangan seperti *Time-Based Token Replay* bisa memanipulasi system clock untuk memvalidasi token kedaluwarsa atau memanipulasi log timestamp. `adjtimex` dan `settimeofday` mengubah waktu sistem langsung; `clock_settime` dipakai oleh NTP dan `timedatectl`. Log semua perubahan waktu penting untuk forensic timeline integrity.

### 10.2. User/Group Modification (`-k identity`)

```bash
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/sudoers -p wa -k privilege
```

**Mengapa:** Setiap perubahan di file ini menandakan penambahan/pengubahan/penghapusan user. Backdoor paling umum: attacker menambah user baru di `/etc/passwd` dengan UID 0 (root). `sudoers` adalah target utama privilege escalation. Flag `-p wa` artinya *write* dan *attribute change* — jadi perubahan permission (`chmod`) juga tercatat.

### 10.3. Network Configuration (`-k network`)

```bash
-w /etc/hosts -p wa -k network
-w /etc/sysconfig/network -p wa -k network
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network
```

**Mengapa:** Attacker sering mengubah `/etc/hosts` untuk redirect traffic (DNS poisoning lokal). `sethostname`/`setdomainname` dipakai oleh C2 beacon untuk fingerprint lingkungan. Log dari group ini membantu mendeteksi host yang tiba-tiba mengganti nama sebagai indikasi pivot post-exploit.

### 10.4. Kernel Module Loading (`-k modules`)

```bash
-w /usr/sbin/insmod -p x -k modules
-w /usr/sbin/rmmod -p x -k modules
-w /usr/sbin/modprobe -p x -k modules
```

**Mengapa:** Rootkit kernel yang paling stealth (Diamorphine, Reptile) di-load via `insmod` atau `modprobe`. Flag `-p x` (execute) artinya setiap eksekusi binary ini tercatat. Untuk deteksi lebih lanjut, tambahkan `-a always,exit -F arch=b64 -S init_module -S finit_module -k modules` yang menangkap syscall level langsung.

### 10.5. Privileged Commands & SUID Track

```bash
-a always,exit -F arch=b64 -S execve -F euid=0 -F auid>=1000 -F auid!=unset -k privileged
```

**Mengapa:** Setiap command yang dijalankan dengan EUID root (via sudo/suid/capability) dicatat. Filter `auid>=1000` skip system users; `auid!=unset` hanya tangkap session login (bukan proses kernel/servis). Key `privileged` memudahkan query: `ausearch -k privileged --start today` untuk audit semua aktivitas root.

### 10.6. File Deletion Tracking (`-k delete`)

```bash
-a always,exit -F arch=b64 -S unlink -S unlinkat -S rename -S renameat -F auid>=1000 -F auid!=unset -k delete
```

**Mengapa:** Deteksi penghapusan file masif (ransomware pattern) atau cleanup jejak attacker. Di banyak insiden, attacker hapus log, binary, dan temporary files setelah eksekusi. Query `aureport -k delete --summary` bisa menunjukkan volume deletion abnormal.

### 10.7. Immutable Rule Paling Akhir

```bash
-e 2
```

Rule `-e 2` mengunci konfigurasi auditd — tidak ada rule yang bisa diubah sampai reboot. Ini mencegah attacker menonaktifkan audit trail runtime. **Wajib jadi rule terakhir**, karena begitu di-load, semua perubahan rule (via `auditctl`) ditolak.

## 11. SELinux Troubleshooting Workflow — Real Examples

### 11.1. Pipeline Dasar: AVC → audit2allow → Policy Module

Setiap denial SELinux menghasilkan AVC (Access Vector Cache) message di audit log. Pipeline komplet:

```bash
# STEP 1 — Temukan AVC denial
sudo ausearch -m avc -ts today --raw
# Output raw: type=AVC msg=audit(1700000000.123:456): avc:  denied  { write } for  pid=1234 comm="httpd" name="index.html" dev="dm-0" ino=5678 scontext=system_u:system_r:httpd_t:s0 tcontext=unconfined_u:object_r:default_t:s0 tclass=file

# STEP 2 — Interpretasi komponen
#   scontext=system_u:system_r:httpd_t:s0       → source (httpd process)
#   tcontext=unconfined_u:object_r:default_t:s0 → target (file tanpa label)
#   tclass=file                                  → object type
#   { write }                                    → operasi yang diblok
# Kesimpulan: httpd tidak punya izin write ke file dengan label default_t

# STEP 3 — Fix path dengan konteks benar
sudo semanage fcontext -a -t httpd_sys_content_t "/var/www/html(/.*)?"
sudo restorecon -Rv /var/www/html

# ATAU (jika memang perlu write) — buat policy module
sudo audit2allow -a -M httpd_write    # generate dari semua AVC di log
sudo semodule -i httpd_write.pp
```

### 11.2. Contoh Skenario Real: Nginx Bind Port Non-Standar

Nginx tidak bisa bind ke port 8080 karena SELinux hanya izinkan port yang didaftarkan:

```bash
# AVC: denied { name_bind } for port=8080
# Solusi yang BENAR (bukan setenforce 0):
sudo semanage port -a -t http_port_t -p tcp 8080
sudo systemctl restart nginx

# Verifikasi port sudah terdaftar
sudo semanage port -l | grep http_port_t
```

### 11.3. Contoh: PostgreSQL dengan Custom Data Directory

```bash
# Saat pindah PGDATA ke /srv/pgsql, muncul AVC:
# denied  { search } for pid=xxx comm="postgres" name="pgsql" dev="dm-1"
sudo semanage fcontext -a -t postgresql_db_t "/srv/pgsql(/.*)?"
sudo restorecon -Rv /srv/pgsql
sudo systemctl restart postgresql
```

### 11.4. Audit2allow — Kapan Pakai dan Kapan Hindari

`audit2allow -a -M mymodule` generate policy dari SEMUA AVC yang tercatat. Ini praktis tapi **berbahaya** kalau AVC denial berasal dari exploit attempt — policy-nya akan mengizinkan aktivitas berbahaya.

✅ **Aman dipakai saat:**
- Skenario yang sudah terverifikasi (app legitimate mencoba akses)
- Development/staging environment
- Service yang di-debug setelah install paket baru

❌ **Hindari saat:**
- Server sedang diserang (AVC bisa dari exploit probe)
- Tidak yakin sumber denial
- Langsung apply ke production tanpa review policy yang dihasilkan

Gunakan `audit2allow -a -R` (generate dengan `require` statements) untuk menghasilkan policy yang lebih terstruktur dan mudah direview.

## 12. SELinux Booleans untuk Common Services

### 12.1. Boolean Management

```bash
# Lihat semua boolean
sudo semanage boolean -l

# Lihat boolean spesifik
sudo getsebool -a | grep httpd
```

### 12.2. Web Server (httpd/nginx) — Boolean Penting

| Boolean | Default | Fungsi | Risiko Enable |
|---------|---------|--------|---------------|
| `httpd_can_network_connect` | off | Apache bisa connect ke network (proxy, backend API) | Semua mod_php bisa jadi C2 beacon |
| `httpd_can_sendmail` | off | Apache bisa kirim email via sendmail | Spam relay jika ada form injection |
| `httpd_enable_cgi` | on | Izinkan eksekusi CGI script | Attack surface jika ada CGI vuln |
| `httpd_read_user_content` | off | Baca file di home directory | Bocornya user file via web |
| `httpd_tmp_exec` | off | Eksekusi file di /tmp | 🚨 Kritis: mencegah webshell dari uploaded PHP di /tmp |
| `httpd_unified` | off | Unified read/write/exec di semua httpd content | Menonaktifkan isolasi antara static & dynamic content |

**Rekomendasi:** Setiap boolean yang enable harus di-justify (approval change). Enable `httpd_can_network_connect` hanya kalau benar-benar perlu proxy reverse ke app server.

### 12.3. Database — PostgreSQL & MariaDB

```bash
# Boolean general
sudo getsebool -a | grep postgresql

# PostgreSQL: izinkan connect dari network (selain local socket)
# Hanya enable jika PostgreSQL listen di non-localhost
sudo setsebool -P postgresql_can_network_connect on

# MariaDB/MySQL: akses ke NFS
sudo setsebool -P mysqld_use_nfs on   # hanya jika data dir di NFS
```

### 12.4. Samba & FTP

```bash
# Samba: berbagi home directory
sudo setsebool -P samba_enable_home_dirs on

# FTP: izinkan user baca file dengan label non-default
sudo setsebool -P ftpd_full_access on   # 🚨 Hati-hati, ini sangat permisif
```

> [!tip] Persistence
> Gunakan flag `-P` agar perubahan boolean bertahan setelah reboot. Tanpa `-P`, boolean reset ke default saat restart.

## 13. Kernel Parameter Explainers — ASLR, rp_filter, dan Mitra

### 13.1. ASLR — Address Space Layout Randomization

```ini
kernel.randomize_va_space = 2   # 0=disabled, 1=randomize, 2=full (default modern)
```

**Cara kerja:** ASLR merandomisasi base address dari stack, heap, shared libraries, dan mmap segments setiap kali process di-fork. Nilai `2` (full) menambahkan randomization untuk stack base address (dibanding `1` yang tidak merandomisasi stack).

**Tanpa ASLR:** Attacker bisa memprediksi alamat memori eksak untuk ROP (Return-Oriented Programming) gadget dan buffer overflow. Eksploitasi jadi semudah copy-paste dari Metasploit module.

**Cek efektivitas:**
```bash
# Bandingkan base address libc di dua proses berbeda
cat /proc/self/maps | head -5
# Jalankan lagi — lihat base address berubah
```

### 13.2. rp_filter — Reverse Path Filtering

```ini
net.ipv4.conf.all.rp_filter = 1   # 0=off, 1=strict, 2=loose
```

**Cara kerja:** Kernel memverifikasi bahwa paket yang masuk melalui interface A memiliki source address yang *routable* kembali melalui interface yang sama. Jika route return-nya lewat interface B, paket di-drop.

**Tanpa rp_filter:** Attacker bisa kirim paket dengan source IP spoofed dari interface yang salah. Contoh klasik: attacker di jaringan internal kirim paket dengan source IP loopback (127.0.0.1) → server anggap sebagai local traffic → bypass firewall rules yang seharusnya blok.

**Strict (1) vs Loose (2):** Strict drop paket jika source address tidak routable via incoming interface. Loose hanya cek apakah source address reachable via *any* interface — lebih permisif, dipakai di multi-homed host dengan asymmetric routing.

### 13.3. tcp_syncookies — SYN Flood Defense

```ini
net.ipv4.tcp_syncookies = 1
```

SYN flood attack membanjiri server dengan SYN packet (tanpa ACK) hingga backlog connection penuh. Syncookies mengkodekan informasi connection awal di SYN-ACK sequence number, alokasi resource baru setelah handshake selesai. Efek samping: TCP options seperti Window Scaling, SACK, Timestamps tidak didukung saat syncookies aktif.

### 13.4. Kunci Lain dalam Satu Baris

| Parameter | Fungsi | Tanpa Proteksi |
|-----------|--------|----------------|
| `accept_source_route = 0` | Blok IP source routing | Attacker bisa menentukan path return packet — bypass firewall |
| `accept_redirects = 0` | Tolak ICMP redirect | MitM via ICMP redirect untuk redirect traffic ke attacker |
| `log_martians = 1` | Log paket dengan source address impossible (0.0.0.0, 255.255.255.255, dll) | Blind spot deteksi scanning |
| `tcp_rfc1337 = 1` | Proteksi TIME-WAIT assassination | Attacker inject RST ke TIME-WAIT connection — close koneksi legitimate |
| `kptr_restrict = 1` | Sembunyikan kernel pointer dari non-root | Kernel address disclosure (KASLR bypass) |
| `dmesg_restrict = 1` | Non-root tidak bisa baca dmesg | Information leak via kernel log |
| `perf_event_paranoid = 3` | Non-root tidak bisa akses perf events | Side-channel attack via performance counters |

## 14. Logging Comparison: auditd vs syslog-ng vs rsyslog

### 14.1. Peran Masing-masing

Ketiga tool ini **bukan kompetitor** langsung — mereka bekerja di layer berbeda:

| Aspek | auditd | rsyslog | syslog-ng |
|-------|--------|---------|-----------|
| Input source | Kernel audit subsystem (netlink socket) | /dev/log, /proc/kmsg, UDP/TCP 514 | /dev/log, /etc, UDP/TCP 514 |
| Data granularity | Syscall-level (setiap execve, write, open) | Application log (string-based) | Application log (string-based) |
| Volume | **Sangat tinggi** — Gigabytes/hari di server busy | Moderate | Moderate |
| Format | Binary (audit.log → `ausearch` / `aureport`) | Text (RFC 5424 / BSD syslog) | Text (RFC 5424 / BSD syslog) |
| Transport | Internal (ke auditd daemon) | TCP/UDP/RELP/TLS (remote) | TCP/UDP/TLS/mongodb/json (remote) |
| Filter language | Rule-based (key, syscall, arg) | Property-based (`:msg, contains, "error"`) | Expression-based (regex, json, kv-parser) |
| Encryption | ❌ (butuh auditd-remote-plugins) | ✅ TLS via imtcp/omfwd | ✅ TLS via network() driver |
| Disk failure behavior | `disk_full_action = SUSPEND` (configurable) | Configurable (queue overflow) | Configurable (disk-based queue) |

### 14.2. Kapan Pakai Yang Mana?

- **auditd** → Security/forensic: mendeteksi perubahan file critical, privilege escalation, syscall anomaly. Wajib untuk PCI-DSS, SOC2 compliance.
- **rsyslog** → Log aggregation server sentral (paling umum di RHEL/Fedora default). Mudah dikonfigurasi untuk forward ke SIEM.
- **syslog-ng** → Infrastruktur kompleks dengan multiple data source dan format. Lebih powerful parsing (JSON, csv, kv-parser built-in). Lebih hemat memory di high volume.

### 14.3. Best Practice: Kombinasi

```text
auditd (event detail) → ausearch/aureport (analisis lokal)
                      → rsyslog atau syslog-ng (forward ke SIEM)

Server A: auditd + rsyslog (forward via RELP/TLS)
Server B: auditd + syslog-ng (parse + transform + forward ke Elasticsearch)
```

## 15. Common Attack Scenarios vs Hardening Layer

### 15.1. Matrix Pertahanan

Setiap serangan mengincar layer tertentu. Hardening layer yang tepat memblokirnya di sumber:

| Attack Scenario | Layer yang Mencegat | Mekanisme |
|----------------|---------------------|-----------|
| **Brute-force SSH password** | SSH config + Fail2ban | `PasswordAuthentication no`, Fail2ban ban IP |
| **Root privilege escalation via SUID binary** | SELinux + Systemd + Auditd | `NoNewPrivileges=true`, `httpd_t` tidak bisa exec `su`; auditd mencatat semua execve EUID=0 |
| **Webshell upload di /tmp** | SELinux boolean | `httpd_tmp_exec=off` mencegah eksekusi PHP di /tmp |
| **Kernel rootkit load** | Sysctl + Auditd + SELinux | `kernel.modules_disabled=1`; rule `-k modules`; SELinux blok `insmod` dari domain non-root |
| **Time manipulation (log tamper)** | Auditd + Sysctl | Rule `-k time-change` catat setiap `settimeofday`; NTP sync via `chronyd` dengan konfigurasi restricted |
| **SYN flood DDoS** | Kernel sysctl | `tcp_syncookies=1`, `tcp_synack_retries=5`, `somaxconn` tuning |
| **Data exfiltration via DNS** | SELinux + AppArmor | Boolean `httpd_can_network_connect=off` (blok koneksi keluar dari web server) |
| **ICMP redirect MitM** | Kernel sysctl | `accept_redirects=0`, `secure_redirects=0` |
| **File tampering (ransomware)** | Auditd + AIDE | Rule `-k delete` catat penghapusan; AIDE detect perubahan checksum filesystem |
| **Container escape via mount** | SELinux + Systemd | Container SELinux label `container_t`; Systemd `ProtectKernelTunables=yes`, `ProtectKernelModules=yes` |

### 15.2. Defense in Depth — Real Case

**Contoh: Attacker berhasil inject webshell via WordPress plugin vuln:**

1. **Layer Web (Nginx/App)** → WAF/blok path eksekusi — jika gagal:
2. **Layer Systemd** → `ProtectSystem=full` mencegah webshell tulis file di luar /tmp — jika bypass:
3. **Layer SELinux** → `httpd_tmp_exec=off` blok eksekusi PHP di /tmp — jika bypass:
4. **Layer Auditd** → Semua `execve` dari `httpd_t` tercatat di audit.log — deteksi via SIEM
5. **Layer AIDE** → Perubahan file di /var/www terdeteksi di daily check

**Tidak ada satu layer yang sempurna.** Kombinasi kelimanya memaksa attacker membangun exploit chain yang kompleks — dan setiap chain link berisiko terdeteksi.

### 15.3. Checklist Prioritas Hardening Berdasarkan Threat Model

| Lingkungan | Prioritas #1 | Prioritas #2 | Prioritas #3 |
|------------|-------------|-------------|-------------|
| Public-facing web server | SELinux enforcing + Boolean hardening | SSH key-only + Fail2ban | Auditd rule minimum |
| Internal DB server | Auditd (identity + time-change) | Systemd NoNewPrivileges | Kernel sysctl (no source routing) |
| Container host | SELinux container labels | Systemd ProtectKernelModules | Auditd (module loading + exec) |
| Dev/Staging | SSH hardening | SELinux permissive (logging) | Lynis audit periodik |

---

## 16. Koneksi ke Vault

| Catatan                          | Koneksi                                                               |
| -------------------------------- | --------------------------------------------------------------------- |
| [[linux-hardening-cis]]          | Referensi CIS benchmark level 2 — catatan ini implementasi praktisnya |
| [[linux-fundamentals-deepdive]]  | Fondasi OS Linux — prerequisite biar paham kernel params, namespaces  |
| [[server-hardening-playbook]]    | Playbook hardening VPS — overlap di SSH + UFW                         |
| [[ebpf-kernel-security]]         | eBPF untuk runtime security — level di atas auditd                    |
| [[infrastructure-administrator]] | Admin tasks — hardening adalah subset dari administrasi               |
| [[hierarchy-operating-systems]]  | OS hierarchy — posisi hardening di layer kernel                       |

## References

1. CIS Linux Benchmarks — https://www.cisecurity.org/cis-benchmarks
2. Practical Linux Hardening Guide — https://github.com/trimstray/the-practical-linux-hardening-guide
3. Fedora Auditd Documentation — https://fedoraproject.org/wiki/Auditd
4. Red Hat SELinux Guide — https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/9/html-single/selinux_users_and_administrators_guide/index
5. Systemd Security Documentation — https://www.freedesktop.org/software/systemd/man/systemd.exec.html
6. Linux Audit Documentation — https://github.com/linux-audit/audit-documentation
7. Lynis — https://cisofy.com/lynis/
8. AIDE Manual — https://aide.github.io/