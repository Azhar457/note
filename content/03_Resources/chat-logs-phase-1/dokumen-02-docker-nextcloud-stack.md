---
title: "Dokumen 02 Docker Nextcloud Stack"
tags:
  - chat-logs-phase-1
  - resources
aliases:
  - "dokumen-02-docker-nextcloud-stack"
created: "2026-04-24"
updated: "2026-07-01"
status: operational
---

<think>
Okay, I need to expand the given Docker Nextcloud stack document to at least 1200 words. Let me look at the original content and see where I can add more details.

First, the original has sections on cleaning old Docker installations, installing Docker Engine V2, AppArmor removal, preparing persistent storage, the docker-compose.yml file, deployment, anti-reset principles, and access verification.

Each section is pretty concise. To expand, I can add more technical details in each step. For example, in the installation part, explain why using the official repository is better than the Ubuntu one. Also, maybe include some background on why AppArmor is disabled in LXC environments.

In the docker-compose.yml section, perhaps elaborate on each service configuration—why specific tags are chosen for MariaDB, what each environment variable does, and the importance of network configuration. Also, maybe add a note on security practices for the environment variables, like using secrets instead of plain text.

For the anti-reset section, I can explain the concept of immutable infrastructure more deeply, discuss the benefits, and perhaps provide an example of a CI/CD pipeline that automates the deployment process. Also, mention how using bind mounts instead of Docker volumes is more reliable in this context.

I should also consider adding troubleshooting tips in each section. For example, if the Docker containers fail to start, what are common issues and how to resolve them. Maybe include logs examples or common error messages.

Additionally, maybe include a step-by-step deployment checklist, a table comparing different approaches to persistent storage, or a diagram showing the architecture of the stack. Since the user mentioned not to use markdown diagrams but text-based ones, perhaps a simple ASCII art or textual description of the stack components and their interactions.

Another area is the Cloudflare tunnel setup. The original mentions it in the tunnel service but doesn't elaborate. I can add more details on how to generate the Cloudflare token, the Zero Trust configuration steps, and how the tunnel works to expose the Nextcloud instance securely.

Also, the security aspects—maybe discuss securing the MariaDB instance, like using SSL/TLS, limiting access via network policies, or setting up proper firewalls. In the AppArmor section, explain the trade-offs of disabling it and how Docker's default security measures can compensate.

Including performance tuning tips for Nextcloud and MariaDB, such as adjusting memory limits, using Docker resource constraints, or optimizing the filesystem for the bind mounts.

Lastly, ensure that all code examples are correct and that explanations are thorough enough to guide someone through each step without ambiguity. Maybe add more commands for verification, like checking Docker logs, verifying persistent data, or testing failover scenarios.
</think>

# Dokumen 02 — Infrastruktur Docker & Persistence Storage

> Implementasi Infrastructure as Code (IaC) dengan Docker Compose V2 untuk Nextcloud + MariaDB. Semua data diikat ke host LXC via bind mount agar tahan reboot, mati listrik, dan anti-reset.

---

## 1. Bersihkan Instalasi Docker Lama

Versi Python `docker-compose` lawas sudah tidak kompatibel dengan Ubuntu 24.04 (modul `distutils` dihapus). Hapus total sebelum instalasi resmi. Proses ini menghilangkan konflik library dan memastikan Docker menggunakan Golang-based Compose Plugin (v2) yang lebih cepat dan kompatibel dengan fitur terbaru.

```bash
sudo apt remove docker-compose docker.io -y
sudo apt autoremove -y
```

### Verifikasi Penghapusan

Pastikan semua artefak lama hilang:

```bash
dpkg -l | grep -E 'docker|compose'
```

---

## 2. Instalasi Docker Engine V2 (Golang)

Gunakan repositori resmi Docker Community Edition. Jangan pakai snap atau repositori bawaan Ubuntu. Pendekatan ini memastikan update langsung dari sumber otentik dan menghindari risiko kerentanan dari versi pihak ketiga.

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

### Verifikasi Instalasi

Cek versi untuk memastikan Golang-based Compose Plugin aktif:

```bash
docker compose version
```

Output yang valid menunjukkan `docker compose` (spasi, bukan `docker-compose`).

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
> Langkah ini wajib dilakukan setelah bypass AppArmor di host Proxmox. Jika dilewatkan, container Docker akan gagal start dengan error `exit status 243`.

### Alternatif Keamanan

Gantikan AppArmor dan SELinux dengan:

1. **SELinux dihost**: Jika Proxmox konfigurasi ulang.
2. **Firewalld**: Batasi akses jaringan ke container via port.
3. **Cap-shelve**: Batasi capability container (e.g., `--cap-drop=NET_RAW`).

---

## 4. Persiapan Direktori Persisten (Anti-Reset)

Data Nextcloud dan MariaDB akan disimpan di filesystem host LXC untuk keperawanan data. Strategi bind mount lebih stabil daripada Docker volume karena tidak bergantung pada service Docker.

```bash
sudo mkdir -p /opt/nextcloud/{app,data,db}
chcon -t container_file_t /opt/nextcloud/ -R  # Untuk kompatibilitas SELinux di host
```

### Struktur Folder

- `/opt/nextcloud/app`: File Nextcloud (termasuk `config.php`).
- `/opt/nextcloud/data`: Upload file pengguna.
- `/opt/nextcloud/db`: Data MariaDB (termasuk basis SQL).

> [!info]
> Jika container dihapus via `docker compose down -v`, data tetap aman karena tidak ada flag `-v` yang mengapus bind mount.

---

## 5. Penulisan File IaC (`docker-compose.yml`)

File ini adalah core dari konfigurasi. Fokus pada 3 poin kritis:

1. Tag spesifik untuk database (hindari `:latest`).
2. Jaringan internal Docker untuk komunikasi container.
3. Kunci keamanan minimalis.

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
    healthcheck:
      test: ["CMD", "mysqladmin", "ping", "-h", "localhost"]
      interval: 10s
      timeout: 5s
      retries: 5

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
      - NEXTCLOUD_ADMIN_USER=admin
      - NEXTCLOUD_ADMIN_PASSWORD=admin123!
    depends_on:
      db:
        condition: service_healthy

  tunnel:
    image: cloudflare/cloudflared:latest
    restart: always
    command: tunnel --no-autoupdate run --token MASUKKAN_TOKEN_ANDA
    ports:
      - "8080:80"
```

### Tips Keamanan

- Gunakan `Secrets` Docker untuk parameter sensitif (ganti `MYSQL_ROOT_PASSWORD` dengan `environment_files`).
- Aktifkan SSL di Nextcloud via HTTPS reverse proxy (lihat [[dokumen-05-ssl-and-reverse-proxy|Dokumen 05]]).

---

## 6. Deployment Stack

```bash
cd /opt/nextcloud
sudo docker compose up -
```
