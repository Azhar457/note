---
title: Hardware Security Deep-Dive — TPM, TEE, Secure Boot, and Intel SGX/ARM TrustZone
tags:
- hardware-security
- tpm
- tee
- secure-boot
- trustzone
- intel-sgx
- cryptography
created: '2026-07-19'
updated: '2026-07-19'
status: operational
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Keamanan tingkat perangkat lunak (OS & hypervisor) tidak akan berarti apa-apa tanpa jangkar keamanan berbasis perangkat keras (*hardware root of trust*). Catatan ini membedah arsitektur keamanan silicon (TPM, TEE, Secure Boot) dan mekanisme perlindungan memori terisolasi tingkat chip, melengkapi [[hierarchy-endpoint-security]] dan [[kernel-forensics]].

## Daftar Isi

1. [UEFI Secure Boot & Measured Boot](#1-uefi-secure-boot--measured-boot)
2. [Arsitektur TPM 2.0 (Trusted Platform Module)](#2-arsitektur-tpm-20-trusted-platform-module)
3. [Trusted Execution Environments (TEE)](#3-trusted-execution-environments-tee)
4. [Mekanisme Enklave: Intel SGX & ARM TrustZone](#4-mekanisme-enklave-intel-sgx--arm-trustzone)
5. [Vektor Serangan & Eksploitasi Perangkat Keras](#5-vektor-serangan--eksploitasi-perangkat-keras)
6. [Koneksi ke Vault](#6-koneksi-ke-vault)

---

## 1. UEFI Secure Boot & Measured Boot

Rantai proses booting yang aman (*Chain of Trust*) sangat krusial untuk mencegah malware tingkat rendah (*bootkit/rootkit*) dimuat sebelum sistem operasi berjalan.

```
┌──────────────┐      Tandatangan diverifikasi      ┌──────────────┐      Tandatangan diverifikasi      ┌──────────────┐
│  ROM Boot    │ ─────────────────────────────────▶│  Bootloader  │ ─────────────────────────────────▶│  OS Kernel   │
│  (Hardware)  │      menggunakan Kunci PK/KEK     │  (Shim/GRUB) │      menggunakan Kunci db/dbx    │  (ntoskrnl)  │
└──────────────┘                                    └──────────────┘                                    └──────────────┘
```

### 1.1 Secure Boot Key Database
UEFI Secure Boot mengandalkan kumpulan sertifikat kunci kriptografi yang disimpan di dalam memori NVRAM non-volatile motherboard:
- **Platform Key (PK)**: Menetapkan kepemilikan platform (biasanya dipasang oleh OEM).
- **Key Exchange Key (KEK)**: Kunci untuk memperbarui database db dan dbx (sertifikat OS seperti Microsoft/RedHat).
- **Signature Database (db)**: Daftar sertifikat dan hash biner yang diizinkan untuk dieksekusi selama boot.
- **Forbidden Signature Database (dbx)**: Blacklist sertifikat/hash biner yang terbukti rentan atau disalahgunakan (mencegah *replay attacks* bootloader lama).

### 1.2 Measured Boot
Berbeda dengan Secure Boot yang **memblokir** pemuatan kode tidak tepercaya, **Measured Boot** tetap mengizinkan booting berjalan, namun merekam setiap hash kode loader/driver ke dalam register TPM (PCR) untuk remote attestation.

---

## 2. Arsitektur TPM 2.0 (Trusted Platform Module)

TPM adalah mikrokontroler kriptografi khusus yang diintegrasikan pada motherboard untuk menghasilkan kunci, memverifikasi integritas boot, dan menyimpan data sensitif secara fisik.

### 2.1 Platform Configuration Registers (PCR)
PCR adalah register internal TPM 20-byte (PCR 0 s.d 23) yang digunakan untuk merekam status booting secara kumulatif. Register ini tidak dapat ditulis langsung secara bebas (*write-protected*); ia hanya dapat diubah melalui operasi matematika **Extend**:

$$\text{PCR}_{\text{new}} = \text{SHA-256}(\text{PCR}_{\text{old}} \mathbin{\Vert} \text{Hash}(\text{NewData}))$$

Tabel pemetaan register PCR standar TCG:

| PCR Index | Komponen yang Diukur (Measured) |
|---|---|
| **PCR 0** | SRTM (System ROM/BIOS code), motherboard configuration |
| **PCR 2** | Option ROM Code (PCI controllers, GPU firmware) |
| **PCR 4** | MBR/GPT partition details & Boot Loader (shim.efi, grub.efi) |
| **PCR 8** | OS Kernel parameters & initrd images |
| **PCR 11** | BitLocker/LUKS Storage Encryption key validation status |

### 2.2 Sealing and Unsealing Data
**Sealing** adalah proses mengenkripsi kunci dekripsi storage (seperti BitLocker atau LUKS) dengan mengaitkannya pada status PCR tertentu.
- Jika ada *bootkit* memodifikasi bootloader, pengukuran PCR 4 akan berubah.
- Saat OS meminta TPM untuk melakukan **Unseal**, TPM membandingkan nilai PCR saat ini dengan nilai yang terkunci. Jika berbeda, TPM akan menolak memberikan kunci dekripsi, mengunci storage dari akses ilegal.

---

## 3. Trusted Execution Environments (TEE)

**TEE** adalah area aman khusus di dalam prosesor utama (*host CPU*) yang menjamin data dan kode yang berjalan di dalamnya dilindungi dari akses luar (termasuk dari user root, kernel OS, atau hypervisor yang terkompromi).

Arsitektur sistem menggunakan TEE terbagi secara fisik menjadi:
1. **Rich Execution Environment (REE)**: Area OS utama (Linux, Windows) yang menjalankan aplikasi normal.
2. **Trusted Execution Environment (TEE)**: Area secure yang menjalankan *Trusted Applications* (TA) di atas *Trusted OS* khusus.

---

## 4. Mekanisme Enklave: Intel SGX & ARM TrustZone

Dua vendor CPU terbesar memiliki pendekatan arsitektur isolasi hardware yang berbeda:

### 4.1 Intel SGX (Software Guard Extensions)
Intel SGX mengadopsi model isolasi berbasis **Enclave** langsung di memori RAM tanpa memedulikan privilese ring OS.

```
┌────────────────────────────────────────────────────────┐
│                      Sistem RAM                        │
│  ┌───────────────────────┐  ┌───────────────────────┐  │
│  │    Aplikasi Biasa     │  │   Enclave SGX (PRM)   │  │
│  │                       │  │                       │  │
│  │   Akses tidak sah     │  │  - Kode/Data Enkripsi │  │
│  │   dihalangi hardware ─┼─▶│  - Kunci Kripto       │  │
│  └───────────────────────┘  └───────────────────────┘  │
└────────────────────────────────────────────────────────┘
```
- **Processor Reserved Memory (PRM)**: Wilayah RAM terisolasi yang dienkripsi secara dinamis di level hardware oleh memori kontroler CPU menggunakan **Memory Encryption Engine (MEE)**.
- **Enclave**: Unit pemrosesan terlindungi di dalam PRM. Data yang keluar dari die CPU menuju RAM fisik akan otomatis dienkripsi secara acak menggunakan kunci simetris internal CPU yang berubah setiap siklus boot. Hal ini melindunginya dari pembacaan RAM fisik (*cold boot attacks*).

### 4.2 ARM TrustZone
ARM TrustZone mengadopsi konsep isolasi sistem penuh secara horizontal dengan membagi CPU menjadi dua status dunia:
1. **Normal World (Non-secure)**: OS Android/iOS standar.
2. **Secure World**: Sistem operasi keamanan mikro (Trusted OS seperti OP-TEE).

- **NS-bit (Non-Secure bit)**: Sebuah bit kontroler fisik di bus AMBA AXI yang menentukan hak akses pembacaan memori/perangkat. Jika NS-bit bernilai 0 (Secure State), CPU dapat mengakses memori secure dan non-secure. Jika NS-bit bernilai 1, CPU akan diblokir keras secara elektrik oleh hardware dari mengakses alamat memori secure.
- **SMC (Secure Monitor Call)**: Instruksi assembly khusus untuk melakukan perpindahan konteks (*context switch*) dari Normal World ke Secure World melalui lapisan *Secure Monitor*.

---

## 5. Vektor Serangan & Eksploitasi Perangkat Keras

Meskipun tangguh, jangkar keamanan perangkat keras rentan terhadap serangan fisik tingkat lanjut dan cacat desain mikroarsitektur:

- **Cold Boot Attack**: Mendinginkan modul memori RAM menggunakan gas cair nitrogen sesaat setelah komputer mati, membiarkan muatan listrik kapasitor RAM tertahan cukup lama untuk diekstraksi menggunakan pembaca memori eksternal guna mencuri kunci BitLocker/LUKS.
- **Voltage Glitching / Fault Injection**: Memberikan fluktuasi tegangan listrik mikro pada chip prosesor selama instruksi perbandingan nilai bootloader dijalankan. Gangguan ini memaksa instruksi kondisional (`if signature == valid`) mengalami galat dan melompat ke blok eksekusi seolah-olah valid.
- **Enclave Side-Channel Attacks**: Menggunakan teknik kebocoran cache CPU (seperti Spectre/Meltdown varian baru) untuk memetakan alamat memori akses data di dalam Intel SGX enklave berdasarkan perbedaan latensi akses memori cache.

---

## 6. Koneksi ke Vault

| Catatan | Hubungan |
|------|----------|
| [[hierarchy-endpoint-security]] | Peta jalan pertahanan endpoint dari Ring -3 (Hardware/TPM) hingga Ring 3 (User Space). |
| [[kernel-forensics]] | Deteksi rootkit yang mencoba menyamar sebelum memori TEE diaktifkan. |
| [[side-channel-analysis]] | Teori matematika dan praktis untuk mengeksploitasi hardware melalui emisi elektromagnetik/daya. |
| [[firmware-reverse-engineering-deepdive]] | Metode rekayasa balik file biner BIOS/UEFI sebelum diverifikasi oleh Secure Boot. |
