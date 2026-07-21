---
title: Picoctf Master Index
tags:
  - picoctf-beginner-guide
  - resources
created: "2026-05-12"
updated: "2026-07-07"
status: operational
---

# 🚩 PICOCTF BEGINNER — Master Index & Roadmap

## 🎯 Pengantar Capture The Flag (CTF) & picoCTF

Capture The Flag (CTF) adalah kompetisi keamanan informasi di mana peserta ditantang untuk menyelesaikan masalah teknis siber untuk menemukan string teks tersembunyi yang disebut **Flag**. Format flag biasanya memiliki pola tertentu, misalnya pada kompetisi ini formatnya adalah `picoCTF{kunci_jawaban_di_sini}`.

Kompetisi CTF terbagi menjadi beberapa tipe utama:

1. **Jeopardy-style:** Menyediakan sekumpulan soal dari berbagai kategori (Web, Forensics, Crypto, Reverse Engineering, Pwn) dengan nilai poin tertentu berdasarkan tingkat kesulitan. picoCTF menggunakan gaya ini.
2. **Attack-Defense:** Setiap tim diberikan server/jaringan yang rentan. Tugas mereka adalah mempertahankan sistem sendiri dari serangan tim lain sekaligus menyerang sistem tim lawan untuk mencuri flag mereka.
3. **King of the Hill:** Peserta memperebutkan kendali atas server tertentu. Tim yang berhasil mempertahankan akses terlama di server tersebut akan mendapatkan poin terbanyak.

picoCTF yang diinisiasi oleh Universitas Carnegie Mellon (CMU) adalah platform pembelajaran CTF Jeopardy terbaik di dunia untuk pemula. Platform ini dirancang khusus dengan kurikulum bertahap agar siapa pun dapat masuk ke dunia keamanan siber tanpa rasa takut.

## 🗺️ Peta Alur Pembelajaran (The Playlist Roadmap)

Alur di bawah dirancang secara sekuensial agar Anda tidak mengalami _cognitive overload_ saat mempelajari topik-topik keamanan siber yang sangat luas.

```
START: CTF ONBOARDING
        │
        ▼
[SECTION 1] Fondasi & Koneksi ───────── [[picoctf-section-1-onboarding]]
        │ (SSH, Netcat, Flag Format, Terminal Navigation)
        ▼
[SECTION 2] Encodings & CyberChef ───── [[picoctf-section-2-cyberchef-encodings]]
        │ (Base64, Hexadecimal, ROT13, Binary, ASCII)
        ▼
[SECTION 3] Linux & Web Basics ──────── [[picoctf-section-3-linux-web-basics]]
        │ (strings, grep, Wave a flag, Insp3ct0r, HTTP Headers)
        ▼
[SECTION 4] Python Automation ───────── [[picoctf-section-4-python-automation]]
        │ (Python Wrangling, PW Crack Series, Socket Programming)
        ▼
[SECTION 5] Specialized Analysis ────── (Deeper Dives Below)
        │
        ├─ Forensics ────────────────── [[picoctf-section-5-forensics]]
        ├─ Reverse Engineering ──────── [[picoctf-section-5-reverse-engineering]]
        └─ Binary Exploitation ──────── [[picoctf-section-5-binary-exploitation]]
```

### Peta Alur Pembelajaran: Contoh Implementasi

Contoh implementasi peta alur pembelajaran di atas dapat dilihat pada kode berikut:

```python
# Import library yang dibutuhkan
import os
import sys

# Definisikan fungsi untuk setiap bagian
def onboarding():
    print("Bagian 1: Fondasi & Koneksi")
    # Implementasi fungsi onboarding

def cyberchef():
    print("Bagian 2: Encodings & CyberChef")
    # Implementasi fungsi cyberchef

def linux_web_basics():
    print("Bagian 3: Linux & Web Basics")
    # Implementasi fungsi linux_web_basics

def python_automation():
    print("Bagian 4: Python Automation")
    # Implementasi fungsi python_automation

def specialized_analysis():
    print("Bagian 5: Specialized Analysis")
    # Implementasi fungsi specialized_analysis

# Jalankan fungsi sesuai dengan peta alur pembelajaran
onboarding()
cyberchef()
linux_web_basics()
python_automation()
specialized_analysis()
```

