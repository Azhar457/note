---
title: "Hierarchy Digital Evidence & Forensic Acquisition"
tags:
  - atlas
  - digital-forensic
  - evidence-acquisition
  - chain-of-custody
  - forensic-investigation
aliases:
  - "hierarchy-digital-evidence-acquisition"
created: "2026-07-28"
updated: '2026-07-28'
status: pending
---

# 🔬 HIERARCHY DIGITAL EVIDENCE & FORENSIC ACQUISITION — Dari Volatile Memory sampai Persistent Cold Storage

> Digital forensic adalah **proses pengawetan, akuisisi, dan analisis bukti digital secara ilmiah dan dapat diverifikasi**. Berbeda dari hacking (cari celah), forensic harus **tahan terhadap cross-examination** — setiap langkah harus reproducible dan chain of custody harus jelas. Hirarki ini memetakan **evolusi persistensi bukti digital** dari **Level 0 (RAM — paling volatil, hilang dalam detik setelah power off)** sampai **Level 6 (cold storage/archived — stabil selama bertahun-tahun)**. Semakin rendah level, semakin mudah bukti hilang — tapi semakin kaya data yang bisa digali.

> [!info] Cara Baca Atlas Ini
> **Baca dari bawah ke atas** — dari Level 0 (RAM) yang paling volatil ke Level 6 (archived) yang paling stabil. Urutan akuisisi dalam investigasi real: **Level 0 → Level 1 → ... → Level 6**. Karena RAM dan network connection hilang duluan saat device mati, mereka harus dikumpulkan pertama. Untuk SOP teknis konkret, lihat [[forensic-imaging-analysis]]. Untuk tools per level, lihat [[ctf-tool-arsenal-universal]].

---

## Tabel Utama — Level 0 sampai Level 6

