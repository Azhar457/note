---
title: Layout & Spacing
tags: [frontend, layout, css]
aliases: [layout-spacing]
---
# Layout & Spacing

Layout adalah struktur tata letak halaman; spacing adalah ritme jarak antar elemen. Keduanya menentukan keterbacaan, hierarki, dan "rasa" profesional UI. Dokumen ini membahas prinsip, teknik CSS, dan praktik spacing.

## Prinsip Layout

1. **Grid dulu, fleksibilitas setelah** — layout dimulai dari grid (12 kolom umum) → komponen mengisi grid; jangan komponen dulu lalu dipaksakan.
2. **Alignment konsisten** — semua elemen sejajar pada garis grid; misalignment kecil terlihat "rusak".
3. **Konten-driven** — layout mengikuti konten (teks panjang vs dashboard), bukan sebaliknya.
4. **Responsive tanpa lompatan** — fluid (clamp, fr) sebelum media query.
5. **Accessibility** — urutan DOM = urutan baca (keyboard); jangan reorder visual yang membingungkan.

## CSS Layout Modern

### Flexbox (1 dimensi — baris/kolom)
```css
.nav { display: flex; gap: 1rem; align-items: center; }
.sidebar { flex: 0 0 280px; }
.main { flex: 1; min-width: 0; }
```

### Grid (2 dimensi)
```css
.layout {
  display: grid;
  grid-template-columns: 280px 1fr;
  grid-template-areas: "sidebar main";
  gap: 1.5rem;
}
.cards {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(260px, 1fr));
  gap: 1rem; /* = spacing scale */
}
```

### Container Queries (komponen responsif sendiri)
```css
.card { container-type: inline-size; }
@container (max-width: 400px) { .card { padding: .75rem; } }
```

## Spacing Scale (Design Token)

```
Base: 4px (atau 8px)
Scale: 0   = 0
      1   = 4px   (ikon dan teks)
      2   = 8px   (gap kecil)
      3   = 12px  (grup kecil)
      4   = 16px  (default padding card)
      5   = 24px  (gap section)
      6   = 32px  (gap blok)
      7   = 48px  (section besar)
      8   = 64px  (halaman)
      9   = 96px+ (hero/landing)
```

Implementasi CSS variable:
```css
:root {
  --space-1: 4px;  --space-2: 8px;  --space-3: 12px;
  --space-4: 16px; --space-5: 24px; --space-6: 32px;
  --space-7: 48px; --space-8: 64px; --space-9: 96px;
}
```
Gunakan scale — jangan angka acak (13px, 21px) kecuali alasan kuat.

## Aturan Empat (Spacing Rules)

1. **Dekat = terkait** — elemen dalam grup berjarak kecil (8-12px); antar grup lebih besar (24px+).
2. **Konsisten antar halaman** — padding card sama di mana-mana (16px), gap form sama (16px).
3. **Jarang pakai jarak menengah besar** — lompatan scale (4→16→48) menciptakan ritme; jarak 20px vs 24px tidak terasa beda tapi tidak disiplin.
4. **Whitespace > border** — pisahkan section dengan spacing, bukan selalu garis; garis untuk sub-grup.

## Typography + Spacing (Vertical Rhythm)

```css
/* Base */
body { font-size: 16px; line-height: 1.6; }
p { margin: 0 0 1rem 0; }        /* 16px */
h1 { font-size: clamp(2rem, 4vw, 2.6rem);
     line-height: 1.15; margin: 0 0 .5em; }
h2 { font-size: clamp(1.4rem, 2.5vw, 1.8rem);
     line-height: 1.25; margin: 2rem 0 .75em; }
```

- Baseline: body line-height 24px (16px × 1.5) → heading margins kelipatan 8/24.
- Jangan `margin-top` pada elemen pertama di container (use `:first-child { margin-top: 0 }` atau `* + *` lobotomized owl: `body * + * { margin-top: ... }` hati-hati).

## Form Layout

- Label di atas input (mobile-friendly & terbaik untuk usability) — 8px gap; input stack gap 16px.
- Grid 2 kolom untuk field pendek (nama depan/belakang) — 16px gap.
- Tombol aksi: kanan (form horizontal) / full-width (mobile).
- Error: inline di bawah field + border merah + ikon; jangan geser layout saat error muncul (reserve space).

## Responsive Breakpoints (Praktis)

| Breakpoint | Target | Layout |
|-----------|--------|--------|
| < 640px | Mobile | 1 kolom, nav hamburger |
| 640-1024px | Tablet | 2 kolom, sidebar collapse |
| 1024-1440px | Desktop | Grid penuh |
| > 1440px | Wide | Max-width container 1200-1400px + center |

- Gunakan `clamp()` untuk fluid type/spacing sebelum breakpoint.
- "Mobile-first": tulis base mobile, tambah breakpoint dengan `min-width`.

## Checklist

- [ ] Grid/alignment konsisten (elemen sejajar)?
- [ ] Spacing memakai scale token (bukan angka acak)?
- [ ] Dekat = terkait (grup vs antar grup)?
- [ ] Vertical rhythm: heading/paragraf selaras?
- [ ] Container queries / fluid sebelum breakpoint?
- [ ] Form: label, gap, error layout stabil?
- [ ] Touch target ≥ 44px di mobile?

## Koneksi ke Vault

- [[industrial-brutalist-ui]] — estetika tegas dengan padding/border konsisten.
- [[ui-ux-pro-max]] — lanjutan UX (hierarki, states).
- [[high-end-visual-design]] — premium polish (typography, shadow, detail).



## Studi Kasus: Dashboard Layout

**Skenario:** dashboard monitoring dengan sidebar, header, grid kartu metrik, tabel.

```css
.app {
  display: grid;
  grid-template-columns: 260px 1fr;
  grid-template-rows: 64px 1fr;
  grid-template-areas:
    "sidebar header"
    "sidebar content";
  height: 100vh;
}
.content { grid-area: content; padding: var(--space-5);
           overflow-y: auto; }
.metrics {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: var(--space-4);
  margin-bottom: var(--space-5);
}
```

Detail: sidebar 260px (bukan 240 — coba & rasakan), gap 16-24px, content padding 24px. Tabel di bawah dengan margin-top 32px (pemisahan visual antar blok berbeda konteks).

## Debug Layout (Tools)

1. Browser devtools → Layout tab (grid overlay) — lihat garis grid.
2. **VisBug** (extensi Chrome) — spacing distance, alignment check visual.
3. **Pesticide / outline all** — `* { outline: 1px solid red }` sementara untuk lihat box.
4. Lighthouse accessibility: kontras, target size.
5. **Chromatic/Playwright screenshots** — visual regression.

## Spacing di Dark Mode

- Ruang kosong lebih penting di dark (kontras rendah) — gunakan spacing untuk memisahkan, bukan border.
- Border di dark: `rgba(255,255,255,.08)` — sangat halus.
- Skeleton di dark: lebih gelap dari surface (bukan lebih terang).

---

  audited
---