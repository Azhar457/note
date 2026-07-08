---
title: "Arp Spoofing Mitigation"
tags:
  - sops
aliases:
  - "arp-spoofing-mitigation"
created: "2026-04-30"
updated: "2026-07-01"
status: active
cssclasses: ""
---

# 🛡️ Mitigasi ARP Spoofing — Defense Against Ettercap & Bettercap

> **Konteks:** Dokumen ini dibuat berdasarkan incident nyata di jaringan kampus (192.168.0.0/24) dengan attacker menggunakan tool ARP spoofing standar (kemungkinan besar Ettercap atau Bettercap). Attack vector: ARP poisoning + ICMP redirect + multicast flood (SSDP/mDNS/IGMP).

> **Filosofi:** ARP protocol dirancang tahun 1982 tanpa autentikasi. Secara desain, ARP trust-based — siapa pun bisa claim "saya gateway." Mitigasi harus layered: endpoint → switch → router → monitoring.

---

## FOTO

![[pasted-image-20260430215147-png]]

## 🎯 Attack Anatomy (Apa yang Sebenarnya Terjadi)

### Timeline Incident

| Fase                   | Waktu    | Kondisi                | Internet?          | Penjelasan                                            |
| ---------------------- | -------- | ---------------------- | ------------------ | ----------------------------------------------------- |
| **1. Recon**           | Awal     | Attacker scan network  | ✅ Normal          | Nmap/Bettercap `net.probe on`                         |
| **2. ARP Poison**      | +0 detik | Attacker claim gateway | ✅ **MASIH JALAN** | Attacker **forward traffic** — MITM aktif tapi "baik" |
| **3. ICMP Redirect**   | +X detik | Routing table diubah   | ❌ **PUTUS**       | Attacker inject ICMP Type 5 → route ke black hole     |
| **4. Multicast Flood** | Paralel  | SSDP/mDNS/IGMP flood   | ❌ **LAG + PUTUS** | Bandwidth exhaustion + CPU overload                   |

### Kenapa Internet "Awalnya Jalan" Tapi Tiba-Tiba Putus?

```
FASE 1 — ARP Poison (MITM "Baik"):
  [Kamu] ──ARP──> [Attacker 192.168.0.240] ──forward──> [Router 192.168.0.1]
  Internet: ✅ JALAN (attacker forward traffic)
  Risk: Traffic di-sniff / di-log

FASE 2 — ICMP Redirect (Black Hole):
  Attacker kirim ICMP Type 5: "Route langsung ke 192.168.0.240 aja"
  [Kamu] ──direct──> [Attacker] ──X──> [Router]
  Internet: ❌ PUTUS (attacker TIDAK forward)
  Risk: Denial of Service

FASE 3 — Multicast Flood:
  Attacker spam: 239.255.255.250 (SSDP), 224.0.0.251 (mDNS), IGMP
  Bandwidth: 🔥 HABIS
  CPU: 🔥 OVERLOAD
```

> **Insight Kritis:** Attacker tidak cuma ARP spoof. Ini adalah **layered attack**: L2 (ARP) + L3 (ICMP redirect) + L2/L3 (multicast flood). Tool yang digunakan kemungkinan **Bettercap** karena support semua vector ini dalam satu framework [^7^][^12^].

---

## 🧱 Layered Defense Matrix

### Layer 1 — Endpoint (User / Victim Host)

**Goal:** Proteksi device individual tanpa kontrol network infrastructure.

#### Step 1.1: Disable ICMP Redirect (WAJIB — Sumber Masalah Utama)

ICMP Redirect Type 5 adalah yang membuat internet putus. Disable di OS:

```powershell
# Windows (Run as Administrator)
netsh interface ipv4 set global icmpredirects=disabled
netsh interface ipv6 set global icmpredirects=disabled

# Verifikasi
netsh interface ipv4 show global
# Output harus: ICMP redirect: disabled
```

```bash
# Linux (persistent via sysctl)
sudo sysctl -w net.ipv4.conf.all.accept_redirects=0
sudo sysctl -w net.ipv4.conf.all.send_redirects=0

# Persistent (edit /etc/sysctl.conf)
echo "net.ipv4.conf.all.accept_redirects=0" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.conf.all.send_redirects=0" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```

**Kenapa ini penting:** ICMP Redirect bilang ke OS "route lewat IP lain." Attacker exploit ini untuk redirect traffic ke black hole. Disable = OS ignore redirect [^4^].

#### Step 1.2: Block ICMP Redirect di Firewall

