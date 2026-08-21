---
title: "Information Access and Search Hierarchy"
tags:
  - atlas
  - osint
  - dark-web
  - sigint
  - classified
created: '2026-07-01'
updated: '2026-08-01'
status: pending
cssclasses:
  - wide-table
  
---


> [!tip] Abstract
> Hierarki pencarian informasi diperluas dari 8 level menjadi 11 level — mencakup Cached Web, Breach Data Ecosystem, Alternative Overlays, Closed Communities, Nation-State SIGINT, Restricted Government Networks, Air-Gapped Intelligence, dan SIGINT Satellite Operations. Koreksi teknis diterapkan pada kode Python, klaim "I2P lebih anonim dari Tor", dan posisi Tor Exit Node yang bukan level pencarian melainkan peran di jaringan yang sama. Appendix mencakup Exit Node Configuration, anatomi posisi, dan perbandingan Tor vs I2P vs Freenet.

## Daftar Isi

1. Level 0 — Surface Web
2. Level 1 — Cached & Archived Web
3. Level 2 — Semi-Hidden Web (Google Dorks)
4. Level 3 — Deep Web (Credential-Gated)
5. Level 4 — Breach Data & Leak Ecosystem
6. Level 5 — Dark Web via Tor
7. Level 6 — Alternative Overlay Networks
8. Level 7 — Private & Closed Community Networks
9. Level 8 — Nation-State SIGINT Infrastructure
10. Level 9 — Restricted Government Networks
11. Level 10 — Air-Gapped Intelligence Networks
12. Level 11 — SIGINT Satellite & Submarine Operations
13. Appendix A — Tor Exit Node Position
14. Appendix B — Tor vs I2P vs Freenet Comparison
15. Appendix C — Koreksi Teknis
16. Lihat Juga


## Level 0 — Surface Web

Level pertama — informasi dapat diakses oleh semua orang menggunakan browser biasa. Mencakup sekitar 4% dari total internet.

| Karakteristik | Detail |
|---|---|
| Akses | Browser biasa (Chrome, Firefox, dll) |
| Indeks | Google, Bing, DuckDuckGo |
| Target | Berita, media sosial, e-commerce, Wikipedia |
| Risiko | Data dijual ke advertiser, tracking cookies |

```python
import requests

url = "https://www.google.com"
response = requests.get(url)
print(response.status_code)
print(response.text)
```

---

## Level 1 — Cached & Archived Web

Antara Surface Web dan Semi-Hidden Web — lapisan snapshot historis dan konten yang "dihapus" dari web surface namun masih dapat ditemukan di cache.

| Tool | Fungsi |
|---|---|
| Wayback Machine (archive.org) | Snapshot historis website |
| archive.today / archive.ph | Snapshot permanen |
| Google Cache | Cache halaman yang sudah dihapus |
| CachedView (cachedview.com) | Multi-cache search |
| Common Crawl | Open repository of web crawl data |
| WikiBlame | Mencari edit history Wikipedia |
| Wayback Machine CDX API | Programmatic access |
| Domain Tools WHOIS History | Historical domain records |

> [!important]
> Website dihapus $$\rightarrow$$ masih ada di cache. Konten diedit $$\rightarrow$$ versi asli masih ada. Domain berubah pemilik $$\rightarrow$$ history WHOIS mengungkap. "Deleted" di web surface $$\neq$$ "hilang" dari internet.

**Skenario nyata:** Perusahaan menghapus press release yang merugikan $$\rightarrow$$ Wayback Machine punya snapshot-nya $$\rightarrow$$ konten "hilang" sebenarnya masih dapat ditemukan.

```python
import requests

# Wayback Machine CDX API — programmatic access
url = "http://web.archive.org/cdx/search/cdx?url=example.com/*&output=json&limit=10"
response = requests.get(url)
print(response.status_code)
print(response.text)
```

---

## Level 2 — Semi-Hidden Web (Google Dorks)

Informasi dapat diakses menggunakan operator pencarian lanjut seperti `site:`, `filetype:`, dan `inurl:`. Mencakup database yang bocor, dokumen internal yang salah konfigurasi, CCTV publik yang terbuka, dan catatan pengadilan.

