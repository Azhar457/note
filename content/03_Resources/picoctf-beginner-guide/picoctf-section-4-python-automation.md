---
tags:
- CTF
- Python
- Automation
- Password-Cracking
aliases:
- PicoCTF Section 4
- Python for CTF Basics
created: 2026-05-12
status: pending
title: Picoctf Section 4 Python Automation
updated: '2026-07-01'
cssclasses:
  - wide-table
  
---
# 🐍 PICOCTF SECTION 4 — Python Automation

> **Environment:** Python 3
> **Filosofi:** Jangan kerjakan secara manual apa yang bisa dikerjakan oleh script.
> **Target:** `.py` scripts, Password Cracking, & Data Wrangling.

---

## FASE 1 — Menjalankan Script Python

Banyak tantangan memberikan file `.py` yang harus dijalankan untuk mendapatkan flag.

### 1.1 Eksekusi Dasar
```bash
python3 script.py
```

### 1.2 Menangani Argumen
Seringkali script membutuhkan file tambahan sebagai argumen (misal: data terenkripsi).
```bash
# Contoh: menjalankan script dengan file data pendukung
python3 script.py -d data.en.txt
```

---

## FASE 2 — Password Cracking Dasar

Tantangan series `PW Crack` mengajarkan cara menebak password yang ditaruh di dalam kode.

### 2.1 Hardcoded Password
Buka file `.py` menggunakan editor atau `cat`. Cari variabel seperti `pos_pw_list` atau `correct_pw`.
```bash
cat level1.py | grep "password"
```

### 2.2 Brute Force Sederhana
Jika password ada di dalam list (array), script biasanya akan mencocokkan input Anda dengan list tersebut.

---

## FASE 3 — Python One-Liner (Otomasi Cepat)

Anda tidak selalu perlu membuat file `.py`. Terkadang satu baris di terminal sudah cukup.

```bash
# Contoh: Melakukan kalkulasi cepat atau manipulasi string
python3 -c "print('A' * 50)"           # Mencetak huruf A 50 kali
python3 -c "print(0x42)"                # Konversi Hex ke Desimal
```

---

## Quick Reference — Cheat Sheet

```bash
# ═══ EXECUTION ═══
python3 [file].py                      # Jalankan script
python3 -c "[command]"                 # Run perintah Python di terminal

# ═══ COMMON TASKS ═══
cat [file].py | grep "flag"            # Intip variabel flag
ls -l *.py                             # Lihat daftar script di folder
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Mencoba menebak password secara manual | Baca source code scriptnya |
| Mengabaikan file `.txt` pendukung | Cek apakah script butuh argumen file `-d` |
| Menggunakan Python 2 | Selalu gunakan `python3` |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-3-linux-web-basics]] — Kembali ke Section 3
- [[picoctf-section-5-reverse-engineering]] — Lanjut ke Section 5

---

*PicoCTF Section 4 | Python Wrangling · PW Crack · Automation*

## FASE 4 — Script Decode Hex/Base64 (PW Crack Pattern)

```python
# Pola umum soal PW Crack: input di-decode, dibandingkan dengan password
import hashlib

# Contoh struktur soal:
# level n: user_input → hash → bandingkan dengan target hash
target = "9b8b4d5c..."
user_input = input("Enter password: ")

def hash_pw(pw):
    return hashlib.sha256(pw.encode()).hexdigest()

if hash_pw(user_input) == target:
    print("Correct!")
```

```bash
# Auto-brute dengan wordlist
cat wordlist.txt | while read pw; do
    python3 level.py "$pw" 2>/dev/null | grep -q "Correct" && echo "FOUND: $pw"
done
```

## FASE 5 — Data Wrangling (flag Format)

```python
# Flag sering di-extract dari output mentah
import re

data = open("output.txt").read()
flag = re.search(r"picoCTF\{[^}]+\}", data)
print(flag.group(0))
```

```bash
# One-liner: static analysis + extraction
strings file.bin | grep -oE "picoCTF\{[^}]+\}"
grep -oE "[0-9a-f]{32}" data.txt | sort -u
```
---

audited
---
