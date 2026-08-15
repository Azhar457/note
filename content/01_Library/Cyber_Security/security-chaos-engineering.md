---
title: Security Chaos Engineering — Resilience Testing & Antifragile Systems
tags:
  - chaos-engineering
  - resilience
  - antifragile
  - security-testing
  - sre
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Security Chaos Engineering = **sengaja inject failure** untuk menguji resilience sistem keamanan. Berbeda dari pentest yang fokus exploit, chaos engineering fokus: "when something breaks, does our security hold?" Melengkapi [[purple-team-osi-killchain]] dengan dimensi resilience testing.
>
> **Domain:** DevOps / Security Engineering
> **Tags:** #chaos-engineering #resilience #antifragile #security-testing #sre

## 1. Ringkasan Eksekutif
Security Chaos Engineering (SCE) memperkenalkan eksperimen kegagalan terkontrol ke dalam infrastruktur keamanan untuk memvalidasi kemampuan deteksi, respons, dan mitigasi otomatis. Dengan merancang skenario kegagalan (mis. WAF down, TLS cert expiry) dan mengukur metrik SLA keamanan, tim dapat membangun sistem yang **antifragile** – tidak hanya tahan, tetapi belajar dari kegagalan.

## 2. Threat Model / Konteks
| Aktor | Vektor | Dampak Potensial |
|-------|--------|------------------|
| Red Team | Membuat layanan keamanan tidak tersedia (WAF, IDS) | Bypass perimeter, eksfiltrasi data |
| Insider | Menonaktifkan log shipping | Hilangnya visibilitas, penyembunyian aksi |
| Supplier Failure | Expired TLS cert | Man‑in‑the‑middle, penurunan kepercayaan |

SCE menguji **confidentiality, integrity, availability** pada lapisan jaringan, aplikasi, dan operasi CI/CD.

## 3. Langkah‑Langkah Teknik Detail
| # | Eksperimen | Injeksi | Expected Behaviour |
|---|------------|--------|--------------------|
| 1 | WAF Failure | `block_waf.sh --duration 30s` | Backend tetap menolak serangan, tidak ada bypass |
| 2 | Cert Expiry | `expire_cert.sh target.com` | Sistem mengembalikan error 526, tidak fallback ke HTTP |
| 3 | Log Drop | `stop_log_ship.sh` | Alert di SIEM, buffer log tidak menyebabkan crash |
| 4 | Auth Down | `kill_service auth` | Cache autentikasi masih berfungsi, degradasi graceful |
| 5 | DNS Fail | `iptables -A OUTPUT -d 8.8.8.8 -j REJECT` | Resolusi cache masih tersedia, tidak ada kebocoran data |
| 6 | Rate Limit Off | `rm /etc/nginx/ratelimit.conf` | Backend menahan DDoS, tidak meluluhkan layanan |

Setiap eksperimen dijalankan melalui **CI pipeline** dengan *gate* yang memverifikasi *steady state* (lihat blok kode di bawah).

```python
STEADY_STATE = {
    "auth_success_rate": 0.99,
    "error_5xx_rate": 0.001,
    "p99_latency_ms": 200,
    "cpu_usage_pct": 0.7,
}

def run_experiment(injection):
    inject_failure(injection)
    measures = {k: measure(k) for k in STEADY_STATE}
    assert all(abs(measures[k] - v) < 0.05 for k, v in STEADY_STATE.items()), "Recovery not within SLA"
```

## 4. Contoh Praktis
```bash
# 1. Simulasi WAF down selama 30 detik pada lingkungan staging
curl -X POST http://ci.example.com/run \
  -d '{"experiment":"waf_failure","duration":30}'

# 2. Verifikasi bahwa serangan SQLi tidak berhasil ketika WAF mati
curl -s -o /dev/null -w "%{http_code}" https://staging.example.com/login?user=admin' OR '1'='1'
# Expected: 403 (blocked) → jika 200, eksperimen gagal
```

## 5. Checklist Mitigasi
- [ ] Definisikan *steady state* KPI keamanan sebelum eksperimen
- [ ] Jalankan eksperimen di *non‑production* terlebih dahulu
- [ ] Otomatisasi rollback jika metrik tidak kembali ke baseline dalam < 2 menit
- [ ] Dokumentasikan semua *fault injection* di ticket tracking
- [ ] Integrasikan alert ke *monitoring stack* (Prometheus + Alertmanager)
- [ ] Review hasil pada *post‑mortem* untuk meningkatkan kontrol kebijakan

## 6. Best Practices & Tooling
SCE memerlukan kombinasi tooling yang dapat di‑orchestrasi secara terprogram. Berikut tabel rekomendasi alat dan peranannya:

| Tool | Kategori | Contoh Penggunaan |
|------|----------|-------------------|
| **Chaos Mesh** | Kubernetes chaos | Simulasi pod kill, network latency, node shutdown |
| **Gremlin** | SaaS chaos platform | Fault injection pada layanan cloud (AWS, GCP) |
| **LitmusChaos** | Open‑source | Experimen pada CI/CD pipeline, integrasi dengan Argo CD |
| **Pumba** | Docker | Mematikan container, menambah latency jaringan |
| **Chaos Monkey for Spring Boot** | Java | Menyuntikkan exception pada bean Spring |
| **Prometheus + Alertmanager** | Observability | Memantau metrik SLA selama dan setelah eksperimen |

Setiap tool harus dikonfigurasi dengan **policy deny‑list** untuk melindungi environment produksi. Dokumentasi runbook harus mencakup langkah rollback manual serta **run‑once** flag untuk eksperimen yang tidak bersifat idempotent.

## 7. Referensi Lintas
- [[purple-team-osi-killchain]]
- [[incident-response-framework]]
- [[sre-practices-and-slo]]

---

### 📚 Referensi
1. "Chaos Engineering" — Rosenthal, Jones
2. Principles of Chaos: https://principlesofchaos.org/
3. Security Chaos Engineering: https://securitychaos.com/
---

audited
---
