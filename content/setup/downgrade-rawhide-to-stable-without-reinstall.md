---
title: "Turun dari Fedora Rawhide → Stable Tanpa Reinstall"
tags:
  - setup
aliases:
  - "downgrade-rawhide-to-stable-without-reinstall"
created: "2026-07-06"
updated: "2026-07-06"
status: active
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