| 🔬 Level | 🧠 Lapisan Bukti | ⏱️ Volatilitas | ⚡ Sumber Bukti | 📦 Tools Akuisisi | ☠️ Risiko Hilang |
|---|---|---|---|---|---|
| **Level 0** — Volatile Memory (RAM) | Detik sampai menit setelah power loss | **Sangat Tinggi** — hilang total saat shutdown | Physical RAM dump, pagefile, swap, /proc/kcore, hiberfil.sys | LiME, Volatility (acquisition), FTK Imager (live), WinPmem, Rekall, RamCapturer | Power loss = data hilang permanen. Cold boot attack: RAM data bertahan ~detik-detik 5–10 menit jika didinginkan |
| **Level 1** — Network Connections & State | Saat koneksi aktif | **Tinggi** — hilang saat disconnect | Active TCP/UDP connections, ARP cache, routing table, DNS cache, netstat output, conntrack entries | netstat, ss, lsof, tcpdump, Wireshark (live capture), netsh, ntopng, Zeek (live) | Network disconnect = state hilang. TTL setiap entri DNS/ARP dalam hitungan detik-menit |
| **Level 2** — Running Processes & OS State | Selama OS menyala | **Tinggi** — berubah tiap detik | Process list, open handles, loaded modules, environment variables, scheduled tasks, logged-on users, clipboard, kernel objects | Sysinternals Suite (pslist, handle, listdlls), ps aux, lsof, /proc/*, autorunsc, zadig | Proses bisa mati kapan saja. Evil process mungkin hanya hidup 30 detik |
| **Level 3** — Temporary & Transient Files | Selama sesi aktif + beberapa hari | **Sedang** — bisa bertahan sampai dihapus OC/cleaner | Browser cache & history, /tmp, %TEMP%, prefetch, recent files, jump lists, thumbnail cache, recycle bin, $Recycle.Bin | Sleuth Kit, Autopsy, FRED, Magnet RAM Capture, tmp watch tools, USN journal parser | Disk cleanup, CCleaner, log rotation, cache eviction. Beberapa file hanya bertahan 1–7 hari |
| **Level 4** — Persistent Storage (Active) | Selama file disimpan | **Rendah** — stabil sampai dihapus/shred | Filesystem (NTFS, ext4, APFS, FAT32), $MFT, journal, $LogFile, unallocated space, $UsnJrnl, $Boot, volume shadow copy | EnCase, FTK Imager, dd, dcfldd, Guymager, Sleuth Kit, Autopsy, X-Ways Forensics | File yang dihapus (deleted inode) bisa ditimpa kapan saja. TRIM (SSD) bikin recovery hampir mustahil |
| **Level 5** — Persistent Storage (Archived / Cold) | Selama media disimpan | **Sangat Rendah** — stabil bertahun-tahun | Backup tapes, optical media (CD/DVD/BR), cold HDD/SSD, offline NAS/SAN, storage array, tape library | Hardware imaging tools (Tableau, DeepSpar, PC-3000, Atola), ddrescue, FTK Imager, EnCase | Bit rot (media murah), magnetic decay (tape), NAND wear (SSD), controller failure (flash) |
| **☠️ Level 6** — Cloud & Remote Storage | Selama cloud provider menyimpan | **Tergantung provider** — dari hitungan jam (ephemeral) sampai tahun (archived S3) | Cloud VM snapshots, cloud storage (S3/Blob/GCS), SaaS data (Google Workspace, Office 365, Salesforce), container layer images | AWS forensic tools, Azure CLI, Google Takeout, Magnet AXIOM Cloud, CloudSweep (CrowdStrike), Rubrik, Veeam | Provider policy hapus data. Encryption (E2EE) bikin data tidak terbaca. Legal jurisdiction issues |

---

## Peta Visual — Volatilitas vs Data Richness

```
Data Richness ↑
              │  L6 ─ Cloud & Remote Storage             ●    ●●● Sangat stabil, akses terbatas
              │  L5 ─ Archived Cold Storage              ● ●    ●●● Paling stabil
              │  L4 ─ Active Persistent Storage          ●●●    ●● Standard forensik
              │  L3 ─ Temporary & Transient Files        ●●●●    ●● Artefak kunci
              │  L2 ─ Running Processes / OS State       ●●●●●   ● Hidup singkat
              │  L1 ─ Network Connections                ●●●●●●  ● Hilang saat disconnect
              │  L0 ─ RAM / Volatile Memory              ●●●●●●● ● Paling kaya, paling rapuh
              │       └────────────────────────────────────────→ Waktu Bertahan
              │
              └──────────────────────────────────→ Urutan Akuisisi (0 → 6)
```

---

## Kenapa Hirarki Ini Penting

### 1. Order of Volatility (OoV) — Golden Rule Forensik

Dalam investigasi forensik, **akuisisi harus dimulai dari data paling volatil**. Urutannya:

```
RAM (L0) → Network State (L1) → Running Processes (L2) → Transient Files (L3)
→ Persistent Storage (L4) → Archived (L5) → Cloud (L6)
```

**Kenapa?** Jika Anda matikan laptop dulu baru ambil RAM — RAM-nya sudah hilang. Jika Anda cabut kabel network sebelum catat koneksi aktif — connection state-nya hilang. **Setiap device yang akan di-forensik harus langsung difoto, dicatat statusnya, lalu di-dump RAM-nya SEBELUM dimatikan.**

### 2. Setiap Level Punya "Tembok" Berbeda

| Level | Tembok Terbesar | Contoh Real |
|-------|-----------------|-------------|
| L0 (RAM) | Anti-forensics di kernel — rootkit sembunyikan proses | Kernel mode rootkit: `ps` tidak tampilkan process berbahaya karena hook syscall. LiMEdump bisa detect module tersembunyi |
| L1 (Network) | Encrypted traffic — tidak bisa inspeksi isi | TLS 1.3 + ECH (Encrypted Client Hello) — metadata koneksi pun terenkripsi |
| L2 (Process) | Malware dengan self-delete / timer kill | Process running hanya 5 detik, log process pun hilang |
| L3 (Temp) | SSD TRIM — overwrite data dalam detik | SSD TRIM command mengosongkan block yang dihapus dalam <1 detik — recovery file hampir mustahil |
| L4 (Storage) | Encryption at rest (BitLocker, FileVault, LUKS) | Tanpa kunci atau recovery key, data terenkripsi tidak terbaca. Cold boot attack (RAM beku) bisa ambil kunci |
| L5 (Archived) | Bit rot, media degradation, obsolete hardware | Tape drive LTO-5 tidak bisa baca LTO-9. HDD yang disimpan 5+ tahun punya failure rate 12%+ |
| L6 (Cloud) | Jurisdiction, legal, encryption, provider cooperation gap | Data di server Singapura, perusahaan AS, user Indonesia — butuh MLAT yang bisa 6 bulan |

### 3. Forensic Competition Biasanya Fokus di Level 2–5

Mayoritas soal CTF forensic:
- **L2 (Process)** — dump process, cari process anomali, extract string dari memory process
- **L3 (Transient)** — browser history analysis, prefetch extraction, jump list parsing
- **L4 (Storage)** — NTFS $MFT analysis, file carving dari unallocated space, VSC (Volume Shadow Copy) extraction

**Level 0 (RAM) dan Level 1 (Network)** jarang keluar di CTF karena tooling-nya complex dan memori dump file bisa 16 GB+. Tapi di investigasi real, itu yang paling penting.

---

## Kontrak Kompetensi Per Level

### Level 0 — Volatile Memory (RAM)
**Harus bisa:**
- Dump RAM dengan LiME (Linux), WinPmem (Windows)
- Ekstrak proses, network socket, cmdline, environment variable dari memory dump
- Analisis dengan Volatility 3: `windows.psscan`, `windows.cmdline`, `windows.netscan`, `windows.malfind`
- Deteksi rootkit / hidden process via `windows.modscan`, `windows.driverirp`
- Cari malware di memory injection region

**TIDAK relevan:** Filesystem analysis, timeline creation, network long-term capture

### Level 1 — Network State
**Harus bisa:**
- Capture live traffic dengan tcpdump/Wireshark
- Analisis PCAP: follow TCP stream, ekstrak file dari HTTP/SMB/DNS, identifikasi C2 beacon
- Filter traffic berdasarkan IP, port, protocol, time range
- Deteksi DNS tunneling, exfiltration via DNS, slowloris, C2 heartbeat

### Level 2 — Running Processes & OS State
**Harus bisa:**
- Identifikasi process legitimate vs malicious
- Cari process yang tidak punya parent (orphan), PPID spoofing, process hollowing
- Baca environment variable yang mengandung credential
- Analisis autoruns, scheduled tasks, services, drivers

### Level 3 — Temporary & Transient Files
**Harus bisa:**
- Ekstrak browser history, cache, cookies, saved passwords (Chrome, Firefox, Edge)
- Baca prefetch file (.pf) — tahu executable apa yang pernah jalan, kapan, berapa kali
- Parse $Recycle.Bin / .Trash — file apa yang dihapus, kapan, dari mana
- Jump list parser — dokumen apa yang baru dibuka
- Thumbnail cache — rekonstruksi gambar yang sudah dihapus
- Volume Shadow Copy (VSC) — restore file ke versi sebelumnya

### Level 4 — Active Persistent Storage
**Harus bisa:**
- Buat forensic image (dd, dcfldd, Guymager, FTK Imager)
- Analisis filesystem: MFT entry, inode table, allocation bitmap, journal ($LogFile, $UsnJrnl)
- File carving: recover deleted file berdasarkan signature (foremost, scalpel, photorec)
- Timeline analysis: buat super timeline dengan plaso/log2timeline
- Registry analysis: extract user activity, USB device history, MRU, network shares
- Slack space, unallocated space, indirect block analysis

### Level 5 — Archived & Cold Storage
**Harus bisa:**
- Read media yang rusak/fail (PC-3000, DeepSpar, ddrescue)
- Reconstruct RAID (mdadm, hardware RAID controller)
- Extract data dari tape backup (tar, Amanda, Bacula)
- File system reconstruction setelah format ulang

### Level 6 — Cloud & Remote Storage
**Harus bisa:**
- Know legal framework untuk cloud data request (CFAA, GDPR, UU ITE, MLAT)
- API-based collection (AWS S3 inventory, Office 365 eDiscovery, GSuite Vault)
- Container forensic (Docker layer analysis, Kubernetes audit log)
- SaaS data extraction (Slack export, Teams retention, Salesforce audit)
- Preserve metadata: timestamps, version history, ACL, shared-with info

---

## Forensic Artifact Map — Windows vs Linux

### Windows
| Artifact | Source | Level | Information Extracted |
|----------|--------|:-----:|----------------------|
| Prefetch | C:\Windows\Prefetch\*.pf | L3 | File jalan, path, count, last run time |
| $UsnJrnl | $MFT USN journal | L4 | Semua perubahan file (create/modify/delete/rename) dengan timestamp |
| $LogFile | NTFS metadata log | L4 | Detail perubahan filesystem — bisa detect file timestamp manipulation |
| Event Log | .evtx files | L3 | Proses jalan, login/logoff, service start/stop, error |
| Registry (SAM) | Config\SAM | L4 | User accounts, last login, password hash |
| Registry (NTUSER.DAT) | User profile | L3 | MRU, typed URLs, recent docs, USB device history, network shares |
| Amcache | C:\Windows\AppCompat\Programs\Amcache.hve | L3 | Application execution history bahkan setelah uninstall |
| ShimCache | Registry AppCompatCache | L3 | Executable path + timestamp (pertahanan terhadap anti-forensics timestamp modification) |
| $Recycle.Bin | Per-user recycle bin | L3 | File dihapus, original path, deletion time |
| Volume Shadow Copy | System Volume Information | L3 | File versi sebelumnya — bisa bypass ransomware encryption |
| Browser Artifacts | User profile | L3 | History, cache, cookies, downloads, saved passwords |
| Jump Lists | User profile | L3 | Recent documents per application |
| LNK Files | User profile | L3 | File access timestamp, target path, volume serial |

### Linux
| Artifact | Source | Level | Information Extracted |
|----------|--------|:-----:|----------------------|
| .bash_history | User home | L3 | Command history — reconstruct attacker activity |
| auth.log / secure | /var/log/ | L3 | SSH login attempts, sudo usage, user switches |
| syslog / journalctl | /var/log/ | L3 | System-wide events, service logs, kernel messages |
| wtmp / btmp | /var/log/ | L3 | All login/logout records (including failed) |
| .ssh (keys, known_hosts) | User home | L3 | Remote connections, authorized keys, host fingerprints |
| /tmp + /var/tmp | Filesystem | L3 | Artifact sementara, session file, dropped tools |
| auditd logs | /var/log/audit/ | L3 | System call audit trail — paling detail |
| $MFT (if NTFS) | Mounted drive | L4 | Filesystem transactions |
| /proc/* | RAM-based pseudofilesystem | L0–2 | Process info, network, modules (hilang saat shutdown) |
| ~/.local/share/Trash | User trash | L3 | Deleted files metadata |
| Chromium/Firefox profiles | User home | L3 | Browser history, cache, cookies |
| Docker/container layers | /var/lib/docker/ | L6 | Container image history, running containers |

---

## Plot Twists

> [!danger] Plot Twist 1: SSD TRIM Membunuh File Carving
> File carving (foremost, scalpel, photorec) hanya bekerja kalau data belum ditimpa. **SSD TRIM** mengosongkan block yang dihapus dalam <1 detik — bahkan sebelum Anda sempat buka forensic imager. **Cara satu-satunya:** non-TRIM forensic image diambil dengan alat hardware write-blocker + firmware-aware imaging (PC-3000 SSD, Atola). Jika SSD sudah di-boot tanpa write-blocker, file yang dihapus **tidak bisa direcover**.

> [!tip] Plot Twist 2: Anti-Forensics Semakin Canggih
> Tools anti-forensics modern bukan sekadar "delete file" — mereka:
> - **$MFT manipulation** — overwrite entry untuk sembunyikan file
> - **Timestamp modification** — setfile / SetMACE bikin timeline forensik kacau
> - **Log wiping** — clear event log, audit log, .bash_history
> - **Secure deletion** — wipe file + overwrite unallocated space 7x (DoD 5220.22-M)
> - **Volume Shadow Copy deletion** — `vssadmin delete shadows /all`
> - **Encryption** — BitLocker, VeraCrypt, FileVault — tanpa kunci, data tidak terbaca
>
> Counter-forensics: `$LogFile` dan `$UsnJrnl` tetap bisa menunjukkan manipulasi — karena USN journal mencatat setiap perubahan termasuk perubahan timestamp. **Forensik bukan melawan data — melawan jejak yang ditinggalkan.**

> [!info] Plot Twist 3: RAM Dump Bisa Ambil Kunci Enkripsi — Tapi Harus Cepat
> Full Disk Encryption (BitLocker, FileVault, LUKS) bikin disk tidak terbaca tanpa kunci. **Tapi jika device sedang ON**, kunci enkripsi ada di RAM. LiME dump + Volatility `windows.lsadump` atau `mac.keychaindump` bisa extract:
> - BitLocker key (pre-boot AES key)
> - LUKS master key
> - FileVault volume key
> - TrueCrypt/VeraCrypt passphrase dari memory
>
> **Cold boot attack:** Dinginkan RAM dengan compressed air → RAM data bertahan 5–10 menit setelah power off → boot dari USB → dump RAM → extract key. Ini teknik forensik tingkat lanjut yang butuh persiapan fisik.

> [!warning] Plot Twist 4: Chain of Custody Sama Pentingnya dengan Data Itu Sendiri
> Tanpa chain of custody yang solid, data forensik **tidak bisa dijadikan bukti hukum** — bahkan kalau teknik akuisisinya sempurna. Chain of custody minimal butuh:
> - **Foto/Video kondisi device** saat tiba di laboratorium
> - **Hash (SHA-256/MD5)** setiap langkah — image asli, image copy, hasil ekstraksi
> - **Log waktu dan personel** — siapa memegang bukti, kapan, untuk apa
> - **Write-blocker** — pastikan device tidak termodifikasi saat akuisisi
> - **Media baru steril** — dd if=/dev/zero sebelum dipakai
>
> Di CTF, chain of custody jarang dinilai. Di investigasi real, **tanpa chain of custody = tidak ada bukti.**

---

## Cross-Link ke Atlas Lainnya

- **SOP Akuisisi Lengkap** → [[forensic-imaging-analysis]]
- **Memory Forensics Deep Dive** → [[memory-forensics-volatility-deepdive]]
- **Mobile Forensics** → [[mobile-forensics]]
- **Data Recovery & File Carving** → [[data-recovery]]
- **IR Framework (OoV Integration)** → [[incident-response-framework]]
- **Cyber Law & Digital Evidence** → [[cyber-law-digital-evidence]]
- **Anti-Forensics Detection** → [[kernel-forensics]]
- **Master Index** → [[master-index]]

---

*Digital Evidence & Acquisition Hierarchy | Level 0 (RAM) → Level 6 (Cloud) · Order of Volatility (OoV) · Chain of Custody = Prasyarat Hukum · SSD TRIM = Musuh File Carving*