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

| Masalah                      | Akibat                             | Fix                                       |
| ---------------------------- | ---------------------------------- | ----------------------------------------- |
| `auditd` disabled di systemd | Service gak start otomatis         | `systemctl enable auditd --now`           |
| Kernel tanpa `audit=1`       | Audit subsystem inactive saat boot | Tambah `audit=1` di `GRUB_CMDLINE_LINUX`  |
| Rules `-a task,never`        | Semua syscall di-skip              | Hapus file rules.d dengan `-a task,never` |

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

| Faktor            | SELinux                              | AppArmor               |
| ----------------- | ------------------------------------ | ---------------------- |
| Label-based       | ✅ Setiap file/process punya context | ❌ Path-based          |
| Granularity       | Sangat detail (types, roles, users)  | Medium (path profiles) |
| Learning curve    | Curam                                | Landai                 |
| Distro default    | Fedora, RHEL, CentOS                 | Ubuntu, Debian, SUSE   |
| Container support | ✅ Container SELinux labels          | ❌ Limited             |

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

| Item                  | Command                                            | Status |
| --------------------- | -------------------------------------------------- | ------ |
| SSH password auth off | `grep PasswordAuthentication /etc/ssh/sshd_config` | ❌/✅  |
| auditd active         | `systemctl is-active auditd`                       | ❌/✅  |
| SELinux enforcing     | `getenforce`                                       | ❌/✅  |
| Kernel ASLR           | `sysctl kernel.randomize_va_space` (harus 2)       | ❌/✅  |
| Fail2ban running      | `systemctl is-active fail2ban`                     | ❌/✅  |
| Unattended upgrades   | `systemctl status unattended-upgrades`             | ❌/✅  |
| UFW enabled           | `ufw status`                                       | ❌/✅  |
| No root login SSH     | `grep PermitRootLogin /etc/ssh/sshd_config`        | ❌/✅  |

---

## 9. Koneksi ke Vault

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
