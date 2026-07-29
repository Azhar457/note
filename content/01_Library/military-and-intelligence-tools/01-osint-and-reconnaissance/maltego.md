---
title: Maltego
tags:
  - 01-osint-and-reconnaissance
  - library
  - military-and-intelligence-tools
created: "2026-06-27"
updated: "2026-07-01"
status: pending
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> Maltego adalah alat pengumpulan data open-source intelligence (OSINT) yang bekerja dengan informasi publik. Seluruh data yang diproses berasal dari sumber terbuka seperti DNS, WHOIS, media sosial, dan API publik. Pembahasan ini bersifat edukasional dan defensive. Penggunaan terhadap individu tanpa tujuan yang sah atau untuk stalking, doxing, atau perencanaan serangan adalah ilegal di banyak yurisdiksi.

---

## 🧬 Apa Itu Maltego Secara Teknis?

Maltego adalah **platform graph-based link analysis** yang mengubah fragmen data (alamat email, nama domain, alamat IP, akun media sosial) menjadi **peta visual hubungan**. Berbeda dengan Shodan yang mencari host di internet, Maltego menjawab pertanyaan: _“Bagaimana semua potongan informasi ini terhubung?”_

Inti dari Maltego adalah konsep **entity** (node) dan **transform** (edge). Anda memulai dengan satu atau beberapa entitas, lalu menjalankan transform untuk menemukan entitas lain yang terhubung. Maltego kemudian menggambar graf yang mengungkapkan hubungan tersembunyi — geografis, organisasi, teknis, atau sosial.

### Arsitektur Mesin Transform

```
┌──────────────────────────────────────────────────────┐
│                  Maltego Client (GUI)                  │
│  Desktop (Windows/Linux/Mac) atau browser (Thin Client)│
└──────────────────────┬───────────────────────────────┘
                       │ (API requests via TDS)
                       ▼
┌──────────────────────────────────────────────────────┐
│              Transform Distribution Server (TDS)       │
│  (Maltego SaaS) - Proksi transform, caching, rate limit │
└──────────────────────┬───────────────────────────────┘
                       │
         ┌─────────────┼─────────────┐
         ▼             ▼             ▼
┌───────────┐ ┌───────────┐ ┌───────────────┐
│ Standard  │ │  Public   │ │  Custom        │
│ Transforms│ │  Transforms│ │  Transforms    │
│ (Maltego) │ │  (Hub)    │ │  (Local/Server) │
│ DNS, WHOIS│ │ Shodan,   │ │  Python/REST   │
│ SSL, IP   │ │ VirusTotal │ │  APIs          │
└───────────┘ └───────────┘ └───────────────┘
                       │
                       ▼
         [Sumber Data Eksternal]
         (DNS server, WHOIS registry,
          Shodan API, Twitter API,
          custom DB, Splunk, etc.)
```

**Transform** adalah unit atomik investigasi. Ia menerima array entitas, mengeksekusi query terhadap sumber data tertentu, dan mengembalikan entitas baru. Transform dijalankan di server (Maltego Public Transform Server atau server pribadi) untuk menyembunyikan kredensial API dan mengurangi beban klien.

---

## 🧩 Model Data Maltego: Entitas, Properti, dan Hubungan

Maltego memiliki lebih dari 40 tipe entitas bawaan, masing-masing dengan properti spesifik:

| Kategori Entitas   | Contoh                                                              | Properti Utama                       |
| ------------------ | ------------------------------------------------------------------- | ------------------------------------ |
| **Person**         | `Person`, `Twitter User`, `GitHub User`                             | name, alias, email, location         |
| **Organization**   | `Company`, `Organization`, `Government`                             | name, industry, URL                  |
| **Infrastructure** | `IP Address`, `Domain`, `NS Record`, `MX Record`, `URL`, `Netblock` | fqdn, whois, nameserver, geolocation |
| **Document/File**  | `Document`, `Image`, `PDF`                                          | title, url, file size, md5           |
| **Location**       | `City`, `Province`, `Country`, `GPS Coordinate`                     | name, area, longitude/latitude       |
| **Technology**     | `Service`, `Banner`, `Port`, `Technology Stack`                     | port, banner, product                |
| **Social Media**   | `Facebook Object`, `Twitter User`, `Instagram Profile`              | profile url, friends count           |
| **Phone**          | `Phone Number`                                                      | country code, subscriber             |

Setiap entitas dapat memiliki **properties** dinamis yang dapat diisi oleh transform. Misalnya, entitas `IP Address` dapat diperkaya dengan properti `location` dari geoIP.

### Weight dan Kredibilitas

Setiap edge (hubungan) memiliki **weight** dan **notes** untuk mencerminkan kepercayaan. Dalam investigasi intelijen, ini penting: "Apakah hubungan ini berdasarkan bukti keras atau hanya inferensial?" Maltego memungkinkan anotasi dan kategorisasi.

---

## ⚔️ Transform Kunci untuk Military & Intelligence Reconnaissance

### 1. DNS & Jaringan

