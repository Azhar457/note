---
title: Cicd Shiftleft Shiftright
tags:
- devops
- library
created: '2026-05-29'
updated: '2026-07-01'
status: pending
cssclasses: ''
---

# ⚙️ CI/CD — Deep Dive: Shift Left ↔ Shift Right

> **Satu kalimat dari Red Hat:** *"To shift left is to test early. To shift right is to test in production."*
> 
> **Yang Red Hat tidak bilang:** Keduanya adalah dua sisi dari satu strategi — dan pipeline yang tidak mengimplementasikan keduanya secara bersamaan adalah pipeline yang incomplete. Dokumen ini bedah **mekanisme teknis**, bukan definisi.

> [!info] Konteks
> Topik ini langsung relevan untuk internship DevOps. Penggunaan CI/CD untuk deployment internal. Paham konsep ini = paham cara infrastructure bekerja dari code commit sampai production.

---

## Mental Model Pertama — SDLC sebagai Garis Waktu

```
TRADITIONAL SDLC (Waterfall, testing di akhir):

Code → Build → [TEST disini saja] → Stage → Deploy → Production
  ←←←←←←←←←←←←←←←←←←←←←←←←←←←←←←
  Bug ditemukan di production = sangat mahal untuk fix
  
MODERN SDLC (Shift Left + Shift Right):

◄─────────────── SHIFT LEFT ────────────────► ◄──── SHIFT RIGHT ────►
│                                             │                       │
Code → SAST → Build → Unit Test → DAST → Stage → Deploy → Prod Monitor
  │       │       │        │         │       │        │         │
  │      Lint   Image    Integr.   API     Load    Smoke     Chaos
  │      SBOM   Scan     Test     Scan    Test    Test      Engineering
  │                                                          Real-user
  │                                                          Metrics
  └──────────────────────────────────────────────────────────┘
                    FAIL FAST, FAIL SMALL
                    Bug ditemukan lebih awal = jauh lebih murah
```

---

## Bagian 1 — CI: Continuous Integration

### Apa yang Sebenarnya Terjadi

```
SEBELUM CI (masalah yang diselesaikan):

Developer A dan B bekerja di feature berbeda selama 2 minggu
→ Hari "merge": gabungkan kode
→ Konflik besar: satu mengubah function yang yang lain juga ubah
→ 2 hari debugging untuk "merge day" saja
→ Disebut "merge hell" atau "integration hell"

DENGAN CI:

Developer commit ke shared branch setiap hari (atau lebih sering)
→ Setiap commit → trigger automated pipeline
→ Pipeline cek: apakah perubahan ini break sesuatu?
→ Jika YA: developer tahu dalam hitungan menit, bukan minggu
→ Fix kecil, bukan refactor besar
```

### Anatomy Pipeline CI yang Sesungguhnya

