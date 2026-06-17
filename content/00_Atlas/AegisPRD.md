# 📋 AEGIS v1.0 — Product Requirement Document

## Network Defense Core for Linux Homelab & Server

---

## 1. Executive Summary

**Product:** Aegis — Real-time Network Defense Platform  
**Version:** 1.0  
**Target:** Linux servers & homelabs (single server)  
**Philosophy:** "Defense-first, modular, lightweight, no browser bloat"

Aegis adalah platform defense yang menggabungkan eBPF kernel-level packet filtering, WAF reverse proxy, dan real-time monitoring dalam satu ekosistem. Dibangun dengan Rust (performance + safety) dan Go (orchestration), dengan Tauri sebagai desktop UI wrapper.

---

## 2. Target User

| Persona                | Description                                             | Pain Point                          |
| ---------------------- | ------------------------------------------------------- | ----------------------------------- |
| **Homelab Enthusiast** | Run services di VPS/homelab (Nextcloud, Jellyfin, blog) | Ingin proteksi tanpa setup kompleks |
| **Small Server Admin** | Manage 1-5 Linux servers                                | Butuh visibility + basic protection |
| **Security Learner**   | Belajar cybersecurity hands-on                          | Butuh platform untuk eksperimen     |
| **DevOps Junior**      | Deploy app ke cloud VPS                                 | Butuh WAF + monitoring sederhana    |

**NOT Target:** Enterprise (100+ servers), Windows/macOS users, compliance-heavy orgs

---

## 3. Core Value Proposition

> **"CrowdStrike untuk homelab Anda — tapi open source, lightweight, dan tanpa cloud dependency."**

| Feature   | Aegis              | CrowdStrike | Cloudflare    |
| --------- | ------------------ | ----------- | ------------- |
| Cost      | Free (open source) | $$$$        | $$-$$$        |
| On-prem   | ✅ Native          | ⚠️ Limited  | ❌ Cloud-only |
| eBPF      | ✅ Native Rust     | ✅ (closed) | ❌            |
| WAF       | ✅ Built-in        | ❌ Separate | ✅            |
| Dashboard | ✅ Tauri desktop   | Web only    | Web only      |
| Offline   | ✅ Full            | ⚠️ Partial  | ❌            |

### 3.1 Cybersecurity Domain Positioning

Aegis sits at the intersection of Network and Application Security within the Blue Team (Defensive Security) domain, with future plans to expand into Endpoint and Data Security.

```
IT (Information Technology)
└── Cybersecurity
    └── Blue Team (Defensive)
        ├── Network Security ⭐ Aegis v1.0
        │   ├── Firewall (eBPF XDP/TC) ✅
        │   ├── IDS/IPS (WAF rules) ✅
        │   ├── DDoS Protection ✅
        │   └── VPN (WireGuard v1.5) 🔄
        │
        ├── Application Security ⭐ Aegis v1.0
        │   ├── WAF (Reverse Proxy) ✅
        │   ├── Bot Detection ✅
        │   └── API Security 🔄
        │
        ├── Endpoint Security ⭐ Aegis v2.0
        │   ├── EDR (process monitoring) 🔄
        │   ├── FIM (file integrity) 🔄
        │   └── Host Firewall ✅ (already implemented)
        │
        └── Data Security ⭐ Aegis v3.0+
            ├── Encryption 🔄
            ├── DLP 🔄
            └── Backup 🔄

SOC Integration (Aegis as data source)
├── SIEM feed (syslog/CEF) 🔄
├── Alert generation ✅
├── Dashboard & reporting ✅
└── MITRE ATT&CK mapping 🔄
```

---

## 4. Module Architecture (v1.0)

