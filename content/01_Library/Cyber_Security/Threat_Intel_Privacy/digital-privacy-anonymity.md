---
title: "Digital Privacy Anonymity"
tags:
  - cyber-security
  - library
  - threat-intel-privacy
aliases:
  - "digital-privacy-anonymity"
created: "2026-05-29"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

# 🕵️ DIGITAL PRIVACY & ANONYMITY — Dari Ad Blocker sampai Ghost Mode

> Kebalikan dari [[hierarchy-osint-rf|OSINT]]. OSINT mengajarkan cara **menemukan** orang dari informasi publik. Dokumen ini mengajarkan cara **menghilang** dari permukaan yang sama. Dua sisi dari koin yang sama.

> [!info] Konteks & Relevansi Personal
> Data kamu pernah muncul di situs judol — itu adalah hasil scraping portfolio publik. Dokumen ini adalah framework untuk mencegah hal serupa, dengan skalabel dari "privacy dasar" sampai "tidak bisa ditemukan sama sekali." Pilih level sesuai threat model, bukan langsung loncat ke ekstrem.

> [!warning] Prinsip Pertama — Threat Model Dulu
> Tidak ada solusi privasi yang "benar" secara universal. Yang benar adalah yang sesuai threat model kamu. Terlalu paranoid = tidak produktif. Tidak cukup paranoid = bocor. Tentukan siapa yang kamu khawatirkan sebelum implement apapun.

---

## Daftar Isi