```yaml
# .github/workflows/ci.yml — Contoh GitHub Actions
# Ini yang jalan setiap kali developer push code

```
```
name: CI Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  # ─── STAGE 1: SHIFT LEFT — Static Analysis (sebelum build) ───────────
  static-analysis:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 1a. Linting — cek syntax dan style
      - name: Run ESLint / Flake8
        run: |
          pip install flake8
          flake8 . --max-line-length=100

      # 1b. SAST — Static Application Security Testing
      # Cari vulnerability di source code sebelum dijalankan
      - name: SAST with Semgrep
        uses: semgrep/semgrep-action@v1
        with:
          config: >-
            p/owasp-top-ten
            p/secrets
            p/sql-injection

      # 1c. Secret Detection — jangan sampai API key masuk ke repo
      - name: Detect Secrets
        uses: trufflesecurity/trufflehog@main
        with:
          path: ./
          base: ${{ github.event.repository.default_branch }}

      # 1d. Dependency check — apakah library yang dipakai punya CVE?
      - name: Check Dependencies (SCA)
        run: |
          pip install safety
          safety check -r requirements.txt

  # ─── STAGE 2: BUILD ──────────────────────────────────────────────────
  build:
    needs: static-analysis  # Hanya jalan jika STAGE 1 sukses
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build Docker Image
        run: docker build -t app:${{ github.sha }} .

      # 2a. Container Image Scanning
      # Cek vulnerability di base image dan installed packages
      - name: Scan Container Image with Trivy
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'app:${{ github.sha }}'
          format: 'table'
          exit-code: '1'        # ← Fail pipeline jika ada CRITICAL vuln
          severity: 'CRITICAL,HIGH'

      # 2b. Generate SBOM (Software Bill of Materials)
      # Daftar semua dependency yang ada di image
      - name: Generate SBOM
        run: |
          syft app:${{ github.sha }} -o spdx-json > sbom.json

      - name: Upload Image
        run: docker push registry.example.com/app:${{ github.sha }}

  # ─── STAGE 3: TEST ───────────────────────────────────────────────────
  test:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 3a. Unit Test
      - name: Run Unit Tests
        run: |
          pytest tests/unit/ -v --cov=app --cov-report=xml
          # Jika coverage < 80%, pipeline gagal
          
      - name: Check Coverage Threshold
        run: |
          coverage report --fail-under=80

      # 3b. Integration Test
      - name: Run Integration Tests
        run: |
          docker-compose up -d  # Start database, cache, dependencies
          pytest tests/integration/ -v
          docker-compose down

      # 3c. DAST — Dynamic Application Security Testing
      # Test aplikasi yang sedang BERJALAN, bukan source code
      - name: DAST with OWASP ZAP
        uses: zaproxy/action-baseline@v0.10.0
        with:
          target: 'http://localhost:8080'
          # Scan: XSS, SQLi, CSRF, Broken Auth, etc.
          # Terhadap aplikasi yang sedang berjalan

  # ─── STAGE 4: SECURITY GATE ──────────────────────────────────────────
  security-gate:
    needs: [static-analysis, build, test]
    runs-on: ubuntu-latest
    steps:
      # Policy check: apakah semua security requirement terpenuhi?
      - name: Evaluate Security Policy
        uses: open-policy-agent/conftest-action@main
        with:
          policy: 'policy/security.rego'
          files: 'sbom.json'
          # Contoh policy: tidak boleh ada library dengan license GPL
          #                tidak boleh ada CVE CVSS > 9.0
          #                semua image harus signed
          
```

### Tiga Level Testing di CI

```
UNIT TEST:
→ Test satu function/class secara isolated
→ Dependency di-mock (simulasi)
→ Cepat: milliseconds per test
→ Jika gagal: developer tahu persis baris mana yang rusak
→ Coverage target: 70-80% minimum

INTEGRATION TEST:
→ Test interaksi antar komponen
→ Pakai database nyata (tapi test DB, bukan production)
→ Lebih lambat: detik sampai menit
→ Jika gagal: tahu sistem mana yang tidak berkomunikasi dengan benar

END-TO-END (E2E) TEST:
→ Test full user flow dari browser ke database
→ Tools: Selenium, Playwright, Cypress
→ Paling lambat: menit sampai puluhan menit
→ Jika gagal: tahu user journey mana yang rusak
→ Biasanya hanya critical path yang di-E2E test (bukan semua)
```

---

## Bagian 2 — Shift Left: Testing Lebih Awal

### Kenapa "Shift Left" Bukan Sekadar Buzzword

```
Cost of Bug Discovery (IBM Systems Sciences Institute):

Phase Ditemukan          | Biaya Fix (relatif)
─────────────────────────┼──────────────────────
Requirements             | $1
Design                   | $6
Development (coding)     | $25
Unit/Integration Testing | $75
Beta / Acceptance Test   | $100
Production               | $500 - $10,000+

[Keyakinan sedang] — angka bervariasi per sumber,
tapi trend-nya konsisten dan widely cited

Implikasi:
→ Bug yang ditemukan saat developer masih nulis kode:
  fix = ubah beberapa baris, 10 menit
→ Bug yang sama ditemukan di production:
  investigasi (jam) + hotfix + deploy + potential downtime
  + customer impact + incident report = bisa berhari-hari
```

