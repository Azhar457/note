---
title: "APK Modding Pipeline — Fedora 44 (apktool → smali → zipalign → apksigner)"
tags:
  - android-reverse-engineering
  - apk-modding
  - smali
  - fedora
created: "2026-08-09"
updated: "2026-08-09"
status: pending
cssclasses:
  - wide-table
  
  - code-wrap

tools: [apktool, jadx, zipalign, apksigner, android-sdk]
---

# APK Modding Pipeline (Fedora 44)

Pipeline lengkap untuk memodifikasi APK (license flip, UI patch, feature unlock)
di Fedora 44. **Diuji nyata** pada Cloudflare 1.1.1.1 v6.32 (`com.cloudflare.onedotonedotonedotone`):
patch `WarpPlusState` → tampil "WARP+ UNLIMITED Connected — Your Internet Is Private".

> ⚠️ **Peringatan validasi**: patch UI ≠ fitur server-side. Untuk Cloudflare WARP+, status
> premium (`account_type`, `quota`) di-enforce di server (`api.cloudflareclient.com`).
> Patch hanya mengubah tampilan app. Verifikasi kebenaran via `https://www.cloudflare.com/cdn-cgi/trace`
> → lihat `warp=plus|on|off` (nilai dari server, bukan app).

## Flow WAJIB (urutan tidak boleh tertukar)

```
1. apktool d   → decode APK ke smali (EDITABLE)
2. edit smali  → ubah logic (VS Code + plugin Smali)
3. apktool b   → build balik jadi APK
4. zipalign    → ⚠️ WAJIB sebelum sign (4-byte align) ← pitfall "app not installed"
5. apksigner   → sign debug keystore
6. deploy      → adb install / kirim WA (rename .apk jika WA compress)
```

### Command (path Fedora 44)

```bash
export SDK=/home/jars/Android/Sdk/android-14

# 1. Decode (sekali)
java -jar /home/jars/RE-tools/apktool.jar d -f -o apktool_out target.apk
/home/jars/RE-tools/jadx/bin/jadx -d jadx_out target.apk   # baca Java (read-only)

# 2. Edit — smali di apktool_out/ (BUKAN jadx_out/ yang read-only)
code apktool_out/

# 3. Build balik
java -jar /home/jars/RE-tools/apktool.jar b apktool_out -o modified.apk

# 4. zipalign (WAJIB sebelum sign!)
$SDK/zipalign -f 4 modified.apk aligned.apk
$SDK/zipalign -c -v 4 aligned.apk | tail -1    # harus "Verification succesful"

# 5. Sign (debug keystore)
$SDK/apksigner sign --ks ~/.android/debug.keystore --ks-pass pass:android \
    --key-pass pass:android --ks-key-alias androiddebugkey \
    --out final_signed.apk aligned.apk
$SDK/apksigner verify --print-certs final_signed.apk   # harus "Verifies"

# 6. Deploy
adb install final_signed.apk     # USB + USB debugging
# atau kirim via WA → rename ke .apk jika WA ubah ekstensi
```

## Struktur yang diedit (mana yang benar)

| Folder | Isi | Bisa edit? | Bisa compile balik? |
|--------|-----|-----------|---------------------|
| `apktool_out/smali/**` | smali (1:1 dex) | ✅ | ✅ via apktool b |
| `jadx_out/sources/**` | Java decompile (read-only) | ❌ | ❌ |

- **Jadx** = untuk BACA logic (Java lebih terbaca daripada smali). Kadang buang blok
  (`JADX WARN: Code restructure failed`) — **normal**, smali tetap lengkap 100%.
- **apktool** = untuk EDIT + rebuild. Smali adalah assembly Android (register-based).

## Pitfall yang sudah kena (validated)

1. **"app not installed as package appears to be invalid"** di detik terakhir
   → APK tidak zipalign (build `apktool b` menghasilkan entry tidak aligned).
   **Fix: zipalign SEBELUM apksigner.** (Terjadi nyata: patched Cloudflare APK
   gagal install, setelah zipalign + re-sign → sukses install.)
2. **Uninstall versi asli dulu** — signature beda (Google vs debug) → install gagal
   meskipun APK valid. Android butuh signature SAMA untuk update path.
3. **Jangan swap ordinal enum kalau mapping JSON "by name"** (moshi `@q(name=...)`
   resolve by name, bukan ordinal). Patch di adapter/parse point lebih efektif:
   ```smali
   # di AccountDataJsonAdapter.smali, :pswitch_7 (case account_type)
   # setelah check-cast WarpPlusState, paksa:
   sget-object v8, Lcom/cloudflare/app/data/warpapi/WarpPlusState;->UNLIMITED:Lcom/cloudflare/app/data/warpapi/WarpPlusState;
   # abaikan hasil parse server
   ```
