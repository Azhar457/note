---
name: human-design
description: >
  Create production-grade Human Design content, tools, charts, and visual
  experiences. Use this skill whenever the user asks about Human Design — including
  bodygraph charts, types (Manifestor, Generator, Manifesting Generator, Projector,
  Reflector), authority, profile, centers, channels, gates, circuits, strategy,
  incarnation crosses, transits, or any interpretation/coaching content. Also
  triggers for: building a Human Design calculator, creating a reading template,
  generating educational content about Ra Uru Hu's system, designing a chart
  visualization tool, explaining the I-Ching gate connections, writing marketing
  copy for HD practitioners, or producing any SEO-optimized blog/landing page
  about Human Design. Always use this skill even if the user asks tangentially —
  e.g., "I want to learn about my type" or "make me a page about auras" is a
  Human Design trigger.
---

# Human Design Skill

A comprehensive guide for creating Human Design content, tools, and visual experiences with custom typography, SEO optimization, and security-first principles.

---

## 1. Domain Overview

Human Design is a synthesis system combining:
- **I-Ching** (64 hexagrams → 64 Gates)
- **Kabbalah** (Tree of Life → Centers)
- **Astrology** (planetary positions at birth)
- **Hindu Chakra System** (9 Centers)
- **Quantum Physics** framing (neutrino stream, conditioning)

**Core vocabulary Claude must handle correctly** [Keyakinan tinggi]:

| Concept | Description |
|---|---|
| **Type** | Manifestor, Generator, Manifesting Generator, Projector, Reflector |
| **Strategy** | How each Type is designed to initiate/respond/wait |
| **Authority** | Decision-making center: Emotional, Sacral, Splenic, Ego/Heart, Self-Projected, Mental/Environmental, Lunar |
| **Profile** | 12 profiles from 6 lines (e.g., 1/3, 2/4, 5/1) |
| **Centers** | 9 energy centers; Defined = consistent, Undefined/Open = conditioned |
| **Channels** | 36 channels connecting pairs of gates |
| **Gates** | 64 gates mapped to I-Ching hexagrams |
| **Incarnation Cross** | Life theme from 4 gates (Conscious Sun/Earth + Unconscious Sun/Earth) |

> [Keyakinan sedang] Specific gate interpretations vary by practitioner tradition. When writing interpretive content, use Ra Uru Hu's original framework as the baseline unless the user specifies otherwise. Always note that professional HD analysis requires birth data verification.

---

## 2. Task Classification

Before proceeding, identify the user's task type:

### 2A — Visual / UI Output
Building a chart, calculator, page, or tool → Read `references/design-system.md` first.

### 2B — Educational / Blog Content
Writing articles, guides, explainers, or coaching scripts → Read `references/seo-content.md` first.

### 2C — Interpretation / Reading
Generating a personal HD reading, gate analysis, or transit report → Read `references/interpretation-guide.md` first.

### 2D — Security-Sensitive
Any tool collecting birth data, processing dates/times/locations, or making API calls → Read `references/security-guide.md` first. **This is mandatory for any interactive tool.**

---

## 3. Universal Constraints (Always Active)

### 3.1 — No Fabricated Data [HARD RULE]
- Never invent gate keywords, channel names, or type percentages
- If unsure of a specific gate's keyword: state "Ini perlu diverifikasi di sumber primer (The Definitive Book of Human Design)"
- Population statistics for Types (~70% Generators, etc.) are approximate [Keyakinan sedang] — label them as such

### 3.2 — Typography (No Default Fonts)
**NEVER use**: Arial, Inter, Roboto, Helvetica, system-ui, sans-serif as the primary font.

**Approved font pairings for Human Design context:**

```css
/* Option A — Mystical Editorial */
@import url('https://fonts.googleapis.com/css2?family=Cormorant+Garamond:ital,wght@0,300;0,400;0,600;1,300;1,400&family=Cinzel:wght@400;600&display=swap');
/* Display: Cinzel | Body: Cormorant Garamond */

/* Option B — Modern Esoteric */
@import url('https://fonts.googleapis.com/css2?family=Playfair+Display:ital,wght@0,400;0,700;1,400&family=Spectral:ital,wght@0,300;0,400;1,300&display=swap');
/* Display: Playfair Display | Body: Spectral */

/* Option C — Clean Spiritual */
@import url('https://fonts.googleapis.com/css2?family=Marcellus+SC&family=Jost:wght@300;400;500&display=swap');
/* Display: Marcellus SC | Body: Jost */

/* Option D — Cosmic Bold */
@import url('https://fonts.googleapis.com/css2?family=Tenor+Sans&family=DM+Serif+Display:ital@0;1&display=swap');
/* Display: DM Serif Display | Body: Tenor Sans */
```

