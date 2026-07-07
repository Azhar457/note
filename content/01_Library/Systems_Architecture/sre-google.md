---
title: "Site Reliability Engineering — Google SRE"
tags:
  - library
  - systems-architecture
aliases:
  - "sre-google"
created: "2026-07-05"
updated: "2026-07-05"
status: active
---

# ⚙️ Site Reliability Engineering

> Betsy Beyer, Chris Jones, Niall Murphy, Jennifer Petoff (Google) — 2016

**Tesis:** Cara Google menjalankan sistem besar dengan **reliability tinggi** — pendekatan SRE yang jembatani dev + ops. Bukan "kita perlu 99.999%" — tapi _error budget, SLO, toil automation, and blameless culture_.

---

## 📌 Kenapa Penting

- Sistem production = beda planet sama development
- SRE adalah **what DevOps looks like when engineers are in charge of ops**
- Error budget = framework buat balance feature velocity vs stability

## 🎯 Key Takeaways

**1. SRE = Software Engineer + Operations**

- Bukan job title — _approach_: operasional problems solved with software engineering
- Target: <50% waktu buat ops (toil), sisanya buat engineering

**2. Service Level Everything**

- **SLI** (Indicator) — metric actual (latency p99, error rate)
- **SLO** (Objective) — target reasonable (99.9% uptime)
- **SLA** (Agreement) — contract dengan consequences
- Gap between SLI and SLO = _room for improvement_

**3. Error Budget**

- 100% reliability is _the wrong target_ — gak worth the cost
- Error budget = 100% - SLO = jumlah failure yang acceptable
- Kalo error budget abis → feature freeze, fokus ke reliability
- **Trade-off explicit:** bukan "reliability vs velocity" — keduanya diukur bersama

**4. Monitoring**

- 4 golden signals: Latency, Traffic, Errors, Saturation (USE method)
- Alert fatigue = kamu salah bikin alert
- Rules: _alert harus actionable, gak boleh noise_

**5. Incident Response**

- Blameless postmortem — bukan nyari siapa salah, tapi _apa yang bisa diperbaiki_
- Incident Command System — clear roles: IC, operations, comms, planning
- Practice: DiRT (Disaster Recovery Testing) — fire drills for production

**6. Capacity & Automation**

- Demand forecasting + load testing
- Automate toil — repetitive manual work yang gak ada nilai jangka panjang
- **Reliability is a feature** — must be designed in

## 📖 Bab Penting

| Bab   | Judul                          | Mengapa                                   |
| ----- | ------------------------------ | ----------------------------------------- |
| 3     | Embracing Risk                 | Error budget concept — **paling penting** |
| 4     | Service Level Objectives       | SLI, SLO, SLA — bahasa universal          |
| 5     | Eliminating Toil               | Apa itu toil + kenapa harus dihilangkan   |
| 6     | Monitoring Distributed Systems | Golden signals + alerting philosophy      |
| 10-12 | Incident Response + Postmortem | On-call culture, blameless                |
| 13    | Emergency Response             | Testing, playbook, practice               |
| 14    | Managing Critical State        | Configuration + secrets management        |

## ⚠️ Tantangan

- **Google-scale** — beberapa teknik overkill untuk startup/proyek kecil
- Fokus ke servis internal — beberapa hal gak relevan buat produk SaaS
- Buku bisa dibaca per-bab independent — gak perlu urut

## 🔗 Koneksi

- [[ddia-kleppmann]] — _theory_ distributed systems, SRE adalah _practice_
- [[ostep-three-easy-pieces]] — OS reliability fundamentals
- [[systems-design-interview-alex-xu]] — SRE = how you _run_ the systems from interview

## ✅ Checklist

- [ ] Tentukan SLO untuk proyek/produk sendiri (mulai dari 99% dulu)
- [ ] Hitung error budget — berapa downtime yang acceptable per bulan?
- [ ] Audit monitoring: ada alert yang gak actionable? matikan!
- [ ] Blameless postmortem: tulis 1 postmortem untuk insiden terakhir
- [ ] Identifikasi 1 sumber toil + automate it
