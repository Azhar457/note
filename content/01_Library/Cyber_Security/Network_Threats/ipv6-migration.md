---
title: IPv6 Migration — Security Implications
tags:
  - ipv6
  - migration
  - dual-stack
  - networking
created: '2026-07-19'
updated: '2026-08-14'
status: complete
cssclasses:
  - wide-table
  - callout
references:
  - [[covert-channel-encyclopedia]]
  - [[logging-compliance-guide]]
related_notes:
  - [[ipv6-migration|IPv6 Migration Overview]]
---

> IPv6 migration sering mengaktifkan IPv6 tanpa monitoring, menciptakan blind spot pada jaringan yang sebelumnya hanya IPv4.

## 1. Ringkasan / Definisi
IPv6 memperkenalkan 128‑bit address space, autoconfiguration (SLAAC), serta mekanisme keamanan seperti IPsec dan privacy extensions. Namun transisi dari IPv4 ke IPv6 tidak otomatis meningkatkan postur keamanan — konfigurasi yang salah dapat membuka vektor baru: tunnel abuse, NDP spoofing, dan exposure layanan yang belum difilter firewall legacy. Kesalahan paling umum: tim jaringan menyalakan IPv6 di router/switch tanpa memperbarui aturan firewall, ACL, dan sistem logging.

## 2. Mekanisme Migrasi
| Metode | Deskripsi | Keamanan | Catatan Praktis |
|--------|-----------|----------|----------------|
| Dual‑stack | IPv4 & IPv6 berjalan bersamaan di interface yang sama. | Butuh kebijakan firewall ganda (IPv4 + IPv6). | Fase transisi paling aman jika kedua stack di-monitor. |
| 6to4 / Teredo / ISATAP | Tunneling otomatis melalui IPv4 network. | Rentan terhadap bypass firewall dan spoofing. | Non‑aktifkan jika tidak diperlukan. |
| NAT64/DNS64 | Translasi IPv6‑only ke layanan IPv4. | Menyembunyikan sumber IPv4 asli, tetap butuh filtering. | Berguna untuk lingkungan IPv6‑only. |
| DHCPv6 + SLAAC | Otomatisasi alamat dan prefix host. | Risiko rogue Router Advertisement. | Monitor RA/NDP dengan IDS/detection tool. |

## 3. Risiko Keamanan
> [!callout] ⚠️
> * **Blind spot IPv6** – banyak tim mematikan logging IPv6 sehingga serangan di segmen IPv6 tidak terdeteksi.
> * **Tunneling abuse** – 6to4/Teredo dapat melewati firewall tradisional dan membuka backdoor.
> * **NDP spoofing** – penyerang mengirim Router Advertisement (RA) palsu untuk menipu host memilih gateway attacker.
> * **Privacy extensions** – temporary address melindungi privasi user, tetapi mengganggu monitoring berbasis IP static.
> * **Extension header abuse** – IPv6 extension header bisa dimanfaatkan untuk evasion filter/IDS.

## 4. Praktik Terbaik (Checklist)
- [ ] **Audit inventaris** perangkat: pastikan router, switch, firewall mendukung IPv6 dengan firmware terbaru.
- [ ] **Disable tunnel otomatis**: matikan 6to4, Teredo, ISATAP kecuali memang dibutuhkan.
- [ ] **Firewall IPv6**: aturan inbound/outbound per interface — jangan sekadar menyalin aturan IPv4.
- [ ] **Enable logging**: aktifkan syslog/Netflow untuk paket IPv6 termasuk ICMPv6 (NDP, RA, NS/NA).
- [ ] **Monitor RA/NDP**: gunakan tool seperti `ndpmon`, `ramond`, atau Snort rule untuk deteksi rogue RA.
- [ ] **Segregasi jaringan**: pisahkan segmen IPv6 critical (server, SCADA) dari user via VLAN/SDN.
- [ ] **Dokumentasi transisi**: catat timeline, scope, dan owner tiap fase migrasi untuk audit.

## 5. Referensi
- RFC 8200 – IPv6 Specification; RFC 4941 – Privacy Extensions; RFC 4861 – Neighbor Discovery.
- NIST SP 800‑119 – Guidelines for the Secure Deployment of IPv6.
- [[logging-compliance-guide]] – panduan logging yang wajib mencakup IPv6.
- [[covert-channel-encyclopedia]] – tunneling IPv6 sering dijadikan covert channel.
---

audited
---
