---
title: "Windows Forensics — Artifact Analysis & Investigation"
tags:
  - windows-forensics
  - registry
  - event-log
  - prefetch
  - forensic-investigation
  - dfir
aliases:
  - "windows-forensics-artifact-analysis"
created: "2026-07-28"
updated: "2026-07-28"
status: active
---

# 🪟 Windows Forensics — Artifact Analysis & Investigation

> **Panduan praktis analisis artifact Windows** untuk CTF dan incident response. Windows menyimpan **ratusan artifact yang mencatat setiap aktivitas user dan proses** — dari eksekusi aplikasi sampai koneksi USB. Soal forensic Windows biasanya menguji kemampuan mengekstrak dan menginterpretasi artifact-artifact ini untuk merekonstruksi kejadian. Untuk gambaran besar digital evidence, lihat [[hierarchy-digital-evidence-acquisition]]. Untuk tools, lihat [[ctf-tool-arsenal-universal]].

> [!tip] Prinsip Emas Windows Forensics
> **Windows mencatat SEMUA yang Anda lakukan — hanya masalah di mana mencarinya.** Bahkan setelah user menghapus file, $MFT, $UsnJrnl, $LogFile, Event Log, Prefetch, dan Registry menyimpan bukti yang tidak bisa dihapus tanpa tools khusus anti-forensik (dan itu pun bisa dilacak).

---

## Daftar Isi

