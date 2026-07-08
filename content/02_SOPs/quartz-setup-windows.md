---
title: "Quartz Setup Windows"
tags:
  - sops
aliases:
  - "quartz-setup-windows"
created: "2026-07-01"
updated: "2026-07-01"
status: active
---

<think>
Okay, the user wants me to expand the documentation beyond 1100 words. Let me start by reviewing the current content. The existing steps are good but need more technical depth and examples.

First, I should add more detailed code examples. The current config.ts example is basic. Maybe explain each part of the configuration with more comments. Also, include a sample roadmap.html file content since it's mentioned in the FASE 6 section.

Next, I need to add more troubleshooting scenarios. The current section has a few points, but I can elaborate on common issues like missing dependencies, incorrect paths, and build errors. Each scenario should have a detailed explanation and solution.

For the deeper technical explanations, I can discuss Quartz's architecture, how it processes Markdown files, and integrates with GitHub Pages. Maybe add a section on the static site generation process, including how dependencies are managed and the flow from Markdown to HTML.

I should also include a comparison table between different configuration options, like enableSPA vs non-SPA, and their use cases. Additionally, a detailed table on common errors and their solutions.

I need to make sure the total word count is over 1100 without being redundant. Let me check the existing content. The current version has 812 words, so I need to add around 300 words. I'll expand each section with more examples and explanations, ensuring that all technical points are covered thoroughly.

Let me start with the installation phase. Add steps and error handling. Then, proceed to the fork and clone process with more technical details. In the configuration section, explain each part of the config.ts file. Include more troubleshooting scenarios for each phase.

For the deployment part, add a GitHub Actions workflow example and explain how it works. In the roadmap section, provide a more complex HTML example with comments. In the advanced configuration, discuss performance optimization techniques and private content management.

Finally, ensure all added sections are well-explained with code examples and tables to enhance clarity. Check that the content flows logically and meets the word requirement.
</think>

### SOP: Quartz v4 + GitHub Pages (Windows)

Quartz adalah generator **statis** berbasis **TypeScript/Markdown** yang dirancang untuk skalabilitas konten, personalisasi tema, dan integrasi cloud. Dokumen ini membahas arsitektur teknis, implementasi multi-level, dan troubleshooting spesifik Windows.

---

#### ⚙️ FASE 0 — Install Prasyarat (5 menit + 7 poin validasi)

**Persyaratan Sistem Minimal**

- Windows 10 64-bit (versi build ≥19041)
- Node.js v18.17.1+ (npm ≥8.19.0)
- Git (v2.39.2+) dengan path `C:\Program Files\Git\bin` di `PATH`

**Validasi Instalasi (via PowerShell):**

```powershell
# Node.js versi <18 tidak didukung
node --version | ForEach-Object {
    if ($_ -notmatch "v[18-20].+"){ throw "Node.js <18 tidak kompatibel dengan Quartz v4"}
}

# Git harus diakses sebagai biner sistem
git --exec-path | ForEach-Object {
    if (-not ($_ -match "Program Files")){ throw "Git tidak terinstall di path sistem" }
}
```

**Install via WSL (Jika Error di Native Windows):**

```bash
wsl --install
sudo apt update && sudo apt install nodejs npm
```

---

#### 🧭 FASE 1 — Fork & Clone: Arsitektur Folder Detil

```
quartz-repo/
├── content/              ← Root konten user
│   ├── tutorials/        ← Subfolder terstruktur
│   └── case-studies/     ← Dengan metadata `.metadata.json`
├── static/               ← Asset statis (SVG, CSS)
│   ├── img/              ← Direktori gambar
│   └── css/              ← File penyesuaian tema
├── quartz/               ← Core library (tidak disentuh)
├── quartz.config.ts      ← File konfigurasi inti
├── public/               ← Output build (hasil .build())
└── .gitignore            ← Penyaring file ekspor
```

**Contoh Pengelolaan Tag dengan Skrip Validasi:**

