# 📋 AEGIS v1.0 — Product Requirement Document (Revised)

## Network Defense Core for Linux Server

## WSL2-Compatible Development | Agent-Manager Architecture

---

## 1. Executive Summary

**Product:** Aegis — Real-time Network Defense Platform  
**Version:** 1.0  
**Target:** Linux servers & homelabs (single server, multi-server v1.5+)  
**Development:** WSL2 (Windows) + VPS (Linux cloud)  
**Philosophy:** "Defense-first, modular, lightweight, headless server + web dashboard"

Aegis adalah platform defense yang menggabungkan eBPF kernel-level packet filtering, WAF reverse proxy, dan real-time monitoring dalam arsitektur Agent-Manager. Server headless (no GUI), admin akses via Web Dashboard atau CLI.

---

## 2. Development Environment

### 2.1 WSL2 Setup (Local Development)

```bash
# WSL2 Requirements
# Windows 10 version 2004+ atau Windows 11
# WSL2 dengan Ubuntu 22.04/24.04

# Check WSL version
wsl --version
# WSL version: 2.2.4.0 (atau lebih baru)

# Check kernel version (butuh 5.15+ untuk eBPF)
uname -r
# Output: 5.15.167.4-microsoft-standard-WSL2 ✓

# Install dependencies
sudo apt update && sudo apt upgrade -y
sudo apt install -y     build-essential     llvm clang libbpf-dev     libssl-dev pkg-config     protobuf-compiler     libsqlite3-dev sqlite3     git curl wget

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source $HOME/.cargo/env
rustup target add x86_64-unknown-linux-gnu

# Install Go
wget https://go.dev/dl/go1.22.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.22.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc
source ~/.bashrc

# Install Node.js (via nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
source ~/.bashrc
nvm install 20
nvm use 20

# Verify installations
rustc --version      # rustc 1.79.0
go version           # go1.22.0
node --version       # v20.12.0
```

### 2.2 WSL2 Limitations & Workarounds

| Feature         | WSL2 Status       | Workaround                       | Production         |
| --------------- | ----------------- | -------------------------------- | ------------------ |
| **XDP**         | ❌ Not supported  | Use TC (Traffic Control) for dev | XDP on real server |
| **TC eBPF**     | ✅ Supported      | Primary dev mode                 | Also works         |
| **Tracepoints** | ✅ Supported      | Full functionality               | Same               |
| **Kprobes**     | ✅ Supported      | Full functionality               | Same               |
| **Real NIC**    | ❌ Virtual switch | Test on VPS                      | Real NIC           |
| **Performance** | ⚠️ Slower         | Acceptable for dev               | Native speed       |

### 2.3 VPS Setup (Testing/Production)

```bash
# Recommended: Hetzner CX21 (€5.35/month) atau DigitalOcean Droplet ($6/month)
# Specs: 2 vCPU, 4GB RAM, 40GB SSD, Ubuntu 22.04

# One-line install Aegis dependencies
 curl -fsSL https://get.aegis.dev | sudo bash

# Or manual:
sudo apt update
sudo apt install -y aegis-xdp aegis-waf aegis-manager aegis-cli

# Start services
sudo systemctl enable --now aegis-xdp aegis-waf aegis-manager

# Check status
sudo aegis-cli status
```

---

## 3. Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    AEGIS v1.0 — SYSTEM ARCHITECTURE         │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  ADMIN INTERFACE (Any device with browser)              │ │
│  │  ─────────────────────────────────────────────────────  │ │
│  │  • Web Dashboard: https://manager-ip:8443               │ │
│  │  • Mobile responsive, dark mode                         │ │
│  │  • Real-time WebSocket updates                          │ │
│  │  • No install required                                  │ │
│  │                                                         │ │
│  │  Optional:                                              │ │
│  │  • Tauri Desktop App (Windows/Mac/Linux)                │ │
│  │  • aegis-cli (SSH terminal)                             │ │
│  └─────────────────────────────────────────────────────────┘ │
│                              │                                │
│                              │ HTTPS / WebSocket              │
│                              │ (mTLS optional v2.0)           │
│                              ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  AEGIS MANAGER (Go + SQLite)                            │ │
│  │  ─────────────────────────────────────────────────────  │ │
│  │  • REST API (Gin)                                       │ │
│  │  • WebSocket server (real-time events)                  │ │
│  │  • Serve dashboard static files                         │ │
│  │  • Aggregate agent data                                 │ │
│  │  • Central config & policy                              │ │
│  │  • Alert dispatcher (Discord, Email, Webhook)           │ │
│  │  • Multi-agent support (v1.5)                           │ │
│  │                                                         │ │
│  │  Default: Run on same server as Agent                   │ │
│  │  Advanced: Separate manager server                      │ │
│  └─────────────────────────────────────────────────────────┘ │
│                              │                                │
│                              │ gRPC (internal)                │
│                              │                                │
│                              ▼                                │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │  AEGIS AGENT (Rust binaries + systemd)                  │ │
│  │  ─────────────────────────────────────────────────────  │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐     │ │
│  │  │ aegis-xdp   │  │ aegis-waf   │  │ aegis-tunnel│     │ │
│  │  │ (or tc)     │  │             │  │             │     │ │
│  │  │             │  │ • Reverse   │  │ • Cloudflare│     │ │
│  │  │ • Packet    │  │   Proxy     │  │   Tunnel    │     │ │
│  │  │   filter    │  │ • Custom    │  │ • Origin    │     │ │
│  │  │ • Rate      │  │   Rules     │  │   Protect   │     │ │
│  │  │   limit     │  │ • Virtual   │  │ • Health    │     │ │
│  │  │ • GeoIP     │  │   Host      │  │   Check     │     │ │
│  │  │ • Port scan │  │ • Rate      │  │             │     │ │
│  │  │   detect    │  │   Limit     │  │             │     │ │
│  │  │ • DNS tunnel│  │ • IP Rep    │  │             │     │ │
│  │  │   detect    │  │             │  │             │     │ │
│  │  └─────────────┘  └─────────────┘  └─────────────┘     │ │
│  │                                                         │ │
│  │  ┌─────────────────────────────────────────────────┐     │ │
│  │  │ aegis-agent (Reporter)                          │     │ │
│  │  │ • Collect events from xdp/waf/tunnel            │     │ │
│  │  │ • gRPC client to Manager                        │     │ │
│  │  │ • Local SQLite queue (offline cache)            │     │ │
│  │  │ • Heartbeat every 30s                           │     │ │
│  │  │ • Auto-restart crashed modules                  │     │ │
│  │  └─────────────────────────────────────────────────┘     │ │
│  │                                                         │ │
│  │  Local SQLite: /var/lib/aegis/agent.db                   │ │
│  │  Config: /etc/aegis/config.toml                         │ │
│  │  Logs: /var/log/aegis/                                  │ │
│  │  PID: /var/run/aegis/                                   │ │
│  └─────────────────────────────────────────────────────────┘ │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

