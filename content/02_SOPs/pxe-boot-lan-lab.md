---
title: PXE Boot LAN — Lab Pentest Laptop Jadul
tags:
- sop
- lab
- pxe
- pentest
created: 2026-08-15
updated: 2026-08-15
status: draft
---

# PXE Boot via LAN — Instal Ubuntu Server di Laptop Jadul (Tanpa USB)

> Ide: boot installer Ubuntu langsung dari network (PXE) — tanpa USB.
> Syarat: laptop jadul harus punya port Ethernet (LAN) + BIOS support PXE boot.

## Kenapa PXE?
- Tidak perlu USB (belum punya)
- Installer dikirim via network ke RAM laptop
- Repeatable: bisa reinstall berkali-kali tanpa colok USB

## Arsitektur
```
[Host Fedora 192.168.1.117]  ← PXE server (dnsmasq + tftp + http)
        │  LAN kabel (Ethernet) — LAPTOP JADUL HARUS PAKE KABEL
        ▼
[Laptop jadul]  ← PXE boot (F12 / BIOS boot menu)
        │  DHCP request → dapat IP + file boot
        ▼
[Netboot installer Ubuntu] → install ke disk lokal laptop
```

## Komponen yang dibutuhkan di host
| Komponen | Fungsi | Status |
|---|---|---|
| dnsmasq | DHCP + TFTP + PXE | ADA (v2.92) |
| tftp-hpa / atftpd | TFTP server kirim boot files | BELUM |
| nginx / python http | Serve installer files (http) | python3 ADA |
| netboot.xyz ISO/kernel | Boot kernel + initrd + preseed | BELUM download |
| ISO Ubuntu 22.04/24.04 | Installer source | BELUM |

## Langkah (ringkas — detail eksekusi besok)
1. Download netboot.xyz + ISO Ubuntu 22.04 server (~2GB)
2. Konfigurasi dnsmasq: DHCP range khusus (192.168.1.200-250), enable TFTP, PXE service tag
3. Serve file via python http.server / nginx di port 80
4. Boot laptop jadul → F12 → Network Boot (PXE)
5. Install Ubuntu Server (22.04 minimal, hardening-ready)

## Risiko & Catatan
- WiFi router rumah biasanya DHCP aktif di 192.168.1.0/24 — dnsmasq harus pakai range terpisah atau port DHCP di interface LAN khusus
- Laptop jadul perlu kabel LAN (bukan WiFi) — PXE tidak jalan di WiFi
- Kalau BIOS jadul tidak support UEFI PXE → perlu BIOS Legacy PXE (i386) — netboot.xyz support dua-duanya
- Alternatif kalau PXE gagal: beli USB 8GB (murah) atau boot dari CD/DVD

## Verifikasi
- [ ] dnsmasq --test konfigurasi
- [ ] TFTP bisa serve file (tftp client test)
- [ ] HTTP serve ISO bisa diakses host lain
- [ ] Laptop jadul muncul di DHCP lease (192.168.1.2xx)
- [ ] Installer boot sampai menu install

audited
---
