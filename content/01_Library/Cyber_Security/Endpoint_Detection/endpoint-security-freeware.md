---
title: Endpoint Security Freeware
tags:
- endpoint-security
- freeware
- open-source
- blue-team
- CPU-ring
created: '2026-05-01'
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  - callout

---
# 🛡️ Endpoint Security Tools — Open Source & Freeware Edition

> Hierarki keamanan endpoint dari firmware (Ring -3) sampai user space (Ring 3), dengan tools **gratis & open source** sebagai pengganti Windows Defender. Mapped ke arsitektur ring yang sudah didefinisikan di [[endpoint-security]] (knowledge primer) dan [[hierarchy-endpoint-security]] (peta konsep atlas). File ini fokus pada **tooling defender** per Ring.

> [!info] Navigator Cepat
> Untuk konsep hirarki privilege CPU dan **plot twist dual-use**, lihat [[hierarchy-endpoint-security]]. Untuk **landscape ancaman** (blue team vs red team per Ring), lihat [[endpoint-security]]. File ini adalah playbook tools-nya.

---

## Daftar Isi

- [[#Ring -3 — Intel ME / AMD PSP]]
- [[#Ring -2 — SMM System Management Mode]]
- [[#Ring -1 — Hypervisor / VMM]]
- [[#Pre-Boot — UEFI / BIOS Firmware]]
- [[#Pre-OS — MBR / VBR / Bootloader]]
- [[#Ring 0 — Kernel & Driver]]
- [[#Ring 3 — User Space]]
- [[#Workflow Stack Rekomendasi]]
- [[#Koneksi ke Framework Lain]]

---

## Ring -3 — Intel ME / AMD PSP

> **Ring -3** = prosesor terpisah yang selalu ON, bahkan saat komputer "mati". OS buta total terhadap lapisan ini.

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — Firmware Transparency _(Coreboot, Heads, ME Cleaner, Libreboot)_ | Ganti firmware proprietary dengan open source. Coreboot: init hardware tanpa blob closed-source. ME Cleaner: strip & neutralize Intel ME modules (hapus networking, keep essential bring-up). Heads: tamper-evident boot dengan TPM + GPG keys. | Tidak semua motherboard support Coreboot (terutama laptop modern). ME Cleaner bisa brick device kalau salah. AMD PSP lebih sulit di-disable dibanding Intel ME. | Self-hosted server, ThinkPad/Chromebook lama, privacy-focused workstation, audit supply chain |
| **Level 1** — Remote Attestation _(TPM2-Tools, Keylime, SafeBoot, fwupd + LVFS)_ | TPM2-Tools: verify PCR values (Platform Configuration Registers) untuk detect tampering. Keylime (CNCF): remote attestation cloud-native — verify integrity dari trusted server. fwupd + LVFS: update firmware BIOS/UEFI dengan verifikasi signature vendor. | TPM2 butuh hardware support. Keylime butuh infrastruktur server. LVFS tidak semua vendor ikut (Apple, beberapa OEM skip). | Enterprise fleet verification, cloud VM attestation, ensure firmware integrity post-update |
| ☠️ **Level 2** — Hardware Audit _(CHIPSEC — extend ke Ring -3, vendor-specific tools)_ | Eclypsium = commercial. Alternatif open source terbatas. Manual audit: dump SPI flash, compare hash dengan image asli dari vendor. | Butuh hardware programmer (CH341A, etc). Flash chip bisa beda ukuran/package. Vendor tidak selalu publish image firmware asli untuk compare. | Forensik hardware, audit second-hand device, detect supply chain implant |

---

## Ring -2 — SMM System Management Mode

> **Ring -2** = firmware interrupt handler. OS tidak pernah "melihat" SMM code berjalan. SMM rootkit = invisible ke OS.

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — SMM Audit _(CHIPSEC — Intel open source)_ | CHIPSEC: 20+ modul security test untuk UEFI/SMM. Check SMM_BWP (SMM BIOS Write Protection), SMRR (System Management RAM Range), lockdown configuration. Bisa detect SMM code injection, verify SMM handler integrity. | Butuh boot ke environment CHIPSEC (USB/DVD). Hanya untuk Intel (AMD punya tool terpisah, kurang mature). Output butuh interpretasi manual. | Audit SMM security sebelum deploy fleet, verify vendor BIOS tidak vulnerable, research SMM exploitation |
| **Level 1** — Firmware Analysis _(FwHunt — Binarly, open source)_ | Scan firmware image (dump dari SPI flash) untuk detect known-bad patterns, anomali SMM code, unsigned modules, backdoor indicators. Database signature community-driven. | Butuh dump firmware dulu (Flashrom/CHIPSEC). False positive pada firmware modifikasi legitimate (Coreboot, etc). Tidak real-time protection. | Threat hunting di firmware level, analyze compromised firmware, verify firmware sebelum flash |
| **Level 2** — SPI Flash Verification _(Flashrom, UEFIExtract, UEFITool)_ | Flashrom: baca/tulis SPI flash chip langsung. UEFIExtract: extract semua module dari firmware image. UEFITool: browse & edit firmware structure. Bandingkan hash module dengan vendor original. | Butuh hardware programmer untuk read/write. Risk brick kalau write salah. Tidak semua chip support. | Forensik firmware, recovery corrupt BIOS, verify firmware integrity manual |

---

## Ring -1 — Hypervisor / VMM

> **Ring -1** = Virtual Machine Monitor. Hypervisor rootkit bisa mengangkat OS asli menjadi VM tanpa sepengetahuan user (Blue Pill).

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — Type-1 Hypervisor _(KVM — Linux kernel, Xen, Hyper-V — Windows built-in)_ | KVM: kernel-based virtualization, native Linux. Xen: paravirtualization, dipakai Qubes OS. Hyper-V: Windows built-in (Pro/Enterprise), gratis. Semua bisa detect timing anomaly dari rogue hypervisor (CPU overhead virtualisasi). | Hyper-V butuh Windows Pro+. KVM butuh Linux host. Xen learning curve tinggi. Tidak ada deteksi otomatis hypervisor rootkit, hanya mitigasi dengan hypervisor legitimate. | Secure multi-tenancy, isolate critical workload, detect Blue Pill via timing side-channel |
| **Level 1** — Security-Focused OS _(Qubes OS — Xen-based, disposable VMs per-app)_ | Isolasi per-aplikasi via disposable VM. Browser di VM terpisah, file di VM terpisah, USB di VM terpisah. Compromise satu VM tidak affect others. Template-based: update satu template, semua VM inherit. | Butuh hardware virtualization (VT-x/AMD-V). Resource usage tinggi (RAM 8GB+ minimum). Learning curve tinggi. Tidak semua software compatible. | High-security workstation, journalist, whistleblower, malware analysis, compartmentalization |
| **Level 2** — Remote Attestation _(Keylime — CNCF, OpenAttestation — Intel)_ | Verify integrity hypervisor & guest OS dari trusted remote server. Measured boot: TPM mencatat setiap stage boot. Keylime: cloud-native attestation dengan revocation otomatis kalau integrity fail. | Butuh TPM2 + infrastruktur server. Kompleks setup. Network dependency untuk attestation server. | Cloud provider verify tenant VM integrity, enterprise ensure no tampering hypervisor |
| **Level 3** — VM Introspection _(KVM-PT — Intel Processor Trace, AFL++ — fuzzing + introspection)_ | Intel PT: trace setiap instruction di CPU dengan overhead minimal. KVM-PT: introspection VM via PT. AFL++: fuzzing dengan coverage guidance via PT. Bisa detect anomali execution di VM. | Butuh CPU Intel dengan PT support (Broadwell+). Kompleks setup. Output trace massive, butuh analisis. | Research hypervisor security, detect VM escape, analyze malware behavior in VM |

---

## Pre-Boot — UEFI / BIOS Firmware

> **Pre-Boot** = sebelum bootloader. UEFI implant survive format & ganti SSD (bersarang di chip ROM motherboard).

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — Secure Boot _(UEFI Secure Boot + custom keys, PreLoader/HashTool, Linux Foundation SBAT)_ | Secure Boot: hanya execute bootloader & OS yang signed. Custom keys: sign sendiri GRUB2/kernel. PreLoader: enroll hash manual tanpa CA. SBAT: Secure Boot Advanced Targeting, revoke vulnerable bootloader. | Butuh disable default Microsoft keys untuk custom. Risk brick kalau salah key. Some hardware Secure Boot implementation buggy. | Prevent bootkit, ensure only trusted OS boot, block BlackLotus-style UEFI bootkit |
| **Level 1** — Firmware Scan _(FwHunt — Binarly, CHIPSEC UEFI scan, manual hash compare)_ | Scan firmware dump untuk known-bad signatures, anomali PEIM/DXE drivers, unsigned modules, backdoor indicators. Compare dengan vendor golden image. | Butuh dump firmware dulu. Vendor tidak selalu publish golden image. False positive pada modifikasi legitimate. | Verify firmware tidak compromised sebelum boot, threat hunting firmware level |
| **Level 2** — Bootloader Protection _(GRUB2 + password + GPG signature, rEFInd + secure boot chain)_ | GRUB2: password protect boot entry, verify kernel signature via GPG. rEFInd: UEFI boot manager dengan auto-detect OS + secure boot chain. | Password GRUB bisa di-bypass dengan live USB (kecuali + disk encryption). Setup GPG signing kompleks. | Prevent unauthorized boot parameter, protect single-user mode, ensure kernel integrity |
| ☠️ **Level 3** — Firmware Recovery _(Flashrom + hardware programmer, vendor crisis recovery tool)_ | Kalau firmware corrupt/rootkitted: flash ulang dengan programmer hardware. Some board punya crisis recovery (jumper/keystroke). | Butuh hardware skill. Risk permanent brick. Some chip soldered, sulit diakses. | Recovery dari firmware corruption, remove persistent firmware implant |

---

## Pre-OS — MBR / VBR / Bootloader

> **Pre-OS** = setelah UEFI, sebelum kernel. Bootkit di sini aktif lebih dulu dari OS.

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — Disk Encryption _(BitLocker — Windows built-in, LUKS — Linux, VeraCrypt — cross-platform open source)_ | BitLocker: encrypt seluruh disk + TPM integration (verify boot integrity). LUKS: Linux standard disk encryption. VeraCrypt: open source successor TrueCrypt, hidden volume support. | BitLocker butuh Windows Pro+ untuk TPM integration penuh. LUKS butuh password setiap boot. VeraCrypt slower than native. Performance overhead encryption. | Prevent offline attack (boot dari live USB), protect data at rest, ensure boot sector integrity |
| **Level 1** — Boot Sector Monitoring _(AIDE — Linux, OSSEC — FIM pada boot sector, Tripwire — open source version)_ | AIDE: Advanced Intrusion Detection Environment, hash database file/boot sector. OSSEC: real-time FIM, alert kalau MBR/VBR berubah. Tripwire: file integrity monitoring klasik. | Butuh baseline database "clean". Alert setelah perubahan (reactive, bukan preventive). False positive pada update system. | Detect bootkit installation, verify boot sector integrity post-update, forensik boot sector |
| **Level 2** — Bootloader Hardening _(GRUB2 + secure boot + password, shim + MokManager)_ | GRUB2 dengan password + verified boot chain. Shim: signed by Microsoft/3rd party, enroll custom key via MokManager. Secure Boot ensure hanya trusted bootloader execute. | Kompleks setup. Password bisa di-bypass tanpa disk encryption. Shim vulnerability pernah ada (BootHole). | Harden boot chain, prevent bootloader tampering, ensure kernel integrity dari boot sampai runtime |

---

## Ring 0 — Kernel & Driver

> **Ring 0** = OS kernel & driver. Kernel rootkit invisible ke user space. BYOVD = attacker bawa driver vulnerable yang sudah signed untuk eksekusi kernel.

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — Built-in Kernel Protection _(PatchGuard — Windows built-in, Driver Signature Enforcement/DSE, HVCI — Hypervisor-protected Code Integrity)_ | PatchGuard: monitor kernel structure critical, BSOD kalau dimodifikasi. DSE: hanya load driver dengan signature valid. HVCI: VMM enforce code integrity (Windows 11). Semua aktif meski Defender dihapus. | PatchGuard bisa di-bypass (tapi sulit). DSE bisa di-disable (test mode, etc). HVCI butuh hardware modern + performance overhead. | Baseline kernel protection tanpa install apa-apa, prevent casual kernel rootkit |
| **Level 1** — Kernel Visibility _(Sysmon — Microsoft, gratis, Event ID 1/6/7/9)_ | Sysmon: log proses creation, driver load, image load, raw disk access. Event ID 6 = driver load (deteksi BYOVD). Event ID 9 = raw access read (bootkit behavior). Gratis dari Microsoft. | Cuma logging, tidak blok. Butuh parsing (Event Viewer atau SIEM). Noisy tanpa filtering. Resource usage moderate. | Detect driver loading, identify BYOVD attack, log kernel-level activity untuk forensik |
| **Level 2** — Kernel Audit & Hardening _(WDAC — Windows Defender Application Control, strict policy, LOLDrivers blocklist)_ | WDAC: whitelist kernel-mode driver & user-mode code. Strict policy = block semua kecuali yang explicitly allowed. LOLDrivers: community database driver known-vulnerable yang sering dipakai attacker. | WDAC butuh Windows Enterprise/Education untuk GUI penuh (Pro bisa via PowerShell). Strict policy bisa blok legitimate software. Maintenance policy butuh effort. | Prevent BYOVD, block known-vulnerable driver, enforce code integrity di kernel & user space |
| **Level 3** — eBPF Runtime Security _(Falco — CNCF, Tetragon — Cilium, Tracee — Aqua Security)_ | eBPF: jalankan program di kernel secara aman tanpa module. Falco: deteksi anomali syscall, file, network. Tetragon: security observability + enforcement (kill process). Tracee: event-based tracing + detection. | Linux only (Windows eBPF masih early). Butuh kernel modern (5.x+). Falco noisy tanpa tuning. Tetragon butuh Cilium ecosystem. | Runtime security container/Linux, detect container escape, monitor syscall anomaly, enforce security policy di kernel |
| **Level 4** — Kernel Debugging & Analysis _(HyperDbg — open source, WinDbg — Microsoft gratis, DTrace Windows)_ | HyperDbg: debugger ring-0 open source, hardware-assisted (Intel VT-x). WinDbg: Windows Debugging Tools, gratis. DTrace: dynamic tracing kernel Windows/Linux. | Butuh skill reverse engineering/advanced. HyperDbg masih development, unstable. WinDbg learning curve tinggi. | Kernel research, analyze rootkit behavior, debug BSOD, reverse engineer driver malicious |
| ☠️ **Level 5** — EDR Open Source Kernel _(Wazuh — kernel event via Auditd, Aurora Agent — Sigma rules real-time, Velociraptor — VQL kernel query)_ | Wazuh: collect kernel event (Auditd Linux, Sysmon Windows), FIM, log analysis. Aurora: Sigma rules real-time di endpoint, deteksi MITRE ATT&CK teknik kernel abuse. Velociraptor: query kernel artifact via VQL. | Wazuh butuh server/SIEM. Aurora butuh tuning. Velociraptor butuh infrastruktur server. Semua butuh skill operasi. | SOC analyst, blue team, detect APT technique, kernel-level threat hunting, incident response |

---

## Ring 3 — User Space

> **Ring 3** = aplikasi biasa. Di sinilah ransomware, RAT, trojan, spyware, fileless malware beroperasi.

| 🔐 Level & Tools | ⚡ Teknik & Sweet Spot | ☠️ Tembok & Batasan | 🎯 Use Case Nyata |
|---|---|---|---|
| **Level 0** — On-Demand Scanner _(KVRT — Kaspersky Virus Removal Tool, Malwarebytes Free, ESET Online Scanner, Dr.Web CureIt!, Kaspersky Cloud Scanner)_ | **KVRT**: portable, engine Kaspersky penuh, scan manual, hapus malware aktif, tidak perlu install. Malwarebytes Free: deteksi adware/PUP terbaik. ESET Online: scan cloud tanpa residen. | **Tidak ada proteksi real-time** (versi gratis). Harus inget scan manual rutin. KVRT tidak update otomatis (download versi baru tiap minggu). Tidak ada prevention, hanya detection & removal. | Scan mingguan, second opinion, bersihin komputer terinfeksi, flash drive toolkit |
| **Level 1** — Behavior Blocker _(OSArmor — NoVirusThanks, Hard_Configurator, SysHardener, Simple Software Restriction Policy)_ | **OSArmor**: blok behavioral mencurigakan real-time — encryption massal (ransomware), DLL injection, disable task manager/registry, startup tampering. **Hard_Configurator**: GUI lockdown Windows policy. | Banyak popup di awal. Learning curve. False positive blok legitimate software. Tidak deteksi malware yang "diam" atau tidak behave aneh. | Blok ransomware sebelum menyebar, hardening Windows tanpa AV berat, proteksi user klik sembarangan |
| **Level 2** — Application Isolation _(Sandboxie Plus — open source, Windows Sandbox — built-in, Firejail — Linux, Docker Desktop)_ | **Sandboxie Plus**: jalankan aplikasi/browser dalam sandbox terisolasi, perubahan tidak permanen. **Windows Sandbox**: instance Windows bersih terisolasi (Win 10/11 Pro). | Sandboxie: beberapa aplikasi tidak kompatibel. Windows Sandbox butuh Pro/Enterprise + virtualization on. Tidak proteksi sistem global, hanya aplikasi di-sandbox. | Browsing aman, jalankan software mencurigakan, test malware, download dari sumber tidak terpercaya |
| **Level 3** — Memory Analysis _(PE-sieve — scan proses running, Hollows_Hunter — process hollowing, Moneta — pure memory scanner, Sysmon Event ID 10)_ | **PE-sieve**: deteksi injection, hollowing, hooking di proses running. **Hollows_Hunter**: deteksi process hollowing & malicious memory allocation. **Moneta**: scan memory untuk anomali. | Butuh akses live system. Bisa false positive pada software dengan packer/protection (gaming anti-cheat, etc). Tidak real-time prevention, hanya detection. | Detect fileless malware, analyze process injection, forensik memory tanpa dump full RAM |
| **Level 4** — Network Monitoring _(Suricata — IDS/IPS, Zeek — network analysis, RITA — Black Hills Infosec, Wireshark + Brim/Zed)_ | **Suricata**: deteksi network-based threats dengan rules (Emerging Threats, etc). **Zeek**: log semua koneksi detail. **RITA**: deteksi beaconing periodic (C2 signature) dari Zeek logs. | Butuh network tap/mirror port. Banyak data, butuh storage. Analisis butuh skill network forensik. RITA butuh Zeek logs. | Network forensik, deteksi C2 beaconing, monitor traffic mencurigakan, analyze breach |
| **Level 5** — Credential Protection _(Credential Guard — Windows built-in Pro+, Windows Hello, LSA Protection)_ | **Credential Guard**: isolasi LSASS di virtual secure mode (VSM), prevent Mimikatz-style credential dump. **LSA Protection**: flag registry protect LSA. | Credential Guard butuh Windows Pro/Enterprise + hardware modern. Tidak semua software compatible (legacy SSO, etc). | Prevent credential dumping, protect Kerberos tickets, secure domain credentials |
| **Level 6** — LOLBin Restriction _(Hard_Configurator — disable script interpreter, WDAC — block certutil/mshta/regsvr32, Sysmon + Aurora Sigma rules)_ | **Hard_Configurator**: disable macro, block script execution, restrict PowerShell. **WDAC**: block LOLBin binary. **Sigma rules**: detect certutil, mshta, regsvr32 abuse. | Aggressive restriction bisa break workflow IT/admin. Butuh whitelist maintenance. User complain kalau script tidak jalan. | Prevent living-off-the-land attack, block script-based malware, restrict admin tool abuse |
| **Level 7** — IOC & Threat Hunting _(LOKI — IOC scanner, THOR Lite — Nextron, Chainsaw — Sigma on Event Logs, YARA + yarGen)_ | **LOKI**: scan file/registry/memory dengan Indicators of Compromise. **THOR Lite**: versi gratis THOR APT scanner (terbatas). **Chainsaw**: analisis Windows Event Logs dengan Sigma rules. **YARA**: signature custom malware. | Butuh threat intelligence untuk bikin rule. Tidak real-time protection, hanya scan/detection. THOR Lite terbatas fitur vs licensed. | Threat hunting, APT detection, forensik cepat pasca-insiden, buat signature custom |
| ☠️ **Level 8** — Advanced Forensics _(Volatility — RAM dump, Rekall — memory framework, MemProcFS — mount RAM as filesystem, Velociraptor — remote forensics)_ | **Volatility**: analisis RAM dump untuk malware fileless, koneksi network, password. **MemProcFS**: mount RAM dump sebagai filesystem untuk browsing. **Velociraptor**: remote collect artifact dari ribuan endpoint. | Butuh dump RAM (BlueScreen, crash, atau tools seperti WinPMEM). Skill reverse engineering. Velociraptor butuh server infrastruktur. | Deep incident response, analyze fileless malware, remote forensics fleet, memory forensics |

---

## Workflow Stack Rekomendasi (No Defender)
```
   [TANPA WINDOWS DEFENDER]
				│
				▼
┌─────────────────────────────────────┐
│  Ring -3 / Pre-Boot                 │
│  Secure Boot ON + TPM 2.0 + fwupd   │
│  (hardware root of trust)           │
└──────────────┬──────────────────────┘
			   │
			   ▼
┌─────────────────────────────────────┐
│  Ring 0 — Kernel Protection         │
│  PatchGuard + DSE (jangan dimatiin) │
│  Sysmon + Aurora (real-time logging)│
│  WDAC strict (whitelist driver/app) │
└──────────────┬──────────────────────┘
               │
			   ▼
┌─────────────────────────────────────┐
│  Ring 3 — Behavior Blocker          │
│  OSArmor (blok ransomware real-time)│
└──────────────┬──────────────────────┘
			   │
		       ▼
┌─────────────────────────────────────┐
│  Ring 3 — Isolation                 │
│  Sandboxie Plus (browser sandbox)   │
│  Windows Sandbox (test software)    │
└──────────────┬──────────────────────┘
			   │
		       ▼
┌─────────────────────────────────────┐
│  Ring 3 — Weekly Scan               │
│  KVRT (Kaspersky, portable, gratis) │
│  Malwarebytes Free (second opinion) │
└──────────────┬──────────────────────┘
			   │
		       ▼
┌─────────────────────────────────────┐
│  Ring 3 — Memory Check (kalau curiga)│
│  PE-sieve / Hollows_Hunter          │
└──────────────┬──────────────────────┘
			   │
			   ▼
┌─────────────────────────────────────┐
│  Ring 3 — Network (opsional)        │
│  Suricata/Zeek + RITA (C2 detect)   │
└─────────────────────────────────────┘

```

---
## Koneksi ke Framework Lain
─────────────────────────────────────
├── [[hierarchy-osint-rf]]          → OSINT & SIGINT (eksternal intelligence)
├── [[application]]                 → Master Tool Arsenal (semua kategori)
├── [[endpoint-security]]      → Ring architecture (threat mapping)

> [!tip] Entry Point Terbaik
> Mulai dari **Ring 0 + Ring 3**: Sysmon + Aurora + OSArmor + KVRT. Itu sudah cover 90% threat user space dan kernel visibility. Baru turun ke Ring -1 / Pre-Boot kalau threat model lu include hardware/firmware level.

---

_Endpoint Security Hierarchy — Open Source Edition | Dari Coreboot sampai KVRT | Dari Ring -3 sampai Ring 3_
