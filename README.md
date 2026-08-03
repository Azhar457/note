<div align="center">

# 🧠 Azhar's Knowledge Base & Digital Garden

[![Quartz v4.5.2](https://img.shields.io/badge/Powered%20by-Quartz%20v4.5.2-7b97aa?style=for-the-badge&logo=quartz)](https://quartz.jzhao.xyz/)
[![GitHub Pages](https://img.shields.io/badge/Deployed%20to-GitHub%20Pages-22c55e?style=for-the-badge&logo=github)](https://azhar457.github.io/note/)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE.txt)

Repositori ini berisi catatan digital publik (**Digital Garden**) yang mencakup dokumentasi teknis, modul pembelajaran, SOP infrastruktur, serta basis pengetahuan mengenai **Cyber Security**, **Systems Architecture**, **DevSecOps**, dan **Computer Science**.

🌐 **Live Site:** [https://azhar457.github.io/note/](https://azhar457.github.io/note/)

---

</div>

## 📌 Topik Utama Basis Pengetahuan

- 🛡️ **Cyber Security & Red Teaming:** Active Directory Exploitation, C2 & Post-Exploitation (Sliver, Cobalt Strike), Web App Pentesting, Wireless Security, CTF Walkthroughs (PicoCTF).
- 🏗️ **Systems & Infrastructure Architecture:** Linux Performance Tuning, eBPF Auditing, Cloudflare Routing, Docker/LXC Containerization, High Availability.
- ⚡ **DevSecOps & Automation:** CI/CD Pipelines, GitHub Actions, Terraform IaC, WAF/IDS Enforcement (Suricata, CrowdSec).
- 📚 **Standard Operating Procedures (SOPs):** Incident Response, Forensic Analysis, Storage Refurbishing, Disaster Recovery.

---

## 📂 Struktur Repositori

```text
note/
├── content/              # 📝 Inti basis pengetahuan (seluruh file Markdown .md)
│   ├── 01_Library/       # Buku, modul teknis, & panduan riset mendalam
│   ├── 02_SOPs/          # Standard Operating Procedures operasional & keamanan
│   └── 03_Resources/     # Referensi, cheatsheet, diagram, & lampiran
├── quartz/               # ⚙️ Source code & komponen UI dari Quartz SSG Framework
│   ├── components/       # Komponen React/TSX (Header, Explorer, Graph, SEO)
│   ├── plugins/          # Plugin pengolah markdown & transformer
│   └── styles/           # Stylesheet SCSS & custom theme
├── .github/workflows/    # 🚀 CI/CD GitHub Actions (Deploy & Build Preview)
├── quartz.config.ts      # 🛠️ Konfigurasi utama Quartz (Title, Plugin, Theme, SEO)
├── quartz.layout.ts      # 📐 Tata letak komponen halaman (Sidebar, Header, Footer)
└── deploy.bat            # 🔄 Script otomatisasi build & sync untuk Windows
```

---

## 🛠️ Cara Mengupdate & Memublikasikan Catatan

### 1. Menambahkan / Memperbarui Catatan

Tambahkan file Markdown (`.md`) baru atau sunting catatan yang ada di dalam folder `content/`.

### 2. Menguji Secara Lokal (Opsional)

Jalankan dev server lokal untuk mempratinjau tampilan:

```bash
# Menguji build & jalankan local dev server (port 8080)
npx quartz build --serve
```

### 3. Memublikasikan Perubahan

- **Via Linux / Terminal Git:**
  ```bash
  git add .
  git commit -m "docs: tambah catatan baru"
  git push origin v4
  ```
- **Via Windows:**
  Jalankan file `deploy.bat` untuk memproses build dan sync secara otomatis.

---

## ⚡ Perintah Penting (Quartz CLI)

| Perintah                   | Deskripsi                                                                 |
| :------------------------- | :------------------------------------------------------------------------ |
| `npx quartz build`         | Membangun seluruh situs HTML dari Markdown ke folder `public/`            |
| `npx quartz build --serve` | Jalankan local server dengan fitur live reload di `http://localhost:8080` |
| `npm run check`            | Menguji TypeScript types dan validasi Prettier pada kode Quartz           |

---

<div align="center">

Dikelola dengan ☕ oleh **Azhar457**

</div>
