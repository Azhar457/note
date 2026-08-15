---
tags: [frontend-engineering, webgis, geolocation, cgnat, browser-api, precision-tracking]
aliases: [WebGIS Precision Tracking, CGNAT Geolocation Bypass, Browser Location API Deep Dive]
status: pending
created: 2026-08-15
updated: 2026-08-15
cssclasses: [wide-table]
---

> [!abstract]
> Carrier-Grade NAT (CGNAT) menutupi ribuan pengguna di belakang satu IP publik, membuat IP geolocation hanya mengembalikan lokasi datacenter ISP, bukan posisi pengguna sesungguhnya. Dokumen ini memetakan **setiap metode praktis** untuk memperoleh koordinat presisi melalui browser — dari GPS/GNSS (3-10m), WiFi RTT 802.11mc (1-2m indoor), BLE beacon (1-5m), cell tower triangulation (50m-5km), browser fingerprinting + historical correlation, hingga passive network timing side-channels dan sensor fusion. Vault sudah memiliki [[cgnat-attribution-deepdive|CGNAT Attribution Deep Dive]] (fokus identifikasi pelaku via log jaringan) — catatan ini melengkapi dari sisi **client-side precision tracking** untuk aplikasi WebGIS.

# 📍 WebGIS Precision Tracking — Beyond IP Geolocation Under CGNAT

**Accurate client positioning when IP-based geolocation fails. Multi-layered approach from browser APIs to passive fingerprinting.**

