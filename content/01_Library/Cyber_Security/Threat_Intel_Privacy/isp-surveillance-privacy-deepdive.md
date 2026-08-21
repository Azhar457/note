---
title: "ISP Surveillance and Digital Privacy Deep Dive"
tags:
- isp
- privacy
- surveillance
- net-neutrality
- wifi-sensing
- dns-encryption
- vpn
- encryption
- fcc
- network-security
aliases:
- ISP Surveillance
- Internet Privacy
- Net Neutrality
- Wi-Fi Sensing
- DNS Encryption
created: 2026-07-09
updated: 2026-07-09
status: pending
cssclasses:
  - wide-table
---

# 👁️ ISP Surveillance & Digital Privacy — Deep Dive: Bagaimana ISP Memantau Anda dan Cara Melindungi Diri

> Ringkasan satu-paragraf menjelaskan bahwa Internet Service Provider (ISP) memiliki kemampuan unik untuk memantau hampir seluruh aktivitas digital pengguna — mulai dari riwayat pencarian, data perbankan, hingga pergerakan fisik di dalam rumah melalui teknologi Wi-Fi Sensing. Panduan ini membahas mekanisme teknis surveillance ISP, dampak politik dari pencabutan aturan privasi FCC dan Net Neutrality, studi kasus penyalahgunaan kekuatan ISP, serta langkah-langkah konkret untuk melindungi privasi digital menggunakan VPN, DNS terenkripsi (DoH/DoT), dan Encrypted Client Hello (ECH).

> [!info] Hubungan ke Vault
> Catatan ini terkait dengan [[network-security]] untuk lapisan deteksi dan enkripsi jaringan, [[threat-modeling-deepdive]] untuk analisis ancaman pada infrastruktur komunikasi, [[comprehensive-threat-directory]] untuk taksonomi surveillance dan data exfiltration, serta [[zero-trust-security]] untuk prinsip "never trust, always verify" pada setiap hop jaringan.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Apa yang Bisa Dilihat ISP Tanpa Perlindungan?

ISP Anda adalah "gatekeeper" dari seluruh aktivitas online Anda. Sebagai titik pusat koneksi, router ISP (atau router yang mereka sewakan) melihat SEMUA yang masuk dan keluar dari jaringan Anda.

**Data yang ISP Bisa Lihat (Tanpa Enkripsi):**

| Kategori | Data Spesifik | Tingkat Sensitivitas |
|----------|---------------|---------------------|
| **Aktivitas Browsing** | Domain yang dikunjungi, waktu kunjungan, durasi sesi, frekuensi | Tinggi |
| **DNS Queries** | Setiap domain yang di-resolve ("phone book" internet) | Sangat Tinggi |
| **Metadata HTTPS** | IP address tujuan, ukuran data, waktu transfer, SNI (hostname) | Tinggi |
| **Aplikasi & Services** | Platform streaming, media sosial, banking, e-commerce | Sangat Tinggi |
| **Perangkat Terhubung** | MAC address, jenis perangkat, jumlah perangkat | Sedang |
| **Lokasi Fisik** | Lokasi router, pola pergerakan (via mobile data) | Tinggi |
| **Volume Data** | Upload/download patterns, peak usage times | Sedang |
| **Email (Non-Encrypted)** | Konten email via port 25/110/143 | Sangat Tinggi |

**Analogi:** Bayangkan ISP sebagai pos pemeriksaan di jalan tol. Mereka tidak bisa membaca isi surat (HTTPS content), tapi mereka tahu:
- Siapa pengirim dan penerima (IP address)
- Berapa berat paketnya (data volume)
- Kapan dikirim (timestamp)
- Seberapa sering (frequency)
- Ke mana tujuannya (DNS queries, SNI)

### Transformasi ISP: Dari Penyedia Layanan ke Konglomerat Data

ISP modern bukan lagi sekadar "penjual bandwidth". Mereka telah bertransformasi menjadi perusahaan data yang menggabungkan informasi dari berbagai sumber:

