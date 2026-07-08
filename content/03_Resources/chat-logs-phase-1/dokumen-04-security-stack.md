---
title: "Dokumen 04 Security Stack"
tags:
  - chat-logs-phase-1
  - resources
aliases:
  - "dokumen-04-security-stack"
created: "2026-04-24"
updated: "2026-07-01"
status: operational
---

# Dokumen 04 — Blue Team Phase 1 (Audit & IPS)

> Hardening tiga lapisan: OS (Lynis), Container (Trivy), dan Jaringan (CrowdSec + Cloudflare WAF). Semua dieksekusi di dalam LXC Nextcloud (`192.168.1.51`) dengan prinsip *defense in depth*.

---

## 1. Audit OS dengan Lynis

Lynis mengecek konfigurasi sistem operasi Ubuntu 24.04, mencari celah yang bisa dieksploitasi sebelum penyerang menyentuh aplikasi.

### 1.1 Instalasi

```bash
sudo apt update

# Tambahkan repositori Lynis
wget -O - https://packages.cisofy.com/keys/cisofy-software-public.key | sudo apt-key add -
echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" | sudo tee /etc/apt/sources.list.d/cisofy-lynis.list

# Fix GPG key jika muncul error NO_PUBKEY
gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 7A9A1D9D5B27C6D3
gpg --export 7A9A1D9D5B27C6D3 | sudo tee /etc/apt/trusted.gpg.d/lynis.gpg > /dev/null

sudo apt update
sudo apt install lynis -y
```

### 1.2 Eksekusi Audit

```bash
sudo lynis audit system
```

> [!tip]
> Fokus perbaikan pada bagian **Warnings** (merah), bukan seluruh 55+ *Suggestions*. Mengejar skor 100/100 bisa merusak fungsionalitas. Target realistis untuk homelab: **70–80/100**.

### 1.3 Remediasi Warning Kritis

Lynis akan mengeluarkan 4 warning utama. Berikut solusi definitifnya:

#### a) DNS Tidak Merespon (NETW-2704 / NETW-2705)

**Akar masalah:** DNS warisan Tailscale (`100.100.100.100` dan `fd7a:115c:a1e0::53`) tidak responsif di LXC.

**Solusi via Proxmox Web UI:**
1. Klik LXC `100` (Docker-Server).
2. Pergi ke menu **DNS**.
3. Isi **DNS servers**: `1.1.1.1 8.8.8.8`
4. **Restart** LXC.

> [!warning]
> Jangan edit `/etc/resolv.conf` secara manual di dalam LXC. Proxmox akan menimpa (*overwrite*) file tersebut saat restart.

#### b) Kebocoran Informasi SMTP Banner (MAIL-8818)

**Akar masalah:** Postfix secara default membocorkan nama OS dan versi software ke setiap koneksi.

**Solusi:**
```bash
sudo postconf -e "smtpd_banner = \$myhostname ESMTP"
sudo systemctl restart postfix
```

Server sekarang hanya menjawab hostname, tanpa menyebutkan `Ubuntu` atau `Postfix`.

#### c) SSH Root Login (SSH-7408)

**Akar masalah:** Login root via password adalah target empuk brute-force.

**Solusi — Buat jalur alternatif dulu:**

```bash
# Buat user non-root
sudo adduser hinzi
sudo usermod -aG sudo hinzi
```

**Verifikasi kritis (jangan lewatkan):**
1. Buka tab baru di Termius.
2. Login dengan `hinzi@192.168.1.51`.
3. Ketik `sudo su` dan masukkan password — pastikan bisa menjadi root.

> [!important]
> Jangan kunci root sebelum verifikasi `sudo` berhasil. Jika terkunci, satu-satunya jalur masuk adalah Console Proxmox.

**Setelah terverifikasi, kunci root:**
```bash
sudo nano /etc/ssnamadomainonfig
```

Ubah:
```text
PermitRootLogin no
```

