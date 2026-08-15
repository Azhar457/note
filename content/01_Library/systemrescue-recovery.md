---
title: SystemRescue Recovery — SOP Pemulihan Boot, Filesystem & Data
tags:
  - systemrescue
  - recovery
  - disaster-recovery
  - linux
  - forensics
created: '2026-08-01'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  
---

# SystemRescue Recovery SOP

> [!abstract] Ringkasan Eksekutif
> SystemRescue adalah live Linux environment yang digunakan untuk **memperbaiki sistem yang tidak bisa boot, memulihkan filesystem yang rusak, dan melakukan data recovery**. Prosedur di bawah adalah langkah baku (SOP) yang telah teruji untuk skenario umum: bootloader rusak, password root lupa, filesystem corrupt, dan disk gagal. Prinsip utama: **minimalkan perubahan pada media asli**, selalu **backup MBR/EFI**, dan **dokumentasikan setiap langkah** (penting bila ke depannya butuh *forensic chain of custody*).

## 1. Threat Model / Konteks

| Skenario | Penyebab Umum | Gejala |
|----------|---------------|--------|
| Filesystem rusak | Power loss, bad sector, fsck interrupt | Superblock corrupt, journal error, mount gagal |
| Bootloader gagal | Update GRUB gagal, dual-boot overwrite, UEFI NVRAM corrupt | "GRUB rescue", "No bootable device", langsung ke UEFI setup |
| Password root lupa | Offboarding, rotasi kata sandi tanpa dokumentasi | Tidak bisa login single-user (su dentang) |
| LVM/RAID rusak | Disk failure, LVM metadata korup | Volume tidak terdeteksi `lvmdiskscan` |
| Disk mati / bad sectors | Usia fisik, overheating, jatuh | `dd` error, I/O error, SMART failure |

## 2. Tools dalam SystemRescue

| Tool | Fungsi | Konten |
|------|--------|--------|
| `parted`, `gparted`, `fdisk` | Manajemen partisi | Utilitas CLI + GUI |
| `fsck`, `xfs_repair`, `btrfs-progs` | Perbaikan filesystem | ext4, xfs, btrfs |
| `chroot` | Mount sistem root ke `/mnt` lalu ganti root | Single-user recovery |
| `dd`, `ddrescue`, `dcfldd` | Imaging & recovery | Bitstream copy + hash |
| `grub-install`, `efibootmgr` | Pemulihan bootloader | BIOS + UEFI |
| `btrfs`, `zfs`, `lvm2` | Manajemen volume | Logical volume |
| `ip`, `iproute2`, `nmcli`, `ssh` | Networking | Remote rescue |

## 3. SOP Boot ke SystemRescue

1. Unduh ISO dari situs resmi (https://www.system-rescue.org/).
2. Flash ke USB: `dd if=systemrescue.iso of=/dev/sdX bs=4M status=progress` atau pakai Etcher.
3. Boot UEFI/BIOS ke USB — atur Boot Order di BIOS, atau `efibootmgr` dari system lain.
4. Pilih kernel: default, alt, atau safe mode (jika ada masalah graphics/memori).
5. Siapkan akses jaringan: `dhcpcd` atau `nmcli device wifi connect <ssid> password <pw>`.
6. Mount sistem target (lihat blok di bawah) sebelum melakukan recovery.

```bash
lsblk                              # kenali partisi
mount /dev/sda2 /mnt               # root
mount /dev/sda1 /mnt/boot          # EFI (jika ada)
mount /dev/sda3 /mnt/home          # home (jika terpisah)
chroot /mnt                        # masuk ke environment sistem
mount -t proc proc /proc && mount -t sysfs sys /sys  # chroot lengkap
```

## 4. Use Case & Langkah Detail

### Use Case 1: GRUB Rusak
```bash
mount /dev/sda2 /mnt
mount /dev/sda1 /mnt/boot/efi
chroot /mnt
grub-install /dev/sda
update-grub
exit
reboot
```

### Use Case 2: Reset Password root
```bash
mount /dev/sda2 /mnt
chroot /mnt
passwd root
exit
reboot
```

### Use Case 3: Filesystem Rusak (ext4)
```bash
umount /dev/sda2                        # pastikan unmount dulu
fsck -y /dev/sda2                       # interaktif answer yes
# jika superblock rusak: backup superblock
fsck -b 32768 /dev/sda2
mount /dev/sda2 /mnt
```

### Use Case 4: Recovery Disk Mati (ddrescue)
```bash
# 3-pass ddrescue: cepat → menengah → lama (pasangan)
ddrescue -n /dev/sda /mnt/recovery/disk.img /mnt/recovery/log.txt
ddrescue -r 3 -d /dev/sda /mnt/recovery/disk.img /mnt/recovery/log.txt
# -d: direct I/O, -r 3: retry 3x untuk bad sector
```

### Use Case 5: Pindahkan Data dari LVM Rusak
```bash
pvscan; vgscan; lvscan                 # deteksi volume
vgchange -ay                           # aktifkan semua volume group
mount /dev/vg0/lv-root /mnt
```

## 5. Checklist Mitigasi & Best Practice

- [ ] **Backup MBR/EFI** sebelum modifikasi: `dd if=/dev/sda of=/mnt/backup/mbr.bin bs=512 count=1`
- [ ] **Backup ESP (UEFI)** : `dd if=/dev/sda1 of=/mnt/backup/esp.img`
- [ ] Jangan pernah mount filesystem yang dicurigai corrupt dalam mode **read-write** sebelum pemeriksaan
- [ ] Verifikasi hash imaji (SHA256/MD5) sebelum dan sesudah proses
- [ ] Dokumentasikan tiap langkah — catat tanggal, waktu, tool, output (untuk audit & forensik)
- [ ] Gunakan `smartctl -a /dev/sda` untuk cek health disk sebelum recovery
- [ ] Salin log recovery ke media eksternal (USB kedua) — jangan simpan hanya di media yang dipulihkan

## 6. Referensi Lintas

- [[forensic-imaging-analysis]] — imaging & hash yang court-ready
- [[cyber-law-digital-evidence]] — chain of custody untuk bukti forensik
- [[file-carving-data-recovery-advanced]] — recovery file setelah filesystem rusak
- [[incident-response-framework]] — konteks prosedur recovery dalam IR

---

### 📚 Referensi Eksternal
- https://www.system-rescue.org/Download/
- Linux Foundation Sysadmin Guide
- Red Hat Enterprise Linux Rescue Mode documentation
---

audited
---