```powershell
# Windows PowerShell (Admin)
New-NetFirewallRule -DisplayName "BLOCK_ICMP_REDIRECT_IN" `
  -Direction Inbound -Protocol ICMPv4 -IcmpType 5 `
  -Action Block -Profile Any

New-NetFirewallRule -DisplayName "BLOCK_ICMP_REDIRECT_OUT" `
  -Direction Outbound -Protocol ICMPv4 -IcmpType 5 `
  -Action Block -Profile Any
```

#### Step 1.3: Static ARP + Aggressive Binding

```powershell
# Hapus semua ARP entry
arp -d *

# Set static ARP untuk gateway (ganti dengan MAC router asli)
arp -s 192.168.0.1 3c-6a-d2-14-9e-68

# Verifikasi
arp -a
# Output: 192.168.0.1  3c-6a-d2-14-9e-68  static
```

> ⚠️ **Limitasi Windows:** Static ARP di Windows bisa di-override oleh ARP reply agresif. Ini bukan bulletproof. Kombinasikan dengan langkah lain.

#### Step 1.4: Rate Limit Multicast/Broadcast (Kurangi Flood)

```powershell
# Block SSDP (UDP 1900) — noise generator
New-NetFirewallRule -DisplayName "BLOCK_SSDP_FLOOD" `
  -Direction Inbound -Protocol UDP -LocalPort 1900 `
  -Action Block -Profile Any

# Block mDNS (UDP 5353) — discovery spam
New-NetFirewallRule -DisplayName "BLOCK_MDNS_FLOOD" `
  -Direction Inbound -Protocol UDP -LocalPort 5353 `
  -Action Block -Profile Any

# Block IGMP (protocol 2) — multicast membership
# (Via Windows Defender Firewall — advanced, custom rule)
```

#### Step 1.5: Selective Block Attacker (JANGAN Full Block)

**❌ SALAH (yang menyebabkan internet putus):**

```powershell
# JANGAN INI — block semua traffic attacker = putus karena dia gateway
New-NetFirewallRule -DisplayName "BLOCK_ATTACKER_ALL" `
  -Direction Inbound -RemoteAddress 192.168.0.240 `
  -Action Block -Protocol Any
```

**✅ BENAR (selective block, allow routing survive):**

```powershell
# Hapus rule lama dulu
Remove-NetFirewallRule -DisplayName "BLOCK_ATTACKER_IN" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "BLOCK_ATTACKER_OUT" -ErrorAction SilentlyContinue

# Block hanya UDP flood
New-NetFirewallRule -DisplayName "BLOCK_ATTACKER_UDP_FLOOD" `
  -Direction Inbound -RemoteAddress 192.168.0.240 `
  -Protocol UDP -LocalPort 1900,5353 `
  -Action Block -Profile Any

# Block ICMP redirect dari attacker
New-NetFirewallRule -DisplayName "BLOCK_ATTACKER_ICMP_REDIRECT" `
  -Direction Inbound -RemoteAddress 192.168.0.240 `
  -Protocol ICMPv4 -IcmpType 5 `
  -Action Block -Profile Any
```

#### Step 1.6: Flush Routing Table (Jika Sudah Terkena ICMP Redirect)

```powershell
# Hapus route yang di-inject attacker
route delete 0.0.0.0 mask 0.0.0.0 192.168.0.240

# Re-add route ke gateway asli
route add 0.0.0.0 mask 0.0.0.0 192.168.0.1 metric 1

# Atau restart network adapter
Disable-NetAdapter -Name "Wi-Fi" -Confirm:$false
Start-Sleep 2
Enable-NetAdapter -Name "Wi-Fi"
```

#### Step 1.7: VPN sebagai Last Resort (Encrypted Tunnel)

```powershell
# VPN tidak menghentikan ARP spoof, tapi melindungi data
# Gunakan WireGuard / OpenVPN — setup sebelum attack terjadi
# Kalau VPN gagal konek karena routing kacau → fix routing dulu (Step 1.6)
```

---

### Layer 2 — Switch / Network Infrastructure (Admin Router/Kampus)

**Goal:** Menghentikan attack di sumbernya. Ini memerlukan kontrol switch/router.

#### Step 2.1: Dynamic ARP Inspection (DAI) — GOLD STANDARD

DAI adalah fitur Cisco switch yang intercept & validate semua ARP packet [^4^][^11^][^13^].

