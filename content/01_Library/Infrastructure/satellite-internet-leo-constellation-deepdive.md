---
title: 'Satellite Internet & LEO Constellation — Deep Dive Teknis'
tags:
- satellite
- leo
- starlink
- kuiper
- oneweb
- broadband
- infrastructure
- latency
- wireless
aliases:
- starlink-architecture
- leo-satellite-constellation
- satellite-broadband-deepdive
created: '2026-08-06'
updated: '2026-08-06'
status: pending
cssclasses:
- wide-table
---

# 🛰️ Satellite Internet & LEO Constellation — Deep Dive Teknis

> [!abstract]
> Internet satelit kembali menjadi tulang punggung konektivitas global setelah era kegagalan Iridium dan Teledesic di awal 2000-an. Gelombang baru konstelasi **Low Earth Orbit (LEO)** — dipimpin Starlink, OneWeb, dan Project Kuiper — memecah paradoks lama satelit geostasioner: kecepatan tinggi vs latensi 600 ms. Dengan menurunkan orbit ke 500–1.200 km, latensi turun hingga 25–40 ms (setara serat optik) dan throughput mencapai 100 Mbps–1 Gbps per pelanggan. Catatan ini memetakan arsitektur fisik konstelasi, spesifikasi satelit, frekuensi Ku/Ka, inter-satellite laser links, ground segment, perbandingan pemain komersial, regulasi spektrum, hingga implikasi astronomi dan orbital debris.
> Vault sudah punya [[hierarchy-computer-networks]] (lapisan fisik dan transport terestrial) — catatan ini melengkapi dari sisi medium fisik nirkabel di orbit, dan berpasangan dengan [[hierarchy-wireless]] serta [[networking-fundamentals-tcpip-bgp]].

---

## Daftar Isi

