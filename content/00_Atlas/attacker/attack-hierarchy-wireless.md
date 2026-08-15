---
title: Attack Perspective — Wireless Security (Red Team)
tags:
- attack
- red-team
- wireless
- wifi
- bluetooth
- rfid
- nfc
- sdr
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Wireless — Perspektif Penyerang

> Wireless attack berbeda dari network tradisional — tidak butuh akses fisik ke kabel. Red team pakai: WiFi deauth, evil twin, Bluetooth sniffing, RFID clone, SDR frequency intercept.

## 1. Attack Surface Wireless

| Teknologi | Vektor | MITRE ID | Tool | Evasion | Detection Gap |
|-----------|--------|----------|------|---------|----------------|
| **WiFi (WPA2/3)** | Deauth + handshake capture → offline crack | T1557.001 | aircrack-ng, hashcat | Deauth = instan, handshake = offline | WIDS detect deauth — tapi crack offline = tidak terdeteksi |
| **WiFi Evil Twin** | Rogue AP → credential phish | T1557.002 | hostapd, dnsmasq, Wifi-Pumpkin | SSID spoof = identical to legit | WIDS detect rogue AP — tapi channel hop = evade |
| **WiFi PMKID** | Clientless handshake capture → crack | T1557.001 | hcxdumptool, hcxtools | No deauth needed = silent | Tidak ada detection (no deauth) |
| **Bluetooth** | Sniffing, BlueBorne, BLE key extraction | T1557 | Bettercap, Ubertooth, Wireshark | BLE = low power, passive sniff = hard detect | Bluetooth monitoring jarang |
| **RFID/NFC** | Card clone, relay attack, skimming | T1557 | Proxmark3, NFC Utils, Android HCE | Passive read = no signal to target | RFID audit = physical only |
| **SDR** | Frequency scan, decode (POCSAG, ADS-B, GSM) | T1590 | RTL-SDR, GQRX, GNU Radio | Passive = no transmission | Tidak ada detection (receive only) |
| **Zigbee** | Network join, key extraction | T1557 | Killerbee, AVR RZUSBSTICK | Repeat = offline, online join = detectable | Zigbee monitoring jarang |
| **LoRa** | Sniffing, jamming | T1557 | RTL-SDR + GNU Radio | Long range = passive from distance | LoRa monitoring = very rare |

## 2. WiFi Attack Chain

```
Recon: airodump-ng → identify target AP (SSID, BSSID, channel, client)
 ↓
PMKID (clientless): hcxdumptool → capture PMKID → hashcat -m 16800
 OR
Handshake (deauth): aireplay-ng --deauth → capture WPA handshake → aircrack-ng / hashcat
 ↓
Crack offline (hashcat):
 hashcat -m 22000 hash.hc22000 wordlist.txt --rules=OneRuleToRuleThemAll
 ↓
If cracked: Join network → lateral movement → C2
If not cracked: Evil Twin → captive portal → credential phish
```

## 3. Bluetooth / BLE Attack

```
Recon: Bettercap → scan BLE devices → identify target (name, MAC, service)
 ↓
BLE sniffing: Ubertooth / nRF Sniffer → capture BLE traffic → Wireshark
 ↓
Key extraction: If pairing capture → extract LTK (Long Term Key)
 ↓
Decrypt: All BLE traffic = decrypted with LTK
 ↓
Attack: GATT write → inject command → control device (smart lock, IoT)
 ↓
Relay: NFC relay (Proxmark3) → clone card → access physical door
```

## 4. SDR / RF Attack

| Frekuensi | Sinyal | Tool | Attack |
|-----------|--------|------|--------|
| **433 MHz** | Remote keyless, weather sensor, garage door | RTL-SDR, rtl_433 | Record + replay (rolljam), decode sensor |
| **868/915 MHz** | IoT (LoRa, Zigbee), smart meter | RTL-SDR, GNU Radio | Sniff, jam, inject |
| **1090 MHz** | ADS-B (aircraft transponder) | RTL-SDR, dump1090 | Track aircraft (OSINT) |
| **GPS L1 1575 MHz** | GPS signal | HackRF, GPS-SDR-SIM | Spoof GPS (fake location) |
| **GSM 900/1800** | 2G cell tower | HackRF, bladeRF | IMSI catcher (fake cell tower) |
| **POCSAG** | Pager message | RTL-SDR, multimon-ng | Intercept pager (hospital, emergency) |

## 5. Tool Stack Wireless

| Tool | Platform | Use | Harga |
|------|----------|-----|-------|
| **aircrack-ng** | WiFi | WPA crack, deauth, evil twin | Free |
| **Bettercap** | WiFi/BLE | MITM, BLE sniff, ARP spoof | Free |
| **hashcat** | GPU | WPA/WPA2/WPA3 offline crack | Free |
| **Ubertooth One** | BLE | Bluetooth sniffing | ~$120 |
| **Proxmark3** | RFID/NFC | Card clone, relay, skimming | ~$50-$400 |
| **RTL-SDR** | RF | Frequency scan, decode | ~$25 |
| **HackRF One** | RF | TX/RX (jam, spoof, inject) | ~$300 |
| **Nordic nRF Sniffer** | BLE | BLE packet capture | ~$100 |

## 6. Referensi
- aircrack-ng — https://www.aircrack-ng.org/
- Bettercap — https://www.bettercap.org/
- hashcat — https://hashcat.net/wiki/
- Proxmark3 — https://proxmark.com/
- RTL-SDR — https://www.rtl-sdr.com/
- HackRF — https://greatscottgadgets.com/hackrf/
- KillerBee (Zigbee) — https://github.com/riverloopsec/killerbee
---

audited
---