### Teknik Shift Left yang Sering Diabaikan

**Threat Modeling (sebelum nulis kode)**

```
Bukan testing tool — ini PROSES berpikir sebelum mulai coding

Framework STRIDE:
S - Spoofing        (penyamaran identitas)
T - Tampering       (modifikasi data)
R - Repudiation     (menolak acknowledge action)
I - Information     (kebocoran informasi)
D - Denial of       (denial of service)
    Service
E - Elevation of    (privilege escalation)
    Privilege

Proses:
1. Buat diagram sistem (DFD - Data Flow Diagram)
2. Untuk setiap komponen dan data flow: terapkan STRIDE
3. Untuk setiap ancaman yang ditemukan: tentukan mitigasi
4. Dokumentasikan keputusan

Contoh:
"Endpoint POST /login" → Threat: Brute force (DoS category)
→ Mitigasi: Rate limiting + CAPTCHA + account lockout
→ Implement SEBELUM nulis kode endpoint tersebut

Tools: OWASP Threat Dragon, Microsoft Threat Modeling Tool
```

**SAST — Static Application Security Testing**

```
CARA KERJA:
Analisis source code / bytecode / binary TANPA menjalankan aplikasi
→ Pattern matching + data flow analysis
→ "Apakah user input ini bisa sampai ke SQL query tanpa sanitasi?"

APA YANG BISA DIDETEKSI:
✅ SQL Injection pattern
✅ Hardcoded secrets / API keys
✅ XSS vulnerability
✅ Insecure crypto (MD5, SHA1 untuk password)
✅ Path traversal
✅ Command injection

APA YANG TIDAK BISA DIDETEKSI:
❌ Vulnerability yang hanya muncul saat runtime
❌ Third-party API behavior
❌ Configuration issues
❌ Business logic flaws

TOOLS:
Gratis/Open Source:
→ Semgrep (300+ rule, multiple language)
→ Bandit (Python spesifik)
→ SonarQube Community (Java, JS, Python, dll)
→ gosec (Go spesifik)
→ Brakeman (Ruby on Rails)

Commercial:
→ Checkmarx, Veracode, Fortify

FALSE POSITIVE PROBLEM:
SAST sering false positive (alarm palsu)
→ Developer alarm fatigue = abaikan semua alert
→ Solusi: tune ruleset, kategorikan severity, hanya fail pipeline untuk CRITICAL
```

**SCA — Software Composition Analysis**

```
Berbeda dari SAST. SCA fokus pada:
→ Library/dependency yang kamu gunakan (bukan kode kamu sendiri)
→ Apakah library ini punya known CVE?
→ Apakah license-nya compatible dengan project kamu?

Kenapa penting:
→ 90% modern application code = third-party libraries
→ npm install satu package kecil → bisa pull 100+ transitive dependencies
→ Log4Shell (2021): bug di Log4j library → 3 miliar device affected
→ XZ Utils backdoor (2024): library yang dipakai di mayoritas Linux distro

Tools:
→ Trivy (Docker image + filesystem)
→ Grype (vulnerability scanning)
→ OWASP Dependency Check
→ Snyk (freemium, developer friendly)
→ GitHub Dependabot (built-in, gratis untuk public repo)

SBOM (Software Bill of Materials):
→ Dokumen yang list SEMUA component di software kamu
→ Seperti "daftar bahan makanan" untuk software
→ Wajib di beberapa regulasi (US Executive Order 14028)
→ Tools: Syft, CycloneDX
```

---

## Bagian 3 — CD: Continuous Delivery vs Deployment

### Perbedaan yang Sering Dikacaukan

```
CONTINUOUS DELIVERY:
                          MANUAL GATE
Code → CI Pipeline → Staging → [Manusia approve] → Production

"Kode selalu siap deploy, tapi deploy = keputusan manusia"
→ Cocok untuk: regulated industry, high-stakes deployment
→ Contoh: bank tidak mau auto-deploy ke production
→ Manusia tetap punya last say

CONTINUOUS DEPLOYMENT:
                          OTOMATIS
Code → CI Pipeline → Staging → [Automated tests] → Production

"Jika semua test hijau, langsung ke production"
→ Cocok untuk: web service, startup, high deployment frequency
→ Contoh: Netflix deploy ribuan kali per hari
→ Tidak ada gate selain automated testing
→ BUTUH: test suite yang sangat mature dan dipercaya
```

