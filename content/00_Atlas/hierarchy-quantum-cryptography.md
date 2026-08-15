---
title: "Hierarchy Quantum Cryptography"
tags:
  - atlas
  - quantum
  - cryptography
  - post-quantum
  - computing
aliases:
  - "hierarchy-quantum-cryptography"
created: "2026-07-17"
updated: '2026-07-17'
status: pending
cssclasses:
  - wide-table
  
---


# 🔬 HIERARKI QUANTUM CRYPTOGRAPHY — Dari Qubit Theory (Level 0) sampai Full Quantum Supremacy (Level 7)

> Quantum computing bukan "komputer yang lebih cepat" — ini adalah **paradigma komputasi yang berbeda secara fundamental**. Qubit tidak seperti bit: mereka bisa berada di superposisi, terbelit (entanglement), dan collapse saat diukur. Hirarki ini memetakan evolusi dari teori qubit sampai era post-quantum — di mana RSA-2048 bisa dipecahkan dalam jam. Untuk deep dive teknis lengkap (Shor, Grover, hardware, QKD, PQC), lihat [[quantum-cryptography-deepdive]].

> [!info] Cara Baca
> Level 0 = teori (qubit, gerbang dasar). Level 3 = NISQ era (2026). Level 5 = fault-tolerant quantum (2030+). Level 6 = **kita di sini untuk migrasi** — bukan karena quantum sudah tiba, tapi karena harvest-now-decrypt-later. Bedakan antara "quantum computing" (komputasi) vs "post-quantum cryptography" (algoritma baru untuk melawan quantum).

---

## Tabel Utama — Level 0 sampai Level 7

| 🔬 Level | 🧠 Domain | ⚡ Kemampuan & Teknik | ☠️ Tembok / Limitasi | ⏱️ Timeline Realistis |
|---|---|---|---|---|
| **Level 0** — Qubit Theory | Superposisi, entanglement, collapse, gerbang Pauli/Hadamard/CNOT, Bloch sphere | Konsep dasar: qubit bisa 0 dan 1 bersamaan. Gerbang quantum memanipulasi state. CNOT: gerbang 2-qubit pertama yang create entanglement. **Qubit = vector dalam ruang Hilbert** | **Fisika bukan teori** — qubit di lab sangat rapuh. Decoherence dalam mikrodetik. Semua percobaan masih dengan <10 qubit stabil | ✅ 2026: sudah tercapai (fisika dasar well-understood) |
| **Level 1** — Quantum Algorithms | Shor (factorization), Grover (search), Simon (period), Deutsch-Jozsa | Shor: RSA/DH/ECDSA collapse dalam polynomial time. Grover: search N item dalam sqrt(N) — AES-256 jadi AES-128 equivalent. Simon: period finding untuk attack symmetric crypto | **Butuh jutaan qubit stabil** — Shor untuk RSA-2048 butuh ~4.000 logical qubit = ~1 juta physical qubit. **Belum ada di 2026** | ✅ Teori matang. Butuh ~2030–2035 untuk realisasi |
| **Level 2** — Quantum Error Correction | Surface code, repetition code, Shor code, Steane code, logical qubit, fault-tolerant threshold | Qubit fisik noise → error. Surface code: encode 1 logical qubit ke banyak physical qubit. Error rate threshold ~10^-3. Google Willow (2024): 105 qubit dengan error correction breakthrough | **Overhead besar**: 1 logical qubit butuh ~1000 physical qubit dengan surface code. Butuh ~1 juta physical qubit total untuk RSA | 🟡 2026: riset aktif (Google, IBM, Microsoft). Breakthrough tiap tahun |
| **Level 3** — NISQ Era | **N**oisy **I**ntermediate-**S**cale **Q**uantum: ~50–1000 qubit tanpa error correction penuh. IBM Condor (1121 qubit 2023) | **Hybrid classical-quantum** (VQE, QAOA). Berguna untuk kimia kuantum, optimasi, sample masalah spesifik. **TIDAK bisa break RSA** — terlalu noisy | NISQ adalah era transisi. Tidak universal. Ada yang mengatakan NISQ tidak akan pernah menghasilkan speedup praktis (Preskill 2018). Quantum winter risk | 🟡 2024–2030: NISQ era. IBM roadmap target 100k qubit 2033 |
| **Level 4** — Fault-Tolerant Quantum | Logical qubit > physical noise threshold. Surface code decoding real-time. First fault-tolerant universal quantum computer | **Quantum computer yang bisa menjalankan algoritma fault-tolerant.** Shor's pada RSA-2048 theoretically feasible — butuh ~1 juta qubit. Google: target 2030 for 1000 logical qubit | **Belum tercapai.** Masih diperdebatkan apakah satu juta qubit diperlukan atau optimized protocol bisa turunkan | 🟡 2028–2035: target realistis. IBM: 100k qubit 2033. Riset aktif |
| **Level 5** — Cryptographically Relevant Quantum | Quantum computer yang **bisa break RSA-2048 dalam jam** (~4k logical qubit stable) | **Y2Q (Year Zero Quantum)**: titik di mana RSA/DH/ECDSA tidak aman lagi. Semua classical PKI collapse. Post-quantum migration harus selesai SEBELUM sini | **Quantum supremacy di kripto** = infrastruktur PKI global harus PQC-ready. US Government target 2035 migration selesai | 🔴 2030–2040: perkiraan paling umum. China investasi terbesar AS/UK juga |
| **Level 6** — Post-Quantum Migration | CRYSTALS-Kyber (FIPS 203), CRYSTALS-Dilithium (FIPS 204), FALCON, SPHINCS+, hybrid TLS (X25519 + Kyber) | **Ini bukan quantum — ini classical kripto baru yang tahan quantum.** Berbasis lattice (Kyber, Dilithium), hash (SPHINCS+), atau code-based (McEliece). NIST standardisasi 2024. Hybrid TLS roll-out 2025+ | **Ukuran key/signature besar** (Kyber: ~1.5KB pubkey vs RSA 256B). Performance overhead. Migrasi butuh 5–10 tahun untuk sistem kritis | 🔴 **2024–2030: NOW.** Jangan tunggu. Migrasi parallel dimulai |
| **☠️ Level 7** — Full Quantum Supremacy | Quantum yang mengalahkan classical computer di **semua** masalah praktis (bukan hanya kripto). Quantum AI, quantum chemistry, material science, optimization | **Masa depan hipotetis.** 1M+ qubit fault-tolerant universal. Kemampuan yang belum bisa dibayangkan — termasuk mungkin memecahkan masalah yang tidak bisa dihitung secara classical | **Physics limit?** Decoherence, error rate scaling, control electronics complexity. Mungkin quantum akan tetap NISQ-limited selamanya | ❓ 2045–2070+ (jika pernah). Mungkin tidak akan tercapai dalam lifetime kita |

