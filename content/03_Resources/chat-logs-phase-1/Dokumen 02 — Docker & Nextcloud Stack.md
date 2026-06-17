---
tags:
  - Docker
  - Nextcloud
  - MariaDB
  - IaC
  - Compose
  - Cloud-Native
  - Persistence
aliases:
  - Nextcloud Stack
  - Docker Compose
  - Infrastructure as Code
status: operational
created: 2026-04-24
---
# Dokumen 02 — Infrastruktur Docker & Persistence Storage

> Implementasi Infrastructure as Code (IaC) dengan Docker Compose V2 untuk Nextcloud + MariaDB. Semua data diikat ke host LXC via bind mount agar tahan reboot, mati listrik, dan anti-reset.

---

## 1. Bersihkan Instalasi Docker Lama

Versi Python `docker-compose` lawas sudah tidak kompatibel dengan Ubuntu 24.04 (modul `distutils` dihapus). Hapus total sebelum instalasi resmi.

```bash
sudo apt remove docker-compose docker.io -y
sudo apt autoremove -y
```

---

## 2. Instalasi Docker Engine V2 (Golang)

Gunakan repositori resmi Docker Community Edition. Jangan pakai snap atau repositori bawaan Ubuntu.

```bash
sudo apt update
sudo apt install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings

# Tambahkan GPG key resmi Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Daftarkan repositori
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update
sudo apt install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin -y

# Mulai dan aktifkan Docker daemon
sudo systemctl start docker
sudo systemctl enable docker
```

> [!tip]
> Docker Compose V2 menggunakan perintah `docker compose` (spasi), bukan `docker-compose` (tanda hubung).

---

## 3. Menyingkirkan AppArmor (Redundan di LXC)

AppArmor bawaan Ubuntu 24.04 di dalam LXC bertabrakan dengan mekanisme Docker. Karena isolasi sudah ditangani Proxmox (Level 1), AppArmor di dalam LXC adalah redundansi yang merusak.

```bash
sudo systemctl stop apparmor
sudo apt purge apparmor -y
sudo rm -rf /etc/apparmor.d
sudo systemctl restart docker
```

> [!warning]
> Langkah ini wajib dilakukan setelah bypass AppArmor di host Proxmox (lihat [[Dokumen 01 — Persiapan Host & LXC|Dokumen 01]]). Jika dilewatkan, container Docker akan gagal start dengan error `exit status 243`.

---

## 4. Persiapan Direktori Persisten (Anti-Reset)

Data Nextcloud dan MariaDB akan disimpan di filesystem host LXC, bukan di dalam layer container yang sifatnya ephemera (sementara).

```bash
sudo mkdir -p /opt/nextcloud/{app,data,db}
```

> [!info]
> Struktur direktori ini adalah rumah permanenmu. Jika container dihapus total (`docker compose down -v`), data tetap aman di `/opt/nextcloud/` karena tidak termasuk flag `-v` untuk volume.

---

## 5. Penulisan File IaC (`docker-compose.yml`)

```bash
sudo nano /opt/nextcloud/docker-compose.yml
```

Isi dengan konfigurasi final berikut. Perhatikan poin-poin kritis:

- **Tidak ada atribut `version:`** — sudah usang di Compose V2, akan di-ignore.
- **MariaDB menggunakan tag spesifik** (`mariadb:12.2.2`) — jangan gunakan `:latest` untuk database agar terhindar dari bom waktu upgrade otomatis.
- **Nextcloud dan MariaDB** saling terhubung via jaringan internal Docker (`nextcloud_default`).
- **Cloudflared** sebagai sidecar container untuk tunnel ke internet (detail di [[Dokumen 03 — Cloudflare Tunnel & Routing|Dokumen 03]]).

```yaml
services:
  db:
    image: mariadb:12.2.2
    restart: always
    command: --transaction-isolation=READ-COMMITTED --log-bin=binlog --binlog-format=ROW
    volumes:
      - /opt/nextcloud/db:/var/lib/mysql
    environment:
      - MYSQL_ROOT_PASSWORD=@mariadb123@
      - MYSQL_PASSWORD=NextcloudUser123!
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud

  app:
    image: nextcloud:latest
    restart: always
    ports:
      - "8080:80"
    volumes:
      - /opt/nextcloud/app:/var/www/html
      - /opt/nextcloud/data:/var/www/html/data
    environment:
      - MYSQL_PASSWORD=NextcloudUser123!
      - MYSQL_DATABASE=nextcloud
      - MYSQL_USER=nextcloud
      - MYSQL_HOST=db
    depends_on:
      - db

  tunnel:
    image: cloudflare/cloudflared:latest
    restart: always
    command: tunnel --no-autoupdate run --token MASUKKAN_TOKEN_ANDA
```

> [!warning]
> Ganti `MASUKKAN_TOKEN_ANDA` dengan token panjang dari dashboard Cloudflare Zero Trust. Token ini akan diperoleh saat pembuatan tunnel di [[Dokumen 03 — Cloudflare Tunnel & Routing|Dokumen 03]].

Simpan (`Ctrl+O`, `Enter`, `Ctrl+X`).

---

## 6. Deployment Stack

```bash
cd /opt/nextcloud
sudo docker compose up -d
```

Perintah ini akan menarik (*pull*) image MariaDB, Nextcloud, dan Cloudflared dari Docker Hub, lalu menyalakannya di background sebagai daemon.

Verifikasi status:

```bash
sudo docker ps
```

Output yang diharapkan:

```text
CONTAINER ID   IMAGE                           STATUS          PORTS
xxxxxxxxxxxx   nextcloud:latest                Up x minutes    0.0.0.0:8080->80/tcp
xxxxxxxxxxxx   mariadb:12.2.2                  Up x minutes    3306/tcp
xxxxxxxxxxxx   cloudflare/cloudflared:latest   Up x minutes
```

---

## 7. Prinsip Anti-Reset & Immutable Infrastructure

### 7.1 Tahan Reboot & Mati Listrik

Jika listrik mati atau server reboot:

1. Proxmox menyalakan LXC secara otomatis.
2. Docker daemon membaca kembali `/opt/nextcloud/docker-compose.yml`.
3. Data tetap ada di `/opt/nextcloud/` karena di-mount ke host via bind volume.
4. Nextcloud melanjutkan operasi tanpa instalasi ulang atau setup wizard.

### 7.2 Larangan Mengubah Container Secara Manual

Jika Trivy menemukan CVE kritis (lihat [[Dokumen 04 — Security Stack|Dokumen 04]]), **jangan pernah** masuk ke dalam container untuk `apt upgrade`:

```bash
# ❌ SALAH — perubahan akan hilang saat restart
docker exec -it nextcloud-db-1 bash
apt update && apt upgrade
```

**Cara benar (Immutable Infrastructure):**

1. Cek Docker Hub apakah versi baru image sudah tersedia.
2. Ubah tag di `docker-compose.yml` (contoh: `mariadb:12.2.2` → `mariadb:12.2.3`).
3. Jalankan `sudo docker compose up -d`.
4. Docker menarik image baru dan mengganti container lama tanpa menyentuh data di `/opt/nextcloud/`.

---

## 8. Verifikasi Akses Lokal

Sebelum eksposur ke internet via tunnel, pastikan Nextcloud berjalan normal di jaringan lokal:

```text
http://192.168.1.51:8080
```

Jika halaman setup Nextcloud muncul, stack berhasil. Lanjutkan ke [[Dokumen 03 — Cloudflare Tunnel & Routing|Dokumen 03]] untuk konfigurasi domain publik dan Zero Trust.