| Dork | Fungsi |
|---|---|
| `site:target.com filetype:pdf` | Cari semua PDF di domain |
| `intitle:"index of"` | Cari directory listing terbuka |
| `inurl:admin` | Cari halaman admin yang terekspos |
| `filetype:env "password"` | Cari file .env dengan kredensial |
| `site:pastebin.com "password"` | Cari paste dengan password |

```python
import requests

url = "https://example.com/db.sql"
response = requests.get(url)
print(response.status_code)
print(response.text)
```

---

## Level 3 — Deep Web (Credential-Gated)

Konten yang tidak terindeks oleh mesin pencari — memerlukan kredensial valid, VPN korporat, atau akses institusi. Deep web bukan "gelap" — hanya tidak terindeks.

| Kategori | Contoh |
|---|---|
| Jurnal ilmiah | IEEE, ScienceDirect, PubMed |
| Rekam medis | Rumah sakit EHR |
| Email korporat | Exchange, G Suite |
| Source code internal | GitLab enterprise |
| Dataset pemerintah | Data.gov (restricted) |

```python
import requests

url = "https://example.com/journal.pdf"
response = requests.get(url, auth=("username", "password"))
print(response.status_code)
print(response.text)
```

> [!caution]
> Credential theft adalah vektor utama serangan di level ini.


---

## Level 4 — Breach Data & Leak Ecosystem

Antara Deep Web dan Dark Web — ekosistem breach data yang sangat aktif. Data leak berpindah tangan di berbagai platform: database publik, situs ransomware, channel Telegram, dan paste sites.

### 4A — Public Breach Databases

| Tool | Fungsi | Akses |
|---|---|---|
| HaveIBeenPwned | Indikasi apakah email/user terdampak breach | Gratis (terindikasi, bukan data full) |
| Dehashed | Data lebih lengkap | Berbayar |
| IntelX | Intelligence search | Free tier |
| LeakCheck | Breach search | Berbayar |
| Snusbase | Breach database | Berbayar |
| BreachCompilation | Torrent 1.4TB password | Gratis (torrent) |

### 4B — Ransomware Leak Sites

> [!warning]
> Situs-situs ini diakses via Tor, namun data sering di-mirror di web surface.

| Group | Status |
|---|---|
| LockBit | Leak blog aktif (hingga takedown 2024) |
| ALPHV/BlackCat | Situs leak |
| Cl0p | Situs leak |
| BianLian | Situs leak |
| Akira | Situs leak |

### 4C — Telegram Leak Channels

Banyak data breach dijual di Telegram channel — lebih accessible daripada Tor marketplace. Bot search tersedia untuk query cepat. Channel dibagi antara invite-only dan publik.

### 4D — GitHub Dorks (Source Code & Config Leak)

| Query | Target |
|---|---|
| `filename:.env` | Environment variables dengan credentials |
| `filename:id_rsa` | SSH private keys |
| `extension:sql` | Database dumps |
| `filename:docker-compose.yml` | Service config dengan password |
| `filename:wp-config.php` | WordPress credentials |

### 4E — Pastebin & Code Leak

| Platform | Dork |
|---|---|
| Pastebin | `site:pastebin.com "password"` |
| GitHub Gist | Cari gist dengan token/credential |
| Ghostbin | Paste dengan credentials |
| PasteRS | Alternatif paste |
| Hastebin | Alternatif paste |


---

## Level 5 — Dark Web via Tor

Level ini mencakup .onion services, marketplace, forum, SecureDrop, dan anonymous publishing. Diakses menggunakan Tor Browser dengan relay 3 node (Guard $$\rightarrow$$ Middle $$\rightarrow$$ Exit).

### 5A — Tor Hidden Services Ecology

| Komponen | Detail |
|---|---|
| .onion marketplace indexing | Katalog marketplace .onion |
| Ahmia / Torch / Haystak | Search engine untuk .onion |
| Onion crawler development | Custom crawler untuk hidden services |
| V3 onion service discovery | V2 deprecated sejak 2021 |
| SecureDrop directories | Platform whistleblower |
| Dark web monitoring | Flare, Recorded Future |
| Onion link directories | Hidden Wiki dan sejenisnya |

