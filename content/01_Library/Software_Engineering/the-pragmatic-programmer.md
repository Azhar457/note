---
title: The Pragmatic Programmer — Hunt & Thomas
tags:
- library
- software-engineering
created: '2026-07-05'
updated: '2026-07-05'
status: pending
cssclasses:
  - wide-table
  - callout

---
# 🛠 The Pragmatic Programmer
> Andrew Hunt & David Thomas — 1999 (2nd ed 2019)

**Tesis:** Programming itu **craftsmanship** — bukan cuma nulis kode, tapi gimana caranya kamu menangani setiap situasi secara profesional. Pragmatis berarti: ambil tanggung jawab (bukan nyalahin), adaptasi terhadap perubahan (bukan kaku), dan terus investasi di pengetahuan (bukan stagnan). Buku ini lebih ke **mindset** daripada syntax tertentu. Edisi 2 (2019) memperbarui contoh-contoh dengan Git, cloud, dan noSQL, tapi prinsip intinya **timeless**.

**Bedanya dengan Clean Code:** Clean Code ngajarin caranya nulis kode yang bersih. Pragmatic Programmer ngajarin mindset: kapan nulis, kapan refactor, kapan *throw away code*, kapan bilang "kayaknya kita salah pendekatan".

> Analogi: Clean Code = tukang kayu yang bikin lemari rapi. Pragmatic Programmer = tukang kayu yang tau kapan harus bongkar lemari lama dan mulai ulang, kapan kasih lemari kilat ke klien, dan gimana cara tetap belajar teknik baru.

---

## 📌 Kenapa Penting

- **Bukan buku teknis** — ini filosofi jadi developer profesional. Banyak hal kelihatan abstract di atas, tapi setelah 5 tahun kerja baru kelihatan relevansinya.
- **Prinsip timeless** — DRY, Tracer Bullets, Broken Window, Orthogonality. Tetap relevan dari PHP/MySQL tahun 2005 sampai ke Rust/Snowflake tahun 2026.
- **Karena banyak guru** — setiap senior programmer di dunia minimal pernah baca buku ini atau dipengaruhi langsung. Bagus untuk *vocabulary* yang sama dengan tim global.
- **Karir-jangka panjang** — ini buku investasi. Bukan skill teknis yang gampang kadaluarsa, tapi cara piker yang bikin kamu tetap jadi senior yang dihargai 10 tahun lagi.

## 🎯 Key Takeaways — Detail + Contoh

Setiap prinsip dari buku ini punya versi sederhana di permukaan tapi punya depth yang dalam saat dipraktekkan. Penjelasan di bawah fokus ke **kenapa** dan **kapan**, gak cuma *do this* tanpa konteks.

### 1. **The Cat Ate My Source Code** — Responsibility Mater

**Prinsip:** Ambil tanggung jawab penuh atas kode lu. Kalo ada bug di kode lu, gak ada gunanya bilang "browser X gak support", "OS-nya aneh", "API-nya rusak". Yang bisa lu lakukan: **perbaiki atau bungkus** solusinya.

```bash
# Buruk — nyalahin environment
> "Ini gak jalan di Windows."
> "Itu bug di dependency X."
> "PM-nya ganti requirement terus."

# Pragmatis — ambil ownership
> "Saya cek di Windows — issue ada di path handling. Saya patching."
> "Dependency X bug-nya saya bungkus dengan workaround di wrapper class."
> "Saya bikin script untuk auto-detect requirement changes."
```

**Knock-on test:** Setelah deploy, ada user complain. Sapa yang lu tunjuk duluan? Kalo jawab lu: "mereka salah klik" atau "spec-nya gak jelas" — belum internalize prinsip ini. Kalo jawab: "saya cek dulu kenapa fitur ini bisa dipake dengan cara yang salah" — sudah internalize.

### 2. **Software Entropy — Broken Window Theory**