Restart SSH:
```bash
sudo systemctl restart ssh
```

Mulai sekarang, semua akses remote menggunakan `hinzi`, lalu `sudo` jika perlu hak root.

---

## 2. Audit Container dengan Trivy

Trivy memindai image Docker dan mencocokkannya dengan database CVE global. Ini adalah realita pahit dunia open source: image "resmi" sering mengandung ratusan kerentanan.

### 2.1 Instalasi

```bash
sudo apt-get install wget apt-transport-https gnupg lsb-release -y

wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | gpg --dearmor | sudo tee /usr/share/keyrings/trivy.gpg > /dev/null

echo "deb [signed-by=/usr/share/keyrings/trivy.gpg] https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main" | sudo tee -a /etc/apt/sources.list.d/trivy.list

sudo apt-get update
sudo apt-get install trivy -y
```

### 2.2 Pemindaian Targeted

Jangan scan mentah — fokus pada ancaman nyata yang sudah ada obatnya:

```bash
# Scan image Nextcloud
sudo trivy image --severity HIGH,CRITICAL --ignore-unfixed nextcloud:latest

# Scan image MariaDB
sudo trivy image --severity HIGH,CRITICAL --ignore-unfixed mariadb:12.2.2
```

| Flag | Fungsi |
|---|---|
| `--severity HIGH,CRITICAL` | Hanya tampilkan kerentanan tinggi dan kritis |
| `--ignore-unfixed` | Abaikan CVE yang belum ada patchnya (tidak bisa kita perbaiki) |

### 2.3 Interpretasi Hasil

**Jika muncul CVE pada `gosu` atau `stdlib`:**
- Ini adalah *utility* kecil di dalam image, bukan aplikasi utamanya.
- Jangan pernah patching manual dengan `apt upgrade` di dalam container.

> [!warning]
> **Larangan mutlak:** Masuk ke container untuk update manual akan merusak prinsip *immutable infrastructure*. Perubahan itu musnah saat restart.

**Cara benar (Immutable Infrastructure):**
1. Cek Docker Hub apakah versi baru image sudah dirilis.
2. Ubah tag di `docker-compose.yml` (contoh: `mariadb:12.2.2` → `mariadb:12.2.3`).
3. Jalankan `sudo docker compose up -d`.
4. Docker menarik image baru dan mengganti container lama tanpa menyentuh data.

---

## 3. Implementasi CrowdSec & Firewall Bouncer

CrowdSec adalah IPS (Intrusion Prevention System) berbasis komunitas. Ia membaca log sistem, mendeteksi pola serangan, dan memblokir IP penyerang di level firewall (iptables).

### 3.1 Instalasi Engine & Bouncer

```bash
# Install repositori CrowdSec
curl -s https://install.crowdsec.net | sudo sh

# Install engine
sudo apt install crowdsec -y

# Install bouncer firewall (otot yang menendang IP)
sudo apt install crowdsec-firewall-bouncer-iptables -y
```

### 3.2 Resolusi Konflik Port 8080

**Akar masalah:** CrowdSec LAPI (Local API) dan Nextcloud sama-sama mengincar port `8080`.

**Solusi — Pindahkan CrowdSec ke port `8081`:**

```bash
# Ubah port di konfigurasi utama
sudo sed -i 's/127.0.0.1:8080/127.0.0.1:8081/g' /etc/crowdsec/config.yaml

# Ubah port untuk CLI (cscli)
sudo sed -i 's/127.0.0.1:8080/127.0.0.1:8081/g' /etc/crowdsec/local_api_credentials.yaml

# Ubah port untuk bouncer firewall
sudo sed -i 's/127.0.0.1:8080/127.0.0.1:8081/g' /etc/crowdsec/bouncers/crowdsec-firewall-bouncer.yaml
```

Restart layanan:
```bash
sudo systemctl restart crowdsec
sudo systemctl restart crowdsec-firewall-bouncer
```

