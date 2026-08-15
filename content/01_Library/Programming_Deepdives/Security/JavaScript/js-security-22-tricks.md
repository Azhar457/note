---
title: 'JavaScript Security Best Practices — 22 Trik Deteksi Bot, Fingerprinting & Stealth'
tags:
  - javascript
  - security
  - fingerprinting
  - anti-bot
  - stealth
  - browser-security
  - red-team
aliases:
  - JavaScript Security 22 Trik
  - JS Bot Detection
  - JS Fingerprinting
created: '2026-08-10'
updated: '2026-08-10'
status: complete
cssclasses:
  - wide-table
---

# 🛡️ JAVASCRIPT SECURITY BEST PRACTICES — 22 Trik Deteksi Bot, Fingerprinting & Stealth

**Dari Canvas Fingerprinting hingga MutationObserver: Panduan Praktis JavaScript untuk Keamanan Siber**

tags:
  - javascript
  - security
  - anti-bot
  - fingerprinting
  - web-security
aliases:
  - JS Security Tricks
  - Bot Detection JS
  - JavaScript Fingerprinting
created: 2026-08-10
status: operational
cssclasses:
  - wide-table

---

> [!abstract] Tujuan Dokumen Ini
> JavaScript bukan hanya bahasa untuk UI. Di tangan seorang security engineer, JavaScript adalah senjata untuk **mendeteksi bot, mem-fingerprint pengguna, memanipulasi DOM secara stealth, dan mengeksfiltrasi data**. Trik-trik ini digunakan oleh tim Red Team untuk membangun tools ofensif, dan oleh Blue Team untuk membangun pertahanan anti-bot yang canggih. Setiap trik disertai kode yang bisa langsung dijalankan di browser.

---

## 🧭 Peta Kategori Trik

| Kategori | Trik # | Tujuan |
|----------|--------|--------|
| **Bot & Headless Detection** | 1, 2, 3, 4, 5 | Mendeteksi Puppeteer, Playwright, Selenium |
| **Fingerprinting** | 6, 7, 8, 9, 10, 11 | Identifikasi pengguna unik |
| **Stealth & Evasion** | 12, 13, 14, 15 | Menghindari deteksi bot |
| **DOM Monitoring** | 16, 17 | Mendeteksi manipulasi halaman |
| **Exfiltration & Tracking** | 18, 19, 20 | Mengirim data secara stealth |
| **Integritas & Tampering** | 21, 22 | Mendeteksi modifikasi kode/sumber daya |

---

## 1. Deteksi Headless Browser via `navigator.webdriver`

**Kapan Digunakan:** Mendeteksi browser yang diotomatisasi (Puppeteer, Selenium WebDriver)

```javascript
// Deteksi properti webdriver yang biasanya true di headless browser
function isWebDriver() {
    return navigator.webdriver === true;
}

// Beberapa bot mencoba menghapus properti ini
// Cek juga dengan Object.getOwnPropertyDescriptor
function isWebDriverDeep() {
    return Object.getOwnPropertyDescriptor(navigator, 'webdriver') !== undefined;
}

console.log('WebDriver detected:', isWebDriver());
```

**Mengapa Penting:**  
- Semua browser otomatis (kecuali yang di-stealth-patch) memiliki `navigator.webdriver === true`.  
- Ini adalah lini pertama deteksi bot.

**Best Practice:**  
- Kombinasikan dengan tes lain karena mudah di-bypass dengan `--disable-blink-features=AutomationControlled`.

---

## 2. Deteksi Bot via `window.chrome` & `navigator.plugins`

**Kapan Digunakan:** Mendeteksi inkonsistensi properti browser yang di-spoof

```javascript
// Headless Chrome sering tidak memiliki window.chrome
function detectHeadlessChrome() {
    if (!window.chrome) return true; // Chrome asli selalu punya window.chrome
    if (!navigator.plugins || navigator.plugins.length === 0) return true; // Headless sering kosong
    return false;
}

// Deteksi inkonsistensi: navigator.plugins harus punya namedItem
function pluginsInconsistency() {
    if (navigator.plugins) {
        // Headless sering punya plugins tapi tanpa method standar
        return typeof navigator.plugins.namedItem !== 'function';
    }
    return false;
}

console.log('Headless Chrome:', detectHeadlessChrome());
```

