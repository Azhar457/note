---
tags:
  - mobile-forensics
  - forensics
  - android
  - iOS
  - acquisition
  - cellebrite
  - MOBILedit
  - blue-team
aliases:
  - Mobile Forensics
  - Mobile Acquisition Hierarchy
  - UFED vs MOBILedit
created: 2026-05-29
status: operational
cssclasses:
  - wide-table
---

# 📱 MOBILE FORENSICS — Hierarki Akuisisi & Tools

> **Prinsip utama:** Yang menentukan "level" forensik bukan toolnya — tapi **metode akuisisi** yang dipakai. Tool mahal seperti Cellebrite UFED bisa operate di Level 1 (logical biasa) atau Level 4 (exploit-based), tergantung kondisi device. Tool yang sama, output yang sangat berbeda.

> [!info] Hubungan ke Vault
> Ini adalah ekstensi dari [[forensic-data-recovery|Data Recovery Forensik]] dan [[DATA_RECOVERY_FORENSIK|Tools Comparison]] — tapi mobile punya attack surface, filesystem, dan acquisition method yang sama sekali berbeda dari storage tradisional (HDD/SSD).

---

## Mengapa Mobile Berbeda dari PC Forensics

```
PC Forensics:
→ Storage terpisah (HDD/SSD) — bisa dicabut, diimaging
→ File system relatif terbuka (NTFS, ext4)
→ Write-blocker → dd/ddrescue → selesai
→ Enkripsi opsional (BitLocker)

Mobile Forensics:
→ Storage soldered — tidak bisa dicabut tanpa chip-off
→ Full disk encryption ON by default (Android 6+, iOS 8+)
→ Secure Enclave / TEE menyimpan kunci — tidak bisa brute force dari luar
→ Boot lock, USB debugging off by default
→ Cloud sync = data bisa ada di mana-mana selain device

Implikasi:
Setiap "level" akuisisi di mobile jauh lebih sulit
dibanding level yang sama di PC forensics
```

---

## Hierarki Akuisisi Mobile — Level 0 sampai Level 7

| Level | Metode | Yang Didapat | Syarat | Tools | Keterbatasan |
|---|---|---|---|---|---|
| **Level 0** — Manual / UI | Foto layar, screenshot manual, scroll dan rekam | Apa yang terlihat di layar saja | Device nyala, layar bisa diakses | Kamera, mata manusia | Paling terbatas, tidak ada metadata, mudah di-manipulasi |
| **Level 1** — Logical | Backup via ADB (Android) atau iTunes/Finder (iOS) | App data yang di-backup, kontak, pesan, foto (tergantung backup setting) | USB debugging ON (Android), Trust This Computer (iOS) | MOBILedit, Oxygen, Magnet AXIOM, UFED | Tidak semua app di-backup, data terenkripsi end-to-end tidak masuk, tergantung izin backup per-app |
| **Level 2** — Advanced Logical | Full file system via ADB (rooted), AFC2 (jailbroken iOS), cloud extraction | Lebih lengkap dari backup biasa — termasuk app yang opt-out backup | Root access (Android) atau Jailbreak (iOS) | Cellebrite UFED, Oxygen, MOBILedit, XRY | Device harus sudah di-root/jailbreak sebelumnya, atau via exploit |
| **Level 3** — File System via Exploit | Gunakan exploit untuk bypass lockscreen atau elevate privilege tanpa root permanen | File system penuh, database SQLite tiap app, deleted artifacts | Exploit tersedia untuk versi OS target | Cellebrite UFED Premium, GrayKey, Checkm8 (iOS), MOBILedit (beberapa Android) | Exploit spesifik per device/OS — tidak ada "satu exploit untuk semua" |
| **Level 4** — Physical / Full Physical | Dump memory chip secara langsung — bit-for-bit image dari storage | Semua yang ada di storage termasuk deleted space, slack space | EDL Mode (Qualcomm), MTK bypass, atau JTAG | UFED Premium, XRY, MSAB, Oxygen (beberapa device) | Enkripsi penuh berarti physical dump masih terenkripsi — butuh kunci dari device |
| **Level 5** — JTAG / ISP | Akses langsung ke memory chip via debug port (JTAG) atau In-System Programming | Raw memory dump sebelum/tanpa software intervention | Akses fisik ke board, skill soldering, pinout documentation | JTAGulator, RIFF Box, Easy-JTAG, ISP adapter | Risiko merusak device, butuh pinout yang tepat, masih dapat raw encrypted data |
| **Level 6** — Chip-Off | Desolder chip NAND dari board, baca langsung dengan programmer | Raw encrypted memory tanpa boot proses | Lab equipment, hot air station, NAND programmer | UP-828, Flashcat, TNM programmer | Data masih terenkripsi, key encryption ada di Secure Element yang tidak ikut dicabut |
| ☠️ **Level 7** — Secure Element Attack | Serangan terhadap chip yang menyimpan kunci enkripsi (Apple Secure Enclave, Google Titan M) | Kunci dekripsi untuk unlock seluruh storage | Lab forensik negara, side-channel attack capability | Tidak ada tool komersial | Hampir mustahil untuk consumer hardware modern — domain intelligence agency |

