---
title: SRE Practices And SLO
tags: [security, sre, reliability]
aliases: [sre-practices-and-slo]
---
# SRE Practices and SLO

Site Reliability Engineering (SRE) menggabungkan operasi sistem dengan prinsip rekayasa perangkat lunak — otomatisasi, monitoring, dan pengukuran kualitas layanan. SLO (Service Level Objective) adalah target kuantitatif: misalnya latensi p95 < 200ms, availability 99.9%, error rate < 0.1%.

## Konsep Inti: SLI → SLO → SLA

1. **SLI (Service Level Indicator)** — metrik yang diukur: availability (uptime), latency, throughput, error rate, durability.
2. **SLO (Service Level Objective)** — target: `availability = 99.9% per bulan`, `latency p95 < 200ms`.
3. **SLA (Service Level Agreement)** — kontrak eksternal dengan konsekuensi (refund, penalty) — biasanya lebih longgar dari SLO internal.

```
Contoh SLI: jumlah request sukses / total request (per 5 menit)
SLO: 99.9% sukses per 30 hari
SLA: 99.5% (kontrak pelanggan)
```

## Error Budget

Error budget = 100% - SLO. Jika SLO 99.9% → budget kegagalan 0.1% per bulan (≈43 menit downtime).
- Selama budget masih ada → tim boleh rilis fitur baru (velocity).
- Jika budget habis (downtime berlebih) → freeze rilis, fokus reliability.
- Perhitungan: `error_budget_remaining = (1 - SLI_actual) * period - SLO * period`

### Contoh Angka

| SLO | Downtime diizinkan/bulan | Error budget |
|-----|--------------------------|--------------|
| 99% | 7.2 jam | 1% |
| 99.5% | 3.6 jam | 0.5% |
| 99.9% | 43 menit | 0.1% |
| 99.99% | 4.3 menit | 0.01% |

## SRE vs DevOps

| DevOps | SRE |
|--------|-----|
| Budaya kolaborasi dev-ops | Peran spesifik (sering engineer background software) |
| Prinsip-prinsip | Praktik + metrik konkret (SLO, error budget) |
| Tooling: CI/CD | Tooling: observability, capacity |
| Semua orang | Tim khusus SRE dengan on-call |

## Toil & Automation

Toil = pekerjaan manual, repetitif, tanpa nilai jangka panjang (restart manual, ticket manual, debug manual).
Target: < 50% waktu SRE untuk toil.
Strategi: otomatisasi (runbook automation, self-healing, alerting yang actionable), delegasi (buang/migrasi), dokumentasi runbook → tooling.

## Praktik Utama

1. **Monitoring & Alerting** — alert harus actionable (bukan halaman kosong); gunakan SLI-based alerting, bukan threshold statis.
2. **Incident Management** — severity, on-call rotation, communication channel (status page), blameless postmortem.
3. **Postmortem** — analisis akar masalah (5 Whys), action items dengan owner, tanpa blame.
4. **Capacity Planning** — prediksi pertumbuhan traffic; load test; scaling plan.
5. **Change Management** — progressive delivery: canary, blue-green, feature flag; otomasi rollback.
6. **Chaos Engineering** — uji kegagalan sengaja (Chaos Monkey, Gremlin, Litmus) untuk verifikasi resilience.
7. **Security** — SRE juga jaga: patching, vulnerability scanning, secrets management, incident response untuk security events.

## Monitoring Stack (Contoh)

- Metrics: Prometheus + Grafana (SLI dashboard).
- Logs: Loki/ELK — aggregation + query.
- Tracing: Jaeger/Tempo — distributed tracing.
- Alerting: Alertmanager, on-call (PagerDuty, Opsgenie).
- Synthetic: Blackbox exporter, Playwright E2E.

## SLO dalam Keamanan

- **Time to patch critical vuln**: SLO 48 jam untuk CISA KEV.
- **Time to detect (TTD)**: < 1 jam untuk critical alerts.
- **Time to respond (TTR)**: < 4 jam.
- **Backup restore testing**: minimal 1x/bulan (RTO teruji).
- **Availability sebagai control**: DoS resilience = availability SLO.

## Red Team Angle

Serangan sering memicu penurunan SLI (DDoS → latency/error spike; data breach → trust turun, churn). SRE metrics membantu deteksi: anomaly latency = kemungkinan serangan. Sebaliknya, penyerang bisa memakai error budget untuk timing: serang saat tim sedang sibuk rilis (budget habis → freeze = opportunity? Atau sebaliknya).

## Checklist Implementasi

- [ ] SLI terukur untuk semua service critical?
- [ ] SLO realistis + error budget dikelola?
- [ ] Alert actionable, on-call rotation jelas?
- [ ] Postmortem berjalan tanpa blame?
- [ ] Automasi mengurangi toil < 50%?
- [ ] Capacity plan ter-update tiap kuartal?

## Koneksi ke Vault

- [[sre-practices-and-slo]] — hub ke incident management di incidents/.
- 02_SOPs/vault-routine — pemeliharaan rutin.
- [[defense-in-depth-strategy]] — availability layer.



## Studi Kasus: Error Budget dalam Praktik

**Scenario: layanan checkout e-commerce**
- SLO: availability 99.95% (≈22 menit downtime/bulan).
- Bulan ini sudah 15 menit downtime (release bug) → sisa budget 7 menit.
- Tim rilis fitur baru → tapi harus lewat canary + feature flag, rollback otomatis.
- Jika budget habis: freeze rilis sampai SLI pulih; fokus root cause.

**Scenario: DDoS serangan**
- SLI error rate spike 30% selama 3 jam → budget habis bulan itu.
- Postmortem: tambah DDoS protection (Cloudflare/edge), rate limit, auto-scaling.
- Action item: load test dengan traffic profile DDoS.

## Alerting Berbasis SLI (Bukan Threshold Statis)

Buruk: `alert if CPU > 90%` (banyak false positive, tidak actionable).
Baik: `alert if error_rate_5m > 0.5% selama 10 menit` (berbasis SLI).
Lebih baik: multiwindow, multi-burn-rate alerting (Google SRE workbook): alert saat error budget burn rate > 14.4x dalam 1 jam atau 6x dalam 6 jam.

## On-Call Best Practice

1. Rotation: 1 minggu on-call, 4-6 minggu off (jangan burnout).
2. Escalation path: primary → secondary → incident commander.
3. Playbook untuk alert umum (runbook) — jangan alert tanpa runbook.
4. Post-incident review: 48 jam setelah incident.
5. Metrics on-call: MTTD, MTTR, alert volume, false positive rate.

## Chaos Engineering Prinsip

- Mulai dari production shadow / staging: matikan instance, blokir dependency, inject latency.
- Tools: Chaos Monkey (Netflix), Gremlin, Chaos Mesh, Litmus (K8s).
- Jangan chaos tanpa observability penuh + rollback plan.
- Chaos experiment = hipotesis: "jika DB down, cache masih serve" → verifikasi.

---

  audited
---