Verifikasi status:
```bash
sudo systemctl status crowdsec
```

Output yang diharapkan: `Active: active (running)`

### 3.3 Verifikasi Blokir Global

CrowdSec otomatis mengunduh ribuan IP berbahaya dari komunitas global:

```bash
sudo cscli decisions list
```

> [!tip]
> Jika muncul `No active decisions`, itu normal. Daftar akan terisi seiring waktu saat servermu mulai menerima traffic. Atau gunakan `sudo cscli hub update && sudo cscli collections install crowdsecurity/nginx` untuk mempercepat deteksi.

---

## 4. Pengamanan Layer 7 dengan Cloudflare

Daripada memasang WAF lokal (Safeline) yang rakus RAM, gunakan WAF bawaan Cloudflare — gratis dan tidak membebani server.

### 4.1 Geo-Blocking (Custom Rule)

Blokir 99% noise dari botnet luar negeri:

1. Dashboard Cloudflare → domain `namadomain.my.id`.
2. **Security** → **WAF** → **Custom rules**.
3. Klik **Create rule**:
   - **Rule name:** `Block Non Indonesia`
   - **Expression:** `(ip.geoip.country ne "ID")`
   - **Action:** `Block`
4. Klik **Deploy**.

> [!info]
> Aturan ini membuang traffic dari Rusia, China, AS, Eropa — tempat asal mayoritas botnet brute-force. CrowdSec di server hanya perlu fokus pada IP Indonesia yang mencurigakan.

### 4.2 Managed Ruleset (Gratis)

1. Di tab **Managed rules**, cari **Cloudflare Free Managed Ruleset**.
2. Pastikan statusnya **Deployed / On**.
3. Ini memblokir eksploitasi umum: SQLi, XSS, Shellshock, Log4j, dsb.

### 4.3 Security Level

1. **Security** → **Settings**.
2. Ubah **Security Level** menjadi **High**.
3. IP dengan reputasi buruk akan mendapat tantangan JavaScript sebelum melihat halaman.

---

## 5. Defense in Depth — Ringkasan Lapisan

| Lapisan | Tools | Fungsi | Level OSI |
|---|---|---|---|
| **Perimeter** | Cloudflare Geo-Block + WAF | Buang ancaman luar negeri & eksploitasi umum | Layer 7 |
| **Tunnel** | Cloudflared | Sembunyikan IP asli, tidak ada port forwarding | Layer 4 |
| **Network** | CrowdSec + Firewall Bouncer | Blokir IP jahat di level OS (iptables) | Layer 3/4 |
| **Container** | Trivy | Audit CVE pada image Docker | Layer 2 |
| **OS** | Lynis | Hardening konfigurasi sistem | Layer 1 |
| **Aplikasi** | Nextcloud Auth + 2FA | Keamanan akhir (password, MFA) | Layer 7 |

> [!tip]
> Serangan yang lolos dari Cloudflare akan dihadang CrowdSec. Serangan yang lolos CrowdSec akan dihadang Nextcloud Auth. Tidak ada single point of failure.

---

## 6. Cheat Sheet Keamanan Harian

| Tugas | Perintah |
|---|---|
| Cek status CrowdSec | `sudo systemctl status crowdsec` |
| Lihat IP yang diblokir | `sudo cscli decisions list` |
| Lihat log serangan real-time | `sudo tail -f /var/log/crowdsec.log` |
| Update scenario CrowdSec | `sudo cscli hub update && sudo cscli collections upgrade -a` |
| Scan ulang dengan Trivy | `sudo trivy image --severity HIGH,CRITICAL --ignore-unfixed nextcloud:latest` |
| Re-run Lynis audit | `sudo lynis audit system` |

---

> [!info]
> Untuk strategi backup otomatis dan disaster recovery, lanjut ke [[dokumen-05-maintenance-disaster-recovery|Dokumen 05]].