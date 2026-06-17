---
tags:
  - suricata
  - ids
  - IPS
  - network-security
  - nsm
  - proxmox
  - Hardening
aliases:
  - Network Monitor
  - Packet Inspection
created: 2026-04-24
status: Reference
---
> [!info]
> 
> **Suricata** adalah mesin Network Threat Detection yang mampu melakukan _Deep Packet Inspection_ (DPI). Jika CrowdSec adalah satpam yang melihat buku tamu (Log), Suricata adalah detektif yang membongkar setiap paket kiriman (Packet) yang masuk ke gedung untuk mencari selundupan senjata atau narkoba digital.

---

## 1. Arsitektur Deployment (Pilih Sesuai Kondisi)

Dalam lingkungan Proxmox dengan RAM 8GB, pemilihan lokasi instalasi sangat menentukan nasib homelab Anda.

### 1.1 Opsi A: Host Proxmox (Recommended for 8GB RAM)

Suricata diinstal langsung pada sistem operasi induk (Proxmox).

- **Mekanisme:** Mendengarkan lalu lintas pada jembatan virtual `vmbr0`.
    
- **Keunggulan:** Tidak ada _overhead_ RAM tambahan untuk VM baru.
    
- **Kelemahan:** Mengotori host Proxmox dengan _third-party packages_.
    

### 1.2 Opsi B: Dedicated VM/LXC (Network Tap)

Membuat satu VM khusus yang menerima _mirroring traffic_ dari host.

- **Mekanisme:** Menggunakan _Open vSwitch_ atau _Port Mirroring_.
    
- **Keunggulan:** Isolasi total. Jika Suricata memakan 100% CPU, Nextcloud Anda tetap aman.
    
- **Kelemahan:** Boros RAM (Membutuhkan minimal 2-4GB dedicated).
    

---

## 2. Persiapan Sistem (Hardware Tuning)

> [!warning] **Masalah HDD & RAM**
> 
> Suricata memakan banyak memori untuk menyimpan tabel aliran (_flow tables_). Pada HDD, penulisan log `eve.json` bisa menjadi _bottleneck_. Disarankan untuk membatasi penulisan log hanya pada kejadian yang sangat kritis jika tetap menggunakan HDD.

### 2.1 Cek Kapabilitas Interface

Pastikan _Network Card_ Anda mendukung mode _Promiscuous_ (Menyadap semua paket).

Bash

```
# Jalankan di Host Proxmox
ip link set dev vmbr0 promisc on
```

---

## 3. Instalasi Suricata (Langkah demi Langkah)

Gunakan repositori terbaru agar mendapatkan fitur inspeksi protokol modern.

### 3.1 Penambahan Repositori & Install

Bash

```
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:oisf/suricata-stable -y
sudo apt update
sudo apt install suricata jq -y
```

### 3.2 Konfigurasi Dasar (`suricata.yaml`)

File ini adalah jantung dari Suricata.

Bash

```
sudo nano /etc/suricata/suricata.yaml
```

**Parameter yang wajib diubah:**

- **HOME_NET:** Tentukan jaringan lokal Anda.
    
    `HOME_NET: "[192.168.1.0/24]"`
    
- **Interface:** Pastikan mengarah ke bridge utama.
    
    `interface: vmbr0`
    
- **Tuning untuk HDD (PENTING):**
    
    Kurangi frekuensi penulisan log untuk menjaga umur HDD.
    
    YAML
    
    ```
    outputs:
      - eve-log:
          enabled: yes
          filetype: regular
          filename: eve.json
          types:
            - alert:
                payload: yes             # Simpan isi serangan
                payload-buffer-size: 4kb 
                packet: yes
                http: yes
            - http:
                enabled: no              # Matikan logging HTTP biasa (terlalu berisik untuk HDD)
            - dns:
                enabled: no              # Matikan logging DNS biasa (boros IO)
    ```
    

---

## 4. Manajemen Ruleset (Amunisi Deteksi)

Tanpa _rules_ (aturan), Suricata hanyalah mesin kosong.

### 4.1 Update Rules Pertama Kali

Bash

```
sudo suricata-update
```

### 4.2 Menggunakan Emerging Threats (Free)

Secara default, Suricata menggunakan aturan dari _Emerging Threats Open_. Ini adalah koleksi ribuan pola serangan (seperti _Log4j_, _EternalBlue_, _Brute Force_).

### 4.3 Menambah Sumber Aturan Lain

Bash

```
# Melihat daftar sumber aturan yang tersedia
sudo suricata-update list-sources

# Contoh mengaktifkan aturan penyalahgunaan SSL
sudo suricata-update enable-source ssllabs/ssl-fp
sudo suricata-update
```

