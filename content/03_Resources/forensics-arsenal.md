# 🛠️ Forensics & Data Recovery Arsenal

> **Semua tool di sini gratis, open-source, atau trial-available**  
> **Semua bisa dipelajari sendiri — dari pemula sampai level lab forensik**  
> **Target:** DFIR (Digital Forensics & Incident Response), Data Recovery, e-Discovery

---

## 📌 Kategori Cepat

| Badge              | Arti                                                                                 |
| ------------------ | ------------------------------------------------------------------------------------ |
| ⬡ **fondasi**      | Tool dasar yang WAJIB dikuasai                                                       |
| ⬡ **imaging**      | Forensic imaging & acquisition                                                       |
| ⬡ **analysis**     | Analisis file system, memory, network                                                |
| ⬡ **recovery**     | Data recovery & file carving                                                         |
| ⬡ **mobile**       | Mobile device forensics                                                              |
| ⚠ **warning zone** | Butuh pengetahuan menengah, bisa merusak evidence jika salah                         |
| ☠ **danger zone**  | Advanced, ribet, tapi PASTI berguna ke depan. Bisa bikin pusing tapi skillnya mahal. |

---

## ⬡ FONDASI (Wajib Banget)

### SystemRescue

**Spesialisasi:** Live OS untuk forensik & recovery  
**Fitur Unggulan:** Pre-installed dengan ddrescue, testdisk, photorec, smartmontools, forensic tools  
**Target:** Semua level — bootable USB pertama yang harus ada di toolkit  
**Kesulitan:** ⭐ (1/5)  
**Tags:** `live-os`, `all-in-one`, `gratis`

```bash
# Buat bootable USB
sudo dd if=systemrescue.iso of=/dev/sdX bs=4M status=progress
```

### Kali Linux

**Spesialisasi:** Penetration testing + Forensics  
**Fitur Unggulan:** Autopsy, Sleuth Kit, Volatility, bulk_extractor, YARA pre-installed  
**Target:** Cybersecurity analyst, DFIR investigator  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `distro`, `dfir`, `pre-installed`

### Paladin OS

**Spesialisasi:** Forensic-focused Linux distro  
**Fitur Unggulan:** GUI-based, write-blocking otomatis, chain of custody helper, report generator  
**Target:** Law enforcement, beginner forensic analyst  
**Kesulitan:** ⭐ (1/5)  
**Tags:** `distro`, `gui`, `law-enforcement`

### CAINE (Computer Aided INvestigative Environment)

**Spesialisasi:** Italian forensic distro  
**Fitur Unggulan:** GUI forensik lengkap, integrated report, evidence management  
**Target:** Digital forensic investigator, academic  
**Kesulitan:** ⭐ (1/5)  
**Tags:** `distro`, `gui`, `academic`

---

## ⬡ IMAGING (Forensic Acquisition)

### dd

**Spesialisasi:** Raw imaging paling dasar  
**Fitur Unggulan:** Universal, ada di semua Unix, bit-for-bit copy  
**Target:** Semua level — tool paling fundamental  
**Kesulitan:** ⭐ (1/5)  
**Tags:** `builtin`, `raw`, `basic`

```bash
dd if=/dev/sdX of=image.dd bs=64K status=progress
```

### dc3dd

**Spesialisasi:** Forensic-grade dd  
**Fitur Unggulan:** On-the-fly hashing (MD5+SHA256), progress display, log otomatis, split output  
**Target:** Forensic investigator yang butuh court-admissible evidence  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `forensic-grade`, `hashing`, `logging`

```bash
dc3dd if=/dev/sdX of=image.dd hash=sha256 log=imaging.log
```

### dcfldd

**Spesialisasi:** Enhanced dd dengan forensik features  
**Fitur Unggulan:** Multiple hash algorithms, flexible logging, status output  
**Target:** Forensic analyst yang butuh flexibility  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `forensic-grade`, `flexible`, `logging`

### ddrescue / GNU ddrescue

**Spesialisasi:** Imaging drive rusak / bad sector  
**Fitur Unggulan:** BISA RESUME, intelligent skipping, retry logic, mapping file  
**Target:** Data recovery technician, drive yang mulai mati  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `recovery`, `resume`, `bad-sector`, `powerful`

```bash
# Pass 1: Copy cepat, skip bad sector
ddrescue -f -n /dev/sdX image.dd rescue.log

# Pass 2: Retry bad sector (3x)
ddrescue -d -r3 /dev/sdX image.dd rescue.log
```

