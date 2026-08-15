---
title: JS Framework Vulnerabilities
tags: [security, web, javascript]
aliases: [js-framework-vulnerabilities]
---
# JS Framework Vulnerabilities

Framework JS modern (React, Vue, Angular, Svelte) mengurangi banyak XSS klasik karena otomatis escape output (React: JSX text nodes escape; Vue: template syntax escaped; Angular: sanitization). Tapi framework juga membawa kelas kerentanan baru: prototype pollution, sink berbahaya (`dangerouslySetInnerHTML`, `v-html`, `[innerHTML]`), supply chain dependency, dan state management leaks.

## Kelas Kerentanan

### 1. Prototype Pollution
- `Object.assign`, `_.merge`, `_.defaultsDeep`, `JSON.parse` + recursive merge di input user.
- Impact: Property injection → RCE via `child_process` options, atau DoS, atau XSS via `innerHTML` pollution.
- Contoh CVE: CVE-2019-10744 (lodash `defaultsDeep` prototype pollution), CVE-2020-8203 (lodash < 4.17.21).
- Deteksi: `curl -X POST -d '{"__proto__":{"polluted":"1"}}'`, cek `Object.prototype.polluted`.
- Pencegahan: gunakan `_.merge` dengan whitelist keys, freeze prototype (`Object.freeze(Object.prototype)`), JSON.parse dengan reviver yang skip `__proto__`.

### 2. DOM Clobbering & Sink Berbahaya
- React `dangerouslySetInnerHTML`, Vue `v-html`, Angular `[innerHTML]` — konten HTML mentah (XSS jika ada input user).
- Sink lain: `document.write`, `eval`, `new Function`, `location.href = userInput`, `innerHTML`, `outerHTML`, `insertAdjacentHTML`.
- DOM clobbering: `<form name="x">` → `window.x` → clobber global variables → bypass sanitizer.

### 3. XSS via Template Injection
- Client-side template engines (handlebars, ejs, mustache) dengan input user → code execution.
- Server-side: `res.render('page', { data: userInput })` — proper escaping beda tiap engine.

### 4. Dependency / Supply Chain
- `npm install` tanpa lockfile → version drift.
- Typo-squatting: `react-dompurify` vs `dompurify` (paket fake).
- Malicious package: event-stream (2018), ua-parser-js (2021) — code injection via dependencies.
- SCA tools: npm audit, Snyk, Dependabot, osv-scanner.
- Prevention: lockfile commit, npm audit in CI, verify package integrity, private registry mirror.

### 5. State Management / Sensitive Data
- Redux/Pinia store menyimpan token/PII di memory — XSS sekali → steal dari store.
- SSR: data serialized ke HTML (`window.__INITIAL_STATE__`) → bisa bocor if not stripped.
- Client-side storage (localStorage) — token di localStorage rentan XSS; prefer cookie HttpOnly + SameSite.

## XSS Context di SPA

| Sink | Escaping Framework | Risiko |
|------|--------------------|--------|
| JSX text `{var}` | Auto-escape HTML entities | Rendah |
| `dangerouslySetInnerHTML` | Tidak | TINGGI |
| `href={var}` | URL scheme check sebagian | Sedang (`javascript:` blocked? React blocks) |
| Vue `{{ var }}` | Auto-escape | Rendah |
| Vue `v-html` | Tidak | TINGGI |
| Angular `{{ var }}` | Auto-escape | Rendah |
| Angular `[innerHTML]` | Sanitizer (DomSanitizer) | Sedang (bypass ada) |

## Attack Vectors Khusus Framework

### React
- `dangerouslySetInnerHTML` → direct XSS.
- SVG/math namespace: encoding bug (historik).
- `href` with `javascript:` — React blocks `javascript:` tapi bypass via `data:text/html`? (tergantung versi).
- SSR hydration mismatch → jika data tidak escaped, XSS dari serialized state.

### Vue
- `v-html` direct.
- Template literal injection di `:class` / `:style` bindings (objek dengan property jahat).
- `v-bind` dengan objek: `v-bind="$attrs"` chain → event handler injection.

