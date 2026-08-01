---
title: Server Hardening Playbook — VPS Production
tags:
  - devops
  - security
  - server-hardening
  - vps
  - linux
  - sysadmin
  - playbook
aliases:
  - VPS Hardening Guide
  - Production Server Security
  - Server Hardening Checklist
created: "2026-07-30"
updated: "2026-07-30"
status: pending
cssclasses:
  - wide-table
---

# 🛡️ Server Hardening Playbook — VPS Production

> Playbook hardening server VPS dari awal (fresh install) sampai production-ready. Bukan teori — ini langkah konkret yang diterapkan di VPS production (beberapa project berbeda). Setiap langkah punya command copy-paste, reasoning kenapa dilakukan, dan verification step. Vault udah punya [[linux-hardening-audit-praktis]] (komponen hardening individual) — playbook ini urutannya dari awal sampe akhir.

> [!tip] Filosofi
> Hardening itu layered defense. Gak ada satu konfigurasi yang bikin server aman. Tapi kombinasi SSH key-only + UFW + fail2ban + auditd + SELinux + automatic updates udah cukup buat repel 99% automated attacks. Sisanya detection + response.

## Daftar Isi

1. [[#1. Prasyarat — Sebelum Mulai]]
2. [[#2. SSH Hardening — Pintu Masuk]]
3. [[#3. Firewall — UFW + Port Selection]]
4. [[#4. Automatic Security Updates]]
5. [[#5. Fail2ban — Brute Force Protection]]
6. [[#6. Auditd — Kernel Audit Trail]]
7. [[#7. SELinux / AppArmor — MAC]]
8. [[#8. Kernel Hardening — Sysctl]]
9. [[#9. File Integrity — AIDE]]
10. [[#10. Logging & Monitoring]]
11. [[#11. Backup Strategy]]
12. [[#12. Verification — Full Checklist]]

---

## 1. Prasyarat — Sebelum Mulai

### 1.1. Fresh Install — Base System

```bash
# Update system
sudo apt update && sudo apt upgrade -y    # Ubuntu
sudo dnf update -y                        # Fedora

# Install essentials
sudo apt install -y curl wget git ufw fail2ban auditd aide unattended-upgrades
sudo dnf install -y curl wget git ufw fail2ban auditd aide

# Timezone
sudo timedatectl set-timezone Asia/Jakarta

# Hostname
sudo hostnamectl set-hostname vps-name
echo "127.0.1.1 vps-name" | sudo tee -a /etc/hosts
```

### 1.2. User Management

```bash
# Create admin user (jangan pake root langsung!)
sudo adduser dev
sudo usermod -aG sudo dev

# Copy SSH key dari root ke dev (sebelum logout)
sudo mkdir -p /home/dev/.ssh
sudo cp ~/.ssh/authorized_keys /home/dev/.ssh/
sudo chown -R dev:dev /home/dev/.ssh
sudo chmod 700 /home/dev/.ssh
sudo chmod 600 /home/dev/.ssh/authorized_keys

# Test login dari terminal lain (JANGAN logout root dulu!)
ssh dev@vps-ip

# Kalo berhasil, baru lanjut
```

### 1.3. SSH Key — Generate & Deploy

```bash
# Dari laptop (bukan server):
ssh-keygen -t ed25519 -a 100 -f ~/.ssh/vps_deploy
ssh-copy-id -i ~/.ssh/vps_deploy.pub dev@vps-ip

# Test
ssh -i ~/.ssh/vps_deploy dev@vps-ip

# Ssh-agent biar gak masukin passphrase tiap kali
eval $(ssh-agent)
ssh-add ~/.ssh/vps_deploy
```

> [!warning] Jangan logout dari sesi root sebelum testing SSH dari user baru! Ini kesalahan paling umum — SSH config salah, lo lock out total. Solusi: `ssh -o PreferredAuthentications=password -o PubkeyAuthentication=no dev@vps-ip` kalo butuh fallback.

---

## 2. SSH Hardening — Pintu Masuk

SSH adalah garis depan pertahanan. Konfigurasi ini minimal untuk production:

```bash
# Backup dulu
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

sudo tee /etc/ssh/sshd_config.d/99-hardening.conf << 'EOF'
# 🔒 Hardening SSH
Port 22                          # Ganti kalo mau ubah port (bikin log lebih bersih)
Protocol 2
PermitRootLogin no               # 🔑 KRITIS: jangan izinin root login
PubkeyAuthentication yes
PasswordAuthentication no        # 🔑 KRITIS: matiin password auth
AuthenticationMethods publickey
MaxAuthTries 3
MaxSessions 5
ClientAliveInterval 300          # 5 menit timeout
ClientAliveCountMax 0            # disconnect kalo idle
AllowUsers dev admin             # whitelist user — semuanya ditolak
LoginGraceTime 30                # 30 detik untuk login
AcceptEnv LANG LC_*
EOF

# Test config
sudo sshd -t

# Kalo ok, restart
sudo systemctl restart sshd
```

### 2.1. Kenapa Ini Penting?

Server production kena brute-force attack terus menerus. Cek sendiri:

```bash
sudo grep "Failed password" /var/log/auth.log | wc -l   # jumlah failed attempt
sudo journalctl -u sshd -p 5 --since "24 hours ago" | grep "Failed" | wc -l
```

Dengan `PasswordAuthentication no`, semua bot yang pake password dictionary langsung ditolak di layer SSH—gak sempet reach PAM atau system auth. Begitu juga `PermitRootLogin no` — root punya UID 0, kalo username-nya udah ketahuan, attacker tinggal brute password-nya. Dengan whitelist `AllowUsers`, user yang gak ada di list gak bakal bisa login meskipun punya key.

### 2.2. Alternative Port (Opsional)

Pindah port SSH dari 22 ke port tinggi (contoh: 2222) bikin log auth jauh lebih bersih karena bot biasanya cuma scan port 22:

```bash
sudo semanage port -a -t ssh_port_t -p tcp 2222    # SELinux (Fedora/RHEL)
sudo ufw allow 2222/tcp
# Di config: Port 2222
```

Tapi ingat: security by obscurity doang — attacker dedicated tetap bakal scan semua port.

---

## 3. Firewall — UFW + Port Selection

### 3.1. UFW — Konfigurasi Dasar

```bash
# Default: deny incoming, allow outgoing
sudo ufw default deny incoming
sudo ufw default allow outgoing

# Allow SSH (WAJIB sebelum enable!)
sudo ufw allow ssh
# Atau kalo pake custom port: sudo ufw allow 2222/tcp

# Allow service ports
sudo ufw allow 80/tcp     # HTTP
sudo ufw allow 443/tcp    # HTTPS
sudo ufw allow 5432/tcp   # Postgres (kalo perlu dari IP tertentu aja)
sudo ufw allow from 192.168.1.0/24 to any port 5432  # better: IP range

# Enable
sudo ufw --force enable
sudo ufw status verbose
```

### 3.2. UFW + Podman — Penting!

Podman rootless pake slirp4netns — FORWARD chain harus di-allow. Kalo UFW set deny FORWARD, container gak bisa reach internet:

```bash
# Cek status FORWARD policy
sudo ufw status verbose | grep default

# Kalo "deny (forwarded)", ganti
# Opsi 1: Allow forward (longgar)
sudo sed -i 's/DEFAULT_FORWARD_POLICY="DENY"/DEFAULT_FORWARD_POLICY="ALLOW"/' /etc/default/ufw
sudo ufw reload

# Opsi 2 (lebih aman): Allow forward dari network tertentu
sudo ufw route allow in on podman0
sudo ufw route allow out on podman0
```

> [!tip] Detail lebih lanjut: [[podman-networking-ufw]] — ada pitfall spesifik soal cgroup v1 vs v2.

### 3.3. Port Audit

```bash
# Lihat port yang lagi listen
sudo ss -tlnp
sudo ss -tulpn

# Cek dari luar (via laptop)
nc -zv vps-ip 22
nc -zv vps-ip 3306      # harusnya filtered kalo gak dibuka
```

---

## 4. Automatic Security Updates

### 4.1. Ubuntu — unattended-upgrades

```bash
sudo dpkg-reconfigure --priority=low unattended-upgrades
# Atau manual:
sudo tee /etc/apt/apt.conf.d/20auto-upgrades << 'EOF'
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Download-Upgradeable-Packages "1";
APT::Periodic::AutocleanInterval "7";
APT::Periodic::Unattended-Upgrade "1";
EOF

# Konfigurasi apa yang di-auto-update
sudo tee /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};
Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Automatic-Reboot-Time "03:00";
EOF
```

### 4.2. Fedora/RHEL — dnf-automatic

```bash
sudo dnf install -y dnf-automatic
sudo sed -i 's/apply_updates = no/apply_updates = yes/' /etc/dnf/automatic.conf
sudo systemctl enable --now dnf-automatic.timer
```

---

## 5. Fail2ban — Brute Force Protection

Fail2ban monitor log file dan ban IP yang gagal login berkali-kali.

```bash
sudo cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local

sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 1h                    # durasi ban — 1 jam cukup
findtime = 10m                  # window deteksi — 10 menit
maxretry = 5                    # 5 gagal dalam 10m = ban
ignoreip = 127.0.0.1/8 10.0.0.0/8 172.16.0.0/12 192.168.0.0/16
backend = auto

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s

[sshd-ddos]
enabled = true
port = ssh
logpath = %(sshd_log)s
maxretry = 3
findtime = 60                   # 3 gagal dalam 1 menit = DDoS attack

[nginx-http-auth]
enabled = true
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10

[nginx-botsearch]
enabled = true
port = http,https
logpath = /var/log/nginx/access.log
maxretry = 15
findtime = 30
EOF

sudo systemctl enable --now fail2ban
sudo fail2ban-client status
sudo fail2ban-client status sshd          # cek banned IPs
sudo fail2ban-client set sshd unbanip 1.2.3.4  # manual unban (kalo false positive)
```

### 5.1. Analisis Failed Attempts

```bash
# SSH failed dalam 24 jam
sudo journalctl -u sshd --since "24 hours ago" | grep "Failed password" | awk '{print $(NF-3)}' | sort | uniq -c | sort -rn | head -10

# Fail2ban banned total
sudo fail2ban-client status sshd | grep "Total banned"
sudo zgrep 'Ban' /var/log/fail2ban.log*
```

### 5.2. False Positive — Jangan Overblock

Kadang IP lo sendiri ke-ban kalo salah masukin password di Termius. Solusi: tambah IP lo ke ignore list:

```bash
sudo fail2ban-client set sshd unbanip 103.xxx.xxx.xxx   # unban sementara
# Tambah ke jail.local: ignoreip = ... 103.xxx.xxx.xxx
```

---

## 6. Auditd — Kernel Audit Trail

Ini bagian yang lo temuin masalah sendiri — auditd "kosong" karena 3 masalah berantai:

```bash
# 1. Aktifin kernel audit parameter
sudo sed -i 's/^GRUB_CMDLINE_LINUX="/GRUB_CMDLINE_LINUX="audit=1 /' /etc/default/grub
sudo update-grub                    # Ubuntu
sudo grub2-mkconfig -o /boot/efi/EFI/fedora/grub.cfg  # Fedora UEFI

# 2. Hapus rules yang nge-block semua
sudo rm -f /etc/audit/rules.d/*.rules.disabled
# Cek apakah ada file dengan "-a task,never"
sudo grep -l "task,never" /etc/audit/rules.d/* && sudo mv /etc/audit/rules.d/audit.rules /etc/audit/rules.d/audit.rules.disabled

# 3. Install base rules
# Ubuntu:
sudo apt install -y auditd

# Fedora: sample rules
sudo cp /usr/share/audit/sample-rules/10-base-config.rules /etc/audit/rules.d/
sudo cp /usr/share/audit/sample-rules/30-stig.rules /etc/audit/rules.d/  # opsional

# 4. Custom rules — vital events
sudo tee /etc/audit/rules.d/custom.rules << 'EOF'
# Kernel module changes
-w /usr/sbin/insmod -p x -k modules
-w /usr/sbin/rmmod -p x -k modules
-w /usr/sbin/modprobe -p x -k modules
-a always,exit -F arch=b64 -S init_module,finit_module,create_module,delete_module -k modules

# User/group changes
-w /etc/passwd -p wa -k identity
-w /etc/shadow -p wa -k identity
-w /etc/group -p wa -k identity
-w /etc/gshadow -p wa -k identity
-w /etc/sudoers -p wa -k privilege
-w /etc/sudoers.d/ -p wa -k privilege

# Network config changes
-w /etc/hosts -p wa -k network
-a always,exit -F arch=b64 -S sethostname -S setdomainname -k network

# Time changes
-a always,exit -F arch=b64 -S adjtimex -S settimeofday -S clock_settime -k time-change

# Login session
-w /var/log/wtmp -p wa -k session
-w /var/log/btmp -p wa -k session
-w /var/log/lastlog -p wa -k session

# SELinux policy changes
-w /etc/selinux/ -p wa -k MAC-policy
EOF

# 5. Enable & start
sudo systemctl enable auditd
sudo systemctl restart auditd
sudo auditctl -e 1

# 6. Verifikasi
sudo auditctl -s | grep enabled          # harus "enabled 1"
sudo aureport --summary                   # liat event summary
sudo ausearch -m USER_LOGIN -ts today     # login hari ini
```

---

## 7. SELinux / AppArmor — MAC

### 7.1. SELinux (Fedora/RHEL)

```bash
# Cek status
getenforce           # harus "Enforcing"
sestatus

# Kalo "Permissive" — aktifin
sudo setenforce 1
# Persist di /etc/selinux/config: SELINUX=enforcing

# Troubleshooting AVC denials — 90% kasus
sudo ausearch -m avc -ts today
# Atau kalo pake auditd
sudo grep AVC /var/log/audit/audit.log | tail -20
```

### 7.2. AppArmor (Ubuntu)

```bash
sudo aa-status
sudo apparmor_status

# Set profiles ke enforce
sudo aa-enforce /etc/apparmor.d/*
sudo systemctl reload apparmor
```

---

## 8. Kernel Hardening — Sysctl

```bash
sudo tee /etc/sysctl.d/99-server-hardening.conf << 'EOF'
# 🛡️ IP Spoofing
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1

# 🛡️ SYN Flood Protection
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_synack_retries = 3

# 🛡️ No Source Routing
net.ipv4.conf.all.accept_source_route = 0
net.ipv6.conf.all.accept_source_route = 0

# 🛡️ No ICMP Redirect
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.secure_redirects = 0
net.ipv6.conf.all.accept_redirects = 0

# 🛡️ Log Martians
net.ipv4.conf.all.log_martians = 1

# 🛡️ ASLR
kernel.randomize_va_space = 2

# 🛡️ Restrict kernel pointers
kernel.kptr_restrict = 1
kernel.dmesg_restrict = 1
kernel.perf_event_paranoid = 3

# 🛡️ Restrict ptrace
kernel.yama.ptrace_scope = 1

# 🛡️ TCP Hardening
net.ipv4.tcp_rfc1337 = 1
net.ipv4.tcp_fin_timeout = 15
EOF

sudo sysctl --system
```

---

## 9. File Integrity — AIDE

AIDE detects perubahan file yang gak sah — kalo ada attacker modify binary/config, AIDE tau.

```bash
# Setup
sudo aideinit
sudo mv /var/lib/aide/aide.db.new.gz /var/lib/aide/aide.db.gz

# Path yang di-monitor (config)
# /etc/aide.conf
# /etc            p+i+n+u+g+s+md5+sha512
# /usr/sbin       p+i+n+u+g+sha512
# /usr/bin        p+i+n+u+g+sha512
# /root           p+i+n+u+g+sha512
# !/var/log       (exclude)

# Check
sudo aide --check

# Cron harian
echo "0 6 * * * root /usr/bin/aide --check | mail -s "AIDE Report" root" | sudo tee /etc/cron.d/aide-check
```

---

## 10. Logging & Monitoring

### 10.1. Logwatch — Daily Summary

```bash
sudo apt install logwatch    # atau: dnf install logwatch
# Otomatis jalan tiap subuh kirim email summary

# Manual test
sudo logwatch --detail High --range today
```

### 10.2. whats-up.sh — One-Command Health Check

```bash
# /home/admin/Devops/whats-up.sh
#!/bin/bash
echo "╔══════════════════════════════╗"
echo "║   HEALTH CHECK $(hostname)    ║"
echo "╚══════════════════════════════╝"

echo ""
echo "📊 DISK:"
df -h / /var /data 2>/dev/null | awk 'NR>1 {print $0 " " ($5+0 > 80 ? "⚠️" : "✅")}'

echo ""
echo "📈 MEMORY:"
free -h | grep Mem

echo ""
echo "🔄 SERVICES:"
for s in sshd ufw fail2ban auditd nginx postgresql; do
    systemctl is-active --quiet $s 2>/dev/null && echo "  ✅ $s" || echo "  ❌ $s"
done

echo ""
echo "🔌 PORTS:"
ss -tlnp4 | awk '{print $4}' | grep -v 127.0.0.1

echo ""
echo "🚫 FAIL2BAN BANS:"
sudo fail2ban-client status sshd 2>/dev/null | grep "Total banned"

echo ""
echo "📝 LAST LOGINS:"
last -5
```

### 10.3. Node Exporter + Prometheus (Optional)

Untuk observasi lebih lanjut, lihat [[observability-stack-prometheus-grafana]].

---

## 11. Backup Strategy

### 11.1. Database Backup

```bash
# /home/admin/Devops/backup-db.sh
#!/bin/bash
BACKUP_DIR="/backup/postgres"
DATE=$(date +%Y%m%d_%H%M)
DB_NAME="primestep_db"

# Dump custom format (compressed, restorable)
pg_dump -Fc -Z6 -U postgres $DB_NAME > "$BACKUP_DIR/${DB_NAME}_$DATE.dump"

# Hapus backup > 30 hari
find $BACKUP_DIR -name "*.dump" -mtime +30 -delete

# Verify
pg_restore -l "$BACKUP_DIR/${DB_NAME}_$DATE.dump" | head -5
sha256sum "$BACKUP_DIR/${DB_NAME}_$DATE.dump" > "$BACKUP_DIR/${DB_NAME}_$DATE.sha256"
```

### 11.2. Config Backup

```bash
# Backup config vital
sudo tar -czf "/backup/config/etc-$(date +%Y%m%d).tar.gz" /etc/ssh/ /etc/ufw/ /etc/fail2ban/ /etc/audit/
sudo tar -czf "/backup/config/var-$(date +%Y%m%d).tar.gz" /var/spool/cron/
```

---

## 12. Verification — Full Checklist

Jalankan playbook ini setelah fresh install, checklist satu per satu:

```bash
# ┌─────────────────────────────────────────────┐
# │         SERVER HARDENING CHECKLIST          │
# ├─────────────────────────────────────────────┤
# │                                             │
# │ 1. SSH: PermitRootLogin no               ❌ │
# │ 2. SSH: PasswordAuthentication no        ❌ │
# │ 3. SSH: AllowUsers whitelist             ❌ │
# │ 4. UFW: default deny incoming            ❌ │
# │ 5. UFW: active                           ❌ │
# │ 6. fail2ban: active                      ❌ │
# │ 7. auditd: enabled + running             ❌ │
# │ 8. SELinux: Enforcing                    ❌ │
# │ 9. Kernel ASLR: 2                        ❌ │
# │ 10. Automatic updates: on                ❌ │
# │ 11. AIDE: initialized + cron             ❌ │
# │ 12. Root login: disabled                 ❌ │
# │ 13. Unused services: disable             ❌ │
# │ 14. Logwatch: daily report               ❌ │
# └─────────────────────────────────────────────┘
```

### Verification Commands

```bash
# 1
grep "^PermitRootLogin" /etc/ssh/sshd_config
# 2
grep "^PasswordAuthentication" /etc/ssh/sshd_config
# 3
grep "^AllowUsers" /etc/ssh/sshd_config
# 4
sudo ufw status verbose | grep "Default: deny (incoming)"
# 5
sudo ufw status | grep Status
# 6
sudo systemctl is-active fail2ban
# 7
sudo systemctl is-enabled auditd && sudo auditctl -s | grep enabled
# 8
getenforce
# 9
sysctl kernel.randomize_va_space
# 10
systemctl is-active unattended-upgrades || systemctl is-active dnf-automatic.timer
# 11
sudo aide --check 2>&1 | tail -3
# 12
grep "^PermitRootLogin" /etc/ssh/sshd_config
# 13
systemctl list-units --type=service --state=running | grep -c "loaded active running"
# 14
ls -la /var/cache/logwatch/
```

### Scoring

| Item                      | Bobot | Critical?                 |
| ------------------------- | ----- | ------------------------- |
| PermitRootLogin no        | 10    | ✅ Ya — root brute-force  |
| PasswordAuthentication no | 10    | ✅ Ya — dictionary attack |
| UFW aktif                 | 8     | ✅ Hampir                 |
| fail2ban SSH jail         | 7     | ✅                        |
| Automatic updates         | 6     | ⬜                        |
| auditd running            | 5     | ⬜                        |
| SELinux Enforcing         | 8     | ✅                        |
| AIDE monitoring           | 4     | ⬜                        |

**Target minimum: 50/58.** Kalo di bawah itu, server lo belum production-ready.

---

## 13. Disable Unused Services

Setiap service yang jalan adalah attack surface tambahan. Prinsipnya: **jalanin cuma yang perlu**.

```bash
# Audit semua service yang jalan
systemctl list-units --type=service --state=running

# Matiin yang gak perlu (sesuai peran server)
sudo systemctl disable --now cups.service          # printer — gak perlu di server
sudo systemctl disable --now bluetooth.service      # bluetooth — server jarang pake
sudo systemctl disable --now avahi-daemon.service   # mDNS — gak perlu di cloud
sudo systemctl mask snapd.service                   # snap — Fedora gak pake

# Cek port yang lagi listen
sudo ss -tulpn | grep LISTEN
# Kalo ada port yang gak dikenal — investigasi!
```

### 13.1. Contoh: Web Server Minimal

Service yang beneran dibutuhin web server:

```
● nginx.service              — web server
● postgresql.service         — database
● sshd.service               — remote access
● fail2ban.service           — protection
● auditd.service             — audit
● ufw.service                — firewall
● systemd-journald           — logging
● cron.service / timers      — scheduled tasks
● node_exporter (optional)   — monitoring
```

> [!tip] Di VPS production, setelah matiin cups, bluetooth, avahi, snapd, kita turunin footprint dari ~45 service ke ~22 — memory saving ~500MB.

## 14. Docker / Podman Security

Container adalah service juga — dan punya attack surface sendiri:

### 14.1. Rootless Container

```bash
# SELINUX — label container
# Fedora: sudo setsebool -P container_manage_cgroup on

# Rootless Podman (default di Fedora)
podman run -d --name web --restart=always -p 8080:80 nginx:alpine

# Jangan pernah:
# - sudo podman run (root container) kalo gak perlu
# - mount /var/run/docker.sock di container (docker-in-docker)
# - --privileged flag
```

### 14.2. Container Image Security

```bash
# Scan image sebelum deploy
podman scan nginx:alpine          # Trivy scan
# Atau
trivy image nginx:alpine

# Prinsip:
# 1. Pake image resmi + version tag (jangan :latest)
# 2. Minimal base (alpine > ubuntu untuk footprint kecil)
# 3. Read-only filesystem kalo bisa
# 4. Non-root user di container
```

## 15. Incident Response — When Things Go Wrong

Playbook ini bikin server lo susah ditembus, tapi kalo tetap kena — ini langkah pertama:

```bash
# 1. ISOLATE — putus koneksi server dari internet kalo curiga breach
# (via cloud console / VNC / IPMI)

# 2. PRESERVE EVIDENCE — jangan restart! dump memory dulu
sudo cat /proc/kcore > /tmp/memory.dump   # hati-hati: file gede

# 3. CHECK RECENT LOGINS
last -10
sudo ausearch -m USER_LOGIN --start today --end now

# 4. CHECK AUTH LOG
sudo journalctl -u sshd --since "24 hours ago" | grep -E "Accepted|Failed"

# 5. CHECK FILE CHANGES
sudo aide --check

# 6. CHECK NETWORK CONNECTIONS
ss -tunap
lsof -i

# 7. CHECK CRON / TMP
ls -la /tmp/
cat /etc/crontab
for f in /etc/cron.*/*; do echo "=== $f ==="; cat "$f"; done
```

> [!warning] Root Cause Analysis (RCA): Jangan langsung rebuild. Cari tau gimana attacker masuk, baru fix pintu itu + add detection rule. Repeat.

## 16. Service Hardening — systemd

Setiap service production perlu isolation:

```ini
# /etc/systemd/system/myapp.service.d/hardening.conf
[Service]
ProtectSystem=full
ProtectHome=true
PrivateTmp=true
NoNewPrivileges=true
CapabilityBoundingSet=CAP_NET_BIND_SERVICE
MemoryMax=512M
TasksMax=100
Restart=on-failure
RestartSec=10
```

Cek skor keamanannya:

```bash
systemd-analyze security myapp.service
# Target: exposed level ≤ 🟡 MEDIUM (8.0)
```

## 17. IPS/IDS — Snort/Suricata (Optional)

Untuk server yang facing internet langsung tanpa Cloudflare:

```bash
sudo apt install -y suricata
# Konfigurasi di /etc/suricata/suricata.yaml — set HOME_NET
# Download rules: sudo suricata-update
sudo systemctl enable --now suricata
```

Tapi untuk server di belakang Cloudflare proxy, WAF layer udah handle ini. Lihat [[waf-reverse-proxy-deepdive]] dan [[ids-ips-waf-nsm-comparison]].

---

## 18. Security Budget Matrix

Berapa waktu & resource yang lo habiskan buat tiap layer? Ini prioritas yang recommended:

| Layer         | Tool                | Cost (setup/hr) | Cost (maintenance) | Priority |
| ------------- | ------------------- | :-------------: | :----------------: | :------: |
| SSH Hardening | Config              |    30 menit     |         0          |  **P0**  |
| Firewall      | UFW                 |    15 menit     |         0          |  **P0**  |
| Brute-force   | Fail2ban            |    15 menit     |         0          |  **P0**  |
| Audit         | Auditd              |    20 menit     |    5 menit/bln     |  **P1**  |
| MAC           | SELinux/AppArmor    |      1 jam      | 0 (setelah stable) |  **P1**  |
| Integrity     | AIDE                |    30 menit     |    10 menit/bln    |  **P2**  |
| Auto-update   | unattended-upgrades |    10 menit     |         0          |  **P2**  |
| Monitoring    | Prometheus/NodeExp  |      2 jam      |    30 menit/bln    |  **P2**  |

Prinsip Pareto: **20% effort (SSH+UFW+fail2ban) ngelindungin 80% attack surface.** Mulai dari sini.

## Koneksi ke Vault

| Catatan                                    | Koneksi                                                         |
| ------------------------------------------ | --------------------------------------------------------------- |
| [[linux-hardening-audit-praktis]]          | Detail per-komponen hardening — playbook ini urutan eksekusinya |
| [[vps-hardening-playbook]] (skill)         | Skill untuk VPS hardening — versi praktis beda format           |
| [[production-server-hardening]]            | Hardening production server dari sisi CIS benchmark             |
| [[linux-hardening-cis]]                    | Referensi CIS Level 2 — playbook ini subset yang paling vital   |
| [[podman-networking-ufw]]                  | UFW + Podman pitfall — FORWARD chain                            |
| [[observability-stack-prometheus-grafana]] | Monitoring setelah hardening selesai                            |
| [[infrastructure-as-code-praktis]]         | Ansible bisa otomasi seluruh playbook ini                       |
| [[attack-defense-hardening-playbook]]      | Hardening dari sudut pandang attack/defense                     |

## References

1. CIS Benchmarks — https://www.cisecurity.org/cis-benchmarks
2. Ubuntu Security Documentation — https://ubuntu.com/security
3. Fedora Security Lab — https://labs.fedoraproject.org/en/security/
4. Fail2ban Documentation — https://fail2ban.readthedocs.io/
5. Linux Audit Documentation — https://github.com/linux-audit/audit-documentation
6. UFW Community Wiki — https://wiki.ubuntu.com/UncomplicatedFirewall
7. Mozilla Security Guidelines — https://infosec.mozilla.org/guidelines/openssh.html