---

## 4. Module Specifications

### 4.1 eBPF Firewall (aegis-xdp / aegis-tc)

**Language:** Rust + Aya  
**Compile features:** `xdp` (production), `tc` (WSL2 dev)  
**Privileges:** root, CAP_BPF, CAP_NET_ADMIN

#### Dual-Mode Architecture

```rust
// crates/aegis-xdp/src/main.rs

#[cfg(feature = "xdp")]
mod mode {
    pub use aya::programs::Xdp;
    pub const MODE_NAME: &str = "xdp";
}

#[cfg(feature = "tc")]
mod mode {
    pub use aya::programs::SchedClassifier;
    pub const MODE_NAME: &str = "tc";
}

#[cfg(not(any(feature = "xdp", feature = "tc")))]
compile_error!("Enable one feature: --features xdp OR --features tc");

pub async fn run(config: FirewallConfig) -> Result<(), Box<dyn Error>> {
    #[cfg(feature = "xdp")]
    println!("Running in XDP mode (production)");

    #[cfg(feature = "tc")]
    println!("Running in TC mode (development/WSL2)");

    // Shared logic regardless of mode
    let mut bpf = Bpf::load_file(&config.bpf_object)?;

    #[cfg(feature = "xdp")]
    let program: &mut Xdp = bpf.program_mut("aegis_filter").unwrap().try_into()?;

    #[cfg(feature = "tc")]
    let program: &mut SchedClassifier = bpf.program_mut("aegis_filter").unwrap().try_into()?;

    program.load()?;
    program.attach(&config.interface, config.attach_flags)?;

    // Common: setup maps, start userspace loop
    setup_maps(&mut bpf, &config).await?;
    event_loop(bpf, config).await
}
```

#### Compile Commands

```bash
# Development (WSL2)
cargo build --package aegis-xdp --features tc

# Production (real server with XDP-capable NIC)
cargo build --package aegis-xdp --features xdp --release

# Both (CI/CD)
cargo build --package aegis-xdp --features tc --target-dir target/dev
cargo build --package aegis-xdp --features xdp --release --target-dir target/prod
```

#### eBPF Program (Shared between XDP and TC)

```c
// crates/aegis-xdp/src/bpf/aegis_filter.bpf.c
// Compiled with: clang -target bpf -O2 -c aegis_filter.bpf.c -o aegis_filter.bpf.o

#include <linux/bpf.h>
#include <linux/pkt_cls.h>  // For TC
#include <linux/if_ether.h>
#include <linux/ip.h>
#include <linux/tcp.h>
#include <linux/udp.h>
#include <bpf/bpf_helpers.h>
#include <bpf/bpf_endian.h>

// Shared maps (same structure for XDP and TC)
struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 10000);
    __type(key, __u32);      // IPv4 address
    __type(value, __u64);    // Block expiration timestamp
} blocklist SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_LRU_HASH);
    __uint(max_entries, 10000);
    __type(key, __u64);      // IP + port combo
    __type(value, struct rate_limit);  // Token bucket
} rate_limit SEC(".maps");

struct {
    __uint(type, BPF_MAP_TYPE_PERCPU_ARRAY);
    __uint(max_entries, 1);
    __type(key, __u32);
    __type(value, __u64);    // Packet count
} stats SEC(".maps");

// XDP entry point
SEC("xdp")
int aegis_xdp_filter(struct xdp_md *ctx) {
    void *data_end = (void *)(long)ctx->data_end;
    void *data = (void *)(long)ctx->data;
    struct ethhdr *eth = data;

    if ((void *)(eth + 1) > data_end)
        return XDP_PASS;

    if (eth->h_proto != bpf_htons(ETH_P_IP))
        return XDP_PASS;

    struct iphdr *ip = (void *)(eth + 1);
    if ((void *)(ip + 1) > data_end)
        return XDP_PASS;

    __u32 src_ip = ip->saddr;

    // Check blocklist
    __u64 *expires = bpf_map_lookup_elem(&blocklist, &src_ip);
    if (expires && *expires > bpf_ktime_get_ns())
        return XDP_DROP;

    // Check rate limit
    if (check_rate_limit(src_ip, ip->protocol) != 0)
        return XDP_DROP;

    // Update stats
    __u32 key = 0;
    __u64 *count = bpf_map_lookup_elem(&stats, &key);
    if (count)
        __sync_fetch_and_add(count, 1);

    return XDP_PASS;
}

// TC entry point (for WSL2 development)
SEC("classifier")
int aegis_tc_filter(struct __sk_buff *skb) {
    // Same logic as XDP but with skb API
    // TC can see packets after network stack processing
    // Good for: connection tracking, rate limiting, logging

    void *data_end = (void *)(long)skb->data_end;
    void *data = (void *)(long)skb->data;
    struct ethhdr *eth = data;

    if ((void *)(eth + 1) > data_end)
        return TC_ACT_OK;

    // ... same logic as XDP ...

    return TC_ACT_OK;  // TC equivalent of XDP_PASS
}

char _license[] SEC("license") = "GPL";
```

#### Features

| Feature                  | Priority | XDP  | TC    | Description                               |
| ------------------------ | -------- | ---- | ----- | ----------------------------------------- |
| **Packet Filter**        | P0       | ✅   | ✅    | Block/allow by src IP, dst port, protocol |
| **Rate Limiting**        | P0       | ✅   | ✅    | Token bucket per IP                       |
| **GeoIP Block**          | P0       | ✅   | ✅    | MaxMind DB lookup                         |
| **Port Scan Detection**  | P0       | ✅   | ⚠️    | SYN flood, port sweep (TC limited)        |
| **Connection Tracking**  | P0       | ⚠️   | ✅    | TC better for stateful tracking           |
| **DNS Tunnel Detection** | P1       | ✅   | ✅    | Heuristic analysis                        |
| **DDoS Mitigation**      | P1       | ✅   | ⚠️    | SYN cookie (XDP only)                     |
| **Auto-restart Service** | P0       | N/A  | N/A   | Userspace watchdog                        |
| **Performance**          | —        | ~1μs | ~10μs | XDP faster                                |

