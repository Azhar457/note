---
tags:
  - game-security
  - anti-cheat
  - reverse-engineering
  - BYOVD
  - kernel-driver
  - DMA
  - exploit
aliases:
  - Cheat Engine Hierarchy
  - Game Security Hierarchy
  - Anti-Cheat Bypass Levels
created: 2026-04-23
updated: "2026-07-01"
status: operational
cssclasses:
  - wide-table
title: Cheatsheet
---

# 🎮 GAME SECURITY — Cheat Engine Hierarchy & Anti-Cheat Landscape

> Setiap level cheat punya "alamat" di CPU privilege ring. Semakin dalam — semakin sulit dideteksi, dan semakin relevan untuk security research **di luar gaming**. Level 3–6 adalah teknik APT nyata.

> [!tip] Kenapa Ini Penting untuk Security?
> Ini topik yang sangat menarik dari sisi **reverse engineering & game security** — karena anti-cheat developer harus paham semua level ini untuk membangun pertahanan. Langsung ke tabelnya.

---

## Tabel Hierarki — Level 0 sampai Level 6

| 🔧 Level & Alat                                                                                                           | ⚡ Cara Kerja & Sweet Spot                                                                                                                                                                                                                                                                    | ☠️ Tembok Kematian                                                                                                                                                                        | 🔵 Anti-Cheat yang Menangkal                                                                                                                                                                     | 🔴 Contoh di Alam Liar                                                                                                   |
| ------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------ |
| **Level 0** — Macro & Script _(AutoHotKey, Logitech GHub Script, Razer Synapse Macro)_                                    | Bukan cheat sejati. Simulasi input keyboard/mouse di level HID device. Recoil control, auto-click, bunny hop otomatis. Beroperasi sepenuhnya di User Space, tidak menyentuh memori game sama sekali.                                                                                          | Deteksi timing. Input manusia memiliki jitter alami — macro menghasilkan interval presisi 1ms yang tidak manusiawi. Mudah dideteksi secara statistik.                                     | Battleye timing analysis, EAC input pattern detection, server-side behavior analysis                                                                                                             | Macro recoil Valorant, AutoHotKey bunny hop CS2, Logitech "no recoil" script                                             |
| **Level 1** — Memory Editor _(Cheat Engine, ArtMoney, GameConqueror Linux)_                                               | Scan & patch nilai di memori proses game (Ring 3 ReadProcessMemory/WriteProcessMemory API). Cari nilai HP=100, freeze, ubah. SpeedHack via timeGetTime() hook.                                                                                                                                | Anti-cheat memantau siapa yang memanggil `OpenProcess` + `ReadProcessMemory` ke PID game. Signature scan DLL Cheat Engine sangat dikenal.                                                 | Easy Anti-Cheat handle scanner, BattlEye process list blacklist, Riot Vanguard Ring 0                                                                                                            | Cheat Engine di game offline/singleplayer, ArtMoney untuk RPG lama                                                       |
| **Level 2** — DLL Injection _(Manual Map Injection, LoadLibrary Injection, Process Hollowing)_                            | Menyuntikkan kode (DLL) langsung ke dalam address space proses game. Cheat berjalan sebagai bagian dari game itu sendiri — bisa hook fungsi render untuk ESP/Wallhack, baca entity list langsung dari memori.                                                                                 | Semua teknik injeksi meninggalkan jejak: loaded module list, VAD (Virtual Address Descriptor) anomali, thread start address aneh. Anti-cheat scan ini setiap detik.                       | BattlEye module scan, EAC VAD scan, Windows PatchGuard (untuk kernel hooks)                                                                                                                      | Internal aimbot CS2, ESP Valorant via D3D hook, triggerbot via Direct3D Present() hook                                   |
| **Level 3** — Kernel Driver (Ring 0) _(Signed driver exploit, BYOVD — Bring Your Own Vulnerable Driver)_                  | Cheat berjalan sebagai kernel driver. Dari Ring 0 bisa baca memori proses manapun tanpa memanggil Win32 API yang dimonitor — langsung akses physical memory via `MmCopyMemory`. Anti-cheat Ring 3 buta total.                                                                                 | Windows DSE (Driver Signature Enforcement) — driver harus punya tanda tangan digital valid. Solusi: exploit driver lama yang sudah punya signature tapi punya vulnerability (BYOVD).      | Riot Vanguard (Ring 0 anti-cheat, senjata melawan senjata), Windows PatchGuard, HVCI (Hypervisor-Protected Code Integrity)                                                                       | Cheat PUBG era 2019–2021, Apex Legends kernel cheat, driver Capcom.sys yang legendaris                                   |
| **Level 4** — Hypervisor / VMM _(Custom Type-1 Hypervisor, KVM-based cheat, Blue Pill variant)_                           | Jalankan game di dalam VM yang dikontrol hypervisor buatan sendiri. Cheat berjalan di Ring -1 — **di bawah OS dan anti-cheat sekaligus**. Bisa intercept memory access game secara transparan, anti-cheat tidak bisa mendeteksi karena dari sudut pandangnya semua normal.                    | Setup sangat kompleks. Latensi tambahan dari virtualisasi bisa terasa di game kompetitif. Intel/AMD CPUID bisa dikueri untuk cek apakah berjalan di VM — anti-cheat modern mulai cek ini. | Vanguard CPUID hypervisor detection, Battleye VM detection heuristic, Intel TXT attestation                                                                                                      | Sangat rare, digunakan di private cheat high-end ($500+/bulan), didokumentasikan di cheat forum underground              |
| **Level 5** — DMA Card _(PCIe DMA — Direct Memory Access via FPGA Card)_                                                  | Kartu PCIe fisik (berbasis FPGA seperti Squirrel DMA, EnigmaX) dipasang di slot PCIe kosong motherboard. Membaca seluruh RAM secara langsung via bus PCIe — **bypass 100% semua software**, termasuk anti-cheat Ring 0, karena tidak ada kode yang berjalan di PC target. Proses di PC kedua. | Hardware murni — tidak ada proses, tidak ada driver, tidak ada jejak software. Tembok: latency DMA transfer (~1–5ms), butuh parsing manual struktur memori game yang update tiap patch.   | **Hampir tidak bisa dideteksi secara software.** Mitigasi: Intel VT-d IOMMU (batasi akses PCIe device ke memori tertentu), server-side anticheat (behavior analysis), fisik: BIOS lock PCIe slot | Squirrel DMA + PCILeech, EnigmaX card, Varware DMA — komunitas aktif di forum private                                    |
| ☠️ **Level 6** — External Overlay + AI Vision _(Screen capture + YOLOv8 object detection, Arduino/FPGA mouse controller)_ | Tidak menyentuh PC game sama sekali. Kamera/capture card merekam output monitor, model AI (YOLOv8) mendeteksi musuh dari pixel murni, lalu sinyal dikirim ke Arduino/FPGA yang mensimulasikan gerakan mouse secara hardware-level. **Tidak ada yang bisa dideteksi dari dalam PC.**           | Latency total pipeline (capture → inference → actuate) ~10–30ms — masih cukup untuk aimbot. Kelemahan: butuh setup fisik eksternal, GPU terpisah untuk inference real-time.               | **Tidak terdeteksi oleh anti-cheat apapun yang ada saat ini.** Satu-satunya counter: server-side statistical analysis dan manual review replay. Hardware ban tidak efektif.                      | Digunakan di turnamen semi-pro (kasus Forsaken CS:GO 2018 adalah versi primitifnya). Versi AI modern jauh lebih canggih. |