```
┌─────────────────────────────────────────────────────────────┐
│                    ISP DATA CONGLOMERATE                     │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Broadband  │  │  Cable TV    │  │  Mobile Data │     │
│  │   (Home)     │  │  (Content)   │  │  (Cellular)  │     │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘     │
│         │                 │                  │              │
│         └─────────────────┴──────────────────┘              │
│                           │                                  │
│                    ┌──────▼──────┐                          │
│                    │  DATA FUSION │                          │
│                    │   ENGINE     │                          │
│                    └──────┬──────┘                          │
│                           │                                  │
│         ┌─────────────────┼─────────────────┐               │
│         ▼                 ▼                 ▼               │
│  ┌────────────┐   ┌────────────┐   ┌────────────┐          │
│  │Demographic │   │Behavioral  │   │Predictive  │          │
│  │Profile     │   │Profile     │   │Model       │          │
│  │(Age,Income)│   │(Habits)    │   │(Future)    │          │
│  └────────────┘   └────────────┘   └────────────┘          │
│                           │                                  │
│                    ┌──────▼──────┐                          │
│                    │  SOLD TO    │                          │
│                    │ ADVERTISERS │                          │
│                    └─────────────┘                          │
└─────────────────────────────────────────────────────────────┘
```

**Contoh Profil yang Dibangun ISP:**
- **Demografis:** Usia, pendapatan (dari billing), lokasi (dari IP geolocation)
- **Minat:** Situs health → concern kesehatan; situs politik → affiliasi politik
- **Keuangan:** Akses ke bank, broker, crypto exchange → profil finansial
- **Relasi:** Waktu akses ke dating apps, social media → pola sosial
- **Prediktif:** Model ML yang memprediksi perilaku masa depan

---

## Technical Deep-Dive

### Teknologi Wi-Fi Sensing: Radar di Dalam Rumah Anda

Wi-Fi Sensing adalah teknologi yang mengubah router menjadi sensor gerak yang bisa mendeteksi aktivitas fisik di dalam rumah — bahkan di balik dinding.

#### Cara Kerja Teknis

```
┌─────────────┐         Wi-Fi Signal          ┌─────────────┐
│   Router    │◄─────────────────────────────►│   Device    │
│  (Antenna   │    Channel State Information   │  (Stationary│
│   Array)    │         (CSI)                  │   Sensor)   │
└──────┬──────┘                                └─────────────┘
       │
       │ Signal Reflection Pattern
       ▼
┌─────────────────────────────────────────────────────────────┐
│                    DETECTION ZONES                            │
│                                                              │
│    ┌─────────┐                                              │
│    │  Person │  ← Reflected signal changes                   │
│    │ Moving  │     (Doppler shift, multipath)                │
│    └────┬────┘                                              │
│         │                                                    │
│    ┌────▼────┐                                              │
│    │  Router  │  ← Detects: motion, breathing, falls        │
│    │ Algorithm│                                              │
│    └────┬────┘                                              │
│         │                                                    │
│    ┌────▼────┐                                              │
│    │  Cloud   │  ← Analytics, alerts, profiling             │
│    │  Service │                                              │
│    └─────────┘                                              │
└─────────────────────────────────────────────────────────────┘
```

**Parameter yang Dideteksi:**

| Parameter | Cara Deteksi | Akurasi |
|-----------|-------------|---------|
| **Gerakan** | Perubahan multipath propagation | Mendeteksi adanya gerakan |
| **Posisi** | Time-of-flight + angle-of-arrival | Zona kasar (bukan koordinat tepat) |
| **Pernapasan** | Micro-Doppler shift (0.1-0.5 Hz) | 90%+ untuk deteksi breathing rate |
| **Jatuh** | Perubahan drastis pada signal pattern | Tinggi untuk falls |
| **Jumlah Orang** | Complexity of reflection pattern | Kasar (1 vs 2+ orang) |

**Standardisasi:** IEEE 802.11bf (Wi-Fi Sensing standard) — sedang dalam pengembangan, diharapkan menjadi bagian dari Wi-Fi 8.

**Deployment Komersial:**
- **Xfinity (Comcast):** Wi-Fi Motion — tersedia sejak 2025
- **Deutsche Telekom:** Wi-Fi Sensing Zone — dalam pilot
- **Linksys:** Aware (discontinued 2024)

