---
title: Package Manager Hierarchy
tags:
  - library
  - platform-technologies
created: "2026-05-29"
updated: "2026-07-01"
status: operational
cssclasses: ""
---

# 📦 PACKAGE MANAGER HIERARCHY — Dari npm sampai Bun, pip sampai uv

> Package manager bukan hanya "tool untuk install library." Di baliknya ada: dependency resolution algorithm, lockfile format, content-addressable storage, virtual environment isolation, dan security supply chain. Memahami ini = memahami kenapa Bun 25x lebih cepat dari npm dan uv 100x lebih cepat dari pip.

> [!info] Konteks
> Ini langsung relevan untuk proyek Laravel (PHP/Composer), Next.js (Node/npm atau Bun), dan Python scripting yang sudah ada di vault. Pilihan package manager mempengaruhi CI/CD speed, disk usage, dan reproducibility.

---

## Daftar Isi

- [[#Mengapa Package Manager Adalah Masalah Sulit]]
- [[#Node.js Ecosystem — Evolusi dari npm sampai Bun]]
- [[#Python Ecosystem — Evolusi dari pip sampai uv]]
- [[#Bun — Deep Dive]]
- [[#uv — Deep Dive]]
- [[#Ekosistem Lain — Cargo, Go Modules, Composer]]
- [[#Decision Matrix]]

---

## Mengapa Package Manager Adalah Masalah Sulit

### Dependency Resolution — NP-Hard Problem

```
Bayangkan kamu install:
  Package A v1.0 → butuh Package C >= 2.0
  Package B v1.0 → butuh Package C >= 2.5 dan < 3.0
  Package D v1.0 → butuh Package C ~= 2.8 (compatible release)

Package manager harus find:
→ Versi C yang satisfy SEMUA constraint sekaligus
→ Jika tidak ada: error, atau compromise

Ini secara matematis adalah Boolean Satisfiability Problem (SAT)
→ NP-complete untuk kasus umum
→ Itulah kenapa dependency resolution bisa lambat dan tidak deterministik

Algoritma yang berbeda dipakai:
npm v1-2: greedy, bisa duplikat package (node_modules hell)
npm v3+:  flat tree, deduplicate
yarn:     SAT solver, reproducible via lockfile
pnpm:     content-addressable store + symlink, paling efisien
uv:       PubGrub algorithm (Rust), fastest currently known
```

### Dependency Hell — Masalah Nyata

```
NODE_MODULES HELL (sebelum pnpm):

project/
└── node_modules/
    ├── package-a/
    │   └── node_modules/
    │       └── lodash@4.0.0     ← copy 1
    ├── package-b/
    │   └── node_modules/
    │       └── lodash@4.0.0     ← copy 2 (identik!)
    └── package-c/
        └── node_modules/
            └── lodash@4.0.0     ← copy 3 (identik!)

Hasil: node_modules bisa 500MB untuk project sederhana
"heaviest object in the universe" = node_modules folder

DIAMOND DEPENDENCY (klasik):
        Your App
        /      \
    Pkg A      Pkg B
       \       /
     lodash@4  lodash@3
         ↑
     CONFLICT!
```

---

## Node.js Ecosystem — Evolusi dari npm sampai Bun

### Timeline & Apa yang Diperbaiki Setiap Iterasi

```
2010: npm (Node Package Manager)
├── Original, bundled dengan Node.js
├── Sequential install (satu per satu)
├── Non-deterministic: install dua kali = hasil berbeda
└── Masalah: lambat, tidak reproducible

2016: yarn (Facebook)
├── Parallel install: 2-3x lebih cepat dari npm
├── Lockfile (yarn.lock): reproducible install
├── Offline cache: tidak download ulang jika sudah ada
└── Masalah: masih node_modules, duplikasi masih ada

2017: npm v5 (respon ke yarn)
├── package-lock.json: lockfile seperti yarn
├── Lebih cepat tapi masih kalah dari yarn
└── Masalah: node_modules masih besar

2017: pnpm
├── Content-addressable store: satu file = satu copy di disk
├── Symlink ke global store (bukan copy)
├── 2-3x lebih cepat dari npm, lebih hemat disk
└── node_modules masih ada tapi jauh lebih kecil

2020: yarn berry (v2+) dengan PnP
├── Zero-installs: tidak perlu install sama sekali
├── Plug'n'Play: tidak ada node_modules!
├── Import dari .yarn/cache zip files langsung
└── Masalah: compatibility issue dengan beberapa package

2022: Bun
├── Runtime baru (bukan Node.js), package manager, bundler, test runner
├── Install 25x lebih cepat dari npm
└── Bukan hanya package manager — ini RUNTIME baru
```

### npm — Fondasi yang Harus Dipahami

```bash
# npm fundamental yang sering salah kaprah

# INSTALL
npm install              # Install dari package.json
npm install pkg          # Install + tambah ke dependencies
npm install -D pkg       # devDependencies (tidak di-bundle ke production)
npm install -g pkg       # Global install (hindari jika bisa)
npm ci                   # ← WAJIB di CI/CD! Install PERSIS dari lockfile

# npm ci vs npm install — PENTING:
# npm install: bisa update patch version, bisa ubah lockfile
# npm ci:      HANYA dari lockfile, gagal jika lockfile tidak sinkron
#              Lebih cepat, lebih reproducible, hapus node_modules dulu

# WORKSPACE (monorepo)
# package.json root:
{
  "workspaces": ["packages/*", "apps/*"]
}
npm install -w packages/ui    # Install di workspace spesifik
npm run build --workspaces    # Run di semua workspace

# SECURITY
npm audit                     # Cek vulnerability di dependencies
npm audit fix                 # Auto-fix yang bisa di-fix
npm audit fix --force         # Force major update (hati-hati breaking change)
npm outdated                  # Lihat package yang bisa di-update

# SCRIPTS
{
  "scripts": {
    "start": "node index.js",
    "dev": "nodemon index.js",
    "build": "tsc",
    "test": "jest",
    "prepare": "husky install",  # ← auto-run setelah npm install
    "prepublishOnly": "npm test" # ← auto-run sebelum npm publish
  }
}
```

### pnpm — Yang Seharusnya Kamu Pakai

```bash
# CARA KERJA pnpm:
# ~/.pnpm-store/ (global content-addressable store)
# └── v3/
#     └── files/
#         ├── 00/abc123...  ← setiap file disimpan sekali
#         ├── 01/def456...
#         └── ...
#
# project/node_modules/ (symlink ke store)
# └── .pnpm/
#     └── lodash@4.17.21/
#         └── node_modules/
#             └── lodash → ~/.pnpm-store/.../lodash  ← SYMLINK, bukan copy

# Install pnpm
npm install -g pnpm
# atau: corepack enable && corepack prepare pnpm@latest --activate

# SETUP PROJECT
pnpm init
pnpm add express         # dependencies
pnpm add -D typescript   # devDependencies
pnpm add -g pm2          # global

# WORKSPACE (monorepo) — pnpm-workspace.yaml
packages:
  - 'packages/*'
  - 'apps/*'

pnpm install             # Install semua workspace
pnpm -r run build        # Run build di semua package
pnpm --filter @myapp/ui build  # Run di package spesifik

# IMPORT DARI WORKSPACE
# package.json:
{
  "dependencies": {
    "@myapp/utils": "workspace:*"  # ← Link ke local package
  }
}

# BENCHMARK vs npm:
# Install 500 packages:
# npm:  120s
# yarn: 70s
# pnpm: 25s   (4.8x lebih cepat dari npm)
# bun:  8s    (15x lebih cepat dari npm)
```

---

## Python Ecosystem — Evolusi dari pip sampai uv

### Fragmentasi yang Membingungkan

```
MASALAH UNIK PYTHON: terlalu banyak tools, masing-masing solve subset masalah

MASALAH 1: Python version management
Tiap project butuh Python versi berbeda
→ Tools: pyenv, conda, asdf, mise, rtx

MASALAH 2: Virtual environment
Isolasi dependencies per project
→ Tools: venv (builtin), virtualenv, conda

MASALAH 3: Dependency management
Install, lock, resolve dependencies
→ Tools: pip, pip-tools, poetry, pipenv, pdm

MASALAH 4: Build & publish
Package project untuk PyPI
→ Tools: setuptools, build, flit, poetry, hatch

MASALAH 5: Script execution
Run script dengan dependencies inline
→ Tools: pipx, uvx

Sebelum uv: kamu butuh pyenv + venv + pip + pip-tools
            = 4 tools berbeda untuk masalah yang related

Setelah uv: uv handle SEMUA ini sekaligus
```

### pip + venv — Yang Wajib Dipahami Dulu

```bash
# VIRTUAL ENVIRONMENT — mengapa wajib
python -m venv .venv                    # Buat virtual environment
source .venv/bin/activate               # Linux/Mac
.\.venv\Scripts\activate                # Windows
pip install requests                    # Install ke venv, bukan global

# TANPA venv: pip install ke global Python
# → conflict antar project
# → "works on my machine" problem
# → tidak bisa isolasi versi berbeda

# pip fundamental
pip install requests==2.31.0            # Pin versi spesifik
pip install "requests>=2.28,<3.0"       # Version range
pip install -r requirements.txt         # Install dari file
pip freeze > requirements.txt           # Export yang terinstall

# MASALAH pip freeze:
# pip freeze output tidak membedakan:
# - Package yang kamu install langsung (direct dependency)
# - Package yang ter-install karena dependency lain (transitive)
# Solusi: pip-tools

# PIP-TOOLS — reproducible Python deps
pip install pip-tools

# requirements.in (hanya direct deps):
requests>=2.28
django>=4.2

# Generate lockfile:
pip-compile requirements.in             # → requirements.txt (pinned, dengan semua transitive)

# Install dari lockfile:
pip-sync requirements.txt
```

### Poetry — Sebelum uv Ada

```toml
# pyproject.toml (format standar modern)
[tool.poetry]
name = "my-project"
version = "0.1.0"
description = ""

[tool.poetry.dependencies]
python = "^3.11"
requests = "^2.31"
django = "^4.2"

[tool.poetry.group.dev.dependencies]
pytest = "^7.0"
black = "^23.0"
ruff = "^0.1"
```

```bash
poetry install          # Install + buat venv otomatis
poetry add requests     # Install + update pyproject.toml
poetry add -G dev pytest  # Dev dependency
poetry run python app.py  # Run dalam venv tanpa activate
poetry shell            # Aktivasi venv
poetry build            # Build package untuk publish
poetry publish          # Publish ke PyPI

# KELEBIHAN poetry:
# ✅ All-in-one: dependency + venv + build + publish
# ✅ pyproject.toml: format standar
# ✅ Lockfile (poetry.lock): reproducible
# ✅ Dependency groups (dev, test, docs terpisah)

# KEKURANGAN poetry:
# ❌ LAMBAT dibanding uv (Python-based, bukan Rust)
# ❌ Tidak mengelola Python version (butuh pyenv terpisah)
# ❌ Resolver kadang hang di project besar
# ❌ Ekosistem terpisah dari pip (kadang confusing)
```

---

## Bun — Deep Dive

### Bukan Hanya Package Manager

```
BUN = Runtime + Package Manager + Bundler + Test Runner + Transpiler
      Semuanya dalam satu binary (< 50MB)

DITULIS DALAM: Zig (bukan Rust!)
ENGINE: JavaScriptCore (Apple, sama yang dipakai Safari)
        bukan V8 (Chrome/Node.js)

MENGAPA Zig?
→ Zig punya kontrol memory sangat granular
→ Comptime (computation at compile time)
→ Bun bisa optimize per-platform saat compile
→ Lebih cepat dari Rust untuk beberapa workload I/O

MENGAPA JavaScriptCore?
→ JSC startup time jauh lebih cepat dari V8
→ JSC optimize berbeda dari V8 — bisa lebih cepat untuk some workloads
→ Tapi: V8 lebih battle-tested untuk server workload
```

### Kenapa Bun Install Lebih Cepat

```
BENCHMARK (install Next.js project dari scratch):
npm:   87 detik
yarn:  67 detik
pnpm:  23 detik
bun:    6 detik  ← ~14x lebih cepat dari npm

TIGA ALASAN TEKNIS:

1. SYMLINK STORAGE (mirip pnpm):
   ~/.bun/install/cache/
   → Satu file, satu copy di disk
   → Symlink ke project, bukan copy

2. PARALEL ASYNC I/O:
   npm: download satu per satu (atau beberapa)
   bun: download SEMUA package sekaligus
        extract SEMUA sekaligus
        resolve SEMUA sekaligus
        pakai Zig's async I/O primitives

3. BINARY LOCKFILE (bun.lockb):
   npm: package-lock.json (JSON, perlu parse text)
   bun: bun.lockb (binary format)
   → Baca lockfile = baca binary, jauh lebih cepat
   → Tapi: tidak human-readable (butuh bun convert)

   bun bun.lockb  # Lihat isi lockfile dalam format readable

4. NATIVE IMPLEMENTATION:
   npm: Node.js (JavaScript process manage JavaScript install)
   bun: Zig + NAPI (native code manage install)
   → Bun tidak punya overhead memulai JS engine untuk install
```

### Bun sebagai Runtime

```typescript
// bun run app.ts — langsung tanpa compile!
// TypeScript native, tidak perlu ts-node atau tsc

// Bun-specific APIs (tidak ada di Node.js):
const file = Bun.file("./data.json")
const json = await file.json() // ← built-in JSON file reader

// Bun.serve — HTTP server built-in
const server = Bun.serve({
  port: 3000,
  fetch(request: Request): Response {
    const url = new URL(request.url)

    if (url.pathname === "/") {
      return new Response("Hello World")
    }

    return new Response("Not Found", { status: 404 })
  },
})

// Bun Shell — run shell commands dari TypeScript
import { $ } from "bun"

const output = await $`ls -la`
console.log(output.text())

// Built-in SQLite
import { Database } from "bun:sqlite"

const db = new Database("mydb.sqlite")
const query = db.query("SELECT * FROM users WHERE id = $id")
const user = query.get({ $id: 1 })
```

### Bun: Compatibility dan Gotchas

```
COMPATIBILITY STATUS (2026):
✅ npm packages: 99%+ kompatibel
✅ package.json scripts
✅ Node.js core APIs (fs, path, http, crypto, dll)
✅ CommonJS dan ESM
✅ TypeScript, JSX native
✅ .env file loading otomatis

GOTCHAS:
⚠️ Beberapa native addon (N-API) mungkin tidak kompatibel
⚠️ JavaScriptCore vs V8: behavior edge case bisa berbeda
   → Kode yang bergantung pada V8-specific GC behavior: beware
⚠️ bun.lockb tidak human-readable
   → Sulit review di PR
   → Bun menyediakan: bun bun.lockb untuk print readable version
⚠️ Bun masih < 2 tahun mature — beberapa edge case belum tercover

KAPAN PAKAI BUN:
✅ New project yang tidak butuh Node.js strict compatibility
✅ Script dan tooling (build scripts, utilities)
✅ API server di mana startup time penting (serverless)
✅ CI/CD pipeline yang install npm packages (speed win)
✅ Full-stack TypeScript dengan Bun runtime

KAPAN TIDAK PAKAI BUN:
❌ Legacy project dengan native addons spesifik
❌ Production yang butuh battle-tested stability
❌ Team yang belum familiar (learning curve)
```

---

## uv — Deep Dive

### Dari Astral (Pembuat Ruff)

```
UV = Universal Python package + project manager
DITULIS DALAM: Rust (sama seperti Ruff linter)
PEMBUAT: Astral (Charlie Marsh dan tim)

Astral philosophy:
"Developer tooling yang bergerak dengan kecepatan bahasa sistem"
→ Ruff: linter 10-100x lebih cepat dari flake8/pylint
→ uv: package manager 10-100x lebih cepat dari pip

BENCHMARK (install PyTorch + deps dari scratch):
pip:    120 detik
poetry: 90 detik
uv:     8 detik  ← ~15x lebih cepat dari pip

BENCHMARK (resolusi cold cache):
pip:    45 detik
uv:     0.8 detik

APA YANG DI-REPLACE uv:
pip          → uv pip install / uv add
pip-tools    → uv pip compile
pyenv        → uv python install / uv python pin
virtualenv   → uv venv
pipx         → uvx (run tools tanpa install)
poetry       → uv add, uv run, uv build (sebagian)
```

### uv: Semua Perintah yang Perlu Diketahui

```bash
# ─── INSTALL UV ───────────────────────────────────────────────
curl -LsSf https://astral.sh/uv/install.sh | sh
# atau: pip install uv

# ─── PYTHON VERSION MANAGEMENT ────────────────────────────────
uv python install 3.12          # Download dan install Python 3.12
uv python install 3.11 3.12     # Install multiple
uv python list                  # Lihat Python yang tersedia
uv python pin 3.12              # Pin versi untuk project ini (.python-version)
uv run python --version         # Run dengan Python yang di-pin

# ─── PROJECT MANAGEMENT ───────────────────────────────────────
uv init my-project              # Buat project baru
cd my-project
uv add requests                 # Install + tambah ke pyproject.toml
uv add --dev pytest ruff        # Dev dependency
uv remove requests              # Hapus dependency
uv sync                         # Sync environment dengan pyproject.toml + lockfile
uv lock                         # Update lockfile tanpa install
uv run python app.py            # Run dalam project environment
uv run pytest                   # Run tool dalam environment

# ─── VIRTUAL ENVIRONMENT ──────────────────────────────────────
uv venv                         # Buat .venv di current directory
uv venv --python 3.11           # Dengan Python version spesifik
source .venv/bin/activate       # Activate (masih perlu untuk beberapa workflow)

# ─── PIP COMPATIBILITY ────────────────────────────────────────
# uv punya pip-compatible interface
uv pip install requests
uv pip install -r requirements.txt
uv pip freeze
uv pip compile requirements.in -o requirements.txt  # pip-tools compatible

# ─── GLOBAL TOOLS (pengganti pipx) ────────────────────────────
uvx ruff check .                # Run ruff tanpa install permanent
uvx black .                     # Run black tanpa install
uv tool install ruff            # Install sebagai global tool
uv tool list                    # Lihat installed tools

# ─── INLINE SCRIPT DEPENDENCIES (PEP 723) ─────────────────────
# Cara baru: dependencies di dalam script!
# script.py:
# /// script
# requires-python = ">=3.11"
# dependencies = [
#   "requests",
#   "rich",
# ]
# ///
# import requests
# from rich import print
# ...

uv run script.py    # uv install deps, run, cleanup — semuanya otomatis
```

### Kenapa uv Cepat — Mekanisme

```
ALASAN 1: PubGrub Resolution Algorithm (Rust implementation)
→ Algorithm dependency resolution terbaru (dikembangkan Dart/pub team)
→ Lebih efisien dari SAT solver yang dipakai poetry
→ Rust = zero-cost abstraction + no GC pause

ALASAN 2: Content-Addressable Cache
~/.cache/uv/
├── wheels/           ← compiled wheel cache per versi
│   └── sha256:abc123/
│       └── requests-2.31.0-py3-none-any.whl
└── archives/         ← source distribution cache
    └── sha256:def456/

→ Package yang pernah didownload TIDAK pernah didownload lagi
→ Hash-based: kalau hash sama, file pasti sama
→ Multi-project share cache: install di project berbeda = instant

ALASAN 3: Parallel Everything
→ Resolve dependencies: parallel
→ Download wheels: parallel
→ Install: parallel
→ Rust async (tokio) untuk I/O concurrent

ALASAN 4: Pre-built Wheels
→ PyPI menyediakan pre-built binary wheel untuk most packages
→ uv prioritaskan wheel over source distribution
→ Tidak perlu compile C extension jika wheel tersedia

ALASAN 5: Lazy Dependency Graph
→ Tidak download SEMUA package info dulu
→ Lazy evaluation: hanya fetch apa yang dibutuhkan untuk resolve
```

### uv: Compatibility

```
KOMPATIBEL DENGAN:
✅ pip (drop-in replacement untuk most commands)
✅ pyproject.toml (PEP 517/518/621)
✅ requirements.txt
✅ setup.py / setup.cfg (legacy)
✅ conda environments (sebagian)
✅ Virtual environments standard

TIDAK FULLY REPLACE:
⚠️ conda: uv tidak handle non-Python deps (CUDA, C libraries)
   → Data science dengan GPU: conda masih diperlukan
⚠️ poetry publishing: uv build ada tapi publish masih beta
⚠️ conda environment: uv tidak baca environment.yml

KETERBATASAN:
❌ Non-PyPI package source (custom registry: bisa tapi setup extra)
❌ Conda packages (hanya pip-compatible packages)
```

---

## Ekosistem Lain — Pembanding

### Rust: Cargo — Standar Emas

```bash
# Cargo = BUILT-IN ke Rust, bukan afterthought
# Ini yang membuat banyak developer Rust happy

cargo new my-project        # Init project
cargo build                 # Compile
cargo run                   # Build + run
cargo test                  # Test
cargo bench                 # Benchmark
cargo doc                   # Generate documentation
cargo publish               # Publish ke crates.io

# Cargo.toml — single source of truth:
[package]
name = "my-project"
version = "0.1.0"
edition = "2021"

[dependencies]
tokio = { version = "1", features = ["full"] }
serde = { version = "1", features = ["derive"] }

[dev-dependencies]
criterion = "0.5"  # Hanya untuk test/benchmark

# KENAPA CARGO DIANGGAP TERBAIK:
# ✅ Satu tool untuk semua (build, test, doc, publish)
# ✅ Reproducible via Cargo.lock
# ✅ Workspace untuk monorepo built-in
# ✅ Features system (conditional compilation)
# ✅ Tidak ada dependency hell (setiap crate bisa punya versi berbeda)
# ✅ Integrated dengan rustup (toolchain management)

# KETERBATASAN:
# Compile time Rust sangat lama (bukan masalah cargo, tapi bahasa)
# Incremental compile membantu tapi masih lama untuk project besar
```

### Go: Go Modules — Simpel tapi Opinionated

```bash
go mod init github.com/username/project
go get github.com/gin-gonic/gin@v1.9.0
go mod tidy      # hapus unused, download yang kurang
go mod download  # download semua deps tanpa install
go mod vendor    # vendoring: copy semua deps ke ./vendor

# go.mod — deklaratif:
module github.com/username/project
go 1.21

require (
    github.com/gin-gonic/gin v1.9.0
    github.com/stretchr/testify v1.8.4
)

# go.sum — lockfile (hash verification):
github.com/gin-gonic/gin v1.9.0 h1:ZAV...
github.com/gin-gonic/gin v1.9.0/go.mod h1:...

# KELEBIHAN:
# ✅ Built-in (tidak perlu install terpisah)
# ✅ Verifikasi hash (supply chain security)
# ✅ GOPATH dan module proxy (sum.golang.org)

# KEKURANGAN:
# ❌ Tidak ada version manager built-in (perlu asdf atau mise)
# ❌ Semantic versioning enforcement longgar
# ❌ Major version harus ganti import path (v2 = github.com/pkg/v2)
```

### PHP: Composer — Mature tapi Lambat

```bash
composer init                  # Init project
composer require laravel/framework  # Install
composer require --dev phpunit/phpunit
composer install               # Install dari composer.lock
composer update                # Update semua
composer dump-autoload         # Regenerate autoloader

# composer.json:
{
    "require": {
        "php": ">=8.1",
        "laravel/framework": "^10.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^10.0"
    },
    "autoload": {
        "psr-4": {
            "App\\": "app/"
        }
    }
}

# MASALAH COMPOSER:
# PHP-based = lambat (no Rust, no Zig)
# composer install di fresh: 30-60 detik untuk Laravel
# Solusi: composer install --prefer-dist --no-interaction (CI/CD flag)
```

---

## Decision Matrix

### Pilih Package Manager per Ekosistem

```
NODE.JS 2026:

New project:
├── Prefer Bun if:
│   → TypeScript-first
│   → Tidak butuh strict Node.js compat
│   → Speed is priority (CI/CD)
│   → Personal project / startup
│
├── Prefer pnpm if:
│   → Monorepo
│   → Team yang sudah familiar
│   → Butuh strict Node.js compat
│   → Enterprise dengan banyak package
│
└── Prefer npm if:
    → Simplicity utama
    → Semua developer familiar
    → Legacy project maintenance

PYTHON 2026:

New project:
└── uv (hampir semua kasus kecuali data science)

Data science / ML:
└── conda (atau mamba) untuk handle CUDA + sistem library

Legacy project:
├── Migrate ke uv jika mungkin
└── Tetap poetry/pip-tools jika ada custom workflow

Script one-off:
└── uvx atau uv run --with (PEP 723)
```

### Perbandingan Kecepatan — Semua Ekosistem

```
INSTALL SPEED BENCHMARK (fresh install, 100+ packages):

Node.js:
npm:   100% (baseline)
yarn:   65%
pnpm:   25%
bun:     7%  ← 14x lebih cepat dari npm

Python:
pip:   100% (baseline)
poetry: 85%
pdm:    70%
uv:      5%  ← 20x lebih cepat dari pip

Rust:
cargo:  — (compiled language, different category)
       Compile time: sangat lama
       Dependency download: mirip pnpm (content-addressable)

Go:
go get: cukup cepat (binary download, tidak compile deps)
```

### Pro/Con Summary Table

| Manager        | Speed           | Reliability      | DX               | Compatibility  | Maturity     |
| -------------- | --------------- | ---------------- | ---------------- | -------------- | ------------ |
| **npm**        | 🔴 Lambat       | ✅ Stabil        | ✅ Familiar      | ✅ Universal   | ✅ 15 tahun  |
| **pnpm**       | 🟡 Cepat        | ✅ Stabil        | ✅ Baik          | ✅ Baik        | ✅ 7 tahun   |
| **yarn berry** | 🟡 Cepat        | ⚠️ Kadang issues | ⚠️ Beda mindset  | ⚠️ Perlu check | 🟡 6 tahun   |
| **Bun**        | 🟢 Sangat cepat | ⚠️ Masih muda    | ✅ All-in-one    | ✅ 99%+        | ⚠️ 2 tahun   |
| **pip**        | 🔴 Lambat       | ✅ Stabil        | 🔴 Manual setup  | ✅ Universal   | ✅ 15+ tahun |
| **poetry**     | 🟡 OK           | ✅ Stabil        | ✅ Baik          | ✅ Baik        | ✅ 6 tahun   |
| **uv**         | 🟢 Sangat cepat | ✅ Stabil        | ✅ All-in-one    | ✅ pip-compat  | 🟡 1.5 tahun |
| **cargo**      | 🟢 Cepat        | ✅ Excellent     | ✅ Best-in-class | ✅ Native      | ✅ 11 tahun  |
| **go mod**     | 🟢 Cepat        | ✅ Stabil        | ✅ Simple        | ✅ Native      | ✅ 6 tahun   |

---

## Setup CI/CD yang Optimal

```yaml
# .github/workflows/ci.yml — dengan package manager caching

# NODE.JS dengan pnpm (recommended untuk production)
- name: Setup pnpm
  uses: pnpm/action-setup@v3
  with:
    version: 9

- name: Cache pnpm store
  uses: actions/cache@v4
  with:
    path: ~/.local/share/pnpm/store
    key: pnpm-${{ hashFiles('**/pnpm-lock.yaml') }}
    restore-keys: pnpm-

- name: Install dependencies
  run: pnpm install --frozen-lockfile # Equivalent npm ci

# NODE.JS dengan Bun (fastest CI)
- name: Setup Bun
  uses: oven-sh/setup-bun@v1
  with:
    bun-version: latest

- name: Cache Bun cache
  uses: actions/cache@v4
  with:
    path: ~/.bun/install/cache
    key: bun-${{ hashFiles('**/bun.lockb') }}

- name: Install
  run: bun install --frozen-lockfile

# PYTHON dengan uv (recommended)
- name: Install uv
  uses: astral-sh/setup-uv@v3
  with:
    enable-cache: true # Otomatis cache ~/.cache/uv

- name: Install Python
  run: uv python install 3.12

- name: Install dependencies
  run: uv sync --frozen # Equivalent pip-sync dari lockfile

- name: Run tests
  run: uv run pytest
```

---

> [!tip] Rekomendasi Konkret 2026
> **Node.js:** Mulai project baru → **Bun**. Existing project → **pnpm** untuk migration yang aman.
>
> **Python:** Apapun project barunya → **uv**. Tidak ada alasan untuk tidak migrasi kecuali conda/GPU dependency.
>
> Untuk portfolio kamu: ganti `npm install` di CI dengan Bun atau pnpm → CI time bisa turun 5-10 menit untuk project Next.js.

> [!warning] Jangan Over-Engineer
> Memilih package manager bukan architectural decision terbesar. Yang lebih penting: **lockfile selalu di-commit ke git** (reproducibility) dan **CI pakai `--frozen-lockfile` / `--locked`** (jangan biarkan CI update deps sendiri). Dua hal ini lebih penting dari pilihan antara npm, pnpm, atau Bun.

---

## 🔗 Lihat Juga

- [[cicd-shiftleft-shiftright|CI/CD Deep Dive]] — caching package manager di pipeline
- [[hierarchy-programming-language|Bahasa Pemrograman]] — konteks Zig (Bun) dan Rust (uv)
- [[api-protocols-deepdive|API Protocols]] — runtime yang di-serve oleh Bun
- [[platform-technologies-overview|Platform Technologies]] — WebAssembly target dari Bun
- [[master-index|Master Index]]

---

_Package Manager Hierarchy | npm → pnpm → Bun · pip → poetry → uv · Cargo · Go Modules · PubGrub · Content-Addressable Storage · CI Caching_