---

### 4.2 WAF Engine (aegis-waf)

**Language:** Rust (Axum + Tokio)  
**Type:** Standalone binary + library  
**Interface:** HTTP reverse proxy + gRPC ke Manager

#### Architecture

```rust
// crates/aegis-waf/src/main.rs

use axum::{
    routing::any,
    Router,
    extract::{State, Host, Request},
    response::Response,
};
use std::sync::Arc;
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let config = load_config("/etc/aegis/config.toml")?;
    let state = Arc::new(AppState::new(config).await?);

    // Load virtual hosts from config
    let vhosts = load_virtual_hosts(&state.config).await?;

    // Build router with virtual host routing
    let app = Router::new()
        .fallback(any(handler))
        .with_state(state.clone());

    // HTTP listener
    let http_listener = TcpListener::bind(&state.config.waf.bind_http).await?;
    let http_server = axum::serve(http_listener, app.clone());

    // HTTPS listener (if TLS configured)
    let https_server = if state.config.waf.tls_enabled {
        let tls_config = rustls::ServerConfig::builder()
            .with_safe_defaults()
            .with_no_client_auth()
            .with_single_cert(
                load_certs(&state.config.waf.tls_cert)?,
                load_keys(&state.config.waf.tls_key)?,
            )?;

        let https_listener = TcpListener::bind(&state.config.waf.bind_https).await?;
        Some(axum::serve(https_listener, app).into_future())
    } else {
        None
    };

    // Start servers
    tokio::select! {
        result = http_server => result?,
        result = https_server.unwrap_or(futures::future::pending()) => result?,
    }

    Ok(())
}

async fn handler(
    State(state): State<Arc<AppState>>,
    Host(host): Host,
    request: Request,
) -> Result<Response, WafError> {
    // 1. Find virtual host configuration
    let vhost = state.vhosts.get(&host)
        .ok_or(WafError::UnknownHost)?;

    // 2. Check rate limit
    if vhost.rate_limit.enabled {
        let client_ip = get_client_ip(&request);
        if state.rate_limiter.check(&client_ip, &vhost).await? {
            return Ok(rate_limit_response());
        }
    }

    // 3. Run WAF rules
    let rule_result = state.rule_engine.check(&request, &vhost).await?;
    match rule_result.action {
        RuleAction::Block => {
            log_block(&state.db, &request, &rule_result).await?;
            return Ok(block_response(&rule_result));
        }
        RuleAction::Allow => {}  // Continue
        RuleAction::Log => {
            log_event(&state.db, &request, &rule_result).await?;
        }
    }

    // 4. Forward to upstream
    let upstream_request = build_upstream_request(&request, &vhost)?;
    let upstream_response = state.http_client.request(upstream_request).await?;

    // 5. Process response (optional)
    let response = process_response(upstream_response, &vhost).await?;

    Ok(response)
}
```

#### Rule Engine

```rust
// crates/aegis-waf/src/rules/engine.rs

use regex::Regex;
use once_cell::sync::Lazy;

pub struct RuleEngine {
    rules: Vec<WafRule>,
    compiled: Vec<CompiledRule>,
}

pub struct WafRule {
    pub id: String,
    pub name: String,
    pub phase: RulePhase,
    pub condition: RuleCondition,
    pub action: RuleAction,
    pub severity: Severity,
    pub enabled: bool,
}

pub enum RuleCondition {
    Regex(String),
    Contains(String),
    StartsWith(String),
    EndsWith(String),
    Exact(String),
    IpRange(Vec<IpNetwork>),
    UserAgentRegex(String),
    Method(Vec<String>),
    And(Box<RuleCondition>, Box<RuleCondition>),
    Or(Box<RuleCondition>, Box<RuleCondition>),
    Not(Box<RuleCondition>),
}

pub enum RuleAction {
    Block,
    Allow,
    Log,
    RateLimit { requests: u32, window: Duration },
    Challenge,  // CAPTCHA or JS challenge
}

// Built-in rules (loaded at startup)
pub static BUILTIN_RULES: Lazy<Vec<WafRule>> = Lazy::new(|| {
    vec![
        // SQL Injection
        WafRule {
            id: "SQLI-001".to_string(),
            name: "SQL Injection - Union Select".to_string(),
            phase: RulePhase::RequestBody,
            condition: RuleCondition::Regex(
                r"(?i)(union\s+select|insert\s+into|delete\s+from|drop\s+table|exec\s*\(|benchmark\s*\()".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::Critical,
            enabled: true,
        },
        WafRule {
            id: "SQLI-002".to_string(),
            name: "SQL Injection - Comment".to_string(),
            phase: RulePhase::RequestBody,
            condition: RuleCondition::Regex(
                r"(?i)(/\*|\*/|--|#|;)".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::High,
            enabled: true,
        },

        // XSS
        WafRule {
            id: "XSS-001".to_string(),
            name: "XSS - Script Tag".to_string(),
            phase: RulePhase::RequestBody,
            condition: RuleCondition::Regex(
                r"(?i)<script[^>]*>[\s\S]*?</script>".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::High,
            enabled: true,
        },
        WafRule {
            id: "XSS-002".to_string(),
            name: "XSS - Event Handler".to_string(),
            phase: RulePhase::RequestBody,
            condition: RuleCondition::Regex(
                r"(?i)\bon\w+\s*=\s*["']?[^"'>]*["']?".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::High,
            enabled: true,
        },

        // LFI/RFI
        WafRule {
            id: "LFI-001".to_string(),
            name: "Local File Inclusion".to_string(),
            phase: RulePhase::RequestUri,
            condition: RuleCondition::Regex(
                r"(\.\./|\.\./|\.%00|\.%01|%00|%01|/etc/passwd|/proc/self)".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::High,
            enabled: true,
        },

        // RCE
        WafRule {
            id: "RCE-001".to_string(),
            name: "Remote Code Execution".to_string(),
            phase: RulePhase::RequestBody,
            condition: RuleCondition::Regex(
                r"(?i)(\$\(.*\)|\$\{.*\}|`.*`|\|.*\||;.*bash|wget\s|curl\s|python\s*-c)".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::Critical,
            enabled: true,
        },

        // SSRF
        WafRule {
            id: "SSRF-001".to_string(),
            name: "Server-Side Request Forgery".to_string(),
            phase: RulePhase::RequestBody,
            condition: RuleCondition::Regex(
                r"(?i)(localhost|127\.0\.0\.1|0\.0\.0\.0|\[::1\]|169\.254\.|10\.|172\.(1[6-9]|2[0-9]|3[01])\.|192\.168\.)".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::High,
            enabled: true,
        },

        // Bot Detection
        WafRule {
            id: "BOT-001".to_string(),
            name: "Bad User-Agent".to_string(),
            phase: RulePhase::RequestHeaders,
            condition: RuleCondition::UserAgentRegex(
                r"(?i)(sqlmap|nikto|nmap|masscan|zgrab|gobuster|dirb|wfuzz)".to_string()
            ),
            action: RuleAction::Block,
            severity: Severity::Medium,
            enabled: true,
        },
    ]
});

impl RuleEngine {
    pub fn new() -> Self {
        let mut compiled = Vec::new();
        for rule in BUILTIN_RULES.iter() {
            if let RuleCondition::Regex(pattern) = &rule.condition {
                compiled.push(CompiledRule {
                    rule: rule.clone(),
                    regex: Regex::new(pattern).ok(),
                });
            }
        }

        Self {
            rules: BUILTIN_RULES.to_vec(),
            compiled,
        }
    }

    pub async fn check(&self, request: &Request, vhost: &VirtualHost) -> Result<RuleResult, WafError> {
        // Check custom rules first (user-defined)
        for rule in &vhost.custom_rules {
            if let Some(result) = self.match_rule(rule, request).await? {
                return Ok(result);
            }
        }

        // Then check built-in rules
        for compiled in &self.compiled {
            if !compiled.rule.enabled {
                continue;
            }
            if let Some(regex) = &compiled.regex {
                if self.check_regex(regex, request, &compiled.rule.phase).await? {
                    return Ok(RuleResult {
                        matched: true,
                        rule: compiled.rule.clone(),
                        action: compiled.rule.action.clone(),
                    });
                }
            }
        }

        Ok(RuleResult::default_allow())
    }
}
```