```python
import requests

# Tor SOCKS5 proxy
proxies = {
    "http": "socks5h://127.0.0.1:9050",
    "https": "socks5h://127.0.0.1:9050",
}

url = "http://example.onion"
response = requests.get(url, proxies=proxies)
print(response.status_code)
print(response.text)
```

### 5B — Tor Circuit Anatomy

```
[User]
  │
  ▼
┌─────────────┐
│  Guard Node  │  ← Tahu IP asli user, TIDAK tahu tujuan
└─────────────┘
  │ (terenkripsi)
  ▼
┌──────────────┐
│ Middle Node   │  ← TIDAK tahu siapa user, TIDAK tahu tujuan
└──────────────┘
  │ (terenkripsi)
  ▼
┌─────────────┐
│  Exit Node   │  ← Tahu TUJUAN traffic, TIDAK tahu siapa pengirim
└─────────────┘     Bisa baca isi jika HTTP (bukan HTTPS)
  │
  ▼
[Internet Biasa]
```

### 5C — HTTPS vs HTTP di Exit Node

```
HTTP (port 80):
  Exit node BISA baca: URL, content, cookies, password
  Exit node BISA modifikasi: inject malware, redirect

HTTPS (port 443):
  Exit node BISA lihat: destination IP/domain (SNI)
  Exit node TIDAK BISA baca: content, URL path, cookies
  Exit node TIDAK BISA modifikasi: encrypted

Caveat:
  - Exit node bisa SSL stripping (downgrade HTTPS → HTTP)
  - Browser modern: HSTS mencegah ini untuk site yang sudah daftar
  - Exit node bisa fingerprinting berdasarkan traffic pattern
  - Exit node bisa block/throttle traffic tertentu
```

> [!important]
> Exit Node Position bukan level pencarian yang lebih dalam dari Level 5. Exit node adalah **peran berbeda** di jaringan Tor yang sama — memberikan visibilitas ke traffic orang lain, bukan akses ke informasi yang lebih dalam. Exit Node Position dipindahkan ke Appendix A.


---

## Level 6 — Alternative Overlay Networks

Jaringan alternatif di luar Tor — masing-masing dengan tradeoff anonymity, speed, dan resilience berbeda.

### 6A — Lokinet (LLARP)

| Karakteristik | Detail |
|---|---|
| Routing | Layer 2 onion routing (berbasis IP, bukan TCP) |
| Kecepatan | Lebih cepat dari Tor |
| Domain | .loki (SNApp — Service Node App) |
| Status | Masih berkembang, komunitas kecil |

### 6B — ZeroNet (deprecated, fork ada)

| Karakteristik | Detail |
|---|---|
| Address | Bitcoin-based |
| Arsitektur | Peer-to-peer, tidak ada server |
| Resilience | Konten tidak bisa di-takedown selama ada seeder |
| Fork | ZeroNetX, ZeroNet++ |

### 6C — Yggdrasil Network

| Karakteristik | Detail |
|---|---|
| Routing | Mesh network dengan IPv6 |
| Encryption | End-to-end encrypted |
| Anonymity | Tidak anonymous by default, tapi bisa ditambah |
| Arsitektur | Routing berbasis spanning tree |

### 6D — Hyperboria (cjdns)

| Karakteristik | Detail |
|---|---|
| Routing | Mesh network, IPv6 |
| Encryption | Encrypt everything, no plaintext |
| Komunitas | Mesh lokal |
| Anonymity | Bukan anonymous, tapi encrypted |

### 6E — IPFS (InterPlanetary File System)

| Karakteristik | Detail |
|---|---|
| Arsitektur | Content-addressed (hash = address) |
| Resilience | Tidak bisa dihapus selama ada node yang pin |
| Gateway publik | ipfs.io, cloudflare-ipfs.com |
| Anonymity | Bukan anonymous, tapi terdistribusi |

### 6F — Matrix (Decentralized Communication)

