---
title: "Hierarchy Embedded Systems"
tags:
  - atlas
  - embedded
  - microcontroller
  - RTOS
  - firmware
aliases:
  - "hierarchy-embedded-systems"
created: "2026-07-17"
updated: "2026-07-17"
status: active
---

# 🔌 HIERARKI EMBEDDED SYSTEMS — Dari GPIO Bare-Metal (Level 0) sampai Safety-Critical Certification (Level 7)

> Embedded systems adalah dunia di mana **programmer bicara langsung ke register hardware** — tidak ada OS, tidak ada virtual memory, tidak ada safety net. Setiap level adalah lapisan abstraksi yang semakin naik: dari blinking LED via register sampai RTOS dengan task scheduling dan safety-critical certification. Untuk tabel lengkap per level dengan tools dan teknik, lihat [[embedded-systems]].

> [!info] Cara Baca
> Level 0 = bare-metal langsung ke register. Level 7 = sistem safety-critical dengan formal verification. Semakin tinggi level, semakin banyak abstraksi — tapi semakin besar juga potensi bug dari ketergantungan pada abstraksi itu sendiri.

---

## Tabel Utama — Level 0 sampai Level 7

| 🔌 Level                                   | 🧠 Domain                                                             | ⚡ Teknik & Tools                                                                                                                                                                                               | ☠️ Tembok Kematian                                                                                                                                     |
| ------------------------------------------ | --------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------ |
| **Level 0** — GPIO & Bare-Metal            | LED blink, button input, register direct access, Arduino/ESP32        | Program langsung ke register hardware. Memory-mapped I/O: kontrol peripheral dengan tulis ke address. Debug via LED/UART — tidak ada `printf`. Clock configuration wajib sebelum peripheral jalan               | Tidak ada safety net — bug bisa brick device. Power consumption salah → baterai habis jam. Infinite loop di init = brick tanpa debugger                |
| **Level 1** — Communication Protocols      | UART, SPI, I2C, CAN, USB, Ethernet, 1-Wire                            | UART: async, 2 wire. SPI: sync, 4 wire, full duplex. I2C: sync, 2 wire, multi-device via address. CAN: differential bus, tahan noise (otomotif). USB: host-device, complex stack                                | SPI clock polarity mismatch → data korup diam-diam. I2C address conflict. UART tanpa flow control → data loss                                          |
| **Level 2** — Interrupt & Timer            | ISR, NVIC, timer overflow, PWM, watchdog, systick                     | ISR: handler cepat, tidak blocking, tidak malloc. NVIC: nested interrupt priority. Watchdog: reset MCU jika hang. Timer: counting register → trigger interrupt                                                  | ISR terlalu lama → missing interrupt berikutnya. Shared data ISR vs main loop tanpa atomic → race condition. Watchdog tidak di-kick → unexpected reset |
| **Level 3** — Bare-Metal Memory            | Stack, heap, linker script, memory map, DMA                           | Semua physical memory — tidak ada virtual memory. Linker script: define region flash/RAM/stack/heap. Stack overflow → corrupt global variable diam-diam. DMA: transfer data antara peripheral dan RAM tanpa CPU | Stack overflow tidak terdeteksi tanpa canary manual. Heap fragmentation di long-running → alloc fail setelah hari. `malloc` di embedded berbahaya      |
| **Level 4** — RTOS                         | FreeRTOS, Zephyr, ThreadX, Mbed OS, task scheduling, semaphore, queue | RTOS: scheduler guarantee timing. Task dengan priority. Preemptive: interrupt task rendah. Semaphore/mutex: koordinasi. Queue: komunikasi data antar task                                                       | Priority inversion: task tinggi diblok task rendah pegang resource. Stack overflow per task tidak terdeteksi. Context switch overhead                  |
| **Level 5** — Firmware Update & Bootloader | Bootloader, OTA, A/B partition, secure boot, rollback protection      | Bootloader: pilih image yang di-load. A/B partition: inactive slot update → swap jika sukses. Secure boot: verify signature sebelum execute. Rollback: anti-downgrade via counter                               | Update gagal tanpa A/B = brick. Bootloader tanpa secure boot → flash firmware jahat. OTA tanpa enkripsi → MITM                                         |
| **Level 6** — Sensor Fusion & Control      | PID, Kalman filter, IMU, LiDAR, SLAM                                  | Sensor fusion: kombinasi multiple sensor untuk estimasi state lebih akurat. Kalman filter: optimal estimator untuk linear system. PID: feedback control. SLAM: lokasi + peta                                    | Kalman diverge jika noise model salah. PID tanpa tuning → oscillation. IMU accumulation error → drift                                                  |
| **☠️ Level 7** — Safety-Critical           | IEC 61508 (SIL 1–4), ISO 26262 (ASIL), DO-178C, MISRA C, formal proof | SIL-4 tertinggi (nuklir). Persyaratan: no dynamic allocation, no recursion, semua path test-covered, formal proof. MISRA C: safe C subset                                                                       | Sertifikasi butuh tahun + biaya besar. Formal verification butuh expert (Frama-C, SPARK Ada). Mayoritas developer tidak pernah menyentuh               |

