---
title: Shodan
tags:
- 01-osint-and-reconnaissance
- library
- military-and-intelligence-tools
created: '2026-06-27'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  

---

> [!warning] Konteks Etis & Legal
> Shodan mengindeks data yang tersedia secara publik di internet. Tidak ada hacking, tidak ada bypass otentikasi, tidak ada interaksi yang merusak. Semua informasi yang dikembalikan adalah hasil dari **banner grabbing pasif** atau **handshake protokol standar**. Namun, apa yang bisa dilakukan dengan data itu sangat bergantung pada niat. Pembahasan ini sepenuhnya **defensif** dan bertujuan agar defender bisa melihat asetnya sendiri sebagaimana penyerang melihatnya.

---

## 🧬 Apa Itu Shodan Secara Teknis?

Shodan bukan crawler halaman web. Ia adalah **port scanner terdistribusi** yang terus menerus memindai seluruh rentang IPv4 (dan sebagian IPv6) pada port-port yang telah ditentukan. Untuk setiap IP:port yang merespons, Shodan mengirimkan permintaan protokol standar — seperti HTTP GET, TLS ClientHello, atau banner request — dan menyimpan balasannya. Seluruh basis data ini bisa dicari dengan **query syntax yang ekspresif**.

### Arsitektur Pemindaian

```
┌─────────────────────────────────────────────────────┐
│                Shodan Scanner Cluster                │
│  (Distributed globally, IP block dialokasikan)       │
└──────────────────────────┬──────────────────────────┘
                           │
          ┌────────────────┼────────────────┐
          ▼                ▼                ▼
   [TCP SYN]          [HTTP GET]      [TLS ClientHello]
          │                │                │
          ▼                ▼                ▼
[IP:22]   Banner    [IP:80/443]     [IP:443] Sertifikat TLS,
"SSH-2.0-OpenSSH_8.1" Server: Apache   issuer, CN, SANs,
                        <title>...</title> cipher suite
                           │
                           ▼
                  ┌────────────────────────┐
                  │  Elasticsearch Cluster │
                  │  (Metadata + Fulltext) │
                  └────────────────────────┘
                           │
                           ▼
                  [Web UI / API / CLI]
```

- Pemindaian dilakukan 24/7, dengan interval beberapa hari hingga minggu tergantung port dan populasi IP.
- Port yang dipindai: sekitar 300 port umum (21, 22, 23, 25, 80, 110, 443, 3306, 3389, 8080, 9200, 11211, 27017, dll.) plus ribuan port langka untuk menemukan layanan spesifik (misal: port 47808 untuk BACnet, 19132 untuk Minecraft Bedrock).
- Banner yang dikumpulkan: header HTTP, handshake TLS/SSL, banner SSH, respons SMTP, banner FTP, respons SIP, jawaban protokol ICS (Modbus, DNP3, BACnet), SNMP, UPnP, bahkan screenshot VNC jika diaktifkan.

### Komponen Data per Layanan

| Komponen | Deskripsi | Contoh |
|----------|-----------|--------|
| **IP & Port** | Alamat dan port terbuka | 203.0.113.45:443 |
| **Transport Protocol** | TCP atau UDP | TCP |
| **Banner / Response** | Data mentah dari aplikasi | `HTTP/1.1 200 OK\nServer: nginx/1.18.0` |
| **Metadata Parsed** | Informasi terstruktur hasil parsing banner | `product:nginx`, `version:1.18.0` |
| **HTTP Title** | Teks dalam `<title>` HTML | `"Login - Cisco Router"` |
| **HTTP Headers** | Seluruh header respons | `X-Powered-By: PHP/7.4.3` |
| **SSL Certificate** | Rantai sertifikat lengkap, issuer, validity | Issuer: `Let's Encrypt`, SAN: `*.example.com` |
| **Location** | Estimasi geografis dari MaxMind GeoIP | Country: ID, City: Jakarta |
| **ISP / Organization** | Pemilik alamat IP | Org: Telkom Indonesia |
| **OS (via CPython/Nmap sig)** | Tebakan sistem operasi dari fingerprinter | `OS: Linux 3.x` |
| **Timestamp** | Kapan terakhir dipindai | `2026-06-27T12:00:00Z` |