```cisco
! Step 1: Enable DHCP Snooping (prerequisite DAI)
ip dhcp snooping
ip dhcp snooping vlan 10

! Trust uplink port (ke router/DHCP server)
interface GigabitEthernet0/1
 ip dhcp snooping trust

! Step 2: Enable DAI
ip arp inspection vlan 10

! Step 3: Trust port ke router (bukan host)
interface GigabitEthernet0/1
 ip arp inspection trust

! Step 4: Rate limit ARP (prevent flood)
interface GigabitEthernet0/2
 ip arp inspection limit rate 100

! Step 5: Validation strict
ip arp inspection validate src-mac dst-mac ip
```

**Cara kerja DAI:**

```
ARP Packet Arrive
    │
    ▼
Is Port Trusted?
    ├── YES → Forward
    └── NO → Validate IP-MAC
              ├── Valid (DHCP binding table / ARP ACL) → Forward
              └── Invalid → DROP + LOG
```

#### Step 2.2: DHCP Snooping (Foundation DAI)

```cisco
! Enable globally
ip dhcp snooping

! Enable per VLAN
ip dhcp snooping vlan 10

! Trust port ke DHCP server
interface GigabitEthernet0/1
 ip dhcp snooping trust

! Verify binding table
show ip dhcp snooping binding
```

#### Step 2.3: Port Security (MAC Locking)

```cisco
! Batasi MAC per port
interface GigabitEthernet0/2
 switchport port-security
 switchport port-security maximum 2
 switchport port-security mac-address sticky
 switchport port-security violation shutdown

! Jika MAC baru muncul → port shutdown / restrict
```

#### Step 2.4: IP Source Guard (Prevent IP/MAC Spoofing)

```cisco
! Gunakan DHCP snooping binding table
interface GigabitEthernet0/2
 ip verify source port-security

! Atau dengan MAC verification
ip verify source port-security mac-address
```

#### Step 2.5: Private VLAN / Port Isolation

```cisco
! Isolasi host — tidak bisa komunikasi langsung antar host
! Hanya bisa ke gateway (promiscuous port)

! Contoh: Private VLAN isolated
interface GigabitEthernet0/2
 switchport mode private-vlan host
 switchport private-vlan host-association 10 101

! Promiscuous port (gateway)
interface GigabitEthernet0/1
 switchport mode private-vlan promiscuous
 switchport private-vlan mapping 10 101
```

**Efek:** Host tidak bisa kirim ARP langsung ke host lain. ARP spoofing gagal karena tidak bisa reach target [^10^].

#### Step 2.6: VLAN Segmentation

```cisco
! Pisahkan network:
! VLAN 10 = Staff (sensitif)
! VLAN 20 = Student (general)
! VLAN 30 = Guest (untrusted)

! Inter-VLAN routing hanya via router (bisa di-filter)
interface Vlan10
 ip address 192.168.10.1 255.255.255.0
 ip access-group ARP_FILTER in
```

#### Step 2.7: 802.1X Authentication (NAC)

```cisco
! Network Access Control — device harus autentikasi sebelum join
interface GigabitEthernet0/2
 dot1x port-control auto
 authentication periodic
 authentication timer reauthenticate 3600
```

---

### Layer 3 — Router / Gateway

#### Step 3.1: Static ARP di Router

```cisco
! Lock MAC critical host di router
arp 192.168.0.214 1c-1b-b5-42-0d-2e arpa

! Atau pakai ARP ACL
arp access-lan STATIC_HOSTS
 permit ip host 192.168.0.214 mac host 1c-1b-b5-42-0d-2e
```

#### Step 3.2: Disable Proxy ARP

```cisco
! Proxy ARP bisa di-abuse untuk spoofing
interface GigabitEthernet0/0
 no ip proxy-arp
```

#### Step 3.3: ICMP Redirect Disable (Router Side)

```cisco
! Disable ICMP redirect di router
interface GigabitEthernet0/0
 no ip redirects
```

---

### Layer 4 — Monitoring & Detection (SOC / Blue Team)

#### Step 4.1: arpwatch (Log ARP Changes)

```bash
# Install
sudo apt install arpwatch

# Monitor interface
sudo arpwatch -i eth0

# Log location: /var/log/arpwatch
# Alert: "flip flop" = MAC berubah untuk IP yang sama
```

#### Step 4.2: XArp (GUI Alert)

```bash
# Download: https://www.xarp.net/
# Windows/Linux GUI — alert popup kalau ARP spoofing detected
# Cocok untuk user non-teknis
```

#### Step 4.3: Wireshark (Manual Analysis)