---

## Peta Privilege vs Detektabilitas

```
                        MUDAH DETEKSI ◄─────────────────────► HAMPIR MUSTAHIL
                              │                                      │
Level 0  │ Macro/AHK          ├── Timing analysis
Level 1  │ Cheat Engine       ├── API hook monitoring
Level 2  │ DLL Injection      ├── VAD scan, module list
Level 3  │ Kernel Driver      ├── PatchGuard, HVCI
Level 4  │ Hypervisor         ├── CPUID check (parsial)
Level 5  │ DMA Card           ├── IOMMU (parsial, jika aktif)
Level 6  │ AI + Hardware      ├── Server-side behavior only ← tembok terakhir
```

---

## Kenapa Ini Relevan untuk Security?

> [!info] Dua Sisi Mata Pedang
> Semua teknik di Level 3–6 adalah **teknik yang sama** digunakan oleh:
>
> - **Cheat developer** → untuk bypass anti-cheat
> - **Anti-cheat engineer** (Riot, BattlEye, VAC) → untuk memahami apa yang harus dilawan
> - **Security researcher** → BYOVD di Level 3 adalah **teknik APT nyata** yang digunakan malware seperti BlackByte ransomware dan Lazarus Group untuk bypass EDR

Level 5 (DMA via PCIe) adalah **teknik yang sama persis** dengan [[data-recovery|PC-3000]] mengakses firmware drive — bedanya cuma targetnya RAM, bukan storage. Konsepnya identik: bypass semua software dengan akses hardware langsung.

---

## 🔗 Lihat Juga

- [[master-index|Master Index]]
- [[endpoint-security|Endpoint Security]] — BYOVD overlap di Ring 0
- [[network-security|Network Security]] — OSI Layer & defense
- [[data-recovery|Data Recovery]] — DMA / PC-3000 konsep serupa
- [[hierarchy-ai-levels|AI Levels Hierarchy]] — AI Vision di Level 6
- [[hardware-hacking-re|Hardware Hacking]] — Teknik RE untuk firmware analysis
- [[underground-knowledge|Underground Knowledge]] — Konsolidasi Cheat + Dark Web

---

_Game Security | Cheat Engine Level 0 (Macro) → Level 6 (AI Vision Hardware) · Anti-Cheat Landscape_
