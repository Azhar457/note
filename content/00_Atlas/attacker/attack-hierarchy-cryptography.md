---
title: Attack Perspective — Cryptography (Classical → Post-Quantum)
tags:
- attack
- red-team
- cryptography
- post-quantum
- cve
- tls
- pki
source: hierarchy-cryptography.md
status: complete
created: '2026-08-14'
updated: '2026-08-14'
cssclasses:
  - wide-table
  - callout
---


# 🔴 Attack Perspective: Cryptography — Timeline Kematian Algoritma

> **Perspektif red team:** Bukan "bagaimana enkripsi bekerja" tapi **bagaimana memecahkan atau bypass kriptografi** — dari frequency analysis (Level 0) sampai harvest-now-decrypt-later (Level 7 PQC). Dual-use: defender memilih algoritma; attacker memilih algoritma yang belum deprecated atau mencari implementasi yang salah.

---

## 1. Per-Level Attack Surface

| Crypto Level                                                     | Attacker Goal                                                                          | Concrete CVE / Technique                                                                                                                                                                                                                                                                                                                                                                                                | Evasion / Bypass                                                                                                                                                                                                                                                                                                   | Detection Gap                                                                                                                                                                                                                                                                         |
| ---------------------------------------------------------------- | -------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **L0** Classical Cipher                                          | Pecahkan cipher dengan frequency analysis                                              | Caesar (geser N), Vigenère (kunci berulang) — dipecahkan dalam menit via frequency analysis huruf                                                                                                                                                                                                                                                                                                                       | Tidak perlu evasi — cipher sudah rusak secara matematis — serangan hanya butuh analisis statistik                                                                                                                                                                                                                  | Tidak ada defense — cipher ini hanya edukasi                                                                                                                                                                                                                                          |
| **L1** Symmetric (DES/3DES mati, AES-256 hidup)                  | Brute force key / side-channel / timing attack                                         | DES (56-bit) — EFF DES Cracker 1999 (22 jam). AES-256: Grover's algorithm mengurangi ke 128-bit (tahan quantum kecil). Side-channel: power analysis (SPA/DPA) — CVE-2014-0160 (Heartbleed — implementasi TLS, bukan AES)                                                                                                                                                                                                | Brute force: distributed attack (botnet). Side-channel: physical access + oscilloscope — sulit evasi tapi high value. AES-256 sendiri belum pecah — serang implementasi (key management, random number generator)                                                                                                  | Defender bergantung pada AES-256 — tapi key management (DPAPI, KMS) sering lemah. Random number generator (CVE-2008-0166 — Debian OpenSSL weak RNG — semua key prediktif)                                                                                                             |
| **L2** Asymmetric (RSA/ECC)                                      | Shor's algorithm (quantum) / classic attack (factoring, discrete log)                  | RSA-1024: dipecahkan. RSA-2048: belum pecah classic. ECC P-256: belum pecah classic. **Quantum:** Shor's algorithm — RSA/ECC mati saat quantum cukup besar. **Classic:** CVE-2014-0160 (Heartbleed — memory leak dari TLS handshake — private key bisa bocor). CVE-2017-11185 (ROBOT — RSA key extraction via padding oracle)                                                                                           | Classic: exploit implementasi (padding oracle, memory leak), bukan algoritma. Quantum: **harvest-now-decrypt-later** — rekam traffic TLS sekarang — decrypt saat quantum aktif (~2030-2035). Tidak perlu evasi — serangan pasif (passive interception)                                                             | Defender bergantung pada RSA/ECC — tapi tidak semua organisasi migrasi ke PQC. Traffic yang direkam sekarang tidak bisa dideteksi sebagai serangan (pasif) — defender baru sadar saat data sudah terbuka                                                                              |
| **L3** Hash (MD5 mati, SHA-1 mati, SHA-256 hidup)                | Collision attack (MD5/SHA-1) / preimage (SHA-256 belum)                                | MD5: collision 2004 (Wang et al.). SHA-1: SHAttered 2017 (Google). SHA-256: belum pecah — tapi Grover's halving (128-bit security). CVE-2012-3287 (DNS cache poisoning via MD5 collision — Kaminsky attack) — tidak perlu collision — hanya hash collision untuk spoof DNS                                                                                                                                              | Collision: generate 2 dokumen dengan hash sama — satu legitimate, satu malicious — swap setelah verifikasi. Preimage: belum praktis untuk SHA-256. Brute force: distributed — belum praktis                                                                                                                        | Defender bergantung pada SHA-256 — tapi banyak legacy system masih pakai MD5/SHA-1 (file checksum, certificate fingerprint). Defender yang tidak audit semua hash — vulnerable                                                                                                        |
| **L4** Protocol (TLS 1.3, WireGuard, Signal)                     | Protocol downgrade / padding oracle / implementation bug                               | **POODLE (2014)** — SSLv3 padding oracle → decrypt cookie. **Heartbleed (2014)** — CVE-2014-0160 — TLS heartbeat memory leak → private key + user data. **ROBOT (2017)** — RSA padding oracle di TLS server. **Logjam (2015)** — weak DH export grade. **BEAST (2011)** — CBC mode padding oracle. **CRIME (2012)** — compression side-channel. TLS 1.3: hapus semua cipher legacy — tapi implementasi masih bisa salah | Protocol downgrade: force client ke SSLv3 / weak cipher — jika server support legacy. Memory leak: tidak butuh evasi — exploit server dari jarak jauh. Padding oracle: timing analysis — butuh banyak request — tapi bisa otomatis                                                                                 | Defender bergantung pada TLS 1.3 — tapi banyak server masih support TLS 1.2 dengan cipher legacy. Heartbleed: server yang belum patch — vulnerable. Blue team tanpa TLS version monitoring — tidak deteksi downgrade                                                                  |
| **L5** PKI / Certificate (X.509, CA hierarchy)                   | CA compromise / certificate mis-issuance / certificate pinning bypass / OCSP soft-fail | **DigiNotar (2011)** — CA compromise — fake Google/Gmail cert — Iran man-in-the-middle. **CNNIC (2015)** — CA compromise — fake cert. **Certifried (CVE-2022-26923)** — AD CS abuse → DA cert. **PetitPotam (CVE-2021-36942)** — NTLM relay → AD CS → DA cert. **OCSP Soft-Fail** — browser terima cert meskipun OCSP tidak respons — revocation tidak ter-enforce                                                      | CA compromise: supply chain — attacker compromise CA vendor — semua cert yang diterbitkan CA tersebut tidak bisa dipercaya — tidak butuh evasi per cert. Certificate mis-issuance: exploit AD CS template (ESC1-ESC14) — request cert dengan hak tinggi — tidak terdeteksi karena cert legitimate dari CA internal | Defender bergantung pada PKI — tapi CA hierarchy jarang diaudit. Certificate Transparency (CT log) — bisa deteksi mis-issuance — tapi jarang dimonitor. OCSP — sering soft-fail — revocation tidak ter-enforce. Blue team tanpa cert monitoring — tidak deteksi fake cert             |
| **L6** Zero-Knowledge / Advanced (ZKP, FHE, MPC)                 | Trusted setup compromise / side-channel / performance denial                           | **zk-SNARK** — trusted setup ceremony — jika ceremony compromise — semua proof bisa dipalsukan. **FHE (Fully Homomorphic Encryption)** — 1000-10.000x lebih lambat — DoS via computation overload. **MPC** — latency tinggi — timing attack. **ZKP** — proof size kecil tapi generation lambat — resource exhaustion                                                                                                    | Trusted setup: attacker ikut ceremony — inject malicious parameter — semua proof valid tapi salah. Performance: FHE compute → overload server — DoS. Side-channel: timing difference saat compute — leak informasi                                                                                                 | Defender bergantung pada formal proof — tapi proof tidak mencakup side-channel (CPU timing, power, memory). FHE — belum battle-tested skala production — performance overhead = DoS vector. Blue team tanpa performance monitoring — tidak deteksi overload                           |
| **L7** Post-Quantum (NIST 2024: Kyber/Dilithium/FALCON/SPHINCS+) | Harvest-now-decrypt-later / algorithm migration gap / performance overhead             | **Harvest-Now-Decrypt-Later (HNDL)** — attacker rekam semua TLS traffic sekarang (RSA/ECC encrypted) — simpan — decrypt saat quantum computer cukup besar (~2030-2035). **NIST FIPS 203 (Kyber)** — lattice-based — belum ada quantum attack praktis — tapi key/signature size jauh lebih besar (perform overhead). **Classic McEliece** — code-based — key size sangat besar (megabyte) — tidak praktis untuk mobile   | HNDL — tidak perlu evasi — serangan pasif — defender tidak bisa deteksi (rekaman traffic tidak meninggalkan trace). PQC migration — hybrid mode (X25519 + Kyber) — perform overhead — DoS vector jika server tidak siap. Key size besar — storage/network overhead — performance attack                            | Defender mulai migrasi PQC (browser hybrid mode 2025+) — tapi banyak organisasi belum siap. Traffic yang direkam sekarang — defender baru sadar saat quantum aktif — tapi sudah terlambat. Blue team tanpa HNDL awareness — tidak menyadari traffic mereka sudah direkam dan disimpan |