```
┌─────────────────────────────────────────────────────────────┐
│                    AEGIS v1.0 — NETWORK DEFENSE CORE       │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  UI LAYER — Tauri Desktop App (Rust + WebView)       │  │
│  │  • Single binary, no browser, no internet required   │  │
│  │  • System tray icon, auto-start on boot              │  │
│  │  • Dark mode default, responsive layout              │  │
│  │  • xterm.js for live log streaming                   │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  API LAYER — Go (Gin) + SQLite (rusqlite)          │  │
│  │  • REST API untuk UI communication                   │  │
│  │  • WebSocket untuk real-time events                  │  │
│  │  • Config management (TOML)                          │  │
│  │  • SQLite: events, blocks, rules, stats              │  │
│  └─────────────────────────────────────────────────────┘  │
│                          │                                  │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  SECURITY MODULES (Modular, separate processes)      │  │
│  │                                                      │  │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  │  │
│  │  │  eBPF XDP   │  │  WAF Engine │  │  Tunnel     │  │  │
│  │  │  Firewall   │  │  (Rust)     │  │  Manager    │  │  │
│  │  │  (Rust+Aya) │  │  Reverse    │  │  (Rust)     │  │  │
│  │  │             │  │  Proxy +    │  │  cloudflare │  │  │
│  │  │ • Packet    │  │  Custom     │  │  tunnel     │  │  │
│  │  │   filter    │  │  Rules      │  │             │  │  │
│  │  │ • Rate      │  │             │  │ • Hide      │  │  │
│  │  │   limit     │  │ • SQLi/XSS  │  │   origin IP │  │  │
│  │  │ • GeoIP     │  │   detection │  │ • DDoS      │  │  │
│  │  │ • Port scan │  │ • Rate      │  │   protect   │  │  │
│  │  │   detect    │  │   limiting  │  │ • Config    │  │  │
│  │  │ • Auto-     │  │ • Virtual   │  │   sync      │  │  │
│  │  │   restart   │  │   Host      │  │             │  │  │
│  │  │   service   │  │ • IP Rep    │  │             │  │  │
│  │  └─────────────┘  └─────────────┘  └─────────────┘  │  │
│  │                                                      │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐  │
│  │  SHARED SERVICES                                     │  │
│  │  • SQLite Database (/var/lib/aegis/aegis.db)       │  │
│  │  • TOML Config (/etc/aegis/config.toml)             │  │
│  │  • Log Directory (/var/log/aegis/)                  │  │
│  │  • PID Files (/var/run/aegis/*.pid)                 │  │
│  └─────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## 5. Module Specifications

### 5.1 eBPF XDP Firewall (aegis-xdp)

**Language:** Rust + Aya (eBPF framework)  
**Type:** Kernel module (requires root, CAP_BPF)  
**Interface:** Unix socket / gRPC ke Go API

#### Features

| Feature                  | Priority | Description                                            |
| ------------------------ | -------- | ------------------------------------------------------ |
| **Packet Filter**        | P0       | Block/allow berdasarkan: src IP, dst port, protocol    |
| **Rate Limiting**        | P0       | Per-IP: X packets/sec, burst Y. Block jika exceed.     |
| **GeoIP Block**          | P0       | Block/allow berdasarkan country code (MaxMind DB)      |
| **Port Scan Detection**  | P0       | Detect SYN flood, port sweep, vertical/horizontal scan |
| **Connection Tracking**  | P0       | Track state: NEW, ESTABLISHED, CLOSED                  |
| **Auto-restart Service** | P0       | Watchdog: monitor WAF process, restart if down         |
| **DNS Tunnel Detection** | P1       | Heuristic: query length, frequency, entropy            |
| **DDoS Mitigation**      | P1       | SYN cookie, rate limit per IP subnet                   |
| **Logging**              | P0       | SQLite + ring buffer, export ke Go API                 |

#### eBPF Program Types

```rust
// XDP program: runs at NIC driver level, before kernel network stack
#[xdp]
pub fn aegis_xdp_filter(ctx: XdpContext) -> u32 {
    // 1. Parse ethernet header
    // 2. Parse IP header
    // 3. Check against blocklist (BPF map)
    // 4. Check rate limit (BPF map + time window)
    // 5. Check GeoIP (userspace lookup via perf event)
    // 6. Return: XDP_DROP | XDP_PASS | XDP_REDIRECT
}

// Tracepoint: monitor process execution (for watchdog)
#[tracepoint]
pub fn aegis_trace_execve(ctx: TracePointContext) {
    // Log execve() calls untuk detect WAF crash/restart
}
```

#### Data Flow

```
NIC Driver → [XDP Program] → Decision (DROP/PASS) → Kernel Network Stack
                │
                ▼
         BPF Maps (blocklist, rate_limit, stats)
                │
                ▼
         Userspace (Rust) → SQLite → Go API → Tauri UI