## 📑 Penjelasan Detail Setiap Kategori Soal

### 1. Fondasi & Koneksi (Onboarding)

Sebelum melangkah ke eksploitasi tingkat lanjut, Anda wajib menguasai cara berinteraksi dengan server jarak jauh (_remote server_). Sebagian besar tantangan CTF tidak menyediakan file unduhan, melainkan sebuah alamat IP dan port yang aktif.

- **Netcat (`nc`):** Protokol utilitas jaringan untuk membaca dan menulis data lintas koneksi jaringan menggunakan TCP atau UDP. Di picoCTF, Anda akan sering mengetik perintah seperti `nc jupiter.challenges.picoctf.org 51234` untuk berinteraksi dengan program di server target.
- **SSH (`ssh`):** Secure Shell digunakan untuk masuk secara aman ke server Linux target guna melakukan investigasi lokal. Anda harus terbiasa dengan sintaks `ssh user@host -p port`.

### 2. Encodings & Kriptografi Dasar

Kriptografi adalah pilar penting keamanan informasi. Pada tahap awal, Anda harus dapat membedakan antara **Encoding** (representasi data alternatif tanpa kunci keamanan, contoh: Base64, Hexadecimal) dengan **Kriptografi** (penyandian data dengan kunci rahasia untuk menjaga kerahasiaan, contoh: Caesar Cipher, Vigenere Cipher, RSA).

- **CyberChef:** Alat bantu web yang dijuluki "The Cyber Swiss Army Knife". Sangat berguna untuk melakukan konversi format enkripsi secara instan dengan metode drag-and-drop.
- **ROT13:** Caesar cipher dengan pergeseran 13 karakter. Sering digunakan untuk menyembunyikan flag secara sederhana.

### 3. Linux & Web Basics

Hampir seluruh infrastruktur server siber berjalan di atas sistem operasi Linux. Penguasaan CLI (Command Line Interface) Linux adalah hal mutlak yang tidak bisa ditawar.

- **Strings & Grep:** Perintah `strings` mengekstrak karakter yang dapat dibaca manusia dari file biner. Dikombinasikan dengan `grep`, Anda bisa mencari flag secara instan tanpa membuka file raksasa secara manual (`strings file_misterius | grep pico`).
- **Inspeksi Elemen Web:** Memahami cara kerja protokol HTTP/HTTPS. Menganalisis bagaimana browser meminta halaman (GET/POST requests), membaca cookies, header HTTP, serta melihat source code HTML/JS menggunakan fitur Developer Tools (F12).

### 4. Python Automation

Tantangan keamanan tingkat lanjut seringkali membutuhkan interaksi ribuan kali dengan server atau dekripsi data berulang yang mustahil dilakukan secara manual. Python adalah bahasa wajib bagi praktisi keamanan siber.

- **Socket Programming:** Membuat koneksi TCP menggunakan pustaka `socket` Python untuk mengirimkan input dan menangkap output dari server secara otomatis.
- **Brute Force Automation:** Menulis skrip untuk menebak kata sandi atau kunci kriptografi dengan cepat berdasarkan kamus kata (_wordlist_) seperti `rockyou.txt`.

### 5. Analisis Spesifik (Deeper Dives)