---

## Posisi MOBILedit dalam Hierarki

```
MOBILedit Forensic Express Pro:

✅ Level 1 — Logical acquisition (kuat, interface bagus)
✅ Level 2 — Advanced logical (beberapa device dengan kondisi tertentu)
⚠️ Level 3 — Sebagian (tergantung device database yang mereka punya)
❌ Level 4+ — Tidak di-support

[Keyakinan sedang] — kapabilitas berubah setiap update,
verifikasi langsung di mobiledit.com/mobiledit-forensic untuk versi terkini

Kelebihan MOBILedit vs kompetitor:
→ Price point lebih terjangkau dari Cellebrite UFED
→ UI yang relatif mudah untuk non-expert
→ Good untuk: logical extraction, app parsing, report generation
→ Support banyak device termasuk feature phone lama

Kelemahan:
→ Tidak support exploit-based extraction seperti UFED Premium / GrayKey
→ iOS support lebih terbatas dibanding Android
→ Update database device tidak secepat Cellebrite
```

---

## Perbandingan Tools — Head to Head

| Tool | Developer | Level Support | iOS | Android | Harga Approx | Target User |
|---|---|---|---|---|---|---|
| **Cellebrite UFED** | Cellebrite (Israel) | Level 1–4 | ✅ Sangat kuat | ✅ Sangat kuat | $15,000-40,000/tahun | Law enforcement, gov |
| **Cellebrite Premium** | Cellebrite | Level 3–4 (exploit) | ✅ Kunci utama iOS | ✅ | Add-on UFED, sangat mahal | Law enforcement khusus |
| **GrayKey** | Grayshift (US) | Level 3–4 | ✅ iOS specialist | ⚠️ Terbatas | $18,000+ | Law enforcement US |
| **Oxygen Forensic Detective** | Oxygen Forensics (US) | Level 1–3 | ✅ Baik | ✅ Sangat baik | $2,000-8,000 | Forensic lab, enterprise |
| **Magnet AXIOM** | Magnet Forensics (Canada) | Level 1–3 | ✅ Baik | ✅ Baik | $4,000-10,000/tahun | Investigator, enterprise |
| **MOBILedit Forensic** | Compelson (Czech) | Level 1–3 | ⚠️ Terbatas | ✅ Baik | $1,000-3,000 | SME, lab menengah |
| **XRY (MSAB)** | MSAB (Sweden) | Level 1–4 | ✅ Kuat | ✅ Kuat | $10,000-25,000 | Law enforcement EU |
| **Belkasoft Evidence Center** | Belkasoft (US/Russia) | Level 1–3 | ✅ Baik | ✅ Baik | $3,000-8,000 | Investigator |
| **Andriller CE** | Andriller | Level 1–2 | ❌ | ✅ | Gratis / $250 | Hobbyist, researcher |
| **ADB + Manual** | Google (ADB tools) | Level 1–2 | ❌ | ✅ (rooted) | Gratis | Researcher, DIY |