---

## Peta Visual — Timeline & Capability

```
Capability ↑
L7 ─ Full Supremacy  │                ?????
L5 ─ Break RSA-2048  │                ░░ Y2Q ~2030-2040
L4 ─ Fault-Tolerant  │           ░░░░ 2028-2035
L3 ─ NISQ Era       │     ░░░░░░░░ 2024-2030
L1 ─ Algorithms     │  ░░░░░░░░░░░░ 1994-2024
L0 ─ Qubit Theory   │ ░░░░░░░░░░░░░░ 1980-sekarang
                     └──────────────────────────→ Time
                       1990  2000  2010  2020  2030  2040
```

> [!warning] Level 6 (PQC Migration) Adalah Prioritas — Bukan Level 7
> Banyak orang fokus ke "kapan quantum bisa break RSA?" — padahal jawabannya adalah **bisa jadi 2035, bisa jadi tidak pernah.** Yang pasti hari ini: **harvest-now-decrypt-later** adalah ancaman nyata. Data terenkripsi hari ini bisa direkam, disimpan, dan di-dekrip setelah Y2Q. Untuk data dengan TTL 30+ tahun (medical record, government, financial), **PQC migration wajib dimulai sekarang.**

---

## Kenapa Hirarki Ini Penting

### 1. Jangan Campur QKD Dengan PQC

| Aspek | QKD (Quantum Key Distribution) | PQC (Post-Quantum Cryptography) |
|---|---|---|
| Cara kerja | Fisika quantum: detect eavesdropping | Matematika lattice/hash/code |
| Hardware | Butuh fiber optik/satelit + quantum detector | Software/library biasa |
| Jangkauan | ~100km fiber (tanpa repeater) | Global (internet) |
| Scalability | Mahal, point-to-point | Skala global |
| Keamanan | Information-theoretic secure | Computational security |

QKD adalah protocol pertukaran kunci yang menggunakan fisika quantum untuk deteksi penyadap. PQC adalah algoritma matematika baru yang menggantikan RSA/ECC. **Keduanya berbeda, jangan bingung.**

### 2. Legal Timeline: Kapan Migrasi Wajib

| Negara/Region | Regulasi | Timeline |
|---|---|---|
| US | NSM-10 (National Security Memorandum) | 2035: government crypto systems migrate to PQC |
| EU | ETSI quantum-safe migration | 2025+: hybrid certificates |
| China | Dilaporkan milliaran investasi quantum | Target 2030 untuk demonstrasi |
| Indonesia | Belum ada regulasi spesifik | **Ikuti standar internasional** (NIST, ISO) |