### Deployment Strategies — Cara Deploy yang Aman

**Blue-Green Deployment**

```
ARSITEKTUR:

Load Balancer
      │
   ┌──┴──┐
   │     │
[BLUE] [GREEN]
v1.0   v1.1 ← versi baru di-deploy di sini dulu
  ↑
100% traffic

PROSES:
1. Production = Blue (v1.0) → handle 100% traffic
2. Deploy v1.1 ke Green (idle)
3. Test Green: smoke test, health check, sanity check
4. Jika sukses: switch Load Balancer → Green handle 100% traffic
5. Blue tetap standby
6. Jika ada masalah di Green: switch kembali ke Blue (rollback instan)
7. Setelah yakin Green stable: Blue bisa di-update atau dimatikan

KELEBIHAN:
→ Rollback instan (flip switch)
→ Zero downtime deployment
→ Bisa test environment production sebelum live

KEKURANGAN:
→ Butuh 2x resources
→ Database migration bisa complex (harus backward compatible)
```

**Canary Deployment**

```
ARSITEKTUR:

Load Balancer
      │
   ┌──┴────────────┐
   │               │
[Stable v1.0]  [Canary v1.1]
 95% traffic    5% traffic ← hanya sebagian kecil user

PROSES:
1. Deploy v1.1 ke subset kecil instance (5%)
2. Monitor: error rate, latency, user behavior di canary
3. Jika metrics bagus: tingkatkan traffic ke canary (5% → 20% → 50% → 100%)
4. Jika ada masalah: routing kembali 100% ke stable, fix, ulang

KELEBIHAN:
→ Ekspos risiko ke sebagian kecil user dulu
→ Real-world testing dengan traffic nyata
→ A/B testing bisa dilakukan di sini

KEKURANGAN:
→ Monitoring yang kuat = syarat mutlak
→ Lebih complex dari blue-green
→ Duration lebih panjang (hours sampai days untuk rollout penuh)

TOOLS: Argo Rollouts, Flagger (Kubernetes-native)
```

**Feature Flags (Feature Toggles)**

```
KONSEP:
Kode di-deploy ke production tapi feature di-disable via flag
→ Flag = switch yang bisa di-toggle tanpa deploy ulang

CONTOH KODE:
if (featureFlags.isEnabled("new-payment-flow", userId)) {
    return newPaymentFlow(order);
} else {
    return legacyPaymentFlow(order);
}

USE CASES:
→ Deploy incomplete feature (dark launch) — ada di production, tidak visible
→ Gradual rollout per user segment (A/B test)
→ Kill switch: matikan feature bermasalah tanpa rollback deploy
→ Beta testing: enable hanya untuk internal user dulu

TOOLS: LaunchDarkly, Unleash (self-hosted), Flagsmith, PostHog
```

---

## Bagian 4 — Shift Right: Testing di Production

### Mengapa Production ≠ Staging

```
MASALAH FUNDAMENTAL:
Staging tidak pernah 100% sama dengan production karena:

1. Data volume berbeda
   Staging: 1000 record test
   Production: 10 juta record nyata
   → Query yang cepat di staging bisa lambat di production

2. Traffic pattern berbeda
   Staging: satu QA engineer test sequential
   Production: 10.000 user concurrent, pola tidak predictable
   → Race condition yang tidak muncul di staging

3. Third-party service behavior berbeda
   Staging: mock payment gateway → selalu success
   Production: real payment gateway → timeout, partial failure, rate limit

4. Infrastructure berbeda (subtly)
   Staging: 1 node
   Production: 50 nodes + load balancer + CDN + cache cluster
   → Distributed system bugs tidak muncul di single node

IMPLIKASI:
Shift right = testing NYATA di environment NYATA dengan user NYATA
(tapi dengan safety net dan controlled exposure)
```