**Prinsip:** Satu jendela pecah di gedung → segera orang lain pecahin jendela lain. Satu bug yang gak diliatin → tim jadi "ya udah biarin aja". Code yang berantakan akan *membuat* orang tanduknulis code berantakan lagi.

**Yang harus dilakuin:** Zero tolerance terhadap code yang gak hygienic. Satu variable jelek? Rename. Satu komentar basi? Hapus. Satu file tanpa test? Tambah satu *charactrization test* paling simpel.

```python
# Hari 1 — gak ada yang ngelakuin
def calc(x, y):
    return x + y

# Hari 7 — udah banyak hack
def calc(x, y, z=None):
    if z: return x + y + z
    elif y == 'special': return x * 2
    else: return x + y

# Hari 14 — rusak total
```

**Yang bukan toleransi:** Bukan berarti lu harus refactor SELURUH codebase sekaligus. Kalo ada satu *broken window*, betulin langsung. Iteratif, kecil-kecil.

### 3. **DRY — Don't Repeat Yourself**

Habis ini di bahas di clean-code juga, tapi versi Pragmatic Programmer lebih *narrow*: **duplikasi knowledge** (bukan duplikasi kode). Dua kode yang keliatan sama belum tentu duplicate. Dua representasi dari satu *fact* yang sama? Itu DRY violation.

```python
# Kode A dan B punya fungsi sama tapi representasi beda
# A
def temp_usd_to_idr(amount):
    return amount * 15000

# B
def convert_dollar(amount, currency="IDR"):
    return amount / 0.000067 if currency == "IDR" else amount
# ⚠️ Pake 15000 di A, 0.000067 di B. Mana yang bener?

# DRY-fied
RATE_USD_IDR = 15000  # single source of truth

def temp_usd_to_idr(amount):
    return amount * RATE_USD_IDR
```

**Tanya Diri:** "Kalo informasi ini berubah, berapa lokasi di codebase harus di-update?". Kalo jawab lebih dari 1, itu DRY violation tersembunyi.

### 4. **Tracer Bullets vs Prototypes**

Konsep ini sering rancu tapi penting banget:

| | Tracer Bullets | Prototypes |
|--|--|--|
| **Tujuan** | End-to-end slice tipis yang *production-ready* | Eksperimen sekali datang |
| **Cara** | Kode beneran tapi minimal (1 endpoint, 1 model, ...) | Code hack bebas, gak peduli clean |
| **Output** | Jadi tulang punggung aplikasi jadi | Dibuang setelah dapet insight |
| **Quality** | Standar produksi | Standar "asal jalan" |

```python
# Tracer Bullet — pakai API production beneran, tapi 1 endpoint aja
@app.route('/api/health')
def health():
    user = db.session.query(User).first()  # beneran query
    return {'status': 'ok', 'test_user': user.name}

# Prototype — eksperimen tulis ulang pakai library lain
def try_lib_v2():
    """ Buat explore apakah lib baru lebih cepet """
    import experimental_lib
    # main-main gak peduli clean
    return experimental_lib.do_stuff()
```

**Waspada:** Orang sering naruh kode prototype ke produksi. Itu pelanggaran parah. Prototype harus *dibuang*.

### 5. **The Power of Plain Text**

Kenapa JSON > XML, Markdown > Word, SQLite > Excel? Karena plain text **langgeng**: gak butuh software spesifik buat baca, gak perlu aktivasi license, gampang di-Git, bisa di-process pake shell.

```bash
# plain text — bisa di-grep, di-cat, di-diff
$ cat config.yaml
database:
  host: localhost
  port: 5432
$ grep host config.yaml

# binary/format-proprietary — cuma bisa dibuka pake tool tertentu
config.cfg.bak  # 😱
```

**Saat ini masih relevan di 2026:** Config (YAML/TOML > JSON UI config), data interchange (JSON, CSV > Excel), knowledge (Markdown > Word). Untungnya ekosistem udah delukuan.

### 6. **Estimasi** — Bukan Janji

