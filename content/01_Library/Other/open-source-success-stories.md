---
title: Open Source Success Stories
tags:
- library
- other
created: '2026-07-01'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout

---

# 🚀 SUCCESS STORIES: Dari Open Source ke Karir Sukses
## "Kalau Mereka Bisa, Kenapa Kamu Tidak?"

> **Filosofi:** Setiap project open source yang sukses dimulai dari satu orang yang frustasi dengan tools existing dan memutuskan untuk build sendiri. Yang membedakan "project mati" dan "project sukses" adalah konsistensi, komunitas, dan positioning.

---

## 🏆 Tier 1: Legenda — Dari Project ke Perusahaan Besar

### 1. Wazuh — Santiago Bassett (Spain → Silicon Valley)

```
┌─────────────────────────────────────────────────────────────┐
│  WAZUH — Open Source SIEM/XDR                               │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  FOUNDER: Santiago Bassett                                  │
│  ─────────────────────────────────────────────────────      │
│  • Background: Industrial Engineer (tidak lulus), Spain     │
│  • Kerja: Cybersecurity engineer di perusahaan kecil        │
│  • Pindah: Silicon Valley untuk kerja di AlienVault         │
│  • Pivot: 2015 — lihat OSSEC (open source) punya 20K users  │
│  • Action: "Kenapa tidak buat bisnis di sekitar ini?"       │
│                                                             │
│  JOURNEY:                                                   │
│  2015 — Start Wazuh sendirian, no funding, no MBA           │
│  2016 — First enterprise customer (Fortune 500 company)     │
│  2018 — 20,000 users, mulai hire team                       │
│  2020 — Launch Wazuh Cloud (SaaS)                           │
│  2023 — 100,000+ users, 700+ paying customers               │
│         Customers: Salesforce, NASA, Walgreens, PWC         │
│         Revenue: Cashflow positive, 40% YoY growth          │
│         Team: ~200 employees, mostly Argentina              │
│         Goal: IPO dalam 5-7 tahun (tanpa VC funding!)       │
│                                                             │
│  BUSINESS MODEL:                                            │
│  • Software: 100% FREE (GPL v2)                             │
│  • Revenue: Professional services + Cloud hosting (SaaS)    │
│  • Split: 50% SaaS, 50% services                            │
│                                                             │
│  KEY INSIGHT:                                               │
│  "Our goal to make this free to anyone... I feel like I am  │
│   betraying my users by charging them for a feature."       │
│  — Santiago Bassett                                         │
│                                                             │
│  LESSON: Build trust dengan community dulu, monetize later. │
│          Jangan pernah charge untuk core software.          │
└─────────────────────────────────────────────────────────────┘
```

**Relevansi untuk Anda:**
- Santiago bukan CS degree — Industrial Engineer yang tidak lulus
- Tidak punya funding — bootstrap dari nol
- Tidak punya experience bisnis — belajar on the job
- **Tapi:** Punya domain expertise (cybersecurity), lihat opportunity, dan execute

---

### 2. Falco — Loris Degioanni (Italy → Sysdig CTO)