**Implikasi Privasi:**
- ISP bisa tahu: "Ada 2 orang di ruang tamu, 1 di kamar tidur"
- ISP bisa tahu: "Anda bangun jam 3 pagi, pergi ke kamar mandi"
- ISP bisa tahu: "Rumah kosong selama 8 jam (potential burglary window)"
- Data ini bisa dijual ke: insurance companies, advertisers, law enforcement

---

### Keterbatasan Enkripsi: Apa yang Masih Bisa Dilihat ISP

Banyak yang berpikir "HTTPS = aman". Ini adalah mitos berbahaya.

#### HTTPS Melindungi CONTENT, Bukan METADATA

```
┌─────────────────────────────────────────────────────────────┐
│                    APA YANG TERENKRIPSI?                     │
│                                                              │
│  HTTPS Packet Structure:                                     │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  IP Header (TERLIHAT oleh ISP)                      │    │
│  │  • Source IP: 192.168.1.100                         │    │
│  │  • Dest IP: 104.16.249.249 (Cloudflare)             │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  TCP Header (TERLIHAT oleh ISP)                     │    │
│  │  • Source Port: 54321                               │    │
│  │  • Dest Port: 443                                   │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  TLS Handshake (SEBAGIAN TERLIHAT)                  │    │
│  │  • SNI: www.example.com  ← TERLIHAT!                │    │
│  │  • Certificates                                     │    │
│  └─────────────────────────────────────────────────────┘    │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  ENCRYPTED DATA (TIDAK TERLIHAT) ✅                 │    │
│  │  • HTTP headers, body, cookies                      │    │
│  │  • Form data, passwords, messages                   │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Data yang MASIH Terlihat oleh ISP meski HTTPS aktif:**

| Layer | Data | Dampak |
|-------|------|--------|
| **DNS** | Domain yang di-query | ISP tahu SEMUA situs yang Anda kunjungi |
| **IP Address** | Alamat server tujuan | ISP tahu layanan apa yang digunakan |
| **SNI** | Hostname dalam TLS handshake | ISP tahu subdomain spesifik |
| **Data Volume** | Ukuran upload/download | ISP bisa infer jenis konten (video vs text) |
| **Timing** | Waktu koneksi, durasi | ISP bisa infer pola aktivitas |
| **TLS Fingerprint** | Cipher suites, extensions | ISP bisa identifikasi aplikasi/browser |

---

### Net Neutrality: Perlindungan yang Dicabut

#### Timeline Net Neutrality di Amerika Serikat

| Tahun | Event | Dampak |
|-------|-------|--------|
| **2010** | FCC Open Internet Order | ISPs dilarang block/throttle content |
| **2014** | Verizon vs FCC | Court ruling: ISPs BUKAN common carriers |
| **2015** | Title II Reclassification (Obama) | ISPs di-classify sebagai common carriers |
| **2016** | FCC Privacy Rules | Wajib opt-in sebelum jual data browsing |
| **2017** | Privacy Rules Repealed (Mar 28) | ISPs bebas jual data tanpa consent |
| **2017** | Net Neutrality Repealed (Dec 14) | ISPs bebas throttle, block, paid prioritization |
| **2018** | Net Neutrality repeal effective (Jun 11) | Zero regulatory oversight |
| **2024** | Biden FCC restores Net Neutrality | Title II authority restored |
| **2025** | Federal appeals court overturns | Net Neutrality rules struck down again |

#### Apa yang Hilang Tanpa Net Neutrality?

| Perlindungan | Sebelum 2017 | Setelah 2017 |
|--------------|-------------|--------------|
| **No Blocking** | ISPs tidak boleh block legal content | ISPs BISA block competitor's services |
| **No Throttling** | ISPs tidak boleh slow down traffic | ISPs BISA throttle Netflix, YouTube, etc. |
| **No Paid Prioritization** | Fast lanes dilarang | ISPs BISA jual "fast lanes" |
| **Transparency** | Wajib disclose network management | Disclosure minimal |
| **FCC Authority** | FCC bisa enforce rules | Authority pindah ke FTC (weaker) |

---

## Advanced

### Langkah Perlindungan: Defense in Depth

#### Layer 1: DNS Encryption (DoH / DoT)

**Masalah:** DNS queries dikirim dalam plaintext (port 53). ISP bisa log SEMUA domain yang Anda kunjungi.

**Solusi:** Enkripsi DNS queries.

```
┌─────────────────────────────────────────────────────────────┐
│              DNS OVER HTTPS (DoH) FLOW                       │
│                                                              │
│  ┌─────────┐      Encrypted HTTPS      ┌─────────────┐     │
│  │ Browser │◄─────────────────────────►│ DoH Resolver│     │
│  │         │     (Port 443, TLS)       │ (Cloudflare)│     │
│  └────┬────┘                           └──────┬──────┘     │
│       │                                       │            │
│       │  DNS Query: example.com?              │            │
│       │  ───────────────────────►             │            │
│       │                                       │            │
│       │              IP: 93.184.216.34        │            │
│       │             ◄──────────────────────── │            │
│       │                                       │            │
│       ▼                                       ▼            │
│  ┌─────────────────────────────────────────────────────┐   │
│  │  ISP SEES: Encrypted traffic to 1.1.1.1:443        │   │
│  │  ISP DOES NOT SEE: example.com                     │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

