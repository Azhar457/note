---
title: "Day 1"
tags:
  - original
aliases:
  - "day-1"
created: "2026-06-06"
updated: "2026-07-07"
status: Ongoing
cssclasses: ""
---

# Catatan Hardening Sistem Linux: Log Hari Ke-1

Dokumentasi ini merangkum langkah-langkah praktis dan konfigurasi teknis yang dilakukan pada **Hari Ke-1** untuk melakukan pengerasan sistem (_system hardening_) pada infrastruktur server lokal. Pengerasan sistem bertujuan untuk memperkecil permukaan serangan (_attack surface_) dengan menonaktifkan layanan yang tidak diperlukan, memperketat akses administratif, dan mengotomatisasi pemblokiran serangan brute force.

> [!important] Topologi Lab & Informasi IP Address
>
> - **Ubuntu Host (Ansible Control Node):** `192.168.130.128` (Berfungsi sebagai server pengendali otomatisasi)
> - **Rocky Linux 9 (Managed Node Target):** `192.168.130.129` (Virtual Machine target yang akan dikeraskan keamanannya, login user: `rocky`)

---

## 🛠️ Fase 1: Audit Keamanan Awal Menggunakan Lynis

Sebelum melakukan perubahan konfigurasi, kita harus memiliki indikator dasar (_baseline_) mengenai tingkat keamanan sistem saat ini. Untuk kebutuhan ini, kita menggunakan **Lynis**, sebuah alat bantu audit keamanan open-source untuk sistem berbasis UNIX (Linux, macOS, BSD).

### 1.1 Instalasi Lynis

Lynis dapat diinstal secara langsung melalui manajer paket bawaan sistem operasi.

```bash
# Untuk Ubuntu/Debian:
sudo apt update && sudo apt install lynis -y

# Untuk Rocky Linux / RHEL (membutuhkan repositori EPEL):
sudo dnf install epel-release -y
sudo dnf install lynis -y
```

### 1.2 Menjalankan Audit Sistem

Jalankan audit keamanan penuh secara cepat tanpa interaksi konfirmasi manual menggunakan opsi `--quick`:

```bash
sudo lynis audit system --quick
```

Lynis akan memindai ratusan kategori mulai dari bootloader, sistem berkas, layanan jaringan, konfigurasi kernel, hingga kebijakan kata sandi. Setelah pemindaian selesai, Lynis akan memberikan skor indeks pengerasan (_hardening index_) dan daftar rekomendasi tindakan.

### 1.3 Menganalisis Log Rekomendasi Lynis

Untuk melihat saran perbaikan (_suggestions_) secara spesifik, saring berkas log atau data laporan menggunakan perintah berikut:

```bash
# Menyaring kata kunci "Suggestion" langsung dari log audit
sudo grep "Suggestion" /var/log/lynis.log | head -n 30

# Alternatif: Menyaring kata kunci "suggestion" dari file data terstruktur
sudo cat /var/log/lynis-report.dat | grep "suggestion" | head -n 20
```

Rekomendasi ini akan memandu kita dalam melakukan prioritas perbaikan keamanan (misalnya: mematikan port yang tidak digunakan, menambahkan banner warning SSH, atau memperketat hak akses file konfig).

---

## 🔒 Fase 2: Penguncian Layanan SSH (SSH Lockdown)

Secure Shell (SSH) adalah gerbang masuk utama ke server. Membiarkan konfigurasi SSH pada status bawaan (_default_) sangat berisiko terhadap serangan brute force dan eksploitasi credential.

### 2.1 Membuat Cadangan Konfigurasi

Sebelum memodifikasi berkas konfigurasi kritis, selalu buat cadangan (_backup_) untuk mempermudah pemulihan (_rollback_) jika terjadi kesalahan konfigurasi.

```bash
sudo cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup.$(date +%F)
```

### 2.2 Mengedit Konfigurasi SSH Daemon

Buka berkas konfigurasi dengan editor teks:

```bash
sudo nano /etc/ssh/sshd_config
```

Masukkan atau sesuaikan direktif keamanan berikut di dalam berkas:

```text
# --- Hardening Core SSH Daemon ---

# Port bawaan sementara tetap 22 untuk validasi awal, ganti ke port non-standar nanti jika semua akses sudah stabil
Port 22

# Blokir login langsung menggunakan user root. Administrator wajib masuk menggunakan user biasa lalu melakukan 'sudo'
PermitRootLogin no

# Nonaktifkan autentikasi berbasis kata sandi biasa untuk mencegah serangan tebak sandi
PasswordAuthentication no

# Wajibkan autentikasi berbasis kunci publik/privat (SSH Keypair)
PubkeyAuthentication yes

# Nonaktifkan X11 forwarding karena kita tidak membutuhkan antarmuka grafis GUI melalui SSH
X11Forwarding no

# Batasi jumlah percobaan login yang gagal dalam satu sesi koneksi sebelum server memutuskan koneksi secara paksa
MaxAuthTries 3

# Atur interval deteksi aktivitas klien (dalam detik) dan batas maksimum toleransi ketidakaktifan
ClientAliveInterval 300
ClientAliveCountMax 2

# Batasi waktu tunggu login tanpa autentikasi sebelum server memutus koneksi
LoginGraceTime 60

# Terapkan Whitelist User. HANYA user 'rocky' yang diizinkan melakukan SSH ke server ini
AllowUsers rocky
```

### 2.3 Menerapkan Perubahan dan Pengujian Sesi

Terapkan perubahan dengan memuat ulang layanan SSH:

```bash
sudo systemctl restart sshd
```

