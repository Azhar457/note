---
title: Security Economics Cost of Breach
tags: [security, economics, risk]
aliases: [security-economics-cost-of-breach]
---
# Security Economics — Cost of Breach

Investasi keamanan bukan biaya — tapi pencegahan risiko. Biaya pelanggaran keamanan (cost of breach) mencakup: deteksi & eskalasi, notifikasi, respons post-breach, kehilangan bisnis, penalti regulasi, dan biaya reputasi. IBM Cost of Data Breach Report 2024 (data 2023) mencatat rata-rata biaya global: **USD 4.45 juta** per pelanggaran (rata-rata 280 hari dari deteksi ke containment — lifecycle breach).

## Komponen Biaya (Cost Components)

| Komponen | Deskripsi | Contoh Angka (Rata-rata) |
|-----------|-----------|---------------------------|
| Deteksi & eskalasi | Forensik, investigasi, triage | USD 1.58 juta |
| Notifikasi | Notifikasi regulator & pelanggan, PR, komunikasi | USD 0.30 juta |
| Respons post-breach | Remediasi, patch, monitoring tambahan | USD 1.38 juta |
| Kehilangan bisnis | Churn, kehilangan pelanggan, penurunan penjualan | USD 1.52 juta |
| Penalti regulasi | GDPR, HIPAA, CCPA, PCI-DSS denda | Variabel (mencapai USD 100 juta+) |

Waktu rata-rata lifecycle breach (time to identify + time to contain): 280 hari; jika < 200 hari, biaya bisa turun USD ~1.12 juta (28%). Artinya: deteksi cepat = penghematan signifikan.

## Faktor Penentu Biaya

1. **Negara/region**: AS paling mahal (USD 5.09 juta); Asia Pasifik lebih rendah tapi naik cepat.
2. **Industri**: kesehatan (healthcare) paling mahal (USD 10.93 juta); keuangan (USD 5.9 juta); energi, teknologi, ritel juga tinggi.
3. **Ukuran pelanggaran**: jumlah data yang dicuri langsung berkorelasi dengan biaya (rata-rata USD 165 per record).
4. **Vektor serangan**: credential compromise & phishing paling umum; ransomware biaya lebih tinggi karena downtime.
5. **Keberadaan AI/automasi**: organisasi dengan AI/ML dalam deteksi (security AI) memiliki biaya lebih rendah (USD 3.84 juta) — penghematan USD 1.8 juta.
6. **Security maturity**: zero-trust, encryption, testing reguler, incident response plan — semua berhubungan dengan biaya lebih rendah.

## Framework Perhitungan (Quantitative Risk)

**ALE (Annual Loss Expectancy)** = Asset Value (AV) × Exposure Factor (EF) × Annual Rate of Occurrence (ARO).
Contoh: database pelanggan (AV USD 10 juta) × exposure 20% × ARO 0.5 (setiap 2 tahun) = ALE USD 1 juta.

**ROI Security**: jika investasi USD 200 ribu mengurangi ARO dari 0.5 → 0.1 (penghematan ALE USD 800 ribu) → ROI positif.

**Cost-benefit**: bandingkan biaya kontrol (firewall, SIEM, pelatihan, audit) vs pengurangan ALE. Jika biaya kontrol > pengurangan ALE → pertimbangkan mitigasi alternatif (transfer risiko via asuransi, atau terima risiko residual).

## Orientasi Regulator (Dampak Finansial Non-Langsung)

- **GDPR (EU)**: denda sampai 4% pendapatan global atau EUR 20 juta — mana yang lebih besar. Bukan hanya biaya, tapi proses investigasi yang panjang (tahun).
- **CCPA/CPRA (California)**: denda statis USD 7.500 per pelanggaran (per record × jumlah record = besar).
- **HIPAA (US, healthcare)**: denda tiered; breach notifikasi wajib dalam 60 hari.
- **PCI-DSS**: denda + biaya forensik + kehilangan acquirer; biaya investigasi bisa USD 50-100 ribu per insiden.
- **Asuransi siber**: premi naik setelah klaim; polis bisa dibatalkan jika kontrol tidak terpenuhi.

