---
title: Untrusted Artifact Analysis
tags: [security, malware, forensics]
aliases: [untrusted-artifact-analysis]
---
# Untrusted Artifact Analysis

Artifact tidak tepercaya (file dari internet, email lampiran, USB asing) harus diperlakukan sebagai potensi malware hingga terbukti aman.

## Prinsip Dasar

1. **Never trust extension — trust content**: `report.pdf.exe` bukan PDF; magic bytes adalah kebenaran.
2. **Isolasi**: analisis di lingkungan terisolasi (VM tanpa network, snapshot).
3. **Document everything**: hash, timestamps, observasi — bukti untuk forensik.
4. **Least privilege**: tools jalan sebagai user non-root di VM.

## Alur Triage

### Langkah 1: Identifikasi & Hash
```bash
sha256sum artifact.bin
file artifact.bin
xxd artifact.bin | head -10
exiftool artifact.bin   # metadata (Office, PDF)
binwalk artifact.bin    # embedded files
```

### Langkah 2: Reputation Check
- VirusTotal (hash + behavior), MalwareBazaar, Hybrid Analysis.
- YARA scan lokal (rules dari malware research community).
- Cek signature digital (Windows): `sigcheck -a` (Sysinternals).

### Langkah 3: Static Inspection
- Office docs: `olevba` (VBA macro), `oleid` (malicious indicators), `msoffcrypto-tool`.
- PDF: `pdfid`, `pdf-parser` (JavaScript? /OpenAction?).
- Scripts (JS/VBS/PS1): baca manual — cari decode, download cradle, obfuscation.
- Archives: `unzip -l` dulu, ekstrak ke folder terisolasi, scan tiap isi.

### Langkah 4: Controlled Execution (Detonation)
- Sandbox: CAPE/Cuckoo atau manual VM snapshot.
- Tools: ProcMon (file/registry/network), Wireshark, INetSim.
- Jangan eksekusi di mesin produksi/dev — hanya di lab.

### Langkah 5: IOC Extraction
- Hash, C2 (IP/domain dari strings + network capture), mutex, file created, registry persistence.
- YARA rule untuk deteksi masa depan; Sigma rule untuk SIEM.

## Automatisasi

Python + tools:
```python
# Triage pipeline sederhana
import hashlib, subprocess
h = hashlib.sha256(open('artifact','rb').read()).hexdigest()
print(subprocess.run(['file','artifact'],capture_output=True,text=True).stdout)
# lanjut: yara -r rules.yar artifact; olevba artifact
```
Tools siap pakai: **pestudio** (Windows PE), **Detect It Easy**, **Capa** (FLARE — deteksi capability malware), **Speakeasy** (emulasi).

## Kasus Khas: Lampiran Email

1. Email berisi `Invoice_2026.pdf` (11KB, ekstensi PDF).
2. `file` → "Composite Document File V2" (OLE, bukan PDF).
3. `oleid` → macro enabled, autoexec indicators.
4. `olevba` → VBA download cradle dari `hxxp://evil/payload.ps1`.
5. Sandbox detonasi → PowerShell dropper → C2 `evil.com:8443`.
6. IOC: hash, C2, mutex → feed SIEM/YARA. Verdict: phishing dengan malware dropper.

## Safety Checklist

- [ ] Hash & dokumentasi sebelum apapun.
- [ ] VM terisolasi + snapshot.
- [ ] Network simulation (INetSim) bukan koneksi nyata.
- [ ] Tools non-root.
- [ ] Sample disimpan terenkripsi setelah analisis.
- [ ] IOC dibagikan (TLP) ke tim intel.

## Koneksi ke Vault

- [[malware-analysis-workflow]] — analisis mendalam setelah triage.
- [[threat-intel]] — IOC ke feed.
- 01_Library/Data_Forensics — lanjutan forensik.



## Alur Lengkap Otomasi Triage (Script Template)

