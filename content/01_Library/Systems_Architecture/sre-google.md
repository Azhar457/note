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

## 📌 Kenapa Penting

Sistem production merupakan lingkungan yang sangat berbeda dengan development. Pada development, fokus utama adalah pada pengembangan fitur dan fungsi baru, sedangkan pada production, fokus utama adalah pada menjaga ketersediaan dan keandalan sistem. Site Reliability Engineering (SRE) hadir sebagai sebuah pendekatan yang menjembatani dev dan ops, memungkinkan tim untuk bekerja sama dan memastikan bahwa sistem dapat berjalan dengan stabil dan efisien.

SRE adalah **what DevOps looks like when engineers are in charge of ops**. Dalam SRE, para insinyur tidak hanya fokus pada pengembangan kode, tetapi juga pada operasional sistem. Mereka bekerja sama dengan tim ops untuk memastikan bahwa sistem dapat berjalan dengan stabil dan efisien.

Error budget adalah framework yang digunakan dalam SRE untuk menyeimbangkan kecepatan pengembangan fitur dengan kestabilan sistem. Dengan error budget, tim dapat menentukan berapa banyak waktu yang dapat dihabiskan untuk pengembangan fitur dan berapa banyak waktu yang harus dihabiskan untuk memastikan kestabilan sistem.

## 🎯 Key Takeaways

**1. SRE = Software Engineer + Operations**
SRE bukanlah sebuah judul pekerjaan, tetapi lebih kepada sebuah pendekatan. Dalam SRE, para insinyur menggunakan prinsip-prinsip pengembangan perangkat lunak untuk memecahkan masalah operasional. Target utama dalam SRE adalah untuk memastikan bahwa kurang dari 50% waktu digunakan untuk operasional (toil), dan sisanya digunakan untuk pengembangan.

Contoh implementasi SRE dalam sebuah perusahaan dapat dilihat sebagai berikut:

```python
# Definisi SRE dalam sebuah perusahaan
class SRE:
    def __init__(self, nama):
        self.nama = nama
        self.waktu_ops = 0
        self.waktu_dev = 0

    def tambah_waktu_ops(self, waktu):
        self.waktu_ops += waktu

    def tambah_waktu_dev(self, waktu):
        self.waktu_dev += waktu

    def get_waktu_ops(self):
        return self.waktu_ops

    def get_waktu_dev(self):
        return self.waktu_dev

# Implementasi SRE dalam sebuah perusahaan
sre = SRE("John Doe")
sre.tambah_waktu_ops(30)  # 30 menit untuk operasional
sre.tambah_waktu_dev(120)  # 120 menit untuk pengembangan
print(sre.get_waktu_ops())  # Output: 30
print(sre.get_waktu_dev())  # Output: 120
```

**2. Service Level Everything**
Dalam SRE, ada tiga konsep yang penting: Service Level Indicator (SLI), Service Level Objective (SLO), dan Service Level Agreement (SLA).

- SLI adalah metric yang digunakan untuk mengukur kinerja sistem. Contoh SLI adalah latency p99 (waktu yang dibutuhkan untuk memproses 99% permintaan) dan error rate (jumlah kesalahan yang terjadi).
- SLO adalah target yang diinginkan untuk sistem. Contoh SLO adalah 99,9% uptime (sistem harus berjalan selama 99,9% waktu).
- SLA adalah perjanjian antara penyedia jasa dan pelanggan tentang kinerja sistem. Contoh SLA adalah perjanjian bahwa sistem akan berjalan selama 99,9% waktu, dan jika gagal, maka penyedia jasa akan memberikan kompensasi kepada pelanggan.

Gap antara SLI dan SLO merupakan ruang untuk perbaikan. Jika SLI lebih buruk dari SLO, maka sistem perlu diperbaiki untuk mencapai target yang diinginkan.

## 📊 Tabel Perbandingan SLI, SLO, dan SLA

| Konsep | Definisi                  | Contoh                  |
| ------ | ------------------------- | ----------------------- |
| SLI    | Metric kinerja sistem     | Latency p99, error rate |
| SLO    | Target kinerja sistem     | 99,9% uptime            |
| SLA    | Perjanjian kinerja sistem | Perjanjian 99,9% uptime |

## 📈 Grafik Kinerja Sistem

Grafik kinerja sistem dapat digunakan untuk memvisualisasikan kinerja sistem dan mengidentifikasi area yang perlu diperbaiki.

