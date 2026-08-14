---
title: Kernel Forensics — Memory Analysis of Compromised Systems
tags:
- forensics
- kernel
- memory-analysis
- volatility
- rootkit
- blue-team
created: '2026-07-19'
updated: '2026-07-19'
status: pending
cssclasses:
  - wide-table
  - callout

---

> [!abstract] Ringkasan & Hubungan ke Vault
> Analisis memori tingkat kernel adalah garis pertahanan terakhir dalam mendeteksi *stealth rootkit* dan *kernel-mode malware* yang berjalan dengan hak akses tertinggi (Ring 0). Catatan ini melengkapi pembahasan [[endpoint-detection-playbook]] dengan memberikan panduan praktis analisis forensik memori.

## Daftar Isi

1. [Arsitektur Memori: User Space vs Kernel Space](#1-arsitektur-memori-user-space-vs-kernel-space)
2. [System Call Table Hooking (SSDT & Linux Syscall Table)](#2-system-call-table-hooking-ssdt--linux-syscall-table)
3. [Integritas IDT dan GDT](#3-integritas-idt-dan-gdt)
4. [DKOM (Direct Kernel Object Manipulation)](#4-dkom-direct-kernel-object-manipulation)
5. [Peralatan & Perintah Taktis Volatility 3](#5-peralatan--perintah-taktis-volatility-3)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. Arsitektur Memori: User Space vs Kernel Space

Dalam sistem operasi modern, memori dibagi secara tegas untuk mencegah aplikasi pengguna biasa merusak fungsionalitas sistem inti:

```
┌─────────────────────────────────────────────────────────┐
│              User Space (Ring 3)                        │
│  - Aplikasi Web, Browser, User Processes                │
│  - Akses memori terbatas melalui Virtual Memory         │
└───────────────────────────┬─────────────────────────────┘
                            │  System Call (Interrupt 0x80 / syscall)
                            ▼
┌─────────────────────────────────────────────────────────┐
│              Kernel Space (Ring 0)                      │
│  - OS Kernel, Driver Perangkat Keras                     │
│  - Akses penuh ke seluruh memori fisik & instruksi CPU  │
│  - Komponen Kritis: SSDT, IDT, GDT                      │
└─────────────────────────────────────────────────────────┘
```

Jika *rootkit* berhasil masuk ke dalam **Kernel Space (Ring 0)**, ia dapat memanipulasi informasi apa pun sebelum diserahkan ke *User Space* (misalnya menyembunyikan file, proses, atau koneksi jaringan dari aplikasi antivirus/EDR yang berjalan di Ring 3).

---

## 2. System Call Table Hooking (SSDT & Linux Syscall Table)

Ketika aplikasi di Ring 3 memanggil fungsi seperti membaca file (`ReadFile` / `sys_read`), CPU beralih ke Ring 0 dan menggunakan tabel indeks untuk mencari alamat fungsi kernel yang sesuai.

### 2.1 SSDT Hooking (Windows)
**System Service Descriptor Table (SSDT)** adalah tabel pointer fungsi yang digunakan kernel Windows untuk memetakan nomor panggilan sistem (System Call ID) ke alamat fungsi internal di `ntoskrnl.exe`.

- **Mechanism**: Rootkit mengubah alamat pointer di SSDT untuk mengarah ke kode rootkit terlebih dahulu.
- **Example**: Meng-hook `NtQuerySystemInformation` agar menyaring proses milik penyerang sebelum mengembalikan daftar proses ke Task Manager.

### 2.2 Linux System Call Table Hooking
Pada Linux kernel module (LKM) rootkit, penyerang menulis ulang alamat fungsi di dalam array `sys_call_table`:

```c
// Kode LKM Rootkit sederhana untuk meng-hook sys_write
unsigned long *sys_call_table;
asmlinkage int (*original_write)(unsigned int, const char __user *, size_t);

asmlinkage int hooked_write(unsigned int fd, const char __user *buf, size_t count) {
    // Saring konten sensitif di sini sebelum menulis ke file/terminal
    return original_write(fd, buf, count);
}

// Menyembunyikan proteksi write-protection register WP pada CPU (CR0)
write_cr0(read_cr0() & (~0x10000));
sys_call_table[__NR_write] = (unsigned long)hooked_write;
write_cr0(read_cr0() | 0x10000); // Aktifkan kembali WP
```

---

## 3. Integritas IDT dan GDT

- **IDT (Interrupt Descriptor Table)**: Tabel yang mendefinisikan *Interrupt Service Routines* (ISR) untuk menangani interupsi perangkat keras dan perangkat lunak. Meng-hook IDT memungkinkan rootkit menangkap input keyboard langsung di level kernel sebelum diproses oleh OS.
- **GDT (Global Descriptor Table)**: Mendefinisikan segmen memori dan hak aksesnya (Privilege Ring). Manipulasi GDT dapat digunakan untuk melakukan eskalasi hak akses Ring 3 ke Ring 0 secara langsung.

---

## 4. DKOM (Direct Kernel Object Manipulation)

**DKOM** adalah teknik manipulasi struktur data kernel internal secara dinamis di memori untuk menyembunyikan jejak serangan tanpa merubah kode fungsi (menghindari deteksi berbasis *integrity check*).

### 4.1 Mekanisme Penyembunyian Proses di Windows
Pada Windows, setiap proses diwakili oleh struktur data di kernel bernama `_EPROCESS`. Struktur ini mengandung tautan ganda (*double-linked list*) bernama `ActiveProcessLinks` (`LIST_ENTRY`) yang menghubungkan satu proses dengan proses lainnya.

```
Proses A (_EPROCESS)          Proses B (Malicious)          Proses C (_EPROCESS)
┌──────────────┐              ┌──────────────┐              ┌──────────────┐
│ Flink ───────┼─────────────▶│ Flink ───────┼─────────────▶│ Flink ───────┼───▶ ...
│ Blink ◀──────┼──────────────┼─ Blink ◀─────┼──────────────┼─ Blink ◀─────┼───◀ ...
└──────────────┘              └──────────────┘              └──────────────┘
```

Rootkit dengan teknik DKOM akan mengubah pointer `Flink` dari **Proses A** untuk langsung menunjuk ke **Proses C**, dan pointer `Blink` dari **Proses C** untuk menunjuk ke **Proses A**:

```
Proses A (_EPROCESS)                                        Proses C (_EPROCESS)
┌──────────────┐                                            ┌──────────────┐
│ Flink ───────┼───────────────────────────────────────────▶│ Flink ───────┼───▶ ...
│ Blink ◀──────┼────────────────────────────────────────────┼─ Blink ◀─────┼───◀ ...
└──────────────┘                                            └──────────────┘
                               Proses B (Tersembunyi)
                               ┌──────────────┐
                               │ Flink (Y)    │ (Putus dari rantai)
                               │ Blink (X)    │
                               └──────────────┘
```
**Akibat**: Proses B tetap berjalan di CPU karena penjadwalan CPU (*thread scheduling*) menggunakan rantai data yang berbeda, namun tidak akan muncul di Task Manager, Process Explorer, atau API Ring 3 karena proses tersebut telah dikeluarkan dari rantai `ActiveProcessLinks`.

---

## 5. Peralatan & Perintah Taktis Volatility 3

**Volatility 3** adalah standar industri untuk melakukan analisis forensik memori secara offline terhadap file dump memori (RAM dump).

### 5.1 Perintah Deteksi pada Windows Memory Dump

```bash
# 1. Mendeteksi proses tersembunyi dengan membandingkan daftar API vs daftar scan memory fisik (DKOM)
python3 vol.py -f memory.dmp windows.psscan > psscan.txt
python3 vol.py -f memory.dmp windows.pslist > pslist.txt
# Bandingkan perbedaan output: psscan menampilkan proses yang diputus dari ActiveProcessLinks!

# 2. Mendeteksi SSDT Hooks (mencari pointer SSDT yang mengarah di luar module kernel resmi ntoskrnl.exe)
python3 vol.py -f memory.dmp windows.ssdt

# 3. Enumerasi driver/module kernel yang dimuat (deteksi rootkit driver tak dikenal)
python3 vol.py -f memory.dmp windows.modules

# 4. Mendeteksi driver tersembunyi yang tidak terdaftar di daftar driver resmi
python3 vol.py -f memory.dmp windows.driverscan

# 5. Mencari file yang sedang terbuka dan handles yang mencurigakan
python3 vol.py -f memory.dmp windows.handles --pid <PID>
```

### 5.2 Perintah Deteksi pada Linux Memory Dump

```bash
# 1. Menampilkan daftar proses di Linux dump memori
python3 vol.py -f linux.raw linux.pslist

# 2. Mendeteksi system call table hooking (mencari deviasi pointer sys_call_table)
python3 vol.py -f linux.raw linux.check_syscall

# 3. Enumerasi modul kernel yang dimuat (LKM rootkit detection)
python3 vol.py -f linux.raw linux.lsmod
```

---

## 6. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[endpoint-detection-playbook]] | Strategi deteksi EDR Ring 3 yang dilewati oleh kernel rootkit melalui DKOM/SSDT. |
| [[hardware-hacking-re]] | Ekstraksi firmware dan anatomis low-level memori hardware. |
| [[incident-response-framework]] | Prosedur akuisisi memori RAM secara aman (LiME, FTK Imager) sebelum dilakukan analisis. |
| [[unified-threat-ontology]] | Penjelasan ancaman siber Ring 0 pada tataran Layer 1 & 2 sistem operasi. |
