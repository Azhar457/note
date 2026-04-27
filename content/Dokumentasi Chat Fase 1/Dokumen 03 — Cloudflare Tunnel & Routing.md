---
tags:
  - cloudflare
  - tunnel
  - zero-trust
  - networking
  - reverse-proxy
  - dns
aliases:
  - Cloudflare Tunnel
  - Zero Trust Routing
created: 2026-04-24
status: operational
---

# Dokumen 03 — Cloudflare Tunnel & Routing

> Eksposur Nextcloud ke internet menggunakan **Cloudflare Tunnel** (`cloudflared`). Tidak perlu membuka port 80/443 di router rumah. Semua koneksi bersifat **outbound** dari server ke Cloudflare — arsitektur Zero Trust murni.

---

## 1. Arsitektur Tunnel vs Tradisional

| Aspek               | Tradisional (Port Forward) | Cloudflare Tunnel (Zero Trust) |
| ------------------- | -------------------------- | ------------------------------ |
| **Arah koneksi**    | Inbound dari internet      | Outbound ke Cloudflare         |
| **Port router**     | Terbuka (80/443)           | Tertutup total                 |
| **IP publik**       | Terexpose langsung         | Tersembunyi                    |
| **DDoS protection** | Manual / berbayar          | Gratis bawaan                  |
| **SSL/HTTPS**       | Manual (Let's Encrypt)     | Otomatis (Cloudflare)          |

```text
Tradisional:  Internet ──► Router (Port 80/443) ──► NPM/Traefik ──► Nextcloud
Zero Trust:   Nextcloud ──► cloudflared ──► Cloudflare Edge ──► Internet
```

---

## 2. Pembuatan Tunnel di Dashboard Cloudflare

1. Masuk ke [Cloudflare Zero Trust](https://one.dash.cloudflare.com).
2. Navigasi ke **Networks** → **Tunnels**.
3. Klik **Create a tunnel** → pilih **Cloudflared**.
4. Beri nama tunnel: `homelab-proxmox`.
5. Di halaman **Choose your environment**, pilih **Docker**.
6. Salin nilai **Token** (string panjang setelah `--token`, contoh: `eyJhIjoiNDE1ZTBlNjI2MmRiNWZiYWEyZTFjMDYwZjczNjM4ZTci...`).

> [!warning]
> Token ini adalah kunci kerajaan. Jangan pernah dishare atau commit ke repository publik. Simpan di password manager.

---

## 3. Integrasi Token ke Docker Compose

Token tunnel sudah disuntikkan ke file `docker-compose.yml` di [[Dokumen 02 — Infrastruktur Docker & Persistence Storage|Dokumen 02]]. Pastikan blok `tunnel` terisi token asli:

```yaml
tunnel:
  image: cloudflare/cloudflared:latest
  restart: always
  command: tunnel --no-autoupdate run --token eyJhIjoiNDE1ZTBlNjI2MmRiNWZiYWEyZTFjMDYwZjczNjM4ZTciLCJ0IjoiYjg5Y2U3MTEtZTBmZS00MThmLTliMTMtMzIy...
```

Setelah disimpan, deploy ulang agar container `cloudflared` ikut menyala:

```bash
cd /opt/nextcloud
sudo docker compose up -d
```

Docker akan menarik image `cloudflared` dan menyambungkannya ke jaringan internal `nextcloud_default` yang sama dengan Nextcloud dan MariaDB.

Verifikasi container aktif:

```bash
sudo docker ps
```

---

## 4. Konfigurasi Public Hostname

Setelah container tunnel berjalan, status di dashboard akan berubah menjadi **Healthy / Connected**.

1. Buka dashboard Cloudflare → klik tunnel `homelab-proxmox`.
2. Masuk ke tab **Public Hostname**.
3. Klik **Add a public hostname**:

| Field            | Nilai              | Keterangan                                |
| ---------------- | ------------------ | ----------------------------------------- |
| **Subdomain**    | `nextcloud`        | Bebas, sesuai kebutuhan                   |
| **Domain**       | `namadomain.my.id` | Domain yang sudah diarahkan ke Cloudflare |
| **Path**         | _(kosongkan)_      | Akses root domain                         |
| **Service Type** | `HTTP`             | Bukan HTTPS — SSL diurus Cloudflare       |
| **URL**          | `app:80`           | DNS internal Docker (bukan IP!)           |

> [!tip]
> Mengapa `app:80`, bukan `192.168.1.51:8080`? Karena `cloudflared` berada di dalam jaringan Docker yang sama. Docker memiliki DNS internal yang menerjemahkan nama service (`app`) ke IP container Nextcloud secara otomatis. Ini adalah keajaiban Service Discovery di Docker Compose.

### 4.1 Multi-App Routing (Konsep)

Jika nanti menambah aplikasi lain di LXC yang sama (contoh: Kutt, Vaultwarden):

| Aplikasi    | Public Hostname              | URL Internal     |
| ----------- | ---------------------------- | ---------------- |
| Nextcloud   | `nextcloud.namadomain.my.id` | `app:80`         |
| Kutt        | `kutt.namadomain.my.id`      | `kutt:80`        |
| Vaultwarden | `vault.namadomain.my.id`     | `vaultwarden:80` |

> [!info]
> Semua service berbagi satu tunnel `cloudflared`. Tidak perlu membuat tunnel baru untuk setiap aplikasi.

### 4.2 Beda LXC/VM (Arsitektur Terdistribusi)

Jika aplikasi berada di LXC atau VM terpisah (contoh: Safeline di IP `192.168.1.52`), gunakan IP internal:

| Aplikasi     | Public Hostname        | URL Internal               |
| ------------ | ---------------------- | -------------------------- |
| Safeline WAF | `waf.namadomain.my.id` | `http://192.168.1.52:8080` |

---

## 5. Trusted Domains di Nextcloud

Nextcloud memiliki mekanisme **Host Header Validation** untuk mencegah serangan Host Header Poisoning. Domain publik harus didaftarkan secara eksplisit di `config.php`.

Edit file konfigurasi di **host LXC** (bukan di dalam container):

```bash
sudo nano /opt/nextcloud/app/config/config.php
```

Temukan blok `trusted_domains`, lalu tambahkan domain publikmu:

```php
  'trusted_domains' =>
  array (
    0 => '192.168.1.51:8080',
    1 => 'nextcloud.namadomain.my.id',
  ),
```

Simpan (`Ctrl+O`, `Enter`, `Ctrl+X`).

> [!info]
> Perubahan ini bersifat _real-time_. Tidak perlu restart container Docker. Nextcloud langsung menerima koneksi dari domain baru.

---

## 6. Verifikasi End-to-End

### 6.1 Dari Jaringan Lokal

```text
http://192.168.1.51:8080
```

Pastikan halaman login Nextcloud muncul normal.

### 6.2 Dari Jaringan Luar (Wajib)

Buka browser dari HP dengan **mobile data** (bukan WiFi rumah):

```text
https://nextcloud.namadomain.my.id
```

> [!tip]
> Menggunakan mobile data memastikan kamu benar-benar mengakses dari internet publik, bukan dari jaringan lokal yang bisa bypass DNS.

Jika halaman login Nextcloud muncul dengan sertifikat HTTPS hijau, seluruh rantai berhasil:

1. ✅ Cloudflare Tunnel terhubung
2. ✅ DNS internal Docker berfungsi
3. ✅ Trusted domains diterima Nextcloud
4. ✅ SSL otomatis aktif

---

## 7. Troubleshooting Umum

| Gejala                            | Penyebab                              | Solusi                                                                   |
| --------------------------------- | ------------------------------------- | ------------------------------------------------------------------------ |
| `502 Bad Gateway`                 | Nextcloud belum siap / container mati | `sudo docker ps` — pastikan `nextcloud-app-1` aktif                      |
| `Access through untrusted domain` | Domain belum di `config.php`          | Tambahkan ke `trusted_domains` di `/opt/nextcloud/app/config/config.php` |
| Tunnel status `Down`              | Token salah / container tidak jalan   | Cek log: `sudo docker logs nextcloud-tunnel-1`                           |
| HTTPS tidak hijau                 | SSL mode Cloudflare salah             | Di dashboard Cloudflare → **SSL/TLS** → pilih **Full (strict)**          |

---

## 8. Keamanan Tambahan di Cloudflare

### 8.1 Security Level

1. Dashboard Cloudflare → **Security** → **Settings**.
2. Ubah **Security Level** menjadi **High**.
3. Ini akan memunculkan tantangan keamanan (JavaScript challenge) bagi IP dengan reputasi buruk.

### 8.2 Always Use HTTPS

1. Dashboard Cloudflare → **SSL/TLS** → **Edge Certificates**.
2. Nyalakan **Always Use HTTPS**.
3. Semua request HTTP akan otomatis di-redirect ke HTTPS.

---

> [!info]
> Untuk memasang satpam keamanan aktif di server (Lynis, Trivy, CrowdSec), lanjut ke [[Dokumen 04 — Security Stack|Dokumen 04]].
> Untuk strategi backup dan maintenance, lanjut ke [[Dokumen 05 — Maintenance & Disaster Recovery|Dokumen 05]].

```

---

Mau lanjut ke **Dokumen 04** sekarang?
```
