---
tags:
- endpoint-security
- blue-team
- red-team
- rootkit
- BYOVD
- firmware
- CPU-ring
aliases:
- Endpoint Security
- CPU Ring Hierarchy
- Virus Endpoint
created: 2026-04-25
status: pending
title: Endpoint Security
updated: '2026-07-01'
cssclasses:
  - wide-table
  - callout

---

# 🦠 ENDPOINT SECURITY — CPU Ring & Boot Chain

> Setiap ancaman punya "alamat" di CPU Ring. Semakin kecil angka Ring, semakin dalam aksesnya ke hardware — dan semakin sulit dideteksi. MBR Bootkit duduk di **Pre-OS** — aktif _sebelum_ kernel Ring 0 sempat menyala.

> [!info] Cara Baca
> Ring = Privilege level CPU. Kolom Blue Team = apa yang bisa dilakukan defender. Kolom Red Team = apa yang dipakai attacker. Baca dari bawah (Ring 3) ke atas (Ring -3) untuk memahami eskalasi privilege.

---

## Tabel Threat per CPU Ring & Boot Stage

| Lapisan                          | CPU Ring / Boot Stage                                      | ☣️ Threat yang Bersarang                                                                         | 🔵 Blue Team (Defender)                                                                  | 🔴 Red Team (Attacker)                                                          |
| -------------------------------- | ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------- |
| **Intel ME / AMD PSP**           | Ring **-3** _(Prosesor terpisah, selalu ON)_               | Supply chain implant langsung dari pabrik — tidak terdeteksi OS apapun                           | Eclypsium Hardware Scan, vendor audit board, ME firmware disable (jika didukung)         | NSA ANT Catalog (COTTONMOUTH, IRATEMONK), firmware backdoor pabrik nation-state |
| **SMM — System Management Mode** | Ring **-2** _(Firmware interrupt, OS buta total)_          | SMM Rootkit — berjalan di interrupt tersembunyi yang OS tidak pernah lihat                       | CHIPSEC, vendor SMM lockdown policy, Intel Boot Guard                                    | LoJax (Fancy Bear / APT28), SMM implant custom                                  |
| **Hypervisor / VMM**             | Ring **-1** _(Virtual Machine Monitor)_                    | Hypervisor Rootkit — mengangkat OS yang asli menjadi VM tanpa sepengetahuan pengguna             | Intel TXT, AMD SEV, Hyper-V SLAT, measured boot via TPM                                  | Blue Pill, vBootkit, VM escape exploit                                          |
| **UEFI / BIOS Firmware**         | **Pre-Boot** _(sebelum bootloader dipanggil)_              | UEFI Implant — survive format ulang & ganti SSD karena bersarang di cip ROM motherboard          | UEFI Secure Boot, TPM 2.0 attestation, Eclypsium UEFI scan                               | MoonBounce, CosmicStrand, BlackLotus (bypass Secure Boot Windows 11)            |
| **MBR / VBR / Bootloader**       | **Pre-OS** _(setelah UEFI, sebelum kernel Ring 0 menyala)_ | MBR Bootkit — menuliskan dirinya ke sektor 0 disk, aktif lebih dulu dari Windows/Linux manapun   | BitLocker + Secure Boot chain, integrity check via TPM PCR, `bootrec /fixmbr`            | TDL4, Necurs, Petya/NotPetya MBR wiper, GRUB-based bootkit                      |
| **Kernel & Driver**              | Ring **0** _(OS Kernel, driver hardware)_                  | Kernel Rootkit, driver exploit, BYOVD — menunggangi driver legitimate yang sudah punya signature | EDR kernel driver (CrowdStrike, SentinelOne, Wazuh), Windows DSE enforcement, PatchGuard | Kernel rootkit, driver signing bypass, BYOVD (Bring Your Own Vulnerable Driver) |
| **User Space**                   | Ring **3** _(Aplikasi biasa)_                              | Ransomware, RAT, trojan, spyware, fileless malware di memori                                     | Antivirus, EDR user-agent, application whitelisting (AppLocker), sandboxing              | Metasploit, Cobalt Strike, Havoc C2, PowerShell Empire                          |

---

## Peta Posisi Threat — Endpoint

```
Ring -3  │ Intel ME / AMD PSP Implant  → Tidak ada software yang bisa deteksi
Ring -2  │ SMM Rootkit (LoJax)         → Survive ganti motherboard
Ring -1  │ Hypervisor Rootkit          → OS mengira dirinya bare-metal
Pre-Boot │ UEFI Implant                → Survive format & ganti SSD
Pre-OS   │ ← MBR BOOTKIT DI SINI      → Aktif sebelum Windows menyala
Ring 0   │ Kernel Rootkit              → EDR bisa lawan, tapi arms race terus
Ring 3   │ Ransomware, RAT, Trojan     → Yang 99% orang kenal sebagai "virus"
```

