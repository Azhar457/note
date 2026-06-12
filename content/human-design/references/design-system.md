# Human Design — Design System Reference

## Visual Identity Principles

Human Design sits at the intersection of science and mysticism. The design language must reflect:

- **Ancient depth** — sacred geometry, warm parchment, golden ratio
- **Modern clarity** — clean layouts, readable hierarchy, functional precision
- **Esoteric soul** — subtle symbolism, celestial textures, reverent spacing

---

## Color Palettes

### Primary Palette — Celestial Earth

```css
:root {
  --hd-bg-primary: [[FAF7F2]];
  --hd-bg-secondary: [[F0EAE0]];
  --hd-bg-dark: [[1C1409]];
  --hd-gold: [[C8A96E]];
  --hd-gold-light: [[E8D5A8]];
  --hd-gold-dark: [[8B6B35]];
  --hd-earth: [[7B4E2D]];
  --hd-ink: [[1A1208]];
  --hd-muted: [[8B7355]];
  --hd-white: [[FFFDF9]];
}
```

### Dark Mode (Cosmic)

```css
.dark-mode {
  --hd-bg-primary: [[0D0A05]];
  --hd-bg-secondary: [[1C1409]];
  --hd-gold: [[D4B896]];
  --hd-ink: [[F5ECD8]];
  --hd-muted: [[9E8A6E]];
}
```

### Type-Specific Accent Colors

```css
/* Assign to each Human Design Type */
--hd-manifestor: [[8B3A52]]; /* deep rose */
--hd-generator: [[3D6B3F]]; /* forest green */
--hd-mangen: [[4A7A6B]]; /* teal green */
--hd-projector: [[3A4E8B]]; /* deep blue */
--hd-reflector: [[7B5E8B]]; /* violet */
```

---

## Typography Implementation

Always import from Google Fonts. Choose ONE of these pairings:

### Pairing A — Mystical Editorial (default recommendation)

```html
<link rel="preconnect" href="https://fonts.googleapis.com" />
<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
<link
  href="https://fonts.googleapis.com/css2?family=Cinzel:wght@400;600;700&family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&display=swap"
  rel="stylesheet"
/>
```

```css
--font-display: "Cinzel", serif;
--font-body: "Cormorant Garamond", serif;
--font-size-display: clamp(2rem, 5vw, 4rem);
--font-size-h1: clamp(1.75rem, 3.5vw, 3rem);
--font-size-body: clamp(1rem, 1.5vw, 1.125rem);
--line-height-body: 1.75;
--letter-spacing-display: 0.08em;
--letter-spacing-caps: 0.15em;
```

### Pairing B — Modern Esoteric

```html
<link
  href="https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Spectral:ital,wght@0,300;0,400;1,300&display=swap"
  rel="stylesheet"
/>
```

```css
--font-display: "Playfair Display", serif;
--font-body: "Spectral", serif;
```

### Pairing C — Clean Spiritual

```html
<link
  href="https://fonts.googleapis.com/css2?family=Marcellus+SC&family=Jost:ital,wght@0,300;0,400;0,500;1,300&display=swap"
  rel="stylesheet"
/>
```

```css
--font-display: "Marcellus SC", serif;
--font-body: "Jost", sans-serif;
```

---

## Bodygraph SVG Layout

```
Approximate pixel positions in a 400×550 canvas:

Centers:
  HEAD:   { cx: 200, cy: 40,  r: 30 }  — Triangle (top)
  AJNA:   { cx: 200, cy: 115, r: 30 }  — Triangle (inverted)
  THROAT: { cx: 200, cy: 195, r: 30 }  — Square
  G/SELF: { cx: 200, cy: 275, r: 30 }  — Diamond/Rhombus
  HEART:  { cx: 140, cy: 245, r: 28 }  — Triangle
  SACRAL: { cx: 200, cy: 365, r: 30 }  — Square
  SPLEEN: { cx: 130, cy: 320, r: 28 }  — Triangle
  SOLAR:  { cx: 270, cy: 320, r: 28 }  — Triangle
  ROOT:   { cx: 200, cy: 450, r: 30 }  — Square

Channels are lines connecting gate midpoints between centers.
Each gate is at roughly halfway along the channel toward its center.
```

**SVG rendering rules:**

- Defined center: `fill="var(--hd-gold)"` + `stroke="var(--hd-stroke)"`
- Undefined center: `fill="none"` + `stroke="var(--hd-stroke)"` + `stroke-dasharray="4 2"` (subtle dashed)
- Active channel: `stroke="var(--hd-gold)"` `stroke-width="3"`
- Inactive channel: `stroke="var(--hd-channel-inactive)"` `stroke-width="1.5"`

---

## Layout Patterns

### Card Component

```css
.hd-card {
  background: var(--hd-white);
  border: 1px solid var(--hd-gold-light);
  border-radius: 2px; /* intentionally sharp — sacred geometry */
  padding: 2rem 2.5rem;
  box-shadow: 0 2px 20px rgba(200, 169, 110, 0.08);
  position: relative;
}
.hd-card::before {
  content: "";
  position: absolute;
  top: 6px;
  left: 6px;
  right: -6px;
  bottom: -6px;
  border: 1px solid var(--hd-gold-light);
  border-radius: 2px;
  z-index: -1;
  opacity: 0.4;
}
```

### Section Divider (Ornamental)

```css
.hd-divider {
  text-align: center;
  margin: 3rem 0;
  color: var(--hd-gold);
  letter-spacing: 0.3em;
  font-size: 0.875rem;
}
.hd-divider::before,
.hd-divider::after {
  content: "——— ✦ ———";
}
```

### Type Badge

```css
.hd-type-badge {
  display: inline-block;
  padding: 0.25em 1em;
  border: 1px solid currentColor;
  border-radius: 100px;
  font-family: var(--font-display);
  font-size: 0.75rem;
  letter-spacing: 0.15em;
  text-transform: uppercase;
}
```

---

## Animation Guidelines

```css
/* Entry animation — use for charts and cards */
@keyframes hd-reveal {
  from {
    opacity: 0;
    transform: translateY(16px);
  }
  to {
    opacity: 1;
    transform: translateY(0);
  }
}

/* Gate pulse — defined center on load */
@keyframes hd-pulse {
  0%,
  100% {
    box-shadow: 0 0 0 0 rgba(200, 169, 110, 0.4);
  }
  50% {
    box-shadow: 0 0 0 8px rgba(200, 169, 110, 0);
  }
}

.hd-defined {
  animation: hd-pulse 3s ease-in-out infinite;
}
.hd-chart {
  animation: hd-reveal 0.6s ease-out forwards;
}
```

Stagger chart center reveals with `animation-delay`:

- HEAD: 0.1s, AJNA: 0.2s, THROAT: 0.3s, etc.

---

## Accessibility Checklist

- [ ] Color contrast: body text ≥ 4.5:1, large text ≥ 3:1
- [ ] Defined/Undefined centers: not distinguished by color alone (use pattern or label)
- [ ] All SVG elements have `<title>` or `aria-label`
- [ ] Interactive elements (buttons, inputs) have visible focus ring
- [ ] Font size minimum 16px for body
- [ ] `prefers-reduced-motion` respected:

```css
@media (prefers-reduced-motion: reduce) {
  *,
  *==before,
  *==after {
    animation: none !important;
    transition: none !important;
  }
}
```