```
┌──────────────────────────────────────────────────────────────┐
│  FALCO — eBPF Runtime Security (CNCF Graduate)               │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  FOUNDER: Loris Degioanni                                    │
│  ────────────────────────────────────────────────────────────│
│  • Background: Italian engineer                              │
│  • Previous: CREATOR OF WIRESHARK (1998!)                    │
│  • 2016: Create Falco di Sysdig                              │
│  • 2018: Donate ke CNCF (Cloud Native Computing Foundation)  │
│  • 2024: CNCF Graduate — same level as Kubernetes, Prometheus│
│                                                              │
│  JOURNEY:                                                    │
│  1998 — Create Wireshark (network protocol analyzer)         │
│         → Most popular network tool in the world             │
│         → Di-acquire oleh Riverbed, tapi tetap open source   │
│                                                              │
│  2013 — Found Sysdig (container visibility)                  │
│         → Pivot ke cloud native security                     │
│                                                              │
│  2016 — Create Falco (runtime security with eBPF)            │
│         → "Insane to think about using eBPF for security"    │
│         → Submit patches ke Linux kernel untuk enable eBPF   │
│         → Open source dari hari pertama                      │
│                                                              │
│  2018 — CNCF Sandbox → Incubator → Graduate (2024)           │
│         → 30+ public adopters: Cisco, Shopify, GitLab        │
│         → 400% increase in contributors since incubation     │
│         → 526% increase in downloads                         │
│                                                              │
│  2024 — Sysdig unicorn (valued >$1B)                         │
│         → Falco = core differentiator                        │
│                                                              │
│  KEY INSIGHT:                                                │
│  "The fact that Falco graduated is a testament to how CNCF   │
│   is becoming an important repository of projects that are   │
│   more or less what the community agrees them to be as the   │
│   default step."                                             │
│  — Loris Degioanni                                           │
│                                                              │
│  LESSON: Open source + CNCF = credibility + adoption.        │
│          eBPF = future of security (Anda di jalur yang benar)│
└──────────────────────────────────────────────────────────────┘
```

**Relevansi untuk Anda:**
- Loris create **2 tools legendaris**: Wireshark + Falco
- Pattern: "Build tool yang saya sendiri butuhkan"
- eBPF = teknologi yang sama dengan Aegis (Anda di jalur yang benar!)
- CNCF graduation = validasi industri tertinggi

---

### 3. Leonardo Di Donato — Dari Open Source ke Sysdig

```
┌────────────────────────────────────────────────────────────────┐
│  LEONARDO DI DONATO — kubectl trace → Sysdig → Falco           │
├────────────────────────────────────────────────────────────────┤
│                                                                │
│  BACKGROUND:                                                   │
│  • Kerja di startup (Kubernetes 1.3 era) — startup gagal       │
│  • Move ke InfluxData — kerja dengan eBPF daily                │
│  • Open source: kubectl trace (eBPF tracing untuk K8s)         │
│                                                                │
│  HOW HE GOT HIRED BY SYSDIG:                                   │
│  1. Build kubectl trace (open source, GitHub)                  │
│  2. Sysdig lihat project-nya ("cool things with eBPF")         │
│  3. Sysdig reach out — mau hire untuk commercial product       │
│  4. Leonardo: "Saya cuma mau kerja open source"                │
│  5. Sysdig: "OK, kami punya open source project (Falco)"       │
│  6. Hired sebagai core maintainer Falco + creator kubectl trace│
│                                                                │
│  KEY QUOTE:                                                    │
│  "I was in love with eBPF. And I've always been in love        │
│   with open-source. I just want to do open-source and do       │
│   cutting-edge things with eBPF."                              │
│  — Leonardo Di Donato                                          │
│                                                                │
│  LESSON: Build project yang Anda passionate, publish ke        │
│          GitHub, company akan datang ke Anda (bukan Anda       │
│          apply ke company).                                    │
└────────────────────────────────────────────────────────────────┘
```

**Relevansi untuk Anda:**
- Leonardo = contoh paling mirip dengan posisi Anda sekarang
- Build tool di waktu luang → di-notice oleh company besar → hired
- **Tidak apply kerja — company yang reach out ke dia!**

---

## 🥈 Tier 2: Sukses Besar — Dari Project ke Company/Karir

### 4. Daniel Brandao — Dari Homelab ke T-Mobile

