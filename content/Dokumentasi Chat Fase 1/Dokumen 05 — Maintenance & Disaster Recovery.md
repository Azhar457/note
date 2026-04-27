---
tags:
  - backup
  - proxmox
  - disaster-recovery
  - maintenance
  - snapshot
  - resize
aliases:
  - Maintenance
  - Disaster Recorvery
  - DR Strategy
created: 2026-04-24
status: operational
---
# Dokumen 05 — Disaster Recovery & Operasional

 > [!info] Strategi kelangsungan hidup homelab berbasis aturan **3-2-1**: 3 salinan data, 2 media berbeda, 1 di luar lokasi. Semua operasi backup dilakukan dari Web UI Proxmox tanpa menyentuh LXC.

---

## 1. Strategi Backup 3-2-1

Aturan emas industri untuk data yang tidak boleh hilang:

| Lapis | Nama | Lokasi | Kegunaan |
|---|---|---|---|
| **1** | Snapshot | SSD Proxmox (storage `local`) | Rollback cepat jika konfigurasi salah atau update gagal |
| **2** | Archive | HDD eksternal / TrueNAS / NAS | Cadangan jika SSD mati atau Proxmox corrupt |
| **3** | Offsite | Cloud (Google Drive / S3 / Backblaze B2) | Tahan bencana fisik (banjir, kebakaran, pencurian) |

> [!info]
> Dokumen ini membahas **Lapis 1** secara otomatis dan **Lapis 2** secara manual. **Lapis 3** dapat diimplementasikan dengan `rclone` atau Proxmox Backup Server di kemudian hari.

---

## 2. Otomatisasi Backup Proxmox (Snapshot Mode)

Proxmox dapat mem-backup LXC secara *live* (tanpa shutdown) menggunakan teknologi snapshot. Prosesnya memakan waktu 1–3 menit untuk LXC 50 GB.

### 2.1 Membuat Jadwal Backup

1. Buka **Web UI Proxmox** (`https://192.168.1.50:8006`).
2. Klik **Datacenter** (ikon bumi) di menu kiri atas.
3. Pilih menu **Backup**.
4. Klik tombol **Add**.

Isi parameter berikut:

| Parameter | Nilai | Keterangan |
|---|---|---|
| **Node** | `pve` | Node Proxmox Anda |
| **Storage** | `local` | Tempat file backup disimpan (bisa diganti ke storage khusus) |
| **Schedule** | `02:00` | Setiap hari jam 2 pagi — saat traffic homelab minimal |
| **Selection mode** | `Include selected VMs` | Hanya backup yang dipilih |
| **VMs/CTs** | Centang `100` (Docker-Server) | LXC Nextcloud + Docker + CrowdSec |
| **Mode** | `Snapshot` | Backup live tanpa mematikan LXC |
| **Compression** | `ZSTD (fast and good)` | Kompresi cepat dengan rasio tinggi |

### 2.2 Retention Policy (Pencegahan Disk Penuh)

Pindah ke tab **Retention** sebelum menyimpan:

| Parameter | Nilai | Arti |
|---|---|---|
| **Keep Last** | `3` | Simpan 3 backup terakhir (3 hari) |

> [!tip]
> Dengan retensi 3 hari, Proxmox otomatis menghapus backup tertua saat backup keempat dibuat. SSD tidak akan penuh karena file backup tidak terus-menerus menumpuk.

Klik **Create**. Jadwal aktif mulai malam ini.

### 2.3 Verifikasi Backup Berjalan

Keesokan harinya, cek di Web UI:

1. Klik LXC `100` → menu **Backup**.
2. Pastikan ada file baru dengan tanggal kemarin dan ukuran yang masuk akal (biasanya 2–5 GB untuk LXC 50 GB yang terkompresi).

---

## 3. Prosedur Restore dari Backup

Jika LXC rusak, data corrupt, atau aplikasi tidak bisa diperbaiki:

1. Klik LXC `100` → menu **Backup**.
2. Pilih file backup berdasarkan tanggal yang diinginkan (pilih tanggal sebelum kejadian).
3. Klik **Restore**.
4. Proxmox akan menimpa seluruh LXC dengan kondisi persis saat backup dibuat.

> [!warning]
> Restore akan **menimpa** LXC yang ada. Jika ada data baru setelah tanggal backup, data tersebut akan hilang. Untuk keamanan, lakukan backup manual sebelum operasi berisiko: **LXC `100` → Backup → Backup now**.

---

## 4. Manual Archive ke Media Eksternal (Lapis 2)

