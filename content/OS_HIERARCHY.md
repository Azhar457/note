---
tags:
  - os
  - linux
  - security
  - military
  - intelligence
  - privacy
  - hierarchy
aliases:
  - OS Hierarchy
  - Operating System Levels
  - OS Security Levels
created: 2026-04-26
status: operational
---

# 🖥️ HIERARKI OS — Dari Consumer sampai Military/Intelligence

> Peta lengkap ekosistem operating system dari yang dipakai orang awam hingga yang dipakai NSA, militer, dan intelijen. Setiap naik level = trade-off antara usability vs security vs kontrol.

> [!info] Plot Twist
> Hampir semua OS tingkat tinggi — termasuk yang dipakai militer AS dan intelijen — berbasis **Linux**, dan khususnya berbasis **RHEL (Red Hat Enterprise Linux)**. AlmaLinux dan Rocky Linux yang kamu kenal itu saudara kandung OS yang dipakai sistem pertahanan. Bukan kebetulan.

---

## Tabel Utama — Level 0 sampai Level 8

| 🖥️ Level & OS                                                                                                       | ⚡ Karakteristik & Sweet Spot                                                                                                                                                                                                                                                                                                                                                                                                                                | ☠️ Tembok & Kelemahan                                                                                                                                                                    | 🎯 Dipakai Oleh                                                                                             |
| -------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------- |
| **Level 0** — Consumer Windows *(Windows 10, Windows 11)*                                                            | Ekosistem software terluas. Plug-and-play semua hardware. Gaming, CorelDRAW, Adobe Suite jalan native. Familiar untuk migrasi dari manapun.                                                                                                                                                                                                                                                                                                                 | Telemetri masif ke Microsoft. Update paksa. Bloatware. Berat di HDD. Closed source — tidak bisa audit apa yang berjalan di background. Terbesar attack surface.                          | Pengguna umum, kantoran, gaming, desainer                                                                   |
| **Level 1** — Consumer Linux *(Linux Mint, Ubuntu, Fedora, Pop!_OS, Zorin OS)*                                       | Open source, ringan di HDD, update dikontrol sendiri, tidak ada telemetri by default. Linux Mint Cinnamon: paling mirip Windows, paling nyaman untuk migrasi. Pop!_OS: gaming + developer. Fedora: bleeding edge, upstream RHEL.                                                                                                                                                                                                                            | Driver hardware kadang butuh setup manual. Ekosistem software lebih terbatas (CorelDRAW tidak ada). Learning curve untuk hal di luar GUI.                                                | Developer, mahasiswa, privacy-conscious user, **kamu sekarang**                                             |
| **Level 2** — Privacy-Focused Desktop *(Whonix, Tails, Kicksecure, Kodachi)*                                         | **Tails**: amnesic OS — berjalan dari USB, tidak menyimpan apapun ke disk, semua traffic via Tor, mati → tidak ada jejak. **Whonix**: dua VM (Gateway + Workstation) — seluruh traffic Workstation dirutekan lewat Tor via Gateway, IP leak mustahil by design. **Kicksecure**: hardened Debian untuk daily use.                                                                                                                                            | Tails tidak cocok untuk produktivitas — amnesic by design. Whonix butuh RAM besar (dua VM berjalan). Kecepatan internet sangat lambat karena Tor.                                        | Jurnalis, whistleblower, aktivis di negara otoriter, researcher privacy                                     |
| **Level 3** — Security Research & Offensive *(Kali Linux, Parrot OS, BlackArch, REMnux)*                             | Kali: 600+ tools pre-installed (Nmap, Metasploit, Burp, Aircrack, Wireshark). Parrot: lebih ringan dari Kali, ada Parrot Home untuk daily use. BlackArch: 2800+ tools, Arch-based. REMnux: khusus malware analysis (reverse engineering tools).                                                                                                                                                                                                             | Bukan untuk daily use — terlalu banyak tools offensive yang tidak perlu di sistem harian. Kali tidak didesain untuk keamanan sistem itu sendiri, tapi untuk menyerang sistem lain.       | Penetration tester, security researcher, CTF player, **target berikutnya kamu**                             |
| **Level 4** — Hardened General Purpose *(Qubes OS, Whonix+KVM, Fedora Silverblue, NixOS)*                            | **Qubes OS**: setiap aplikasi/aktivitas berjalan di VM terpisah (compartmentalization). Email di VM sendiri, browser di VM sendiri, coding di VM sendiri. Compromise satu VM tidak affect yang lain. Fedora Silverblue: immutable OS — root filesystem read-only, update atomic (bisa rollback). NixOS: reproducible, declarative config — seluruh sistem dideskripsikan dalam satu file.                                                                   | Qubes butuh RAM besar (minimum 16GB recommended) dan SSD — tidak cocok HDD. Learning curve Qubes sangat tinggi. NixOS: kurva belajar konfigurasi sangat curam.                           | Security professional paranoid, developer yang butuh isolasi kuat, Snowden pakai Qubes                      |
| **Level 5** — Enterprise Linux *(RHEL, AlmaLinux, Rocky Linux, SLES, Oracle Linux)*                                  | **RHEL (Red Hat Enterprise Linux)**: standar de facto enterprise dan pemerintah. Sertifikasi keamanan FIPS 140-2, Common Criteria EAL4+. Support 10 tahun per major version. SELinux enforcing by default. **AlmaLinux & Rocky Linux**: RHEL clone 1:1 binary compatible, gratis, komunitas. **SLES**: Novell/SUSE, populer di Eropa dan perbankan.                                                                                                         | Bukan untuk desktop consumer — dirancang untuk server dan infrastruktur. RHEL berbayar (subscription). Update lebih konservatif — software sering versi lama tapi stabil.                | Bank, rumah sakit, pemerintah, cloud provider (AWS, GCP, Azure semua pakai RHEL internally), **militer AS** |
| **Level 6** — Certified Security OS *(SELinux-enforced RHEL, DISA STIG hardened, CIS Benchmark hardened)*            | **DISA STIG** (Security Technical Implementation Guide): panduan hardening resmi Departemen Pertahanan AS — ratusan setting spesifik yang harus dikonfigurasi. **CIS Benchmark**: hardening guide untuk enterprise. **FIPS 140-2**: standar kriptografi federal AS — modul crypto harus tersertifikasi. RHEL dengan semua ini aktif = OS yang sama dipakai sistem militer AS.                                                                               | Setup STIG compliant sangat kompleks dan membatasi usability. Banyak fitur dimatikan demi keamanan. Butuh expertise khusus untuk maintain.                                               | Kontraktor pertahanan AS, sistem militer tidak classified, instansi pemerintah federal AS                   |
| **Level 7** — Compartmented & Classified OS *(SELinux MLS, Trusted Solaris, LynxOS, VxWorks, Green Hills INTEGRITY)* | **SELinux MLS** (Multi-Level Security): satu sistem bisa handle data dengan classification berbeda (Unclassified, Secret, Top Secret) — proses di level berbeda tidak bisa saling akses. **Green Hills INTEGRITY**: RTOS certified DO-178C dan Common Criteria EAL6+ — dipakai avionik militer dan sistem senjata. **LynxOS**: real-time, dipakai F-16, Apache helicopter flight control. **VxWorks**: RTOS dipakai di Mars Rover, sistem rudal, submarine. | Source code tidak public (proprietary). Harga lisensi sangat mahal. Butuh clearance untuk akses dokumentasi lengkap. Tidak bisa dibeli individual.                                       | Sistem avionik militer, flight control pesawat tempur, sistem rudal, submarine, spacecraft NASA/militer     |
| **Level 8** — Air-Gapped Classified Networks *(JWICS, SIPRNet, NSANet — bukan OS tapi ekosistem)*                    | **SIPRNet** (Secret Internet Protocol Router Network): jaringan terpisah fisik dari internet publik, untuk data Secret. **JWICS** (Joint Worldwide Intelligence Communications System): untuk Top Secret/SCI. **NSANet**: jaringan internal NSA. Semua berjalan di atas OS hardened (RHEL-based atau custom), air-gapped (tidak terhubung internet sama sekali), fasilitas SCIF (Sensitive Compartmented Information Facility).                             | Tidak bisa diakses dari luar — by design. Stuxnet membuktikan air-gap bisa ditembus via USB yang diinfeksi. Physical security menjadi concern utama karena network attack tidak mungkin. | NSA, CIA, DIA, militer AS, Five Eyes partners, ekuivalen di negara lain (BIN, BSSN untuk Indonesia)         |

