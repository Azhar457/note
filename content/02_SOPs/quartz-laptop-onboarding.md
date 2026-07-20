---
title: "SOP — Vault Quartz Sync ke Laptop Baru (On-Boarding)"
tags:
  - sop
  - quartz
  - github-pages
  - vault
  - deployment
aliases:
  - "Quartz Laptop Onboarding"
  - "Vault Sync Setup"
  - "Laptop Baru Quartz"
created: "2026-07-19"
updated: "2026-07-19"
status: active
---

> [!abstract] Ringkasan
> SOP cepat untuk **on-boarding laptop ke-3 (atau ke-N)** sebagai node sinkronisasi vault primer → content/ → Quartz build → push GitHub Pages. Total durasi: 30-45 menit kalau semua prasyarat sudah siap. Bedanya dengan [[quartz-setup-windows]]: SOP itu tentang **bash-first Fedora/Linux** setup dari awal; SOP ini fokus **restore workflow sync deploy di laptop yang sudah punya repo** clone.

## Daftar Isi

1. [Kapan Pakai SOP Ini](#kapan-pakai-sop-ini)
2. [Prasyarat](#prasyarat)
3. [Alur 5 Langkah](#alur-5-langkah)
4. [Detail Setiap Langkah](#detail-setiap-langkah)
5. [Common Pitfalls](#common-pitfalls)
6. [Verifikasi Akhir](#verifikasi-akhir)
7. [Catatan Terkait](#catatan-terkaitan)

---

## Kapan Pakai SOP Ini

- ✅ Beli laptop baru (refurbished / cleared) → setup workflow cron sync deploy.
- ✅ Migrasi dari Termius-only ke laptop pribadi dengan Termius sebagai remote.
- ✅ Repositori Quartz sudah ada di GitHub (`Azhar457/note` v4 branch), tinggal clone ulang.
- ❌ Setup server Quartz dari zero di remote (lihat [[quartz-setup-windows]] lebih cocok).
- ❌ Clone vault primer (`/mnt/data_d/Documents/Wide Note/Note`) — itu pakai Obsidian Sync atau git remote beda.

---

## Prasyarat

| Tools/Asset            | Versi                                  | Path/Cara Dapatkan                                                        |
| ---------------------- | -------------------------------------- | ------------------------------------------------------------------------- |
| Node.js (system)       | v24 LTS (`24.18.0`)                    | `nvm install 24`; **bukan Hermes node v22**                               |
| nvm                    | 0.39+                                  | `curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash` |
| git                    | 2.x+                                   | `dnf install git` (Fedora) / `brew install git` (Mac)                     |
| SSH key                | Ed25519                                | `ssh-keygen -t ed25519 -C "laptop-azhar@urbansolv"`                       |
| GitHub PAT/SSH         | scope `repo` push                      | Settings → Developer settings → PAT (classic) atau upload SSH pubkey      |
| Repo `note` Quartz     | cloned @ branch `v4`                   | `git clone git@github.com:Azhar457/note.git`                              |
| Vault primer (mounted) | `/mnt/data_d/Documents/Wide Note/Note` | via sync client (Obsidian Sync / Syncthing)                               |
| Bash                   | 5.x                                    | Default di Fedora 44                                                      |

**Tahu ini penting:** `sync_content.sh` hard-coded `SOURCE` & `DEST`. Kalau path beda, edit dulu sebelum jalankan (lihat [[#Catatan Penting Path]]).

---

## Alur 5 Langkah

```
1. Clone repo Quartz ke laptop baru
2. Install toolchain: nvm + node v24 + dependencies
3. Mount atau pull vault primer ke path standard
4. Edit sync_content.sh kalau path beda
5. Test pipeline: sync → format → build → push
```

Tiap langkah verifikasi-nya terpisah — **jangan skip**.

---

## Detail Setiap Langkah

### Step 1 — Clone Repo Quartz

```bash
mkdir -p ~/Work && cd ~/Work && \
git clone git@github.com:Azhar457/note.git && \
cd note && \
git checkout v4 && \
git pull origin v4
```

Expected: branch tracking `v4`, working tree clean.

**Verify:**

```bash
git branch -vv
# * v4  a88d5f1 [origin/v4] Quartz sync: Jul 19, 2026, 10:36 PM
```

### Step 2 — Install Toolchain

```bash
# Install nvm kalau belum ada
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc

# Install node v24 (WAJIB system node, bukan Hermes internal)
nvm install 24
nvm use 24

# Verify
node --version    # v24.18.0 atau setara
npm --version     # 10.x

# Install dependency repo
cd ~/Work/note
npm install
```

**Penjelasan kenapa node v22 (bawaan Hermes) tidak boleh:** Build Quartz gagal dengan error `EBADENGINE` atau packet signature mismatch. Lihat [[02_SOPs/jarswaf-build-common-errors]] (planned) jika muncul error spesifik.

### Step 3 — Mount/Pull Vault Primer

Vault primer lokasinya beda-beda per device (lihat memory user: VPS1 pakai sync multi-device). Pilih salah satu:

**Opsi A — Obsidian Sync (jika sudah punya subscription):**

```
1. Install Obsidian di laptop baru
2. Login dengan akun yang punya vault "Note"
3. Aktifkan sync di Obsidian Settings → Sync
4. Tunggu first sync selesai (~5-15 menit)
5. Move vault ke /mnt/data_d/Documents/Wide Note/Note (sesuai path standard)
```

**Opsi B — Syncthing (self-hosted, free):**

```bash
# Install Syncthing di laptop baru
sudo dnf install syncthing
systemctl --user enable syncthing
systemctl --user start syncthing

# Di web UI (http://localhost:8384), add folder remote & share device ID
# Tunggu first sync
```

**Verify vault primer reachable:**

```bash
ls -la "/mnt/data_d/Documents/Wide Note/Note/00_Atlas/master-index.md"
# Expected: file ada, 0 errors
```

### Step 4 — Edit `sync_content.sh` (kalau path beda)

Buka `~/Work/note/scratch/sync_content.sh`, cari dua baris ini:

```bash
SOURCE="/mnt/data_d/Documents/Wide Note/Note"
DEST="/mnt/data_d/Desktop/Domain Website/azhar457.github.io[note]/note/content"
```

Edit jadi path lokal laptop baru:

```bash
SOURCE="/home/<user>/Documents/Wide Note/Note"
DEST="/home/<user>/Work/note/content"
```

**Catatan Penting Path:**

- `DEST` HARUS persis di dalam repo Quartz (folder `content/` ada di repo). Pattern `[note]` di nama folder adalah karakter valid bash (bracket di unix path) — JANGAN ganti jadi spasi, akan破坏 git.
- Pakai `realpath` untuk resolve symlink sebelum asign:

```bash
DEST="$(realpath ~/Work/note/content)"
```

### Step 5 — Test Pipeline Penuh

```bash
cd ~/Work/note
bash scratch/sync_content.sh
bash scratch/deploy-cron.sh
```

Pipeline sukses jika:

- ✅ `sync_content.sh` exit 0, log `[3] Done!`
- ✅ `deploy-cron.sh` → `[3/3] Syncing to GitHub Pages...` → `SUCCESS: Site deployed`
- ✅ Git log punya commit baru: `git log --oneline -1`

---

## Common Pitfalls

1. **Path `content/` salah sub-folder.** Sering orang buat `~/Work/note/scratch/content/` (di bawah `scratch/`). Itu salah — `content/` harus di root repo.
2. **Lupa `node` di PATH saat jalankan deploy-cron.sh.** Bisa result deploy sukses invoked Hermes node v22 instead of system v24 — build fail silently. Solusi: `deploy-cron.sh` sudah prepend PATH v24 di langkah `[1/3]`. Tapi kalau dipanggil manual, jalankan:

```bash
export PATH="/home/jars/.nvm/versions/node/v24.18.0/bin:$PATH"
npx quartz build
```

3. **Vault Sync belum selesai tapi `sync_content.sh` jalan.** Result: copy setengah file, broken render. Tunggu Obsidian Sync status "Up to date" dulu.
4. **SSH key bukan dari akun yang punya akses `Azhar457/note`.** `git push` ditolak. Cek `ssh -T git@github.com` → harus print `Hi Azhar457!`.
5. **`.obsidian/` dan `.trash/` ke-sync ke `content/`.** Lihat fix terbaru `sync_content.sh` (added `--exclude=".obsidian/"`, `.trash/`, `.DS_Store`, dst.). Kalau pakai script lama, exclude manual.

---

## Verifikasi Akhir

```bash
# Cek git state
cd ~/Work/note && git status
# Expected: clean working tree (no uncommitted changes), branch v4

# Cek vault primer
ls "/mnt/data_d/Documents/Wide Note/Note/00_Atlas/master-index.md"
sha256sum "$SOURCE/00_Atlas/master-index.md"  # Catat hash

# Cek content mirror
ls "$DEST/00_Atlas/master-index.md"
sha256sum "$DEST/00_Atlas/master-index.md"  # Harus sama

# Cek public/ build
ls public/ | head
test -f public/index.html && echo "✓ Homepage rendered"
test -f public/01_Library/index.html && echo "✓ Library index rendered"

# Cek remote push
git log origin/v4 --oneline -5
# Harus muncul commit dari cron job hari ini
```

---

## Catatan Terkait

- [[quartz-setup-windows|SOP Quartz Setup Windows]] — Setup awal (Windows, Bash WSL)
- [[master-index-audit-broken-wikilink-sweep|SOP Vault Audit]] — Kalau setelah deploy ada broken link
- [[podman-networking-ufw]] — Kalau perlu override container network buat testing lokal
- [[ansible-hardening-rocky-linux-9]] — Hardening laptop Fedora (script ini jalan di Fedora)
- [[inndex|Atlas Master-Index]] — Verifikasi rendering homepage post-deploy