```
┌─────────────────────────────────────────────────────────────┐
│  DANIEL BRANDAO — NetWiz → T-Mobile Engineer                │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  PROJECT: NetWiz                                             │
│  ─────────────────────────────────────────────────────       │
│  • Built di Meta hackathon (2 hari)                          │
│  • Tools: Home lab ThinkCenters + Proxmox                    │
│  • Function: Network change detection + auto-rollback      │
│                                                               │
│  PORTFOLIO:                                                  │
│  • GitHub: Living showcase (bukan sekadar class assignments)│
│  • CI/CD: Build pipeline sendiri untuk personal website      │
│  • Homelab: Infrastructure as code                           │
│                                                               │
│  INTERVIEW T-MOBILE:                                         │
│  • Tidak cuma sebut coursework                               │
│  • Walk through GitHub portfolio secara intentional          │
│  • Highlight: NetWiz, CI/CD pipeline, homelab                │
│  • Result: HIRED                                             │
│                                                               │
│  KEY QUOTE:                                                   │
│  "Post anything that shows your skills in cybersecurity.     │
│   It could be code, it could be documentation."              │
│  — Daniel Brandao                                            │
│                                                               │
│  LESSON: Portfolio > Resume. Homelab > GPA.                │
└─────────────────────────────────────────────────────────────┘
```

---

### 5. Suricata — Victor Julien & OISF

```
┌─────────────────────────────────────────────────────────────┐
│  SURICATA — Open Source IDS/IPS                             │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  FOUNDERS: Victor Julien, Matt Jonkman, Will Metcalf         │
│  ─────────────────────────────────────────────────────       │
│  • 2007: Victor experiment dengan code sendiri               │
│  • 2008: Meet di conference US, share prototype              │
│  • Funding: DHS (Department of Homeland Security) seed      │
│  • Organization: OISF (Open Information Security Foundation) │
│  • License: GPLv2 (anti-corporate acquisition)               │
│                                                               │
│  GROWTH:                                                     │
│  • 15+ years journey                                          │
│  • Adopted by: AWS (network firewall), enterprise worldwide  │
│  • Model: Vendor membership (sustainable funding)            │
│  • Community: Core team + contributors global                │
│                                                               │
│  KEY INSIGHT:                                                 │
│  "We wanted to establish an organization that would make    │
│   Suricata safe from acquisition, which we'd seen happen to  │
│   other open-source projects."                               │
│  — Victor Julien                                             │
│                                                               │
│  LESSON: Foundation/organization = longevity.               │
│          GPLv2 = protection dari corporate takeover.         │
└─────────────────────────────────────────────────────────────┘
```

---

## 🥉 Tier 3: Realistis untuk Anda — Path Mahasiswa

### 6. Path A: "Aegis → Junior Security Engineer"

```
┌─────────────────────────────────────────────────────────────┐
│  SCENARIO A: Aegis v1.0 → Kerja di Startup/Scale-up       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  TIMELINE:                                                   │
│  Semester 6 (Now) — Start Aegis v1.0                         │
│  ├── Build eBPF firewall + WAF                              │
│  ├── Publish ke GitHub (open source)                         │
│  ├── Tulis blog: "Building eBPF Security from Scratch"       │
│  └── Share di Reddit r/homelab, r/netsec, Hacker News      │
│                                                               │
│  Semester 7 — Aegis v1.0 Release                             │
│  ├── 100+ GitHub stars                                      │
│  ├── 10+ users (homelab community)                           │
│  ├── Fix bugs, iterate berdasarkan feedback                │
│  └── Sertifikasi: CompTIA Security+                         │
│                                                               │
│  Semester 8 — Portfolio Polish                               │
│  ├── Aegis v1.1 (FIM, container security)                   │
│  ├── Blog series: 5-10 technical articles                    │
│  ├── Speaking: Local meetup / campus event                 │
│  └── LinkedIn: Share journey, build following               │
│                                                               │
│  Apply Kerja:                                                │
│  ├── Target: Junior Security Engineer / SOC Analyst        │
│  ├── Company: Startup cybersecurity / tech scale-up          │
│  ├── Salary: $40K-60K (Indonesia: Rp 8-15 juta)            │
│  └── Differentiator:                                        │
│      "Saya build security platform sendiri, ini GitHub-nya"  │
│      (bukan: "Saya lulusan IT dengan IPK 3.5")             │
│                                                               │
│  Year 1-2 Kerja:                                             │
│  ├── Kontribusi ke Aegis sambil kerja (weekend)             │
│  ├── Belajar dari senior di company                          │
│  ├── Aegis v1.3 (AI detection)                             │
│  └── Pivot: Senior Security Engineer / Detection Engineer   │
│                                                               │
│  Year 3-5:                                                   │
│  ├── Aegis v2.0 (multi-agent, enterprise)                    │
│  ├── Pilihan A: Stay di company, naik ke Staff/Principal     │
│  ├── Pilihan B: Join company besar (CrowdStrike, etc)       │
│  └── Pilihan C: Startup sendiri (Wazuh-style)               │
└─────────────────────────────────────────────────────────────┘
```

