---
title: "CTF and Cyber Competition Framework"
tags:
  - atlas
  - ctf
  - cyber-competition
  - methodology
  - universal-framework
aliases:
  - "hierarchy-ctf-competition-framework"
created: "2026-07-28"
updated: '2026-07-28'
status: pending
cssclasses:
  - wide-table
  
---


# 🏆 HIERARCHY CTF & CYBER COMPETITION FRAMEWORK — Dari Wargame Pemula sampai Live Red vs Blue Exercise

> Capture The Flag (CTF) dan turunannya (Attack-Defense, Forensik, Red vs Blue Exercise) adalah **cara paling efisien untuk mengukur dan melatih kemampuan teknis keamanan siber** di luar produksi. Berbeda dari sertifikasi yang menguji hafalan, kompetisi menguji kemampuan memecahkan masalah baru di bawah tekanan waktu. Hirarki ini memetakan evolusi bentuk kompetisi dari **Level 0 (wargame online pemecah soal individu)** sampai **Level 6 (live-fire range dengan infra nyata)** — semua level **universal**, tidak terikat pada satu event atau satu penyelenggara.

> [!info] Cara Baca Atlas Ini
> Mulai dari **Level 0** kalau kamu baru pertama kali ikut CTF. Loncat ke **Level 4–6** kalau sudah pernah jadi finalis atau sudah kerja di SOC/IR. Setiap level punya **kontrak kompetensi yang bisa diukur** — bukan hanya "pernah ikut". Untuk methodology konkret saat kompetisi, lihat [[ctf-competition-methodology-strategy]]. Untuk tool arsenal per level, lihat [[ctf-tool-arsenal-universal]].

---

## Tabel Utama — Level 0 sampai Level 6

| 🏆 Level                                                          | 🎯 Format                                                                    | ⏱️ Durasi               | 🧠 Kompetensi Inti yang Diukur                                                      | 🎭 Tipe Orang yang Kompeten                                                          | 🛠️ Contoh Platform / Event                                                             |
| ----------------------------------------------------------------- | ---------------------------------------------------------------------------- | ----------------------- | ----------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------ | --------------------------------------------------------------------------------------- |
| **Level 0** — Solo Wargame / Quiz Pemula                          | Individual, soal-soal independen, auto-grader                                | Bebas (latihan mandiri) | Konsep dasar: encoding, hashing, cipher klasik, OSINT ringan, logika                | Mahasiswa semester 1–3, pemula tanpa pengalaman                                      | PicoCTF, OverTheWire Bandit (0–10), Cryptopals set 1, TryHackMe beginner path           |
| **Level 1** — Jeopardy CTF (Static)                               | Tim, kategori soal independen, flag statis, scoring per-flag                 | 24–72 jam               | Multi-disiplin dasar: web, crypto, reverse, pwn, forensic, misc                     | Mahasiswa tingkat akhir, junior security engineer, tim kampus pertama                | CTF beginner-to-intermediate (picoCTF, TAMU CTF, PicoMini), CSAW CTF Quals              |
| **Level 2** — Jeopardy CTF (Dynamic / Hard)                       | Soal dengan service yang berjalan, patch & exploit dinamis                   | 24–48 jam               | Exploit chain, bypass WAF/IDS, real-time patching, multi-stage                      | Tim universitas berpengalaman, profesional muda, komunitas nasional                  | DEF CON CTF Quals, Google CTF, PlaidCTF, HackTheBox (offensive path)                    |
| **Level 3** — Attack-Defense CTF                                  | Setiap tim punya server sendiri, saling serang & mempertahankan service      | 6–10 jam (offline)      | Network hardening, patch cepat, exploit adversary, service monitoring               | Tim Penyerang dan Pertahanan terlatih, finalis nasional, security engineer full-time | RuCTF, iCTF, RuCTFE, ENOWARS, FAUST CTF, FAUST                                          |
| **Level 4** — Live Red Team Exercise (Cooperative)                | Tim red vs tim blue pada environment bersama, evaluator jadi white cell      | 2–5 hari                | Adversary emulation, detection engineering, TTP chaining, blue team playbooks       | Red/blue team profesional, SOC analyst, threat hunter, detection engineer            | CCDC (National Collegiate Cyber Defense), Locked Shields (NATO CCDCOE), Cyber Coalition |
| **Level 5** — Live Red Team vs Production-like Blue Team          | Tim red free-form, blue team produksi incident response                      | 1–4 minggu              | Real-world intrusion chain, evasion, persistence, exfiltration under SOC monitoring | Nation-state APT-equivalent red team, senior SOC analyst, IR lead                    | CBEST (UK Bank of England), TIBER-EU, purple team engagement enterprise                 |
| **☠️ Level 6** — Cyber Range / Critical Infrastructure Simulation | Whole-of-nation exercise, multi-domain (cyber + physical + comms + decision) | 1–3 minggu              | Crisis decision-making, cross-sector coordination, kinetic-cyber convergence        | CISO, National CSIRT, military cyber command, critical infrastructure operator       | NATO Cyber Coalition, Cyber Guard (US DoD), GridEx (NERC), AUSCDE (Australia)           |

