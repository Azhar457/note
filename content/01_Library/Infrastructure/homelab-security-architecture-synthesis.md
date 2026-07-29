---
title: "Homelab Security Architecture — Proxmox + Nextcloud + Cloudflare + Suricata + Disaster Recovery"
tags:
  - homelab
  - infrastructure
  - security
  - proxmox
  - nextcloud
  - cloudflare
  - suricata
  - backup
  - library
aliases:
  - "homelab-architecture-synthesis"
  - "proxmox-security-stack"
  - "nextcloud-homelab"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
cssclasses:
  - wide-table
---

# 🏠 Homelab Security Architecture — Proxmox + Nextcloud + Cloudflare Zero Trust + Suricata + Disaster Recovery

> **Filosofi:** Homelab adalah mini data center pribadi — lengkap dengan hypervisor (Proxmox), self-hosted cloud storage (Nextcloud), zero-trust tunnel (Cloudflare), intrusion detection (Suricata), dan disaster recovery plan. Berbeda dengan production cloud — di homelab, **single point of failure is the physical host.** Semua layer keamanan harus self-contained karena gak ada cloud provider yang backup.

> [!info] Sumber Material
> Catatan ini synthesis dari 6 dokumen chat-log phase-1 (`dokumen-01` s/d `dokumen-06`) di `03_Resources/chat-logs-phase-1/`. Chat-log mentah berisi thinking chain dan debugging session — di sini dikompilasi jadi arsitektur final + command reference yang siap copy-paste.

> [!info] Posisi di Vault
> Terhubung dengan [[infrastructure-administrator]] (sysadmin patterns), [[networking-fundamentals-tcpip-bgp]] (TCP fundamentals + Suricata placement), [[container-kubernetes-security-deepdive]] (container hardening), [[cloudflare-ruleset-engine-phases]] (Cloudflare WAF + Tunnel), [[database-security-sql-nosql-injection-defense]] (DB hardening), [[postgresql-admin-backup]] (backup strategy), dan [[ollama-vllm-self-hosting-deployment]] (self-hosted AI).

---

## Daftar Isi