- [[#Threat Model — Tentukan Musuhmu Dulu]]
- [[#Layer 1 — Blokir Surveillance Korporat]]
- [[#Layer 2 — Bersihkan Jaringan Lokal]]
- [[#Layer 3 — Identity Compartmentalization]]
- [[#Layer 4 — Hapus Public Paper Trail]]
- [[#Layer 5 — Disconnection dari Infrastruktur]]
- [[#Data Broker — Musuh Utama yang Jarang Disebut]]
- [[#OPSEC Fundamentals]]
- [[#Privacy Tools Hierarchy]]
- [[#Konteks Indonesia]]

---

## Threat Model — Tentukan Musuhmu Dulu

```
Sebelum implement apapun, jawab ini:

SIAPA yang mau kamu hindari?
├── Data broker & advertiser komersial  → Level 1-2 cukup
├── Stalker / mantan / orang iseng      → Level 1-3
├── Jurnalis / investigator privat      → Level 1-4
├── Hacker / criminal                  → Level 1-3 + security hygiene
├── Pemerintah / law enforcement        → Level 1-5 (tapi ada batas legal)
└── Nation-state actor                  → Di luar scope dokumen ini

APA yang mau kamu lindungi?
├── Alamat rumah         → Level 3-4 critical
├── Identitas online     → Level 1-3
├── Aktivitas browsing   → Level 1-2
├── Konten komunikasi    → Enkripsi E2E (Signal, ProtonMail)
└── Keberadaan fisik     → Level 4-5
```

>[!tip] Aturan Emas
>Privasi bukan tentang menyembunyikan kejahatan — ini tentang **kontrol atas informasi tentang dirimu sendiri**. Data kamu yang muncul di situs judol adalah bukti nyata bahwa hilangnya kontrol ini punya konsekuensi nyata.

---

## Layer 1 — Blokir Surveillance Korporat

### Fakta yang Perlu Diketahui

```
Estimasi nilai data satu user per tahun:
Google: ~$300 (US user)
Facebook: ~$200
Data broker aggregate: ~$200
Total: ~$700/tahun per individu

Yang dikumpulkan:
→ Behavioral profile (kamu klik apa, beli apa, baca apa)
→ Location history (lewat GPS, WiFi, cell tower triangulation)
→ Social graph (siapa yang kamu kenal)
→ Financial behavior (pengeluaran, kategori)
→ Health data (dari search query, wearable)
→ Political/religious inference (dari konten yang dikonsumsi)

Dynamic pricing (terbukti):
→ Amazon, hotel, airline ticket
→ Algoritma deteksi: user pakai MacBook → asumsi mampu bayar lebih
→ Price inflation jika terdeteksi high-income signal
→ Solusi: private browsing + browser spoofing user agent
```

### Implementasi Teknis

**Browser & Extension Stack:**

```
Minimum viable:
├── Firefox (bukan Chrome — Chrome adalah surveillance tool)
│   Settings: DNS over HTTPS aktif, telemetri off
├── uBlock Origin — ad + tracker blocker (open source, efektif)
│   Mode: Medium blocking untuk sehari-hari
├── Privacy Badger (EFF) — learn tracker patterns
└── Cookie AutoDelete — hapus cookie otomatis

Advanced:
├── Mullvad Browser (dibuat bareng Tor Project)
│   → Fingerprint resistant, no Google telemetry
├── Brave Browser
│   → Chromium-based tapi privacy-first
│   → Block fingerprinting by default
└── LibreWolf (Firefox hardened fork)

Anti-Fingerprinting:
→ Browser fingerprint = kombinasi unik:
  screen size + font list + GPU info + timezone + language
→ bahkan tanpa cookie, masih bisa di-track
→ Tool cek: coveryourtracks.eff.org

DNS Privacy:
→ Default DNS (ISP) = ISP tahu setiap domain yang kamu visit
→ DNS over HTTPS (DoH): enkripsi DNS query
  Providers: Cloudflare (1.1.1.1), NextDNS, Quad9
→ Lebih baik: self-hosted Unbound DNS resolver
```

**Email Privacy:**

```
Email komersial (Gmail, Yahoo, Outlook):
→ Scan isi email untuk advertising
→ Metadata tersimpan selamanya
→ Bisa di-subpoena oleh penegak hukum

Alternatif:
├── ProtonMail / ProtonMail → zero-access encryption
│   → ProtonMail tidak bisa baca email kamu
│   → Swiss law (lebih protektif dari US/EU)
├── Tutanota → Germany-based, open source
├── Skiff Mail → Web3/decentralized
└── SimpleLogin / AnonAddy → email alias service
    → Satu email real kamu → ratusan alias
    → Alias per service: "shopee@random.simplelogin.com"
    → Alias bocor? Matikan alias itu saja
    → Real email tidak pernah terekspos
```

---

## Layer 2 — Bersihkan Jaringan Lokal

### IoT Threat yang Diabaikan

```
Device yang "menelepon rumah" (kirim telemetri):
├── Smart TV: Samsung, LG, Android TV = track apa yang ditonton
│   (bahkan jika tidak langganan streaming)
│   Metode: ACR (Automatic Content Recognition)
│   → Kamera TV capture apa yang di layar → identify konten
├── Robot vacuum (Roomba, Roborock): map seluruh rumah
│   → Layout rumah = data yang sangat sensitif
│   → iRobot sempat rencanakan jual data ini
├── Smart speaker: selalu listen untuk wake word
│   → Recording bisa di-upload ke server
├── Printer modern: log semua yang dicetak, kirim ke vendor
├── Game console: track game session, achievement, purchase
└── Smartphone: lokasi 24/7, microphone access background app

Kamu tidak beli produk ini — kamu adalah produk dari device ini.
```

### Pi-hole — DNS Sinkhole untuk Seluruh Network

```
Pi-hole adalah:
→ DNS server yang berjalan di local network kamu
→ Semua DNS request dari semua device → Pi-hole dulu
→ Pi-hole cek: domain ini ada di blocklist?
  YA  → return 0.0.0.0 (block, tidak connect)
  TIDAK → forward ke upstream DNS (Cloudflare, dll)

Yang di-block:
→ Semua domain telemetri dari Windows, Android, iOS
→ Semua domain ad network (Google Ads, Facebook Pixel)
→ Domain data broker yang diketahui
→ Custom: tambah domain apapun

Hardware yang dibutuhkan:
→ Raspberry Pi 4 (~Rp 700rb) → dedicated Pi-hole
→ Atau: VPS kecil ($3/bulan) → Pi-hole di cloud
→ Atau: Docker container di server yang sudah ada

Setup:
curl -sSL https://install.pi-hole.net | bash
# Ikuti wizard, set sebagai DNS server di router

Statistik nyata:
→ Rata-rata rumah tangga: 30-50% DNS query di-block
→ Artinya: 1 dari 3 request adalah tracking/telemetri
```

### VPN — Apa yang Diselesaikan dan Apa yang Tidak

```
VPN MENYELESAIKAN:
✅ ISP tidak bisa lihat konten traffic kamu
✅ ISP tidak bisa jual browsing history kamu
✅ Website tidak lihat IP asli kamu
✅ Bypass geo-restriction
✅ Protection di public WiFi (coffee shop, hotel)

VPN TIDAK MENYELESAIKAN:
❌ Anonymity — VPN provider lihat semua traffic
❌ Protect dari cookie/fingerprint tracking
❌ Sembunyikan dari Google jika kamu login Google
❌ Protect dari malware
❌ Membuat kamu "anonymous" di internet

Pilih VPN yang benar:
├── Mullvad VPN → bayar cash/Monero, tidak butuh email saat daftar
│   → No-log yang benar-benar verified
│   → Circuit mode (mirip Tor tapi lebih cepat)
├── ProtonVPN → Swiss law, open source, no-log
├── IVPN → privacy-focused, no email registration
└── HINDARI: NordVPN, ExpressVPN (marketing > substance)
    HideMyAss (serahkan log ke FBI 2011)
    IPVanish (serahkan log ke FBI meski klaim no-log)

Untuk anonymity sesungguhnya: VPN + Tor, bukan pilih salah satu
```

---

## Layer 3 — Identity Compartmentalization

### Mengapa Single Identity Berbahaya

```
Skenario single point of failure:

Kamu punya SATU email utama untuk:
→ Semua akun sosmed
→ Semua layanan online
→ Bank, OVO, GoPay
→ Tokopedia, Shopee

Jika email ini bocor (have i been pwned?):
→ Credential stuffing: coba password dari breach di semua service
→ Account takeover: reset password semua service via email ini
→ Data aggregation: hubungkan semua akun = profil lengkap kamu
→ Social engineering: phish semua kontak kamu

Dan memang email utama sudah bocor:
→ Cek: haveibeenpwned.com
→ Kemungkinan besar jawaban: YA, sudah di beberapa breach
```

### Identity Silo Architecture

```
DESAIN SILO IDEAL:

SILO A — Daily Life (Identitas Utama)
├── Email: email asli yang hanya untuk personal/keluarga
├── Phone: nomor utama, hanya untuk kontak terpercaya
├── Payment: rekening utama, kartu debit/kredit
└── Location: alamat rumah asli

SILO B — Professional / Online Presence
├── Email: ProtonMail atau alias berbeda
├── Phone: nomor sekunder (eSIM, Google Voice)
├── Payment: kartu virtual (Privacy.com) atau OVO terpisah
└── "Alamat": PO Box atau alamat kantor
    (untuk registrasi yang butuh alamat)

SILO C — High-Risk / Anonymous Activities
├── Email: ProtonMail baru, buat via Tor, tanpa link ke identitas lain
├── Phone: nomor burner (beli cash, tanpa KYC)
├── Payment: Monero, cash, kartu prepaid beli cash
└── Location: tidak ada link ke lokasi nyata

ATURAN ANTAR SILO:
→ JANGAN cross-reference: jangan login ke Silo A service dari device Silo C
→ JANGAN reuse password
→ JANGAN pakai device yang sama untuk keduanya (idealnya)
→ JANGAN mention satu silo di silo lain
```

### Tools untuk Compartmentalization

```
EMAIL ALIAS:
SimpleLogin (ProtonMail company):
→ Buat unlimited alias
→ "shopee_2026@sl.myalias.com" → forward ke ProtonMail
→ Reply dari ProtonMail → tampil sebagai alias, bukan email asli
→ Service bocor? Disable alias itu saja

PHONE NUMBER VIRTUAL:
→ Google Voice (US only, butuh US number untuk verifikasi)
→ TextNow / TextFree (US, Canada)
→ MySudo ($1-5/bulan per alias) → recommended untuk compartmentalization
→ 0815x prepaid beli di counter tanpa KYC (untuk kebutuhan lokal)

PAYMENT MASKING:
Privacy.com (US only):
→ Buat kartu virtual per merchant
→ Lock ke merchant tertentu
→ Set spending limit
→ Merchant breach? Hanya kartu virtual itu yang affected

Alternatif Indonesia:
→ GoPay/OVO dengan identitas berbeda (grey area KYC)
→ Kartu prepaid Visa (Jenius, dll)
→ Crypto (Monero untuk privacy sesungguhnya, bukan Bitcoin)

BROWSER ISOLATION:
→ Firefox container (Firefox Multi-Account Containers addon)
→ Satu container per silo (Personal, Shopping, Social)
→ Antar container tidak share cookie/session
→ Google di Social container tidak bisa track aktivitas di Shopping container
```

---

## Layer 4 — Hapus Public Paper Trail

### Database Publik yang Bisa Reveal Alamat Rumah

```
DI INDONESIA (setara):
→ Direktori telepon publik (sudah jarang, tapi masih ada)
→ PPID (Pejabat Pengelola Informasi dan Dokumentasi)
→ Data KPR yang bocor (sering terjadi)
→ Data NPWP yang bocor (2022, 69 juta data)
→ Data BPJS yang bocor (2021, 279 juta data)
→ Social media yang overshare lokasi
→ Google Maps review dengan foto yang reveal lokasi

DI AS (yang dimaksud video):
→ Property records (nama pemilik + alamat = publik)
→ Vehicle registration (DMV = publik di banyak state)
→ Voter registration (nama + alamat = publik)
→ Court records (kasus hukum = publik)
→ Business registration (owner + address)
```

### Mitigasi Legal (Konteks Umum)

```
STRATEGI PEMISAHAN ASET DARI IDENTITAS:

1. PO Box / Virtual Office Address:
   → Gunakan alamat layanan PO Box untuk registrasi online
   → Jangan pakai alamat rumah sebagai billing address
   → Untuk bisnis: virtual office (Rp 200-500rb/bulan)
   → Di AS: Earth Class Mail, Stable, Anytime Mailbox

2. Tidak Overshare di Registrasi Online:
   → Banyak form yang butuh "address" tapi tidak ada validasi
   → Isi dengan alamat PO Box atau kota saja
   → Hanya isi alamat asli jika WAJIB (pengiriman fisik)

3. Audit Data Broker Secara Berkala:
   → Data broker = perusahaan yang jual data pribadi
   → Opt-out dari semua yang bisa (ada ratusan)
   → Tool otomatis: DeleteMe ($10/bulan, US focus)
   → Manual: cari nama kamu di Spokeo, Whitepages, BeenVerified
     lalu submit opt-out request satu per satu

4. Google Yourself Rutin:
   → Setiap bulan: cari nama kamu + kota
   → Cari: "nama kamu" site:judol (seperti kasus kamu)
   → Google Alerts: notif jika nama kamu muncul di Google
   → Jika ada: submit Google Removal Request
```

---

## Layer 5 — Disconnection dari Infrastruktur

### Apa yang Selalu Meninggalkan Jejak

```
SMARTPHONE:
→ Lokasi 24/7 via GPS + WiFi + Cell tower
→ App yang request location background (Instagram, TikTok)
→ Google/Apple track lokasi bahkan jika GPS dimatikan
  (via WiFi probe request, Bluetooth)
→ IMEI (permanent device ID) + IMSI (SIM ID)
→ Metadata foto: GPS coordinate, device model, timestamp

SOLUSI:
→ Airplane mode saat tidak butuh konektivitas
→ GrapheneOS (Android hardened) — tidak ada Google service
→ "Faraday bag" ($20) — block semua sinyal saat tidak dipakai
→ Pisahkan device: phone untuk komunikasi, phone lain untuk banking
→ Extreme: kembali ke feature phone basic

TRANSPORTASI MODERN:
→ Kereta, pesawat: KTP/paspor = log identitas + rute
→ Jalan tol: e-money = log waktu + lokasi
→ Kendaraan modern (2015+): telematics, GPS, bisa di-subpoena
→ GoCar, Grab: log lengkap semua perjalanan

PEMBAYARAN:
→ Semua digital payment = log transaksi permanent
→ Kartu kredit/debit: profil belanja tersimpan selamanya
→ Satu-satunya anonimitas: cash dan crypto (Monero)

SOLUSI PRAKTIS:
→ Cash untuk pembelian sensitif
→ Preset transport card (tidak di-link ke identitas)
→ Paspor vs KTP: paspor tidak print alamat fisik
  (lebih aman digunakan sebagai ID saat check-in hotel)
```

---

## Data Broker — Musuh Utama yang Jarang Disebut

```
APA ITU DATA BROKER:
Perusahaan yang:
1. Kumpulkan data dari berbagai sumber (public record, breach, survey)
2. Agregasi dan enrich data
3. Jual ke siapapun yang bayar

SUMBER DATA MEREKA:
→ Public record (tanah, kendaraan, pengadilan)
→ Social media yang kamu overshare
→ Loyalty program (member Indomaret, Alfamart, SPBU)
→ Survey yang kamu isi dengan dapat diskon
→ Breach database yang mereka beli
→ App yang kamu install (dengan permission luas)
→ ISP yang jual data browsing (legal di beberapa negara)

YANG MEREKA JUAL:
→ Alamat rumah kamu
→ Nomor telepon
→ Keluarga dan koneksi sosial
→ Financial status (perkiraan)
→ Political affiliation (dari donate records, social media)
→ Health condition (dari search dan purchase history)
→ Criminal/court records

SIAPA YANG BELI:
→ Advertiser (target iklan lebih presisi)
→ Employer (background check)
→ Landlord (screening penyewa)
→ Skip tracer (temukan orang yang hilang/kabur)
→ Stalker (bayar $5-15 untuk full dossier seseorang)
→ Investigator privat
→ Law enforcement (tanpa warrant di beberapa yurisdiksi)

OPT-OUT STRATEGY:
Tier 1 (lakukan sekarang, gratis):
→ haveibeenpwned.com → cek breach
→ Google Alerts untuk nama kamu
→ Google Removal Request untuk konten yang ditemukan
→ Ajukan ke Google Search Console untuk de-index

Tier 2 (manual, butuh waktu):
→ List semua data broker yang ada di kamu
→ Submit opt-out satu per satu
→ US focused: Spokeo, BeenVerified, Whitepages, Intelius, MyLife
→ Proses: 2-6 minggu per broker, harus di-repeat tiap tahun

Tier 3 (berbayar, otomatis):
→ DeleteMe ($129/tahun) — monitor dan remove secara berkala
→ Kanary, Incogni — alternatif
→ Untuk Indonesia: belum ada service lokal yang mature
```

---

## OPSEC Fundamentals

```
OPSEC (Operations Security) adalah proses:
1. IDENTIFY: informasi apa yang kritis untuk dilindungi
2. ANALYZE THREATS: siapa yang mau informasi ini, dan kenapa
3. ANALYZE VULNERABILITIES: di mana informasi ini bisa bocor
4. ASSESS RISK: seberapa mungkin ancaman exploit vulnerability
5. APPLY COUNTERMEASURES: implement protection yang tepat

COMMON OPSEC FAILURES:

Reuse identifier:
→ Username yang sama di semua platform
  "azhar457" di GitHub, Instagram, Reddit, Discord
→ OSINT bisa correlate semua ini jadi satu profil
→ Solusi: username berbeda per platform
  atau gunakan kata acak per service

Metadata yang dilupakan:
→ Foto yang diposting → lihat metadata EXIF → GPS coordinate
→ Dokumen Word/PDF → author name, edit history
→ Git commit → email address, timezone, activity pattern

Pattern recognition:
→ Posting di jam yang sama setiap hari → lokasi timezone terbaca
→ Bahasa dan gaya penulisan yang konsisten → fingerprinting linguistik
→ Topik yang dibahas → inferensi profesi, hobi, lokasi

SOLUSI:

Strip metadata sebelum share:
→ Foto: mat2 (Linux), ExifTool, atau share via platform yang auto-strip
→ Dokumen: LibreOffice "Export as PDF" strip metadata
→ Screenshot lebih aman dari foto langsung

Consistency kills:
→ Jika mau anonymous: buat persona baru, jangan carryover habit
→ Pindah ke timezone berbeda untuk anonymitas tinggi
→ Hindari topik yang terlalu spesifik ke diri sendiri
```

---

## Privacy Tools Hierarchy

| Level | Threat Model | Tools & Measures | Trade-off |
|---|---|---|---|
| **Level 0** — Baseline | Data broker komersial | uBlock Origin + Firefox + HTTPS Everywhere | Minimal, tidak ganggu workflow |
| **Level 1** — Privacy Conscious | Targeted advertising, stalker kasual | + VPN (Mullvad) + ProtonMail + Password Manager | Sedikit lebih lambat, beberapa site blocked |
| **Level 2** — Privacy Aware | Investigator privat, data broker | + SimpleLogin alias + Pi-hole + DNS-over-HTTPS + 2FA hardware key | Setup butuh waktu, some inconvenience |
| **Level 3** — Privacy Serious | Ex-partner obsesif, jurnalis | + Separate devices per use case + GrapheneOS + Physical address separation + Data broker opt-out | Significant lifestyle adjustment |
| **Level 4** — High Privacy | Pemerintah asing, kriminal organized | + Tor Browser + Monero + Identity silo complete + Faraday bag | Sangat terbatas, butuh disiplin tinggi |
| **Level 5** — Ghost Mode | Nation-state, severe stalking | + No smartphone + Cash only + No modern vehicle + Fake ID aliases via legal entity | Hampir tidak bisa hidup normal |

>[!warning] Jangan Skip Level
>Level 5 tanpa Level 1-4 = useless. Pakai Tor tapi tetap login Google di tab lain = sia-sia. Privacy adalah sistem, bukan fitur individual.

---

## Konteks Indonesia

### Yang Berbeda dari Konteks AS (Video)

```
DATA YANG SUDAH BOCOR MASIF DI INDONESIA:
→ Data KTP (NIK) 279 juta: breach BPJS 2021
→ Data NPWP 69 juta: breach DJP 2022
→ Data PLN, Telkom, BPJS Ketenagakerjaan berbagai waktu
→ Artinya: data dasarmu sudah di luar kendali di dark web
→ Fokus ke damage control, bukan prevent initial breach

LEGAL LANDSCAPE:
→ UU PDP (Perlindungan Data Pribadi) berlaku 2024
→ Hak: minta hapus data, minta koreksi, portabilitas data
→ Controller data wajib respond dalam 3 hari (query) / 14 hari (hapus)
→ Masih early days, enforcement belum kuat

Yang BISA dilakukan di Indonesia:
✅ Minta hapus akun dan data dari semua platform yang sudah tidak dipakai
✅ Aktifkan 2FA di semua akun penting (bank, email, sosmed)
✅ Pakai email alias (SimpleLogin) untuk signup service baru
✅ Pi-hole untuk block telemetri IoT di rumah
✅ ProtonMail untuk komunikasi sensitif
✅ Google Removal Request untuk content yang tidak diinginkan (terbukti efektif)
✅ Audit app permission di smartphone (revoke location, microphone, contact untuk app yang tidak perlu)

Yang TIDAK BISA dilakukan (atau butuh effort ekstra):
❌ Opt-out dari data broker Indonesia (belum ada infrastruktur)
❌ Anonymous phone number tanpa KYC (regulasi SIM card wajib KYC)
❌ Trust/LLC untuk sembunyikan kepemilikan properti (sistem berbeda)
❌ Cash transaction untuk semua hal (digital payment makin wajib)
```

### Immediate Action List (Indonesia, Sekarang)

```
LAKUKAN MINGGU INI:

1. Audit breach:
   → haveibeenpwned.com → masukkan semua email kamu
   → Ganti password yang bocor

2. Password Manager:
   → Install Bitwarden (open source, gratis)
   → Migrate semua password ke sana
   → Generate unique password per site

3. 2FA di akun kritis:
   → Bank → aktifkan 2FA biometrik + OTP
   → Email → aktifkan 2FA dengan authenticator app (bukan SMS)
   → Google/Apple account → hardware key atau authenticator

4. Audit app permission Android/iOS:
   → Settings → Apps → Permission manager
   → Revoke lokasi background dari semua app non-esensial
   → Revoke microphone dari app yang tidak perlu
   → Revoke contact dari app yang tidak perlu kontak

5. Google yourself:
   → Cari nama kamu + nomor telepon
   → Cari nama kamu + alamat
   → Cari nama kamu di nama situs yang mencurigakan
   → Jika ada: submit Google Removal Request

6. Portfolio audit (relevan untuk kamu):
   → Review apa yang public di azharmtq.my.id dan vault
   → Hapus atau obfuscate info yang terlalu spesifik
   → Pasang robots.txt yang block AI scraper
```

---

## Koneksi ke Topik Lain di Vault

```
OSINT ← → Privacy adalah dua sisi koin yang sama:
[[hierarchy-osint-rf]]: "Ini cara menemukan orang dari OSINT"
Dokumen ini:           "Ini cara mencegah OSINT menemukan kamu"

Setiap teknik OSINT = attack surface yang perlu ditutup:
→ OSINT Level 1 (username): pakai username berbeda per platform
→ OSINT Level 2 (metadata foto): strip EXIF sebelum upload
→ OSINT Level 3 (social graph): limit siapa yang bisa lihat koneksi kamu
→ OSINT Level 4 (Shodan/subdomain): pastikan tidak ada exposed service
→ OSINT Level 5 (breach intel): monitor haveibeenpwned, opt-out data broker
→ OSINT Level 6 (geospatial): jangan geotag foto, pakai fake location

Kriptografi [[cryptography-biometrics]]:
→ E2E enkripsi: Signal, ProtonMail, Matrix
→ Full disk encryption: selalu aktif di semua device
→ Post-quantum: untuk komunikasi jangka panjang yang sensitive

Underground Knowledge [[underground-knowledge]]:
→ Tor Browser: Layer 3 privacy
→ I2P: Layer 5 untuk komunikasi (lebih anonim dari Tor)
→ Monero: Layer 4+ untuk payment privacy

OS Hierarchy [[hierarchy-operating-systems]]:
→ Tails: amnesic OS untuk task sensitif satu kali
→ Whonix: daily driver dengan full Tor routing
→ Qubes OS: compartmentalization total per app
```

---

>[!tip] Bottom Line
>Privacy bukan binary — bukan "private sepenuhnya" atau "tidak sama sekali." Ini kontinum, dan kamu tidak harus ada di ujung mana pun. Langkah paling impactful untuk kebanyakan orang:
>1. **Password manager + unique password per site** (protect dari credential stuffing)
>2. **2FA di semua akun kritis** (protect dari account takeover)
>3. **Email alias untuk signup baru** (isolate breach damage)
>4. **Google yourself monthly** (detect dan respond ke exposure)
>
>Empat ini saja sudah melindungi 80% dari ancaman yang paling mungkin kamu hadapi. Level lebih tinggi hanya jika threat model mengharuskan.

---

## 🔗 Lihat Juga

- [[hierarchy-osint-rf|OSINT & RF Hierarchy]] — cara orang MENEMUKAN kamu (reverse dari dokumen ini)
- [[underground-knowledge|Underground Knowledge]] — Tor, I2P, Dark Web untuk anonymitas
- [[cryptography-biometrics|Kriptografi & Biometrik]] — enkripsi untuk protect konten komunikasi
- [[hierarchy-operating-systems|Hierarki OS]] — Tails, Whonix, Qubes untuk OS privacy
- [[zero-taxonomy-security|Zero Taxonomy]] — Zero-Day yang bisa compromise semua privacy kamu
- [[llm-security-red-teaming-attack-surface-ai-layer|LLM Security]] — Zero-Width sebagai tracking vector baru
- [[master-index|Master Index]]

---

*Digital Privacy & Anonymity | Threat Model → Ad Blocking → Pi-hole → Identity Silo → Paper Trail → Ghost Mode · OPSEC · Data Broker · Indonesia Context*