---

## Plot Twist: Family Tree OS

```
LINUX KERNEL (Linus Torvalds, 1991)
│
├── Debian
│    ├── Ubuntu
│    │    ├── Linux Mint ◄── kamu sekarang
│    │    ├── Pop!_OS
│    │    └── Zorin OS
│    ├── Kali Linux ◄── security research
│    ├── Tails ◄── privacy/anonymity
│    └── Whonix ◄── Tor-based privacy
│
├── Red Hat (RHEL)
│    ├── Fedora (upstream/testing ground RHEL)
│    ├── AlmaLinux ◄── RHEL clone gratis ← PLOT TWIST
│    ├── Rocky Linux ◄── RHEL clone gratis ← PLOT TWIST
│    ├── CentOS (deprecated)
│    └── RHEL proper ← dipakai militer AS, bank, pemerintah
│
├── Arch Linux
│    ├── Manjaro
│    └── BlackArch ◄── security research
│
├── Gentoo
│    └── Chromium OS / ChromeOS (Google)
│
└── Android (mobile, Linux kernel)

BUKAN LINUX:
├── Windows NT kernel (Microsoft) ◄── closed source
├── macOS / iOS (XNU kernel, Darwin) ◄── hybrid
├── VxWorks ◄── proprietary RTOS militer/aerospace
└── Green Hills INTEGRITY ◄── EAL6+, sistem senjata
```

