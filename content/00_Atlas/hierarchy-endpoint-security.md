---
title: Hierarchy Endpoint Security
tags:
- atlas
- endpoint-security
- blue-team
- CPU-ring
- firmware
created: '2026-07-17'
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  
---


# 🛡️ HIERARKI ENDPOINT SECURITY — Dari Ring 3 sampai Sub-Firmware (Ring -3)

> Setiap byte yang diproses CPU melewati hierarki privilege yang sudah ditetapkan sejak arsitektur Intel x86 dirancang di tahun 1978. **Semakin kecil angka Ring, semakin dalam akses ke hardware — dan semakin buta OS terhadap apa yang terjadi di sana.** File ini adalah peta konsepnya. Untuk tools defender per Ring, lihat [[endpoint-security-freeware]]. Untuk threat landscape (Blue vs Red), lihat [[endpoint-security]].

> [!info] Cara Baca
> Baca dari bawah ke atas — dari Ring 3 (aplikasi biasa) sampai Ring -3 (prosesor sekunder yang selalu ON). Setiap naik satu Ring, attacker mendapat kemampuan lebih besar DAN defender mendapat visibilitas lebih kecil. Pre-OS dan Pre-Boot bukan "Ring" dalam artian CPU klasik — itu *sebelum* CPU privilege hierarchy sempat berlaku.

---

## Tabel Utama — Ring 3 sampai Pre-Firmware

| 🛡️ Lapisan | 🧠 Zona | ⚡ Siapa yang Beroperasi di Sini | ☠️ Tembok Defender | 🎯 Use Case Riil & Contoh |
|---|---|---|---|---|
| **Sub-Firmware (Ring -3)** | Intel ME / AMD PSP — **prosesor terpisah**, selalu ON, bahkan saat laptop "mati" | NSA ANT Catalog (COTTONMOUTH, IRATEMONK), supply chain implant langsung dari pabrik | Tidak ada yang bisa deteksi dari software. Hanya vendor audit + hardware scanner (Eclypsium = commercial) | Nation-state APT. Cia 0day vault leak menunjukkan 6+ implan level ini. Open source ecosystem belum punya replacement |
| **Ring -2** | SMM (System Management Mode) — firmware interrupt handler, **OS buta total** | LoJax (Fancy Bear / APT28, 2018) — UEFI rootkit pertama yang in-the-wild | CHIPSEC (Intel open source), Intel Boot Guard vendor lock, SMM lockdown policy | Advanced persistent threat. Bisa survive OS reinstall, sering jadi target intelijen |
| **Ring -1** | Hypervisor / VMM — Virtual Machine Monitor | Blue Pill (historical, 2006), vBootkit, VM escape exploit | Intel TXT, AMD SEV, Hyper-V SLAT, measured boot via TPM | Nation-state lab, advanced red team. Saat attacker sudah di sini, OS mengira dirinya bare-metal |
| **Pre-Boot** | UEFI / BIOS Firmware — sebelum bootloader dipanggil. Tinggal di **SPI flash chip** | MoonBounce (Kaspersky 2022), CosmicStrand (2022), BlackLotus (2023 — bypass Secure Boot Windows 11) | UEFI Secure Boot, TPM 2.0 attestation, fwupd + LVFS for vendor-signed updates | Targeted attack pada high-value target. BlackLotus dijual di darkweb USD $5.000 |
| **Pre-OS** | MBR / VBR / Bootloader — **setelah UEFI, sebelum kernel Ring 0 menyala** | TDL4, Necurs, Petya/NotPetya (MBR wiper 2017), GRUB-based bootkit | BitLocker + Secure Boot chain, TPM PCR integrity check, `bootrec /fixmbr` | Ransomware destroy-and-extort (NotPetya rugi USD 10 miliar global). Masih efektif di Windows tanpa Secure Boot |
| **Ring 0** | OS Kernel + Driver — jantung OS. **Semua syscall lewat sini** | BYOVD (Bring Your Own Vulnerable Driver), kernel rootkit, driver signing bypass | EDR kernel callback (CrowdStrike, SentinelOne, Wazuh), Windows DSE, PatchGuard, SELinux enforcing | APT post-intrusion. Lazarus Group pakai BYOVD untuk disable EDR. Cheat game cheat level 3+ juga di sini |
| **Ring 3** | User Space — aplikasi biasa, **99% orang kenal ini sebagai "virus"** | Ransomware (WannaCry, LockBit), RAT, trojan, spyware, fileless malware di memori | Antivirus, EDR user-agent, AppLocker, sandboxing, PowerShell Constrained Language Mode | Bulk cybercrime. Initial access vector jauh lebih umum (phishing, drive-by download) |