---

### 4.3 Tunnel Manager (aegis-tunnel)

**Language:** Rust  
**Type:** Standalone binary  
**Interface:** gRPC ke Manager

```rust
// crates/aegis-tunnel/src/main.rs

use std::process::{Command, Child};
use tokio::time::{interval, Duration};

pub struct TunnelManager {
    config: TunnelConfig,
    process: Option<Child>,
    health_check_url: String,
    status: Arc<RwLock<TunnelStatus>>,
}

#[derive(Debug, Clone)]
pub enum TunnelStatus {
    Connected,
    Connecting,
    Error(String),
    Disabled,
}

impl TunnelManager {
    pub fn new(config: TunnelConfig) -> Self {
        Self {
            health_check_url: format!("http://localhost:{}/health", config.metrics_port),
            status: Arc::new(RwLock::new(TunnelStatus::Disabled)),
            ..config
        }
    }

    pub async fn start(&mut self) -> Result<(), TunnelError> {
        if !self.config.enabled {
            return Ok(());
        }

        // Validate config
        if self.config.cloudflare_token.is_empty() {
            return Err(TunnelError::MissingToken);
        }

        // Write cloudflared config
        let config_path = write_cloudflared_config(&self.config)?;

        // Spawn cloudflared process
        let mut cmd = Command::new("cloudflared");
        cmd.arg("tunnel")
            .arg("--config")
            .arg(&config_path)
            .arg("run");

        self.process = Some(cmd.spawn()?);

        // Wait for "Connected" in stdout
        wait_for_connection(&mut self.process, Duration::from_secs(30)).await?;

        // Update status
        *self.status.write().await = TunnelStatus::Connected;

        // Start health check loop
        let status = self.status.clone();
        let health_url = self.health_check_url.clone();
        tokio::spawn(async move {
            let mut interval = interval(Duration::from_secs(30));
            loop {
                interval.tick().await;
                match check_health(&health_url).await {
                    Ok(true) => {
                        *status.write().await = TunnelStatus::Connected;
                    }
                    Ok(false) | Err(_) => {
                        *status.write().await = TunnelStatus::Error("Health check failed".to_string());
                        // Trigger reconnect
                    }
                }
            }
        });

        Ok(())
    }

    pub async fn stop(&mut self) -> Result<(), TunnelError> {
        if let Some(mut child) = self.process.take() {
            child.kill()?;
        }
        *self.status.write().await = TunnelStatus::Disabled;
        Ok(())
    }

    pub async fn get_status(&self) -> TunnelStatus {
        self.status.read().await.clone()
    }
}

// Origin IP Protection
pub fn setup_origin_protection(config: &OriginProtectionConfig) -> Result<(), Box<dyn Error>> {
    if !config.enabled {
        return Ok(());
    }

    // Block all direct IP access (only allow via Cloudflare tunnel)
    // This is done via iptables/nftables rules

    let allowed_ips = config.allowed_ips.clone();
    let tunnel_ips = get_cloudflare_tunnel_ips()?;  // Fetch from Cloudflare API

    // Setup iptables rules
    // 1. Allow loopback
    // 2. Allow Cloudflare tunnel IPs
    // 3. Drop everything else to protected ports

    Ok(())
}
```

---

### 4.4 Agent Reporter (aegis-agent)

**Language:** Rust  
**Type:** Daemon  
**Interface:** gRPC ke Manager

