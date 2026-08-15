---
title: Hierarchy Wireless — Hierarki Spektrum Nirkabel dari WiFi hingga Tactical SDR
tags:
  - atlas
  - wireless
  - sigint
  - cybersecurity
  - physical-layer
aliases:
  - Wireless Security Roadmap
  - Spektrum Nirkabel Hierarchy
created: 2026-07-19
updated: 2026-08-15
status: pending
cssclasses:
  - wide-table
  
---


# 📡 Hierarchy Wireless — Hierarki Spektrum Nirkabel

> Peta hierarki kemampuan wireless security dari level **konsumen/off-the-shelf** (WiFi rumah, BLE, NFC) hingga **tactical-grade** (SDR, IMSI catcher, satellite downlink). Pelengkap [[hierarchy-osint-rf]] yang fokus ke RF emission; catatan ini lebih luas: protokol nirkabel, attack surface, dan tooling.

---

## Daftar Isi

- [[#Sheet 1 — Wireless Consumer / Off-the-Shelf]]
- [[#Sheet 2 — Wireless Pro / Pentester Standard]]
- [[#Sheet 3 — Wireless Tactical / SDR-Grade]]
- [[#Plot Twist — Tiga Vektor Lateral di Wireless Attack]]
- [[#Koneksi ke Vault]]

---

## Sheet 1 — Wireless Consumer / Off-the-Shelf

Spektrum kemampuan yang umumnya **tersedia tanpa clearance** — beli di toko, tidak butuh lisensi khusus. Cocok untuk homelab pentest, learning, audit internal SME.

| Level & Tools                                                                                                                                                                                                                                                | Teknik & Sweet Spot                                                                                                    | Tembok & Batasan                                                                                             | Use Case Nyata                                                               |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------------- |
| **Level 0** — WiFi WPS & Default Password _(aireplay-ng, Reaver, Wash, Wifite)_                                                                                                                                                                              | Serangan WPS PIN bruteforce di router yang belum patched. Reaver crack PIN router dalam 4-10 jam.                      | Mayoritas router modern disable WPS by default. Patch 2011 sudah adopted.                                    | Mendeteksi router konsumen yang masih allow WPS (laporan audit internal)     |
| **Level 1** — WPA2 Handshake Capture _(aircrack-ng, hcxtools, hashcat)_                                                                                                                                                                                      | Capture 4-way handshake dengan deauth, crack offline via hashcat + wordlist rockyou. GPU-accelerated.                  | WPA3 sudah menggantikan WPA2-Personal di pasar baru. PMKID attack masih mungkin di WPA2.                     | Audit password WiFi corporate yang masih lemah (wordlist-based)              |
| **Level 2** — WPA3 Dragonblood & SAE Attacks _([Dragonslayer](https://github.com/vanhoefm/dragonslayer), [hostap-mt](https://w1.fi/hostapd/))_                                                                                                               | Exploit implementation flaw di WPA3-SAE. Timing side-channel di transition mode. Waktu patching bervariasi per vendor. | Mayoritas produksi modern sudah patched WPA3-SAE. Tinggal eksploitasi device lama.                           | Riset akademik, validasi apakah firmware router kantor punya CVE Dragonblood |
| **Level 3** — Evil Twin & Captive Portal _(hostapd-mana, Wifiphisher, eaphammer)_                                                                                                                                                                            | Rogue AP dengan nama SSID mirip legitimate (e.g. `Starbucks_Free` di kafe). Capture creds atau push malware.           | HTTPS HSTS + certificate pinning bisa mitigate captive portal MITM. User harus sadar untuk notice SSID aneh. | Pentest social engineering, demo security awareness                          |
| **Level 4** — Bluetooth Low Energy (BLE) & HID Injection _([nRF Connect](https://www.nordicsemi.com/Products/Development-tools/nrf-connect-for-mobile), [gattacker](https://github.com/lostwellness/gattacker), [bleah](https://github.com/cyberarm/bleah))_ | Sniff & inject GATT characteristic di BLE peripheral. BadUSB via HID (mouse/keyboard spoofing) di BLE HID.             | BLE 5+ randomized address mempersulit tracking permanen kecuali pair persistent.                             | Pentest IoT device, kontrol smart-lock/lampu paksa, BYOD keyboard injection  |
| **Level 5** — NFC / RFID Cloning _(proxmark3, ACR122U, libnfc)_                                                                                                                                                                                              | Read UID dari Mifare Classic → clone ke magic card. Read credit-card NFC (EMV) untuk research.                         | NFC payment terenkripsi (Apple Pay/Google Pay pakai tokenization — tidak langsung expose PAN).               | Riset access control kartu, audit badge karyawan, eksplorasi transit card    |
| **Level 6** — Zigbee / Z-Wave IoT _(Z-Stack sniff, [Z3us](https://github.com/kdmytro/z3us), [razbermon](https://github.com/razbermon-iot/iozt/))_                                                                                                            | Sniff & replay Zigbee traffic. Eksploitasi pairing. Banyak smart-home device belum punya secure pairing.               | Zigbee 3.0 dengan Touchlink/Install Code menambah barrier. Matter/Thread menyatukan layer.                   | Pentest smart-home, audit gedung otomatis (lighting, HVAC controller)        |

---

## Sheet 2 — Wireless Pro / Pentester Standard

Tooling **standar untuk pentester profesional**. Umumnya butuh dedicated hardware USB dongle ($25-300). Tool ini juga dipakai **red team enterprise**.

| Level & Tools | Teknik & Sweet Spot                                                                                                                                                                                            | Tembok & Batasan                                                                                          | Use Case Nyata                                                                  |
| --- | --- | --- | --- |
| **Level 7** — WiFi Enterprise (802.1X / EAP) _([eaphammer](https://github.com/s0lst1c3/eaphammer), [hostapd-wpe](https://github.com/air-verse/aircrack-ng), [wpa_supplicant_eap_peap_crack](https://github.com/joswr1ght/wpa-peaphammer))_ | Evil twin attack 802.1X dengan negosiasi EAP ke weaker method (PEAP-MSCHAPv2 → crack via asleap). RADIUS mis-config.  | 802.1X dengan EAP-TLS + per-user cert membuat attack ini jauh lebih sulit.                                | Audit RADIUS-Server enterprise, validasi penerapan EAP-TLS                       |
| **Level 8** — 5G / LTE IMSI Catchers (Stingray-class) _([IMSI-catcher](https://github.com/0x0d3ad/imsi-catcher-detector), [rayhunter](https://github.com/EFForg/rayhunter-diag))_ | Rogue base station yang memaksa handset turun ke 2G/3G (no mutual auth). Tangkap IMSI, TMSI, lokasi perangkat. Rate-limit enforcement di 4G/LTE. | Di 5G SA deployments, IMSI protection mandatory. Device juga ada IMSI-catcher detector (Android 12+). | Forensic saat ada indikasi targeted surveillance, riset 5G security posture       |
| **Level 9** — Cellular Base-Station (BTS) Sandbox _([OpenBTS](https://github.com/RangeNetworks), [OsmoBTS](https://osmocom.org/projects/cellular-infrastructure/wiki/OsmoBTS), OsmoSGSN, OsmoMGW)_              | Bangun BTS sendiri (mini GSM/UMTS) dengan SDR. Asumsikan SIM Anda. Lihat handset Anda connect ke BTS rogue.       | Regulasi telekomunikasi ketat (running BTS tanpa ijin = ilegal di mayoritas negara). Legal only in lab.   | Lab riset cellular security, edukasi, simulasi cellular-protocol man-in-the-middle |
| **Level 10** — GPS Spoofing & Jamming _([GPS-SDR-SIM](https://github.com/osqzss/gps-sdr-sim), HackRF One)_                                            | Broadcast fake GPS signal yang membuat receiver berpikir di lokasi lain. Jamming dengan broad-spectrum noise (illegal civilian). | Anti-spoofing (Galileo OS-NMA, GPS M-code). Regulasi penggunaan frequency (ITU-R + local regulator).       | Riset di GPS-equipped drone, autonomous vehicle di sandbox environment          |
| **Level 11** — WiFi & BLE Continuous Monitor _([Kismet](https://www.kismetwireless.net/), [Wireshark+wifi](https://www.wireshark.org/), [BearTrap](https://github.com/hjr-lab/BearTrap))_           | 24/7 sensor detection rogue AP/Evil Twin di enterprise. Integration ke SIEM (Loki/Splunk).                            | False positive bisa tinggi di dense area (apartment buildings). Perlu tuning baseline.                   | SOC enterprise, monitoring gedung multi-tenant, audit compliance                 |

---

## Sheet 3 — Wireless Tactical / SDR-Grade

Spektrum **research-grade / nation-state**. Butuh SDR hardware (USRP, LimeSDR, HackRF) mulai $300-$10k, ditambah technical expertise khusus. Banyak komponen ini.subject riset legal/akademik, atau dipakai oleh intelijen.

| Level & Tools | Teknik & Sweet Spot                                                                                                                                                                               | Tembok & Batasan                                                                                                       | Use Case Nyata                                                                                |
| --- | --- | --- | --- |
| **Level 12** — Wide-Band SDR Capture _([LimeSDR](https://limemicro.com/products/boards/), [USRP B200/B210](https://www.ettus.com/products/), GNU Radio)_ | Capture full band (1 MHz – 6 GHz) sekaligus. Decode protokol proprietary (LoRa, sub-GHz IoT).                              | Butuh storage besar (TB untuk capture panjang). Processing CPU/GPU heavy.                                                 | Reverse engineering IoT proprietary, riset waveform baru                                     |
| **Level 13** — Protocol Reverse Engineering _([Universal Radio Hacker](https://github.com/jopohl/urh), [inspectrum](https://github.com/miek/inspectrum), [SigBerkeley]() swooping)_ | Capture demodulated baseband → manual decode. Identifikasi preamble, sync, payload, CRC. Eliminasi layer proprietary.      | Butuh waktu signifikan (minggu untuk protokol sederhana). Beberapa protokol pakai encryption → tidak bisa decode tanpa key. | Riset IoT proprietary (smart-meter, industrial sensor), academic wireless research            |
| **Level 14** — Satellite Downlink Intercept _([SatNOGS](https://opensatnet.org/projects/satnogs/), NOAA weather satellites, Inmarsat / Iridium)_ | Receive downlink sinyal dari LEO/MEO/GEO satellite. Decoder demodulator built atop open source. NOAA APT, LRPT, HRPT.      | Regulasi ITU — menerima downlink tidak selalu illegal, tapi decode & redistribute bisa. Bird-feed S-band butuh izin.         | Meteorologi, maritim tracking, riset orbital                                                  |
| **Level 15** — RF Side-Channel & TEMPEST _([TEMPEST font](https://www.youtube.com/watch?v=RmsFwxY1-lc), [Van Eck phreaking demo](https://www.youtube.com/watch?v=2Dp5b3aM-nI))_ | Capture EM emanation dari monitor/kabel (VGA, HDMI, USB). Rekonstruksi display dari sincangan EM yang tertangkap.            | Sangat specialized: butuh shielded room, broadband antenna, software FFT dengan timing resolution ms.                     | Riset TEMPEST (akademik CS), validasi emanation compliance produk (perisai TEMPEST-level)     |
| **Level 16** — Nation-State SIGINT & Quantum Cryptanalysis _([XKEYSCORE](https://en.wikipedia.org/wiki/XKEYSCORE), NSA ANT, GCHQ) — close-source)_ | Tap ke fiber backbone / antenna farm (per [[xkeyscore]]). Kuantum computer untuk RSA/ECC. | Klasifikasi. Akses negara-bangsa. Quantum cryptanalysis butuh $100M+ infrastructure (Google Willow, IBM Heron).              | Mass surveillance (legally regulated), cryptographic backdooring, foreign intelligence         |
| **Level 17** — Quantum Radar & LPI / LPD _([DARPA HRTI](https://en.wikipedia.org/wiki/Quantum_radar), Spread-spectrum, OFDM, chaotic)_ | Waveform dengan low probability of intercept/detect (LPI/LPD). Quantum illumination untuk deteksi stealth aircraft.           | Sangat classified. Militer-only. Riset publik terlambat 5-15 tahun dari capability aktual.                                  | Anti-stealth defense, electronic warfare kontra-emersi (limited Tier-1 country)              |

---

## Plot Twist — Tiga Vektor Lateral di Wireless Attack

Yang jarang dibahas di literatur standar tapi praktis relevan:

### Twist 1 — Bluetooth Mesh Hijack via GATT Injection

```
Device A (sniffer, valid pair)
       │
       │  BLE GATT read char_value
       ▼
Device B (victim — e.g. insulin pump, smart-lock)
       │
       │  Inject update firmware via GATT
       ▼
Command sent → physical device compromised
```

Risk: banyak medical IoT (insulin pump, pacemaker legacy) tidak menggunakan secure pairing.

### Twist 2 — WiFi Deauth sebagai Smokescreen + Channel Switch Reconnaissance

```
Attacker sends 50 deauth/sec on ch 6
       │
       ▼
Target AP trigger channel-switch announcement (CSA)
       │
       ▼
Legitimate clients pindah ke ch 1 (attacker-controlled)
       │
       ▼
Attacker inspect original ch 6 secara stealth
(exposes hidden SSID, paket management-only, dsb)
```

Advanced reconnaissance yang jarang ditangkep SOC tradisional. Lihat referensi: [CSA Injection paper](https://www.mathy.com/vanhoef/bluff/2017).

### Twist 3 — Hybrid Cellular + WiFi Handoff untuk Persistent C2

```
[Persistent command & control architecture]
  ┌─ Cell 1 (Tower A) → MikroTik disrupts → fail-over ─┐
  ├─ Cell 2 (Tower B) — fallback via SIM#2 ───────────┤
  ├─ WiFi captive portal (rogue AP) → fallback ────────┤
  └─ LoRa 868 MHz ad-hoc mesh → long-range fallback ──┘
```

Berlaku di **APT-targeting**: kalau adversary tahu target sering travel (konsuler, jurnalis), multi-channel C2 jadi resilient. Lihat [[apt-c2-infrastructure]].

---

## Koneksi ke Vault

### Catatan Materi Wireless

- [[wireless-security-deepdive]] — Deep dive sister untuk hierarchy ini
- [[hierarchy-osint-rf]] — Hierarki OSINT & RF signal paralel
- [[hierarchy-search]] — Hierarki informasi (surface → Five Eyes SIGINT)

### Hardware & Offense Tools

- [[imsi-catcher]] — IMSI catcher hardware
- [[oscor]] — OSOR spectrum analyzer (legal Intercept)
- [[hack5-suite]] — Hak5 payload & implant ecosystem
- [[victoria-hdd]] — Storage forensics

### Defense & Detection

- [[blueteam-detection-matrix]] — Detection matrix untuk rogue AP/Evil Twin
- [[covert-channel-encyclopedia]] — Sub-GHz & UWB covert channel
- [[cgnat-attribution-deepdive]] — Attribution pasca-WiFi-capture-correlation
- [[dns-tunneling-deepdive]] — Covert exfil via RF-channel (LoRa, ISM)

### SIGINT Lintas Domain

- [[siginter]] — Siginter architecture
- [[upstream-and-tempora]] — Upstream collection (NSA/CNE)
- [[xkeyscore]] — Indexing tool dari Five Eyes partnership
- [[military-sigint-deepdive]] — Military SIGINT mendalam
- [[siginter-quantum]] — Quantum-based SIGINT (cryptographically relevant)

---

> **Catatan etika & hukum:** Mayoritas Level ≥ 8 butuh lisensi regulator lokal (Kominfo di Indonesia, FCC di US, dst.). Jalankan hanya di lab terisolasi dengan spektrum analyzer untuk monitor unintentional emission. Lihat [[digital-privacy-anonymity]] & [[isp-surveillance-privacy-deepdive]] untuk konteks legal surveillance.

audited