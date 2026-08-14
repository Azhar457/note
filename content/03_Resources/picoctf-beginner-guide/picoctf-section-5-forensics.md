---
title: Picoctf Section 5 Forensics
tags:
- picoctf-beginner-guide
- resources
created: '2026-05-12'
updated: '2026-07-01'
status: pending
---

cssclasses:
  - wide-table
  - callout

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

Dalam tahap ini, kita menggunakan `exiftool` untuk memeriksa metadata dari file SVG. Metadata dapat berisi informasi seperti judul, pembuat, dan lain-lain. Jika flag disembunyikan dalam metadata, maka kita dapat menemukannya dengan menggunakan `exiftool`.

Selain itu, kita juga menggunakan `cat` untuk membaca isi teks mentah dari file SVG dan kemudian menggunakan `grep` untuk mencari pola "picoCTF" di dalam teks tersebut.

### 1.2 Penanganan Fragmented Tags
Jika flag dipotong-potong ke dalam banyak tag `<tspan>`, gunakan **PCRE Grep** untuk menyatukannya:

```bash
# Ekstraksi teks di antara tag tspan dan hapus spasi/newline
grep -Po '(?<=>)[^<]+(?=</tspan>)' drawing.flag.svg | tr -d '\n '
```

Dalam beberapa kasus, flag dapat dipotong-potong ke dalam beberapa tag `<tspan>`. Untuk menangani hal ini, kita dapat menggunakan **PCRE Grep** untuk menyatukan teks di antara tag `<tspan>`.

Opsi `-P` digunakan untuk mengaktifkan mode Perl Compatible Regular Expressions (PCRE), yang memungkinkan kita menggunakan ekspresi reguler yang lebih kompleks. Ekspresi reguler `(?<=>)[^<]+(?=</tspan>)` digunakan untuk mencari teks di antara tag `<tspan>`.

Setelah ekstraksi teks, kita menggunakan `tr -d '\n '` untuk menghapus spasi dan newline dari teks tersebut.

### 1.3 Contoh Kasus
```markdown
# Diberikan file SVG dengan isi berikut:
# <svg>
#   <text>
#     <tspan>picoCTF{</tspan>
#     <tspan>flag_</tspan>
#     <tspan>di_sini}</tspan>
#   </text>
# </svg>

# Ekstraksi teks di antara tag tspan
$ grep -Po '(?<=>)[^<]+(?=</tspan>)' file.svg
picoCTF{
flag_
di_sini}

# Hapus spasi dan newline
$ grep -Po '(?<=>)[^<]+(?=</tspan>)' file.svg | tr -d '\n '
picoCTF{flag_di_sini}
```

Dalam contoh di atas, kita memiliki file SVG dengan tag `<tspan>` yang berisi bagian-bagian flag. Dengan menggunakan **PCRE Grep**, kita dapat mengekstraksi teks di antara tag `<tspan>` dan kemudian menghapus spasi dan newline untuk mendapatkan flag lengkap.

---

## FASE 2 — Pencarian Masif (Recursive Grep)

Tantangan "Needle in the Haystack" di mana flag berada di salah satu dari ribuan file di dalam ratusan folder.

### 2.1 Grep Mode "Terminator"
```bash
# Cari teks "picoCTF{" di direktori saat ini dan semua subdirektorinya
grep -r "picoCTF{" .
```

Dalam tahap ini, kita menggunakan `grep` dengan opsi `-r` untuk melakukan pencarian rekursif di direktori saat ini dan semua subdirektorinya.

Opsi `-r` digunakan untuk mengaktifkan mode rekursif, yang memungkinkan `grep` untuk mencari di semua file dan subdirektori di direktori saat ini.

### 2.2 Tabel Perbandingan Opsi Grep
| Flag | Fungsi |
|---|---|
| `-r` | **Recursive**. Menyelam ke semua folder dan subfolder. |
| `.` | Titik melambangkan direktori saat ini sebagai titik mulai. |
| `-h` | (Opsional) Sembunyikan nama file, tampilkan isinya saja. |
| `-i` | (Opsional) Lakukan pencarian dengan mode tidak membedakan huruf besar/kecil. |
| `-n` | (Opsional) Tampilkan nomor baris dari hasil pencarian. |

Dalam tabel di atas, kita dapat melihat beberapa opsi yang dapat digunakan dengan `grep` untuk melakukan pencarian masif.

