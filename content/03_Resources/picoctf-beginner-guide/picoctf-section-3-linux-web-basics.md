---
title: Picoctf Section 3 Linux Web Basics
tags:
  - picoctf-beginner-guide
  - resources
created: "2026-05-12"
updated: "2026-07-07"
status: pending
---

# 🛠️ PICOCTF SECTION 3 — Linux & Web Basics

> **Tools:** `strings`, `grep`, `file`, `reset`, Browser DevTools  
> **Filosofi:** Intip apa yang tidak terlihat di permukaan.  
> **Target:** Binary files, Source code, & Hidden Web elements.

---

## FASE 1 — Analisis Biner Sederhana (File & Strings)

Saat Anda mengunduh berkas biner (seperti program yang sudah dikompilasi, gambar, atau berkas arsip) di tantangan CTF, isi berkas tersebut tidak dapat langsung dibaca dengan editor teks biasa. Membuka berkas biner secara paksa dengan editor teks hanya akan menampilkan karakter acak yang tidak berarti (_garbage characters_).

### 1.1 Perintah `file` (Identifikasi Format Sebenarnya)

Ekstensi berkas di sistem operasi Linux tidak menentukan jenis berkas. Seorang pembuat soal CTF bisa saja menyembunyikan berkas arsip zip dengan mengubah ekstensinya menjadi `.jpg`. Perintah `file` memeriksa bagian _header_ berkas (dikenal sebagai **Magic Bytes**) untuk menentukan tipe data berkas yang sebenarnya.

```bash
# Contoh penggunaan:
file target_file
```

**Contoh Output:**

```text
target_file: ELF 64-bit LSB shared object, x86-64, version 1 (SYSV), dynamically linked, interpreter /lib64/ld-linux-x86-64.so.2, for GNU/Linux 3.2.0, build id: 1234abcd..., stripped
```

- `ELF 64-bit`: Program biner executable untuk arsitektur Linux 64-bit.
- `dynamically linked`: Program membutuhkan library eksternal untuk berjalan.
- `stripped`: Informasi simbol debug telah dihapus untuk memperkecil ukuran berkas, yang membuat proses analisis mendalam (_reverse engineering_) menjadi lebih menantang.

### 1.2 Perintah `strings` (Ekstraksi Teks Biner)

Perintah `strings` memindai seluruh berkas biner dan menampilkan urutan karakter ASCII yang dapat dicetak (_printable characters_) dengan panjang minimal 4 karakter (secara default). Teknik ini sangat efektif untuk menemukan flag yang ditanam langsung sebagai string konstan di dalam kode program.

```bash
# Menampilkan string dan menyaring kata kunci picoCTF
strings strings_it | grep "picoCTF"
```

### 1.3 Pemulihan Terminal Akibat Kesalahan `cat`

Jika Anda tidak sengaja menjalankan perintah `cat` pada file biner (seperti `cat biner_executable`), terminal Anda kemungkinan besar akan menampilkan karakter aneh dan rusak. Ini terjadi karena biner tersebut berisi urutan kontrol terminal ANSI yang mengubah pemetaan font terminal Anda. Jangan panik atau menutup terminal Anda. Anda dapat memulihkannya dengan mengetik perintah berikut (meskipun karakter yang Anda ketik mungkin tidak terlihat di layar, tekan saja Enter):

```bash
reset
```

Perintah ini akan menginisialisasi ulang status terminal Anda ke konfigurasi bawaan.

---

## FASE 2 — Penguasaan Pencarian Tekstual (`grep` Mastery)

`grep` (Global Regular Expression Print) adalah salah satu utilitas CLI Linux paling kuat untuk mencari baris teks yang cocok dengan pola tertentu di dalam satu atau banyak berkas.

### 2.1 Sintaks Pencarian Tingkat Lanjut

- **Pencarian Rekursif (`-r` atau `-R`):** Mencari kecocokan kata kunci di seluruh berkas yang ada di dalam direktori saat ini beserta seluruh sub-direktorinya.
  ```bash
  grep -r "picoCTF" .
  ```
- **Case-Insensitive (`-i`):** Mengabaikan perbedaan huruf besar dan huruf kecil pada kata kunci pencarian.
  ```bash
  grep -i "picoctf" file_log.txt
  ```
- **Menampilkan Baris Sekitar (`-B`, `-A`, `-C`):** Menampilkan konteks baris sebelum (_Before_), sesudah (_After_), atau keduanya (_Context_) di sekitar baris yang cocok. Ini sangat berguna jika flag dipecah ke beberapa baris.
  ```bash
  # Menampilkan 2 baris sebelum dan 2 baris sesudah baris yang cocok
  grep -C 2 "flag" database.sql
  ```
- **Hanya Tampilkan Kecocokan (`-o`):** Hanya mengekstrak string yang cocok secara persis dengan pola pencarian, bukan menampilkan seluruh baris teks. Sangat ampuh jika dikombinasikan dengan Regular Expression (Regex).
  ```bash
  # Mengekstrak pola flag picoCTF menggunakan regex
  grep -o -E "picoCTF\{[a-zA-Z0-9_-]+\}" file.txt
  ```

---

## FASE 3 — Eksploitasi Web Dasar (Web Exploitation)

Tantangan kategori Web Exploitation melatih Anda untuk menganalisis aplikasi web dari sudut pandang client-side maupun server-side.

### 3.1 Inspeksi Kode Sumber (Browser DevTools)