---

## Peta Visual — Kompetensi vs Kompleksitas

```
Kompleksitas ↑│
              │   L6 ─ Critical Infra Sim         ●●●●●●  ●  Kinetic+Cyber
              │   L5 ─ Live Red Team vs Prod-Blue ●●●●●       ●● Real SOC
              │   L4 ─ Cooperative Red vs Blue    ●●●●        ●●● Eval=WhiteCell
              │   L3 ─ Attack-Defense CTF         ●●●             ●● Auto-grader
              │   L2 ─ Jeopardy Hard/Dynamic      ●●                  ●● Auto-grader
              │   L1 ─ Jeopardy Static Beginner   ●                    ●● Auto-grader
              │   L0 ─ Wargame Solo                  ●
              │       └──────────────────────────────────────────→ Difficulty/Solo
              │
              └──────────────────────────────────────────────────→ Time Pressure
```

---

## Kenapa Hirarki Ini Penting

### 1. Kompetisi Bukan Sekadar Soal — Tapi Training Loop

CTF adalah **closed-loop micro-incident**:
- Anda gagal → tidak ada production impact
- Anda sukses → dapat skor langsung
- Anda berulang → kemampuan ter-koherensi naik secara eksponensial

Survei nasional (US CyberSeek 2024): engineer dengan track record CTF Top-100 rata-rata mendapat pekerjaan 3–6 bulan lebih cepat dari yang tanpa track record.

### 2. Setiap Level Mengukur Skill Berbeda

| Skill | Mulai Relevan di Level | Puncak di Level |
|-------|------------------------|-----------------|
| Reading source code | L0 | L3 |
| Reverse engineering | L1 | L3 |
| Exploit development | L2 | L3 |
| Patch dalam menit | L3 | L3 |
| Network defense | L3 | L5 |
| Threat hunting | L4 | L5 |
| Crisis decision | L5 | L6 |
| Cross-domain coordination | L6 | L6 |

**Tidak ada level yang "lebih tinggi" otomatis lebih baik.** SOC analyst mungkin lebih tajam di L4–L5 daripada attacker murni yang jago di L2–L3.

### 3. CTF Mengajarkan "Meta-Skill" yang Tidak Ada di Kursus

Yang tidak diajarkan kursus tapi dilatih CTF:
- **Time triage** — skip soal value rendah, fokus value tinggi
- **Delegation** — bagi tugas sesuai spesialisasi anggota tim
- **Tool-switching** — fallback kalau tool utama gagal
- **Frustration tolerance** — 24 jam tanpa hasil yang berarti
- **Writeup discipline** — dokumentasi yang bisa dipelajari orang lain

---

## Kontrak Kompetensi Per Level

### Level 0 — Solo Wargame
**Yang harus bisa:** install Linux/WSL, navigasi CLI dasar, baca pesan error, copy-paste command dari writeup.
**Yang TIDAK relevan di level ini:** exploit development, binary analysis, network sniffing.

### Level 1 — Jeopardy Static
**Yang harus bisa:** identifikasi tipe soal dalam 30 detik, tahu tool default per kategori (CyberChef, binwalk, strings, exiftool), bisa baca source code Python/JavaScript singkat.
**Yang TIDAK relevan:** patching, service maintenance, evasion.