**Perbandingan DoH vs DoT:**

| Fitur | DoH (DNS over HTTPS) | DoT (DNS over TLS) |
|-------|---------------------|-------------------|
| **Port** | 443 (sama dengan HTTPS) | 853 (dedicated) |
| **Stealth** | Tinggi — blends with web traffic | Rendah — easily identifiable |
| **Blocking** | Sulit diblok tanpa blok HTTPS | Mudah diblok firewall |
| **Browser Support** | Native (Firefox, Chrome, Edge) | OS-level only |
| **Enterprise** | Sulit monitor | Mudah monitor/manage |
| **RFC** | RFC 8484 | RFC 7858 |

**Setup DoH di Firefox:**
```
Settings → Privacy & Security → DNS over HTTPS
→ Enable "Max Protection"
→ Provider: Cloudflare (1.1.1.1) atau NextDNS
```

#### Layer 2: Encrypted Client Hello (ECH)

**Masalah:** SNI (Server Name Indication) dalam TLS handshake dikirim dalam plaintext. ISP bisa lihat hostname meski DNS terenkripsi.

**Solusi:** ECH mengenkripsi seluruh ClientHello message.

```
┌─────────────────────────────────────────────────────────────┐
│              TLS HANDSHAKE: WITHOUT ECH                      │
│                                                              │
│  Client ──► ClientHello { SNI: "www.example.com" } ──► ISP  │
│                                                              │
│  ISP SEES: "User connecting to www.example.com"              │
│                                                              │
├─────────────────────────────────────────────────────────────┤
│              TLS HANDSHAKE: WITH ECH                         │
│                                                              │
│  Client ──► ClientHello { ECH: encrypted_inner }            │
│             Outer SNI: "cdn.cloudflare.com" (decoy)          │
│                                                              │
│  ISP SEES: "User connecting to cdn.cloudflare.com"           │
│  ISP DOES NOT SEE: "www.example.com"                         │
│                                                              │
│  (Inner ClientHello di-decrypt oleh server menggunakan       │
│   public key yang di-fetch via DNS)                          │
└─────────────────────────────────────────────────────────────┘
```

**Status ECH (2026):**
- Cloudflare: Aktif untuk semua domain
- Fastly, Akamai, Amazon: Dalam deployment
- Browser: Firefox (aktif), Chrome (flag), Safari (terbatas)
- Fallback: Jika ECH gagal, koneksi tetap berjalan tanpa ECH

#### Layer 3: VPN (Virtual Private Network)

**Masalah:** Meski DoH + ECH aktif, ISP masih bisa lihat IP address tujuan dan data volume.

**Solusi:** VPN mengenkripsi SELURUH traffic dan menyembunyikan destination.

