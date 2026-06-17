---
tags:
  - CTF
  - Onboarding
  - SSH
  - Netcat
aliases:
  - PicoCTF Section 1
  - SSH and NC Basics
created: 2026-05-12
status: operational
---

# 🚀 PICOCTF SECTION 1 — Onboarding & Connection

> **Environment:** Linux Shell / Webshell
> **Filosofi:** Teliti membaca instruksi adalah setengah dari perjuangan.
> **Target:** SSH (Secure Shell), Netcat (nc), & Flag Discovery.

---

## FASE 1 — Identifikasi Flag

Flag adalah string teks unik yang membuktikan Anda telah memecahkan tantangan.
*   **Format Dasar:** `picoCTF{...}`
*   **Karakteristik:** Sering menggunakan *Leet Speak* (misal: `1337` untuk `leet`).

---

## FASE 2 — Penguasaan SSH (Secure Shell)

Tantangan seringkali mengharuskan Anda masuk ke server remote.

### 2.1 Perintah Standar
```bash
# Format: ssh [username]@[host] -p [port]
ssh ctf-player@titan.picoctf.net -p 57470
```

### 2.2 Jebakan Klasik (The Period Trap)
> [!danger] Warning: Period Trap
> Jangan menyalin tanda titik (.) di akhir kalimat instruksi. Password `1ad5be0d.` (dengan titik) akan ditolak. Password yang benar adalah `1ad5be0d`.

### 2.3 Tips Troubleshooting
*   **Verbose Mode**: Gunakan `-v` untuk melihat proses debug jika koneksi gagal.
*   **Invisible Password**: Saat mengetik password di Linux, kursor **tidak akan bergerak**. Ketik saja dan tekan Enter.

---

## FASE 3 — Netcat (The Swiss Army Knife)

`nc` digunakan untuk mengirim atau menerima data melalui jaringan.

### 3.1 Diagram Alur Komunikasi
```
[ SERVER (PicoCTF) ] <─────────── [ CLIENT (Anda) ]
  (Listener Mode)                   (Connector Mode)
  Membuka port &                    Mengetuk pintu ke 
  menunggu tamu.                    IP & Port target.
```

### 3.2 Perintah Koneksi
```bash
# Menghubungkan ke server target
nc titan.picoctf.net [PORT]
```

---

## Quick Reference — Cheat Sheet

```bash
# ═══ SSH ═══
ssh -p [PORT] [USER]@[HOST]            # Koneksi SSH dengan port
ssh -v -p [PORT] [USER]@[HOST]         # Verbose mode (Debug)

# ═══ NETCAT (nc) ═══
nc [HOST] [PORT]                       # Connect ke target
nc -lvnp [PORT]                        # Buka listener (Sisi Server)
```

---

## Anti-Pattern — Jangan Lakukan Ini

| ❌ Salah | ✅ Benar |
|---|---|
| Menyalin titik di akhir password | Hanya salin karakter Alphanumeric |
| Panik kursor tidak gerak saat ketik password | Teruskan mengetik dan tekan Enter |
| Mengabaikan username `as ctf-player` | Selalu gunakan username sesuai instruksi |

---

## 🔗 Lihat Juga

- [[picoctf-master-index]] — Roadmap Utama
- [[picoctf-section-2-cyberchef-encodings]] — Lanjut ke Section 2

---

*PicoCTF Section 1 | SSH · Netcat · Flag Discovery*