Semua ini diindeks dan bisa dicari dengan filter spesifik.

---

## 🔍 Query Shodan: Bahasa Interogasi Seluruh Internet

Query Shodan bukan sekadar kata kunci, melainkan ekosistem filter yang presisi. Daftar filter paling kritikal:

| Filter | Fungsi | Contoh |
|--------|--------|--------|
| `port:` | Port spesifik | `port:22` |
| `product:` | Nama produk terdeteksi | `product:Apache` |
| `version:` | Versi spesifik | `version:2.4.49` (rentan) |
| `os:` | Sistem operasi | `os:"Windows 7"` |
| `country:` | Kode negara ISO3166-1 alpha-2 | `country:ID` |
| `city:` | Kota | `city:"Bandung"` |
| `org:` | Organisasi / ISP | `org:"PT Telekomunikasi"` |
| `hostname:` | Reverse DNS atau subdomain | `hostname:*.go.id` |
| `net:` | CIDR range | `net:103.10.64.0/22` |
| `before:` / `after:` | Tanggal pemindaian | `after:2026-01-01` |
| `ssl:` | Data sertifikat SSL | `ssl:"Let's Encrypt"` |
| `ssl.cert.subject.cn:` | Common Name sertifikat | `ssl.cert.subject.cn:"*.bankbca.co.id"` |
| `http.title:` | Judul halaman HTML | `http.title:"Webcam 7"` |
| `http.status:` | Kode status HTTP | `http.status:200` |
| `http.html:` | Isi HTML mentah (substring) | `http.html:"phpMyAdmin"` |
| `has_screenshot:true` | IP yang memiliki screenshot VNC/web | `has_screenshot:true` |
| `tags:` | Tag oleh curator Shodan | `tags:scada` atau `tags:ics` |
| `vuln:` | Kerentanan (dari integrasi dengan NVD) | `vuln:CVE-2021-34527` (PrintNightmare) |

Query bisa dikombinasikan dengan boolean `AND`, `OR`, `NOT`. Contoh konkret:

```shodan
# Semua server Hikvision di Indonesia yang tidak pakai password (banner "success": true)
country:ID product:"Hikvision-Webs" "success\": true"

# Semua router MikroTik dengan versi rentan dan API exposed di port 8728
port:8728 product:"MikroTik" version:<6.43

# Database Elasticsearch tanpa otentikasi yang bocor di AWS
org:"Amazon" product:elastic "You Know, for Search" -http.basic

# Industrial Control System di Indonesia yang terhubung internet
country:ID tags:ics

# Citrix ADC dengan CVE-2019-19781 (path traversal)
vuln:CVE-2019-19781

# Semua server Jenkins yang exposed dan tidak memiliki autentikasi
http.title:"Dashboard [Jenkins]" "Set up a backup" -"login"
```

Shodan mendukung **API REST** untuk otomatisasi, dan **Shodan CLI** untuk scripting. Dengan API key (gratis terbatas, berbayar untuk full access), kita bisa melakukan download massal dan analisis statistik.

---

## 🕵️‍♂️ Shodan sebagai Senjata Dual-Use: Defender vs Attacker

Shodan adalah contoh sempurna alat **dual-use**. Ia tidak tahu apakah Anda seorang sysadmin atau penyerang; ia hanya memberikan data yang tersedia.

### 🛡️ Defensive Use Cases

1. **Asset Discovery & Shadow IT**: Temukan semua IP dan layanan milik organisasi yang terekspos ke internet tanpa sepengetahuan tim IT. Query: `org:"Nama Perusahaan"` atau `net: subnet` untuk melihat apa yang terpublikasi.
2. **Exposure Audit**: Cari database yang terpapar tanpa password (`product:mongodb -authentication`), panel admin (`http.title:"phpMyAdmin"`), atau file `.git` yang terbuka (`http.title:"Index of /.git"`). Ini adalah kerentanan paling umum yang sering tidak disadari.
3. **Supply Chain Risk**: Pantau vendor pihak ketiga yang menyimpan data Anda. Misal: `ssl.cert.subject.cn:"*.vendoranda.com"` untuk melihat di mana sertifikat itu dipasang.
4. **Vulnerability Prioritization**: Filter `vuln:` untuk mencari perangkat yang rentan terhadap CVE spesifik. Digabung dengan `org:` Anda, ini membantu prioritas patching tanpa perlu scan ulang internal.
5. **Incident Response**: Saat ada indikasi compromise, cari IP internal di Shodan untuk melihat apakah ada port tak wajar yang terbuka. Juga bisa mencari banner yang berisi string C2 tertentu.