>[!warning] Harga adalah estimasi dan berubah — verifikasi langsung ke vendor
>[Keyakinan rendah] untuk angka harga — lisensi enterprise sangat bervariasi tergantung negosiasi dan region.

---

## Platform-Specific: iOS vs Android

### iOS Forensics — Lebih Terlindungi

```
Tantangan utama iOS:
1. Secure Enclave (chip terpisah) menyimpan kunci enkripsi
   → Tidak bisa extract kunci tanpa unlock device
2. USB Restricted Mode (iOS 11.4.1+)
   → USB tidak bisa transfer data setelah 1 jam tanpa unlock
3. Full Disk Encryption default sejak iOS 8
4. GrayKey dan Cellebrite Premium menggunakan exploit
   → Tapi Apple patch exploit dengan cepat di iOS baru

Timeline penting:
→ iOS < 16: GrayKey bisa full file system di banyak device
→ iOS 17+: jauh lebih susah, exploit lebih sedikit
→ iPhone dengan chip A17+: hampir tidak ada tool komersial yang bisa

Alternatif jika device terkunci:
→ iTunes backup (jika backup pernah dibuat dan tidak terenkripsi)
→ iCloud backup (butuh Apple ID credential)
→ MDM profile (jika device di-manage corporate)
```

### Android Forensics — Lebih Variatif

```
Android lebih beragam tergantung vendor:

Samsung:
→ EDL mode via Test Point di beberapa model lama
→ Samsung FRP bypass lebih banyak dokumentasinya
→ Knox security di flagship sangat ketat

Qualcomm chipset:
→ EDL (Emergency Download Mode) — accessible via 9008 port
→ UFED, Oxygen bisa physical extraction via EDL
→ Butuh bypass QFuse (security fuse) di device modern

MediaTek chipset:
→ Bacaclod / preloader exploit pada versi lama
→ MTK bypass tools (banyak yang tidak resmi)

Praktis untuk Level 1-2:
→ ADB backup: adb backup -apk -shared -all -f backup.ab
→ Root + TWRP: dd if=/dev/block/mmcblk0 of=/sdcard/fullimage.img
→ Frida + script: instrument app runtime untuk extract data
```

---

## Acquisition Decision Flow

```
DEVICE DITEMUKAN
        │
        ▼
Device nyala?
        │
   YA──────────NO
   │            │
   ▼            ▼
Layar terbuka? Coba nyalakan?
   │            → JANGAN! Mungkin auto-encrypt saat boot
   │            → Airplane mode, masukkan Faraday bag
   │            → Bawa ke lab
   │
   YA──────────NO
   │            │
   ▼            ▼
Screenshot +  USB Restricted Mode?
Backup cepat     │
(Level 0-1)   YA──────────NO
               │            │
               ▼            ▼
          Faraday bag    ADB backup
          tunggu         (Level 1)
          forensik lab      │
                        Rooted/Jailbroken?
                            │
                        YA──────NO
                        │       │
                        ▼       ▼
                   Full FS   Coba exploit
                   (Level 2) database tool
                             (Level 3)
```

---

## Artifact yang Bisa Didapat per Level

```
Level 1 (Logical):
✅ Kontak, SMS, Call log
✅ Foto dan video (yang di backup)
✅ Browser history (tergantung app)
✅ Beberapa app data
❌ Deleted data
❌ App yang opt-out backup
❌ Keychain / credential store

Level 2 (Advanced Logical / File System):
✅ Semua di Level 1
✅ Database SQLite tiap app (pesan, activity)
✅ Cache dan thumbnail (termasuk yang sudah "dihapus" dari gallery)
✅ Keychain (iOS, jika full FS access)
✅ Location history (com.apple.routined, Google Timeline)
⚠️ Deleted data — tergantung apakah sudah di-overwrite

Level 3 (Physical / Exploit):
✅ Semua di Level 2
✅ Deleted artifacts (unallocated space scan)
✅ App yang tidak di-backup
✅ Credential yang di-cache
✅ Artifacts forensik yang biasanya tersembunyi

Level 4+ (JTAG/Chip-off):
✅ Raw dump — semua yang pernah ada
⚠️ TAPI: masih terenkripsi jika tanpa kunci dari Secure Element
→ Untuk device modern: raw dump tidak berguna tanpa kunci
```

