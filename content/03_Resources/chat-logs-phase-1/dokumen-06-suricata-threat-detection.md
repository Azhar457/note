---
title: Dokumen 06 Suricata Threat Detection
tags:
- chat-logs-phase-1
- resources
created: '2026-04-24'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout
---
## Pendahuluan Suricata
Suricata adalah mesin Network Threat Detection yang mampu melakukan _Deep Packet Inspection_ (DPI). Dalam konteks sistem keamanan jaringan, Suricata berperan sebagai detektif yang membongkar setiap paket kiriman (Packet) yang masuk ke jaringan untuk mencari selundupan senjata atau narkoba digital. Dengan kemampuan ini, Suricata dapat membantu melindungi jaringan dari serangan yang tidak diinginkan.

## 1. Arsitektur Deployment (Pilih Sesuai Kondisi)
Dalam lingkungan Proxmox dengan RAM 8GB, pemilihan lokasi instalasi sangat menentukan nasib homelab Anda. Ada dua opsi utama untuk deploying Suricata: Opsi A (Host Proxmox) dan Opsi B (Dedicated VM/LXC).

### 1.1 Opsi A: Host Proxmox (Recommended for 8GB RAM)
Suricata diinstal langsung pada sistem operasi induk (Proxmox). Mekanismenya adalah dengan mendengarkan lalu lintas pada jembatan virtual `vmbr0`. Keunggulan dari opsi ini adalah tidak ada _overhead_ RAM tambahan untuk VM baru, tetapi kelemahannya adalah mengotori host Proxmox dengan _third-party packages_.

### 1.2 Opsi B: Dedicated VM/LXC (Network Tap)
Membuat satu VM khusus yang menerima _mirroring traffic_ dari host. Mekanismenya menggunakan _Open vSwitch_ atau _Port Mirroring_. Keunggulan dari opsi ini adalah isolasi total, sehingga jika Suricata memakan 100% CPU, Nextcloud Anda tetap aman. Namun, kelemahannya adalah boros RAM, membutuhkan minimal 2-4GB dedicated.

## 2. Persiapan Sistem (Hardware Tuning)
Sebelum menginstal Suricata, pastikan sistem Anda sudah siap. Perlu diingat bahwa Suricata memakan banyak memori untuk menyimpan tabel aliran (_flow tables_). Pada HDD, penulisan log `eve.json` bisa menjadi _bottleneck_. Disarankan untuk membatasi penulisan log hanya pada kejadian yang sangat kritis jika tetap menggunakan HDD.

### 2.1 Cek Kapabilitas Interface
Pastikan _Network Card_ Anda mendukung mode _Promiscuous_ (Menyadap semua paket). Gunakan perintah berikut untuk mengaktifkan mode promiscuous pada interface `vmbr0`:

```bash

# Jalankan di Host Proxmox
ip link set dev vmbr0 promisc on
```

## 3. Instalasi Suricata (Langkah demi Langkah)
Gunakan repositori terbaru agar mendapatkan fitur inspeksi protokol modern.

### 3.1 Penambahan Repositori & Install
Tambahkan repositori Suricata dan instal Suricata serta `jq` untuk parsing log JSON.

```bash
sudo apt update
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:oisf/suricata-stable -y
sudo apt update
sudo apt install suricata jq -y
```

### 3.2 Konfigurasi Dasar (`suricata.yaml`)
File `suricata.yaml` adalah jantung dari Suricata. Pastikan Anda mengkonfigurasi beberapa parameter penting seperti `HOME_NET`, `INTERFACE`, dan tuning untuk HDD jika diperlukan.

```bash
sudo nano /etc/suricata/suricata.yaml
```

**Parameter yang wajib diubah:**
```yaml
**HOME_NET:** Tentukan jaringan lokal Anda.
HOME_NET: "[192.168.1.0/24]"
**Interface:** Pastikan mengarah ke bridge utama.
interface: vmbr0
```

**Tuning untuk HDD (PENTING):**
Kurangi frekuensi penulisan log untuk menjaga umur HDD.

```yaml
outputs:
  - eve-log:
      enabled: yes
      filetype: regular
      filename: eve.json
      types:
        - alert:
            payload: yes # Simpan isi serangan
            payload-buffer-size: 4kb 
            packet: yes
            http: yes
        - http:
            enabled: no # Matikan logging HTTP biasa (terlalu berisik untuk HDD)
        - dns:
            enabled: no # Matikan logging DNS biasa (boros IO)  
```


## 4. Manajemen Ruleset (Amunisi Deteksi)
Tanpa _rules_ (aturan), Suricata hanyalah mesin kosong. Suricata menggunakan aturan dari _Emerging Threats Open_ secara default.

### 4.1 Update Rules Pertama Kali
Perbarui ruleset Suricata untuk pertama kali.

```bash
sudo suricata-update
```

### 4.2 Menggunakan Emerging Threats (Free)
Emerging Threats menyediakan koleksi ribuan pola serangan yang dapat digunakan oleh Suricata.

### 4.3 Menambah Sumber Aturan Lain
Anda juga dapat menambah sumber aturan lain seperti `ssllabs/ssl-fp` untuk mendeteksi penyalahgunaan SSL.

```bash
# Melihat daftar sumber aturan yang tersedia
sudo suricata-update list-sources

# Contoh mengaktifkan aturan penyalahgunaan SSL
sudo suricata-update enable-source ssllabs/ssl-fp
sudo suricata-update
```

