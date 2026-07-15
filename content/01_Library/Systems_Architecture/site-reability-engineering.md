---
title: "SITE RELIABILITY ENGINEERING — A Deep Dive into Production Integrity"
tags:
  - sre
  - reliability
  - slo
  - monitoring
  - incident-management
  - automation
aliases:
  - SRE Deep Dive
  - Site Reliability Engineering
  - Production Engineering
  - sre-google
created: "2026-07-05"
updated: 2026-07-09
status: operational
cssclasses:
  - wide-table
---

> [!abstract] Beyond Uptime: The Engineering of Trust
> SRE bukan sekadar pekerjaan "menjaga server tetap hidup." SRE adalah disiplin rekayasa yang menerapkan **prinsip-prinsip perangkat lunak pada operasi sistem** untuk menciptakan infrastruktur yang skalabel, andal, dan efisien. Buku seminal dari Google ini mendefinisikan bahasa universal bagi organisasi untuk menyeimbangkan kecepatan pengembangan fitur dengan stabilitas sistem—bukan dengan insting, tetapi dengan **matematika, SLO, dan error budget.** Dokumen ini adalah pembedahan operasional dan implementasi Python dari fondasi SRE.

---

## 🧬 1. Fondasi: SRE = Rekayasa Perangkat Lunak yang Diterapkan pada Operasi

SRE lahir dari frustrasi: operasi tradisional tidak skalabel. Ketika sistem tumbuh, tim ops tumbuh secara linear. SRE mematahkan kurva ini dengan memperlakukan operasi sebagai **masalah rekayasa perangkat lunak**, bukan masalah manual.

**Prinsip Inti:**

- **Rekrutmen:** Hanya mempekerjakan _software engineer_ untuk melakukan pekerjaan operasi. Pola pikir "kode di atas segalanya" memastikan bahwa setiap tugas ops yang berulang akan diotomatisasi, bukan dikerjakan secara manual.
- **50% Rule:** Targetkan maksimal 50% waktu kerja untuk _toil_ (tugas operasional manual, repetitif, dan tidak bernilai jangka panjang). Sisa waktu digunakan untuk proyek rekayasa yang mengurangi _toil_ di masa depan atau meningkatkan keandalan.
- **Error Budget:** Inovasi dan stabilitas adalah kekuatan yang berlawanan. Error budget adalah jembatan di antara keduanya. Ini adalah kuantifikasi matematis dari "seberapa tidak andal yang dapat kita terima."

```python
# Model SRE dalam Kode: The 50% Rule
from dataclasses import dataclass
from typing import List

@dataclass
class Task:
    name: str
    is_toil: bool
    hours: float

class SRE_Team:
    def __init__(self, engineers: int):
        self.engineers = engineers
        self.tasks: List[Task] = []

    def add_task(self, task: Task):
        self.tasks.append(task)

    def toil_percentage(self) -> float:
        toil_hours = sum(t.hours for t in self.tasks if t.is_toil)
        total_hours = sum(t.hours for t in self.tasks)
        return toil_hours / total_hours * 100 if total_hours > 0 else 0

    def should_focus_on_engineering(self) -> bool:
        return self.toil_percentage() > 50
```

---

## 📊 2. Service Level Objectives (SLO): Matematika Keandalan

**SLI, SLO, SLA** adalah segitiga suci SRE. Kesalahan paling umum adalah menetapkan SLO tanpa data, atau menetapkan SLA yang tidak realistis.

### Definisi Formal:

- **SLI (Service Level Indicator):** Metrik kuantitatif yang terukur. Contoh: `latency_p99 < 100ms`, `error_rate < 0.1%`, `uptime = (total_time - downtime) / total_time`.
- **SLO (Service Level Objective):** Target numerik untuk SLI dalam jendela waktu tertentu. Contoh: "99.9% dari semua permintaan harus lebih cepat dari 100ms dalam 30 hari terakhir." Ini adalah **komitmen internal**.
- **SLA (Service Level Agreement):** Kontrak legal dengan pelanggan yang mencakup konsekuensi finansial jika SLO dilanggar. SLA selalu **lebih longgar** dari SLO internal untuk memberikan buffer.

### Error Budget: Izin untuk Gagal

Error budget adalah `1 - SLO`. Jika SLO Anda adalah 99.9% (3 nines), error budget Anda adalah 0.1% dari total waktu. Dalam 30 hari (43.200 menit), itu adalah **43,2 menit downtime yang "diizinkan."**

