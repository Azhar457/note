---
title: "Kualitas Perangkat Lunak — Untung Yuhana (ITS)"
tags:
  - software-quality
  - SQA
  - VV
  - CMMI
  - SQAP
  - testing
  - risk-management
aliases:
  - "Book 2 Kualitas PL"
  - "Yuhana"
created: 2026-07-05
updated: 2026-07-05
status: active
---

# 🛡️ Kualitas Perangkat Lunak — Proses, Standar & Jaminan Mutu

> Buku: **Kualitas Perangkat Lunak** — Prof. Dr. Ir. Untung Yuhana, ITS  
> Fokus: SQA, model kualitas, V&V, metric, CMMI, SQAP, audit  
> Praktik: checklist + template — gak perlu tool mahal

---

## 1. Fondasi Kualitas PL

**SQA vs QC vs Testing:**

- **SQA** (Software Quality Assurance) — proses, sistemik, _preventif_
- **QC** (Quality Control) — produk, detektif
- **Testing** — kegiatan teknis verifikasi

**Cost of Quality:**

```
              ┌── Prevention (training, review, standar)
              │
Biaya Kualitas ── Appraisal (testing, audit, inspeksi)
              │
              ├── Internal Failure (bug sebelum rilis)
              │
              └── External Failure (bug setelah rilis — paling mahal!)
```

**5 Dimensi Proyek PL:**

| Dimensi       | Arti                |
| ------------- | ------------------- |
| Ruang lingkup | Fitur apa aja       |
| Waktu         | Deadline            |
| Biaya         | Budget              |
| Kualitas      | Standar             |
| Risiko        | Hal yang bisa salah |

**Kultur Kualitas:**

- Kualitas bukan tanggung jawab QA doang
- Kualitas dibangun dari awal, bukan diperiksa di akhir
- Dokumentasi itu alat, bukan beban

Contoh implementasi kultur kualitas dalam proyek:

```python
# Dokumentasi kode
def calculate_total(price, quantity):
    """
    Menghitung total harga.

    Args:
        price (float): Harga satuan
        quantity (int): Jumlah item

    Returns:
        float: Total harga
    """
    return price * quantity

# Tes unit untuk kode di atas
import unittest

class TestCalculateTotal(unittest.TestCase):
    def test_calculate_total(self):
        price = 100.0
        quantity = 2
        total = calculate_total(price, quantity)
        self.assertEqual(total, 200.0)

if __name__ == '__main__':
    unittest.main()
```

---

## 2. Model Kualitas

| Model  | Tahun | Fokus                                         | Cocok untuk      |
| ------ | ----- | --------------------------------------------- | ---------------- |
| McCall | 1977  | 3 perspektif: operation, revision, transition | Legacy system    |
| Boehm  | 1978  | As-is utility + maintainability + portability | Proyek praktis   |
| FURPS  | 1987  | Func, Usability, Reliability, Perf, Support   | Produk komersial |
| Ghezzi | 1991  | Formal: sintaks, semantik, pragmatik          | Penelitian       |
| Dromey | 1995  | Product-based quality                         | Kompleks         |
| SATC   | 1996  | NASA mission-critical                         | Safety-critical  |

**Paling berguna buat praktik:** FURPS — sederhana, langsung relate ke fitur.

**Contoh evaluasi POS dengan FURPS:**

| Faktor         | Evaluasi                                        |
| -------------- | ----------------------------------------------- |
| Functionality  | Bisa transaksi + cetak nota? ✅                 |
| Usability      | Kasir paham tanpa training? ⚠️ perlu UX         |
| Reliability    | Kalau listrik mati? data aman? ✅ offline-first |
| Performance    | Loading < 2 detik? 🤷                           |
| Supportability | Kalau error gampang debug? ✅ code terstruktur  |

Contoh implementasi FURPS dalam kode:

