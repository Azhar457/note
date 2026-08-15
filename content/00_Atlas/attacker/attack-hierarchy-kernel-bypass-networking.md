---
title: Attack Perspective — Kompilasi Kernel Bypass Networking (Red Team)
tags:
- attack
- red-team
- kernel-bypass
- dpdk
- xdp
- ebpf
- zero-copy
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  - callout
---

# Kernel Bypass Networking — Perspektif Penyerang

> Kernel bypass (DPDK, XDP, AF_XDP, io_uring) memungkinkan packet processing tanpa lewat kernel syscall — red team exploit untuk C2 high-speed, packet sniffing stealth, dan bypass EDR network monitoring.

## 1. Attack Surface Kernel Bypass

| Teknik | Fungsi Defender | RedTeam Use | Evasion | Detection Gap |
|--------|----------------|-------------|---------|----------------|
| **DPDK** (Data Plane Dev Kit) | Line-rate packet processing (firewall, IDS) | C2 high-speed (1M+ pkt/s), packet inject, MITM hardware | Bypass kernel network stack — EDR hook (syscall monitor) tidak lihat traffic | EDR sysmon tidak capture DPDK traffic — kernel bypass = invisible |
| **XDP / eBPF** (eXpress Data Path) | Drop packet at driver level (DDoS mitigation), ACL | Packet drop selective (block blue team probe), traffic redirect, covert channel | eBPF program runs at driver level — sebelum kernel network stack — EDR tidak lihat | eBPF rootkit: CVE-2021-3490 (verifier bypass → root), load custom program → intercept syscall |
| **AF_XDP** | High-performance socket (zero-copy) | Packet sniffing stealth (no tcpdump signature), C2 socket high-speed | Zero-copy = no kernel buffer copy = no EDR memory scan | tcpdump/Zeek capture di kernel — AF_XDP bypass kernel → tidak capture |
| **io_uring** | Async I/O (Linux 5.1+) | Fast C2 I/O, async file exfil, exploit chain (CVE-2024-1086 nf_tables UAF lewat io_uring) | io_uring = async, no blocking syscall → EDR syscall hook tidak trigger | io_uring bypass tradisional syscall monitoring — EDR perlu io_uring specific hook |
| **TUN/TAP** | VPN tunnel, virtual interface | Custom C2 tunnel, encrypted VPN pivot, bypass firewall | TUN/TAP = virtual interface → traffic terlihat sebagai new interface, bukan existing | EDR jarang monitor TUN/TAP interface creation |

## 2. eBPF Rootkit — Stealth Level Tinggi

```
Load eBPF program (Ring 0 equivalent, JIT compiled)
 ↓
Attach ke kprobe/tracepoint/syscall
 ↓
Intercept syscall: open(), read(), readdir(), getdents()
 ↓
Filter: hide process (pid), hide file (name), hide network (port)
 ↓
Return modified result ke userspace
 ↓
ps, ls, netstat = tidak menampilkan process/file/port attacker
 ↓
EDR: "sistem sehat" — karena syscall return di-filter oleh eBPF
```

**CVE eBPF Exploit:**
| CVE | Impact | Red Team Value |
|-----|--------|----------------|
| CVE-2021-3490 | eBPF verifier bypass → kernel code execution | Root via eBPF — stealth, no module load |
| CVE-2022-0185 | eBPF cred array overflow → privilege escalation | Container escape → host root |
| CVE-2024-1086 | nf_tables UAF (io_uring chain) → root | Kernel exploit via netfilter — common Linux |

## 3. Tool Stack

| Tool | Use | Catatan |
|------|-----|---------|
| **libbpf** | Load eBPF program | Standard library — compile BPF C → load ke kernel |
| **bcc** | eBPF scripting (Python) | Tools: execsnoop, opensnoop, tcpltate — red team modify untuk stealth |
| **bpftrace** | eBPF one-liner | Quick prototype — attach ke tracepoint → log syscall |
| **DPDK** | Kernel bypass packet processing | C2 high-speed, packet inject — bypass kernel network stack |
| **scapy** | Packet crafting | Custom protocol, exploit payload — manual injection |
| **pwntools** | Exploit framework | Kernel exploit chain (ROP, heap, io_uring) |

## 4. Referensi
- eBPF Project — https://ebpf.io/
- libbpf Docs — https://libbpf.readthedocs.io/
- DPDK — https://dpdk.org/
---

audited
---
