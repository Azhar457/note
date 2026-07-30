---
title: Firmware Reverse Engineering Learning Roadmap — From PCB Dumping to Emulation
  and Exploitation
tags:
- firmware-re
- hardware-hacking
- reverse-engineering
- binwalk
- ghidra
- roadmap
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Perangkat IoT, router, dan sistem tertanam (*embedded systems*) sering kali menjadi titik masuk terlemah dalam jaringan perusahaan karena firmware yang jarang diperbarui. Catatan ini merancang peta jalan belajar terstruktur dari ekstraksi perangkat keras fisik hingga emulasi kode biner, sebagai pasangan praktis dari berkas teoritis [[firmware-reverse-engineering-deepdive]].

## Daftar Isi

1. [Kurikulum Belajar 4 Fase](#1-kurikulum-belajar-4-fase)
2. [Fase 1: Interaksi Fisik Perangkat Keras & Akuisisi Firmware (Dumping)](#2-fase-1-interaksi-fisik-perangkat-keras--akuisisi-firmware-dumping)
3. [Fase 2: Dekompresi & Ekstraksi File System (Unpacking)](#3-fase-2-dekompresi--ekstraksi-file-system-unpacking)
4. [Fase 3: Analisis Kode Statis & Emulasi Dinamis (Ghidra & QEMU)](#4-fase-3-analisis-kode-statis--emulasi-dinamis-ghidra--qemu)
5. [Fase 4: Eksploitasi & Repackaging Firmware](#5-fase-4-eksploitasi--repackaging-firmware)
6. [Kumpulan Soal Latihan & Solusi](#6-kumpulan-soal-latihan--solusi)
7. [Koneksi ke Vault](#7-koneksi-ke-vault)

---

## 1. Kurikulum Belajar 4 Fase

Peta jalan belajar ini menuntun Anda dari sirkuit fisik hingga penemuan kerentanan biner:

```
[Fase 1: Hardware Dump] ──> [Fase 2: Unpacking] ──> [Fase 3: Static & Emulation] ──> [Fase 4: Exploitation]
- UART / JTAG Pinout        - Analisis Header (File)    - Ghidra (ARM/MIPS RE)       - Buffer Overflow IoT
- SPI Flash desoldering     - binwalk extraction        - QEMU User/System Emulation - Backdoor Injection
- Bus Pirate / CH341A       - SquashFS filesystem mount - Firmadyne analysis         - firmware repackaging
```

---

## 2. Fase 1: Interaksi Fisik Perangkat Keras & Akuisisi Firmware (Dumping)

Sebelum menganalisis kode biner, Anda harus mengekstraknya dari memori fisik chip perangkat:

- **UART (Universal Asynchronous Receiver-Transmitter)**: Antarmuka serial 4-pin (TX, RX, VCC, GND) yang sering memberikan akses shell konsol root langsung saat boot. Gunakan multimeter untuk mengidentifikasi GND dan TX sebelum menyalakan perangkat.
- **JTAG (Joint Test Action Group)**: Antarmuka debugging hardware yang memungkinkan interupsi CPU, pembacaan memori register, dan dumping memori internal chip secara langsung.
- **Dumping via SPI Flash**: Jika port debug terkunci, Anda harus melakukan desoldering chip memori (biasanya EEPROM/SPI Flash SOIC-8) dan membacanya menggunakan perangkat programmer eksternal seperti **CH341A USB Programmer** atau **Bus Pirate**.

---

## 3. Fase 2: Dekompresi & Ekstraksi File System (Unpacking)

Setelah mendapatkan berkas biner mentah (`firmware.bin`), langkah berikutnya adalah membongkar strukturnya:

### 3.1 Deteksi Struktur dengan `binwalk`
`binwalk` memindai berkas biner mentah berdasarkan tanda tangan (*signatures*) file terkompresi yang dikenal:
```bash
# Analisis tanda tangan biner
binwalk firmware.bin

# Ekstraksi otomatis seluruh file system yang ditemukan (seperti SquashFS atau JFFS2)
binwalk -e firmware.bin
```

### 3.2 Ekstraksi Manual Menggunakan `dd`
Jika `binwalk` gagal karena offset non-standar, gunakan perintah `dd` untuk memotong file secara manual:
```bash
# Potong file mulai dari offset 0x120000 sepanjang 5MB
dd if=firmware.bin of=filesystem.squashfs bs=1 skip=1179648 count=5242880
```

---

## 4. Fase 3: Analisis Kode Statis & Emulasi Dinamis (Ghidra & QEMU)

### 4.1 Reverse Engineering Statis dengan Ghidra
1. Muat biner sistem yang diekstrak (misal: daemon server web router `/usr/sbin/httpd` berkode MIPS atau ARM) ke dalam **Ghidra**.
2. Analisis fungsi untuk mencari kerentanan klasik seperti panggilan sistem tidak aman `system()` yang menerima input parameter tidak disanitasi.

### 4.2 Emulasi Dinamis Menggunakan QEMU
Jika perangkat keras fisik tidak tersedia, lakukan emulasi biner menggunakan QEMU:
```bash
# Jalankan biner MIPS menggunakan QEMU User Space Emulation dengan chroot
cp $(which qemu-mips-static) ./squashfs-root/
sudo chroot ./squashfs-root ./qemu-mips-static ./usr/sbin/httpd
```
*Note*: Untuk emulasi jaringan penuh, gunakan framework **Firmadyne** yang memuat kernel sistem operasi lengkap di atas emulasi QEMU System.

---

## 5. Fase 4: Eksploitasi & Repackaging Firmware

### 5.1 Eksploitasi Kerentanan IoT
Sebagian besar kerentanan pada firmware IoT berupa:
- Kredensial statis tersembunyi (*backdoor accounts* di `/etc/shadow` atau `/etc/passwd`).
- Buffer overflow pada fungsi parsing input HTTP server router (karena ketiadaan proteksi ASLR/Stack Canaries pada arsitektur sistem tertanam lama).

### 5.2 Repackaging Firmware
Setelah memodifikasi file system (misalnya menyisipkan skrip reverse shell pada skrip startup `/etc/init.d/rcS`), kemas kembali biner untuk di-flash ke perangkat:
```bash
# Kemas ulang folder root filesystem menjadi SquashFS
mksquashfs squashfs-root/ modified_filesystem.bin -comp xz

# Gabungkan kembali header bootloader asli dengan filesystem baru menggunakan binwalk/firmware-mod-kit
```

---

## 6. Kumpulan Soal Latihan & Solusi

### Soal 1
Mengapa `binwalk` terkadang tidak dapat mendeteksi file system di dalam berkas dump biner firmware? Bagaimana langkah penyelesaiannya?

**Solusi**
Ada beberapa kemungkinan penyebab:
1. **Enkripsi Firmware**: Penyerang/vendor mengenkripsi file biner untuk melindungi kekayaan intelektual.
2. **Kompresi Non-Standar**: Penggunaan kompresi modifikasi yang tanda tangannya tidak terdaftar di database biner `binwalk`.
3. **Obfuscation**: Pengacakan byte header (seperti XOR masking).

Langkah Penyelesaian:
- Lakukan reverse engineering statis pada file biner loader bootloader (seperti U-Boot) yang bertugas mendekripsi firmware di memori saat booting.
- Gunakan teknik *hardware debugging* (JTAG) untuk menghentikan proses boot setelah memori didekripsi, lalu dump isi memori RAM fisik langsung ke komputer eksternal (*RAM dumping*).

---

## 7. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[firmware-reverse-engineering-deepdive]] | Dasar teori enkripsi firmware, analisis arsitektur chip, dan analisis dinamis. |
| [[hardware-hacking-re]] | Protokol fisik hardware (UART, JTAG, SPI) dan penggunaan osiloskop/logic analyzer. |
| [[exploit-development]] | Teori penulisan exploit paylod untuk CPU MIPS/ARM di router IoT. |