```

#### Acceptance Criteria

- [ ] Drop packet dalam < 1μs (XDP guarantee)
- [ ] Rate limit: 10,000 packets/sec per core
- [ ] GeoIP lookup: < 100μs per packet
- [ ] Auto-restart WAF: < 5 detik dari crash detect
- [ ] Zero packet loss saat eBPF program reload
- [ ] Memory footprint: < 50MB kernel + userspace

---

### 5.2 WAF Engine (aegis-waf)

**Language:** Rust (full rewrite dari Python)  
**Type:** Standalone binary + library  
**Interface:** HTTP reverse proxy + gRPC ke Go API

#### Features

| Feature                      | Priority | Description                                       |
| ---------------------------- | -------- | ------------------------------------------------- |
| **Reverse Proxy**            | P0       | Forward ke backend: HTTP/HTTPS, WebSocket support |
| **Virtual Host**             | P0       | Route berdasarkan Host header + SNI               |
| **Custom Rules**             | P0       | Regex-based: SQLi, XSS, LFI, RCE, SSRF            |
| **Rate Limiting**            | P0       | Per-IP, per-path, per-virtual-host                |
| **IP Reputation**            | P0       | Sync blocklist dengan eBPF firewall               |
| **Request/Response Logging** | P0       | Full HTTP log ke SQLite                           |
| **ModSecurity CRS**          | P1       | Optional: load CRS rules                          |
| **Bot Detection**            | P2       | Challenge-response untuk suspicious UA            |
| **Caching**                  | P2       | Static asset cache dengan TTL                     |

#### Rule Engine

```rust
// Rule structure
pub struct WafRule {
    pub id: String,
    pub name: String,
    pub phase: RulePhase,      // RequestHeaders | RequestBody | Response
    pub condition: RuleCondition, // Regex | Contains | Equals | IPRange
    pub action: RuleAction,      // Block | Allow | Log | RateLimit
    pub severity: Severity,     // Critical | High | Medium | Low
    pub enabled: bool,
}

// Example rules (built-in)
const DEFAULT_RULES: &[WafRule] = &[
    WafRule {
        id: "SQLI-001",
        name: "SQL Injection - Union Select",
        phase: RulePhase::RequestBody,
        condition: RuleCondition::Regex(
            r"(?i)(union\\s+select|insert\\s+into|delete\\s+from|drop\\s+table)"
        ),
        action: RuleAction::Block,
        severity: Severity::Critical,
        enabled: true,
    },
    WafRule {
        id: "XSS-001",
        name: "Cross-Site Scripting - Script Tag",
        phase: RulePhase::RequestBody,
        condition: RuleCondition::Regex(
            r"(?i)<script[^>]*>[\\s\\S]*?</script>"
        ),
        action: RuleAction::Block,
        severity: Severity::High,
        enabled: true,
    },
    // ... more rules
];
```

#### Virtual Host Configuration

```toml
# /etc/aegis/waf/vhosts.d/blog.toml
[virtual_host]
server_name = ["blog.example.com", "www.blog.example.com"]
listen = "0.0.0.0:443"
tls_cert = "/etc/aegis/certs/blog.crt"
tls_key = "/etc/aegis/certs/blog.key"

[backend]
upstream = "http://127.0.0.1:3000"
timeout = 30

[rules]
enabled = ["SQLI-*", "XSS-*", "LFI-*"]
custom_rules = [
    { id = "CUSTOM-001", regex = "(?i)admin_panel", action = "block" }
]

[rate_limit]
requests_per_minute = 100
burst = 20
block_duration = 300
```

#### Acceptance Criteria

- [ ] Handle 10,000 req/sec pada single core
- [ ] Latency tambahan: < 1ms untuk request yang di-allow
- [ ] Virtual Host: support 100+ vhosts tanpa performance drop
- [ ] Rule update: hot reload tanpa restart
- [ ] TLS termination: support TLS 1.3, OCSP stapling
- [ ] WebSocket: full duplex proxy tanpa buffering issue

---

### 5.3 Tunnel Manager (aegis-tunnel)

**Language:** Rust  
**Type:** Standalone binary  
**Interface:** gRPC ke Go API

#### Features

| Feature                  | Priority | Description                              |
| ------------------------ | -------- | ---------------------------------------- |
| **Cloudflare Tunnel**    | P0       | cloudflared integration, config sync     |
| **Tunnel Status**        | P0       | Health check, auto-reconnect             |
| **Origin IP Protection** | P0       | Block direct IP access (only via tunnel) |
| **Multiple Tunnels**     | P1       | Support multiple tunnel per domain       |
| **Metrics**              | P1       | Bandwidth, latency, error rate           |

#### Cloudflare Tunnel Integration

```rust
// Spawn cloudflared sebagai child process
// Monitor via stdout/stderr + health check HTTP endpoint

pub struct TunnelManager {
    config: TunnelConfig,
    process: Option<Child>,
    health_check_url: String,
}

impl TunnelManager {
    pub async fn start(&mut self) -> Result<(), TunnelError> {
        // 1. Validate config (token, hostname)
        // 2. Spawn cloudflared process
        // 3. Wait for "Connected" in stdout
        // 4. Start health check loop (every 30s)
        // 5. Auto-reconnect on failure
    }