File backup Proxmox tersimpan di `/var/lib/vz/dump/` di host Proxmox. Salin secara berkala ke media eksternal untuk redundansi.

### 4.1 Lokasi File Backup

Via **Shell node Proxmox**:

```bash
ls -lah /var/lib/vz/dump/
```

File bernama: `vzdump-lxc-100-2026_04_24-02_00_00.tar.zst`

### 4.2 Transfer ke HDD Eksternal / TrueNAS

```bash
# Mount HDD eksternal (asumsi sudah terdeteksi sebagai /dev/sdb1)
mkdir -p /mnt/backup-hdd
mount /dev/sdb1 /mnt/backup-hdd

# Salin file backup terbaru
cp /var/lib/vz/dump/vzdump-lxc-100-*.tar.zst /mnt/backup-hdd/

# Unmount
umount /mnt/backup-hdd
```

> [!info]
> Untuk otomatisasi Lapis 2, pertimbangkan Proxmox Backup Server (PBS) atau NFS mount ke TrueNAS. Ini akan dibahas di fase infrastruktur storage lanjutan.

---

## 5. Ekspansi Disk LXC (On-the-fly)

Jika ruang penyimpanan habis — misalnya foto/video di Nextcloud memenuhi disk — tambahkan kapasitas tanpa mematikan LXC dan tanpa kehilangan data.

### 5.1 Proses Resize via Web UI

1. Klik LXC `100` → **Resources**.
2. Klik **Root Disk** (misal: `local-lvm:vm-100-disk-0`, size `50G`).
3. Klik **Volume Action** → **Resize**.
4. Masukkan **Size Increment (GB)**. Contoh: `20` (menjadi total 70 GB).
5. Klik **Resize disk**.

### 5.2 Verifikasi di Dalam LXC

```bash
df -h
```

Output akan menunjukkan filesystem `/` sudah bertambah ukurannya.

> [!tip]
> Linux modern dengan ext4/xfs secara otomatis mengekspansi filesystem setelah virtual disk diperbesar. Tidak perlu `fdisk`, `resize2fs`, atau restart LXC. Fitur ini adalah keunggulan LXC dibanding VM penuh.

---

## 6. Cheat Sheet Operasional Harian

| Tugas | Perintah / Lokasi |
|---|---|
| Cek status container | `sudo docker ps` |
| Cek log Nextcloud real-time | `sudo docker logs -f nextcloud-app-1` |
| Cek log CrowdSec | `sudo tail -f /var/log/crowdsec.log` |
| Restart stack | `cd /opt/nextcloud && sudo docker compose restart` |
| Update image & redeploy | `sudo docker compose pull && sudo docker compose up -d` |
| Cek ruang disk LXC | `df -h` |
| Cek backup otomatis | Proxmox UI → LXC `100` → **Backup** |
| Backup manual sebelum update | Proxmox UI → LXC `100` → **Backup** → **Backup now** |
| Resize disk | Proxmox UI → LXC `100` → **Resources** → **Resize** |

---

## 7. Checklist Sebelum Major Update

Sebelum melakukan upgrade besar (Proxmox kernel, Docker major version, Nextcloud major version):

- [ ] Jalankan **Backup now** manual via Web UI Proxmox
- [ ] Verifikasi file backup tercipta di LXC `100` → **Backup**
- [ ] Screenshot atau catat versi saat ini (`sudo docker ps`, `sudo lynis --version`)
- [ ] Siapkan waktu jendela maintenance (minimal 30 menit)
- [ ] Pastikan ada akses Console Proxmox (darurat jika SSH gagal)

> [!warning]
> Jangan pernah update Proxmox kernel atau upgrade Docker tanpa backup. Rollback dari kehancuran tanpa backup berarti mengulang dari nol — termasuk setup Nextcloud, konfigurasi CrowdSec, dan data pengguna.

---

> [!info]
> Seluruh 5 dokumen homelab telah lengkap. Arsitektur Anda sekarang memiliki:
> - **Virtualisasi:** Proxmox + LXC (Dokumen 01)
> - **Aplikasi:** Nextcloud + MariaDB via Docker IaC (Dokumen 02)
> - **Jaringan:** Cloudflare Tunnel Zero Trust (Dokumen 03)
> - **Keamanan:** Lynis + Trivy + CrowdSec + Cloudflare WAF (Dokumen 04)
> - **Kelangsungan Hidup:** Backup 3-2-1 + Resize on-the-fly (Dokumen 05)