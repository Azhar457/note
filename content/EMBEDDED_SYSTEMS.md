---
tags:
  - embedded
  - firmware
  - iot
  - bare-metal
  - flash-forensics
  - rtos
  - mcu
aliases:
  - Embedded Systems
  - Flash Drive Forensics
  - Bare Metal
created: 2026-04-25
---

# 🔌 EMBEDDED SYSTEMS & FLASH FORENSICS — Bare-Metal World

> Di bawah OS, di bawah driver, ada dunia di mana programmer berbicara langsung ke register hardware. Embedded Systems = memprogram dunia fisik. Flash Forensics = membedah media penyimpanan sampai ke chip NAND-nya.

> [!info] Cara Baca
> Keduanya bertemu di satu titik: **bare-metal access ke hardware tanpa abstraksi OS**. Flash forensics adalah embedded RE yang diterapkan ke storage device. Gunakan bersama [[RE_HARDWARE_HACKING]] untuk gambaran lengkap.

---

## Sheet 1 — Embedded Systems: Dari LED Blink sampai RTOS

| 🔌 Level & Konsep | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian | 🔗 Koneksi ke Topik Lain |
|---|---|---|---|
| **Level 0** — GPIO & Bare-Metal Basics *(LED blink, button input, register direct access, Arduino/ESP32)* | Program langsung ke register hardware tanpa OS. GPIO (General Purpose I/O): pin yang bisa diset HIGH/LOW via register. Memory-mapped I/O: peripheral di-control dengan tulis ke address tertentu. Tidak ada `printf` — debug via LED atau UART. Clock configuration: MCU harus dikonfigurasi clock source sebelum peripheral bisa jalan. | Tidak ada safety net — bug bisa brick device (infinite loop saat init = tidak bisa re-program tanpa hardware debugger). Power consumption salah konfigurasi = baterai habis dalam jam. | Koneksi ke Hardware Hacking (UART, JTAG), koneksi ke Computer Architecture (register, MMIO) |
| **Level 1** — Communication Protocols *(UART, SPI, I2C, CAN, USB, Ethernet, 1-Wire)* | UART: async serial, 2 wire (TX/RX), point-to-point, baud rate harus match. SPI: sync, 4 wire (MOSI/MISO/CLK/CS), master-slave, full duplex, cepat. I2C: sync, 2 wire (SDA/SCL), multi-device di satu bus via address, half duplex. CAN: differential bus, tahan noise, dipakai otomotif. USB: host-device, complex stack, butuh library. | SPI clock polarity/phase mismatch = data korup diam-diam. I2C address conflict jika dua device sama address. UART tidak ada hardware flow control → data loss jika processor lambat. | Koneksi ke Hardware Hacking (sniff protokol via logic analyzer), koneksi ke RE (decode protokol proprietary) |
| **Level 2** — Interrupt & Timer *(ISR, NVIC, timer overflow, PWM, watchdog, systick)* | Interrupt: hardware signal ke CPU untuk hentikan program sementara, handle event, lanjut. ISR (Interrupt Service Routine): handler yang harus cepat, tidak boleh blocking, tidak boleh allocate memory dinamis. NVIC (ARM): Nested Vectored Interrupt Controller — priority, preemption. Timer: counting register, trigger interrupt saat overflow. Watchdog: reset MCU jika tidak di-kick dalam interval tertentu — cegah hang. PWM: simulasi output analog via switching cepat. | ISR terlalu lama → missing interrupt berikutnya. Shared data antara ISR dan main loop tanpa volatile/atomic → race condition. Watchdog tidak di-kick di semua path → unexpected reset. | Koneksi ke OS Internals (interrupt = fondasi syscall), koneksi ke Computer Architecture (pipeline interrupt) |
| **Level 3** — Memory Management Bare-Metal *(stack, heap, linker script, memory map, DMA)* | Tidak ada virtual memory — semua physical address. Linker script: define region (flash, RAM, stack, heap), place section (.text, .data, .bss). Stack overflow → corrupt heap atau global variable diam-diam (tidak ada guard page). `malloc` di embedded: berbahaya karena fragmentation, banyak sistem gunakan static allocation. DMA: transfer data antara peripheral dan RAM tanpa CPU — konfigurasi source, destination, size, trigger. | Stack overflow tidak terdeteksi jika tidak ada stack canary manual. Heap fragmentation di long-running system → allocation fail setelah berjalan berhari-hari. | Koneksi ke OS Internals (memory management analog), koneksi ke Binary Exploitation (stack overflow sama konsepnya) |
| **Level 4** — RTOS *(FreeRTOS, Zephyr, ThreadX, Mbed OS, task scheduling, semaphore, queue)* | RTOS (Real-Time OS): scheduler yang guarantee timing. Task: unit eksekusi dengan priority. Preemptive scheduling: task prioritas tinggi bisa interrupt task prioritas rendah kapanpun. Semaphore/mutex: koordinasi antar task. Queue: komunikasi data antar task (producer-consumer). Deadline: hard real-time (miss = catastrophic) vs soft real-time (miss = degraded). | Priority inversion: task prioritas tinggi diblokir oleh task rendah yang pegang resource. Stack overflow per-task tidak terdeteksi tanpa stack watermark monitoring. Context switch overhead pada MCU lambat. | Koneksi ke OS Internals (RTOS adalah OS minimal), koneksi ke Robotics (ROS 2 di atas Linux, FreeRTOS di MCU) |
| **Level 5** — Firmware Update & Bootloader *(bootloader, OTA, A/B partition, secure boot, rollback protection)* | Bootloader: kode pertama yang jalan, pilih image yang di-load, handle update. A/B partition: dua slot firmware — update slot inactive, swap jika sukses, rollback jika gagal. OTA (Over-the-Air): update via network tanpa fisik. Secure boot: verifikasi signature firmware sebelum execute. Rollback protection: anti-downgrade via counter di fuse/secure element. | Update yang gagal di tengah jalan tanpa A/B = brick. Bootloader tanpa secure boot = attacker bisa flash firmware jahat. OTA tanpa enkripsi/signing = MITM attack pada firmware. | Koneksi ke Hardware Hacking (JTAG bypass bootloader), koneksi ke RE (firmware RE via binwalk) |
| **Level 6** — Sensor Fusion & Control Theory *(PID, Kalman filter, IMU, LiDAR, SLAM, complementary filter)* | Sensor fusion: kombinasi multiple sensor untuk estimasi state yang lebih akurat dari satu sensor saja. IMU (Inertial Measurement Unit): accelerometer + gyroscope, bias drift masalah utama. Kalman filter: optimal estimator untuk linear system dengan Gaussian noise. PID controller: Proportional-Integral-Derivative — feedback control untuk motor, temperature, dll. SLAM (Simultaneous Localization and Mapping): robot tahu posisinya sambil bangun peta. | Kalman filter diverge jika noise model salah. PID tanpa tuning yang benar → oscillation atau lambat response. IMU accumulation error → drift seiring waktu. | Koneksi ke AI Level 5 (Embodied AI/Robotics), koneksi ke RF (IMU + GPS fusion) |
| ☠️ **Level 7** — Safety-Critical & Certification *(IEC 61508, ISO 26262, DO-178C, MISRA C, formal verification)* | Safety Integrity Level (SIL): SIL-4 tertinggi (nuklir, aviasi). ISO 26262: automotive functional safety. DO-178C: aviasi software. Persyaratan: no dynamic allocation, no recursion, semua path harus tercover oleh test, formal proof untuk bagian kritis. MISRA C: subset C yang aman untuk safety-critical (tidak ada undefined behavior). | Sertifikasi membutuhkan tahun dan biaya sangat besar. Tools formal verification (Frama-C, SPARK Ada) butuh expert khusus. Majority developer tidak pernah menyentuh ini. | Koneksi ke Research Methodology (formal verification = mathematical proof), koneksi ke AI safety concern |

