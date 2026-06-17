---
tags:
  - CTF
  - Forensics
  - Grep
  - Linux
aliases:
  - PicoCTF Forensics
  - Grep Mastery for CTF
created: 2026-05-12
status: operational
---

# 🔍 PICOCTF SECTION 5 — Forensics & Filesystem

> **Environment:** Terminal / Bash
> **Filosofi:** Cari "Jarum" menggunakan mesin, bukan mata.
> **Target:** File SVG, Zip berisi ribuan folder, & Metadata.

> [!danger] Golden Rule
> Jika `grep` biasa gagal, kemungkinan polanya diacak atau dipotong (fragmented).

---

## FASE 1 — Analisis Konten Tersembunyi (SVG)

SVG (Scalable Vector Graphics) adalah file berbasis **XML/Teks**. Seringkali flag disembunyikan di dalam tag visual yang sangat kecil.

### 1.1 Identifikasi Awal
```bash
# Cek metadata biner (Kadang flag ada di Title/Creator)
exiftool drawing.flag.svg

# Baca isi teks mentah
cat drawing.flag.svg | grep "picoCTF"
```

### 1.2 Penanganan Fragmented Tags
Jika flag dipotong-potong ke dalam banyak tag `<tspan>`, gunakan **PCRE Grep** untuk menyatukannya:

```bash
# Ekstraksi teks di antara tag tspan dan hapus spasi/newline
grep -Po '(?<=>)[^<]+(?=</tspan>)' drawing.flag.svg | tr -d '\n '
```

---

## FASE 2 — Pencarian Masif (Recursive Grep)

Tantangan "Needle in the Haystack" di mana flag berada di salah satu dari ribuan file di dalam ratusan folder.

### 2.1 Grep Mode "Terminator"
```bash
# Cari teks "picoCTF{" di direktori saat ini dan semua subdirektorinya
grep -r "picoCTF{" .
```

| Flag | Fungsi |
|---|---|
| `-r` | **Recursive**. Menyelam ke semua folder dan subfolder. |
| `.` | Titik melambangkan direktori saat ini sebagai titik mulai. |
| `-h` | (Opsional) Sembunyikan nama file, tampilkan isinya saja. |

---

## FASE 3 — Kerangka Berpikir Forensik File

Lain kali jika bertemu file gambar/dokumen, ikuti hierarki ini:

1.  **Metadata**: Gunakan `exiftool` (untuk .jpg, .png).
2.  **Strings/Teks**: Gunakan `cat` atau `strings` (untuk .svg atau biner).
3.  **Visual**: Buka gambarnya, cek detail kecil.
4.  **Steganography**: Gunakan `steghide`, `zsteg`, atau `binwalk` (untuk data tersembunyi di level bit).

---

## Quick Reference — Cheat Sheet

```bash
# ═══ FORENSIK DASAR ═══
strings file.ext | grep "picoCTF"      # Ekstrak teks dari biner
exiftool file.jpg                      # Cek metadata
grep -r "picoCTF" .                    # Cari rekursif di folder

# ═══ EKSTRAKSI LANJUTAN ═══
grep -Po '(?<=>)[^<]+(?=</tspan>)'     # Regex PCRE untuk tag XML
tr -d '\n '                            # Hapus newline & spasi
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Buka satu-satu ribuan folder | Gunakan `grep -r` |
| Menyerah saat `exiftool` kosong | Cek konten teks dengan `cat` atau `strings` |
| Menganggap file gambar = biner saja | SVG adalah file teks (XML) |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-3-linux-web-basics]] — Dasar Pencarian
- [[picoctf-section-5-reverse-engineering]] — Lanjut ke RE

---

*PicoCTF Modul 1 | Forensics · Grep · SVG · Filesystem*
