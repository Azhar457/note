---
title: "Picoctf Section 1 Onboarding"
tags:
  - picoctf-beginner-guide
  - resources
aliases:
  - "picoctf-section-1-onboarding"
created: "2026-05-12"
updated: "2026-07-07"
status: operational
---

# 🚀 PICOCTF SECTION 1 — Onboarding & Connection

> **Environment:** Linux Shell / Webshell  
> **Filosofi:** Teliti membaca instruksi adalah setengah dari perjuangan.  
> **Target:** SSH (Secure Shell), Netcat (nc), & Flag Discovery.

---

## FASE 1 — Identifikasi Flag & Konsep Dasar

Flag adalah string teks unik yang bertindak sebagai bukti bahwa Anda telah berhasil memecahkan suatu tantangan. Flag ini biasanya disimpan di tempat tersembunyi di server target, didekripsi melalui algoritma tertentu, atau diekstrak dari file biner yang rusak.

- **Format Dasar:** Format standar flag di platform ini adalah `picoCTF{kunci_jawaban_di_sini}`. Pola ini memudahkan pembuatan sistem penilaian otomatis (_automated grading system_).
- **Karakteristik Leet Speak:** Seringkali kata di dalam tanda kurung kurawal menggunakan variasi _Leet Speak_ (misal: mengganti huruf `e` dengan `3`, `a` dengan `4`, `s` dengan `5`, atau `t` dengan `7`). Contoh: `picoCTF{1337_h4ck3r_57470}`. Penulisan ini menuntut ketelitian tinggi saat menyalin jawaban agar tidak terjadi kesalahan tik (_typo_).

---

## FASE 2 — Penguasaan SSH (Secure Shell)

SSH adalah protokol jaringan kriptografi yang digunakan untuk mengoperasikan layanan jaringan secara aman melalui jaringan yang tidak aman. Dalam konteks CTF, SSH digunakan untuk masuk ke lingkungan server simulasi Linux target guna mencari berkas flag yang disembunyikan di direktori lokal server tersebut.

### 2.1 Sintaks Perintah Koneksi

Perintah dasar SSH membutuhkan parameter username, nama host (atau IP address), serta nomor port yang digunakan (secara bawaan adalah port 22, namun pada tantangan CTF seringkali diubah ke port dinamis tingkat tinggi untuk alasan keamanan).

```bash
# Format standar: ssh [username]@[host] -p [port]
ssh ctf-player@titan.picoctf.net -p 57470
```

### 2.2 Mekanisme Kerja Keamanan SSH

Ketika pertama kali Anda terhubung ke server baru menggunakan SSH, sistem akan menampilkan sidik jari kunci host (_host key fingerprint_) dan menanyakan konfirmasi.

```text
The authenticity of host 'titan.picoctf.net (3.23.14.88)' can't be established.
ED25519 key fingerprint is SHA256:abcd1234...
Are you sure you want to continue connecting (yes/no/[fingerprint])?
```

Anda wajib mengetik `yes` dan menekan Enter. Sidik jari ini akan disimpan di berkas lokal Anda di alamat `~/.ssh/known_hosts`. Jika di kemudian hari host key server berubah, SSH akan memblokir koneksi dengan peringatan keamanan keras **"WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!"** untuk mencegah serangan _Man-in-the-Middle_ (MitM). Jika ini terjadi pada server CTF yang sering di-deploy ulang, Anda dapat mereset kunci host tersebut dengan perintah:

```bash
ssh-keygen -R titan.picoctf.net
```

### 2.3 Jebakan Klasik & Troubleshooting SSH

- **The Period Trap (Jebakan Titik):** Pada instruksi teks picoCTF, kalimat petunjuk sering diakhiri dengan tanda titik untuk tata bahasa Inggris yang benar, misalnya: _"The password is: password123."_. Praktikan pemula sering menyalin titik di akhir tersebut, sehingga menghasilkan error _Permission Denied_. Pastikan Anda hanya menyalin teks sandi alphanumeric tanpa menyertakan tanda baca penutup kalimat.
- **Kursor Sandi yang Tidak Bergerak (Invisible Password):** Saat Anda mengetik kata sandi di shell Linux, terminal tidak akan menampilkan karakter asteris (`*`) atau menggerakkan kursor. Hal ini adalah fitur keamanan bawaan sistem operasi UNIX untuk mencegah pencurian kata sandi lewat bahu (_shoulder surfing_). Cukup ketik sandi dengan benar lalu tekan Enter.
- **Verbose Mode (`-v`):** Jika koneksi SSH Anda mengalami kegagalan (misalnya macet di tulisan _Connecting..._), tambahkan flag `-v` (verbose) atau `-vv` untuk menampilkan log debug detail dari setiap fase negosiasi kunci kriptografi dan autentikasi.
  ```bash
  ssh -v ctf-player@titan.picoctf.net -p 57470
  ```

---

## FASE 3 — Netcat (The Network Swiss Army Knife)