### ☠️ Offensive / Criminal Use Cases

1. **Target Selection**: Penyerang dapat memilih target berdasarkan geografi, organisasi, atau jenis perangkat. Contoh: mencari server keuangan dengan versi rentan di kota tertentu.
2. **Mass Exploitation**: Botnet dan ransomware sering memanfaatkan Shodan untuk mencari seluruh host yang rentan terhadap exploit tertentu. Contoh: query `product:"Apache CouchDB"` untuk mencari database yang bisa dieksekusi kode via RCE.
3. **Credential Stuffing Target**: Cari panel login yang terekspos (RDP, SSH, VNC, WordPress admin, cPanel) lalu lakukan brute-force.
4. **Industrial Sabotage**: Aktor state-level memonitor ICS/SCADA devices via Shodan (`tags:scada`) untuk reconnaissance sebelum serangan (contoh: Stuxnet awalnya membutuhkan intel tentang PLC Siemens).
5. **Doxing dan Surveillance**: Dengan query seperti `ip: [IP individu]` atau `hostname:dialup.nama-isp.net`, bisa didapatkan layanan yang dijalankan korban (file sharing, webcam, dll).

---

## 🔬 Anatomi Serangan: Dari Shodan ke Remote Code Execution

Untuk menunjukkan betapa powerful Shodan sebagai *reconnaissance*, inilah alur serangan realistis:

1. **Recon**: Penyerang mengeksekusi query `product:"Apache" version:"2.4.49"` (versi yang rentan CVE-2021-41773 — path traversal yang bisa berujung RCE).
2. **Filter Target**: Penambahan `country:ID` menghasilkan 150 IP. Lalu ditambah `-ssl` untuk yang tidak pakai HTTPS (mungkin lebih tidak terawat).
3. **Verifikasi Manual**: Penyerang mengirimkan request:
   ```
   curl http://target_ip/cgi-bin/.%2e/.%2e/.%2e/.%2e/bin/sh --data 'echo;id'
   ```
   Jika berhasil, ia mendapatkan uid.
4. **Exekusi Shell**: Dengan payload lebih besar, penyerang mendapatkan reverse shell, lalu lateral movement.
5. **Persistence**: Install web shell, backdoor, atau ransomware.

**Waktu dari Query ke Root**: Bisa kurang dari 10 menit. Inilah mengapa Shodan adalah alat yang sangat berbahaya di tangan yang salah — dan sangat berharga untuk pertahanan.

---

## 🔐 Countermeasures: Menghilang dari Shodan

Tidak ada cara untuk *menghapus* IP dari Shodan secara seketika, karena pemindaian terjadi terus-menerus. Tetapi Anda bisa:

1. **Tutup Port yang Tidak Perlu**: Shodan tidak bisa memindai port yang tidak terbuka. Pastikan firewall hanya membuka port yang benar-benar dibutuhkan untuk publik.
2. **IP Access Control**: Batasi akses ke layanan sensitif (SSH, database, panel admin) hanya dari IP internal atau VPN. Gunakan security group di cloud.
3. **Autentikasi Wajib**: Semua layanan yang harus publik wajib memiliki autentikasi (HTTP basic auth, certificate-based, SSO). Jangan mengandalkan "security by obscurity".
4. **Harden Banner**: Jika memungkinkan, modifikasi banner untuk menghilangkan informasi versi (misal: `ServerTokens Prod` di Apache, `DebianBanner no` di SSH). Ini mempersulit penyerang tetapi bukan solusi utama.
5. **Shodan On-Prem Agent**: Untuk jaringan internal, Shodan menyediakan **private scanning agent** yang memindai dari dalam, lalu hasilnya hanya bisa diakses oleh akun Anda. Ini berguna untuk inventory.
6. **Honeypots & Deception**: Pasang honeypot di port tinggi dan kirim banner palsu untuk mengotori hasil Shodan penyerang dan deteksi scanning.
7. **Legal Takedown Request**: Jika ada data sangat sensitif yang terindeks (misal: API key yang tidak sengaja terekspos), Anda bisa menghubungi Shodan untuk menghapus banner spesifik. Tapi data akan kembali saat scan berikutnya jika celah tidak ditutup.

