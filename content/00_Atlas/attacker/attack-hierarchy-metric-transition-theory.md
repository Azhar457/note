---
title: Attack Perspective — Metric & Transition Theory (Red Team Gaming)
tags:
- attack
- red-team
- metric
- transition
- game-theory
- deception
- signal-detection
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# Metric & Transition Theory — Perspektif Penyerang (Game Theory)

> Security metric = signal detection theory. Red team = adversary dalam game theory pemain yang mencoba meminimalkan signal sambil memaksimalkan impact. Setiap metric punya false positive/negative → red team eksploitasi gap.

## 1. Attack Surface Metric & Detection

| Metric Type | Defender Use | Red Team Bypass | Game Theory | Signal Theory |
|-------------|-------------|-----------------|-------------|----------------|
| **Detection Rate (TPR)** | True Positive Rate → catch attack | Live below threshold → false negative | Minimize signal-to-noise → blend | Signal < noise → no detect |
| **False Positive Rate (FPR)** | Alert fatigue → tune down sensitivity | Exploit tuned-down → low sensitivity → miss | Defender false-positive averse → attacker exploit | Defender trade recall for precision |
| **Mean Time to Detect (MTTD)** | Time from attack → detect | Slow attack → spread TTP across time → MTTD long | Delay game → attacker = time advantage | Time-based detection → gap |
| **Mean Time to Respond (MTTR)** | Time from detect → respond | Fast impact → outpace response | Speed game → attacker beat response | Response delay → impact done |
| **Coverage Gap** | Detection rule coverage → MITRE % | Target sub-technique with no rule → gap | Coverage ≠ detection → gap = attacker surface | Uncovered = signal absent |
| **Deception Rate** | Honeypot/deception → catch attacker | Honeypot identification → avoid → real target | Deception game → identify then avoid | Honeypot = signature → identifiable |

## 2. Game Theory Security (Red Team Strategy)

| Game Type | Defender Strategy | Red Team Best Response | Equilibrium |
|-----------|-------------------|----------------------|-------------|
| **Inspection Game** | Random audit (audit cost vs risk) | Audit probability → attack if p(audit) < threshold | Mixed strategy → randomized |
| **Signaling Game** | Signal (alert) → invest in detection | Mimic legitimate signal → no alert | Perfect Bayesian = signal indistinguishable |
| **Resource Allocation Game** | Allocate defense budget → highest risk | Find lowest coverage area → exploit | Nash equilibrium = balanced coverage (rare) |
| **Deception Game** | Deploy honeypot | Probe → identify honeypot → avoid | Sequential → identify → avoid |
| **Timing Game** | Detection window (T+0 → T+N) | Execute before T+N → win | Speed = attacker advantage |

## 3. Detection Evasion (Signal Detection Theory)

```
Defender Goal: Maximize True Positive (catch attack) → minimize False Positive (alert fatigue)
 ↓
Red Team Strategy: Minimize Signal → blend with noise
 ├── Signal: C2 beacon, lateral scan, exfil → any anomaly
 ├── Noise: Legitimate traffic (business activity, maintenance)
 └→ Objective: signal/noise ratio → below detection threshold
 ↓
Techniques:
 ├── Traffic shaping: jitter, cap, business hours → blend
 ├── Volume: low bandwidth → below threshold
 ├── Protocol: HTTPS, DNS, cloud API → mimic legit
 ├── TTP: LOLBin, legit tool → no signature match
 └→ Timing: slow operation → outside correlation window
 ↓
Result: Signal below noise → false negative → no alert → undetected
```

## 4. Deception Identification (Honeypot Avoidance)

| Honeypot Type | Identification | Red Team Avoidance |
|---------------|---------------|---------------------|
| **Fake service (.fake HTTP)** | Port scan → unusual port open, no banner → suspicious | Skip → target real service |
| **Fake credential (honeytoken)** | Credential looks out-of-place (format, age, access) | Skip → use real credential |
| **Fake file (canary)** | File name too perfect (password.xlsx on desktop) | Skip → avoid unrealistic file |
| **Fake user** | Account never login → no activity → suspicious | Skip → target active user |
| **Fake share** | Share name unusual → too exposed | Skip → avoid |
| **Canary token (DNS)** | Token trigger → DNS callback → detect | Avoid → no DNS resolve of suspicious domain |

## 5. Referensi
- Signal Detection Theory — https://en.wikipedia.org/wiki/Detection_theory
- MITRE Engage (Deception Framework) — https://engage.mitre.org/
- Nash Equilibrium (Security) — https://en.wikipedia.org/wiki/Nash_equilibrium
---

audited
---