**Mengapa Penting:**  
- Browser headless memiliki inkonsistensi kecil di objek navigator.  
- Mendeteksi spoofing parsial yang dilakukan bot tingkat rendah.

**Best Practice:**  
- Gunakan bersama tes WebDriver untuk mengurangi false positive.

---

## 3. Event Timing Analysis — Bedakan Input Manusia vs Script

**Kapan Digunakan:** Mendeteksi apakah event mouse/keyboard dihasilkan oleh manusia atau script

```javascript
// Manusia memiliki jeda antar event; bot mengirim event instan
let lastEventTime = Date.now();
let suspiciousCount = 0;

document.addEventListener('mousemove', (e) => {
    const now = Date.now();
    const delta = now - lastEventTime;

    // Mouse move terlalu cepat (kurang dari 5ms) mencurigakan
    if (delta < 5) {
        suspiciousCount++;
        if (suspiciousCount > 10) {
            console.warn('Bot-like mouse activity detected!');
        }
    } else {
        suspiciousCount = 0; // Reset jika ada jeda alami
    }

    lastEventTime = now;
});
```

**Mengapa Penting:**  
- Bot mengirim event dalam loop tanpa delay, tidak mungkin dilakukan manusia.  
- Menganalisis timing adalah cara paling sulit untuk di-bypass.

**Best Practice:**  
- Gunakan sebagai sinyal tambahan; jangan blokir hanya berdasarkan timing.

---

## 4. Canvas Fingerprinting — Identifikasi Unik Pengguna

**Kapan Digunakan:** Menghasilkan hash unik dari rendering gambar di canvas

```javascript
function canvasFingerprint() {
    const canvas = document.createElement('canvas');
    canvas.width = 200;
    canvas.height = 50;
    const ctx = canvas.getContext('2d');

    // Render teks dengan font, warna, dan gaya spesifik
    ctx.font = '14px Arial';
    ctx.fillStyle = 'rgb(255, 0, 0)';
    ctx.fillText('BotOrHuman?', 10, 30);

    // Ekstrak data PNG dan hash
    const dataUrl = canvas.toDataURL();
    // Gunakan fungsi hash sederhana (atau kirim dataUrl ke server)
    let hash = 0;
    for (let i = 0; i < dataUrl.length; i++) {
        hash = ((hash << 5) - hash) + dataUrl.charCodeAt(i);
        hash |= 0;
    }
    return hash;
}

console.log('Canvas fingerprint:', canvasFingerprint());
```

**Mengapa Penting:**  
- Setiap perangkat menghasilkan gambar yang sedikit berbeda karena perbedaan GPU, driver, dan font rendering.  
- Sangat sulit di-spoof tanpa menurunkan kualitas visual.

**Best Practice:**  
- Gunakan bersama fingerprint lain; jangan andalkan satu metrik.

---

## 5. WebGL Fingerprinting — Sidik Jari GPU

**Kapan Digunakan:** Mendapatkan identitas unik GPU dan driver

```javascript
function webglFingerprint() {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    if (!gl) return 'webgl not supported';

    // Dapatkan informasi renderer dan vendor
    const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
    const vendor = gl.getParameter(debugInfo.UNMASKED_VENDOR_WEBGL);
    const renderer = gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);

    return `${vendor} | ${renderer}`;
}

console.log('WebGL fingerprint:', webglFingerprint());
```

**Mengapa Penting:**  
- Mengungkapkan vendor GPU, model, dan versi driver.  
- Sangat sulit di-spoof karena langsung dari hardware.

**Best Practice:**  
- Sinyal kuat untuk deteksi; bot sering menonaktifkan WebGL atau memiliki renderer generik.

---

## 6. AudioContext Fingerprinting — Sidik Jari Audio Stack

**Kapan Digunakan:** Mengidentifikasi perangkat melalui pemrosesan audio

```javascript
function audioFingerprint() {
    const ctx = new (window.AudioContext || window.webkitAudioContext)();
    const oscillator = ctx.createOscillator();
    const analyser = ctx.createAnalyser();
    const gain = ctx.createGain();

    oscillator.type = 'triangle';
    gain.gain.value = 0.1;
    oscillator.connect(analyser);
    analyser.connect(ctx.destination);

    // Ambil sampel frequency data
    const freqData = new Uint8Array(analyser.frequencyBinCount);
    analyser.getByteFrequencyData(freqData);

    // Hash sederhana dari data audio
    let hash = 0;
    for (let i = 0; i < freqData.length; i++) {
        hash = ((hash << 5) - hash) + freqData[i];
        hash |= 0;
    }
    ctx.close();
    return hash;
}

console.log('Audio fingerprint:', audioFingerprint());
```

