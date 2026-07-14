# Panduan Agent untuk Vault Ini

Vault ini dirancang untuk dibaca manusia DAN diakses oleh berbagai AI agent/model.

## Aturan Main

1. **Frontmatter wajib.** Setiap note punya `tags`, `aliases`, `created`, `status`. Agent: gunakan `tags` untuk filter, `aliases` untuk lookup sinonim.

2. **Folder = domain.** Path mencerminkan topik:
   - `01_Library/AI_Systems/` — AI/ML/Agent architecture
   - `01_Library/Cyber_Security/` — Security blue/red team
   - `01_Library/DevOps/` — CI/CD, infra ops
   - `01_Library/Software_Engineering/` — pola coding, buku
   - `01_Library/Systems_Architecture/` — distributed systems, OS
   - Subfolder di dalamnya = subtopik (misal `Network_Threats/`, `Endpoint_Detection/`)

3. **`_index.md` = MOC (Map of Content).** Tiap folder punya `_index.md` yang daftar semua file di folder itu. Agent: baca `_index.md` dulu sebelum menyelam ke file detail.

4. **Wikilink:** Format `[[nama-file]]` (tanpa path, tanpa `.md`). Obsidian resolve otomatis.

5. **Tabel:** WAJIB ada blank line setelah pipe sequence (`| ... |` → blank → teks berikutnya). Tanpa blank line, markdown parser Obsidian dan GitHub gagal render.

6. **JANGAN edit note tanpa konfirmasi.** Kecuali user minta.

7. **Bahasa:** Campur Indonesia + Inggris. Jawab sesuai bahasa yang user pakai.

8. **Status field:** `operational` = siap pakai, `draft` = masih dikerjain, `stale` = mungkin udah outdated.