---

## Peta Visual — Privilege vs Visibility

```
                    ↑ Privilege Meninggi
                    │ Visibility Defender Menurun
                    │
    Ring -3 ────────┼──── Intel ME / AMD PSP
                    │       (tidak terdeteksi OS apapun)
    Ring -2 ────────┼──── SMM (interrupt tersembunyi)
                    │
    Ring -1 ────────┼──── Hypervisor / VMM
                    │       (OS mengira bare-metal)
    Pre-Boot ───────┼──── UEFI / BIOS SPI flash
                    │       (survive format & ganti SSD)
                    │
   ──── OS belum nyala ────
                    │
    Pre-OS ─────────┼──── MBR / VBR / Bootloader
                    │       ← NotPetya, Petya wiper di sini
                    │
    Ring 0 ─────────┼──── Kernel + Driver
                    │       (BYOVD cheat game & APT)
                    │
    Ring 3 ─────────┼──── User Space Application
                    │       (ransomware umum, RAT, trojan)
                    ↓ Privilege Menurun
                    ↓ Visibility Defender Meningkat
```

> [!warning] Inversi Privilege–Visibility
> Konsep inti hierarki ini adalah **inversi paradoks**: privilege naik, visibility defender turun. Ring 3 gampang dideteksi (antivirus regular cukup). Ring -3 *mustahil* dideteksi dari software alone. Inilah kenapa target pemerintah & korporasi besar butuh hardware attestation (TPM, HSM) — software-only defense mandek di Ring 0.

---

## Kenapa Hirarki Ini Penting

### 1. Setiap Komputer Punya Stack Ini — Tanpa Pengecualian

Windows, macOS, Linux, FreeBSD — semua menjalankan CPU x86 atau ARM. Semua CPU modern mengimplementasikan privilege ring (atau **exception level** di ARM: EL0 = Ring 3, EL1 = Ring 0, EL2 = hypervisor, EL3 = firmware). Hirarki ini bukan fitur OS — ini **fitur hardware**. Mau pake OS apapun, hirarkinya ada.

### 2. Boot Chain Adalah Single-Point-of-Failure

Satu kompromi di Ring -3, -2, atau Pre-Boot = total kompromi ke semua ring di bawahnya. Ini sebabnya:
- Stuxnet (2010) menyebar via USB dan menulis MBR — tidak butuh eksploitasi OS sama sekali
- NotPetya (2017) punya **kapabilitas wiper** yang aktif sebelum Windows bisa boot
- MoonBounce (2022) survive reinstall OS karena tinggal di SPI flash

OS-level defense (antivirus, EDR) **buta terhadap semua layer di atas Ring 0**.

### 3. Threat Model Bergantung pada Target

| Target | Layer yang Harus Dipertahankan |
|---|---|
| **Pengguna rumahan** | Ring 3 + Ring 0 (antivirus + Windows Update cukup) |
| **Perusahaan kecil** | Ring 3, Ring 0, Pre-OS (Secure Boot + EDR + backup) |
| **Korporasi enterprise** | + Pre-Boot (TPM attestation, firmware audit berkala) |
| **Government / Critical infra** | + Ring -1 (measured boot, hypervisor isolation) |
| **Militer / Intelijen** | + Ring -2 dan -3 (vendor firmware audit, supply chain integrity, hardware disable Intel ME jika feasible) |

Naik hierarki → effort + cost eksponensial. SMB tidak butuh vendor firmware audit sama sekali. NSA butuh.