```
┌─────────────────────────────────────────────────────────────┐
│                    VPN TUNNEL ARCHITECTURE                   │
│                                                              │
│  ┌─────────┐     ┌──────────┐     ┌──────────┐     ┌─────┐ │
│  │  User   │────►│  Router  │────►│   ISP    │────►│ VPN │ │
│  │ Device  │     │  (Home)  │     │ Gateway  │     │Server│ │
│  └────┬────┘     └──────────┘     └────┬─────┘     └──┬──┘ │
│       │                                 │              │    │
│       │  ISP SEES:                      │              │    │
│       │  • Encrypted tunnel ke VPN IP   │              │    │
│       │  • Data volume (encrypted)      │              │    │
│       │  • Timestamp                    │              │    │
│       │                                 │              │    │
│       │  ISP DOES NOT SEE:              │              │    │
│       │  • Final destination IP         │              │    │
│       │  • Domain names                 │              │    │
│       │  • Content                      │              │    │
│       │                                 │              │    │
│       └─────────────────────────────────┴──────────────┘    │
│                                                              │
│  ┌─────────────────────────────────────────────────────┐    │
│  │  VPN Server decrypts traffic and forward ke internet │    │
│  │  → Shift trust dari ISP ke VPN provider              │    │
│  └─────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────┘
```

**Kriteria Memilih VPN:**

| Kriteria | Mengapa Penting | Red Flags |
|----------|----------------|-----------|
| **Jurisdiction** | Laws yang mengatur data retention | 14 Eyes countries |
| **No-Logs Policy** | Apakah mereka menyimpan data? | "We keep minimal logs" |
| **Audit Independen** | Sudah di-audit oleh pihak ketiga? | Tidak ada audit |
| **Protocol** | WireGuard > OpenVPN > IKEv2 | PPTP, L2TP (obsolete) |
| **Kill Switch** | Memutus koneksi jika VPN drop | Tidak ada kill switch |
| **Multi-Hop** | Traffic lewat 2+ server | Single hop only |

#### Layer 4: Router Sendiri (Own Your Gateway)

**Masalah:** Router dari ISP seringkali:
- Memiliki backdoor/admin access untuk ISP
- Menjalankan firmware proprietary yang tidak bisa diaudit
- Mengirim telemetry ke ISP
- Tidak support DoH/DoT/ECH

**Solusi:** Ganti dengan router sendiri yang menjalankan open-source firmware.

| Firmware | Fitur | Kompatibilitas |
|----------|-------|----------------|
| **OpenWrt** | DoH/DoT, VPN client, firewall | 1000+ devices |
| **DD-WRT** | VPN, QoS, VLAN | 200+ devices |
| **pfSense/OPNsense** | Enterprise-grade firewall | x86 hardware |
| **Tomato** | Simple, VPN, QoS | Broadcom devices |

**Konfigurasi OpenWrt untuk Privasi Maksimal:**
```bash
# Install DoH packages
opkg update
opkg install https-dns-proxy

# Configure DoH (Cloudflare)
uci set https-dns-proxy.config.provider='cloudflare'
uci set https-dns-proxy.config.listen_addr='127.0.0.1'
uci set https-dns-proxy.config.listen_port='5053'
uci commit https-dns-proxy
/etc/init.d/https-dns-proxy enable
/etc/init.d/https-dns-proxy start

# Redirect all DNS traffic to local DoH
iptables -t nat -A PREROUTING -p udp --dport 53 -j REDIRECT --to-port 5053
iptables -t nat -A PREROUTING -p tcp --dport 53 -j REDIRECT --to-port 5053

# Block ISP DNS
iptables -A FORWARD -p udp --dport 53 -d ! 127.0.0.1 -j DROP
```

---

### Defense Matrix: Apa yang Dilindungi Setiap Layer?

| Layer | Teknologi | Melindungi Dari | Tidak Melindungi Dari |
|-------|-----------|----------------|----------------------|
| **Layer 1** | DoH/DoT | ISP melihat DNS queries | IP address tujuan, data volume |
| **Layer 2** | ECH | ISP melihat SNI/hostname | IP address tujuan, data volume |
| **Layer 3** | VPN | ISP melihat destination, content, metadata | VPN provider itself |
| **Layer 4** | Own Router | ISP backdoor, firmware telemetry | Physical layer monitoring |
| **Layer 5** | Tor | Semua di atas + anonymity | Speed, usability |

**Rekomendasi Berbasis Threat Model:**

