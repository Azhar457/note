---
title: Underground Knowledge
tags:
- cyber-security
- library
- threat-intel-privacy
created: '2026-04-25'
updated: '2026-07-01'
status: active
---

# ☠️ UNDERGROUND KNOWLEDGE — Cheat Engine & Dark Web Hierarchy

> Dua hierarki "shadow knowledge" yang jarang ada di kurikulum resmi. Cheat Engine: senjata yang sama dipakai cheat developer dan anti-cheat engineer — plus teknik identik dengan APT malware nyata. Dark Web: infrastruktur anonimitas yang dipakai jurnalis, whistleblower, peneliti, dan pelaku kejahatan dalam satu jaringan yang sama.

> [!warning] Konteks Etis
> Semua teknik di dokumen ini bersifat dual-use. Pemahaman mendalam tentang cara kerja sistem ini adalah **prasyarat** untuk bisa membangun pertahanan yang efektif. Pengetahuan bukan kejahatan — penggunaan yang menentukan.

---

## Sheet 1 — Cheat Engine Hierarchy: Dari Macro sampai DMA God Mode

| 🎮 Level & Alat | ⚡ Cara Kerja & Sweet Spot | ☠️ Tembok Kematian | 🔵 Anti-Cheat yang Menangkal | 🔴 Contoh di Alam Liar |
|---|---|---|---|---|
| **Level 0** — Macro & Script *(AutoHotKey, Logitech GHub Script, Razer Synapse Macro)* | Bukan cheat sejati. Simulasi input keyboard/mouse di level HID device — Ring 3 murni. Recoil control, auto-click, bunny hop otomatis. Tidak menyentuh memori game sama sekali. | Timing terlalu presisi. Input manusia punya jitter alami — macro menghasilkan interval 1ms yang tidak manusiawi. Mudah dideteksi secara statistik. | BattlEye timing analysis, EAC input pattern detection, server-side behavior analysis | Macro recoil Valorant, AHK bunny hop CS2, Logitech "no recoil" script |
| **Level 1** — Memory Editor *(Cheat Engine, ArtMoney, GameConqueror Linux)* | Scan & patch nilai di memori proses game via Ring 3 `ReadProcessMemory` / `WriteProcessMemory` API. Cari nilai HP=100, freeze, ubah. SpeedHack via `timeGetTime()` hook. Cheat Engine juga bisa attach debugger ke proses. | Anti-cheat memantau siapa yang panggil `OpenProcess` ke PID game. Signature DLL Cheat Engine sangat dikenal. | Easy Anti-Cheat handle scanner, BattlEye process list blacklist, Riot Vanguard Ring 0 | Cheat Engine di game offline/single player, ArtMoney untuk RPG lama |
| **Level 2** — DLL Injection *(Manual Map Injection, LoadLibrary, Process Hollowing, Reflective DLL)* | Suntikkan kode (DLL) ke dalam address space proses game. Cheat berjalan sebagai bagian dari game — bisa hook fungsi render untuk ESP/Wallhack, baca entity list langsung. Manual Map: inject tanpa tercatat di module list. Reflective DLL: DLL yang bisa load dirinya sendiri dari memori. | Semua teknik injeksi meninggalkan jejak: VAD (Virtual Address Descriptor) anomali, thread start address aneh, private memory executable tanpa backing file. | BattlEye module scan, EAC VAD scan, Windows PatchGuard, Vanguard memory integrity check | Internal aimbot CS2, ESP Valorant via D3D hook, triggerbot via Direct3D Present() hook |
| **Level 3** — Kernel Driver / Ring 0 *(Signed driver exploit, BYOVD — Bring Your Own Vulnerable Driver)* | Cheat berjalan sebagai kernel driver. Dari Ring 0 bisa baca memori proses manapun tanpa memanggil Win32 API yang dimonitor — langsung via `MmCopyMemory`. Anti-cheat Ring 3 buta total. BYOVD: exploit driver lama yang punya signature valid tapi ada vulnerability — load, exploit, dapat Ring 0. | Windows DSE (Driver Signature Enforcement) — harus bypass. PatchGuard deteksi modifikasi kernel. HVCI (Hypervisor-Protected Code Integrity) blokir unsigned driver dari execute. | Riot Vanguard (Ring 0 anti-cheat), HVCI, Windows PatchGuard, Kernel Patch Protection | Cheat PUBG era 2019–2021, Apex kernel cheat, driver Capcom.sys legendaris. **BYOVD juga dipakai BlackByte ransomware dan Lazarus Group untuk bypass EDR** |
| **Level 4** — Hypervisor / VMM *(Custom Type-1 Hypervisor, KVM-based cheat, Blue Pill variant)* | Jalankan game di dalam VM yang dikontrol hypervisor buatan sendiri. Cheat berjalan di Ring -1 — di bawah OS dan anti-cheat sekaligus. Intercept memory access game secara transparan. Dari sudut pandang anti-cheat: semua terlihat normal. | Setup sangat kompleks. Latensi tambahan dari virtualisasi terasa di game kompetitif. CPUID bisa dikueri untuk deteksi VM — anti-cheat modern mulai cek ini. | Vanguard CPUID hypervisor detection, BattlEye VM detection heuristic, Intel TXT attestation | Sangat rare. Private cheat high-end ($500+/bulan). Didokumentasikan di forum underground. Teknik identik dengan **Blue Pill rootkit** di dunia malware |
| **Level 5** — DMA Card *(PCIe DMA via FPGA — Squirrel DMA, EnigmaX, PCILeech)* | Kartu PCIe fisik berbasis FPGA dipasang di slot PCIe kosong. Membaca seluruh RAM via bus PCIe langsung — **bypass 100% semua software**. Tidak ada proses, tidak ada driver, tidak ada jejak di OS target. Proses di PC kedua. | Tidak ada proses untuk dideteksi. Tembok satu-satunya: Intel VT-d IOMMU (batasi akses DMA device), server-side behavior analysis, physical inspection. | IOMMU enforcement, server-side statistical analysis, hardware ban (tidak efektif) | Squirrel DMA + PCILeech, EnigmaX card. Teknik **identik dengan PC-3000 yang akses firmware storage via PCIe** |
| ☠️ **Level 6** — External AI Vision *(Screen capture + YOLOv8, Arduino/FPGA mouse controller)* | Tidak menyentuh PC game sama sekali. Capture card rekam output monitor → model AI (YOLOv8) deteksi musuh dari pixel murni → sinyal ke Arduino/FPGA yang simulasi gerakan mouse secara hardware-level. Zero software footprint di PC target. | Latency pipeline ~10–30ms tapi masih feasible untuk aimbot. Butuh GPU terpisah untuk inference real-time. Setup fisik eksternal cukup mencolok. | **Tidak terdeteksi anti-cheat software apapun saat ini.** Satu-satunya counter: server-side replay review manual. | Kasus Forsaken CS:GO 2018 = versi primitif. Versi AI modern (YOLOv8) jauh melampaui itu |

