---
title: "CSS Layout Deep-Dive: Grid, Flexbox, Container Queries & Modern Patterns"
tags: [css, frontend, layout, web-development, responsive-design]
aliases: [CSS Layout, CSS Grid, Flexbox, Container Queries, Modern CSS]
status: pending
created: 2026-08-04
updated: 2026-08-04
cssclasses:
  - wide-table
  - callout

---

> [!abstract]
> Catatan komprehensif tentang **CSS Layout modern** — CSS Grid, Flexbox, Container Queries, `:has()` selector, CSS Nesting, logical properties, dan pola responsive design kontemporer. Vault punya [[frontend-engineering-react-architecture]] — catatan ini melengkapi sisi layout & styling yang diharapkan tim FE MspUrbansolv (14+ repo). Target: 2000+ kata, Bahasa Indonesia + istilah teknis English.

## Daftar Isi
1. [[#1. CSS Grid: Two-Dimensional Layout System]]
2. [[#2. Flexbox: One-Dimensional Layout System]]
3. [[#3. Subgrid: Nested Grid Alignment]]
4. [[#4. Container Queries: Component-Driven Responsive]]
5. [[#5. :has() Selector: Parent & Sibling Selection]]
6. [[#6. CSS Nesting: Native Selector Nesting]]
7. [[#7. Logical Properties: Writing-Mode Aware Spacing]]
7. [[#8. Modern Responsive Patterns: clamp(), min(), max()]]
9. [[#9. Position: Sticky & Modern Positioning]]
10. [[#10. Browser Support & CanIUse 2025]]
11. [[#References]]
12. [[#Koneksi ke Vault]]

## 1. CSS Grid: Two-Dimensional Layout System

CSS Grid adalah layout system **dua dimensi** (rows + columns) yang memungkinkan kontrol penuh atas placement item dalam grid container. Berbeda dengan Flexbox (satu dimensi), Grid cocok untuk layout level page/macro.

```css
.grid-container {
  display: grid;
  grid-template-columns: repeat(3, 1fr);  /* 3 kolom sama lebar */
  grid-template-rows: auto 1fr auto;      /* header, content, footer */
  gap: 24px;                              /* gutter antar item */
  grid-template-areas:
    "header header header"
    "sidebar content content"
    "footer footer footer";
}

.header    { grid-area: header; }
.sidebar   { grid-area: sidebar; }
.content   { grid-area: content; }
.footer    { grid-area: footer; }
```

| Property | Deskripsi | Contoh |
|:---------|:----------|:-------|
| `grid-template-columns` | Kolom eksplisit | `200px 1fr 2fr` |
| `grid-template-rows` | Baris eksplisit | `auto 1fr auto` |
| `repeat(n, track)` | Repetisi track | `repeat(4, 1fr)` |
| `minmax(min, max)` | Track fleksibel | `minmax(200px, 1fr)` |
| `grid-auto-flow` | Implicit placement | `dense` / `row` / `column` |
| `grid-auto-rows/cols` | Implicit track size | `minmax(100px, auto)` |

**Implicit vs Explicit grid**: Eksplisit = `grid-template-*` yang didefinisikan. Implicit = Grid menciptakan track otomatis saat item meluap.

```css
/* Implicit grid example */
.grid {
  display: grid;
  grid-template-columns: repeat(2, 1fr);  /* eksplisit: 2 kolom */
  grid-auto-rows: minmax(100px, auto);     /* implisit: tinggi otomatis */
}
```

## 2. Flexbox: One-Dimensional Layout System

Flexbox dirancang untuk **satu dimensi** — row ATAU column. Ideal untuk komponen, navigation, card, form, dan micro-layout.

```css
.flex-container {
  display: flex;
  flex-direction: row;      /* row | row-reverse | column | column-reverse */
  flex-wrap: wrap;          /* nowrap | wrap | wrap-reverse */
  justify-content: space-between;  /* main-axis alignment */
  align-items: center;      /* cross-axis alignment */
  gap: 16px;                /* modern gap property */
}

.flex-item {
  flex-grow: 1;             /* mengambil sisa space */
  flex-shrink: 1;           /* mengecil bila perlu */
  flex-basis: 200px;        /* initial size */
  /* shorthand: flex: 1 1 200px; */
}
```

| Property | Axis | Nilai | Efek |
|:---------|:----:|:------|:-----|
| `justify-content` | Main | `flex-start`, `center`, `space-between`, `space-around`, `space-evenly` | Alignment main axis |
| `align-items` | Cross | `stretch`, `center`, `flex-start`, `flex-end`, `baseline` | Alignment cross axis |
| `align-content` | Cross | (multi-line) | Alignment cross axis multi-line |
| `flex-grow` | Main | 0, 1, 2... | Berapa proporsi ambil sisa space |
| `flex-shrink` | Main | 0, 1, 2... | Berapa proporsi mengecil |
| `flex-basis` | Main | `auto`, `200px`, `0` | Initial size sebelum grow/shrink |

## 3. Subgrid: Nested Grid Alignment

**Subgrid** (`grid-template-rows: subgrid` / `grid-template-columns: subgrid`) memungkinkan nested grid menginherit track sizing dari parent grid. Tanpa subgrid, nested grid punya track sendiri yang tidak align dengan parent.

```css
.parent {
  display: grid;
  grid-template-columns: 200px 1fr 100px;
}

.child {
  display: grid;
  grid-template-columns: subgrid;  /* inherit 3 kolom dari parent */
  grid-column: 1 / -1;             /* span full width */
}
```

| Subgrid Value | Inherit From |
|:--------------|:-------------|
| `subgrid` (rows) | Parent `grid-template-rows` |
| `subgrid` (columns) | Parent `grid-template-columns` |
| `subgrid` (both) | Parent both axes |

**Browser support 2025**: ✅ Chrome 117+, Firefox 71+, Safari 16+, Edge 117+. **Global ~95%+**.

## 4. Container Queries: Component-Driven Responsive

**Container Queries** (`@container`) mengubah responsive design dari viewport-based ke **component-based**. Component bisa adapt ke ukuran container-nya sendiri, bukan viewport.

```css
.card-container {
  container-type: inline-size;      /* atau size, normal */
  container-name: card;             /* optional name */
}

@container card (min-width: 400px) {
  .card {
    display: flex;
    flex-direction: row;
  }
}

@container card (max-width: 399px) {
  .card {
    flex-direction: column;
  }
}
```

| Property | Nilai | Deskripsi |
|:---------|:------|:----------|
| `container-type` | `size`, `inline-size`, `normal` | Apa yang di-query container |
| `container-name` | custom-ident | Nama container (optional) |
| `@container` | `(condition)` | Query condition |

**Container Query Units**:
- `cqw` = 1% container width
- `cqh` = 1% container height
- `cqi` = 1% container inline size
- `cqb` = 1% container block size
- `cqmin` = min(cqi, cqb)
- `cqmax` = max(cqi, cqb)

```css
/* Typography responsif terhadap container, bukan viewport */
.card-title {
  font-size: clamp(1.5rem, 5cqw, 3rem);
}
```

**Browser support 2025**: ✅ Chrome 105+, Firefox 110+, Safari 16+, Edge 105+. **Global ~92%+**.

## 5. :has() Selector: Parent & Sibling Selection

`:has()` adalah **relational pseudo-class** yang memungkinkan seleksi berdasarkan descendant/sibling — "parent selector" yang selama ini tidak ada di CSS.

```css
/* Select card yang PUNYA image */
.card:has(img) { border-radius: 12px; }

/* Select label yang PUNYA invalid input */
label:has(+ input:invalid) { color: red; }

/* Select section yang PUNYA h2 di dalamnya */
section:has(h2) { padding-top: 2rem; }

/* Form validation styling tanpa JS */
form:has(:invalid) button[type="submit"] { opacity: 0.5; }
```

| Pattern | Artinya |
|:--------|:--------|
| `parent:has(child)` | Parent yang punya child |
| `prev:has(+ next)` | Previous sibling yang diikuti next |
| `ancestor:has(descendant)` | Ancestor yang punya descendant |
| `:not(:has(...))` | Tidak punya ... |

**Browser support 2025**: ✅ Chrome 105+, Firefox 121+, Safari 15.4+, Edge 105+. **Global ~92%+**.

## 6. CSS Nesting: Native Selector Nesting

CSS Nesting native (tanpa preprocessor) memungkinkan selector nested langsung di stylesheet.

```css
.card {
  padding: 1rem;
  border-radius: 8px;
  
  &--featured {
    border: 2px solid gold;
  }
  
  &:hover {
    box-shadow: 0 4px 12px rgba(0,0,0,0.15);
  }
  
  .card__title {
    font-size: 1.25rem;
    
    &:hover { color: var(--accent); }
  }
  
  @media (max-width: 600px) {
    padding: 0.5rem;
  }
}
```

| Syntax | Artinya |
|:-------|:--------|
| `&` | Parent selector reference |
| `&:hover` | Parent dengan pseudo-class |
| `&.modifier` | Parent dengan class modifier |
| `& > *` | Child selector langsung |

**Browser support 2025**: ✅ Chrome 120+, Firefox 117+, Safari 16.5+, Edge 120+. **Global ~85%+** (masih perlu fallback untuk Safari < 16.5).

## 7. Logical Properties: Writing-Mode Aware Spacing

**Logical properties** menggantikan physical properties (margin-top, padding-left) dengan properties yang aware terhadap `writing-mode`, `direction`, dan `text-orientation`.

| Physical | Logical (horizontal-tb) | Logical (vertical-rl) |
|:---------|:------------------------|:----------------------|
| `margin-top` | `margin-block-start` | `margin-inline-start` |
| `margin-bottom` | `margin-block-end` | `margin-inline-end` |
| `margin-left` | `margin-inline-start` | `margin-block-start` |
| `margin-right` | `margin-inline-end` | `margin-block-end` |
| `padding-top` | `padding-block-start` | `padding-inline-start` |
| `border-left` | `border-inline-start` | `border-block-start` |
| `width` | `inline-size` | `block-size` |
| `height` | `block-size` | `inline-size` |
| `top` | `inset-block-start` | `inset-inline-start` |
| `left` | `inset-inline-start` | `inset-block-start` |

```css
/* Logical spacing works for RTL & vertical writing automatically */
.element {
  margin-inline: auto;          /* center horizontal (both LTR/RTL) */
  margin-block: 1rem 2rem;      /* top/bottom in current writing mode */
  padding-inline-start: 1rem;   /* left in LTR, right in RTL */
  inline-size: 100%;            /* width in horizontal, height in vertical */
}
```

**Browser support 2025**: ✅ Chrome 87+, Firefox 41+, Safari 15+, Edge 87+. **Global ~96%+**.

## 8. Modern Responsive Patterns: clamp(), min(), max()

### clamp(min, preferred, max)
Fluid typography & spacing tanpa media queries:

```css
/* Fluid font size: minimum 1rem, preferred 2.5vw, maximum 2rem */
h1 { font-size: clamp(1rem, 2.5vw, 2rem); }

/* Fluid spacing */
.card { padding: clamp(1rem, 3vw, 2rem); }

/* Container-query aware */
.card-title { font-size: clamp(1.25rem, 4cqw, 2.5rem); }
```

### min() & max()
```css
/* Lebar: minimal 300px, maksimal 80% container */
.container { width: min(80%, 800px); }

/* Padding: minimal 1rem, tapi minimal 5vw */
.spacer { padding: max(1rem, 5vw); }
```

## 9. Position: Sticky & Modern Positioning

`position: sticky` adalah hybrid relative + fixed — element scroll normal sampai hit threshold, lalu jadi fixed.

```css
.header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--bg);
}

.sidebar {
  position: sticky;
  top: 64px;      /* di bawah header */
  height: calc(100vh - 64px);
  overflow-y: auto;
}
```

**Sticky container requirement**: parent harus punya `overflow` yang scrollable (bukan `hidden` atau `visible` default).

## 10. Browser Support & CanIUse 2025 Summary

| Feature | Chrome | Firefox | Safari | Edge | Global Support |
|:--------|:------:|:-------:|:------:|:----:|:--------------:|
| CSS Grid | 57+ | 52+ | 10.1+ | 16+ | ~98% |
| Flexbox | 29+ | 28+ | 9+ | 12+ | ~99% |
| Subgrid | 117+ | 71+ | 16+ | 117+ | ~95% |
| Container Queries | 105+ | 110+ | 16+ | 105+ | ~92% |
| :has() | 105+ | 121+ | 15.4+ | 105+ | ~92% |
| CSS Nesting | 120+ | 117+ | 16.5+ | 120+ | ~85% |
| Logical Properties | 87+ | 41+ | 15+ | 87+ | ~96% |
| clamp()/min()/max() | 79+ | 75+ | 13.1+ | 79+ | ~97% |
| aspect-ratio | 88+ | 89+ | 15+ | 88+ | ~95% |
| position: sticky | 56+ | 32+ | 6.1+ | 79+ | ~99% |

> **Catatan**: Global support dihitung dari caniuse.com data (processed via curl). Safari sering jadi bottleneck untuk features terbaru (Nesting, :has() early).

## References

1. CSS Grid Layout Module Level 1: https://www.w3.org/TR/css-grid-1/
2. CSS Flexible Box Layout Module Level 1: https://www.w3.org/TR/css-flexbox-1/
3. CSS Container Queries Module Level 1: https://www.w3.org/TR/css-contain-3/
4. Selectors Level 4 — :has(): https://www.w3.org/TR/selectors-4/#relational
5. CSS Nesting Module: https://www.w3.org/TR/css-nesting-1/
6. CSS Logical Properties and Values Level 1: https://www.w3.org/TR/css-logical-1/
7. MDN — CSS Grid: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_grid_layout
8. MDN — Flexbox: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_flexible_box_layout
9. MDN — Container Queries: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_container_queries
10. MDN — :has(): https://developer.mozilla.org/en-US/docs/Web/CSS/:has
11. MDN — CSS Nesting: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_nesting
12. CanIUse: https://caniuse.com/
13. Every Layout: https://every-layout.dev/ (composable layout primitives)
14. CSS-Tricks Complete Guide to Grid: https://css-tricks.com/snippets/css/complete-guide-grid/
15. CSS-Tricks Complete Guide to Flexbox: https://css-tricks.com/snippets/css/a-guide-to-flexbox/

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[frontend-engineering-react-architecture]] | FE architecture — layout adalah foundation |
| [[design-patterns-gof]] | Layout patterns vs design patterns |
| [[browser-engine-architecture]] | Browser rendering engine & layout phase |
| [[high-end-visual-design]] | Design system & spacing tokens |
| [[industrial-brutalist-ui]] | Brutalist layout patterns |
| [[layout-spacing]] | Spacing tokens & semantic CSS |
| [[design-taste-frontend]] | Anti-slop frontend — layout quality |
| [[ui-ux-pro-max]] | UI/UX intelligence & design systems |