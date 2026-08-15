---
title: "Podman Networking UFW"
tags:
  - devops
  - podman
  - networking
  - firewall
  - container
aliases:
  - "Podman Network + UFW Routing"
  - "Container Firewall Rules"
created: "2026-07-11"
updated: "2026-07-11"
status: pending
cssclasses: ""
---

# 🐳 Podman Networking & UFW Integration

> **Filosofi:** Podman is daemonless — gak ada Docker daemon yang nanganin networking buat lu. UFW + Podman butuh route allow manual. Kalau cuma `ufw enable`, container lu gak bisa akses internet dan dari luar gak bisa masuk.

---

## Podman Network Architecture

```
┌──────────┐    eth0 (host)    ┌──────────┐
│  Client   │◀──────────────▶│   Host    │
└──────────┘                  └────┬─────┘
                                   │
                           podman0 bridge
                                   │
              ┌────────────────────┼────┐
              ▼                    ▼    ▼
        ┌──────────┐         ┌──────────┐
        │ Container │         │ Container │
        │ :11080    │         │ :5432     │
        └──────────┘         └──────────┘
```

| Network Mode | IP Access | Port Mapping | Use Case |
|-------------|-----------|-------------|----------|
| **bridge** (default) | Container punya IP sendiri | `-p HostPort:ContainerPort` | Isolasi antar container |
| **host** | Container pake IP host | Port langsung expose | Performance critical, gak butuh isolasi |
| **macvlan** | IP dari subnet fisik | Langsung ke LAN | Container sebagai "device" sendiri |
| **none** | Loopback-only | Gak ada | Testing/isolasi total |

---

## UFW + Podman — The Correct Pattern

> [!danger] Jangan lakukan ini
> `ufw enable` langsung tanpa routing rule → **container gak bisa akses internet**. Forward policy default adalah DROP.

### Step-by-step:

```bash
# 1. Aktifkan UFW + default deny incoming
ufw default deny incoming
ufw default allow outgoing

# 2. Izinkan SSH dulu (sebelum enable!)
ufw allow ssh

# 3. Enable UFW
ufw enable

# 4. ⚠️ Krusial: izinkan forward dari eth0 ke podman bridge
ufw route allow in on eth0 out on podman0 to any port 80 proto tcp
ufw route allow in on eth0 out on podman0 to any port 443 proto tcp
ufw route allow in on eth0 out on podman0 to any port 5432 proto tcp
# dst — satu rule per container port yang perlu diakses dari luar

# 5. Pastikan IP forwarding ON
sysctl net.ipv4.ip_forward=1
# Persisten: echo "net.ipv4.ip_forward=1" >> /etc/sysctl.d/99-podman.conf
```

### Port Mapping Logic

```
          ┌──────────────────────────────────┐
          │          Host port :8080         │
          │   ufw allow 8080/tcp             │
          │   ufw route allow ... to 8080    │
          │                                  │
          │   podman run -p 8080:3000 app    │
          │                                  │
          ▼                                  ▼
    External client ───────────▶ Container app (:3000)
```

| Yang Dibutuhkan | Command |
|----------------|---------|
| Buka port di host | `ufw allow 8080/tcp` |
| Route ke container | `ufw route allow in on eth0 out on podman0 to any port 8080 proto tcp` |
| Jalankan container | `podman run -p 8080:3000 app` |

---

## Podman Network Commands

```bash
# List networks
podman network ls

# Inspect bridge
podman network inspect podman0
# → lihat subnet, gateway, containers terhubung

# Buat network custom (berguna untuk multi-container)
podman network create frontend --subnet 10.89.0.0/24

# Jalankan container di network tertentu
podman run --network frontend --name web -d nginx

# Hubungkan container ke network
podman network connect frontend web
```

---

## Common Failures

| Gejala | Penyebab | Fix |
|--------|----------|-----|
| Container bisa akses internet, tapi port gak bisa diakses dari luar | Kurang `ufw route allow` | Tambah rule route allow |
| `ufw enable` bikin SSH drop | Lupa `ufw allow ssh` sebelum enable | Console/VNC, `ufw allow ssh` |
| Container gak bisa resolve DNS | DNS resolver blokir | `ufw allow out on podman0 to any port 53 proto udp` |
| Port conflict | 2 container pake host port sama | Ganti port mapping `-p 8081:3000` |
| Podman default network gak ada | Rootless podman | Rootless pake slirp4netns, beda behavior |

---

## Rootless vs Rootful Podman