    pub fn get_status(&self) -> TunnelStatus {
        // Healthy | Connecting | Error | Disabled
    }
}
```

#### Acceptance Criteria

- [ ] Tunnel establish: < 30 detik dari start
- [ ] Auto-reconnect: < 10 detik dari disconnect
- [ ] Origin protection: block 100% direct IP access
- [ ] Zero config drift: sync dengan Aegis config

---

### 5.4 Dashboard & UI (aegis-ui)

**Language:** TypeScript + React + Tauri  
**Type:** Desktop app (single binary)  
**Interface:** Tauri IPC → Go API

#### Pages

| Page          | Description                                               |
| ------------- | --------------------------------------------------------- |
| **Dashboard** | Overview: blocked today, active connections, top threats  |
| **Firewall**  | eBPF rules, blocklist, rate limit config, live packet log |
| **WAF**       | Virtual hosts, rules editor, request log, block stats     |
| **Tunnel**    | Tunnel status, config, bandwidth graph                    |
| **Logs**      | Searchable event log, filter by time/type/severity        |
| **Settings**  | Config editor, backup/restore, update check               |

#### UI Mockup (Text)

```
┌─────────────────────────────────────────────────────────────┐
│  🛡️ AEGIS                              [🔴 Stop] [⚙️ Settings]│
├──────────┬──────────────────────────────────────────────────┤
│ Dashboard│  ┌─────────────┐  ┌─────────────┐  ┌──────────┐ │
│ Firewall │  │  Blocked   │  │  Active     │  │  Threats │ │
│ WAF      │  │  Today     │  │  Conn       │  │  Level   │ │
│ Tunnel   │  │            │  │             │  │          │ │
│ Logs     │  │  1,247     │  │  42         │  │  Medium  │ │
│ Settings │  └─────────────┘  └─────────────┘  └──────────┘ │
│          │                                                   │
│          │  ┌─────────────────────────────────────────────┐  │
│          │  │  LIVE TRAFFIC                               │  │
│          │  │  14:32:01  DROP  192.168.1.100 → :22  SSH   │  │
│          │  │  14:32:05  PASS  10.0.0.5 → :443  HTTPS    │  │
│          │  │  14:32:08  BLOCK 45.142.214.58 → :80  SQLi │  │
│          │  │  14:32:12  DROP  185.220.101.0 → :22  Scan   │  │
│          │  └─────────────────────────────────────────────┘  │
│          │                                                   │
│          │  ┌─────────────────────────────────────────────┐  │
│          │  │  TOP BLOCKED IPs                            │  │
│          │  │  1. 185.220.101.0  (Russia)  342 blocks    │  │
│          │  │  2. 45.142.214.58  (China)   128 blocks    │  │
│          │  │  3. 192.168.1.100 (Local)    45 blocks     │  │
│          │  └─────────────────────────────────────────────┘  │
└──────────┴──────────────────────────────────────────────────┘
```

#### Acceptance Criteria

- [ ] Startup: < 3 detik
- [ ] Memory: < 100MB
- [ ] Real-time update: < 500ms latency dari event ke UI
- [ ] Offline: full functionality tanpa internet
- [ ] Responsive: 1024x768 minimum resolution

---

## 6. API Layer (aegis-api)

**Language:** Go (Gin framework)  
**Type:** Standalone binary  
**Database:** SQLite (rusqlite via CGO)

### Endpoints

```
GET  /api/v1/status              → System status, all modules
GET  /api/v1/firewall/rules      → List eBPF rules
POST /api/v1/firewall/rules      → Add new rule
DELETE /api/v1/firewall/rules/:id → Remove rule
GET  /api/v1/firewall/blocks     → Blocked IPs with stats
GET  /api/v1/firewall/live       → WebSocket: live packet stream

GET  /api/v1/waf/vhosts          → List virtual hosts
POST /api/v1/waf/vhosts          → Add virtual host
GET  /api/v1/waf/rules           → List WAF rules
POST /api/v1/waf/rules           → Add custom rule
GET  /api/v1/waf/logs            → WAF request/response logs

GET  /api/v1/tunnel/status       → Tunnel health status
POST /api/v1/tunnel/start        → Start tunnel
POST /api/v1/tunnel/stop         → Stop tunnel

GET  /api/v1/logs                → Query logs (filter, pagination)
GET  /api/v1/logs/export         → Export to CSV/JSON

GET  /api/v1/config              → Current config
PUT  /api/v1/config              → Update config (hot reload)
POST /api/v1/config/backup       → Backup config + DB
POST /api/v1/config/restore      → Restore from backup
```

### WebSocket Events

```json
// firewall.packet
{
  "timestamp": "2026-06-16T14:32:01Z",
  "action": "DROP",
  "src_ip": "185.220.101.0",
  "dst_port": 22,
  "protocol": "TCP",
  "reason": "GeoIP: Russia",
  "country": "RU"
}