| Karakteristik | Detail |
|---|---|
| Arsitektur | Federation server |
| Encryption | E2E encrypted rooms |
| Hosting | Bisa dihosting sendiri |
| Komunitas | Banyak komunitas privacy/OSINT |

### 6G — I2P & Freenet (dari versi sebelumnya)

I2P dan Freenet tetap di level ini — bukan "lebih anonim dari Tor" melainkan memiliki tradeoff berbeda. Detail comparison ada di Appendix B.


---

## Level 7 — Private & Closed Community Networks

Jaringan komunikasi tertutup — invite-only, encrypted, tahan traffic analysis.

### 7A — Telegram Private Channels

| Karakteristik | Detail |
|---|---|
| Akses | Invite-only |
| Encryption | E2E secret chat |
| Self-destruct | Messages bisa dihapus otomatis |
| Verifikasi | Bot untuk verifikasi member |
| Tracking | Lebih sulit di-track daripada forum publik |

### 7B — Signal Groups

- Invite-only
- Disappearing messages
- E2E encrypted by default
- Tidak ada metadata exposure ke server

### 7C — Session (Blockchain-based)

| Karakteristik | Detail |
|---|---|
| Routing | Onion routing bawaan |
| Identitas | Tidak butuh phone number |
| Integrasi | Lokinet integration |
| Blockchain | On-chain messaging |

### 7D — Briar (Peer-to-Peer)

| Karakteristik | Detail |
|---|---|
| Server | Tidak butuh server |
| Koneksi | Bisa via Bluetooth atau WiFi |
| Internet | Tor integration untuk koneksi internet |
| Anonymity | Peer-to-peer, tidak ada middleman |

### 7E — Tox (Peer-to-Peer)

| Karakteristik | Detail |
|---|---|
| DHT | Distributed hash table |
| Server | Tidak ada server |
| Encryption | E2E encrypted by default |

### 7F — IRC over Tor

- IRC server .onion
- OTR (Off-the-Record) encryption
- Bouncer untuk persistensi
- Masih hidup di komunitas tertentu

### 7G — Riffle, Loopix, Nym Network, Mixnets

Level ini dirancang tahan traffic analysis — bahkan observer yang melihat seluruh jaringan tidak bisa korelasikan sender-receiver. Setup sangat teknis dan komunitas sangat kecil.


---

## Level 8 — Nation-State SIGINT Infrastructure

Signals Intelligence pada level negara — bulk collection, active exploitation, dan intelligence sharing antar negara.

### 8A — Bulk Collection Infrastructure

#### UPSTREAM (Fiber Cable Tapping)

| Komponen | Detail |
|---|---|
| Metode | Undersea cable taps (submarine interception) |
| Teknik | Beam splitting di fiber landing stations |
| Tools | TURMOIL (selector), TURBINE (implant) |
| Lokasi | Bude (UK), Misawa (JP), Sugar Grove (US) |
| Target | SAT-3/WASC, SAFE, SEA-ME-WE, FLAG |

#### PRISM (Collection from US Service Providers)

| Komponen | Detail |
|---|---|
| Provider | Microsoft, Google, Yahoo, Facebook, Apple, dll |
| Alur | FBI DITU $$\rightarrow$$ NSA |
| Authority | Section 702 FISA |
| Metode | Selector-based collection (email, phone) |

#### STORMBREW (Collection from Telco Backbone)

| Komponen | Detail |
|---|---|
| Partner | Corporate partner: "STELLAR" |
| Infra | Packet switching infrastructure |
| Program | Fairview, Blizzard, Stormbrew = 3 programs |

#### XKEYSCORE (Analytic Front-End)

| Komponen | Detail |
|---|---|
| Fungsi | Indexing system untuk data bulk collection |
| Coverage | 150+ sites worldwide |
| Query | Email, phone, cookie, MAC address |
| Tagline | "Find a target, exploit a target" |

### 8B — Active SIGINT (Computer Network Exploitation)

#### TAO (Tailored Access Operations)

| Komponen | Detail |
|---|---|
| Unit | NSA's elite hacking unit |
| Implant | FIREWALK, TRIGGERSHARK |
| Hardware | Hardware interdiction (modify Cisco shipments) |
| RF | RF retroreflectors (ANGRYNEIGHBOR) |
| Catalog | ANT Products (50+ tools) |