**Mengapa Penting:**  
- Perbedaan kecil di perangkat keras audio dan driver menghasilkan sidik jari unik.  
- Sangat stabil (tidak berubah antar sesi).

**Best Practice:**  
- Gunakan untuk identifikasi jangka panjang; nilai hampir tidak pernah berubah.

---

## 7. Battery API Fingerprinting — Deteksi Perangkat

**Kapan Digunakan:** Mendapatkan informasi level baterai dan status pengisian

```javascript
async function batteryFingerprint() {
    if (!('getBattery' in navigator)) return 'Battery API not supported';

    const battery = await navigator.getBattery();
    return {
        charging: battery.charging,
        level: battery.level,
        chargingTime: battery.chargingTime,
        dischargingTime: battery.dischargingTime,
    };
}

batteryFingerprint().then(console.log);
```

**Mengapa Penting:**  
- Level baterai dan status pengisian bisa menjadi sidik jari tambahan.  
- Bot/VPS sering melaporkan "charging, level 100%" (tidak realistis).

**Best Practice:**  
- Gunakan sebagai sinyal tambahan, bukan utama (privasi sensitif).

---

## 8. Font Fingerprinting — Daftar Font Terinstal

**Kapan Digunakan:** Mengidentifikasi pengguna berdasarkan daftar font yang tersedia

```javascript
function fontFingerprint() {
    const baseFonts = ['monospace', 'sans-serif', 'serif'];
    const testFonts = [
        'Arial', 'Verdana', 'Times New Roman', 'Courier New',
        'Comic Sans MS', 'Impact', 'Georgia', 'Palatino',
        'Trebuchet MS', 'Helvetica', 'Segoe UI', 'Roboto'
    ];

    const canvas = document.createElement('canvas');
    const ctx = canvas.getContext('2d');

    const available = [];
    for (const font of testFonts) {
        for (const base of baseFonts) {
            ctx.font = `12px '${font}', ${base}`;
            const width = ctx.measureText('abcdefghijklmnopqrstuvwxyz0123456789').width;
            ctx.font = `12px ${base}`;
            const baseWidth = ctx.measureText('abcdefghijklmnopqrstuvwxyz0123456789').width;
            if (width !== baseWidth) {
                available.push(font);
                break;
            }
        }
    }
    return available.join(',');
}

console.log('Fonts:', fontFingerprint());
```

**Mengapa Penting:**  
- Daftar font adalah sidik jari yang kuat karena sangat bervariasi antar perangkat.  
- Bot/VPS sering memiliki set font minimal (hanya default OS).

**Best Practice:**  
- Gunakan untuk mendeteksi VPS/bot dengan font terbatas.

---

## 9. Client Rects Fingerprinting — Deteksi Viewport & Zoom

**Kapan Digunakan:** Mendeteksi ukuran viewport, zoom level, dan rasio piksel

```javascript
function viewportFingerprint() {
    const el = document.createElement('div');
    el.style.cssText = 'position:fixed;top:0;left:0;width:10px;height:10px';
    document.body.appendChild(el);

    const rect = el.getBoundingClientRect();
    document.body.removeChild(el);

    return {
        width: rect.width,
        height: rect.height,
        pixelRatio: window.devicePixelRatio,
        screenW: screen.width,
        screenH: screen.height,
        innerW: window.innerWidth,
        innerH: window.innerHeight,
    };
}

console.log('Viewport:', viewportFingerprint());
```

**Mengapa Penting:**  
- Bot sering menggunakan viewport default (800x600) atau tidak memiliki devicePixelRatio yang wajar.  
- Mendeteksi zoom dan scaling yang aneh.

**Best Practice:**  
- Gunakan untuk mendeteksi lingkungan non-manusia.

---

## 10. Timezone & Intl Fingerprinting — Lokasi vs Klaim

**Kapan Digunakan:** Mendeteksi inkonsistensi antara zona waktu, bahasa, dan lokasi IP