### Guymager

**Spesialisasi:** GUI forensic imager  
**Fitur Unggulan:** GUI yang clean, E01 & AFF support, built-in verification  
**Target:** Investigator yang lebih nyaman GUI daripada CLI  
**Kesulitan:** ⭐ (1/5)  
**Tags:** `gui`, `e01`, `aff`, `user-friendly`

### ewfacquire (libewf)

**Spesialisasi:** Expert Witness Format (E01) acquisition  
**Fitur Unggulan:** Compressed forensic image, CRC integrity per chunk, metadata embedding  
**Target:** Enterprise forensic, EnCase-compatible workflows  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `e01`, `compressed`, `encase`, `enterprise`

```bash
ewfacquire /dev/sdX -t image -C case001 -D "Evidence HDD" -e "Investigator"
```

### AFF4 Imager

**Spesialisasi:** Next-gen forensic format  
**Fitur Unggulan:** Open standard, memory forensics compatible, streaming capable  
**Target:** Advanced forensic lab, research institution  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `next-gen`, `open-standard`, `memory-compatible`

---

## ⬡ ANALYSIS (Investigasi & Extraction)

### Autopsy

**Spesialisasi:** GUI forensic analysis platform  
**Fitur Unggulan:** Timeline analysis, keyword search, file carving, EXIF parser, report generator, module extensible  
**Target:** DFIR analyst, law enforcement, corporate investigator  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `gui`, `timeline`, `keyword-search`, `reporting`, `enterprise`

### Sleuth Kit (TSK)

**Spesialisasi:** CLI forensic analysis framework  
**Fitur Unggulan:** `fls` (list files), `ils` (list inodes), `icat` (extract file), `fsstat` (file system info)  
**Target:** Forensic analyst yang butuh granular control  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `cli`, `framework`, `granular`, `powerful`

```bash
# List semua file (termasuk deleted)
fls -r -p /dev/sdX

# Extract file dari inode
icat /dev/sdX 12345 > recovered_file.doc
```

### Volatility

**Spesialisasi:** Memory forensics framework  
**Fitur Unggulan:** Analisis RAM dump: process list, network connections, registry, malware detection, password extraction  
**Target:** Malware analyst, incident responder, advanced DFIR  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `memory`, `malware`, `advanced`, `powerful`

```bash
# Identifikasi profile OS dari RAM dump
volatility -f memory.dmp imageinfo

# List process
volatility -f memory.dmp --profile=Win7SP1x64 pslist
```

### Plaso / log2timeline

**Spesialisasi:** Super-detailed timeline generation  
**Fitur Unggulan:** Aggregasi timestamp dari SEMUA artifact: registry, event logs, browser history, file system, dll  
**Target:** Timeline analyst, incident responder  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `timeline`, `aggregation`, `detailed`, `enterprise`

```bash
log2timeline.py timeline.plaso /dev/sdX
psort.py -o l2tcsv timeline.plaso > timeline.csv
```

### Bulk Extractor

**Spesialisasi:** Fast data extraction  
**Fitur Unggulan:** Scan seluruh disk tanpa parse file system — email, CC, URL, domain, SSN, phone numbers  
**Target:** Quick triage, e-discovery, data classification  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `fast`, `triage`, `pii`, `e-discovery`

```bash
bulk_extractor -o bulk_out/ /dev/sdX
```

### YARA

**Spesialisasi:** Pattern matching for malware/artifacts  
**Fitur Unggulan:** Rule-based detection, IOC matching, custom signatures  
**Target:** Malware analyst, threat hunter  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `malware`, `ioc`, `rules`, `threat-hunting`

```bash
yara -r malware_rules.yar /mnt/analysis/
```

### ExifTool

**Spesialisasi:** Metadata extraction  
**Fitur Unggulan:** 1000+ file formats, GPS extraction, timestamp analysis, batch processing  
**Target:** OSINT investigator, image/video forensics  
**Kesulitan:** ⭐ (1/5)  
**Tags:** `metadata`, `exif`, `gps`, `osint`

```bash
exiftool -r -gps* -DateTimeOriginal /mnt/analysis/ > metadata.txt
```

### analyzeMFT

**Spesialisasi:** NTFS Master File Table parser  
**Fitur Unggulan:** Parse $MFT untuk timeline file system, detect timestomping  
**Target:** Windows forensics specialist  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `ntfs`, `mft`, `windows`, `timestomp`