### Chaos Engineering — "Break Things on Purpose"

```
FILOSOFI:
"If a system is going to fail, better to discover it in a controlled
 experiment than during peak traffic on Friday night."
                                          — Netflix SRE team

PRINSIP:
1. Define "steady state" — apa normal metric sistem?
2. Hypothesize: "jika kita inject X, sistem akan tetap normal"
3. Inject chaos: kill instance, inject latency, drop network
4. Observe: apakah sistem recover? berapa lama?
5. Fix weakness yang ditemukan

HIERARCHY CHAOS EXPERIMENT:

Level 1 — Instance/Process level:
→ Kill random pod/container
→ "Jika satu instance mati, sistem tetap serve user?"

Level 2 — Infrastructure level:
→ Simulate zone failure (availability zone down)
→ "Jika satu data center mati, sistem tetap jalan?"

Level 3 — Application level:
→ Inject latency ke dependency (database, external API)
→ "Jika payment gateway lambat 5 detik, apa yang terjadi?"
→ "Apakah circuit breaker aktif? Apakah user dapat feedback?"

Level 4 — Data level:
→ Corrupt data di sebagian node (untuk test data validation)
→ "Sistem bisa detect dan handle malformed data?"

Level 5 — Security level:
→ Simulate credential exposure
→ "Sistem detect dan respond ke unauthorized access pattern?"

TOOLS:
→ Chaos Monkey (Netflix) — kill random EC2 instance
→ Gremlin — managed chaos platform
→ Chaos Mesh (Kubernetes) — inject pod failure, network chaos
→ Pumba — Docker container chaos
→ LitmusChaos (open source, Kubernetes-native)
```

### Observability — Prerequisite untuk Shift Right

```
"You can't chaos engineer a system you can't observe"

TIGA PILAR OBSERVABILITY (disebut "Three Pillars"):

1. METRICS (angka agregat):
   → CPU usage, memory, request per second, error rate, latency (P50/P95/P99)
   → Tools: Prometheus + Grafana, Datadog, New Relic
   
   CONTOH ALERT:
   rule: HTTP 5xx rate > 1% untuk 5 menit → PagerDuty alert
   rule: P99 latency > 2 detik → Slack notification

2. LOGS (event detail):
   → Setiap request, setiap error, setiap state change
   → Tools: ELK Stack (Elasticsearch + Logstash + Kibana), Loki + Grafana
   
   STRUCTURED LOGGING (wajib untuk shift right):
   # BAD: log sebagai string biasa
   logger.info("User 12345 login from 192.168.1.1")
   
   # GOOD: log sebagai JSON yang bisa di-query
   logger.info({
     "event": "user_login",
     "user_id": 12345,
     "ip": "192.168.1.1",
     "timestamp": "2026-05-29T10:00:00Z",
     "latency_ms": 45
   })

3. TRACES (perjalanan satu request):
   → Satu request HTTP → bisa melewati 20 microservice
   → Trace tunjukkan: di service mana lambatnya? di mana error-nya?
   → Tools: Jaeger, Zipkin, Tempo (Grafana), OpenTelemetry
   
   CONTOH TRACE:
   Request /checkout (200ms total)
   ├── AuthService (5ms)
   ├── CartService (15ms)
   ├── PaymentService (150ms) ← BOTTLENECK!
   │   ├── ValidateCard (10ms)
   │   └── ChargeCard (140ms) ← external API call lambat
   └── NotificationService (30ms)
```

---

## Bagian 5 — Hubungan CI/CD + Shift Left/Right

### Unified Pipeline View