---

### 7. Path B: "Aegis → Hired oleh Company Besar"

```
┌─────────────────────────────────────────────────────────────┐
│  SCENARIO B: Aegis → Di-notice oleh Company → Hired         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  INSPIRASI: Leonardo Di Donato (kubectl trace → Sysdig)     │
│                                                               │
│  TIMELINE:                                                   │
│  Semester 6-7 — Build Aegis, publish blog                    │
│  ├── "How I built eBPF firewall in Rust" → Hacker News front │
│  ├── "WAF dengan 10K req/sec di single core" → trending    │
│  ├── "Purple Team module untuk homelab" → r/netsec hot      │
│  └── GitHub: 500+ stars, 50+ forks                          │
│                                                               │
│  Semester 8 — Di-notice:                                    │
│  ├── Email dari recruiter: "Saw your project, interested?" │
│  ├── DM di Twitter/LinkedIn dari engineer company            │
│  ├── Invitation: "Want to chat about your eBPF work?"       │
│  └── Options:                                                │
│      • CrowdStrike (Falcon team)                             │
│      • Sysdig (Falco team)                                   │
│      • Isovalent (Cilium/eBPF)                               │
│      • Red Hat (kernel team)                                 │
│      • Startup eBPF-focused (new)                            │
│                                                               │
│  Interview:                                                  │
│  • Tidak: "Tell me about your coursework"                    │
│  • Ya: "Walk me through Aegis architecture"                 │
│  • Coding: "How would you extend this to Windows?"          │
│  • Result: HIRED sebagai eBPF Security Engineer             │
│                                                               │
│  Salary: $80K-120K (US) / Rp 20-40 juta (Indonesia remote)  │
│                                                               │
│  REALITY CHECK:                                              │
│  • Butuh: Project yang genuinely useful + technical depth   │
│  • Butuh: Consistent blogging + community engagement         │
│  • Butuh: 6-12 bulan dedicated work                         │
│  • Tidak instant — tapi possible!                           │
└─────────────────────────────────────────────────────────────┘
```

---

### 8. Path C: "Aegis → Startup Sendiri"

```
┌─────────────────────────────────────────────────────────────┐
│  SCENARIO C: Aegis → Wazuh-style Bootstrapped Company       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  INSPIRASI: Santiago Bassett (Wazuh — no VC, IPO goal)      │
│                                                               │
│  TIMELINE:                                                   │
│  Year 0-1 (Now + 12 bulan) — Build + Community              │
│  ├── Aegis v1.0-1.2 (network + endpoint + container)       │
│  ├── 1000+ GitHub stars                                     │
│  ├── 100+ active users (homelab + small business)          │
│  ├── Blog + YouTube channel ("Building Security Tools")    │
│  └── Community: Discord/Slack dengan 500+ members            │
│                                                               │
│  Year 1-2 — Monetization:                                    │
│  ├── Aegis Cloud (SaaS): Managed hosting untuk SMB         │
│  ├── Professional Services: Setup + tuning untuk enterprise  │
│  ├── Support Subscription: Priority support + consulting   │
│  └── Team: 2-3 people (co-founder + engineer)              │
│                                                               │
│  Year 2-3 — Scale:                                           │
│  ├── 50+ paying customers                                   │
│  ├── $100K+ ARR (Annual Recurring Revenue)                  │
│  ├── Team: 10-15 people                                     │
│  └── Funding: Bootstrapped (tidak VC) atau angel round      │
│                                                               │
│  Year 3-5 — Enterprise:                                      │
│  ├── 500+ customers                                         │
│  ├── $1M+ ARR                                               │
│  ├── Team: 50+ people                                       │
│  └── Goal: Series A atau profitable bootstrapped            │
│                                                               │
│  REALITY CHECK:                                              │
│  • 90% open source projects tidak jadi bisnis               │
│  • Butuh: Business sense + technical + persistence           │
│  • Butuh: Network (know people who need your tool)         │
│  • Butuh: 3-5 tahun dedicated work                          │
│  • Reward: Independence + impact + potential wealth         │
└─────────────────────────────────────────────────────────────┘
```