---

## Sheet 2 — Dark Web & Information Access Hierarchy

| 🌑 Level & Ekosistem                                                                          | ⚡ Cara Akses & Konten                                                                                                                                                                                                                                                                                            | ☠️ Risiko & Tembok                                                                                                                                                           | 🔵 Siapa yang Memantau                                                                                            |
| --------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------- |
| **Level 0** — Surface Web *(Google, Bing, DuckDuckGo, Yandex)*                                | Browser biasa. ~4% dari total internet. Berita, sosmed, e-commerce, Wikipedia — semua terindeks crawler. Yandex lebih baik untuk reverse image search wajah dibanding Google.                                                                                                                                    | Tidak ada risiko teknis. Tapi: data behavioral dijual ke advertiser, ISP log semua request, Cloudflare lihat semua traffic yang lewat.                                       | ISP, Google, Cloudflare, pemerintah via PRISM (Snowden 2013)                                                      |
| **Level 1** — Semi-Hidden Web *(Google Dorks, Shodan, Paywalls, Login-gated)*                 | Browser + operator pencarian lanjut (`site:`, `filetype:`, `inurl:`, `intitle:`). Shodan: search engine perangkat terkoneksi internet. Database bocor yang belum dihapus, dokumen internal misconfigured, CCTV publik terbuka.                                                                                   | Legal abu-abu — mengakses sistem tanpa izin eksplisit bisa ilegal meski "terbuka." Shodan menampilkan apa yang seharusnya tidak publik.                                      | Pemilik server via access log, Shodan sendiri log semua query                                                     |
| **Level 2** — Deep Web *(Database akademik, intranet, cloud storage tidak terindeks)*         | Kredensial valid, VPN korporat, akses institusi. Jurnal ilmiah (Sci-Hub), rekam medis, email korporat, source code internal. Bukan "gelap" — hanya tidak terindeks search engine.                                                                                                                                | Credential theft adalah vektor utama masuk. Perbedaan deep web dan dark web sering disalahpahami — deep web = tidak terindeks, bukan ilegal.                                 | Admin IT via SIEM, audit trail database, DLP (Data Loss Prevention)                                               |
| **Level 3** — Dark Web via Tor *(Ahmia, Torch, The Hidden Wiki, .onion sites)*                | Tor Browser → traffic dienkripsi dan dirutekan melalui 3 node relay (Guard → Middle → Exit). .onion address hanya bisa diakses via Tor. Konten: SecureDrop (whistleblower), forum peneliti, marketplace ilegal, ransomware blog, leak database.                                                                  | Exit node bisa baca traffic HTTP yang tidak dienkripsi E2E. Opsec buruk (login akun real, Javascript enabled) = terekspos.                                                   | **Exit node operator**, NCA, FBI (Operation Onymous), Europol, Tor Project researcher                             |
| **Level 4** — Tor Exit Node Position *(Konsep "titik node terluar" dari film)*                | Daftar jadi exit node = seluruh traffic user Tor yang exit lewatmu bisa dimonitor. Bisa lihat: URL tujuan, konten HTTP, DNS query, metadata — jika traffic tidak dienkripsi E2E. Bandwidth konsumsi masif (bisa 100Mbps+, 10–40TB/bulan).                                                                        | Traffic besar = ISP notice. Di beberapa negara, exit node operator ditangkap karena traffic penggunanya. Dan kamu juga dipantau oleh researcher yang monitor exit node list. | Kamu memantau user, tapi **kamu juga dipantau** oleh: Tor Project, researcher akademis, LE yang monitor exit node |
| **Level 5** — I2P & Freenet *(Invisible Internet Project, Freenet, Zeronet)*                  | Garlic routing (I2P): lebih anonim dari Tor, traffic dibungkus berlapis. Konten persisten terdistribusi (Freenet) — tidak ada server tunggal yang bisa di-takedown. Lebih lambat, lebih anonim, lebih kecil komunitasnya.                                                                                        | Traffic tidak keluar ke clearnet — tertutup dalam ekosistemnya. Sulit dimonitor tapi bukan mustahil via traffic analysis attack.                                             | Researcher akademis, jarang LE karena kompleksitas dan skala kecil                                                |
| **Level 6** — Private Overlay Networks *(Riffle, Loopix, Nym Network, Mixnets)*               | Mixnet: pesan di-mix dengan pesan orang lain + delay acak — bahkan observer yang lihat seluruh jaringan tidak bisa korelasikan sender-receiver. Dirancang tahan global passive adversary. SPIFFE (identity layer) + mixnet = komunikasi service anonim.                                                          | Setup sangat teknis. Komunitas sangat kecil. Latensi tinggi karena delay intentional. Belum ada deployment skala besar.                                                      | Tidak ada teknik deteksi yang terbukti efektif untuk mixnet yang diimplementasi benar                             |
| **Level 7** — VPN: Realita vs Mitos                                                           | VPN memindahkan titik kepercayaan, bukan menghilangkannya. ISP lihat: "kamu konek ke VPN." VPN provider lihat: semua yang tadinya ISP lihat. No-log policy: bisa bohong (kasus HideMyAss 2011, IPVanish 2016 — serahkan log ke FBI meski klaim no-log). DNS leak, IPv6 leak, WebRTC leak = bypass VPN diam-diam. | VPN bukan anonymity tool — VPN adalah trust relocation tool. Jurisdiction VPN provider menentukan apakah log diserahkan ke pemerintah.                                       | VPN provider, Five Eyes pressure via court order, DNS resolver (jika leak)                                        |
| ☠️ **Level 8** — Nation-State SIGINT *(Echelon, XKEYSCORE, FORNSAT, Five/Nine/Fourteen Eyes)* | NSA/GCHQ: jaringan intercept komunikasi satelit global (FORNSAT), tap undersea cable, platform udara (RC-135). XKEYSCORE: query "semua aktivitas seseorang di internet" dalam hitungan detik. Snowden 2013 mengkonfirmasi semua ini nyata dan operasional sejak 2007.                                            | Tidak dapat diakses publik. Infrastruktur bernilai miliaran dolar. Dioperasikan oleh komunitas intelijen negara-negara Five Eyes (US, UK, CA, AU, NZ) + extended.            | NSA, GCHQ, ASD, CSIS, DGSE — Five Eyes + Nine Eyes + Fourteen Eyes                                                |

