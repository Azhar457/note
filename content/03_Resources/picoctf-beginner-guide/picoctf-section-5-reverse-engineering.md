---
tags:
- CTF
- Reverse-Engineering
- Java
- Python
- Hashing
aliases:
- PicoCTF RevEng
- SHA256 Indexing Guide
created: 2026-05-12
status: pending
title: Picoctf Section 5 Reverse Engineering
updated: '2026-07-01'
---

# ⚙️ PICOCTF SECTION 5 — Reverse Engineering

> **Environment:** Java JDK, Python 3
> **Filosofi:** Pahami logikanya, temukan kuncinya, atau hancurkan pintunya.
> **Target:** Source Code (.java, .py), Compiled Bytecode, & License Key.

> [!tip] Golden Rule
> Password yang ditaruh di dalam Source Code (Hardcoded) adalah kerentanan fatal.

---

## FASE 1 — Java Source Analysis (VaultDoor)

Tantangan di mana password disembunyikan langsung di dalam fungsi `checkPassword`.

### 1.1 Compiled vs Interpreted
Berbeda dengan Python, Java harus dikompilasi ke bytecode sebelum bisa dijalankan.

```bash
# Tahap 1: Kompilasi (.java -> .class)
javac VaultDoorTraining.java

# Tahap 2: Eksekusi
java VaultDoorTraining
```

### 1.2 Analisis Logika `equals()` & `substring()`
```java
// Contoh potongan kode yang menjebak
String input = userInput.substring("picoCTF{".length(), userInput.length()-1);
if (input.equals("w4rm1ng_Up_w1tH_jAv4_...")) { ... }
```
> [!warning] Hati-hati
> Karena ada fungsi `substring()`, kamu harus memasukkan flag secara utuh dengan bungkusnya `picoCTF{...}` agar setelah dipotong hasilnya cocok dengan string target.

---

## FASE 2 — Python Reverse Engineering (Keygenme)

Tantangan di mana kunci lisensi dibuat secara dinamis menggunakan **SHA256 Hashing**.

### 2.1 Konsep SHA256 (Digital Blender)
*   **Satu Arah**: "BENNETT" jadi hash bisa, balik lagi nggak bisa.
*   **Sensitif**: Satu huruf beda (kapital/kecil), hasil hash berubah total.

### 2.2 Memahami "Indexing" & "Obfuscation"
Hasil SHA256 terdiri dari 64 karakter. Program seringkali hanya mengambil beberapa karakter di posisi tertentu (Index) secara acak untuk menyesatkan (Obfuscation).

**Langkah Eksekusi (Python One-Liner):**
```bash
# Ambil karakter indeks [4], [5], [3], [6], [2], [7], [1], [8] dari hash username "BENNETT"
python3 -c "import hashlib; u = b'BENNETT'; h = hashlib.sha256(u).hexdigest(); print(h[4] + h[5] + h[3] + h[6] + h[2] + h[7] + h[1] + h[8])"
```

---

## FASE 3 — Strategi Menembus "Pintu"

Dalam Reverse Engineering, kamu punya dua pilihan:

1.  **Opsi A (The Keygenner)**: Pelajari algoritma pembuatan kunci, buat kuncinya (Intended Way).
2.  **Opsi B (The Patcher)**: Hancurkan logikanya. Ubah `if (check_key)` menjadi `if (true)`.
    *   *Catatan:* Opsi B bisa gagal jika kunci tersebut juga digunakan sebagai kunci dekripsi (misal: Fernet) untuk data berikutnya.

---

## Quick Reference — Cheat Sheet

```bash
# ═══ JAVA ═══
javac File.java && java File           # Compile & Run

# ═══ PYTHON HASHING ═══
# Mencari hash SHA256 via terminal
echo -n "BENNETT" | sha256sum

# Python Indexing (Ambil karakter posisi 4)
python3 -c "import hashlib; print(hashlib.sha256(b'input').hexdigest()[4])"
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Memasukkan password tanpa bungkus `picoCTF{}` | Cek logika `substring` di kode |
| Menghitung indeks hash secara manual | Gunakan Python one-liner (Indeks mulai dari 0) |
| Patching logika sembarangan | Pastikan kunci tidak dipakai untuk dekripsi data |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-4-python-automation]] — Kembali ke Modul 4
- [[picoctf-section-5-binary-exploitation]] — Lanjut ke Modul 3

---

*PicoCTF Modul 2 | RevEng · Java · Python · SHA256*