---

## 2. Timeline Kematian — Attacker Timeline

```
1960-1990: L0 (Classical) → Mati segera (frequency analysis)
1990-2000: L1 DES → Mati 1999 (EFF cracker)
2004-2017: L3 MD5 → SHA-1 → Mati bertahap (collision)
2011-2017: L5 PKI → DigiNotar → CNNIC → CA compromise
2014-2017: L4 Protocol → Heartbleed → POODLE → ROBOT → Logjam → Implementasi error
2022-2024: L5 AD CS → Certifried (CVE-2022-26923) → PetitPotam (CVE-2021-36942)
2024-2026: L7 PQC → NIST standardisasi → Hybrid mode roll-out → Migration gap
2030-2035?: L2/L4 RSA/ECC → Shor's algorithm → Mati (jika quantum cukup besar)
```

**Red Team Strategy Timeline:**
- **Sekarang (2024-2026):** Exploit implementasi (padding oracle, memory leak, CA mis-issuance) — algoritma masih kuat — serang implementasi
- **Mendatang (2026-2030):** Harvest-Now-Decrypt-Later — rekam semua traffic RSA/ECC — simpan — decrypt saat quantum aktif — serangan pasif — tidak terdeteksi
- **Post-Quantum (2030+):** Target organisasi yang belum migrasi PQC — semua RSA/ECC traffic terbuka — serangan pasif — full access

---

## 3. CVE Intelligence — Crypto / Protocol / PKI (2024-2026)

| CVE            | CVSS             | Target                                 | Red Team Value                                                                   | Evasion / Bypass                                                                                |
| -------------- | ---------------- | -------------------------------------- | -------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------- |
| CVE-2024-3400  | 10.0             | PAN-OS GlobalProtect                   | Pre-auth RCE — access ke network traffic — intercept TLS / inject malicious cert | RCE → intercept traffic → inject fake cert / downgrade TLS                                      |
| CVE-2024-21410 | 9.8              | Exchange NTLM Relay                    | Relay → AD CS → fake cert → domain admin                                         | Relay → cert mis-issuance → DA — tidak terdeteksi oleh cert monitoring jika CA internal         |
| CVE-2023-4911  | 7.8              | glibc (Looney Tunables)                | Local root → access ke semua process → dump TLS private keys dari memory         | Kernel root → memory read → key extraction — EDR tidak bisa cegah jika kernel sudah compromised |
| CVE-2022-26923 | 8.1              | AD CS (Certifried)                     | AD CS template abuse → DA certificate → persistent auth                          | Cert mis-issuance — legitimate CA — tidak terdeteksi oleh CT log jika CA internal               |
| CVE-2021-36942 | 7.8              | MS-EFSRPC (PetitPotam)                 | NTLM relay → AD CS → cert mis-issuance → DA                                      | Relay — MitM — tidak perlu creds — relay berhasil → cert — persistent                           |
| CVE-2014-0160  | 7.5 (historical) | Heartbleed — TLS heartbeat memory leak | Memory leak → private key + user data — exploit server jarak jauh                | Tidak perlu evasi — exploit server dari jarak jauh — memory leak automatic                      |

---

## 4. Red Team Playbook — Crypto Attack Scenarios

### Scenario A: TLS Downgrade + Memory Dump (Classic + L4)
1. **Initial Access:** Phishing → User click → Shellcode (Ring 3)
2. **Persistence:** WMI Event Sub → Hidden
3. **PrivEsc:** BYOVD → Kernel (Ring 0) → PPL bypass → LSASS dump → TLS private key dari memory server (jika target = server admin)
4. **Exfil:** Intercept TLS traffic (jika server compromised — inject root CA) → Decrypt traffic → Extract sensitive data
5. **Evasion:** Direct syscall → AMSI/ETW bypass → Memory-only payload → Cleanup otomatis

### Scenario B: AD CS Abuse → Domain Admin → Full Access (L5 + PKI)
1. **Recon:** BloodHound → AD CS server → ESC1 template (Any purpose + Enroll — No approval)
2. **Initial Access:** Valid domain user (phishing / brute force / credential stuffing)
3. **Certificate Request:** Request cert dengan ESC1 → Get DA-level certificate (10 tahun validity)
4. **Persistence:** Certificate-based auth — Golden Ticket alternatif — Tidak perlu password — Tidak terdeteksi oleh password rotation
5. **Lateral:** Cert auth → Semua service — Full domain dominance — Persistent (cert tidak expire selama 10 tahun)
6. **Exfil:** HTTPS dengan cert auth — Blend dengan admin traffic — Tidak terdeteksi

### Scenario C: Harvest-Now-Decrypt-Later (L2 + L7 — Quantum Threat)
1. **Recon:** Network mapping — Identify TLS servers (bank, government, critical infra)
2. **Interception:** Passive network tap / Mirror port — Rekam semua TLS handshake + encrypted traffic — No injection — No interaction — Fully passive
3. **Storage:** Encrypted storage — Chunked — Compressed — Simpan di distributed storage — Tidak meninggalkan trace
4. **Wait:** 5-10 tahun — Quantum computer cukup besar (2030-2035) — Shor's algorithm → Decrypt RSA/ECC private keys → Decrypt semua traffic
5. **Exfil:** Decrypt data — Extract crown jewel — Full access — Defender baru sadar saat data sudah terbuka — Tapi sudah terlambat
6. **Evasion:** Tidak perlu — Serangan pasif — Tidak meninggalkan trace — Defender tidak bisa deteksi rekaman traffic

---

## 5. References

- NIST Post-Quantum Cryptography — https://csrc.nist.gov/projects/post-quantum-cryptography
- CRYSTALS-Kyber (FIPS 203) — https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.203.pdf
- CRYSTALS-Dilithium (FIPS 204) — https://nvlpubs.nist.gov/nistpubs/FIPS/NIST.FIPS.204.pdf
- Heartbleed — CVE-2014-0160 — https://heartbleed.com/
- DigiNotar — https://en.wikipedia.org/wiki/DigiNotar
- Certifried — CVE-2022-26923 — https://posts.specterops.io/certified-pre-owned-d959a9d37ad5
- PetitPotam — CVE-2021-36942 — https://github.com/dirkjanm/krbrelayx
- TLS 1.3 — https://tools.ietf.org/html/rfc8446
- WireGuard — https://www.wireguard.com/
- Signal Protocol — https://signal.org/docs/
---

audited
---