Selama error budget masih positif, tim produk bebas meluncurkan fitur baru. Jika budget habis, semua peluncuran dihentikan, dan seluruh fokus tim beralih ke stabilitas.

**Perhitungan Error Budget (Python):**

```python
from datetime import datetime, timedelta

class ErrorBudget:
    def __init__(self, slo_percentage: float, window_days: int = 30):
        self.slo = slo_percentage
        self.budget_percentage = 100 - slo_percentage
        self.window = timedelta(days=window_days)
        self.total_minutes = self.window.total_seconds() / 60
        self.budget_minutes = self.budget_percentage / 100 * self.total_minutes

    def consume(self, downtime_minutes: float):
        self.budget_minutes -= downtime_minutes
        return self.budget_minutes >= 0

# Contoh
budget = ErrorBudget(99.9, 30)
print(f"Error budget awal: {budget.budget_minutes:.1f} menit")
is_ok = budget.consume(45)
print(f"Budget tersisa: {budget.budget_minutes:.1f} menit. Masih bisa deploy? {is_ok}")
```

---

## 📈 3. Golden Signals: Empat Pilar Observabilitas

| Sinyal         | Definisi                                           | Metrik Khas                                 | Contoh Alert                        |
| -------------- | -------------------------------------------------- | ------------------------------------------- | ----------------------------------- |
| **Latency**    | Waktu layanan permintaan. BEDAKAN sukses vs error. | `p50`, `p95`, `p99`                         | `p99 > 200ms` untuk 5 menit         |
| **Traffic**    | Jumlah permintaan ke sistem                        | `requests_per_second`, `connections`        | Lonjakan 3x lipat dari baseline     |
| **Errors**     | Tingkat kegagalan permintaan                       | `5xx / total`, `exception_count`            | `error_rate > 1%` untuk 2 menit     |
| **Saturation** | Seberapa "penuh" sumber daya                       | `cpu`, `memory`, `queue_depth`, `disk_iops` | `queue_depth > 100` selama 10 menit |

**Implementasi Python:**

```python
import random
from collections import deque
import statistics

class GoldenSignalMonitor:
    def __init__(self, window_seconds=60):
        self.window = window_seconds
        self.latencies = deque(maxlen=1000)
        self.error_count = 0
        self.request_count = 0

    def record_request(self, latency_seconds: float, is_error: bool):
        self.latencies.append(latency_seconds)
        self.request_count += 1
        if is_error:
            self.error_count += 1

    def get_p99_latency(self) -> float:
        if not self.latencies: return 0
        sorted_lat = sorted(self.latencies)
        idx = int(0.99 * len(sorted_lat))
        return sorted_lat[min(idx, len(sorted_lat)-1)]

    def get_error_rate(self) -> float:
        return self.error_count / self.request_count if self.request_count else 0

monitor = GoldenSignalMonitor()
for _ in range(100):
    latency = random.expovariate(1/0.05)
    is_error = random.random() < 0.01
    monitor.record_request(latency, is_error)

print(f"P99 Latency: {monitor.get_p99_latency()*1000:.1f}ms")
print(f"Error Rate: {monitor.get_error_rate():.2%}")
```

---

## 🔧 4. Eliminating Toil: Otomatisasi atau Mati

**Toil** adalah pekerjaan operasi yang: Manual, Repetitif, Dapat diotomatisasi, Tidak bernilai jangka panjang, Tumbuh linear dengan sistem.

**Bukan Toil:** Postmortem (bernilai), debugging kompleks (tidak repetitif).

**Strategi:**

- Identifikasi → Kuantifikasi → Otomatisasi → Produkkan

**Contoh Otomatisasi (Log Cleaner):**

```python
import os
from datetime import datetime, timedelta

class LogCleaner:
    def __init__(self, log_dir, retention_days=7):
        self.log_dir = log_dir
        self.retention = timedelta(days=retention_days)

    def clean(self):
        now = datetime.now()
        for fname in os.listdir(self.log_dir):
            fpath = os.path.join(self.log_dir, fname)
            if os.path.isfile(fpath):
                mtime = datetime.fromtimestamp(os.path.getmtime(fpath))
                if now - mtime > self.retention:
                    os.remove(fpath)
```

---

