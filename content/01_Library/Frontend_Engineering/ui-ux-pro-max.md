---
title: UI/UX Pro Max
tags: [frontend, ui, ux, design]
aliases: [ui-ux-pro-max]
---
# UI/UX Pro Max

Level lanjutan UI/UX: hierarki, informasi, states, dan "feel" produk yang matang. Ini bukan tentang tren visual, tapi keputusan desain yang berdampak pada hasil (konversi, usability, kepercayaan).

## 1. Hierarki Informasi (Information Architecture)

- **Satu halaman satu fokus** — tiap halaman punya primary action; sisanya sekunder.
- **F-pattern / Z-pattern** — tempatkan konten penting di path baca alami (kiri atas → bawah; hero → CTA).
- **Progressive disclosure** — tampilkan ringkasan dulu, detail di-request (expand, modal, drawer).
- **Content hierarchy**: judul → subjudul → paragraf → aksi; jangan semua sama besar.

## 2. State Design (Semua Kondisi)

| State | Burnik | Baik |
|-------|--------|------|
| Loading | Spinner kosong | Skeleton + progress |
| Empty | "No data" | Ilustrasi + tindakan (buat / coba lagi) |
| Error | Alert merah doang | Pesan jelas + solusi (retry, fix) |
| Partial | Tidak ada | Banner info + item yang load |
| Success | Tanpa feedback | Konfirmasi ringan + next step |

### Contoh Empty State
```html
<div class="empty">
  <svg ...aria-hidden="true"></svg>
  <h3>Belum ada transaksi</h3>
  <p>Transaksi pertama kamu akan muncul di sini.</p>
  <button>Buat transaksi</button>
</div>
```
Aturan: empty state = kesempatan konversi (ajak aksi), bukan teks mati.

## 3. Microcopy (Teks Antarmuka)

- **Tombol = aksi**: "Simpan perubahan", "Hapus akun" (bukan "OK", "Submit").
- **Error = solusi**: "Email tidak valid. Contoh: nama@domain.com" (bukan "Error 500 — terjadi kesalahan").
- **Confirm destructive**: "Hapus 3 file permanen? Tindakan tidak bisa dibatalkan." + tombol merah "Hapus permanen".
- **Copywriting tone**: konsisten (formal/ramah/teknis) — jangan campur.
- **Empty/helper**: jelaskan kenapa + apa berikutnya.

## 4. Form UX (Konversi & Kesalahan)

1. **Label selalu terlihat** (bukan placeholder-only — placeholder menghilang saat mengetik).
2. **Validasi**: on-blur (setelah keluar field) + inline; jangan menunggu submit untuk semua.
3. **Auto-format**: input telepon/rupiah diformat saat ketik; jangan tolak mentah.
4. **Simpan & autosave** — untuk form panjang, tampilkan status "Tersimpan 12:04".
5. **Multistep**: progress indicator + bisa kembali; simpan state.
6. **Keyboard**: Enter submit, tab order logis, focus pertama otomatis.

## 5. Accessibility (A11y) Lanjutan

- **Focus order**: tab melalui elemen interaktif dalam urutan yang masuk akal.
- **ARIA**: gunakan hanya saat perlu (`role="alert"` untuk error penting; `aria-live` untuk update dinamis) — jangan sembarang aria (lebih buruk dari tanpa).
- **Reduced motion**: `@media (prefers-reduced-motion: reduce) { * { animation-duration: .01ms !important; } }`.
- **Contrast**: teks ≥ 4.5:1; UI besar/ikon ≥ 3:1.
- **Screen reader test**: jalankan NVDA/VoiceOver minimal untuk halaman inti.

## 6. Performance sebagai UX

- **LCP < 2.5s** (hero/content terbesar cepat).
- **INP < 200ms** (interaksi responsif).
- **CLS < 0.1** (tidak lompat layout — set width/height media, reserve space untuk ads/toast).
- Image: modern format (AVIF/WebP), lazy loading, `fetchpriority` untuk hero.
- Font: self-host, subset, `font-display: swap`.
- JS: minimal bundle, route-level code splitting, tidak blocking render.

