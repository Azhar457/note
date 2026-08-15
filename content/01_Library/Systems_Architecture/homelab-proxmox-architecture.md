---
title: 'Homelab Proxmox Architecture: ZFS, Network Segmentation, dan Backup Strategy'
tags:
- systems-architecture
- homelab
- proxmox
- virtualization
- networking
- storage
aliases:
- Homelab Proxmox Architecture
- Proxmox Architecture
- ZFS Homelab
created: 2026-07-21
updated: 2026-07-21
status: pending
cssclasses:
  - wide-table
  - callout
  - code-wrap
---

# Homelab Proxmox Architecture: ZFS, Network Segmentation, dan Backup Strategy

> [!tip] **Proxmox Virtual Environment (PVE)** adalah platform virtualisasi enterprise sumber terbuka yang sangat populer untuk infrastruktur Homelab. Dokumentasi ini mendefinisikan desain arsitektur homelab terpadu, mencakup konfigurasi sistem penyimpanan file **ZFS**, segmentasi jaringan virtual (**VLANs**), serta strategi rotasi cadangan (**Backup Rotation**) menggunakan Proxmox Backup Server (PBS).

---

## 1. Topologi Fisik & Logis Homelab

Arsitektur homelab dirancang untuk memisahkan beban kerja publik (seperti reverse proxy WAF) dari server internal sensitif (seperti database RAG & Obsidian Vault sync server).

```
                             [ Internet ]
                                  │
                                  ▼
                        [ Router (OPNsense) ]
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼ (VLAN 10 - Public/DMZ)                          ▼ (VLAN 20 - Private/LAN)
   [ WAF Proxy ]                                 [ Proxmox VE Host ]
   (LXC / VM Container)                                    │
                                           ┌───────────────┴───────────────┐
                                           ▼ (LXC Container)               ▼ (LXC Container)
                                    [ RAG Database ]               [ Obsidian Vault Server ]
```

*   **PVE Host**: Mesin server fisik utama (misal: Mini PC Intel NUC / Server Rack refurbished) yang menjalankan Proxmox VE.
*   **VLAN 10 (DMZ)**: Menampung kontainer reverse proxy/WAF. Hanya port `80` dan `443` yang dibuka ke internet.
*   **VLAN 20 (Local LAN)**: Lingkungan aman untuk penyimpanan data sensitif. Tidak boleh diakses langsung dari internet tanpa VPN (WireGuard/Tailscale).

---

## 2. Strategi Penyimpanan Data: ZFS Pool Layout

ZFS adalah sistem berkas (filesystem) modern yang menyediakan fitur proteksi integritas data bawaan (*RAID software, snapshotting, self-healing*).

### Desain ZFS Pool Homelab
Untuk efisiensi dan performa maksimal, bagi media penyimpanan menjadi dua pool terpisah:

```
                  ┌────────────────────────────────────────┐
                  │          PROXMOX VE STORAGE            │
                  └───────────┬────────────────┬───────────┘
                              │                │
       [ SSD Pool (zpool-fast) ]              [ HDD Pool (zpool-storage) ]
       - NVMe SSD Mirror (RAID 1)             - SATA HDD RAIDZ1 (3x HDD)
       - Proxmox OS, VM/LXC Disks             - Backup, ISO, Media Files
```

#### A. `zpool-fast` (NVMe Mirror - RAID 1)
*   **Komponen**: 2x 1TB NVMe SSD.
*   **Fungsi**: Menyimpan sistem operasi Proxmox VE, disk root VM, kontainer LXC, dan database aktif (PostgreSQL/SQLite-Vec).
*   **Kelebihan**: Latensi baca/tulis mendekati nol, meminimalkan bottleneck saat evaluasi kueri RAG.

#### B. `zpool-storage` (RAIDZ1 - Setara RAID 5)
*   **Komponen**: 3x 4TB SATA HDD.
*   **Fungsi**: Penyimpanan jangka panjang, snapshot cadangan, berkas ISO, dan direktori Obsidian Vault cadangan.
*   **Formula Kapasitas Efektif**:
    
    $$\text{Kapasitas Efektif} = (N - 1) \times \text{Ukuran HDD Min} = (3 - 1) \times 4\text{ TB} = 8\text{ TB}$$

---

## 3. Segmentasi Jaringan Virtual (Virtual Networking & VLANs)

Proxmox menggunakan bridge virtual (`vmbr0`) untuk menghubungkan mesin virtual ke jaringan fisik. Kita mengaktifkan fitur **VLAN Aware** agar bridge dapat meneruskan tag VLAN dari router.

### Konfigurasi `/etc/network/interfaces` di Proxmox Host:
```text
auto lo
iface lo inet loopback

iface enp3s0 inet manual
# Port Ethernet Fisik yang terhubung ke Switch/Router

auto vmbr0
iface vmbr0 inet static
        address 192.168.1.100/24
        gateway 192.168.1.1
        bridge-ports enp3s0
        bridge-stp off
        bridge-fd 0
        bridge-vlan-aware yes
# Bridge virtual utama, diatur sebagai vlan-aware agar LXC bisa menentukan VLAN tag sendiri
```