```rust
// crates/aegis-agent/src/main.rs

use tokio::time::{interval, Duration};
use tonic::transport::Channel;

pub struct AgentReporter {
    manager_client: ManagerClient<Channel>,
    local_db: SqlitePool,
    config: AgentConfig,
}

impl AgentReporter {
    pub async fn new(config: AgentConfig) -> Result<Self, Box<dyn Error>> {
        let channel = Channel::from_shared(config.manager_address)?
            .connect_timeout(Duration::from_secs(10))
            .connect()
            .await?;

        let client = ManagerClient::new(channel);
        let db = SqlitePool::connect(&config.local_db_path).await?;

        Ok(Self {
            manager_client: client,
            local_db: db,
            config,
        })
    }

    pub async fn run(&self) -> Result<(), Box<dyn Error>> {
        // Spawn tasks
        tokio::join!(
            self.heartbeat_loop(),
            self.event_collector_loop(),
            self.watchdog_loop(),
        );

        Ok(())
    }

    async fn heartbeat_loop(&self) {
        let mut interval = interval(Duration::from_secs(30));
        loop {
            interval.tick().await;

            let heartbeat = HeartbeatRequest {
                agent_id: self.config.agent_id.clone(),
                timestamp: Utc::now().to_rfc3339(),
                status: self.collect_status().await,
                metrics: self.collect_metrics().await,
            };

            match self.manager_client.send_heartbeat(heartbeat).await {
                Ok(_) => {
                    // Flush local queue to manager
                    self.flush_queue().await.ok();
                }
                Err(e) => {
                    // Queue events locally
                    self.queue_event(Event::HeartbeatFailed(e.to_string())).await.ok();
                }
            }
        }
    }

    async fn event_collector_loop(&self) {
        // Subscribe to events from xdp, waf, tunnel
        let mut rx = self.event_bus.subscribe();

        while let Ok(event) = rx.recv().await {
            // Try send to manager
            match self.manager_client.send_event(event.clone()).await {
                Ok(_) => {}
                Err(_) => {
                    // Queue locally if manager unreachable
                    self.queue_event(event).await.ok();
                }
            }
        }
    }

    async fn watchdog_loop(&self) {
        let mut interval = interval(Duration::from_secs(10));

        loop {
            interval.tick().await;

            for service in &self.config.watchdog_services {
                if !self.is_service_running(service).await {
                    log::warn!("Service {} is down, restarting...", service);
                    self.restart_service(service).await.ok();

                    // Notify manager
                    self.manager_client.send_alert(Alert {
                        severity: Severity::Warning,
                        message: format!("Service {} restarted by watchdog", service),
                        timestamp: Utc::now(),
                    }).await.ok();
                }
            }
        }
    }
}
```

---

### 4.5 Manager API (Go + Gin)

```go
// manager/cmd/aegis-manager/main.go

package main

import (
	"log"
	"net/http"

	"github.com/gin-gonic/gin"
	"github.com/gin-contrib/cors"
	"gorm.io/driver/sqlite"
	"gorm.io/gorm"
)

func main() {
	// Database
	db, err := gorm.Open(sqlite.Open("/var/lib/aegis/manager.db"), &gorm.Config{})
	if err != nil {
		log.Fatal("Failed to connect database:", err)
	}

	// Auto-migrate
	db.AutoMigrate(&Agent{}, &FirewallEvent{}, &WafEvent{}, &BlockedIP{}, &VirtualHost{}, &TunnelStatus{})

	// Router
	r := gin.Default()
	r.Use(cors.Default())

	// API routes
	api := r.Group("/api/v1")
	{
		// Status
		api.GET("/status", getStatus(db))

		// Agents
		api.GET("/agents", listAgents(db))
		api.POST("/agents/register", registerAgent(db))
		api.POST("/agents/:id/heartbeat", agentHeartbeat(db))

		// Firewall
		api.GET("/firewall/rules", listFirewallRules(db))
		api.POST("/firewall/rules", addFirewallRule(db))
		api.DELETE("/firewall/rules/:id", deleteFirewallRule(db))
		api.GET("/firewall/blocks", listBlockedIPs(db))
		api.POST("/firewall/block", blockIP(db))
		api.POST("/firewall/unblock", unblockIP(db))

		// WAF
		api.GET("/waf/vhosts", listVirtualHosts(db))
		api.POST("/waf/vhosts", addVirtualHost(db))
		api.GET("/waf/rules", listWafRules(db))
		api.POST("/waf/rules", addWafRule(db))
		api.GET("/waf/logs", listWafLogs(db))

		// Tunnel
		api.GET("/tunnel/status", getTunnelStatus(db))
		api.POST("/tunnel/start", startTunnel(db))
		api.POST("/tunnel/stop", stopTunnel(db))

		// Logs
		api.GET("/logs", queryLogs(db))
		api.GET("/logs/export", exportLogs(db))

		// Config
		api.GET("/config", getConfig())
		api.PUT("/config", updateConfig())
	}

	// WebSocket for real-time events
	api.GET("/ws/events", websocketHandler())

	// Serve dashboard static files
	r.Static("/", "./dashboard/dist")
	r.NoRoute(func(c *gin.Context) {
		c.File("./dashboard/dist/index.html")
	})

	// Start server
	log.Println("Aegis Manager starting on :8443")
	if err := r.RunTLS(":8443", "/etc/aegis/certs/manager.crt", "/etc/aegis/certs/manager.key"); err != nil {
		log.Fatal("Failed to start server:", err)
	}
}
```

---

### 4.6 Dashboard (React + Vite)

```typescript
// dashboard/src/App.tsx

import { BrowserRouter, Routes, Route } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { ThemeProvider } from './contexts/ThemeContext';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import Firewall from './pages/Firewall';
import Waf from './pages/Waf';
import Tunnel from './pages/Tunnel';
import Logs from './pages/Logs';
import Settings from './pages/Settings';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      refetchInterval: 5000, // Auto-refresh every 5s
      staleTime: 3000,
    },
  },
});

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <ThemeProvider>
        <BrowserRouter>
          <Layout>
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/firewall" element={<Firewall />} />
              <Route path="/waf" element={<Waf />} />
              <Route path="/tunnel" element={<Tunnel />} />
              <Route path="/logs" element={<Logs />} />
              <Route path="/settings" element={<Settings />} />
            </Routes>
          </Layout>
        </BrowserRouter>
      </ThemeProvider>
    </QueryClientProvider>
  );
}

export default App;
```

---

### 4.7 CLI (aegis-cli)

