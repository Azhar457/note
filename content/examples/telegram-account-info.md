---
title: Telegram Account Info
tags: [telegram, account, identity]
aliases: [Telegram ID]
created: 2026-08-02
updated: 2026-08-02
status: complete
---

# 📱 Telegram Account Info

> [!info] Data akun Telegram pribadi — disimpan lokal, TIDAK di-sync ke Quartz (folder `examples/` di luar `Note/`).

| Field | Value |
|:---|:---|
| **User ID** | `6180769527` |
| **Platform** | Telegram |
| **Source** | Home channel DM session (Hermes) |
| **Tipe chat** | Private DM |
| **Lokasi file** | `Wide Note/examples/telegram-account-info.md` |

---

## 🔒 Catatan Privasi

- Telegram User ID bersifat **publik di API level** — siapa pun yang pernah chat sama bot bisa lihat ID-nya. Ini **bukan secret**, tapi berguna untuk:
  - Setup bot / automation pribadi
  - Notifikasi cron ke chat sendiri
  - Whitelist akses (hanya ID ini yang boleh terima pesan tertentu)
- **Jangan** share ID ini bersama nomor HP / username publik di satu tempat yang bisa di-index.

## 🔗 Terkait

- `examples/osint-check-2026-08-02.md` — dokumentasi OSINT session (audit eksposur data pribadi)