## 7. Dark Mode & Theme

- **Bukan invert** — surface elevation via warna: `bg-base` (paling gelap) → `bg-raised` → `bg-overlay`.
- Tingkatkan saturation untuk accent di dark (warna terlihat pudar).
- Border: `rgba(255,255,255,.12)` bukan putih solid.
- Simpan preferensi: `prefers-color-scheme` + toggle manual (persist localStorage).
- Kontras tetap AA di dark.

## 8. Desain untuk Kepercayaan

- **Buat transparan**: harga total sebelum checkout, biaya tersembunyi = red flag (lihat [[dark-patterns-resistance]]).
- **Keamanan terlihat**: badge SSL, "data dienkripsi", MFA onboarding — mengurangi friction saat transaksi.
- **Error yang tidak menyalahkan**: "Kami gagal memuat data, coba lagi" (bukan "Kesalahan kamu").
- **Konsistensi logika**: tombol tidak pindah posisi antar halaman; bahasa tidak berubah-ubah.

## 9. Review & Iterasi

1. **Heuristic evaluation** (Nielsen 10): visibility of status, match system-world, user control, consistency, error prevention, recognition > recall, flexibility, aesthetic minimalis, error recovery, help.
2. **Task-based usability test**: 5 user × 3 task — catat waktu & frustrasi.
3. **Analytics**: funnel (di mana user drop?), heatmap (klik aneh), session replay (jika etis — consent).
4. **A/B test** untuk keputusan penting (CTA copy, layout, harga display).

## Checklist Final

- [ ] Hierarki jelas (1 primary action/halaman)?
- [ ] Semua state (loading/empty/error/success) dirancang?
- [ ] Microcopy actionable & konsisten?
- [ ] Form: label, validasi inline, keyboard ok?
- [ ] A11y: focus, contrast, reduced motion, screen reader dasar?
- [ ] Performance budget (LCP/INP/CLS) terukur?
- [ ] Dark mode benar (bukan invert)?
- [ ] Kepercayaan: transparansi & error-friendly?
- [ ] Tested: 5 user task-based?



## Pola UX yang Sering Gagal (Anti-pattern)

1. **Placeholder sebagai label** — menghilang saat mengetik; user lupa isi field. Selalu label permanen.
2. **Loading tanpa progress** — spinner > 2s tanpa info = user kabur; gunakan skeleton + estimasi waktu ("Memuat 1.2MB…").
3. **Dropdown untuk 2-3 opsi** — radio lebih baik (terlihat semua).
4. **Toast spam** — 3 toast bersamaan = noise; queue + prioritas.
5. **Konfirmasi berlebihan** — "Yakin?" di setiap aksi membuat user mati rasa; konfirmasi hanya untuk destructive/irreversible.
6. **Register wall** — minta akun sebelum user lihat nilai produk; izinkan guest/lihat dulu.

## Proses Desain yang Efektif (Rapid)

1. **Wireframe** — struktur & prioritas (tanpa visual).
2. **Low-fi prototype** — Figma/Balsamiq, uji alur (5 user).
3. **High-fi** — visual + states.
4. **Dev handoff** — token + komponen (storybook), bukan gambar statis.
5. **Uji di production** (A/B/analytics) — keputusan berbasis data.

## Microcopy Library (Template)

- Login error: "Email atau kata sandi salah. Lupa kata sandi?"
- Empty cart: "Keranjangmu kosong. Lihat produk terlaris →"
- Deletion: "Nama file akan dihapus permanen. Lanjutkan?"
- Maintenance: "Kami sedang pemeliharaan singkat. Kembali dalam 15 menit."
- Update: "Versi baru 2.4 tersedia — perbaikan keamanan penting."

---

  audited
---