```go
// cli/cmd/aegis-cli/main.go

package main

import (
	"fmt"
	"os"
	"github.com/spf13/cobra"
)

var rootCmd = &cobra.Command{
	Use:   "aegis-cli",
	Short: "Aegis Security Platform CLI",
	Long:  `Command line interface for managing Aegis security platform.`,
}

func init() {
	rootCmd.AddCommand(statusCmd)
	rootCmd.AddCommand(logsCmd)
	rootCmd.AddCommand(blockCmd)
	rootCmd.AddCommand(unblockCmd)
	rootCmd.AddCommand(reloadCmd)
	rootCmd.AddCommand(configCmd)
}

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Show Aegis system status",
	Run: func(cmd *cobra.Command, args []string) {
		client := NewAPIClient()
		status, err := client.GetStatus()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

		fmt.Println("🛡️  Aegis Security Platform")
		fmt.Println("═══════════════════════════════════════")
		fmt.Printf("Version:    %s\n", status.Version)
		fmt.Printf("Uptime:     %s\n", status.Uptime)
		fmt.Println()
		fmt.Println("Services:")
		for _, svc := range status.Services {
			icon := "🟢"
			if svc.Status != "running" {
				icon = "🔴"
			}
			fmt.Printf("  %s %s: %s (PID: %d)\n", icon, svc.Name, svc.Status, svc.PID)
		}
		fmt.Println()
		fmt.Println("Stats:")
		fmt.Printf("  Packets blocked today: %d\n", status.Stats.BlockedToday)
		fmt.Printf("  WAF blocks today:      %d\n", status.Stats.WafBlockedToday)
		fmt.Printf("  Active connections:    %d\n", status.Stats.ActiveConnections)
	},
}

var logsCmd = &cobra.Command{
	Use:   "logs [module]",
	Short: "View logs",
	Args:  cobra.MaximumNArgs(1),
	Run: func(cmd *cobra.Command, args []string) {
		module := "all"
		if len(args) > 0 {
			module = args[0]
		}

		tail, _ := cmd.Flags().GetInt("tail")
		follow, _ := cmd.Flags().GetBool("follow")

		client := NewAPIClient()
		logs, err := client.GetLogs(module, tail, follow)
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}

		for _, log := range logs {
			fmt.Printf("[%s] %s: %s\n", log.Timestamp, log.Level, log.Message)
		}
	},
}

func main() {
	if err := rootCmd.Execute(); err != nil {
		fmt.Fprintf(os.Stderr, "Error: %v\n", err)
		os.Exit(1)
	}
}
```

---

## 5. Configuration

### 5.1 Agent Config: `/etc/aegis/config.toml`

```toml
# Aegis Agent Configuration
# Place this file on each protected server

[agent]
id = "auto"                    # Auto-generate UUID on first run
version = "1.0.0"
log_level = "info"
log_dir = "/var/log/aegis"
data_dir = "/var/lib/aegis"

[manager]
# Manager address (can be same server or remote)
address = "https://127.0.0.1:8443"
api_key = ""                   # Generated on first registration
heartbeat_interval = 30        # seconds
reconnect_interval = 10        # seconds

[firewall]
enabled = true
mode = "auto"                  # auto | xdp | tc
interface = "eth0"

# Blocklist settings
blocklist_ttl = 86400          # 24 hours auto-expire
blocklist_max_size = 10000

# Rate limiting
rate_limit_default = 100       # packets/sec per IP
rate_limit_burst = 20

# GeoIP
geoip_enabled = true
geoip_db_path = "/var/lib/aegis/GeoLite2-Country.mmdb"
geoip_block_countries = ["CN", "RU", "KP", "IR"]

# Port scan detection
port_scan_enabled = true
syn_threshold = 100            # SYN packets/sec
port_scan_threshold = 10       # unique ports/min

# DNS tunnel detection
dns_tunnel_enabled = true
dns_max_query_length = 100
dns_max_queries_per_minute = 60
dns_entropy_threshold = 4.0

# DDoS mitigation
ddos_enabled = true
ddos_syn_cookie_threshold = 1000
ddos_auto_block = true

[waf]
enabled = true
bind_http = "0.0.0.0:80"
bind_https = "0.0.0.0:443"
tls_enabled = true
tls_cert_dir = "/etc/aegis/certs"

# Default rate limiting
requests_per_minute = 100
burst = 20
block_duration = 300           # 5 minutes

# Rule settings
builtin_rules_enabled = true
custom_rules_dir = "/etc/aegis/waf/rules"

# Virtual hosts directory
vhosts_dir = "/etc/aegis/waf/vhosts.d"

[tunnel]
enabled = false                # Enable when ready
cloudflare_token = ""          # Set via UI or env var
tunnel_name = "aegis-tunnel"
metrics_port = 45678

[tunnel.origin_protection]
enabled = true
allow_direct_ip = false
allowed_ips = ["127.0.0.1"]

[watchdog]
enabled = true
check_interval = 10            # seconds
max_restarts = 5               # per hour
restart_delay = 5              # seconds

[watchdog.services]
aegis-xdp = true
aegis-waf = true
aegis-tunnel = false           # Optional
```

### 5.2 Manager Config: `/etc/aegis/manager.toml`

```toml
# Aegis Manager Configuration
# Only needed if running manager separately

[manager]
bind = "0.0.0.0:8443"
tls_cert = "/etc/aegis/certs/manager.crt"
tls_key = "/etc/aegis/certs/manager.key"

# Dashboard
dashboard_enabled = true
dashboard_path = "/usr/share/aegis/dashboard"

# Database
db_path = "/var/lib/aegis/manager.db"

# Alerting
[alerts]
discord_webhook = ""
email_smtp = ""
email_from = ""
email_to = []

# Retention
[retention]
event_logs_days = 90
connection_logs_days = 30
blocked_ips_days = 365
```

---

## 6. Database Schema