```javascript
function timezoneFingerprint() {
    const tz = Intl.DateTimeFormat().resolvedOptions().timeZone;
    const locale = navigator.language;
    const offset = new Date().getTimezoneOffset();

    // Cek apakah offset sesuai dengan timezone yang diiklankan
    // (logika validasi bisa ditambahkan di sini)
    return {
        timezone: tz,
        locale: locale,
        utcOffset: offset, // dalam menit, negatif = UTC+
    };
}

console.log('Timezone:', timezoneFingerprint());
```

**Mengapa Penting:**  
- Bot yang menggunakan proxy lintas negara sering memiliki zona waktu yang tidak cocok dengan IP.  
- Mendeteksi spoofing lokasi.

**Best Practice:**  
- Bandingkan dengan IP address di server untuk deteksi anomali.

---

## 11. Proxy Detection via WebRTC — Kebocoran IP Asli

**Kapan Digunakan:** Mendapatkan IP lokal asli di balik VPN/proxy

```javascript
function detectWebRTCLeak() {
    return new Promise((resolve) => {
        const pc = new RTCPeerConnection({ iceServers: [{ urls: 'stun:stun.l.google.com:19302' }] });
        pc.createDataChannel('');
        pc.createOffer().then(offer => pc.setLocalDescription(offer));

        pc.onicecandidate = (event) => {
            if (event.candidate) {
                const ipRegex = /\d+\.\d+\.\d+\.\d+/;
                const match = event.candidate.candidate.match(ipRegex);
                if (match) {
                    resolve(match[0]);
                    pc.close();
                }
            }
        };

        // Timeout 2 detik
        setTimeout(() => { resolve(null); pc.close(); }, 2000);
    });
}

detectWebRTCLeak().then(ip => console.log('WebRTC IP:', ip));
```

**Mengapa Penting:**  
- WebRTC bisa membocorkan IP lokal dan publik asli meskipun menggunakan VPN/proxy.  
- Bypass pengaturan proxy browser.

**Best Practice:**  
- Gunakan untuk mendeteksi pengguna yang menyembunyikan identitas.

---

## 12. Stealth: Menghapus `navigator.webdriver` (Red Team)

**Kapan Digunakan:** Mengakali deteksi bot sederhana

```javascript
// Override navigator.webdriver untuk menghindari deteksi
Object.defineProperty(navigator, 'webdriver', {
    get: () => undefined,
    configurable: true
});

// Untuk Puppeteer/Playwright, ini bisa dilakukan via evaluateOnNewDocument
// atau addInitScript untuk stealth mode.
```

**Mengapa Penting:**  
- Ini adalah langkah pertama dalam membangun bot yang tidak terdeteksi.  
- Tanpa ini, tes `navigator.webdriver` langsung menangkap bot.

**Best Practice:**  
- Gunakan bersama patch lain (headless detection bypass, fake plugins, dll.).

---

## 13. Stealth: Fake `window.chrome` & `navigator.plugins` (Red Team)

**Kapan Digunakan:** Meniru browser asli di lingkungan headless

```javascript
// Tambahkan window.chrome (headless biasanya tidak punya)
window.chrome = {
    runtime: {},
    loadTimes: function() {},
    csi: function() {},
    app: {}
};

// Tambahkan plugins palsu
Object.defineProperty(navigator, 'plugins', {
    get: () => {
        return [
            { name: 'Chrome PDF Plugin', filename: 'internal-pdf-viewer' },
            { name: 'Chrome PDF Viewer', filename: 'mhjfbmdgcf...' },
            { name: 'Native Client', filename: 'internal-nacl-plugin' },
        ];
    },
    configurable: true
});
```

**Mengapa Penting:**  
- Mengisi celah yang ditinggalkan browser headless.  
- Membuat bot lebih mirip browser manusia.

**Best Practice:**  
- Teliti properti browser asli dan tiru secara akurat.

---

## 14. MutationObserver — Deteksi Manipulasi DOM

**Kapan Digunakan:** Mendeteksi apakah bot mengubah konten halaman

```javascript
// Pantau perubahan DOM — jika ada perubahan masif dalam waktu singkat, mungkin bot
const observer = new MutationObserver((mutations) => {
    let changedNodes = 0;
    for (const mut of mutations) {
        changedNodes += mut.addedNodes.length + mut.removedNodes.length;
    }

    if (changedNodes > 50) {
        console.warn('Massive DOM change detected!', changedNodes);
    }
});

observer.observe(document.body, {
    childList: true,
    subtree: true,
    attributes: true,
});
```