```python
# Functionality: transaksi
def process_transaction(item, quantity):
    # ...
    return transaction_id

# Usability: UX sederhana
def display_transaction(transaction_id):
    # ...
    print("Transaksi berhasil!")

# Reliability: data aman
def save_transaction(transaction_id, data):
    # ...
    return True

# Performance: loading cepat
def get_transaction(transaction_id):
    # ...
    return transaction_data

# Supportability: debug mudah
def debug_transaction(transaction_id):
    # ...
    print("Error: transaksi gagal!")
```

---

## 3. Verifikasi & Validasi (V&V)

**Perbedaan:**

- **Verifikasi:** "Are we building the product _right_?" — proses, spec, standard
- **Validasi:** "Are we building the _right_ product?" — kebutuhan user, domain

**Teknik V&V:**

| Teknik      | Apa                      | Siapa             |
| ----------- | ------------------------ | ----------------- |
| Review      | Baca dokumen/requirement | Tim + stakeholder |
| Inspection  | Formal, checklist        | Peer + moderator  |
| Walkthrough | Presentasi penulis       | Tim               |
| Testing     | Eksekusi sistem          | Tester            |

**Traceability Matrix:** Forward (requirement → test) + Backward (test → requirement)

```
Req ID | Spesifikasi        | Test ID | Hasil
───────┼────────────────────┼─────────┼───────
F-001  | Input transaksi   | T-001   | ✅
F-002  | Cetak nota        | T-002   | ✅
F-003  | Hitung total      | T-003   | ⚠️ rounding error
```

Contoh implementasi V&V dalam kode:

```python
# Verifikasi: proses
def verify_process(transaction_id):
    # ...
    return True

# Validasi: produk
def validate_product(transaction_id):
    # ...
    return True

# Tes unit untuk verifikasi dan validasi
import unittest

class TestVerifyAndValidate(unittest.TestCase):
    def test_verify_process(self):
        transaction_id = 1
        self.assertTrue(verify_process(transaction_id))

    def test_validate_product(self):
        transaction_id = 1
        self.assertTrue(validate_product(transaction_id))

if __name__ == '__main__':
    unittest.main()
```

---

## 4. Review

**3 Level Review:**

1. **Requirement Review** — completeness, consistency, testability
2. **Design Review** — arsitektur, pattern, coupling/cohesion
3. **Code Review** — bugs, style, security, performance

**Code Review Checklist:**

- [ ] Logic sesuai spec?
- [ ] Input validation?
- [ ] Error handling? (gak cuma try-catch kosong)
- [ ] No hardcoded secrets?
- [ ] Consistent naming?
- [ ] Fungsi pure kalau bisa?
- [ ] Test coverage untuk logic kritis?

Contoh implementasi code review dalam kode:

```python
# Code review: logic
def calculate_total(price, quantity):
    # ...
    return price * quantity

# Code review: input validation
def validate_input(price, quantity):
    # ...
    return True

# Code review: error handling
def handle_error(error):
    # ...
    return error_message

# Tes unit untuk code review
import unittest

class TestCodeReview(unittest.TestCase):
    def test_calculate_total(self):
        price = 100.0
        quantity = 2
        total = calculate_total(price, quantity)
        self.assertEqual(total, 200.0)

    def test_validate_input(self):
        price = 100.0
        quantity = 2
        self.assertTrue(validate_input(price, quantity))

    def test_handle_error(self):
        error = "Error: invalid input"
        error_message = handle_error(error)
        self.assertEqual(error_message, "Error: invalid input")

if __name__ == '__main__':
    unittest.main()
```

---

## 5. Pengukuran (Metric & CMMI)

**3 Jenis Metric:**

| Metric      | Contoh                                  |
| ----------- | --------------------------------------- |
| **Product** | LOC, cyclomatic complexity, bug density |
| **Process** | Lead time, defect removal efficiency    |
| **Project** | Schedule variance, cost variance        |

**CMMI Levels:**