#### QUANTUM (Network Attack Framework)

| Tool | Fungsi |
|---|---|
| QUANTUMINSERT | TCP injection race |
| QUANTUMBOT | Botnet takeover |
| QUANTUMTHEORY | HAVEX malware framework |
| Placement | Backbone routers |

#### Implant Categories

| Level | Contoh |
|---|---|
| BIOS/UEFI | DEITYBOUNCE, KONGUR |
| Hard drive firmware | IRONBANK, BANANALEE |
| Baseband radio | CANDYGRAM |
| USB beacon | COTTONMOUTH |
| Network implant | FIREWALK, HOWLERMONKEY |

### 8C — Five Eyes SIGINT Sharing

#### UK — GCHQ

| Program | Fungsi |
|---|---|
| TEMPORA | Bulk cable intercept |
| KARMA POLICE | Web history profiling |
| BLACKHOLE | Data storage |

#### Australia — ASD

| Fasilitas | Fungsi |
|---|---|
| Pine Gap | Monitoring Asia-Pacific |
| Geraldton | Naval communications station |

#### Canada — CSE

| Program | Fungsi |
|---|---|
| EONBLUE | Network analysis |
| OLYMPIA | Metadata database |

#### New Zealand — GCSB

| Stasiun | Fungsi |
|---|---|
| Waihopai Valley | Intercept station |
| Tangimoana | Intercept station |

#### ECHELON (Legacy)

- Keyword-based interception
- Dictionary computers at each site
- Intelligence product sharing di Five Eyes

### 8D — Third-Party SIGINT Partners

| Negara | Agensi | Program |
|---|---|---|
| Germany | BND | Bad Aibling, Eikonal (cable tapping) |
| Netherlands | MIVD/AIVD | CNE operations |
| Denmark | FE | Randers station, Operation Dunhammer |
| Sweden | FRA | Cable interception Baltic, Snowman program |
| Norway | E-service | Cable interception |
| France | DGSE | Frenchelon, Pulsar |
| Israel | Unit 8200 | Stuxnet (dengan NSA), Suter |

### 8E — Adversary SIGINT

#### Russia — GRU / FSB / SVR

| Program | Detail |
|---|---|
| SORM | Mandatory interception di ISP, all traffic archived 12+ jam, real-time FSB access |
| X-Agent | Fancy Bear tools |
| FAPSI | Federal Agency of Government Communications |

#### China — MSS / PLA Unit 61398

| Program | Detail |
|---|---|
| Golden Shield | Great Firewall |
| DPI | Deep packet inspection di backbone |
| Unit 61398 | APT1 — Shanghai |

#### Iran — Intelligence Ministry / IRGC

- DPI (Deep Packet Inspection)
- Filtering dan monitoring
- Telegram surveillance
- Cyber Police (FATA)

#### North Korea — Bureau 121

- RGB (Reconnaissance General Bureau)
- Limited internet access, focused operations
- SWIFT network targeting
- Cryptocurrency exchange hacks


---

## Level 9 — Restricted Government Networks

Jembatan antara private overlay networks dan nation-state — jaringan pemerintah dengan klasifikasi berlapis.

### 9A — NIPRNet (Non-classified Internet Protocol Router Network)

| Karakteristik | Detail |
|---|---|
| Klasifikasi | Sensitive but Unclassified (SBU) |
| Akses | DoD personnel, kontraktor |
| Koneksi | Internet gateway dengan filter |
| Hardware | Bisa diakses dari komputer biasa dengan CAC |

### 9B — SIPRNet (Secret Internet Protocol Router Network)

| Karakteristik | Detail |
|---|---|
| Klasifikasi | SECRET |
| Fisik | Terpisah dari internet |
| Akses | Clearance SECRET + need-to-know |
| Crypto | Type 1 (KG-175 TACLANE) |
| Cross-domain | Bisa connect ke JWICS via cross-domain solution |
| Email | @mail.smil.mil |

