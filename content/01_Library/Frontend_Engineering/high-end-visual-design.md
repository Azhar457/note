---
title: High End Visual Design
tags: [frontend, design, visual]
aliases: [high-end-visual-design]
---
# High-End Visual Design

"High-end" visual = produk yang terasa premium: detail terkontrol, tipografi cermat, warna disiplin, motion halus, dan konsistensi total. Contoh acuan: Stripe, Linear, Vercel, Apple, Raycast, Arc. Bukan sekadar "bagus" — tapi sistematis & intentional.

## 1. Design System Tokens (Fondasi)

Setiap keputusan visual = token (bukan nilai acak di komponen):

```css
:root {
  /* Warna */
  --bg: #0a0a0f; --surface: #12121a; --border: rgba(255,255,255,.1);
  --text: #f4f4f5; --text-muted: #a1a1aa;
  --primary: #6d5cff; --primary-hover: #7d6dff;

  /* Radius */
  --radius-sm: 6px; --radius-md: 10px; --radius-lg: 16px;

  /* Shadow (multi-layer, subtle) */
  --shadow-sm: 0 1px 2px rgba(0,0,0,.4);
  --shadow-md: 0 4px 12px rgba(0,0,0,.3), 0 1px 3px rgba(0,0,0,.5);
  --shadow-lg: 0 12px 40px rgba(0,0,0,.5), 0 2px 8px rgba(0,0,0,.4);

  /* Font */
  --font-display: "Inter", sans-serif;
  --font-mono: "JetBrains Mono", monospace;
  --tracking-tight: -0.02em;
}
```

## 2. Tipografi Premium

- **Satu keluarga font dengan banyak weight** (Inter: 400/500/600/700) — variasi via weight, bukan font kedua.
- **Negative tracking** untuk display besar: `letter-spacing: -0.02em` (h1), `-0.01em` (h2) — terasa modern.
- **Mono untuk data**: angka, kode, ID — konsisten (tabular-nums).
- **Line-height ketat** di heading (1.1-1.2), longgar di body (1.5-1.6).
- **Hierarki halus**: perbedaan ukuran 2px terasa; jangan lompat besar tanpa alasan.
- **Max-width text**: 65-75ch untuk paragraf (keterbacaan).

## 3. Warna & Atmosphere

