---
title: "🗺️ ACTIVE CONTEXT — Session Handoff"
description: "```"
tags:
  - active-context
  - session
  - handoff
  - meta
aliases:
  - Active Context
  - Session State
updated: 2026-04-30
session_id: "[ISI: tanggal-topik-utama, contoh: 20260430-arp-forensik]"
status: active
---

# 🗺️ ACTIVE CONTEXT — Session Handoff

> Paste file ini di awal conversation baru sebagai briefing Claude.
> Instruksi ke Claude: _"Baca ACTIVE_CONTEXT ini. Fokus pada bagian
> yang ditandai ⚡. Tanya jika ada yang kurang jelas sebelum lanjut."_

---

## ⚡ SIAPA AKU (Selalu Ada)

```
Nama/alias  : [nama atau panggilan]
Background  : [contoh: Mahasiswa Pendidikan Matematika, self-taught CS/Security]
Stack utama : [contoh: Linux Mint, Python, Obsidian, ESP32]
Level       : [contoh: intermediate — paham konsep, masih belajar implementasi]
Vault       : [contoh: azhar457.github.io/note]
```

---

## ⚡ STATUS SAAT INI

```
Tanggal update : [YYYY-MM-DD HH:MM]
Conversation   : [nomor/nama conversation ini, contoh: "War Room Session 3"]
Topik aktif    : [apa yang sedang dikerjakan SEKARANG]
Fase           : [contoh: planning / implementing / debugging / documenting]
Mood/energy    : [opsional tapi berguna: fresh / tired / deep focus]
```

---

## ⚡ KEPUTUSAN YANG SUDAH DIBUAT (Jangan Diulang)

> Hal-hal ini sudah diputuskan — tidak perlu ditanya ulang atau direkomendasikan ulang.

- [ ] [Keputusan 1 — contoh: "Pakai Linux Mint Cinnamon, bukan Ubuntu"]
- [ ] [Keputusan 2 — contoh: "Format dokumen: Obsidian MD + Quartz deploy"]
- [ ] [Keputusan 3]

---

## ⚡ OUTPUT YANG SUDAH ADA

> File/artefak yang sudah dibuat di conversation sebelumnya.
> Claude tidak perlu buat ulang kecuali diminta eksplisit.

| File             | Isi Singkat         | Status          |
| ---------------- | ------------------- | --------------- |
| `[nama-file.md]` | [deskripsi 1 baris] | ✅ Selesai      |
| `[nama-file.md]` | [deskripsi 1 baris] | ⚠️ Draft        |
| `[nama-file.md]` | [deskripsi 1 baris] | 🔄 Perlu update |

---

## ⚡ YANG BELUM SELESAI / NEXT ACTION

> Ini yang akan dilanjutkan di conversation ini.

```
Prioritas 1 (sekarang)   : [apa yang langsung dikerjakan]
Prioritas 2 (setelahnya) : [apa yang menyusul]
Parkir (nanti)           : [ide/topik yang belum waktunya]
```

---

## PREFERENSI INTERAKSI (Selalu Ada)

```
Gaya respons    : Padat, top-down (gambaran besar dulu, detail belakangan)
Jika salah      : Jelaskan root cause dulu, baru koreksi
Format output   : Teknis → header/tabel/diagram | Santai → conversational
Saat buat file  : Sajikan opsi + tradeoff, biarkan aku yang pilih
Bahasa          : Indonesia, campur English untuk istilah teknis
Jangan          : Disclaimer panjang, basa-basi berlebihan, menebak-nebak
```

---

## KONTEKS TAMBAHAN (Opsional)

> Isi jika relevan untuk conversation ini. Kosongkan jika tidak perlu.

### Kendala / Batasan Saat Ini

```
Hardware  : [contoh: HDD 256GB, RAM 4GB — tidak bisa jalankan VM berat]
Software  : [contoh: Linux Mint, tidak ada akses admin router kampus]
Waktu     : [contoh: malam, butuh jawaban cepat]
```

### Referensi yang Relevan

```
- [Link atau nama file yang berkaitan dengan topik saat ini]
- [contoh: "Lihat TOOLS_PENTING.md untuk hierarki recovery"]
```

---

## JANGAN DIBAHAS (Opsional)

> Topik yang sudah selesai atau tidak relevan di conversation ini.

- [contoh: "Setup Quartz sudah selesai, tidak perlu dibahas lagi"]
- [contoh: "Pertanyaan soal SCP Foundation sudah dijawab wkwkwk"]

---

---

# 📋 CONTOH ISI — Kasus Nyata

> Ini contoh ACTIVE_CONTEXT yang terisi penuh.
> Hapus bagian ini saat dipakai untuk handoff asli.

---

## ⚡ SIAPA AKU

```
Nama/alias  : Azhar
Background  : Mahasiswa Pendidikan Matematika, Bandung
              Self-taught CS/Security dari rasa penasaran
Stack utama : Linux Mint Cinnamon (HDD), Python, Bash,
              Obsidian + Quartz, ESP32, RTL-SDR
Level       : Intermediate — paham konsep sistem, masih
              belajar implementasi dan research formal
Vault       : azhar457.github.io/note
```

---

## ⚡ STATUS SAAT INI

```
Tanggal update : 2026-04-30 23:00 WIB
Conversation   : War Room Session 1 (hampir habis token)
Topik aktif    : Melanjutkan vault Obsidian — ada beberapa
                 file yang belum di-push ke Quartz
Fase           : Documenting → transisi ke implementing
Mood/energy    : Fresh, tapi token hampir habis wkwkwk
```