---

## 🆚 Shodan vs Censys vs ZoomEye

Seperti yang Anda singgung, ada beberapa alternatif dengan pendekatan serupa:

| Aspek | **Shodan** | **Censys** | **ZoomEye** (KnownSec) |
|-------|------------|------------|-------------------------|
| **Model Data** | Berbasis port & service | Berbasis host & sertifikat | Berbasis port, service, dan web fingerprint |
| **Query Language** | Kaya, fokus pada filter banner | Query language sendiri + SQL-like via API | Kaya, dengan filter Mandarin |
| **Sertifikat SSL** | Diindeks, bisa dicari | Ini adalah spesialisasi Censys | Ya |
| **Screenshot** | Fitur premium (VNC, web) | Tidak fokus ke screenshot | Screenshot web |
| **Cakupan IPv6** | Parsial | Lebih baik dari Shodan | Parsial |
| **Vulnerability Database** | Integrasi CVE langsung | Tidak secara native, tapi bisa lewat BigQuery | Ya, dengan plugin |
| **API** | Sangat baik, dokumentasi lengkap | API REST + Google BigQuery | API terbatas |
| **Harga** | Free tier terbatas, subscription | Free 250 query/bulan, data via BigQuery gratis | Poin harian, subscription |
| **Use Case Unggul** | IoT/ICS, quick banner grabbing | Penelitian akademis, analisis sertifikat masif | Keamanan web, fingerprint aplikasi |

Censys sering digunakan untuk riset skala besar karena datasetnya bisa diakses langsung di Google BigQuery tanpa batasan query API. Misalnya: “Tunjukkan semua sertifikat yang diterbitkan untuk domain `*.go.id` dalam 24 jam terakhir” — ini sangat berguna untuk memonitor perubahan infrastruktur pemerintah atau perusahaan secara near real-time.

---

## 📈 Statistik Mengerikan (per 2026)

- Lebih dari **4 miliar IP** dipindai setiap siklus penuh.
- Rata-rata **300 juta layanan unik** terbuka di internet pada satu waktu.
- Jutaan database MongoDB, Elasticsearch, Redis, dan Cassandra tanpa password terindeks.
- Puluhan ribu perangkat ICS/SCADA (PLC, RTU, HMI) terhubung langsung ke internet, banyak dengan kredensial default.

Data ini bukan rahasia; ia adalah hasil dari apa yang organisasi gagal lindungi. Shodan hanya mencerminkannya.

---

## 🔗 Koneksi dalam Vault

- [[pegasus]] — Jika Shodan menemukan C2 server Pegasus, itu bisa dijadikan IOC; OSINT aktif via Shodan/Censys adalah bagian dari investigasi spyware.
- [[maltego]] — Shodan punya plugin untuk Maltego, menghubungkan IP dengan data OSINT lain.
- [[metasploit]] — Setelah Shodan menemukan host rentan, Metasploit bisa langsung meluncurkan exploit (dalam konteks pentest resmi).
- [[xkeyscore]] — NSA memiliki kemampuan serupa tapi dengan intercept langsung di backbone; Shodan adalah versi sipil yang lebih lambat dan legal.
- [[cellebrite-ufed]] — Shodan tidak menyentuh mobile secara langsung, tapi pencarian IP sering mengungkap jaringan Wi-Fi internal.

---

## 📚 Referensi

- Matherly, J. (2015). *Shodan: The Official Guide to the Internet’s Most Dangerous Search Engine*.
- Censys Documentation: https://search.censys.io
- ZoomEye Documentation: https://www.zoomeye.org
- NIST National Vulnerability Database integration with Shodan.
- OWASP: Using Search Engines for Penetration Testing.

---

*Shodan Deep Dive | Internet Scanning & OSINT Reconnaissance | Dual-Use Infrastructure Discovery*
---

audited
---
