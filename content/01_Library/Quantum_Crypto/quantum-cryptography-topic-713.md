---
title: "7.1.3 — Quantum Cryptography Notes"
tags: [quantum, crypto]
aliases: [7-1-3]
---
# 7.1.3 — Quantum Cryptography

Topik 7.1.3: kekuatan kriptografi pasca-kuantum dan distribusi kunci kuantum. (1) **Shor** — faktorisasi polinomial-time → RSA/ECC mati; (2) **Grover** — search 2x percepat → AES key size digandakan; (3) **PQC NIST 2024** — ML-KEM (Kyber, KEM), ML-DSA (Dilithium, signature), SLH-DSA (SPHINCS+), FN-DSA (Falcon); (4) **QKD BB84** — foton polarisasi, deteksi eavesdrop (error rate), provably secure via quantum mechanics; (5) **Post-quantum migration** — crypto inventory, hybrid mode (classic + PQC), crypto agility.

Risiko praktis: harvest-now-decrypt-later (data sensitif direkam sekarang, didekripsi saat Q-day). Mulai migrasi aset long-life (data 20+ tahun). Referensi: NIST FIPS 203/204/205, ETSI QKD standards.
---

  audited
---