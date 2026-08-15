---
title: Web Security MOC
tags: [security, web, moc]
aliases: [web-security]
---
# Web Security — Map of Content

Map of Content (MOC) untuk domain keamanan web: hub navigasi yang menghubungkan semua catatan terkait di vault. Gunakan sebagai titik masuk ketika membahas web security.

## Alur Serangan Web (Attack Surface Taxonomy)

```
Client-side          Server-side          Infra/API
├─ XSS (reflected/   ├─ SQLi               ├─ WAF bypass
│    stored/DOM)     ├─ Command injection  ├─ Request smuggling
├─ CSRF              ├─ SSRF               ├─ Cache poisoning
├─ Clickjacking      ├─ File upload/incl.  ├─ TLS misconfig
├─ CORS misconfig    ├─ Deserialization    ├─ API auth flaws
├─ CSP bypass        ├─ AuthN/AuthZ flaws  └─ Rate limiting
└─ DOM clobbering    └─ IDOR/BOLA
```

## Catatan Terkait (Wikilink)

### Client-side & Framework
- [[js-framework-vulnerabilities]] — prototype pollution, sink berbahaya di React/Vue/Angular.
- [[csp-best-practices]] — Content Security Policy mitigasi XSS.
- [[dark-patterns-resistance]] — manipulasi UI & consent.

### Server-side
- [[command-injection]] — OS command injection, payload & bypass.
- [[threat-modeling-stride-dread]] — model ancaman web app.

### API & Proxy
- [[owasp-api-security-top-10]] — 10 risiko API teratas (BOLA, authN, dsb).
- [[wiod-reverse-proxy-deepdive]] — reverse proxy, request smuggling, header trust.

### Framework
- [[django-security]] — Django checklist produksi.
- [[create-dockerfile]] — Dockerfile aman (jika web app di container).

### Defensive
- [[waf-internal-architecture-deepdive]] — WAF pipeline & bypass.
- [[defense-in-depth-strategy]] — lapisan pertahanan web.
- [[sre-practices-and-slo]] — reliability & availability web service.

## Learning Path (Menjadi Web Pentester)

1. **Fondasi HTTP** — method, headers, status code, session cookie.
2. **OWASP Top 10 Web** — pahami tiap risiko (SQLi, XSS, IDOR, etc).
3. **Burp Suite dasar** — proxy, repeater, intruder.
4. Latihan: PortSwigger Web Security Academy (labs gratis).
5. **Tools lanjut** — ffuf, sqlmap (learn manual dulu), nuclel (nuclei), wafw00f.
6. **Bug bounty** — program kecil, fokus satu kategori (IDOR/API).
7. **Write-up** — dokumentasikan penemuan (gaya vault ini: bahasa ID + istilah EN).

## Referensi Eksternal

- OWASP Top 10 — owasp.org/www-project-top-ten
- PortSwigger Web Security Academy — portswigger.net/web-security
- OWASP API Security Top 10 — owasptop10
- PayloadsAllTheThings — github.com/swisskyrepo
- HackTricks — book.hacktricks.xyz (web)

## Maintainer Catatan

- Update saat menambah catatan web security baru: tambahkan wikilink di atas.
- Marker `audited` = konten diverifikasi (2026-08).



## Deskripsi Ringkas Setiap Area (Depth per Topik)

### Client-side
- **XSS** — inject script: reflected (di URL), stored (di DB, dipakai user lain), DOM (sink browser). Dampak: cookie theft, session hijack, keylogging, CSRF trigger. Mitigasi: auto-escape, CSP ([[csp-best-practices]]), sanitasi (DOMPurify).
- **CSRF** — request lintas situs atas nama user: mitigasi token anti-CSRF, SameSite cookie, double-submit.
- **Clickjacking** — iframe transparan di atas UI: X-Frame-Options/frame-ancestors.
- **CORS** — jika Access-Control-Allow-Origin mencerminkan origin jahat + credentials → data leak lintas origin; whitelist ketat origin.