## Metrik Keamanan sebagai Metrik Bisnis

1. **MTTD (Mean Time To Detect)** — lebih rendah = biaya lebih rendah; target: < 1 jam untuk critical.
2. **MTTR (Mean Time To Respond)** — target: < 4 jam (critical).
3. **Patching SLA** — % patch critical dalam 48 jam; 72 jam untuk high.
4. **Training completion rate** — % karyawan yang selesai phishing awareness; korelasi dengan penurunan phishing click rate.
5. **Penetration test result** — jumlah critical/high finding; trend penurunan setiap kuartal.
6. **Incident rate** — jumlah insiden per bulan; trend penurunan.

Metrik ini harus dipresentasikan ke manajemen sebagai bahasa bisnis (USD, risiko, ROI), bukan bahasa teknis (CVE, rules, logs).

## Studi Kasus: Ransomware dan Ekonomi

Ransomware LockBit 3.0: biaya rata-rata (termasuk ransom, downtime, remediasi, kehilangan bisnis) bisa mencapai USD 4.4 juta (IBM). Pembayaran ransom tidak menjamin data kembali (30-40% tidak pulih penuh). Investasi dalam backup (3-2-1), segmentasi jaringan, dan deteksi endpoint lebih murah daripada membayar ransom + downtime.

## Checklist Investasi Keamanan

- [ ] Aset kritis di-identifikasi (crown jewels)?
- [ ] ALE per aset terhitung?
- [ ] Kontrol saat ini (firewall, SIEM, EDR, backup, training) terukur efektivitas?
- [ ] ROI setiap kontrol terhitung (pengurangan ALE vs biaya kontrol)?
- [ ] Metrik keamanan dipresentasikan dalam bahasa bisnis?
- [ ] Asuransi siber aktif dan sesuai risiko?
- [ ] Budget keamanan dialokasikan berdasarkan prioritas risiko (bukan "sama rata")?



## Mitigasi Biaya: Prioritas Investasi Terbaik (Riset IBM)

1. **Security AI/automasi deteksi** — penghematan terbesar (USD 1.8 juta).
2. **Zero Trust architecture** — penghematan signifikan (USD 1.0 juta+).
3. **Incident Response plan + testing** — cut time-to-contain (percepat break-even).
4. **Enkripsi penuh** (data at rest + transit) — kurangi komponen kehilangan bisnis.
5. **Backup & recovery teruji** — ransomware recovery lebih cepat & murah dari ransom.
6. **Training karyawan (human error)** — kurangi vektor masuk phishing/credential.

## Presentasi ke Manajemen (Template)

```text
Situasi: rata-rata biaya breach USD 4.45 juta (IBM 2024), sektor X = USD Y.
Risiko tahunan (ALE) kami: USD N juta (perhitungan lampiran).
Investasi yang diusulkan: USD M (EDR, MFA, training, SIEM) dalam 12 bulan.
Ekspektasi pengurangan ALE: 40-60% (karena faktor A, B) → break-even < 2 tahun.
Risiko jika tidak invest: terkena insiden dalam 2 tahun (prob. berdasarkan industri) = biaya USD N.
```
Gunakan angka konservatif; jangan janjikan "zero risk".

## Metrik Operasional vs Ekonomi (Konteks Vault)

- [[sre-practices-and-slo]] — availability = biaya downtime (setiap 0.1% downtime punya nilai bisnis).
- [[threat-modeling-stride-dread]] — scoring ancaman untuk kalkulasi ALE per asset.
- 02_SOPs — incident response plan mengurangi cost of breach (containment cepat).
- Kerangka ini dipakai untuk meyakinkan stakeholder investasi keamanan di organisasi.

---

  audited
---