**Salah kaprah:** "Fitur ini 4 jam." → 16 jam kemudian release. → User marah → trust turun.

**Benara:** "Fitur ini kira-kira 4 jam, realistiskah 6-8 jam, worst case 16 jam kalo ada hidden complexity."

```python
# Sistem estimasi PERT
Optimistic = 4   # kalo gak ada masalah sama sekali
Most_Likely = 8  # realistis
Pessimistic = 24 # kalo ada masalah

Estimate = (Optimistic + 4 * Most_Likely + Pessimistic) / 6
# ± 3 jam
```

Berapa kasihkan timebuf: kalikan estimate 2x. kalo Most_Likely 4 jam, kasih estimator 8 jam. Ini gak fraud — ini disiplin kerja professional.

### 7. **Decoupling + Orthogonality**

Dua modul ortogonal → perubahan di A gak ngaruh ke B. Bukan decoupling total (mustahil); tujuannya: **minimal cross-effect**.

```python
# ORTHOGONAL: ubah format log gak rusak file processor
class FileProcessor:
    def __init__(self, logger):
        self.logger = logger  # ← dependency-injected
    def process(self, file):
        try:
            data = file.read()
            self.logger.info(f"Processed {file.name}")
            return data
        except Exception as e:
            self.logger.error(f"Failed: {e}")
            raise

# NON-ORTHOGONAL: coupling ke logger konkrit
class FileProcessor:
    def process(self, file):
        print(f"[INFO] Processing {file.name}")  # gabisa ganti logger
        try:
            return file.read()
        except:
            print("[ERROR] failed")  # pake print harus bener
            raise
```

**Cara Test:** "Kalo saya ubah X (logger, DB driver, payment gateway), berapa file yang harus ikut diedit?". Makin sedikit, makin orthogonal. Makin orthogonal, makin maintainable.

### 8. **Knowledge Portfolio**

Karir developer = investasi pengetahuan. Diversification (compound interest) > day-trading.

| Kategori | Contohh | Frekuensi |
|---------|---------|-----------|
| Bahasa pemrograman | 1 bahasa baru per tahun (elixir, go, rust) | 12 bulan |
| Buku teknis | 1 buku/bulan (~200 halaman) | 30 hari |
| Framework | 1 framework major per tahun (Vue, Astro, Svelte) | 12 bulan |
| Domain knowledge | Industri baru (insurance, fintech, health) | 2-3 tahun |
| Soft skills | Negotiirting, presenting, writing | Terus-menerus |
| Bahasa Inggris | Baca 1 technical blog/paper per hari | Harian |

**Penting:** Pengetahuan itu *compound*. Yang lu pelajari tahun 1 membantu memahami tahun 2. Kesabaran > sprint.

## 📖 Bab Penting (2nd ed)

| Bab | Judul | Prioritas | Waktu baca | Apa yang dipelajari |
|-----|-------|-----------|------------|---------------------|
| 1 | A Pragmatic Philosophy | ✅ Wajib | ~30 menit | Responsibility, broken window, KISS |
| 2 | A Pragmatic Approach | ✅ Wajib | ~45 menit | DRY, orthogonality, reversibility |
| 3 | The Basic Tools | ✅ Wajib | ~30 menit | Shell, editor, Git — *tools of trade* |
| 4 | Pragmatic Paranoia | ⭐ Rekomendasi | ~20 menit | Defensive coding, balancing tradeoff |
| 5 | Bend or Break | ✅ Wajib | ~45 menit | Decoupling, Event-Driven, MVC |
| 6 | Concurrency | ⭐ Rekomendasi | ~30 menit | Actor model, shared state minimization |
| 7 | While You Are Coding | ✅ Wajib | ~30 menit | Naming, perception vs reality, refactoring |
| 8 | Before the Project | ⭐ Rekomendasi | ~30 menit | Requirements, specification, prototyping |
| 9 | Pragmatic Projects | ⭐ Rekomendasi | ~30 menit | Pragmatic Teams, quality circles |
| 10 | Postface | 📖 Pelengkap | ~10 menit | Critical commentary dari edisi 2 |

