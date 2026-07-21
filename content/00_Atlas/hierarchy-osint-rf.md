---
title: Hierarchy Osint Rf
tags:
- atlas
created: '2026-04-23'
updated: '2026-07-01'
status: operational
---

# 🕵️ OSINT & 📡 RF Signal — Hierarki Lengkap

> Dua tabel yang jarang dibahas di kurikulum IT standar tapi wajib dikuasai untuk security research, forensik digital, dan threat intelligence.

---

## Daftar Isi

- [[#Sheet 1 — OSINT Open Source Intelligence]]
- [[#Sheet 2 — RF Signal Intelligence SIGINT]]
- [[#Koneksi antara OSINT dan RF]]

---

## Sheet 1 — OSINT: Open Source Intelligence

> **OSINT** = mengumpulkan informasi dari sumber yang **tersedia publik secara legal**. Kuncinya bukan akses ilegal — tapi tahu **di mana harus melihat** dan **bagaimana menghubungkan titik-titik**.

|🔍 Level & Tools|⚡ Teknik & Sweet Spot|☠️ Tembok & Batasan|🎯 Use Case Nyata|
|---|---|---|---|
|**Level 0** — Passive Googling _(Google, Bing, DuckDuckGo, Yandex)_|Nama + kota, username, nomor telepon, email. Operator dasar: `"exact phrase"`, `site:`, `filetype:`. Yandex unggul untuk pengenalan wajah reverse image search.|Hasil terlalu umum untuk target dengan nama populer. Google memfilter banyak hasil sensitif.|Background check dasar, verifikasi identitas, cek reputasi bisnis|
|**Level 1** — Username & Email Recon _(Sherlock, Maigret, Holehe, GHunt, Hunter.io)_|Sherlock scan 400+ platform sekaligus dari satu username. Holehe cek apakah email terdaftar di 120+ layanan. GHunt dump info Google account dari email.|Target yang pakai username berbeda di setiap platform. Banyak false positive di platform kecil.|Investigasi fraud, tracking persona online, verifikasi akun|
|**Level 2** — Metadata & Image Intelligence _(ExifTool, Jeffrey's Exif Viewer, Google Lens, PimEyes)_|Foto yang diupload sering menyimpan GPS coordinates, device model, timestamp di metadata EXIF. PimEyes: facial recognition search seluruh internet dari satu foto. Reverse image search lacak origin foto.|Platform besar (Instagram, Twitter) otomatis strip metadata saat upload. PimEyes berbayar dan ada batasan etika serius.|Verifikasi hoax/disinformasi, lacak lokasi dari foto, investigasi jurnalistik|
|**Level 3** — Social Network Analysis _(Maltego, SpiderFoot, OSINT Framework, Gephi)_|Visualisasi graf koneksi antar entitas (orang → perusahaan → domain → IP → email). Maltego transform: satu nama bisa expand jadi ratusan node koneksi otomatis. SpiderFoot OSINT otomatis dari satu seed target.|Data bisa outdated. Maltego Community Edition sangat terbatas. Graf besar butuh validasi manual — garbage in garbage out.|Threat actor profiling, investigasi jaringan kriminal, due diligence korporat|
|**Level 4** — Infrastructure & Domain Recon _(Shodan, Censys, FOFA, Amass, Subfinder, theHarvester)_|Shodan: search engine untuk **semua perangkat yang terkoneksi internet** — kamera CCTV, router, ICS/SCADA, server. Amass + Subfinder: enumerasi subdomain pasif. theHarvester: harvest email + subdomain dari sumber publik.|Shodan hanya melihat apa yang terekspos ke internet. Target di belakang Cloudflare/WAF tersembunyi IP-nya.|Attack surface mapping, keamanan infrastruktur, riset kerentanan kamera publik|
|**Level 5** — Data Breach Intelligence _(Have I Been Pwned, Dehashed, IntelligenceX, Breach Forums monitor)_|Database kebocoran data yang sudah dipublikasikan. HIBP cek apakah email/password bocor. IntelligenceX arsip Tor, paste, dan dokumen yang sudah dihapus. Dehashed: search by email, IP, username, password hash.|Menggunakan breach data untuk akses akun = ilegal. Garis tipis antara research dan penyalahgunaan.|Credential monitoring, investigasi fraud, notifikasi user yang bocor|
|**Level 6** — Geospatial & Satellite Intelligence _(Google Earth Pro, Sentinel Hub, Maxar, Planet.com, SunCalc, GeoSpy)_|Analisis foto satelit resolusi tinggi untuk tracking pergerakan fisik, verifikasi klaim geografis, lacak konstruksi fasilitas militer. SunCalc: hitung posisi matahari dari bayangan di foto untuk pinpoint waktu dan lokasi. GeoSpy: AI geolocation dari foto pemandangan.|Citra satelit komersial biasanya delay 1–3 hari. Resolusi publik dibatasi regulasi (~30cm pixel).|Investigasi Bellingcat (MH17, Wagner Group), pemantauan konflik, verifikasi klaim media|
|**Level 7** — Behavioral & Linguistic Analysis _(LIWC, Linguistic Inquiry, stylometry, i2 Analyst Notebook)_|Analisis gaya penulisan (stylometry) untuk de-anonymisasi penulis anonim. LIWC menganalisis pola psikologis dari teks. i2 Analyst Notebook: platform link analysis profesional dipakai FBI/Interpol.|Butuh corpus teks yang cukup besar untuk akurasi. False attribution berbahaya secara legal dan etis.|Atribusi malware dari komentar kode, de-anonymisasi forum gelap, analisis propaganda|
|☠️ **Level 8** — Aggregasi & Korelasi Multi-Source _(Palantir Gotham, Recorded Future, Mandiant Advantage, i-Base)_|Korelasi otomatis lintas ratusan sumber data (breach data + SIGINT + geospatial + social + financial). Palantir Gotham dipakai CIA, FBI, Polri beberapa negara. Recorded Future: threat intelligence real-time dari darkweb + clearnet + teknikal feeds.|Akses terbatas pemerintah dan enterprise besar. Biaya lisensi jutaan dolar. Risiko false positive pada skala besar bisa menghancurkan karier/hidup orang yang salah diidentifikasi.|Counter-terrorism, financial crime investigation, APT attribution|

---

### Workflow OSINT Standar (OSINT Cycle)

```
[SEED / TARGET]
      │
      ▼
┌─────────────────────────────┐
│  Level 0–1: IDENTIFY        │  Username, email, nama, foto
│  Siapa targetnya?           │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Level 2–3: ENUMERATE       │  Metadata, koneksi sosial, afiliasi
│  Apa yang terhubung?        │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Level 4–5: INFRASTRUCTURE  │  Domain, IP, server, credential bocor
│  Di mana mereka beroperasi? │
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Level 6–7: LOCATE & VERIFY │  Geospatial, behavioral, linguistic
│  Kapan dan di mana fisiknya?│
└──────────────┬──────────────┘
               │
               ▼
┌─────────────────────────────┐
│  Level 8: CORRELATE & ACT   │  Multi-source fusion → kesimpulan
│  Apa artinya semua ini?     │
└─────────────────────────────┘
```

> [!warning] Garis Etis OSINT OSINT **legal** = informasi yang tersedia publik tanpa bypass autentikasi. OSINT **ilegal** = menggunakan breach data untuk akses akun, stalking, doxxing dengan niat harm. Bellingcat, Forensic Architecture, dan ICIJ (Panama Papers) membuktikan OSINT bisa jadi jurnalisme investigatif kelas dunia — tanpa menyentuh hal ilegal.

---

## Sheet 2 — RF Signal Intelligence (SIGINT)

> **RF** = Radio Frequency. Semua komunikasi nirkabel — WiFi, HP, satelit, radar, remote TV — adalah sinyal RF. **SIGINT** di ranah akademik = studi bagaimana sinyal dikirim, diterima, dianalisis, dan diamankan.

| 📡 Level & Tools                                                                                                    | ⚡ Teknik & Sweet Spot                                                                                                                                                                                                                                                                                                                                       | ☠️ Tembok & Batasan                                                                                                                      | 🎯 Aplikasi Nyata                                                                                            |
| ------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ |
| **Level 0** — Spectrum Awareness _(RTL-SDR dongle $15, SDR#, GQRX)_                                                 | SDR (Software Defined Radio): dongle USB murah yang bisa menangkap sinyal radio 25MHz–1.7GHz. Dengarkan ATC (komunikasi pilot-ATC), cuaca NOAA, AIS kapal, ACARS pesawat, sinyal FM/AM, pager rumah sakit.                                                                                                                                                  | Hanya receive, tidak bisa transmit. Resolusi ADC rendah. Butuh antena yang sesuai frekuensi target.                                      | Belajar spektrum RF, monitoring cuaca, tracking pesawat via ADS-B, hobi ham radio                            |
| **Level 1** — Protocol Decoding _(GNU Radio, Universal Radio Hacker, Wireshark + RF)_                               | Universal Radio Hacker: rekam sinyal RF tak dikenal, analisis modulasi (AM/FM/FSK/ASK/PSK), decode protokol secara visual. GNU Radio: platform flowgraph untuk membangun receiver/transmitter custom dari blok.                                                                                                                                             | Decode protokol proprietary butuh reverse engineering mendalam. Beberapa protokol terenkripsi end-to-end.                                | Reverse engineering remote kontrol, keamanan IoT, riset protokol industri                                    |
| **Level 2** — WiFi & Bluetooth Analysis _(Kismet, Aircrack-ng, Wireshark, hcxdumptool, BtleJuice)_                  | Kismet: passive WiFi/Bluetooth monitoring — deteksi semua perangkat di sekitar tanpa connect. Monitor mode capture semua frame. Analisis handshake WPA2, beacon frame, probe request (device yang mencari AP lama).                                                                                                                                         | Capture di frekuensi 2.4/5GHz butuh adapter mode monitor. WPA3 jauh lebih resistan. Transmitting tanpa izin melanggar hukum.             | Wireless security audit, keamanan jaringan kampus, deteksi rogue AP                                          |
| **Level 3** — Cellular Network Analysis _(IMSI Catcher concept, gr-gsm, Osmocom, SIMtrace)_                         | Analisis protokol GSM/4G/5G di layer sinyal. gr-gsm: decode traffic GSM dengan RTL-SDR. Osmocom: stack open-source untuk seluruh protokol seluler. SIMtrace: monitoring komunikasi SIM card.                                                                                                                                                                | GSM (2G) sudah deprecated, 4G/5G terenkripsi lebih kuat. IMSI catcher aktif = ilegal di hampir semua negara tanpa otoritas.              | Riset keamanan protokol seluler, analisis legacy network, akademis                                           |
| **Level 4** — Side-Channel RF _(TEMPEST, Van Eck Phreaking, Power Analysis)_                                        | **TEMPEST**: menangkap radiasi elektromagnetik tidak sengaja dari komputer/monitor untuk merekonstruksi apa yang ditampilkan di layar — **tanpa akses fisik ke perangkat**. Van Eck (1985) membuktikan monitor CRT bisa "dibaca" dari luar gedung dengan antena sederhana. Power analysis: menganalisis konsumsi daya CPU untuk ekstrasi kunci kriptografi. | Butuh antena directional sensitif dan setup shielded. Monitor modern (LCD/OLED) jauh lebih susah dibanding CRT. Jarak efektif terbatas.  | Keamanan fasilitas pemerintah, certified TEMPEST shielding (standar NATO SDIP-27), riset side-channel attack |
| **Level 5** — Software Defined Radio Advanced _(HackRF One, LimeSDR, USRP, OpenBTS)_                                | HackRF: SDR yang bisa **transmit** 1MHz–6GHz, bukan hanya receive. LimeSDR/USRP: resolusi ADC lebih tinggi, dipakai lab universitas. OpenBTS: bangun BTS GSM sendiri dengan USRP.                                                                                                                                                                           | Transmitting di frekuensi berlisensi = ilegal. HackRF transmit power rendah (10–15mW). Regulasi frekuensi sangat ketat di setiap negara. | Lab riset universitas, demo security conference (DEF CON), licensed amateur radio                            |
| **Level 6** — Satellite & High-Altitude Signals _(Inmarsat decode, Iridium sniffing, GPS spoofing research, ACARS)_ | Decode komunikasi satelit Inmarsat L-band dengan RTL-SDR (yang dipakai untuk lacak MH370). Iridium: komunikasi satelit LEO yang bisa di-sniff. GPS spoofing: broadcast sinyal GPS palsu untuk menipu receiver navigasi.                                                                                                                                     | Antena parabola directional untuk sinyal satelit lemah. GPS spoofing aktif = ilegal dan berbahaya (bisa menyesatkan pesawat/kapal).      | Riset navigasi, analisis komunikasi aviasi, forensik insiden penerbangan                                     |
| **Level 7** — Electronic Warfare Concepts _(Jamming theory, DRFM, Radar cross-section, LPI radar)_                  | Domain militer/akademis: jamming (ganggu sinyal musuh), DRFM (Digital Radio Frequency Memory — tipu radar dengan replay sinyal yang dimodifikasi), LPI (Low Probability of Intercept) radar. Analisis radar cross-section untuk stealth.                                                                                                                    | Implementasi aktif = domain militer eksklusif. Jamming frekuensi apapun = ilegal berat di semua yurisdiksi sipil.                        | Riset akademis Teknik Elektro/Pertahanan, kontraktor pertahanan, lembaga riset seperti LIPI/BRIN             |
| ☠️ **Level 8** — SIGINT Infrastructure _(Echelon, XKEYSCORE RF module, FORNSAT, TRANSIT collection)_                | NSA/GCHQ level: jaringan antena raksasa yang intercept komunikasi satelit global (FORNSAT), analisis sinyal dari submarine cable landing points, koleksi SIGINT dari platform udara (RC-135, U-2). Snowden documents mengkonfirmasi keberadaan dan skala operasinya.                                                                                        | Tidak dapat diakses publik. Infrastruktur bernilai miliaran dolar. Dioperasikan oleh komunitas intelijen negara.                         | Kontra-terorisme, HUMINT support, strategic intelligence                                                     |

---

### Peta Frekuensi yang Bisa Dipelajari Secara Legal

```
Frekuensi      Isi                          Tools
─────────────────────────────────────────────────────
87–108 MHz   │ FM Radio biasa              │ RTL-SDR + SDR#
108–137 MHz  │ Komunikasi Aviasi (VHF ATC) │ RTL-SDR + SDR#
137–138 MHz  │ Cuaca NOAA Satelit          │ RTL-SDR + WXtoImg
156–174 MHz  │ AIS Kapal Laut (Marine VHF) │ RTL-SDR + OpenCPN
433–434 MHz  │ IoT, remote, sensor cuaca   │ RTL-SDR + URH
1090 MHz     │ ADS-B Pesawat (lokasi real) │ RTL-SDR + dump1090
1.5 GHz      │ Inmarsat / GPS              │ RTL-SDR + antena patch
2.4 / 5 GHz  │ WiFi, Bluetooth             │ Kismet + monitor mode adapter
```

> [!tip] Entry Point Terbaik untuk Mahasiswa IT Mulai dari **RTL-SDR dongle** (~Rp 200rb di Tokopedia) + antena dipole sederhana + software **SDR#** (Windows) atau **GQRX** (Linux). Dalam satu sore kamu bisa track pesawat real-time di atas kotamu menggunakan ADS-B di 1090MHz. Dari situ dunia RF terbuka lebar.

---

## Koneksi antara OSINT dan RF

```
OSINT Level 4 (Shodan)          RF Level 0 (RTL-SDR)
        │                               │
        │   Shodan bisa scan            │   RTL-SDR bisa
        │   perangkat RF yang           │   detect beacon
        │   terekspos ke internet       │   WiFi dari Shodan target
        └──────────────┬────────────────┘
                       │
                       ▼
              ┌─────────────────┐
              │  Contoh Nyata:  │
              │  Target = tower │
              │  IoT factory    │
              │                 │
              │  OSINT → temukan│
              │  IP & firmware  │
              │                 │
              │  RF → detect    │
              │  protokol zigbee│
              │  atau 433MHz    │
              │  yang bocor     │
              └─────────────────┘
```

> [!info] Karir yang Relevan Kombinasi OSINT + RF membuka jalur ke:
> 
> - **Threat Intelligence Analyst** (Recorded Future, Mandiant, Group-IB)
> - **RF Security Researcher** (IOActive, NCC Group)
> - **SIGINT Analyst** (BSSN, BIN, kontraktor pertahanan)
> - **Wireless Security Consultant** (penetration testing infrastruktur)
> - **Jurnalis Investigatif** (model Bellingcat)

---

## 🔗 Lihat Juga

- [[network-security|Network Security]]
- [[cheatsheet|Cheat Engine]]
- [[hierarchy-search|Search Hierarchy]]
- [[hierarchy-ai-levels|AI Levels Hierarchy]]
- [[military-and-intelligence-tools-hub|military-and-intelligence-tools-hub]]
- [[military-intelligence-tools-hierarchy|military-and-intelligence-tools Hierarchy]]

---

_OSINT & RF Signal Intelligence Hierarchy | Dari Google sampai Echelon · Dari RTL-SDR sampai TEMPEST_