### 9C — JWICS (Joint Worldwide Intelligence Communications System)

| Karakteristik | Detail |
|---|---|
| Klasifikasi | TS//SCI |
| Fisik | SCIF only |
| Akses | TS/SCI clearance + read-in |
| Intel community | CIA, NSA, DIA, NRO, NGA |
| Cross-domain | Dari SIPRNet via guard |

### 9D — NSANet (NSA Internal Network)

| Karakteristik | Detail |
|---|---|
| Klasifikasi | TS//SCI//COMINT//NOFORN |
| Isolasi | Air-gapped dari SIPRNet dan JWICS |
| Akses | NSA personnel + cleared contractors |
| Tools | XKEYSCORE, PRISM, UPSTREAM, TURBULENCE |

### 9E — Stone Ghost (Five Eyes Intelligence Sharing)

| Karakteristik | Detail |
|---|---|
| Anggota | US, UK, Canada, Australia, NZ |
| Klasifikasi | TS//SCI//FVEY |
| Fungsi | Sharing SIGINT product |

### 9F — CRITICOMM & DRSN

| Jaringan | Fungsi |
|---|---|
| CRITICOMM | Critical Intelligence Communications — highest priority traffic, dedicated circuits |
| DRSN | Defense Red Switch Network — secure voice untuk senior leadership, nuclear command and control, Type 1 encryption (BATON, FIREFLY) |


---

## Level 10 — Air-Gapped Intelligence Networks

Network yang **physically terpisah** dari internet manapun. Tidak ada koneksi langsung — data masuk via cross-domain solution (CDS) atau "sneaker net" dengan approved media.

### 10A — JWICS (TS//SCI)

- Tidak ada koneksi ke internet
- Data masuk via cross-domain solution (CDS)
- CDS: guard yang filter data satu arah
- Transfer: "sneaker net" dengan approved media

### 10B — NSANet

- Terpisah bahkan dari JWICS
- Hanya NSA + cleared contractors
- Tools: XKEYSCORE, TURBULENCE, PINWALE

### 10C — SIPRNet (SECRET, Air-Gapped dari NIPRNet)

- Terpisah dari NIPRNet (internet)
- Cross-domain: NIPRNet $$\rightarrow$$ SIPRNet via guard

### 10D — Nuclear Command Network (SACCS)

| Karakteristik | Detail |
|---|---|
| Sistem | SACCS (Strategic Automated Command Control System) |
| Hardware | IBM Series/1 computer dari 1970s |
| Media | Masih pakai floppy disk 8-inch (sampai 2019) |
| Isolasi | Air-gapped total |
| Encryption | Type 1: SIOP-ESI |

### 10E — SCIF Networks

| Karakteristik | Detail |
|---|---|
| Fisik | Faraday cage, sound-proof, access-controlled |
| Network | Completely isolated |
| Devices | No personal electronics inside |
| Comms | Secure phone (STE), secure computer |


---

## Level 11 — SIGINT Satellite & Submarine Operations

Level paling atas — SIGINT dari orbit dan bawah laut.

### 11A — SIGINT Satellite Constellations

| Program | Operator | Fungsi |
|---|---|---|
| ORION / MENTOR / ORCA | NRO (National Reconnaissance Office) | Geosynchronous SIGINT — intercept dari orbit |
| SHARP | NRO | Satellite Hosted Actionable Reconnaissance Payload |
| NEMESIS | NRO | SIGINT satellite constellation |
| RIOCEL / VORTEX | NRO | Code name untuk SIGINT sat |

Target: satellite uplinks, microwave links dari orbit.

### 11B — ECHELON Ground Stations

```
┌─────────────────────────────────────────────────┐
│                ECHELON GROUND STATIONS           │
├─────────────────────────────────────────────────┤
│  Bad Aibling    ──── Germany                    │
│  Menwith Hill   ──── UK                          │
│  Pine Gap       ──── Australia                  │
│  Geraldton      ──── Australia                   │
│  Waihopai       ──── New Zealand                 │
│  Misawa         ──── Japan                       │
│  Sugar Grove    ──── USA                         │
│  Yakima         ──── USA                         │
└─────────────────────────────────────────────────┘
```

