---
title: "🛠️ PICOCTF SECTION 3 — Linux & Web Basics"
description: "Saat Anda mengunduh file biner yang tidak bisa dibaca manusia, gunakan alat ini:"
tags:
  - CTF
  - Linux
  - Web-Exploitation
  - CLI
aliases:
  - PicoCTF Section 3
  - Linux CLI Basics
created: 2026-05-12
status: operational
---

# 🛠️ PICOCTF SECTION 3 — Linux & Web Basics

> **Tools:** `strings`, `grep`, `file`, Browser DevTools
> **Filosofi:** Intip apa yang tidak terlihat di permukaan.
> **Target:** Binary files, Source code, & Hidden Web elements.

---

## FASE 1 — Analisis Biner Sederhana

Saat Anda mengunduh file biner yang tidak bisa dibaca manusia, gunakan alat ini:

### 1.1 Command `strings`

Menampilkan semua urutan karakter yang dapat dicetak dalam file.

```bash
# Mencari flag di dalam file biner
strings strings_it | grep "picoCTF"
```

### 1.2 Command `file`

Mengetahui jenis file sebenarnya (ekstensi bisa menipu).

```bash
file target_file
```

---

## FASE 2 — Pencarian Tekstual (Grep Mastery)

`grep` adalah sahabat terbaik Anda untuk menyaring ribuan baris teks.

### 2.1 Mencari Flag Pertama

```bash
grep "picoCTF" file.txt
```

### 2.2 Case Insensitive

Jika tidak yakin huruf besar/kecil:

```bash
grep -i "picoctf" file.txt
```

---

## FASE 3 — Web Exploitation (Sanity Check)

Tantangan seperti `Insp3ct0r` melatih Anda melihat ke balik tampilan website.

### 3.1 Inspect Element (Ctrl + Shift + I)

Flag sering dipecah menjadi beberapa bagian di lokasi berbeda:

- **HTML**: Cek komentar `<!-- ... -->`.
- **CSS**: Cek file `.css` untuk komentar.
- **JavaScript**: Cek file `.js`.

### 3.2 File `robots.txt`

File standar yang memberi tahu bot pencari mana yang tidak boleh diindeks. Seringkali berisi folder rahasia.

```bash
# Akses via browser
https://jupiter.challenges.picoctf.org/problem/XXXXX/robots.txt
```

---

## Quick Reference — Cheat Sheet

```bash
# ═══ LINUX CLI ═══
strings [file] | grep "pico"           # Cari flag di biner
grep -r "pico" .                       # Cari rekursif di folder
cat [file]                             # Baca isi file teks

# ═══ WEB ═══
view-source:[URL]                      # Lihat source code HTML
/robots.txt                            # Cek file konfigurasi robot
/secret/                               # Tebakan folder umum
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah                                | ✅ Benar                                    |
| --------------------------------------- | ------------------------------------------- |
| Mencoba membaca file biner dengan `cat` | Gunakan `strings` agar terminal tidak rusak |
| Hanya mengecek HTML                     | Cek juga file CSS dan JS pendukung          |
| Mengabaikan hint "inspect"              | Gunakan Browser Developer Tools             |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-2-cyberchef-encodings]] — Kembali ke Section 2
- [[picoctf-section-4-python-automation]] — Lanjut ke Section 4

---

_PicoCTF Section 3 | strings · grep · robots.txt · Insp3ct0r_
