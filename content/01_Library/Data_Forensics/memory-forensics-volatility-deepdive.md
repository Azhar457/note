---
tags:
  - memory-forensics
  - volatility
  - digital-forensics
  - incident-response
  - malware-analysis
  - ram-analysis
  - rootkit-detection
  - memory-acquisition
aliases:
  - Memory Forensics Volatility
  - Volatility 3 Deep-Dive
  - RAM Forensics
  - Memory Analysis Playbook
status: pending
created: 2026-07-23
updated: 2026-07-23
cssclasses:
  - wide-table
---

# Memory Forensics & Volatility 3: RAM Analysis untuk Researcher, Pentester & Militer

> [!tip] **Memory forensics** adalah analisis RAM dump untuk merekonstruksi aktivitas sistem, mendeteksi rootkit, malware, dan serangan tanpa meninggalkan jejak di disk. **Volatility 3** adalah framework open-source utama untuk analisis memory lintas platform (Windows, Linux, macOS). Catatan ini mencakup acquisition hingga analisis depth-level untuk operasi blue team, red team, dan military intelligence.

---

## Daftar Isi

1. [[#1. Memory Acquisition]]
2. [[#2. Volatility 3 vs Volatility 2]]
3. [[#3. Process Analysis]]
4. [[#4. Network Artifact Analysis]]
5. [[#5. Rootkit & Kernel-Mode Detection]]
6. [[#6. Credential Dumping]]
7. [[#7. Malware & Attacker Activity Reconstruction]]
8. [[#8. Timeline Analysis]]
9. [[#9. Anti-Forensics Detection]]
10. [[#10. MITRE ATT&CK Mapping]]
11. [[#Referensi]]
12. [[#Koneksi ke Vault]]

---

## 1. Memory Acquisition

### 1.1 Windows

```powershell
# FTK Imager — GUI (reliable untuk production)
# File → Capture Memory → Destination path

# winpmem — open-source dari Velociraptor
winpmem_mini_x64_rc2.exe memdump.raw

# DumpIt — dari Magnet/IOC (simple one-click)
DumpIt.exe /OUTPUT memdump.raw

# LiveKD — dari Sysinternals (cuma kernel space)
livekd -o kernel.raw
```

**Verifikasi integritas:**
```bash
sha256sum memdump.raw > memdump.sha256
echo "Hash tersimpan — chain of custody untuk forensik legal"
```

### 1.2 Linux

```bash
# LiME (Linux Memory Extractor) — load kernel module
# Build dari source:
git clone https://github.com/504ensicsLabs/LiME.git
cd LiME/src && make
sudo insmod lime.ko "path=memdump.lime format=lime"

# AVML (Azure VM Memory Linux) — production-ready
sudo ./avml memdump.raw
sudo ./avml memdump.compress.raw  # kompresi internal

# LiME via network — remote acquisition
sudo insmod lime.ko "path=tcp:4444 format=lime"  # netcat receiver: nc -l -p 4444 > memdump.lime

# /proc/kcore fallback (tanpa kernel module)
sudo xxd /proc/kcore | head -c 100M > memdump_proc.raw  # limited, missing userspace
```

### 1.3 macOS

```bash
# macOS Memory Reader (avml fork)
sudo ./macmr memdump.raw

# LiME untuk macOS (MacLime)
sudo kextload MacLime.kext  # SIP harus disabled

# OSXPMem (rekomen)
sudo osxpmem.app/Contents/MacOS/osxpmem -o memdump.raw
```

### 1.4 Virtual Machine (VMware, VirtualBox)

```bash
# VMware — file .vmem langsung
cp /vmfs/volumes/datastore/vm/vm_name.vmem ./memdump.raw

# VirtualBox — .sav + .vdi conversion
vboxmanage debugvm "VM Name" dumpvmcore --filename=vmcore.elf
```

---

## 2. Volatility 3 vs Volatility 2

| Aspek | Volatility 2 | Volatility 3 |
|-------|-------------|-------------|
| **Python** | Python 2 (EOL!) | Python 3 (modern) |
| **Profile** | Manual profile download (`--profile=Win10x64_19041`) | Auto-detection via `banners` + ISF |
| **Symbols** | Debug symbols per-OS version | ISF (Intermediate Symbol Format) — portable |
| **Plugin system** | Python class, register manual | Plugin auto-discover via directory scan |
| **Linux support** | Limited (kcore) | Full (via LiME, avml) |
| **macOS support** | Experimental (Yosemite only) | Native (Mojave+) |
| **Kecepatan** | Single-threaded | Multi-threaded (layer processing) |
| **Layering** | Fixed layer chain | Dynamic layer stacking |

**Command line comparison:**

```bash
# Volatility 2
python2 vol.py -f memdump.raw --profile=Win10x64_19041 pslist

# Volatility 3
python3 vol.py -f memdump.raw windows.pslist

# Volatility 3 — auto-detect OS
python3 vol.py -f memdump.raw windows.info
python3 vol.py -f memdump.raw linux.info
python3 vol.py -f memdump.raw mac.info
```

**Installasi Volatility 3:**
```bash
git clone https://github.com/volatilityfoundation/volatility3.git
cd volatility3
python3 -m venv venv && source venv/bin/activate
pip3 install .
# Download symbol tables untuk offline
python3 vol.py --symbol-dir /opt/volatility_symbols/
```

---

## 3. Process Analysis

### 3.1 Process Listing & Enumeration

```bash
# Proses normal — via PsActiveProcessHead linked list
python3 vol.py -f memdump.raw windows.pslist

# Proses tersembunyi — pool tag scanning (bypass DKOM)
python3 vol.py -f memdump.raw windows.psscan

# Process tree — parent-child relationship
python3 vol.py -f memdump.raw windows.pstree

# Contoh output parsing — ekstrak PPID
python3 vol.py -f memdump.raw windows.psscan --output=csv | grep -E "PID|PPID"
```

**Key indicators — process yang mencurigakan:**
- Proses tanpa parent (orphan process) — kemungkinan injection
- Proses dengan path tidak wajar: `C:\Users\Public\svchost.exe`
- Proses `svchost.exe` di luar `C:\Windows\System32\`
- Nama mirip: `scvhost.exe`, `expl0rer.exe`, `systme.exe`

### 3.2 DLL Injection Detection

```bash
# List DLL per process
python3 vol.py -f memdump.raw windows.dlllist --pid 1234

# Malfind — deteksi executable memory yang tidak normal
python3 vol.py -f memdump.raw windows.malfind

# Hollow process detection — image path mismatch
python3 vol.py -f memdump.raw windows.pslist | awk '$4 ~ /svchost/ && $3 != 1'

# Deteksi reflective DLL — via VAD tags
python3 vol.py -f memdump.raw windows.vadinfo --pid 1234
```

### 3.3 Process Injection Types

| Tipe Injection | Fileless? | Detection |
|---------------|-----------|-----------|
| Classic CreateRemoteThread | Ya (API) | `malfind`, VAD mem RX |
| Process Hollowing | Ya | PEB mismatch, `cmdline` anomali |
| APC Injection | Ya | `apcscan`, kernel APC queue |
| Reflective DLL | Ya | No LoadLibrary call, manual mapping |
| Threadless Injection | Ya | No CreateRemoteThread — harder |

---

## 4. Network Artifact Analysis

```bash
# TCP/UDP connections — dari network structures kernel
python3 vol.py -f memdump.raw windows.netscan

# Berbeda dengan netstat — netscan membaca kernel objects langsung
# Detection: hidden connection yang tidak muncul di netstat

# Socket handle — per process
python3 vol.py -f memdump.raw windows.handles --pid 1234 --object-type File

# DNS cache — domain yang baru di-resolve
python3 vol.py -f memdump.raw windows.dnscache

# IE/Edge history recover
python3 vol.py -f memdump.raw windows.iehistory
```

**Key C2 indicators dari memory:**
- Beacon interval pattern (fixed jitter)
- `netscan` → koneksi ke IP asing via port 443, 8080, 8443
- DNS cache → domain DGA (random string `.com`, `.xyz`)
- Process dengan outbound connection + hidden window

---

## 5. Rootkit & Kernel-Mode Detection

### 5.1 Driver & Module Scanning

```bash
# Kernel modules — driver tersembunyi
python3 vol.py -f memdump.raw windows.modscan   # hidden driver
python3 vol.py -f memdump.raw windows.modlist    # from PEB

# SSDT (System Service Dispatch Table) — hook detection
python3 vol.py -f memdump.raw windows.ssdt

# Driver IRP (I/O Request Packet) hooks
python3 vol.py -f memdump.raw windows.driverirp

# Driver scan — signature verification
python3 vol.py -f memdump.raw windows.modscan | \
  while read mod; do
    if [[ $mod != *"microsoft"* ]] && [[ $mod != *"windows"* ]]; then
      echo "[!] Unverified driver: $mod"
    fi
  done
```

### 5.2 Kernel Callback Detection

```bash
# Process creation callback — malware register untuk re-infect
python3 vol.py -f memdump.raw windows.callbacks

# Image load callback — detect non-Microsoft driver load
python3 vol.py -f memdump.raw windows.callbacks --Type LoadImage

# Registry callback — process persistence monitor
python3 vol.py -f memdump.raw windows.callbacks --Type Registry
```

### 5.3 DKOM (Direct Kernel Object Manipulation)

```bash
# Compare pslist vs psscan — proses yang hanya muncul di psscan = hidden
python3 vol.py -f memdump.raw windows.virtree

# EPROCESS token abuse — privilege escalation detection
python3 vol.py -f memdump.raw windows.getservicesids --pid 4  # System PID

# Hidden kernel threads
python3 vol.py -f memdump.raw windows.thrdscan --pid anomali
```

---

## 6. Credential Dumping

### 6.1 Windows — LSASS Memory Extraction

```bash
# LSASS process analysis
python3 vol.py -f memdump.raw windows.lsadump

# Hashdump — SAM registry hive dari memory
python3 vol.py -f memdump.raw windows.hashdump

# Mimikatz-like extraction via memory
# Cached domain credentials
python3 vol.py -f memdump.raw windows.cachedump

# DPAPI master key — decrypt protected data
python3 vol.py -f memdump.raw windows.dpapi -k
```

**LSASS protection bypass:**
- PPL (Protected Process Light) sejak Windows 8.1
- Bypass: kernel driver → disable PPL → dump
- Detection: `malfind` akan flag proses yang membaca LSASS memory

### 6.2 Linux — Credential Extraction

```bash
# Shadow file content dari kernel memory
python3 vol.py -f memdump.lime linux.passwd

# Bash history — attacker commands
python3 vol.py -f memdump.lime linux.bash

# Su/sudo logs
python3 vol.py -f memdump.lime linux.pslist | grep -E "sudo|su"

# SSH keys dari heap
python3 vol.py -f memdump.lime linux.keyutils
```

---

## 7. Malware & Attacker Activity Reconstruction

### 7.1 Command History

```bash
# Windows console history — attacker command line
python3 vol.py -f memdump.raw windows.cmdline          # process startup command
python3 vol.py -f memdump.raw windows.cmdscan          # command console history
python3 vol.py -f memdump.raw windows.consoles         # full console buffer

# Deteksi launcher — non-interactive process
python3 vol.py -f memdump.raw windows.cmdscan | grep -E "powershell.*-EncodedCommand|wmic|mshta|rundll32|cscript|wscript"
```

### 7.2 File Artifact Recovery

```bash
# MFT parsing dari memory — recently deleted files
python3 vol.py -f memdump.raw windows.mftparser

# TrueCrypt/VeraCrypt volume detection
python3 vol.py -f memdump.raw windows.truecryptsummary

# Prefetch files — application execution timeline
python3 vol.py -f memdump.raw windows.prefetchparser

# UserAssist — program execution dari registry memory
python3 vol.py -f memdump.raw windows.userassist
```

### 7.3 Clipboard & GUI

```bash
# Clipboard content — copy-paste attack command
python3 vol.py -f memdump.raw windows.clipboard

# Desktops — windows titles (attacker tools console)
python3 vol.py -f memdump.raw windows.windowstations

# Screenshot recovery — via GDI objects
python3 vol.py -f memdump.raw windows.gditimers
```

---

## 8. Timeline Analysis

```bash
# Timeliner — buat timeline event lengkap
python3 vol.py -f memdump.raw windows.timeliner \
  --output=csv --output-file=timeline.csv

# Filter dari timeline:
# 1. Process creation events — executable baru
# 2. Network connections — C2 communication window
# 3. File writes — dropper activity
# 4. Registry modifications — persistence

# Analisa burst activity — detection window
# Attacker biasanya:
# 1. Dropper → create reg run key → beacon out
# 2. Download payload → inject → network scan
# 3. Credential dump → exfiltrate
# Setiap fase punya memory artifact berbeda
```

**Timeline reconstruction steps:**
1. **Initial compromise:** Deteksi proses loader (usually short-lived)
2. **Persistence:** Registry `Run` key perubahan, scheduled task
3. **C2 establishment:** `netscan` + DNS cache → external IP
4. **Lateral movement:** New service creation, RDP artifacts
5. **Mission completion:** File deletion, log clearing, registry cleanup

---

## 9. Anti-Forensics Detection

| Teknik | Metode | Volatility Detection |
|--------|--------|---------------------|
| **Process hollowing** | Unmap PE, map malicious, resume thread | `malfind`, VAD mismatch |
| **DKOM** | Unlink EPROCESS from list | `psscan` vs `pslist` |
| **Memset** | Zero memory regions | `malfind` RWX pages |
| **Timestomping** | Ubah file timestamp | MFT vs prefetch timestamp |
| **Log clearing** | Clear EventLog entries | `evtlogs` buffer in memory |
| **API unhooking** | Restore original syscall | `ssdt` hook detection |
| **Hypervisor/rootkit** | VM-based rootkit (Blue Pill) | CPUID inconsistency, timing diff |
| **Memory encryption** | Encrypt pages in memory | `vadinfo` → page priority abnormal |

```bash
# Deteksi memset — executable pages dengan entropy rendah
python3 vol.py -f memdump.raw windows.vadinfo --pid 4444 | grep -E "VadS|Page|Entropy"

# Deteksi log clearing — EventLog buffer di memory
python3 vol.py -f memdump.raw windows.evtlogs
```

---

## 10. MITRE ATT&CK Mapping

| Tactic | Technique ID | Nama | Volatility Plugin |
|--------|-------------|------|-------------------|
| Execution | T1059 | Command and Scripting Interpreter | `cmdscan`, `consoles`, `cmdline` |
| Persistence | T1547 | Boot or Logon Autostart Execution | `prefetchparser`, `userassist` |
| Privilege Escalation | T1055 | Process Injection | `malfind`, `vadinfo` |
| Defense Evasion | T1564 | Hide Artifacts | `psscan`, `modscan` |
| Credential Access | T1003 | OS Credential Dumping | `lsadump`, `hashdump`, `cachedump` |
| Discovery | T1057 | Process Discovery | `pslist`, `pstree` |
| Command & Control | T1071 | Application Layer Protocol | `netscan`, `dnscache` |
| Exfiltration | T1041 | Exfiltration Over C2 | `netscan` (large outbound data) |

---

## Referensi

1. Volatility Foundation. *"Volatility 3 Documentation."* (2024). https://volatility3.readthedocs.io/
2. Ligh, M. H. et al. *"The Art of Memory Forensics."* Wiley (2014).
3. Case, A. & Golden, R. *"Windows Memory Forensics with Volatility 3."* SANS (2023).
4. 504ensics Labs. *"LiME — Linux Memory Extractor."* (2023).
5. Microsoft. *"Windows TimeLine: The Evolution of Memory Acquisition."* (2024).
6. Mandiant. *"In-Memory Threats: From Code Injection to Process Hollowing."* (2023).
7. CrowdStrike. *"DKOM: The Hidden Process Problem."* (2024).
8. uacm. *"Magnet DumpIt vs winpmem: Acquisition Comparison."* (2024).
9. MITRE. *"ATT&CK: Enterprise Matrix — Defense Evasion."* (2024).
10. Cichonski, P. et al. *"NIST SP 800-86: Guide to Integrating Forensic Techniques into Incident Response."* (2023).

---

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[data-recovery]] | Data recovery dari disk — memory sebagai pelengkap jika disk di-encrypt |
| [[mobile-forensics]] | Mobile device forensics — beda metodologi, sama tujuan reconstruct |
| [[malware-analysis-reverse-engineering-playbook]] | Analisis malware — memory forensics untuk dynamic analysis |
| [[endpoint-detection-playbook]] | EDR detection — memory artifact sebagai source of truth |
| [[forensic-imaging-analysis]] | SOP imaging — memory + disk imaging untuk forensik lengkap |
| [[incident-response-framework]] | IR framework — memory forensics fase 3: analysis & containment |
| [[kernel-forensics]] | Kernel forensics — rootkit detection overlap dengan memory |
