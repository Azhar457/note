---
title: "Google Dorks"
tags:
  - 01-osint-and-reconnaissance
  - library
  - military-and-intelligence-tools
aliases:
  - "google-dorks"
created: "2026-06-27"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

> [!warning] Konteks Etis & Legal
> Google Dorks memanfaatkan mesin pencari Google untuk menemukan informasi yang terindeks secara publik. Tidak ada eksploitasi, tidak ada bypass otentikasi, tidak ada akses ilegal. Namun, informasi yang ditemukan bisa sangat sensitif (dokumen internal, kredensial, database backup). Menggunakan informasi itu untuk mengakses sistem tanpa izin adalah ilegal. Pembahasan ini sepenuhnya defensif: agar defender tahu apa yang bisa dilihat penyerang dan bagaimana menutup celah.

---

## 🧬 Apa Itu Google Dorks?

Google Dorks (atau "Google Hacking") adalah penggunaan operator pencarian lanjutan Google untuk menemukan informasi yang **tidak dimaksudkan untuk publik**, tetapi secara tidak sengaja terindeks oleh crawler Google. Ini adalah teknik OSINT paling sederhana namun paling mematikan: tanpa mengirim satu byte pun ke server target, penyerang dapat menemukan halaman login, file konfigurasi, backup database, kamera pengawas, dokumen rahasia pemerintah, dan banyak lagi.

Inti dari Google Dorks adalah **search operators** — kata kunci sintaks yang mempersempit pencarian ke parameter spesifik:

- `site:` — membatasi pencarian ke domain tertentu.
- `filetype:` — mencari jenis file tertentu (pdf, xls, sql, bak, log, env).
- `intitle:` — mencari kata dalam tag `<title>` halaman.
- `inurl:` — mencari string di dalam URL.
- `intext:` — mencari string di dalam body halaman.
- `cache:` — melihat versi tersimpan Google dari suatu halaman.
- `link:` — (deprecated) mencari halaman yang menautkan ke URL tertentu.
- `related:` — mencari situs yang mirip.
- `before:` / `after:` — filter tanggal.
- `..` — range numerik (misal: `site:target.com port: 1..65535`).

Operator-operator ini bisa dikombinasikan untuk membuat query yang sangat presisi dan kuat.

---

## 🔍 Operator Esensial & Kombinasinya

### 1. `site:` — Membidik Satu Domain atau TLD

Membatasi pencarian ke domain atau top-level domain tertentu.

- **`site:target.com`** → semua halaman dari target.com yang diindeks Google.
- **`site:go.id`** → seluruh situs pemerintah Indonesia.
- **`site:mil`** → situs militer AS.
- **`site:ac.id`** → universitas di Indonesia.

### 2. `filetype:` — Mencari File yang Tidak Seharusnya Publik

Membatasi hasil ke tipe file tertentu. Google mendukung puluhan ekstensi: `pdf, doc, xls, ppt, sql, bak, log, txt, env, cfg, conf, ini, dbf, mdb, rar, zip, tar, tgz, php, asp, aspx, jsp, json, xml, rss, wsdl, wadl`.

- **`filetype:sql`** → file dump database SQL.
- **`filetype:bak`** → file backup.
- **`filetype:env`** → file environment variables (sering mengandung API keys, database passwords).
- **`filetype:log`** → file log aplikasi.
- **`filetype:pem`** atau **`filetype:key`** → kunci privat SSL.
- **`filetype:pdf intext:"classified"`** → dokumen rahasia.

### 3. `intitle:` / `allintitle:` — Judul Halaman yang Memberi Petunjuk

Mencari teks di dalam `<title>` HTML.

- **`intitle:"Index of"`** → listing direktori Apache/Nginx.
- **`intitle:"phpMyAdmin"`** → panel admin database.
- **`intitle:"Dashboard [Jenkins]"`** → Jenkins CI/CD.
- **`intitle:"Webcam"`** → antarmuka webcam.
- **`intitle:"login"`** → halaman login apa pun.

### 4. `inurl:` / `allinurl:` — String di URL

Mencari kata atau pola di URL. Sangat berguna untuk menemukan panel admin, file konfigurasi, atau endpoint API.