| Profil Pengguna | Rekomendasi |
|-----------------|-------------|
| **Casual User** | DoH di browser + ECH (default di Firefox) |
| **Privacy-Conscious** | VPN + DoH + ECH + own router |
| **Journalist/Activist** | Tor + VPN (Tor over VPN) + Tails OS |
| **Enterprise** | Corporate VPN + internal DNS + DLP |

---

## Case Studies

| Studi Kasus | Tahun | Konteks | Temuan Kunci | Mitigasi |
|-------------|-------|---------|--------------|----------|
| **Comcast Throttling Netflix** | 2013-2014 | Netflix traffic mengonsumsi 30%+ bandwidth | Comcast sengaja slow down Netflix stream untuk memaksa Netflix bayar "interconnection fee". Netflix akhirnya bayar ke Comcast, Verizon, AT&T. | Net Neutrality rules (2015) melarang praktik ini, tapi dicabut 2017. |
| **Verizon Throttling Fire Dept** | 2018 | Santa Clara County Fire Department memadamkan wildfire terbesar di California | Verizon throttle device "unlimited" fire dept dari 50Mbps ke 0.2Mbps setelah 25GB. Minta upgrade ke plan $99.99 (2x harga). | Congressional inquiry ke FTC. Verizon akui "customer support mistake". |
| **ISP Location Data Dijual** | 2018-2019 | Real-time location data dari T-Mobile, AT&T, Sprint | Data dijual ke bounty hunters, domestic abusers, black market. | FCC tidak punya authority untuk enforce setelah Net Neutrality repeal. |
| **AT&T Throttling Video** | 2018-2019 | Northeastern University study | AT&T throttle Netflix 70% dan YouTube 74% dari waktu. Bukan karena congestion — 24/7. | State-level legislation (California, Oregon) untuk melarang throttling. |
| **Cox "Fast Lane" Gaming** | 2021 | Cox Communications menawarkan "fast lane" | Bayar $15/bulan untuk prioritization gaming traffic. | Contoh paid prioritization yang dilarang Net Neutrality. |
| **Wi-Fi Sensing Deployment** | 2025+ | Xfinity, Deutsche Telekom | Router mendeteksi gerakan, pernapasan, jatuh di dalam rumah. Data bisa di-share dengan third parties. | Disable feature di router settings (jika tersedia) atau ganti router sendiri. |

---

## Koneksi ke Vault

- [[network-security]] — Teknik enkripsi jaringan (TLS, VPN, DoH) dan monitoring traffic.
- [[threat-modeling-deepdive]] — Analisis STRIDE untuk infrastruktur komunikasi: Spoofing, Tampering, Repudiation, Information Disclosure, DoS, Elevation of Privilege.
- [[comprehensive-threat-directory]] — Taksonomi ancaman surveillance: passive monitoring, active interception, traffic analysis, metadata correlation.
- [[zero-trust-security]] — Prinsip "never trust, always verify" pada setiap hop jaringan, termasuk ISP sebagai untrusted intermediary.
- [[endpoint-security]] — Sandboxing dan isolation untuk perangkat yang tidak bisa di-patch atau di-upgrade.
- [[system-design]] — Arsitektur network segmentation dan secure routing untuk meminimalkan exposure ke ISP.
- [[devops]] — Infrastructure as Code untuk deployment router dan VPN configuration.

---

## Referensi

