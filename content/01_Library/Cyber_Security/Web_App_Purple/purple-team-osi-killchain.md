---
title: Purple Team Osi Killchain
tags:
- cyber-security
- library
- web-app-purple
created: '2026-05-29'
updated: '2026-07-01'
status: pending
cssclasses:
  - wide-table
  - callout

---

# ⚔️ PURPLE TEAM — Full Kill-Chain: Attack & Defense per OSI Layer

> **Filosofi Purple Team:** Attacker terkuat mengeksploitasi setiap layer sekaligus. Defender tematang membangun kontrol di setiap layer (Defense-in-Depth). Purple Team mensimulasikan keduanya secara bersamaan untuk temukan gap yang tidak terlihat dari satu sisi saja.

> [!info] Cara Baca
> Baca kolom Red (attacker) dan Blue (defender) secara paralel per layer. Perhatikan bagaimana serangan di Layer 1 bisa cascade sampai Layer 7 — ini yang disebut **full kill-chain**. Layer bukan dibaca linear — APT menyerang beberapa layer sekaligus.

---

## Tabel Utama — Attack & Defense per OSI Layer

| OSI Layer | ☣️ Red Team (Attacker) | 🔵 Blue Team (Defender) | 🎯 Tools Terbaik |
|---|---|---|---|
| **Layer 1 — Physical** | Physical access = game over. USB drop (BadUSB, Rubber Ducky), hardware implant di keyboard/mouse, cable tapping, evil maid attack di BIOS/UEFI, supply chain compromise di hardware level. **Bootkit/MBR implant sering mulai di sini.** | Biometric lock, CCTV, tamper-evident seal, HSM, Faraday cage untuk device sensitif, disable USB port via Group Policy, TPM 2.0 + Secure Boot. Full disk encryption sebagai last line of defense. | BitLocker / VeraCrypt + TPM, Yubico Security Key, hardware write-blocker |
| **Layer 2 — Data Link** | ARP Poisoning, MAC Spoofing, VLAN Hopping, WiFi Evil Twin + Deauth Attack, Layer 2 MITM. Implant network driver untuk sembunyikan traffic di level ini — invisible ke Layer 3 monitoring. | 802.1X Port Authentication, Dynamic ARP Inspection (DAI), MACsec encryption, segmentasi dengan managed switch, disable unused port, NAC (Network Access Control) untuk deteksi rogue device. | Cisco ISE, Aruba ClearPass, Bettercap (Red), Wireshark (Blue) |
| **Layer 3 — Network** | IP Spoofing, BGP Hijack (nation-state level), port scanning, pivoting melalui compromised host. Fast-flux DNS + DGA (Domain Generation Algorithm) untuk C2 yang berubah-ubah dan susah diblokir. | Strict firewall rule, micro-segmentation, Zero Trust Network Access (ZTNA), IPsec, BGPsec. Network visibility dari EDR yang bisa korelasikan endpoint + network event. | Palo Alto NGFW, Fortinet, CrowdStrike + Network visibility, Nmap (Red) |
| **Layer 4 — Transport** | Port scanning & service enumeration, TCP/UDP hijacking, eksploitasi service yang weak. RAT menggunakan encrypted tunnel — TLS over TCP port 443 terlihat seperti traffic HTTPS biasa, tidak terdeteksi firewall konvensional. | Stateful inspection, TLS inspection (decrypt-monitor-re-encrypt), port knocking, strict egress filtering. Monitor pola TCP/UDP yang anomali — koneksi panjang tanpa aktivitas, beacon interval yang terlalu reguler. | Suricata, Zeek, Brim (network forensik), hping3 (Red) |
| **Layer 5 — Session** | Session hijacking (cookie, token, WebSocket takeover), maintain long-lived C2 session. **DNS Tunneling** — enkapsulasi command dalam DNS query, karena DNS hampir selalu diizinkan keluar firewall. Bypass semua filter berbasis port. | Session management: short-lived token, mTLS, WAF dengan session anomaly detection. DNS security: Response Policy Zone (RPZ), sinkholing domain C2, monitor DoH/DoT untuk DNS tunneling terenkripsi. | Cloudflare Gateway, Cisco Umbrella, iodine (Red DNS tunnel), dnsdumpster |
| **Layer 6 — Presentation** | Data encoding & obfuscation (base64, XOR, custom crypter), SSL pinning bypass, steganografi (sembunyikan payload dalam gambar/audio). Rootkit menyembunyikan struktur data di kernel memory — proses tidak terlihat, file tidak terlihat, network connection tidak terlihat. | Strong encryption standard (TLS 1.3 only), certificate pinning, DLP (Data Loss Prevention), format validation pada semua file input. Memory protection: ASLR, DEP, CFG untuk cegah code injection. | Binwalk (deteksi steganografi), Volatility (memory forensik), Ghidra (RE rootkit) |
| **Layer 7 — Application** | Exploit web app (SQLi, RCE, XSS), phishing dengan malicious document, supply chain attack (SolarWinds style — compromise update server). RAT delivery via aplikasi legitimate. Full remote desktop via WebRTC + WebSocket. Keylogger + screen capture + command execution setelah foothold. | Application whitelisting (AppLocker, WDAC), runtime protection via EDR, behavioral analysis (deteksi anomali perilaku proses bukan hanya signature). Zero trust application access. Regular patching + SBOM (Software Bill of Materials) untuk track dependency. | CrowdStrike Falcon, Microsoft Defender for Endpoint, Burp Suite (Red), OWASP ZAP |
| **Layer 8 — Human** *(tidak resmi)* | **Initial access paling sering dari sini.** Phishing, vishing, USB drop di parkiran kantor, pretexting, insider recruitment. "Who Am I" style — manipulasi psikologis sebagai pintu masuk sebelum teknis. Social engineering bypass semua kontrol Layer 1-7. | Security awareness training + simulated phishing (GoPhish). MFA everywhere — hardware key (YubiKey) untuk account kritis. Least privilege principle. Incident response drill rutin. GRC process untuk enforce human control secara sistematis. | KnowBe4, GoPhish, Proofpoint (email security), YubiKey |