```ts
// quartz.config.ts
export const config: QuartzConfig = {
  configuration: {
    ignorePatterns: [
      "**/private/**", // Folder konten sensitif
      "**/drafts/**/*.md", // Artikel dalam proses
    ],
  },
}
```

---

#### 📁 FASE 2 — Copy Vault: Alur Validasi Konten

**Strategi Transfer Konten Terprogram:**

```bash
# Skrip bash dengan ekstensi `.ps1` untuk Windows
$ErrorActionPreference = "Stop"
Get-ChildItem .\local-vault\*.md | ForEach-Object {
    # Validasi metadata header
    if ($_ -match "%%.*%%") { Write-Host "Error: Header tidak valid di $_" }
}

# Transfer ke struktur Quartz
Copy-Item .\local-vault\*.md content/ -Recurse -ErrorAction SilentlyContinue
```

---

#### ⚙️ FASE 3 — Konfigurasi Maxis: Contoh Implementasi Penuh

```ts
// quartz.config.ts
import { QuartzConfig, defaultConfig } from "@quartz/stem"

export const config: QuartzConfig = {
  ...defaultConfig,
  plugins: [
    {
      name: "customHeaderCode",
      onPostProcess(ctx) {
        if (ctx.frontmatter.layout === "roadmap") {
          return `
            <script>
              let highlight = true; 
              if (highlight) document.body.style.color = "red";
            </script>
          `
        }
        return ""
      },
    },
  ],
  configuration: {
    theme: {
      colors: {
        darkMode: {
          highlight: "rgba(0, 0, 255, 0.2)", // Highlight gelap
        },
      },
    },
    enablePopovers: true, // Toggle info hover
    enableSPA: true, // Navigasi single-page
  },
}
```

| Properti Konfigurasi | Fungsi                       | Nilai Default |
| -------------------- | ---------------------------- | ------------- |
| `enableSPA`          | Navigasi instan (AJAX-based) | `true`        |
| `ignorePatterns`     | Penyaring file ekspor        | `[]`          |
| `theme`              | Tema situs web               | `default`     |

---

#### 🔍 FASE 4 — Test Lokal: Debugging Level Lanjut

**Perintah dengan Logging Debug (via PowerShell):**

```powershell
QUARTZ_LOG_LEVEL=debug npx quartz build --serve
```

**Contoh Output Debug:**

```
[2023-04-12 14:30:04] Parsing: content/roadmap.md
[2023-04-12 14:30:04] Injecting custom header for layout: roadmap
[2023-04-12 14:30:05] Warning: No tags found in: content/tutorials/advanced.md
```

---

#### 🚀 FASE 5 — Deploy ke GitHub Pages

**File `.github/workflows/build-deploy.yml`:**

```yaml
on:
  push:
    branches:
      - main

jobs:
  build-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Setup Node.js v18.x
        uses: actions/setup-node@v3
        with:
          node-version: "18.x"
      - run: npm install
      - run: npx quartz build --public-folder public
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v3
        with:
          publish_dir: ./public
          github_token: ${{ secrets.GITHUB_TOKEN }}
```

---

#### 🧠 FASE 6 — Roadmap Embedding: HTML + TypeScript

**Contoh File `roadmap.html`:**

```html
<svg width="600" height="400" xmlns="http://www.w3.org/2000/svg">
  <circle cx="120" cy="100" r="20" fill="red" />
  <circle cx="200" cy="100" r="20" fill="green" />
  <circle cx="140" cy="180" r="20" fill="orange" />
  <text x="110" y="125" font-family="Arial" font-size="12">Dev</text>
  <text x="190" y="125" font-family="Arial" font-size="12">Prod</text>
  <text x="130" y="205" font-family="Arial" font-size="12">QA</text>
</svg>
```

**Embedding di `tutorial.md`:**

```markdown
<div class="graphviz">
  ![Roadmap](/roadmap.html)
</div>
```

---

#### 🔨 Konfigur
