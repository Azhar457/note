---
title: "Dokumen 05 Maintenance Disaster Recovery"
tags:
  - chat-logs-phase-1
  - resources
created: "2026-04-24"
updated: "2026-07-21"
status: pending
cssclasses:
  - wide-table
  - callout
---


# Dokumen 05 — Maintenance, Disaster Recovery & Operasional

Dokumen panduan operasional pemeliharaan rutin, prosedur *disaster recovery*, otomatisasi backup, dan penanganan insiden infrastruktur server/container.

---

## 1. Strategi Backup 3-2-1

Strategi backup berlapis untuk mencegah kehilangan data akibat kegagalan hardware, kesalahan manusia, atau serangan ransomware:

| Lapis | Jenis Media | Lokasi Storage | Frekuensi | Retensi |
|---|---|---|---|---|
| **Lapis 1** | Local Storage (Proxmox VZDump) | `/var/lib/vz/dump` (SSD Local) | Harian (02:00) | 7 Hari |
| **Lapis 2** | External Cold Storage | External Drive / NAS | Mingguan (Minggu 03:00) | 4 Minggu |
| **Lapis 3** | Offsite Cloud Storage | Encrypted Rclone / S3 Compatible | Bulanan | 6 Bulan |

---

## 2. Otomatisasi Backup Proxmox VE (VZDump)

Menggunakan perintah CLI `vzdump` untuk snapshot otomatis LXC container dan Virtual Machine:

```bash
# Snapshot instan container 100 dengan kompresi zstd
vzdump 100 --mode snapshot --compress zstd --storage local --remove 0

# Jadwalkan cron job backup otomatis harian pukul 02:00
0 2 * * * root vzdump 100 101 102 --mode snapshot --compress zstd --storage local --keep-daily 7 >> /var/log/vzdump-cron.log 2>&1
```

---

## 3. Prosedur Restore Container & VM

> [!WARNING]
> Prosedur restore akan menimpa data container aktif. Pastikan mengambil snapshot keadaan sebelum restore dilakukan.

### Langkah-langkah Restore via CLI:
1. Hentikan container target:
   ```bash
   pct stop 100
   ```
2. Jalankan restore dari arsip backup `.tar.zst`:
   ```bash
   pct restore 100 /var/lib/vz/dump/vzdump-lxc-100-2026_07_21.tar.zst --storage local-lvm --force
   ```
3. Verifikasi status dan jalankan kembali container:
   ```bash
   pct start 100
   pct status 100
   ```

### Troubleshooting Kendala Restore:
- **Error `insufficient free space`**:
  Hapus dump lama di `/var/lib/vz/dump/` untuk memberikan ruang disk.
- **Error `storage pool does not exist`**:
  Periksa ID storage di `/etc/pve/storage.cfg` dan arahkan ke storage yang valid.

---

## 4. Manual Archive & External Offsite Sync Script

Skrip otomatisasi sinkronisasi backup ke media penyimpanan eksternal:

```bash
#!/usr/bin/env bash
set -euo pipefail

TARGET_MOUNT="/mnt/backup-external"
LOG_FILE="/var/log/backup-sync.log"

echo "[$(date)] Starting backup sync..." | tee -a "$LOG_FILE"

if mountpoint -q "$TARGET_MOUNT" || mount /dev/disk/by-label/BACKUP_EXT "$TARGET_MOUNT"; then
  rsync -avh --progress /var/lib/vz/dump/ "$TARGET_MOUNT/proxmox-dumps/" | tee -a "$LOG_FILE"
  echo "[$(date)] Backup sync completed successfully." | tee -a "$LOG_FILE"
else
  echo "[$(date)] ERROR: External target mount failed!" | tee -a "$LOG_FILE"
  exit 1
fi
```

---

## 5. Ekspansi Ukuran Disk LXC Container

Jika kuota storage pada LXC container mencapai batas kritis:

```bash
# Tambahkan kapasitas 10GB ke rootfs container 100
pct resize 100 rootfs +10G

# Verifikasi perubahan ukuran disk di dalam container
pct exec 100 -- df -h /
```

---

## 6. Maintenance & Emergency Cheat Sheet

| Perintah | Deskripsi Fungsi |
|---|---|
| `pct list` | Menampilkan seluruh status LXC container aktif |
| `pct config <id>` | Memeriksa konfigurasi spesifik container |
| `pct status <id>` | Memeriksa status kesehatan runtime container |
| `journalctl -u pve-cluster -n 50` | Debugging error klaster Proxmox |
| `df -hT` | Memeriksa penggunaan kapasitas filesystem |

---

## 7. Checklist Pra-Update Infrastruktur

- [x] Pastikan ketersediaan file backup *snapshot* terbaru (`.tar.zst`).
- [x] Periksa sisa ruang disk penyimpanan (minimal 20% free space).
- [x] Lakukan pemindaian integritas filesystem (`fsck` / `zpool status`).
- [x] Catat versi paket sistem sebelum melakukan `apt update && apt upgrade`.
## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian: ada vs tidak ada kontrol, efektivitas, dokumentasi, repeatable.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Never trust, always verify |
| **MITRE ATT&CK** | Framework TTP serangan |
| **SIEM** | Security Information & Event Management |
| **EDR** | Endpoint Detection & Response |
| **SOAR** | Security Orchestration & Response |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **OIDC** | OpenID Connect |
| **PKCE** | Proof Key for Code Exchange |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/
- Cloud Native (CNCF) — https://www.cncf.io/