```
Filter: arp
Yang dicari:
  - Gratuitous ARP (tanpa request)
  - Multiple MAC untuk IP yang sama
  - ARP reply dari MAC yang tidak diminta

Filter: icmp.type == 5
Yang dicari:
  - ICMP Redirect — routing manipulation
```

#### Step 4.4: Suricata / Zeek (IDS)

```yaml
# Suricata rule — detect ARP spoofing
alert arp any any -> any any (msg:"ARP SPOOFING DETECTED";
content:"|00 01 08 00 06 04 00 02|";
classtype:attempted-admin; sid:1000001; rev:1;)
```

```zeek
# Zeek script — log ARP anomaly
event arp_request(mac: string, src_ip: addr, dst_ip: addr) {
  # Log untuk analisis
}
```

#### Step 4.5: Wazuh / SIEM Integration

```xml
<!-- Wazuh decoder — ARP log -->
<decoder name="arpwatch">
  <program_name>arpwatch</program_name>
</decoder>

<!-- Rule -->
<rule id="100001" level="10">
  <decoded_as>arpwatch</decoded_as>
  <match>flip flop</match>
  <description>ARP spoofing detected: MAC changed for IP</description>
</rule>
```

---

## 📋 Decision Tree — "Saya Terkena ARP Spoofing, Apa yang Harus Saya Lakukan?"

```
START
  │
  ▼
Apakah kamu punya akses router/switch?
  ├── YA → Lanjut ke [ADMIN ROUTER PATH]
  └── TIDAK → Lanjut ke [USER PATH]

[USER PATH]
  │
  ▼
Step 1: Disable ICMP Redirect
  netsh interface ipv4 set global icmpredirects=disabled
  │
  ▼
Step 2: Block ICMP Redirect di Firewall
  New-NetFirewallRule ... IcmpType 5 ... Block
  │
  ▼
Step 3: Set Static ARP
  arp -s <gateway_ip> <gateway_mac>
  │
  ▼
Step 4: Block UDP Flood (SSDP/mDNS)
  New-NetFirewallRule ... UDP 1900,5353 ... Block
  │
  ▼
Step 5: Selective Block Attacker (JANGAN full block)
  │
  ▼
Masih terkena?
  ├── YA → Pindah network (hotspot/LAN lain) atau VPN
  └── TIDAK → Monitor dengan Wireshark/arpwatch

[ADMIN ROUTER PATH]
  │
  ▼
Step 1: Enable DHCP Snooping
Step 2: Enable Dynamic ARP Inspection (DAI)
Step 3: Configure Port Security
Step 4: Enable IP Source Guard
Step 5: Setup Private VLAN / Port Isolation
Step 6: Deploy arpwatch / XArp / Suricata
Step 7: Integrasi log ke SIEM
  │
  ▼
Validasi:
  show ip arp inspection statistics vlan 10
  show ip dhcp snooping binding
```

---

## 🛠️ Script Otomatis — Windows Defense (Run as Admin)

```powershell
# ============================================
# ANTI-ARP-SPOOF + ICMP-REDIRECT Defense Script
# Version: 1.0
# Target: Windows 10/11
# Context: Kampus network, no router access
# ============================================

param(
    [string]$AttackerIP = "192.168.0.240",
    [string]$GatewayIP = "192.168.0.1",
    [string]$GatewayMAC = "3c-6a-d2-14-9e-68"
)

Write-Host "=== ARP SPOOFING DEFENSE SCRIPT ===" -ForegroundColor Cyan
Write-Host ""

# Step 1: Disable ICMP Redirect
Write-Host "[1/6] Disable ICMP Redirect..." -ForegroundColor Yellow
netsh interface ipv4 set global icmpredirects=disabled
netsh interface ipv6 set global icmpredirects=disabled
Write-Host "      ✓ ICMP redirect disabled" -ForegroundColor Green

# Step 2: Block ICMP Redirect (Type 5)
Write-Host "[2/6] Block ICMP Redirect in firewall..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "BLOCK_ICMP_REDIRECT_IN" `
  -Direction Inbound -Protocol ICMPv4 -IcmpType 5 `
  -Action Block -Profile Any -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "BLOCK_ICMP_REDIRECT_OUT" `
  -Direction Outbound -Protocol ICMPv4 -IcmpType 5 `
  -Action Block -Profile Any -ErrorAction SilentlyContinue
Write-Host "      ✓ ICMP redirect blocked" -ForegroundColor Green

# Step 3: Reset ARP + Set Static
Write-Host "[3/6] Reset ARP table + set static gateway..." -ForegroundColor Yellow
arp -d *
arp -s $GatewayIP $GatewayMAC
Write-Host "      ✓ Static ARP set: $GatewayIP -> $GatewayMAC" -ForegroundColor Green

# Step 4: Block UDP Flood (SSDP/mDNS)
Write-Host "[4/6] Block UDP flood (SSDP/mDNS)..." -ForegroundColor Yellow
New-NetFirewallRule -DisplayName "BLOCK_SSDP_FLOOD" `
  -Direction Inbound -Protocol UDP -LocalPort 1900 `
  -Action Block -Profile Any -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "BLOCK_MDNS_FLOOD" `
  -Direction Inbound -Protocol UDP -LocalPort 5353 `
  -Action Block -Profile Any -ErrorAction SilentlyContinue
Write-Host "      ✓ UDP flood blocked" -ForegroundColor Green

# Step 5: Selective block attacker (NOT full block)
Write-Host "[5/6] Selective block attacker ($AttackerIP)..." -ForegroundColor Yellow
# Remove old full-block rules if exist
Remove-NetFirewallRule -DisplayName "BLOCK ATTACKER IN" -ErrorAction SilentlyContinue
Remove-NetFirewallRule -DisplayName "BLOCK ATTACKER OUT" -ErrorAction SilentlyContinue
# Add selective rules
New-NetFirewallRule -DisplayName "BLOCK_ATTACKER_UDP_FLOOD" `
  -Direction Inbound -RemoteAddress $AttackerIP `
  -Protocol UDP -LocalPort 1900,5353 `
  -Action Block -Profile Any -ErrorAction SilentlyContinue
