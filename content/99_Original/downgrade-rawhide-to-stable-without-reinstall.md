---
title: "Turun dari Fedora Rawhide → Stable Tanpa Reinstall"
tags:
  - setup
  - original
aliases:
  - "downgrade-rawhide-to-stable-without-reinstall"
created: "2026-07-06"
updated: "2026-07-07"
status: Ongoing
---

# Turun dari Fedora Rawhide → Stable Tanpa Reinstall

**Host:** Ryzen 5 4500U / 14GB RAM  
**Dari:** Fedora 45 Rawhide (kernel `7.2.0-0.rc1.fc45`)  
**Ke:** Fedora 44 Stable (kernel `7.0.14-201.fc44`)  
**Tanggal:** 2026-07-06

> **Peringatan:** Metode ini hanya bekerja jika perbedaan versi masih _satu major release_ (45→44).  
> Lompat 2+ release (F45→F43) bakal hancur karena Python/GLIBC dependency graph.

---

## Step-by-step

### 1. Matikan Repo Rawhide, Aktifkan Repo Stable

```bash
sudo dnf config-manager setopt rawhide.enabled=0
sudo dnf config-manager setopt rawhide-source.enabled=0
sudo dnf config-manager setopt fedora.enabled=1
sudo dnf config-manager setopt updates.enabled=1
```

### 2. Paksa Releasever ke 44

```bash
echo "releasever=44" | sudo tee -a /etc/dnf/dnf.conf
```

Verifikasi: `cat /etc/dnf/dnf.conf` — harus ada `releasever=44` di akhir.

### 3. Bersihkan Cache DNF

```bash
sudo dnf clean all
```

### 4. Coba Init Distro-Sync (kadang langsung berhasil)

```bash
sudo dnf --releasever=44 distro-sync --allowerasing --disablerepo="rpmfusion*" --best
```

**Kalau gagal error "Package X has no upgrade candidate"** → lanjut step 5.

### 5. Hapus Package Bermasalah (Conflict Blockers)

Identifikasi: `dnf check`

Yang gue hapus waktu itu:

```bash
# Paket lama yang ngeblock downgrade
sudo rpm -e --nodeps --justdb fmt11 openssl3-libs libpmem libpmemobj
sudo dnf remove noopenh264 --allowerasing
```

> `--justdb` = hapus dari RPM database aja, file fisik tetap ada.  
> AMAN untuk `libpmem*` karena gak dipakai runtime sistem.

### 6. Reinstall GPG Keys + Repo Files (biar pas versi 44)

```bash
sudo dnf reinstall fedora-repos fedora-gpg-keys --allowerasing --releasever=44
sudo dnf install --releasever=44 \
  https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm \
  https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm
```

### 7. Matikan Repo RPM Fusion Rawhide

```bash
sudo dnf config-manager setopt \
  rpmfusion-free.enabled=0 \
  rpmfusion-free-rawhide.enabled=0 \
  rpmfusion-nonfree.enabled=0 \
  rpmfusion-nonfree-rawhide.enabled=0 \
  rpmfusion-nonfree-nvidia-driver.enabled=0 \
  rpmfusion-nonfree-steam.enabled=0
```

### 8. Jalankan Distro-Sync Final

```bash
sudo dnf --releasever=44 distro-sync --allowerasing --disablerepo="rpmfusion*" --best
```

Ini yang mendowngrade ~2000+ package dari fc45 → fc44. Proses ~5-10 menit.

### 9. Install Ulang RPM Fusion

Setelah distro-sync selesai, enable repo fusion yang bener:

```bash
sudo dnf config-manager setopt \
  rpmfusion-free.enabled=1 \
  rpmfusion-nonfree.enabled=1
```

### 10. Fix openh264 Conflict

```bash
sudo dnf swap noopenh264 openh264 --allowerasing
sudo dnf install openh264 --allowerasing
```

Ini resolve konflik antara `noopenh264` (dari Fedora) dan `openh264` (dari Cisco).

### 11. Verifikasi

```bash
cat /etc/os-release
# → VERSION="44 (Forty Four)", VERSION_ID=44

uname -r
# → 7.0.14-201.fc44.x86_64 (kernel stable)

rpm -qa | grep fc45 | wc -l
# → 9 (atau kurang — package non-kritis)

dnf check
# → 0 problem(s)
```

### 12. Hapus Kernel Rawhide Tersisa

```bash
sudo dnf remove kernel-core-7.2.0-0.rc1.260701g665159e24674.16.fc45.x86_64
```

> Kernel aktif (`uname -r`) tetap dipake sampai reboot. Setelah reboot, kernel fc44 jadi default.

### 13. Update /etc/os-release Manual

Kalau masih tampil versi lama setelah distro-sync (walaupun biasanya udah keupdate otomatis):

```bash
# Cek dulu
cat /etc/os-release

# Kalau masih salah, reinstall:
sudo dnf reinstall fedora-release fedora-release-common --releasever=44
```

---

## Hasil Akhir

