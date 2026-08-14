---
title: "Hierarchy Side-Channel Attacks"
tags:
  - atlas
  - side-channel
  - hardware
  - crypto
  - blue-team
aliases:
  - "hierarchy-side-channel"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  - callout
---


# ⚡ HIERARKI SIDE-CHANNEL ATTACK — Dari Timing Observation (Level 0) sampai Quantum Side-Channel (Level 5)

> Side-channel attack adalah seni **membaca data rahasia dari efek samping yang tidak disengaja** — bukan dari ciphertext atau kode, tapi dari timing, power consumption, emisi elektromagnetik, suara, panas, atau pantulan cahaya. Hirarki ini memetakan evolusi dari yang paling non-invasif (timing) sampai yang paling canggih (quantum side-channel). Untuk implementasi ChipWhisperer, power analysis, dan countermeasure, lihat [[hardware-hacking-re]] Sheet 2 (Level 4–5 Side-Channel & Fault Injection).

> [!info] Cara Baca
> Level 0 = observasi timing (software-only, tidak butuh alat). Level 5 = quantum side-channel (penelitian frontier). Setiap level menambah **signal-to-noise ratio** — semakin tinggi level, semakin presisi probing fisik. Tapi juga semakin mahal dan membutuhkan akses fisik.

---

## Tabel Utama — Level 0 sampai Level 5

| ⚡ Level | 🧠 Pendekatan | ⚡ Teknik & Cara Kerja | ☠️ Tembok / Countermeasure | 🎯 Aplikasi Nyata |
|---|---|---|---|---|
| **Level 0** — Timing Attack | Ukur **waktu eksekusi** fungsi kriptografi. Perbedaan waktu eksekusi untuk input berbeda → infer data rahasia | Classic: timing attack pada RSA (Kocher 1996) — waktu exponentiation bergantung pada bit kunci. **Remote timing attack** via network latency (bisa dilakukan dari jaringan lain) | Constant-time programming. Blinding (randomize exponent). **Jitter/noise injection.** Network latency noise bisa masking | Crack password verification (string comparison timing), RSA key extraction via network |
| **Level 1** — Power Analysis (Simple) | Monitor **konsumsi daya** chip secara langsung — SPA (Simple Power Analysis) | Setiap instruksi punya power signature berbeda. Operasi kripto (AES S-box lookup, RSA multiplication) tampak jelas di power trace. **Satu trace cukup** untuk baca kunci langsung | Hiding (randomize instruksi). Masking (split data jadi multiple shares). **Single trace saja tidak cukup jika ada noise filtering.** | Smart card attack, IoT key extraction, hardware security research |
| **Level 2** — Power Analysis (Differential) | DPA: korelasi statistik **ribuan trace** → ekstrak kunci dari noise background | Tidak perlu tahu instruksi spesifik. Kumpulkan 10k+ trace dengan input random → korelasi trace dengan hypothetical power model → kunci ter-reveal | Masking (order d — semakin tinggi d, semakin sulit DPA). Random delay insertion. **ChipWhisperer bisa break masking order 1 dalam ribuan trace** | ChipWhisperer target training, smart card reverse, secure element evaluation |
| **Level 3** — EM Emanation | Probe antena dekat chip → baca **emisi elektromagnetik** tanpa kontak fisik | Setiap transisi transistor memancarkan EM. Dengan probe dekat (±1mm dari die), EM trace sama detail dengan power trace. **Non-invasive**: tanpa modifikasi device | EM shielding (mu-metal, copper tape). On-die EM sensor (deteksi probe). **EM masih sama powerful dengan power analysis — lebih non-invasif** | Smartphone secure element (SE), TPM extraction, hardware forensic evaluation |
| **Level 4** — Acoustic / Thermal / Optical | Analisis suara keyboard, panas chip, atau pantulan cahaya LED | **Acoustic**: suara keyboard bisa direkonstruksi ke teks (typo acoustic attack). **Thermal**: chip yang baru compute punya hotspot — thermal camera bisa baca data residual. **Optical**: pantulan monitor ke mata kucing/teko → baca data di layar (Van Eck phreaking optical) | **Acoustic**: quiet keyboard, white noise. **Thermal**: cooldown period. **Optical**: privacy screen, frosted glass | Keylogger via microphone (acoustic keyboard), data extraction dari air-gapped system (thermal) |
| **☠️ Level 5** — Fault + Cache + Quantum | Cache timing (Flush+Reload, Prime+Probe), Rowhammer, Quantum side-channel | **Cache timing**: Flush+Reload — monitor cache line untuk infer data di shared memory (Meltdown/Spectre). **Rowhammer**: flip bit di DRAM tetangga via akses berulang. **Quantum side-channel**: measure qubit state via EM dari quantum processor | Cache flush instructions (clflush). ECC memory mitigasi Rowhammer. Quantum side-channel baru frontier — mitigasi belum ada | Cloud VM escape (Meltdown/Spectre — 2018), DRAM bit flip (Rowhammer), akademis frontier |

---

## Peta Visual — Invasiveness vs Information