- **`inurl:admin`** → halaman dengan "admin" di URL.
- **`inurl:login`** → halaman login.
- **`inurl:phpmyadmin`** → instalasi phpMyAdmin.
- **`inurl:wp-content`** → direktori upload WordPress.
- **`inurl:api/v1`** → endpoint API.
- **`inurl:backup`** → direktori atau file backup.

### 5. `intext:` — Pencarian di Body Halaman

Mencari teks di dalam konten halaman.

- **`intext:"password" filetype:txt`** → file teks yang berisi kata "password".
- **`intext:"SELECT * FROM" filetype:php`** → kode PHP dengan query SQL.
- **`intext:"API_KEY"`** → halaman yang secara tidak sengaja menampilkan API key.

### 6. Operator Logika & Wildcard

- **`OR`** (atau `|`) — Gabungan alternatif: `site:target.com (filetype:pdf OR filetype:docx)`
- **`-`** (minus) — Mengecualikan kata: `site:target.com -filetype:html`
- **`*`** — Wildcard: `site:target.com inurl:"*backup*"` (mencari backup, backups, backup-old, dll.)
- **`..`** — Range numerik: `site:target.com inurl:"id=1..1000"`
- **`" "`** — Kutip untuk frasa persis: `"Index of /backup"`

---

## ☠️ Dorks Paling Mematikan: Kategorisasi & Contoh Nyata

### Kategori A: File Konfigurasi & Kredensial

| Query                                         | Tujuan                                                                             |
| --------------------------------------------- | ---------------------------------------------------------------------------------- |
| `intitle:"Index of" ".env"`                   | File environment Laravel/Symfony yang mengandung DB password, APP_KEY, API secret. |
| `filetype:sql "password"`                     | Dump database dengan hash atau plaintext password.                                 |
| `filetype:pem intext:"BEGIN RSA PRIVATE KEY"` | Kunci privat SSL.                                                                  |
| `intitle:"index of" "config.php"`             | File konfigurasi PHP dengan kredensial database.                                   |
| `inurl:/.git/config`                          | File konfigurasi Git repositori, mungkin mengandung remote origin dengan token.    |
| `filetype:tfstate`                            | Terraform state file, sering berisi AWS keys, IP internal, arsitektur cloud.       |
| `filetype:yml intext:"password"`              | File YAML dengan password (Ansible playbook, docker-compose).                      |
| `filetype:json intext:"private_key"`          | JSON yang memuat private key.                                                      |

### Kategori B: Panel Administrasi & Layanan Terbuka

| Query                                                 | Tujuan                               |
| ----------------------------------------------------- | ------------------------------------ |
| `intitle:"phpMyAdmin" intext:"Welcome to phpMyAdmin"` | Instalasi phpMyAdmin tanpa proteksi. |
| `intitle:"Dashboard [Jenkins]"`                       | Jenkins CI/CD tanpa otentikasi.      |
| `intitle:"Grafana"`                                   | Dashboard monitoring Grafana publik. |
| `intitle:"Kibana"`                                    | Instalasi Kibana elastis.            |
| `inurl:admin intitle:login`                           | Halaman login panel admin.           |
| `intitle:"Apache Tomcat"`                             | Apache Tomcat console.               |
| `intitle:"Internet Information Services"`             | IIS server default page.             |
| `intitle:"MongoDB Express"`                           | Mongo Express panel.                 |
| `intitle:"RabbitMQ"`                                  | RabbitMQ management interface.       |

### Kategori C: Informasi Pribadi & Data Breach

| Query                                               | Tujuan                                              |
| --------------------------------------------------- | --------------------------------------------------- |
| `filetype:xls intext:"email" intext:"password"`     | Spreadsheet Excel berisi daftar email dan password. |
| `filetype:csv "credit card"`                        | Data kartu kredit dalam CSV.                        |
| `intitle:"index of" "passport"`                     | Scan paspor yang tersimpan di direktori publik.     |
| `filetype:pdf "social security number"`             | Dokumen PDF dengan nomor SSN (AS).                  |
| `site:pastebin.com intext:"@target.com" "password"` | Kredensial target yang bocor di Pastebin.           |

### Kategori D: Informasi Infrastruktur & Jaringan Internal