- **To DNS name [from Domain]** → Mendapatkan semua subdomain yang diketahui (via certificate transparency, DNSDB, passive DNS).
- **To IP Address [from Domain]** → Resolusi A/AAAA.
- **To Netblock [from IP]** → WHOIS netblock query.
- **To NS, MX, SOA [from Domain]** → Mengungkap infrastruktur email dan nama server.
- **Reverse DNS [from IP]** → Mendapatkan PTR record, sering mengungkap nama host internal (misal: `dc01.internal.corp.com`).

Sekali transform ini dijalankan berulang pada domain target, Anda akan melihat peta infrastruktur organisasi: server email, nameserver, reverse proxy, dan bahkan layanan cloud yang digunakan.

### 2. WHOIS & Registrasi

- **To Organization [from Domain/IP]** → Data WHOIS historis dan saat ini.
- **To Email [from Domain]** → Email registrar/administratif dari WHOIS.
- **To Phone [from Domain]** → Nomor telepon yang tercatat.

Sering kali, alamat email pribadi digunakan untuk mendaftarkan domain perusahaan, yang kemudian bisa dihubungkan ke akun media sosial atau profil GitHub. Inilah benang merah pertama dari infrastruktur ke manusia.

### 3. Social Media & Profiling

- **To Twitter/GitHub/Instagram [from Email]** → Pencarian profil berdasarkan email (via API publik atau data leak).
- **To Profile [from Alias]** → Mencari username di berbagai platform.
- **To Connections [from Social Media]** → Mengambil daftar teman/follower (jika API mengizinkan).

Dengan satu alamat email dari WHOIS, Anda mungkin menemukan akun Twitter pengembang, lalu menemukan akun GitHub-nya, lalu melihat organisasi GitHub-nya yang lain, dan seterusnya. Ini adalah rantai OSINT klasik.

### 4. Data Breach & Leak Correlation

- **To Email [from Domain]** → Mencari email dengan domain tersebut yang muncul di database breach (Have I Been Pwned API, Dehashed). Ini mengungkap kredensial bocor.
- **To Password [from Email]** → Jika breach menyertakan password, transform tertentu bisa mengambilnya (legalitas abu-abu).

### 5. SSL/TLS Certificate Analysis

- **To SSL Certificate [from IP/Port]** → Mendapatkan rantai sertifikat, SANs (Subject Alternative Names).
- **To Domain [from SSL Certificate]** → SAN sering mengungkap domain lain yang di-hosting di server yang sama, atau proyek staging/internal. Ini adalah teknik **domain correlation** yang sangat kuat.

### 6. Shodan & Censys Integration (via Transforms)

Dengan Maltego standard transforms atau dari hub, Anda bisa:

- `To Port/Service [from IP]` → Menampilkan semua port terbuka dan banner yang dikenal Shodan.
- `To Vulnerability [from IP/Service]` → Mencocokkan dengan CVE yang terdeteksi.

Ini menggabungkan kekuatan Shodan ke dalam graf, sehingga Anda bisa melihat gambaran lengkap: organisasi → domain → IP → port/service → kerentanan.

---

## 🔎 Studi Kasus: Dari Nama Perusahaan ke Potensi Attack Surface

**Skenario:** Red team atau unit intelijen menargetkan PT Contoh Teknologi. Hanya diketahui nama perusahaan.

1. **Mulai dengan entitas `Company`** "PT Contoh Teknologi".
2. **Transform: To Domain [Company]** → menemukan `contohteknologi.co.id`.
3. **To DNS name (subdomain)** → mengungkapkan:
   - `mail.contohteknologi.co.id`
   - `vpn.contohteknologi.co.id`
   - `staging.api.contohteknologi.co.id`
   - `jenkins.internal.contohteknologi.co.id` (ups, ter-expose di sertifikat SSL)
4. **To IP Address [from Domain]** → beberapa IP publik.
5. **To Netblock [from IP]** → menunjukkan bahwa mereka menggunakan cloud provider tertentu, dan mungkin ada IP lain dalam netblock yang juga milik mereka.
6. **Shodan Transform on IPs** → menemukan:
   - Port 22 (SSH) terbuka di beberapa IP.
   - Port 443 dengan sertifikat SANs: `*.contohteknologi.co.id`, `*.internal.corp` (mengonfirmasi domain internal).
   - Port 8080 dengan Jenkins tanpa otentikasi.
7. **WHOIS on Domain** → email pendaftar: `admin@contohteknologi.co.id`.
8. **To Social Media [from Email]** → menemukan profil LinkedIn dengan nama lengkap, posisi "System Administrator".
9. **To Email [from Domain]** via breach data → satu email `it.support@contohteknologi.co.id` muncul di data breach LinkedIn 2012 dengan password hash MD5.
10. **Graph Analysis** → menunjukkan hubungan antara manusia (admin), infrastruktur (Jenkins), dan kerentanan (password lemah, Jenkins terpapar). Attack path menjadi jelas.

