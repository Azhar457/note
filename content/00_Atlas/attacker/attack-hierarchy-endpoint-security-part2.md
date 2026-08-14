---
title: Attack Perspective — Endpoint Security Part 2 (Ring -3, Ring -2, Hypervisor, References)
tags:
- attack
- red-team
- endpoint-security
- intel-me
- smm
- hypervisor
- firmware
source: hierarchy-endpoint-security.md (part 2)
status: complete
created: '2026-08-14'
updated: '2026-08-14'
---

cssclasses:
  - wide-table
  - callout

# 🔴 Attack Perspective: Endpoint Security — Deep Layers (Ring -2 → Ring -3)

> Lanjutan dari `attack-hierarchy-endpoint-security.md` (bagian 1: Ring 3 → Pre-Boot). Bagian ini fokus pada layer paling dalam: SMM, Hypervisor, dan Sub-Firmware (Intel ME / AMD PSP).

---

## 2.1 Ring -2 — System Management Mode (SMM)

**Apa itu:** SMM = System Management Mode — mode CPU khusus yang diaktifkan oleh System Management Interrupt (SMI). OS sepenuhnya buta terhadap operasi di SMM. Semua syscall, semua memory access, semua EDR hook — tidak berfungsi saat CPU di SMM mode.

**Attacker Capability:**
- Intercept semua firmware event (boot, shutdown, power state, thermal event)
- Modify boot chain sebelum OS menyala — insert rootkit sebelum kernel
- Bypass semua OS-level defense — OS tidak bisa deteksi operasi SMM
- Persist di firmware SPI — survive format disk, reinstall OS, ganti SSD

**Concrete CVE / Tool / Technique:**
- **LoJax (Fancy Bear / APT28, 2018)** — UEFI rootkit pertama in-the-wild yang survive OS reinstall. LoJax inject malicious module ke SPI flash — saat boot, malicious module load sebelum OS — OS tidak pernah tahu.
- **SMM Rootkit (theoretical/proof of concept)** — Custom SMI handler yang intercept boot → inject malicious code ke boot chain → persist
- **CHIPSEC** — Intel open source tool untuk audit firmware modules — tapi butuh akses fisik + expert — jarang dipakai

**Evasion Strategy:**
- Operasi hanya saat SMI trigger (thermal, power event) — tidak meninggalkan trace di OS
- Intercept firmware event → modify event handler → inject malicious code → return ke OS → OS tidak pernah tahu operasi terjadi
- Persist di SPI flash — tidak ada file di disk — OS-level scan (antivirus, EDR) tidak bisa deteksi

**Defender Detection Gap:**
- OS-level tool (antivirus, EDR, SIEM, sysmon) — **mustahil deteksi** operasi SMM — OS buta
- CHIPSEC (Intel open source) — bisa audit firmware module — tapi butuh akses fisik + expert level — jarang dilakukan
- Intel Boot Guard — vendor lock — hanya vendor bisa verify firmware integrity — konsumen tidak punya akses
- SMM Lockdown Policy — bisa disable SMI handler yang tidak perlu — tapi jarang di-enable di consumer device

**Red Team Strategy:**
- Target device dengan SMM lockdown disabled (consumer laptop, server tanpa hardening)
- Gunakan LoJax (public exploit chain) atau custom SMM rootkit (proof of concept)
- Inject malicious module ke SPI flash — persist — survive semua defense OS
- Operasi di SMM — bypass semua EDR, semua sysmon, semua audit log — OS tidak pernah tahu

---

## 2.2 Ring -1 — Hypervisor / VMM (Virtual Machine Monitor)

**Apa itu:** Hypervisor = software yang mengelola virtual machine. Ring -1 dalam konteks x86 privilege ring (walaupun secara teknis hypervisor berjalan di Ring 0 — tapi dengan privilege lebih tinggi dari OS guest). OS guest (Ring 0 dalam VM) — semua syscall lewat hypervisor — hypervisor bisa intercept semua operasi sebelum sampai ke hardware.