### Level 2 — Jeopardy Dynamic
**Yang harus bisa:** exploit chain (3+ step), patch binary/script dalam menit, bypass anti-cheat sederhana, log analysis real-time.
**Yang TIDAK relevan:** full network defense, IR formal.

### Level 3 — Attack-Defense
**Yang harus bisa:** hardening service dalam menit, tulis exploit yang reliable (bukan one-shot), monitor service health, inject flag ke sesama tim, baca packet capture real-time.
**Yang TIDAK relevan di sini:** long-running operation, formal IR procedure.

### Level 4 — Cooperative Red vs Blue
**Yang harus bisa:** main di playbook tim, komunikasikan intent ke evaluator, baca ATT&CK matrix, joint after-action review.
**Yang TIDAK relevan:** zero-day research, full nation-state tooling.

### Level 5 — Live Red Team vs Prod-Blue
**Yang harus bisa:** hidup di bawah SOC detection, chain 5+ TTP tanpa terdeteksi, persistence dalam waktu lama, exfiltration.
**Yang TIDAK relevan:** latihan murni akademis.

### Level 6 — Critical Infrastructure Sim
**Yang harus bisa:** komunikasi ke eksekutif non-teknis, decision di bawah ketidakpastian, prioritas sumber daya, dokumentasi untuk audit publik.
**Yang TIDAK relevan:** teknik murni, exploit delivery.

---

## Plot Twists

> [!danger] Plot Twist 1: Skor Tertinggi ≠ Skill Terbaik
> Banyak tim yang juara CTF statis (L1–L2) tapi gagal di attack-defense (L3) karena **mereka hanya belajar "solve" bukan "operate"**. Operation skill (monitoring, patch cepat, teamwork) tidak dilatih di jeopardy. Lompatan L2 → L3 adalah **perubahan paradigm**, bukan peningkatan incremental.

> [!tip] Plot Twist 2: Attack-Defense Lebih Akurat Mengukur "Engineer Real"
> Attack-Defense (L3) mengukur skill yang sama yang dipakai di SOC/IR harian: **service maintenance + rapid patching + monitoring**. Jeopardy tidak mengukur skill itu. Jika Anda ingin kerja di SOC/IR/blue team, train di L3+. Jika Anda ingin jadi researcher/RE, train di L2.

> [!info] Plot Twist 3: Live Exercise (L4+) Butuh Psikologi, Bukan Teknik
> Saat evaluator kasih Anda "server sudah compromised, apa yang Anda lakukan dalam 5 menit?" — yang diuji bukan exploit, tapi **prioritization, communication, decision under pressure**. Multi-national exercise (L6) bahkan masuk ke **geopolitics & legal framework** (apakah Anda diizinkan counter-attack? Boleh ambil-down service?). Skill teknis murni Anda hanya 30% dari nilai total.

> [!warning] Plot Twist 4: Semua Level Punya "Cheat Code" yang Berbeda
> - L0: cari writeup online (tidak ada cheat — itu memang latihan)
> - L1: bagiin tugas ke anggota tim, jangan solo
> - L2: patch cepat lebih penting dari exploit sophisticated
> - L3: monitoring + alert > fancy exploit
> - L4: komunikasi > teknis
> - L5: persistence + stealth > first-time success
> - L6: dokumentasi > kecepatan

---

## Cross-Link ke Atlas Lainnya

- **Cyber Kill Chain (Offense)** → [[00_Atlas/hierarchy-cybersecurity-defense-architecture]]
- **Defensive Ring Hierarchy (Endpoint)** → [[hierarchy-endpoint-security]]
- **Network Defense (L3 ke atas)** → [[hierarchy-network-security]]
- **Threat Modeling** → [[hierarchy-threat-modeling]]
- **Malware Analysis (RE)** → [[hierarchy-malware-analysis]]
- **Supply Chain (CTF infra)** → [[hierarchy-supply-chain-security]]
- **Master Index** → [[master-index]]

---

*CTF & Cyber Competition Hierarchy | Level 0 (Solo Wargame) → Level 6 (Critical Infra Sim) · Skill Berbeda Per Level · "Score Tertinggi" ≠ Skill Terbaik*

audited
---
