---
title: "Threat Modeling Deep Dive"
  Sistem'
tags:
- cyber-security
- library
created: '2026-07-02'
updated: '2026-07-02'
status: pending
cssclasses: ''
---

# 🛡️ Threat Modeling — Deep Dive: Metodologi dan Praktik Identifikasi Ancaman Sistem

> Ringkasan satu-paragraf menjelaskan bahwa threat modeling adalah proses sistematis untuk mengidentifikasi, mengkuantifikasi, dan mengatasi risiko keamanan dalam sistem perangkat lunak atau infrastruktur melalui pendekatan berbasis struktur (seperti STRIDE, PASTA, attack tree) dan mengintegrasikannya ke dalam siklus hidup pengembangan (SDLC) maupun operasi keamanan.

> [!info] Hubungan ke Vault
> Catatan ini terkait dengan [[comprehensive-threat-directory]] untuk taksonomi ancaman, [[network-security]] dan [[endpoint-security]] untuk lapisan deteksi, serta [[system-design]] untuk arsitektur sistem yang dimodelkan.

---

## Daftar Isi

- [[#Foundation]]
- [[#Technical Deep-Dive]]
- [[#Advanced]]
- [[#Case Studies]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Foundation

### Apa Itu Threat Modeling?

Threat modeling adalah aktivitas analisis keamanan yang bertujuan memahami bagaimana seorang penyerang bisa berinteraksi dengan sistem, titik mana yang rentan, dan apa dampaknya jika terjadi eksploitasi. Proses ini biasanya dilakukan selama desain awal maupun sebagai bagian dari penilaian berkala.

### Kerangka Kerja Utama

Beberapa metodologi yang banyak digunakan:

| Metodologi | Fokus Utama | Tahap Utama | Kelebihan |
|------------|-------------|-------------|-----------|
| **STRIDE** (Microsoft) | Kategori ancaman berdasarkan Spoofing, Tampering, Repudiation, Information Disclosure, Denial of Service, Elevation of Privilege | 1. Menggambar arsitektur (DFD) 2. Mengidentifikasi ancaman per elemen 3. Menetapkan mitigasi | Mudah dipahami, terintegrasi dengan SDL Microsoft |
| **PASTA** (Process for Attack Simulation and Threat Analysis) | Risiko berbasis seranggan berulang tahapan | 1. Tujuan bisnis 2. Scope teknis 3. Decomposisi aplikasi 4. Analisis ancaman 5. Analisis kerentanan 6. Analisis serangan 7. Dampak dan risiko 8. Respons | Mengkaitkan risiko bisnis dengan teknikal, cocok untuk risk management formal |
| **Attack Tree** | Pohon keputusan yang menunjukkan jalur serangan dari tujuan ke leaf eksploitasi | 1. Definisikan tujuan attacker 2. Pecah menjadi sub-tujuan (AND/OR) 3. Tambahkan nilai biaya/keterampilan | Visual intuitif, mudah untuk komunikasi dengan pemangku kepentingan non-teknis |
| **TRIKE** | Risiko berbasis kebutuhan kepatuhan dan auditing | 1. Definisikan aktor dan hak 2. Modelkan prinsip keamanan (authority, osv) 3. Identifikasi pelanggaran | Fokus pada integritas dan akuntabilitas, berguna untuk sistem yang altamente terregulasi |
| **VAST** (Visual, Agile, Simple Threat modeling) | Skalabilitas dalam tim DevOps | 1. Application Threat Map (developer view) 2. Operational Threat Map (infrastructure/ops view) | Dirancang untuk integrasi terus-menerus dalam CI/CD pipeline |

### Konsep Dasar yang Harus Dipahami

- **Asset**: Hal yang berharga yang perlu dilindungi (data, layanan, reputasi).
- **Threat Actor**: Penyerang dengan motivasi, kemampuan, dan sumber daya tertentu (e.g., insider, cybercriminal, nation-state).
- **Attack Surface**: Total titik di mana sistem dapat menerima masukan dari pihak tidak terpercaya.
- **Trust Boundary**: Batas di mana tingkat kepercayaan berubah (misalnya, antara internet dan DMZ).
- **Mitigasi**: Kontrol yang diterapkan untuk mengurangi likelihood atau dampak ancaman.
- **Risk**: Kombinasi likelihood (probabilitas) dan impact (dampak) dari sebuah ancaman yang berhasil.

---

## Technical Deep-Dive

### Langkah-Langkah Threat Modeling Praktis

Berikut adalah alur kerja yang dapat disesuaikan dengan metodologi pilihan:

1. **Menyiapkan Tim dan Scope**
   - Identifikasi pemangku kepentingan (dev, secops, product, compliance).
   - Tentukan batasan sistem yang akan dimodelkan (misalnya: hanya aplikasi web, atau termasuk API dan basis data).
   - Kumpulkan dokumen arsitektur: diagram komponen, alur data, infrastruktur cloud.

2. **Membuat Diagram Arsitektur (Data Flow Diagram - DFD)**
   - Gunakan simbol standar: proses, data store, aliran data, entitas eksternal.
   - Tampilkan trust boundary dengan garis putus-putus.
   - Contoh sederhana:
     ```
     +----------------+       HTTPS       +----------------+
     |   User (Ext)   | <---------------> |   Web App      |
     +----------------+                   +----------------+
		                                         |
		                                 +-------v-------+
		                                 |   API GW      |
		                                 +-------+-------+
		                                         |
		                             +-----------v-----------+
		                             |   Auth Service        |
			                          +-----------+-----------+
		                                         |
		                                 +-------v-------+
		                                 |   DB (Postgres) |
		                                 +---------------+
     ```

3. **Identifikasi dan Katalogkan Ancaman**
   - Untuk setiap elemen dalam DFD, tanya: “Apa yang bisa salah jika komponen ini diserang?”
   - Gunakan kartu kunci STRIDE atau daftar pertanyaan PASTA.
   - Hasil: daftar ancaman dengan ID, deskripsi, komponen yang terpengaruh, aliran data terkait, dan kategori.

4. **Analisis Kerentanan dan Dampak**
   - Hubungkan setiap ancaman dengan kerentanan yang ada (misalnya: SQL injection → kurangnya prepared statement).
   - Penilaian risiko menggunakan skor (misalnya: CVSS atau skala internal 1-5 untuk likelihood dan impact).
   - Dokumenkan asumsi dan keterbatasan data.

5. **Rancang dan Prioritaskan Mitigasi**
   - Untuk setiap risiko tinggi, pilih kontrol: preventive, detective, atau responsive.
   - Contoh mitigasi:
     - Spoofing → enforcing mutlai-factor authentication (MFA).
     - Tampering → implementasi tanda tangan digital atau hash integritas.
     - Information Disclosure → enkripsi data di transit dan at-rest.
   - Catat owner, target selesai, dan metrik verifikasi.

6. **Validasi dan Ulang**
   - Review hasil dengan tim pengembang dan keamanan.
   - Integrasikan ke dalam backlog sebagai user story atau ticket.
   story atau bug.
   - Periksa kembali ketika ada perubahan arsitektur signifikan (misalnya: migrasi ke micro-services, adopsi service mesh).

### Contoh Artefak

#### Threat Model Register (Tabel)

| Threat ID | Judul                       | Kategori STRIDE | Komponen Terpengaruh | Likelihood | Dampak | Skor Risiko | Status Mitigasi |
|-----------|-----------------------------|-----------------|----------------------|------------|--------|-------------|-----------------|
| TM-001    | SQL Injection di API        | Tampering       | API Gateway, DB      | Tinggi     | Krutis | 9           | Dalam Implementasi |
| TM-002    | Session Hijacking via XSS   | Spoofing        | Web App, Auth Service| Sedang     | Tinggi | 7           | Belum Ditangani |
| TM-003    | Kebocoran Kartu Kredit di Log| Info Disclosure | API Gateway, Payment | Sedang     | Krutis | 8           | Selesai         |
| TM-004    | Privilege Escalasi via BYOVD| Elevation of Privilege | OS Kernel   | Rendah     | Krutis | 6           | Direncanakan Q4 |

#### Contoh Aturan Sigma untuk Deteksi Upaya Exploitasi (berdasarkan threat model)

```yaml
title: Upaya SQL Injection melalui Parameter URI
id: 9a8b7c6d-5e4f-3a2b-1c0d-9f8e7d6c5b4a
status: eksperimental
logsource:
  produk: webserver
  layanan: apache
detection:
  selection:
    cs-uri-query: "| select|union|insert|update|delete|drop|--"
  condition: selection
level: tinggi
```

---

## Advanced

### Toolchain dan Otomatisasi

| Alat                     | Lisensi      | Fokus                      | Integrasi CI/CD | Catatan |
|--------------------------|--------------|----------------------------|-----------------|---------|
| Microsoft Threat Modeling Tool | Gratis (MIT) | STRIDE, DFD visual         | Via TMX export + skrip custom | GUI mudah, cocok untuk tim awal |
| OWASP Threat Dragon      | MIT          | STRIDE, LINDDUN, DFD       | CLI, JSON export | Open source, cross-platform |
| IriusRisk (Community)    | Freemium     | PASTA, risk-based, countermeasure | REST API, plugin Jenkins/GitLab | Versi terbatas tapi cukup untuk tim kecil |
| PyTM                     | Apache 2.0   | Python-as-code, threat modeling as code | GitHub Actions, pre‑commit | Mendefinisikan model sebagai kode Python |
| Threagile                | Apache 2.0   | Graf-based, risk-driven    | Docker, CLI     | Menghasilkan raportasi risiko otomatis |
| Microsoft Threat Modeling Extension for Azure DevOps | Gratis | Azure‑centric, work item tracking | Native Azure DevOps | Terkait langsung dengan backlog |

#### Contoh Penggunaan PyTM (Infrastructure as Code)

```python
# threatmodel.py
from pytm import TM, Server, Datastore, Actor, Boundary, Dataflow

tm = TM("Online Shop Threat Model")

user = Actor("User")
web = Server("Web Frontend")
web.inBoundary = Boundary("Internet")
db = Datastore("PostgreSQL DB")
db.inBoundary = Boundary("Internal Network")
api = Server("API Gateway")
api.inBoundary = Boundary("DMZ")

df1 = Dataflow(user, web, "HTTPS GET/POST")
df2 = Dataflow(web, api, "Internal REST")
df3 = Dataflow(api, db, "SQL Query")
df4 = Dataflow(db, api, "Query Result")

tm.process()
```

Jalankan dengan:
```bash
ptm threatmodel.py
```
Yang menghasilkan file `threatmodel.tm` dan `threatmodel.report.html`.

### Mengintegrasikan Threat Modeling ke dalam SDLC

- **Shift‑Left**: Mulai threat modeling pada tahap rancangan (fitur awal atau epic).
- **Definition of Done (DoD)**: Tambahkan “Threat model reviewed dan mitigasi tercatat” sebagai syarat untuk menyelesaikan user story.
- **Automated Regression**: Simpan model sebagai file versi‑kontrol (misalnya: `threatmodel.tmx`). Pada setiap perubahan arsitektur, jalankan skrip diff untuk mendeteksi drift.
- **Feedback Loop**: Hasil penetrasi tes atau incident post‑mortem harus digunakan untuk memperbaiki model (menambah ancaman baru, mengoreksi asumsi).

---

## Case Studies

| Studi Kasus | Konteksusun | Metodologi | Temuan Kunci | Mitigasi yang Diimplementasi |
|-------------|-----------|-----------|--------------|------------------------------|
| **E‑Commerce Platform (2023)** | Aplikasi web micro‑service + API gateway + DB terdistribusi | STRIDE + Attack Tree | 1. Insecure Direct Object Reference (IDOR) pada endpoint order/<id>. 2. Credential hard‑coded dalam CI vars. | 1. Implementasi objek level access control (OLAC). 2. Migrasi ke vault secret (HashiCorp Vault) dan rotasi otomatis. |
| **Sistem IoT Smart Meter (2022)** | Jaringan ratusan ribu meter berbasis LoRaWAN + backend cloud | PASTA + VAST | 1. Firmware tidak ditandatangani → risiko suplai rantai compromised. 2. Tidak ada mutal TLS antara meter dan concentrator. | 1. Code signing dengan ECDSA P‑256, verifikasi saat boot. 2. Deploy mutual TLS dengan sertifikat unik per device. |
| **Platform Pembayaran Digital (2024)** | Mobile app ↔ gateway ↔ processor eksternal (PCI‑DSS) | LINDDUN (privacy focus) + STRIDE | 1. Log debug mengirim PAN pertama 6 digit ke server analitik. 2. Tokenisasi tidak konsisten di caching layer. | 1. Penerapan masking pada tingkat ingestion log. 2. Penegakan tokenisasi konsisten dengan skrining bypass cache. |
| **Sistem Informasi Rumah Sakit (2021)** | EMR web-based + integrasi lab pihak ketiga | TRIKE + Threat Library | 1. Akses ke catatan pasien melalui parameter ID tanpa otorisasi berbasis role. 2. Transfer data lab menggunakan FTP tanpa enkripsi. | 1. Penerapan RBAC berbasis atribut (ABAC) dengan atribut departemen dan jam kerja. 2. Migrasi ke SFTP dengan kunci SSH dan audit harian. |

---

## Koneksi ke Vault

- [[comprehensive-threat-directory]] – taksonomi lengkap ancaman dan teknik eksploitasi.
- [[network-security]] – lapisan deteksi jaringan yang dapat mengawasi pola yang diprediksi dari threat model (misalnya: beaconing, tunneling).
- [[endpoint-security]] – mitigasi tingkat host (EDR, AV, HIPS) yang sesuai dengan mitigasi yang diidentifikasi.
- [[system-design]] – prinsip arsitektur yang memperlengan surface area yang aman (kemasan komponen, prinsip least privilege).
- [[devops]] – integrasi threat modeling ke dalam pipeline CI/CD (shift‑left devsecops).
- [[zero-trust-security]] – konsep zero trust yang dapat diturunkan dari prinsip never trust, always verify yang terwujud dalam threat modeling.

---

## Referensi

1. OWASP Foundation. *OWASP Testing Guide v4*. 2014. https://owasp.org/www-project-testing-guide/
2. Microsoft. *Threat Modeling Tool*. https://learn.microsoft.com/en-us/azure/security/develop/threat-modeling-tool
3. Shostack, Adam. *Threat Modeling: Designing for Security*. Wiley, 2014.
4. UcedaVelez, Alfredo & Marco M. Morana. *Risk Centric Threat Modeling: Process for Attack Simulation and Threat Analysis (PASTA)*. Wiley, 2015.
5. Carnegie Mellon University. *Security Engineering: A Guide to Building Dependable Distributed Systems*. 2003. (CAPEC, Attack Trees)
6. The MITRE Corporation. *Common Attack Pattern Enumeration and Classification (CAPEC)*. https://capec.mitre.org/
7. OWASP. *OWASP Threat Dragon*. https://owasp.org/www-project-threat-dragon/
8. Python Software Foundation. *PyTM – Python Threat Modeling*. https://pypi.org/project/pytm/
9. National Institute of Standards and Technology (NIST). *SP 800-30 Rev. 1: Guide for Conducting Risk Assessments*. 2012.
10. ISO/IEC 27005:2018 – Information technology — Security techniques — Information security risk management.

> [!tip] Bottom Line
> Threat modeling bukan sekadar dokumentasi satu kali; ini adalah praktik berkelanjutan yang harus diembed ke dalam budaya pengembangan dan operasi keamanan. Dengan memodelkan ancaman secara sistematis, tim dapat mengalihkan fokus dari *reactive patching* ke *preventive design*, mengurangi biaya mitigasi secara signifikan dan meningkatkan kepercayaan pemangku kepentingan terhadap keamanan produk.
---

audited
---