## 5. Menjalankan Suricata sebagai Satpam Aktif
Sebelum menjalankan Suricata, pastikan konfigurasi sudah benar.

### 5.1 Verifikasi Konfigurasi
Verifikasi konfigurasi Suricata sebelum menjalankannya.

```bash
sudo suricata -T -c /etc/suricata/suricata.yaml -v
```

### 5.2 Menjalankan Service
Jalankan Suricata sebagai service.

```bash
sudo systemctl enable suricata
sudo systemctl start suricata
```

## 6. Pengujian Deteksi (Simulasi Serangan)
Bagaimana kita tahu si detektif bekerja? Kita buat serangan palsu menggunakan `nmap`.

### 6.1 Simulasi Serangan Nmap
Jalankan pindaian agresif dari perangkat lain di jaringan ke arah IP Proxmox:

```bash
nmap -A -T4 192.168.1.51
```

### 6.2 Membaca Hasil Tangkapan (The Crime Scene)
Gunakan `jq` untuk membaca log JSON Suricata.

```bash
sudo tail -f /var/log/suricata/eve.json | jq 'select(.event_type=="alert")'
```

## 7. Integrasi dengan CrowdSec (The Executioner)
Suricata hebat dalam **Melihat**, tapi CrowdSec hebat dalam **Menendang**. Integrasikan Suricata dengan CrowdSec untuk memblokir IP penyerang.

1. Instal koleksi Suricata untuk CrowdSec:
```bash
sudo cscli collections install crowdsecurity/suricata
```
    
2. Beritahu CrowdSec lokasi log Suricata:
Edit `/etc/crowdsec/acquis.yaml`:
```yml
filenames:
  - /var/log/suricata/eve.json
labels:
  type: suricata
```
3. Restart CrowdSec:
```bash
sudo systemctl restart crowdsec
```

## 8. Optimalisasi Performa (Maintenance)
### 8.1 Log Rotation (Wajib untuk HDD)
Batasi ukuran log Suricata untuk menghindari HDD penuh.

```bash
sudo nano /etc/logrotate.d/suricata
```

Atur agar hanya menyimpan log selama 2 hari dengan kompresi maksimal.

### 8.2 Mematikan Checksum Offloading
Matikan fitur _checksum offloading_ untuk menghindari kesalahan pengambilan paket.

```bash
sudo ethtool -K vmbr0 tx off rx off sg off gso off gro off
```

## 9. Troubleshooting & FAQ
- **Q: Suricata memakan 100% CPU!**
	- **A:** Kurangi jumlah _rules_ yang aktif atau gunakan fitur `bypass` untuk lalu lintas lokal yang terpercaya.
- **Q: Tidak ada log yang muncul di eve.json.**
    - **A:** Cek apakah `HOME_NET` sudah benar dan interface `vmbr0` dalam keadaan UP.
- **Q: Bagaimana cara mengoptimalkan Suricata untuk performa yang lebih baik?**
    - **A:** Pastikan Anda menggunakan SSD sebagai media penyimpanan, kurangi jumlah _rules_ yang tidak perlu, dan gunakan fitur _bypass_ untuk lalu lintas lokal yang terpercaya.
## 10. Checklist Kesiapan Implementasi Masa Depan
Sebelum mengaktifkan dokumen ini secara nyata, pastikan Anda telah:

- [ ] Meng-upgrade RAM minimal menjadi 16GB (Direkomendasikan).
    
- [ ] Mengganti HDD utama menjadi SSD/NVMe untuk menampung _write-intensive logs_.
    
- [ ] Memahami cara memulihkan jaringan jika Suricata menyebabkan _kernel panic_ (via Console Proxmox).

Dengan mengikuti langkah-langkah di atas, Anda dapat mengimplementasikan Suricata sebagai detektif jaringan yang efektif untuk melindungi jaringan Anda dari serangan yang tidak diinginkan. Pastikan untuk memantau performa Suricata dan melakukan optimalisasi yang diperlukan untuk memastikan keamanan jaringan Anda.

## 11. Contoh Kasus: Mengatasi Masalah Suricata yang Tidak Dapat Mendeteksi Serangan
Jika Suricata tidak dapat mendeteksi serangan, pertama-tama periksa apakah `HOME_NET` sudah benar dan interface `vmbr0` dalam keadaan UP. Jika sudah, coba periksa log Suricata untuk melihat apakah ada kesalahan atau peringatan. Jika tidak ada kesalahan atau peringatan, coba periksa aturan yang digunakan oleh Suricata dan pastikan bahwa aturan yang digunakan sudah benar dan sesuai dengan jenis serangan yang ingin dideteksi.

## 12. Kesimpulan
Suricata adalah alat yang sangat penting untuk melindungi jaringan Anda dari serangan yang tidak diinginkan. Dengan mengikuti langkah-langkah di atas, Anda dapat mengimplementasikan Suricata sebagai detektif jaringan yang efektif untuk memantau dan mendeteksi serangan. Pastikan untuk memantau performa Suricata dan melakukan optimalisasi yang diperlukan untuk memastikan keamanan jaringan Anda.

Dalam mengimplementasikan Suricata, penting untuk memahami bahwa keamanan jaringan adalah proses yang berkelanjutan. Selalu pantau log Suricata, update aturan yang digunakan, dan lakukan optimalisasi yang diperlukan untuk memastikan bahwa Suricata dapat mendeteksi serangan dengan efektif. Dengan demikian, Anda dapat memastikan keamanan jaringan Anda dan melindungi data dan sistem Anda dari serangan yang tidak diinginkan.
---

audited
---