**Attacker Capability:**
- Intercept semua syscall dari OS guest — OS tidak tahu operasi sebenarnya
- Modify memory access — OS mengira memory = original — tapi hypervisor bisa inject malicious code
- Bypass semua OS-level defense — EDR, antivirus, sysmon — tidak berfungsi jika hypervisor intercept syscall
- Persist di hypervisor layer — survive OS reinstall (jika hypervisor tetap ter-install)

**Concrete CVE / Tool / Technique:**
- **Blue Pill (historical, 2006)** — Proof of concept hypervisor rootkit — hypervisor load di bawah OS — OS tidak tahu — semua syscall di-intercept
- **vBootkit** — UEFI-based hypervisor rootkit — persist di Pre-Boot → load hypervisor → OS berjalan di hypervisor
- **VM Escape** — CVE-2015-3456 (VENOM — QEMU virtual floppy controller buffer overflow) — VM escape → hypervisor access
- **Hypervisor Rootkit (custom)** — Load hypervisor di bawah OS → intercept semua syscall → inject malicious operation → OS tidak pernah tahu

**Evasion Strategy:**
- Load hypervisor sebelum OS — OS mengira dirinya bare-metal — semua defense OS (EDR, antivirus, sysmon) tidak bisa deteksi hypervisor
- Intercept syscall — OS panggil syscall → hypervisor intercept → inject malicious operation → return ke OS → OS tidak tahu operasi di-modify
- Persist di hypervisor layer — jika hypervisor tidak di-uninstall — persist survive OS reinstall

**Defender Detection Gap:**
- OS-level tool (antivirus, EDR, sysmon, SIEM) — **mustahil deteksi** hypervisor rootkit — OS berjalan di dalam hypervisor — hypervisor bisa intercept semua telemetry
- Hypervisor-level audit — jarang dilakukan — butuh hypervisor-level tool (VMware vSphere audit, Hyper-V audit)
- Hardware attestation (Intel TXT, AMD SEV) — bisa deteksi hypervisor yang tidak ter-verifikasi — tapi jarang di-enable
- Measured boot (TPM PCR) — bisa deteksi boot chain yang tidak sesuai — tapi jarang digunakan untuk hypervisor audit

**Red Team Strategy:**
- Target VM dengan hypervisor yang tidak ter-audit (consumer VM, cloud instance tanpa measured boot)
- Gunakan VM escape exploit (CVE-2015-3456 VENOM) atau custom hypervisor rootkit
- Load hypervisor di bawah OS → intercept semua syscall → bypass semua defense OS
- Persist di hypervisor layer — jika hypervisor tidak di-uninstall — persist survive OS reinstall

---

## 2.3 Ring -3 — Intel Management Engine (ME) / AMD Platform Security Processor (PSP)

**Apa itu:** Intel ME = Management Engine — prosesor terpisah (bukan CPU utama) yang selalu ON — bahkan saat laptop "mati" (power off tapi kabel ter-plug). AMD PSP = Platform Security Processor — sama fungsinya. Prosesor sekunder ini menjalankan firmware terpisah — OS utama tidak punya akses — semua operasi di Ring -3 tidak terlihat dari OS.

**Attacker Capability:**
- Akses penuh ke hardware — memory, network, storage — tanpa OS tahu
- Remote access (jika ME/PSP interface aktif) — access ke sistem tanpa user login
- Persist di firmware SPI — survive format disk, reinstall OS, ganti SSD, ganti CPU (jika ME chip terpisah)
- Intercept semua komunikasi — network traffic, USB data, storage access — OS tidak tahu

**Concrete CVE / Tool / Technique:**
- **Intel ME Exploit (CVE-2017-5705)** — Intel AMT — remote administration access — attacker bisa akses sistem tanpa user login — remote code execution di Ring -3
- **NSA ANT Catalog (COTTONMOUTH, IRATEMONK)** — Firmware implant — implant di Intel ME / firmware — remote access + data exfil — tidak terdeteksi dari OS
- **BlackLotus (2023)** — UEFI rootkit yang bisa bypass Secure Boot — tapi juga bisa digunakan untuk inject ke firmware — chain ke Ring -3 jika exploit berhasil
- **Intel Boot Guard Bypass (CVE-2022-0001)** — Bypass Secure Boot — memungkinkan UEFI rootkit — chain ke firmware implant

