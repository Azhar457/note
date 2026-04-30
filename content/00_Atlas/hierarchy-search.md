### 🌐 Hierarki Pencarian Informasi — Surface sampai Beyond Dark Web

| Level & Ekosistem                                                                          | Cara Akses                                                         | Konten yang Ada                                                                                                                                                                         | ☠️ Risiko & Tembok                                                                                                                                                    | 🔵 Siapa yang Memantau                                                                                                 |
| ------------------------------------------------------------------------------------------ | ------------------------------------------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- |
| **Level 0** — Surface Web _(Google, Bing, DuckDuckGo)_                                     | Browser biasa                                                      | ~4% dari total internet. Berita, sosmed, e-commerce, Wikipedia. Semua terindeks crawler.                                                                                                | Tidak ada risiko teknis. Data kamu dijual ke advertiser.                                                                                                              | ISP, Google, Cloudflare, pemerintah via PRISM                                                                          |
| **Level 1** — Semi-Hidden Web _(Paywalls, Login-gated, Google Dorks)_                      | Browser + teknik pencarian lanjut (`site:`, `filetype:`, `inurl:`) | Database bocor yang belum dihapus, dokumen internal yang salah konfigurasi, CCTV publik yang terbuka, court records.                                                                    | Legal abu-abu tergantung yurisdiksi. Mengakses sistem tanpa izin = ilegal meski "terbuka".                                                                            | Pemilik server via access log, Shodan memantau semua IP publik                                                         |
| **Level 2** — Deep Web _(Database akademik, intranet, cloud storage)_                      | Kredensial valid, VPN korporat, akses institusi                    | Jurnal ilmiah (Sci-Hub), rekam medis, email korporat, source code internal, dataset pemerintah non-publik.                                                                              | Credential theft adalah vektor utama. Bukan "gelap" — hanya tidak terindeks.                                                                                          | Admin IT internal, SIEM perusahaan, audit trail database                                                               |
| **Level 3** — Dark Web via Tor _(Ahmia, Torch, The Hidden Wiki, .onion sites)_             | Tor Browser → relay 3 node (Guard → Middle → Exit)                 | Forum peneliti, whistleblower platform (SecureDrop), marketplace ilegal, leak database, ransomware blog, layanan anonim legitimate.                                                     | Exit node bisa membaca traffic HTTP yang tidak dienkripsi. Opsec buruk = terekspos.                                                                                   | **Exit node operator**, NCA, FBI (Operation Onymous), Europol                                                          |
| **Level 4** — Tor Exit Node Position _(Konsep film yang kamu maksud)_                      | Daftar jadi exit node (bandwidth besar wajib)                      | **Semua traffic yang melewatimu** dari user Tor ke internet biasa. Bisa lihat: URL tujuan, konten HTTP, DNS query, metadata — jika traffic tidak dienkripsi E2E.                        | Bandwidth konsumsi masif (bisa 100Mbps+). ISP kamu akan melihat traffic aneh. Di beberapa negara, exit node operator pernah ditangkap karena traffic pengguna mereka. | Kamu memantau orang lain, tapi **kamu juga dipantau** oleh: Tor Project, researcher, LE yang monitoring exit node list |
| **Level 5** — I2P & Freenet _(Invisible Internet Project, Freenet, Zeronet)_               | Client I2P / Freenet terpisah                                      | Jaringan garlic routing (lebih anonim dari Tor). Konten persisten terdistribusi — tidak ada server tunggal yang bisa di-takedown. Lebih lambat, lebih anonim.                           | Traffic tidak keluar ke clearnet — tertutup dalam ekosistemnya. Lebih sulit dimonitor tapi bukan mustahil via traffic analysis.                                       | Researcher akademis, jarang LE karena kompleksitasnya                                                                  |
| **Level 6** — Private Overlay Networks _(Riffle, Loopix, Nym Network, Mixnets)_            | Undangan / komunitas tertutup                                      | Akademisi, intelligence community, aktivis di negara otoriter. Dirancang tahan traffic analysis — bahkan observer yang melihat seluruh jaringan tidak bisa korelasikan sender-receiver. | Setup sangat teknis. Komunitas sangat kecil.                                                                                                                          | Belum ada teknik deteksi yang terbukti efektif untuk mixnet yang benar                                                 |
| ☠️ **Level 7** — Nation-State Intelligence Feeds _(XKEYSCORE, Palantir, Five Eyes SIGINT)_ | Tidak bisa diakses publik — backbone ISP level, undersea cable tap | Seluruh traffic internet global yang tidak dienkripsi, metadata komunikasi, pola perilaku agregat. XKEYSCORE bisa query "semua aktivitas seseorang di internet" dalam hitungan detik.   | Snowden documents (2013) membuktikan ini nyata dan sudah operasional sejak 2007.                                                                                      | NSA, GCHQ, ASD, CSIS, DGSE — Five Eyes + Nine Eyes + Fourteen Eyes                                                     |

---

### Anatomi Posisi Exit Node (Yang di Film)

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

> [!danger] Realita Exit Node Peneliti Dan Egerstad (2007) menjalankan 5 exit node, berhasil intercept **ribuan kredensial** email diplomat dan NGO internasional yang menggunakan Tor tapi lupa bahwa exit node bisa baca traffic HTTP. Dia ditangkap bukan karena hacking — tapi karena **memiliki informasi yang seharusnya tidak dia punya**.

---

### Kenapa Bandwidth Exit Node Sangat Besar

> [!info] Matematika Sederhana Setiap user Tor yang exit melalui node kamu = seluruh traffic mereka melewati koneksi internetmu. Jika 1.000 user simultan masing-masing mengonsumsi 1Mbps → kamu butuh **1Gbps uplink**. Operator exit node besar (relay besar) bisa mengonsumsi 10–40TB/bulan. Ini yang membuat mayoritas exit node dioperasikan oleh universitas, perusahaan hosting, atau... intelligence agency yang pura-pura menjadi relay sukarela.

---

### 🔗 Lihat Juga

- [[NETWORK_SECURITY]]
- [[AI_LEVELS_HIERARCHY]]
- [[CHEAT]]
