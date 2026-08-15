---
title: Defense In Depth Strategy
tags: [security, defense, architecture]
aliases: [defense-in-depth-strategy]
---
# Defense In Depth Strategy

Defense-in-depth berarti menggunakan beberapa lapis pertahanan yang saling melengkapi — jika satu lapis gagal, lapis lain tetap menangkap ancaman. Model klasik: perimeter (firewall, WAF) → endpoint (EDR, AV) → aplikasi (input validation, auth) → data (enkripsi, ACL) → monitoring (SIEM, audit log).

## Model Lapisan

```
┌─────────────────────────────────────────┐
│ 1. Policy & Governance (cara kerja)      │
│ 2. Physical (akses fisik, CCTV, badge)   │
│ 3. Network (firewall, IDS/IPS, segmentasi)│
│ 4. Perimeter (WAF, DDoS protection)      │
│ 5. Application (auth, input validation)  │
│ 6. Endpoint (EDR, AV, hardening)         │
│ 7. Data (encryption, DLP, backup)        │
│ 8. Monitoring (SIEM, audit, hunting)     │
└─────────────────────────────────────────┘
```

## Prinsip Kunci

1. **Layered** — jangan percaya satu kontrol: deteksi + prevent + respond di tiap lapis.
2. **Least privilege** — akun/service hanya punya akses minimum yang dibutuhkan.
3. **Default deny** — tutup semua kecuali yang eksplisit diizinkan.
4. **Redundancy** — backup offline, failover, disaster recovery teruji.
5. **Detectability** — setiap lapis harus bisa mendeteksi kegagalan lapis di bawahnya.
6. **Zero Trust** — never trust, always verify: setiap request diautentikasi, device diteliti (device posture), akses per-session bukan per-network.

## Implementasi Praktis

### Network Segmentation
- VLAN terpisah: DMZ, internal, database, IoT, guest.
- Micro-segmentation (NSX, Cilium) untuk workload cloud.
- Egress filtering: hanya port/domain yang dibutuhkan keluar.
- Jump host / bastion untuk admin.

### Endpoint
- EDR (CrowdStrike, Defender, SentinelOne) + AV baseline.
- Hardening: CIS benchmarks, LUKS/BitLocker, AppLocker/allowlisting.
- Patch management: otomatis, SLA per severity.

### Aplikasi & Data
- Input validation server-side, parameterized queries, WAF di depan.
- AuthN/AuthZ kuat: MFA wajib, session management aman, RBAC.
- Enkripsi: data at rest (AES-256), in transit (TLS 1.2+).
- DLP untuk data sensitif; backup 3-2-1 (3 copies, 2 media, 1 offsite) + restore testing rutin.

### Monitoring & Response
- SIEM: korelasi log semua lapis; rule + anomaly.
- Incident response plan: playbook per scenario (ransomware, breach, DoS).
- Threat hunting: hipotesis berbasis MITRE ATT&CK.
- Tabletop exercise: uji plan setahun 2x.

## Kasus: Mengapa Layered Penting
- WAF bypass → aplikasi masih punya input validation → payload gagal.
- Phishing → MFA menghalangi credential abuse → EDR menangkap jika ada payload.
- Zero-day browser → sandbox + EDR behavioral detection → isolation.
- Insider threat → least privilege + DLP + audit log → exposure terbatas.

## Metrik Keberhasilan
- Time to detect (TTD) & time to respond (TTR) menurun.
- % coverage: aset dengan EDR, backup teruji, MFA aktif.
- Red team exercise: berapa lapis yang berhasil ditembus? (tujuan: bukan 0 tembus, tapi deteksi di lapis 2-3).



## Zero Trust Architecture Detail

Model NIST SP 800-207: tiga pilar utama.
1. **Identity** — setiap user/device punya identitas kuat; MFA, cert-based, device enrollment (MDM policy compliance).
2. **Device** — postur device diverifikasi sebelum akses (OS version, EDR aktif, disk encrypted).
3. **Network** — tidak ada "trusted internal network": micro-segmentation, per-connection authorization.

Praktik:
- BeyondCorp-style: akses aplikasi via policy engine (Auth0/Okta + device trust), tanpa VPN.
- Service mesh (Istio/Linkerd) untuk workload-to-workload auth (mTLS).
- API gateway sebagai policy enforcement point untuk service.
- Continuous verification: session re-auth saat risk naik (impossible travel, device change).

## Red Team vs Defense-in-Depth

Dari sudut penyerang, defense-in-depth berarti harus "menang di semua lapis":
1. Phishing → MFA block (identity layer) → tapi cari MFA bypass: session cookie theft, push fatigue, SIM swap.
2. Exploit → EDR detect → tapi cari LOLBins, memory-only, BYOVD untuk menghindari.
3. Lateral → segmentasi → tapi cari piggyback legitimate service (SMB admin shares, WinRM via jump host).
4. Data → DLP/encryption → tapi cari SQL dump via app logic, bukan raw disk.

**Pelajaran:** penyerang mencari "weakest link" — satu lapis lemah = semua bisa ditembus. Defense-in-depth yang baik = setiap lapis punya deteksi, bukan cuma prevent.

## Tabletop Exercise Scenario

**Scenario: Ransomware di domain controller**
- T+0: EDR alert "Credential dumping via lsass"
- T+15: SOC konfirmasi, isolate host
- T+30: IR team aktif; backup restore plan
- T+60: CTO tanya: apakah backup aman? (jawaban: 3-2-1, offline copy)
- T+90: apakah kita harus bayar? (kebijakan: jangan, ada backup)
- Verifikasi setelah: apakah deteksi terjadi di lapis yang benar? apa yang bisa lebih cepat?

**Metrik**: TTD < 1 jam (target), TTR < 4 jam, backup restore RTO < 24 jam.

## Checklist Implementasi Bertahap

1. Inventory aset (jangan lindungi yang tidak diketahui).
2. Prioritaskan: critical business apps + data crown jewels.
3. Quick wins: MFA untuk semua admin, EDR roll-out, patching SLA.
4. Network: segmentasi DMZ + internal; egress control.
5. Monitoring: SIEM + log semua lapis; alert tuning.
6. Continues: red team exercise, threat hunting, policy review.

## Koneksi ke Vault

- [[hierarchy-endpoint-security]] — lapis endpoint detail.
- [[hierarchy-network-security]] — lapis network.
- [[waf-plan]] — lapis perimeter.
- [[sre-practices-and-slo]] — reliability lapisan (availability = defense).
- incident response SOP di 02_SOPs.

---

  audited
---