// waf.block
{
  "timestamp": "2026-06-16T14:32:08Z",
  "action": "BLOCK",
  "src_ip": "45.142.214.58",
  "host": "blog.example.com",
  "path": "/wp-admin/admin-ajax.php",
  "rule_id": "SQLI-001",
  "rule_name": "SQL Injection - Union Select",
  "severity": "Critical"
}

// tunnel.status
{
  "tunnel_id": "cf-blog",
  "status": "connected",
  "uptime": 3600,
  "bandwidth_in": 1024000,
  "bandwidth_out": 512000
}
```

---

## 7. Configuration Schema

### Main Config: `/etc/aegis/config.toml`

```toml
[aegis]
version = "1.0.0"
log_level = "info"          # debug | info | warn | error
log_dir = "/var/log/aegis"
data_dir = "/var/lib/aegis"

[api]
bind = "127.0.0.1:8080"     # Internal API, UI connects here
websocket = true

[firewall]
enabled = true
interface = "eth0"          # NIC untuk XDP
xdp_mode = "native"         # native | skb | offload
blocklist_ttl = 86400       # 24 jam auto-expire
rate_limit_default = 100    # packets/sec
geoip_db = "/var/lib/aegis/GeoLite2-Country.mmdb"

[firewall.dns_tunnel]
enabled = true
max_query_length = 100      # karakter
max_queries_per_minute = 60
entropy_threshold = 4.0     # Shannon entropy

[firewall.ddos]
enabled = true
syn_cookie_threshold = 1000 # SYN/sec
country_block_on_ddos = ["CN", "RU", "KP"]

[waf]
enabled = true
bind = "0.0.0.0:80"         # HTTP
bind_tls = "0.0.0.0:443"    # HTTPS
tls_cert_dir = "/etc/aegis/certs"
max_request_size = 10485760 # 10MB
request_timeout = 30

[waf.rate_limit]
enabled = true
requests_per_minute = 100
burst = 20
block_duration = 300        # 5 menit

[tunnel]
enabled = true
cloudflare_token = ""         # Diisi via UI, encrypted at rest
health_check_interval = 30
auto_reconnect = true

[tunnel.origin_protection]
enabled = true
allow_direct_ip = false     # Hanya allow via tunnel
allowed_ips = ["127.0.0.1"] # Untuk local debug

[watchdog]
enabled = true
services = ["aegis-waf", "aegis-tunnel"]
check_interval = 10         # detik
restart_on_failure = true
max_restarts = 5            # per jam
```

---

## 8. Data Model (SQLite)

```sql
-- Firewall events
CREATE TABLE firewall_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    action TEXT CHECK(action IN ('DROP', 'PASS', 'RATE_LIMIT')),
    src_ip TEXT NOT NULL,
    dst_ip TEXT NOT NULL,
    src_port INTEGER,
    dst_port INTEGER,
    protocol TEXT,
    reason TEXT,
    country TEXT,
    packet_size INTEGER
);

CREATE INDEX idx_fw_time ON firewall_events(timestamp);
CREATE INDEX idx_fw_src_ip ON firewall_events(src_ip);
CREATE INDEX idx_fw_action ON firewall_events(action);

-- WAF events
CREATE TABLE waf_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    action TEXT CHECK(action IN ('BLOCK', 'ALLOW', 'LOG')),
    src_ip TEXT NOT NULL,
    host TEXT,
    method TEXT,
    path TEXT,
    user_agent TEXT,
    rule_id TEXT,
    rule_name TEXT,
    severity TEXT,
    request_body TEXT,
    response_status INTEGER
);

CREATE INDEX idx_waf_time ON waf_events(timestamp);
CREATE INDEX idx_waf_src_ip ON waf_events(src_ip);
CREATE INDEX idx_waf_rule ON waf_events(rule_id);

-- Blocked IPs (with metadata)
CREATE TABLE blocked_ips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    ip TEXT UNIQUE NOT NULL,
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    block_count INTEGER DEFAULT 1,
    reason TEXT,
    country TEXT,
    expires_at DATETIME,       -- NULL = permanent
    source TEXT CHECK(source IN ('FIREWALL', 'WAF', 'MANUAL'))
);

CREATE INDEX idx_blocked_ip ON blocked_ips(ip);
CREATE INDEX idx_blocked_expires ON blocked_ips(expires_at);

-- Virtual hosts
CREATE TABLE virtual_hosts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    server_names TEXT NOT NULL,  -- JSON array
    listen_http TEXT,
    listen_https TEXT,
    tls_cert TEXT,
    tls_key TEXT,
    upstream TEXT NOT NULL,
    enabled BOOLEAN DEFAULT 1,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- WAF rules
