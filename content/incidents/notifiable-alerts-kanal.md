---
title: Notifiable Alerts Kanal
tags: [incident, alerts]
aliases: [notifiable-alerts-kanal]
---
# Notifiable Alerts — Kanal Notifikasi

Definisi alert yang wajib dinotifikasi (kanal: email, Telegram, SIEM ticket), kategorisasi: (1) **Critical** (notify ≤ 5 menit) — RCE aktif, ransomware deteksi, credential dump, exfiltration besar, availability loss kritis; (2) **High** (≤ 15 menit) — auth bypass attempt massal, privilege escalation, malware deteksi (EDR), phishing campaign ke karyawan; (3) **Medium** (≤ 1 jam) — port scan besar, login gagal berulang (> 10 per user), SSL cert expired; (4) **Low** (harian) — disk usage, patch outdated, minor misconfig.

Format pesan: severity, host/service, IOC, action taken, timeline. Eskalasi: jika tidak diakui dalam SLA, eskalasi ke on-call berikutnya. Jangan flood — grouping per 5 menit.
---

  audited
---