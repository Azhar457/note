---
title: Hierarchy Threat Modeling
tags:
  - atlas
  - threat-modeling
  - risk
  - blue-team
aliases:
  - hierarchy-threat-modeling
created: 2026-07-17
updated: 2026-07-17
status: completed
cssclasses:
  - wide-table
  - callout
---

# 🛡️ HIERARKI THREAT MODELING — Dari Intuisi Developer (Level 0) sampai Formal Verification (Level 5)

> Threat modeling adalah **proses sistematis untuk menjawab "Apa yang terburuk yang bisa terjadi?" sebelum kode ditulis.** Bukan mendokumentasikan ancaman untuk kepentingan audit — tapi untuk mengubah keputusan desain sebelum terlambat. Hirarki ini memetakan evolusi kedalaman analisis: dari sekadar STRIDE checklist, sampai formal verification yang membuktikan properti keamanan secara matematis. Untuk metodologi lengkap + praktik, lihat [[threat-modeling-deepdive]].

> [!info] Cara Baca
> Level 0 = intuisi (murah, subjektif). Level 5 = formal proof (mahal, presisi). Semakin tinggi level, semakin pasti jawabannya — tapi semakin mahal. Organisasi yang baik memilih level yang sepadan dengan criticality sistem.

---

## Tabel Utama — Level 0 sampai Level 5

| 🛡️ Level | 🧠 Pendekatan | ⚡ Metodologi | ☠️ Tembok Kematian | 🎯 Kapan Digunakan |
|---|---|---|---|---|
| **Level 0** — Intuisi Developer | "Apa yang berbahaya?" tanpa framework formal. Brainstorm berdasar pengalaman | Semua orang bisa — hanya butuh knowledge domain + pengalaman security | Bias konfirmasi: lo hanya lihat ancaman yang sudah lo kenal. Tidak sistematis, banyak blind spot | Side project, MVP, personal app tanpa data sensitif |
| **Level 1** — STRIDE Checklist | Microsoft STRIDE: **S**poofing, **T**ampering, **R**epudiation, **I**nformation Disclosure, **D**enial of Service, **E**levation of Privilege | Cocok STRIDE tiap elemen DFD. Sederhana, mudah diingat, dokumentasi rapi | Tidak bisa capture business logic flaw. Tidak bisa prioritasi risiko. Satu model cocok untuk semua (tidak spesifik industri) | Startup, mid-size company, secure SDLC awal |
| **Level 2** — Attack Tree | Pohon AND/OR: dari goal attacker → sub-actions leaf. Setiap leaf punya cost/skill indicator | Visual intuitif. Komunikasi dengan non-teknis. Bisa kuantifikasi effort attacker | Pohon membesar eksponensial untuk sistem kompleks. Tidak handle multiple attackers parallel | Bug bounty scoping, threat intel brief, komunikasi manajemen |
| **Level 3** — PASTA (7-Stage) | **P**rocess for **A**ttack **S**imulation and **T**hreat **A**nalysis: 1. Business objective 2. Technical scope 3. App decomposition 4. Threat analysis 5. Vuln analysis 6. Attack simulation 7. Risk & impact | Risk-based + business-driven. Output: risk register, prioritized mitigations | Heavy process (butuh ~2 hari–1 minggu per sistem). Butuh threat modeling specialist | Sistem kritis (finansial, healthcare), regulated industry, enterprise risk management |
| **Level 4** — Continuous Threat Modeling | Integrasi TM di CI/CD: OWASP Threat Dragon → update otomatis di pipeline. Security champion review tiap sprint | Threat model tidak dokumen statis — hidup berubah bersama kode. OWASP Threat Dragon: open-source TM tool | Butuh budaya security champion. CI/CD integration tooling masih berkembang. **False positive noise** tinggi | DevOps mature, platform engineering, unicorn/enterprise |
| **☠️ Level 5** — Formal Verification | ProVerif, Tamarin, Alloy, TLA+, formal proof of security properties | **Mathematical proof** bahwa properti keamanan berlaku untuk semua state. Tidak ada false positive — hitam-putih | **Waktu**: formal verification satu protokol kripto butuh bulan–tahun. Butuh PhD-level knowledge. Skalabilitas rendah | Protokol kripto, secure boot chain, hardware security module, military grade system |

---

## Peta Visual — Effort vs Certainty

```
Certainty ↑
  L5 ─ Formal Proof      ●
  L4 ─ Continuous TM     ●←●
  L3 ─ PASTA 7-Stage      ●←●●
  L2 ─ Attack Tree          ●←●●●
  L1 ─ STRIDE Checklist      ●←●●●
  L0 ─ Intuition               ●←●●●●
      └────────────────────────→ Effort
```