| Query                                               | Tujuan                                                                         |
| --------------------------------------------------- | ------------------------------------------------------------------------------ |
| `site:target.com intitle:"networking" "IP address"` | Diagram jaringan internal.                                                     |
| `intitle:"index of" "network"`                      | Listing direktori yang berisi peta jaringan.                                   |
| `filetype:vsd intext:"firewall"`                    | Diagram Visio infrastruktur.                                                   |
| `filetype:pdf "internal use only"`                  | Dokumen yang ditandai internal.                                                |
| `inurl:server-status`                               | Halaman status Apache, mengungkapkan request URL, IP klien, dan path internal. |
| `intitle:"index of" "ssh"`                          | Kunci SSH yang terpapar.                                                       |

### Kategori E: Perangkat IoT & Kamera Publik

| Query                                  | Tujuan                                  |
| -------------------------------------- | --------------------------------------- |
| `intitle:"Live View" intitle:"Webcam"` | Webcam publik.                          |
| `intitle:"Network Camera"`             | Kamera jaringan.                        |
| `inurl:view.shtml`                     | Kamera IP.                              |
| `intitle:"WebcamXP"`                   | WebcamXP software.                      |
| `intitle:"scada"`                      | Perangkat SCADA (industri).             |
| `intitle:"BACnet"`                     | Perangkat BACnet (building automation). |
| `inurl:"/cgi-bin/webproc"`             | Router/modern interface.                |

---

## 🔬 Teknik Lanjutan: Menggabungkan Dorks untuk Presisi

### Query Bertingkat

Daripada satu dork besar, kombinasikan secara presisi:

```google
site:target.com (filetype:bak OR filetype:old OR filetype:backup) intext:"<?php"
```

Mencari file backup PHP yang mengandung kode sumber.

```google
site:target.com inurl:backup filetype:sql
```

Mencari file backup database di domain target.

```google
site:target.com intitle:"index of" "parent directory" "wp-config"
```

Mencari direktori terbuka yang mengandung file konfigurasi WordPress.

### Wildcard & Ranges untuk Fuzzing

```google
site:target.com inurl:"page=*"
```

Mencari parameter page yang mungkin rentan terhadap LFI/RFI.

```google
site:target.com inurl:"id=1..999"
```

Enumerasi ID numerik pada parameter URL.

### Google Dorks untuk Bug Bounty & Red Team

- **Subdomain Enumeration**: `site:*.target.com -www` → menemukan subdomain selain www.
- **File Upload Discovery**: `site:target.com inurl:upload` → menemukan endpoint upload file.
- **Backend Technology**: `site:target.com inurl:jsp` atau `inurl:asp` atau `inurl:php` → mengidentifikasi teknologi backend.
- **Error Messages**: `site:target.com intext:"SQL syntax"` → SQL errors yang bocor struktur database.
- **Debug Mode**: `site:target.com intext:"Debug mode"` → aplikasi dalam mode debug.

---

## 🛡️ Countermeasures: Mengurangi Eksposur di Google

### 1. Robots.txt — Bukan Solusi Utama

File `robots.txt` meminta crawler untuk tidak mengindeks direktori tertentu. Namun, Google Dorks seringkali justru menargetkan file yang ada di `Disallow` karena penyerang bisa menggunakan `inurl:` untuk melihat URL yang diblokir. Contoh:

```
User-agent: *
Disallow: /admin/
Disallow: /backup/
```

Penyerang akan mencari `site:target.com inurl:/admin/` untuk melihat apakah direktori ini memiliki file index. Robots.txt tidak mencegah pengindeksan sepenuhnya jika ada link eksternal menuju direktori tersebut.

### 2. Meta Tag `noindex`

Lebih kuat dari `robots.txt`. Tambahkan di `<head>`:

```html
<meta name="robots" content="noindex, nofollow" />
```

Ini mencegah Google mengindeks halaman meskipun ada tautan dari luar. Namun, harus dikonfigurasi per halaman.

### 3. .htaccess / Nginx Authentication

Proteksi direktori sensitif dengan password (HTTP Basic Auth) sehingga Google tidak bisa mengaksesnya (kode status 401/403). Cek header response: jika server mengembalikan 403, Google tidak akan mengindeks.