## 🚨 5. Incident Management & Blameless Postmortem

### Filosofi: Blame is the Enemy of Learning

Tujuan utama saat insiden: **pulihkan layanan secepat mungkin.** Setelah itu: **blameless postmortem.**

**Struktur Postmortem:**

1. Ringkasan Insiden — apa, dampak, durasi
2. Timeline — deteksi → respons → pemulihan
3. Analisis Akar Penyebab — "5 Whys"
4. Action Items — spesifik, terukur, berbatas waktu

**Contoh 5 Whys — Deployment Gagal:**

1. Why? → Script migrasi DB error
2. Why? → Perubahan skema tidak kompatibel
3. Why? → Tidak ada test integrasi skema di CI/CD
4. Why? → Tim asumsi ORM akan handle
5. Why? → Tidak ada checklist pre-deployment
   **Action Item:** Validasi skema otomatis di pipeline CI/CD.

---

## ⚖️ 6. Capacity Planning & Load Testing

| Jenis              | Tujuan                                             |
| ------------------ | -------------------------------------------------- |
| **Load Testing**   | Tingkatkan beban bertahap → temukan breaking point |
| **Stress Testing** | Beban ekstrem → lihat bagaimana sistem gagal       |
| **Soak Testing**   | Beban tinggi durasi panjang → deteksi memory leak  |

**Load Test Sederhana:**

```python
import concurrent.futures, time, statistics, urllib.request

def run_load_test(url, concurrency=10, num_requests=100):
    def req(u):
        start = time.time()
        try:
            with urllib.request.urlopen(u, timeout=5) as r:
                return {"status": r.status, "latency": time.time()-start}
        except Exception as e:
            return {"status": "error", "latency": time.time()-start}

    with concurrent.futures.ThreadPoolExecutor(max_workers=concurrency) as ex:
        results = list(ex.map(lambda _: req(url), range(num_requests)))

    lats = [r['latency'] for r in results if r['status'] != 'error']
    errs = [r for r in results if r['status'] == 'error']
    print(f"P50: {statistics.median(lats)*1000:.1f}ms, P99: {sorted(lats)[int(0.99*len(lats))]*1000:.1f}ms")
    print(f"Error Rate: {len(errs)/num_requests:.2%}")
```

---

## 🛠️ 7. Configuration & Secrets Management

**Praktik Terbaik:**

- Config di VCS (Git) — traceable, reviewable
- Pisahkan config dari kode — tidak ada URL DB hardcode
- Secrets di Vault — jangan pernah commit

**Contoh (python-dotenv + hvac):**

```python
import os
from dotenv import load_dotenv
import hvac

# Dev: .env
load_dotenv()
db_user = os.getenv("DB_USER")

# Production: HashiCorp Vault
client = hvac.Client(url='http://localhost:8200')
client.token = os.getenv("VAULT_TOKEN")
secret = client.secrets.kv.v2.read_secret_version(path='myapp/database')
db_pass = secret['data']['data']['password']
```

---

## 📚 Koneksi ke Vault

| Konsep SRE                 | Dokumen Terkait                                         |
| -------------------------- | ------------------------------------------------------- |
| Error Budget & SLO         | [[ddia-summary]], [[system-design]]                     |
| Monitoring & Observability | [[infrastructure-administrator]], [[endpoint-security]] |
| Incident Response          | [[blueteam-detection-matrix]], [[network-security]]     |
| Eliminating Toil           | [[devops]]                                              |
| Capacity Planning          | [[cloud-infrastructure]], [[ostep-three-easy-pieces]]   |
| Blameless Culture          | [[dual-use-spectrum-and-ethical-framework]]             |

---

## ✅ Checklist Implementasi SRE

- [ ] Definisikan SLI (2-3 metrik kunci)
- [ ] Tetapkan SLO realistis (mulai 99%)
- [ ] Hitung error budget, publikasikan ke tim
- [ ] Audit monitoring — matikan alert tidak actionable
- [ ] Tulis postmortem pertama (template blameless)
- [ ] Identifikasi 1 toil → otomatisasi
- [ ] Simulasikan load test di staging

> [!tip] SRE Bukan Pekerjaan, Ini Pola Pikir
> Setiap engineer bisa terapkan SRE — hitung error budget sebelum deploy, tulis postmortem untuk bug serius, otomatisasi satu toil per minggu.
