---
title: "Hierarchy Reverse Engineering"
tags:
  - atlas
  - reverse-engineering
  - binary
  - firmware
  - malware
aliases:
  - "hierarchy-reverse-engineering"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
---

# 🔧 HIERARKI REVERSE ENGINEERING — Dari String & Metadata (Level 0) sampai Deobfuscation VM (Level 7)

> Reverse engineering adalah **membedah logika tanpa dokumentasi**. Hirarki ini memetakan perjalanan dari membaca string mentah (Level 0) sampai membalikkan bytecode VM protector (Level 7). Setiap level menambah depth — dan biaya waktu. Mulai dari yang paling murah; berhenti ketika cukup untuk menjawab pertanyaan. Untuk playbook teknis lengkap (alat per level + command), lihat [[hardware-hacking-re|Sheet 1 — RE Software & Firmware]].

> [!info] Cara Baca
> Level 0 = sebelum analisis (recon). Level 7 = paling advanced (deobfuscator custom VM). Untuk incident response, Level 0–2 biasanya cukup. Level 4+ untuk bug bounty, malware zero-day, APT research.

---

## Tabel Utama — Level 0 sampai Level 7

| 🔧 Level | 🧠 Pendekatan | ⚡ Alat & Teknik | ☠️ Tembok Kematian | 🎯 Kapan Digunakan |
|---|---|---|---|---|
| **Level 0** — String & Metadata Recon | `strings`, `file`, `binwalk`, `ExifTool`, Detect It Easy, TrID | Ekstrak semua teks readable: URL, API key, path hardcoded. Identifikasi format file. Carve firmware image otomatis. Identifikasi packer/compiler | Obfuscation sederhana (XOR string encode) sudah cukup menyembunyikan strings. Binwalk gagal pada firmware terenkripsi penuh | Triage cepat, ekstrak credentials, identifikasi library |
| **Level 1** — Disassembly Statis | Ghidra, IDA Free/Pro, Cutter/Rizin, `objdump`, `readelf` | Machine code → assembly → pseudo-C decompile. Analisis CFG, cross-reference, identifikasi crypto dari pola instruksi. Ghidra (NSA, gratis) setara IDA Pro | Stripped binary = semua fungsi `FUN_00401234`. Butuh jam renaming manual. Obfuscated control flow menyesatkan decompiler | Analisis malware, audit library third-party, cari hardcoded credential |
| **Level 2** — Dynamic Analysis | x64dbg, OllyDbg, GDB+PEDA, Frida, Process Monitor, strace | Jalankan program di debugger — pause, inspect memori, ubah register, bypass kondisi. Frida: inject JavaScript ke proses manapun. ProcMon: rekam semua syscall | Anti-debug: `IsDebuggerPresent`, timing check, exception-based detection. Sandbox evasion: VM detection, sleep sampai keluar | Bypass proteksi, analisis malware behavior, hooking mobile app API |
| **Level 3** — Firmware RE | Binwalk, Firmwalker, FACT, Ghidra + SVD-Loader, OpenOCD | Ekstrak firmware via UART/JTAG/flash dump. FACT: analysis otomatis credential/versi. SVD-Loader: load register definition MCU ARM | Firmware terenkripsi dengan kunci di secure element = butuh hardware attack. Custom RTOS tanpa dokumentasi = susah orientasi | Router, kamera IP, IoT device audit, medical device |
| **Level 4** — Protocol RE | Wireshark + Lua dissector, Scapy, Proxmark3, Universal Radio Hacker (URH) | RE protokol proprietary dari traffic capture. Build Wireshark dissector custom. Proxmark3: RE RFID/NFC. URH: RE RF signal dari SDR | E2E encryption + cert pinning. Rolling code (remote mobil) berubah tiap penggunaan. Protokol tidak terdokumentasi | Akses kontrol, protokol industri (Modbus, DNP3), smart card research |
| **Level 5** — Symbolic Execution & Fuzzing | angr, KLEE, AFL++, LibFuzzer, Triton | Symbolic execution = input simbolik → matematika, generate input capai tiap branch. AFL++: coverage-guided fuzzing — mutasi otomatis, pantau coverage, crash = potensi vuln | Path explosion pada program besar. Fuzzing butuh jam–minggu untuk crash di target kompleks | Vulnerability research, CTF, bug bounty, audit library kripto |
| **Level 6** — Binary Exploitation | pwntools, ROPgadget, pwndbg, heap exploitation, kernel exploit | Dari crash → controlled code execution. ROP: chain gadget bypass NX/DEP. Kernel exploit: dari user space ke Ring 0. Heap feng shui: kontrol alokasi memory | ASLR + PIE + Stack Canary + Full RELRO + seccomp = exploitasi sangat sulit. Kernel mitigasi modern (SMEP, SMAP, CET) | CVE research, pwn CTF, jailbreak iOS/Android, privilege escalation |
| **☠️ Level 7** — Compiler & VM Internals | LLVM IR analysis, JVM/Dalvik bytecode, WebAssembly RE, VMProtect deobfuscation | RE pada intermediate representation. LLVM IR: compiler-introduced vulnerability. Dalvik: Android app. WASM: browser DRM/anti-cheat. **VM deobfuscation**: balikkan bytecode custom VM (VMProtect, Themida) — satu fungsi bisa jadi ribuan instruksi | VM protector = satu fungsi jadi ribuan instruksi custom ISA — butuh minggu untuk satu fungsi kritis. Data flow analysis rumit | DRM bypass, advanced malware, anti-cheat RE, APT tool analysis |