- [[#Artefak Eksekusi — Apa yang Pernah Jalan]]
- [[#Registry Analysis — Hive Mana yang Harus Dicek]]
- [[#Event Log — Windows Logging]]
- [[#Filesystem Artifact — $MFT, $UsnJrnl, Timestamp]]
- [[#User Activity — Browser, Recent Files, Jump Lists]]
- [[#USB Device History — Siapa Colok Flashdisk]]
- [[#Prefetch & Superfetch — Application Execution History]]
- [[#Windows Crash Dumps & Hibernation]]
- [[#Timeline Reconstruction — Excel Waktu]]
- [[#Cheat Sheet — Tools & Commands per Artifact]]

---

## Artefak Eksekusi — Apa yang Pernah Jalan

### 1.1 Prefetch (.pf)

**Lokasi:** `C:\Windows\Prefetch\*.pf`
**Fungsi:** Mencatat aplikasi yang dijalankan dari hard disk untuk mempercepat loading berikutnya.
**Level:** L3 (transient)

```bash
# Analisis dengan PECmd (Eric Zimmerman)
PECmd.exe -f "C:\Windows\Prefetch\NOTEPAD.EXE-12345678.pf"
PECmd.exe -d "C:\Windows\Prefetch\" --csv output.csv

# Informasi dari Prefetch:
#   - Nama file executable
#   - Path lengkap
#   - Jumlah eksekusi (run count)
#   - Timestamp pertama dan terakhir jalan
#   - File dan folder yang diakses saat proses jalan
#   - Volume serial number
```

**⚠️ Prefetch dimatikan di SSD** — Windows 10+ disable Prefetch otomatis kalau detect SSD. Tapi di kebanyakan soal CTF, disk image masih HDD.

**CTF Pattern:** Cari aplikasi aneh: `mimikatz.exe`, `procdump.exe`, `nc.exe`, `plink.exe`, `psexec.exe`, atau tool hacking lain dengan run count 1–2.

### 1.2 ShimCache (AppCompatCache)

**Lokasi:** Registry `SYSTEM\CurrentControlSet\Control\Session Manager\AppCompatCache`
**Fungsi:** Mencatat semua executable yang pernah dijalankan — bahkan sebelum Prefetch diimplementasikan (Windows XP era).
**Level:** L3 (persistent)

```bash
# Ekstrak dari Registry hive SYSTEM
# Dengan RegRipper:
rip.pl -r SYSTEM -f appcompatcache

# Dengan AppCompatCacheParser (EZ Tools):
AppCompatCacheParser.exe --csv output.csv -f SYSTEM
```

**Keunggulan ShimCache vs Prefetch:**

- ShimCache tetap ada meski aplikasi hanya jalan sekali
- ShimCache mencatat **path penuh** executable
- Tapi ShimCache **tidak punya timestamp** (hanya urutan eksekusi — yang terakhir di list = yang terakhir dijalankan)

### 1.3 Amcache

**Lokasi:** `C:\Windows\AppCompat\Programs\Amcache.hve`
**Fungsi:** Database aplikasi yang pernah diinstal/dijalankan — lebih detail dari ShimCache.
**Level:** L3 (persistent)

```bash
# Analisis dengan AmcacheParser (EZ Tools)
AmcacheParser.exe -f Amcache.hve --csv output.csv

# Informasi dari Amcache:
#   - Nama file, path, ukuran
#   - Hash SHA-1 file
#   - Product name, publisher, version
#   - First/Last executed timestamp
#   - Program ID (GUID)
```

**CTF Pattern:** Cari executable unsigned (tanpa publisher) atau dengan hash mencurigakan — tool attacker biasanya tidak punya signature.

### 1.4 UserAssist

**Lokasi:** Registry `NTUSER.DAT\Software\Microsoft\Windows\CurrentVersion\Explorer\UserAssist\{GUID}\Count`
**Fungsi:** Mencatat shortcut yang di-klik/dijalankan user dari Start Menu atau Desktop.
**Level:** L3 (persistent)

```bash
# Dengan RegRipper
rip.pl -r NTUSER.DAT -f userassist

# Informasi UserAssist:
#   - Nama shortcut yang dijalankan
#   - Jumlah eksekusi (count)
#   - Timestamp terakhir jalan
#   - ROT13 encrypted — perlu decrypt: https://www.nirsoft.net/utils/...
```

**CTF Pattern:** Shortcut yang tidak wajar — `mimikatz.lnk`, `backdoor.lnk`, `nc.lnk`.

---

## Registry Analysis — Hive Mana yang Harus Dicek

### Registry Hive Locations

| Hive           | File                                  | Fungsi                                                |
| -------------- | ------------------------------------- | ----------------------------------------------------- |
| **SYSTEM**     | `C:\Windows\System32\config\SYSTEM`   | System-wide config: services, drivers, network, USB   |
| **SOFTWARE**   | `C:\Windows\System32\config\SOFTWARE` | Software config: installed programs, network settings |
| **SAM**        | `C:\Windows\System32\config\SAM`      | User accounts & password hashes                       |
| **SECURITY**   | `C:\Windows\System32\config\SECURITY` | Security policies, audit, logon sessions              |
| **NTUSER.DAT** | `C:\Users\<user>\NTUSER.DAT`          | Per-user config: MRU, typed URLs, recent docs         |

### 2.1 SYSTEM Hive — Key Paths

```bash
# Mounted devices — drive letters & volume serial
SYSTEM\MountedDevices

# Services — apa yang auto-start?
SYSTEM\CurrentControlSet\Services
# Cek: ImagePath, Start (0=boot, 1=system, 2=auto, 3=manual, 4=disabled)
# Cari service aneh dengan Start=2 (auto) atau Start=0

# Network interfaces — IP, MAC, DHCP
SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\{GUID}

# USB device history — flashdisk pernah dicolok
SYSTEM\CurrentControlSet\Enum\USBSTOR
# Subkey: ProdID_Rev → lihat device yang pernah terhubung

# Computer name
SYSTEM\CurrentControlSet\Control\ComputerName\ComputerName
```

### 2.2 SOFTWARE Hive — Key Paths

```bash
# Installed programs — registry uninstall
SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall
# Cari: DisplayName, InstallDate, Publisher

# Network list — pernah connect ke WiFi mana?
SOFTWARE\Microsoft\Windows NT\CurrentVersion\NetworkList\Profiles
# ProfileGuid, Description (SSID), DateCreated, DateLastConnected

# Windows version
SOFTWARE\Microsoft\Windows NT\CurrentVersion
# ProductName, CurrentBuild, InstallDate

# Terminal Server — RDP connections?
SOFTWARE\Microsoft\Terminal Server Client\Servers
# Cek MRU (Most Recently Used) RDP connections
```

### 2.3 SAM Hive — User Accounts

```bash
# User list
SAM\SAM\Domains\Account\Users\Names
# Subkey = username
# Value (default) = RID

# User detail (per RID, e.g., 000001F4 = Administrator)
SAM\SAM\Domains\Account\Users\000001F4
# F value = NTLM hash (offset 0xA0–0xA8)
# V value = last logon timestamp

# Password hash extraction (butuh SYSTEM hive juga)
# Tools: secretsdump.py, mimikatz, samdump2
python3 secretsdump.py -system SYSTEM -sam SAM LOCAL
```

### 2.4 NTUSER.DAT — Per User Activity

```bash
# Recent Documents (MRU)
NTUSER.DAT\Software\Microsoft\Windows\CurrentVersion\Explorer\RecentDocs
# .ext subkey — file extension → MRUListEx = order

# Typed URLs (Internet Explorer)
NTUSER.DAT\Software\Microsoft\Internet Explorer\TypedURLs
# url1, url2, url3 — apa yang user ketik di address bar

# Run MRU (Start → Run dialog)
NTUSER.DAT\Software\Microsoft\Windows\CurrentVersion\Explorer\RunMRU
# MRUList — command yang di-run via Start → Run

# MUICache — aplikasi yang pernah dibuka
NTUSER.DAT\Software\Microsoft\Windows\ShellNoRoam\MUICache
# Atau di: Software\Classes\Local Settings\Software\Microsoft\Windows\Shell\MuiCache
```

---

## Event Log — Windows Logging

### Log Locations

```bash
# Windows 10+ (.evtx)
C:\Windows\System32\winevt\Logs\
#   Security.evtx     — login/logoff, privilege use, object access
#   System.evtx       — system events, driver load, service start
#   Application.evtx  — application errors/warnings
#   PowerShell.evtx   — PowerShell execution (jika enabled)
#   Microsoft-Windows-Sysmon/Operational.evtx — Sysmon events
```

### 3.1 Security Log — Event ID Must Know

| Event ID      | Deskripsi                        |                  Untuk CTF                  |
| ------------- | -------------------------------- | :-----------------------------------------: |
| **4624**      | Logon success                    |        Siapa login? Dari mana (IP)?         |
| **4625**      | Logon failure                    |            Brute force attempt?             |
| **4634**      | Logoff                           |           Kapan session berakhir            |
| **4648**      | Logon with explicit credential   |              RunAs atau Psexec              |
| **4672**      | Admin logon (SeTcbPrivilege)     |           Privileged account used           |
| **4688**      | Process created                  | **Wajib** — executable apa yang dijalankan? |
| **4689**      | Process exited                   |           Kapan process berakhir            |
| **4698**      | Scheduled task created           |            Persistence mechanism            |
| **4700/4701** | Scheduled task enabled/disabled  |              Task manipulation              |
| **4720**      | User account created             |           Attacker buat user baru           |
| **4732**      | User added to local group        |            Privilege escalation             |
| **5140**      | SMB share access                 |              Lateral movement               |
| **5152/5154** | Windows Filtering Platform block |               Firewall block                |
| **5156**      | Connection accepted              |          Koneksi inbound diterima           |

### 3.2 PowerShell Log — Event ID

| Event ID      | Deskripsi                             |
| ------------- | ------------------------------------- |
| **4103**      | Module logging — command execution    |
| **4104**      | Script block logging — script content |
| **4105/4106** | Start/Stop script execution           |
| **53504**     | PowerShell remoting                   |

### 3.3 Sysmon Log — Event ID (Jika Terinstall)

| Event ID | Deskripsi                                             |
| -------- | ----------------------------------------------------- |
| **1**    | Process creation (detail: hash, command line, parent) |
| **3**    | Network connection (detail: IP, port, protocol)       |
| **7**    | DLL loaded (untuk process hollowing detection)        |
| **8**    | CreateRemoteThread — process injection                |
| **9**    | RawAccessRead — bypass file lock                      |
| **10**   | ProcessAccess — handle ke process lain                |
| **11**   | FileCreate — file modification                        |
| **12**   | Registry modification                                 |
| **13**   | Registry value modification                           |
| **15**   | Named pipe — inter-process communication              |
| **22**   | DNS query — domain yang diakses                       |

**Sysmon sangat penting** — deteksi tool seperti mimikatz, cobalt strike, process injection langsung keliatan.

### 3.4 Event Log Analysis Commands

```bash
# Dengan wevtutil (native Windows)
wevtutil qe Security /q:"*[System[EventID=4624]]" /c:5 /f:text

# Dengan Log Parser (Microsoft LogParser)
LogParser.exe -i:EVT -o:CSV "SELECT TimeGenerated, EventID, Message FROM Security.evtx WHERE EventID=4624"

# Dengan EvtxeCmd (EZ Tools)
EvtxeCmd.exe -f Security.evtx --csv output.csv --inc 4624

# Dengan python-evtx
python3 -c "
import Evtx.Evtx as evtx
path = 'Security.evtx'
with evtx.Evtx(path) as log:
    for record in log.records():
        print(record.xml())
        break
"

# Timeline — semua event dalam range waktu
tshark -r Security.evtx -Y "System/TimeCreated/@SystemTime" -T fields -e System/EventID -e System/TimeCreated/@SystemTime
```

---

## Filesystem Artifact — $MFT, $UsnJrnl, Timestamp

### 4.1 $MFT (Master File Table)

**Lokasi:** Root dari volume NTFS (tersembunyi, file `$MFT`)
**Fungsi:** Database sentral NTFS — mencatat **setiap file dan folder** di volume.

```bash
# Ekstrak informasi file dari $MFT
# Dengan MFTECmd (EZ Tools)
MFTECmd.exe -f "\$MFT" --csv output.csv

# Informasi per file entry:
#   - Filename (short + long)
#   - Parent directory reference
#   - Timestamps: $STANDARD_INFORMATION (SI) vs $FILE_NAME (FN)
#   - Ukuran file (real + allocated)
#   - Flag: in use, directory, deleted
#   - Data attribute: resident/non-resident, cluster runs
```

**⚠️ Timestamp Manipulation Detection:**

```
$SI timestamp — bisa dimanipulasi dengan SetMACE / timestomp
$FN timestamp — TIDAK bisa dimanipulasi (karena di parent directory entry)
Jika $SI ≠ $FN → timestamp telah dimanipulasi
```

### 4.2 $UsnJrnl (Update Sequence Number Journal)

**Lokasi:** `$Extend\$UsnJrnl` (file sistem NTFS)
**Fungsi:** Mencatat **setiap perubahan** pada file — create, modify, delete, rename.

```bash
# Analisis dengan MFTECmd
MFTECmd.exe -f "\$UsnJrnl" --csv output.csv

# Informasi per entry:
#   - USN (sequence number — menaik)
#   - Timestamp
#   - Reason: DATA_EXTEND, DATA_OVERWRITE, RENAME_NEW_NAME, DELETE, etc
#   - Source info: USER vs SYSTEM
#   - File reference

# Gunakan USN untuk timeline:
# Urutkan berdasarkan USN ascending → timeline aktivitas per file
```

**CTF Pattern:** Cari Reason=DELETE — file apa yang dihapus? Mungkin attacker hapus tool setelah dipake. Reason=RENAME — file di-rename untuk sembunyi.

### 4.3 $LogFile

**Lokasi:** Root volume `$LogFile`
**Fungsi:** Transaction log NTFS — mencatat operasi yang belum di-commit ke $MFT.

```bash
# $LogFile bisa digunakan untuk:
# - Recover metadata yang belum ditulis ke $MFT
# - Deteksi timestamp modification
# - Lihat operasi yang dibatalkan (crash recovery)
```

### 4.4 Volume Shadow Copy (VSC)

**Lokasi:** `\\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy{N}`
**Fungsi:** Snapshot file system — bisa restore file versi sebelumnya.

```bash
# Lihat shadow copy
vssadmin list shadows

# Mount shadow copy
mklink /d C:\shadow_copy \\?\GLOBALROOT\Device\HarddiskVolumeShadowCopy1\

# Cari file yang dihapus di snapshot
# Versi file sebelum ransomware encrypt
```

---

## User Activity — Browser, Recent Files, Jump Lists

### 5.1 Browser History

**Chrome/Edge:**

```bash
# History database
%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\History
# SQLite database — table: urls, visits, downloads

sqlite3 History "SELECT url, title, last_visit_time FROM urls ORDER BY last_visit_time DESC LIMIT 20;"

# Cache
%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\Cache\

# Bookmarks
%USERPROFILE%\AppData\Local\Google\Chrome\User Data\Default\Bookmarks
```

**Firefox:**

```bash
# Profile folder
%USERPROFILE%\AppData\Roaming\Mozilla\Firefox\Profiles\*.default-release

# Places database
places.sqlite — table: moz_places, moz_historyvisits
```

**CTF Pattern:** URL terakhir yang dikunjungi — attacker cari exploit? Download tool? Klik link phishing?

### 5.2 Jump Lists

**Lokasi:** `%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations\`
**Fungsi:** Mencatat file-file yang baru dibuka per aplikasi.

```bash
# Dengan JLECmd (EZ Tools)
JLECmd.exe -d "C:\Users\user\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations" --csv output.csv

# Informasi per entry:
#   - Aplikasi (dari AppID)
#   - File path (bisa UNC path)
#   - Timestamp: created, modified, accessed
#   - Isi file (jika executable — bisa jadi malware path)
```

**AppID penting:**

| AppID              | Aplikasi         |
| ------------------ | ---------------- |
| `5b4d0c8f5a2c4e3f` | Notepad          |
| `9b1b1a2c3d4e5f6a` | Command Prompt   |
| `1b4d0c8f5a2c4e3f` | Windows Explorer |
| `a1b2c3d4e5f6a7b8` | Chrome           |
| `f4e5d6c7b8a9b0c1` | Word             |
| `e7d8c9b0a1f2e3d4` | Excel            |

### 5.3 LNK Files

**Lokasi:** `%USERPROFILE%\AppData\Roaming\Microsoft\Windows\Recent\*.lnk`
**Fungsi:** Shortcut yang baru diklik.

```bash
# Analisis dengan LECmd (EZ Tools)
LECmd.exe -f "C:\Users\user\Recent\malware.lnk" --csv output.csv

# Informasi dari LNK:
#   - Target file path + arguments
#   - Working directory
#   - Icon location
#   - Machine ID (hostname)
#   - Volume serial
#   - Timestamps
```

### 5.4 Recycle Bin ($Recycle.Bin)

**Lokasi:** `C:\$Recycle.Bin\SID\`
**Fungsi:** File yang dihapus user (belum permanently deleted).

```bash
# Analisis dengan RBCmd (EZ Tools)
RBCmd.exe -d "C:\$Recycle.Bin\S-1-5-21-..." --csv output.csv

# Informasi per file:
#   - Original path (sebelum dihapus)
#   - Deletion timestamp
#   - Ukuran file
#   - File header bytes
#   - Index (untuk recovery)
```

**CTF Pattern:** File yang dihapus dari Recycle Bin dalam waktu dekat → attacker bersih-bersih.

---

## USB Device History — Siapa Colok Flashdisk

### Registry Key: USBSTOR

**Lokasi:** `SYSTEM\CurrentControlSet\Enum\USBSTOR`
**Fungsi:** Semua USB mass storage device yang pernah terhubung.

```bash
# Melalui RegRipper:
rip.pl -r SYSTEM -f usb

# Informasi per device:
#   - Vendor ID (VID_xxxx)
#   - Product ID (PID_xxxx)
#   - Serial number (unique per device)
#   - Class: USBSTOR\Disk&Ven_...

# First/Last Connected:
# Cek di: SYSTEM\CurrentControlSet\Enum\USBSTOR\...\Properties\{83da6326-97a6-4088-9453-a1923f573b29}\0064
# 0064 = first connected
# 0065 = last connected
# 0066 = last removed
```

### Registry Key: MountedDevices

**Lokasi:** `SYSTEM\MountedDevices`
**Fungsi:** Mapping drive letter ke device.

```bash
# Cari flashdisk yang dicolok:
# \\DosDevices\\D: → GUID yang mengarah ke USBSTOR
# \\DosDevices\\E: → GUID yang mengarah ke USBSTOR
```

**⚠️ USB Serial Number:** Setiap flashdisk punya serial number unik. Jika Anda punya serial number, Anda bisa identifikasi flashdisk yang dipakai attacker — dan jika mereka pernah colok ke komputer lain, Anda bisa lacak.

---

## Prefetch & Superfetch — Application Execution History

(Pembahasan lebih detail di [[#1.1 Prefetch (.pf)]])

**Ringkasan Cepat:**

- Prefetch di `C:\Windows\Prefetch\*.pf`
- Setiap aplikasi → satu file .pf
- Nama format: `NAMAAPP.EXE-HASH.pf`
- Informasi: run count, first/last run, file yang diakses

**Praktik di CTF:**

```bash
# 1. Hitung aplikasi paling sering dijalankan
PECmd.exe -d "C:\Windows\Prefetch" --csv prefetch.csv
# Sortir: run count descending

# 2. Cari aplikasi "one-hit" — jalan cuma 1x (biasanya malware)
# Run count 1 = executable dijalankan sekali

# 3. Cari path yang tidak wajar
# %TEMP% atau %APPDATA% → dropper
# %USERPROFILE%\Downloads → download dari internet
# C:\Users\<user>\Desktop → user jalankan langsung

# 4. Timeline correlation
# Bandingkan timestamp Prefetch dengan Event ID 4688 (process creation)
# Waktu harus cocok — jika tidak, ada timestamp manipulation
```

---

## Windows Crash Dumps & Hibernation

### Crash Dump (.dmp)

**Lokasi:** `C:\Windows\Minidump\*.dmp` atau `C:\Windows\MEMORY.DMP`
**Fungsi:** Memory dump saat Windows crash.

```bash
# Analisis dengan Volatility 3
python3 vol.py -f C:\Windows\MEMORY.DMP windows.info
python3 vol.py -f C:\Windows\MEMORY.DMP windows.psscan
python3 vol.py -f C:\Windows\MEMORY.DMP windows.netscan
```

**CTF Pattern:** Crash dump sering berisi memory injection malware yang belum sempat dihapus — karena dump diambil saat crash, attacker tidak sempat bersih-bersih.

### Hibernation File (hiberfil.sys)

**Lokasi:** `C:\hiberfil.sys`
**Fungsi:** RAM dump saat laptop masuk hibernasi (sleep → disk).

```bash
# Ekstrak dengan volatility
python3 vol.py -f hiberfil.sys windows.info
# Sama seperti RAM dump — bisa extract proses, password, encryption key
```

**⚠️ Hibernation file bisa sebesar RAM (8–32 GB).** Jarang di CTF karena ukuran besar, tapi kalau ada — ini goldmine.

---

## Timeline Reconstruction

### Tools Timeline

| Tool                            | Output               | Kelebihan             |
| ------------------------------- | -------------------- | --------------------- |
| **Plaso (log2timeline)**        | .plaso → CSV/Elastic | Multi-source otomatis |
| **EZ Tools (TimelineExplorer)** | CSV timeline         | Windows-specific      |
| **MFTECmd + timeline**          | CSV timeline         | $MFT-focused          |

### Super Timeline dengan Plaso

```bash
# Buat timeline dari disk image
log2timeline --storage timeline.plaso evidence.dd

# Export ke CSV
psort -o l2tcsv -w timeline.csv timeline.plaso

# Filter timeline: cari kata "malware", "hack", atau "attack"
grep -i "malware\|hack\|mimikatz\|nc.exe\|psexec" timeline.csv

# Cari event antara dua waktu
awk -F',' '$1 >= "2026-07-28 10:00:00" && $1 <= "2026-07-28 14:00:00"' timeline.csv
```

### Timeline Windows — Event Sequence

Urutan yang harus dicari:

```
1. ✅ User login (Event 4624) → siapa, dari mana (IP), jam berapa
2. ✅ Download tool (Event 4688) → browser executable → browser.exe
3. ✅ Tool dijalankan (Event 4688) → mimikatz.exe / psexec.exe
4. ✅ Outbound connection (Event 5156 / Sysmon 3) → IP tujuan, port
5. ✅ File dihapus (RBCmd/$UsnJrnl) → tool dihapus setelah dipakai
6. ✅ User account dibuat (Event 4720) → backdoor account
7. ✅ User logout (Event 4634) → attacker selesai
```

**Dari timeline di atas, Anda bisa rekonstruksi:** Attacker X login jam 10:00 → download tool di 10:05 → jalankan tool di 10:10 → exfil data ke IP 5.6.7.8:443 → hapus tool di 10:15 → buat user baru di 10:20 → logout di 10:30.

---

## Cheat Sheet — Tools & Commands per Artifact

### Tools Wajib Windows Forensics

| Tool                          | Fungsi                                                  | Install                                              |
| ----------------------------- | ------------------------------------------------------- | ---------------------------------------------------- |
| **EZ Tools (Eric Zimmerman)** | MFT, USN, Registry, Event Log, Prefetch, Jump List, LNK | https://ericzimmerman.github.io/                     |
| **Volatility 3**              | Memory forensic                                         | `pip install volatility3`                            |
| **RegRipper**                 | Registry analysis                                       | `git clone https://github.com/keydet89/RegRipper3.0` |
| **Plaso**                     | Timeline                                                | `pip install plaso`                                  |
| **Sleuth Kit**                | Filesystem analysis                                     | `sudo apt install sleuthkit`                         |
| **Autopsy**                   | GUI forensic                                            | `sudo apt install autopsy`                           |
| **LogParser**                 | Event log query                                         | Microsoft download                                   |
| **python-evtx**               | Python EVTX parser                                      | `pip install python-evtx`                            |

### Command Quick Reference

```bash
# === FILE SYSTEM ===
# MFT analisis
MFTECmd.exe -f "\$MFT" --csv mft.csv

# USN journal
MFTECmd.exe -f "\$UsnJrnl" --csv usn.csv

# Recycle Bin
RBCmd.exe -d "\$Recycle.Bin\S-1-5-21-..." --csv recycle.csv

# === REGISTRY ===
# SYSTEM hive
rip.pl -r SYSTEM -f system
rip.pl -r SYSTEM -f usb
rip.pl -r SYSTEM -f network

# SOFTWARE hive
rip.pl -r SOFTWARE -f software
rip.pl -r SOFTWARE -f uninstall

# SAM hive
rip.pl -r SAM -f sam

# NTUSER.DAT
rip.pl -r NTUSER.DAT -f userassist
rip.pl -r NTUSER.DAT -f recentdocs

# === EVENT LOG ===
# Security events
EvtxeCmd.exe -f Security.evtx --csv security.csv --inc 4624,4625,4688,4720

# PowerShell
EvtxeCmd.exe -f Microsoft-Windows-PowerShell%4Operational.evtx --csv ps.csv

# Sysmon
EvtxeCmd.exe -f Microsoft-Windows-Sysmon%4Operational.evtx --csv sysmon.csv

# === APPLICATION EXECUTION ===
# Prefetch
PECmd.exe -d "C:\Windows\Prefetch" --csv prefetch.csv

# Amcache
AmcacheParser.exe -f Amcache.hve --csv amcache.csv

# ShimCache
AppCompatCacheParser.exe --csv shim.csv

# === USER ACTIVITY ===
# Jump Lists
JLECmd.exe -d "C:\Users\user\AppData\Roaming\Microsoft\Windows\Recent\AutomaticDestinations" --csv jumplist.csv

# LNK files
LECmd.exe -f "C:\Users\user\Recent\malware.lnk" --csv lnk.csv

# Browser history
# Chrome: sqlite3 History "SELECT * FROM urls ORDER BY last_visit_time DESC LIMIT 20;"

# === MEMORY (jika ada RAM dump) ===
vol.py -f memory.raw windows.psscan
vol.py -f memory.raw windows.netscan
vol.py -f memory.raw windows.cmdline
vol.py -f memory.raw windows.hashdump
vol.py -f memory.raw windows.malfind
```

---

## Cross-Link

- **Atlas Digital Evidence** → [[hierarchy-digital-evidence-acquisition]]
- **Memory Forensics Deep Dive** → [[memory-forensics-volatility-deepdive]]
- **Network Forensics** → [[hierarchy-network-forensics]]
- **IR Framework** → [[incident-response-framework]]
- **Tool Arsenal** → [[ctf-tool-arsenal-universal]]
- **CTF Methodology** → [[ctf-competition-methodology-strategy]]
- **Endpoint Detection** → [[hierarchy-endpoint-security]]
- **Master Index** → [[master-index]]

---

_Windows Forensics · Registry, Event Log, Prefetch, $MFT = Empat Pilar · Timestamp Manipulation Terdeteksi via $SI vs $FN · EZ Tools + Volatility + Plaso = Holy Trinity · Timeline = Kunci Rekonstruksi_