---

## ⬡ RECOVERY (Data Recovery & Carving)

### TestDisk

**Spesialisasi:** Partition recovery & repair  
**Fitur Unggulan:** Recovery tabel partisi, recovery boot sector, undelete files (FAT/NTFS/ext2)  
**Target:** Technician, sysadmin, DIY recovery  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `partition`, `repair`, `undelete`, `interactive`

```bash
testdisk /dev/sdX
# Pilih: [Create] → [Intel] → [Analyse] → [Quick Search] → [List] → Copy
```

### PhotoRec

**Spesialisasi:** File carving (tanpa file system)  
**Fitur Unggulan:** Recovery 480+ file formats, works on corrupted/formatted drives, ignores file system  
**Target:** Recovery dari drive yang terformat atau file system corrupt  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `carving`, `format-agnostic`, `480-formats`, `powerful`

```bash
photorec /d /mnt/recovered /dev/sdX
```

### Foremost

**Spesialisasi:** File carving (predefined types)  
**Fitur Unggulan:** Military-grade (US Air Force), predefined headers, config file customizable  
**Target:** Military/enterprise, predefined recovery  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `military`, `predefined`, `configurable`, `enterprise`

```bash
foremost -t jpg,pdf,doc,zip -i image.dd -o recovered/
```

### Scalpel

**Spesialisasi:** File carving (custom headers)  
**Fitur Unggulan:** Custom header/footer definitions, multi-threaded, fast  
**Target:** Advanced recovery, custom file formats  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `custom`, `headers`, `multi-thread`, `advanced`

### R-Studio

**Spesialisasi:** Professional data recovery GUI  
**Fitur Unggulan:** Recovery dari formatted/corrupt/deleted, RAID reconstruction, network recovery  
**Target:** Professional data recovery technician  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `gui`, `professional`, `raid`, `network`, `enterprise`

### UFS Explorer

**Spesialisasi:** RAID & complex storage recovery  
**Fitur Unggulan:** RAID 0/1/5/6/10 reconstruction, virtual disk support, NAS/SAN recovery  
**Target:** Enterprise data recovery, data center  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `raid`, `nas`, `san`, `virtual-disk`, `enterprise`

### DMDE

**Spesialisasi:** Manual hex editing & partition repair  
**Fitur Unggulan:** Disk editor, partition manager, RAID constructor, NTFS utilities  
**Target:** Expert / "opreker" hardcore, low-level repair  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `hex-editor`, `manual`, `low-level`, `expert`, `cheap-but-deadly`

---

## ⬡ MOBILE FORENSICS

### ADB (Android Debug Bridge)

**Spesialisasi:** Android acquisition & analysis  
**Fitur Unggulan:** Backup, shell access, file extraction, logcat  
**Target:** Mobile forensic technician  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `android`, `builtin`, `cli`, `acquisition`

```bash
adb backup -apk -shared -all -f backup.ab
adb pull /sdcard/ /mnt/evidence/android/
```

### iTunes Backup + iBackupBot

**Spesialisasi:** iOS logical acquisition  
**Fitur Unggulan:** Backup extraction, plist parsing, message recovery  
**Target:** iOS investigator, law enforcement (budget)  
**Kesulitan:** ⭐⭐ (2/5)  
**Tags:** `ios`, `logical`, `backup`, `budget`

### Cellebrite UFED

**Spesialisasi:** Mobile forensic enterprise  
**Fitur Unggulan:** Physical & logical extraction, bypass lockscreen, cloud extraction, report generator  
**Target:** Law enforcement, corporate forensic lab  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `enterprise`, `physical`, `lock-bypass`, `cloud`, `expensive`

### GrayKey

**Spesialisasi:** iOS unlock & extraction  
**Fitur Unggulan:** Brute-force iOS passcode, full file system extraction  
**Target:** Law enforcement (restricted)  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `ios`, `brute-force`, `restricted`, `law-enforcement`, `expensive`

### Magnet AXIOM

**Spesialisasi:** Digital evidence platform (mobile + computer + cloud)  
**Fitur Unggulan:** Artifact parsing, cloud sync analysis, timeline, reporting  
**Target:** DFIR lab, law enforcement, corporate  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `artifact`, `cloud`, `timeline`, `reporting`, `enterprise`

---

## ⚠️ WARNING ZONE (Menengah — Hati-hati, Bisa Merusak Evidence)

### EnCase Forensic (OpenText)