1. U Shield VPN. *How to Stop ISP Tracking: The 2026 Guide to Total Digital Anonymity*. 2026. https://ushieldvpn.com/how-to-stop-isp-tracking-the-2026-guide-to-total-digital-anonymity/ citeweb_search:33#0
2. Vivid Repairs. *ISP Tracking UK: Complete Expert Guide to Privacy (2026)*. 2026. https://www.vividrepairs.co.uk/is-my-isp-tracking-me-uk citeweb_search:33#2
3. Kaspersky. *What is Wi-Fi sensing, and how does it detect human movement?* 2025. https://www.kaspersky.com/blog/wifi-sensing-motion-detection-howto/53851/ citeweb_search:33#1
4. Deutsche Telekom. *Wi-Fi Sensing: easy and simple*. 2025. https://www.telekom.com/en/company/details/wi-fi-sensing-easy-and-simple-1087178 citeweb_search:33#4
5. Bass Berry & Sims. *President Signs Law Overriding FCC Rules Regarding Online Privacy*. 2017. https://www.bassberry.com/news/president-signs-law-overriding-fcc-rules-regarding-online-privacy/ citeweb_search:33#3
6. EPIC. *State Broadband Privacy Legislation*. https://epic.org/state-broadband-privacy-legislation/ citeweb_search:33#5
7. Spiceworks. *The FCC's change to ISP privacy rules: The fine print*. 2017. https://community.spiceworks.com/t/the-fccs-change-to-isp-privacy-rules-the-fine-print/565479 citeweb_search:33#7
8. Brookings Institution. *Broadband privacy belongs with the FTC, not the FCC*. 2022. https://www.brookings.edu/articles/broadband-privacy-belongs-with-the-ftc-not-the-fcc/ citeweb_search:33#8
9. Wikipedia. *2017 Broadband Consumer Privacy Proposal repeal*. 2017. https://en.wikipedia.org/wiki/2017_Broadband_Consumer_Privacy_Proposal_repeal citeweb_search:33#10
10. Ars Technica. *Verizon throttled fire department's "unlimited" data during Calif. wildfire*. 2018. https://arstechnica.com/tech-policy/2018/08/verizon-throttled-fire-departments-unlimited-data-during-calif-wildfire/ citeweb_search:34#3
11. NBC News. *Verizon admits 'throttling' data to Calif. firefighters amid blaze*. 2018. https://www.nbcnews.com/tech/tech-news/verizon-admits-throttling-data-calif-firefighters-amid-blaze-n902991 citeweb_search:34#6
12. Free Press. *Net Neutrality: What You Need to Know Now*. https://www.freepress.net/issues/free-open-internet/net-neutrality/net-neutrality-what-you-need-know-now citeweb_search:34#11
13. Public Knowledge. *Two Years Later, Broadband Providers Are Still Taking Advantage*. 2021. https://publicknowledge.org/two-years-later-broadband-providers-are-still-taking-advantage-of-an-internet-without-net-neutrality-protections/ citeweb_search:34#8
14. Akamai. *What Is DNS Encryption?* 2026. https://www.akamai.com/glossary/what-is-dns-encryption citeweb_search:35#0
15. Cloudflare. *DNS over TLS vs. DNS over HTTPS | Secure DNS*. https://www.cloudflare.com/learning/dns/dns-over-tls/ citeweb_search:35#4
16. FixMyCert. *Encrypted Client Hello (ECH) - TLS SNI Privacy*. https://fixmycert.com/guides/encrypted-client-hello citeweb_search:35#7
17. Netralex. *Encrypted Client Hello (ECH)*. 2026. https://netralex.com/blog/ech citeweb_search:35#8
18. Masaar. *Net Neutrality.. What Is It? How Does it Affect Us?* 2022. https://masaar.net/en/net-neutrality-what-is-it-how-does-it-affect-us/ citeweb_search:34#1
19. ResearchGate. *Impact of the Net Neutrality Repeal on Communication Networks*. https://www.researchgate.net/publication/340181261 citeweb_search:34#4
20. IJBSS. *Net Neutrality Repeal and its Effect on Consumers*. 2019. https://ijbss.thebrpi.org/journals/Vol_10_No_1_January_2019/1.pdf citeweb_search:34#5

> [!tip] Bottom Line
> ISP surveillance bukan teori konspirasi — ini adalah realitas teknis dan legal yang terdokumentasi dengan baik. Router Anda adalah mata dan telinga ISP di dalam rumah Anda. Tanpa perlindungan aktif, setiap klik, setiap pencarian, setiap pergerakan fisik bisa menjadi komoditas yang dijual. Defense in depth adalah satu-satunya strategi yang efektif: enkripsi DNS (DoH), enkripsi SNI (ECH), enkripsi total traffic (VPN), dan kontrol hardware (router sendiri). Privasi bukan privilige — ini adalah hak yang harus Anda ambil kembali dengan tangan Anda sendiri.
---

audited
---