---

## Peta Visual — Effort vs Depth

```
      ↑ Kedalaman pemahaman
      │
 L7 ──┼─────────────────────────● Deobfuscation VM / LLVM IR
      │                          (minggu)
 L6 ──┼───────────────────● Binary exploitation
      │                    (hari-minggu)
 L5 ──┼────────────● Symbolic execution / fuzzing
      │             (hari)
 L4 ──┼──────● Protocol RE
      │       (jam-hari)
 L3 ──┼──● Firmware RE
      │    (jam)
 L2 ──┼──● Dynamic analysis (Debugger/Frida)
      │    (30-60 menit)
 L1 ──┼──● Static disassembly
      │    (15-30 menit)
 L0 ──┼──● String recon
      │    (5-10 menit)
      └─────────────────────────→ Waktu & effort
```

> [!warning] RE Bukan Linier — Bolak-Balik Level
> Praktisi RE jarang lurus L0→L7. Mereka bolak-balik: L1 static → L2 dynamic cek behavior → balik L1 untuk konfirmasi → L4 protocol RE → L1 lagi. Hirarki ini adalah menu, bukan resep. Pilih level yang menjawab pertanyaan paling murah.

---

## Kenapa Hirarki Ini Penting

### 1. RE Adalah Dialog Dengan Binary

Setiap level seperti bertanya: 
- L0: "Siapa kamu?" (strings, metadata)
- L1: "Apa yang bisa kamu lakukan?" (disassembly)
- L2: "Apa yang kamu lakukan saat jalan?" (dynamic)
- L5: "Apa yang terjadi kalau aku kasih input ini?" (fuzzing)
- L6: "Bisakah aku mengontrolmu?" (exploitation)

Binary "menjawab" hanya kalau teknik yang tepat digunakan. Hirarki membantu kita memilih pertanyaan yang tepat berdasarkan apa yang sudah kita tahu.

### 2. Anti-Analysis = Harga Yang Harus Dibayar

Semakin tinggi level RE, semakin banyak anti-analysis yang ditemui — karena developer binary sadar bahwa binary mereka akan di-RE. Tiap level punya anti-analysis spesifik:
- Level 0 → XOR string, encrypted sections
- Level 1 → Obfuscated control flow (O-LLVM)
- Level 2 → Anti-debug, anti-VM, timing checks
- Level 4 → Certificate pinning, custom encryption
- Level 7 → VM-based obfuscation

Mendeteksi anti-analysis di level bawah sudah merupakan intelijen: semakin kuat anti-analysis, semakin sensitif binary itu.

### 3. Output RE = Input untuk Level Lain

Hasil RE di satu level jadi input level berikutnya:
- L0 strings → L1 cari cross-reference string itu
- L1 rename fungsi → L2 set breakpoint lebih mudah
- L2 dynamic dump → L3 firmware RE dapat konteks runtime
- L4 protocol spec → L5 fuzzer tahu format message
- L6 exploit → validasi bahwa analysis L5 benar (RCE)

**Validasi silang antar level** adalah cara terkuat untuk memastikan RE benar.

---

## Plot Twists

