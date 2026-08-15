---
title: IoT Security Deepdive
tags: [security, iot, attacker]
aliases: [iot-security-deepdive]
---
# IoT Security — Deepdive (Attack & Defense)

IoT = embedded device dengan koneksi jaringan: kamera, router, sensor, printer, smart home. Keamanannya sering lemah: firmware lama, default credential, update jarang, protokol tidak aman. Dari sudut penyerang: IoT = pintu masuk jaringan & botnet material; dari blue: memahami permukaan serangan untuk proteksi.

## Permukaan Serangan IoT

```
┌─────────────────────────────────────────┐
│ Physical   : UART, JTAG, SPI, USB,     │
│              reset button, SD/eMMC     │
├─────────────────────────────────────────┤
│ Network    : web UI (port 80/443),     │
│              telnet/ssh, mDNS/UPnP,    │
│              MQTT, CoAP, cloud API     │
├─────────────────────────────────────────┤
│ Firmware   : update OTA, extraction,   │
│              filesystem, bootloader    │
├─────────────────────────────────────────┤
│ Radio      : BLE, Zigbee, Z-Wave,      │
│              Wi-Fi (WPS), NFC          │
└─────────────────────────────────────────┘
```

## 1. Firmware & Hardware

- **Extraction**: UART (serial console — sering root shell tanpa auth), JTAG (debug — dump flash, chip-off), SPI flash read.
- **Firmware analysis**: binwalk (extract FS), strings (secret/URL), entropy (encrypted? packed?), filesystem (squashfs/cpio/ubi), run di emulator (QEMU) — lihat [[firmware-reverse-engineering-deepdive]].
- **Hardcoded secrets**: kredensial root default, API key cloud, private key SSH — grep strings.
- **Boot**: secure boot tidak aktif → modifikasi firmware; check bootloader (U-Boot console).
- **Rabbit hole**: crypto keys di firmware → decrypt update, sign payload sendiri.

### Alur Analisis Firmware (Ringkas)
1. Dapatkan firmware (vendor support page, OTA endpoint, dump via UART/SPI).
2. `binwalk -Me firmware.bin` — extract.
3. Identifikasi FS (squashfs: `unsquashfs`, ubifs: `ubireader_extract_files`).
4. Strings + grep: password, API key, IP, `/etc/passwd`, init scripts, web pages.
5. Emulate + debug (QEMU user/system mode; firmware analysis toolkit).

## 2. Jaringan & Service

- **Default credential** — masih #1: admin/admin, root/root, ubnt/ubnt; cek konsol login.
- **Telnet/SSH lemah** — telnet tanpa enkripsi; SSH dengan key default (diprediksi: e.g. cert di firmware).
- **Web UI vuln** — SQLi/XSS/command injection di admin panel (auth bypass sering).
- **UPnP/SSDP** — refleksi DDoS, port forward tanpa auth.
- **MQTT tanpa TLS/auth** — publish/subscribe terbuka (lihat [[ai-comm-protocol-deepdive]]).
- **Cloud API** — IDOR (deviceID user lain), firmware update endpoint (mitm/poison), token statis.
- **Broadcast/radio**: BLE pairing lemah (Just Works), Zigbee key default (Zigbee Alliance test key), WPS PIN brute (router).

## 3. Ekosistem Botnet (Kenapa IoT Diserang)

- **Mirai** (2016): default credential scanner → botnet DDoS 620 Gbps. Kode sumber terbuka → puluhan varian.
- **Moose, Hajime, Gafgyt** — varian/berbeda: telnet brute, vuln exploit (CVE-2017-17215 Huawei HG532 RCE, CVE-2018-10561/10562 GPON auth bypass).
- **Androids botnet** (AdbMiner) — ADB debug tanpa auth.
- **Dampak**: DDoS besar, proxy abuse, crypto mining, pivot jaringan.

Deteksi sebagai blue: scan internal untuk device dengan telnet terbuka, default password (honeypot), traffic mencurigakan (DDoS patterns, mining pool).

## 4. Attack Workflow (Red Team, IoT di Jaringan Client)

1. **Discovery**: nmap/UDP scan (UPnP, mDNS via avahi), ARP — temukan device.
2. **Web UI**: cek login default; fuzz endpoint (auth bypass); burp untuk repeater.
3. **Firmware**: cek update check (mitm), download firmware, analisis statik; cari backdoor/hidden shell.
4. **Radio**: BLE scan (hcitool/btlejack) — pairing, GATT services; Zigbee sniffer.
5. **Pivot**: device sebagai foothold → jaringan internal (jika sama network segment).

## 5. Defense (Blue Team & Vendor)

### Untuk vendor/builder:
1. No default credential — first-boot setup wajib.
2. Secure boot + signed firmware + OTA TLS + rotation key.
3. Update lifecycle: patch support jelas (EOL policy!).
4. Web admin: TLS, auth kuat, input validation, CSRF.
5. Network service: telnet off by default; SSH with per-device key.
6. Minimal attack surface: tutup port tidak perlu (UPnP off, mDNS limit).
7. Secure elements untuk crypto keys (jika grade enterprise).

### Untuk pengguna/admin jaringan:
1. **Segregasi**: IoT di VLAN terpisah (tidak bisa reach laptop/DC).
2. **Update rutin**: vendor app/OTA; monitor EOL (device tua = risiko).
3. **Credentials**: ganti semua default; MFA jika didukung.
4. **Monitoring**: DNS sinkhole (Pi-hole) untuk domain mencurigakan; traffic anomaly (new device beaconing).
5. **Firewall egress**: blokir keluar kecuali whitelist (IoT sering beacon C2).
6. **Network discovery**: lakukan audit berkala (nmap internal) — device tak dikenal = temuan.

## 6. Tools Summary

| Kategori | Tools |
|----------|-------|
| Firmware | binwalk, unsquashfs, ubireader, firmware-analysis-toolkit (FAT), QEMU |
| Hardware | UART (logic analyzer, screen/minicom), JTAG (openocd), SPI flash (flashrom, Bus Pirate) |
| Network | nmap, masscan, hydra (crack default), tcpdump, Wireshark |
| Web | Burp, ffuf, nuclei (IoT templates) |
| Radio | btlejack, gattlib, hcitool, zigpy/zllsniffer, HackRF (SDN) |
| SCADA/ICS | lihat Data/ICS notes (Modbus, DNP3) |

## 7. Case Study: Kamera IP

1. Nmap: port 80 (web) + 554 (RTSP) + 23 (telnet) + 37777 (Dahua custom).
2. Default creds: admin/blank (vendor lama).
3. Web UI: RCE via command injection di parameter (CVE nyata: CVE-2017-8225, CVE-2018-10819 Hikvision backdoor password).
4. Firmware: OTA tanpa signature → modifikasi.
5. Pivot: kamera di jaringan yang sama → ARP spoof ke server.

Blue: ganti password, update firmware, VLAN isolasi, blokir egress.

## Checklist

- [ ] Semua device: default credential diganti?
- [ ] Firmware & app update terjadwal (EOL check)?
- [ ] IoT di VLAN terpisah?
- [ ] Telnet/port tidak perlu dimatikan?
- [ ] Egress firewall whitelist?
- [ ] Monitoring: DNS sinkhole + anomaly?
- [ ] Documented inventory (device, firmware, owner)?

---

  audited
---