1. [[#1. Mengapa LEO — Masalah Latensi Geostasioner]]
2. [[#2. Arsitektur Konstelasi LEO]]
3. [[#3. Orbital Shell — Altitude dan Bidang Orbit]]
4. [[#4. Perangkat Keras Satelit — Propulsi dan De-orbit]]
5. [[#5. Spektrum Frekuensi dan Antena Phased-Array]]
6. [[#6. Inter-Satellite Laser Links (ISL)]]
7. [[#7. User Terminal dan Ground Gateway]]
8. [[#8. Perbandingan Pemain Utama]]
9. [[#9. Latensi dan Throughput Real]]
10. [[#10. Regulasi Spektrum dan ITU/FCC]]
11. [[#11. Dampak Astronomi dan Orbital Debris]]
12. [[#Koneksi ke Vault]]

---

## 1. Mengapa LEO — Masalah Latensi Geostasioner

Satelit geostasioner (GEO) berada 35.786 km di atas ekuator. Sinyal radio menempuh dua kali jarak tersebut (uplink + downlink), sehingga **round-trip latency minimum ~477 ms** antara pengguna dan stasiun bumi; dalam praktik nyata 600 ms atau lebih. Untuk aplikasi interaktif (voice call, gaming, API real-time), latensi ini tidak dapat digunakan.

Konstelasi LEO menurunkan satelit ke **500–1.200 km** — kira-kira 1/30 hingga 1/70 ketinggian GEO — sehingga latensi pengguna-ke-satelit-ke-bumi turun ke **25–35 ms**, setara kabel serat optik terestrial. Inilah alasan utama "Internet in the Sky" generasi kedua berhasil, sementara generasi pertama (Iridium, Teledesic) bangkrut karena biaya peluncuran tinggi dan pasar yang belum siap.

> [!note]
> Konteks historis: konsep konstelasi LEO pertama kali dirancang pada pertengahan 1980-an dalam program **Brilliant Pebbles** (Strategic Defense Initiative AS), yang menempatkan senjata di orbit rendah untuk mencegat misil balistik. Turunan komersialnya di tahun 1990-an adalah Iridium, Globalstar, dan Teledesic — semuanya gagal secara finansial.

| Parameter | GEO | LEO | MEO |
|:----------|:-----:|:-----:|:-----:|
| Altitude | ~35.786 km | 500–1.200 km | ~20.000 km |
| Latensi RTT | ≥477 ms | 25–40 ms | ~120 ms |
| Cakupan | Global (3–4 satelit) | Regional per satelit | Regional |
| Contoh | HughesNet, Viasat | Starlink, OneWeb, Kuiper | O3b (MEO) |
| Jumlah satelit | Puluhan | Ribuan | Puluhan |

---

## 2. Arsitektur Konstelasi LEO

Satelit LEO mengelilingi bumi setiap ~90–120 menit. Satu satelit hanya terlihat dari satu titik di permukaan selama **beberapa menit**, sehingga dibutuhkan ratusan hingga ribuan satelit untuk cakupan yang terus-menerus.

```
        ◎ (satelit LEO, ~550 km)
        │     beam Ku/Ka
        │
   ┌────┴────┐        ┌──────────┐
   │  User   │        │  Gateway │
   │ terminal│        │ ground st│
   └─────────┘        └──────────┘
        ↑ ISL (laser)   ↑
```

Struktur konstelasi dirancang dalam **orbital shell** — kelompok bidang orbital pada ketinggian dan inklinasi tertentu. Shell-shell ini saling overlap membentuk jaring selular di langit, menjamin selalu ada satelit dalam jangkauan setiap titik di permukaan.

---

## 3. Orbital Shell — Altitude dan Bidang Orbit

### Starlink (SpaceX)
- Gen1: 4.425 satelit yang disetujui FCC (Maret 2018), dioperasikan pada shell ~**550 km**.
- Shell operasional v1: 1.584 satelit (72 planes × 22), pada ketinggian 550–570 km.
- Gen2 (v2): 7.500 satelit disetujui (Desember 2022) pada shell 525, 530, dan 535 km; total izin hingga 29.988 satelit.
- V2 Mini (diluncurkan sejak Februari 2023): ~800 kg, dua solar array.
- V2 penuh (direncanakan dibawa Starship): ~2.000 kg, solar array 20 m.

Pilihan ketinggian 550 km memudahkan de-orbit: bila satelit gagal, drag atmosfer menurunkan orbit dan satelit terbakar dalam waktu relatif singkat.

### OneWeb (Eutelsat OneWeb)
- 648 satelit generasi pertama (12 planes × 49, plus spares on-orbit), massa ~150 kg.
- Orbit **1.200 km**, inklinasi 86,4° (hampir polar — optimal untuk cakupan lintang tinggi).
- Desain awal 18 planes × 49 satelit, direduksi setelah cakupan terbukti cukup.
- Tidak memiliki inter-satellite link pada Gen1; hanya dapat melayani area yang terjangkau gateway.

### Project Kuiper (Amazon Leo)
- 3.236 satelit dalam 98 bidang orbital, tiga shell: **590 km, 610 km, dan 630 km**.
- Fase 1: 578 satelit di 630 km, inklinasi 51,9°.
- Prototipe KuiperSat-1/2 terbang Oktober 2023; 396 satelit produksi telah diluncurkan per Juli 2026.

| Pemain | Jumlah | Altitude | Bidang/Inklinasi | Massa/satelit |
|:-------|:------:|:--------:|:-----------------|:-------------:|
| Starlink Gen1 | 4.425 | 550 km | 72 planes | 260–800 kg |
| Starlink Gen2 | ~29.988 (izin) | 525–605 km | bervariasi | 800–2.000 kg |
| OneWeb Gen1 | 648 | 1.200 km | 12 planes, 86,4° | 150 kg |
| Kuiper | 3.236 | 590/610/630 km | 98 planes | ~100-an kg |

---

## 4. Perangkat Keras Satelit — Propulsi dan De-orbit

### Struktur fisik

```
        [Solar Array]
              │
 [Payload RF] ──[Phased Array Ku/Ka]──[Laser ISL pod]
              │
     [Hall-effect thruster → propulsion]
              │
     [Propellant: Krypton/Argon]
```

### Thruster
- Semua pemain utama memakai **Hall-effect thruster** (ion propulsion): dorongan kecil namun efisien, mengionisasi gas **krypton** atau **argon** untuk orbit raising, station keeping, dan de-orbit.
- Starlink Gen1 memakai krypton — erosi channel lebih tinggi dibanding xenon, tetapi krypton jauh lebih melimpah dan murah.
- Thruster Gen2 Starlink memakai argon, diklaim 2,4× thrust dan 1,5× specific impulse dibanding versi krypton.
- OneWeb dan Kuiper juga dilengkapi Hall-effect thruster.

### De-orbit / Decommission
- Satelit dirancang hidup ~5–7 tahun; di akhir masa pakai, propulsi menurunkan orbit hingga masuk atmosfer dan terbakar terkendali.
- NASA mensyaratkan keandalan de-orbit >90%; SpaceX mengadopsi standar lebih tinggi lagi.
- OneWeb mengikuti pedoman mitigasi orbital debris internasional: de-orbit dalam waktu 25 tahun setelah pensiun.

---

## 5. Spektrum Frekuensi dan Antena Phased-Array

SpaceX mengajukan lisensi ke FCC pada November 2016 untuk layanan NGSO pada **Ku-band** (user downlink) dan **Ka-band** (gateway uplink). Pola ini diikuti para pesaing:

- OneWeb: user service di **Ku-band**, link gateway di **Ka-band**.
- Kuiper: **Ka-band** untuk user terminal phased-array.
- Starlink v2 Mini (Februari 2023+): tambahan frekuensi **71–86 GHz (W/E band)** untuk gateway.

### Tabel Band

| Band | Range | Penggunaan |
|:-----|:------|:-----------|
| L | 1–2 GHz | Mobile satellite (Iridium, Inmarsat) |
| Ku | 11,7–18 GHz | Starlink user, OneWeb user, DTH TV |
| Ka | 26–40 GHz | Gateway, high-throughput, Kuiper user |
| V | 40–75 GHz | Eksperimen Gen2 |
| W/E | 71–86 GHz | Starlink v2 Mini gateway links |

> [!warning]
> Karena orbit rendah dan jumlah satelit masif, total daya pancar konstelasi dapat menimbulkan **Equivalent Power Flux Density (EPFD)** yang mengganggu sistem GEO. ITU menetapkan batas EPFD; SpaceX dan Romania menguji penaikan batas tersebut (2024) untuk meningkatkan kecepatan dan cakupan.

### Antena phased-array
Semua pemain memakai **phased array antenna** — susunan ratusan elemen dengan kontrol fase digital yang membentuk dan mengarahkan beam secara elektronis, tanpa motor fisik. Inilah yang memungkinkan terminal melacak satelit yang bergerak ~7,5 km/s.

---

## 6. Inter-Satellite Laser Links (ISL)

Fitur pembeda terbesar Starlink (dan rencana Kuiper) dibanding OneWeb Gen1:

- **Tanpa ISL**: satelit wajib berada dalam jangkauan gateway terestrial. Trafik naik ke satelit lalu langsung turun ke stasiun bumi, kemudian masuk internet terestrial.
- **Dengan ISL** (optical inter-satellite link): paket diteruskan antar satelit melalui laser sampai mendekati gateway tujuan. Manfaatnya:
  1. Melayani daerah tanpa stasiun bumi: lautan, kutub, wilayah remote.
  2. Menurunkan latensi dibanding hop terestrial yang berbelok.

Fakta penting:
- Starlink satelit awal (v1) diluncurkan tanpa laser; uji ISL sukses akhir 2020, dan kini menjadi standar.
- Antartika tidak memiliki gateway — koneksi dilakukan via ISL ke stasiun bumi di Chile, Selandia Baru, dan Australia.
- OneWeb Gen1 **tidak punya ISL** — ini membatasi layanan hanya pada area dengan gateway; satelit demo Gen2 "JoeySat" menguji laser ISL.
- Laser komunikasi luar angkasa bukan teknologi baru (ESA/NASA sudah memakainya sejak 2000-an, mis. sistem EDRS), tetapi penerapannya di konstelasi mass-market inilah yang baru.

---

## 7. User Terminal dan Ground Gateway

### Terminal pengguna
- **Starlink**: "Dishy" — phased array self-aligning, ~$200–500 untuk perangkat; **Starlink Mini** (Juni 2024) mendukung 100 Mbps dan muat di ransel.
- **Starlink Business**: antenna high-performance, kecepatan 150–500 Mbps, prioritas dukungan 24/7.
- **Kuiper**: tiga kelas terminal — Leo Nano (7 inci², 100 Mbps), Leo Pro (11 inci², 400 Mbps), Leo Ultra (20×30 inci, hingga 1 Gbps download / 400 Mbps upload; beberapa unit bisa digabung).
- **OneWeb**: terminal mirip VSAT, pemasangan oleh installer (segmen enterprise).

### Ground gateway
- Gateway = stasiun bumi yang menghubungkan satelit ke internet terestrial (fiber backbone).
- Starlink memiliki puluhan gateway; v2 Mini menambah band frekuensi baru untuk backhaul.
- OneWeb membutuhkan gateway di setiap wilayah layanan — karena tidak ada ISL, ini pernah menjadi hambatan operasional.

> [!note]
> Model trafik dua arah: user ↔ satellite ↔ (gateway terdekat) ↔ fiber terestrial ↔ internet. Alternatif: user ↔ (serial ISL antar satelit) ↔ gateway jauh.

---

## 8. Perbandingan Pemain Utama

| Kriteria | Starlink | OneWeb | Kuiper |
|:---------|:---------|:-------:|:------:|
| Operator | SpaceX | Eutelsat OneWeb | Amazon |
| Total satelit (2026) | 10.397 operasional (Juni 2026) | 652 (selesai) | 396 produksi |
| Pelanggan | 12 juta+ (Juni 2026) | B2B/gov | pilot/beta |
| Latensi target | 20–40 ms | — | — |
| ISL | Ya (laser) | Belum (Gen1) | Direncanakan |
| Band | Ku/Ka → W | Ku (user), Ka (gateway) | Ka |
| Segmen pasar | Konsumen + enterprise + mobility | Enterprise, government | Konsumen + enterprise |

- **Starlink** — first mover dan terbesar: ±75% satelit aktif maneuverable di orbit bumi, melayani 160+ negara, termasuk konektivitas pesawat dan kapal.
- **OneWeb** — merger dengan Eutelsat; fokus enterprise/B2B dan pemerintahan, cakupan lintang tinggi (polar) tanpa retail konsumen.
- **Kuiper** — Amazon mengontrak 92 peluncuran (ULA, ArianeGroup, Blue Origin, bahkan Falcon 9) senilai $10 miliar; masih di fase awal, FCC menunda deadline setengah konstelasi dari Juli 2026.

---

## 9. Latensi dan Throughput Real

- Starlink beta ("Better Than Nothing Beta", Okt 2020): ekspektasi 50–150 Mbps dan latensi 20–40 ms.
- Starlink saat ini: hasil uji mandiri bervariasi antara 50–500 Mbps tergantung region, beban jaringan, dan plan layanan.
- Kuiper: Leo Nano 100 Mbps, Pro 400 Mbps, Ultra 1 Gbps.
- OneWeb: layanan enterprise, throughput per terminal ~400 Mbps.

### Perbandingan latensi medium

| Medium | RTT | Tipe |
|:-------|:------:|:------:|
| Fiber (antar-pantai) | 10–20 ms | Terestrial |
| LEO satcom | 25–40 ms | Satelit orbital |
| GEO satcom | ≥500 ms | Geostasioner |
| Broadband kabel | 5–20 ms | Terestrial |

LEO adalah satu-satunya medium satelit yang mendekati fiber dari sisi latensi. Uji Ookla menunjukkan performa bervariasi seiring pertumbuhan pelanggan dan penambahan satelit.

---

## 10. Regulasi Spektrum dan ITU/FCC

- **ITU (International Telecommunication Union)**: mengelola spektrum dan slot orbital; menetapkan batas EPFD untuk melindungi sistem GEO.
- **FCC (AS)**: lisensi Gen1 Starlink (2018), Gen2 (2022); persetujuan negara asing diperlukan untuk beroperasi (Kanada pertama, November 2020).
- **Kuiper**: lisensi 3.236 satelit (Juli 2020), kewajiban meluncurkan setengah konstelasi per Juli 2026 — ditunda FCC Juni 2026 dengan sanksi penurunan prioritas spektral untuk satelit yang terlambat.
- Ku/Ka band juga dipakai layanan lain (DTH TV, broadcast); koordinasi frekuensi antar sistem NGSO dan GEO di ITU sangat rumit.

---

## 11. Dampak Astronomi dan Orbital Debris

### Astronomi
- Ribuan satelit terang di orbit rendah menimbulkan garis-garis (trails) pada CCD teleskop dan mengganggu observasi astronomi — kekhawatiran utama komunitas astronom (satelit dapat terlihat dengan mata telanjang).
- Megakonstelasi meningkatkan polusi cahaya langit malam secara global.

### Orbital debris
- Dengan 10.000+ satelit aktif, risiko tabrakan di LEO meningkat signifikan; debris >10 cm diperkirakan puluhan ribu objek.
- Mitigasi: de-orbit propulsif, kepatuhan pedoman ITU (<25 tahun), manuver otonom untuk menghindari tabrakan (Starlink melakukan ribuan manuver per tahun).

### Keamanan dan militer
- Starlink menjadi tulang punggung komunikasi Ukraina sejak invasi Rusia 2022; narrow beam-nya lebih tahan jamming dibanding satelit GEO.
- **Starshield** — divisi militer SpaceX: kontrak SDA Proliferated LEO (2023) untuk komunikasi satelit militer AS.

---

## 12. Kesimpulan

1. Konstelasi LEO memecahkan tiga masalah klasik satelit: **latensi**, **throughput**, dan **cakupan global** di wilayah tanpa fiber.
2. Enabler utamanya: phased-array, Hall-effect thruster, laser ISL, dan biaya peluncuran rendah yang memungkinkan ribuan satelit.
3. Persaingan berpusat pada spektrum Ku/Ka dan kecepatan membangun konstelasi — Kuiper masih tertinggal, OneWeb fokus enterprise.
4. Masa depan: laser ISL generasi baru, konektivitas mobility (pesawat, kapal, kendaraan), dan integrasi dengan 5G/6G non-terestrial.

---

## References

1. Wikipedia — Starlink. https://en.wikipedia.org/wiki/Starlink
2. Starlink — Technology (official). https://www.starlink.com/technology
3. Wikipedia — Project Kuiper (Amazon Leo). https://en.wikipedia.org/wiki/Project_Kuiper
4. Wikipedia — Eutelsat OneWeb. https://en.wikipedia.org/wiki/OneWeb
5. Wikipedia — Low Earth Orbit. https://en.wikipedia.org/wiki/Low_Earth_orbit
6. Wikipedia — Satellite Internet access. https://en.wikipedia.org/wiki/Satellite_Internet_access
7. GSMA — Satellite Communications Regulatory Guide. https://www.gsma.com/spectrum/wp-content/uploads/2024/06/Satellite-communications-regulatory-guide.pdf
8. Wikipedia — Phased array antenna. https://en.wikipedia.org/wiki/Phased_array
9. Wikipedia — Laser communication in space. https://en.wikipedia.org/wiki/Laser_communication_in_space
10. Wikipedia — Ka-band. https://en.wikipedia.org/wiki/Ka-band
11. SpaceX — Starshield. https://www.spacex.com/starshield/
12. Wikipedia — SpaceX Starshield. https://en.wikipedia.org/wiki/SpaceX_Starshield
13. Wikipedia — Iridium Satellite Constellation. https://en.wikipedia.org/wiki/Iridium_satellite_constellation

---

## Koneksi ke Vault

| Catatan | Koneksi |
|:--------|:--------|
| [[hierarchy-computer-networks]] | Medium fisik/transport — LEO melengkapi lapisan fisik terestrial |
| [[hierarchy-wireless]] | Band Ku/Ka dan cakupan radio — perluasan spektrum nirkabel |
| [[networking-fundamentals-tcpip-bgp]] | RTT/latensi layer transport — konteks perbandingan medium |
| [[wireguard-vpn-architecture-deepdive]] | Konektivitas daerah blank spot — solusi satelit vs VPN terestrial |
| [[offline-internet-indonesia]] | Daerah blank spot Indonesia — satelit sebagai alternatif infrastruktur |
