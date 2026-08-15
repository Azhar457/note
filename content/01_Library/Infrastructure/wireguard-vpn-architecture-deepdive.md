---
title: "WireGuard & VPN Architecture — Protocol Internals, Noise_IK, Kernel vs Userspace, Site-to-Site Routing"
tags:
  - infrastructure
  - vpn
  - wireguard
  - networking
  - cryptography
  - library
aliases:
  - "WireGuard Deep Dive"
  - "VPN Protocol Internals"
created: "2026-07-28"
updated: "2026-07-28"
status: pending
cssclasses:
  - wide-table
---

> [!info] Ringkasan
> WireGuard adalah protokol VPN modern yang dirancang dengan prinsip minimalis: hanya ~4.000 baris kode vs OpenVPN ~600.000 baris. Keamanannya berasal dari kriptografi modern (Noise_IK, Curve25519, BLAKE2, ChaCha20Poly1305) dan attack surface yang diminimalkan. Catatan ini membahas protocol internals, handshake flow, kernel vs userspace implementation, routing & allowed-ips, multi-hop, serta perbandingan performa dengan OpenVPN/IPsec.

**Domain Terkait:** [[networking-fundamentals-tcpip-bgp]] (fondasi network) → [[linux-hardening-cis]] (hardening) → [[homelab-security-architecture-synthesis]] (infrastruktur) → [[dns-fundamentals-bind9]] (DNS) → [[podman-networking-ufw]] (firewall) → [[tls-ssl-deepdive]] (perbandingan crypto)

---