> [!danger] Plot Twist 1: AI Mengubah RE — Tapi Tidak Sepenuhnya
> 2024–2026: LLM binary decompilation (Ghidra + LLM plugin, IDA + GPT) bisa generate pseudo-code yang lebih readable. Tapi untuk:
> - Obfuscated code (control flow flattening) → LLM sering hallucinate
> - Binary with anti-analysis → LLM ikut bingung
> - Protocol RE → LLM bisa bantu baca hex dump tapi tidak gantikan pattern recognition manusia
> **AI = tools, bukan replacement**. Level 7 masih butuh manusia karena butuh reasoning tentang intent.

> [!tip] Plot Twist 2: Frida (L2) Adalah Game Changer Terbesar 2010-an
> Frida: dynamic instrumentation tanpa perlu reverse engineer dulu. Inject JavaScript ke proses berjalan — trace function calls, bypass SSL pinning, dump memory, hook API. Untuk mobile app RE, Frida mengurangi waktu Week 0 → L2 menjadi **30 menit**. Bandingkan dengan IDA Pro Week 0 → L4 yang butuh hari.

> [!tip] Plot Twist 3: Ghidra Gratis Setara IDA Pro Untuk 90% Kasus
> IDA Pro: USD 2,589 (Pro) — standar industri dekade. Ghidra (NSA, 2019): gratis, open source, decompiler setara. Untuk 90% kasus (malware, firmware, IoT RE), Ghidra cukup. IDA unggul di: plugin ecosystem, debugging, dan binary diffing untuk patch analysis. **Mulai dengan Ghidra — upgrade ke IDA hanya kalau butuh**.

> [!info] Plot Twist 4: Hardware RE (Sheet 2) Adalah RE Level Paling Dalam
> [[hardware-hacking-re|Sheet 2 — Hardware Hacking]]: dari visual inspect (L0) sampai decap + FIB (L7). Sesuatu yang tidak bisa di-RE di software (firmware terenkripsi, secure element locked) harus di-RE di hardware. Kedua disiplin RE dan HW hacking **saling melengkapi**: satu tutup celah yang lain.

> [!warning] Plot Twist 5: Waktu RE Paling Sering Dihabiskan Untuk Renaming
> Stripped binary: Ghidra/IDA generate nama fungsi `FUN_00401234`. 60% waktu RE dihabiskan untuk: rename fungsi berdasarkan konteks + tipe data parameter + struktur. Tools automatic rename (FLIRT, F.L.I.R.T., Lumina) membantu tapi tetap butuh validasi manual. **Renaming adalah investasi**: semakin baik nama, semakin cepat sisa RE.

---

## Perbandingan Level per Use Case

| Profil | Level Minimum | Saran Fokus |
|---|---|---|
| **Malware analyst** | L0–L2 | Ghidra + Frida + sandbox |
| **Bug bounty hunter** | L1, L5–L6 | Ghidra + AFL++ + pwntools |
| **IoT security researcher** | L0–L4 | Binwalk + Ghidra + URH + JTAGulator |
| **Mobile app security** | L1–L2 + Frida | jadx + Frida + objection |
| **DRM/anti-cheat RE** | L7 | VMProtect deobfuscation + LLVM IR |
| **CTF player** | L1–L6 | Ghidra + pwntools + angr + GDB |

---

## Sumber & Telusur Lebih Lanjut

- **Sheet 1 (RE Lengkap)** → [[hardware-hacking-re]] (Level 0–7 tabel + alat per level)
- **Sheet 2 (Hardware Hacking)** → [[hardware-hacking-re]] (Level 0–7 fisik — visual inspect sampai decap)
- **Firmware RE Deepdive** → [[firmware-reverse-engineering-deepdive]] (782 baris — firmware extraction, UART, JTAG, QEMU)
- **Malware Analysis** → [[malware-analysis-reverse-engineering-playbook]] (RE untuk endpoint detection)
- **Web Exploit Level Analog** → [[hierarchy-offensive]] (Level privilege escalation)
- **Side-Channel & Hardware Attack** → (akan ada: `hierarchy-side-channel.md`)
- **Master Index** → [[master-index]]

---

> RE adalah **satu-satunya skill di security yang membuat binary bicara**. Tanpa RE, lo cuma lihat behaviour dari luar. Dengan RE, lo baca pikirannya. Semakin tinggi level, semakin banyak yang binary itu ceritakan — tapi semakin lo bayar dengan waktu dan fokus.

*Reverse Engineering Hierarchy | Level 0 (String Recon) → Level 7 (VM Deobfuscation) · Membuat Binary Bicara*