CREATE TABLE waf_rules (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    rule_id TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    phase TEXT,
    pattern TEXT NOT NULL,
    action TEXT,
    severity TEXT,
    enabled BOOLEAN DEFAULT 1,
    hit_count INTEGER DEFAULT 0,
    last_hit DATETIME
);

-- Tunnel status
CREATE TABLE tunnel_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    tunnel_id TEXT NOT NULL,
    status TEXT,
    started_at DATETIME,
    last_heartbeat DATETIME,
    bytes_in INTEGER DEFAULT 0,
    bytes_out INTEGER DEFAULT 0,
    errors INTEGER DEFAULT 0
);
```

---

## 9. Threat Defense Matrix

| Threat                 | Defense Layer  | Mechanism                                     |
| ---------------------- | -------------- | --------------------------------------------- |
| **Port Scan**          | eBPF XDP       | Detect SYN flood, port sweep pattern          |
| **SQL Injection**      | WAF            | Regex pattern matching di request body        |
| **XSS**                | WAF            | Regex script tag, event handler, javascript:  |
| **DDoS (Volumetric)**  | eBPF XDP       | Rate limit, SYN cookie, GeoIP block           |
| **DDoS (Application)** | WAF            | Rate limit per IP, per path, challenge        |
| **DNS Tunneling**      | eBPF XDP       | Query length, frequency, entropy heuristic    |
| **Brute Force**        | WAF + eBPF     | Rate limit login endpoints, progressive delay |
| **Bad Bot**            | WAF            | User-Agent filter, behavior analysis          |
| **Direct IP Access**   | Tunnel Manager | Block non-tunnel traffic                      |
| **Service Crash**      | Watchdog       | Auto-restart WAF/Tunnel dalam 5 detik         |
| **Config Tampering**   | File Integrity | Monitor /etc/aegis/ changes                   |

---

## 10. Non-Functional Requirements

| Requirement         | Target                                                |
| ------------------- | ----------------------------------------------------- |
| **Performance**     | < 1ms latency (eBPF), < 5ms (WAF), 10K req/sec        |
| **Reliability**     | 99.9% uptime, auto-restart on failure                 |
| **Security**        | Rust memory safety, least privilege, encrypted config |
| **Scalability**     | Single server (v1.0), multi-server (v2.0)             |
| **Usability**       | Install: 1 command, setup: < 5 menit                  |
| **Maintainability** | Modular, hot reload, clear logging                    |
| **Portability**     | Linux x86_64 + ARM64 (v1.0), more OS (v2.0)           |

---

## 11. Development Roadmap (Weekly Task List)

### WEEK 1-2: FOUNDATION

├── [ ] Setup WSL2 development environment
├── [ ] Install Rust + Aya + Go + Node.js
├── [ ] Create GitHub repo: aegis-security
├── [ ] Setup Cargo workspace structure
├── [ ] Setup Go module structure
├── [ ] Setup React + Vite project
├── [ ] Write README.md with architecture diagram
├── [ ] Setup GitHub Actions CI/CD
└── [ ] Create docker-compose.dev.yml

### WEEK 3-4: eBPF FIREWALL (TC mode for WSL2)

├── [ ] Write eBPF TC program (C)
├── [ ] Compile with Aya
├── [ ] Userspace Rust daemon
├── [ ] BPF maps: blocklist, rate_limit, stats
├── [ ] SQLite logging
├── [ ] gRPC client to Manager
├── [ ] Test: drop packet from specific IP
├── [ ] Test: rate limit exceeded
└── [ ] Document: TC vs XDP differences

### WEEK 5-6: WAF ENGINE

├── [ ] Axum HTTP server
├── [ ] Reverse proxy logic
├── [ ] Virtual Host routing (Host header + SNI)
├── [ ] Rule engine: regex matching
├── [ ] Built-in rules: SQLi, XSS, LFI, RCE
├── [ ] Rate limiting per IP/path
├── [ ] Request/response logging
├── [ ] Hot reload config
└── [ ] Test: block SQL injection payload

### WEEK 7-8: MANAGER API

├── [ ] Gin REST API server
├── [ ] SQLite schema + GORM
├── [ ] Endpoints: firewall, waf, logs, config
├── [ ] WebSocket for real-time events
├── [ ] Serve dashboard static files
├── [ ] Agent registration + heartbeat
├── [ ] Alert dispatcher (Discord webhook)
└── [ ] Test: full API flow

### WEEK 9-10: DASHBOARD

├── [ ] React layout + sidebar navigation
├── [ ] Dashboard overview page
├── [ ] Firewall rules editor
├── [ ] WAF virtual host manager
├── [ ] Live traffic log viewer
├── [ ] Alert panel
├── [ ] Settings page
├── [ ] Dark mode
└── [ ] Test: end-to-end UI flow

### WEEK 11-12: INTEGRATION & POLISH

├── [ ] Docker Compose production
├── [ ] Systemd service files
├── [ ] Install script (install.sh)
├── [ ] DNS tunnel detection heuristic
├── [ ] DDoS mitigation (SYN cookie)
├── [ ] Cloudflare tunnel integration
├── [ ] Documentation: INSTALL.md, API.md
├── [ ] Performance testing (wrk)
└── [ ] Release v1.0 on GitHub[]()

---

## 12. Project Structure

```
aegis/
├── Cargo.toml                    # Rust workspace
├── go.mod                        # Go module
├── Makefile                      # Build automation
├── README.md
├── docs/
│   ├── INSTALL.md
│   ├── CONFIG.md
│   └── API.md
├── scripts/
│   ├── install.sh               # One-line install
│   └── uninstall.sh
├── config/
│   ├── aegis.toml               # Default config
│   └── waf/
│       └── default-rules.toml
├── crates/
│   ├── aegis-xdp/               # eBPF XDP firewall
│   │   ├── src/
│   │   │   ├── main.rs          # Userspace daemon
│   │   │   ├── bpf/
│   │   │   │   └── aegis_xdp.bpf.c  # eBPF program (C via libbpf)
│   │   │   ├── firewall.rs
│   │   │   ├── ratelimit.rs
│   │   │   ├── geoip.rs
│   │   │   ├── watch.rs         # Watchdog
│   │   │   └── lib.rs
│   │   └── Cargo.toml
│   │
│   ├── aegis-waf/               # WAF reverse proxy
│   │   ├── src/
│   │   │   ├── main.rs
│   │   │   ├── proxy.rs         # Reverse proxy logic
│   │   │   ├── vhost.rs         # Virtual host routing
│   │   │   ├── rules/           # Rule engine
│   │   │   │   ├── engine.rs
│   │   │   │   ├── parser.rs
│   │   │   │   └── builtin.rs   # Built-in rules
│   │   │   ├── tls.rs           # TLS termination
│   │   │   ├── ratelimit.rs
│   │   │   └── lib.rs
│   │   └── Cargo.toml
│   │
│   ├── aegis-tunnel/            # Tunnel manager
│   │   ├── src/
│   │   │   ├── main.rs
│   │   │   ├── cloudflare.rs
│   │   │   ├── health.rs
│   │   │   └── lib.rs
│   │   └── Cargo.toml
│   │
│   └── aegis-common/            # Shared library
│       ├── src/
│       │   ├── config.rs        # TOML config
│       │   ├── db.rs            # SQLite wrapper
│       │   ├── logging.rs
│       │   └── models.rs        # Data structures
│       └── Cargo.toml
│
├── api/                          # Go API server
│   ├── main.go
│   ├── handlers/
│   │   ├── firewall.go
│   │   ├── waf.go
│   │   ├── tunnel.go
│   │   └── logs.go
│   ├── middleware/
│   │   ├── auth.go
│   │   └── cors.go
│   ├── models/
│   └── db/
│       └── sqlite.go
│
├── ui/                           # Tauri + React
│   ├── src-tauri/
│   │   ├── Cargo.toml
│   │   ├── tauri.conf.json
│   │   └── src/
│   │       └── main.rs          # Tauri commands
│   ├── src/
│   │   ├── App.tsx
│   │   ├── components/
│   │   │   ├── Dashboard.tsx
│   │   │   ├── Firewall.tsx
│   │   │   ├── Waf.tsx
│   │   │   ├── Tunnel.tsx
│   │   │   └── Logs.tsx
│   │   ├── hooks/
│   │   │   └── useApi.ts
│   │   └── styles/
│   │       └── global.css
│   ├── package.json
│   └── vite.config.ts
│
└── tests/
    ├── integration/
    └── load/