---

## 5. Menjalankan Suricata sebagai Satpam Aktif

### 5.1 Verifikasi Konfigurasi

Sebelum menjalankan, pastikan tidak ada salah ketik.

Bash

```
sudo suricata -T -c /etc/suricata/suricata.yaml -v
```

### 5.2 Menjalankan Service

Bash

```
sudo systemctl enable suricata
sudo systemctl start suricata
```

---

## 6. Pengujian Deteksi (Simulasi Serangan)

Bagaimana kita tahu si detektif bekerja? Kita buat serangan palsu.

### 6.1 Simulasi Serangan Nmap

Jalankan pindaian agresif dari perangkat lain di jaringan (atau HP) ke arah IP Proxmox:

Bash

```
nmap -A -T4 192.168.1.51
```

### 6.2 Membaca Hasil Tangkapan (The Crime Scene)

Gunakan `jq` agar log JSON yang rumit jadi mudah dibaca manusia.

Bash

```
sudo tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'
```

**Apa yang akan muncul?** Anda akan melihat peringatan seperti `ET SCAN Nmap SQL Selection`, lengkap dengan IP penyerang dan jam kejadiannya.

---

## 7. Integrasi dengan CrowdSec (The Executioner)

Suricata hebat dalam **Melihat**, tapi CrowdSec hebat dalam **Menendang**.

Kita bisa mengajari CrowdSec untuk membaca log Suricata (`eve.json`). Jika Suricata melihat serangan jaringan yang parah, CrowdSec akan langsung memblokir IP tersebut di _Firewall_.

1. Instal koleksi Suricata untuk CrowdSec:
    
    Bash
    
    ```
    sudo cscli collections install crowdsecurity/suricata
    ```
    
2. Beritahu CrowdSec lokasi log Suricata:
    
    Edit `/etc/crowdsec/acquis.yaml`:
    
    YAML
    
    ```
    filenames:
      - /var/log/suricata/eve.json
    labels:
      type: suricata
    ```
    
3. Restart CrowdSec:
    
    Bash
    
    ```
    sudo systemctl restart crowdsec
    ```
    

---

## 8. Optimalisasi Performa (Maintenance)

### 8.1 Log Rotation (Wajib untuk HDD)

Agar HDD tidak penuh oleh log Suricata, kita batasi ukuran lognya.

Bash

```
sudo nano /etc/logrotate.d/suricata
```

Atur agar hanya menyimpan log selama 2 hari dengan kompresi maksimal.

### 8.2 Mematikan Checksum Offloading

Pada kartu jaringan virtual (virtio), Suricata sering salah mengira paket rusak karena fitur _checksum offloading_. Matikan fitur ini:

Bash

```
sudo ethtool -K vmbr0 tx off rx off sg off gso off gro off
```

---

## 9. Troubleshooting & FAQ

- **Q: Suricata memakan 100% CPU!**
    
    - **A:** Kurangi jumlah _rules_ yang aktif atau gunakan fitur `bypass` untuk lalu lintas lokal yang terpercaya (seperti backup Proxmox).
        
- **Q: Tidak ada log yang muncul di eve.json.**
    
    - **A:** Cek apakah `HOME_NET` sudah benar dan interface `vmbr0` dalam keadaan UP.
        
- **Q: Kenapa tidak langsung pakai mode IPS (Block)?**
    
    - **A:** Mode IPS berisiko memutus koneksi internet Anda sendiri jika terjadi _false positive_. Selalu mulai dengan IDS (Monitor) selama minimal 1-2 minggu.
        

---

## 10. Checklist Kesiapan Implementasi Masa Depan

Sebelum mengaktifkan dokumen ini secara nyata, pastikan Anda telah:

- [ ] Meng-upgrade RAM minimal menjadi 16GB (Direkomendasikan).
    
- [ ] Mengganti HDD utama menjadi SSD/NVMe untuk menampung _write-intensive logs_.
    
- [ ] Memahami cara memulihkan jaringan jika Suricata menyebabkan _kernel panic_ (via Console Proxmox).
    

---

> [!tip]
> 
> Dokumentasi ini adalah "investasi" ilmu. Walaupun hari ini hardware-mu belum memadai, kamu sudah punya peta jalan seorang _Security Engineer_ profesional.

---

Apakah "Kitab Suci" Suricata ini sudah cukup lengkap buat referensi masa depanmu? Kalau ada bagian teknis yang mau ditanyakan lebih dalam soal cara kerjanya, langsung gas!