**Evasion Strategy:**
- Operasi di prosesor sekunder — OS dan semua software defense (antivirus, EDR, sysmon, SIEM) — **mustahil deteksi** — OS tidak punya akses ke Ring -3
- Remote access — access sistem tanpa user login — tidak meninggalkan trace di user log
- Persist di firmware SPI — survive semua defense software — hanya hardware audit yang bisa deteksi

**Defender Detection Gap:**
- OS-level tool — **mustahil deteksi** — OS tidak punya akses ke Ring -3
- Vendor audit (Intel Boot Guard, AMD PSP audit) — hanya vendor bisa verifikasi — konsumen jarang punya akses
- Hardware scanner komersial (Eclypsium) — bisa deteksi firmware implant — tapi mahal + jarang dipakai
- Supply chain verification — memastikan firmware tidak di-modify saat produksi — tapi jarang dilakukan (kecuali militer / intelijen)

**Red Team Strategy:**
- Target device dengan Intel ME / AMD PSP yang aktif (hampir semua device modern)
- Gunakan CVE-2017-5705 (Intel AMT RCE) — jika target punya Intel AMT aktif — remote access langsung ke Ring -3
- Gunakan firmware implant chain (BlackLotus → SPI implant) — jika akses fisik tersedia — persist di firmware → survive semua
- Operasi di Ring -3 — semua telemetry OS tidak bisa deteksi — full stealth

---

## 6. Operational Security (OpSec) — Deep Layer Attack

1. **Ring 3:** In-memory payload (BOF, DONUT) — no disk touch — AMSI/ETW bypass — timestamp manipulation — cleanup otomatis saat exit
2. **Ring 0:** Direct syscall + module stomping — driver load (BYOVD) — unload setelah operasi — no driver trace — PPL bypass (custom Mimikatz build) — LSASS dump — cleanup memory
3. **Pre-Boot / UEFI:** SPI flash modification — backup original SPI → modify → write back — jika deteksi — restore original — UEFI implant (LoJax chain) — persist — survive reinstall
4. **Ring -2 / SMM:** SMM handler modification — intercept boot event — inject malicious code — return — OS tidak tahu — CHIPSEC audit jarang — full stealth
5. **Ring -3:** Intel ME / AMD PSP — remote access (CVE-2017-5705) — operasi di prosesor sekunder — OS blind — vendor audit jarang — full stealth — highest opsec
6. **Physical:** USB drop (BadUSB) — device drop ke target location — physical access — SPI flash access — firmware implant — survive semua

---

## 7. References (Deep Layer)

- Intel ME / AMD PSP — https://me.bios.dev/, https://www.blackhat.com/docs/us-17/thursday/us-17-Eiram-Cybereason-The-Intel-ME-Investigation.pdf
- LoJax / UEFI Rootkit — https://www.welivesecurity.com/2018/09/27/lojax-first-uefi-rootkit-found-wild-courtesy-sednit-group/
- BlackLotus — https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/
- CHIPSEC — https://github.com/chipsec/chipsec
- System Management Mode (SMM) — https://github.com/chipsec/chipsec_util
- BYOVD — https://www.crowdstrike.com/blog/exploiting-cve-2023-4911/
- Direct Syscalls — https://github.com/jackullrich/SysWhispers3, https://github.com/vxunderground/HellsGate
- UEFI Secure Boot — https://docs.microsoft.com/en-us/windows-hardware/design/device-experiences/oem-secure-boot
- Intel Boot Guard — https://www.intel.com/content/www/us/en/developer/articles/technical/boot-guard-approach-to-secure-boot.html
- SpecterOps (AD Security) — https://posts.specterops.io/
- The DFIR Report — https://thedfirreport.com/
