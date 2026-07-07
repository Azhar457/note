---
title: "Dokumen 01 Persiapan Host Lxc"
tags:
  - chat-logs-phase-1
  - resources
aliases:
  - "dokumen-01-persiapan-host-lxc"
created: "2026-04-24"
updated: "2026-07-01"
status: Final
---

# Dokumen 01 — Persiapan Host & LXC

> Panduan pembangunan fondasi virtualisasi menggunakan Proxmox VE dan LXC (Linux Container). Semua perintah dieksekusi dari Web UI Proxmox atau Shell host Proxmox, kecuali dinyatakan lain.

---

## 1. Konfigurasi Repositori Proxmox

Secara default Proxmox mengunci repositori berbayar. Alihkan ke repositori gratis agar pembaruan sistem berjalan.

1. Buka Web UI Proxmox (`https://192.168.1.50:8006`).
2. Klik node **pve** → **Updates** → **Repositories**.
3. **Disable** semua repositori bertuliskan `enterprise`.
4. Klik **Add** → pilih **No-Subscription**.
5. Buka **Shell** node Proxmox, lalu perbarui sistem:

```bash
apt update && apt dist-upgrade -y
```

> [!tip]
> Selalu pastikan kernel Proxmox dalam keadaan terbaru sebelum membuat LXC produksi.

---

## 2. Unduh Template OS

1. Di Web UI, klik storage **local** (di bawah node `pve`).
2. Pilih **CT Templates** → klik **Templates**.
3. Cari `ubuntu-24.04-standard`, lalu klik **Download**.

---

## 3. Pembuatan LXC untuk Docker

Klik tombol **Create CT** dan isi parameter berikut:

| Tab          | Parameter              | Nilai                                   |
| ------------ | ---------------------- | --------------------------------------- |
| **General**  | Hostname               | `Docker-Server`                         |
|              | Password               | `<PASSWORD_KUAT>`                       |
|              | Unprivileged container | **Uncentang** (dibutuhkan untuk Docker) |
| **Template** | Template               | `ubuntu-24.04-standard`                 |
| **Disks**    | Storage                | `local-lvm`                             |
|              | Disk size              | `50 GB` (bisa diekspansi nanti)         |
| **CPU**      | Cores                  | `2`                                     |
| **Memory**   | Memory                 | `2048` (2 GB, elastis)                  |
| **Network**  | IPv4                   | **Static**                              |
|              | CIDR                   | `192.168.1.51/24`                       |
|              | Gateway                | `192.168.1.1`                           |

> [!warning]
> Jangan nyalakan LXC terlebih dahulu. Lakukan modifikasi fitur di langkah berikutnya.

---

## 4. Modifikasi Fitur LXC (Wajib untuk Docker)

Docker membutuhkan izin _nesting_ dan _keyctl_ agar dapat berjalan di dalam LXC.

1. Klik LXC `100` (Docker-Server).
2. Pergi ke menu **Options** → klik ganda **Features**.
3. Centang **nesting** dan **keyctl** → klik **OK**.
4. Klik **Start**.

---

## 5. Bypass AppArmor dari Host Proxmox

Ubuntu 24.04 di dalam LXC membawa AppArmor sendiri yang bentrok dengan Docker. Karena isolasi sudah ditangani Proxmox (Level 1), AppArmor di dalam LXC harus dilepas.

Buka **Shell node Proxmox** (bukan console LXC):

```bash
nano /etc/pve/lxc/100.conf
```

Tambahkan baris berikut di akhir file:

```text
lxc.apparmor.profile: unconfined
```

Simpan (`Ctrl+O`, `Enter`, `Ctrl+X`), lalu restart LXC:

```bash
pct stop 100
pct start 100
```

---

## 6. Akses SSH & Manajemen User

Gunakan Termius atau terminal lokal untuk SSH ke LXC. Web Console Proxmox hanya untuk darurat.

### 6.1 Koneksi Awal sebagai Root

```bash
ssh root@192.168.1.51
```

> [!warning]
> Jika gagal login root via password, ubah sementara `PermitRootLogin` di dalam LXC melalui **Console** Proxmox, bukan SSH.

### 6.2 Pembuatan User Non-Root

Sebelum mengunci akses root, buat jalur alternatif:

```bash
adduser nama_user
usermod -aG sudo nama_user
```

Verifikasi login baru di tab terminal terpisah:

```bash
ssh nama_user@192.168.1.51
sudo su
```

### 6.3 Pengamanan SSH (Disable Root Login)

Setelah verifikasi `sudo` berhasil, kunci akses root:

```bash
sudo nano /etc/ssh/sshd_config
```

Ubah baris:

```text
PermitRootLogin no
```

Restart SSH:

```bash
sudo systemctl restart ssh
```

> [!tip]
> Semua konfigurasi selanjutnya di Dokumen 02–05 dieksekusi via user `nama_user` dengan prefix `sudo`.

---

## 7. Hardening DNS & SMTP (Post-Lynis)

Setelah audit Lynis (lihat [[dokumen-04-security-stack|Dokumen 04]]), perbaiki dua warning kritis berikut:

### 7.1 DNS Resolver

Lynis mendeteksi DNS Tailscale (`100.100.100.100`) tidak responsif. Atur dari Web UI Proxmox:

1. Klik LXC `100` → **DNS**.
2. Isi **DNS servers**: `1.1.1.1 8.8.8.8`
3. Restart LXC.

### 7.2 SMTP Banner Hardening

```bash
sudo postconf -e "smtpd_banner = \$myhostname ESMTP"
sudo systemctl restart postfix
```

---

## 8. Update Sistem

Sebelum masuk ke instalasi Docker, pastikan OS dalam keadaan steril:

```bash
sudo apt update && sudo apt upgrade -y
```

---

> [!info]
> Lanjut ke [[dokumen-02-docker-nextcloud-stack|Dokumen 02]] untuk instalasi Docker Engine dan deployment Nextcloud via IaC.
