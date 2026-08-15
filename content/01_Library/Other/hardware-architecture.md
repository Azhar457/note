---
title: Hardware Architecture
tags: [atlas, hardware]
aliases: [hardware-architecture]
---
# Hardware Architecture

Peta arsitektur perangkat keras: (1) **CPU** — ISA (x86, ARM, RISC-V), mikroarsitektur (pipelining, speculative execution, cache), side-channel (Meltdown/Spectre family); (2) **Memory** — hierarchy (register, cache, RAM, disk), DDR, ECC, Rowhammer; (3) **Peripheral & Bus** — PCIe, USB, SPI/I2C/UART (firmware/hardware hacking), DMA; (4) **Boot** — BIOS/UEFI, secure boot, BootROM, Intel ME/AMD PSP; (5) **SoC/Embedded** — ARM Cortex, MMIO, TrustZone; (6) **Attacks fisik** — glitching, side-channel power/EM, chip-off, JTAG.

Hubungkan: Firmware RE (01_Library/Firmware_RE), Hardware hacking skill, hierarchy-recursive-ring (ring -3 sampai 3). Untuk pentest fisik/hardware CTF, lihat roadmap firmware.
---

  audited
---