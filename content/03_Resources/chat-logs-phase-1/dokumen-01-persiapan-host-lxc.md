---
title: Dokumen 01 Persiapan Host Lxc
tags:
- chat-logs-phase-1
- resources
created: '2026-04-24'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout
---


# Dokumen 01 — Persiapan Host & LXC
Panduan pembangunan fondasi virtualisasi menggunakan Proxmox VE dan LXC (Linux Container). Semua perintah dieksekusi dari Web UI Proxmox atau Shell host Proxmox, kecuali dinyatakan lain.

## 1. Konfigurasi Repositori Proxmox

Secara default Proxmox mengunci repositori berbayar. Alihkan ke repositori gratis agar pembaruan sistem berjalan. Berikut langkah-langkahnya:

1. Buka Web UI Proxmox (`https://192.168.1.50:8006`).
2. Klik node **pve** → **Updates** → **Repositories**.
3. **Disable** semua repositori bertuliskan `enterprise`.
4. Klik **Add** → pilih **No-Subscription**.
5. Buka **Shell** node Proxmox, lalu perbarui sistem:

```bash
apt update && apt dist-upgrade -y
```

Selalu pastikan kernel Proxmox dalam keadaan terbaru sebelum membuat LXC produksi. Hal ini untuk memastikan bahwa sistem Anda memiliki patches terbaru untuk meningkatkan keamanan dan stabilitas.

### 1.1 Penggunaan Mirror Repository

Untuk meningkatkan kecepatan update, Anda dapat menggunakan mirror repository yang lebih dekat dengan lokasi Anda. Misalnya, untuk menggunakan mirror repository di Indonesia, tambahkan baris berikut ke dalam file `/etc/apt/sources.list`:

```bash
deb http://kambing.ui.ac.id/ubuntu/ focal main restricted
deb http://kambing.ui.ac.id/ubuntu/ focal-updates main restricted
deb http://kambing.ui.ac.id/ubuntu/ focal universe
deb http://kambing.ui.ac.id/ubuntu/ focal-updates universe
```

### 1.2 Troubleshooting Repository

Jika Anda mengalami masalah saat update, periksa apakah repository Anda sudah benar. Anda dapat menggunakan perintah `apt-cache policy` untuk memeriksa repository yang sedang digunakan.

```bash
apt-cache policy
```

## 2. Unduh Template OS

Unduh template OS yang akan digunakan untuk LXC. Berikut langkah-langkahnya:

1. Di Web UI, klik storage **local** (di bawah node `pve`).
2. Pilih **CT Templates** → klik **Templates**.
3. Cari `ubuntu-24.04-standard`, lalu klik **Download**.

Pastikan Anda memilih template yang sesuai dengan kebutuhan Anda. Dalam contoh ini, kita menggunakan `ubuntu-24.04-standard` sebagai template OS untuk LXC.

### 2.1 Pembuatan Template OS Sendiri

Jika Anda ingin membuat template OS sendiri, Anda dapat melakukan dengan menggunakan perintah `pveam`. Berikut contoh perintah untuk membuat template OS Ubuntu 24.04:

```bash
pveam update
pveam available
pveam download local ubuntu_24.04-standard_1
```

## 3. Pembuatan LXC untuk Docker

Buat LXC baru untuk Docker dengan mengikuti langkah-langkah berikut:

Klik tombol **Create CT** dan isi parameter berikut:

| Tab | Parameter | Nilai |
|---|---|---|
| **General** | Hostname | `Docker-Server` |
| | Password | `<PASSWORD_KUAT>` |
| | Unprivileged container | **Uncentang** (dibutuhkan untuk Docker) |
| **Template** | Template | `ubuntu-24.04-standard` |
| **Disks** | Storage | `local-lvm` |
| | Disk size | `50 GB` (bisa diekspansi nanti) |
| **CPU** | Cores | `2` |
| **Memory** | Memory | `2048` (2 GB, elastis) |
| **Network** | IPv4 | **Static** |
| | CIDR | `192.168.1.51/24` |
| | Gateway | `192.168.1.1` |

Jangan nyalakan LXC terlebih dahulu. Lakukan modifikasi fitur di langkah berikutnya.

### 3.1 Pengaturan Resource LXC

Pastikan Anda mengatur resource LXC dengan benar. Berikut contoh perintah untuk mengatur resource LXC:

```bash
pct set 100 -cpu 2 -memory 2048
```

## 4. Modifikasi Fitur LXC (Wajib untuk Docker)

Docker membutuhkan izin *nesting* dan *keyctl* agar dapat berjalan di dalam LXC. Berikut langkah-langkahnya:

1. Klik LXC `100` (Docker-Server).
2. Pergi ke menu **Options** → klik ganda **Features**.
3. Centang **nesting** dan **keyctl** → klik **OK**.
4. Klik **Start**.

Modifikasi fitur ini diperlukan agar Docker dapat berjalan dengan stabil di dalam LXC.

### 4.1 Pengaturan Fitur LXC

Pastikan Anda mengatur fitur LXC dengan benar. Berikut contoh perintah untuk mengatur fitur LXC:

```bash
pct set 100 -features nesting=1,keyctl=1
```

## 5. Bypass AppArmor dari Host Proxmox

Ubuntu 24.04 di dalam LXC membawa AppArmor sendiri yang bentrok dengan Docker. Karena isolasi sudah ditangani Proxmox (Level 1), AppArmor di dalam LXC harus dilepas. Berikut langkah-langkahnya:

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

## 6. Akses SSH & Manajemen User

Gunakan Termius atau terminal lokal untuk SSH ke LXC. Web Console Proxmox hanya untuk darurat.

### 6.1 Koneksi Awal sebagai Root

```bash
ssh root@192.168.1.51
```

Jika gagal login root via password, ubah sementara `PermitRootLogin` di dalam LXC melalui **Console** Proxmox, bukan SSH.

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

## 7. Hardening DNS & SMTP (Post-Lynis)

Setelah audit Lynis, perbaiki dua warning kritis berikut:

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

## 8. Update Sistem

Sebelum masuk ke instalasi Docker, pastikan OS dalam keadaan steril:

```bash
sudo apt update && sudo apt upgrade -y
```

## 9. Instalasi Docker

Instalasi Docker dilakukan melalui paket resmi Ubuntu. Berikut langkah-langkahnya:

```bash
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update
sudo apt install -y docker-ce
```

Setelah instalasi selesai, pastikan Docker berjalan dengan benar:

```bash
sudo systemctl start docker
sudo systemctl enable docker
```

## 10. Verifikasi Instalasi Docker

Verifikasi instalasi Docker dengan menjalankan container sederhana:

```bash
sudo docker run -it --rm ubuntu bash
```

Jika Anda dapat masuk ke dalam container, maka instalasi Docker telah sukses.

## 11. Konfigurasi Docker

Konfigurasi Docker untuk menggunakan storage yang diinginkan. Berikut contoh konfigurasi untuk menggunakan storage `/var/lib/docker`:

```bash
sudo nano /etc/docker/daemon.json
```

Tambahkan baris berikut:

```json
{
  "data-root": "/var/lib/docker"
}
```

Simpan dan restart Docker:

```bash
sudo systemctl restart docker
```

## 12. Instalasi Docker Compose

Instalasi Docker Compose dilakukan melalui pip. Berikut langkah-langkahnya:

```bash
sudo apt install -y python3-pip
sudo pip3 install docker-compose
```

Setelah instalasi selesai, pastikan Docker Compose berjalan dengan benar:

```bash
sudo docker-compose --version
```

Dengan demikian, Anda telah mempersiapkan host dan LXC untuk dijadikan sebagai server yang aman dan stabil. Pastikan untuk melakukan update sistem secara teratur dan memantau log sistem untuk memastikan keamanan dan stabilitas server.

### 12.1 Troubleshooting Docker

Jika Anda mengalami masalah saat menjalankan container Docker, periksa apakah Docker berjalan dengan benar. Berikut contoh perintah untuk memeriksa status Docker:

```bash
sudo systemctl status docker
```

Jika Docker tidak berjalan, Anda dapat memulainya dengan perintah:

```bash
sudo systemctl start docker
```

### 12.2 Optimasi Performa Docker

Untuk meningkatkan performa Docker, Anda dapat mengoptimalkan konfigurasi Docker. Berikut contoh perintah untuk mengoptimalkan konfigurasi Docker:

```bash
sudo nano /etc/docker/daemon.json
```

Tambahkan baris berikut:

```json
{
  "exec-root": "/var/run/docker",
  "data-root": "/var/lib/docker",
  "log-driver": "json-file",
  "log-opts": {
    "labels": "com.example.labels",
    "env": "os,customer"
  }
}
```

Simpan dan restart Docker:

```bash
sudo systemctl restart docker
```

Dengan demikian, Anda telah mempersiapkan host dan LXC untuk dijadikan sebagai server yang aman dan stabil. Pastikan untuk melakukan update sistem secara teratur dan memantau log sistem untuk memastikan keamanan dan stabilitas server.
---

audited
---
