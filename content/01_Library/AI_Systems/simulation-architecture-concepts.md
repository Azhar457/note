---
title: Arsitektur Dan Konsep Simulasi
tags:
- library
- other
created: '2026-05-16'
updated: '2026-07-01'
status: pending
cssclasses: ''
---
# 🛡️ ARSITEKTUR & KONSEP — Simulasi Keamanan Siber

Dokumentasi ini menguraikan landasan teori, skema jaringan, dan metodologi simulasi "Defender vs Attacker" berdasarkan kurikulum pengajaran Keamanan Siber. Fokus utama adalah pada pemisahan antara lingkungan yang rentan untuk forensik dan lingkungan yang diperkuat untuk pertahanan aktif.

## 🏗️ Lingkungan & Spesifikasi (Environment)

| Komponen            | Detail Spesifikasi                                      |
| ------------------- | ------------------------------------------------------- |
| **Hardware Host**   | Laptop Win 10 LTSC IoT, AMD Ryzen 5 4500U, RAM 16GB     |
| **Hypervisor**      | VMware Workstation Pro                                  |
| **OS VM Rentan**    | Metasploitable 2 (Ubuntu 8.04 - Hardy)                  |
| **OS VM Kuat**      | Rocky Linux 10 (RHEL Family)                            |
| **Layanan Utama**   | WordPress CMS (Dockerized)                              |

Selain spesifikasi di atas, lingkungan simulasi juga dilengkapi dengan beberapa tool pendukung seperti:

*   **Cloudflare** sebagai lapis pertama pertahanan untuk memblokir bot otomatis dan menyembunyikan IP asli VM2.
*   **SafeLine WAF** sebagai lapis kedua pertahanan untuk melindungi aplikasi web dari eksploitasi.
*   **CrowdSec** sebagai lapis ketiga pertahanan untuk mendeteksi dan memblokir IP pelaku serangan.
*   **Lynis** sebagai tool audit untuk memandu proses hardening OS.
*   **Docker** sebagai container untuk mengisolasi lingkungan WordPress dan Database.
*   **Auditd** sebagai tool untuk memantau setiap command yang dijalankan oleh penyerang.
*   **Tcpdump** sebagai tool untuk merekam seluruh lalu lintas data mentah.
*   **AIDE** sebagai tool untuk melakukan audit baseline file system.

## 🧠 Filosofi Pemisahan: VM1 vs VM2

Mengapa kita membedakan pendekatan keamanan pada kedua VM ini? Dan mengapa alat forensik dasar seperti `tcpdump`, `AIDE`, dan `auditd` **tidak** diutamakan di VM2?

### 🎯 VM1: Metasploitable2 (Fokus Forensik & Honeypot)

VM ini sengaja dibiarkan memiliki banyak celah keamanan (*vulnerable-by-design*). Tujuannya adalah membiarkan *Attacker* menembus sistem agar *Blue Team* bisa mempelajari cara kerja eksploitasi, pergerakan lateral, dan pemasangan *backdoor*. 
Oleh karena itu, kita sangat bergantung pada alat forensik manual di level Sistem Operasi:

*   **`tcpdump`**: Untuk menangkap *raw packet* (pcap) dari *payload exploit* yang dikirim.
*   **`auditd`**: Untuk merekam secara diam-diam *command* jahat apa saja yang diketik oleh *hacker* setelah berhasil mendapatkan *shell*.
*   **`AIDE`**: Untuk mengetahui file biner atau konfigurasi apa saja yang dirusak/disisipi *malware*.

### 🛡️ VM2: Rocky Linux 10 (Fokus Active Defense & Pencegahan)

VM ini merepresentasikan server *production* modern dengan konsep **Defense in Depth** (Pertahanan Berlapis). Tujuannya bukan untuk melihat *hacker* mengacak-acak sistem, melainkan **memblokir mereka sejauh mungkin sebelum menyentuh sistem operasi**.
Oleh karena itu, alat forensik OS manual (`tcpdump`/`auditd`) menjadi kurang krusial di sini. Sebagai gantinya, kita berinvestasi pada pertahanan aktif dan cerdas:

*   **Lapis 1 (DNS/Edge):** **Cloudflare** memblokir *bot* dan *tools* pentest otomatis (*Bot Fight Mode* / WAF Rules).
*   **Lapis 2 (Application/Layer 7):** **SafeLine WAF** menganalisis secara semantik setiap *request* HTTP untuk memblokir injeksi kode (SQLi, XSS) sebelum mencapai *container* WordPress.
*   **Lapis 3 (Network/Behavioral):** **CrowdSec** memantau anomali log dan secara otomatis menjatuhkan larangan (*ban*) pada IP *attacker* di level *firewall* (Nftables) jika ada indikasi *bruteforce* atau *scanning*.
*   **Lapis 4 (OS/Container):** **Docker Security Opts** dan Hardening OS (hasil audit **Lynis**) membatasi pergerakan *hacker* seandainya mereka secara ajaib berhasil menembus 3 lapis pelindung di atas.

## 🌐 Topologi Jaringan & Skema IP

Simulasi dilakukan dalam satu laptop host menggunakan skema jaringan internal yang dapat diekspos melalui *port forwarding* atau terowongan jaringan untuk akses eksternal.

### Pemetaan Alamat IP & Domain

*   **Metasploitable2 (VM1):** `192.168.86.128` (Akses langsung via LAN untuk eksploitasi).
*   **Rocky Linux 10 (VM2):** `192.168.86.129` (Di-proxy secara aman melalui Cloudflare ke `defend.azharmtq.my.id`).
*   **Adapter Mode:** Bridged / NAT.

## 🛠️ Pemetaan Matriks Keamanan (Blue Team Stack)

Tabel berikut menjelaskan fungsionalitas setiap alat keamanan yang diinstal di lingkungan simulasi sesuai dengan peran utamanya di masing-masing VM:

| Lapis Pertahanan | Nama Tool     | Fungsi Utama dalam Simulasi                                                                 | Target VM        |
| ---------------- | ------------- | ------------------------------------------------------------------------------------------- | ---------------- |
| **Edge Network** | `Cloudflare`  | Memblokir bot otomatis, menyembunyikan IP asli VM2, menyajikan enkripsi SSL (*Full Strict*).| Rocky Linux 10   |
| **Web App**      | `SafeLine`    | Bertindak sebagai WAF Semantik Layer 7 untuk melindungi WordPress dari eksploitasi web.     | Rocky Linux 10   |
| **Behavioral IPS**| `CrowdSec`   | Mendeteksi pola serangan (bruteforce, scanning) dan memblokir IP pelaku di level iptables.  | Rocky Linux 10   |
| **OS Audit**     | `Lynis`       | Melakukan audit mendalam terhadap konfigurasi Kernel & OS untuk memandu proses *hardening*. | Rocky Linux 10   |
| **Container**    | `Docker`      | Mengisolasi lingkungan WordPress dan Database agar tidak menyentuh OS Host secara langsung. | Rocky Linux 10   |
| **Syscall Log**  | `auditd`      | Memantau setiap *command* yang dijalankan oleh penyerang, perubahan file, dan akses root.   | Metasploitable2  |
| **Pcap Capture** | `tcpdump`     | Merekam seluruh lalu lintas data mentah (pcap) untuk dianalisis di Wireshark.               | Metasploitable2  |
| **Integrity**    | `AIDE`        | Melakukan audit *baseline* file system untuk mendeteksi perubahan ilegal pada file biner.   | Metasploitable2  |

## 🎯 Tujuan Akhir Laporan

1.  **Sisi Forensik (VM1):** Menyusun *timeline* serangan yang akurat (Kapan, Siapa, Lewat mana, Apa dampaknya) menggunakan log dari `auditd` dan `tcpdump`.
2.  **Sisi Hardening (VM2):** Mendemonstrasikan efektivitas arsitektur **Defense in Depth** dalam menggagalkan AI *Attacker* (contoh: Agent Zero) dan *tools* pentest otomatis sebelum mereka berhasil menembus lapisan aplikasi.

## 🔗 Lihat Juga

*   [[simulation-architecture-concepts|Master SOP Setup Lingkungan]]
*   [[network-security|Dasar Keamanan Jaringan (OSI Layer)]]

## 📚 Instalasi dan Konfigurasi

### Instalasi Rocky Linux 10

