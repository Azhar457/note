---
title: "Hierarchy Hardware Hacking"
tags:
  - atlas
  - hardware
  - embedded
  - JTAG
  - side-channel
  - firmware
aliases:
  - "hierarchy-hardware-hacking"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  - callout
---


# 🔩 HIERARKI HARDWARE HACKING — Dari Visual PCB (Level 0) sampai Silicon RE & FIB (Level 7)

> Software bisa di-patch, firmware bisa di-flash ulang — tapi hardware yang sudah dimodifikasi secara fisik **tidak bisa di-unpatch**. Hirarki hardware hacking memetakan serangan dari paling non-invasif (mata & multimeter) sampai paling destruktif (decap chip + FIB edit). Setiap level naik = biaya naik 10x lipat dan irreversible. Untuk tabel lengkap alat per level + sheet software RE companion, lihat [[hardware-hacking-re]].

> [!info] Cara Baca
> Level 0 = visual inspection (murah, non-destruktif). Level 7 = silicon RE (puluhan miliar, destruktif). Semakin tinggi level, semakin **tidak bisa diulang** — chip hancur setelah analisis. Mulai dari yang paling non-invasif, eskalasi hanya jika target punya proteksi di level sebelumnya.

---

## Tabel Utama — Level 0 sampai Level 7

| 🔩 Level | 🧠 Pendekatan | ⚡ Alat & Teknik | ☠️ Tembok Kematian | 🎯 Aplikasi Nyata |
|---|---|---|---|---|
| **Level 0** — Physical Recon | Multimeter, visual PCB inspection, **FCC ID lookup** (fccid.io — foto internal resmi dari sertifikasi FCC), magnifying glass | Buka casing, foto PCB, identifikasi chip marking. Cek continuity jalur, ukur voltase power rail. FCC ID lookup sering dapat foto internal sebelum lo buka sendiri | Chip marking sengaja dihapus. Komponen BGA tidak terlihat pin-nya tanpa X-ray | Identify target, cari UART/JTAG pad, reverse PCB layout awal |
| **Level 1** — UART / Serial Console | USB-to-UART adapter (CH340G/CP2102), logic analyzer, PuTTY, minicom, screen | **Lubang debug paling umum**: 3-4 pad (TX, RX, GND, VCC). Sambung → sering langsung **root shell**. Identifikasi baud rate via logic analyzer atau brute force (1200–115200) | Vendor disable UART di production build atau require password. Baiknya identifikasi dulu pad mana yang UART | Root akses router/kamera IP, dump boot log, akses recovery mode |
| **Level 2** — JTAG / SWD Debug | OpenOCD, JLink, CMSIS-DAP, UrJTAG, Black Magic Probe | **Interface debug industri**: pause execution, read/write memory, flash firmware, single-step. SWD: 2-pin lebih baru (ARM Cortex-M). OpenOCD: open-source controller | Banyak device **burn JTAG fuse** (disable permanen). Beberapa butuh autentikasi. Pad sering tidak di-label | Firmware dump, unlock bootloader, debug embedded, bypass secure boot |
| **Level 3** — Flash Chip Dump | Flashrom, CH341A programmer, SOIC clip, Bus Pirate | Dump langsung dari chip flash SPI/NOR tanpa lewat CPU. CH341A ~Rp 50rb. SOIC clip jepit tanpa desolder. Flashrom support ratusan chip | Flash BGA = harus desolder. Chip dengan internal encryption = dump terenkripsi | Backup firmware sebelum mod, bypass write protection, recover brick |
| **Level 4** — Side-Channel Attack | ChipWhisperer, oscilloscope, power analysis, EM probe, timing analysis | **Power Analysis**: monitor konsumsi daya CPU saat kripto → ekstrak kunci AES dari power trace. ChipWhisperer: platform open-source SCA. **EM Analysis**: probe antena kecil → baca emisi elektromagnetik. **Timing**: ukur waktu eksekusi untuk infer data | Butuh ribuan trace untuk DPA. Target dengan masking/jitter mitigation sangat resistan. Butuh statistik signal processing | Smart card attack, secure element research, IoT key extraction |
| **Level 5** — Fault Injection | Voltage glitching (ChipShouter), clock glitching, laser fault injection (laser diode microscope), EM fault injection | **Voltage glitch**: spike voltase sesaat → corrupt instruksi — skip security check. **Clock glitch**: pulsa clock ekstra → execute instruksi ganda. **Laser FI**: tembak laser presisi ke die → flip bit di SRAM/register | FI mahal (laser FI puluhan juta). Modern chip punya voltage/frequency detector → zeroize jika anomali. Timing presisi nanosecond | Bypass secure boot, extract key dari HSM/TPM, jailbreak console, bypass PIN limit |
| **Level 6** — PCB & Circuit RE | X-ray PCB, dye-and-pry, layer delamination, KiCad RE | **X-ray**: lihat layer PCB multi-layer non-destruktif. **Dye-and-pry**: celup PCB pewarna, cungkil BGA → lihat ball pattern. **Delamination**: kupas layer PCB satu per satu untuk trace semua jalur | X-ray butuh mesin industri. Delamination destruktif — tidak bisa diulang. Butuh skill PCB layout | RE produk kompetitor, security audit hardware proprietary, reverse supply chain |
| **☠️ Level 7** — Silicon RE | Decap kimia (asam nitrat/sulfat), SEM imaging, FIB circuit edit, netlist reconstruction | Larutkan epoxy packaging → ekspos die. SEM: foto seluruh permukaan die per layer. **FIB**: potong & deposit logam di level atom — edit circuit fisik. Rekonstruksi netlist dari foto SEM → schematic chip full | Biaya per chip: Rp 50 juta–Rp 5 miliar. Destruktif total. Butuh lab cleanroom + operator expert | Military chip RE (DARPA TRUST), clone detection, backdoor search di chip kripto |

