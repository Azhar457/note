# Human Design — SEO Content Reference

## Target Keyword Universe

### Primary Keywords (high intent)
- human design chart
- human design types
- human design reading
- human design calculator
- bodygraph chart

### Secondary Keywords (educational)
- human design generator strategy
- human design projector authority
- what is human design
- human design incarnation cross
- human design centers explained
- human design gates meaning

### Long-tail / Semantic Keywords
- how to read a human design bodygraph
- human design type [Manifestor/Generator/Projector/Reflector/MG]
- emotional authority human design
- sacral authority human design
- human design profile [1/3, 2/4, 5/1, etc.]

---

## On-Page SEO Template

### HTML Structure (mandatory)
```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  
  <!-- Primary Meta -->
  <title>[Target Keyword] — [Brand] | [Differentiator]</title>
  <meta name="description" content="[160 char max. Include primary keyword naturally. State clear benefit.]">
  <meta name="robots" content="index, follow">
  <link rel="canonical" href="[full URL]">
  
  <!-- Open Graph -->
  <meta property="og:type" content="article">
  <meta property="og:title" content="[Same as title or slight variation]">
  <meta property="og:description" content="[Can match meta description]">
  <meta property="og:image" content="[1200×630 image URL]">
  <meta property="og:url" content="[canonical URL]">
  
  <!-- Twitter Card -->
  <meta name="twitter:card" content="summary_large_image">
  <meta name="twitter:title" content="[Title]">
  <meta name="twitter:description" content="[Description]">
  
  <!-- Schema.org -->
  <script type="application/ld+json">
  {
    "@context": "https://schema.org",
    "@type": "Article",
    "headline": "[H1 text]",
    "description": "[Meta description]",
    "author": { "@type": "Person", "name": "[Author]" },
    "datePublished": "[ISO date]",
    "dateModified": "[ISO date]",
    "publisher": {
      "@type": "Organization",
      "name": "[Brand]",
      "logo": { "@type": "ImageObject", "url": "[logo URL]" }
    }
  }
  </script>
</head>
```

### For Tools/Calculators, use WebApplication schema:
```json
{
  "@context": "https://schema.org",
  "@type": "WebApplication",
  "name": "Human Design Chart Calculator",
  "applicationCategory": "LifestyleApplication",
  "description": "Generate your free Human Design bodygraph chart",
  "offers": { "@type": "Offer", "price": "0" }
}
```

---

## Content Structure Rules

### Heading Hierarchy
```
<h1>  — One per page. Contains primary keyword. Max 70 chars.
<h2>  — Major sections. Contains secondary keywords.
<h3>  — Subsections. Conversational / question-based works well.
<h4>  — Fine detail. Rarely needed.
```

### Optimal Article Structure for Human Design Content
```
Introduction (primary keyword in first 100 words)
└── Hook: what the reader will gain
└── Brief definition or context

[H2] What Is [Topic]? (definitional)
[H2] The [N] Types / Gates / Centers (list or breakdown)
  └── [H3] Each item with detail
[H2] How to [Apply / Read / Use] [Topic]
[H2] Common Misconceptions (great for featured snippets)
[H2] Frequently Asked Questions
└── Use <details><summary> or schema FAQ markup

CTA / Conclusion
└── Next step for reader
└── Internal link to related content
```

---

## Keyword Density & Placement

| Location | Rule |
|---|---|
| `<title>` | Primary keyword present |
| `<h1>` | Primary keyword present, naturally phrased |
| First 100 words | Primary keyword used once |
| `<h2>` tags | At least 2 contain secondary/related keywords |
| Body | 1–2% density (1–2 uses per 100 words) |
| Alt text | Descriptive, include keyword where natural |
| URL slug | `/human-design-[topic]/` — hyphens, no underscores |

**Red flags to avoid:**
- Same keyword in every H2
- Exact keyword match >3% density
- Keyword in unnatural positions ("Human Design Human Design chart…")

---

## FAQ Schema (Boosts Featured Snippets)

```html
<script type="application/ld+json">
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "What is Human Design?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Human Design is a system combining I-Ching, astrology, Kabbalah, and Hindu chakra teachings to create a unique bodygraph chart based on birth data."
      }
    },
    {
      "@type": "Question",
      "name": "How do I find my Human Design type?",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "Enter your birth date, time, and location into a Human Design calculator. The system calculates planetary positions to determine your type: Manifestor, Generator, Manifesting Generator, Projector, or Reflector."
      }
    }
  ]
}
</script>
```

---

## Internal Linking Strategy

Always include 2–4 internal links per article:
- One to the chart calculator/tool
- One to the relevant Type page
- One to an authority/strategy explanation
- One to a foundational "What is Human Design" page

Anchor text: descriptive, keyword-relevant — never "click here."

---

## Content Quality Signals

### E-E-A-T (Experience, Expertise, Authoritativeness, Trust)
- Cite Ra Uru Hu and the IHDS (International Human Design School) as source authorities where appropriate
- Add author bio if publishing under a practitioner's name
- Include "last updated" date on educational content
- Note when information is interpretation vs. original system teaching

### Readability
- Target Flesch-Kincaid Grade 8–10 for general audience
- Sentences: avg < 20 words
- Paragraphs: max 4 sentences
- Use bullet lists for comparisons, numbered lists for steps

### Core Web Vitals Targets
- LCP < 2.5s (optimize font loading with `font-display: swap`)
- CLS < 0.1 (set explicit width/height on images and SVG charts)
- FID/INP < 100ms (defer non-critical JS)

```css
/* Font loading optimization — always use */
@font-face {
  font-display: swap; /* prevents invisible text flash */
}
```