Netcat (`nc`) adalah utilitas jaringan yang membaca dan menulis data di seluruh koneksi jaringan menggunakan protokol TCP atau UDP. Di dunia keamanan siber, Netcat adalah alat fundamental yang dijuluki "Pisau Swiss Lipat" karena multifungsi—bisa digunakan untuk port scanning, banner grabbing, transfer file, hingga membuat backdoor sederhana.

### 3.1 Arsitektur Komunikasi Client-Server

Dalam tantangan picoCTF, server target bertindak sebagai **Listener** (membuka pintu port tertentu dan menjalankan skrip di baliknya). Sementara komputer Anda bertindak sebagai **Connector** (klien yang mengetuk pintu koneksi tersebut).

```
+---------------------------+                      +---------------------------+
|    SERVER (PicoCTF)       |   TCP Connection     |       CLIENT (Anda)       |
|    (Listener Mode)        | <==================> |     (Connector Mode)      |
|  Menjalankan skrip Python |                      |  Mengirim input & membaca |
|  dan menunggu di Port 9999|                      |  output lewat terminal    |
+---------------------------+                      +---------------------------+
```

### 3.2 Menghubungkan ke Server Target

Untuk terhubung ke port tantangan, Anda cukup memanggil `nc` diikuti oleh nama host/IP dan nomor port:

```bash
nc titan.picoctf.net 61234
```

Setelah koneksi terbentuk, apa pun yang Anda ketik di terminal lokal akan dikirim ke program di server, dan apa pun yang dihasilkan oleh program server akan ditampilkan di terminal Anda. Tantangan interaktif seringkali meminta Anda menyelesaikan kuis matematika cepat atau memasukkan input buffer overflow melalui koneksi Netcat ini.

---

## 📋 Panduan Perintah Cepat (Cheat Sheet)

### Utilitas SSH

| Perintah                             | Deskripsi                                                                     |
| ------------------------------------ | ----------------------------------------------------------------------------- |
| `ssh [user]@[host] -p [port]`        | Melakukan koneksi SSH ke target pada port spesifik.                           |
| `ssh -i [private_key] [user]@[host]` | Autentikasi SSH menggunakan file kunci privat (Keypair) alih-alih kata sandi. |
| `ssh -v -p [port] [user]@[host]`     | Menampilkan informasi debug koneksi (sangat berguna saat koneksi macet).      |
| `ssh-keygen -R [host]`               | Menghapus entri host lama dari `known_hosts` jika host key berubah.           |

### Utilitas Netcat (`nc`)

| Perintah                                     | Deskripsi                                                                                                              |
| -------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| `nc [host] [port]`                           | Menghubungkan ke IP/Domain dan Port tertentu menggunakan protokol TCP bawaan.                                          |
| `nc -u [host] [port]`                        | Menghubungkan ke target menggunakan protokol UDP (User Datagram Protocol).                                             |
| `nc -lvnp [port]`                            | Membuka listener TCP lokal (Listen, Verbose, Numeric IP, Port spesifik) untuk menangkap koneksi balik (reverse shell). |
| `nc -vz -w 2 [host] [start_port]-[end_port]` | Melakukan port scanning cepat pada rentang port target dengan timeout 2 detik.                                         |

---

## ⚠️ Anti-Pattern & Skenario Kegagalan

| Kegagalan                                                 | Penyebab Utama                                                                                        | Solusi                                                                                                   |
| --------------------------------------------------------- | ----------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| `ssh: connect to host ... port ...: Connection refused`   | Layanan SSH di server target mati atau port yang dimasukkan salah.                                    | Periksa kembali nomor port pada deskripsi soal. Hubungkan ulang beberapa saat lagi.                      |
| `ssh: connect to host ... port ...: Connection timed out` | Firewall memblokir koneksi port keluar atau jaringan lokal Anda lambat.                               | Pastikan jaringan Anda tidak memblokir port tingkat tinggi (Gunakan webshell bawaan picoCTF jika perlu). |
| `ssh: Host key verification failed.`                      | Kunci host server target telah berubah sejak koneksi terakhir Anda.                                   | Jalankan perintah `ssh-keygen -R [host]` untuk menghapus entri lama.                                     |
| `nc: command not found`                                   | Paket netcat belum terinstal di sistem operasi lokal Anda.                                            | Jalankan `sudo apt update && sudo apt install netcat-openbsd -y` di Debian/Ubuntu.                       |
| Koneksi Netcat terputus seketika setelah terhubung        | Skrip di server mengalami crash akibat input yang tidak valid atau pembatasan waktu idle (_timeout_). | Tulis skrip otomatisasi Python untuk mengirimkan input secara instan tanpa jeda manual.                  |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Peta Alur Pembelajaran Utama & Kurikulum CTF.
- [[picoctf-section-2-cyberchef-encodings]] — Mempelajari representasi data desimal, biner, hex, dan base64 dengan CyberChef.
- [[technician-toolkit-standard]] — Daftar lengkap perkakas diagnostik jaringan Linux tingkat lanjut.

---

_PicoCTF Section 1 | SSH · Netcat · Flag Discovery | Dokumentasi Pembelajaran Taktis_