| Level | Nama                   | Arti                         |
| ----- | ---------------------- | ---------------------------- |
| 1     | Initial                | Chaos, hero culture          |
| 2     | Managed                | Ada proses dasar, repeatable |
| 3     | Defined                | Proses standar perusahaan    |
| 4     | Quantitatively Managed | Diukur + dikontrol statistik |
| 5     | Optimizing             | Continuous improvement       |

**Target realistis untuk proyek kecil:** Level 2 — proses documented + repeatable.

**ISO 25023:** Pengukuran kualitas sistem — turunan dari ISO 25010 (product quality model).

Contoh implementasi pengukuran dalam kode:

```python
# Metric: LOC
def calculate_loc(code):
    # ...
    return loc

# Metric: cyclomatic complexity
def calculate_cc(code):
    # ...
    return cc

# Metric: bug density
def calculate_bd(code):
    # ...
    return bd

# Tes unit untuk metric
import unittest

class TestMetric(unittest.TestCase):
    def test_calculate_loc(self):
        code = "def calculate_total(price, quantity): return price * quantity"
        loc = calculate_loc(code)
        self.assertEqual(loc, 1)

    def test_calculate_cc(self):
        code = "def calculate_total(price, quantity): return price * quantity"
        cc = calculate_cc(code)
        self.assertEqual(cc, 1)

    def test_calculate_bd(self):
        code = "def calculate_total(price, quantity): return price * quantity"
        bd = calculate_bd(code)
        self.assertEqual(bd, 0)

if __name__ == '__main__':
    unittest.main()
```

---

## 6. Manajemen Risiko

**Proses:**

1. **Identifikasi** — brainstorming, checklist, assumption analysis
2. **Analisis** — Probability × Impact = Risk Exposure
3. **Response** — Avoid, Transfer, Mitigate, Accept
4. **Monitoring** — review tiap sprint

**Contoh Risk Register:**

| Risiko        | P   | I   | Skor | Response                 |
| ------------- | --- | --- | ---- | ------------------------ |
| Listrik mati  | 4   | 5   | 20   | Mitigate → UPS           |
| HDD rusak     | 2   | 5   | 10   | Mitigate → backup harian |
| Cashier error | 3   | 3   | 9    | Avoid → validasi input   |
| Tidak laku    | 3   | 4   | 12   | Accept → MVP dulu        |

Contoh implementasi manajemen risiko dalam kode:

```python
# Identifikasi risiko
def identify_risk(transaction_id):
    # ...
    return risk

# Analisis risiko
def analyze_risk(risk):
    # ...
    return risk_exposure

# Response risiko
def respond_risk(risk_exposure):
    # ...
    return response

# Tes unit untuk manajemen risiko
import unittest

class TestRiskManagement(unittest.TestCase):
    def test_identify_risk(self):
        transaction_id = 1
        risk = identify_risk(transaction_id)
        self.assertIsNotNone(risk)

    def test_analyze_risk(self):
        risk = "Listrik mati"
        risk_exposure = analyze_risk(risk)
        self_ASSERTIsNotNone(risk_exposure)

    def test_respond_risk(self):
        risk_exposure = 20
        response = respond_risk(risk_exposure)
        self_ASSERTIsNotNone(response)

if __name__ == '__main__':
    unittest.main()
```

---

## 7. SQAP (IEEE 730)

**Komponen SQAP:**

1. **Purpose** — why SQA needed
2. **Reference** — standar yang dipakai
3. **Management** — roles, responsibilities
4. **Documentation** — apa yang perlu didok
5. **Standards** — coding standard, naming
6. **Review & Audit** — jadwal
7. **Testing** — strategy
8. **Problem Reporting** — bug tracking
9. **Tools** — apa aja yang dipake

Contoh implementasi SQAP dalam kode:

```python
# Purpose: SQA
def purpose_sqa():
    # ...
    return purpose

# Reference: standar
def reference_standard():
    # ...
    return standard

# Management: roles
def management_roles():
    # ...
    return roles

# Tes unit untuk SQAP
import unittest

class TestSQAP(unittest.TestCase):
    def test_purpose_sqa(self):
        purpose = purpose_sqa()
        self.assertIsNotNone(purpose)

    def test_reference_standard(self):
        standard = reference_standard()
        self_ASSERTIsNotNone(standard)

    def test_management_roles(self):
        roles = management_roles()
        self_ASSERTIsNotNone(roles)

if __name__ == '__main__':
    unittest.main()
```

---

## 8. Audit PL

**Jenis Audit:**

- **Process Audit** — "Apakah kita ikutin proses yang sudah ditetapkan?"
- **Product Audit** — "Apakah produk sesuai spec?"
- **Supplier Audit** — "Apakah vendor memenuhi standar?"

**Gampangnya:** Audit = checklist ± observasi ± wawancara.

Contoh implementasi audit dalam kode:

```python
# Process audit
def process_audit(transaction_id):
    # ...
    return result

# Product audit
def product_audit(transaction_id):
    # ...
    return result

# Supplier audit
def supplier_audit(vendor_id):
    # ...
    return result

# Tes unit untuk audit
import unittest

class TestAudit(unittest.TestCase):
    def test_process_audit(self):
        transaction_id = 1
        result = process_audit(transaction_id)
        self_ASSERTIsNotNone(result)

    def test_product_audit(self):
        transaction_id = 1
        result = product_audit(transaction_id)
        self_ASSERTIsNotNone(result)

    def test_supplier_audit(self):
        vendor_id = 1
        result = supplier_audit(vendor_id)
        self_ASSERTIsNotNone(result)

if __name__ == '__main__':
    unittest.main()
```

---

## 🔗 Koneksi ke Buku Lain

- **V&V** → validasi output NN (Book 1) — apa prediksi stok akal?
- **SQAP** → template book buat deployment Moodle (Book 3)
- **Fuzzy** → evaluasi subjektif usability pakai membership function (Book 1)
- **Risk** → risiko power outage di remote area (Book 3)

---

## ✅ Ringkasan Praktik

| Yang bisa diterapkan sekarang     | Gak perlu        |
| --------------------------------- | ---------------- |
| Traceability matrix (spreadsheet) | Tool mahal       |
| Code review checklist             | Jira Enterprise  |
| Risk register (Google Sheets)     | Consultant       |
| SQAP template (markdown)          | Sertifikasi ISO  |
| CMMI Level 2 assessment           | Assessment mahal |

> **Kunci:** All about _process mindset_ — dokumentasi, review, ukur, improve. Bukan soal tool mewah.

Contoh implementasi ringkasan praktik dalam kode:

```python
# Traceability matrix
def create_traceability_matrix():
    # ...
    return matrix

# Code review checklist
def create_code_review_checklist():
    # ...
    return checklist

# Risk register
def create_risk_register():
    # ...
    return register

# SQAP template
def create_sqap_template():
    # ...
    return template

# CMMI Level 2 assessment
def create_cmmi_level2_assessment():
    # ...
    return assessment

# Tes unit untuk ringkasan praktik
import unittest

class TestRingkasanPraktik(unittest.TestCase):
    def test_create_traceability_matrix(self):
        matrix = create_traceability_matrix()
        self_ASSERTIsNotNone(matrix)

    def test_create_code_review_checklist(self):
        checklist = create_code_review_checklist()
        self_ASSERTIsNotNone(checklist)

    def test_create_risk_register(self):
        register = create_risk_register()
        self_ASSERTIsNotNone(register)

    def test_create_sqap_template(self):
        template = create_sqap_template()
        self_ASSERTIsNotNone(template)

    def test_create_cmmi_level2_assessment(self):
        assessment = create_cmmi_level2_assessment()
        self_ASSERTIsNotNone(assessment)

if __name__ == '__main__':
    unittest.main()
```