---

## Sheet 2 — Flash Drive Forensics & Restoration

| 🔧 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok Kematian | 🎯 Kapan Dipakai |
|---|---|---|---|
| **Level 0** — Deteksi & Validasi *(ValidDrive, H2testw, F3)* | ValidDrive: tulis & verifikasi kapasitas yang diklaim dalam ~10 menit — buktikan flash scam. H2testw: tulis pattern, baca ulang, deteksi error dan kapasitas palsu. F3 (Fight Flash Fraud): open-source, lebih detail untuk Linux. Output: kapasitas valid, highest valid region, visual map. | Tidak bisa deteksi flash yang scam sangat canggih (fake sektor awal valid, akhir rusak). Waktu test proporsional kapasitas — 2TB palsu butuh waktu lama untuk dibuktikan. | Setiap flash drive lelang/murah/mencurigakan sebelum dipercaya |
| **Level 1** — Identifikasi Controller *(ChipGenius, Flash Drive Information Extractor, USBDeview)* | ChipGenius baca VID (Vendor ID) + PID (Product ID) dari descriptor USB — identifikasi controller IC dan flash chip. Output: nama controller (SMI SM3257, Alcor AU698x, Phison PS2251, Innostor IS916), nama NAND chip, firmware version. VID/PID adalah kunci untuk cari MPTool yang tepat. | Beberapa controller murah report VID/PID palsu untuk kelihatan branded. Controller sangat obscure mungkin tidak ada di database manapun. | Wajib sebelum cari MPTool — salah MPTool bisa brick flash drive |
| **Level 2** — Low Level Format & Restoration *(MPTool per controller)* | MPTool = Manufacturing Program — software yang sama dipakai pabrik saat produksi. Akses langsung ke controller firmware, bypass OS. Fungsi: low level format, restore kapasitas asli chip NAND, set serial number, tuning parameter. Masing-masing controller punya MPTool berbeda: AlcorMP (Alcor), PhisonMPTool (Phison), SMIFlashTool (SMI), SkymediMPTool (Skymedi). Cari di flashboot.ru atau usbdev.ru by VID/PID. | MPTool yang salah controller bisa brick permanent. Beberapa MPTool versi tertentu hanya cocok firmware tertentu. Flash drive sudah mati total (controller tidak respond) = MPTool tidak bisa membantu. | Flash drive scam: restore ke kapasitas asli NAND chip. Flash drive error: reset wear leveling table, clear bad block map |
| **Level 3** — HPA / Kapasitas Tersembunyi *(hdparm, HDAT2, kapasitas asli vs yang diexpose)* | Beberapa flash drive memanipulasi kapasitas yang dilaporkan ke OS (mirip HPA di HDD). `hdparm -N` cek native max vs current max. HDAT2 via bootable DOS: akses langsung ke ATA command, bisa reset kapasitas. Flash scam: controller diprogram lapor 2TB padahal NAND hanya 32GB — setelah 32GB data overwrite sendiri ke awal. | Teknik ini lebih relevan untuk HDD. Flash drive modern pakai USB Mass Storage class, bukan ATA — hdparm tidak berlaku langsung. Controller firmware yang mengontrol kapasitas palsu harus di-reflash via MPTool. | Koneksi ke SOP HPA Exorcism (konsep sama, implementasi berbeda untuk flash) |
| **Level 4** — NAND Flash Internals *(SLC/MLC/TLC/QLC, wear leveling, garbage collection, write amplification)* | SLC (1 bit/cell): paling cepat, tahan ~100k P/E cycle. MLC (2 bit): consumer standard. TLC (3 bit): murah, ~1000 P/E. QLC (4 bit): termurah, ~100 P/E — batas untuk data center SSD. Wear leveling: controller distribusi write merata ke semua sel agar tidak ada yang mati duluan. Garbage collection: mirip compaction — bersihkan blok dengan data invalid. Write amplification: satu write logical bisa trigger banyak write physical. | QLC flash tidak cocok untuk write-intensive workload. Wear leveling yang jelek (cheap controller) → sel tertentu mati duluan. Over-provisioning (kapasitas "tersembunyi" untuk GC dan WL) dikurangi pada flash murah → performa drop drastis saat mendekati penuh. | Koneksi ke Database Internals (LSM-tree dan flash GC mirip konsepnya), koneksi ke Computer Architecture (storage hierarchy) |
| **Level 5** — Chip-Off & NAND Reading *(desolder chip, NAND programmer, raw dump, ECC reconstruction)* | Desolder chip NAND dari PCB (hot air station atau infrared). NAND programmer (Flashcat, Dataman, TNM): baca raw dump dari chip tanpa controller. Raw dump = data + ECC (Error Correcting Code) bytes. ECC harus di-decode dengan algoritma yang sesuai controller aslinya. Page mapping: controller punya skema pemetaan logical ↔ physical yang berbeda-beda (tidak terstandarisasi). | Tanpa tahu ECC dan page mapping controller, raw dump adalah data tidak terbaca. Desolder yang salah (terlalu panas) = chip rusak permanent. Setiap brand controller punya format proprietary berbeda. | Koneksi ke Data Recovery Level 6 (chip-off), koneksi ke Hardware Hacking Level 3 (flash chip dump) |
| ☠️ **Level 6** — Flash Forensics Tingkat Laboratorium *(electron microscopy, wear pattern analysis, deleted data recovery dari NAND)* | NAND yang sudah di-erase masih menyimpan residual charge yang bisa dideteksi dengan peralatan lab khusus. Wear pattern analysis: sel yang lebih aus menunjukkan area yang lebih sering diakses — informasi forensik. Deleted file recovery dari NAND: data "terhapus" mungkin masih ada di blok yang belum di-GC. Over-provisioning area: area tersembunyi yang menyimpan data lama dari wear leveling. | Lab-level equipment (electron microscope, probe station). Chip harus dalam kondisi tertentu. Enkripsi hardware (AES-256 di controller modern) membuat recovery tidak feasible meski fisik berhasil. | Koneksi ke Data Recovery Level 6 (deep nano-physics), koneksi ke Kriptografi (enkripsi hardware) |