Choose based on brand tone. Vary per generation — never reuse the same pairing twice without user confirmation.

### 3.3 — SEO Requirements (Always Embedded)
See `references/seo-content.md` for full checklist. Minimum requirements for any content output:
- Semantic HTML5 (`<article>`, `<section>`, `<h1>` hierarchy)
- Meta description ≤160 characters
- Target keyword in `<title>`, first `<h1>`, first paragraph, and at least one subheading
- Schema.org markup when building pages
- No keyword stuffing — natural density 1–2%
- Alt text on all visual elements

### 3.4 — Security-First (Always Active for Interactive Tools)
Any form, calculator, or data-collecting component MUST follow `references/security-guide.md`. Non-negotiable baseline:
- Input validation on ALL fields (date, time, location)
- No birth data stored client-side beyond session
- No third-party analytics scripts injected without disclosure
- CSP headers declared in code comments for deployment guidance
- XSS-safe rendering (no `innerHTML` with raw user input)

---

## 4. Chart Visualization Standards

When rendering a Bodygraph chart:

### 4.1 — Geometry
```
The Bodygraph uses a fixed 9-center layout:
HEAD (top center) → AJNA → THROAT → G/SELF (center)
     ↓                              ↓
  [left]  HEART/EGO        SACRAL  [right]
            ↓                ↓
         SPLEEN          ROOT (bottom)
```

Use SVG for chart rendering. Defined centers = filled/colored. Undefined = outlined only.

### 4.2 — Color System for Centers
```css
:root {
  --hd-defined: [[C8A96E]];       /* warm gold — defined/active */
  --hd-undefined: transparent; /* hollow — open/undefined */
  --hd-stroke: [[2D2417]];        /* dark brown — all outlines */
  --hd-channel-active: [[C8A96E]];
  --hd-channel-inactive: [[E8DDD0]];
  --hd-background: [[FAF7F2]];    /* warm parchment */
  --hd-text-primary: [[1A1208]];
  --hd-text-muted: [[8B7355]];
  --hd-accent: [[7B4E2D]];        /* earth red */
}
```

### 4.3 — Accessibility
- Minimum contrast ratio 4.5:1 for body text
- Defined vs Undefined centers must be distinguishable without color alone (use pattern fill as fallback)
- All SVG elements need `aria-label` or `<title>` tags

---

## 5. Content Tone Guidelines

| Context | Tone |
|---|---|
| Educational blog | Clear, grounded, accessible. Avoid jargon overload. |
| Coaching/reading | Empowering, specific, non-deterministic ("designed to…" not "you must…") |
| Technical/developer | Precise, factual, cite source system |
| Marketing copy | Evocative but honest — never promise outcomes HD cannot guarantee |

**Ethical boundary** [HARD RULE]: Human Design is a self-knowledge system. Never write content framing HD as medical advice, psychological diagnosis, or guaranteed life outcome predictor. Add a disclaimer when writing reading content.

---

## 6. Reference Files

| File | When to read |
|---|---|
| `references/design-system.md` | Before building any visual, chart, or UI |
| `references/seo-content.md` | Before writing any article, landing page, or meta content |
| `references/interpretation-guide.md` | Before writing readings, gate analyses, or type/authority explanations |
| `references/security-guide.md` | Before building any interactive tool, form, or calculator |

---

## 7. Output Checklist

Before delivering any output, verify:

- [ ] No fabricated HD facts — all claims are either [Keyakinan tinggi/sedang/rendah] labeled or flagged for verification
- [ ] Custom font loaded (not Arial/Inter/Roboto/system-ui)
- [ ] SEO meta elements present (for web output)
- [ ] Security constraints followed (for interactive tools)
- [ ] Ethical disclaimer present (for reading/interpretation content)
- [ ] Accessibility: contrast, aria labels, semantic HTML
- [ ] Tone matches task classification (2A/2B/2C/2D)