---

## Peta Visual — Abstraksi vs Kontrol

```
Abstraksi ↑
L7 ─ Safety-Certified ●──●●●● Control ↓
L6 ─ Sensor Fusion    ●──●●●
L5 ─ Bootloader/OTA  ●──●●
L4 ─ RTOS            ●──●
L3 ─ Memory Mgmt     ●──
L2 ─ Interrupt       ●─
L1 ─ Protocols       ●
L0 ─ GPIO/Register   ● (kontrol penuh atas hardware)
    └───────────────────→ Control atas hardware
```

---

## Kenapa Hirarki Ini Penting

### 1. Embedded = Dunia Tanpa OS — Semua Tanggung Jawab Padamu

Tidak ada memory protection (kecuali MPU di ARM Cortex-M). Tidak ada process isolation. Satu buffer overflow = corrupt program counter = crash atau RCE. **Setiap level menambah abstraksi yang menambah safety — tapi juga menambah potensi bug dari abstraksi itu sendiri.**

### 2. RTOS (L4) vs Bare-Metal (L0–L3) — Trade-off Besar

| Aspek          | Bare-Metal                | RTOS                        |
| -------------- | ------------------------- | --------------------------- |
| Complexity     | Rendah                    | Tinggi                      |
| Determinism    | Tinggi (lo kontrol penuh) | Medium (scheduler overhead) |
| Task isolation | Tidak ada                 | Ada (task stack separate)   |
| Debugging      | Mudah (sekuensial)        | Sulit (task switching)      |
| Reusability    | Rendah                    | Tinggi (modular task)       |

Pilih bare-metal kalau MCU sangat kecil (8-bit, RAM < 4KB) atau kebutuhan real-time sangat ketat. Pilih RTOS kalau ada ≥3 task concurrent.

### 3. Safety-Critical (L7) = Level Paling Mahal

Sertifikasi SIL/ASIL/DO-178C bisa menghabiskan **USD 1–10 juta** per produk. Ini bukan untuk produk konsumen. Tapi untuk airbag ECU, flight control, medical implant — tidak ada alternatif.

---

## Plot Twists

> [!danger] Plot Twist 1: 80% IoT Device Pakai Level 0–1 — Tanpa Proteksi
> ESP32, Arduino, STM32 — mayoritas development di Level 0–1 (GPIO + protokol). Tidak ada RTOS, tidak ada secure boot, tidak ada memory protection. Hasil: **satu buffer overflow = RCE penuh**. Inilah mengapa IoT botnet (Mirai) masih relevan — device embedded tanpa proteksi.

> [!tip] Plot Twist 2: DMA (L3) Adalah "Backdoor" ke Memory
> DMA (Direct Memory Access) bisa baca/tulis memory tanpa CPU. Kalau attacker bisa control DMA controller → bisa baca RAM berisi kunci enkripsi, credential, atau flash dump. DMA attack adalah vector favorit untuk ekstraksi key dari embedded device (lihat: PCILeech untuk FPGA-based DMA attack via Thunderbolt).

> [!info] Plot Twist 3: Safety-Critical (L7) Paling Sering Violated oleh Update OTA
> Ironi: produk yang certified SIL-4 di produksi → OTA update firmware → certified void. Kenapa? Karena update OTA bisa me-load firmware yang tidak melalui proses sertifikasi. **Update OTA dan safety certification adalah contradiction in terms** — solusi: re-certify setiap update (mahal) atau gunakan dual-channel dengan verified boot.

---

## Sumber & Telusur Lebih Lanjut

- **Embedded Systems Lengkap** → [[embedded-systems]] (Sheet 1 + Sheet 2 Flash Forensics)
- **Hardware Hacking (debugging HW)** → [[hierarchy-hardware-hacking]] (UART, JTAG, flash dump)
- **Firmware RE** → [[firmware-reverse-engineering-deepdive]] (firmware extraction, analysis)
- **RTOS (FreeRTOS)** → [[firmware-re-roadmap]] (learning roadmap)
- **Computer Architecture (underlying HW)** → [[hierarchy-abstraction-layers]] (register level analogy)
- **Master Index** → [[master-index]]

---

> Embedded systems adalah dunia di mana **software bertemu hardware** — dan di situlah bug paling berbahaya lahir. Pilih level yang sesuai dengan safety requirement targetmu. Untuk IoT lampu kamar — Level 2 (interrupt + timer) sudah cukup. Untuk airbag mobil — Level 7 (SIL-4) atau jangan dijual.

_Embedded Systems Hierarchy | Level 0 (GPIO/Register) → Level 7 (Safety-Critical) · Dunia Tanpa OS, Semua Tanggung Jawab Padamu_