```
SDLC STAGE   │ PHASE        │ SHIFT      │ TECHNIQUE           │ TOOLS
─────────────┼──────────────┼────────────┼─────────────────────┼──────────────────────
Plan         │ Pre-code     │ Left ◄     │ Threat modeling     │ OWASP Threat Dragon
             │              │            │ Architecture review  │ ADR (Arch Decision)
─────────────┼──────────────┼────────────┼─────────────────────┼──────────────────────
Code         │ Development  │ Left ◄     │ IDE security plugin │ SonarLint, Semgrep
             │              │            │ Pre-commit hooks     │ Husky, pre-commit
             │              │            │ SAST                │ Semgrep, Bandit
─────────────┼──────────────┼────────────┼─────────────────────┼──────────────────────
Build        │ CI Pipeline  │ Left ◄     │ Container scan       │ Trivy, Grype
             │              │            │ SCA                 │ Snyk, Dependabot
             │              │            │ SBOM generation     │ Syft, CycloneDX
             │              │            │ Code signing        │ Sigstore/Cosign
─────────────┼──────────────┼────────────┼─────────────────────┼──────────────────────
Test         │ CI Pipeline  │ Left ◄     │ Unit test           │ pytest, Jest, JUnit
             │              │            │ Integration test     │ Testcontainers
             │              │            │ DAST                │ OWASP ZAP, Nuclei
             │              │            │ API security test   │ 42Crunch, Dredd
─────────────┼──────────────┼────────────┼─────────────────────┼──────────────────────
Deploy       │ CD Pipeline  │ Both ↔     │ Blue-green          │ Argo Rollouts
             │              │            │ Canary              │ Flagger
             │              │            │ Feature flags       │ Unleash, LaunchDarkly
             │              │            │ Smoke test          │ k6, Postman
─────────────┼──────────────┼────────────┼─────────────────────┼──────────────────────
Production   │ Runtime      │ Right ►    │ Chaos engineering   │ Chaos Mesh, Gremlin
             │              │            │ Real user monitoring│ Sentry, Datadog RUM
             │              │            │ SIEM                │ Splunk, Wazuh
             │              │            │ A/B testing         │ PostHog, Optimizely
             │              │            │ Observability       │ Prometheus+Grafana
```

### Cost vs Discovery Time

```
VISUALISASI KENAPA SHIFT LEFT MATTERS:

$10,000 ──►                                              ★ Production Bug
                                                         (incident, hotfix,
                                                          downtime, data loss)
 $1,000 ──►                              ★ Staging Bug
                                         (delay release,
                                          rework)
   $100 ──►               ★ Integration Test Bug
                           (fix dan run ulang test)
    $25 ──►    ★ Unit Test / SAST Bug
               (fix dan commit ulang)
     $1 ──►  ★ Code Review / Threat Model
               (ubah design sebelum implementasi)
              │         │         │         │
           Plan       Code      Test     Production
```

---

## Bagian 6 — Implementasi Pipeline Minimal yang Proper

### Untuk Project Personal / Freelance / Startup

```yaml
# .github/workflows/minimal-ci.yml
# Pipeline minimal tapi proper untuk project kecil
```
```
name: CI/CD

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      # 1. Dependency security check
      - name: Security audit
        run: |
          # Untuk Node.js:
          npm audit --audit-level=high
          # Untuk Python:
          # pip install safety && safety check

      # 2. SAST ringan
      - name: Semgrep scan
        uses: semgrep/semgrep-action@v1
        with:
          config: p/owasp-top-ten

      # 3. Build
      - name: Build
        run: docker build -t app:${{ github.sha }} .

      # 4. Unit Test
      - name: Test
        run: |
          docker run app:${{ github.sha }} pytest tests/unit/

      # 5. Deploy ke staging (hanya dari main)
      - name: Deploy to Staging
        if: github.ref == 'refs/heads/main'
        run: |
          # Push image
          docker push registry.example.com/app:${{ github.sha }}
          # Update deployment
          kubectl set image deployment/app \
            app=registry.example.com/app:${{ github.sha }}

      # 6. Smoke test setelah deploy
      - name: Smoke Test
        if: github.ref == 'refs/heads/main'
        run: |
          sleep 30  # Tunggu pod ready
          curl -f https://staging.example.com/health || exit 1
```

### Metrics yang Harus Dipantau