**Mengapa Penting:**  
- Bot sering memodifikasi DOM secara masif (mengisi form, menghapus popup, dll.).  
- Mendeteksi aktivitas tidak wajar di halaman.

**Best Practice:**  
- Gunakan untuk mendeteksi otomatisasi yang agresif.

---

## 15. Shadow DOM — Sembunyikan Elemen dari Bot

**Kapan Digunakan:** Menyembunyikan konten dari scraper sederhana

```javascript
// Buat elemen yang tidak terlihat oleh querySelector biasa
const host = document.createElement('div');
const shadow = host.attachShadow({ mode: 'closed' });
const hiddenContent = document.createElement('span');
hiddenContent.textContent = 'Data Rahasia';
shadow.appendChild(hiddenContent);

document.body.appendChild(host);

// Bot yang menggunakan document.querySelector('span') tidak akan menemukan ini
console.log('Shadow DOM hidden element created');
```

**Mengapa Penting:**  
- Scraper berbasis DOM sederhana tidak bisa mengakses Shadow DOM closed.  
- Melindungi konten sensitif dari scraping.

**Best Practice:**  
- Gunakan `mode: 'closed'` agar tidak bisa diakses dari luar.

---

## 16. IntersectionObserver — Deteksi Viewport & Scrolling Manusia

**Kapan Digunakan:** Membedakan pengguna manusia yang scrolling dengan bot

```javascript
const detectionBox = document.createElement('div');
detectionBox.style.cssText = 'position:fixed;bottom:0;left:0;width:100%;height:50px;z-index:-1';
document.body.appendChild(detectionBox);

let humanScrollDetected = false;
const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
        if (entry.isIntersecting) {
            humanScrollDetected = true;
            console.log('Human scrolling detected!');
        }
    }
});

observer.observe(detectionBox);
```

**Mengapa Penting:**  
- Bot tidak men-scroll secara alami; mereka langsung akses seluruh halaman.  
- Mendeteksi apakah pengguna benar-benar melihat halaman.

**Best Practice:**  
- Tempatkan elemen deteksi di berbagai posisi halaman.

---

## 17. Service Worker — Tracking & Offline Cache Stealth

**Kapan Digunakan:** Melacak pengguna lintas sesi tanpa cookie

```javascript
// Daftarkan Service Worker untuk intercept request dan tracking
if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js').then(reg => {
        console.log('SW registered');
    });
}

// sw.js — simpan fingerprint pengguna di cache
self.addEventListener('install', (event) => {
    self.skipWaiting();
});

self.addEventListener('fetch', (event) => {
    // Dapat menyimpan informasi pengguna di cache untuk tracking persisten
    // Ini bertahan meskipun storage browser dibersihkan
});
```

**Mengapa Penting:**  
- Service worker bertahan setelah storage browser dibersihkan.  
- Sangat sulit dihapus (perlu unregister manual).

**Best Practice:**  
- Gunakan untuk tracking jangka panjang; perhatikan aspek legal (GDPR).

---

## 18. Beacon API — Exfiltrasi Data Stealth

**Kapan Digunakan:** Mengirim data ke server tanpa menunggu respons

```javascript
// Kirim data saat pengguna meninggalkan halaman
window.addEventListener('beforeunload', () => {
    const data = JSON.stringify({
        fingerprint: canvasFingerprint(),
        timestamp: Date.now(),
        url: location.href,
    });

    // navigator.sendBeacon tidak memblokir unload, sangat stealth
    navigator.sendBeacon('https://collector.example.com/log', data);
});
```

**Mengapa Penting:**  
- `sendBeacon` mengirim data bahkan setelah tab ditutup.  
- Tidak bisa diblokir oleh `XMLHttpRequest` atau `fetch` biasa.

**Best Practice:**  
- Gunakan untuk exfiltrasi data yang harus sampai meskipun pengguna menutup browser.

---

## 19. Cache API — Penyimpanan Data Stealth

**Kapan Digunakan:** Menyimpan data yang bertahan setelah storage dibersihkan

```javascript
// Simpan data di Cache API (bukan localStorage)
async function stealthStorage(key, value) {
    const cache = await caches.open('app_cache_v1');
    const response = new Response(JSON.stringify(value));
    await cache.put(`/data/${key}`, response);
}

async function stealthRetrieve(key) {
    const cache = await caches.open('app_cache_v1');
    const response = await cache.match(`/data/${key}`);
    return response ? response.json() : null;
}
```

