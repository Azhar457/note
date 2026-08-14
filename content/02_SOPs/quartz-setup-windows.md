---
title: Quartz Setup Windows
tags:
- 02-sops
created: '2026-07-01'
updated: '2026-07-01'
status: pending
---

### SOP: Quartz v4 + GitHub Pages (Windows)

#### FASE 0 — Install Prasyarat (5 menit)

**Cek dulu yang sudah ada:**

```
Buka PowerShell / Command Prompt, ketik:
node --version    → harus v18+ 
git --version     → harus ada
```

Kalau belum ada:

- **Node.js** → nodejs.org → download LTS → install
- **Git** → git-scm.com → download → install (next-next-finish)

---

#### FASE 1 — Fork & Clone Quartz (5 menit)

```
1. Buka: github.com/jackyzha0/quartz
2. Klik tombol "Fork" (kanan atas)
3. Repository name: ganti jadi nama vaultmu
   Contoh: security-knowledge-base
4. Klik "Create Fork"
```

Sekarang kamu punya repo sendiri. Clone ke lokal:

bash

```bash
cssclasses:
  - wide-table
  - callout

# Ganti USERNAME dan REPO-NAME sesuai punyamu
git clone https://github.com/USERNAME/REPO-NAME
cd REPO-NAME
npm i
```

---

#### FASE 2 — Copy Vault ke Quartz (3 menit)

Struktur folder Quartz:

```
REPO-NAME/
├── content/        ← SEMUA file .md vault kamu masuk sini
├── quartz/
├── quartz.config.ts
└── ...
```

**Yang dilakukan:**

```
1. Buka folder vault Obsidian kamu di Windows Explorer
2. Select semua file .md → Copy
3. Paste ke folder: REPO-NAME/content/
4. Untuk roadmap.html → taruh di: REPO-NAME/quartz/static/
   (nanti bisa dilink dari md file)
```

---

#### FASE 3 — Konfigurasi (5 menit)

Buka `quartz.config.ts` dengan VSCode atau Notepad++, edit bagian ini:

typescript

```typescript
const config: QuartzConfig = {
  configuration: {
    pageTitle: "🔐 Security & CS Knowledge Base", // ← ganti
    enableSPA: true,
    enablePopovers: true,
    analytics: null,
    locale: "en-US",
    baseUrl: "USERNAME.github.io/REPO-NAME", // ← ganti
    ignorePatterns: ["private", "templates"],
    defaultDateType: "created",
    theme: {
      fontOrigin: "googleFonts",
      cdnCaching: true,
      typography: {
        header: "Schibsted Grotesk",
        body: "Source Sans Pro",
        code: "IBM Plex Mono",  // ← bagus untuk konten teknis
      },
      colors: {
        lightMode: {
          light: "#faf8f8",
          lightgray: "#e5e5e5",
          gray: "#b8b8b8",
          darkgray: "#4e4e4e",
          dark: "#2b2b2b",
          secondary: "#284b63",
          tertiary: "#84a98c",
          highlight: "rgba(143, 159, 169, 0.15)",
        },
        darkMode: {
          light: "#161618",
          lightgray: "#393639",
          gray: "#646464",
          darkgray: "#d4d4d4",
          dark: "#ebebec",
          secondary: "#7b97aa",
          tertiary: "#84a98c",
          highlight: "rgba(143, 159, 169, 0.15)",
        },
      },
    },
  },
```

---

#### FASE 4 — Test Lokal (2 menit)

bash

```bash
# Di dalam folder REPO-NAME
npx quartz build --serve

# Buka browser: http://localhost:8080
# Cek semua file md terbaca, internal link jalan
```

---

#### FASE 5 — Deploy ke GitHub Pages (5 menit)

**Setup GitHub Actions untuk auto-deploy:**

bash

```bash
# Di folder REPO-NAME
npx quartz sync --no-push

git add .
git commit -m "initial: setup vault"
git push
```

Lalu di GitHub:

```
1. Buka repo kamu di github.com
2. Settings → Pages
3. Source: GitHub Actions
4. Save
```

Quartz sudah include file workflow otomatis — setiap kamu `git push`, site langsung rebuild sendiri.

**URL hasil:**

```
https://USERNAME.github.io/REPO-NAME
```

---

#### FASE 6 — Link Roadmap HTML

Di file `MASTER_INDEX.md`, tambahkan:

markdown

```markdown
## 🗺️ Visual Roadmap

- [Roadmap 1](/REPO-NAME/static/roadmap1.html)
- [Roadmap 2](/REPO-NAME/static/roadmap2.html)
- [Roadmap 3](/REPO-NAME/static/roadmap3.html)
```

---

#### Update Vault ke Depan (30 detik per update)

bash

```bash
# Setiap kali ada file baru atau edit:
npx quartz sync
# Selesai — auto push + auto deploy
```

---

> [!warning] Satu yang Perlu Diperhatikan Semua konten di vault ini akan **public** — bisa dilihat siapa saja. Pastikan tidak ada info sensitif (password, data pribadi, dll) yang ikut ter-upload. File dengan tag `private` di frontmatter akan di-skip otomatis oleh Quartz.
## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/

### FAQ & Catatan Tambahan

**Q: Apa beda konseptual yang paling penting dipahami?**
A: Bedakan antara teori (definisi formal), implementasi (kode konkret), dan operasional (jalankan di produksi). Banyak orang paham teori tetapi gagal implementasi; sebaliknya, banyak yang bisa implementasi tanpa paham fundamental.

**Q: Apa saja sumber terbaik untuk mempelajari topik ini lebih dalam?**
A: Buku akademis untuk teori (formal proof), blog industri untuk praktik terkini (real-world case), CVE database untuk kerentanan konkret, dan video/lecture untuk visualisasi konsep. Kombinasi sumber memberi pemahaman menyeluruh.

**Q: Bagaimana cara menilai maturity implementasi saya?**
A: Audit terhadap checklist standar industri (NIST, CIS, OWASP). Penilaian: ada vs tidak ada kontrol, efektivitas, dokumentasi, repeatable.

### Glossary

| Istilah | Definisi Singkat |
|---------|------------------|
| **Zero Trust** | Never trust, always verify |
| **MITRE ATT&CK** | Framework TTP serangan |
| **SIEM** | Security Information & Event Management |
| **EDR** | Endpoint Detection & Response |
| **SOAR** | Security Orchestration & Response |
| **IoC** | Indicator of Compromise |
| **MFA** | Multi-Factor Authentication |
| **RBAC** | Role-Based Access Control |
| **SBOM** | Software Bill of Materials |
| **SLSA** | Supply-chain Levels for Software Artifacts |
| **OIDC** | OpenID Connect |
| **PKCE** | Proof Key for Code Exchange |

## Referensi Tambahan
- OWASP Cheatsheet — https://cheatsheetseries.owasp.org/
- NIST SP 800-53 — https://csrc.nist.gov/publications/detail/sp/800-53
- Cloud Security Alliance — https://cloudsecurityalliance.org/
- Cloud Native (CNCF) — https://www.cncf.io/