---

## Peta Ekosistem Embedded & Flash

```
EMBEDDED SYSTEMS
│
├── MCU (ARM Cortex-M, ESP32, STM32)
│    ├── Bare-metal (Level 0-3)
│    ├── RTOS (Level 4)
│    └── Safety-critical (Level 7)
│
├── SBC (Raspberry Pi, BeagleBone)
│    └── Linux + real-time extension
│
└── FPGA (Xilinx, Intel Altera)
     └── Hardware-defined logic
          └── Dipakai DMA card (Cheat Engine Level 5)

FLASH FORENSICS
│
├── Consumer Flash (USB, SD card)
│    ├── ValidDrive → ChipGenius → MPTool (Level 0-2)
│    └── Chip-Off jika controller mati (Level 5)
│
├── SSD NVMe/SATA
│    ├── HDDSuperClone untuk cloning (Data Recovery Level 4)
│    └── PC-3000 untuk firmware (Data Recovery Level 5)
│
└── Embedded Flash (eMMC, NOR, NAND di router/kamera)
     ├── JTAG/UART dump (Hardware Hacking Level 1-2)
     └── Chip-Off (Hardware Hacking Level 3)
```

> [!tip] Entry Point untuk Mahasiswa IT
> **ESP32 devboard** (~Rp 50rb) adalah lab embedded lengkap: WiFi, Bluetooth, GPIO, UART, SPI, I2C, ADC, DAC, dual-core RTOS. Bisa belajar Level 0–4 tanpa beli hardware mahal.
> **Flash forensics**: beli beberapa flash drive murah/lelang di Shopee, praktikkan workflow ValidDrive → ChipGenius → flashboot.ru → MPTool. Ini skill langsung pakai.

> [!warning] Embedded Security yang Sering Diabaikan
> 70% device IoT di dunia punya default credential yang tidak pernah diganti. 60% tidak pernah dapat firmware update setelah 2 tahun. UART/JTAG yang tidak di-disable di production = pintu belakang terbuka. Ini bukan teori — Mirai botnet 2016 menguasai 600.000 device IoT via credential default.

---

## 🔗 Lihat Juga

- [[MASTER_INDEX]]
- [[RE_HARDWARE_HACKING]] — RE firmware + hardware debug interface
- [[FONDASI_CS]] — Computer Architecture sebagai fondasi MCU
- [[OSINT_RF_HIERARCHY]] — RF protocol yang berjalan di atas embedded
- [[SOP_HPA_Exorcism]] — Flash forensics tingkat HDD

---

*Embedded Systems & Flash Forensics | Dari LED Blink sampai Chip-Off NAND · Bare-Metal World*
