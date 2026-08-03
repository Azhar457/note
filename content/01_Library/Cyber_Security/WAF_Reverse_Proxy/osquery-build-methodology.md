---
title: Osquery Build Methodology
tags:
- osquery
- monitoring
- endpoint
- sql
created: '2026-07-19'
updated: '2026-07-19'
status: pending
---

> Osquery = query OS seperti database.

## Key Tables
| Table | Purpose |
|-------|---------|
| processes | Running apps |
| listening_ports | Network listeners |
| socket_events | Network connections |
| file_events | File changes |
| users | User accounts |
| services | Running services (Windows) |

## Example Queries
```sql
-- Suspicious processes
SELECT * FROM processes 
WHERE path LIKE '/tmp/%' OR name LIKE '%mal%';

-- Unusual network listeners
SELECT * FROM listening_ports 
WHERE port NOT IN (80, 443, 22, 3306);
```