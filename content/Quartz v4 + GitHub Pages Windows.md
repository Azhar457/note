# 🚀 SOP: Quartz v4 + GitHub Pages (Windows)

Dokumentasi ini berisi langkah-langkah konkret untuk melakukan setup, kustomisasi, dan deployment Obsidian Vault ini menggunakan Quartz v4 ke GitHub Pages.

---

## 🛠️ FASE 0 — Prasyarat Sistem
Sebelum memulai, pastikan perangkat Anda sudah terinstall:
- **Node.js (v22.0.0 atau lebih baru)**: `node -v`
- **Git**: `git --version`
- **NPM**: `npm -v`

---

## 📂 FASE 1 — Struktur Repositori
Repositori ini (`Azhar457/note`) adalah framework Quartz yang sudah dikonfigurasi. Struktur utamanya adalah:
- `content/`: Lokasi semua file `.md` (Obsidian Vault).
- `quartz/static/`: Lokasi aset statis (gambar, PDF, HTML interaktif).
- `quartz.config.ts`: Konfigurasi utama metadata situs.
- `deploy.bat`: Script otomatis untuk build & sync.

---

## ⚙️ FASE 2 — Konfigurasi Situs
Edit file `quartz.config.ts` untuk mengatur identitas situs:

```typescript
configuration: {
  pageTitle: "🔐 Security & CS Knowledge Base",
  baseUrl: "Azhar457.github.io/note",
  defaultDateType: "created", // Menggunakan tanggal pembuatan file
  theme: {
    // Kustomisasi warna & font di sini
  }
}
```

---

## 🖥️ FASE 3 — Menangani Aset Statis (HTML Roadmap)
Jika Anda memiliki file HTML interaktif (seperti Roadmap Aplikasi), jangan letakkan di `content/` karena Quartz akan mencoba merendernya sebagai Markdown.
1. Pindahkan file `.html` ke: `quartz/static/Roadmap/`
2. Akses file tersebut via URL: `/note/Roadmap/nama_file.html`
3. Tautkan di `index.md` menggunakan format standard Markdown:
   `[Buka Aplikasi](/note/Roadmap/Application_Cyber.html)`

---

## 🚀 FASE 4 — Build & Deployment
Saya telah menyediakan script **`deploy.bat`** di root folder untuk menyederhanakan workflow.

### Menjalankan Build Lokal (Preview)
Gunakan perintah ini di terminal untuk melihat hasil sementara:
```bash
npx quartz build --serve
```
Situs akan tersedia di: `http://localhost:8080`

### Melakukan Deployment ke GitHub Pages
Cukup jalankan script otomatis:
1. Klik dua kali file `deploy.bat`.
2. Script akan menjalankan `npx quartz build` dan `npx quartz sync`.
3. Tunggu hingga proses GitHub Actions di browser selesai.

---

## 📝 FASE 5 — Sinkronisasi Konten
Setiap kali Anda menambah atau mengedit catatan di Obsidian:
1. Pastikan file tersimpan di folder `content/`.
2. Jalankan `deploy.bat`.
3. Perubahan akan live dalam hitungan menit.

---

## ⚠️ Troubleshooting & Tips
- **Warning: File isn't yet tracked by git**: Ini muncul jika file baru belum di-commit. Jalankan `git add .` sebelum build jika ingin tanggal akurat.
- **Index.md**: Quartz mewajibkan adanya file `content/index.md` sebagai homepage. Kami menggunakan `MASTER_INDEX.md` yang disalin menjadi `index.md`.
- **Private Files**: Tambahkan `draft: true` atau `tags: [private]` di frontmatter untuk menyembunyikan file dari publik.

---
> [!IMPORTANT]
> Selalu periksa kembali file di folder `content/` sebelum melakukan sync untuk memastikan tidak ada data sensitif yang terpublikasi secara tidak sengaja.