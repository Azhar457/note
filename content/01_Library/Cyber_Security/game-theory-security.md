---
title: Game Theory in Security — Strategic Decision Making for Attack & Defense
tags:
  - game-theory
  - attacker-defender
  - security-economics
  - strategic
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Game theory memberikan framework matematis untuk **strategic interaction antara attacker dan defender**. Catatan ini melengkapi [[purple-team-osi-killchain]] dengan reasoning: "given what Blue will do, what should Red do (and vice versa)?".
>
> **Domain:** Cyber Security / Strategic
> **Tags:** #game-theory #attacker-defender #security-economics #nash-equilibrium

## 1. Ringkasan Eksekutif
Dalam keamanan siber, setiap keputusan defender direspons oleh attacker — dan sebaliknya. Game theory memodelkan interaksi ini sebagai **game dengan payoff matrix**, memungkinkan analisis kuantitatif tentang kapan harus bertahan, di mana harus berinvestasi, dan bagaimana menyusun strategi *mixed* yang sulit dieksploitasi lawan. Konsep kunci: **Nash Equilibrium**, **dominant strategy**, dan **Stackelberg game** untuk *resource allocation*.

## 2. Threat Model / Konteks
| Aspek | Deskripsi |
|-------|-----------|
| **Players** | Attacker (Red), Defender (Blue), terkadang regulator/pihak ketiga |
| **Information asymmetry** | Attacker tahu kapan menyerang; defender tidak tahu kapan diserang |
| **Payoff** | Cost of defense vs. cost of breach (dalam USD, reputasi, downtime) |
| **Time horizon** | One-shot vs. repeated game (APT berulang kali) |

Model ini relevan untuk *security budget allocation*, *vulnerability disclosure policy*, dan *deception technology* (honeypot).

## 3. Langkah-Langkah Teknik Detail
### 3.1 Tipe Game
| Game Type | Players | Description | Security Example |
|-----------|---------|-------------|-----------------|
| **Zero-sum** | 2 | Satu menang, satu kalah | Attacker compromise → Blue failed |
| **Non-zero-sum** | 2+ | Kedua pihak bisa menang | Bug bounty: researcher menemukan bug, company patch → both win |
| **Stackelberg** | Leader-follower | Defender commit duluan, attacker ikuti | Airport security: randomized patrols |
| **Bayesian** | 2 | Satu pemain punya private info | Insider threat: defender tak tahu siapa malicious |
| **Repeated** | 2+ | Beberapa ronde | APT campaign: attack → defend → adapt → repeat |

### 3.2 Defender's Dilemma
```
                 Attacker
             Attack    Stay
Defender  ┌────────────────
Defend    │   -5, -5    -10, 0
Not Defend│    0, 10       0, 0
           └────────────────

Nash Equilibrium: Defender randomized (mixed strategy)
```

### 3.3 Aplikasi Nyata Game Theory
| Aplikasi | Model | Contoh |
|----------|-------|--------|
| **Penjadwalan patch** | Stackelberg | Defender mengumumkan jadwal patch, attacker memilih waktu serangan |
| **Deception (honeypot)** | Bayesian | Defender menyembunyikan aset asli di antara decoy — attacker tidak tahu mana yang nyata |
| **Bug bounty** | Non-zero-sum | Researcher dan vendor sama-sama untung dari disclosure yang terkoordinasi |
| **Ransomware negotiation** | Repeated | Keputusan bayar/tidak bayar memengaruhi perilaku attacker di kampanye berikutnya |
| **Insider threat** | Bayesian + repeated | Defender mengalokasikan monitoring berdasarkan prior probability per karyawan |

## 4. Contoh Praktis
```python
# Payoff matrix sederhana: probabilitas mixed strategy defender
import numpy as np

# Baris: defend / not-defend. Kolom: attack / stay
payoff_defender = np.array([[-5, -10], [0, 0]])

# Mixed strategy: p = probabilitas defend
# Defender meminimalkan kerugian ekspektasi
for p in np.linspace(0, 1, 11):
    expected = p * (0.5 * -5 + 0.5 * -10) + (1 - p) * (0.5 * 0 + 0.5 * 0)
    print(f"p={p:.1f} -> E[loss]={expected:.1f}")
```

> [!note] Interpretasi
> Hasil loop menunjukkan bahwa **semakin tinggi probabilitas defend (p), semakin besar kerugian ekspektasi** jika defender memilih defend secara deterministik. Nash Equilibrium tercapai ketika defender *mengacak* strategi (mixed strategy) sehingga attacker tidak bisa memprediksi kapan defense aktif — ini analog dengan randomisasi patrol keamanan fisik.

## 5. Checklist Mitigasi
- [ ] Identifikasi payoff matrix untuk skenario utama (breach vs. defense cost)
- [ ] Gunakan mixed strategy untuk resource allocation (randomized patching schedule)
- [ ] Terapkan Stackelberg thinking: apa yang attacker akan lakukan jika tahu defense kita?
- [ ] Simulasikan repeated game dengan wargame / tabletop exercise
- [ ] Hitung ROI keamanan: Expected Loss Reduction vs. Cost of Controls
- [ ] Integrasikan hasil ke [[threat-modeling-stride-dread]] untuk prioritisasi risiko

## 6. Referensi Lintas
- [[purple-team-osi-killchain]]
- [[security-economics-cost-of-breach]]
- [[threat-modeling-stride-dread]]
- [[defense-in-depth-strategy]]

---

### 📚 Referensi
1. "The Mathematics of Crime" — M. D'Orsogna
2. "Game Theory for Security" — Tambe, Yadav
3. CySecGame: https://github.com/Limmen/cysecgame

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