**Strategi baca:** Baca bab 1, 2, 3 duluan — ini mindset. Sisanya loncat ke yang relevan sama masalah lu.

## ⚠️ Kritik & Konteks

| Kritik | Penjelasan | Kapan Diabaikan |
|--------|------------|-----------------|
| Edisi 1 (1999) agak *dated* | Contoh kode Java/XML udah gak kekinian (sekarang TypeScript/Rust) | Pahami prinsip, ignore sintaks |
| Edisi 2 (2019) terlalu *preachy* | Buku ini sambul *aphorisms* dan anekdot — terasa kayak TED talk bukan manual | Anno 2026 masih valid, tapi jangan harap explicit code recipe |
| Agak subjectif | "Use plain text" — teori, tapi Excel/Binary ada tempatnya | Tetepin *default*: plain text, tapi gunakan binary format kalau perlu |
| Gak kasih framework kerja | Gak ada Sprint-by-Sprint framework kayak Scrum/XP | Pasangkan dengan buku seperti *Extreme Programming Explained* |
| Konsep traceability diulas tipis | DRY tracing butuh tools (Sonargraph, ddd) | Lihat ebuku *Managing Technical Debt* / tools modern |

**Kasusnya cocok dengan 2026:**
- **Masih valid:** DRY, Orthogonality, Responsibilitas, Broken Window
- **Kurang valid:** XML, CORBA, COM — banyak replaced dengan format/protokol modern
- **Missing di edisi 2:** Microservices, Serverless, AI-assisted coding. Buku gak bahas ini, tapi mindset tetap applicable.

**Wajib di-baca ulang:** Karena prinsipnya high-level, setiap 2-3 tahun saat lu udah lebih senior, ulaca dan tafsir ulang. Pemahaman lu bakal berubah.

## 🚦 Prioritas Prinsip

| Prioritas | Prinsip |Sisi Gelap-nya |
|--------|----------|--------|
| 1 | DRY, Broken Window | kode bersih dimulai dari sini |
| 2 | Orthogonality | komponer-modulen lu mudah diubah independen |
| 3 | Plain Text | config & data jangan di-lock format proprietary, ourself |
| 4 | Tracer Bullets | prototipe tipe tipis-lebar-bukan-murun-vs-prototype |
| 5 | Estimasi | be honest |
| 6 | Knowledge Portfolio | investasi tahunan ke kemampuan baru |

## 🔗 Koneksi ke Vault Lain

- [[clean-code-robert-martin]] — buku komplementer: clean code = hasil coding yang baik, pragmatic programmer = cara hidupnya.
- [[design-patterns-gof]] — orthogonality contoh konkret ada di Strategy, Decorator, Adapter.
- [[bonus-books-refactoring-legacy-ydkjs-knuth]] — broken window + refactoring = radi bersih.
- [[deep-work-and-so-good-newport]] — knowledge portfolio + deep work = superpower.
- [[systems-design-interview-alex-xu]] — README.ptgit akhir tracer bullets ada di level sistem: build vertical first.

## ✅ Checklist Praktik

- [ ] Identifying 1 DRY violation di codebase + refactor
- [ ] Audit broken windows di codebase → fix minimal 1 per minggu
- [ ] Coba 1 tool baru (shell alias, editor macro, git hook)
- [ ] Renovasi 1 prototype lama yang tertinggal di production (drop atau re-write dengan tracer first)
- [ ] Kasih timebuf ke semantic estimate (multiply calculated PERT by 2)
- [ ] Pilih 1 bahasa/framework asing untuk bulan ini (goalkan 30 menit/hari)
- [ ] Buat Reading Plan 12 bulan — 12 buku teknis + 4 non-teknis (cal newport, do-interruptarium)
- [ ] Tes orthogonality: ganti DB driver di codebase, hitung file yang rusak
---

audited
---
