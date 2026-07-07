---
tags:
  - Self-Experiment
aliases:
  - Self-Experiment
created: 2026-06-06
updated: "2026-07-01"
status: Ongoing
cssclasses:
  - wide-table
title: Day 1
---

# Catatan

> [!tip] Kenapa Ini Penting untuk Security?
> Ubuntu-Host (Ansible Control): x.x.x.128 ubuntu-host ubuntu-host
> Rocky Linux (Managed Nodes): x.x.x.129 rocky My-VM2-@234@9090

### Hardening

> [!warning] Requirement
>
> EPEl RELEASE, etc ...

Installation and Check Basic

```
1. `sudo dnf/apt/etc install lynis -y`

2. `sudo lynis audit system --quick`
```

![[pasted-image-20260606200451-png]]
Lynis Suggestion

```bash
sudo grep "Suggestion" /var/log/lynis.log | head -n 30
# Atau baca report dat
sudo cat /var/log/lynis-report.dat | grep "suggestion" | head -n 20
```

![[pasted-image-20260606200536-png]]

###  SSH Lockdown

```
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%F)

sudo nano /etc/ssh/sshd_config
```

```bash
# --- Hardening Core ---
Port 22 # Port 22 dulu, ganti nanti kalau sudah yakin
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
X11Forwarding no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
LoginGraceTime 60
AllowUsers rocky # GANTI 'rocky' dengan user KALIAN. Ini WHITELIST.
				 # Kalau ada user lain, tambah: AllowUsers rocky
```

```
sudo systemctl restart sshd

# DARI CONTROL NODE (jangan close SSH yang aktif! Buka tab baru):
ssh rocky@192.168.130.129
# Harus masih bisa. Kalau gagal = kamu lock diri sendiri.
```

### Install Fail2ban

```
sudo dnf install fail2ban -y

sudo systemctl enable fail2ban --now
sudo systemctl status fail2ban
```

```
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/secure
maxretry = 3
bantime = 3600
EOF

sudo systemctl restart fail2ban
sudo fail2ban-client status sshd
```

PAM Password Policy

```
# Cek profile aktif
sudo authselect current

# Pilih profile dengan hashing kuat
sudo authselect select sssd --force
sudo authselect enable-feature with-faillock
sudo authselect enable-feature with-pwhistory
sudo authselect apply-changes

# Edit faillock config
sudo nano /etc/security/faillock.conf
```

Edit agar sesuai

```
deny = 5
fail_interval = 900
unlock_time = 600
even_deny_root = true
```

Password Quality

```
sudo nano /etc/security/pwquality.conf
```

Edit

```
minlen = 12
minclass = 3
maxrepeat = 2
gecoscheck = 1
```

2026-06-06: Day 1 Hardening

- SSH: PermitRootLogin no, Password no, AllowUsers rocky, MaxAuthTries 3
- fail2ban: installed, sshd jail enabled, ban 1 hour after 3 fails
- PAM: authselect with-faillock, pwquality minlen=12
- Test: SSH dari control node masih works