---

## Full Kill-Chain — Serangan APT Multi-Layer

```
FASE 1 — INITIAL ACCESS (Layer 8 → Layer 7)
─────────────────────────────────────────────
Phishing email dengan malicious document
        │
        ▼
User buka dokumen → macro execute → downloader
        │
        ▼
RAT tahap pertama ter-install di user space (Layer 7)

FASE 2 — PERSISTENCE & PRIVILEGE ESCALATION (Layer 7 → Layer 0)
──────────────────────────────────────────────────────────────────
RAT kirim beacon ke C2 via DNS Tunneling (Layer 5)
atau HTTPS ke legitimate-looking domain (Layer 4/6)
        │
        ▼
Attacker dapat shell → cari privilege escalation
        │
        ▼
BYOVD: load vulnerable driver → Ring 0 access (Kernel)
        │
        ▼
Install rootkit → sembunyikan semua artifact (Layer 6)
        │
        ▼
Flash UEFI implant → persist survive reinstall OS (Layer 1)

FASE 3 — LATERAL MOVEMENT (Layer 2 → Layer 3)
──────────────────────────────────────────────
ARP Poisoning → MITM traffic internal (Layer 2)
        │
        ▼
Scan network internal → identify target baru (Layer 3)
        │
        ▼
Pass-the-hash / Kerberoasting → compromise akun lain
        │
        ▼
Pivot ke server yang lebih valuable

FASE 4 — EXFILTRATION (Layer 5/6)
──────────────────────────────────
Data dikumpulkan → dikompresi → dienkripsi
        │
        ▼
Exfil via DNS Tunneling (bypass DLP)
atau via steganografi dalam gambar (bypass content filter)
atau via legitimate cloud service (OneDrive, Dropbox)

TOTAL: Attacker menyerang Layer 8,7,6,5,4,3,2,1 sekaligus
Setiap layer yang tidak dimonitor = blind spot
```

---

## Purple Team View — Mengapa Serangan Ini Berbahaya

| Faktor | Penjelasan |
|---|---|
| **Multi-layer simultaneously** | Defender yang hanya monitor Layer 7 tidak akan lihat DNS Tunneling di Layer 5 atau ARP Poisoning di Layer 2 |
| **Legitimate tools abuse** | Living-off-the-land: PowerShell, WMI, CertUtil — semua tools Windows yang sah dipakai untuk serangan, tidak ada signature malware |
| **Encrypted C2** | TLS over port 443 = tidak bisa dibedakan dari traffic HTTPS normal tanpa TLS inspection |
| **Persistence di multiple level** | Hapus RAT di Layer 7 → rootkit di Layer 6 install ulang → hapus rootkit → UEFI implant di Layer 1 install ulang |
| **Initial access dari human layer** | Semua kontrol teknis Layer 1-7 tidak berguna jika user klik phishing dan execute macro |

---

## Defense-in-Depth — Kontrol per Layer yang Harus Ada