> [!caution] Aturan Emas Pengujian SSH Hardening
> **JANGAN PERNAH** menutup sesi SSH aktif Anda setelah merestart layanan `sshd`. Buka jendela terminal baru atau tab baru, lalu coba lakukan koneksi ke server dari mesin Ansible Control Anda untuk menguji apakah akses SSH Key masih berfungsi:
>
> ```bash
> ssh rocky@192.168.130.129
> ```
>
> Jika koneksi baru berhasil masuk, Anda aman untuk menutup sesi lama. Jika gagal, perbaiki konfigurasi melalui sesi aktif yang masih terbuka untuk menghindari terkunci dari luar (_locked out_).

---

## 🛡️ Fase 3: Pencegahan Brute Force Menggunakan Fail2ban

Untuk meminimalisir dampak serangan pemindaian otomatis, kita memasang **Fail2ban**. Fail2ban memantau log sistem (seperti `/var/log/secure` atau `/var/log/auth.log`) dan secara dinamis menambahkan aturan firewall (melalui iptables/firewalld) untuk memblokir alamat IP yang menunjukkan tanda-tanda serangan brute force.

### 3.1 Instalasi Fail2ban

```bash
# Untuk Rocky Linux 9:
sudo dnf install fail2ban -y

# Jalankan dan aktifkan layanan saat boot
sudo systemctl enable fail2ban --now
sudo systemctl status fail2ban
```

### 3.2 Konfigurasi Jail Lokal untuk SSH

Buat berkas konfigurasi lokal `/etc/fail2ban/jail.local` untuk mendefinisikan aturan pemblokiran spesifik SSH:

```bash
sudo tee /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
# Durasi pemblokiran IP penyerang (dalam detik) - 3600 detik = 1 Jam
bantime = 3600

# Rentang waktu pengamatan log untuk menghitung akumulasi kesalahan login
findtime = 600

# Batas maksimum toleransi kegagalan login dalam rentang findtime sebelum diblokir
maxretry = 3

# Menggunakan systemd journal sebagai backend pemantauan log
backend = systemd

[sshd]
enabled = true
port = ssh
filter = sshd
logpath = /var/log/secure
maxretry = 3
bantime = 3600
EOF
```

Terapkan konfigurasi baru dengan memuat ulang Fail2ban:

```bash
sudo systemctl restart fail2ban
```

Verifikasi status aturan pemblokiran SSH dengan perintah:

```bash
sudo fail2ban-client status sshd
```

---

## 🔑 Fase 4: Kebijakan Autentikasi PAM & Kualitas Kata Sandi

Pluggable Authentication Modules (PAM) adalah mekanisme integrasi autentikasi pada sistem operasi Linux. Kita akan mengonfigurasi batas kegagalan masuk secara lokal (_account lockout_) dan ketentuam kompleksitas kata sandi minimum.

### 4.1 Mengaktifkan Fitur Keamanan PAM

Gunakan utilitas `authselect` untuk mengelola konfigurasi profil PAM bawaan sistem secara aman:

```bash
# Periksa profil aktif saat ini
sudo authselect current

# Pilih profil SSSD dengan pemaksaan dan aktifkan fitur faillock serta pwhistory
sudo authselect select sssd --force
sudo authselect enable-feature with-faillock
sudo authselect enable-feature with-pwhistory
sudo authselect apply-changes
```

### 4.2 Mengonfigurasi Faillock (Account Lockout Policy)

Edit berkas konfigurasi `/etc/security/faillock.conf` untuk menetapkan aturan penguncian akun setelah kegagalan berturut-turut:

```bash
sudo nano /etc/security/faillock.conf
```

Sesuaikan nilai-nilai berikut:

```text
# Kunci akun setelah 5 kali gagal masuk
deny = 5

# Rentang waktu akumulasi kegagalan (dalam detik) - 900 detik = 15 Menit
fail_interval = 900

# Durasi penguncian akun sebelum otomatis terbuka kembali (dalam detik) - 600 detik = 10 Menit
unlock_time = 600

# Terapkan juga aturan penguncian ini pada akun root
even_deny_root = true
```

### 4.3 Mengonfigurasi Kualitas Kata Sandi (`pwquality`)

Untuk memastikan pengguna tidak menggunakan kata sandi yang mudah ditebak, edit berkas `/etc/security/pwquality.conf`:

```bash
sudo nano /etc/security/pwquality.conf
```

Ubah nilainya menjadi konfigurasi standar industri berikut:

```text
# Panjang minimum kata sandi adalah 12 karakter
minlen = 12

# Minimal harus mengandung 3 jenis kelas karakter yang berbeda (Huruf besar, huruf kecil, angka, simbol)
minclass = 3

# Maksimum pengulangan karakter berturut-turut yang diizinkan
maxrepeat = 2

# Lakukan pengecekan kata sandi terhadap informasi pengguna di berkas GECOS (seperti nama asli)
gecoscheck = 1
```

---

## 📝 Kesimpulan Hasil Hari Ke-1

- **SSH:** Teliti dikonfigurasi menggunakan kunci publik, melarang root login, dan dibatasi hanya untuk user `rocky`.
- **Fail2ban:** Aktif memantau upaya brute force SSH dan akan memblokir alamat IP penyerang selama 1 jam jika gagal 3 kali dalam rentang 10 menit.
- **PAM:** Mengunci akun secara otomatis jika salah sandi 5 kali, dan mewajibkan kata sandi baru memiliki panjang minimal 12 karakter dengan kompleksitas tinggi.
- **Konektivitas:** Diuji dan diverifikasi bahwa sesi remote Ansible dari control node tetap berfungsi secara normal dengan protokol SSH Key yang dikeraskan.
