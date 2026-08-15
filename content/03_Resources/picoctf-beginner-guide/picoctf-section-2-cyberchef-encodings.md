---
tags:
- CTF
- Cryptography
- Encoding
- CyberChef
aliases:
- PicoCTF Section 2
- Pattern Recognition for Encodings
created: 2026-05-12
status: pending
title: Picoctf Section 2 Cyberchef Encodings
updated: '2026-07-01'
cssclasses:
  - wide-table
  - callout
---


# 🧩 PICOCTF SECTION 2 — Encodings & CyberChef

> **Tools:** CyberChef, `base64`, `tr`
> **Filosofi:** Jangan tebak-tebak buah manggis. Kenali pola visualnya.
> **Target:** Base64, Hex, Base32, ROT13, & Binary.

---

## FASE 1 — Pattern Recognition (Pengenalan Pola)

Gunakan tabel ini untuk menebak jenis encoding hanya dalam sekali lirik:

| Jenis | Contoh Visual | Kunci Identitas |
|---|---|---|
| **Base64** | `YXpoYXI=` | Campur A-Z, a-z, 0-9. Sering ada `=` di akhir. |
| **Hex (B16)** | `61 7a 68 61 72` | Hanya `0-9` dan `A-F`. Awalan `0x`. |
| **Base32** | `MFRGGZJA` | Full CAPS. Angka hanya `2-7`. Tanpa 0, 1, 8, 9. |
| **Binary** | `01100001` | Hanya berisi angka `0` dan `1`. |
| **ROT13** | `cvpbPGS` | Terlihat seperti kata normal tapi berantakan. |

---

## FASE 2 — Manipulasi Data di Terminal

Seringkali lebih cepat menggunakan terminal daripada membuka browser.

### 2.1 Base64 Decoding
```bash
echo "bDNhcm5fdGgzX3IwcDM1" | base64 -d
```

### 2.2 ROT13 (Translate command)
```bash
# Me-rotate karakter A-Z dan a-z sebanyak 13 langkah
echo "cvpbPGS" | tr 'A-Za-z' 'N-ZA-Mn-za-m'
```

---

## FASE 3 — CyberChef (The Magic Stick)

Untuk tantangan yang lebih kompleks, gunakan **CyberChef**.

### 3.1 Fitur "Magic"
Jika Anda menaruh input di CyberChef, klik ikon **Magic Wand** (tongkat sihir). Alat ini akan menebak jenis encoding secara otomatis.

### 3.2 Pemetaan "Base" ke Nama Umum
> [!tip] Kamus CyberChef
> - **Base 16** ➔ From Hex
> - **Base 64** ➔ From Base64
> - **Base 2** ➔ From Binary

---

## FASE 4 — Jebakan Padding & Binary

Saat mengonversi angka ke biner (misal: 42 ke biner):
*   **Manual**: `101010` (6 bit).
*   **8-bit Format**: `00101010` (8 bit).

> [!danger] Warning: Leading Zeros
> Di PicoCTF, jangan menambah `0` di depan (padding) kecuali instruksi memintanya. `picoCTF{101010}` ≠ `picoCTF{00101010}`.

---

## Quick Reference — Cheat Sheet

```bash
# ═══ TERMINAL DECODING ═══
echo "[STRING]" | base64 -d            # Decode Base64
echo "[STRING]" | xxd -r -p            # Decode Hex (Plain)

# ═══ IDENTIFIKASI ═══
# Base 16 = Hex (0-9, A-F)
# Base 32 = CAPS (A-Z, 2-7)
# Base 64 = Mix (A-Z, a-z, 0-9, =)
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Brute Force menebak manual | Gunakan tabel pola atau fitur "Magic" |
| Menambah `0` di depan biner | Masukkan biner murni tanpa padding |
| Bingung mencari "Base 16" | Cari kata kunci "Hexadecimal" |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-1-onboarding]] — Kembali ke Section 1
- [[picoctf-section-3-linux-web-basics]] — Lanjut ke Section 3

---
*PicoCTF Section 2 | Base64 · Hex · ROT13 · CyberChef*
audited