---

## ⚡ KEPUTUSAN YANG SUDAH DIBUAT

- [x] OS harian: Linux Mint Cinnamon (HDD 256GB, bukan dual boot)
- [x] Kantor: WPS Office (bukan LibreOffice) + Inkscape
- [x] Vault platform: Obsidian + Quartz v4 + GitHub Pages
- [x] Domain: azhar457.github.io/note (is-a.dev pending)
- [x] Conversation microservices: A (War Room) B (Deep Dive) C (Build) D (Debug)
- [x] Personal preferences Claude: sudah di-set di Settings

---

## ⚡ OUTPUT YANG SUDAH ADA

| File                                | Isi Singkat                        | Status                   |
| ----------------------------------- | ---------------------------------- | ------------------------ |
| `MASTER_INDEX.md`                   | Index semua topik + roadmap        | ✅ Di vault              |
| `TOOLS_PENTING.md`                  | Data Recovery + Endpoint + Network | ✅ Di vault              |
| `AI_LEVELS_HIERARCHY.md`            | AI Level 0–11                      | ✅ Di vault              |
| `OS_HIERARCHY.md`                   | OS consumer sampai military        | ✅ Di vault              |
| `KRIPTOGRAFI_BIOMETRIK.md`          | Crypto + Auth stack                | ✅ Di vault              |
| `INFRASTRUKTUR_CLOUD.md`            | Shared hosting → Zero Trust        | ✅ Di vault              |
| `RE_HARDWARE_HACKING.md`            | RE + hardware layer                | ✅ Di vault              |
| `OSINT_RF_HIERARCHY.md`             | OSINT + SIGINT                     | ✅ Di vault              |
| `FONDASI_CS.md`                     | OS Internals + Computer Arch       | ✅ Di vault              |
| `MATEMATIKA_ALGORITMA.md`           | Algo + Diskrit + LinAlg            | ✅ Di vault              |
| `SYSTEM_DESIGN.md`                  | DB Internals + Software Arch       | ✅ Di vault              |
| `EMBEDDED_SYSTEMS.md`               | Embedded + Flash Forensics         | ✅ Di vault              |
| `UNDERGROUND_KNOWLEDGE.md`          | Cheat Engine + Dark Web            | ✅ Di vault              |
| `RESEARCH_METHODOLOGY.md`           | Riset Level 0–8                    | ✅ Di vault              |
| `KURIKULUM_MAPPING.md`              | Mata kuliah → CS/Security path     | ✅ Di vault              |
| `DATA_RECOVERY_FORENSIK.md`         | Tools comparison + workflow        | ✅ Di vault              |
| `SOP_HPA_Exorcism.md`               | HPA/DCO/MBR wipe SOP               | ✅ Di vault              |
| `SOP_OpenSource_Recovery.md`        | ddrescue + DVR recovery            | ✅ Di vault              |
| `WEB_HACKING.md`                    | CTF web playbook                   | ✅ Di vault              |
| `AI_EVALUATION_FRAMEWORK.md`        | LLM testing framework              | ✅ Di vault              |
| `arp-spoofing-mitigation.md`        | ARP defense + PowerShell script    | ✅ Di vault              |
| `arp-spoofing-incident-addendum.md` | IR report professional             | ✅ Di vault              |
| `about.md`                          | Profile page untuk Quartz          | ⚠️ Perlu isi placeholder |

---

## ⚡ YANG BELUM SELESAI / NEXT ACTION

```
Prioritas 1 (sekarang)   : Isi placeholder di about.md
                           (nama, kontak, link sosmed)

Prioritas 2 (setelahnya) : Push semua file baru ke GitHub
                           → npx quartz sync

Prioritas 3              : Daftar is-a.dev untuk custom domain
                           (azhar.is-a.dev atau nama lain)

Parkir (nanti)           : - Implementasi AI_EVALUATION_FRAMEWORK
                             (Python + OpenRouter API)
                           - Eksperimen ESP32 Marauder
                           - Belajar RTL-SDR ADS-B tracking
                           - CTF pertama (picoCTF sebagai start)
```

---

## PREFERENSI INTERAKSI

```
Gaya respons    : Padat, top-down, keberanian epistemik
Jika salah      : Root cause dulu baru koreksi — jangan skip
Format output   : Teknis → terstruktur | Santai → conversational
Saat buat file  : Sajikan opsi + tradeoff
Bahasa          : Indonesia + English untuk istilah teknis
Jangan          : Disclaimer panjang, menebak-nebak, terlalu lembut
```

---

## KONTEKS TAMBAHAN

### Kendala Saat Ini

```
Hardware  : HDD (bukan SSD) — hindari rekomendasi yang butuh SSD
            RAM 4GB — VM berat tidak feasible saat ini
Network   : Kampus — tidak punya akses admin router/switch
ESP32     : Classic N4 (bukan S3) — Bruce firmware tidak support
```

### Referensi Relevan Saat Ini

```
- Vault publik: azhar457.github.io/note
- Repo GitHub: github.com/Azhar457/note
- Portfolio: azharmtq.my.id (geo-locked Indonesia only)
```

---

## JANGAN DIBAHAS

- Setup Quartz sudah selesai dan jalan ✅
- Pertanyaan SCP Foundation sudah dijawab (ARG/fan site) wkwkwk
- Pilihan OS sudah final: Linux Mint Cinnamon
- Hierarki yang sudah selesai tidak perlu dibuat ulang

---

_ACTIVE_CONTEXT | Template + Contoh | Update setiap pindah conversation_