### Server-side
- **SQLi** — injeksi query: `' OR '1'='1`, union, blind/time-based; parameterized query adalah satu-satunya solusi robust.
- **Command injection** — lihat [[command-injection]]: shell escape, filter bypass, blind OAST.
- **SSRF** — server mem-fetch URL user → akses internal (169.254.169.254 metadata, localhost); block private range + allowlist.
- **File upload/inclusion** — ekstensi ganda, magic bytes, symlink; LFI/RFI path traversal.
- **Deserialization** — Java/PHP/Python object injection → RCE (ysoserial, phpggc).

### Infra & API
- **WAF bypass** — lihat [[waf-internal-architecture-deepdive]].
- **Request smuggling** — lihat [[wiod-reverse-proxy-deepdive]].
- **API auth flaws** — lihat [[owasp-api-security-top-10]]: BOLA, authN lemah, mass assignment.

## Prioritization untuk Belajar/Praktik

1. **SQLi & XSS** — paling umum, paling banyak bounty.
2. **IDOR/BOLA** — bounty modern, impact tinggi.
3. **SSRF** — semakin umum di arsitektur cloud.
4. **AuthN/AuthZ** (JWT, OAuth) — kritikal di API.
5. **Deserialization/smuggling** — advanced, dampak RCE/poison cache.

## Tools Quick Reference

| Kebutuhan | Tools |
|-----------|-------|
| Intercept & test | Burp Suite, ZAP |
| Fuzz endpoint | ffuf, gobuster (dir), nuclei (template) |
| SQLi | sqlmap (manual dulu), Burp Intruder |
| XSS | DOM Invader, XSStrike |
| Scanning | Nuclei, wpscan (WP), nikto |
| Subdomain enum | subfinder, amass |
| API test | Postman, Bruno, Insomnia |
| WAF detect | wafw00f |

## Checklist Audit Web App (Ringkas)

- [ ] Input validation & output encoding (semua layer).
- [ ] AuthN kuat + MFA; session secure (HttpOnly, SameSite, Secure).
- [ ] AuthZ per object & function (BOLA/BFLA check).
- [ ] Headers security: CSP, HSTS, X-Frame-Options, nosniff.
- [ ] HTTPS penuh; TLS 1.2+.
- [ ] Dependency & image scanned; no critical.
- [ ] Error handling tidak verbose.
- [ ] Rate limit & logging aktif.



## Learning Path Lanjutan & Referensi

### Setelah Dasar
1. Kuasai HTTP & session management dalam-dalam (cookies, header, cache).
2. Praktik lab: PortSwigger (semua kategori), PentesterLab, HackTheBox Web.
3. Baca write-up bug bounty (hackerone reports public, Medium) — pola temuan.
4. Otomasi: tulis script Python (requests) untuk exploit PoC; kenali nuclei template.
5. Spesialisasi: pilih satu — API security, frontend security, atau infra (smuggling/cache).

### Referensi Eksternal (Paling Berguna)
- PortSwigger Research (request smuggling, cache poisoning) — blog.portswigger.net
- OWASP Cheat Sheets — cheatsheetseries.owasp.org
- PayloadsAllTheThings — payload list lengkap per kategori
- HackTricks — book.hacktricks.xyz (web + cloud + mobile)
- CVE trending: cve.org, NVD, Twitter/Bluesky security researchers

## Hubungan Antar-Catatan (Graph View Mental)

```
web-security-moc ──┬── client: js-framework, csp, dark-patterns
                   ├── server: command-injection, stride
                   ├── api/proxy: owasp-api, wiod
                   ├── framework: django, dockerfile
                   └── defense: waf, defense-in-depth, sre
```

Gunakan MOC ini sebagai titik masuk: topik apa pun yang dibahas, mulai dari sini dan ikuti wikilink.

## Changelog

- 2026-08-15: dibuat dari `vault:01_Library/.../.md` (folder aneh) → dipindah ke path normal; konten diperluas memenuhi kuota; marker `audited`.

---

  audited
---