---

## Anatomi Tor: Posisi Exit Node yang Dimaksud

```
[Kamu — User Tor]
      │ koneksi terenkripsi ke Guard
      ▼
┌─────────────┐
│  Guard Node │ ← Tahu IP aslimu, TIDAK tahu tujuanmu
└─────────────┘
      │ terenkripsi, Guard tidak tahu isi
      ▼
┌──────────────┐
│ Middle Node  │ ← Tidak tahu siapa kamu, tidak tahu tujuanmu
└──────────────┘
      │ terenkripsi satu layer tersisa
      ▼
┌─────────────────────────────────┐
│         EXIT NODE               │ ← ☠️ POSISI YANG DIMAKSUD
│                                 │   Tahu TUJUAN traffic
└─────────────────────────────────┘   TIDAK tahu siapa pengirimnya
      │ traffic TIDAK terenkripsi     Bisa baca ISI jika HTTP
      │ (jika bukan HTTPS/E2E)
      ▼
  [Internet Biasa]
```

> [!danger] Kasus Nyata: Dan Egerstad 2007
> Peneliti Swedia menjalankan 5 exit node Tor → berhasil intercept ribuan kredensial email diplomat dan NGO internasional yang menggunakan Tor tapi lupa bahwa exit node bisa baca traffic HTTP. Dia ditangkap bukan karena hacking — tapi karena **memiliki informasi yang seharusnya tidak dia punya**. Pelajaran: Tor melindungi *siapa kamu*, bukan *apa yang kamu kirim* jika tidak ada enkripsi E2E.

