---
title: Industrial Brutalist UI
tags: [frontend, ui, design, brutalist]
aliases: [industrial-brutalist-ui]
---
# Industrial Brutalist UI

Brutalist UI (web brutalism) adalah gaya desain yang menonjolkan: raw structure, typography besar, warna kontras, border tegas, tanpa hiasan — estetika "industrial". Sumber inspirasi: arsitektur brutalist (beton, geometri, fungsi > ornamen) dan interface teknis (terminal, kontrol industri, blueprint).

## Prinsip Desain

1. **Function over decoration** — elemen punya alasan; dekorasi minimal.
2. **Raw structure** — tampilkan grid/struktur apa adanya (border, outline terlihat).
3. **Typography dominance** — font besar, bold, mono; hirarki jelas.
4. **Limited palette** — 2-3 warna (sering: off-white/krem, hitam, satu aksen industri seperti kuning safety/merah).
5. **Straight edges** — radius 0 atau sangat kecil; border 2-4px tegas.
6. **Texture** — noise, grid pattern, scanline, halftone (subtle).
7. **Utility/technical elements** — status indicators, labels ala panel kontrol, angka/monospace.

## Anatomi Komponen

### Header / Nav
- Nama site besar (display font, uppercase).
- Nav: teks polos + border bawah saat hover/active; no dropdown mewah.
- Aksen: nomor indeks (01, 02, 03), status dot (● online).

### Typography
- Font: mono (JetBrains Mono, IBM Plex Mono) untuk data/label; grotesk (Archivo, Space Grotesk) untuk display.
- Ukuran: h1 3-5rem; caption uppercase 0.7-0.8rem letter-spacing 0.1em.
- Kontras: hitam diatas krem; aksen kuning untuk penting.

### Kartu / Panel
- Border 2-3px solid; shadow offset (hard shadow: `box-shadow: 4px 4px 0 #000` — teknik "neo-brutalist").
- Corner tags (kode panel: "SYS-01"), status bar di bawah.

### Form Controls
- Input: border tegas, background putih/krem, focus = background kuning/akasen.
- Button: sudut kotak, shadow keras saat idle, translate saat active (`active { transform: translate(2px,2px); box-shadow: none; }`).
- Checkbox/radio: kotak besar custom.

## CSS Approach (Contoh Kode)

```css
:root {
  --bg: #f4f1ea;        /* krem industrial */
  --ink: #1a1a1a;       /* hitam */
  --accent: #eab308;    /* kuning safety */
  --border: 3px solid var(--ink);
  --hard-shadow: 5px 5px 0 var(--ink);
}

body { background: var(--bg); color: var(--ink);
       font-family: "Archivo", sans-serif; }
h1, h2, h3 { font-family: "Space Grotesk", sans-serif;
             text-transform: uppercase; letter-spacing: -0.02em; }

.card {
  border: var(--border);
  box-shadow: var(--hard-shadow);
  background: #fff;
  padding: 1.5rem;
}
.card:hover { transform: translate(-2px, -2px);
              box-shadow: 7px 7px 0 var(--ink); }

button {
  border: var(--border); background: var(--accent);
  font-weight: 700; text-transform: uppercase; padding: .6rem 1.2rem;
  cursor: pointer; box-shadow: 4px 4px 0 var(--ink);
}
button:active { transform: translate(4px, 4px); box-shadow: none; }
```

## Kapan Memakai (Use Cases)

1. **Developer tools / internal dashboards** — estetika teknis cocok (status, data density).
2. **Portfolio/studio** — kesan kuat, memorable.
3. **Tech/security blogs** — bond dengan pembaca teknis.
4. **Landing page eksperimen** — diferensiasi (jangan ikut tren cookie-cutter).
5. **Creative/art projects** — ekspresi visual.

## Kapan TIDAK

1. Produk mainstream yang butuh trust (e-commerce, bank, health) — user bisa merasa "rusak".
2. Konten panjang untuk pembaca umum (keterbacaan typography besar mengganggu).
3. Mobile-heavy apps dengan banyak form (density brutal = sulit di layar kecil) — atau redesign adaptif.

## Aksesibilitas (Jangan Dikorbankan)