**Spesialisasi:** Enterprise forensic platform  
**Fitur Unggulan:** E01 format native, scripting (EnScript), enterprise case management  
**Target:** Large forensic lab, law enforcement, corporate  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `enterprise`, `e01`, `scripting`, `expensive`, `industry-standard`

### X-Ways Forensics

**Spesialisasi:** Lightweight but powerful forensic suite  
**Fitur Unggulan:** Ultra-fast, low resource, template-based reporting, WinHex integration  
**Target:** Expert investigator yang butuh speed & efficiency  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `fast`, `lightweight`, `winhex`, `expert`, `expensive`

### FTK (Forensic Toolkit)

**Spesialisasi:** Full forensic suite + e-Discovery  
**Fitur Unggulan:** Distributed processing, KFF hash database, indexing, review platform  
**Target:** Enterprise e-discovery, large-scale investigation  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `enterprise`, `distributed`, `indexing`, `e-discovery`, `expensive`

### SANS SIFT Workstation

**Spesialisasi:** Pre-configured forensic VM  
**Fitur Unggulan:** Semua tool forensik terinstall & terkonfigurasi, SANS course compatible  
**Target:** SANS student, DFIR practitioner  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `vm`, `pre-configured`, `sans`, `training`, `all-in-one`

### REMnux

**Spesialisasi:** Malware analysis distro  
**Fitur Unggulan:** Reverse engineering tools, sandbox analysis, network analysis  
**Target:** Malware analyst, reverse engineer  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `malware`, `reverse-engineering`, `sandbox`, `advanced`

### Rekall

**Spesialisasi:** Memory forensics framework (alternative Volatility)  
**Fitur Unggulan:** Modern codebase, better plugin architecture, cross-platform  
**Target:** Memory forensics researcher  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `memory`, `alternative`, `modern`, `research`

### Redline

**Spesialisasi:** Endpoint threat detection & analysis  
**Fitur Unggulan:** Mandiant (Google Cloud), IOC hunting, memory analysis, timeline  
**Target:** Incident responder, SOC analyst  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `endpoint`, `ioc`, `mandiant`, `incident-response`, `free`

---

## ☠️ DANGER ZONE (Advanced — Ribet Tapi PASTI Berguna Kedepannya)

### PC-3000 (ACE Laboratory)

**Spesialisasi:** Hardware-level disk repair & firmware  
**Fitur Unggulan:** Firmware repair, head mapping, translator rebuild, password removal, factory mode access  
**Target:** Professional data recovery lab, hardware specialist  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `hardware`, `firmware`, `russia`, `professional-lab`, `expensive`, `king-of-recovery`

> **Kenapa ribet:** Butuh pemahaman elektronik disk, soldering skill, dan pengetahuan firmware vendor-specific. Tapi ini adalah tool TERKUAT untuk recovery fisik.

### Dolphin Data Lab

**Spesialisasi:** DVR/CCTV video recovery + firmware  
**Fitur Unggulan:** 99% DVR brands support, deep scan video fragments, overwrite recovery, firmware repair  
**Target:** Forensic video specialist, police, security company  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `video`, `dvr`, `cctv`, `china`, `firmware`, `deep-scan`, `forensic-video`

> **Kenapa ribet:** Video DVR punya format proprietary yang beda-beda. Dolphin punya database firmware terbesar tapi butuh pemahaman struktur video khusus.

### Atola TaskForce

**Spesialisasi:** Hardware imager & diagnostik otomatis  
**Fitur Unggulan:** Imaging tercepat (500+ MB/s), auto-diagnosis hardware, multi-drive parallel, report otomatis  
**Target:** Large recovery lab, enterprise forensic  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `hardware-imager`, `fast`, `auto-diagnosis`, `parallel`, `enterprise`, `expensive`

> **Kenapa ribet:** Hardware imager level enterprise. Harganya puluhan ribu dolar tapi bisa imaging 4 drive sekaligus dengan kecepatan maksimal.

### RapidSpar

**Spesialisasi:** Cloud-based firmware repair  
**Fitur Unggulan:** Auto firmware fix via cloud, tidak perlu jadi ahli firmware, plug-and-play  
**Target:** Computer repair shop, mid-level technician  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `cloud`, `firmware`, `auto-repair`, `mid-level`, `plug-and-play`

> **Kenapa ribet:** Meski "auto", tetap butuh pemahaman kapan harus pakai mode apa. Cloud dependency juga concern untuk evidence sensitif.