| Item              | Sebelum               | Sesudah                |
| ----------------- | --------------------- | ---------------------- |
| **Release**       | Fedora 45 (Rawhide)   | Fedora 44 (Forty Four) |
| **Kernel**        | 7.2.0-0.rc1.fc45      | 7.0.14-201.fc44        |
| **Python**        | 3.15.0~b3             | 3.14.6                 |
| **Total package** | campuran fc44+fc45    | 2070 fc44, 9 fc45 sisa |
| **DNF check**     | 5+ problems           | 0 problems             |
| **Stability**     | Rolling / rawan break | Stable release         |

---

## Catatan Penting

- **Jangan lompat 2 release** — F45→F43 pasti gagal karena Python major version (3.15→3.13).
- **`--justdb`** cuma buat package yang udah pasti orphan/obsolete — cek dulu `dnf provides <lib>`.
- **9 package fc45 sisa** itu gak kritis: codec (x264, x265, vlc-plugins), appstream metadata, yama-ptrace. Biarin aja — nanti update `dnf distro-sync` selanjutnya bakal ke-replace.
- **RPM Fusion appstream** dari fc45 gak masalah — cuma data metadata buat GNOME Software.

---

## 🛠️ Analisis Teknis & Penjelasan Mekanisme Kerja

Proses downgrade sistem operasi Linux (khususnya distribusi berbasis RPM seperti Fedora/RHEL) adalah operasi tingkat rendah yang berisiko tinggi. Di bawah ini adalah penjelasan mendalam mengenai mengapa langkah-langkah di atas diperlukan dan bagaimana DNF mengelola dependensi selama proses transisi.

### 1. DNF Config-Manager & Prioritas Repositori

Perintah `dnf config-manager` digunakan untuk memodifikasi konfigurasi repositori secara cepat di `/etc/yum.repos.d/`. Menyetel `rawhide.enabled=0` dan mengaktifkan repositori stabil (`fedora` dan `updates`) memberi tahu manajer paket untuk tidak lagi melihat database paket fc45 (Rawhide) yang tidak stabil, melainkan mengarahkan indeks paket ke versi stabil fc44.

### 2. Memaksa Releasever via dnf.conf

Secara bawaan, DNF mendeteksi versi rilis sistem melalui paket `fedora-release`. Namun, selama proses downgrade, paket ini masih berada pada versi fc45. Dengan menuliskan `releasever=44` di `/etc/dnf/dnf.conf`, kita secara paksa mengesampingkan deteksi otomatis tersebut dan mengarahkan DNF untuk selalu mengunduh metadata dari cermin repositori Fedora 44.

### 3. Memahami Parameter Distro-Sync

Perintah utama yang melakukan pergeseran paket adalah:
`sudo dnf --releasever=44 distro-sync --allowerasing --disablerepo="rpmfusion*" --best`

- `distro-sync`: Menyelaraskan seluruh paket terinstal ke versi terbaru yang tersedia di repositori aktif (dalam hal ini, karena kita memaksa versi 44, manajer paket akan mendowngrade paket yang versinya lebih tinggi dari fc44).
- `--allowerasing`: Mengizinkan manajer paket untuk menghapus paket terinstal jika diperlukan untuk menyelesaikan konflik dependensi. Tanpa flag ini, transaksi akan langsung gagal jika ada paket fc45 yang tidak memiliki padanan fc44.
- `--best`: Memaksa DNF untuk hanya memilih kandidat paket terbaik (versi tertinggi yang cocok). Jika tidak dapat diselesaikan, transaksi akan dibatalkan.
- `--disablerepo="rpmfusion*"`: Mematikan repositori pihak ketiga selama proses inti untuk menghindari konflik library eksternal (seperti driver Nvidia atau codec media) yang seringkali mengacaukan dependency tree.

### 4. Risiko Penggunaan `--nodeps --justdb` pada RPM

Pada Step 5, digunakan perintah:
`sudo rpm -e --nodeps --justdb fmt11 openssl3-libs libpmem libpmemobj`
Ini adalah operasi bedah darurat pada database RPM:

- `--nodeps`: Menginstruksikan RPM untuk mengabaikan pemeriksaan ketergantungan paket. RPM akan menghapus entri paket meskipun ada paket lain yang membutuhkannya.
- `--justdb`: Hanya menghapus catatan registrasi paket dari database RPM lokal (`/var/lib/rpm/`), namun **TIDAK** menghapus berkas biner/library fisik (`.so`) dari sistem berkas.
- _Mengapa ini aman untuk kasus di atas?_ Karena library fisik tetap berada di `/usr/lib64/` sehingga program yang sedang berjalan tidak akan crash seketika karena kehilangan pustaka tautan dinamis. Setelah distro-sync berhasil dijalankan, DNF akan menginstal versi fc44 yang benar dan menimpa berkas fisik lama tersebut dengan aman.

### 5. Mengatasi Masalah openh264 vs noopenh264

Masalah lisensi paten Cisco membuat Fedora membagi library codec H.264 menjadi `noopenh264` (versi dummy tanpa kemampuan decode paten, bawaan repositori Fedora) dan `openh264` (versi fungsional dari repositori Cisco). Pertukaran paket menggunakan `dnf swap` memastikan bahwa browser dan pemutar media dapat memanggil akselerasi perangkat keras dengan benar pada versi Fedora yang baru diturunkan.