## Daftar Isi
1. [[#🧭 Precision Hierarchy]]
2. [[#1. GPS/GNSS via Geolocation API — Maximum Accuracy]]
3. [[#2. WiFi-Based Precision — Indoor & Urban Canyon]]
4. [[#3. BLE Beacon Positioning — Micro-Location]]
5. [[#4. Cell Tower Triangulation — Wide Area Fallback]]
6. [[#5. Browser Fingerprinting + Historical Correlation]]
7. [[#6. Passive Network Timing Side-Channels]]
8. [[#7. Sensor Fusion — Combining All Sources]]
9. [[#8. Passive Subscriber Data — Beyond the Browser]]
10. [[#📊 Decision Matrix — Which Method When]]
11. [[#🔗 Related Infrastructure]]
12. [[#References]]
13. [[#Koneksi ke Vault]]

---

## 🧭 Precision Hierarchy

| Method | Typical Accuracy | Requires Permission | Works Behind CGNAT |
|--------|------------------|---------------------|---------------------|
| **GPS/GNSS (browser)** | 3-10m | Yes (HTTPS + user gesture) | Yes |
| **WiFi RTT / 802.11mc** | 1-2m indoor | Yes | Yes |
| **WiFi triangulation (Google/Apple DB)** | 10-25m | Yes | Yes |
| **Cell tower triangulation** | 50m-5km | Yes | Yes |
| **Bluetooth LE beacons** | 1-5m indoor | Yes + BLE scan | Yes |
| **Browser fingerprint → historical correlation** | Varies | No | Yes |
| **HTML5 Geolocation API (fallback)** | 10m-50km | Yes | Yes |
| **IP geolocation (baseline)** | City-level at best | No | No (CGNAT kills it) |

---

## 1. GPS/GNSS via Geolocation API — Maximum Accuracy

**How it works:** Browser requests OS-level location. OS uses GPS chip, WiFi scanning, or cell towers depending on device capabilities. Under HTTPS, modern browsers expose high-accuracy mode.

```javascript
/**
 * High-accuracy position request.
 * On devices with GPS (phones, tablets, some laptops),
 * this returns lat/lon within 3-10 meters.
 * Behind CGNAT — doesn't matter. GPS is client-side.
 */
async function getHighAccuracyPosition() {
  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error("Geolocation not supported"));
      return;
    }

    const options = {
      enableHighAccuracy: true,   // Force GPS-level precision
      timeout: 30000,             // 30 seconds max wait for GPS fix
      maximumAge: 0               // Never use cached position
    };

    navigator.geolocation.getCurrentPosition(
      (position) => {
        const result = {
          latitude: position.coords.latitude,
          longitude: position.coords.longitude,
          accuracy: position.coords.accuracy,        // meters, 95% confidence
          altitude: position.coords.altitude,        // meters, may be null
          altitudeAccuracy: position.coords.altitudeAccuracy,
          heading: position.coords.heading,          // degrees from true north
          speed: position.coords.speed,              // m/s
          timestamp: position.timestamp,
          source: "GNSS/WiFi/Cell (OS-level)"
        };
        resolve(result);
      },
      (error) => {
        // Graceful degradation
        switch(error.code) {
          case error.PERMISSION_DENIED:
            reject(new Error("User denied geolocation"));
            break;
          case error.POSITION_UNAVAILABLE:
            reject(new Error("Position unavailable — fallback needed"));
            break;
          case error.TIMEOUT:
            reject(new Error("GPS fix timed out — try WiFi fallback"));
            break;
        }
      },
      options
    );
  });
}

/**
 * Continuous tracking for movement — watchPosition.
 * Use for real-time asset tracking, fleet management.
 */
function startContinuousTracking(onPosition, onError) {
  const watchId = navigator.geolocation.watchPosition(
    (position) => {
      onPosition({
        lat: position.coords.latitude,
        lon: position.coords.longitude,
        accuracy: position.coords.accuracy,
        speed: position.coords.speed,
        heading: position.coords.heading,
        ts: Date.now()
      });
    },
    onError,
    {
      enableHighAccuracy: true,
      timeout: 15000,
      maximumAge: 5000  // Accept 5-second-old positions for smooth tracking
    }
  );
  return watchId; // Call navigator.geolocation.clearWatch(watchId) to stop
}
```

**Backend validation — store the accuracy metadata:**

```python
# Django/Flask endpoint receiving location pings
from dataclasses import dataclass
from datetime import datetime, timezone

@dataclass
class LocationPing:
    latitude: float
    longitude: float
    accuracy: float         # Horizontal accuracy in meters
    altitude: float | None
    speed: float | None
    heading: float | None
    source: str             # "gps", "wifi", "cell", "manual"
    client_ts: int          # Epoch ms from client
    server_ts: datetime     # Server timestamp on receipt

    def is_reliable(self) -> bool:
        """Filter out obviously bad pings."""
        if self.accuracy > 500:    # >500m accuracy — reject for precision use
            return False
        if self.latitude == 0 and self.longitude == 0:
            return False           # Default/null location
        if self.speed and self.speed > 300:  # >1080 km/h — impossible
            return False
        return True
```

**Why this beats IP geolocation:**
- GPS is client-side — CGNAT is irrelevant.
- Accuracy metadata lets you filter bad pings server-side.
- `watchPosition` gives continuous tracks, not single points.

---

## 2. WiFi-Based Precision — Indoor & Urban Canyon

### 2a. WiFi Triangulation via Browser (Google Geolocation API)

When GPS is unavailable (indoors, urban canyons), the browser falls back to WiFi scanning. The browser scans visible WiFi access points (BSSID + signal strength) and sends them to Google's or Apple's geolocation service.

**This happens automatically** with `enableHighAccuracy: true` — no extra code needed. But you can also call the Google Geolocation API directly for more control:

```javascript
/**
 * Direct Google Geolocation API call with WiFi AP data.
 * Requires an API key.
 * Works when browser's built-in geolocation fails or you want raw AP data.
 */
async function googleWiFiGeolocation(apiKey) {
  // This requires the browser to support WiFi scanning
  // Currently limited: ChromeOS, some Android WebView contexts
  // For full WiFi AP scanning, you need a native app or Chrome extension

  const response = await fetch(
    `https://www.googleapis.com/geolocation/v1/geolocate?key=${apiKey}`,
    {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        considerIp: false,  // Don't fall back to IP — we want WiFi precision
        wifiAccessPoints: [
          // Populate from native WiFi scan
          // { macAddress: "00:11:22:33:44:55", signalStrength: -65 }
        ]
      })
    }
  );
  return response.json();
}
```

### 2b. WiFi RTT (802.11mc) — Sub-Meter Indoor

**Requires:** Android 9+ with WiFi RTT-capable hardware, Chrome 91+ on compatible devices.

802.11mc / WiFi Round-Trip-Time provides **1-2 meter accuracy indoors** by measuring the time radio waves take to travel between device and access point. No triangulation — direct distance measurement.

```javascript
/**
 * Check if WiFi RTT is available on this device.
 * Limited browser support as of 2026 — primarily Android + Chrome.
 */
async function isWiFiRttAvailable() {
  if (!('rtt' in navigator)) {
    return false;
  }
  try {
    // @ts-ignore — experimental API
    const capabilities = await navigator.rtt.getCapabilities();
    return capabilities && capabilities.rttSupported;
  } catch (e) {
    return false;
  }
}

/**
 * Range to known APs using WiFi RTT.
 * Requires APs to support 802.11mc (FTM Responder role).
 */
async function measureWiFiRtt(accessPoints) {
  // @ts-ignore
  if (!navigator.rtt) throw new Error("WiFi RTT not supported");

  // @ts-ignore
  const results = await navigator.rtt.range({
    accessPoints: accessPoints.map(ap => ({
      bssid: ap.bssid,
      frequency: ap.frequency,  // 2412 for 2.4GHz, 5180 for 5GHz
      channelWidth: ap.channelWidth || 80
    })),
    timeout: 10000
  });

  // Each result contains distance in mm and standard deviation
  return results.map(r => ({
    bssid: r.bssid,
    distanceMeters: r.distance / 1000,     // Convert mm to meters
    stdDevMeters: r.distanceStdDev / 1000,
    success: r.success
  }));
}

// Trilateration: With distances to 3+ APs at known locations,
// calculate device position using least-squares multilateration.
// (See algorithm in Section 7 — Sensor Fusion)
```

**Real-world use:** Deploy 3+ 802.11mc-capable APs in a warehouse. Each AP's location is surveyed. Client measures distance to each AP → trilateration → 1-2m accuracy indoors. No GPS needed.

---

## 3. BLE Beacon Positioning — Micro-Location

**Accuracy:** 1-5 meters indoor.  
**Requires:** BLE beacons deployed in the environment, browser with Web Bluetooth API.

```javascript
/**
 * Scan for BLE beacons using Web Bluetooth API.
 * Chrome/Edge on desktop and Android. Not supported on iOS Safari.
 *
 * Beacons broadcast: UUID, Major, Minor, TX Power (at 1m reference distance)
 * Signal strength (RSSI) → estimated distance using path loss model.
 */
async function scanBLEBeacons() {
  if (!navigator.bluetooth) {
    throw new Error("Web Bluetooth not supported on this browser");
  }

  try {
    // Request device — user must select from browser dialog
    const device = await navigator.bluetooth.requestDevice({
      acceptAllDevices: true,
      optionalServices: []  // Beacons don't have GATT services
    });

    // For beacon scanning without pairing, use the experimental
    // navigator.bluetooth.requestLEScan() if available
    // As of 2026, this requires chrome://flags#enable-experimental-web-platform-features

    return device;
  } catch (e) {
    throw new Error(`BLE scan failed: ${e.message}`);
  }
}

/**
 * RSSI to distance estimation (log-distance path loss model).
 *
 * @param rssi - Received Signal Strength Indicator (dBm), e.g., -65
 * @param txPower - Calibrated RSSI at 1 meter (from beacon advertisement), e.g., -59
 * @param environmentFactor - 2.0 free space, 2.5-3.0 office, 3.5-4.0 industrial
 * @returns Estimated distance in meters
 */
function rssiToDistance(rssi, txPower, environmentFactor = 2.8) {
  if (rssi === 0) return -1; // Invalid RSSI

  const ratio = (txPower - rssi) / (10 * environmentFactor);
  return Math.pow(10, ratio);
}

// Example: RSSI = -72, txPower = -59, n = 2.8 (office)
// ratio = (-59 - (-72)) / 28 = 13/28 = 0.464
// distance = 10^0.464 ≈ 2.91 meters
```

**Beacon deployment pattern for a floor:**

```
 ┌──────────────────────────────────┐
 │  [B1]──────────────[B2]          │
 │   │                  │           │
 │   │     [USER]       │           │
 │   │                  │           │
 │  [B3]──────────────[B4]          │
 └──────────────────────────────────┘

4 beacons at surveyed positions.
User receives RSSI from each.
Trilateration → (x, y) on floor plan.
```

**Server-side beacon database:**

```sql
-- PostgreSQL/PostGIS table for beacon positions
CREATE TABLE beacons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    uuid TEXT NOT NULL,
    major INTEGER NOT NULL,
    minor INTEGER NOT NULL,
    tx_power INTEGER,                    -- Calibrated RSSI at 1m
    geom GEOMETRY(Point, 4326),          -- WGS84 position
    floor INTEGER,                       -- Building floor number
    building_id UUID REFERENCES buildings(id),
    installed_at TIMESTAMPTZ,
    last_calibrated TIMESTAMPTZ
);

CREATE INDEX idx_beacons_uuids ON beacons(uuid, major, minor);
CREATE INDEX idx_beacons_geom ON beacons USING GIST(geom);
```

---

## 4. Cell Tower Triangulation — Wide Area Fallback

**Accuracy:** 50m-5km depending on tower density.  
**How:** Browser reports nearby cell towers (MCC, MNC, LAC, Cell ID, signal strength). Server queries a cell tower database (Mozilla Location Service, OpenCelliD, commercial) for tower coordinates. Triangulate from multiple towers.

```javascript
/**
 * Cell tower information from Network Information API.
 * Limited browser support — Chrome on Android primarily.
 * Provides: MCC, MNC, LAC, CID, signal strength.
 */
async function getCellTowerInfo() {
  // @ts-ignore — Network Information API is experimental
  if (!navigator.connection) {
    return null;
  }

  // @ts-ignore
  const connection = navigator.connection;

  // This gives the serving cell only
  // For neighboring cells, you need a native app or Chrome extension
  return {
    effectiveType: connection.effectiveType,  // '4g', '3g', etc.
    downlink: connection.downlink,            // Mbps estimate
    rtt: connection.rtt,                      // ms estimate
    // MCC/MNC/CID not exposed via this API
    // Need Native Messaging or a native SDK wrapper
  };
}

/**
 * For full cell tower data, use a native Android WebView bridge.
 * Android TelephonyManager provides getAllCellInfo().
 *
 * Then send to server, query OpenCelliD or MLS for tower locations,
 * triangulate client position.
 */
// Android WebView JavaScript Interface (Kotlin/Java side):
// @JavascriptInterface
// fun getCellTowers(): String {
//     val tm = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
//     val cells = tm.allCellInfo
//     // Serialize to JSON, return to JavaScript
//     return Gson().toJson(cells.map { ... })
// }
```

**Server-side tower lookup + triangulation:**

```python
import requests
import math
from scipy.optimize import minimize

class CellTowerLocator:
    """
    Query tower coordinates and triangulate user position.
    Uses OpenCelliD or Mozilla Location Service (MLS).
    """

    MLS_API_URL = "https://location.services.mozilla.com/v1/geolocate?key="

    def __init__(self, api_key: str):
        self.api_key = api_key

    def geolocate_by_cell_towers(self, cell_towers: list[dict]) -> dict:
        """
        cell_towers: list of {radio, mcc, mnc, lac, cid, signalStrength}
        Returns: {lat, lon, accuracy}
        """
        payload = {
            "cellTowers": cell_towers,
            "fallbacks": {"ip": False}  # Don't fall back to IP — defeats the purpose
        }

        resp = requests.post(
            f"{self.MLS_API_URL}{self.api_key}",
            json=payload,
            timeout=10
        )
        resp.raise_for_status()
        data = resp.json()

        return {
            "latitude": data["location"]["lat"],
            "longitude": data["location"]["lng"],
            "accuracy": data.get("accuracy", 0),
            "source": "cell-tower-triangulation"
        }

    def triangulate_manual(self, towers: list[dict]) -> tuple[float, float]:
        """
        Manual multilateration from tower positions and signal strength.
        Uses least-squares optimization.
        """
        # Each tower: {lat, lon, signalStrength_dBm, txPower_dBm}
        def error_fn(point):
            lat, lon = point
            total_error = 0.0
            for tower in towers:
                dist_km = haversine(lat, lon, tower["lat"], tower["lon"])
                # Convert distance to expected signal strength
                # Free-space path loss: FSPL = 20*log10(d_km) + 20*log10(f_MHz) + 32.45
                # This is simplified — real path loss has environmental factors
                est_distance = rssi_to_distance(
                    tower["signalStrength_dBm"],
                    tower.get("txPower_dBm", -50)
                )
                total_error += (dist_km * 1000 - est_distance) ** 2
            return total_error

        # Initial guess: centroid of tower positions
        init_lat = sum(t["lat"] for t in towers) / len(towers)
        init_lon = sum(t["lon"] for t in towers) / len(towers)

        result = minimize(error_fn, [init_lat, init_lon], method="Nelder-Mead")
        return result.x[0], result.x[1]
```

---

## 5. Browser Fingerprinting + Historical Correlation

**How it works:** Even without explicit location permission, a browser leaks identifying information: WebGL renderer, canvas fingerprint, installed fonts, timezone, language, screen resolution, audio context fingerprint. This fingerprint is statistically unique. If the same fingerprint was ever seen at a known location (from a prior visit where the user granted location permission), you can correlate.

```javascript
/**
 * Generate a browser fingerprint for cross-session correlation.
 * This does NOT request location permission.
 * Combined with a server-side fingerprint→location database,
 * you can infer location of returning visitors.
 */
async function generateFingerprint() {
  const components = {
    // 1. Canvas fingerprint
    canvasHash: await getCanvasFingerprint(),

    // 2. WebGL fingerprint (GPU model)
    webglRenderer: getWebGLRenderer(),

    // 3. Audio context fingerprint
    audioHash: getAudioFingerprint(),

    // 4. Screen properties
    screen: `${screen.width}x${screen.height}x${screen.colorDepth}`,
    devicePixelRatio: window.devicePixelRatio,

    // 5. Timezone and locale
    timezone: Intl.DateTimeFormat().resolvedOptions().timeZone,
    language: navigator.language,

    // 6. Platform
    platform: navigator.platform,
    userAgent: navigator.userAgent,

    // 7. Hardware concurrency
    cores: navigator.hardwareConcurrency,

    // 8. Installed fonts (sample — full enumeration requires Flash or API)
    fonts: await detectFonts(["Arial", "Helvetica", "Times", "Courier",
      "Verdana", "Georgia", "Comic Sans MS", "Impact", "Monaco",
      "Consolas", "Ubuntu", "Roboto", "Open Sans", "Lato"]),

    // 9. Touch support
    touchPoints: navigator.maxTouchPoints,

    // 10. Do Not Track
    dnt: navigator.doNotTrack,
  };

  // Hash the entire fingerprint
  const fingerprint = await sha256(JSON.stringify(components));
  return { fingerprint, components };
}

function getCanvasFingerprint() {
  return new Promise((resolve) => {
    const canvas = document.createElement('canvas');
    canvas.width = 280;
    canvas.height = 60;
    const ctx = canvas.getContext('2d');

    // Draw text with subtle variations that render differently per GPU/driver
    ctx.textBaseline = "top";
    ctx.font = "14px Arial";
    ctx.fillStyle = "#f60";
    ctx.fillRect(125, 1, 62, 20);
    ctx.fillStyle = "#069";
    ctx.fillText("Browser Fingerprint Probe 🎯", 2, 15);
    ctx.fillStyle = "rgba(102, 204, 0, 0.7)";
    ctx.fillText("Browser Fingerprint Probe 🎯", 4, 17);

    canvas.toBlob((blob) => {
      const reader = new FileReader();
      reader.onload = () => resolve(reader.result);
      reader.readAsDataURL(blob);
    }, 'image/png');
  });
}

function getWebGLRenderer() {
  try {
    const canvas = document.createElement('canvas');
    const gl = canvas.getContext('webgl') || canvas.getContext('experimental-webgl');
    if (!gl) return null;
    const debugInfo = gl.getExtension('WEBGL_debug_renderer_info');
    if (!debugInfo) return null;
    return gl.getParameter(debugInfo.UNMASKED_RENDERER_WEBGL);
  } catch (e) {
    return null;
  }
}

function getAudioFingerprint() {
  return new Promise((resolve) => {
    try {
      const ctx = new (window.AudioContext || window.webkitAudioContext)();
      const oscillator = ctx.createOscillator();
      const analyser = ctx.createAnalyser();
      const gain = ctx.createGain();
      const scriptProcessor = ctx.createScriptProcessor(4096, 1, 1);

      oscillator.type = "triangle";
      oscillator.frequency.value = 10000;

      gain.gain.value = 0; // Silent — user won't hear this

      oscillator.connect(analyser);
      analyser.connect(scriptProcessor);
      scriptProcessor.connect(gain);
      gain.connect(ctx.destination);

      oscillator.start(0);

      scriptProcessor.onaudioprocess = (event) => {
        const output = event.outputBuffer.getChannelData(0);
        const hash = output.slice(0, 30).reduce((acc, v) => acc + v, 0);
        oscillator.stop();
        scriptProcessor.disconnect();
        analyser.disconnect();
        gain.disconnect();
        ctx.close();
        resolve(hash.toString());
      };
    } catch (e) {
      resolve(null);
    }
  });
}

async function sha256(message) {
  const msgBuffer = new TextEncoder().encode(message);
  const hashBuffer = await crypto.subtle.digest('SHA-256', msgBuffer);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map(b => b.toString(16).padStart(2, '0')).join('');
}
```

**Server-side correlation:**

```python
# When user grants location permission, store: fingerprint -> (lat, lon, accuracy, timestamp)
# When user visits without granting location, look up fingerprint

class FingerprintLocationDB:
    """Maps browser fingerprints to their last known locations."""

    def __init__(self, redis_client, pg_pool):
        self.redis = redis_client          # Fast cache
        self.pg = pg_pool                  # Persistent store

    async def store_location(self, fingerprint: str, lat: float, lon: float, accuracy: float):
        """Store a fingerprint→location mapping when user grants permission."""
        now = datetime.now(timezone.utc)

        # Cache in Redis (1 hour TTL for fast lookups)
        await self.redis.setex(
            f"fp:loc:{fingerprint}",
            3600,
            json.dumps({"lat": lat, "lon": lon, "accuracy": accuracy, "ts": now.isoformat()})
        )

        # Persist in PostgreSQL for long-term correlation
        async with self.pg.acquire() as conn:
            await conn.execute("""
                INSERT INTO fingerprint_locations (fingerprint, geom, accuracy, recorded_at)
                VALUES ($1, ST_SetSRID(ST_MakePoint($2, $3), 4326), $4, $5)
                ON CONFLICT (fingerprint) DO UPDATE SET
                    geom = EXCLUDED.geom,
                    accuracy = EXCLUDED.accuracy,
                    recorded_at = EXCLUDED.recorded_at
            """, fingerprint, lon, lat, accuracy, now)

    async def get_last_location(self, fingerprint: str) -> dict | None:
        """Retrieve last known location for a fingerprint."""
        # Check Redis first
        cached = await self.redis.get(f"fp:loc:{fingerprint}")
        if cached:
            return json.loads(cached)

        # Fall back to PostgreSQL
        async with self.pg.acquire() as conn:
            row = await conn.fetchrow("""
                SELECT ST_Y(geom) AS lat, ST_X(geom) AS lon, accuracy, recorded_at
                FROM fingerprint_locations
                WHERE fingerprint = $1
                ORDER BY recorded_at DESC
                LIMIT 1
            """, fingerprint)

            if row:
                result = {
                    "lat": row["lat"],
                    "lon": row["lon"],
                    "accuracy": row["accuracy"],
                    "ts": row["recorded_at"].isoformat()
                }
                # Re-cache in Redis
                await self.redis.setex(f"fp:loc:{fingerprint}", 3600, json.dumps(result))
                return result

        return None
```

**Accuracy:** As good as the user's last GPS-enabled visit. If they granted location last week at the office, you know their office location to 10m. This session they didn't grant permission, but the fingerprint matches → you know where they are (or at least where they've been).

---

## 6. Passive Network Timing Side-Channels

**Concept:** Even without location permission, network timing can reveal geographic distance. The Round-Trip Time (RTT) from client to server is bounded by the speed of light in fiber (~5µs/km). By measuring RTT from the client to multiple geographically distributed edge servers, you can triangulate the client's approximate region.

```javascript
/**
 * Measure RTT to multiple edge servers.
 * Client sends a request; server echoes back.
 * RTT / 2 ≈ one-way latency ≈ light-speed distance.
 *
 * Requires: Server endpoints deployed in known locations.
 * CDN edges (Cloudflare, Fastly, CloudFront) work well.
 */
async function measureRTTToEdges(edgeUrls) {
  const results = [];

  for (const edge of edgeUrls) {
    const start = performance.now();

    try {
      // Use a lightweight endpoint — HEAD request, no body
      await fetch(`${edge}/ping`, {
        method: 'HEAD',
        cache: 'no-store',
        mode: 'cors'  // CORS might block — use no-cors or same-origin
      });

      const rtt = performance.now() - start;
      results.push({
        edge: edge,
        rttMs: rtt,
        estimatedDistanceKm: rtt * 100  // Rough: 1ms RTT ≈ 100km in fiber
      });
    } catch (e) {
      // Edge unreachable — infinite RTT
      results.push({ edge: edge, rttMs: Infinity, estimatedDistanceKm: Infinity });
    }
  }

  return results;
}

/**
 * Triangulate from RTT measurements.
 *
 * Server locations:
 *   Singapore:  1.35°N, 103.82°E
 *   Tokyo:     35.68°N, 139.76°E
 *   Frankfurt: 50.11°N,   8.68°E
 *   Virginia:  38.95°N,  77.45°W
 *
 * For each server, the client lies on a circle of radius RTT_to_distance(server).
 * Intersection of 3+ circles ≈ client location.
 */
const EDGE_SERVERS = [
  { name: "Singapore",  lat: 1.35,   lon: 103.82 },
  { name: "Tokyo",      lat: 35.68,  lon: 139.76 },
  { name: "Frankfurt",  lat: 50.11,  lon: 8.68   },
  { name: "Virginia",   lat: 38.95,  lon: -77.45 },
  { name: "São Paulo",  lat: -23.55, lon: -46.63 },
];

// Convert RTT measurements to estimated location
function triangulateFromRTT(measurements) {
  // Each measurement: {edge, rttMs}
  // Convert RTT to distance (km): distance = rttMs * 100 (approximation)

  // Simple approach: weighted centroid
  let weightedLat = 0, weightedLon = 0, totalWeight = 0;

  for (const m of measurements) {
    const server = EDGE_SERVERS.find(s => m.edge.includes(s.name));
    if (!server || !isFinite(m.rttMs)) continue;

    // Closer servers get higher weight
    const weight = 1 / Math.max(m.rttMs, 1);  // 1/RTT weighting
    weightedLat += server.lat * weight;
    weightedLon += server.lon * weight;
    totalWeight += weight;
  }

  if (totalWeight === 0) return null;

  return {
    lat: weightedLat / totalWeight,
    lon: weightedLon / totalWeight,
    confidence: Math.min(totalWeight / 10, 1.0)  // Normalize
  };
}
```

**Limitations:**
- Network congestion, routing asymmetry, and bufferbloat add noise.
- VPNs and proxies add their own latency layer.
- Accuracy is regional (~100-500km) — not building-level.
- Best combined with other methods as a sanity check.

---

## 7. Sensor Fusion — Combining All Sources

**Principle:** No single method is always available or accurate. Fuse GPS, WiFi, BLE, cell towers, fingerprint correlation, and RTT into a single position estimate using a Kalman filter or weighted least squares.

```python
import numpy as np
from typing import Optional
from dataclasses import dataclass

@dataclass
class PositionEstimate:
    lat: float
    lon: float
    accuracy: float  # Standard deviation in meters
    source: str

class SensorFusion:
    """
    Combine multiple position estimates into one optimal estimate.
    Uses inverse-variance weighting (simpler than Kalman — works for static fusion).
    """

    def fuse(self, estimates: list[PositionEstimate]) -> Optional[PositionEstimate]:
        """
        Weight each estimate by 1/variance (1/accuracy²).
        More accurate sources dominate.
        """
        if not estimates:
            return None

        # Convert to ECEF (Earth-Centered Earth-Fixed) for proper 3D averaging
        ecef_points = []
        weights = []

        for est in estimates:
            if est.accuracy <= 0:
                continue
            x, y, z = self._latlon_to_ecef(est.lat, est.lon)
            ecef_points.append((x, y, z))
            # Inverse variance weighting: weight = 1 / accuracy²
            weights.append(1.0 / (est.accuracy ** 2))

        if not ecef_points:
            return None

        total_weight = sum(weights)

        # Weighted average in ECEF
        avg_x = sum(p[0] * w for p, w in zip(ecef_points, weights)) / total_weight
        avg_y = sum(p[1] * w for p, w in zip(ecef_points, weights)) / total_weight
        avg_z = sum(p[2] * w for p, w in zip(ecef_points, weights)) / total_weight

        # Convert back to lat/lon
        lat, lon = self._ecef_to_latlon(avg_x, avg_y, avg_z)

        # Combined accuracy: sqrt(1 / total_weight)
        combined_accuracy = np.sqrt(1.0 / total_weight)

        return PositionEstimate(
            lat=lat,
            lon=lon,
            accuracy=combined_accuracy,
            source="fused"
        )

    def _latlon_to_ecef(self, lat: float, lon: float):
        """Convert WGS84 lat/lon to ECEF coordinates."""
        a = 6378137.0  # WGS84 semi-major axis
        f = 1 / 298.257223563
        e2 = 2 * f - f * f

        lat_rad = np.radians(lat)
        lon_rad = np.radians(lon)

        n = a / np.sqrt(1 - e2 * np.sin(lat_rad)**2)

        x = n * np.cos(lat_rad) * np.cos(lon_rad)
        y = n * np.cos(lat_rad) * np.sin(lon_rad)
        z = (1 - e2) * n * np.sin(lat_rad)

        return x, y, z

    def _ecef_to_latlon(self, x: float, y: float, z: float):
        """Convert ECEF to WGS84 lat/lon."""
        a = 6378137.0
        f = 1 / 298.257223563
        e2 = 2 * f - f * f

        lon = np.arctan2(y, x)

        p = np.sqrt(x**2 + y**2)
        lat = np.arctan2(z, p * (1 - e2))

        # Iterative refinement for latitude
        for _ in range(5):
            n = a / np.sqrt(1 - e2 * np.sin(lat)**2)
            lat = np.arctan2(z + e2 * n * np.sin(lat), p)

        return np.degrees(lat), np.degrees(lon)
```

**Frontend fusion orchestrator:**

```javascript
/**
 * Collect all available position estimates and send to server for fusion.
 */
async function collectAllPositionSources() {
  const sources = [];

  // 1. Try GPS/WiFi via Geolocation API (requires permission)
  try {
    const gps = await getHighAccuracyPosition();
    sources.push({
      lat: gps.latitude,
      lon: gps.longitude,
      accuracy: gps.accuracy,
      source: "gnss-wifi"
    });
  } catch (e) {
    console.log("GPS/WiFi unavailable:", e.message);
  }

  // 2. Try fingerprint-based location (no permission needed)
  try {
    const fp = await generateFingerprint();
    const fpLocation = await fetch(`/api/location/fingerprint/${fp.fingerprint}`)
      .then(r => r.json());

    if (fpLocation && fpLocation.found) {
      sources.push({
        lat: fpLocation.lat,
        lon: fpLocation.lon,
        accuracy: fpLocation.accuracy || 500, // Low confidence for historical
        source: "fingerprint-correlation"
      });
    }
  } catch (e) {
    console.log("Fingerprint lookup failed:", e.message);
  }

  // 3. Try RTT triangulation (no permission needed)
  try {
    const rttMeasurements = await measureRTTToEdges([
      "https://sg.edge.example.com",
      "https://jp.edge.example.com",
      "https://de.edge.example.com",
      "https://us.edge.example.com",
    ]);

    // Send RTT data to server for triangulation
    const rttLocation = await fetch("/api/location/triangulate-rtt", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ measurements: rttMeasurements })
    }).then(r => r.json());

    if (rttLocation) {
      sources.push({
        lat: rttLocation.lat,
        lon: rttLocation.lon,
        accuracy: rttLocation.accuracy || 50000, // Low confidence
        source: "rtt-triangulation"
      });
    }
  } catch (e) {
    console.log("RTT triangulation failed:", e.message);
  }

  // 4. Send all sources to server for sensor fusion
  const fused = await fetch("/api/location/fuse", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ estimates: sources })
  }).then(r => r.json());

  return {
    fused: fused,
    sources: sources,
    timestamp: Date.now()
  };
}
```

---

## 8. Passive Subscriber Data — Beyond the Browser

For applications where you control the infrastructure (mobile network operator, enterprise WiFi), you can obtain location without any browser involvement:

| Data Source | How to Access | Accuracy | Legal Framework |
|-------------|---------------|----------|-----------------|
| **Mobile Core Network (5G/4G)** | AMF/LMF location services via NEF | 10-50m (5G), 50-500m (4G) | Lawful intercept / subscriber consent |
| **WiFi Controller** | Cisco/Aruba/Ubiquiti API | 5-15m | Enterprise policy |
| **Radius/Diameter logs** | RADIUS accounting with Called-Station-Id | AP-level (10-30m) | Enterprise policy |
| **DHCP lease + switch port mapping** | Network management system | Switch/AP level | Enterprise policy |
| **MDM/EMM platform** | Mobile Device Management API | GPS-level (3-10m) | Employee consent / BYOD policy |

---

---

## 📊 Decision Matrix — Which Method When

```
                    ┌─────────────────────────────────────────────┐
                    │           DOES USER GRANT PERMISSION?         │
                    └──────────────┬──────────────────┬────────────┘
                                   │ YES              │ NO
                    ┌──────────────▼──────┐   ┌───────▼──────────────┐
                    │   DEVICE HAS GPS?    │   │  FINGERPRINT IN DB?  │
                    └──┬──────────────┬────┘   └──┬──────────────┬────┘
                       │ YES          │ NO        │ YES          │ NO
                       │              │           │              │
                 ┌─────▼─────┐  ┌────▼─────┐ ┌───▼────┐  ┌──────▼──────┐
                 │ GPS 3-10m │  │ INDOORS? │ │ FP CORR│  │ RTT REGION  │
                 │ CONTINUOUS│  └──┬────┬──┘ │ 10-500m│  │ 50-500km    │
                 │ TRACKING  │  YES│   │NO   └────────┘  └─────────────┘
                 └───────────┘     │   │
                    ┌──────────────▼┐  └──────────────┐
                    │ WiFi/BLE 1-25m│                 │
                    │ RTT 1-2m      │          ┌──────▼──────┐
                    │ BEACONS 1-5m  │          │ CELL TOWERS │
                    └───────────────┘          │ 50m-5km     │
                                               └─────────────┘
```

---

---

## 🔗 Related Infrastructure

| Component | Purpose |
|-----------|---------|
| **PostGIS database** | Store all location pings, beacon positions, tower DB |
| **Redis** | Real-time location cache, fingerprint→location mapping |
| **MQTT broker** | Real-time location streaming for live tracking dashboards |
| **GeoServer / MapServer** | Serve WMS/WFS layers for WebGIS frontend |
| **Leaflet / OpenLayers / MapLibre** | Browser-side map rendering |
| **TimescaleDB** | Time-series location data for historical tracks |
| **Grafana + Geomap panel** | Operations dashboard for live location monitoring |

---

*WebGIS Precision Tracking · GPS · WiFi RTT · BLE Beacons · Cell Triangulation · Fingerprint Correlation · Sensor Fusion*

---

## References

1. W3C Geolocation API Specification — https://www.w3.org/TR/geolocation-API/
2. Google Geolocation API Documentation — https://developers.google.com/maps/documentation/geolocation/overview
3. IEEE 802.11mc (FTM - Fine Timing Measurement) — https://standards.ieee.org/ieee/802.11/4656/
4. Bluetooth Core Specification (BLE Direction Finding) — https://www.bluetooth.com/specifications/specs/
5. Mozilla Developer Network — Geolocation.getCurrentPosition() — https://developer.mozilla.org/en-US/docs/Web/API/Geolocation/getCurrentPosition
6. OpenCelliD — Open Database of Cell Towers — https://opencellid.org/
7. Google Material Design — Request Location Permission — https://material.io/design/communication/permissions
8. RFC 791 (Internet Protocol) — IP geolocation limitations — https://datatracker.ietf.org/doc/html/rfc791
9. RFC 7969 (CGNAT Operational Considerations) — https://datatracker.ietf.org/doc/html/rfc7969
10. PostGIS Documentation — Geometry/Geography types — https://postgis.net/docs/
11. TimescaleDB Schema for Location Time-Series — https://docs.timescale.com/timescaledb/latest/
12. MapLibre GL JS — Open-source Map Renderer — https://maplibre.org/

## Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[cgnat-attribution-deepdive]] | CGNAT dari sisi jaringan: identifikasi pelaku via log ISP, regulasi logging — catatan ini dari sisi client-side tracking |
| [[browser-fingerprinting-defense]] | Browser fingerprinting sebagai teknik tracking — di sini dipakai untuk historical location correlation |
| [[attack-browser-fingerprinting-defense]] | Attacker perspective: fingerprint dapat dieksploitasi untuk tracking presisi |
| [[networking-fundamentals-tcpip-bgp]] | Dasar IP geolocation dan mengapa CGNAT menghancurkannya |
| [[hierarchy-infrastructure-evolution]] | Infrastruktur GeoServer/PostGIS/MQTT dalam arsitektur WebGIS |
| [[anti-tracking-browser-extensions]] | Perspektif defender: bagaimana user memblokir teknik tracking di dokumen ini |
| [[java-security-22-tricks]] | Berbagi konsep fingerprinting: header/TLS fingerprint dipakai juga di Java security |