Saat menghadapi tantangan web sederhana seperti tantangan _Insp3ct0r_ di picoCTF, langkah pertama adalah memeriksa berkas yang dikirimkan oleh server ke peramban (_browser_) Anda. Tekan `Ctrl + Shift + I` (atau `F12`) untuk membuka Developer Tools.

1.  **Tab Elements / HTML Source:** Periksa struktur DOM HTML. Cari komentar-komentar yang sengaja ditinggalkan developer menggunakan sintaks `<!-- komentar -->`.
2.  **Tab Sources / Debugger (CSS & JS):** Aplikasi web modern memisahkan gaya tampilan (CSS) dan logika aplikasi (JavaScript) ke berkas eksternal. Periksa berkas stylesheet `.css` dan skrip `.js`. Flag seringkali dipecah menjadi tiga bagian dan diletakkan masing-masing di file HTML, CSS, dan JS.

### 3.2 Berkas Konfigurasi Sensitif (`robots.txt` & `.git`)

Aplikasi web sering meninggalkan berkas administratif atau riwayat pengembangan yang dapat diakses oleh publik jika server tidak dikonfigurasi dengan aman.

- **`robots.txt`:** Protokol standar yang digunakan oleh situs web untuk berkomunikasi dengan bot perayap mesin pencari (seperti Googlebot). File ini menentukan halaman mana yang _tidak boleh_ diindeks. Dalam skenario CTF, entri `Disallow` di `robots.txt` sering kali menunjukkan letak folder atau file rahasia yang berisi flag.
  ```text
  # Contoh isi robots.txt
  User-agent: *
  Disallow: /admin-portal-rahasia/
  ```
- **`.git` Leak:** Jika pengembang tidak sengaja mengunggah folder repositori `.git` ke direktori root web server, penyerang dapat mengunduh folder tersebut dan merekonstruksi seluruh riwayat kode sumber aplikasi (termasuk komit lama yang mungkin berisi kredensial atau flag yang telah dihapus). Anda dapat memeriksanya dengan mengakses `http://[IP-Target]/.git/`.

### 3.3 Manipulasi Cookie

Cookie adalah data kecil yang dikirim dari situs web dan disimpan di komputer pengguna oleh peramban web pengguna saat pengguna tersebut sedang menjelajah. Cookie sering digunakan untuk manajemen sesi (_session management_) atau melacak status login.

Di Developer Tools, buka tab **Application** (pada Chrome) atau **Storage** (pada Firefox), lalu pilih bagian **Cookies**. Anda akan melihat pasangan nama dan nilai (_Key-Value Pair_).

- **Contoh Skenario:** Jika Anda masuk sebagai tamu, Anda mungkin melihat cookie `admin=0` atau `auth=guest`. Anda dapat memodifikasi nilai tersebut secara langsung menjadi `admin=1` atau `auth=admin`, lalu memuat ulang (_refresh_) halaman web untuk mengelabui logika autentikasi server dan mendapatkan akses administratif.

---

## 📋 Lembar Acuan Perintah (Cheat Sheet)

```bash
# ═══ ANALISIS FILE & BINER ═══
file berkas_misterius                  # Cek tipe berkas berdasarkan magic bytes
strings -n 6 berkas_biner              # Cari string yang panjangnya minimal 6 karakter
strings berkas.bin | grep -oE "picoCTF\{.*\}" # Ekstraksi flag otomatis dari file biner

# ═══ GREP MASTERY ═══
grep -rnw '/path/ke/direktori/' -e 'pico' # Cari string 'pico' secara rekursif, tampilkan baris, abaikan biner
grep -E "(pico|flag)" file.txt         # Cari baris yang mengandung kata 'pico' ATAU 'flag' (Extended Regex)

# ═══ WEB & DIAGNOSTIK ═══
curl -I https://target.com             # Ambil HTTP Response Header saja
curl -s https://target.com/robots.txt  # Baca file robots.txt secara diam-diam lewat terminal
```

---

## ⚠️ Anti-Pattern & Skenario Kesalahan Umum

| Tindakan Salah ❌                                               | Dampak Buruk                                                                                                    | Solusi Benar ✅                                                                                                                 |
| --------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------- |
| Membuka file biner raksasa dengan perintah `cat`                | Terminal macet, crash, dan menampilkan karakter aneh yang merusak output konsol.                                | Gunakan perintah `strings` untuk menyaring teks, atau gunakan `hexdump -C` jika ingin menganalisis byte mentah.                 |
| Hanya menguji file index HTML saat melakukan investigasi web    | Melewatkan komponen penting seperti script JS, CSS, config XML, atau endpoint API tempat penyimpanan data asli. | Periksa tab _Network_ di DevTools untuk melihat seluruh daftar aset yang diunduh secara berkala oleh halaman web.               |
| Melakukan brute force direktori web secara manual satu per satu | Sangat lambat dan tidak efisien.                                                                                | Gunakan alat bantu pemindai otomatis (_directory brute force_) seperti `gobuster`, `dirb`, atau `ffuf` dengan wordlist standar. |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Peta Alur Pembelajaran Utama.
- [[picoctf-section-2-cyberchef-encodings]] — Kembali ke teknik konversi encoding data.
- [[picoctf-section-4-python-automation]] — Melanjutkan ke pembuatan skrip eksploitasi otomatis menggunakan Python.

---

_PicoCTF Section 3 | strings · grep · robots.txt · Insp3ct0r | Edisi Lengkap_
