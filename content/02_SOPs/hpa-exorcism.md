---
title: "Hpa Exorcism"
tags:
  - sops
aliases:
  - "hpa-exorcism"
created: "2026-04-23"
updated: "2026-07-01"
status: active
---

<think>
Okay, the user wants me to expand the existing documentation to over 1100 words. Let me check the current content. It's already 937 words. They mentioned adding more code examples, detailed troubleshooting scenarios, and deeper technical explanations.

First, the original content has a structured SOP for a hardware and software exorcism process. I need to add real-life code examples where possible. Maybe include a script that automates some steps with error handling. Also, each phase of the SOP lacks detailed troubleshooting. For instance, if the DCO reset fails, how do you diagnose that? What about HPA unlock errors?

I should break down each phase to explain the underlying concepts. Like, why is DCO reset a prerequisite for HPA? What's the technical reason behind checking ROTA? Need to explain the device hierarchy and why USB-to-SATA adapters are important for isolation.

In the troubleshooting section, I can add common errors and their solutions. For example, if `dd` hangs, it might be due to bad sectors, and `conv=noerror` helps but still, what else can be done? Also, handling drive conflicts where multiple drives are detected.

The theory section needs more depth. Explaining how HPA works on the firmware level, how DCO overlays the physical capacity, and the structure of the MBR. Maybe a diagram in markdown format to show the memory layout.

I also need to elaborate on the importance of booting from a Live USB and not the installed OS. Security aspects here—why it's critical for safety in this procedure. Also, the role of each tool like `hdparm` and `dd` in the process.

Adding more tables for parameters, like detailed descriptions of each command's flags. Maybe a table comparing different USB-to-SATA adapters and their compatibility.

Including more code examples would help. For example, a complete bash script that automates the entire process with user prompts and checks. Also, error handling in the script if the user inputs the wrong drive.

Wait, the user wants the response to start directly with the content, no greetings. Need to make sure the markdown is preserved. Also, check that all code blocks are correctly formatted with syntax highlighting if possible.

Let me structure each section to add the required details without fluff. For example, in the DCO Reset section, add a subsection explaining what DCO is, how it manipulates drive capacity, and why resetting it is crucial. Similarly, for HPA, explain how HPA is hidden and why unlocking it is a critical step.

In troubleshooting, create a list with common issues like "HPA unlock fails after power cycle" and the solution would be to ensure the 'p' parameter was used in the `hdparm` command. Another issue could be "Zero-fill process aborts due to I/O errors" which would involve checking the drive's physical condition and using `badblocks`.

Also, in the estimation time table, add more entries for different SSD sizes and note that SSDs might have faster times due to their architecture. Maybe discuss why HDD takes longer than SSD.

I should also explain the parameters of `dd` in more detail, like `bs=4M` being a balance between speed and memory usage, and `conv=noerror` allowing the process to continue despite errors.

Adding a subsection on security considerations—why Zero-fill is necessary over a normal erase, and how it affects data recovery.

Including step-by-step instructions for creating the Live USB, which the original didn't have. Maybe even a brief on verifying the ISO checksum for authenticity.

Finally, ensure the total word count exceeds 1100, but the expansion should be natural, not forced. Check that all added content is relevant and enhances the technical depth without redundancy.
</think>

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