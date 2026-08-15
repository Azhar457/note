---
title: WAF Plan
tags: [security, waf, planning]
aliases: [waf-plan]
---
# WAF Deployment Plan

Rencana implementasi WAF (Web Application Firewall) end-to-end: dari kebutuhan → pilih solusi → arsitektur → deploy → tuning → pemeliharaan. Melengkapi [[waf-internal-architecture-deepdive]] (internal) dan terkait [[wiod-reverse-proxy-deepdive]] (proxy layer).

## 1. Kebutuhan & Tujuan

Tanyakan dulu (jangan langsung pasang):
- Aset yang dilindungi? (semua web app / hanya critical?)
- Ancaman utama? (SQLi/XSS injection, bot/DDoS, credential stuffing, API abuse?)
- Budget & skill tim? (open source self-host vs cloud managed?)
- Regulatory/compliance? (PCI-DSS mewajibkan WAF untuk e-commerce? — PCI DSS 4.0: WAF sebagai control untuk aplikasi custom)
- Performance budget? (latency tambahan, throughput)

## 2. Pilihan Solusi

| Opsi | Kelebihan | Kekurangan | Cocok |
|------|-----------|-----------|-------|
| **Nginx + ModSecurity + CRS** (self-host) | Free, kontrol penuh, rules transparan | Maintenance, tuning manual, performance tuning | Tim punya skill infra |
| **Coraza** (Go) | Modern, cepat, kompatibel CRS | Ekosistem lebih kecil | Go shop |
| **Cloudflare WAF** | Global edge, managed rules, DDoS, JS challenge, zero-downtime | Data lewat Cloudflare, harga tier, logging terbatas di low tier | Publik internet apps |
| **AWS WAF** (ALB/CloudFront) | Integrasi AWS, managed rules, per-request cost kecil | Rule limits (100/web ACL), no regex lebar? — mendukung, tapi managed | Sudah di AWS |
| **GCP Cloud Armor** | Edge, adaptive protection | Admin complex | GCP |
| **Imperva/F5/Barracuda** | Enterprise features, support | Mahal | Enterprise |

**Rekomendasi umum**: cloud = Cloudflare/AWS WAF (managed, cepat); on-prem/sensitive = Nginx+ModSecurity+CRS (full control). Hybrid: cloud edge + on-prem WAF untuk API internal.

## 3. Arsitektur Deployment

```
Internet → CDN/Edge WAF (Cloudflare) → LB → Nginx+ModSecurity (on-prem WAF)
                                               → App Server (non-proxy langsung)
```
Mode: **transparent/reverse proxy** (standar) vs **bridge** (L2, legacy) — pakai reverse proxy.

Penting:
- **Polling**: WAF inline di jalur request (bukan mirror) untuk block.
- **High availability**: 2+ instance; LB di depan.
- **Fail-open vs fail-closed**: jika WAF down — fail-open (availability) dengan alert, atau fail-closed (security) — keputusan bisnis; rekomendasi: fail-open + monitor + SLA.
- **Separation**: WAF di DMZ; app di internal; DB tersembunyi.

## 4. Konfigurasi Awal & Ruleset

1. **CRS**: paranoia level 1 dulu (FP rendah) dalam **Detection mode** (log only) — 1-2 minggu baseline.
2. **Whitelist/exception**: endpoint bermasalah (file upload besar, API JSON) — per-endpoint tuning, bukan disable global.
3. **Anomaly threshold**: default 5; sesuaikan setelah data (jangan langsung 100).
4. **Custom rules**: kebutuhan spesifik (path sensitif, header aneh, geo block — hati-hati geo block: false positive user sah).
5. **Rate limiting**: login, API, search — per IP + session; grace for good bots (SEO).
6. **Bot management** (Cloudflare): challenge untuk suspicious (browser integrity score), rate untuk API.

## 5. Go-Live & Rollout

| Fase | Mode | Durasi | Kriteria lanjut |
|------|------|--------|-----------------|
| Fase 1 | Detection (log only) | 1-2 minggu | FP rate < 1%, no critical app broken |
| Fase 2 | Detection + alert | 1 minggu | Alert actionable, tidak noisy |
| Fase 3 | Blocking untuk high confidence | 1 minggu | False positive block = 0-1 |
| Fase 4 | Full enforcement + rate limit | terus | Monitoring harian |

- Rollout per-domain dulu (pilot), lalu semua.
- Komunikasi ke tim dev: contoh request yang diblokir (log) → mereka paham.

## 6. Tuning & Pemeliharaan

- **Review log mingguan**: blocked requests, anomaly distribution, FP.
- **Update CRS bulanan** (release) + custom rules review.
- **Attack trend monitoring**: spike blocking = serangan atau FP wave — telusuri.
- **Performance**: latensi p95 sebelum/sesudah WAF (< 50ms tambahan wajar); throughput (connections/s); resource usage modsecurity (SecAuditEngine jangan di RequestBody jika besar).
- **Bypass testing berkala** (tiap kuartal): tim merah mencoba payload bypass (lihat waf internal note: encoding, smuggling) — dokumentasikan hasilnya.
- **Dashboards**: block rate, top rules triggered, top attack sources (IP/geo/ASN), FP report.

## 7. Integrasi dengan Proses Lain

- **CI/CD**: perubahan custom rules via git (policy as code); review PR; test payload suite (regression — payload yang harus diblokir).
- **SIEM**: kirim log WAF (audit) ke SIEM — correlation dengan app logs.
- **Incident response**: playbook "WAF alert → verifikasi → mitigo" (block IP/ASN, rate limit, update rule).
- **Compliance**: dokumentasi config + report (PCI DSS 4.0: WAF config review tahunan + penetration test).

## 8. KPI WAF

| Metrik | Target |
|--------|--------|
| Block rate (traffic) | 0.1-2% (wajar) |
| False positive rate | < 0.1% |
| TTD (deteksi serangan) | < 15 menit (alert) |
| Coverage | 100% internet-facing web apps |
| Downtime WAF | < 0.1% (HA) |
| Bypass success (red team test) | 0 (atau documented & fixed) |

## 9. Checklist Deployment

- [ ] Kebutuhan & aset teridentifikasi
- [ ] Solusi dipilih (cloud/on-prem/hybrid) + HA
- [ ] CRS paranoia level + detection mode baseline
- [ ] Exception per endpoint (bukan global disable)
- [ ] Rate limiting & bot management
- [ ] Rollout fase (detection → blocking) dengan kriteria
- [ ] Monitoring: log SIEM + dashboard + alert
- [ ] Tuning rutin (mingguan) + update CRS bulanan
- [ ] Bypass test kuartalan + remediasi
- [ ] Integrasi PCI/compliance (jika relevan)

---

  audited
---