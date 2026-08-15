---
title: Hardware Hacking Re
tags:
- cyber-security
- library
created: '2026-04-23'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  

---

# 🔬 Reverse Engineering & Hardware Hacking — Hierarki Lengkap

> Dua disiplin yang tak terpisahkan: RE membedah **logika** (binary/firmware), Hardware Hacking membedah **fisik** (silikon/sirkuit). Keduanya bertemu di satu titik — memahami sistem yang tidak memberikan dokumentasinya kepadamu.

---

## Daftar Isi

- [[#Sheet 1 — Reverse Engineering Software & Firmware]]
- [[#Sheet 2 — Hardware Hacking Physical Layer]]
- [[#Titik Temu RE dan Hardware Hacking]]

---

## Sheet 1 — Reverse Engineering: Software & Firmware

> **RE** = proses memahami cara kerja sistem tanpa akses ke source code.
> Senjata utama: kesabaran, disassembler, dan kopi.

| 🔧 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok Kematian | 🎯 Aplikasi Nyata |
|---|---|---|---|
| **Level 0** — String & Static Recon *(strings, file, binwalk, ExifTool, Detect-It-Easy)* | Analisis binary tanpa menjalankannya. `strings` dump semua teks readable (URL, kunci API, path hardcoded). `file` identifikasi format. `binwalk` carve firmware image — ekstrak filesystem, kernel, bootloader secara otomatis. Detect-It-Easy: identifikasi packer/protector/compiler. | Obfuscation sederhana (XOR encode string) sudah cukup menyembunyikan strings. Binwalk gagal pada firmware terenkripsi penuh. | Analisis malware awal, ekstrak filesystem dari firmware router, cek binary mencurigakan |
| **Level 1** — Disassembly Statis *(Ghidra, IDA Free, Cutter/Rizin, objdump)* | Konversi machine code → assembly → pseudo-C decompile (Ghidra/IDA). Analisis control flow graph, cross-reference fungsi, identifikasi algoritma kriptografi dari pola instruksi. Ghidra (NSA, gratis) setara IDA Pro dalam banyak kasus. | Stripped binary (tanpa simbol debug) = semua fungsi bernama `FUN_00401234`. Butuh jam untuk rename manual. Obfuscated control flow (opaque predicate) menyesatkan decompiler. | Analisis malware statis, cari hardcoded credential di binary, audit library third-party |
| **Level 2** — Dynamic Analysis *(x64dbg, OllyDbg, GDB+PEDA, Frida, Proc Monitor)* | Jalankan program di bawah debugger — pause, inspect memori, ubah register, bypass kondisi. Frida: dynamic instrumentation tanpa source code, inject JavaScript ke proses manapun (mobile, desktop, IoT). Process Monitor: rekam semua syscall, file access, registry, network. | Anti-debug tricks: `IsDebuggerPresent`, timing check, exception-based detection. Sandbox evasion: malware deteksi VM dan tidur sampai keluar sandbox. | Bypass proteksi software, analisis malware behavior, hooking API mobile app |
| **Level 3** — Firmware RE *(Binwalk, Firmwalker, FACT, Ghidra + SVD-Loader, OpenOCD)* | Ekstrak firmware dari device (via UART/JTAG/flash chip dump), analisis dengan Ghidra. FACT (Firmware Analysis and Comparison Tool): analisis otomatis kerentanan, credential hardcoded, versi library. SVD-Loader: load peripheral register definition ke Ghidra untuk MCU ARM. | Firmware terenkripsi dengan kunci yang tersimpan di secure element = butuh hardware attack. Custom RTOS tanpa dokumentasi = susah orientasi. | Keamanan router, kamera IP, IoT device, medical device firmware audit |
| **Level 4** — Protocol RE *(Wireshark + Lua dissector, Scapy, Proxmark, Universal Radio Hacker)* | Reverse engineer protokol komunikasi proprietary dari traffic capture. Bangun Wireshark dissector custom dengan Lua. Proxmark3: RE protokol RFID/NFC (kartu akses gedung, e-money). URH: RE protokol RF dari sinyal yang di-capture SDR. | Protokol dengan enkripsi end-to-end + certificate pinning. Rolling code (remote mobil) berubah tiap penggunaan. | Keamanan akses kontrol, analisis protokol industri (Modbus, DNP3), smart card research |
| **Level 5** — Symbolic Execution & Fuzzing *(angr, KLEE, AFL++, LibFuzzer, Triton)* | **Symbolic execution**: jalankan program dengan input simbolik — matematika, bukan nilai konkret. Secara otomatis generate input yang mencapai setiap branch. AFL++: coverage-guided fuzzing — mutasi input otomatis, pantau coverage, crash = potential vulnerability. | Path explosion pada program besar (jumlah path eksponensial). Fuzzing butuh jam hingga minggu untuk menemukan crash di target kompleks. | Vulnerability research, CTF, bug bounty, audit keamanan library kriptografi |
| **Level 6** — Binary Exploitation *(pwntools, ROPgadget, pwndbg, heap exploitation, kernel exploit)* | Dari crash → controlled code execution. Buffer overflow, format string, use-after-free, heap feng shui. ROP (Return-Oriented Programming): chain gadget dari binary yang ada untuk bypass NX/DEP. Kernel exploit: dari user space ke Ring 0. | ASLR + PIE + Stack Canary + Full RELRO + seccomp membuat exploitation sangat sulit. Modern kernel mitigations (SMEP, SMAP, CET). | CVE research, pwn CTF, jailbreak iOS/Android, privilege escalation |
| ☠️ **Level 7** — Compiler & VM Internals *(LLVM IR analysis, JVM/Dalvik bytecode, WebAssembly RE, obfuscator internals)* | RE pada level intermediate representation. Analisis LLVM IR untuk compiler-introduced vulnerability. Dalvik bytecode RE untuk Android app. WASM RE untuk browser-based DRM/anti-cheat. Deobfuscate VM-based protector (VMProtect, Themida) yang translasi instruksi ke bytecode custom VM. | VM-based protector dengan custom ISA = satu fungsi bisa jadi ribuan instruksi VM. Butuh minggu untuk satu fungsi kritis. | DRM bypass research, advanced malware analysis, anti-cheat RE |

---

## Sheet 2 — Hardware Hacking: Physical Layer

> **Hardware Hacking** = serangan dan analisis pada level fisik — sirkuit, sinyal, dan silikon.
> Senjata utama: oscilloscope, soldering iron, dan tidak takut merusak.

| 🔩 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok Kematian | 🎯 Aplikasi Nyata |
|---|---|---|---|
| **Level 0** — Physical Recon *(Multimeter, visual inspection, FCC ID lookup)* | Buka casing, foto PCB, identifikasi chip dari marking. FCC ID di label belakang device → cari di fccid.io → dapat foto internal + test report resmi. Multimeter: ukur voltase, cek jalur (continuity). | Chip marking sengaja dihapus (common di produk yang tidak mau di-RE). Komponen BGA tidak bisa diidentifikasi visual. | Identifikasi hardware target, cari UART/JTAG pad, reverse PCB layout |
| **Level 1** — UART / Serial Console *(USB-to-UART adapter, PuTTY, minicom, screen)* | UART adalah "lubang debug" paling umum di embedded device. Biasanya 3–4 pad di PCB (TX, RX, GND, VCC). Sambungkan logic analyzer atau USB-UART adapter → buka serial console → sering langsung dapat **root shell** atau boot log yang mengekspos info sensitif. | Beberapa vendor disable UART di production build atau require password untuk console. Butuh logic analyzer untuk identifikasi baud rate jika tidak diketahui. | Root akses router/kamera IP, dump boot log, akses recovery mode tersembunyi |
| **Level 2** — JTAG / SWD Debug Interface *(OpenOCD, JLink, CMSIS-DAP, UrJTAG, Black Magic Probe)* | JTAG: interface debug standar industri untuk MCU/SoC. Bisa pause eksekusi, baca/tulis memori, flash firmware baru, single-step instruksi. SWD: versi 2-pin lebih baru dari JTAG (common di ARM Cortex-M). OpenOCD: open-source JTAG controller. | Banyak device production **burn JTAG fuse** (disable permanen). Beberapa implementasi JTAG membutuhkan autentikasi. Pad JTAG sering tidak di-label. | Firmware dump, unlock bootloader, debug embedded system, bypass secure boot |
| **Level 3** — Flash Chip Dump *(Flashrom, CH341A programmer, SOIC clip, Bus Pirate)* | Dump langsung dari flash chip (NOR/NAND) tanpa lewat CPU. CH341A: programmer murah (~Rp 50rb) untuk chip SPI NOR flash. SOIC clip: jepit chip tanpa desolder. Flashrom: software yang support ratusan flash chip. | Flash chip BGA tidak bisa di-clip — harus desolder. Chip dengan internal encryption = dump terenkripsi. | Backup firmware sebelum modifikasi, bypass write protection, recover brick device |
| **Level 4** — Side-Channel Attack *(ChipWhisperer, oscilloscope, power analysis, EM analysis)* | **Power Analysis**: monitor konsumsi daya CPU saat operasi kriptografi → ekstrak kunci AES dari pola power trace. ChipWhisperer: platform open-source khusus side-channel attack. **EM Analysis**: probe antena kecil dekat chip → baca emisi elektromagnetik tanpa kontak fisik. Timing attack: ukur waktu eksekusi untuk inferensi data rahasia. | Butuh ribuan trace untuk Simple/Differential Power Analysis. Target dengan proper masking/jitter mitigation sangat resistan. ChipWhisperer butuh pengetahuan statistik signal processing. | Smart card attack, secure element research, IoT key extraction, akademis |
| **Level 5** — Fault Injection *(Voltage glitching, clock glitching, laser fault injection, EM fault injection)* | **Voltage glitch**: spike voltase sesaat untuk corrupt instruksi CPU — skip security check, bypass PIN verification. **Clock glitch**: inject pulsa clock ekstra → CPU execute instruksi ganda atau skip. **Laser fault injection**: tembak laser presisi ke die chip untuk flip bit di SRAM/register. | Laser fault injection butuh decap kimia dulu + alat laser presisi seharga ratusan juta. Voltage/clock glitch butuh timing presisi nanosecond. Modern chip punya voltage/frequency detector yang trigger zeroize jika anomali terdeteksi. | Bypass secure boot, extract key dari HSM/TPM, jailbreak console gaming, bypass PIN limit |
| **Level 6** — PCB & Circuit RE *(X-ray PCB, dye-and-pry, layer delamination, KiCad RE)* | **X-ray**: lihat layer dalam PCB multi-layer tanpa destruktif. **Dye-and-pry**: celup PCB ke cairan pewarna, cungkil BGA chip → lihat ball pattern untuk RE routing. Delamination: kupas layer PCB satu per satu secara mekanis/kimiawi untuk trace semua jalur. | X-ray PCB butuh mesin X-ray industri. Delamination destruktif — tidak bisa diulang. Butuh skill PCB layout profesional untuk interpret hasilnya. | RE produk kompetitor, security audit hardware proprietary, reverse supply chain |
| ☠️ **Level 7** — Silicon RE *(Decapsulation kimia, SEM imaging, FIB circuit edit, netlist RE)* | **Decapsulation**: larutkan epoxy packaging chip dengan asam nitrat/sulfat → ekspos die silikon. **SEM**: scan seluruh permukaan die, foto setiap layer. **FIB (Focused Ion Beam)**: potong dan deposit jalur logam di level atom — bisa edit circuit secara fisik. Rekonstruksi netlist dari foto SEM → full schematic dari chip yang tidak punya dokumentasi. | Biaya per chip: Rp 50 juta – Rp 5 miliar. Proses destruktif — chip habis setelah RE. Butuh lab cleanroom dan operator expert. | Military chip RE (DARPA TRUST program), clone detection, undocumented backdoor search di chip kriptografi |

---

## Titik Temu RE dan Hardware Hacking

```
TARGET: Router WiFi mencurigakan
         │
         ▼
[Hardware] Buka casing → foto PCB → FCC ID lookup
         │
         ▼
[Hardware] UART pad ditemukan → sambung USB-UART → dapat boot log
         │
         ├── Boot log expose: kernel version, filesystem type
         │
         ▼
[Hardware] Dump flash via SOIC clip + CH341A
         │
         ▼
[RE] binwalk -e firmware.bin → ekstrak filesystem squashfs
         │
         ▼
[RE] Ghidra → analisis binary daemon yang jalan di background
         │
         ▼
[RE] strings → temukan URL hardcoded + credential default
         │
         ▼
[RE] Dynamic: Frida hook → intercept komunikasi terenkripsi
         │
         ▼
RESULT: Full understanding sistem tanpa dokumentasi apapun
```

>[!tip] Entry Point untuk Mahasiswa IT
>**Mulai dari CTF (Capture The Flag)** — khususnya kategori RE dan pwn.
>Platform: **picoCTF** (beginner), **pwn.college** (intermediate), **Hack The Box** (advanced).
>Hardware: beli **ESP32 devboard** (~Rp 50rb) → target sempurna untuk belajar UART, firmware flash, dan basic hardware hacking legal.

---

## 🔗 Lihat Juga

- [[endpoint-security|Endpoint Security]] — CPU Ring & Blue Team vs Red Team
- [[network-security|Network Security]] — OSI Layer Blue Team vs Red Team
- [[cheatsheet|Cheat Engine]] — Cheat Engine Hierarchy
- [[hierarchy-osint-rf|OSINT & RF Hierarchy]]
- [[cryptography-biometrics|Kriptografi & Biometrik]]

---

*Reverse Engineering & Hardware Hacking | Dari strings sampai FIB Silicon Edit*
---

audited
---