---

## 📊 Perbandingan Path

| Aspek | Path A (Employee) | Path B (Hired by Big Co) | Path C (Startup) |
|-------|-------------------|-------------------------|------------------|
| **Timeline** | 6-12 bulan | 12-18 bulan | 3-5 tahun |
| **Risk** | Low | Medium | High |
| **Reward** | Stable income | High salary + prestige | Uncapped |
| **Control** | Low (boss decides) | Medium (team decides) | High (you decide) |
| **Skill needed** | Technical | Technical + visibility | Technical + business |
| **Aegis role** | Portfolio | Magnet | Product |
| **Probability** | 70% | 20% | 10% |
| **Best for** | Stability | Recognition | Independence |

---

## 🎯 Action Plan: Dari Sekarang

### Minggu Ini (Week 1)

| # | Action | Output |
|---|--------|--------|
| 1 | Buat GitHub repo: `aegis-security` | Repository publik |
| 2 | Tulis README dengan vision | 500+ words |
| 3 | Design logo (simple) | `assets/logo.png` |
| 4 | Setup project structure | Cargo + Go + React |
| 5 | Tulis blog post #1 | "Why I'm building Aegis" |

### Bulan Ini (Month 1)

| # | Action | Output |
|---|--------|--------|
| 1 | eBPF Hello World (TC mode) | Working code |
| 2 | WAF skeleton (Axum) | Reverse proxy works |
| 3 | Manager API (Gin) | Basic endpoints |
| 4 | Dashboard shell (React) | Navigation works |
| 5 | Blog post #2 | "eBPF for Security: A Beginner's Guide" |
| 6 | Share di Reddit/HN | 100+ views |

### Semester Ini (3 bulan)

| # | Action | Output |
|---|--------|--------|
| 1 | Aegis v1.0 MVP | Working product |
| 2 | 5+ blog posts | Content library |
| 3 | 100+ GitHub stars | Social proof |
| 4 | 10+ users (homelab) | Validation |
| 5 | Sertifikasi Security+ | Credential |

---

## 💡 Golden Rules dari Success Stories

| Rule | Contoh | Aplikasi untuk Anda |
|------|--------|---------------------|
| **Build what you need** | Wireshark (Loris butuh network analyzer) | Aegis (Anda butuh homelab defense) |
| **Open source dari hari 1** | Falco, Wazuh | Publish ke GitHub sejak scaffold |
| **Blog about journey** | Daniel Brandao | 1 post/minggu minimum |
| **Community first** | Wazuh 100K users gratis | Discord/Slack untuk users |
| **Don't charge for core** | Wazuh GPL v2 | MIT/Apache license |
| **Monetize services** | Wazuh SaaS + support | Aegis Cloud (v2.0) |
| **Persistence > Perfection** | Suricata 15+ years | Consistent 6-12 bulan |
| **Hire slow, fire fast** | Wazuh Argentina team | Solo dulu, hire saat revenue |

---

## 🚀 Final Motivation

```
Santiago Bassett: "I started by myself with no funding."
Loris Degioanni: "It was sort of insane to think about using eBPF."
Leonardo Di Donato: "I just want to do open-source and cutting-edge things."
Victor Julien: "We wanted to make Suricata safe from acquisition."

BEDANYA: Mereka execute. Anda juga bisa execute.
```

---

*Document Version: 1.0*  
*Last Updated: 2026-06-17*  
*Purpose: Motivation + roadmap dari success stories open source cybersecurity*
---

audited
---