Di dalam panel Proxmox GUI:
*   Berikan **VLAN Tag: 10** pada antarmuka jaringan LXC WAF.
*   Berikan **VLAN Tag: 20** pada antarmuka jaringan LXC RAG Database.

---

## 4. Strategi Rotasi Cadangan (Backup Strategy & PBS)

Gunakan metode **3-2-1 Backup Rule** untuk mengamankan data homelab Anda dari kegagalan hardware:
*   **3 Salinan Data**: 1 data produksi aktif + 2 data cadangan.
*   **2 Media Berbeda**: Disimpan di SSD lokal dan server NAS lokal terpisah.
*   **1 Cadangan Off-site**: Cadangan terenkripsi yang diunggah ke cloud (misal: Backblaze B2 / Rclone).

### Integrasi Proxmox Backup Server (PBS)
PBS mendukung deduplikasi data tingkat lanjut (*dirty-bitmap backup*), membuat backup harian hanya memakan waktu hitungan detik karena hanya mengirim perbedaan blok data yang berubah.

#### Jadwal Backup Job (Cron di PVE):
*   **Frekuensi**: Setiap hari pukul 02.00 pagi.
*   **Retention Policy (Pruning)**:
    *   `keep-last`: 7 (Menyimpan 7 cadangan terakhir).
    *   `keep-daily`: 7 (Menyimpan cadangan harian selama 1 minggu).
    *   `keep-weekly`: 4 (Menyimpan cadangan mingguan selama 1 bulan).
    *   `keep-monthly`: 12 (Menyimpan cadangan bulanan selama 1 tahun).

---

## 🔗 Referensi & Catatan Terkait
- WAF architecture deepdive (privat) — Konfigurasi Deploy WAF LXC di VLAN DMZ
- [[linux-performance-debugging-toolkit]] — Pemantauan Beban CPU/RAM Hypervisor Host
- [[obsidian-vault-scaling-playbook]] — Strategi Sinkronisasi File Vault ke Storage Homelab
- [[ebpf-runtime-security-auditing]] — Monitoring Aktivitas Mencurigakan di Virtual Machine

## 6. Deepdive — Hardening Proxmox Host

### 6.1 Attack Surface & Mitigasi

| Vektor | Risiko | Mitigasi |
|--------|--------|----------|
| **Web UI exposed** | Brute force, CVE | Jangan expose 8006 ke internet — VPN saja |
| **SSH root** | Brute force | Key-only auth, disable password, port ubah |
| **LXC/VM escape** | Escape ke host | Patch rutin (pve-qemu-kvm, lxc), seccomp default |
| **ZFS snapshot tamper** | Ransomware destroy backup | PBS immutable repository (retention + verification) |
| **Unprivileged container** | Privilege escalation | Jalankan LXC unprivileged default, map UID |
| **Storage plaintext** | Data theft fisik | ZFS native encryption (aes-256-gcm) |

### 6.2 Proxmox Backup Server — Immutable Backup

```bash
# PBS dengan repository immutable (retention period)
# → bahkan admin/proxmox tidak bisa hapus backup sebelum retention expiry
pbs: backup-ke-pbs (datastore: vault, retention: 7d,14d,30d)

# Verifikasi backup berkala (bukan cuma ada)
# PBS verify-job: cek checksum + test restore
```

### 6.3 ZFS Performance & Integrity Tuning

| Parameter | Nilai | Efek |
|-----------|-------|------|
| `recordsize` | 128K (VM) / 1M (file besar) | Alignment dengan workload |
| `compression` | `lz4` | Kompresi CPU murah, IOPS naik |
| `atime` | `off` | Kurangi write overhead |
| `ashift` | 12 (4K sector) | Alignment SSD/NVMe |
| `sync` | `standard` (default) | Integrity vs performance tradeoff |
| `scrub` | weekly cron | Self-healing aktif |

## 7. Tool Stack

| Tool | Use |
|------|-----|
| **Proxmox VE** | Hypervisor (LXC + KVM) |
| **Proxmox Backup Server** | Backup immutable + dedupe |
| **OPNsense** | Firewall/router (VLAN, VPN) |
| **WireGuard / Tailscale** | Remote access aman |
| **ZFS (zpool, zfs)** | Storage + snapshot + scrub |
| **Prometheus + Grafana** | Monitoring (node_exporter, pve exporter) |

## 8. Referensi

- Proxmox docs — https://pve.proxmox.com/wiki/Main_Page
- PBS docs — https://pbs.proxmox.com/docs/
- ZFS administration — https://openzfs.github.io/openzfs-docs/
- OPNsense — https://docs.opnsense.org/
---

audited
---
