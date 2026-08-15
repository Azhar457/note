---
title: "Raspberry Pi 5 NVMe Boot — Troubleshooting dari USB ke NVMe SSD"
tags: [iot, raspberry-pi, nvme, embedded, hardware, bootloader, troubleshooting, storage]
aliases: [Raspberry Pi NVMe Boot, RPi 5 NVMe Setup, RPi NVMe Troubleshooting]
status: pending
created: 2026-08-15
updated: 2026-08-15
cssclasses: [wide-table, callout]
---

> [!abstract]
> Panduan praktis troubleshooting Raspberry Pi 5: boot dari flashdrive USB yang stuck di inisialisasi GPU V3D, NVMe SSD yang tidak terdeteksi, NVMe corrupt yang menyebabkan crash-loop, urutan boot EEPROM (`BOOT_ORDER`), format ulang total, hingga migrasi penuh ke SSD NVMe menggunakan SD Card Copier. Semua perintah diverifikasi terhadap dokumentasi resmi Raspberry Pi. Vault sudah memiliki [[iot-protocols-mqtt-coap-lwm2m]] (protokol komunikasi IoT) — catatan ini melengkapi dari sisi hardware storage dan boot-level SBC.

# 🥧 Raspberry Pi 5 NVMe Boot — Panduan Troubleshooting

