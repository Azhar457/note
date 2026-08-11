# Telegram Group/Channel Search Engines (OSINT)

**Source:** Riset search engine Telegram (2026-08-09)
**Use case:** Threat intel, OSINT, menemukan grup/channel publik tanpa akun Telegram

## Tool List

### 1. Telegago — Free, No Account
- Google Custom Search Engine khusus konten publik Telegram
- Tidak perlu akun Telegram untuk cari channel/grup
- URL: `https://cse.google.com/cse?cx=006368593537057042503:efxu7xprihg`

### 2. TelegramDB — Freemium, Account Required
- Bot + web service untuk pencarian mendalam grup/channel publik
- Cara pakai: bot `@tgdb_search_bot` di Telegram atau situs web resmi
- Fitur gratis: `/search` (20 hasil pertama gratis), `/resolve` (ID → username)
- Fitur berbayar (kredit): `/where` (cari grup yang pernah diikuti user tertentu), `/members` (export daftar anggota grup)

### 3. Telemetry — Freemium, Account Required
- Search engine yang mengindeks konten publik Telegram
- Berguna untuk konten yang tidak terindeks Google
- URL: `https://www.telemetryapp.io/` (daftar akun dulu)
- Harga: gratis terbatas (15 kredit), paket berbayar untuk akses luas

### 4. Waybien — Freemium, No Account for Basic
- Search engine multi-platform: Telegram, Facebook, Discord, WhatsApp
- URL: `https://waybien.com/en` — pencarian dasar gratis, fitur lanjutan berbayar

### 5. Lyzem
- Sering disebut komunitas OSINT sebagai search engine channel/grup Telegram
- (Detail perlu verifikasi lebih lanjut)

## Quick Reference
| Tool | Account | Gratis | URL |
|---|---|---|---|
| Telegago | Tidak | Ya | cse.google.com (cx=006368593537057042503:efxu7xprihg) |
| TelegramDB | Ya | 20 hasil/search | @tgdb_search_bot |
| Telemetry | Ya | 15 kredit | telemetryapp.io |
| Waybien | Tidak (basic) | Basic | waybien.com/en |
| Lyzem | Tidak | Ya | lyzem.com/search?q=<keyword> |
| TgramSearch | — | — | tgram.me (DNS mati saat tes 2026-08-09) |
| Tlgrm.eu | Tidak | Ya | tlgrm.eu (landing page, perlu kategori) |
| OSINT.ME CSE | Tidak | Ya (API 403 bot) | cse.google.com |

---

# ADVANCED OSINT — Deep Investigation Tools

## 1. TelegramDB (TgDB Search Plus) — Deep User Footprinting

Bot: `@tgdb_search_bot` / web Premium. Paling canggih untuk lacak jejak digital user.

| Perintah | Fungsi | Biaya |
|---|---|---|
| `/search` | Cari grup/channel publik via keyword | Gratis 20 hasil, lanjut kredit |
| `/where [username]` | **Tampilkan SEMUA grup publik yang pernah diikuti user** — jejak tersimpan walau sudah keluar grup | Kredit |
| `/members` | Export daftar anggota grup ke CSV | Kredit |
| `/network` | Cari channel/grup dengan audiens mirip (overlap) | Kredit |
| `/near` | Cari user "terdekat" dengan target (pola join grup) | Kredit |

**`/where` adalah killer feature** — footprint user yang nyaris mustahil via cara lain.

## 2. Telemetry — Deep Content & Analytics

- Search engine: >1 juta channel, 2.5 miliar pesan terindeks
- **Boolean search** (AND, OR, NOT) di dalam konten pesan
- **Channel Analytics:** engagement, subscriber count, mention antar-channel, tipe postingan dominan
- Mengindeks **pesan**, bukan cuma channel
- Harga: 15 pencarian/hari gratis (25 hasil/pencarian), paid mulai $29/bulan

## 3. Maltego Telegram Transforms (Expert OSINT)

Plugin Maltego untuk visualisasi relasi + de-anonimisasi:

- 📱 Cari profil Telegram via nomor HP
- 👥 Grup terhubung dengan channel tertentu
- 🛡 List admin grup
- 😀 **De-anonimisasi via stiker:** tiap sticker pack punya ID yang menyisipkan UID pembuat → ekstrak UID → resolve ke username
- 🔗 Visualisasi similar channel (audiens overlap)
- 🗑 Deteksi postingan dihapus & cari arsip (via gap di ID postingan)

Level: investigasi relasi antar channel, temukan pembuat konten anonim.

## 4. Alternatif Tambahan

- **TgramSearch** — katalog >700.000 channel, filter bahasa/region
- **Tlgrm.eu** — direktori channel by kategori
- **OSINT.ME Telegram CSE** — Google CSE alternatif Telegago (hasil bisa beda)

## 5. Telegram Groups Parser (DIY)

Open-source scraper buat build search engine sendiri:

1. Jalankan parser dengan daftar keyword (`queries.txt`, `cities.txt` + `words.txt`)
2. Auto-cari grup/channel cocok keyword → simpan ke `groups.json` + jumlah partisipan
3. Ekstrak ID grup & username
4. Web interface (React + API) untuk management

## Tingkatan Kedalaman

| Level | Tool | Kemampuan |
|---|---|---|
| Basic | Telegago, Lyzem | Cari grup/channel via keyword (permukaan) |
| Intermediate | Telemetry | Cari pesan di dalam grup, analisis channel |
| Advanced | TelegramDB (`/where`, `/network`) | Lacak jejak user, network overlap, ekspor anggota |
| Expert | Maltego Transforms | De-anonimisasi, visualisasi relasi, deteksi admin, stiker tracing |
| DIY | Telegram Groups Parser | Build index sendiri, scraping massal |

## Kombinasi Paling Powerful (Deep Search)
1. **Telemetry** → search konten pesan
2. **TelegramDB `/where`** → footprinting user
3. **Maltego Transform** → visualisasi network