| Aspek | Rootful (`sudo podman`) | Rootless (`podman`) |
|-------|------------------------|---------------------|
| **Port binding** | Bisa <1024 | >1024 (via `net.ipv4.ip_unprivileged_port_start`) |
| **Network** | Bridge (podman0) | slirp4netns (NAT) |
| **Volume mount** | Bebas | Terbatas (user namespace) |
| **UFW routing** | `ufw route allow` works | Lebih kompleks (pakai `-p`) |
| **Use case** | Production / system containers | Development / user apps |

---

---

## 🧠 Berpikir — Metodologi Penyusunan Catatan

Catatan ini disusun melalui proses berpikir terstruktur sebagai berikut:

### 1. Thinking Type yang Digunakan

| Type | Kenapa | Bagian |
|------|--------|--------|
| **Analytical Thinking** | Memecah arsitektur Podman network jadi 4 mode (bridge, host, macvlan, none) + menganalisis mengapa UFW perlu route allow terpisah | Network Architecture, Rootless vs Rootful |
| **Systems Thinking** | Memetakan jalur traffic: client → eth0 → UFW → podman0 bridge → container; cascade failure kalau satu link missing | UFW + Podman Pattern, Port Mapping Logic |
| **Concrete Thinking** | Step-by-step command untuk UFW routing — urutan penting (SSH dulu!). Exact syntax yang bisa di-copy | Step-by-step, Commands |
| **Critical Thinking** | Mengapa `ufw enable` langsung tanpa route allow bikin container mati? Forward policy default DROP — ini jarang diketahui | Peringatan Danger |

### 2. Background Knowledge (Pra-Penulisan)

- **Podman daemonless architecture**: gak pake dockerd — network management ada di `cni-plugins` atau `netavark`
- **iptables forward chain**: UFW manage ini via `ufw-before-forward` chain, route allow add rule ke FORWARD policy
- **Contabo double firewall trap**: pengalaman langsung — UFW allow SSH tapi masih timeout karena hypervisor firewall di panel Contabo blokir duluan
- **Rootless slirp4netns**: user-mode networking — traffic keluar via TAP device, bukan bridge, jadi UFW route allow gak works
- **Persistent IP forwarding**: sysctl setting ilang setelah reboot tanpa `/etc/sysctl.d/`

### 3. RAG Vault — Dokumen yang Dikonsultasi

| Dokumen | Kontribusi |
|---------|-----------|
| [[cicd-guide\|CI/CD Pipeline Guide]] | Container deployment context, environment yang perlu expose |
| [[devops\|DevOps Roadmap]] | Docker vs Podman positioning, container skill progression |
| [[infrastructure-administrator\|Infrastructure Administrator]] | Server layout — di folder mana container jalan |
| [[cloud-infrastructure\|Infrastruktur Cloud]] | Container orchestration scale, network isolation |

### 4. Sintesis — Bagaimana Bagian Bergabung

```
Background Knowledge (Podman architecture + UFW internals)
    │
    ▼
RAG Vault (konteks deployment existing)
    │
    ▼
Analytical:  Network modes → compare bridge vs host vs macvlan
    │
    ▼
Systems:     Traffic flow → UFW → bridge → container → cascade failure points
    │
    ▼
Concrete:    Step-by-step routing commands → exact syntax
    │
    ▼
Critical:    Pitfalls → double firewall, rootless limitation, lost on reboot
```

### 5. Sequential Thinking Steps

```
Thought 1 (Cognitive):   "Podman is daemonless. Gak ada dockerd yg manage iptables automatically."
Thought 2 (Analytical):  "Ada 4 network mode. Bridge default, host buat perf, macvlan buat LAN, none buat isolasi."
Thought 3 (Systems):     "Traffic: client → eth0 → ufw INPUT → FORWARD (kena DROP) → podman0 → container."
                          "Break at FORWARD = no internet for containers."
Thought 4 (Critical):    "UFW default forward policy = DROP. Ini yg bikin container mati setelah ufw enable."
Thought 5 (Concrete):    "Fix: ufw route allow in on eth0 out on podman0 to any port X proto tcp."
Thought 6 (Analytical):  "Rootless vs rootful: rootless pake slirp4netns, route allow gak works."
Thought 7 (Systems):     "Cascade: UFW enable → SSH lupa diallow → lockout. Solusi: console/VNC."
```

---

## 🔗 Lihat Juga

- [[cicd-guide|CI/CD Pipeline Guide]] — Container deployment
- [[devops|DevOps Roadmap]] — Docker vs Podman context
- [[infrastructure-administrator|Infrastructure Administrator]] — Server layout
- [[cloud-infrastructure|Infrastruktur Cloud]] — Container orchestration scale
---

audited
---