```python
#!/usr/bin/env python3
# triage_artifact.py — triage pipeline cepat
import hashlib, subprocess, sys, pathlib

artifact = pathlib.Path(sys.argv[1])
h = hashlib.sha256(artifact.read_bytes()).hexdigest()
print(f"HASH  : {h}")
print(f"FILE  : {subprocess.run(['file', str(artifact)], capture_output=True, text=True).stdout.strip()}")
print(f"SIZE  : {artifact.stat().st_size} bytes")
# lanjut: vt_lookup.py, yara_scan.py, oleid.py
```
Run: `./triage_artifact.py sample.bin` → output ringkasan.

## Klasifikasi Verdict (Setelah Triage)

| Verdict | Arti | Action |
|---------|------|--------|
| Benign | Aman | Izinkan / dokumentasi |
| Suspicious | Mencurigakan tapi belum pasti | Sandboxing lanjut |
| Malicious | Malware terkonfirmasi | Isolasi, IOC ekstraksi, notifikasi |
| Unknown | Tidak cukup data | Sandboxing + deep analysis |

## Contoh Triage Lengkap (Step-by-Step)

1. File `invoice_2026_001.pdf` (15KB, ekstensi `.pdf`).
2. `sha256` → `e3b0...` (contoh).
3. `file` → "Composite Document File V2 Document" (OLE, bukan PDF).
4. `exiftool` → author, creation date (indicators: aneh).
5. `oleid` → makro `Yes`, autoexec `Yes`.
6. `olevba` → VBA `AutoOpen()` memanggil `Shell()` dengan URL `hxxp://evil/drop.vbs`.
7. Sandbox → `drop.vbs` download → PowerShell → C2 `evil.com:8443`.
8. Verdict: **Malicious** (phishing + malware dropper). IOC: hash, URL, C2, mutex. Notifikasi + block.

## Koneksi ke TI

Lihat [[threat-intel]] untuk integrasi IOC; [[malware-analysis-workflow]] untuk analisis mendalam. Template ini bagian dari SOP: semua artifact dari email/internet wajib triage sebelum dibuka oleh user.



## Analisis Khusus per Tipe File

### PDF Malicious
Indicators: `/OpenAction`, `/JavaScript`, `/Launch`, stream terkompresi aneh. Tools: `pdfid`, `pdf-parser`, `peepdf`. Contoh: `/OpenAction << /F (evil.exe) /S /Launch >>`.

### Office Macro
Tools: `olevba`, `oledump`, `msoffcrypto-tool`. Makro: `AutoOpen`, `Document_Open`, `Workbook_Open`. Periksa URL (`http://`), `Shell()`, `WScript.Shell`, `PowerShell`.

### Script (JS, VBS, PS1, HTA)
Obfuscation: base64, rot13, concatenation, eval. Tools: deobfuscate manual + `js-beautify`, `python3 -m py_compile`. Periksa network calls (`XMLHttpRequest`, `WScript.Shell`, `Invoke-WebRequest`).

### Executable / Binary
Lihat [[malware-analysis-workflow]] — disassembly, sandbox, memory forensics.

### Archive (ZIP, RAR, 7z)
Cek nested files: `.lnk` dalam ZIP (`directory traversal + symlink`), `.exe` dalam `.zip` yang di-rename `.doc`. Ekstraksi hanya setelah triage isi individual.

## Integrasi SIEM / Response

Jika verdict Malicious:
1. Isolasi host (network disconnect / firewall block).
2. IOC masuk ke SIEM/YARA feed.
3. Pencarian retroaktif: cari IOC sama di log 30 hari terakhir (SIEM query: `file.hash=<h>` atau `network.ip=<c2>`).
4. Notifikasi stakeholder (security, IT, manajemen) — TLP:AMBER.
5. Post-incident: review proses triage, apakah bisa lebih cepat?

## Link Referensi (Cross-Note)

- [[threat-intel]] — IOC feed.
- [[command-injection]] — payload injection dalam macro/script.
- 01_Library/Data_Forensics — lanjut forensik penuh.

---

  audited
---