---
title: Dark Patterns Resistance
tags: [security, ux, privacy, social-engineering]
aliases: [dark-patterns-resistance]
---
# Dark Patterns Resistance

Dark pattern = desain UI yang sengaja menyesatkan user untuk melakukan hal yang menguntungkan bisnis tapi merugikan user (kepercayaan, privasi, uang). Dari sudut keamanan: dark patterns adalah bentuk manipulasi — saudara dari social engineering. Memahami dark patterns penting untuk: (1) melindungi user (blue team / UX security), (2) mengenali manipulasi saat red team / pentest (pretexting, phishing), (3) desain produk yang etis.

## Jenis Dark Patterns (Klasifikasi)

### 1. Misdirection & Deception
- **Hidden costs** — biaya disembunyikan sampai checkout.
- **Confirmshaming** — guilting user: "No thanks, I prefer to pay full price."
- **Forced action** — mewajibkan aksi (subscribe) untuk fungsi dasar.
- **Disguised ads** — iklan disamarkan sebagai konten asli/notifikasi.
- **Sneak into basket** — item ditambahkan tanpa persetujuan.

### 2. Interface Interference
- **Preselection** — opsi default menguntungkan bisnis (opt-in newsletter, share data).
- **Confusing wording** — bahasa membingungkan ("unsubscribe" tersembunyi).
- **Infinite scroll / nagging** — hambatan keluar dari layanan.
- **Hidden subscription** — trial gratis auto-perpanjang tanpa reminder.

### 3. Privacy Zuckering
- Menipu user mengizinkan data sharing lebih luas dari yang disadari.
- **Extremely long T&C** — menyembunyikan klausa penting.
- **Privacy-intrusive defaults** — tracking default ON.

### 4. Dark Nudges
- **Scarcity pressure** — "hanya 3 tersisa!" (palsu).
- **Countdown timer** — tekanan waktu artifisial ("berakhir 10:00" selalu reset).

## Counter-Patterns (Resistance Strategy)

**Untuk user / blue team:**
1. **Awareness training** — cara mengenali dark patterns di aplikasi sehari-hari.
2. **Browser extensions**: Privacy Badger, uBlock Origin (block tracking), Consent-O-Matic (auto-opt-out cookie).
3. **Checklist**: halaman terms dibaca di bagian penting; selalu cek "default" sebelum submit.
4. **Report**: laporkan dark pattern (regulator/complaint channel, media konsumen).

**Untuk desainer / product security:**
1. **Design review dengan dark pattern checklist** (Wicked Deceptive Pattern framework).
2. **Transparency by default** (GDPR/CCPA compliance = legal basis).
3. **Testing**: usability testing untuk mendeteksi confusion.
4. **Ethical design principles** — user is not the product; clear consent.

## Regulasi Terkait

| Regulasi | Cakupan | Relevansi Dark Pattern |
|----------|---------|------------------------|
| GDPR (EU) | Data privacy | Persetujuan harus bebas, spesifik, informed, unambiguous; dark pattern consent = melanggar |
| DSA (EU Digital Services Act) | Platform | Larangan dark patterns yang memanipulasi user (misal: consent design) |
| CCPA/CPRA (US) | Data privacy California | "Do Not Sell" opt-out harus jelas, tidak disembunyikan |
| US FTC | Consumer protection | Menuntut dark pattern sebagai unfair/deceptive practice (kasus Epic, Amazon) |
| UU PDP (Indonesia) | Data privacy | Persetujuan eksplisit; praktik menyesatkan = sanksi |

## Kaitan dengan Social Engineering

Dark pattern dan social engineering sama-sama mengeksploitasi bias kognitif:
- **Authority/urgency** — "pejabat meminta", "segera verifikasi".
- **Scarcity** — "kesempatan terakhir".
- **Defaults & inertia** — orang malas = manipulasi default.
- **Confusion** — kebingungan = kelemahan.

Di phishing: halaman login palsu memakai "preselected" checkbox, confusing wording (mirip resmi), dan pressure countdown. Mengenali dark pattern = menyadari manipulasi.

## Deteksi & Audit Dark Pattern (Checklist)

1. Apakah opsi default menguntungkan penyedia (opt-in vs opt-out)?
2. Apakah ada elemen tekanan waktu / scarcity palsu?
3. Apakah biaya/turunan tersembunyi sampai titik lanjut?
4. Apakah keluar layanan (unsubscribe/delete account) lebih sulit dari masuk?
5. Apakah persetujuan data unambiguous & mudah dibatalkan?
6. Apakah ada greeted user dengan guilt/confirmshaming?
7. Apakah T&C/T&C terlampau panjang dengan klausa penting di tengah?

## Tools & Referensi

- **consent.guide** (EU) — panduan design consent yang sah.
- **Deceptive Design** (darkpatterns.org) — katalog + gallery.
- **Wicked Deceptive Patterns** — framework akademik klasifikasi.
- **FTC** case studies dark pattern enforcement.
- **GDPR consent guidelines** (EDPB).

## Red Team Angle

Dark pattern pengetahuan membantu pretexting & phishing realism: tiru pola resmi (urgensi, appeal authority, default trust). Sebaliknya blue team menguji ketahanan user terhadap manipulasi lewat simulated phishing dengan elemen dark pattern (bukan cuma link).

## Koneksi ke Vault

- [[prompt-injection-defense]] — dark pattern = manipulasi, injection = manipulasi input.
- [[security-economics-cost-of-breach]] — dark pattern meningkatkan distrust → churn (cost).
- 03_Resources — UX/design security resources.



## Studi Kasus: Dark Pattern Terkenal

1. **Amazon Prime** — proses unsubscribe berlapis (disebut "Iliad flow") yang membuat keluar sangat sulit; FTC menggugat 2023 (Unsubscribe Act & dark pattern enforcement).
2. **LinkedIn** — preselect "allow connection requests" dan notifikasi; privacy default invasif saat pendaftaran.
3. **Cookie consent teduh** — tombol "Accept all" besar mencolok, "Manage options" kecil abu-abu; DPA Eropa mulai menindak (CNIL denda 100 juta euro ke Google/Facebook 2022 — consent UX).
4. **Game mobile** — loot box dengan mekanik scarcity + "almost won" (dark nudge).

Pelajaran: dark pattern bukan cuma etika — menjadi bahan penegakan hukum. Untuk bisnis, desain consent yang adil justru menurunkan risiko denda dan meningkatkan kepercayaan.

## Menguji Aplikasi untuk Dark Pattern (Methodology)

1. **User journey test**: buat akun baru → coba unsubscribe/delete → catat jumlah langkah, konfirmasi berlapis, opsi tersembunyi.
2. **Default audit**: semua checkbox saat pendaftaran — apa default-nya? (opt-in vs opt-out).
3. **Timing & pressure**: ada countdown? "hanya X tersisa"? (verifikasi kebenaran klaim).
4. **Symmetric friction**: seberapa mudah mendaftar vs keluar — jika keluar 3x lebih sulit, ada dark pattern.
5. **Language audit**: apakah wording menyesatkan (mis. "unsubscribe" sebenarnya hanya mematikan satu kategori).

## Hubungan dengan Phishing & Social Engineering

Penyerang menggunakan teknik yang sama: urgensi palsu ("akun akan diblokir dalam 24 jam"), preset-checkbox di halaman fake consent, atau "one more step" loop. Pelatihan anti-phishing sebaiknya mencakup modul dark pattern recognition — karyawan yang paham manipulasi UI lebih tahan terhadap vektor manipulasi lain.

---

  audited
---