- **Digital Forensics:** Mencari bukti digital dari file sampah, menganalisis paket lalu lintas jaringan (PCAP), mengekstrak file tersembunyi dari gambar (Steganografi menggunakan `steghide` atau `exiftool`), serta memeriksa struktur file yang rusak.
- **Reverse Engineering:** Menganalisis program biner yang sudah dikompilasi (EXE atau ELF Linux) tanpa memiliki kode sumber aslinya. Anda akan menggunakan disassembler dan decompiler seperti Ghidra atau IDA Pro untuk memahami alur logika program dan menemukan algoritma pembuatan flag.
- **Binary Exploitation (Pwn):** Menemukan kerentanan memori pada program biner (seperti _Buffer Overflow_, _Format String Vulnerability_, atau _Use-After-Free_) untuk mengambil alih alur eksekusi program dan memicu pemanggilan shell (`/bin/sh`) pada server target.

## 🛠️ Rekomendasi Setup Lingkungan Kerja Lokal

Untuk kenyamanan bermain CTF, disarankan untuk tidak hanya mengandalkan webshell bawaan picoCTF, melainkan membangun lingkungan kerja sendiri di komputer lokal:

1.  **Virtual Machine (VM):** Pasang hypervisor seperti VirtualBox atau VMware Workstation, lalu instal distribusi Linux khusus penetrasi seperti **Kali Linux** atau **Parrot Security OS**. Distribusi ini telah dilengkapi ratusan alat bantu siap pakai.
2.  **Docker:** Jika Anda menggunakan Linux host atau WSL2 di Windows, Docker sangat efisien untuk menjalankan program CTF dalam kontainer terisolasi tanpa merusak konfigurasi sistem utama Anda.
3.  **Visual Studio Code:** Gunakan VS Code dengan ekstensi Python, Markdown, dan SSH FS untuk menulis skrip eksploitasi dan mencatat temuan secara terorganisir.

## 🔗 Referensi Pendukung

Untuk memperdalam pemahaman lintas sub-domain keamanan, silakan merujuk pada catatan berikut:

- [[curriculum-mapping]] — Peta kurikulum keamanan siber global dan sertifikasi industri (OSCP, CISSP, CEH).
- [[technician-toolkit-standard]] — Panduan lengkap penggunaan perkakas sistem, troubleshooting hardware, dan utilitas pengetesan jaringan.
- [[endpoint-security-freeware]] — Konsep pengamanan komputer klien dari serangan malware tingkat lanjut.

### Tabel Perbandingan

| Teknologi | Fungsi                     | Kelebihan                                                         |
| --------- | -------------------------- | ----------------------------------------------------------------- |
| Netcat    | Protokol utilitas jaringan | Membaca dan menulis data lintas koneksi jaringan                  |
| SSH       | Secure Shell               | Masuk secara aman ke server Linux target                          |
| CyberChef | Alat bantu web             | Melakukan konversi format enkripsi secara instan                  |
| Python    | Bahasa pemrograman         | Membuat skrip eksploitasi dan mencatat temuan secara terorganisir |

## 📊 Tips dan Trik

- **Jangan pernah menyerah:** Jika Anda mengalami kesulitan, coba lagi dan lagi sampai Anda menemukan solusi.
- **Gunakan alat bantu:** Netcat, SSH, CyberChef, dan Python adalah alat bantu yang sangat penting dalam menyelesaikan tantangan CTF.
- **Mencatat temuan:** Mencatat temuan Anda secara terorganisir dapat membantu Anda memahami pola dan logika di balik tantangan CTF.

### Contoh Implementasi

Contoh implementasi tips dan trik di atas dapat dilihat pada kode berikut:

```python
# Import library yang dibutuhkan
import os
import sys

# Definisikan fungsi untuk mencatat temuan
def catat_temuan(temuan):
    with open("temuan.txt", "a") as f:
        f.write(temuan + "\n")

# Jalankan fungsi untuk mencatat temuan
catat_temuan("Temuan 1")
catat_temuan("Temuan 2")
```

Dengan demikian, Anda telah mempelajari dasar-dasar CTF dan telah siap untuk memulai perjalanan Anda dalam dunia keamanan siber. Ingatlah untuk selalu mencatat temuan Anda dan menggunakan alat bantu yang tepat untuk menyelesaikan tantangan CTF.