---

## Koneksi: Cheat Engine ↔ Security Research ↔ Dark Web

```
Cheat Engine Level 3 (BYOVD)
        │
        └── TEKNIK IDENTIK ──► BlackByte Ransomware (bypass EDR)
                               Lazarus Group (APT Korea Utara)
                               ← ini bukan kebetulan, toolset sama

Cheat Engine Level 5 (DMA PCIe)
        │
        └── KONSEP IDENTIK ──► PC-3000 (akses firmware storage via PCIe)
                               Cold boot attack (baca RAM via PCIe DMA)
                               Digital forensics hardware

Dark Web Level 4 (Exit Node)
        │
        └── DIPAKAI OLEH ───► Jurnalis (The Guardian, NYT pakai Tor)
                              Whistleblower (Snowden via Tor)
                              Researcher (monitor threat actor)
                              Pelaku kejahatan
                              Intelligence agency (juga pakai Tor)
                              ← semua dalam jaringan yang sama
```

> [!tip] Framework Berpikir: Dual-Use Knowledge
> Hampir semua yang ada di sheet ini adalah dual-use. Test sendiri dengan pertanyaan ini sebelum mempelajari teknik apapun:
> - Apakah saya memahami **cara kerjanya** (pengetahuan) atau **cara menggunakannya untuk merugikan** (niat)?
> - Apakah ada konteks legal yang sah (penelitian, CTF, bug bounty, pertahanan)?
> - Apakah ini digunakan pada sistem milik sendiri atau dengan izin?
>
> Bellingcat menggunakan OSINT Level 6 untuk mengekspos kejahatan perang. NSA menggunakan Level 8 untuk surveillance massal. Toolset yang sama, niat dan akuntabilitas yang berbeda.

---

## Peta Posisi Semua Level

```
CHEAT ENGINE
Level 0  │ Macro/AHK          → Ring 3, timing detectable
Level 1  │ Memory Editor      │ OpenProcess API tracked
Level 2  │ DLL Injection      │ VAD anomaly detectable
Level 3  │ Kernel Driver      │ PatchGuard, HVCI (hard)
Level 4  │ Hypervisor         │ CPUID check (partial)
Level 5  │ DMA Card PCIe      │ IOMMU only (if enabled)
Level 6  │ AI + Hardware      → Zero software footprint

DARK WEB / INFORMATION ACCESS
Level 0  │ Surface Web        → Full visibility to everyone
Level 1  │ Dorks/Shodan       │ Server logs
Level 2  │ Deep Web           │ Auth + SIEM
Level 3  │ Tor (.onion)       │ Exit node + LE
Level 4  │ Exit Node          │ You see others, others see you
Level 5  │ I2P/Freenet        │ Academic researcher
Level 6  │ Mixnet             │ No proven detection
Level 7  │ VPN reality        │ Provider + court order
Level 8  │ Nation-State SIGINT → Backbone-level, no escape
```

---

## 🔗 Lihat Juga

- [[master-index]]
- [[hierarchy-osint-rf]] — OSINT sebagai komplemen pencarian info
- [[hardware-hacking-re]] — teknik yang overlap dengan Level 3–5 cheat
- [[cyber-security]] — Blue Team vs Red Team (anti-cheat = blue team gaming)
- [[network-security|OSI Layer Hierarchy]] — OSI Layer Threat Landscape
- [[cryptography-biometrics|Biometrik Levels]] — enkripsi E2E yang melindungi traffic Tor

---

*Underground Knowledge | Cheat Engine Level 0–6 + Dark Web Level 0–8 · Shadow Hierarchy*