```

---

## 13. Success Metrics

| Metric              | Target                    | Measurement                  |
| ------------------- | ------------------------- | ---------------------------- |
| **Install Time**    | < 5 menit                 | Fresh VM, run install script |
| **First Block**     | < 2 menit setelah install | Default rules active         |
| **Latency Impact**  | < 1ms (eBPF), < 5ms (WAF) | wrk/benchmark                |
| **Uptime**          | > 99%                     | 30-day test                  |
| **Memory**          | < 200MB total             | htop monitoring              |
| **CPU**             | < 5% idle                 | htop monitoring              |
| **GitHub Stars**    | 100+ (3 bulan)            | GitHub metrics               |
| **Issues Resolved** | 90%+                      | GitHub issues                |

---

## 14. Future Roadmap (v1.1+)

| Version | Feature                            | ETA        |
| ------- | ---------------------------------- | ---------- |
| v1.1    | File Integrity Monitoring (FIM)    | +1 month   |
| v1.2    | Container Security (Docker/Podman) | +2 months  |
| v1.3    | AI Anomaly Detection (Python ML)   | +3 months  |
| v1.4    | Purple Team Module (self-attack)   | +4 months  |
| v1.5    | WireGuard VPN for admin            | +5 months  |
| v2.0    | Multi-server federation            | +6 months  |
| v2.1    | Windows support (ETW)              | +8 months  |
| v2.2    | macOS support (DTrace)             | +10 months |

### 14.1 Version Mapping to Cybersecurity Domains, Roles, and Skills

Below is the strategic domain alignment, targeting role profiles, and skill sets needed for each phase of the expansion roadmap:

- **v1.0 — Network Defense Core**
  - **Domain:** Blue Team → Network Security + Application Security
  - **Role:** Security Engineer (tool builder)
  - **Skill:** Rust, eBPF, Go, Linux kernel
- **v1.1 — File Integrity Monitoring (FIM)**
  - **Domain:** Blue Team → Endpoint Security
  - **Role:** Detection Engineer
  - **Skill:** eBPF tracepoints, file system hooks
- **v1.2 — Container Security**
  - **Domain:** Blue Team → Cloud Security
  - **Role:** DevSecOps Engineer
  - **Skill:** Docker, Kubernetes, OPA
- **v1.3 — AI Anomaly Detection**
  - **Domain:** SOC → Threat Hunting + UEBA
  - **Role:** Detection Engineer / Data Scientist
  - **Skill:** Python, ML, statistical analysis
- **v1.4 — Purple Team Module**
  - **Domain:** Red Team + Blue Team (Purple Team)
  - **Role:** Purple Team Operator
  - **Skill:** Attack simulation, detection validation
- **v1.5 — Multi-Agent + WireGuard**
  - **Domain:** Security Architecture
  - **Role:** Security Architect
  - **Skill:** Distributed systems, network design
- **v2.0 — Windows + macOS Agent**
  - **Domain:** Endpoint Security (cross-platform EDR)
  - **Role:** EDR Developer
  - **Skill:** Windows internals (ETW), macOS internals (DTrace, Endpoint Security Framework)
- **v2.1 — SIEM Integration**
  - **Domain:** SOC → SIEM Engineering
  - **Role:** SIEM Engineer
  - **Skill:** Splunk, Elastic, QRadar APIs
- **v2.2 — Enterprise Features**
  - **Domain:** GRC + Security Architecture
  - **Role:** Security Consultant
  - **Skill:** Compliance frameworks, risk assessment

---

## 15. Appendices

### A. System Requirements

| Requirement | Minimum                               | Recommended       |
| ----------- | ------------------------------------- | ----------------- |
| OS          | Linux 5.10+ (Ubuntu 22.04, Debian 12) | Linux 6.1+        |
| CPU         | x86_64, 1 core                        | x86_64, 2+ cores  |
| RAM         | 512MB                                 | 2GB               |
| Disk        | 100MB                                 | 1GB (for logs)    |
| Kernel      | CONFIG_BPF=y, CONFIG_XDP=y            | Full eBPF support |
| Privileges  | root (for eBPF)                       | root + CAP_BPF    |

### B. Dependencies

```bash
# Build dependencies
sudo apt install -y \
    llvm clang libbpf-dev \
    libssl-dev pkg-config \
    protobuf-compiler

# Runtime dependencies
sudo apt install -y \
    sqlite3 libsqlite3-dev

# Optional: cloudflared (for tunnel)
wget -q https://github.com/cloudflare/cloudflared/releases/latest/download/cloudflared-linux-amd64.deb
sudo dpkg -i cloudflared-linux-amd64.deb
```

### C. Glossary

| Term           | Definition                                                         |
| -------------- | ------------------------------------------------------------------ |
| **eBPF**       | Extended Berkeley Packet Filter — run sandboxed programs in kernel |
| **XDP**        | Express Data Path — eBPF hook at network driver level              |
| **TC**         | Traffic Control — eBPF hook in kernel network stack (after XDP)    |
| **WAF**        | Web Application Firewall — filter HTTP traffic                     |
| **GeoIP**      | IP-to-country mapping database                                     |
| **SYN Cookie** | DDoS mitigation: stateless SYN flood protection                    |
| **Tauri**      | Rust-based desktop app framework (Electron alternative)            |

---

_Document Version: 1.0_  
_Last Updated: 2026-06-16_  
_Author: Aegis Team_  
_Status: Draft — Ready for Review_
