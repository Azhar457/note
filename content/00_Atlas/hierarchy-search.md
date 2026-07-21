---
title: Hierarchy Search
tags:
  - atlas
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

### 🌐 Hierarki Pencarian Informasi — Surface sampai Beyond Dark Web

Hierarki pencarian informasi dapat dibagi menjadi beberapa level, mulai dari surface web yang dapat diakses oleh semua orang hingga level yang lebih rendah yang memerlukan akses khusus dan pengetahuan teknis. Berikut adalah penjelasan lebih lanjut tentang hierarki pencarian informasi:

#### Level 0 — Surface Web

Surface web merupakan level pertama dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses oleh semua orang menggunakan browser biasa. Surface web mencakup sekitar 4% dari total internet dan berisi berita, media sosial, e-commerce, dan Wikipedia. Semua konten pada surface web telah terindeks oleh mesin pencari seperti Google, Bing, dan DuckDuckGo.

Namun, perlu diingat bahwa Surface Web juga memiliki risiko tersendiri, seperti penjualan data pengguna ke advertiser. Oleh karena itu, pengguna perlu berhati-hati dalam membagikan informasi pribadi dan menggunakan layanan online.

Contoh kode untuk mengakses surface web menggunakan Python:

```python
import requests

# Mengakses halaman web
url = "https://www.google.com"
response = requests.get(url)

# Menampilkan kode status
print(response.status_code)

# Menampilkan konten halaman web
print(response.text)
```

#### Level 1 — Semi-Hidden Web

Level 1 merupakan tingkat kedua dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses menggunakan teknik pencarian lanjut seperti site:, filetype:, dan inurl:. Semi-hidden web mencakup database yang telah bocor, dokumen internal yang salah konfigurasi, CCTV publik yang terbuka, dan catatan pengadilan.

Pengguna perlu berhati-hati dalam mengakses informasi pada level ini, karena beberapa konten mungkin memiliki status hukum yang abu-abu. Mengakses sistem tanpa izin dapat dianggap ilegal, meskipun "terbuka".

Contoh kode untuk mengakses semi-hidden web menggunakan Python:

```python
import requests

# Mengakses database bocor
url = "https://example.com/db.sql"
response = requests.get(url)

# Menampilkan kode status
print(response.status_code)

# Menampilkan konten database
print(response.text)
```

#### Level 2 — Deep Web

Deep web merupakan level ketiga dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses menggunakan kredensial yang valid, VPN korporat, atau akses institusi. Deep web mencakup jurnal ilmiah, rekam medis, email korporat, source code internal, dan dataset pemerintah non-publik.

Pengguna perlu berhati-hati dalam mengakses informasi pada level ini, karenacredential theft dapat menjadi vektor utama. Namun, perlu diingat bahwa deep web bukanlah "gelap" — hanya tidak terindeks oleh mesin pencari.

Contoh kode untuk mengakses deep web menggunakan Python:

```python
import requests

# Mengakses jurnal ilmiah
url = "https://example.com/journal.pdf"
username = "username"
password = "password"

# Mengirimkan request dengan kredensial
response = requests.get(url, auth=(username, password))

# Menampilkan kode status
print(response.status_code)

# Menampilkan konten jurnal
print(response.text)
```

#### Level 3 — Dark Web via Tor

Dark web via Tor merupakan level keempat dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses menggunakan Tor Browser dan relay 3 node (Guard → Middle → Exit). Dark web mencakup forum peneliti, platform whistleblower (SecureDrop), marketplace ilegal, leak database, ransomware blog, dan layanan anonim yang legitimate.

Namun, perlu diingat bahwa Exit node dapat membaca traffic HTTP yang tidak dienkripsi. Oleh karena itu, pengguna perlu berhati-hati dalam menggunakan layanan ini dan memastikan bahwa opsec (operational security) mereka baik.

Contoh kode untuk mengakses dark web via Tor menggunakan Python:

```python
import socks
import socket

# Mengatur proxy Tor
socks.setdefaultproxy(socks.PROXY_TYPE_SOCKS5, "127.0.0.1", 9050)
socket.socket = socks.socksocket

# Mengakses halaman web dark web
url = "http://example.onion"
response = requests.get(url)

# Menampilkan kode status
print(response.status_code)

# Menampilkan konten halaman web
print(response.text)
```

#### Level 4 — Tor Exit Node Position

Level 4 merupakan tingkat kelima dalam hierarki pencarian informasi. Pada level ini, pengguna dapat menjadi exit node dan memiliki akses ke semua traffic yang melewatinya. Tor exit node position dapat diakses dengan menjadi exit node dan memiliki bandwidth yang besar.

Namun, perlu diingat bahwa menjadi exit node memiliki risiko tersendiri, seperti konsumsi bandwidth yang masif dan potensi terekspos oleh ISP atau LE (law enforcement).