## Daftar Isi
- [[#1. Filosofi Desain WireGuard]]
- [[#2. Cryptographic Primitives — Noise_IK]]
- [[#3. Handshake Flow]]
- [[#4. Data Plane Encryption]]
- [[#5. Kernel vs Userspace Implementation]]
- [[#6. Routing & Allowed-IPs]]
- [[#7. Multi-Hop & Site-to-Site]]
- [[#8. NAT Traversal & Roaming]]
- [[#9. Performance Benchmark]]
- [[#10. MTU/MSS Considerations]]
- [[#11. Deploy Guide]]
- [[#12. Keamanan & Auditing]]
- [[#13. Referensi]]

---

## 1. Filosofi Desain WireGuard

WireGuard (Jason A. Donenfeld, 2015-2020) hadir karena frustrasi dengan VPN existing:

| Aspek | OpenVPN | IPsec | WireGuard |
|---|---|---|---|
| **Kode** | ~600.000 baris | ~400.000 baris | ~4.000 baris |
| **Crypto** | OpenSSL (ribuan opsi) | Complex IKE | Noise_IK (fixed) |
| **Handshake** | TLS + auth | IKEv1/v2 (6-9 msg) | 1-RTT (3 msg) |
| **Key rotation** | Manual | Complex | Automatic (perfect forward secrecy) |
| **Roaming** | ❌ | ❌ | ✅ Native |
| **Kernel integration** | Via tun | Via tun/ipsec | ✅ In-kernel (wg) |

**Prinsip:** Setiap opsi adalah attack surface. Tidak ada pilihan cipher, algoritma, atau mode — semuanya fixed.

---

## 2. Cryptographic Primitives — Noise_IK

WireGuard menggunakan protokol **Noise_IK** (Noise Protocol Framework — initiator/pre-known static key). Satu pattern: `Noise_IK_25519_ChaChaPoly_BLAKE2s`.

| Primitive | Fungsi | Alasan |
|---|---|---|
| **Curve25519** | Key exchange (ECDH) | Side-channel resistant, konstanta-time |
| **ChaCha20Poly1305** | AEAD encryption | Cepat di CPU tanpa AES-NI |
| **BLAKE2s** | Hashing | Hash cepat, built-in keying |
| **HKDF (BLAKE2s)** | Key derivation | Extract-expand dari DH result |

**Mengapa ChaCha20 bukan AES?** ChaCha20 adalah ARX cipher (add-rotate-xor) yang tidak butuh hardware AES-NI. Performa konsisten di semua CPU, termasuk ARM dan embedded.

### Pre-shared Keys (PSK) Opsional

```ini
[Interface]
PrivateKey = base64
ListenPort = 51820

[Peer]
PublicKey = base64
PresharedKey = base64  # Opsional — anti-quantum layer
AllowedIPs = 10.0.0.0/24
```

PSK menambahkan lapisan symmetric encryption di luar Curve25519. Berguna sebagai defense terhadap quantum computer (Grover's algorithm).

---

## 3. Handshake Flow

WireGuard menggunakan **1-RTT handshake** (3 messages):

```
Initiator (Client)            Responder (Server)
      │                              │
      │  Msg 1: Initiation           │
      │  - Static public key (encrypted) │
      │  - Ephemeral public key       │
      │  - Timestamp (anti-replay)    │
      ├─────────────────────────────▶│
      │                              │
      │  Msg 2: Response             │
      │  - Static public key (encrypted) │
      │  - Ephemeral public key       │
      │  - Encrypted empty transport  │
      │◄─────────────────────────────┤
      │                              │
      │  Msg 3: Cookie (if needed)   │
      │  - Anti-DoS cookie           │
      ├─────────────────────────────▶│
      │                              │
      │  ←─── Session established ──→│
      │  Transport key derived       │
      │  (Perfect Forward Secrecy)   │
```

### Key Derivation (KDF Chain)

```
static_static = DH(init_static, resp_static)      # Long-term auth
ephemeral_remote = DH(init_ephemeral, resp_static) # ECDH
static_remote = DH(init_static, resp_ephemeral)    # ECDH
ephemeral_ephemeral = DH(init_ephemeral, resp_ephemeral) # PFS

# Mix via HKDF chain → session key
```

### Re-keying

Setiap **120 detik** atau setelah **2^64 paket**, WireGuard melakukan re-handshake otomatis. Ini memberikan Perfect Forward Secrecy: jika kunci jangka panjang bocor, session key tidak bisa di-decrypt.

---

## 4. Data Plane Encryption

Setelah handshake, data di-enkripsi dengan ChaCha20Poly1305:

```
┌─────────────────────────────────────────────┐
│                 WireGuard Packet             │
├────────────┬──────────┬──────────┬───────────┤
│ Type (4B)  │ Reserved │ Session │ Counter   │
│            │ (4B)     │  ID (8B) │ (8B)      │
├────────────┴──────────┴──────────┴───────────┤
│ Encrypted Payload (ChaCha20Poly1305 AEAD)     │
│  - Inner IP packet                           │
│  - Padding (opsional)                        │
├──────────────────────────────────────────────┤
│ Poly1305 MAC tag (16B)                       │
└──────────────────────────────────────────────┘
```

**Counter-based:** Setiap packet punya counter monotonic → mencegah replay attack. Counter di-reset saat re-key.

---

## 5. Kernel vs Userspace Implementation

### Kernel Module (`wg`)

```
Packet flow: Network → wg module → ChaCha20 (kernel crypto) → tun → userspace
                      ↓
                  Zero-copy di kernel
                      ↓
              Performa ~ linier dengan CPU
```

**Keunggulan:**
- Latensi lebih rendah (skip context switch)
- Throughput lebih tinggi (zero-copy)
- Integrasi dengan network stack kernel

**Instalasi:**
```bash
# Kernel module sudah built-in di Linux 5.6+
modprobe wireguard
# Cek
lsmod | grep wireguard
```

### Userspace (`boringtun` — Cloudflare)

```
Packet flow: Network → tun → userspace (boringtun) → ChaCha20 → userspace lagi
```

**Keunggulan:**
- Cross-platform (Windows, macOS, BSD)
- Update tanpa reboot
- Sandboxing lebih mudah
- Debug lebih mudah

**Perbandingan performa:**

| Implementasi | Throughput (1Gbps) | Latensi (ms) | CPU Usage |
|---|---|---|---|
| Kernel (wg) | ~940 Mbps | 0.1-0.3 | 5-10% |
| boringtun | ~850 Mbps | 0.3-0.8 | 15-25% |
| OpenVPN (TLS) | ~400 Mbps | 1-3 | 30-50% |

---

## 6. Routing & Allowed-IPs

WireGuard tidak menggunakan routing table tradisional — ia menggunakan **AllowedIPs** sebagai routing + ACL sekaligus.

```ini
[Peer]
PublicKey = peer1_publickey
AllowedIPs = 10.0.0.2/32, 192.168.1.0/24
```

### Bagaimana AllowedIPs Bekerja

1. **Terima:** Packet dengan src IP dalam AllowedIPs diterima
2. **Kirim:** Packet dengan dst IP dalam AllowedIPs dikirim ke peer ini
3. **Route otomatis:** WireGuard menambahkan route ke table kernel

```bash
# Cek route yang dibuat WireGuard
ip route show dev wg0
# Output: 10.0.0.0/24 dev wg0 proto kernel scope link src 10.0.0.1
```

### Full Tunnel vs Split Tunnel

```ini
# Full tunnel — semua traffic via VPN
AllowedIPs = 0.0.0.0/0, ::/0

# Split tunnel — hanya subnet tertentu
AllowedIPs = 10.0.0.0/8, 172.16.0.0/12
```

---

## 7. Multi-Hop & Site-to-Site

### Multi-Hop (Bounce)

```
Client ⇄ Relay (VPS) ⇄ Office
```

Konfigurasi relay:

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = relay_private

[Peer]
# Client
PublicKey = client_public
AllowedIPs = 10.0.0.2/32

[Peer]
# Office
PublicKey = office_public
AllowedIPs = 10.0.0.3/32, 192.168.1.0/24
```

Relay harus enable IP forwarding:

```bash
sysctl -w net.ipv4.ip_forward=1
sysctl -w net.ipv6.conf.all.forwarding=1
```

### Site-to-Site

```
Site A (10.0.0.0/24) ⇄ VPS ⇄ Site B (10.0.1.0/24)
```

```ini
# Site A
[Peer]
PublicKey = site_b_public
AllowedIPs = 10.0.1.0/24, 10.0.0.0/24
Endpoint = site-b.example.com:51820
```

---

## 8. NAT Traversal & Roaming

### Native Roaming

WireGuard mendeteksi perubahan source IP/port setiap kali packet diterima. Jika client pindah jaringan (WiFi → 4G), WireGuard tetap connect tanpa handshake ulang.

```
Client @ IP A ────▶ Server
     │
     │ (pindah WiFi)
     ▼
Client @ IP B ────▶ Server
     │               │
     │ Packet tiba   │ Server update endpoint
     │ dari IP baru  │ di memory
     ◀───────────────┤
```

### Persistent Keepalive

Untuk NAT/firewall yang timeout:

```ini
[Peer]
PersistentKeepalive = 25  # detik
```

Nilai umum: `25` detik. Jangan terlalu kecil (< 10) — bisa dianggap DoS.

---

## 9. Performance Benchmark

| VPN | 1-Core Throughput | 4-Core Throughput | Latency Add | CPU/Connection |
|---|---|---|---|---|
| WireGuard | 940 Mbps | 3.8 Gbps | +0.1 ms | 1% / 1K conn |
| IPsec (AES-NI) | 800 Mbps | 3.2 Gbps | +0.3 ms | 3% / 1K conn |
| OpenVPN (AES-256) | 300 Mbps | 800 Mbps | +1.5 ms | 8% / 1K conn |
| OpenVPN (ChaCha20) | 250 Mbps | 700 Mbps | +2.0 ms | 10% / 1K conn |

WireGuard 3-10× lebih cepat dari OpenVPN untuk throughput tinggi.

---

## 10. MTU/MSS Considerations

WireGuard menambahkan 60-byte overhead per packet. Jika interface MTU = 1500:

```
Payload max = 1500 - 60 = 1440 bytes
```

**Konfigurasi:**

```ini
[Interface]
Address = 10.0.0.1/24
MTU = 1420  # Untuk ethernet tunnel
```

**MTU calculator:**

$$ \text{MTU}_{tunnel} = \text{MTU}_{link} - 80 \text{ (IPv6)} \text{ atau } - 60 \text{ (IPv4)} $$

Recomendasi tabel:

| Link Type | MTU |
|---|---|
| Ethernet (1500) | 1420 |
| PPPoE (1492) | 1412 |
| 4G/LTE (1500) | 1420 |
| IPv6 tunnel | 1400 |
| GRE tunnel | 1360 |

---

## 11. Deploy Guide

### Server

```bash
# Install
dnf install wireguard-tools  # Fedora
# atau
apt install wireguard         # Ubuntu

# Generate keys
wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key
chmod 600 /etc/wireguard/private.key

# Config /etc/wireguard/wg0.conf
```

```ini
[Interface]
Address = 10.0.0.1/24
ListenPort = 51820
PrivateKey = <server-private>
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <client-public>
AllowedIPs = 10.0.0.2/32
```

```bash
# Start
systemctl enable --now wg-quick@wg0
```

### Client

```ini
[Interface]
PrivateKey = <client-private>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server-public>
Endpoint = server.example.com:51820
AllowedIPs = 0.0.0.0/0, ::/0  # Full tunnel
PersistentKeepalive = 25
```

---

## 12. Keamanan & Auditing

### Audit Checklist

- [ ] `PrivateKey` file mode 600
- [ ] `ListenPort` tidak exposed ke publik (pakai firewall)
- [ ] `AllowedIPs` serumit mungkin — tidak 0.0.0.0/0 kecuali perlu
- [ ] Rotate keys periodik (setiap 6 bulan)
- [ ] `PresharedKey` enabled untuk sensitive link
- [ ] Firewall: hanya port 51820/UDP dari peer yang dikenal

### Firewall Config

```bash
# UFW
ufw allow in on eth0 to any port 51820 proto udp

# nftables
nft add rule inet filter input udp dport 51820 accept
nft add rule inet filter input iifname "wg0" accept
nft add rule inet filter forward iifname "wg0" oifname "eth0" accept
```

---

## 13. Referensi

- **WireGuard Whitepaper:** https://www.wireguard.com/papers/wireguard.pdf
- **Noise Protocol Framework:** https://noiseprotocol.org/noise.html
- **boringtun (Cloudflare):** https://github.com/cloudflare/boringtun
- **WireGuard Official:** https://www.wireguard.com/
- **Performance Benchmark:** https://www.wireguard.com/performance/

**Cross-link vault:**
- [[networking-fundamentals-tcpip-bgp]] — routing & network dasar
- [[linux-hardening-cis]] — OS hardening
- [[homelab-security-architecture-synthesis]] — infrastruktur
- [[dns-fundamentals-bind9]] — DNS integration
- [[podman-networking-ufw]] — firewall konfigurasi
- [[tls-ssl-deepdive]] — crypto fundamental
- [[cryptography-biometrics]] — kriptografi
---

audited
---