US sudah **mewajibkan** federal agency untuk migrasi ke PQC sebelum 2035. Sektor finansial dan health biasanya mengikuti.

### 3. Key Size Dilema — Trade-off Paling Terasa

| Algoritma | Public Key | Signature | Keterangan |
|---|---|---|---|
| RSA-2048 | 256 B | 256 B | Classical, deprecated |
| ECC P-256 | 32 B | 64 B | Classical |
| **Kyber-768** | **1.2 KB** | — | PQC KEM NIST standard |
| **Dilithium-3** | **1.3 KB** | **2.4 KB** | PQC signature NIST standard |
| SPHINCS+ | 64 B | **~8–17 KB** | PQC hash-based, signature besar |
| Classic McEliece | **~260 KB** | — | PQC code-based, publik key raksasa |

Kyber dan Dilithium adalah sweet spot — ukuran masih manageable. Tapi Classic McEliece punya public key 260KB (bandingkan dengan RSA 256B) — tidak feasible untuk internet scale.

---

## Plot Twists

> [!danger] Plot Twist 1: Harvest-Now-Decrypt-Later Bukan Teori — Sudah Terjadi
> NSA, GRU, MSS — semua badan intelijen besar **merekam traffic terenkripsi sekarang** dan menyimpannya untuk di-dekrip nanti saat quantum cukup besar. Data medical record, government communication, financial transaction dengan TTL 30+ tahun terancam bahkan jika quantum baru tiba 2035. **PQC migration = solusi pre-emptive, bukan reaktif.**

> [!warning] Plot Twist 2: Quantum Mungkin Tidak Akan Break RSA — Tapi Itu Tidak Penting
> Ada teori bahwa quantum computing akan tetap NISQ-limited selamanya karena decoherence adalah limit fundamental. Tapi **dampak pada security sudah terjadi sekarang** — karena ketidakpastian timeline membuat planning jadi. Organisasi harus migrasi ke PQC tanpa tahu pasti kapan Y2Q tiba. **Ketidakpastian sendiri sudah menjadi risiko.**

> [!tip] Plot Twist 3: AES-256 Aman Lebih Lama Dari RSA-2048
> Grover's algorithm mengurangi security AES setengahnya — AES-256 menjadi efektif AES-128. Tapi AES-128 masih aman untuk beberapa dekade ke depan (128-bit security). Bandingkan: RSA-2048 yang classical-nya 112-bit security → Shor's collapse jadi polynomial. **Simetric key akan bertahan lebih lama dari asymmetric.**

> [!info] Plot Twist 4: PQC Key Size Masalah Besar Untuk IoT
> Device IoT dengan RAM 256KB dan flash 1MB — Kyber public key 1.2KB bukan masalah. Tapi Classic McEliece 260KB = impossible. TLS handshake dengan PQC signature > MTU 1500 bytes → fragmentasi. **PQC migration untuk IoT butuh optimasi khusus** (lighter parameter set, session resumption, pre-shared key).

> [!info] Plot Twist 5: NIST PQC Bukan Satu-Satunya Game
> China: sedang standardisasi algoritma PQC sendiri (LAC, HQC — berbasis code-based). Russia: GOST series diadaptasi. Ada risiko **fragmentasi global** — satu set algoritma untuk China, satu set untuk NATO, satu set untuk negara non-aligned. Interoperabilitas bisa jadi masalah.

---

## Sumber & Telusur Lebih Lanjut

- **Deep Dive Lengkap (1390 baris)** → [[quantum-cryptography-deepdive]] (qubit → Shor → PQC → QKD → hardware → migration)
- **Classical Crypto Hierarchy (PQC subset)** → [[hierarchy-cryptography]] (Level 5–7 = PQC dan quantum)
- **Timeline Y2Q** → [[quantum-cryptography-deepdive]] (section 20 — threat timeline)
- **PQC Migration Playbook** → [[cryptography-biometrics]] (post-quantum migration roadmap)
- **Quantum Hardware** → [[quantum-cryptography-deepdive]] (sections 15–17: superconducting, trap ion, topological)
- **Network Security Hybrid** → [[hierarchy-network-security]] (hybrid TLS X25519+Kyber)
- **Master Index** → [[master-index]]

---

> Hierarchy quantum cryptography bukan tentang "kapan quantum tiba." Ini tentang **apa yang harus dilakukan sekarang** (PQC migration) vs **apa yang bisa ditunggu** (fault-tolerant quantum). Harvest-now-decrypt-later adalah ancaman yang membutuhkan aksi sekarang — bukan dalam 10 tahun.

*Quantum Cryptography Hierarchy | Level 0 (Qubit Theory) → Level 7 (Full Supremacy) · Y2Q Bisa 2035 — Atau Tidak Pernah — Tapi Migrasi Harus Sekarang*

audited
---