```sql
-- Agent registration
CREATE TABLE agents (
    id TEXT PRIMARY KEY,
    name TEXT,
    hostname TEXT NOT NULL,
    ip_address TEXT,
    version TEXT,
    status TEXT CHECK(status IN ('online', 'offline', 'error')),
    last_heartbeat DATETIME,
    registered_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    metadata TEXT  -- JSON
);

-- Firewall events
CREATE TABLE firewall_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT REFERENCES agents(id),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    action TEXT CHECK(action IN ('DROP', 'PASS', 'RATE_LIMIT')),
    src_ip TEXT NOT NULL,
    dst_ip TEXT,
    src_port INTEGER,
    dst_port INTEGER,
    protocol TEXT,
    reason TEXT,
    country TEXT,
    packet_size INTEGER,
    interface TEXT
);

-- WAF events
CREATE TABLE waf_events (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT REFERENCES agents(id),
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
    response_status INTEGER,
    response_time_ms INTEGER
);

-- Blocked IPs
CREATE TABLE blocked_ips (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT REFERENCES agents(id),
    ip TEXT NOT NULL,
    first_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    last_seen DATETIME DEFAULT CURRENT_TIMESTAMP,
    block_count INTEGER DEFAULT 1,
    reason TEXT,
    country TEXT,
    expires_at DATETIME,
    source TEXT CHECK(source IN ('FIREWALL', 'WAF', 'MANUAL', 'AUTO')),
    UNIQUE(agent_id, ip)
);

-- Virtual hosts
CREATE TABLE virtual_hosts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT REFERENCES agents(id),
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
    agent_id TEXT REFERENCES agents(id),
    rule_id TEXT NOT NULL,
    name TEXT NOT NULL,
    phase TEXT,
    pattern TEXT NOT NULL,
    action TEXT,
    severity TEXT,
    enabled BOOLEAN DEFAULT 1,
    hit_count INTEGER DEFAULT 0,
    last_hit DATETIME,
    UNIQUE(agent_id, rule_id)
);

-- Tunnel status
CREATE TABLE tunnel_status (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT REFERENCES agents(id),
    tunnel_id TEXT NOT NULL,
    status TEXT,
    started_at DATETIME,
    last_heartbeat DATETIME,
    bytes_in INTEGER DEFAULT 0,
    bytes_out INTEGER DEFAULT 0,
    errors INTEGER DEFAULT 0
);

-- System alerts
CREATE TABLE alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    agent_id TEXT REFERENCES agents(id),
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    severity TEXT CHECK(severity IN ('info', 'warning', 'critical')),
    category TEXT,
    message TEXT,
    acknowledged BOOLEAN DEFAULT 0
);

-- Indexes
CREATE INDEX idx_fw_time ON firewall_events(timestamp);
CREATE INDEX idx_fw_agent ON firewall_events(agent_id);
CREATE INDEX idx_fw_src_ip ON firewall_events(src_ip);
CREATE INDEX idx_waf_time ON waf_events(timestamp);
CREATE INDEX idx_waf_agent ON waf_events(agent_id);
CREATE INDEX idx_blocked_agent_ip ON blocked_ips(agent_id, ip);
CREATE INDEX idx_alerts_time ON alerts(timestamp);
```

---

## 7. Development Workflow (WSL2)

### 7.1 Daily Development Flow

```bash
# 1. Open WSL2 terminal
cd ~/projects/aegis

# 2. Start dev environment
docker-compose -f docker-compose.dev.yml up -d
# This starts: PostgreSQL (optional), Redis (optional), mock manager

# 3. Open VS Code
# Install "Remote - WSL" extension
code .
# VS Code opens with WSL2 as remote

# 4. Terminal 1: Rust development
cargo watch -x 'build --features tc'
# Auto-recompile on file change

# 5. Terminal 2: Go development
cd manager/
go run ./cmd/aegis-manager
# Auto-restart on file change (air tool)

# 6. Terminal 3: Dashboard
cd dashboard/
npm run dev
# Vite dev server with hot reload

# 7. Test eBPF (TC mode)
sudo ./target/debug/aegis-xdp --config config/dev.toml --features tc

# 8. Test WAF
curl -H "Host: test.local" http://localhost:8080/
# Should forward to upstream

curl -H "Host: test.local" -d "union select * from users" http://localhost:8080/
# Should block with SQLI-001
```

### 7.2 Testing on VPS

```bash
# 1. Push code
git push origin main

# 2. CI/CD builds release binary
# GitHub Actions: .github/workflows/release.yml

# 3. Download latest release on VPS
ssh user@vps-ip
wget https://github.com/yourname/aegis/releases/latest/download/aegis-linux-amd64.tar.gz
tar xzf aegis-linux-amd64.tar.gz
sudo ./install.sh

# 4. Test XDP mode (production)
sudo aegis-xdp --config /etc/aegis/config.toml --features xdp

# 5. Verify with real traffic
# From another machine:
nmap -sS vps-ip
# Should see blocked in Aegis dashboard
```

### 7.3 Debugging eBPF

```bash
# Check eBPF programs loaded
sudo bpftool prog list

# Check eBPF maps
sudo bpftool map list
sudo bpftool map dump id <map_id>

# Trace eBPF programs
sudo cat /sys/kernel/debug/tracing/trace_pipe

# Check kernel messages
sudo dmesg | grep -i bpf

# Verify XDP attachment
ip link show dev eth0
# Should show: xdpobjid <id>

# TC specific
sudo tc filter show dev eth0 ingress
sudo tc qdisc show dev eth0
```

---

## 8. Deployment

### 8.1 Single Server (All-in-One)

```bash
# Install script
#!/bin/bash
set -e

echo "🛡️  Installing Aegis Security Platform..."

# Create user
sudo useradd -r -s /bin/false aegis || true

# Create directories
sudo mkdir -p /etc/aegis/{certs,waf/rules,waf/vhosts.d}
sudo mkdir -p /var/lib/aegis
sudo mkdir -p /var/log/aegis
sudo mkdir -p /var/run/aegis

# Download binaries
ARCH=$(uname -m)
VERSION="${1:-latest}"
BASE_URL="https://github.com/yourname/aegis/releases/download/$VERSION"

curl -L "$BASE_URL/aegis-xdp-$ARCH" -o /tmp/aegis-xdp
curl -L "$BASE_URL/aegis-waf-$ARCH" -o /tmp/aegis-waf
curl -L "$BASE_URL/aegis-tunnel-$ARCH" -o /tmp/aegis-tunnel
curl -L "$BASE_URL/aegis-agent-$ARCH" -o /tmp/aegis-agent
curl -L "$BASE_URL/aegis-manager-$ARCH" -o /tmp/aegis-manager
curl -L "$BASE_URL/aegis-cli-$ARCH" -o /tmp/aegis-cli

# Install
sudo install -m 755 /tmp/aegis-* /usr/local/bin/

# Install systemd services
sudo tee /etc/systemd/system/aegis-xdp.service > /dev/null <<EOF
[Unit]
Description=Aegis eBPF Firewall
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/aegis-xdp --config /etc/aegis/config.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/aegis-waf.service > /dev/null <<EOF
[Unit]
Description=Aegis WAF
After=network.target

[Service]
Type=simple
User=aegis
Group=aegis
ExecStart=/usr/local/bin/aegis-waf --config /etc/aegis/config.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/aegis-manager.service > /dev/null <<EOF
[Unit]
Description=Aegis Manager
After=network.target

[Service]
Type=simple
User=aegis
ExecStart=/usr/local/bin/aegis-manager --config /etc/aegis/manager.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo tee /etc/systemd/system/aegis-agent.service > /dev/null <<EOF
[Unit]
Description=Aegis Agent Reporter
After=aegis-xdp.service aegis-waf.service

[Service]
Type=simple
User=aegis
ExecStart=/usr/local/bin/aegis-agent --config /etc/aegis/config.toml
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# Reload and enable
sudo systemctl daemon-reload
sudo systemctl enable aegis-xdp aegis-waf aegis-manager aegis-agent

# Generate default config if not exists
if [ ! -f /etc/aegis/config.toml ]; then
    sudo aegis-cli init-config
fi

# Generate certificates
sudo aegis-cli generate-certs

echo "✅ Aegis installed successfully!"
echo ""
echo "Start services: sudo systemctl start aegis-xdp aegis-waf aegis-manager"
echo "Check status:   sudo aegis-cli status"
echo "Dashboard:      https://$(hostname -I | awk '{print $1}'):8443"
```