### 4. Dual-Use Knowledge: Defender dan Attacker Paham Hierarki Ini

Setiap red teamer paham hirarki privilege — karena itulah **rute hidup** mereka: dari Ring 3 (phishing initial access) → escalate ke Ring 0 (BYOVD disable EDR) → persist di Pre-Boot (UEFI implant). Tanpa paham hierarki, lo cuma bisa nyangkut di Ring 3 — yang artinya lo cuma script kiddie.

---

## Plot Twists

> [!danger] Plot Twist 1: BYOVD Bukan Bug — Itu Fitur
> Di Ring 0, OS Microsoft mengizinkan driverkernel **third-party** untuk di-load jikasigned oleh vendor legitimate. Driver tua yang vulnerable (CVE-2015-0003, CVE-2019-16098) masih punya signature valid. Attacker load driver itu → exploit kernel → DISABLE EDR. **Anti-cheat game (EasyAntiCheat, BattlEyE) pakai teknik sama untuk deteksi cheat.** BYOVD adalah dual-use: cheat game & APT disable defense. BlackByte ransomware + Lazarus Group pakai BYOVD di alam liar.

> [!danger] Plot Twist 2: Modern OS Tidak Lagi Single-Ring
> Saat Windows boot di atas UEFI Secure Boot + Measured Boot + Credential Guard + HVCI + VBS — yang sebenarnya berjalan bukan OS tradisional. Ada **virtualization-based security** (VBS) yang membuat OS sendiri jadi "VM di dalam hypervisor Microsoft." Ring 0 yang defender liat **bukan Ring 0 yang sebenarnya** — attacker mengeksploit Ring 0 OS, tapi Ring 0 *asli* adalah hypervisor Microsoft. Inilah kenapa PatchGuard + HVCI sekarang susah dilewati: hypervisor punya privilege lebih tinggi dari kernel.

> [!danger] Plot Twist 3: Air-Gap Bisa Ditembus Pre-Boot
> Stuxnet (2010) adalah bukti konsep: komputer yang **tidak pernah terhubung internet** bisa dikompromi via USB drive yang sudah membawa UEFI/MBR payload. Air-gap adalah **mitigasi network**, bukan **mitigasi physical access**. Kalau attacker punya akses fisik 30 detik ke laptop anda, semua ring -3 sampai Ring 3 bisa dijangkau.

> [!tip] Plot Twist 4: Amirankan pada CPU Buatan Sendiri
> Proyek RISC-V (open instruction set) memungkinkan vendor membuat CPU tanpa Ring -2 (SMM) dan Ring -3 (ME/PSP). NVIDIA, Western Digital, China (RISC-V consortium) mulai adopsi. Ini bukan cuma soal religious open source — ini soal **kedaulatan hierarki privilege**. Negara bisa menolak backdoor firmware jika mereka kontrol desain CPU.

---

## Tools Landscape Snapshot

Hierarki ini menjelaskan **mengapa** setiap layer butuh tool berbeda. Untuk grid lengkap tools open source & freeware per Ring, lihat [[endpoint-security-freeware]] di `01_Library/Cyber_Security/Endpoint_Detection/`. Singkatannya:

| Ring | Open Source Frontier | Commercial | Catatan |
|---|---|---|---|
| -3 | Sangat terbatas (ME Cleaner / Coreboot untuk device support) | Eclypsium, vendor tool | Tooling detection masih jauh dari matang |
| -2 | CHIPSEC (Intel only) | Vendor SMM lockdown | Audit perlu hardware & waktu |
| -1 | Hyper-V Linux KVM + measured boot | VMware vSphere, Hyper-V | Mature secara umum |
| Pre-Boot | fwupd, Heads, Coreboot, TPM2-Tools | OEM vendor tools | Secure Boot sudah mature |
| Pre-OS | N/A (OS belum boot) | N/A | Butuh boot ke external media |
| 0 | Wazuh (HIDS), Sysmon, eBPF-based, SELinux | CrowdStrike, SentinelOne, Defender for Endpoint | Sangat mature, arms race ketat |
| 3 | ClamAV, OSSEC, OWASP ModSecurity | Semua antivirus komersial | Tools banyak, advisories sering |

