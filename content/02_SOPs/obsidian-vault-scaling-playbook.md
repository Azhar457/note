---
tags:
  - sop
  - obsidian
  - vault
  - git
  - project-management
aliases:
  - SOP Obsidian Vault Scaling Playbook
  - Vault Hygiene Playbook
  - Vault Scaling Playbook
status: evergreen
created: 2026-07-21
updated: 2026-07-21
---

# SOP: Obsidian Vault Scaling & Hygiene Playbook

> [!tip] **Obsidian Vault Scaling & Hygiene** adalah pedoman standardisasi untuk memelihara integritas Obsidian Vault yang berukuran besar ($> 300\text{ files}$). Dokumen ini mendefinisikan aturan penulisan tautan (_wiki links_), standarisasi format frontmatter YAML, manajemen alias untuk mencegah _infinite redirect loop_ di Quartz, serta otomatisasi pre-commit audit untuk menjaga kesehatan data vault secara mandiri.

---

## 1. Standar Struktur & Konvensi Penamaan (Naming Conventions)

Untuk menjaga struktur berkas tetap bersih dan mudah dipindai oleh generator Quartz maupun database RAG lokal:

### A. Struktur Folder Hierarkis

Setiap file baru wajib diletakkan di bawah salah satu folder utama berikut:

- `00_Inbox/`: Tempat menyimpan draf kasar, catatan sementara, atau file scraping mentah.
- `01_Library/`: Catatan pengetahuan permanen (Evergreen Notes) yang terbagi menjadi subfolder tematik (e.g., `Machine_Learning/`, `Systems_Architecture/`, `Software_Engineering/`).
- `02_SOPs/`: Standar Operasional Prosedur taktis yang berisi langkah pemecahan masalah praktis.
- `03_Projects/`: Catatan spesifik tentang progres proyek aktif (seperti JarsWAF).

### B. Aturan Penamaan File (Filename Rules)

- **Format Kebab-Case**: Gunakan huruf kecil dipisahkan dengan tanda hubung (`-`). Hindari spasi atau karakter khusus.
  - _Benar_: `model-context-protocol-specification.md`
  - _Salah_: `Model Context Protocol Specification.md` atau `mcp_spec.md`
- **Unique Basename**: Setiap file harus memiliki nama dasar yang unik di seluruh folder untuk menghindari bentrokan resolusi tautan internal di Quartz.

---

## 2. Aturan Emas Manajemen Alias (Alias Safety Policy)

Alias digunakan di Quartz untuk membuat pengalihan URL (redirect). Konfigurasi alias yang salah dapat merusak build website Anda.

### A. Kebijakan Anti Self-Reference

> [!caution] **Aturan Utama**: Jangan pernah memasukkan nama file yang sama tanpa ekstensi ke dalam daftar `aliases` pada berkas tersebut.

- **Skenario Kerusakan (Infinite Redirect)**:
  Jika berkas bernama `output.md` memiliki alias `output`:

  ```yaml
  # content/output.md
  ---
  aliases:
    - output
  ---
  ```

  Quartz akan menghasilkan file `public/output/index.html` yang memuat tag `<meta http-equiv="refresh" content="0; url=./output">`. Browser pengguna akan terjebak dalam putaran penyegaran tanpa henti (_infinite refresh loop_).

- **Praktik Terbaik**: Gunakan alias hanya untuk singkatan, nama alternatif dalam bahasa Inggris/Indonesia, atau nama historis file sebelum diganti namanya.
  ```yaml
  # content/01_Library/Systems_Architecture/model-context-protocol-specification.md
  ---
  aliases:
    - MCP Spec
    - Model Context Protocol
  ---
  ```

---

## 3. Format Baku Frontmatter YAML

Setiap file di dalam Vault harus diawali oleh blok frontmatter YAML tertutup dengan struktur key-value yang valid:

```yaml
---
tags:
  - machine-learning # Kategori utama (huruf kecil, kebab-case)
  - vector-database # Sub-kategori spesifik
aliases:
  - HNSW Index Tuning # Nama alias alternatif
status: evergreen # Status: evergreen (matang), seedling (draf), atau archived (arsip)
created: 2026-07-21 # Tanggal pembuatan (YYYY-MM-DD)
updated: 2026-07-21 # Tanggal modifikasi terakhir (YYYY-MM-DD)
---
```

---

## 4. Alur Kerja Pemangkasan & Penggabungan Catatan (Split & Merge Policy)

Seiring bertambahnya ukuran Vault, lakukan pembersihan berkala untuk memilah konten:

```
              [ Catatan > 800 baris / Topik Terlalu Luas ]
                                  │
                                  ▼
                   ┌─────────────────────────────┐
                   │ Lakukan Split (Pemisahan)   │
                   └──────────────┬──────────────┘
                                  │
         ┌────────────────────────┴────────────────────────┐
         ▼                                                 ▼
[ Buat Note Baru Khusus ]                        [ Jadikan Note Lama ]
(e.g. `vector-quantization-hnsw-tuning.md`)      (Index Hub / Map of Content)
```

1.  **Kapan Harus Split (Memisah)**:
    - Jika sebuah catatan memiliki panjang $> 800$ baris atau mencakup lebih dari 3 topik yang berbeda.
    - Pindahkan sub-topik ke berkas baru dengan tautan dua arah (_two-way wiki-links_).
2.  **Kapan Harus Merge (Menggabungkan)**:
    - Jika terdapat catatan dengan isi $< 10$ baris yang memiliki keterkaitan erat dengan catatan induk.
    - Pindahkan teksnya ke dalam bagian tersendiri di catatan induk, lalu hapus berkas draf kecil tersebut.

---

## 5. Audit Otomatis dengan Git Hook & Prettier

Untuk mencegah kode rusak ter-push ke GitHub Pages:

### A. Prettier Code Formatting

Jalankan format otomatis pada semua berkas Markdown sebelum sinkronisasi:

```bash
npx prettier --write "content/**/*.md"
```

### B. Skrip Audit Internal (Linting Wikilinks & Aliases)

Gunakan skrip Python sederhana di folder `scratch/` untuk mendeteksi alias berbahaya:

```python
import os
import yaml

VAULT_DIR = "/mnt/data_d/Documents/Wide Note/Note"

def audit_vault():
    for root, _, files in os.walk(VAULT_DIR):
        for file in files:
            if not file.endswith(".md"):
                continue
            path = os.path.join(root, file)
            basename = os.path.splitext(file)[0]

            with open(path, "r", encoding="utf-8") as f:
                content = f.read()
                if content.startswith("---"):
                    parts = content.split("---")
                    try:
                        meta = yaml.safe_load(parts[1])
                        if meta and "aliases" in meta:
                            for alias in meta["aliases"]:
                                if str(alias).lower() == basename.lower():
                                    print(f"⚠️ DANGER: Self-referencing alias found in {file} (Alias: {alias})")
                    except Exception as e:
                        print(f"Error parsing YAML in {file}: {e}")

if __name__ == "__main__":
    audit_vault()
```

---

## 🔗 Referensi & Catatan Terkait

- [[model-context-protocol-specification]] — Integrasi Skema Data Vault dengan MCP
- [[linux-performance-debugging-toolkit]] — Pemantauan Disk Overhead saat Build Quartz
- [[jina-reader-web-scraping-rag]] — SOP Scraping dan Ingest Data Mentah ke Vault