1.  Download ISO Rocky Linux 10 dari [situs resmi](https://rockylinux.org/download).
2.  Buat VM baru di VMware Workstation Pro dengan spesifikasi yang telah ditentukan.
3.  Pasang ISO Rocky Linux 10 ke VM dan lakukan instalasi.
4.  Konfigurasi jaringan dan setting lainnya sesuai dengan kebutuhan.

### Instalasi Metasploitable 2

1.  Download ISO Metasploitable 2 dari [situs resmi](https://sourceforge.net/projects/metasploitable/).
2.  Buat VM baru di VMware Workstation Pro dengan spesifikasi yang telah ditentukan.
3.  Pasang ISO Metasploitable 2 ke VM dan lakukan instalasi.
4.  Konfigurasi jaringan dan setting lainnya sesuai dengan kebutuhan.

### Instalasi Docker

1.  Instal Docker di Rocky Linux 10 dengan menjalankan perintah `sudo dnf install docker`.
2.  Mulai service Docker dengan menjalankan perintah `sudo systemctl start docker`.
3.  Aktifkan service Docker untuk memulai otomatis saat boot dengan menjalankan perintah `sudo systemctl enable docker`.

### Instalasi WordPress

1.  Pull image WordPress dari Docker Hub dengan menjalankan perintah `sudo docker pull wordpress`.
2.  Buat container WordPress dengan menjalankan perintah `sudo docker run -d -p 8080:80 wordpress`.
3.  Akses WordPress melalui browser dengan url `http://localhost:8080`.

### Instalasi Cloudflare

1.  Buat akun Cloudflare dan tambahkan domain `defend.azharmtq.my.id` ke akun Cloudflare.
2.  Konfigurasi DNS domain untuk menggunakan Cloudflare.
3.  Aktifkan fitur *Bot Fight Mode* dan WAF di akun Cloudflare.

### Instalasi SafeLine WAF

1.  Instal SafeLine WAF di Rocky Linux 10 dengan menjalankan perintah `sudo dnf install safeline-waf`.
2.  Konfigurasi SafeLine WAF untuk melindungi WordPress.
3.  Aktifkan SafeLine WAF untuk memulai proteksi.

### Instalasi CrowdSec

1.  Instal CrowdSec di Rocky Linux 10 dengan menjalankan perintah `sudo dnf install crowdsec`.
2.  Konfigurasi CrowdSec untuk memantau log dan memblokir IP pelaku serangan.
3.  Aktifkan CrowdSec untuk memulai proteksi.

### Instalasi Lynis

1.  Instal Lynis di Rocky Linux 10 dengan menjalankan perintah `sudo dnf install lynis`.
2.  Jalankan Lynis untuk melakukan audit OS dengan menjalankan perintah `sudo lynis audit system`.
3.  Ikuti rekomendasi dari Lynis untuk melakukan hardening OS.

## 📊 Analisis Log

### Analisis Log Auditd

1.  Akses log auditd dengan menjalankan perintah `sudo tail -f /var/log/audit/audit.log`.
2.  Cari log yang mencurigakan dan analisis untuk mengetahui apa yang terjadi.
3.  Buat laporan dari analisis log untuk memberikan gambaran tentang serangan.

### Analisis Log Tcpdump

1.  Akses log tcpdump dengan menjalankan perintah `sudo tcpdump -r /var/log/tcpdump.log`.
2.  Cari paket yang mencurigakan dan analisis untuk mengetahui apa yang terjadi.
3.  Buat laporan dari analisis log untuk memberikan gambaran tentang serangan.

## 🚀 Kesimpulan

Dalam simulasi keamanan siber ini, kita telah mempelajari tentang arsitektur dan konsep simulasi keamanan siber. Kita telah mempelajari tentang lingkungan dan spesifikasi, filosofi pemisahan, topologi jaringan, dan skema IP. Kita juga telah mempelajari tentang instalasi dan konfigurasi beberapa tool keamanan seperti Docker, WordPress, Cloudflare, SafeLine WAF, CrowdSec, dan Lynis. Dalam analisis log, kita telah mempelajari tentang analisis log auditd dan tcpdump. Dengan keseluruhan konsep dan tool ini, kita dapat membangun sistem keamanan siber yang kuat dan efektif.