### 4. Google Search Console — Remove URL

Jika data sensitif sudah terlanjur terindeks:

1. Hapus file dari server.
2. Kembalikan status 404 atau 410.
3. Gunakan **Google Search Console** > Removals > Temporary Removals untuk menghapus URL dari indeks dengan cepat.
4. Untuk penghapusan permanen, pastikan server mengembalikan 404/410 dan halaman tidak lagi di-link.

### 5. Data Leak Monitoring (Self-Dorking)

Lakukan pencarian dork terhadap domain Anda sendiri secara berkala:

```
site:domainanda.com filetype:sql
site:domainanda.com filetype:env
site:domainanda.com intitle:"index of"
site:domainanda.com inurl:backup
```

Ini adalah bagian dari **External Attack Surface Management (EASM)**. Jika menemukan data sensitif, segera hapus dan de-indeks.

### 6. Harden Konfigurasi Server

- Matikan **directory listing** (Options -Indexes di Apache, `autoindex off` di Nginx).
- Jangan biarkan file backup dengan ekstensi `.bak`, `.old`, `.backup` di direktori publik.
- Jangan commit file `.env` atau `config.php` ke repositori publik.
- Gunakan `.gitignore` yang tepat, dan jika perlu, blokir akses ke `/.git/` via server config.
- Matikan **server-status** atau batasi akses ke IP internal.

### 7. Audit Sertifikat SSL

Google mengindeks isi sertifikat SSL melalui Certificate Transparency. Jangan cantumkan hostname internal di SAN sertifikat publik. Gunakan wildcard atau internal CA.

---

## ↔️ Dual-Use Spectrum

```
DEFENSE ◄────────────────────────────────────────► OFFENSE

Self-Dorking                Bug Bounty               Data Thief
│                           │                        │
Memeriksa eksposur          Menemukan endpoint       Mencari file .sql
aset sendiri                rentan di program        bocor untuk dijual
│                           bug bounty               │
│                           │                        ▼
▼                           ▼                        Identity Thief
Security audit              Red team:                Mencari spreadsheet
eksternal tanpa             menemukan                email:password untuk
biaya sepeser pun           dokumen internal         credential stuffing
```

Google Dorks adalah OSINT murni: tidak ilegal, tidak invasive, tidak meninggalkan jejak di server target (semua query ke Google, bukan ke target). Namun, hasilnya bisa digunakan untuk serangan yang sangat merusak.

---

## 🔗 Koneksi dalam Vault

- [[shodan]] — Shodan mencari perangkat; Google Dorks mencari file dan direktori. Keduanya saling melengkapi: Shodan menemukan IP yang terbuka, Google Dorks menemukan apa yang ada di balik IP tersebut.
- [[maltego]] — Maltego dapat menggunakan Google Dorks sebagai bagian dari transform untuk menemukan dokumen terkait domain atau email.
- [[metasploit]] — Google Dorks dapat menemukan aplikasi rentan (misal: `inurl:/struts/` untuk Apache Struts), yang kemudian dieksploitasi dengan Metasploit.
- [[bloodhound]] — Tidak langsung, tetapi informasi dari dorks (dokumen internal, nama karyawan) bisa digunakan untuk social engineering dan mendapatkan akses awal ke AD.
- [[burp-suite]] — Setelah menemukan aplikasi web dengan Google Dorks, Burp Suite digunakan untuk mengaudit dan mengeksploitasi lebih dalam.
- [[pegasus]] — Operator Pegasus bisa menggunakan dorks untuk menemukan nomor telepon atau email target.

---

## 📚 Referensi

- Long, J. (2004). _Google Hacking for Penetration Testers_. Syngress.
- GHDB (Google Hacking Database) oleh Exploit-DB: https://www.exploit-db.com/google-hacking-database
- Google Search Central Documentation: https://developers.google.com/search/docs
- OWASP: _Testing for Information Leakage_ (WSTG-INFO-04)
- MITRE ATT&CK: T1593 (Search Open Websites/Domains), T1591 (Gather Victim Org Information)

---

_Google Dorks Deep Dive | Advanced Search Operators for Exposed Data | Passive Reconnaissance OSINT_