- Kontras warna: hitam/krem = aman; aksen kuning hanya untuk elemen besar/border (jangan teks kecil).
- Focus state terlihat jelas (outline 3px).
- Jangan andalkan warna saja (plus icon/label).
- Ukuran font tetap responsif (clamp).
- Motion: hover transform halus (150ms), jangan berlebihan.

## Inspirasi & Referensi

- Brutalist Websites (brutalistwebsites.com) — galeri.
- Neo-brutalism trend (2022-2024) — playfully harsh, shadow keras.
- Industrial design: panel kontrol pabrik, HMI (human-machine interface), blueprint.
- Contoh implementasi: devtools, CLI tools sites, "Unix vibes" portfolio.

## Implementasi Cepat (Stack)

- **HTML/CSS saja** cukup; utility CSS (UnoCSS/Tailwind) untuk cepat.
- Font self-hosted (jangan Google Fonts di production sensitive) — performance + privacy.
- Grid: `display: grid; grid-template-columns: repeat(12, 1fr)` untuk layout teknikal.
- Dekorasi: CSS noise (svg data-uri), pattern grid via `background-image: linear-gradient(...) 2px 2px`.
- Status elemen: `data-state` attribute + CSS `[data-state="ok"]` dll.

## Checklist

- [ ] Palette 2-3 warna konsisten (krem/putih + hitam + 1 aksen)?
- [ ] Typography: display + mono + keterbacaan heading uppercase?
- [ ] Border & shadow konsisten (hard shadow)?
- [ ] Hover/active state jelas (transform + shadow)?
- [ ] Aksesibilitas: kontras AA, focus visible, tidak andalkan warna?
- [ ] Responsive (mobile tidak broken)?
- [ ] Font self-hosted / performant?



## Detail Implementasi: Dekorasi Industrial

### Noise & Texture (Subtle)
```css
/* noise via SVG data-uri (jangan gambar besar) */
body::after {
  content: "";
  position: fixed; inset: 0;
  background-image: url("data:image/svg+xml,...<filter noise>...");
  opacity: 0.05; pointer-events: none;
}
/* grid blueprint */
.bg-grid {
  background-image:
    linear-gradient(rgba(0,0,0,.08) 1px, transparent 1px),
    linear-gradient(90deg, rgba(0,0,0,.08) 1px, transparent 1px);
  background-size: 24px 24px;
}
```

### Status & Data Elements
```html
<!-- panel kontrol vibe -->
<div class="panel">
  <header><span class="tag">SYS-01</span><span class="dot ok"></span> API Gateway</header>
  <dl class="metrics">
    <div><dt>REQ/S</dt><dd>1,204</dd></div>
    <div><dt>P95</dt><dd>42ms</dd></div>
    <div><dt>ERR</dt><dd>0.02%</dd></div>
  </dl>
  <footer><code>UP 14d 06h</code></footer>
</div>
```

### Marquee / Terminal Bar
- Header bawah/atas dengan teks berjalan ala ticker mesin (CSS animation, pause on hover).
- Terminal window component: title bar (• • •) + mono content + blinking cursor.

## Tokopedia Toko Estetika — Anti-pattern di Brutalist

1. **Terlalu banyak shadow** — semua elemen hard-shadow = noisy; batasi ke elemen interaktif (card, button).
2. **Warna aksen berlebihan** — kuning di mana-mana = mata capek; aksen hanya untuk CTA & status kritis.
3. **Typography display untuk paragraf** — heading besar boleh; body tetap readable (16px+, line-height 1.5).
4. **Animasi berlebih** — brutalist = tegas; animasi halus (150ms) bukan bounce berlebihan.
5. **Memaksa semua halaman brutal** — halaman form/auth bisa tetap clean, biarkan bagian showcase yang ekspresif.

## Responsive Adaptation

- Mobile: kurangi ukuran h1 (3rem → 2rem), border 3px → 2px, shadow 5px → 3px.
- Touch target ≥ 44px — button padding besar.
- Table: horizontal scroll atau card layout di mobile.
- Dense metrics: 2 kolom grid di mobile (bukan 4).

---

  audited
---