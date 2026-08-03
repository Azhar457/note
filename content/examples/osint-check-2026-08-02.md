---
title: OSINT Check Session — 2026-08-02
tags: [osint, searchsploit, exploit-db, breach, privacy, audit, mcp]
aliases: [OSINT Check, Pengecekan Data Pribadi]
created: 2026-08-02
updated: 2026-08-02
status: complete
---

# 🔍 OSINT Check Session — 2026-08-02

> [!abstract] Ringkasan
> Session audit eksposur data pribadi (nama, nomor HP, email, NIK, afiliasi UNPAS) + setup searchsploit (Exploit-DB) terintegrasi ke Hermes via MCP. Dokumentasi ini mencatat **apa yang dilakukan, query apa yang dijalankan, temuan apa yang valid, dan verdict akhir** — termasuk deteksi API breach yang ternyata **tidak valid** (red flag penting).

---

## Daftar Isi
1. [[#1. Setup Searchsploit + Integrasi Hermes]]
2. [[#2. Query OSINT yang Dijalankan]]
3. [[#3. Temuan — Eksposur Publik]]
4. [[#4. Verdict — Breach Database & NIK]]
5. [[#5. Red Flag — API yang Tidak Valid]]
6. [[#6. Rekomendasi Mitigasi]]
7. [[#7. Audit Trail Sumber]]

---

## 1. Setup Searchsploit + Integrasi Hermes

| Item | Detail |
|:---|:---|
| Binary | `/opt/exploitdb/searchsploit` (symlink: `/usr/local/bin/searchsploit`) |
| Repo | `exploit-database/exploitdb` via **GitLab** (GitHub sempat block abuse) |
| Branch | `main` (bukan `master`) |
| Total exploits | **47.109** |
| MCP server | `~/.local/share/searchsploit-mcp/mcp_server.py` |
| Wrapper | `run.sh` (`env -u PYTHONPATH` — pola anti-conflict venv Hermes) |
| SDK | MCP 1.28.1 (v1 decorator `@server.list_tools` — BUKAN v2 `add_request_handler`) |
| Tools | `exploit_search`, `exploit_search_cve`, `exploit_read`, `exploit_db_status` |
| Registrasi | `~/.hermes/config.yaml` → `mcp_servers.searchsploit` (enabled) |
| Verifikasi | initialize + tools/list + tools/call — semua PASS ✅ |

**Pitfall yang ditemukan:**
- `--colour 0` → **illegal option** di versi searchsploit ini (dihapus dari args)
- `get_capabilities()` di MCP 1.28.1 butuh 2 argumen wajib: `notification_options` + `experimental_capabilities`
- Repo `JitPatro/searchsploit` (5 stars, stale 2023) ❌ — **bukan** yang resmi
- Default branch repo exploitdb adalah `main` — tarball `master.tar.gz` → 404

## 2. Query OSINT yang Dijalankan

Semua via SearXNG self-hosted (`127.0.0.1:8888`, format=json, UA Mozilla):

| # | Query | Hasil |
|:---|:---|:---|
| 1 | `"Azhar Fauzi" Universitas Pasundan` | 21 results — **bukan orang ini** (Harry Fauzi, Rizky Azhar, dll) |
| 2 | `"Azhar Muttaqien"` | 25 results — LinkedIn ✅, Masjid Ulul Albaab ✅, portfolio ✅ |
| 3 | `"Azhar Fauzi" github` | 22 results — noise MDN, 1 db.sql orang lain |
| 4 | `"Azhar Muttaqien" github` | 21 results — **portfolio azhar457.github.io** ✅ |
| 5 | `"azharsss457"` | 12 results — semua noise (Scribd, etheses, hasil ujian Pakistan) |
| 6 | `"azharmtq"` | 0 results — IG handle **tidak ter-index** ✅ |
| 7 | `"0818-0352-8486"` / `"0818 0352 8486"` | 3 results — semua konteks masjid/kajian |
| 8 | `"081803528486"` | 0 results — format tanpa dash tidak ter-index |
| 9 | `"0818-0352-8486" NIK` | 19 results — **semua noise** (nik.energy, NIK Czech) |
| 10 | `"Azhar Muttaqien" NIK` | 0 results |
| 11 | `"0818-0352-8486" bocor` / `... data` | 0 results |

**Fetch penuh (Jina Reader)**: portfolio GitHub, LinkedIn (authwall), website Masjid Ulul Albaab, GitHub API user.

## 3. Temuan — Eksposur Publik

| Sumber | Data terekspos | Risiko |
|:---|:---|:---|
| **azhar457.github.io** (portfolio) | Nama, "Mahasiswa Teknik Informatika UNPAS", email `azharsss457@gmail.com`, IG `@azharmtq`, link GitHub+LinkedIn | 🟡 Sedang |
| **LinkedIn** (azhar-muttaqien-a74a69237) | Cybersec \| Devops, Urbansolv, UNPAS, Bandung, 23 koneksi | 🟡 Sedang |
| **ulul-albaab-website.vercel.app** | "a.n. Azhar Muttaqien — Bendahara 2025/2026" + **WA 0818-0352-8486** | 🔴 **Tinggi** |
| **GitHub API azhar457** | 27 repos publik, created 2023-08-25, 9 followers — **bersih** (no email/lokasi) | 🟢 Aman |
| SearXNG index | IG `@azharmtq` tidak ter-index; email string tidak di-index | 🟢 Aman |

## 4. Verdict — Breach Database & NIK

### ❌ xposedornot.com — TIDAK VALID (red flag!)
- Query `email=azharsss457@gmail.com` → 772 breach
- Query `email=randomuser12345@nonexistent.com` → **772 breach IDENTIK** 🔴
- Query `email=test@test.com` → 772 breach IDENTIK
- **Kesimpulan**: API mengembalikan dump statis semua breach untuk SEMUA query — **bukan data spesifik email**. Data ini TIDAK bisa dipakai sebagai bukti.

### ⚠️ HIBP (haveibeenpwned.com)
- API butuh `hibp-api-key` (HTTP 401 tanpa key) — tidak bisa diverifikasi gratis.

### ✅ Verdict NIK — AMAN (sejauh index publik)
- **0 hasil** untuk kombinasi nomor HP + NIK / nama + NIK di SearXNG
- **0 hasil** untuk "nomor bocor" / "nomor data"
- NIK **tidak ditemukan** di sumber yang bisa diakses publik
- ⚠️ Catatan: NIK bocor biasanya ada di **dataset breach tertutup** (BPJS 2019, IndiHome, MyPertamina, KreditPlus — breach Indonesia yang dikenal bawa NIK). Search engine publik TIDAK bisa mendeteksi ini. Verifikasi penuh butuh HIBP key / dataset breach lokal.

## 5. Red Flag — API yang Tidak Valid

**Pelajaran penting (berlaku untuk semua riset):** sebelum percaya hasil API OSINT, **selalu tes dengan kontrol negatif** (email acak / data acak). Kalau hasilnya identik → API-nya ngasih dump statis → data tidak valid.

## 6. Rekomendasi Mitigasi

1. 🔴 **Nomor WA di website masjid** — minta admin ganti ke nomor masjid/form kontak. Prioritas tertinggi (PII + jabatan bendahara = target social engineering).
2. 🟡 **Email di portfolio GitHub** — ganti ke email publik terpisah atau obfuscate.
3. 🟡 **LinkedIn** — kurangi detail posisi spesifik kalau tidak perlu.
4. 🟢 **Rutin** — `"Azhar Muttaqien"` / `"azharsss457"` / `"azharmtq"` / nomor HP tiap beberapa bulan.

## 7. Audit Trail Sumber

| Sumber | URL | Status |
|:---|:---|:---|
| Portfolio | `https://azhar457.github.io/` | Primer — fetched via Jina ✅ |
| LinkedIn | `https://id.linkedin.com/in/azhar-muttaqien-a74a69237` | Primer — authwall, snippet dari SearXNG ✅ |
| Masjid Ulul Albaab | `https://ulul-albaab-website.vercel.app/` | Primer — fetched via Jina ✅ |
| GitHub API | `https://api.github.com/users/azhar457` | Primer — direct curl ✅ |
| xposedornot | `https://api.xposedornot.com/v1/breaches?email=...` | ❌ INVALID — kontrol negatif gagal |
| HIBP | `https://haveibeenpwned.com/api/v3/...` | ⚠️ Butuh API key (401) |

---

> [!tip] Cross-link
> - [[telegram-account-info]] — Telegram ID pribadi (folder examples/)
> - `Note/01_Library/military-and-intelligence-tools/01-osint-and-reconnaissance/` — catatan OSINT di vault
> - [[crawl-ambil-data-publik]] — pipeline crawl data publik (root Wide Note)
