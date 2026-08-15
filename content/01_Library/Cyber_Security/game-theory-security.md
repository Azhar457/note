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
---

audited
---
