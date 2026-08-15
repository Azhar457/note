---
title: Logging Compliance Guide
tags:
  - logging
  - compliance
  - audit
  - regulation
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  
references:
  - [[osquery-build-methodology]]
  - [[ipv6-migration]]
related_notes:
  - [[logging-compliance-guide|Logging Compliance]]
---

> Logging compliance guide memberikan kerangka praktis untuk memastikan sistem log memenuhi regulasi (ISO 27001, PCI DSS, GDPR, HIPAA) dan mendukung incident response.

## 1. Ringkasan / Definisi
Compliance logging berarti mencatat, menyimpan, melindungi, dan memverifikasi log sistem secara konsisten sesuai standar industri dan hukum. Ini bukan sekadar menyimpan file — meliputi integritas, retensi, akses, enkripsi, audit trail yang dapat diverifikasi, serta kemampuan untuk merekonstruksi timeline insiden. Setiap organisasi yang menangani data sensitif wajib memiliki kebijakan logging terstruktur.

## 2. Standar Utama
| Standar | Fokus | Persyaratan Log Utama |
|---------|------|----------------------|
| ISO 27001 (A.12.4) | Logging & monitoring | Catat event akses, kegagalan, perubahan konfigurasi |
| PCI DSS (Req 10) | Logging & audit | Simpan 1 tahun, 3 bulan akses cepat; audit trail lengkap |
| GDPR (Art. 30, 32) | Proteksi data | Pseudonymization, retensi terukur, akses terbatas |
| HIPAA (164.312(b)) | Audit controls | Audit trail untuk akses ePHI (electronic Protected Health Info) |
| NIST CSF (DE.CM) | Continuous monitoring | Deteksi anomali dan respons otomatis |
| SOC 2 | Trust Services Criteria | Monitoring sistem dan verifikasi integritas log |

## 3. Praktik Terbaik (Checklist)
- [ ] Tentukan kategori event: login sukses/gagal, perubahan konfigurasi, akses data sensitif, operasi administratif.
- [ ] Terapkan format log terstruktur (JSON, CEF, LEEF) untuk parsing otomatis.
- [ ] Gunakan WORM atau immutable storage untuk retensi jangka panjang.
- [ ] Enkripsi log saat transit (TLS 1.3) dan saat diam (AES‑256‑GCM atau ChaCha20‑Poly1305).
- [ ] Atur retensi sesuai regulasi (min. 1 tahun PCI, min. 5 tahun HIPAA audit, GDPR sesuai tujuan).
- [ ] Lakukan audit periodik: integritas log (hash chain, digital signature), akses yang tidak sah.
- [ ] Integrasikan dengan SIEM/SOC untuk alert real‑time (mis. Splunk, Elastic, Sentinel).
- [ ] Dokumentasikan kebijakan retensi, penghapusan (data lifecycle), dan recovery.
- [ ] Lakukan training tim operasional tentang interpretasi log dan eskalasi.

> [!callout] 💡
> Logging yang baik bukan tentang volume — fokus pada event relevan dengan konteks lengkap (timestamp UTC, user ID, source IP, action, result, session ID). Gunakan centralized logging (syslog, Fluent Bit, Logstash) untuk mengurangi risiko kehilangan log lokal dan mempermudah korelasi.

## 4. Langkah Audit Log
1. **Identifikasi sumber log**: server, endpoint, aplikasi, database, firewall, IDS.
2. **Verifikasi integritas**: periksa hash chain atau tanda tangan digital setiap file log.
3. **Analisis timeline**: rekonstruksi urutan event untuk mendeteksi anomali.
4. **Periksa hak akses**: pastikan hanya role yang berwenang dapat membaca atau menghapus log.
5. **Uji retensi**: verifikasi bahwa log lama belum dihapus sebelum batas regulasi.
6. **Dokumentasi temuan**: buat laporan audit dengan rekomendasi perbaikan.

## 5. Referensi Cross-Note
- [[osquery-build-methodology]] – sumber log endpoint yang dapat diintegrasikan ke pipeline logging.
- [[ipv6-migration]] – pastikan logging mencakup paket IPv6 (ICMPv6, NDP, RA, NS/NA).
- [[ipv6-migration]] – panduan tambahan untuk transisi jaringan.
- RFC 5424 – The Syslog Protocol.
- NIST SP 800‑92 – Guide to Computer Security Log Management.
---

audited
---