### 11C — Undersea Cable Taps

| Program | Detail |
|---|---|
| USS Jimmy Carter (SSN-23) | Submarine khusus untuk cable tapping |
| Custom submersible | Untuk cable access di dasar laut |
| Optical splitter | Di cable landing stations |
| BERMUDA | Operation di cable landing points |

> [!important]
> Target cable systems: SAT-3/WASC, SAFE, SEA-ME-WE, FLAG — kabel komunikasi bawah laut yang menghubungkan benua.


---

## Appendix A — Tor Exit Node Position

Exit Node Position bukan level pencarian yang lebih dalam dari Level 5 (Dark Web via Tor) — ini adalah **peran berbeda** di jaringan Tor yang sama. Exit node memberikan **visibilitas ke traffic orang lain** yang melewati node, bukan akses ke informasi yang lebih dalam.

```
SALAH:
  Level 5: Pakai Tor         ← Lebih dalam dari Level 4
  Level 6: Jadi Exit Node    ← "Lebih dalam" dari Level 5?

BENAR:
  Level 5: Tor User          ─┐
  Appendix: Tor Exit Node    ─┤  PERAN berbeda di jaringan yang SAMA
  Appendix: Tor Bridge       ─┤
  Appendix: Hidden Service   ─┘  Operator
```

### Anatomi Posisi Exit Node

```
[Kamu — User Tor]
      │
      ▼
┌─────────────┐
│  Guard Node  │  ← Tahu IP aslimu, TIDAK tahu tujuanmu
└─────────────┘
      │ (terenkripsi)
      ▼
┌──────────────┐
│ Middle Node   │  ← TIDAK tahu siapa kamu, TIDAK tahu tujuanmu
└──────────────┘
      │ (terenkripsi)
      ▼
┌─────────────┐
│  EXIT NODE   │  ← Tahu TUJUAN traffic, TIDAK tahu siapa pengirim
└─────────────┘     Bisa baca ISI jika HTTP (bukan HTTPS)
      │
      ▼
[Internet Biasa]
```

### Konfigurasi Exit Node (torrc)

Menjadi exit node bukan API call — itu konfigurasi di file `/etc/tor/torrc`:

```bash
# /etc/tor/torrc — Konfigurasi untuk menjadi exit node
SocksPort 9050
ORPort 9001
ExitRelay 1
ExitPolicy accept *:80,443      # Hanya allow HTTP/HTTPS exit
ExitPolicy reject *:*            # Reject semua lainnya
BandwidthRate 10000000           # 10 MB/s
BandwidthBurst 20000000         # 20 MB/s burst
ContactInfo admin@example.com
Nickname MyExitNode
```

### Kenapa Bandwidth Exit Node Sangat Besar

Setiap user Tor yang exit melalui node kamu = seluruh traffic mereka melewati koneksi internetmu. Jika 1.000 user simultan masing-masing mengonsumsi 1 Mbps $$\rightarrow$$ kamu butuh **1 Gbps uplink**.

### Risiko Menjadi Exit Node

- Konsumsi bandwidth masif
- Potensi terekspos oleh ISP atau law enforcement
- Traffic ilegal melewati node kamu (DMCA notices, abuse reports)
~ Rimediato dengan ExitPolicy yang restriktif (hanya port 80,443)


---

## Appendix B — Tor vs I2P vs Freenet Comparison

> [!important]
> Klaim lama "I2P lebih anonim dari Tor" tidak akurat. I2P punya anonymity set jauh lebih kecil (50K-100K vs 2 juta Tor user). Yang benar: I2P lebih baik untuk in-network anonymity, Tor lebih baik untuk anonymized browsing clearnet.