Seluruh investigasi di atas dilakukan **tanpa mengirim satu paket pun ke target** selain yang dilakukan oleh transform (yang sebagian besar adalah query ke database publik). Ini adalah kekuatan OSINT pasif yang mematikan.

---

## 🕸️ Maltego untuk Intelijen Militer dan Kontra-Terorisme

Dalam konteks military & intelligence (Level 0), Maltego digunakan untuk:

- **Target Network Mapping**: Memetakan jaringan pendukung target (individu, perusahaan, lokasi) dari satu titik awal (nomor telepon, nama samaran, email). Ini adalah standard link analysis untuk intelijen manusia (HUMINT) dan SIGINT.
- **Supply Chain Analysis**: Melihat hubungan antara perusahaan, pemilik, dan anak perusahaan untuk mengidentifikasi entitas yang terlibat dalam proliferasi atau sanksi.
- **Botnet / C2 Tracking**: Dengan memulai dari IP C2 yang diketahui, Maltego dapat menemukan domain terkait, nameserver, dan IP lain dalam netblock yang sama, membantu memetakan infrastruktur C2 aktor ancaman.
- **Fraud & Criminal Investigation**: Menghubungkan nomor telepon penipu dengan korban lain, akun bank, atau alamat fisik melalui OSINT.

---

## 🛡️ Deteksi & Pertahanan Terhadap Penggunaan Maltego

Maltego sendiri tidak meninggalkan jejak pada target karena ia beroperasi pada data publik. Namun, query ke layanan tertentu bisa tercatat:

- **DNS queries**: Jika Anda menjalankan transform DNS, nameserver target mungkin mencatat query dari server transform (bukan dari Anda). Untuk investigasi sensitif, gunakan DNS over HTTPS atau VPN.
- **WHOIS queries**: Rate limited oleh registry.
- **Social Media API**: Akses API bisa di-log oleh platform (Twitter, GitHub) dan mungkin terkait dengan akun API Anda. Gunakan akun throwaway atau resmi untuk red team.
- **Shodan/Censys API**: Pemilik data (target) tidak tahu Anda meng-query mereka, tetapi Shodan tahu.

Untuk defender:

- **Tidak banyak yang bisa dilakukan** untuk mencegah pemetaan OSINT. Data yang Anda publikasikan di DNS, WHOIS, sertifikat SSL, dan media sosial adalah data publik. Satu-satunya cara adalah meminimalkan exposure: menghilangkan informasi pribadi dari WHOIS (gunakan privacy guard), membersihkan SAN dari domain internal, tidak menggunakan email pribadi untuk pendaftaran domain, dan menghapus metadata dari dokumen publik.
- **Monitor eksposur Anda sendiri** dengan menggunakan Maltego secara defensif: lakukan self-reconnaissance dan hapus data sensitif yang ditemukan.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄────────────────────────────────────────────► OFFENSE

SOC / Blue Team             Red Team                 APT / State Actor
│                           │                        │
Memetakan aset sendiri      Menemukan titik lemah    Full OSINT profiling
dan hubungan supply          sebelum serangan          target untuk spear-
chain untuk mengelola        untuk simulasi            phishing dan social
risiko                       realistis                 engineering
│                           │                        │
│                           │                        ▼
▼                           ▼                        Doxing, stalking,
Forensik digital:           OSINT untuk               intimidation
hubungkan artefak           credential stuffing
dengan identitas            dari breach data
└─────────────────────────────────────────────────────┘
```

Maltego adalah alat netral; hasilnya bergantung pada tangan operator.

---

## 🔗 Koneksi dalam Vault

- [[shodan]] — Transform Shodan di Maltego mengintegrasikan data host/service langsung ke graf.
- [[bloodhound]] — Keduanya menggunakan graph database (Neo4j) untuk analisis. Maltego untuk hubungan dunia nyata; BloodHound untuk hubungan Active Directory.
- [[metasploit]] — Setelah target terpetakan di Maltego, Metasploit digunakan untuk eksploitasi endpoint yang ditemukan.
- [[pegasus]] — Investigasi Pegasus sering dimulai dengan OSINT di Maltego: melacak nomor telepon, akun, dan infrastruktur yang terkait dengan operator spyware.
- [[xkeyscore]] — Maltego adalah versi sipil dari query link analysis yang dilakukan NSA dengan XKEYSCORE. XKEYSCORE juga menggunakan graph untuk memetakan koneksi, tetapi dengan data rahasia.

---

## 📚 Referensi

- Paterva, _Maltego User Guide_ (2023)
- Vinicius, _Mastering Maltego: A Comprehensive Guide to OSINT and Link Analysis_ (2022)
- Bazzell, M. _Open Source Intelligence Techniques_ (2023)
- NIST SP 800-137: Information Security Continuous Monitoring (ISCM) — relevan untuk self-reconnaissance.
- MITRE ATT&CK: T1591 (Gather Victim Org Information), T1590 (Gather Victim Network Information), T1593 (Search Open Websites/Domains)

---

_Maltego Deep Dive | OSINT Link Analysis & Reconnaissance | Dual-Use Entity Correlation_