```
FOUR KEY METRICS (DORA Metrics — standar industri):

1. DEPLOYMENT FREQUENCY
   → Seberapa sering deploy ke production?
   → Elite: multiple per day
   → High: once per day - once per week
   → Medium: once per week - once per month
   → Low: once per month atau lebih jarang

2. LEAD TIME FOR CHANGES
   → Dari commit → production, berapa lama?
   → Elite: < 1 jam
   → High: < 1 hari
   → Medium: < 1 minggu
   → Low: > 1 minggu

3. CHANGE FAILURE RATE
   → Berapa persen deployment yang menyebabkan incident?
   → Elite: 0-15%
   → High: 16-30%
   → Medium/Low: > 30%

4. MEAN TIME TO RECOVERY (MTTR)
   → Jika ada incident, berapa lama sampai recovery?
   → Elite: < 1 jam
   → High: < 1 hari
   → Medium: < 1 minggu
   → Low: > 1 minggu

[Keyakinan tinggi] — ini adalah research-backed metrics dari Google DORA team
```

---

## Koneksi ke Vault

CI/CD adalah IMPLEMENTATION dari konsep yang sudah ada di vault:

[[cloud-infrastructure]] — Kubernetes deployment target
→ kubectl apply, Helm chart, Argo CD (GitOps)

[[system-design]] — Software Architecture patterns
→ Canary, Blue-Green adalah architectural decision

[[zero-taxonomy-security]] — Zero-Day dalam CI/CD
→ Supply chain attack (SolarWinds) menyerang CI/CD pipeline
→ CI/CD security = shift left untuk keamanan supply chain

[[ids-ips-waf-nsm-comparison]] — Tools yang diintegrasikan ke shift right
→ SIEM monitoring = shift right technique
→ WAF protection = runtime (shift right)

[[ebpf-kernel-security]] — Shift right observability
→ eBPF + Falco = runtime security monitoring (shift right)
→ Tetragon = policy enforcement at runtime

(DevOps):
→ Pipeline CI/CD kemungkinan: GitHub Actions atau GitLab CI
→ Container: Docker + mungkin Kubernetes
→ Monitoring: mungkin Prometheus + Grafana
→ Paham konsep ini = langsung produktif dari hari pertama

---

>[!tip] Tiga yang Paling Worth Dipraktikkan Sekarang
>Tanpa lab besar atau biaya:
>1. **GitHub Actions + Semgrep** — buat repo, setup pipeline CI basic dengan SAST. Gratis, 30 menit setup, langsung produksi skills yang dipakai di industri.
>2. **Trivy untuk container scanning** — install Docker + Trivy, scan image apa saja, lihat CVE yang ditemukan. `trivy image nginx:latest` — hasilnya mengejutkan.
>3. **Chaos Mesh di Minikube** — install Minikube (Kubernetes lokal), deploy app sederhana, inject pod failure, observe behavior. Skill chaos engineering masih sangat langka.

>[!warning] Anti-Pattern yang Sering Terjadi
>1. **Pipeline yang selalu green** = pipeline yang tidak useful (semua check di-skip atau threshold terlalu rendah)
>2. **Test hanya di staging** = tidak dapat feedback dari real-world behavior
>3. **Chaos engineering tanpa observability** = tidak tahu apa yang terjadi saat chaos diinjeksi
>4. **SAST tanpa tuning** = terlalu banyak false positive → developer abaikan semua alert

---

## 🔗 Lihat Juga

- [[cloud-infrastructure|Cloud Infrastructure]] — Kubernetes sebagai deployment target
- [[system-design|System Design]] — Architectural patterns (microservices, event-driven)
- [[zero-taxonomy-security|Zero Taxonomy]] — Supply chain attack via CI/CD pipeline
- [[ids-ips-waf-nsm-comparison|Security Tools]] — SIEM sebagai shift right technique
- [[ebpf-kernel-security|eBPF]] — Runtime observability (shift right foundation)
- [[master-index|Master Index]]

---

*CI/CD Deep Dive | Shift Left (SAST/DAST/SCA/Threat Model) · Shift Right (Chaos/Observability/Canary) · Pipeline Anatomy · DORA Metrics · DevSecOps*
---

audited
---