Untuk [[cyber-security|Cyber Security]] primer yang membahas lanskap penuh ancaman & kontrol, pakai [[endpoint-security]] (Library deepdive).

---

## Perbandingan Pendekatan Lockdown

| Pendekatan | Lockdown Layer | Trade-off | Contoh |
|---|---|---|---|
| **Default OS Config** | Ring 3 saja (antivirus) | User-friendly, vulnerable | Windows Defender default, macOS XProtect |
| **Hardened OS** | Ring 3 + Ring 0 | Butuh expertise, app compatibility turun | DISA STIG, CIS Benchmark, Qubes OS, Fedora Silverblue |
| **Measured Boot Stack** | + Pre-Boot | Butuh TPM 2.0 di semua device | BitLocker + Secure Boot + PCR attestation |
| **VBS / Credential Guard** | + Virtualization Ring -1 | Performance cost 5-10%, compat tertentu drop | Windows VBS, AMD SEV, Intel TDX |
| **Full Supply Chain Audit** | + Pre-Boot vendor + Ring -2, -3 | Mahal, butuh vendor relationship | NSA / intelijen supply chain program |

Lockdown naik hierarki = effort eksponensial, benefit incremental. Kebanyakan organisasi **berhenti di Measured Boot** (= sudah sangat kuat). Yang naik ke VBS / supply chain audit biasanya yang sudah punya threat model spesifik (high-value target, classified).

---

## Rekomendasi per Profil

| Profil | Lockdown Minimum | Tambahan Jika Budget Ada |
|---|---|---|
| **Personal / Rumahan** | Windows Update + Antivirus built-in + Browser hardening (uBlock Origin) | BitLocker, Secure Boot aktif (default sudah), backup ke external |
| **SMB / UKM** | EDR tier-1 (Defender for Business ~$3/user/bulan), Secure Boot, backup offsite | VBS + Credential Guard, MDM (Intune), vulnerability management |
| **Mid-Market Enterprise** | Full EDR + DLP + SIEM + vulnerability management + BitLocker policy | SOAR, hardware attestation fleet, firmware audit berkala |
| **Regulated (Finance / Health)** | Di atas + compliance framework (PCI-DSS, HIPAA, SOC 2) + audit logging | Hardware HSM, dedicated security team |
| **Critical Infrastructure / Govt** | + air-gap untuk sensitive system, supply chain integrity, hardware attestation | Custom OS (SELinux MLS), dedicated crypto module (FIPS 140-3 Level 4) |
| **Defense / Intelijen** | + vendor firmware audit, ME disable, firmware re-build dari source | Custom CPU design, classified hardware supply chain (bukan commodity) |

---

## Sumber & Telusur Lebih Lanjut

- **Threat Landscape Lengkap** → [[endpoint-security]] (tabel ancaman per Ring + Blue/Red Team)
- **Tools Freeware per Ring** → [[endpoint-security-freeware]] (CHIPSEC, Wazuh, fwupd, Keylime)
- **OS Family Tree** → [[hierarchy-operating-systems]] (Linux Mint ↔ JWICS dalam satu pohon keluarga)
- **OS Internals Foundations** → [[computer-science-foundations]] (kernel module, hypervisor, EL0-EL3 ARM)
- **Offensive Privilege Escalation** → [[hierarchy-offensive]] (Level 3: PrivEsc Specialist)
- **Network Defense Analog** → [[network-security]] (OSI Layer — hirarki network)
- **BYOVD Dual-Use** → [[underground-knowledge]] (cheat engine level 3 pakai BYOVD juga)
- **Master Index** → [[master-index]]

---

> Jika lo paham hirarki ini, lo paham **mengapa** antivirus modern saja tidak cukup — dan **di mana** celah defender anda lemah. Hirarki privilege CPU bukan konsep textbook; itu peta operasi harian setiap red team, blue team, dan APT nation-state.

*Endpoint Security Hierarchy | Ring 3 (Aplikasi) → Ring -3 (Sub-Firmware Selalu ON) · Inversi Privilege-Visibility*

audited
---