### 2.3 Contoh Kasus
```markdown
# Diberikan direktori dengan struktur berikut:
# .
# ├── file1.txt
# ├── file2.txt
# ├── folder1
# │   ├── file3.txt
# │   └── file4.txt
# └── folder2
#     ├── file5.txt
#     └── file6.txt

# Cari teks "picoCTF{" di direktori saat ini dan semua subdirektorinya
$ grep -r "picoCTF{" .
./file1.txt:picoCTF{flag_di_sini}
./folder1/file3.txt:picoCTF{flag_lain}
./folder2/file5.txt:picoCTF{flag_baru}
```

Dalam contoh di atas, kita memiliki direktori dengan beberapa file dan subdirektori. Dengan menggunakan `grep` dengan opsi `-r`, kita dapat mencari teks "picoCTF{" di semua file dan subdirektori di direktori saat ini.

---

## FASE 3 — Kerangka Berpikir Forensik File

Lain kali jika bertemu file gambar/dokumen, ikuti hierarki ini:

1.  **Metadata**: Gunakan `exiftool` (untuk .jpg, .png).
2.  **Strings/Teks**: Gunakan `cat` atau `strings` (untuk .svg atau biner).
3.  **Visual**: Buka gambarnya, cek detail kecil.
4.  **Steganography**: Gunakan `steghide`, `zsteg`, atau `binwalk` (untuk data tersembunyi di level bit).

Dalam tahap ini, kita memiliki kerangka berpikir forensik file yang dapat digunakan untuk menganalisis file gambar/dokumen.

### 3.1 Contoh Kasus
```markdown
# Diberikan file gambar dengan format .jpg
# File tersebut memiliki metadata yang dapat dilihat dengan exiftool

$ exiftool file.jpg
ExifTool Version Number         : 12.30
File Name                       : file.jpg
Directory                       : .
File Size                        : 1024 bytes
File Modification Date/Time     : 2023:02:20 14:30:00+07:00
File Access Date/Time           : 2023:02:20 14:30:00+07:00
File Inode Change Date/Time      : 2023:02:20 14:30:00+07:00
File Permissions               : rw-r--r--
File Type                       : JPEG
MIME Type                       : image/jpeg
JFIF Version                    : 1.01
Exif Byte Order                 : Little-endian (Intel, II)
Make                            : Canon
Camera Model Name              : Canon EOS 5D
Orientation                     : Top-left side (Horizontal / normal)
X Resolution                   : 72
Y Resolution                   : 72
Resolution Unit                : inches
Software                        : Adobe Photoshop CS6 (Macintosh)
Modify Date                     : 2023:02:20 14:30:00
Artist                          : John Doe
Copyright                       : 2023 John Doe
Exif Version                    : 0231
Flashpix Version                : 0100
Color Space                     : sRGB
Components Configuration       : Y, Cb, Cr,
Compressed Bits Per Pixel       : 4
Pixel X Dimension               : 1024
Pixel Y Dimension               : 768
Display Scale                   : 72
```

Dalam contoh di atas, kita memiliki file gambar dengan format .jpg yang memiliki metadata yang dapat dilihat dengan `exiftool`. Metadata tersebut dapat berisi informasi seperti pembuat, tanggal modificasi, dan lain-lain.

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

Dalam bagian ini, kita memiliki quick reference atau cheat sheet yang dapat digunakan sebagai acuan untuk melakukan forensik dasar.

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Buka satu-satu ribuan folder | Gunakan `grep -r` |
| Menyerah saat `exiftool` kosong | Cek konten teks dengan `cat` atau `strings` |
| Menganggap file gambar = biner saja | SVG adalah file teks (XML) |

Dalam bagian ini, kita memiliki beberapa contoh anti-pattern atau praktik yang tidak baik yang harus dihindari saat melakukan forensik.

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-3-linux-web-basics]] — Dasar Pencarian
- [[picoctf-section-5-reverse-engineering]] — Lanjut ke RE

Dalam bagian ini, kita memiliki beberapa link yang dapat digunakan sebagai acuan untuk mempelajari materi lain yang terkait dengan picoctf.

---

*PicoCTF Modul 1 | Forensics · Grep · SVG · Filesystem*

Dalam modul ini, kita telah mempelajari beberapa konsep dasar forensik, termasuk penggunaan `grep` untuk mencari teks di dalam file dan direktori, penggunaan `exiftool` untuk memeriksa metadata file gambar, dan penggunaan `strings` untuk mengekstraksi teks dari file biner.

Kita juga telah mempelajari beberapa contoh kasus yang dapat digunakan sebagai acuan untuk mempraktekan konsep-konsep yang telah dipelajari.

Dengan mempelajari materi ini, kita dapat memperoleh kemampuan untuk melakukan forensik dasar dan mengembangkan kemampuan itu menjadi lebih lanjut dengan mempelajari materi lain yang terkait dengan picoctf.