```markdown
+---------------+
| Kinerja |
| Sistem |
+---------------+
| Uptime | 99,9% |
| Latency | 100ms |
| Error Rate | 0,1% |
+---------------+
```

## 🎯 Capacity & Automation

Dalam SRE, kapasitas dan otomatisasi sangat penting untuk memastikan bahwa sistem dapat berjalan dengan stabil dan efisien.

- Demand forecasting digunakan untuk memprediksi kebutuhan kapasitas sistem. Dengan demand forecasting, tim dapat memprediksi kapan sistem akan membutuhkan kapasitas tambahan dan mempersiapkan diri untuk meningkatkan kapasitas.
- Load testing digunakan untuk menguji kinerja sistem dengan beban yang berat. Dengan load testing, tim dapat mengidentifikasi kelemahan sistem dan memperbaikinya sebelum sistem digunakan dalam produksi.

Otomatisasi sangat penting dalam SRE. Dengan otomatisasi, tim dapat mengurangi waktu yang dibutuhkan untuk operasional (toil) dan meningkatkan efisiensi. Beberapa contoh otomatisasi dalam SRE adalah:

- Otomatisasi deployment: sistem dapat di-deploy secara otomatis ke produksi tanpa perlu campur tangan manual.
- Otomatisasi monitoring: sistem dapat dipantau secara otomatis untuk mengidentifikasi kelemahan dan memperbaikinya.

Berikut adalah contoh kode untuk otomatisasi deployment menggunakan Ansible:

```yml
---
- name: Deploy aplikasi
  hosts: produksi
  become: yes

  tasks:
    - name: Install dependensi
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - dependensi1
        - dependensi2

    - name: Deploy aplikasi
      copy:
        content: "{{ lookup('file', 'aplikasi.jar') }}"
        dest: /path/to/aplikasi.jar
        mode: "0644"

    - name: Start aplikasi
      systemd:
        name: aplikasi
        state: started
        enabled: yes
```

## 📊 Contoh Skenario Troubleshooting

Berikut adalah contoh skenario troubleshooting untuk masalah latency tinggi:

1. Mengidentifikasi masalah: tim mendeteksi bahwa latency sistem meningkat secara signifikan.
2. Mengumpulkan data: tim mengumpulkan data tentang kinerja sistem, termasuk latency, error rate, dan CPU usage.
3. Menganalisis data: tim menganalisis data dan menemukan bahwa latency tinggi disebabkan oleh bottleneck pada database.
4. Mengatasi masalah: tim meningkatkan kapasitas database dan mengoptimalkan query untuk mengurangi latency.
5. Menguji hasil: tim menguji hasil perubahan dan memastikan bahwa latency telah menurun secara signifikan.

## 📚 Bab Penting

Berikut adalah beberapa bab penting dalam buku "Site Reliability Engineering" oleh Betsy Beyer, Chris Jones, Niall Murphy, dan Jennifer Petoff:

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

Dalam implementasi SRE, ada beberapa tantangan yang perlu dihadapi. Berikut adalah beberapa contoh tantangan:

- Google-scale: beberapa teknik yang digunakan dalam SRE mungkin terlalu besar untuk startup atau proyek kecil.
- Fokus ke servis internal: beberapa hal yang dibahas dalam SRE mungkin tidak relevan untuk produk SaaS.
- Buku bisa dibaca per-bab independent: tidak perlu membaca buku secara urut untuk memahami konsep-konsep yang dibahas.

## 🔗 Koneksi

Berikut adalah beberapa koneksi antara SRE dan konsep-konsep lain:

- [[ddia-kleppmann]] — _theory_ distributed systems, SRE adalah _practice_
- [[ostep-three-easy-pieces]] — OS reliability fundamentals
- [[systems-design-interview-alex-xu]] — SRE = how you _run_ the systems from interview

## ✅ Checklist

Berikut adalah beberapa checklist yang dapat digunakan untuk memulai implementasi SRE:

- [ ] Tentukan SLO untuk proyek/produk sendiri (mulai dari 99% dulu)
- [ ] Hitung error budget — berapa downtime yang acceptable per bulan?
- [ ] Audit monitoring: ada alert yang gak actionable? matikan!
- [ ] Blameless postmortem: tulis 1 postmortem untuk insiden terakhir
- [ ] Identifikasi 1 sumber toil + automate it

Dengan melakukan checklist di atas, Anda dapat memulai implementasi SRE dalam proyek/produk Anda dan meningkatkan keandalan serta efisiensi sistem.
