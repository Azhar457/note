---
tags:
  - endpoint-security
  - blue-team
  - red-team
  - rootkit
  - byovd
  - firmware
  - cpu-ring
aliases:
  - Endpoint Security
  - CPU Ring Hierarchy
  - Virus Endpoint
created: 2026-04-25
status: operational
cssclasses:
  - wide-table
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

- [[MASTER_INDEX]]
- [[NETWORK_SECURITY]] — OSI Layer 1–8 Blue/Red Team
- [[DATA_RECOVERY]] — Partition & Data Recovery Level 0–7
- [[FONDASI_CS]] — OS Internals (Kernel Module, Hypervisor)
- [[UNDERGROUND_KNOWLEDGE]] — BYOVD overlap di Cheat Engine Level 3
- [[RE_HARDWARE_HACKING]] — Firmware RE sebagai vektor analisis

---

_Endpoint Security | CPU Ring -3 sampai Ring 3 · Boot Chain Threat Landscape_