---

## Open Source / Gratis untuk Research

```
Android:
├── ADB (Android Debug Bridge) — Google, gratis
│   adb backup, adb pull, adb shell
├── Andriller CE — community edition, gratis
│   logical extraction + basic parsing
├── MVT (Mobile Verification Toolkit) — Amnesty Tech
│   deteksi spyware (Pegasus, dll) di iOS/Android backup
│   github.com/mvt-project/mvt
└── Frida — dynamic instrumentation
    intercept runtime app untuk extract data

iOS:
├── libimobiledevice — open source iTunes protocol
│   idevicebackup2 untuk backup tanpa iTunes
├── idevicepair, ideviceinfo — device info
└── MVT untuk analisis backup

Analisis Artifact:
├── Autopsy — GUI forensik, bisa parse mobile backup
├── ALEAPP (Android Logs, Events, And Protobuf Parser)
│   python script, parse Android artifacts
│   github.com/abrignoni/ALEAPP
└── iLEAPP (iOS equivalent dari ALEAPP)
    github.com/abrignoni/iLEAPP
```

---

## Koneksi ke Kasus Nyata

```
SCENARIO 1 — Perusahaan kehilangan device karyawan:
Level yang dibutuhkan : 1-2 (data corporate)
Tools yang tepat      : MDM remote wipe ATAU MOBILedit/Oxygen
                        untuk extract data sebelum wipe

SCENARIO 2 — Investigasi criminal (polisi):
Level yang dibutuhkan : 2-4 (tergantung kunci / enkripsi)
Tools yang tepat      : Cellebrite UFED + GrayKey (iOS)
                        Oxygen + EDL (Android Qualcomm)

SCENARIO 3 — Peneliti security check device sendiri:
Level yang dibutuhkan : 1-3
Tools yang tepat      : ADB + ALEAPP/iLEAPP (gratis)
                        MVT untuk cek spyware

SCENARIO 4 — Recover foto dari HP yang layarnya mati:
Level yang dibutuhkan : 1-2 (jika backup ada) atau 5 (JTAG)
Tools yang tepat      : Coba backup dulu via ADB blind
                        Kalau gagal → JTAG (lab)
```

---

>[!tip] Yang Paling Worth untuk Dipelajari Sekarang
>Tanpa budget untuk Cellebrite/GrayKey:
>1. **ADB commands** — gratis, powerful untuk Android yang USB debugging ON
>2. **MVT** — open source, deteksi spyware di backup, dipakai Amnesty International
>3. **ALEAPP/iLEAPP** — parse artifact dari backup tanpa tool mahal
>4. **Frida** — bukan forensik tool tapi bisa extract data dari running app
>
>Kombinasi ini sudah cukup untuk 60-70% kasus research dan investigasi internal. [Keyakinan sedang] — tergantung device dan kondisi.

>[!warning] Legal Boundary yang Harus Dipahami
>Mobile forensics sangat sensitif secara hukum:
>- Di Indonesia: UU ITE dan UU PDP mengatur akses data pribadi
>- Melakukan akuisisi tanpa izin pemilik / tanpa surat perintah = pelanggaran
>- Bahkan untuk device sendiri: beberapa exploit bisa void warranty
>- Penelitian harus di device sendiri atau dengan consent tertulis yang jelas

---

## 🔗 Lihat Juga

- [[data-recovery|Data Recovery & Forensics]] — PC/HDD forensics sebagai pembanding
- [[DATA_RECOVERY_FORENSIK|Tools Comparison]] — tools recovery general
- [[endpoint-security|Endpoint Security]] — Secure Enclave dan hardware security
- [[KRIPTOGRAFI_BIOMETRIK|Kriptografi]] — enkripsi yang bikin mobile forensics susah
- [[EMBEDDED_SYSTEMS|Embedded Systems]] — JTAG dan chip-off connection
- [[index|Master Index]]

---

*Mobile Forensics | Level 0 (Manual) → Level 7 (Secure Element) · MOBILedit · Cellebrite · GrayKey · iOS vs Android · Open Source Path*
