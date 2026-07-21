---
title: Hpa Exorcism
tags:
- sops
created: '2026-04-23'
updated: '2026-07-01'
status: active
---

# 🔪 SOP — The Safe Exorcist  
> **HPA Unlock › DCO Reset › MBR Wipe › Zero-Fill Total**  

> [!danger] PERINGATAN KRITIS  
- Dokumen ini berisi **prosedur destruktif permanen**. Salah memilih drive = kehilangan data selamanya.  
- Tahan drive target dari komputer utama (gunakan USB-to-SATA adapter).  
- **Jangan jalankan di drive OS utama**. Pastikan boot dari Live USB (tidak dari installed OS).  

---

## ⚙️ Prasyarat & Persiapan  

| Komponen          | Detail                          |  
|--------------------|---------------------------------|  
| **OS**            | SystemRescue Live USB (versi ≥ 12.04) |  
| **Tools wajib**   | `hdparm` `dd` `lsblk` `blockdev` `badblocks` |  
| **Drive target**  | Terhubung via USB-to-SATA (jangan ke SATA motherboard!) |  
| **Verifikasi**    | Pastikan drive target **tidak ter-mount** |  

### Contoh Instalasi Alat di Rocky Linux  
```bash
sudo dnf install hdparm util-linux coreutils e2fsprogs
```

> [!attention]  
> **Jika drive target sudah ter-mount**, perintah `dd` bisa menyebabkan korupsi data bersifat cascading ke drive lain yang terpasang bersama. Gunakan `lsblk` untuk cek semua drive:  
```bash
lsblk
# Contoh output: sdb: target, sda: drive OS
```

---

## ⚙️ Fase 1 — Identifikasi Target & Status  

### 1.1: Deteksi Tipe Drive  

```bash
lsblk -d -o NAME,SIZE,MODEL,ROTA
```

**Legenda Output:**  
- `ROTA=1` = HDD (menggunakan mekanisme disk fisik)  
- `ROTA=0` = SSD/NVMe (tanpa mekanisme geser)  

**Output Contoh:**  
```
NAME   SIZE   MODEL          ROTA
sda    238.5G Samsung SSD 870  0
sdb    1.82T ST2000LM015-2DR  1
```

> ❗ Pastikan `sdb` adalah drive target yang sesuai kebutuhan Anda. Jika tidak yakin, **lebih baik tidak melanjutkan**.

### 1.2: Unmount Drive Target  

```bash
umount /dev/sdX* 2>/dev/null || true
```

> ❗ Pastikan tidak ada partisi (`sdX1`, `sdX2`, etc.) yang masih aktif sebagai mount point. Gunakan `df -h` untuk konfirmasi.

---

## ⚙️ Fase 2 — Reset DCO (Device Configuration Overlay)  

> [!info]  
> **DCO (Device Configuration Overlay)** adalah layer firmware yang **mengurangi kapasitas fisik drive** untuk kontrol vendor (seperti OEM recovery). Reset DCO **hendaklah dilakukan sebelum unlock HPA**, karena DCO bisa **override** HPA jika tidak dibersihkan.

### 2.1: Cek Status DCO  

```bash
hdparm --dco-identify /dev/sdX
```

**Contoh Output (DCO dimanipulasi):**  
```
drive is in DCO mode: enabled sectors = 500105856/976773168
```

> ✅ Jika output menunjukkan angka tidak sama → DCO aktif dan perlu direset.

---

### 2.2: Reset DCO ke Pabrik  

```bash
sudo hdparm --dco-restore /dev/sdX
```

> ❗ **Jika Error (`Input/output error`), ini biasa terjadi pada drive terenkripsi**. Coba:  
> ```bash
> dd if=/dev/zero of=/dev/sdX bs=512 count=1 status=progress
> # Tulis ulang sektor pertama untuk melompati enkripsi
> ```

### 2.3: Paksa Kernel Mereload Konfigurasi  

```bash
sudo blockdev --rereadpt /dev/sdX
```

---

## ⚙️ Fase 3 — Buka Kunci HPA (Hidden Partition Area)  

> [!warning]  
> **HPA (Hidden Partition Area)** adalah area tersembunyi yang tidak dikenali oleh sistem operasi umum. HPA bisa digunakan untuk menampung:  
> - OEM recovery factory image  
> - Malware persisten  
> - Rootkit yang terjebak di sektor akhir  

### 3.1: Cek Status HPA  

```bash
hdparm -N /dev/sdX
```

**Contoh Output (HPA Aktif):**  
```
max sectors = 500105856/976773168, HPA is enabled
```

> ✅ Catat angka kedua (`976773168`) sebagai `native_max`.

---

### 3.2: Buka Kunci HPA  

```bash
sudo hdparm -N p976773168 /dev/sdX
```

> 🔧 **Jika Gagal dengan Error (`hdparm: invalid option`)**:  
> - Pastikan parameter `-N` diikuti dengan opsi `p<angka>`.  
> - Coba tambahkan `-n` untuk non-DOS mode: