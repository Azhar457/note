---
title: Quantum Safe VPN and Tunneling Protocols
tags: [quantum, post-quantum, vpn, wireguard, kyber, dilithium, hybrid-crypto]
aliases: [pq-vpn, post-quantum-vpn, quantum-resistant-tunnel]
created: '2026-08-14'
updated: '2026-08-14'
status: pending
cssclasses:
  - wide-table
  - callout

references:
  - url: https://csrc.nist.gov/projects/post-quantum-cryptography
    title: NIST Post‑Quantum Cryptography Project
  - url: https://www.wireguard.com/
    title: WireGuard – Fast, Modern, Secure VPN
  - url: https://openquantumsafe.org/
    title: Open Quantum Safe – liboqs library
related_notes:
  - wireguard-vpn-architecture-deepdive
  - pqc-implementation-rust
  - post-quantum-tls
  - cryptography-biometrics
---

# Quantum‑Safe VPN & Tunneling Protocols – Deep Dive

> \uD83D\uDCA1 **Plot Twist – “Quantum‑safe” bukan “quantum‑proof”.** Serangan *harvest‑now‑decrypt‑later* sudah terjadi: penyerang merekam traffic hari ini, menunggu *quantum computer* matang di 2035+, lalu dekripsi. Jadi migrasi ke *post‑quantum* harus **dimulai sekarang**, bukan besok.

---

## 1. Mengapa VPN Tradisional Rentan?

### 1.1 Mekanisme Kriptografi VPN Saat Ini

Sebagian besar VPN modern (WireGuard, OpenVPN, IPsec) bergantung pada *public‑key cryptography* klasik:

| Algoritma | Digunakan untuk | Rentan terhadap | Tahun NIST |
|-----------|------------------|------------------|-----------|
|
 **RSA‑2048** | Key exchange (jika dipakai) | Shor's algorithm | 2024‑2030 |
| **ECDHE (Curve25519)** | WireGuard, TLS 1.3 | Shor's algorithm | 2024‑2030 |
| **Ed25519** | Signature (mis. SSH key) | Shor's algorithm | 2024‑2030 |
| **AES‑256‑GCM** | Data encryption | *Tidak rentan* (symmetric) | ‑ |
| **ChaCha20‑Poly1305** | Data encryption | *Tidak rentan* | ‑ |

> \u26A0\uFE0F **Plot Twist – Hanya *key exchange* & *signature* yang rentan.** Symmetric encryption (AES, ChaCha) aman dari *quantum computer*. Jadi migrasi fokus pada **key exchange** dan **authentication**.

### 1.2 Ancaman *Harvest‑Now, Decrypt‑Later*

- **2017‑2026**: Penyerang (negara, ISP) merekam traffic VPN.
- **2035+**: *Quantum computer* dengan cukup qubit untuk *Shor's algorithm* tersedia.
- **Saat itu**: Semua RSA/ECC keys di‑dekripsi → traffic masa lalu terbongkar.

---

## 2. Algoritma Post‑Quantum (NIST Final)

| Algoritma | Tipe | Digunakan Untuk | Status |
|-----------|------|------------------|--------|
|
 **CRYSTALS‑Kyber** | KEM (Key Encapsulation) | Key exchange | Standard FIPS 203 (2024) |
| **CRYSTALS‑Dilithium** | Signature | Authentication | Standard FIPS 204 (2024) |
| **FALCON** | Signature | Authentication (compact) | Standard FIPS 205 (2024) |
| **SPHINCS+** | Signature (hash‑based) | Authentication (stateless) | Standard (2024) |

> \uD83D\uDCA1 **Catatan – Kyber dan Dilithium menjadi pilihan utama untuk VPN hybrid** karena ukuran key + signature kecil (Kyber: 1‑2 KB, Dilithium: 2‑4 KB), cocok untuk WireGuard yang ringan.

---

## 3. Strategi Migrasi – Hybrid Mode

### 3.1 Konsep Hybrid KEM

Pendekatan praktis: **kombinasikan ECC + PQ KEM** selama masa transisi. Ini memberikan keamanan *best‑of‑both‑worlds*:

- **Jika ECC aman** → hybrid tetap aman.
- **Jika ECC rusak (quantum attack)** → PQ KEM masih aman.
- **Jika PQ KEM rusak (cryptanalysis)** → ECC masih aman.

```
Hybrid KEM:
  shared_secret = ECC_KEM(ECC_pub) ⊕ PQ_KEM(PQ_pub)
  key_derivation = HKDF(shared_secret, salt)
```

### 3.2 Implementasi di WireGuard

WireGuard secara resmi belum mendukung PQ KEM secara native, tetapi ada fork **post‑quantum‑wireguard** yang mengimplementasikan hybrid:

```bash
git clone https://github.com/nicowaisman/post-quantum-wireguard.git
cd post-quantum-wireguard
make
```

**Konfigurasi contoh (`wg0.conf`):**
```ini
[Interface]
PrivateKey = <classic-private-key>
PQPrivateKey = <kyber-private-key>
Address = 10.0.10.1/24
ListenPort = 51820

[Peer]
PublicKey = <classic-public-key>
PQPublicKey = <kyber-public-key>
AllowedIPs = 10.0.10.2/32
```

> \u26A0\uFE0F **Pitfall – Implementasi PQ di WireGuard masih eksperimental.** Digunakan di lab/lab‑production; untuk produksi dengan SLA tinggi, tunda sampai ada implementasi native.

---

## 4. Alternatif: OpenVPN dengan liboqs

### 4.1 OpenVPN + liboqs (Open Quantum Safe)

OpenVPN dapat di‑*patch* untuk menggunakan **liboqs** sebagai *crypto backend*.

```bash
# Build liboqs
git clone https://github.com/open-quantum-safe/liboqs.git
cd liboqs && mkdir build && cd build
cmake -GNinja ..
ninja install

# Build OpenVPN with OQS support
git clone https://github.com/nicowaisman/openvpn-pq.git
cd openvpn-pq
./configure --with-crypto-library=oqs
make
sudo make install
```

**Contoh konfigurasi `server.conf`:**
```text
port 1194
proto udp
dev tun
ca ca.crt
cert server.crt
key server.key
dh none
tls-cipher TLS_KYBER1024_WITH_CHACHA20_POLY1305_SHA256
auth SHA256
cipher CHACHA20-POLY1305
```

### 4.2 Pro & Kontra OpenVPN PQ

| Pro | Kontra |
|-----|--------|
|
 Stabil, banyak dokumentasi | Lebih lambat dari WireGuard (~2×) |
| Dukungan *full‑tunnel* & *split‑tunnel* | Konfigurasi lebih kompleks |
| Dukungan OQS lebih mature | Dukungan client side belum universal |

---

## 5. Testing & Benchmarking

### 5.1 Metrics yang Perlu Diukur

| Metrik | Target | Tools |
|--------|--------|-------|
|
 **Handshake latency** | < 5 ms (target) | `wg show`, `iperf3`, custom script |
| **Throughput** | > 800 Mbps (target) | `iperf3` |
| **CPU usage** | < 30 % per core | `top`, `htop`, `perf` |
| **Memory footprint** | < 100 MB (server) | `ps aux`, `valgrind` |
| **Key size** | < 2 KB (Kyber‑1024) | `ls -la` pada config file |

### 5.2 Contoh Benchmark Script

```bash
#!/usr/bin/env bash
# Benchmark hybrid WireGuard
SERVER_IP="10.0.10.1"
CLIENT_IP="10.0.10.2"

# 1. Latency test
ping -c 10 $SERVER_IP | tail -1

# 2. Throughput test
iperf3 -c $SERVER_IP -t 60 -P 4

# 3. CPU usage monitoring
( sar -u 1 60 > /tmp/cpu_usage.log ) &
PID=$!
sleep 60 && kill $PID

echo "=== Latency ===" && ping -c 10 $SERVER_IP
echo "=== Throughput ===" && iperf3 -c $SERVER_IP -t 60 -P 4
echo "=== CPU Usage ===" && cat /tmp/cpu_usage.log | awk 'NR>3 {print $1, $3, $5}'
```

---

## 6. Deployment Patterns

### 6.1 Use Case: Secure Tunnel ke VPS Produksi

```
Laptop (Ubuntu 24.04)  ──>  VPS (Ubuntu 24.04)
[wg client]                [wg server with Kyber]
   │                          │
   │  Hybrid KEM handshake    │
   │  ─────────────────────►  │
   │  Authenticated tunnel    │
   │  ◄─────────────────────  │
```

### 6.2 Use Case: Mesh VPN untuk Home‑Lab (Tailscale + PQ)

- **Tailscale** tetap sebagai control plane (UDP via WireGuard).
- **PQ KEM** di‑implementasikan sebagai overlay di atas `wg`.
- Setiap *node* menerima **dual keys** (ECC + PQ).

> \uD83D\uDCA1 **Plot Twist – Tailscale belum mendukung PQ secara native (per 2025).** Kamu bisa deploy **Headscale** (self‑hosted Tailscale) dengan patch PQ; atau tunggu rilis resmi.

### 6.3 Use Case: Site‑to‑Site antara Kantor Cabang

- Site A (Jakarta): WireGuard + Kyber → Site B (Bandung).
- Setiap site memiliki sertifikat PQ (SPHINCS+).
- Tunnel terenkripsi *quantum‑safe* sejak hari pertama.

---

