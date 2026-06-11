---
tags:
  - cyber-security
  - blue-team
  - simulation
  - virtual-lab
  - forensic
  - hardening
  - defense-in-depth
aliases:
  - Cyber Security Simulation Architecture
  - Defender vs Attacker Concept
created: 2026-05-16
status: operational
cssclasses:
  - wide-table
---

# 🛡️ ARSITEKTUR & KONSEP — Simulasi Keamanan Siber

> Dokumentasi ini menguraikan landasan teori, skema jaringan, dan metodologi simulasi "Defender vs Attacker" berdasarkan kurikulum pengajaran Keamanan Siber. Fokus utama adalah pada pemisahan antara lingkungan yang rentan untuk forensik dan lingkungan yang diperkuat untuk pertahanan aktif.

> [!info] Analogi Dosen
> **Tugas 1 (Rumah Rentan / Honeypot):** Membangun rumah tanpa pagar untuk memantau perilaku orang asing yang masuk; mencatat apa yang mereka bakar atau hapus.
> **Tugas 2 (Rumah Kuat / Hardened):** Membangun rumah dengan sistem keamanan berlapis (Defense in Depth) namun tetap menyediakan layanan publik (Web) yang dapat diakses dari luar dengan aman.

---

## 🏗️ Lingkungan & Spesifikasi (Environment)

| Komponen            | Detail Spesifikasi                                      |
| ------------------- | ------------------------------------------------------- |
| **Hardware Host**   | Laptop Win 10 LTSC IoT, AMD Ryzen 5 4500U, RAM 16GB     |
| **Hypervisor**      | VMware Workstation Pro                                  |
| **OS VM Rentan**    | Metasploitable 2 (Ubuntu 8.04 - Hardy)                  |
| **OS VM Kuat**      | Rocky Linux 10 (RHEL Family)                            |
| **Layanan Utama**   | WordPress CMS (Dockerized)                              |

---

## 🧠 Filosofi Pemisahan: VM1 vs VM2

Mengapa kita membedakan pendekatan keamanan pada kedua VM ini? Dan mengapa alat forensik dasar seperti `tcpdump`, `AIDE`, dan `auditd` **tidak** diutamakan di VM2?

### 🎯 VM1: Metasploitable2 (Fokus Forensik & Honeypot)
VM ini sengaja dibiarkan memiliki banyak celah keamanan (*vulnerable-by-design*). Tujuannya adalah membiarkan *Attacker* menembus sistem agar *Blue Team* bisa mempelajari cara kerja eksploitasi, pergerakan lateral, dan pemasangan *backdoor*. 
Oleh karena itu, kita sangat bergantung pada alat forensik manual di level Sistem Operasi:
- **`tcpdump`**: Untuk menangkap *raw packet* (pcap) dari *payload exploit* yang dikirim.
- **`auditd`**: Untuk merekam secara diam-diam *command* jahat apa saja yang diketik oleh *hacker* setelah berhasil mendapatkan *shell*.
- **`AIDE`**: Untuk mengetahui file biner atau konfigurasi apa saja yang dirusak/disisipi *malware*.

### 🛡️ VM2: Rocky Linux 10 (Fokus Active Defense & Pencegahan)
VM ini merepresentasikan server *production* modern dengan konsep **Defense in Depth** (Pertahanan Berlapis). Tujuannya bukan untuk melihat *hacker* mengacak-acak sistem, melainkan **memblokir mereka sejauh mungkin sebelum menyentuh sistem operasi**.
Oleh karena itu, alat forensik OS manual (`tcpdump`/`auditd`) menjadi kurang krusial di sini. Sebagai gantinya, kita berinvestasi pada pertahanan aktif dan cerdas:
- **Lapis 1 (DNS/Edge):** **Cloudflare** memblokir *bot* dan *tools* pentest otomatis (*Bot Fight Mode* / WAF Rules).
- **Lapis 2 (Application/Layer 7):** **SafeLine WAF** menganalisis secara semantik setiap *request* HTTP untuk memblokir injeksi kode (SQLi, XSS) sebelum mencapai *container* WordPress.
- **Lapis 3 (Network/Behavioral):** **CrowdSec** memantau anomali log dan secara otomatis menjatuhkan larangan (*ban*) pada IP *attacker* di level *firewall* (Nftables) jika ada indikasi *bruteforce* atau *scanning*.
- **Lapis 4 (OS/Container):** **Docker Security Opts** dan Hardening OS (hasil audit **Lynis**) membatasi pergerakan *hacker* seandainya mereka secara ajaib berhasil menembus 3 lapis pelindung di atas.

---

## 🌐 Topologi Jaringan & Skema IP

Simulasi dilakukan dalam satu laptop host menggunakan skema jaringan internal yang dapat diekspos melalui *port forwarding* atau terowongan jaringan untuk akses eksternal.

### Pemetaan Alamat IP & Domain
- **Metasploitable2 (VM1):** `192.168.86.128` (Akses langsung via LAN untuk eksploitasi).
- **Rocky Linux 10 (VM2):** `192.168.86.129` (Di-proxy secara aman melalui Cloudflare ke `defend.azharmtq.my.id`).
- **Adapter Mode:** Bridged / NAT.

---

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

---

## 🎯 Tujuan Akhir Laporan
1.  **Sisi Forensik (VM1):** Menyusun *timeline* serangan yang akurat (Kapan, Siapa, Lewat mana, Apa dampaknya) menggunakan log dari `auditd` dan `tcpdump`.
2.  **Sisi Hardening (VM2):** Mendemonstrasikan efektivitas arsitektur **Defense in Depth** dalam menggagalkan AI *Attacker* (contoh: Agent Zero) dan *tools* pentest otomatis sebelum mereka berhasil menembus lapisan aplikasi.

---

## 🔗 Lihat Juga

- [[SOP-Setup-Lingkungan-Simulasi|Master SOP Setup Lingkungan]]
- [[network-security|Dasar Keamanan Jaringan (OSI Layer)]]

---

*Simulasi Keamanan Siber | Arsitektur & Konsep · Blue Team Matriks*