> [!warning] Level 0–1 Cukup untuk 80% Kasus
> Jangan over-invest di threat modeling. Untuk aplikasi CRUD internal tanpa data sensitif — STRIDE checklist (L1) + attack tree untuk fitur kritis (L2) sudah cukup. **Level 3+ untuk sistem yang jika breach = kebangkrutan atau kematian.** (Pikirkan: medical device, flight control, core banking.)

---

## Kenapa Hirarki Ini Penting

### 1. Threat Modeling Bukan Sekali — Harus Iteratif

Setiap perubahan arsitektur → update threat model. API baru → tambah STRIDE per endpoint. Dependencies baru → attack tree baru untuk supply chain.

Threat model yang tidak pernah diupdate adalah **dokumen yang menua tanpa guna**. Level 4 (continuous TM) mengatasi ini dengan integrasi otomatis di pipeline.

### 2. Output Threat Model = Input untuk Security Testing

| Level Threat Model | Output → Untuk |
|---|---|
| L0–L1 (STRIDE) | Checklist security requirement → SAST rules |
| L2 (Attack Tree) | Attack path → prioritasi penetration test |
| L3 (PASTA) | Risk register → control allocation |
| L4 (Continuous) | Auto-generated test case → DAST/IAST |
| L5 (Formal) | Proof of security → certification (CC EAL7, FIPS) |

### 3. Dual-Use: Red Team Juga Threat Model — Tapi Untuk Goal Berbeda

Defender: "Bagaimana attacker bisa masuk?"
Red teamer/attacker: "Apa kontrol defender yang paling lemah?"

Kedua threat model menggunakan hirarki dan metodologi yang sama — hanya perspektif yang berbeda.

---

## Plot Twists

> [!danger] Plot Twist 1: STRIDE Tidak Handle Business Logic
> STRIDE excellent untuk ancaman teknis. Tapi business logic flaw (lo bisa transfer uang tanpa otorisasi karena race condition) bukan milik kategori STRIDE manapun. **Complement STRIDE dengan misuse case atau process flow analysis** untuk tangkap ancaman business logic.

> [!tip] Plot Twist 2: Attack Tree (L2) Paling Efektif Untuk Komunikasi Dengan Bos Non-Teknis Attack tree: visual, intuitif, langsung lihat "kalau attacker mau capai X, harus lewat jalur Y." Untuk presentasi ke CTO/CEO — attack tree mengalahkan STRIDE table mana pun. Tambahkan cost indikator (per node) untuk justifikasi budget security.

 > [!tip] Plot Twist 3: Formal Verification (L5) Digunakan NSA, Bukan Startup ProVerif dan Tamarin dipakai untuk verifikasi protokol kripto TLS 1.3, Signal Protocol, WireGuard. **Butuh waktu bulan–tahun** untuk satu protokol. Untuk aplikasi web biasa, Level 5 adalah overshoot. Tapi untuk secure boot chain, HSM firmware, dan protokol kripto baru — L5 adalah satu-satunya cara untuk "pasti".

> [!info] Plot Twist 4: AI-Assisted Threat Modeling Sedang Muncul (2025+) LLM-based TM tools mulai muncul: generate STRIDE dari arsitektur diagram, expand attack tree dari deskripsi, saran mitigasi dari CVE database. **Tapi belum bisa gantikan human reasoning** — untuk ancaman yang membutuhkan konteks bisnis spesifik atau zero-day technique, AI masih hallucinate. Level 4 (continuous TM) akan sangat terbantu AI untuk automasi rutin.


## Sumber & Telusur Lebih Lanjut

- **Deep Dive Threat Modeling** → [[threat-modeling-deepdive]] (STRIDE, PASTA, Attack Tree lengkap)
- **Security Requirements dari Threat Model** → [[comprehensive-threat-directory]] (taksonomi ancaman)
- **Endpoint Security (STRIDE per device)** → [[endpoint-detection-playbook]]
- **Network Threat Model (STRIDE per OSI)** → [[hierarchy-network-security]]
- **Formal Verification** → [[quantum-cryptography-deepdive]] (formal proof in crypto context)
- **Master Index** → [[master-index]]

> Threat modeling bukan tentang "berapa banyak ancaman yang lo temukan." Ini tentang **seberapa yakin lo bahwa lo sudah menemukan ancaman yang paling berbahaya**. Pilih level yang membangun keyakinan itu — tanpa menghabiskan budget untuk ancaman yang tidak relevan.

*Threat Modeling Hierarchy | Level 0 (Intuition) → Level 5 (Formal Verification) · Seberapa Yakin Kamu?*