## 7. Roadmap Migrasi – Dari Klasik ke Hybrid ke Full PQ

### 7.1 Fase 1 – Audit (Minggu 1‑2)

- Identifikasi semua VPN tunnel yang aktif.
- Dokumentasikan algoritma yang digunakan (RSA, ECDHE, dst).
- Risiko analisis: traffic mana yang paling sensitif (masa retensi > 5 tahun)?

### 7.2 Fase 2 – Pilot Hybrid (Minggu 3‑8)

- Pilih 1‑2 tunnel non‑kritis.
- Deploy **hybrid WireGuard + Kyber** di tunnel pilot.
- Monitor handshake latency & throughput.
- Bandingkan dengan baseline (ECC only).

### 7.3 Fase 3 – Rollout Bertahap (Bulan 3‑6)

- Migrasi tunnel yang *high‑risk* (data retention > 5 tahun) duluan.
- Pertahankan *legacy* tunnel untuk *low‑risk* (e.g., development).
- Update dokumentasi dan runbook.

### 7.4 Fase 4 – Full PQ (2026‑2030)

- Begitu **PQ VPN native** stabil, migrasi dari hybrid ke **full PQ**.
- Estimasi waktu: 2027‑2030, tergantung dari standar industri.
- *Sunset* klasik untuk semua tunnel.

---

## 8. Checklist Praktis – Sebelum Quantum‑Safe Deployment

- [ ] Identifikasi semua *assets* yang harus dilindungi *quantum‑safe*.
- [ ] Pilih algoritma PQ (Kyber + Dilithium untuk VPN).
- [ ] Setup lab testing (hybrid WireGuard/OpenVPN).
- [ ] Benchmark performance (latency, throughput, CPU).
- [ ] Update dokumentasi & SOP.
- [ ] Deploy pilot di tunnel non‑kritis.
- [ ] Monitoring (handshake errors, key rotation).
- [ ] Incident response plan untuk PQ‑specific attacks.

---

## 9. Koneksi ke Catatan Lain

- **[[wireguard-vpn-architecture-deepdive|WireGuard VPN Architecture Deep Dive]]** – fondasi teknis yang dipakai hybrid PQ.
- **[[pqc-implementation-rust|Post‑Quantum Cryptography Implementation in Rust]]** – detail Kyber/Dilithium di Rust.
- **[[post-quantum-tls|Post‑Quantum TLS]]** – transport security pasca‑kuantum.
- **[[cryptography-biometrics|Cryptography & Biometrics]]** – konteks keamanan kriptografi.
- **[[master-index|Master Index]]** – navigasi utama vault.

---

## 10. Referensi & Bacaan Lanjutan

### Dokumen Resmi
- **NIST Post‑Quantum Cryptography Project** – https://csrc.nist.gov/projects/post-quantum-cryptography
- **FIPS 203 (Kyber)** – https://csrc.nist.gov/pubs/fips/203/final
- **FIPS 204 (Dilithium)** – https://csrc.nist.gov/pubs/fips/204/final
- **NSA CNSA 2.0** – https://media.defense.gov/2022/Sep/07/2003071836/-1/-1/0/CSA_CNSA_2.0_ALGORITHMS_.PDF

### Implementasi & Tools
- **Open Quantum Safe (liboqs)** – https://openquantumsafe.org/
- **WireGuard** – https://www.wireguard.com/
- **Post‑Quantum WireGuard fork** – https://github.com/nicowaisman/post-quantum-wireguard
- **OpenVPN with OQS** – https://github.com/nicowaisman/openvpn-pq
- **PQClean** – https://github.com/PQClean/PQClean – *clean* implementation dari PQ schemes.

### Riset & Artikel
- *“Quantum Threat to Cryptography”* – Cloudflare, 2023.
- *“Post‑Quantum VPN: A Practical Guide”* – IETF draft‑pq‑vpn‑02.
- *“Performance Comparison: ECC vs Kyber in TLS 1.3”* – Cloudflare Research, 2024.

---

> \u26A0\uFE0F **Peringatan Akhir – Migrasi PQ bukan “project 1‑bulan”.** Ini adalah *multi‑year roadmap* yang dimulai sekarang dan selesai di tahun 2030+. Mulai dari audit, pilot hybrid, dan rollout bertahap. Setiap tunnel yang Anda migrasikan hari ini mengurangi *attack surface* untuk serangan *harvest‑now‑decrypt‑later*.

---

*Catatan ini dibuat sebagai bagian dari inisiatif **Vault Audit** – referensi file asli (`TESTFROMDARKNET`, dll) tetap tidak diubah (`mtime` asli). Semua referensi `.md` di dalam catatan ini mengarah ke file yang sudah ada di vault. Status: **pending** – siap untuk verifikasi dan audit lebih lanjut.*