4. **WA/Bluetooth compress APK** → file mengecil/ekstensi berubah. Cek ukuran
   + rename `.apk` di HP.
5. **Gate logic kadang pakai enum TIDAK sesuai intuition**: app mungkin
   ngecek `TEAM` (bukan `FREE`/`UNLIMITED`) — baca seluruh xref sebelum patch:
   ```bash
   grep -rn "WarpPlusState\." apktool_out/smali*/ | grep -oE "->[A-Z]+" | sort | uniq -c | sort -rn
   ```

## Verifikasi hasil patch (server-side honest)

- UI berubah ≠ fitur server. Untuk WARP: cek `warp=plus|on|off` via
  `https://www.cloudflare.com/cdn-cgi/trace` dari perangkat terkoneksi tunnel.
- Patch kosmetik (label UNLIMITED) valid sebagai RE skill — tetapi
  `quota`/`premium_data` tetap dari server. `.so` (libnativetunnel.so, Rust/boringtun)
  tidak punya anti-tamper & license check — seluruh logic license ada di
  Java (dex) + server. Jadi mod aman dari crash anti-tamper.

## Opsional: integrasi sing-box rotator standalone

Bahan terkait di `~/.local/share/singbox-rotator/`:
- `rotator.py start --no-9r` — standalone mode: 20 SOCKS proxy lokal
  (11080–11099) + HTTP (21080–21099) tanpa dependensi 9Router.
- `pac-server.py` — PAC server lokal tetap jalan (baca `state.json`,
  `pool_id: null` untuk standalone).
- Untuk routing WARP/Cloudflare setup: gunakan SOCKS lokal sebagai
  outbound proxy (bukan patch app).

## File & alat terkait

- `apktool.jar` → `/home/jars/RE-tools/apktool.jar`
- jadx → `/home/jars/RE-tools/jadx/bin/`
- Android SDK build-tools → `/home/jars/Android/Sdk/android-14`
- Sampel teruji: `~/TESTFROMDARKNET/re_cf1111/` (CF 1.1.1.1)


## Pitfall & Troubleshooting (Pengalaman Nyata)

### App Tidak Bisa Install

| Gejala | Penyebab | Fix |
|--------|----------|-----|
| "App not installed" | zipalign tidak dijalankan / salah urutan | `zipalign -f 4` SEBELUM sign |
| "Parse error" | APK corrupt / signing salah | Build ulang + `apksigner verify` |
| "Signature mismatch" | Update dari store dengan signature beda | Uninstall dulu, baru install modded |
| Package name bentrok | Sama dengan app terpasang | `adb uninstall com.pkg` dulu |

### APK Tidak Mau Build Balik

1. **Resource conflict**: apktool gagal rebuild karena resource ID berubah → coba `apktool b --use-aapt2`
2. **Smali syntax error**: register tidak match → cek `.locals` dan register count, error di log apktool
3. **Proguard/obfuscation**: nama class di-mangle → jadx tetap baca, tapi smali edit harus cari by string reference

### WARP+ Quota — Konteks Server-Side

```bash
# Cek status nyata (bukan tampilan app)
curl https://www.cloudflare.com/cdn-cgi/trace
# → warp=plus  : akun benar-benar premium
# → warp=on    : hanya VPN aktif (bukan plus)
# → warp=off   : VPN mati
```

Patch UI (`WarpPlusState`) hanya mengubah string tampilan. Quota premium (`account_type`, `quota`) di-enforce server `api.cloudflareclient.com` — kalau token tidak valid, server tetap tolak. Jangan percaya tampilan app; verifikasi via trace endpoint.

### Keystore Management

```bash
# Buat keystore sendiri (production / non-debug)
keytool -genkey -v -keystore my.keystore -alias mykey -keyalg RSA -keysize 2048 -validity 10000

# Sign dengan keystore custom
$SDK/apksigner sign --ks my.keystore --ks-pass pass:PASSWORD --out final.apk aligned.apk
```

Debug keystore (`~/.android/debug.keystore`) hanya untuk testing lokal — Play Store menolak signature debug. Untuk distribusi: buat keystore release dan simpan di tempat aman (kehilangan keystore = tidak bisa update app).

## References

- apktool — https://ibotpeaches.github.io/Apktool/
- jadx — https://github.com/skylot/jadx
- Android Build Tools (zipalign/apksigner) — https://developer.android.com/tools
- Smali — https://github.com/JesusFreke/smali
- Cloudflare trace — https://www.cloudflare.com/cdn-cgi/trace
---

audited
---
