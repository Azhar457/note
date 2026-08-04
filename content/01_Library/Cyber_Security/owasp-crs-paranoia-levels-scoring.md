---
title: "OWASP CRS — Paranoia Levels & Anomaly Scoring: PL1-PL4, Threshold, Scoring Mode, Implementation"
tags:
  - cyber-security
  - waf
  - crs
  - anomaly-scoring
  - paranoia-level
  - library
aliases:
  - "CRS Paranoia Levels"
  - "Anomaly Scoring CRS"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Paranoia Level (PL) adalah mekanisme CRS untuk mengatur ketelitian deteksi. PL1 (default) mendeteksi serangan umum dengan false positive rendah. PL4 mendeteksi hampir semua varian serangan dengan risiko false positive tinggi. Anomaly scoring mengakumulasi skor dari setiap rule match dan memblokir ketika threshold terlampaui. Sistem ini penting untuk dipahami karena WAF sudah memiliki mekanisme anomaly scoring di `anomaly.rs`.

**Cross-link:** [[owasp-crs-rule-structure-analysis]] → [[waf-reverse-proxy-deepdive]] → [[waf-internal-architecture-deepdive]] → [[hierarchy-waf-reverse-proxy]]

---

## Daftar Isi
- [[#1. Paranoia Level System]]
- [[#2. PL1 — Default Mode]]
- [[#3. PL2 — Advanced Mode]]
- [[#4. PL3 — High Mode]]
- [[#5. PL4 — Paranoid Mode]]
- [[#6. Anomaly Scoring Mechanism]]
- [[#7. Scoring Modes]]
- [[#8. Implikasi ke WAF]]

---

## 1. Paranoia Level System

CRS membagi aturan ke dalam 4 paranoia level. Setiap PL adalah superset dari PL sebelumnya.

```text
PL4: Semua aturan termasuk encoding/obfuscation varian
  ↑
PL3: Aturan tambahan untuk bypass techniques
  ↑
PL2: Aturan tambahan untuk advanced attack
  ↑
PL1: Aturan dasar untuk serangan umum
```

### Konfigurasi

```apache
# crs-setup.conf
# Default: PL1
SecAction \
  "id:900000,\
  phase:1,\
  nolog,\
  pass,\
  t:none,\
  setvar:'tx.paranoia_level=1'"
```

---

## 2. PL1 — Default Mode

**Cocok untuk:** Production dengan prioritas stabilitas.

| Karakteristik | Nilai |
|---|---|
| False positive | Sangat rendah |
| Coverage | Serangan umum (basic SQLi, XSS, LFI) |
| Anomaly threshold | 5 (inbound) |
| Contoh yang terdeteksi | `' OR 1=1`, `<script>alert(1)</script>`, `../../etc/passwd` |
| Contoh yang Lolos | `SeLeCt * FrOm`, URL encoded, comment injection |

### Contoh Rule PL1

```apache
# PL1: Basic SQLi — keyword-based
SecRule ARGS "@contains OR 1=1" "id:942110, phase:2, t:lowercase, ..."
```

---

## 3. PL2 — Advanced Mode

**Cocok untuk:** Aplikasi yang sudah di-tune, mau deteksi lebih ketat.

| Karakteristik | Nilai |
|---|---|
| FP relatif | Rendah |
| Coverage | SQLi dengan comment, XSS dengan event handler |
| Threshold | 5 (inbound) |
| Tambahan deteksi | Case toggling, basic obfuscation |

### Contoh Rule PL2

```apache
# PL2: SQLi dengan comment injection
SecRule ARGS "@rx (?i)'(?:--|#|/\*)" "id:942120, phase:2, \
  tag:'paranoia-level/2', \
  setvar:'tx.anomaly_score_pl2=+%{tx.critical_anomaly_score}'"
```

---

## 4. PL3 — High Mode

**Cocok untuk:** High-security apps dengan monitoring ketat.

| Karakteristik | Nilai |
|---|---|
| FP | Tinggi — perlu tuning exclusion |
| Coverage | URL encoding, unicode, white-space obfuscation |
| Threshold | 5 (inbound) — lebih mudah ter-trigger |

### Contoh Rule PL3

```apache
# PL3: URL encoded SQLi
SecRule ARGS "@rx %27[^%]*%6F%72" "id:942130, phase:2, \
  tag:'paranoia-level/3', \
  setvar:'tx.anomaly_score_pl3=+%{tx.critical_anomaly_score}'"
```

---

## 5. PL4 — Paranoid Mode

**Cocok untuk:** Pentest / CTF / security research.

| Karakteristik | Nilai |
|---|---|
| FP | Sangat tinggi — hampir semua input mencurigakan |
| Coverage | Semua encoding varian, double encoding, mixed case |
| Threshold | Mungkin perlu dinaikkan ke 10+ |
| Penggunaan | Jangan di production tanpa exclusion rule |

### Contoh Rule PL4

```apache
# PL4: Double encoded SQLi
SecRule ARGS "@rx %25(32|33|27|28|29)" "id:942140, phase:2, \
  tag:'paranoia-level/4', \
  setvar:'tx.anomaly_score_pl4=+%{tx.critical_anomaly_score}'"
```

---

## 6. Anomaly Scoring Mechanism

Setiap rule match menambahkan skor ke anomaly counter.

### Per Severity

| Severity | Skor | Contoh |
|---|---|---|
| CRITICAL | 5 | SQLi, XSS, RCE |
| ERROR | 4 | Protocol violation |
| WARNING | 3 | Scanner detection |
| NOTICE | 2 | Information disclosure |

### Per PL

Setiap PL punya anomaly score counter sendiri:

```apache
tx.anomaly_score_pl1  # Hanya dari PL1 rules
tx.anomaly_score_pl2  # Dari PL1 + PL2 rules
tx.anomaly_score_pl3  # Dari PL1 + PL2 + PL3 rules
tx.anomaly_score_pl4  # Dari semua rules
```

### Blocking Decision

```apache
# Jika paranoia_level = 2
# Hanya cek tx.anomaly_score_pl2
# Jika >= tx.inbound_anomaly_score_threshold → BLOCK

SecRule TX:ANOMALY_SCORE_PL2 "@ge %{tx.inbound_anomaly_score_threshold}" \
  "id:949110, phase:2, block, \
  msg:'Inbound Anomaly Score Exceeded'"
```

---

## 7. Scoring Modes

### Accumulate Mode (CRS default)

Semua rule match diakumulasi. Jika total ≥ threshold → block.

```text
Request: 3 rule matches
  CRITICAL (+5) + WARNING (+3) + NOTICE (+2) = 10
  Threshold: 5
  → BLOCKED (10 >= 5)
```

### Threshold Mode (alternatif)

Setiap rule individual memiliki skor. Blokir jika ada rule dengan severity tertentu.

```text
Request: 3 rule matches
  CRITICAL (+5) → threshold critical = 1 → BLOCKED
  (tanpa akumulasi)
```

---

## 8. Implikasi ke WAF

### WAF current state (`anomaly.rs`)

```rust
// Scoring mode: "accumulate" atau "threshold"
pub scoring_mode: String,
pub anomaly_threshold: u32,  // default: 5

// Severity scoring
pub fn score(&self) -> u32 {
    match self {
        Self::Low => 2,
        Self::Medium => 3,
        Self::High => 4,
        Self::Critical => 5,
    }
}
```

### Perbandingan

| Aspek | CRS v4 | WAF |
|---|---|---|
| Paranoia levels | PL1-PL4 | Belum ada 🎯 |
| Per-PL scoring | `anomaly_score_pl[1-4]` | Single score |
| Severity scoring | CRITICAL=5, ERROR=4, WARNING=3, NOTICE=2 | Critical=5, High=4, Medium=3, Low=2 |
| Accumulate mode | Default | `scoring_mode: "accumulate"` |
| Threshold mode | Available | `scoring_mode: "threshold"` |
| Data files (.data) | `@pm from-file` | Belum ada 🎯 |

### Rekomendasi

1. **Implementasi PL system** — Setiap rule punya level 1-4
2. **Per-PL threshold** — Threshold berbeda per level
3. **Data file support** — Load pattern dari file external
4. **Phase-based blocking** — Separate blocking decision phase

**Lokasi CRS:** `/mnt/data_d/Projects/Reference/owasp-coreruleset/`