```
MATURE DEFENDER STACK (dari dalam ke luar):

[Layer 1 — Physical]
  BitLocker + TPM → jika laptop dicuri, data tidak terbaca
  Secure Boot → bootkit tidak bisa load tanpa signature valid
  Tamper detection → alert jika device dibuka

[Layer 2 — Data Link]  
  802.1X → device tidak dikenal tidak dapat akses network
  DAI → ARP poisoning tidak bisa jalan
  
[Layer 3 — Network]
  NGFW + micro-segmentation → lateral movement terbatas
  ZTNA → tidak ada implicit trust berdasarkan lokasi network

[Layer 4 — Transport]
  TLS inspection → decrypt + inspect semua traffic
  Egress filtering → tidak semua port boleh keluar

[Layer 5 — Session]
  DNS security → blokir domain C2, detect DNS tunneling
  mTLS → session tidak bisa dihijack

[Layer 6 — Presentation]
  DLP → deteksi exfiltration
  ASLR + DEP → code injection harder
  Memory forensik → rootkit bisa dideteksi di memory

[Layer 7 — Application]
  EDR (behavioral) → deteksi anomali perilaku, bukan signature
  AppLocker → hanya aplikasi whitelisted yang bisa jalan
  SBOM → tahu semua dependency yang dipakai

[Layer 8 — Human]
  Security awareness → user tidak klik phishing
  MFA + hardware key → credential theft tidak cukup
  Least privilege → damage limited jika akun compromise
  
KORELASI SEMUA LAYER:
  XDR + SOAR → event dari semua layer dikorelasikan
               alert yang meaningful, bukan noise
  SIEM → historical data untuk threat hunting
  SOC → manusia yang review dan respond
```

---

## Mapping ke MITRE ATT&CK

| Kill-Chain Phase | MITRE Tactic | Contoh Technique |
|---|---|---|
| Initial Access (Layer 8→7) | Initial Access | T1566 Phishing, T1195 Supply Chain |
| Persistence (Layer 6→1) | Persistence | T1542 Pre-OS Boot, T1014 Rootkit |
| Privilege Escalation | Privilege Escalation | T1068 Exploit vuln driver (BYOVD) |
| Defense Evasion | Defense Evasion | T1036 Masquerading, T1055 Process Injection |
| Lateral Movement (Layer 2→3) | Lateral Movement | T1550 Pass-the-Hash, T1021 Remote Services |
| C2 (Layer 4→5) | Command & Control | T1071 App Layer Protocol, T1572 DNS Tunneling |
| Exfiltration (Layer 5→6) | Exfiltration | T1048 Exfil over Alt Protocol, T1041 Exfil over C2 |

---

## Yang Membedakan Amateur vs APT

```
AMATEUR ATTACKER:
→ Pakai satu teknik di satu layer
→ Noisy → mudah terdeteksi
→ Tidak punya persistence plan
→ Mudah dievict setelah ditemukan

APT (Advanced Persistent Threat):
→ Chain attack di semua layer
→ Quiet → dwell time rata-rata 200+ hari sebelum terdeteksi
→ Multiple persistence di level berbeda
→ Jika satu persistence dihapus → yang lain masih ada
→ Live-off-the-land → tidak ada malware signature

Itulah kenapa disebut "Advanced" dan "Persistent" —
bukan karena toolnya mahal tapi karena strateginya berlapis
dan dirancang untuk bertahan lama tanpa terdeteksi
```

---

> [!warning] Insight Paling Penting
> **Layer 8 (Human) adalah layer yang paling sering jebol dan paling sedikit di-invest.** Perusahaan bisa habiskan miliaran untuk Palo Alto, CrowdStrike, dan Splunk — tapi satu user yang klik phishing membatalkan semua investasi itu. Initial access hampir selalu dari Layer 8, bukan dari Layer 1-7. Security awareness bukan "nice to have" — ini adalah kontrol dengan ROI tertinggi.

> [!tip] Purple Team Exercise — Cara Simulasikannya
> Red team eksekusi full kill-chain dari Layer 8 sampai Layer 1. Blue team deteksi dan respond. Purple team duduk bersama, review setiap langkah: "Di mana detection gagal? Control mana yang missing? Alert mana yang fired tapi di-ignore karena noise?" Iterasi ini yang membangun mature security posture — bukan tool mahal yang tidak di-tune.

---

## 🔗 Lihat Juga

- [[endpoint-security|Endpoint Security]] — CPU Ring hierarchy, Boot Chain threat
- [[network-security|Network Security]] — OSI Layer 1–8 threat table
- [[underground-knowledge|Underground Knowledge]] — BYOVD detail, Cheat Engine kernel
- [[hardware-hacking-re|Hardware Hacking]] — UEFI implant, firmware attack
- [[llm-security-red-teaming-attack-surface-ai-layer|LLM Security]] — Layer baru di atas Layer 7 untuk AI system
- [[master-index|Master Index]]

---

*Purple Team OSI Kill-Chain | Layer 1 (Physical) → Layer 8 (Human) · Red vs Blue · Defense-in-Depth · APT Full Chain*