---

## Hierarki Privacy OS Khusus

```
TAILS
├── Amnesic — tidak simpan apapun
├── Semua traffic → Tor
├── Boot dari USB
└── Use case: investigasi jurnalistik, whistleblower
     Contoh: Snowden rekomendasikan Tails

WHONIX
├── Dua VM: Gateway + Workstation
├── IP leak mustahil by architecture
├── Bisa persistent (simpan data)
└── Use case: daily use yang butuh anonimitas kuat

QUBES OS
├── Setiap app = VM terpisah
├── Compromise satu app tidak spread
├── Bisa combine dengan Whonix (Qubes+Whonix)
└── Use case: high-value target (aktivis, jurnalis, exec)
     Snowden: "Qubes is the most secure OS"
     Butuh: RAM 16GB+, SSD, bukan untuk HDD
```

---

## Kenapa Militer Pilih RHEL?

```
Alasan teknis:
✅ FIPS 140-2 certified crypto modules
✅ SELinux enforcing (MAC — Mandatory Access Control)
✅ Common Criteria EAL4+ certification
✅ DISA STIG compliance — ratusan security control
✅ 10 tahun support — sistem militer tidak ganti OS tiap 3 tahun
✅ Supply chain yang bisa diaudit (Red Hat = IBM company)
✅ Open source = bisa diaudit sendiri oleh NSA, DISA, dll

AlmaLinux & Rocky Linux:
= RHEL tanpa subscription fee
= Binary compatible 1:1
= Cocok untuk: lab, development, non-critical govt system
= Tidak punya sertifikasi RHEL (FIPS, Common Criteria)
  → untuk sistem certified harus RHEL proper
```

---

## Rekomendasi per Use Case

| Kebutuhan | OS Rekomendasi | Alasan |
|---|---|---|
| **Harian + HDD + Kantor** | Linux Mint Cinnamon | Ringan, familiar, WPS Office jalan |
| **Security Research** | Kali Linux (VM) atau Parrot OS | Tools lengkap, tidak untuk daily |
| **Privacy tinggi** | Tails (USB) atau Whonix (VM) | Sesuai threat model |
| **Isolasi maksimal** | Qubes OS | Tapi butuh SSD + RAM besar |
| **Server/Infrastruktur** | AlmaLinux / Rocky Linux | RHEL-compatible, gratis, stabil |
| **Enterprise/Gov** | RHEL proper | Certified, support resmi |
| **Aerospace/Militer** | VxWorks / Green Hills | Real-time, safety certified |
| **Classified network** | Custom hardened RHEL + STIG | Air-gapped, SCIF facility |

---

## Soal Partisi HDD 256GB untuk Linux Mint

```
Rekomendasi layout 256GB HDD:

/boot     →   512MB   (bootloader)
/         →   40GB    (root — sistem + software)
swap      →   4-8GB   (tergantung RAM, makin besar makin baik di HDD)
/home     →   sisa    (~200GB untuk data pribadi)

Kenapa /home terpisah:
→ Reinstall OS tidak hapus data pribadi
→ Bisa ganti distro tanpa kehilangan file

Swap di HDD:
→ Wajib lebih besar dari di SSD
→ HDD lambat, swap besar = lebih jarang terpicu
→ RAM 4GB → swap 8GB
→ RAM 8GB → swap 4GB
```

>[!tip] Untuk Nanti — Ketika Sudah Punya SSD
>Urutan upgrade yang worth: RAM dulu → SSD. SSD bahkan 128GB murah sudah mengubah pengalaman Linux secara dramatis. Qubes OS dan Whonix yang butuh VM juga baru feasible setelah ada SSD.

---

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[UNDERGROUND_KNOWLEDGE]] — Tor dan dark web yang bawa kamu ke Whonix
- [[INFRASTRUKTUR_CLOUD]] — Linux sebagai fondasi semua cloud
- [[FONDASI_CS]] — OS Internals sebagai fondasi memahami perbedaan ini

---

*OS Hierarchy | Dari Linux Mint sampai JWICS · Plot Twist: Semua Berbasis RHEL*