### DeepSpar Disk Imager

**Spesialisasi:** Professional imaging untuk drive rusak  
**Fitur Unggulan:** Hardware-level control, adaptive imaging, head selection, power management  
**Target:** Professional recovery lab  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `hardware-imager`, `adaptive`, `head-control`, `professional`, `expensive`

> **Kenapa ribet:** Control hardware langsung ke drive. Bisa matiin head yang rusak, atur power, dan imaging dengan strategi khusus per-drive.

### MantaRay (Dolphin)

**Spesialisasi:** Forensic data recovery hardware  
**Fitur Unggulan:** Write-block hardware, imaging, analysis, report — all-in-one box  
**Target:** Law enforcement, corporate forensic  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `all-in-one`, `hardware`, `write-block`, `law-enforcement`, `enterprise`

### HxD / 010 Editor / Hex Workshop

**Spesialisasi:** Hex editor profesional  
**Fitur Unggulan:** Edit disk langsung, template parsing, binary diff, data interpreter  
**Target:** Reverse engineer, forensic analyst, malware researcher  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `hex-editor`, `disk-edit`, `template`, `reverse-engineering`, `expert`

> **Kenapa ribet:** Bisa edit byte per byte langsung ke disk. Satu kesalahan = evidence corrupt. Butuh pemahaman struktur biner mendalam.

### Hashcat

**Spesialisasi:** Password cracking & hash recovery  
**Fitur Unggulan:** GPU acceleration, 300+ hash types, distributed cracking, rule-based attack  
**Target:** Password forensic, encrypted volume recovery  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `password`, `gpu`, `cracking`, `distributed`, `advanced`, `powerful`

```bash
# Crack WPA2 handshake
hashcat -m 2500 capture.hccapx wordlist.txt

# Crack BitLocker
hashcat -m 22100 bitlocker_hash.txt wordlist.txt
```

> **Kenapa ribet:** Butuh GPU powerful, pemahaman hash algorithms, dan strategi attack (dictionary, brute-force, rules, masks). Tapi ini KUNCI untuk akses encrypted evidence.

### John the Ripper

**Spesialisasi:** Password cracker (alternative Hashcat)  
**Fitur Unggulan:** CPU-focused, auto-detection hash type, community rules  
**Target:** Password forensic, system penetration tester  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `password`, `cpu`, `auto-detect`, `community`, `alternative`

### Binwalk

**Spesialisasi:** Firmware analysis & extraction  
**Fitur Unggulan:** Signature analysis, embedded file extraction, entropy analysis, disassembly  
**Target:** IoT forensics, firmware reverse engineer  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `firmware`, `iot`, `extraction`, `entropy`, `reverse-engineering`

```bash
# Extract embedded files dari firmware
binwalk -e firmware.bin

# Entropy analysis (detect encrypted/compressed)
binwalk -E firmware.bin
```

> **Kenapa ribet:** Firmware IoT punya struktur unik. Binwalk bisa extract tapi butuh pemahaman arsitektur embedded systems untuk analisis lanjut.

### Ghidra

**Spesialisasi:** Reverse engineering framework (NSA)  
**Fitur Unggulan:** Disassembly, decompilation, scripting, collaborative analysis  
**Target:** Malware reverse engineer, vulnerability researcher  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `reverse-engineering`, `disassembly`, `decompiler`, `nsa`, `free`, `powerful`

> **Kenapa ribet:** Reverse engineering butuh pemahaman assembly, C, dan arsitektur CPU. Ghidra powerful tapi learning curve-nya curam. Skill ini MAHAL di pasaran.

### Radare2 / Cutter

**Spesialisasi:** Open-source reverse engineering  
**Fitur Unggulan:** CLI-based (Radare2) atau GUI (Cutter), debugger, emulator, binary analysis  
**Target:** Open-source reverse engineer, CTF player  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `reverse-engineering`, `open-source`, `debugger`, `cli`, `advanced`

### Velociraptor

**Spesialisasi:** Endpoint monitoring & forensic hunting  
**Fitur Unggulan:** VQL (Velociraptor Query Language), artifact collection, hunting across enterprise  
**Target:** Enterprise DFIR, threat hunter, SOC  
**Kesulitan:** ⭐⭐⭐⭐⭐ (5/5)  
**Tags:** `endpoint`, `hunting`, `vql`, `enterprise`, `dfir`, `advanced`