- **Palet gelap berlapis** (dark first untuk produk tech premium) — surface berbeda via hue/brightness halus, bukan shadow saja.
- **Satu aksen** (primary) + semantic (success/warning/danger) — sisanya neutral.
- **Gradient konten**: backdrop blur + radial glow (subtle, posisi fokus).
- **Border**: `rgba(warna, .1-.15)` — halus; jangan solid abu gelap pekat.
- **Mode terang**: jangan putih murni (#fff) — `#fafafa`/`#f8f8f8`; text `#18181b`.

## 4. Surface & Elevation

- Elevation: bg (0) < surface (1) < overlay (2) < modal (3) — via kombinasi warna + border + shadow halus.
- Card: surface + border 1px + shadow-sm; hover: shadow-md + border terang.
- Modal: overlay blur (backdrop) + shadow-lg.
- Tab aktif / nav aktif: background transisi halus + indicator (dot/line), bukan border tebal.

## 5. Motion (Detail Halus)

- Durasi: 120-250ms (default 200ms); easing custom: `cubic-bezier(0.2, 0, 0, 1)`.
- Element masuk: fade + translateY(4-8px) (bukan slide jauh).
- Hover: transform scale(1.02) untuk kartu; shadow intensif.
- Page transitions (SPA): fade/soft slide 150ms.
- Skeleton shimmer: gradient animate, subtle.
- Semua dimatikan dengan prefers-reduced-motion.

## 6. Detail yang Membuat Premium

| Elemen | Detail |
|--------|--------|
| Focus ring | 2px + offset 2px, warna primary/white 60% |
| Scrollbar | Custom tipis (webkit), warna surface |
| Selection | `::selection` bg primary 20% |
| Placeholder | text-muted, tidak italic aneh |
| Empty avatar | Initial + gradient subtle |
| Image hover | Slight zoom (overflow hidden) + overlay gradient |
| Toggle | Switch dengan knob animasi, label jelas |
| Table | Row hover highlight, header sticky + blur |
| Kode block | Mono, syntax highlight halus, copy button |
| Toast | Slide-in kanan bawah, auto-dismiss, progress bar |

## 7. Keseimbangan & Restraint

- **Kurang lebih** — hapus elemen yang tidak menambah: border yang tidak perlu, warna ekstra, ikon dekoratif.
- **Satu efek per elemen** — satu card punya (shadow + hover) tapi tidak (shadow + gradient + animasi + border glow).
- **Ruangan bernafas** — padding 16-24px; seksyen 48-96px.
- **Konsistensi > kreativitas** — jangan variasi per halaman.
- **Fokus pada konten**: visual mendukung, bukan bersaing.

## 8. Tools & Workflow

- **Figma**: design tokens (variables), component library, auto-layout.
- **Storybook**: component gallery + states + a11y check.
- **Chromatic** (visual regression test) — mencegah desain drift.
- **Performance:** Lighthouse CI (LCP/INP/CLS budget).
- **Font**: Variable font (satu file banyak weight).

## Checklist

- [ ] Token terpusat (warna/radius/shadow/font/spacing)?
- [ ] Typography: family tunggal + weight, tracking display, mono data?
- [ ] Warna: palet berlapis, satu aksen, border halus?
- [ ] Shadow multi-layer, subtle (bukan gelap tebal)?
- [ ] Motion: durasi ≤ 250ms, easing konsisten, reduced-motion?
- [ ] Detail: focus ring, selection, scrollbar, placeholder?
- [ ] Restraint: tidak ada elemen berlebihan?
- [ ] Visual regression test jalan di CI?

## Inspirasi

- Linear.app, Stripe.com, Vercel.com — studi kasus langsung.
- Refactoring UI — buku.
- Every Layout, Design Engineering Handbook.



## Dark vs Light (Strategi Premium)

Produk premium sering default dark (developer tools, dashboards) — tapi light mode tetap harus dirawat:
- Light: `#fafafa` bg, `#18181b` text; border `rgba(0,0,0,.08)`.
- Dark: lihat token di atas; surface elevation WAJIB via brightness (bukan shadow tebal).
- Aksen: light (dark text on accent), dark (accent -20% brightness untuk teks di atasnya).
- Jangan lama pakai satu mode: user berpindah — token otomatis (CSS variables switch).

## Komponen Melekat (Signature Detail)

- **Sticky header dengan blur**: `backdrop-filter: blur(12px)` + `background: rgba(10,10,15,.7)` — konten scroll di bawah tetap terbaca.
- **Bento grid** (layout blok asimetris teratur) — dashboard/landing modern (Vercel-style).
- **Hover reveal**: aksi sekunder muncul saat hover (edit, delete) di card — dengan focus-visible fallback.
- **Command palette** — Cmd+K untuk akses cepat (produk power-user).
- **Kosong elegan** — empty state dengan ilustrasi tipis + aksi (bukan teks "No data").

## Visual Regression (Jaga Kualitas)

1. Storybook stories untuk semua komponen + states.
2. Chromatic CI: diff screenshot setiap PR — approve/reject visual.
3. Playwright visual test untuk halaman kritis (viewport mobile + desktop).
4. Baseline: token perubahan = diff besar → review bersama designer.

## Prinsip "Praktis vs Mewah"

- Mewah (eye-candy): gradient excess, animasi bombastis, 3D — hanya untuk landing/hero.
- Praktis premium: konsistensi, hierarki, micro-detail, performance, aksesibilitas — untuk app sehari-hari.
- Golden rule: kalau elemen tidak menambah kejelasan, hapus.

---

  audited
---