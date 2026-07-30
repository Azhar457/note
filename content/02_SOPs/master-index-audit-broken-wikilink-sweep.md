---
title: "SOP — Vault Master-Index Audit & Broken Wikilink Sweep"
tags:
  - sop
  - vault-maintenance
  - wikilink
  - master-index
aliases:
  - "Master Index Audit SOP"
  - "Broken Wikilink Sweep"
created: "2026-07-19"
updated: "2026-07-19"
status: pending
---

> [!abstract] Ringkasan
> Prosedur audit berkala untuk master-index + sweeping broken wikilink + scanning stub `_index.md` setelah batch besar (rename, fuse folder, atau sync dari vault primer). Tujuannya: graph Obsidian tetap "existing files only", tidak ada link mati, dan setiap folder punya `_index.md` bermakna.

## Daftar Isi

1. [Kapan Jalankan SOP Ini](#kapan-jalankan-sop-ini)
2. [Pre-Requisites](#pre-requisites)
3. [Workflow](#workflow)
4. [Verifikasi](#verifikasi)
5. [Decision Framework — Broken Wikilink](#decision-framework--broken-wikilink)
6. [Pitfalls](#pitfalls)
7. [Catatan Terkait](#catatan-terkaitan)

---

## Kapan Jalankan SOP Ini

Trigger eksekusi:

- ✅ Setelah `sync_content.sh` pertama kali selesai dengan vault baru (fase on-boarding)
- ✅ Setelah batch rename / restructure folder (`kebab-case` → `snake_case` atau sebaliknya)
- ✅ Setelah fuse / merge folder duplicate (lihat [[Internet_Offline/_index|Internet_Offline]] & [[Kualitas_Perangkat_Lunak/_index|Kualitas_Perangkat_Lunak]])
- ✅ Setelah cron job deploy mingguan (kebiasaan hygiene — bukan wajib tapi sangat direkomendasikan)
- ❌ Jangan jalankan tiap push kecil — overhead > nilai

---

## Pre-Requisites

| Tool             | Gunanya                           | Versi Minimum    |
| ---------------- | --------------------------------- | ---------------- |
| `obsidian`       | Graph view + backlinks panel      | 1.5+             |
| `ripgrep` (`rg`) | Cari broken wikilink di semua .md | 13+              |
| `find` + `comm`  | Diff set link vs set file         | coreutils stdlib |
| `git`            | Diff vault primer vs content/     | 2.x              |

---

## Workflow

### Step 1 — Scan Semua Wikilink di Vault

```bash
cd /path/vault && \
  rg -oN '\[\[[^]]+\]\]' --type md | \
  sort -u > /tmp/all_wikilinks.txt && \
  echo "Total wikilink unik: $(wc -l < /tmp/all_wikilinks.txt)"
```

### Step 2 — Extract Basename + Alias Set

```bash
# Strip [[...]] wrapper
sed -i 's/^\[\[//; s/\]\]$//' /tmp/all_wikilinks.txt

# Beberapa quartz plugin gelar sticky path di nama file dulu, atau title alias—kita pakai 2 lookup strategy:
# A) Match exact basename (tanpa .md)
find /path/vault -name "*.md" -type f | \
  xargs -I{} basename {} .md > /tmp/all_files.txt
sort -u /tmp/all_files.txt -o /tmp/all_files.txt
```

### Step 3 — Scan Frontmatter `aliases:` untuk Resolve Alias

```bash
# Ambil semua alias dari frontmatter
find /path/vault -name "*.md" -type f -print0 | \
  xargs -0 awk '/^aliases:/,/^[^-]/{print}' | \
  grep -oE '"[^"]+"' | tr -d '"' | sort -u > /tmp/all_aliases.txt
```

### Step 4 — Diff: Detect Broken Links

```bash
# Gabungkan files + aliases sebagai "resolvable set"
cat /tmp/all_files.txt /tmp/all_aliases.txt | sort -u > /tmp/resolvable.txt

# Broken = wikilink yang tidak ada di files maupun aliases
comm -23 /tmp/all_wikilinks.txt /tmp/resolvable.txt > /tmp/broken_wikilinks.txt
wc -l /tmp/broken_wikilinks.txt
```

### Step 5 — Investigasi Tiap Broken Wikilink

Untuk setiap entry di `/tmp/broken_wikilinks.txt`, klasifikasikan:

| Kategori                | Contoh                                  | Tindakan                                        |
| ----------------------- | --------------------------------------- | ----------------------------------------------- |
| **Rename batch**        | nama lama → sudah di-rename permanen    | Patch semua referensinya                        |
| **Future planned**      | ATLAS refer sesuatu yang belum ditulis  | Buat stub note minimal + flag `status: planned` |
| **Typo / salah ketik**  | e.g. `azeure` (harusnya `azure`)        | Patch referensinya                              |
| **Old filename cached** | Quartz cache belum invalidate           | Clean `.quartz-cache/` dan rebuild              |
| **False positive**      | Plugin-generated path (e.g. `new-note`) | Abaikan jika memang internal template           |

### Step 6 — Audit `_index.md` per Folder

```bash
# Cari _index.md yang masih auto-generated template pendek (< 15 baris)
find /path/vault -name "_index.md" -type f | \
  xargs wc -l | \
  awk '$1 < 15 && $2 !~ /total/ {print}'
```

Untuk setiap yang < 15 baris:

1. Cek apakah folder punya catatan substantif. **Tidak** → **fusion / hapus folder**.
2. **Ya** → tulis `_index.md` proper dengan MOC description, stats line, dan file listing.

Format standar `_index.md` ada di [[template-note|Template Note]] — pattern: frontmatter + ringkasan + tabel Daftar Isi + deskripsi folder + link balik ke parent `_index`.

### Step 7 — Update Master-Index Atlas

Edit `00_Atlas/master-index.md`:

1. Tambah entry untuk catatan baru yang baru dibuat (Step 5 kategori "future planned" → "now created").
2. Hapus entry yang file-nya sudah dihapus.
3. Verifikasi semua `[[wikilink]]` di tabel masih resolve pakai Step 4-script ulang.

---

## Verifikasi

| Item                      | Expected                                          | Perintah                                                     |
| ------------------------- | ------------------------------------------------- | ------------------------------------------------------------ |
| Broken wikilink           | 0 (atau hanya yang false-positive)                | `wc -l /tmp/broken_wikilinks.txt`                            |
| `_index.md` per folder    | Semua ≥ 15 baris                                  | `find … -name "_index.md" -exec wc -l {} \;`                 |
| Master-index resolve rate | 100%                                              | `rg '\[\[' content/00_Atlas/master-index.md` lalu run Step 4 |
| Graph view Obsidian       | Sort "existing files only", tidak ada orphan node | Manual di Obsidian sidebar                                   |

---

## Decision Framework — Broken Wikilink

Sama dengan policy 3-duplicate handling yang sudah ada di memory:

1. **Fusion (merge to existing note).** Kalau ada catatan dengan topik sama di folder berbeda → tulis ulang wikilink menunjuk ke existing + hapus duplikat.
2. **Hilangkan.** Kalau broken link berasal dari folder stub (seperti [[Internet_Offline/_index|Internet_Offline]] atau [[Kualitas_Perangkat_Lunak/_index|Kualitas_Perangkat_Lunak]]) → ganti `_index.md` jadi redirect-stub yang refer ke lokasi baru, jangan create duplikat.
3. **Biarkan.** Kalau konteks cukup beda dan catatan baru akan deep-dive, tulis stub note dengan `aliases: ["broken-link-as-alias"]` + flag `status: planned`.

---

## Pitfalls

1. **Quartz cache stale.** Walau file sudah ditambah, Quartz cache `.quartz-cache/` lama masih serve broken link. Solusi: `rm -rf .quartz-cache && npx quartz build` sebelum verifikasi.
2. **Wikilink dengan path prefix.** `[[folder/note]]` vs `[[note]]` keduanya valid tapi Quartz prefer basename untuk graph lookup. Path-prefixed kadang "magically hilang" di graph.
3. **Alias dengan spasi / special char.** Alias di frontmatter harus quoted `"…"`. Alias tanpa tanda kutip di YAML list akan ditolak oleh parser.
4. **Frontmatter YAML indent.** `aliases:` harus di level 0 (top level), bukan nested di `metadata:`. Cek dengan `head -5 file.md`.
5. **Cron-deploy overwrite.** Karena `quartz sync` overwrite `_index.md` di content/, fix struktural harus di vault primer (`/mnt/data_d/Documents/Wide Note/Note`), bukan di `azhar457.github.io[note]/note/content/`.

---

## Catatan Terkait

- [[se-learning-path-moc]] — MOC yang refer stub folders Internet_Offline & Kualitas_Perangkat_Lunak
- [[Internet_Offline/_index|Internet_Offline Index]] — contoh stub konsolidasi
- [[Kualitas_Perangkat_Lunak/_index|Kualitas_Perangkat Lunak Index]] — contoh stub konsolidasi
- [[master-index]] — Atlas central yang sering berubah, wajib sweep tiap edit besar
- [[quartz-setup-windows|SOP Quartz Setup Windows]]
- [[02_SOPs/vault-routine|Vault Maintenance Routine (parent)]]
