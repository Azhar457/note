---
title: Design Taste Frontend
tags: [frontend, design, ui]
aliases: [design-taste-frontend]
---
# Design Taste — Frontend Engineering

"Design taste" = kemampuan menilai dan mengeksekusi estetika: kapan sesuatu terlihat baik, profesional, dan konsisten — bukan sekadar "cantik" tapi sesuai konteks & tujuan. Skill ini yang membedakan frontend engineer yang membuat produk terasa polished vs sekadar fungsional.

## Prinsip Inti

1. **Hierarki visual** — elemen penting lebih menonjol: ukuran, warna, kontras, spacing. User harus tahu "di mana mulai membaca".
2. **Konsistensi** — spacing scale, warna, font, radius dipakai sistem (design token), bukan tebakan per halaman.
3. **Kesederhanaan (less is more)** — kurangi elemen yang tidak membantu. Tiap elemen harus punya alasan.
4. **Alignment** — grid & baseline; jangan elemen "hampir sejajar" (visible misalignment = terlihat broken).
5. **Spacing over decoration** — ruang kosong (whitespace) meningkatkan kejelasan; jangan isi semua area.
6. **Konteks & purpose** — desain untuk pengguna: dashboard padat vs marketing landing luas — beda tujuannya.

## Spacing & Rhythm

- Gunakan scale: 4px base → 4, 8, 12, 16, 24, 32, 48, 64. (atau 8px scale utk konsistensi besar).
- **Vertical rhythm**: heading & paragraf konsisten (margin 1.5rem, line-height 1.5-1.6).
- **Density**: high-density (tool, dashboard) vs comfortable (reading, form).
- Jangan spacing acak: kalau dua elemen dekat = terkait; jauh = berbeda.

## Typography

1. **Pilih 2 font maksimal** (display + body); mono untuk data/kode.
2. **Ukuran sistem**: 12, 14, 16 (body), 20, 24, 30, 36 (heading) — fluid dengan `clamp()`.
3. **Line-height**: 1.4-1.6 body; heading 1.1-1.25.
4. **Letter-spacing**: uppercase small caps +0.05-0.1em; jangan negative kecuali display besar.
5. **Kontras teks**: jangan grey-on-grey (#999 di #f5); target #4a4a4a minimum untuk body di background terang.
6. **Font loading**: self-host + `font-display: swap`; jangan blocking render 3s.

## Warna

- **Palette**: base (bg/text) + primary + secondary + semantic (success/warning/danger/info).
- **Neutral ramp**: 9-10 step (50-950) untuk bg/border/text.
- **Aksen**: 1 warna aksen (CTA), jangan 5 warna mencolok.
- **Semantic dengan aksesibilitas**: error merah + ikon (bukan warna saja); kontras AA 4.5:1 teks.
- **Mode gelap**: bukan sekadar invert — sesuaikan saturation; surface elevation via warna, bukan shadow gelap.

## Shadow & Elevation

- Shadow scale: 1 (halus), 2 (card), 3 (modal/dropdown), 4 (drawer).
- Elevasi: elemen terapung = lebih penting (modal > dropdown > card).
- Jangan shadow tebal di semua elemen (terlihat murahan/berantakan).

## Komponen: Detail yang Membuat Polished

| Detail | Buruk | Baik |
|--------|-------|------|
| Button loading | Hilang | Spinner + disabled + tidak berubah ukuran |
| Empty state | "No data" | Ilustrasi + aksi (tombol retry/create) |
| Error inline | Alert global doang | Field error + pesan jelas + focus |
| Skeleton | Spinner halaman | Skeleton blok sesuai layout |
| Hover/focus | Hanya cursor | Hover subtle + focus ring terlihat |
| Toast | Muncul sembarangan | Posisi konsisten, stack, auto-dismiss + undo |
| Table | Row hover aneh | Row selection jelas, sort indicator, pagination info |
| Form | Submit tanpa feedback | Disabled state benar, label + helper, validation on blur |
| Image | Layout shift | `width/height` + aspect-ratio + blur-up placeholder |

## Micro-interaction

- Durasi: 100-200ms (UI kecil), 200-300ms (transisi), jangan 500ms+ (terasa lambat).
- Easing: `cubic-bezier(0.2, 0, 0, 1)` umum; hindari ease-in untuk muncul (slow start terasa berat).
- Feedback tiap aksi: klik (active state), toggle (switch animasi), submit (loading).
- Kurangi motion jika `prefers-reduced-motion`.

## Audit Design (Checklist Cepat)

- [ ] Hierarki: apa yang pertama dilihat user = yang paling penting?
- [ ] Spacing konsisten (scale, bukan tebakan).
- [ ] Typography: 2 font, size scale, line-height ok, kontras AA.
- [ ] Warna: palette disiplin, semantic jelas.
- [ ] Shadow: konsisten scale, tidak berlebihan.
- [ ] States: hover, focus, active, disabled, loading, error, empty — semua ada?
- [ ] Responsive: breakpoint tidak patah, touch target ≥ 44px.
- [ ] Dark mode (jika ada) benar-benar dark (bukan invert).
- [ ] Tidak ada elemen "hampir sejajar".
- [ ] Performance: font/image tidak blocking.

## Belajar Meningkatkan Taste

1. **Lihat banyak**: dribbble/awwwards/mobbin (tapi filter — banyak yang style-only); teliti produk yang dipakai orang (Stripe, Linear, Vercel, Raycast — perhatikan detail).
2. **Redesign latihan**: ambil UI biasa → buat lebih baik (tanpa fungsi berubah) — bandingkan.
3. **Review sendiri**: screenshot UI sendiri + checklist di atas.
4. **Baca prinsip**: Apple HIG, Material Design, Refactoring UI (buku), Design Systems (Shopify Polaris).
5. **Implementasi**: figma → code; pelajari CSS (grid, clamp, container queries) agar bisa eksekusi.

## Sumber

- Refactoring UI — prinsip praktis (buku/website).
- Stripe & Linear design (kasus top).
- Every Layout (every-layout.dev) — responsive layout patterns.
- System UI fonts vs custom — tradeoff.



## Design Review Ritual (Praktik Tim)

1. **Visual review mingguan** — 30 menit: buka 3 halaman utama, checklist di atas.
2. **Screenshot archive** — simpan screenshot tiap rilis (bandingkan regresi visual).
3. **Pair review** — engineer + designer (atau 2 engineer) lihat perubahan UI di PR (bukan cuma code review).
4. **User testing mini** — 3-5 user: "di mana kamu klik untuk X?" — validasi hierarki & affordance.
5. **Design debt log** — catat inkonsistensi (spacing, warna, component) → sprint backlog.

---

  audited
---