---

## Peta Visual — Biaya vs Invasiveness

```
            ↑ Biaya (log scale)
            ↑ Invasiveness (permanen)
            ↑
  L7 ───────┼──────────── Silicon RE (FIB, SEM, decap)
            │             ~Rp 50 jt – 5 M
  L6 ───────┼───────── PCB RE (X-ray, delam)
            │          ~Rp 5 jt – 500 jt
  L5 ───────┼────── Fault Injection (laser, glitch)
            │       ~Rp 500 rb – 500 jt
  L4 ───────┼─── Side-Channel (oscilloscope, CW)
            │    ~Rp 2 jt – 100 jt
  L3 ───────┼─ Flash dump (CH341A, SOIC clip)
            │  ~Rp 50 rb – 5 jt
  L2 ───────┼ JTAG/SWD (JLink, OpenOCD)
            │  ~Rp 100 rb – 30 jt
  L1 ───────┼ UART (USB-UART adapter)
            │  ~Rp 15 rb – 200 rb
  L0 ───────┼ Visual / Multimeter
            │  ~Rp 0 – 500 rb
            └─────────────────────────→ Skill requirement
```

> [!warning] Level 4+ Tidak Reversible
> Setiap level dari 4 ke atas kemungkinan besar **merusak target secara permanen**: decap menghancurkan packaging, FIB memotong jalur logam, fault injection bisa brick chip permanent. Bedakan antara "research di target sekali pakai" vs "analisis forensik chain of custody." Untuk forensik, berhenti di Level 3 dan gunakan clone/replacement sebanyak mungkin.

---

## Kenapa Hirarki Ini Penting

### 1. Hardware Attack Lebih Mahal Dari Software Attack — Tapi Lebih Powerful

Software exploit butuh skill dan mungkin koneksi jaringan. Hardware exploit butuh: alat (CH340 ~Rp 15rb), akses fisik (atau supply chain), waktu (buka casing, solder, probe). Tapi:

| Serangan Software | Serangan Hardware Sebanding |
|---|---|
| Remote code execution | UART root shell (L1) |
| Debugger bypass | JTAG debug (L2) |
| Memory dump | Flash dump (L3) |
| Key extraction via Meltdown/Spectre | Side-channel power analysis (L4) |
| Kernel exploit | Fault injection bypass secure boot (L5) |

Hardware attack tidak butuh bug di OS — dia menyerang **fisika** chip, bukan abstraksi software.

### 2. UART (L1) Adalah "Pintu Belakang" Paling Umum

Produsen embedded device sering tinggalkan UART di production board untuk debugging internal — tapi lupa nonaktifkan di firmware release. Hasilnya: **root shell via 3 kabel + USB adapter Rp 15rb**. Ini adalah attack vector paling underrated di IoT security. Banyak CVE berawal dari "UART enabled on production device" → root access → dump firmware → find more vuln.

### 3. JTAG Fuse (L2) = Game of Trust

Produsen yang serius soal security **burn JTAG fuse** di production: fuse fisik di chip yang memutus koneksi JTAG secara permanen. Tapi:
- Kalau fuse tidak di-burn = JTAG terbuka lebar
- Kalau di-burn dan ada bug di firmware → **tidak bisa debug** (chip brick forever)
- Harga keamanan vs serviceability trade-off

Cara mengecek JTAG fusing: coba konek via JLink/OpenOCD. Kalau bisa detect target → JTAG terbuka. Kalau tidak → mungkin fused (atau pin tidak terhubung).

### 4. Supply Chain Attack Paling Powerful Ada di Hardware Level

Menginfeksi supply chain di Level 6–7:
- **Level 6**: Re-create PCB layout kompetitor + inject malicious chip
- **Level 7**: FIB edit die di fabrikasi → hardware backdoor di transistor level (dideteksi Snowden docs: NSA menanam implant di hardware Cisco sebelum sampai customer)
- **Level 3**: Infect SPI flash sebelum device sampai ke pengguna (BMC bom)