**Mengapa Penting:**  
- Cache API tidak ikut terhapus saat "Clear browsing data" (tergantung browser).  
- Tempat persisten untuk menyimpan fingerprint.

**Best Practice:**  
- Gunakan untuk backup data; jangan andalkan sebagai satu-satunya penyimpanan.

---

## 20. CSP & SRI Bypass Detection — Deteksi Injeksi Script

**Kapan Digunakan:** Mendeteksi apakah script eksternal telah dimodifikasi

```javascript
// Periksa integritas script dengan membandingkan hash
async function checkScriptIntegrity(url, expectedHash) {
    const response = await fetch(url);
    const text = await response.text();

    // Hitung hash (SHA-256 via SubtleCrypto)
    const encoder = new TextEncoder();
    const data = encoder.encode(text);
    const hashBuffer = await crypto.subtle.digest('SHA-256', data);
    const hashArray = Array.from(new Uint8Array(hashBuffer));
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('');

    return hashHex === expectedHash;
}
```

**Mengapa Penting:**  
- Mendeteksi jika CDN atau script pihak ketiga telah di-tamper.  
- Validasi integritas di sisi klien.

**Best Practice:**  
- Gunakan SRI (Subresource Integrity) di tag `<script>` untuk pencegahan.

---

## 21. Cookie Tampering Detection — Deteksi Modifikasi Cookie

**Kapan Digunakan:** Mendeteksi jika pengguna mengubah cookie secara manual

```javascript
// Set cookie dengan signature HMAC
function setSignedCookie(name, value, secret) {
    const signature = btoa(value + ':' + secret); // Sederhana, gunakan HMAC di production
    document.cookie = `${name}=${value}.${signature}; path=/; Secure`;
}

function checkCookieIntegrity(name, secret) {
    const cookies = document.cookie.split('; ');
    for (const cookie of cookies) {
        const [key, val] = cookie.split('=');
        if (key === name) {
            const [value, signature] = val.split('.');
            const expectedSig = btoa(value + ':' + secret);
            return signature === expectedSig;
        }
    }
    return false;
}
```

**Mengapa Penting:**  
- Mencegah privilege escalation dengan memodifikasi cookie.  
- Memastikan data cookie berasal dari server yang sah.

**Best Practice:**  
- Selalu validasi cookie di sisi server; ini adalah lapisan tambahan.

---

## 22. Console DevTools Detection — Deteksi Developer Tools Terbuka

**Kapan Digunakan:** Mendeteksi jika pengguna membuka DevTools (sering digunakan oleh pentester)

```javascript
function detectDevTools() {
    const threshold = 160;
    const isOpen = () => {
        const widthThreshold = window.outerWidth - window.innerWidth > threshold;
        const heightThreshold = window.outerHeight - window.innerHeight > threshold;
        return widthThreshold || heightThreshold;
    };

    // Juga deteksi via timing console.log
    const start = performance.now();
    debugger; // Jika DevTools terbuka, eksekusi berhenti di sini
    const end = performance.now();
    const timingCheck = (end - start) > 100;

    return isOpen() || timingCheck;
}

console.log('DevTools open:', detectDevTools());
```

**Mengapa Penting:**  
- Mendeteksi reverse engineering atau debugging oleh penyerang.  
- Bisa memicu penghancuran data atau redirect jika DevTools terdeteksi.

**Best Practice:**  
- Gunakan dengan hati-hati; bisa menghasilkan false positive.

---

## 🔗 Koneksi ke Vault

| Domain Vault | Koneksi dengan Trik JavaScript |
|--------------|-------------------------------|
| **[[web-hacking-exploitation]]** | Fingerprinting, bot detection, DOM manipulation |
| **[[browser-security-exploitation-deepdive]]** | DevTools detection, CSP bypass, service worker |
| **[[osint]]** | Canvas/WebGL fingerprinting untuk tracking |
| **[[digital-privacy-anonymity]]** | WebRTC leak detection, stealth evasion |
| **[[network-security]]** | Cookie tampering, script integrity |
| **[[underground-knowledge]]** | Stealth techniques, anti-detection |

---

*JavaScript Security | 22 Trik Deteksi Bot · Fingerprinting · Stealth · Exfiltration*
---

audited
---
