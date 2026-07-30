---
title: Game Theory in Security — Strategic Decision Making for Attack & Defense
tags:
- game-theory
- attacker-defender
- security-economics
- strategic
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> [!abstract] Ringkasan & Hubungan ke Vault
> Game theory memberikan framework matematis untuk **strategic interaction antara attacker dan defender**. Catatan ini melengkapi [[purple-team-osi-killchain]] dengan reasoning: "given what Blue will do, what should Red do (and vice versa)?".
>
> **Domain:** Cyber Security / Strategic
> **Tags:** #game-theory #attacker-defender #security-economics #nash-equilibrium

## 1. Game Types in Security

| Game Type | Players | Description | Security Example |
|-----------|---------|-------------|-----------------|
| **Zero-sum** | 2 | One wins, one loses | Attacker compromises system → Blue failed |
| **Non-zero-sum** | 2+ | Both can win/lose | Bug bounty: researcher finds bug, company patches → both win |
| **Stackelberg** | Leader-follower | Defender commits first (show defenses), attacker follows | Airport security: randomized patrols |
| **Bayesian** | 2 | One player has private info | Insider threat: defender doesn't know who is malicious |
| **Repeated** | 2+ | Multiple rounds | APT campaign: attack → defend → adapt → repeat |

### 1.1 Defender's Dilemma

```
                 Attacker
             Attack    Stay
Defender  ┌────────────────
Defend    │   -5, -5    -10, 0
Not Defend│    0, 10       0, 0
           └────────────────

If Defender defends + Attacker attacks = both lose (-5 each)
If Defender not defend + Attacker attacks = Attacker wins (10)
If Defender defends + Attacker stays = Defender loses resources (-10)

Nash Equilibrium: Defender randomized (mixed strategy)
```

---

### 📚 Referensi
1. "The Mathematics of Crime" — M. D'Orsogna
2. "Game Theory for Security" — Tambe, Yadav
3. CySecGame: [https://github.com/Limmen/cysecgame](https://github.com/Limmen/cysecgame)