> **Kenapa ribet:** VQL adalah bahasa query khusus yang powerful tapi butuh waktu untuk dikuasai. Tapi sekali dikuasai, bisa hunting artifact di ribuan endpoint sekaligus.

### osquery

**Spesialisasi:** SQL-powered system instrumentation  
**Fitur Unggulan:** Query OS state via SQL, real-time monitoring, cross-platform  
**Target:** Security engineer, system administrator  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `sql`, `monitoring`, `cross-platform`, `facebook`, `enterprise`

### CrowdStrike Falcon / Carbon Black

**Spesialisasi:** EDR (Endpoint Detection & Response)  
**Fitur Unggulan:** Real-time telemetry, threat hunting, incident response, remote acquisition  
**Target:** Enterprise SOC, MSSP  
**Kesulitan:** ⭐⭐⭐⭐ (4/5)  
**Tags:** `edr`, `telemetry`, `enterprise`, `cloud`, `expensive`

### KAPE (Kroll Artifact Parser and Extractor)

**Spesialisasi:** Targeted artifact collection & parsing  
**Fitur Unggulan:** Lightning-fast collection, 100+ targets predefined, timeline-ready output  
**Target:** Incident responder, DFIR consultant  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `artifact`, `fast`, `targeted`, `kroll`, `incident-response`, `free`

```bash
# Collect artifacts dari live system
kape.exe --tsource C: --tdest D:\Collection --target !SANS_Triage
```

### Eric Zimmerman Tools

**Spesialisasi:** Windows artifact parsing suite  
**Fitur Unggulan:** 20+ tools untuk parse registry, event logs, jump lists, prefetch, shellbags, dll  
**Target:** Windows forensic analyst  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `windows`, `artifact`, `registry`, `free`, `comprehensive`

> **Kenapa ribet:** Windows punya RATUSAN artifact. Tools Eric Zimmerman parse masing-masing tapi butuh pemahaman Windows internals untuk interpretasi.

### RegRipper

**Spesialisasi:** Registry analysis automation  
**Fitur Unggulan:** Plugin-based, 500+ plugins, timeline generation, malware detection  
**Target:** Windows forensic specialist  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `registry`, `windows`, `plugin`, `automation`, `forensic`

```bash
rip.pl -r NTUSER.DAT -p userassist
```

### Chntpw

**Spesialisasi:** Windows password reset & registry edit  
**Fitur Unggulan:** Reset password admin, edit registry offline, unlock account  
**Target:** System recovery technician  
**Kesulitan:** ⭐⭐⭐ (3/5)  
**Tags:** `password-reset`, `registry`, `offline`, `windows`, `recovery`

---

## 📊 Quick Reference Matrix

| Skenario                    | Tool Rekomendasi        | Level      |
| --------------------------- | ----------------------- | ---------- |
| Drive hidup, butuh RAM dump | Volatility + LiME       | ⚠️ Warning |
| Drive mati, bad sector      | ddrescue → Autopsy      | ⬡ Fondasi  |
| Partisi hilang / RAW        | TestDisk                | ⬡ Fondasi  |
| File terhapus               | PhotoRec / R-Studio     | ⬡ Fondasi  |
| DVR/CCTV recovery           | Dolphin Data Lab        | ☠️ Danger  |
| Firmware corrupt            | PC-3000 / RapidSpar     | ☠️ Danger  |
| RAID failure                | UFS Explorer / R-Studio | ⚠️ Warning |
| Encrypted volume            | Hashcat / John          | ☠️ Danger  |
| Mobile Android              | ADB + Autopsy           | ⬡ Fondasi  |
| Mobile iOS locked           | Cellebrite / GrayKey    | ☠️ Danger  |
| Malware analysis            | REMnux + Ghidra         | ☠️ Danger  |
| Enterprise hunting          | Velociraptor + KAPE     | ☠️ Danger  |
| Timeline super-detail       | Plaso + Autopsy         | ⚠️ Warning |
| Quick triage                | Bulk Extractor          | ⬡ Fondasi  |

---

> [!TIP] **Learning Path Recommendation:**
>
> 1. **Month 1-2:** Kuasai SystemRescue + ddrescue + TestDisk + PhotoRec
> 2. **Month 3-4:** Deep dive Autopsy + Sleuth Kit + Volatility
> 3. **Month 5-6:** Plaso timeline + YARA + Bulk Extractor
> 4. **Month 7-12:** Pilih spesialisasi — Mobile (Cellebrite), Hardware (PC-3000), atau Malware (Ghidra/REMnux)