---

## 9. Threat Defense Matrix

| Threat                   | Defense Layer | Mechanism                        | Status  |
| ------------------------ | ------------- | -------------------------------- | ------- |
| **Port Scan**            | eBPF XDP/TC   | SYN flood detection, port sweep  | ✅ v1.0 |
| **SQL Injection**        | WAF           | Regex pattern matching           | ✅ v1.0 |
| **XSS**                  | WAF           | Script tag, event handler filter | ✅ v1.0 |
| **LFI/RFI**              | WAF           | Path traversal patterns          | ✅ v1.0 |
| **RCE**                  | WAF           | Command injection patterns       | ✅ v1.0 |
| **SSRF**                 | WAF           | Internal IP block                | ✅ v1.0 |
| **DDoS Volumetric**      | eBPF XDP      | Rate limit, SYN cookie           | ✅ v1.0 |
| **DDoS Application**     | WAF           | Per-path rate limit              | ✅ v1.0 |
| **DNS Tunneling**        | eBPF          | Query length, entropy heuristic  | ✅ v1.0 |
| **Brute Force**          | WAF + eBPF    | Progressive delay, IP block      | ✅ v1.0 |
| **Bad Bot**              | WAF           | User-Agent filter                | ✅ v1.0 |
| **Direct IP Access**     | Tunnel        | Origin protection                | ✅ v1.0 |
| **Service Crash**        | Watchdog      | Auto-restart                     | ✅ v1.0 |
| **GeoIP Block**          | eBPF          | Country-based filtering          | ✅ v1.0 |
| **IP Reputation**        | Shared        | Blocklist sync                   | ✅ v1.0 |
| **File Integrity**       | Agent         | FIM module                       | 🔄 v1.1 |
| **Container Security**   | Agent         | Docker/Podman monitor            | 🔄 v1.2 |
| **AI Anomaly Detection** | Manager       | ML-based detection               | 🔄 v1.3 |
| **Purple Team**          | Manager       | Self-attack simulation           | 🔄 v1.4 |
| **WireGuard VPN**        | Tunnel        | Admin access VPN                 | 🔄 v1.5 |

---

## 10. Success Metrics

| Metric             | Target          | Measurement            |
| ------------------ | --------------- | ---------------------- |
| **Install Time**   | < 5 minutes     | Fresh Ubuntu 22.04 VM  |
| **First Block**    | < 2 minutes     | Default rules active   |
| **XDP Latency**    | < 1μs           | `bpftool prog profile` |
| **TC Latency**     | < 10μs          | `bpftool prog profile` |
| **WAF Latency**    | < 5ms           | `wrk` benchmark        |
| **Throughput**     | 10K req/sec     | `wrk -t4 -c1000`       |
| **Uptime**         | > 99%           | 30-day test            |
| **Memory**         | < 200MB total   | `ps aux`               |
| **CPU Idle**       | < 5%            | `htop`                 |
| **Dashboard Load** | < 3 seconds     | Browser dev tools      |
| **GitHub Stars**   | 100+ (3 months) | GitHub metrics         |

---

## 11. Future Roadmap

| Version | Feature                                                  | ETA        |
| ------- | -------------------------------------------------------- | ---------- |
| v1.0    | Network Defense Core (XDP/TC + WAF + Tunnel + Dashboard) | Month 3    |
| v1.1    | File Integrity Monitoring (FIM)                          | +1 month   |
| v1.2    | Container Security (Docker/Podman)                       | +2 months  |
| v1.3    | AI Anomaly Detection (Python ML service)                 | +3 months  |
| v1.4    | Purple Team Module (self-attack simulation)              | +4 months  |
| v1.5    | Multi-Agent + WireGuard VPN                              | +5 months  |
| v2.0    | Windows Agent (ETW)                                      | +8 months  |
| v2.1    | macOS Agent (DTrace)                                     | +10 months |
| v2.2    | Enterprise Features (RBAC, SSO, SIEM integration)        | +12 months |

---

## 12. Appendices

### A. WSL2 Kernel Update (if needed)

```bash
# Check current kernel
uname -r
# Need 5.15+ for eBPF

# Update WSL2 kernel
wsl --update

# Or build custom kernel with eBPF support
git clone https://github.com/microsoft/WSL2-Linux-Kernel.git
cd WSL2-Linux-Kernel
# Follow Microsoft docs for custom kernel build
```

### B. VPS Recommendations

| Provider         | Instance      | Price    | Specs           | Best For             |
| ---------------- | ------------- | -------- | --------------- | -------------------- |
| **Hetzner**      | CX21          | €5.35/mo | 2 vCPU, 4GB RAM | Development, testing |
| **DigitalOcean** | Basic Droplet | $6/mo    | 1 vCPU, 1GB RAM | Minimal testing      |
| **AWS**          | t3.small      | ~$15/mo  | 2 vCPU, 2GB RAM | Production-like      |
| **Linode**       | Nanode 1GB    | $5/mo    | 1 vCPU, 1GB RAM | Budget testing       |

### C. Useful Commands

```bash
# Build all Rust crates
cargo build --workspace --features tc

# Build release
cargo build --workspace --features xdp --release

# Run tests
cargo test --workspace

# Format code
cargo fmt

# Lint
cargo clippy --workspace

# Build Go manager
cd manager/
go build -o aegis-manager ./cmd/aegis-manager

# Build CLI
cd cli/
go build -o aegis-cli ./cmd/aegis-cli

# Build dashboard
cd dashboard/
npm run build

# Run e2e tests
docker-compose -f docker-compose.test.yml up --abort-on-container-exit
```

---

_Document Version: 1.0-WSL2_  
_Last Updated: 2026-06-16_  
_Author: Aegis Team_  
_Status: Final — Ready for Implementation_