### Angular
- `[innerHTML]` + DomSanitizer bypass (`bypassSecurityTrustHtml`).
- Template injection: server-side template (Angular Universal) dengan interpolation user.
- Legacy: `$sce` bypass (AngularJS).

## Testing Tools & Approach

1. **Semgrep** — rule pattern untuk sink berbahaya (`dangerouslySetInnerHTML`, `v-html`, `eval`).
2. **ESLint security plugin** — `eslint-plugin-react` (dangerous-dangerouslySetInnerHTML), `eslint-plugin-vue` (v-html).
3. **Burp + DOM Invader** — find DOM XSS; postMessage exploit; prototype pollution scanner.
4. **Retire.js** — detect vulnerated library versions.
5. **Nuclei** — template scan framework-specific (hash of library → known CVEs).

## Checklist Audit Aplikasi SPA

- [ ] Tidak ada `dangerouslySetInnerHTML` / `v-html` tanpa sanitasi DOM (DOMPurify)?
- [ ] Semua input user diverifikasi (validation schema runtime: zod/yup)?
- [ ] Dependencies: no known vuln (npm audit clean) + lockfile di-commit?
- [ ] Token di HttpOnly cookie, bukan localStorage?
- [ ] SSR initial state tidak mengandung sensitive data?
- [ ] `Object.prototype` di-freeze / merge library aman?
- [ ] CSP terpasang (lihat [[csp-best-practices]])?

## Red Team Perspective

Dari sudut penyerang: prioritas = sink berbahaya + prototype pollution chain. Tools: DOM Invader (Burp), Puppeteer custom payload, postMessage scanning. Bypass labeling: framework auto-escape tidak berarti aman — find sink eksplisit. Supply chain: library lama di frontend = permukaan serangan besar (XSS historis).



## Contoh Payload Per Sink

```javascript
// React — dangerous sink
<div dangerouslySetInnerHTML={{__html: userInput}} />

// Vue
<div v-html="userInput"></div>

// Angular
<div [innerHTML]="userInput"></div>

// Prototype pollution → RCE (Node.js server-side)
fetch('/api/merge', { method: 'POST',
  body: JSON.stringify({ __proto__: { shell: "/proc/self/exe", argv0: "console.log(1)" } }) })
// jika server memakai _.merge pada body → pollution → child_process options ter-inject
```

## DOM XSS Hunting Workflow (Burp DOM Invader)

1. Aktifkan DOM Invader di Burp; buka aplikasi target.
2. Inject "canary" value di tiap input (`canary123xyz`).
3. Invader menandai source→sink flow.
4. Klik hasil → bukti exploitation (alert(1) atau cookie read).
5. Uji juga: postMessage listener (`window.addEventListener('message')`), `location.hash` sink.
6. Prototype pollution scanner: inject `__proto__` payloads → cek sink.

## Studi Kasus: XSS di Library Populer

- **CVE-2020-8203 lodash** — prototype pollution via `defaultsDeep`.
- **CVE-2018-16487 lodash** — `template` function code injection (server-side).
- **CVE-2021-23358 underscore** — template injection.
- **React CVE-2017-14734** — XSS via `dangerouslySetInnerHTML` dengan `{__html: undefined}` (historik).
- **jQuery CVE-2019-11358** — prototype pollution via `$.extend(true, {}, obj)`.
- Pelajaran: library populer = target besar; selalu SCA scan + upgrade rutin.

## Mitigasi & Hardening

1. **DOMPurify** untuk semua HTML sanitization (whitelist tag/attr, config ketat).
2. **CSP** (lihat [[csp-best-practices]]) — kontrol script source.
3. **Runtime validation**: zod/yup schema untuk semua input API.
4. **Dependency hygiene**: renovate/dependabot auto-update; audit di CI (fail on high).
5. **Freeze prototype**: `Object.freeze(Object.prototype)` di entry app.
6. **Secure storage**: token di HttpOnly cookie; sensitive data tidak di store global.
7. **SSR**: jangan serialisasi data sensitif; gunakan token per-session untuk hydration.

---

  audited
---