- [[#1. Arsitektur Fisik & Virtual]]
- [[#2. Proxmox Host Hardening]]
- [[#3. LXC Container — Nextcloud Stack]]
- [[#4. Cloudflare Zero Trust Tunnel]]
- [[#5. Security Stack — Suricata IDS/IPS]]
- [[#6. Backup Strategy — 3-2-1 Rule]]
- [[#7. Disaster Recovery Plan]]
- [[#8. Monitoring — Health Check Script]]
- [[#9. Maintenance — Update + Expansion]]
- [[#10. Pre-Update Checklist]]
- [[#11. Cheat Sheet — Quick Reference]]

---

## 1. Arsitektur Fisik & Virtual

### 1.1 Physical Layout

```plaintext
┌───────────────────────────────────────────────────────┐
│                  PHYSICAL HOST (Proxmox VE)            │
│  CPU: Intel/AMD | RAM: 8-32GB | SSD: 256GB+           │
│                                                       │
│  ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  │
│  │ LXC 100      │  │ LXC 101      │  │ LXC 102     │  │
│  │ Nextcloud    │  │ Docker Host  │  │ Suricata    │  │
│  │ + PostgreSQL │  │ + Monitoring │  │ IDS/IPS     │  │
│  │ + Redis      │  │ + Ollama     │  │ (inline)    │  │
│  └──────────────┘  └──────────────┘  └─────────────┘  │
│                                                       │
│  ┌──────────────────────────────────────────────────┐ │
│  │           EXTERNAL HDD (USB/SATA)                │ │
│  │  Backup target: vzdump + rsync mirror            │ │
│  └──────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────┘
         │
         ▼
   Cloudflare Tunnel (cloudflared)
         │
         ▼
   INTERNET → nextcloud.yourdomain.com
```

### 1.2 LXC Resource Allocation (8GB Host)

| LXC          | Purpose                             | RAM  | Disk  | CPU     |
| ------------ | ----------------------------------- | ---- | ----- | ------- |
| **100**      | Nextcloud + PostgreSQL + Redis      | 2 GB | 32 GB | 2 cores |
| **101**      | Docker (Portainer, Ollama, Grafana) | 3 GB | 40 GB | 2 cores |
| **102**      | Suricata IDS (inline)               | 1 GB | 16 GB | 1 core  |
| **Reserved** | Proxmox host overhead               | 2 GB | N/A   | N/A     |

---

## 2. Proxmox Host Hardening

### 2.1 Post-Install Security

```bash
# Update + reboot
apt update && apt dist-upgrade -y && reboot

# Disable root SSH
sed -i 's/^PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
systemctl restart sshd

# UFW basics
ufw default deny incoming
ufw default allow outgoing
ufw allow 8006/tcp  # Proxmox web UI
ufw allow 22/tcp    # SSH
ufw enable

# Fail2ban for Proxmox
apt install fail2ban -y
cat > /etc/fail2ban/jail.d/proxmox.conf <<EOF
[proxmox]
enabled = true
port = 8006
filter = proxmox
logpath = /var/log/pveproxy/access.log
maxretry = 5
bantime = 3600
EOF
systemctl restart fail2ban
```

### 2.2 Proxmox Backup Schedule (CLI)

```bash
# vzdump semua container setiap hari jam 2 pagi, retention 3
# Simpan di local storage:
cat > /etc/cron.d/vzdump-backup <<'EOF'
0 2 * * * root vzdump 100 101 102 --mode snapshot --compress zstd --storage local --retention 3
EOF
```

---

## 3. LXC Container — Nextcloud Stack

### 3.1 docker-compose.yml

```yaml
version: "3.8"

services:
  postgres:
    image: postgres:16.3-alpine
    container_name: nc-postgres
    restart: unless-stopped
    environment:
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: ${NC_DB_PASSWORD}
    volumes:
      - ./pg-data:/var/lib/postgresql/data
    # No port bind — only accessible from internal docker network

  redis:
    image: redis:7.2-alpine
    container_name: nc-redis
    restart: unless-stopped
    command: redis-server --requirepass ${REDIS_PASSWORD}
    volumes:
      - ./redis-data:/data

  nextcloud:
    image: nextcloud:29.0-fpm-alpine
    container_name: nextcloud-app
    restart: unless-stopped
    environment:
      POSTGRES_HOST: postgres
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: ${NC_DB_PASSWORD}
      REDIS_HOST: redis
      REDIS_HOST_PASSWORD: ${REDIS_PASSWORD}
      NEXTCLOUD_TRUSTED_DOMAINS: "nextcloud.yourdomain.com"
    volumes:
      - ./nc-data:/var/www/html
    depends_on:
      - postgres
      - redis

  nginx:
    image: nginx:alpine
    container_name: nc-nginx
    restart: unless-stopped
    ports:
      - "127.0.0.1:8081:80"
    volumes:
      - ./nginx-nextcloud.conf:/etc/nginx/conf.d/default.conf:ro
    depends_on:
      - nextcloud
```

### 3.2 Nextcloud Security Config

```php
// config/config.php additions
$CONFIG = array(
  'trusted_domains' => ['nextcloud.yourdomain.com'],
  'overwriteprotocol' => 'https',
  'overwrite.cli.url' => 'https://nextcloud.yourdomain.com',
  'htaccess.RewriteBase' => '/',
  'maintenance_window_start' => 1,
  // Security hardening
  'allow_local_remote_servers' => false,
  'filelocking.enabled' => true,
  'memcache.locking' => '\OC\Memcache\Redis',
);
```

---

## 4. Cloudflare Zero Trust Tunnel

### 4.1 Tunnel Architecture

```plaintext
INTERNET                   CLOUDFLARE EDGE            HOMELAB
────────                   ───────────────            ───────
Browser → HTTPS → Cloudflare → Tunnel (cloudflared) → LXC: nginx → Nextcloud
                  │
                  ├─ WAF (OWASP CRS + Cloudflare Managed Rules)
                  ├─ Zero Trust Access (OTP / SSO before tunnel)
                  ├─ Bot Fight Mode
                  └─ DDoS protection (automatic)
```

### 4.2 Setup cloudflared di LXC

```bash
# Install cloudflared
curl -L https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64 -o /usr/local/bin/cloudflared
chmod +x /usr/local/bin/cloudflared

# Login + buat tunnel
cloudflared tunnel login
cloudflared tunnel create homelab-proxmox

# Konfigurasi tunnel
cat > ~/.cloudflared/config.yml <<EOF
tunnel: <TUNNEL_ID>
credentials-file: /root/.cloudflared/<TUNNEL_ID>.json

ingress:
  - hostname: nextcloud.yourdomain.com
    service: http://localhost:8081
  - service: http_status:404
EOF

# Install sebagai service
cloudflared service install
systemctl enable cloudflared --now
```

### 4.3 Cloudflare Zero Trust Access (OTP before tunnel)

```
Cloudflare Dashboard → Zero Trust → Access → Applications:
  - Application: nextcloud.yourdomain.com
  - Policy: Allow email azhar@urbansolv.co.id
  - Method: OTP via email (one-time PIN)

Result: attacker gak bisa akses nextcloud walaupun tahu URL-nya —
        harus masuk OTP dulu sebelum tunnel respond.
```

---

## 5. Security Stack — Suricata IDS/IPS

### 5.1 Placement: NFQUEUE Inline Mode

```plaintext
┌──────────┐    ┌──────────┐    ┌──────────┐
│ INTERNET │───▶│ SURICATA │───▶│ LXC 100  │
│          │    │ (inline) │    │ Nextcloud│
└──────────┘    └──────────┘    └──────────┘
                     │
                     ▼
              NFQUEUE di iptables
```

```bash
# iptables — redirect traffic ke Suricata NFQUEUE
iptables -I FORWARD -p tcp --dport 80 -j NFQUEUE --queue-num 0
iptables -I FORWARD -p tcp --dport 443 -j NFQUEUE --queue-num 0

# Suricata inline mode config
# /etc/suricata/suricata.yaml:
af-packet:
  - interface: eth0
    threads: 1
    cluster-id: 99
    cluster-type: cluster_flow

nfq:
  mode: accept
  repeat-mark: 1
  repeat-mask: 1
  bypass-mark: 1
  bypass-mask: 1
  route-queue: 2
  batchcount: 20
  fail-open: yes  # ← penting! Kalau Suricata crash, traffic tetap jalan
```

### 5.2 Suricata Rules — Homelab Specific

```bash
# Enable OWASP emerging threats rules:
suricata-update enable-source et/open
suricata-update enable-source oisf/trafficid
suricata-update enable-source sslbl/ssl-fp-blacklist

# Custom rule — alert Nextcloud brute force
cat > /var/lib/suricata/rules/local.rules <<'EOF'
alert http $HOME_NET any -> any any (msg:"Nextcloud brute force login";
  flow:to_server,established; content:"POST"; http_method;
  content:"/login"; http_uri; content:"password"; http_client_body;
  threshold:type both,track by_src,count 10,seconds 60;
  classtype:attempted-recon; sid:1000001; rev:1;)
EOF

suricata-update
systemctl restart suricata
```

---

## 6. Backup Strategy — 3-2-1 Rule

### 6.1 Three Layers

```
Layer 1: Proxmox vzdump (online, fast recovery)
         └─ vzdump 100 --mode snapshot → /var/lib/vz/dump/
         └─ retention: 3 copies (daily)
         └─ format: .tar.zst (Zstandard compression)

Layer 2: External HDD rsync (offline, independent)
         └─ rsync /var/lib/vz/dump/ → /mnt/backup-hdd/
         └─ daily at 3 AM
         └─ sha256sum verification

Layer 3: Offsite (Cloud / different location)
         └─ rclone sync to Backblaze B2 / Google Drive
         └─ weekly, encrypted
         └─ $6/TB/month (B2)
```

### 6.2 Backup Script — Automated

```bash
#!/bin/bash
# /usr/local/bin/homelab-backup.sh
set -euo pipefail
DATE=$(date +%Y-%m-%d)
LOG="/var/log/homelab-backup-${DATE}.log"

exec > >(tee -a "$LOG") 2>&1

echo "=== HOMELAB BACKUP START: $(date) ==="

# Layer 1: Proxmox vzdump — handled by cron di section 2.2
# Layer 2: External HDD
echo "[1/3] Mount external HDD..."
TARGET="/mnt/backup-hdd"
mkdir -p "$TARGET"
mount /dev/disk/by-label/BACKUP "$TARGET"

echo "[2/3] Rsync vzdump to HDD..."
rsync -av --progress /var/lib/vz/dump/vzdump-lxc-*.tar.zst "$TARGET/"

echo "[2/3] Verify checksums..."
cd "$TARGET"
sha256sum *.tar.zst > checksums-${DATE}.sha256

echo "[3/3] Unmount HDD..."
umount "$TARGET"

echo "=== HOMELAB BACKUP DONE: $(date) ==="
```

---

## 7. Disaster Recovery Plan

### 7.1 Restore from Scratch

```plaintext
SCENARIO: Host SSD mati total → rebuild dari backup HDD + cloud.

STEP 1: Reinstall Proxmox VE (USB ISO, 15 menit)
STEP 2: Restore LXC dari vzdump backup:
        pct restore 100 /mnt/backup-hdd/vzdump-lxc-100-2026_07_19-*.tar.zst
        pct restore 101 ...
        pct restore 102 ...
STEP 3: Start container: pct start 100 101 102
STEP 4: Reinstall cloudflared + reconnect tunnel
STEP 5: Verify: https://nextcloud.yourdomain.com → login
STEP 6: Restore file-level data dari cloud backup (rclone)
```

### 7.2 Recovery Time Objective (RTO)

| Component           | Time to Recover   | Notes                              |
| ------------------- | ----------------- | ---------------------------------- |
| Proxmox OS          | 15 min            | Fresh install from USB             |
| LXC restore         | 5 min each (zstd) | Fast karena snapshot restore       |
| Cloudflare tunnel   | 5 min             | Reinstall cloudflared + re-auth    |
| Full Nextcloud data | 1-2 hours         | Dari rclone offsite backup         |
| **Total RTO**       | **~2-3 hours**    | Bisa 30min tanpa full data restore |

---

## 8. Monitoring — Health Check Script

### 8.1 whats-up.sh

```bash
#!/bin/bash
# /usr/local/bin/whats-up.sh
# Run on-demand dari SSH/Termius — one view all status

echo "╔══════════════════════════════════════╗"
echo "║  HOMELAB HEALTH CHECK — $(date)    ║"
echo "╚══════════════════════════════════════╝"

# Container status
echo -e "\n📦 CONTAINERS:"
for ct in 100 101 102; do
  state=$(pct status $ct 2>/dev/null | awk '{print $2}')
  case $state in
    running) echo "  ✅ LXC $ct — running" ;;
    stopped) echo "  🔴 LXC $ct — STOPPED" ;;
    *)       echo "  ⚠️  LXC $ct — $state" ;;
  esac
done

# Disk usage
echo -e "\n💾 DISK:"
df -h / /mnt/backup-hdd | tail -2

# Docker services inside LXC 101
echo -e "\n🐳 DOCKER (LXC 101):"
pct exec 101 -- docker ps --format "  {{.Names}} — {{.Status}}" 2>/dev/null || echo "  ⚠️  Cannot connect"

# Nextcloud health
echo -e "\n☁️ NEXTCLOUD:"
curl -sk --max-time 5 https://localhost:8081/status.php 2>/dev/null | jq -r '
  "  installed: \(.installed), version: \(.versionstring // "N/A"), users: \(.num_users // "N/A")"' || echo "  ⚠️  Not responding"

# Cloudflare tunnel
echo -e "\n🌐 CLOUDFLARE:"
systemctl is-active cloudflared 2>/dev/null || echo "  inactive"
curl -sk --max-time 5 https://nextcloud.yourdomain.com/login 2>/dev/null | grep -q "Nextcloud" && echo "  ✅ Tunnel accessible" || echo "  🔴 Tunnel NOT accessible"

# Recent errors
echo -e "\n🚨 RECENT ERRORS (last 1h):"
journalctl --since "1 hour ago" -p err --no-pager -n 5 2>/dev/null || echo "  (clean)"

echo -e "\n══════════════════════════════════════"
```

---

## 9. Maintenance — Update + Expansion

### 9.1 LXC Disk Expansion

```bash
# Resize LXC disk dari 32GB ke 48GB
pct resize 100 rootfs 48G
# Verify inside container: df -h /
```

### 9.2 Weekly Update Routine

```bash
# Host Proxmox
apt update && apt list --upgradable
# Review: apakah ada kernel update? → perlu reboot
apt dist-upgrade -y

# LXC containers
for ct in 100 101 102; do
  pct exec $ct -- apt update && apt upgrade -y
done

# Docker images (LXC 101)
pct exec 101 -- docker compose pull
pct exec 101 -- docker compose up -d --remove-orphans

# Suricata rules (LXC 102)
pct exec 102 -- suricata-update
pct exec 102 -- systemctl restart suricata
```

---

## 10. Pre-Update Checklist

```
☐ Run backup: /usr/local/bin/homelab-backup.sh
☐ Verify backup: sha256sum /mnt/backup-hdd/checksums-*.sha256
☐ Check disk space: df -h → >20% free on /
☐ Read changelog: apt changelog <package-to-update>
☐ Stop non-essential containers: docker compose stop (optional)
☐ apt dist-upgrade -y
☐ Reboot if kernel updated
☐ Post-reboot: run whats-up.sh
☐ Wait 2 hours for monitoring observation
☐ Check Suricata: tail -f /var/log/suricata/fast.log
```

---

## 11. Cheat Sheet — Quick Reference

| Task                     | Command                                                                  |
| ------------------------ | ------------------------------------------------------------------------ |
| **Container status**     | `pct list`                                                               |
| **Container start/stop** | `pct start 100` / `pct stop 100`                                         |
| **Container console**    | `pct enter 100`                                                          |
| **Backup (snapshot)**    | `vzdump 100 --mode snapshot --compress zstd`                             |
| **Restore**              | `pct restore 100 /path/to/vzdump-lxc-100-*.tar.zst`                      |
| **Docker status**        | `pct exec 101 -- docker ps`                                              |
| **Docker compose up**    | `pct exec 101 -- docker compose -f /opt/docker/docker-compose.yml up -d` |
| **Nextcloud OCC**        | `pct exec 100 -- docker exec nextcloud-app php occ`                      |
| **Cloudflare restart**   | `systemctl restart cloudflared`                                          |
| **Suricata logs**        | `pct exec 102 -- tail -f /var/log/suricata/eve.json \| jq .`             |
| **Suricata restart**     | `pct exec 102 -- systemctl restart suricata`                             |
| **Health check**         | `/usr/local/bin/whats-up.sh`                                             |
| **Disk resize**          | `pct resize <CTID> rootfs <SIZE>G`                                       |
| **SSH to container**     | `ssh root@<lxc-ip>`                                                      |

---

## 🔗 Lihat Juga

- [[infrastructure-administrator]] — Full sysadmin patterns + Ansible automation
- [[networking-fundamentals-tcpip-bgp]] — TCP fundamentals (Suricata placement context)
- [[container-kubernetes-security-deepdive]] — Container hardening (AppArmor, seccomp, Falco)
- [[cloudflare-ruleset-engine-phases]] — Cloudflare WAF + Tunnel architecture detail
- [[database-security-sql-nosql-injection-defense]] — PostgreSQL RLS + hardening
- [[postgresql-admin-backup]] — Backup strategy (pg_dump -Fc, verification)
- [[ollama-vllm-self-hosting-deployment]] — Self-hosted AI di LXC 101
- [[ids-ips-waf-nsm-comparison]] — Suricata vs Zeek vs WAF comparison
- [[dns-fundamentals-bind9]] — DNS for internal services

---

## Referensi

- Proxmox VE. _Administration Guide_. https://pve.proxmox.com/wiki/Main_Page
- Nextcloud. _Admin Manual_. https://docs.nextcloud.com/server/latest/admin_manual/
- Cloudflare. _Zero Trust Tunnel_. https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/
- Suricata. _Inline IPS Mode_. https://suricata.readthedocs.io/en/suricata-7.0.0/setting-up-ipsinline-for-linux/
- OWASP. _ModSecurity Core Rule Set_. https://coreruleset.org/
- Backblaze B2. _Cloud Backup Pricing_. https://www.backblaze.com/cloud-storage/pricing

---

_Dibuat: 19 Juli 2026 — Synthesis dari 6 chat-log phase-1: homelab end-to-end architecture siap copy-paste deploy._
