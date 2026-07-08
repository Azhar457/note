---
title: "Cicd Guide"
tags:
  - devops
  - library
aliases:
  - "cicd-guide"
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

# CI/CD Pipeline Guide 
> [!tip] Stack: Express + NestJS · Runner: Self-hosted (Ubuntu) · Container: Podman · DB: PostgreSQL/MySQL → Podman

---

## Daftar Isi
1. [Prerequisites & Deliverables](#1-prerequisites--deliverables)
2. [Branching Strategy](#2-branching-strategy)
3. [Secret Management](#3-secret-management)
4. [Self-Hosted Runner](#4-self-hosted-runner)
5. [CI Pipeline — Testing & Security](#5-ci-pipeline--testing--security)
6. [Containerization — Podman](#6-containerization--podman)
7. [Database Migration — Native ke Podman](#7-database-migration--native-ke-podman)
8. [CD Pipeline — Deployment](#8-cd-pipeline--deployment)
9. [Rollback Strategy](#9-rollback-strategy)
10. [Notifikasi & Alerting](#10-notifikasi--alerting)
11. [Master Checklist](#11-master-checklist)

---

## 1. Prerequisites & Deliverables

> [!tip] **Konvensi:** Setiap item diberi tag `[SKIP jika sudah ada]` atau `[WAJIB]`.

### 1.1 Di VM / VPS

| Tool | Cek | Install |
|---|---|---|
| Node.js LTS (≥20) | `node -v` | `nvm install --lts` |
| npm | `npm -v` | Ikut Node.js |
| Git | `git --version` | `apt install git` |
| Podman | `podman --version` | `apt install podman` |
| GitHub Actions Runner | `./svc.sh status` | Lihat §4 |
| PostgreSQL client | `psql --version` | `apt install postgresql-client` |

> [!tip] `[SKIP jika sudah ada]` — jangan reinstall jika versi sudah memenuhi syarat.

### 1.2 Di GitHub Repository

- [ ] Satu repo per project (bukan per orang)
- [ ] Branch `main` dan `develop` sudah ada
- [ ] GitHub Secrets sudah dikonfigurasi (lihat §3)
- [ ] Branch protection rules aktif (lihat §2)

---

## 2. Branching Strategy

### 2.1 Struktur Branch

```
main        → production only, deploy otomatis, strictly protected
develop     → integration, semua feature PR ke sini
feature/*   → pengerjaan fitur (ex: feature/auth-login)
fix/*       → bugfix (ex: fix/payment-null-error)
hotfix/*    → patch darurat langsung dari main
```

### 2.2 Naming Convention

```
feature/[nama-fitur-singkat]
fix/[nama-bug]
hotfix/[deskripsi-singkat]

# Contoh:
feature/user-authentication
fix/db-connection-timeout
hotfix/token-expiry-crash
```

### 2.3 Branch Protection Rules

Masuk: **GitHub Repo → Settings → Branches → Add rule**

**Untuk branch `main`:**
```
✅ Require pull request before merging
✅ Require approvals: 1
✅ Require status checks to pass (pilih: CI Pipeline)
✅ Require branches to be up to date before merging
✅ Include administrators
❌ Allow force pushes → OFF
❌ Allow deletions → OFF
```

**Untuk branch `develop`:**
```
✅ Require pull request before merging
✅ Require status checks to pass (pilih: CI Pipeline)
❌ Allow force pushes → OFF
```

---

## 3. Secret Management

> [!tip] **Aturan utama: TIDAK ADA kredensial di dalam kode atau file yang di-commit.**

### 3.1 GitHub Secrets

Masuk: **Repo → Settings → Secrets and variables → Actions → New repository secret**

| Secret Name | Isi |
|---|---|
| `DB_HOST` | IP atau hostname database |
| `DB_PORT` | Port database |
| `DB_NAME` | Nama database |
| `DB_USER` | Username database |
| `DB_PASSWORD` | Password database |
| `JWT_SECRET` | Secret untuk JWT |
| `DEPLOY_SSH_KEY` | Private key SSH ke VPS (jika CD via SSH) |

### 3.2 .env.example di Repo

Buat file `.env.example` di root repo (bukan `.env` — itu masuk `.gitignore`):

```env
# .env.example — Template saja, tanpa nilai asli
NODE_ENV=development
PORT=3000

DB_HOST=
DB_PORT=5432
DB_NAME=
DB_USER=
DB_PASSWORD=

JWT_SECRET=
JWT_EXPIRES_IN=7d
```

### 3.3 .gitignore Wajib Ada

```gitignore
# Environment
.env
.env.local
.env.production

# Dependencies
node_modules/

# Build
dist/
build/

# Logs
*.log
```

---

## 4. Self-Hosted Runner

### 4.1 Registrasi Runner ke Repo

```bash
# Di GitHub: Repo → Settings → Actions → Runners → New self-hosted runner
# Ikuti instruksi yang muncul, kemudian:

cd ~/actions-runner
./config.sh --url https://github.com/[org]/[repo] --token [TOKEN]
```

### 4.2 Jalankan sebagai Service (Auto-restart)

```bash
# Install sebagai systemd service
sudo ./svc.sh install
sudo ./svc.sh start

# Cek status
sudo ./svc.sh status

# Cek di GitHub: Settings → Actions → Runners → harusnya status "Idle"
```

### 4.3 Verifikasi Runner Online

```bash
# Dari GitHub Actions, cek apakah runner muncul dengan label:
# self-hosted, Linux, X64
```

> [!tip] **Catatan keamanan:** Self-hosted runner JANGAN dipasang di server production. Gunakan VM terpisah atau pastikan runner berjalan dengan user non-root yang permission-nya terbatas.

---

## 5. CI Pipeline — Testing & Security

### 5.1 File Pipeline

Simpan di: `.github/workflows/ci.yml`

```yaml
name: CI Pipeline

on:
  pull_request:
    branches: [main, develop]
  push:
    branches: [develop]

jobs:
  ci:
    name: Lint · Audit · Build · Test
    runs-on: self-hosted

    steps:
      # ── 1. CHECKOUT ──────────────────────────────────
      - name: Checkout code
        uses: actions/checkout@v4

      # ── 2. SETUP NODE ─────────────────────────────────
      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      # ── 3. DELIVERABLES / DEPENDENCIES ───────────────
      - name: Install dependencies
        run: npm ci
        # npm ci lebih strict dari npm install:
        # - Pakai package-lock.json, tidak modifikasi
        # - Fail jika lock file tidak sync

      # ── 4. LINT ───────────────────────────────────────
      - name: Lint
        run: npm run lint
        # Skip jika script belum ada di package.json:
        # run: npm run lint --if-present

      # ── 5. TYPE CHECK (NestJS / TypeScript only) ──────
      - name: Type check
        run: npx tsc --noEmit
        # Hapus step ini jika project adalah plain Express JS

      # ── 6. SECURITY AUDIT ─────────────────────────────
      - name: Security audit
        run: npm audit --audit-level=high
        # --audit-level=high: hanya fail jika ada vulnerability HIGH/CRITICAL
        # Ganti ke =moderate jika mau lebih strict
        continue-on-error: false

      # ── 7. BUILD CHECK ────────────────────────────────
      - name: Build
        run: npm run build
        env:
          NODE_ENV: test

      # ── 8. UNIT TEST ──────────────────────────────────
      - name: Run tests
        run: npm run test
        # Jika belum ada test sama sekali, comment step ini dulu
        # Jangan block PR karena test kosong
        env:
          NODE_ENV: test
          DB_HOST: ${{ secrets.DB_HOST }}
          DB_PORT: ${{ secrets.DB_PORT }}
          DB_NAME: ${{ secrets.DB_NAME }}
          DB_USER: ${{ secrets.DB_USER }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

### 5.2 Fallback Jika Pipeline Gagal

| Failure Point        | Tindakan                                                                                                     |
| -------------------- | ------------------------------------------------------------------------------------------------------------ |
| `npm ci` gagal       | Cek apakah `package-lock.json` di-commit. Jalankan `npm install` lokal lalu commit lock file.                |
| Lint gagal           | Fix di lokal dulu sebelum push ulang. PR tidak bisa merge.                                                   |
| `tsc --noEmit` gagal | Ada type error di kode. Harus difix, bukan di-skip.                                                          |
| `npm audit` gagal    | Jalankan `npm audit fix`. Jika tidak bisa auto-fix, review manual dan buat keputusan apakah acceptable risk. |
| Build gagal          | Cek error log di Actions. Biasanya import missing atau env var tidak tersedia.                               |
| Test gagal           | Lihat test output. Jangan merge sebelum test hijau.                                                          |
## 6. Containerization — Podman

### 6.1 Prinsip Utama

```
Buat container baru → Test → Verifikasi → Cutover → Shutdown yang lama
JANGAN langsung replace container yang sedang berjalan
```

### 6.2 Struktur File

```
project/
├── Containerfile          # Equivalent Dockerfile untuk Podman
├── podman-compose.yml     # Equivalent docker-compose
└── .github/
    └── workflows/
        └── cd.yml
```

### 6.3 Containerfile (NestJS)

```dockerfile
# Containerfile
FROM node:20-alpine AS builder

WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM node:20-alpine AS production

WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev
COPY --from=builder /app/dist ./dist

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### 6.4 podman-compose.yml

```yaml
version: '3.8'

services:
  backend:
    build: .
    container_name: yourvps-backend
    ports:
      - "3000:3000"
    env_file:
      - .env
    depends_on:
      - db
    restart: unless-stopped

  db:
    image: postgres:15-alpine
    container_name: yourvps-db
    environment:
      POSTGRES_DB: ${DB_NAME}
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    restart: unless-stopped

volumes:
  pgdata:
```

### 6.5 Update Versi — Zero Downtime Strategy

```bash
# 1. Build image baru dengan tag versi
podman build -t yourvps-backend:v2 .

# 2. Jalankan container BARU di port sementara (3001)
podman run -d \
  --name yourvps-backend-new \
  -p 3001:3000 \
  --env-file .env \
  yourvps-backend:v2

# 3. Test container baru
curl http://localhost:3001/health

# 4. Jika OK → stop yang lama, rename, start yang baru di port asli
podman stop yourvps-backend
podman rename yourvps-backend yourvps-backend-old

podman stop yourvps-backend-new
podman run -d \
  --name yourvps-backend \
  -p 3000:3000 \
  --env-file .env \
  yourvps-backend:v2

# 5. Verifikasi final
curl http://localhost:3000/health

# 6. Jika sudah aman (tunggu minimal 10 menit / 1 request cycle)
podman rm yourvps-backend-old
podman rmi yourvps-backend:v1
```

### 6.6 Jika Ada Masalah Setelah Cutover

```bash
# Rollback: hidupkan kembali container lama
podman stop yourvps-backend

podman run -d \
  --name yourvps-backend \
  -p 3000:3000 \
  --env-file .env \
  yourvps-backend:v1    # versi sebelumnya

# Cek log untuk investigasi
podman logs yourvps-backend-old
```

---

## 7. Database Migration — Native ke Podman

> [!tip] **Aturan: BACKUP DULU, baru sentuh apapun.**

### 7.1 Alur Migrasi

```
[1] Backup DB native
     ↓
[2] Spin up container DB baru (port berbeda)
     ↓
[3] Restore backup ke container
     ↓
[4] Test koneksi app ke container DB
     ↓
[5] Test query kritis (bukan hanya connect)
     ↓
[6] Cutover: arahkan app ke container DB
     ↓
[7] Monitor 1-2 hari
     ↓
[8] Jika aman → shutdown native DB
    Jika tidak → rollback ke native
```

### 7.2 Step 1 — Backup

```bash
# PostgreSQL
pg_dump -U [user] -h localhost [dbname] > backup_$(date +%Y%m%d_%H%M).sql

# MySQL
mysqldump -u [user] -p [dbname] > backup_$(date +%Y%m%d_%H%M).sql

# Simpan di lokasi aman, bukan di dalam folder project
cp backup_*.sql ~/db-backups/
```

### 7.3 Step 2-3 — Container Staging DB

```bash
# Jalankan container DB di port 5433 (bukan 5432 yang native)
podman run -d \
  --name db-staging \
  -e POSTGRES_DB=[dbname] \
  -e POSTGRES_USER=[user] \
  -e POSTGRES_PASSWORD=[pass] \
  -p 5433:5432 \
  -v pgdata-staging:/var/lib/postgresql/data \
  postgres:15-alpine

# Tunggu container ready
sleep 5

# Restore backup
cat backup_[tanggal].sql | podman exec -i db-staging \
  psql -U [user] [dbname]
```

### 7.4 Step 4-5 — Verifikasi

```bash
# Test koneksi dari app (ubah DB_PORT sementara ke 5433)
# Atau test manual:
psql -h localhost -p 5433 -U [user] -d [dbname]

# Query kritis yang WAJIB dicek sebelum cutover:
# - Jumlah rows di tabel utama (harus sama persis dengan native)
# - Query yang paling sering dipakai oleh aplikasi
# - Foreign key integrity
SELECT COUNT(*) FROM [tabel_utama];
```

### 7.5 Rollback Point

```bash
# Jika setelah cutover ada masalah:

# 1. Stop container DB
podman stop db-container-name

# 2. Kembalikan koneksi app ke native DB
# (edit .env: DB_PORT=5432, DB_HOST=localhost)

# 3. Restart app
podman restart yourvps-backend

# Native DB tidak pernah dimatikan selama proses ini — ini safety net-nya
```

---

## 8. CD Pipeline — Deployment

> [!tip] CD hanya berjalan jika CI sudah pass. Tidak ada deploy tanpa green pipeline.

### 8.1 File CD Pipeline

Simpan di: `.github/workflows/cd.yml`

```yaml
name: CD Pipeline

on:
  push:
    branches: [main]    # Hanya deploy ke production dari main

jobs:
  deploy:
    name: Build & Deploy
    runs-on: self-hosted
    needs: []           # Tambahkan job CI di sini jika dalam satu workflow

    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Build container image
        run: |
          podman build -t yourvps-backend:${{ github.sha }} .
          podman tag yourvps-backend:${{ github.sha }} yourvps-backend:latest

      - name: Run new container (staging port)
        run: |
          podman run -d \
            --name yourvps-backend-new \
            -p 3001:3000 \
            --env-file .env \
            yourvps-backend:${{ github.sha }}

      - name: Health check
        run: |
          sleep 5
          curl --fail http://localhost:3001/health || exit 1
        # Jika health check gagal, step ini fail dan deploy berhenti

      - name: Cutover
        run: |
          podman stop yourvps-backend || true
          podman rm yourvps-backend || true
          podman rename yourvps-backend-new yourvps-backend
          podman update --publish 3000:3000 yourvps-backend

      - name: Final verification
        run: |
          sleep 3
          curl --fail http://localhost:3000/health

      - name: Cleanup old images
        run: |
          podman image prune -f
```

### 8.2 Endpoint Health Check

Pastikan aplikasi punya endpoint `/health`:

```typescript
// NestJS
@Get('/health')
health() {
  return { status: 'ok', timestamp: new Date().toISOString() };
}
```

```javascript
// Express
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});
```

---

## 9. Rollback Strategy

### 9.1 Rollback Level 1 — Container (Deployment Gagal)

```bash
# Kembalikan ke image sebelumnya
podman stop yourvps-backend
podman rm yourvps-backend

podman run -d \
  --name yourvps-backend \
  -p 3000:3000 \
  --env-file .env \
  yourvps-backend:[SHA_COMMIT_SEBELUMNYA]
```

### 9.2 Rollback Level 2 — Git (Revert Code)

```bash
# Revert commit terakhir
git revert HEAD --no-edit
git push origin main

# Pipeline akan otomatis jalan dan deploy versi yang sudah di-revert
```

### 9.3 Rollback Level 3 — Database

```bash
# Gunakan backup yang dibuat sebelum migrasi
podman exec -i [container-db] \
  psql -U [user] [dbname] < ~/db-backups/backup_[tanggal].sql
```

### 9.4 Kapan Pakai Rollback Level Berapa

| Situasi | Level |
|---|---|
| Container crash setelah deploy | 1 |
| Bug kritis ditemukan setelah deploy | 1 atau 2 |
| Data corrupt setelah migrasi DB | 3 |
| Code logic error, tidak ada masalah data | 2 |

---

## 10. Notifikasi & Alerting

### 10.1 Notifikasi via GitHub Actions (Slack/Discord)

Tambahkan di akhir job CI/CD:

```yaml
      - name: Notify on failure
        if: failure()
        run: |
          curl -X POST ${{ secrets.DISCORD_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"content": "❌ Pipeline gagal di branch **${{ github.ref_name }}** — commit `${{ github.sha }}`"}'

      - name: Notify on success
        if: success()
        run: |
          curl -X POST ${{ secrets.DISCORD_WEBHOOK_URL }} \
            -H 'Content-Type: application/json' \
            -d '{"content": "✅ Deploy berhasil — branch **${{ github.ref_name }}**"}'
```

### 10.2 GitHub Actions Default Notifikasi

GitHub otomatis kirim email ke committer jika pipeline gagal. Pastikan email notifikasi aktif di:
**GitHub → Settings → Notifications → Actions**

---

## 11. Master Checklist

### Setup Awal
- [ ] Repo sudah konsolidasi (bukan per orang)
- [ ] Branch `main` dan `develop` ada
- [ ] `.gitignore` mencakup `.env` dan `node_modules`
- [ ] `.env.example` sudah ada di repo
- [ ] GitHub Secrets sudah diisi
- [ ] Self-hosted runner online dan terdaftar di repo
- [ ] Branch protection aktif untuk `main` dan `develop`

### CI Pipeline
- [ ] `ci.yml` sudah ada di `.github/workflows/`
- [ ] Lint berjalan tanpa error
- [ ] Build berhasil
- [ ] Security audit tidak ada HIGH/CRITICAL
- [ ] Pipeline fail → PR tidak bisa merge (branch protection enforce)

### Containerization
- [ ] `Containerfile` sudah dibuat dan tested lokal
- [ ] `podman-compose.yml` sudah dikonfigurasi
- [ ] Health check endpoint tersedia di aplikasi
- [ ] Strategi update versi sudah dipahami tim

### Database Migration
- [ ] Backup terakhir tersimpan di lokasi aman
- [ ] Container DB staging sudah ditest
- [ ] Query kritis sudah diverifikasi di staging
- [ ] Rollback plan sudah dikomunikasikan ke tim
- [ ] Native DB tetap hidup sampai 1-2 hari setelah cutover

### CD Pipeline
- [ ] `cd.yml` hanya trigger dari branch `main`
- [ ] Health check setelah deploy berjalan
- [ ] Rollback container bisa dilakukan dalam < 5 menit
- [ ] Tim tahu cara rollback manual jika pipeline CI/CD tidak tersedia

---

*Dokumen ini dibuat sebagai referensi kerja internal — update sesuai kondisi infrastructure yang berkembang.*