## Daftar Isi
1. [[#1. Konteks dan Arsitektur Boot Raspberry Pi 5]]
2. [[#2. Gejala: Boot Stuck di Driver GPU V3D]]
3. [[#3. NVMe Tidak Terdeteksi — PCIe Bus]]
4. [[#4. NVMe Corrupt Menyebabkan Crash-Loop]]
5. [[#5. Urutan Boot EEPROM — BOOT_ORDER]]
6. [[#6. Format Ulang Total NVMe dari Terminal]]
7. [[#7. SD Card Copier — Migrasi OS ke NVMe]]
8. [[#8. Verifikasi Akhir dan Uji Boot dari NVMe]]
9. [[#9. Matriks Perbandingan Media Boot]]
10. [[#10. Tabel Kode Boot Mode dan Nilai BOOT_ORDER]]
11. [[#11. Referensi]]

## 1. Konteks dan Arsitektur Boot Raspberry Pi 5

Raspberry Pi 5 (BCM2712) menggunakan bootloader yang tersimpan di EEPROM on-board. Berbeda dengan model lama (Pi 1-3) yang memakai `bootcode.bin` dari SD, Pi 4/5 memuat bootloader langsung dari EEPROM, kemudian mencoba berbagai **boot mode** sesuai urutan yang didefinisikan di `BOOT_ORDER`.

```
┌─────────────────────────────────────────────────────────┐
│                 Raspberry Pi 5 Boot Flow                │
├─────────────────────────────────────────────────────────┤
│  1. Boot ROM (SoC) → load bootloader dari EEPROM        │
│  2. Bootloader baca BOOT_ORDER (kanan→kiri, LSB dulu)   │
│  3. Coba tiap boot mode sesuai urutan:                  │
│       1 = SD Card       4 = USB Mass Storage            │
│       6 = NVMe (PCIe)   7 = HTTP/Network Install        │
│  4. Mode pertama yang sukses → load kernel → OS         │
└─────────────────────────────────────────────────────────┘
```

Siklus boot ini yang menjadi inti hampir semua masalah pada raw chat: ketika NVMe corrupt dipasang di slot PCIe, bootloader mencoba membacanya **sebelum** USB (karena urutan `6` mendahului `4`), lalu hang menunggu respons bus PCIe.

## 2. Gejala: Boot Stuck di Driver GPU V3D

**Gejala:** Flashdrive USB terdeteksi (`USB Mass Storage device detected` / `Attached SCSI removable disk`), tapi booting stuck/hang di baris terakhir:

```
watchdog: sync_state() pending due to 100200000.v3d
```

`100200000.v3d` adalah modul GPU Broadcom V3D — umum pada Raspberry Pi / SBC ARM.

### Penyebab dan Solusi

| # | Langkah | Detail |
|---|---------|--------|
| 1 | Pindahkan port USB | Colok ke port **USB 2.0** (hitam). Inisialisasi USB 3.0 pada sebagian image OS sering hang/deferred probe saat boot. |
| 2 | Periksa catu daya | Pastikan adaptor sesuai spesifikasi resmi (**5V 3A / 27W** untuk Pi 5). Under-voltage sering membuat boot terhenti tepat saat chip grafis V3D diaktifkan. |
| 3 | Format & flash ulang image | File sistem di flashdrive bisa korup, atau image tidak sesuai arsitektur (ARM64 vs x86_64). Flash ulang pakai **BalenaEtcher** atau **Raspberry Pi Imager** (hindari format manual tanpa bootloader sesuai). |
| 4 | Nonaktifkan akselerasi GPU | Untuk custom Linux image, tambahkan `nomodeset` pada boot parameters (`cmdline.txt` / GRUB) untuk melewati pemuatan driver V3D saat startup. |

## 3. NVMe Tidak Terdeteksi — PCIe Bus

**Gejala:** `lsblk` hanya menampilkan flashdrive (`sda`, 14.6G) — NVMe (`/dev/nvme0n1`) tidak muncul sama sekali.

### Penyebab

Secara bawaan, interface PCIe pada Raspberry Pi 5 **tidak aktif atau dibatasi**. Perlu diaktifkan via config + bootloader.

### Langkah Perbaikan

**1. Aktifkan PCIe di config.txt:**

```bash
sudo nano /boot/firmware/config.txt
```

Tambahkan di bagian paling bawah:

```text
dtparam=nvme
```

> [!note] `dtparam=nvme` adalah alias resmi dari `dtparam=pciex1` (dokumentasi Raspberry Pi). Untuk HAT NVMe gen 3 bisa juga `dtparam=pciex1_gen=3`, tapi **Pi 5 tidak certified untuk Gen 3** — default Gen 2 (5 GT/s) lebih stabil.

Simpan (Ctrl+O, Enter, Ctrl+X) lalu reboot:

```bash
sudo reboot
```

**2. Periksa koneksi fisik kabel ribbon/HAT:**

- Kabel ribbon PCIe harus terpasang sangat rapat, lurus, latch terkunci di **kedua sisi** (Pi dan M.2 board).
- Perhatikan arah pin kontak kawat pada socket.

**3. Cek level hardware setelah reboot:**

```bash
lspci
```

- Jika muncul baris `Non-Volatile memory controller` → hardware terbaca, jalankan `lsblk` untuk melihat `/dev/nvme0n1`.
- Jika `lspci` kosong/tidak menampilkan NVMe → masalah di kabel fleksibel PCIe atau power delivery ke NVMe HAT.

> [!note] HAT+ compliant device **auto-detected** oleh bootloader — tidak perlu `PCIE_PROBE=1`. Setting itu hanya untuk custom PCIe expansion yang tidak mendukung HAT+ spec.

## 4. NVMe Corrupt Menyebabkan Crash-Loop

**Gejala:** Saat NVMe corrupt dipasang, Raspberry Pi gagal booting total (stuck/hang), meskipun booting dari USB.

**Mengapa:** Ketika kernel Linux membaca jalur PCIe saat boot, jika controller SSD corrupt/short, sistem menunggu respon dari bus PCIe secara **infinite wait** atau kernel panic — tidak bisa masuk ke OS USB.

### Langkah Format & Perbaikan NVMe Corrupt

**1. Cabut NVMe & nyalakan dari USB dulu:**

```bash
# Lepas SSD NVMe dari board/HAT
# Nyalakan Raspberry Pi dari flashdrive USB sampai masuk OS/desktop dengan lancar
```

**2. Gunakan enclosure NVMe-to-USB (rekomendasi utama):**

Masukkan SSD ke enclosure USB, colokkan setelah OS berjalan (hot-plug). Cara ini aman karena tidak memblokir proses boot di awal.

> [!warning] Hot-plugging langsung ke slot PCIe/HAT saat Pi menyala **sangat tidak disarankan** — risiko short circuit pada pin daya PCIe, merusak hardware.

**3. Reset/wipe total NVMe lewat terminal** (detail di Section 6).

## 5. Urutan Boot EEPROM — BOOT_ORDER

### Masalah: "Kalau NVMe corrupt dipasang, tetap boot ke NVMe yang corrupt"

**Akar masalah:** Nilai `BOOT_ORDER` di foto layar = `0xf461`. Karena dibaca **kanan ke kiri** (LSB dulu):

| Nibble | Boot Mode |
|--------|-----------|
| `1` | SD Card |
| `6` | **NVMe** |
| `4` | USB Mass Storage |

Bootloader membaca `6` sebelum `4` — jadi saat NVMe dicolok, sistem **dipaksa membukanya dulu** sebelum menyentuh USB. NVMe corrupt → hang.

### Solusi: Ubah Urutan Boot

Edit EEPROM config:

```bash
sudo rpi-eeprom-config --edit
```

Ubah `BOOT_ORDER` agar USB dibaca sebelum NVMe:

```text
BOOT_ORDER=0xf641
```

Penjelasan `0xf641` (baca kanan→kiri):

| Urutan | Kode | Makna |
|--------|------|-------|
| 1 | `1` | Cek SD Card dulu |
| 2 | `4` | Jika SD kosong, prioritaskan boot dari USB flashdrive |
| 3 | `6` | NVMe baru dibaca setelah USB |
| 4 | `f` | RESTART (ulang dari awal) |

Simpan (Ctrl+O, Enter, Ctrl+X), pasang NVMe, lalu:

```bash
sudo reboot
```

Sistem masuk OS dari USB, dan NVMe corrupt bisa dideteksi aman via `lsblk` untuk diformat ulang.

## 6. Format Ulang Total NVMe dari Terminal

Proses wipe total menghapus seluruh tabel partisi yang bermasalah dan membuat tabel partisi baru.

### 1. Identifikasi nama drive

```bash
lsblk
```

Cari drive NVMe — biasanya `nvme0n1`. **Pastikan tidak memilih `sda`** (itu USB OS yang sedang dipakai).

### 2. Unmount seluruh partisi NVMe

```bash
sudo umount /dev/nvme0n1p* 2>/dev/null
```

### 3. Wipe total (hapus tabel partisi & data corrupt)

```bash
sudo wipefs --all --force /dev/nvme0n1
sudo dd if=/dev/zero of=/dev/nvme0n1 bs=1M count=100 status=progress
```

`wipefs` membersihkan signature filesystem lama; `dd` menulis ulang header untuk membersihkan struktur corrupt.

### 4. Buat tabel partisi baru (GPT) & format

```bash
sudo parted /dev/nvme0n1 mklabel gpt
sudo parted -a optimal /dev/nvme0n1 mkpart primary ext4 0% 100%
sudo mkfs.ext4 -F /dev/nvme0n1p1
```

### 5. Verifikasi hasil

```bash
lsblk
```

NVMe muncul sebagai `/dev/nvme0n1` dengan satu partisi bersih `/dev/nvme0n1p1`.

> [!warning] Pesan `You may need to update /etc/fstab` dari `parted` hanyalah peringatan umum Linux. Karena NVMe akan di-overwrite total oleh SD Card Copier, **tidak perlu edit `/etc/fstab` manual**.

## 7. SD Card Copier — Migrasi OS ke NVMe

Setelah NVMe bersih, buka **SD Card Copier** dari menu GUI Raspberry Pi.

### Pengaturan yang benar

| Field | Nilai |
|-------|-------|
| Copy From Device | flashdrive (`/dev/sda`, mis. `hp v245o`) |
| Copy To Device | NVMe (`/dev/nvme0n1`, mis. `BC901 NVMe SK hynix 256GB`) |
| New Partition UUIDs | **WAJIB CENTANG** `[x]` |

### Kenapa "New Partition UUIDs" wajib dicentang?

Memicu SD Card Copier untuk **menduplikat identitas (UUID)** dari flashdrive ke NVMe. Jika kedua drive terpasang bersamaan dengan UUID identik, sistem bingung saat booting (**UUID collision**). Dengan opsi ini, SD Card Copier otomatis:

1. Membuatkan UUID baru untuk NVMe
2. Memperbarui `/cmdline.txt` dan `/etc/fstab` di dalam NVMe secara otomatis

### Tentang `/etc/fstab`

Bisa **di-ignore total**. Peringatan dari `parted` hanyalah notifikasi umum saat menambah partisi di OS yang aktif. SD Card Copier yang akan menangani semuanya.

Klik **Start**, tunggu proses copying selesai (beberapa menit).

## 8. Verifikasi Akhir dan Uji Boot dari NVMe

### Verifikasi partisi NVMe

```bash
lsblk
```

Struktur NVMe (`nvme0n1`) harus identik dengan USB (`sda`): **dua partisi**:

| Partisi | Mount point | Filesystem |
|---------|-------------|------------|
| `nvme0n1p1` | `/boot/firmware` | FAT |
| `nvme0n1p2` | `/` | EXT4 |

### Periksa urutan bootloader EEPROM

```bash
vcgencmd bootloader_config
```

Pastikan baris `BOOT_ORDER` memiliki angka `6` (NVMe) dan `4` (USB). Jika `0xf641` atau `0xf461` — NVMe sudah terdaftar.

### Uji coba booting dari NVMe

```bash
sudo poweroff
```

1. Tunggu lampu LED di board berhenti berkedip.
2. Cabut flashdrive USB (`sda`) dari port.
3. Nyalakan kembali Raspberry Pi.

Sistem akan booting langsung dari SSD NVMe dengan kecepatan jauh lebih tinggi dibanding flashdrive USB.

> [!tip] Setelah migrasi sukses dan stabil, untuk booting **langsung dari NVMe** (tanpa USB), set `BOOT_ORDER=0xf416` — urutan resmi Raspberry Pi untuk boot dari PCIe storage. `0xf641` tetap aman dipakai selama flashdrive masih dicolok.

## 9. Matriks Perbandingan Media Boot

| Kriteria | MicroSD | Flashdrive USB | NVMe SSD (PCIe) |
|----------|---------|----------------|-----------------|
| Kecepatan baca | ~50-100 MB/s | ~100-400 MB/s | **~700-1400 MB/s** |
| Kecepatan tulis | Lambat | Sedang | **Cepat** |
| Boot mode code | `1` | `4` | `6` |
| Boot order resmi | `0xf41` | `0xf41` (USB setelah SD) | `0xf416` |
| Daya tahan (write cycle) | Rendah | Sedang | **Tinggi** |
| Ukuran maksimum praktis | 1 TB | 1 TB | 2 TB+ |
| Risiko korupsi | Tinggi (umur pendek) | Sedang | Rendah |
| Boot dari default Pi 5 | ✅ | ✅ (aktifkan) | ❌ (perlu config) |

## 10. Tabel Kode Boot Mode dan Nilai BOOT_ORDER

### Boot mode codes (nibble dalam BOOT_ORDER)

| Kode | Boot Mode | Dukungan |
|------|-----------|----------|
| `0x1` | SD Card | Semua model |
| `0x2` | Network (TFTP) | Semua (butuh Ethernet) |
| `0x4` | USB Mass Storage | Pi 4/5, CM4/CM5 |
| `0x6` | NVMe (PCIe) | CM4, CM5, Pi 5, Pi 500 |
| `0x7` | HTTP/Network Install | Pi 4/5 (bootloader >= 10 Mar 2022) |
| `0xf` | RESTART (loop) | — |

### Nilai BOOT_ORDER yang umum

| Nilai | Urutan (kanan→kiri) | Keterangan |
|-------|---------------------|------------|
| `0xf41` | SD → USB → RESTART | **Default** jika BOOT_ORDER kosong |
| `0xf14` | USB → SD → RESTART | USB first |
| `0xf46` | NVMe → USB → RESTART | NVMe first (dokumentasi resmi) |
| `0xf416` | SD → USB → NVMe → RESTART | Boot PCIe storage (resmi) |
| `0xf641` | SD → USB → NVMe → RESTART | Variasi yang dipakai di troubleshooting ini |
| `0xf461` | SD → NVMe → USB → RESTART | ⚠️ NVMe sebelum USB — penyebab crash-loop |

> [!warning] `BOOT_ORDER` dibaca **kanan ke kiri** (LSB dulu) — `0xf461` berarti urutan coba: `1` (SD) → `6` (NVMe) → `4` (USB) → `f` (loop). NVMe corrupt akan di-probe sebelum USB tercapai → hang.

## 11. Referensi

1. Raspberry Pi Documentation — Raspberry Pi computer hardware: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html
2. Raspberry Pi Documentation — BOOT_ORDER configuration: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#BOOT_ORDER
3. Raspberry Pi Documentation — NVMe SSD boot: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#nvme-ssd-boot
4. Raspberry Pi Documentation — Boot from PCIe: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#boot-from-pcie
5. Raspberry Pi Documentation — EEPROM bootflow: https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#eeprom-boot-flow
6. Raspberry Pi Documentation — M.2 HAT+: https://www.raspberrypi.com/documentation/accessories/m2-hat-plus.html
7. Raspberry Pi Documentation — config.txt: https://www.raspberrypi.com/documentation/computers/config_txt.html
8. Raspberry Pi bootloader release notes: https://github.com/raspberrypi/rpi-eeprom/releases

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[iot-protocols-mqtt-coap-lwm2m]] | Protokol komunikasi IoT — melengkapi dari sisi hardware storage SBC |
| [[robotics-autonomous-systems]] | Sistem robotik sering memakai SBC + storage eksternal untuk logging data |
| [[ai-comm-protocol-deepdive]] | Komunikasi AI di edge device — fondasi hardware yang sama |
| [[homelab-proxmox-architecture]] | Homelab juga memakai storage NVMe — prinsip boot/partition serupa |
| [[networking-fundamentals-tcpip-bgp]] | Jaringan SBC — konteks deployment IoT |