> [!warning] BYOVD: Senjata Ganda
> Bring Your Own Vulnerable Driver (BYOVD) di Ring 0 bukan hanya teknik cheat game — ini **teknik APT nyata** yang digunakan BlackByte ransomware dan Lazarus Group untuk mematikan EDR. Driver lama yang punya signature valid tapi vulnerable di-load, di-exploit, dan digunakan untuk mendapat akses Ring 0.

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[network-security|Network Security]] — OSI Layer 1–8 Blue/Red Team
- [[data-recovery|Data Recovery]] — Partition & Data Recovery Level 0–7
- [[computer-science-foundations|Computer Science Foundations]] — OS Internals (Kernel Module, Hypervisor)
- [[underground-knowledge|Underground Knowledge]] — BYOVD overlap di Cheat Engine Level 3
- [[hardware-hacking-re|Hardware Hacking]] — Firmware RE sebagai vektor analisis

---

## Deepdive — BYOVD & Kernel Attack Chain

### BYOVD (Bring Your Own Vulnerable Driver)

BYOVD = teknik di mana attacker membawa driver lama yang punya signature valid tapi vulnerable untuk mendapat akses Ring 0 tanpa perlu zero-day kernel. Driver seperti `RTCore64.sys` (MSI Afterburner), `gdrv.sys` (Gigabyte), `iqvw64e.sys` (Intel) punya CVE untuk arbitrary read/write kernel memory. Serangan: 1) deploy driver vulnerable (tidak butuh admin jika sudah SYSTEM atau via abuse signed service), 2) exploit vulnerability untuk read/write kernel memory, 3) patch EDR kernel callback (`PsSetCreateProcessNotifyRoutine`) → EDR buta. Kasus nyata: BlackByte ransomware pakai `RTCore64.sys` untuk kill AV, Lazarus Group pakai driver lain untuk disable EDR. Mitigation: Microsoft Vulnerable Driver Blocklist (Windows 11 22H2+), WDAC (Windows Defender Application Control) untuk block driver loading.

### Bootkit Persistence Chain

Bootkit = implant dulu sebelum kernel menyala. Diagram alur serangan MBR/VBR dan UEFI implant, dari initial compromise sampai persistence permanen:

```
Initial Access (Ring 3):
  Phishing / exploit → user context → privesc → SYSTEM
    ↓
Firmware Access (Pre-OS):
  Flash tools (flashrom / UEFITool) → SPI flash write
    ↓
Persistence Level:
  MBR/VBR → overwrite sector 0 (disk-based, cukan kalau format)
  UEFI → flash chip (motherboard, survive format + SSD swap)
  SMM → interrupt hook (survive firmware reflash jika locked)
    ↓
Execution (Pre-kernel):
  Bootkit loads before kernel → patch kernel image in memory
    ↓
Kernel Hook (Ring 0):
  Bootkit injects rootkit module → kernel runs with backdoor
    ↓
Detection:
  EDR blind (pre-OS) → hanya vendor tools (CHIPSEC, Eclypsium)
  TPM PCR measurement → dapat detect tapi hanya jika measured boot aktif
```

### EDR Bypass Techniques (Ring 0 → Ring 3)

| Teknik | Target | Impact | Detection |
|--------|--------|--------|-----------|
| **Direct Syscall** | EDR userland hook | Bypass ntdll hook | Sysmon Event 1 (process) |
| **Callback Patch** | PsSetCreateProcessNotifyRoutine | EDR kernel blind | PatchGuard detection |
| **Kernel-mode RW** | EDR driver memory | Tamper EDR signature | Memory integrity scan |
| **BYOVD** | EDR kernel callback | Kill EDR process | Driver blocklist |
| **Hypervisor** | EDR entire system | EDR runs inside VM | Nested virt detect |

### Tool Stack — Endpoint Attack & Defense

| Tool | Ring | Use |
|------|------|-----|
| **BYOVDKit / D Edmonton** | Ring 0 | BYOVD framework |
| **KDU (Kernel Driver Utility)** | Ring 0 | Vulnerable driver loader |
| **CHIPSEC** | Ring -2/-1 | UEFI/SMM audit |
| **Eclypsium** | Ring -3 | Hardware/firmware scan |
| **PCILeech** | Ring -1 | DMA memory read/write |

### References

- BYOVD Research — https://loldrivers.io/
- BlackLotus UEFI — https://www.welivesecurity.com/2023/03/01/blacklotus-uefi-bootkit-myth-confirmed/
- Microsoft Vulnerable Driver Blocklist — https://learn.microsoft.com/en-us/windows/security/threat-protection/microsoft-defender-application-control/microsoft-recommended-driver-block-rules
- CHIPSEC — https://github.com/chipsec/chipsec
- LoJax (APT28) — https://www.welivesecurity.com/2018/09/27/lojax-first-uefi-rootkit-found-wild-cosmic-strand/

---

*Endpoint Security | CPU Ring -3 sampai Ring 3 · Boot Chain Threat Landscape*