```
Information ↑
L5 ─ Fault/Cache/Quantum ●──●●● Invasiveness
L4 ─ Acoustic/Thermal    ●──●●
L3 ─ EM Emanation       ●──●
L2 ─ DPA (Differential) ●──●
L1 ─ SPA (Simple)       ●─
L0 ─ Timing              ●
    └────────────────────────→ Physical proximity needed
        Remote      Local     Same chip
```

> [!warning] Most SC Attacks Di-Mitigasi Dengan Constant-Time Programming
> 80% side-channel attack bisa dimitigasi dengan constant-time programming: kode yang berjalan dalam **waktu yang sama dan power yang sama** untuk semua input. Tidak ada branching yang bergantung pada data rahasia. Tools: **ctgrind** (detect constant-time violation), **dudect** (detect timing difference). Countermeasure untuk DPA/EM butuh masking + hiding — lebih rumit.

---

## Kenapa Hirarki Ini Penting

### 1. Side-Channel Bypass Enkripsi Tanpa Memecah Algoritma

AES-256 secara matematis aman (butuh 2^256 percobaan brute force). Tapi AES dengan implementasi naive — **kunci bisa diekstrak via power analysis dalam 10 menit dengan ChipWhisperer**. Ini bukan bug di algoritma — ini bocor melalui efek samping eksekusi. Semua enkripsi hanya seaman implementasinya.

### 2. Applicable ke Semua Level Hardware

| Target | SC Attack Layer | Efektivitas |
|---|---|---|
| Smart card (contact) | SPA/DPA (L1/L2) | Sangat efektif |
| Mobile phone SE | EM (L3) | Efektif dengan probe dekat |
| Cloud VM | Cache timing (L5) | Meltdown/Spectre |
| Air-gapped PC | Acoustic (L4) | Lambat tapi possible |
| IoT microcontroller | SPA (L1) | Sangat efektif (tanpa shielding) |

### 3. Countermeasure Hierarchy = Kebalikan

Countermeasure paling dasar: **constant-time** (gratis untuk developer yang aware). 
- Constant-time → stop timing attack (L0)
- + Hiding (random delay, shuffling) → mitigate SPA (L1)
- + Masking (d-order) → mitigate DPA (L2)
- + EM shielding → mitigate EM (L3)
- + Physical isolation (air-gap) → mitigate acoustic/thermal (L4)
- + ECC memory + no shared cache → mitigate cache/rowhammer (L5)

---

## Plot Twists

> [!danger] Plot Twist 1: Spectre (2018) Adalah Side-Channel Paling Destruktif Abad Ini
> Spectre/Meltdown: **cache timing attack** yang mengeksploitasi speculative execution di CPU. Attacker bisa baca memory kernel, memory proses lain, dan password dari JavaScript di browser. **2 tahun patch cycle** untuk semua OS + CPU microcode. Ini bukan bug implementasi — ini **desain CPU yang fundamental trade-off speed vs security.**

> [!tip] Plot Twist 2: Rowhammer Bisa Flip Bit Tanpa Akses — Dari DRAM
> Rowhammer: akses baris DRAM berulang → charge bocor ke baris tetangga → flip bit. Attack: flip bit di page table entry → privilege escalation. Diperparah dengan **TRRespass** (2020) yang bisa target baris spesifik. ECC memory mitigasi sebagian, tapi modern DDR4/DDR5 masih rentan dalam beberapa kondisi.

> [!warning] Plot Twist 3: Acoustic Attack dari Keyboard Bisa Dapat Password
> Penelitian 2023: deep learning bisa rekonstruksi teks dari suara keyboard dengan akurasi 95%. Microphone smartphone di meja cukup untuk merekam. Countermeasure: quiet keyboard (silent switch), white noise generator, atau password manager with autofill.

> [!info] Plot Twist 4: EM Emanation Tidak Bisa Dimatikan Sepenuhnya
> Setiap transistor yang switching memancarkan EM. Shielding (mu-metal, copper) mengurangi — tapi tidak menghilangkan — EM. **Untuk secure environment (embassy, military), TEMPEST shielding standard adalah persyaratan.** Indonesia punya standar serupa untuk ruangan rapat terbuka.

---

## Sumber & Telusur Lebih Lanjut

- **Side-Channel dalam Hardware Hacking** → [[hardware-hacking-re]] Sheet 2 (Level 4–5 SCA + Fault Injection)
- **ChipWhisperer (Platform SC)** → [[hardware-hacking-re]] (ChipWhisperer CW308, CW1173)
- **Meltdown/Spectre** → [[ebpf-kernel-security]] (speculative execution vulnerability)
- **Constant-Time Programming** → [[cryptography-biometrics]] (implementation security)
- **TEMPEST** → [[hierarchy-osint-rf]] (RF emanations intelligence)
- **Master Index** → [[master-index]]

---

> Side-channel attack mengajarkan: **implementasi lebih penting dari algoritma.** AES-256 paling kuat pun tidak berguna jika power trace mengekspos kunci. Constant-time programming adalah investasi security paling murah dengan dampak tertinggi.

*Side-Channel Attack Hierarchy | Level 0 (Timing) → Level 5 (Cache/Fault/Quantum) · Membaca Rahasia dari Efek Samping*