New-NetFirewallRule -DisplayName "BLOCK_ATTACKER_ICMP_REDIRECT" `
  -Direction Inbound -RemoteAddress $AttackerIP `
  -Protocol ICMPv4 -IcmpType 5 `
  -Action Block -Profile Any -ErrorAction SilentlyContinue
Write-Host "      ✓ Attacker selectively blocked" -ForegroundColor Green

# Step 6: Verify
Write-Host "[6/6] Verification..." -ForegroundColor Yellow
Write-Host ""
Write-Host "--- ARP Table ---" -ForegroundColor Cyan
arp -a | Select-String $GatewayIP
Write-Host ""
Write-Host "--- ICMP Redirect Status ---" -ForegroundColor Cyan
netsh interface ipv4 show global | Select-String "redirect"
Write-Host ""
Write-Host "--- Firewall Rules ---" -ForegroundColor Cyan
Get-NetFirewallRule | Where-Object { $_.DisplayName -like "BLOCK*" } |
  Select DisplayName, Direction, Action | Format-Table -AutoSize
Write-Host ""
Write-Host "=== DEFENSE APPLIED ===" -ForegroundColor Cyan
Write-Host "Test ping ke gateway:" -ForegroundColor Yellow
ping $GatewayIP -n 4
```

---

## 🧠 Framework Berpikir: Defense in Depth

| Layer             | Control                                    | Efektivitas  | Butuh Akses Router? |
| ----------------- | ------------------------------------------ | ------------ | ------------------- |
| **L1 — Endpoint** | Static ARP, ICMP disable, firewall         | ⚠️ Partial   | ❌ Tidak            |
| **L2 — Switch**   | DAI, DHCP Snooping, Port Security          | ✅ High      | ✅ Ya               |
| **L3 — Router**   | Static ARP, Proxy ARP disable              | ✅ Medium    | ✅ Ya               |
| **L4 — Monitor**  | arpwatch, XArp, Suricata, SIEM             | ✅ High      | ⚠️ Partial          |
| **L5 — Segment**  | Private VLAN, 802.1X, Network Segmentation | ✅ Very High | ✅ Ya               |

> **Prinsip:** Tanpa kontrol Layer 2 (switch), kamu tidak bisa **menghentikan** ARP spoofing. Tapi kamu bisa **melindungi diri** di Layer 1 (endpoint) dan **mendeteksi** di Layer 4 (monitoring).

---

## 🔗 Lihat Juga

- [[network-security|Network Security]] — OSI Layer 1–8 threat landscape
- [[cyber-security|Cyber Security Roadmap]] — Blue Team defense roadmap
- [[application|Master Arsenal]] — Defensive tools arsenal
- [[underground-knowledge|Underground Knowledge]] — Cheat Engine & Dark Web hierarchy (dual-use mindset)

---

_Mitigasi ARP Spoofing | Defense Against Ettercap & Bettercap | Layer 1 (Endpoint) → Layer 5 (Segmentation)_