Contoh kode untuk mengatur exit node Tor menggunakan Python:

```python
import stem

# Mengatur exit node
exit_node = stem.exitNode("example.onion")

# Mengatur bandwidth
exit_node.set_bandwidth(1000)

# Menampilkan informasi exit node
print(exit_node.get_info())
```

#### Level 5 — I2P & Freenet

Level 5 merupakan tingkat keenam dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses menggunakan client I2P atau Freenet yang terpisah. I2P dan Freenet mencakup jaringan garlic routing yang lebih anonim dari Tor. Konten pada level ini persisten dan terdistribusi — tidak ada server tunggal yang bisa di-takedown.

Namun, perlu diingat bahwa level ini memiliki kecepatan yang lebih lambat dan kompleksitas yang lebih tinggi.

Contoh kode untuk mengakses I2P menggunakan Python:

```python
import i2p

# Mengatur client I2P
i2p_client = i2p.Client("example.i2p")

# Mengakses halaman web I2P
url = "http://example.i2p"
response = i2p_client.get(url)

# Menampilkan kode status
print(response.status_code)

# Menampilkan konten halaman web
print(response.text)
```

#### Level 6 — Private Overlay Networks

Level 6 merupakan tingkat ketujuh dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses menggunakan undangan atau komunitas tertutup. Private overlay networks mencakup Riffle, Loopix, Nym Network, dan Mixnets. Level ini dirancang tahan traffic analysis — bahkan observer yang melihat seluruh jaringan tidak bisa korelasikan sender-receiver.

Namun, perlu diingat bahwa setup level ini sangat teknis dan komunitasnya sangat kecil.

Contoh kode untuk mengakses private overlay network menggunakan Python:

```python
import riffle

# Mengatur client Riffle
riffle_client = riffle.Client("example.riffle")

# Mengakses halaman web Riffle
url = "http://example.riffle"
response = riffle_client.get(url)

# Menampilkan kode status
print(response.status_code)

# Menampilkan konten halaman web
print(response.text)
```

#### Level 7 — Nation-State Intelligence Feeds

Level 7 merupakan tingkat terakhir dalam hierarki pencarian informasi. Pada level ini, informasi dapat diakses oleh negara-negara yang memiliki backbone ISP level dan undersea cable tap. Level ini mencakup seluruh traffic internet global yang tidak dienkripsi, metadata komunikasi, dan pola perilaku agregat.

Namun, perlu diingat bahwa level ini tidak bisa diakses oleh publik dan hanya bisa diakses oleh lembaga Intelijen Negara.

### Anatomi Posisi Exit Node

Berikut adalah anatomi posisi exit node:

```
[Kamu — User Tor]
      │
      ▼
┌─────────────┐
│  Guard Node │  ← Tahu IP aslimu, tidak tahu tujuanmu
└─────────────┘
      │ (terenkripsi)
      ▼
┌──────────────┐
│ Middle Node  │  ← Tidak tahu siapa kamu, tidak tahu tujuanmu
└──────────────┘
      │ (terenkripsi)
      ▼
┌─────────────┐
│  EXIT NODE  │  ← ☠️ TITIK YANG DIMAKSUD DI FILM
└─────────────┘     Tahu TUJUAN traffic, TIDAK tahu siapa pengirimnya
      │             Tapi bisa baca ISI jika HTTP (bukan HTTPS)
      ▼
  [Internet Biasa — reddit.com, dsb]
```

Pengguna perlu berhati-hati dalam menggunakan exit node, karena exit node dapat membaca traffic HTTP yang tidak dienkripsi.

### Kenapa Bandwidth Exit Node Sangat Besar

Bandwidth exit node sangat besar karena setiap user Tor yang exit melalui node kamu = seluruh traffic mereka melewati koneksi internetmu. Jika 1.000 user simultan masing-masing mengonsumsi 1Mbps → kamu butuh **1Gbps uplink**.

### 🔗 Lihat Juga

- [[network-security|Network Security]]
- [[hierarchy-ai-levels|AI Levels Hierarchy]]
- [[cheatsheet|Cheat Engine]]
- [[military-and-intelligence-tools-hub|military-and-intelligence-tools-hub]]
- [[military-intelligence-tools-hierarchy|military-and-intelligence-tools Hierarchy]]

Dalam menggunakan layanan online, pengguna perlu berhati-hati dan memahami risiko yang terkait. Dengan memahami hierarki pencarian informasi, pengguna dapat lebih baik dalam mengakses informasi yang mereka butuhkan. Selain itu, pengguna juga perlu memahami cara mengakses setiap level dan menggunakan teknik yang tepat untuk meningkatkan keamanan dan anonimitas.