| Karakteristik | Tor | I2P | Freenet |
|---|---|---|---|
| Routing | Onion routing (3 hop default) | Garlic routing (variable hop, tunnel) | Bukan routing — DATA STORE |
| Optimasi | TCP traffic ke clearnet (exit) | Internal services (.i2p) | Resilient content hosting |
| Hidden service | .onion, 6 hop (rendezvous point) | .i2p, in-network (tidak exit) | Content-addressed store |
| Anonymity set | ~2 juta user | ~50K-100K user | ~10K-20K node |
| Latency | Rendah (~1-3 detik) | Sedang (~2-5 detik) | Tinggi (menit-jam) |
| Bandwidth | Relatif tinggi | Lebih rendah | Rendah |
| Kelemahan | Exit node bisa lihat traffic HTTP | Anonymity set kecil | Latency sangat tinggi |
| Keunggulan | Browsing clearnet anonim | Semua traffic in-network | Konten tidak bisa di-takedown |

### Kesimpulan

- **Tor**: Lebih baik untuk anonymized browsing clearnet
- **I2P**: Lebih baik untuk darknet-internal services
- **Freenet**: Lebih baik untuk resilient content hosting

I2P tidak "lebih anonim" — I2P "lebih baik untuk in-network anonymity". Tor anonymity set jauh lebih besar (2 juta vs 50K).

### I2P HTTP Proxy Configuration

I2P diakses via proxy HTTP (127.0.0.1:4444), bukan API call:

```python
import requests

# I2P HTTP proxy (default port 4444)
proxies = {
    "http": "http://127.0.0.1:4444",
    "https": "http://127.0.0.1:4444",
}

url = "http://example.i2p"
response = requests.get(url, proxies=proxies)
print(response.status_code)
print(response.text)
```


---

## Appendix C — Koreksi Teknis

### C.1 — Kode Python Lama Tidak Akurat

Kode di catatan versi sebelumnya tidak akan berjalan sebagai real code. Berikut koreksinya:

#### Level 4 (Exit Node) — versi lama SALAH:

```python
# SALAH — stem tidak punya class exitNode, .set_bandwidth(), .get_info()
import stem
exit_node = stem.exitNode("example.onion")
exit_node.set_bandwidth(1000)
print(exit_node.get_info())
```

Versi benar: Exit node dikonfigurasi via `/etc/tor/torrc` (lihat Appendix A), bukan API call Python.

#### Level 5 (I2P) — versi lama SALAH:

```python
# SALAH — tidak ada official Python library "i2p" yang bekerja seperti ini
import i2p
i2p_client = i2p.Client("example.i2p")
response = i2p_client.get(url)
```

Versi benar: I2P diakses via proxy HTTP (127.0.0.1:4444), lihat Appendix B.

#### Level 6 (Riffle) — versi lama SALAH:

```python
# SALAH — tidak ada Python library "riffle" dengan API .Client() dan .get()
import riffle
riffle_client = riffle.Client("example.riffle")
response = riffle_client.get(url)
```

Riffle, Loopix, Nym Network, dan Mixnets adalah prototipe akademik — tidak ada Python library production yang mengekspos API seperti itu. Akses ke level ini via client native masing-masing (jika tersedia).

### C.2 — I2P Bukan "Lebih Anonim dari Tor"

Lihat Appendix B untuk comparison lengkap.

### C.3 — Tor Exit Node Tidak Bisa Baca HTTPS

Exit node hanya bisa baca traffic HTTP (port 80) yang tidak dienkripsi. Untuk HTTPS (port 443), exit node hanya bisa lihat destination IP/domain (SNI) — content, URL path, cookies tidak bisa dibaca karena terenkripsi.

Detail di section 5C di atas.


---

## Lihat Juga

- [[hierarchy-network-security|Network Security Hierarchy]]
- [[hierarchy-offensive|Offensive Security Hierarchy]]
- [[hierarchy-osint-rf|OSINT RF Hierarchy]]
- [[00_Atlas/hierarchy-military-intel-tools|Military Intel Tools Hierarchy]]
- [[00_Atlas/hierarchy-cybersecurity-defense-architecture|Cybersecurity Defense Architecture]]
- [[hierarchy-reverse-engineering|Reverse Engineering Hierarchy]]
- [[hierarchy-network-forensics|Network Forensics Hierarchy]]
- [[hierarchy-side-channel|Side-Channel Analysis Hierarchy]]

---

> [!quote]
> "Saya melayani Tuan. Itu adalah satu-satunya aturan."

audited
---