Hardware supply chain attack **tidak bisa dideteksi software** — satu-satunya deteksi adalah physical inspection atau trusted foundry.

---

## Plot Twists

> [!danger] Plot Twist 1: CH341A (Rp 50rb) Bisa Dump Firmware Router Rp 5 Juta
> Alat paling murah di hierarki (CH341A + SOIC clip) bisa memflash/dump SPI flash chip pada 99% router konsumen. Satu clamp ke flash chip → `flashrom -r backup.bin` → dapat full firmware. Produsen yang tidak proteksi flash read-back = full attack surface terbuka. Ini mengapa **flash write protection** adalah mitigasi hardware penting — tapi banyak vendor skip.

> [!danger] Plot Twist 2: Voltage Glitching Bisa Bypass Secure Boot Tanpa Exploit
> Secure Boot: verifikasi signature firmware sebelum eksekusi. Voltage glitching: di tengah verifikasi signature, inject voltage drop sesaat → CPU lompat instruksi → signature check terlewat → firmware unsigned dieksekusi. Tidak perlu bug di bootloader — **serang hardware, bukan software**. Modern ARM Trusted Firmware punya countermeasure (voltage monitor) — tapi banyak chip murah tidak.

> [!tip] Plot Twist 3: Decapping Chip = Membaca "Pikiran" Silicon
> SEM imaging of decapped die = lihat layout fisik transistor. Dari foto SEM, peneliti bisa identifikasi: modul AES (look for S-box pattern), CPU core, cache, memory controller. FIB bisa memotong jalur data di antara modul — misal potong jalur AES output sebelum XOR dengan plaintext → kunci ter-expose. DARPA TRUST program mensponsori riset ini untuk verifikasi chip militer AS tidak punya backdoor.

> [!tip] Plot Twist 4: Most IoT Devices Fall at Level 0–2
> Lebih dari 70% embedded device konsumen (2024 survey) **gagal** di Level 0–2: UART enabled, tidak ada password console, tidak ada JTAG fuse, flash bisa dibaca tanpa proteksi. Jika target lo adalah IoT device rumahan, lo tidak perlu Level 4+ — start with screwdriver, multimeter, and USB-UART. **Kebanyakan keamanan embedded adalah teater**, bukan engineering.

> [!info] Plot Twist 5: Hardware Hacking Adalah Satu-Satunya Cara Untuk "Pasti" — Karena Fisika Tidak Bisa Dibohongi
> Software can lie: debugger detected, VM detected, strings obfuscated, anti-analysis aktif. Tapi **voltase adalah voltase** — probe oscilloscope menunjukkan tegangan real-time yang tidak bisa dimanipulasi software. **Emisi EM adalah emisi EM** — tidak bisa dienkripsi. **Silicon adalah silicon** — fotonya di SEM tidak bisa diubah setelah fabrikasi. Inilah kenapa hardware hacking adalah **ultimate ground truth**: semua abstraksi software pada akhirnya berjalan di atas transistor yang fisik.

---

## Perbandingan Level per Target

| Target | Level Minimum | Saran Fokus |
|---|---|---|
| **Router rumah / CCTV** | L0–L3 | UART → flash dump → firmware RE |
| **IoT smart home** | L1–L4 | JTAG + side-channel untuk key extraction |
| **Secure element / smart card** | L4–L5 | Power analysis + FI untuk extract key |
| **TPM / HSM** | L5–L7 | FI + decap untuk read silicon |
| **Military chip** | L6–L7 | SEM + FIB + netlist RE (DARPA TRUST level) |
| **Console gaming (jailbreak)** | L3–L5 | Flash dump + FI bypass signature check |

---

## Sumber & Telusur Lebih Lanjut

- **Sheet 2 (Hardware Hacking Lengkap)** → [[hardware-hacking-re]] (Level 0–7 tabel + flow interaksi RE-HW)
- **Sheet 1 (Software RE)** → [[hardware-hacking-re]] (strings → decompile → exploit)
- **Firmware RE Deepdive** → [[firmware-reverse-engineering-deepdive]] (flash extraction, QEMU emulation, UEFI)
- **Side-Channel Attack** → (akan ada: `hierarchy-side-channel.md`)
- **Supply Chain Security** → [[software-supply-chain-security-deepdive]] (SLSA, provenance)
- **Endpoint Security (Boot Chain Analog)** → [[hierarchy-endpoint-security]] (Secure Boot, Ring -3/-2)
- **Wireless (SDR untuk RE RF)** → [[hierarchy-wireless]] (spectrum analysis companion)
- **Master Index** → [[master-index]]

---

> Hardware hacking adalah **ilmu pasti paling "pasti" di security** — karena lo berinteraksi dengan fisika, bukan abstraksi. Tapi pastinya mahal. Pilih level yang sepadan dengan value target.

*Hardware Hacking Hierarchy | Level 0 (Visual PCB) → Level 7 (Silicon RE/FIB) · Semakin Tinggi, Semakin Destruktif*

audited
---
