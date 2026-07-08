---
title: "Lynis Hardening Tracker Rocky Linux 9"
tags:
  - original
aliases:
  - "lynis-hardening-tracker-rocky-linux-9"
created: "2026-06-06"
updated: "2026-07-01"
status: Ongoing — Day 2 Complete
---

# 🔐 Lynis Hardening Tracker — Rocky Linux 9 (Dokumentasi Teknis Komprehensif)

---

## 🧭 Profil Sistem dan Konteks

| Parameter     | Nilai                           | Penjelasan Teknis                                                                 |
| ------------- | ------------------------------- | --------------------------------------------------------------------------------- |
| Host          | rocky (192.168.130.129)         | Alamat IP internal untuk sistem target                                            |
| OS            | Rocky Linux 9 (RHEL-based)      | Distro berbasis Red Hat Enterprise Linux 9 dengan kompatibilitas Enterprise-grade |
| Kernel        | 5.14.0-78.el9.x86_64 (misalnya) | Versi kernel yang mendukung modul keamanan seperti SELinux dan AppArmor           |
| Baseline Scan | 2026-06-06 20:00                | Hasil pemindaian awal sebelum hardening menggunakan `lynis audit system`          |
| Current Scan  | 2026-06-06 21:37                | Skor terkini setelah implementasi langkah hardening                               |
| Target Score  | 90+ (skala 100)                 | Target berdasarkan benchmark hardening PCI-DSS, CIS, dan OWASP                    |

---

## 📈 Progresif Skor Keamanan

| Fase         | Tanggal              | Skor | Delta | Langkah Kunci                                                                                             |
| ------------ | -------------------- | ---- | ----- | --------------------------------------------------------------------------------------------------------- |
| **Baseline** | 2026-06-06           | 67   | —     | Sistem baru dengan hardening minimal (SSH aktif, firewall dasar)                                          |
| **Hari 1**   | 2026-06-06           | 69   | +2    | **SSH lockdown**: root login dinonaktifkan, otorisasi berbasis kunci, batasi percobaan login              |
| **Hari 2**   | 2026-06-06           | 74   | +5    | Implementasi **PAM** (Password Authentication Modules) + **aIDE** (Asset Integrity Directory Engine)      |
| **Hari 3**   | 2026-06-07 (planned) | 80+  | +6    | Optimasi SSH (batasi port forwarding, log detail), konfigurasi `login.defs` (umask, password TTL)         |
| **Hari 4**   | 2026-06-08 (planned) | 85+  | +5    | Nonaktifkan protokol legacy (X11), periksa layanan (`auditd`, `syslog`), dan partisi log (`/var/log`)     |
| **Hari 5**   | 2026-06-09 (planned) | 90+  | +5    | Implementasi logging eksternal (rsyslog), validasi konfigurasi keamanan (`lynis report`), dan audit final |

---

## ✅ Detail Konfigurasi yang Telah Diberlakukan

### 🔒 Hari 1: SSH & Perlindungan Akun

- **SSH Konfigurasi**

  ```bash
  PermitRootLogin no
  PasswordAuthentication no
  AllowUsers rocky
  ```

  _Mencegah brute-force dan akses root langsung, hanya membolehkan user `rocky`._

- **Fail2Ban Rule (`/etc/fail2ban/jail.local`)**

  ```ini
  [sshd]
  bantime = 3600
  maxretry = 3
  ```

  _Menjebak IP yang mencoba 3 kali login salah dalam 1 jam._

- **PAM (Password Authentication Modules)**
  ```bash
  authselect select sssd with-faillock with-pwhistory
  ```
  _Mengaktifkan kebijakan password kompleksitas (`minlen=12`) dan blokir akun setelah 5 cobaan._

---

### 🔐 Hari 2: Integritas Sistem & Audit

- **AIDE (Advanced Intrusion Detection Environment)**

  ```bash
  aide --init && cp /etc/aide/aide.db.new /etc/aide/aide.db
  ```

  _Membangun baseline integritas file. Jadwalkan cron `0 0 * * * aide --check`._

- **Kernel Hardening (`/etc/sysctl.d/99-hardening.conf`)**

  ```bash
  net.ipv4.conf.all.rp_filter = 1
  net.ipv4.icmp_echo_ignore_broadcasts = 1
  ```

  _Mencegah spoofing IP dan mitigasi DDOS._

- **Audit Trail (`auditctl -l`)**
  ```bash
  -w /etc/passwd -p war
  -w /etc/shadow -p war
  ```
  *Memantau perubahan
