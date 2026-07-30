---
title: Systemd & Service Management Deep Dive
tags:
  - linux
  - systemd
  - system-administration
  - devops
  - service-management
  - journald
  - library
aliases:
  - systemd Service Units
  - journalctl Guide
  - systemd Timers
  - Service Management Linux
created: "2026-07-30"
updated: "2026-07-30"
status: pending
cssclasses:
  - wide-table
---

# ⚙️ Systemd & Service Management Deep Dive

> Panduan praktis systemd — service units, journald logging, timers, socket activation, resource control, dan troubleshooting. Systemd adalah init system default di semua distro modern (Fedora, RHEL, Ubuntu, Debian, Arch). Catatan ini lahir dari masalah auditd di Fedora 44 yang ternyata disabled + kernel param missing — representasi gap pengetahuan tentang systemd lifecycle. Vault udah punya [[linux-fundamentals-deepdive]] (OS level) — ini implementasi systemd spesifik.

## Daftar Isi

1. [[#1. Systemd Architecture — Unit Types]]
2. [[#2. Service Units — Anatomi & Lifecycle]]
3. [[#3. Journald — Centralized Logging]]
4. [[#4. Systemd Timers — Cron Modern]]
5. [[#5. Socket Activation — On-Demand Services]]
6. [[#6. Resource Control — CPU/Memory Limits]]
7. [[#7. Systemd Security — Service Hardening]]
8. [[#8. Systemd-networkd — Network Config]]
9. [[#9. Troubleshooting & Common Issues]]
10. [[#10. Boot Process Timeline — From initramfs to Graphical Session]]
11. [[#11. Target & Runlevel Mapping — SysV Compatibility]]
12. [[#12. Dependency Resolution — After vs Requires vs Wants vs BindsTo]]
13. [[#13. systemd-analyze Plot — Visual Boot Analysis]]
14. [[#14. Emergency Recovery — Rescue & Emergency Targets]]
15. [[#15. Security Namespace Hardening — PrivateTmp, PrivateDevices, ProtectSystem]]
16. [[#16. systemd-coredump — Core Dump Management]]
17. [[#17. systemd-logind — Session & Seat Management]]
18. [[#18. SysVinit to Systemd — Migration Patterns]]
19. [[#19. Koneksi ke Vault]]

---

## 1. Systemd Architecture — Unit Types

Systemd manage semua resource sebagai **unit**. Ada 12 tipe unit:

| Tipe | Ekstensi | Fungsi | Contoh |
|------|----------|--------|--------|
| **Service** | `.service` | Daemon / background process | nginx.service, postgresql.service |
| **Socket** | `.socket` | IPC / network socket | sshd.socket, docker.socket |
| **Timer** | `.timer` | Scheduled task | fstrim.timer, logrotate.timer |
| **Mount** | `.mount` | Mount point | home.mount, boot.mount |
| **Automount** | `.automount` | On-demand mount | mnt-data.automount |
| **Path** | `.path` | File/directory trigger | cups.path |
| **Slice** | `.slice` | Resource control group | machine.slice, system.slice |
| **Target** | `.target` | Group of units (runlevel) | multi-user.target, graphical.target |
| **Scope** | `.scope` | Externally created process | user@1000.service (user scope) |
| **Device** | `.device` | Kernel device | sys-devices-pci...device |
| **Swap** | `.swap` | Swap partition | swapfile.swap |
| **Network** | `.network` | Network configuration | 50-dhcp.network |

```bash
# Unit management
systemctl list-units --type=service --all   # semua service
systemctl list-units --type=timer           # timer saja
systemctl list-unit-files --type=service    # semua file unit (active + inactive)
systemctl list-dependencies sshd.service    # dependency tree
```

---

## 2. Service Units — Anatomi & Lifecycle

### Struktur Service Unit

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Awesome Application
Documentation=https://docs.myapp.com
After=network-online.target postgresql.service
Wants=postgresql.service              # optional dependency
Requires=redis.service                # hard dependency, gagal kalo redis gak start
BindsTo=redis.service                 # stop myapp kalo redis stop

[Service]
Type=simple                           # default: langsung fork
User=myapp
Group=myapp
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/node /opt/myapp/server.js
ExecReload=/bin/kill -HUP $MAINPID
ExecStop=/bin/kill -TERM $MAINPID
Restart=on-failure                    # restart otomatis
RestartSec=5                          # delay 5 detik sebelum restart
TimeoutStartSec=30
TimeoutStopSec=10
Environment=NODE_ENV=production
EnvironmentFile=-/etc/myapp/env.conf
StandardOutput=journal
StandardError=journal

# Hardening
NoNewPrivileges=yes
PrivateTmp=yes
ProtectSystem=full
ProtectHome=yes

[Install]
WantedBy=multi-user.target            # start di boot level multi-user
```

### Type — Arti Penting

| Type | Behavior | Cocok untuk |
|------|----------|-------------|
| `simple` | ExecStart langsung jalan, systemd anggap "started" | Node.js, Python, long-running shell |
| `forking` | Parent exit, child lanjut (daemon) | MySQL, Nginx, PostgreSQL |
| `oneshot` | Jalan sekali lalu exit | Script setup, cleanup |
| `dbus` | Tunggu bus name di D-Bus | NetworkManager, systemd-resolved |
| `notify` | Panggil `sd_notify()` setelah siap | Aplikasi yang pake libsystemd |
| `idle` | Simple, tapi delay sampai semua job selesai | Print banner, welcome message |

### Service Lifecycle

```bash
systemctl daemon-reload            # reload unit file setelah diubah
systemctl start myapp.service      # start
systemctl stop myapp.service       # stop
systemctl restart myapp.service    = stop + start
systemctl reload myapp.service     # Sends SIGHUP (kalo support)
systemctl enable myapp.service     # auto-start di boot
systemctl disable myapp.service    # hapus auto-start
systemctl enable --now myapp.service  # enable + start sekaligus

# Status
systemctl status myapp.service     # status + recent logs
systemctl is-active myapp.service  # active/inactive/activating
systemctl is-enabled myapp.service # enabled/disabled/static
systemctl show myapp.service       # semua properties (100+ fields)
systemctl cat myapp.service        # print unit file content
```

### Drop-in Config — Override Tanpa Edit File Asli

```bash
# 1. Buat drop-in directory
sudo mkdir -p /etc/systemd/system/myapp.service.d/

# 2. Buat override.conf
sudo cat > /etc/systemd/system/myapp.service.d/override.conf << 'EOF'
[Service]
Restart=always
RestartSec=10
MemoryMax=1G
CPUQuota=50%
EOF

# 3. Reload
sudo systemctl daemon-reload
sudo systemctl restart myapp.service

# Verifikasi
systemctl cat myapp.service   # liat hasil merge unit file asli + drop-in
systemctl show myapp.service -p MemoryMax
```

---

## 3. Journald — Centralized Logging

Semua log systemd terpusat di journald — gak perlu `/var/log/syslog` atau `auth.log` (tapi tetap bisa forward ke syslog tradisional).

### Konfigurasi Journald

```ini
# /etc/systemd/journald.conf
[Journal]
Storage=persistent                     # simpan di disk (/var/log/journal/)
Compress=yes
Seal=yes
SystemMaxUse=4G
SystemKeepFree=1G
MaxRetentionSec=1month
ForwardToSyslog=no                     # gak perlu syslog
ForwardToWall=yes
```

### journalctl — Master Log Viewer

```bash
# Basic
journalctl                              # semua log (butuh sudo/group adm)
journalctl -u nginx.service             # log service tertentu
journalctl -u sshd.service -u nginx.service  # multiple services
journalctl -k                           # kernel messages

# Time-based
journalctl --since "1 hour ago"
journalctl --since "2026-07-30 09:00" --until "2026-07-30 12:00"
journalctl -u myapp.service --since yesterday

# Filter
journalctl -p err -b                    # error priority, boot sejak boot
journalctl _PID=1234                    # by PID
journalctl _UID=1000                    # by user
journalctl -p warning..err              # range priority (warning sampai error)

# Output
journalctl -f                           # follow (tail -f)
journalctl -n 50                        # last 50 lines
journalctl -u myapp.service --no-pager  # full output, gak pager
journalctl -o json-pretty               # JSON format

# Maintenance
journalctl --disk-usage                 # size on disk
journalctl --vacuum-size=500M           # hapus log sampai 500MB
journalctl --vacuum-time=7d             # hapus log lebih dari 7 hari
sudo journalctl --rotate                # force rotate log files
```

---

## 4. Systemd Timers — Cron Modern

Systemd timer > cron: logging terintegrasi, dependency-aware, bisa missed-exec, persistent.

```ini
# /etc/systemd/system/backup.service
[Unit]
Description=Daily Database Backup

[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup-db.sh
User=postgres
```

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Run backup daily at 3 AM

[Timer]
OnCalendar=daily
OnCalendar=*-*-* 03:00:00        # atau format tepat
Persistent=true                   # kalo missed (mati listrik), jalan pas boot
RandomizedDelaySec=300            # random delay 0-5 menit
Unit=backup.service               # default: nama sama (backup.timer → backup.service)

[Install]
WantedBy=timers.target
```

```bash
# Activate
sudo systemctl daemon-reload
sudo systemctl enable --now backup.timer

# Management
systemctl list-timers --all         # semua timer + next run
systemctl list-timers               # hanya yang active
systemctl status backup.timer
journalctl -u backup.timer -u backup.service  # log timer + service
```

### Format OnCalendar

| Pattern | Makna | Contoh Next |
|---------|-------|-------------|
| `daily` | Setiap hari 00:00 | `Thu 2026-07-31 00:00:00 WIB` |
| `hourly` | Setiap jam :00 | `Thu 2026-07-30 10:00:00 WIB` |
| `*-*-* 03:00:00` | Setiap hari jam 3 pagi | `Thu 2026-07-31 03:00:00 WIB` |
| `Mon..Fri 08:30:00` | Weekdays jam 8:30 | `Fri 2026-08-01 08:30:00 WIB` |
| `Sat,Sun 00:00:00` | Weekend midnight | `Sat 2026-08-02 00:00:00 WIB` |
| `*:0/15` | Setiap 15 menit | `Thu 2026-07-30 09:15:00 WIB` |
| `*-01-01 00:00:00` | Setiap tahun baru | `Fri 2027-01-01 00:00:00 WIB` |

```bash
# Test timer
systemd-analyze calendar "Mon..Fri 09:00:00"   # prev/next fire time
```

---

## 5. Socket Activation — On-Demand Services

Service start pas pertama kali ada koneksi ke socket-nya — hemat resource.

```ini
# /etc/systemd/system/myecho.socket
[Unit]
Description=Echo Service Socket

[Socket]
ListenStream=7777
Accept=yes                        # fork per connection

[Install]
WantedBy=sockets.target
```

```ini
# /etc/systemd/system/myecho@.service    # template (@ = instance)
[Unit]
Description=Echo Service %i

[Service]
Type=simple
ExecStart=/usr/bin/cat
StandardInput=socket
StandardOutput=socket
```

```bash
sudo systemctl enable --now myecho.socket
ss -tlnp | grep 7777      # LISTEN, tapi gak ada process name — bidikan systemd
echo "hello" | nc localhost 7777  # first connect → service auto-start
journalctl -u myecho@.service    # log per instance
```

### Use Case Socket Activation

| Skenario | Manual | Socket Activation |
|----------|--------|-------------------|
| SSH diakses jarang | Jalan 24/7, makan memory | Start saat ada koneksi SSH |
| Container socket | Docker socket listen | Start dockerd pas ada request |
| Web app low traffic | Nginx selalu jalan | Start saat request masuk |

> [!tip] Fedora 44 default untuk `sshd.socket` — bukan `sshd.service`. Cek dengan `systemctl status sshd.socket`.

---

## 6. Resource Control — CPU/Memory Limits

Systemd bisa control resources via cgroups v2.

### Sesi Unit

```ini
[Service]
MemoryMax=1G                   # hard limit (OOM kill kalo exceeded)
MemoryHigh=768M                # soft limit (mulai throttle)
CPUQuota=50%                   # max 50% 1 core
CPUQuotaPeriodSec=1s
TasksMax=100                   # max threads/processes
IOWeight=100                   # I/O priority (100-1000)
IOReadBandwidthMax=/dev/sda 10M  # I/O rate limit
IOWriteBandwidthMax=/dev/sda 5M
```

### Sesi System Level — Slice

```bash
# Buat slice untuk batch job
sudo cat > /etc/systemd/system/batch.slice << 'EOF'
[Slice]
CPUQuota=200%           # max 2 core
MemoryMax=4G
TasksMax=200
EOF

# Assign service ke slice
sudo cat > /etc/systemd/system/batch-job.service.d/override.conf << 'EOF'
[Service]
Slice=batch.slice
EOF
```

### Monitor Resource

```bash
systemd-cgtop                           # top untuk cgroups
systemctl show --property=MemoryMax myapp.service
systemd-cgls                            # tree view cgroups
```

---

## 7. Systemd Security — Service Hardening

Checklist hardening per-service (dari [[linux-hardening-audit-praktis]]):

```bash
# Analyze security profile
systemd-analyze security myapp.service
```

| Directive | Efek | Level |
|-----------|------|-------|
| `ProtectSystem=full` | Read-only /usr, /etc | Wajib |
| `ProtectHome=yes` | Gak bisa akses /home, /root | Wajib |
| `PrivateTmp=yes` | /tmp terisolasi | Wajib |
| `NoNewPrivileges=yes` | Gak bisa suid/sgid | Wajib |
| `CapabilityBoundingSet=...` | Batasi Linux capabilities | Medium |
| `SystemCallFilter=~@debug` | Block syscall berbahaya | Medium |
| `PrivateDevices=yes` | Gak liat /dev (kecuali /dev/null, /dev/zero) | Tinggi |
| `ProtectKernelModules=yes` | Block insmod/modprobe | Tinggi |
| `MemoryDenyWriteExecute=yes` | Prevent W+X memory pages | Tinggi |
| `RestrictAddressFamilies=...` | Batasi network domains | Tinggi |
| `LockPersonality=yes` | Prevent exec domain change | Maksimal |

---

## 8. Systemd-networkd — Network Config

Alternatif lightweight ke NetworkManager — cocok buat server.

```ini
# /etc/systemd/network/50-dhcp.network
[Match]
Name=enp* ens*

[Network]
DHCP=ipv4
LinkLocalAddressing=ipv6
DNSSEC=allow-downgrade
```

```ini
# /etc/systemd/network/50-static.network
[Match]
Name=enp3s0

[Network]
Address=192.168.1.100/24
Gateway=192.168.1.1
DNS=1.1.1.1
DNS=8.8.8.8
Domains=local.domain

[Route]
Destination=10.0.0.0/8
Gateway=192.168.1.254
```

```bash
systemctl enable --now systemd-networkd
networkctl status                  # status network
networkctl list                    # all links
networkctl lldp                   # LLDP neighbors
```

---

## 9. Troubleshooting & Common Issues

### Issue 1: Service Gagal Start

```bash
systemctl status myapp.service    # liat status + exit code
journalctl -xeu myapp.service     # -x = extra explanation, -e = end
systemctl reset-failed myapp.service  # reset "failed" state
```

### Issue 2: Slow Boot — Analyze Boot Time

```bash
systemd-analyze                    # total boot time
systemd-analyze blame              # per unit boot time (desc)
systemd-analyze critical-chain     # critical path di boot sequence
systemd-analyze plot > boot.svg    # visual timeline
```

### Issue 3: Timer Gak Jalan

```bash
systemctl list-timers              # next run
journalctl -u backup.timer -p info # log timer events
systemctl status backup.timer
systemctl start backup.service     # test service langsung
```

### Issue 4: Unit Not Found

```bash
systemctl daemon-reload            # sering ketinggalan!
systemctl list-unit-files | grep myapp
systemctl preset myapp.service     # enable berdasarkan preset
```

### Issue 5: Drop-in Gak Kebaca

```bash
systemctl cat myapp.service        # verify override applied
# Kalo gak muncul: nama file harus .conf!
# /etc/systemd/system/myapp.service.d/*.conf ✅
# /etc/systemd/system/myapp.service.d/override ❌ (no extension)
```

### Debug Mode

```bash
# Enable debug logging
journalctl -p debug -u myapp.service
systemctl start myapp.service
# Atau set environment
SYSTEMD_LOG_LEVEL=debug systemctl start myapp.service
```

---



## 11. Systemd Boot Process — From Power-On to Login

Understanding systemd boot sequence penting buat troubleshooting slow boot atau service yang gak start.

```
Power On → BIOS/UEFI → Bootloader (GRUB) → Kernel + initramfs → init (PID 1 = systemd) → default.target
```

### Phase-by-Phase Timeline

```bash
# Analisis boot time
systemd-analyze                         # total boot time
systemd-analyze blame                   # per-unit time (descending)
systemd-analyze critical-chain          # critical path ke target
systemd-analyze plot > boot.svg         # visual timeline — buka di browser
```

**Output `systemd-analyze` fields:**
- **kernel**: waktu dari bootloader sampai kernel selesai init
- **initrd**: waktu dari initramfs sampai root filesystem siap
- **userspace**: waktu dari systemd start sampai default.target tercapai

### Initramfs — kenapa penting?

Initramfs (initial RAM filesystem) adalah sistem sementara yang di-load kernel sebelum root filesystem di-mount. Systemd di initramfs:
1. Load storage drivers (SATA, NVMe, mdadm, LVM)
2. Decrypt LUKS partition
3. Mount root filesystem
4. Switch_root ke rootfs

Kalo boot lambat di "initrd" phase — curigain: LUKS decryption, network mount, atau storage driver timeouts.

## 12. Target vs SysV Runlevel Mapping

SysV runlevel → systemd target mapping:

| SysV Runlevel | systemd Target | Fungsi |
|:---:|:---:|:---|
| 0 | poweroff.target | Shutdown |
| 1 / S | rescue.target | Single-user mode, minimal |
| 2 | multi-user.target | Multi-user tanpa GUI (debian turunan) |
| 3 | multi-user.target | Multi-user, text-only |
| 4 | multi-user.target | Custom (jarang dipake) |
| 5 | graphical.target | Multi-user + GUI |
| 6 | reboot.target | Reboot |
| emergency | emergency.target | Rescue shell, root fs ro |

```bash
# Switch target di runtime
sudo systemctl isolate multi-user.target   # text mode
sudo systemctl isolate graphical.target    # GUI mode

# Default boot target
sudo systemctl get-default
sudo systemctl set-default multi-user.target   # boot ke text mode
```

### 12.1 Systemd Targets vs Services

Target bukan "runlevel" — dia adalah **synchronization point**:

```
┌─────────────────┐
│ sysinit.target  │ ← basic system init
└────────┬────────┘
         ▼
┌─────────────────┐
│ basic.target    │ ← filesystems, swap, sockets
└────────┬────────┘
         ▼
┌─────────────────┐
│multi-user.target│ ← all services (no GUI)
└────┬──────┬─────┘
     ▼      ▼
┌────────┐ ┌────────────────┐
│graphical│ │poweroff.target │
│.target │ │reboot.target    │
└────────┘ └────────────────┘
```

Service unit `WantedBy=multi-user.target` artinya: service ini akan start ketika systemd mencapai target itu. Tapi target tercapai **setelah semua service yang diperlukan sukses**.

## 13. Service Dependency — After vs Requires vs Wants

Empat directive utama yang ngatur hubungan service:

| Directive | Effect | Behavior if fails |
|-----------|--------|-------------------|
| `After=A.service` | Order: start AFTER A | A gagal, service tetap start |
| `Before=A.service` | Order: start BEFORE A | Kebalikan After |
| `Requires=A.service` | Hard dep: A harus jalan | A gagal → service gagal |
| `Wants=A.service` | Soft dep: usahakan A jalan | A gagal → service tetap jalan |
| `BindsTo=A.service` | Lifecycle bond | A stop → service stop |

### Praktik — Service yang butuh database

```ini
[Unit]
Description=My App
After=network-online.target postgresql.service
Requires=postgresql.service
# Wants=postgresql.service   ← pake ini kalo app bisa jalan tanpa DB (misal: cache)

[Service]
ExecStart=/usr/bin/node /opt/app/server.js
Restart=on-failure
```

> [!tip] Use `Wants` instead of `Requires` unless your app literally cannot function without the dependency. `Wants` lets the service still start if the dep is temporarily broken, which helps with recovery.

### Dependency Tree

```bash
systemctl list-dependencies postgresql.service
# Shows: postgresql.service
#         ● ├─system.slice
#         ● ├─systemd-journald.socket
#         ● ├─basic.target
#         ● │ ├─-.mount
#         ● │ ├─paths.target
#         ● │ ├─slices.target
#         ● │ └─sockets.target
```

## 14. Emergency Recovery

Ada kalanya systemd gagal total — service critical gak jalan, systemd hang, atau root fs corrupt.

### 14.1. Rescue Mode (Single User)

```bash
# Dari GRUB: tambah "1" atau "single" di kernel cmdline
# Atau dari GRUB: tekan 'e' → cari "linux" line → tambah " systemd.unit=rescue.target"

# Kalo udah di shell:
sudo systemctl rescue            # switch ke rescue mode secara real-time
```

### 14.2. Emergency Mode

```bash
# GRUB: tambah " systemd.unit=emergency.target"
# Emergency: root filesystem di-mount READ-ONLY, gak ada network, cuma shell
mount -o remount,rw /            # remount rw manual kalo perlu
```

### 14.3. Boot Parameter untuk Debug Systemd

| Parameter | Efek |
|-----------|------|
| `systemd.unit=rescue.target` | Boot ke rescue |
| `systemd.unit=emergency.target` | Boot ke emergency |
| `systemd.log_level=debug` | Log systemd dengan debug level |
| `systemd.log_target=console` | Log ke console (gak ke journal) |
| `systemd.journald.forward_to_console=yes` | Journald output ke console |
| `systemd.mask=network.service` | Mask service tertentu saat boot |

```bash
# Test kalo service rusak bikin boot hang:
# Tambah "systemd.mask=myapp.service systemd.mask=myapp.timer" di kernel cmdline
```

## 15. Namespace Isolation — ProtectSystem, PrivateTmp, dll

Systemd bisa mengisolasi service menggunakan Linux namespaces — sama kaya container tapi lebih lightweight.

```ini
[Service]
# 🟢 PrivateTmp — /tmp dan /var/tmp terisolasi
PrivateTmp=yes
# Membuat namespace mount baru untuk /tmp
# Setiap service punya /tmp sendiri → gak bisa liat file temp service lain

# 🟢 ProtectSystem — read-only filesystem
ProtectSystem=full
# full: /usr dan /etc read-only
# strict: /usr, /etc, dan / read-only (lebih keras)
# true: /usr read-only

# 🟢 ProtectHome — /home, /root, /run/user gak bisa diakses
ProtectHome=yes

# 🟢 PrivateDevices — /dev dibatasi (cuma null, zero, random, urandom)
PrivateDevices=yes

# 🟢 ProtectKernelTunables — /sys dan /proc/sys read-only
ProtectKernelTunables=yes

# 🟢 ProtectKernelModules — block insmod/modprobe
ProtectKernelModules=yes

# 🟢 ProtectControlGroups — /sys/fs/cgroup read-only
ProtectControlGroups=yes

# 🟢 NoNewPrivileges — gak bisa escalate privilege
NoNewPrivileges=yes

# 🔴 MemoryDenyWriteExecute — prevent W+X memory pages
MemoryDenyWriteExecute=yes
```

### Efek Samping

| Isolation | Cache effect | Notable impact |
|-----------|:---:|:---|
| PrivateTmp | Session-based | tmp file gak survive restart |
| ProtectSystem=full | — | Gak bisa write ke /etc |
| ProtectHome=yes | SSH key gak terbaca | Home SSH key auth |
| PrivateDevices | — | Gak bisa akses GPU/device |

## 16. systemd-coredump — Debug Application Crash

```bash
# Enable
sudo systemctl enable --now systemd-coredump.socket
ulimit -c unlimited                # enable core dump per session

# Lihat core dumps
coredumpctl list
coredumpctl info                   # detail crash

# Debug
coredumpctl gdb                    # langsung GDB ke dump terakhir
coredumpctl debug myapp.service    # debug specific service
coredumpctl dump myapp.service > core.dump  # export dump

# Config
# /etc/systemd/coredump.conf
[Coredump]
Storage=external                   # simpan ke /var/lib/systemd/coredump/
Compress=yes
ProcessSizeMax=2G
```

## 17. systemd-logind — Session & Seat Management

```bash
# Cek session aktif
loginctl list-sessions
loginctl session-status <id>

# Cek user login
loginctl list-users
loginctl user-status 1000

# Seat (physical terminal)
loginctl list-seats
loginctl seat-status seat0

# Lock/unlock session
loginctl lock-session <id>
loginctl unlock-session <id>
```

Systemd-logind juga yang nge-manage:
- **Idle action**: suspend/shutdown setelah idle
- **Lid switch**: action pas laptop lid ditutup
- **Multi-seat**: support multiple keyboard/monitor/mouse di satu PC

---

## 10. Boot Process Timeline — From initramfs to Graphical Session

Memahami boot process systemd penting buat debugging slow boot dan service dependency issues. Berbeda dengan SysV init yang linear (Sxx → Kxx script), systemd parallelize startup berdasarkan dependency graph.

### Boot Sequence Overview

```
UEFI/BIOS → Bootloader (GRUB) → Kernel + initramfs → initrd.target → basic.target → multi-user.target → graphical.target
```

### 1. initramfs Stage (`initrd.target`)

Kernel mount initramfs (initial RAM filesystem) sebagai root sementara. Systemd di initramfs menjalankan unit-unit penting:

```bash
# Service yang jalan di initramfs
systemd-fsck@.service     # check filesystem
systemd-udevd.service     # device manager — detect hardware
dracut-initqueue.service  # dracut — load storage drivers
systemd-journald.service  # journald udah aktif dari tahap ini
```

Setelah root filesystem terdeteksi dan di-mount, systemd switch root ke filesystem asli (`/sysroot` → `/`) dan lanjut ke `basic.target`.

### 2. basic.target — Minimal Boot

Tahap ini semua filesystem (termasuk `/usr`, `/var`) udah di-mount. Service yang aktif:

- `sysinit.target` — mount, swap, udev, random seed, selinux policy
- `sockets.target` — semua socket unit aktif (termasuk dbus.socket, sshd.socket)
- `timers.target` — timer unit mulai dijadwalkan
- `local-fs.target` — semua local filesystem mount selesai

### 3. multi-user.target — Multi-User Text Mode

Server-grade target — network online, SSH, database, web server jalan. Gak ada display manager.

```bash
systemctl list-dependencies multi-user.target  # liat semua unit yang start
```

### 4. graphical.target — Desktop Environment

Multi-user plus display manager (GDM, SDDM, LightDM). Ini target default di distro desktop.

```bash
systemctl get-default                     # liat target default
sudo systemctl set-default multi-user.target  # boot ke CLI (hemat resource)
```

### Boot Time Debugging

```bash
systemd-analyze time               # breakdown: kernel → initrd → userspace
systemd-analyze blame              # per-service startup time
systemd-analyze critical-chain     # critical path — service paling lambat
```

---

## 11. Target & Runlevel Mapping — SysV Compatibility

Systemd **target** menggantikan SysV **runlevel**. Ini tabel mapping buat migrasi mental dari sistem lama:

| SysV Runlevel | Systemd Target | Fungsi | Status |
|:---:|:---:|---|---|
| 0 | `poweroff.target` | Shutdown system | Direct mapping |
| 1 | `rescue.target` | Single-user mode, minimal filesystem | Mirip |
| 2 | `multi-user.target` | Debian/Ubuntu default multi-user | Custom di Debian |
| 3 | `multi-user.target` | RHEL/Fedora multi-user (text mode) | Direct mapping |
| 4 | `multi-user.target` | Custom (jarang dipake) | Unused |
| 5 | `graphical.target` | Multi-user + display manager | Direct mapping |
| 6 | `reboot.target` | Reboot system | Direct mapping |

### Perubahan Perintah

| SysV | Systemd |
|------|---------|
| `init 3` | `systemctl isolate multi-user.target` |
| `init 5` | `systemctl isolate graphical.target` |
| `telinit q` | `systemctl daemon-reload` |
| `/etc/inittab` | `/etc/systemd/system/default.target` symlink |

### Compatibility Layer

Systemd tetap jalanin script SysV di `/etc/init.d/` via `systemd-sysv-generator` — tapi gak direkomendasikan. Generator ini bikin `.service` unit otomatis dari script SysV yang gak punya systemd unit.

```bash
# Cek apakah service masih pake SysV fallback
systemctl show rc-local.service | grep -E '(LoadState|FragmentPath)'
# Kalo pake SysV → FragmentPath bakal nunjuk /etc/init.d/
```

> [!warning] Systemd akan **nge-skip** service yang unitnya udah ada versi native systemd. Jadi SysV script cm fallback — prioritas selalu `.service` file.

---

## 12. Dependency Resolution — After vs Requires vs Wants vs BindsTo

Ini salah satu sumber confusion terbesar. Empat directive dependency punya behavior yang berbeda secara fundamental:

### `After=` — Ordering Only

```ini
[Unit]
After=postgresql.service
```

- **Jaminan order**: myapp start **setelah** PostgreSQL.
- **Gak jamin PostgreSQL start**: kalo PostgreSQL gagal, myapp tetap jalan.
- Cocok buat: Ordering tanpa hard dependency — "kalo dia ada, jalanin dulu".

### `Requires=` — Hard Start Dependency

```ini
[Unit]
Requires=redis.service
```

- **Wajib start bareng**: systemd start redis sebelum myapp.
- **Kalo gagal → myapp gagal**: kalo redis gagal start, myapp juga gagal.
- **Tapi gak jamin order**: systemd bisa start keduanya paralel. Kombinasikan dengan `After=` kalo perlu urutan tertentu.
- **Kalo stop**: redis stop → myapp **gak otomatis** stop. (Beda sama BindsTo)

### `Wants=` — Soft Dependency

```ini
[Unit]
Wants=postgresql.service
```

- **Coba start**: systemd usahain start PostgreSQL.
- **Kalo gagal → myapp tetap jalan**: PostgreSQL failure gak ngaruh ke myapp.
- Default buat `WantedBy=` di `[Install]` section — `multi-user.target` Wants semua service.

### `BindsTo=` — Lifecycle Binding

```ini
[Unit]
BindsTo=redis.service
```

- **Semua fitur Requires**: PostgreSQL wajib start, kalo gagal myapp gagal.
- **+ Auto-stop**: kalo redis stop (sengaja atau crash), myapp otomatis stop.
- **+ Auto-restart**: kalo redis restart, myapp ikut restart.
- Cocok buat: Service yang gak punya arti tanpa dependency-nya (e.g., aplikasi yang butuh Redis cache).

### Summary Decision Matrix

| Directive | Start Dependency | Order Guarantee | Propagation (Failure) | Propagation (Stop) |
|-----------|:---:|:---:|:---:|:---:|
| `After=` | ❌ | ✅ | ❌ | ❌ |
| `Wants=` | ✅ (soft) | ❌ | ❌ | ❌ |
| `Requires=` | ✅ (hard) | ❌ | ✅ (start failure → stop) | ❌ |
| `BindsTo=` | ✅ (hard) | ❌ | ✅ | ✅ (stop both) |

### Pola Umum

```ini
# Typical web app with DB
[Unit]
Description=Web Application
After=network-online.target postgresql.service redis.service
Wants=postgresql.service
BindsTo=redis.service
```

---

## 13. systemd-analyze Plot — Visual Boot Analysis

Output `systemd-analyze plot > boot.svg` ngasih timeline grafis boot process. Ini cara bacanya:

### Anatomi SVG Plot

```
Kernel (biru) ───────────────────────────┐
initrd (hijau) ──────────────────────┐    │
Userspace (merah) ───────────────────┤    │
                                      │    │
Unit-Name              ████████████░░░░░░░░░  [Activation]
Service A              ██████████░░░░░░░░░░   [Running + Config]
Service B                 ████████████░░░░░
```

### Warna Bar

| Warna | Arti |
|-------|------|
| **Biru** | Kernel boot — dari bootloader sampai initramfs |
| **Hijau** | initramfs — driver load, filesystem mount |
| **Merah** | Userspace — target/service startup |
| **Abu-abu/garis** | Idle time — nunggu dependency atau device |

### Bar Segments

Tiap bar unit punya dua bagian:
1. **Solid bar (████)** — Activation time (ExecStart, mounting, device detection)
2. **Dotted/empty bar (░░░)** — Config time (parsing unit file, setting up cgroups)

### Baca Masalah dari Plot

| Pola | Interpretasi | Fix |
|------|--------------|-----|
| Satu bar panjang >30s | Service slow start | Cek ExecStart, log service |
| Celah kosong sebelum service penting | Idle nunggu dependency | Tambah `After=` explicit |
| Banyak service start serial (berurutan padahal gak dependent) | Dependency gak optimal | Kurang `After=` — biar paralel |
| initrd bar panjang | Driver storage lambat | Dracut config, module unload |
| Kernel bar panjang | Hardware init lambat | Kernel param, modprobe |

### Export & Share

```bash
# HTML interactive (systemd v254+)
systemd-analyze plot > boot.html

# Plain text untuk sharing di terminal
systemd-analyze blame | head -20
systemd-analyze critical-chain
```

---

## 14. Emergency Recovery — Rescue & Emergency Targets

Saat system gagal boot atau service critical rusak, systemd nyediain dua target recovery.

### rescue.target — Single-User Mode

```bash
# Dari GRUB: tambah parameter ke kernel line
systemd.unit=rescue.target

# Atau kalo masih bisa akses shell
sudo systemctl isolate rescue.target
```

- Mount filesystem **read-only** (kecuali `/proc`, `/sys`)
- Root shell sebagai `root` (tanpa password prompt di Fedora/Debian)
- **Gak** start network service
- Cocok buat: **fsck manual, config fix, mount troubleshoot**

### emergency.target — Minimal Shell

```bash
# Bahkan lebih minimal dari rescue
systemd.unit=emergency.target
```

- **Hanya** root filesystem di-mount (read-only)
- **Gak** ada service, **gak** ada network, **gak** ada udev
- Shell langsung di `/dev/console`
- Cocok buat: **Root filesystem corrupted, /etc fstab broken**

### GRUB Recovery Entry

```bash
# Tambah entry manual di GRUB:
# 1. Waktu boot, tekan 'e' di menu GRUB
# 2. Cari baris linux /vmlinuz-...
# 3. Tambah di akhir:
systemd.unit=emergency.target
# 4. Ctrl+X atau F10 buat boot
```

### Additional Kernel Parameters

| Parameter | Efek |
|-----------|------|
| `systemd.unit=rescue.target` | Boot ke maintenance mode |
| `systemd.unit=emergency.target` | Boot ke emergency shell |
| `systemd.mask=network.target` | Skip network secara global |
| `systemd.wants=...` | Force start service tertentu |
| `systemd.debug-shell` | Buka shell interaktif di tty9 selama boot |
| `1` atau `single` | SysV compatibility — fallback ke rescue.target |

### Systemctl Emergency Commands

```bash
sudo systemctl rescue         # switch ke rescue mode (broadcast warning)
sudo systemctl emergency      # switch ke emergency (langsung)
sudo systemctl isolate rescue.target
```

> [!danger] Rescue/emergency mode unmount filesystem. Pastikan **sync** dulu sebelum isolate.

---

## 15. Security Namespace Hardening — PrivateTmp, PrivateDevices, ProtectSystem

Salah satu kekuatan systemd adalah kemampuan **namespace isolation** per-service tanpa container. Ini bedah detail tiga directive utama:

### PrivateTmp=yes

Bikin namespace `/tmp` dan `/var/tmp` terpisah per service.

```bash
# Sebelum: semua service liat /tmp yang sama
# Sesudah: tiap service punya /tmp sendiri
```

- Implementasi: **Mount namespace** + `pam_namespace`-style bind mount
- Service A gak bisa liat file temporary service B
- File yang dibuat di `/tmp` otomatis cleanup pas service stop
- Cocok buat: **Service yang handle sensitive data sementara**

```ini
[Service]
PrivateTmp=yes
```

```bash
# Verifikasi
lsns -t mnt | grep myapp.service   # liat namespace terisolasi
```

### PrivateDevices=yes

Batasi akses ke device nodes — service cuma liat `/dev/null`, `/dev/zero`, `/dev/random`, `/dev/urandom`, `/dev/full`.

```bash
# Service gak bisa:
# - Akses /dev/sda (disk raw)
# - Akses /dev/tty* (terminal)
# - Akses /dev/dri (GPU)
# - Akses /dev/snd (audio)
# Yang bisa: /dev/null, /dev/zero, /dev/random, /dev/full
```

- Implementasi: **Device cgroup (cgroup v1 BPF atau eBPF)**, bukan mount namespace
- Efektif blokir **direct disk access** dari service
- Cocok buat: **Daemon yang gak perlu hardware access — web server, API**

```ini
[Service]
PrivateDevices=yes
```

### ProtectSystem=full

Membuat `/usr` dan `/etc` read-only untuk service. Tiga level:

| Level | Efek |
|-------|------|
| `ProtectSystem=no` | Default — full access |
| `ProtectSystem=yes` | `/usr` dan `/etc` read-only |
| `ProtectSystem=full` | `/usr`, `/etc`, **dan** `/usr/share` read-only |
| `ProtectSystem=strict` | **Seluruh filesystem** read-only kecuali yang di-explicit `ReadWritePaths=` |

- Implementasi: **Mount namespace** + `MS_RDONLY` bind mount
- `/var` tetap writable (kecuali strict) — cocok buat log dan data
- Cocok buat: **Service yang gak perlu install/update file sistem**

```ini
[Service]
ProtectSystem=full
# Tambah path yang tetap writable
ReadWritePaths=/var/lib/myapp
```

### Namespace Chain — Kombinasi untuk Maximum Isolation

```ini
[Service]
PrivateTmp=yes
PrivateDevices=yes
ProtectSystem=full
ProtectHome=yes
NoNewPrivileges=yes
PrivateUsers=yes           # user namespace — root di dalam ≠ root di luar
ProtectKernelTunables=yes  # /sys dan /proc/sys read-only
ProtectControlGroups=yes   # /sys/fs/cgroup read-only
```

---

## 16. systemd-coredump — Core Dump Management

Systemd menangani core dump via `systemd-coredump` — lebih rapi daripada kernel core_pattern tradisional.

### Konfigurasi

```ini
# /etc/systemd/coredump.conf
[Coredump]
Storage=external              # simpan di /var/lib/systemd/coredump/
Compress=yes
ProcessSizeMax=2G
ExternalSizeMax=2G
JournalSizeMax=500M
KeepFree=10G
```

| Storage Value | Behavior |
|:---:|---|
| `none` | Jangan simpan — langsung discard |
| `external` | Simpan ke `/var/lib/systemd/coredump/` + log metadata ke journal |
| `journal` | Simpan langsung di journald (hati-hati — journal size cepet gede) |
| `both` | Simpan ke file eksternal + metadata ke journal |

### Melihat Core Dump

```bash
# List semua core dump
coredumpctl list

# Format:
# TIME                          PID   UID   GID  SIG PRESENT EXE
# Thu 2026-07-30 14:22:01 WIB  3421  1000  1000  11  *       /usr/bin/myapp

# Detail dump tertentu (interactive)
coredumpctl info

# Extract core file for GDB
coredumpctl dump 3421 > /tmp/core.3421
gdb /usr/bin/myapp /tmp/core.3421

# Or one-liner — langsung debug
coredumpctl debug 3421
```

### Matikan Core Dump (Production)

```bash
# Temporer — per shell
ulimit -c 0

# Permanen — semua service
sudo cat > /etc/systemd/coredump.conf.d/disable.conf << 'EOF'
[Coredump]
Storage=none
ProcessSizeMax=0
EOF
sudo systemctl restart systemd-coredump.socket
```

### Analisa Journal Core Dump

```bash
# Cari service yang crash
journalctl -u myapp.service -p err

# Dengan full stack trace
coredumpctl info myapp.service
```

---

## 17. systemd-logind — Session & Seat Management

`systemd-logind` handle user session lifecycle, seat (physical console) tracking, dan multi-user desktop management.

### Session Tracking

Setiap login session — baik TTY, SSH, atau display manager — direkam:

```bash
loginctl list-sessions        # semua session aktif
loginctl list-users           # user dengan session aktif
loginctl show-session <id>    # detail session (seat, tty, display)
loginctl show-user <username> # detail user + session state
```

| Session Type | Identifier |
|:---:|:---:|
| TTY login (Alt+F1-F6) | `tty2`, `tty3` |
| SSH session | `ssh` (via PAM) |
| Graphical desktop | `seat0` — display manager (GDM/SDDM) |
| `machinectl` | Container session |

### Seat Management

Seat adalah kumpulan hardware (keyboard, mouse, monitor) yang dipake satu user.

```bash
loginctl list-seats              # semua seat
loginctl seat-status seat0       # detail seat (devices, session aktif)
loginctl attach seat0 /dev/input/event3  # assign device ke seat

# Multi-seat (dua orang pake PC bareng):
# seat0 = main monitor + keyboard
# seat1 = second monitor + keyboard via USB
```

### Session Control

```bash
# Lock/unlock session
loginctl lock-session <id>      # lock screen
loginctl unlock-session <id>    # unlock
loginctl lock-sessions          # lock semua session user ini
loginctl unlock-sessions        # unlock semua

# Terminate session
loginctl kill-session <id>      # kill proses di session
loginctl terminate-session <id> # force terminate session
sudo loginctl terminate-user <username>  # kick semua session user
```

### Integration with Systemd

```bash
# User service — service yang jalan di session user
systemctl --user list-units     # user-scoped services
journalctl --user -u myapp.service  # log user service

# Lingering — biarkan user service jalan meski user logout
sudo loginctl enable-linger <username>
```

---

## 18. SysVinit to Systemd — Migration Patterns

Buat sysadmin yang migrate service dari sistem SysVinit lawas (CentOS 6, Debian 7, Ubuntu 14.04) ke systemd.

### Typical SysVinit Script → Systemd Mapping

```bash
# SysV: /etc/init.d/myapp
#!/bin/bash
# chkconfig: 2345 80 20
# description: My Legacy App

start() {
    /usr/bin/myapp --daemon --config /etc/myapp.conf
}
case "$1" in
    start) start ;;
    stop) killall myapp ;;
    restart) stop; start ;;
esac
```

```ini
# Systemd: /etc/systemd/system/myapp.service
[Unit]
Description=My Legacy App Migration

[Service]
Type=forking                # karena script pake --daemon
ExecStart=/usr/bin/myapp --daemon --config /etc/myapp.conf
ExecStop=/usr/bin/killall myapp
PIDFile=/var/run/myapp.pid   # penting buat Type=forking!
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

### Migration Checklist

| SysV Concept | Systemd Equivalent |
|:---|---|
| `chkconfig: 2345 80 20` | `WantedBy=multi-user.target` + priority implicit via dependency graph |
| `/etc/init.d/service status` | `systemctl status service` |
| `/etc/init.d/service restart` | `systemctl restart service` |
| LSB headers (`Provides:`, `Required-Start:`) | `After=`, `Requires=`, `Wants=` |
| `--daemon` / `daemonize()` | `Type=forking` + `PIDFile=` |
| `/var/lock/subsys/` | Tidak perlu — systemd track via cgroup |
| `lockfile` / `flock` | `PrivateTmp=yes` + file-based locking |
| `insserv` / `update-rc.d` | `systemctl enable/disable` |
| SysV priority (Sxx/Kxx) | `After=` / `Before=` explicit |

### Migration Step by Step

```bash
# 1. Cek apakah ada SysV fallback
systemctl show myapp.service | grep FragmentPath
# Kalo nunjuk /etc/init.d/ → masih pake fallback

# 2. Generate unit file dari SysV (starter)
systemctl cat myapp.service    # liat hasil auto-generate

# 3. Buat unit file manual
sudo cat > /etc/systemd/system/myapp.service << 'EOF'
[Unit]
Description=MyApp (migrated from SysV)
After=network.target

[Service]
Type=forking
ExecStart=/etc/init.d/myapp start
ExecStop=/etc/init.d/myapp stop
ExecReload=/etc/init.d/myapp reload
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF

# 4. Aktivasi
sudo systemctl daemon-reload
sudo systemctl enable --now myapp.service

# 5. Verifikasi
systemctl status myapp.service
journalctl -u myapp.service

# 6. Kalo OK, hapus SysV script
sudo rm /etc/init.d/myapp
sudo systemctl daemon-reload   # biar systemd gak fallback lagi
```

### Pitfall: Type=forking Tanpa PIDFile

Kesalahan paling umum — `Type=forking` tanpa `PIDFile=`:

```ini
[Service]
Type=forking
ExecStart=/usr/sbin/daemonize -p /var/run/myapp.pid /usr/bin/myapp
PIDFile=/var/run/myapp.pid
```

**Konsekuensi**: systemd gak tau PID proses utama → `ExecStop` dan `Restart=` gak bekerja dengan benar.

### Converter Tool

```bash
# systemd-sysv-generator jalan otomatis — hasilnya:
ls /run/systemd/generator.late/*.service   # auto-generated SysV → systemd
```

---

## 19. Koneksi ke Vault

| Catatan | Koneksi |
|---------|---------|
| [[linux-hardening-audit-praktis]] | Service hardening di catatan itu pakai systemd properties — note ini bedah detailnya |
| [[linux-fundamentals-deepdive]] | Fondasi OS — prerequisite understanding kernel, cgroups, namespaces |
| [[hierarchy-operating-systems]] | Posisi systemd di OS hierarchy (userspace init) |
| [[linux-hardening-cis]] | CIS benchmark — systemd bagian dari Level 1 hardening |
| [[observability-stack-prometheus-grafana]] | journald metrics → Prometheus via node_exporter |
| [[vps-hardening-playbook]] | Hardening VPS — enable/disable services via systemctl |

## References

1. systemd Documentation — https://www.freedesktop.org/software/systemd/man/
2. systemd.exec(5) — Service execution config — https://www.freedesktop.org/software/systemd/man/systemd.exec.html
3. systemd.timer(5) — Timer unit — https://www.freedesktop.org/software/systemd/man/systemd.timer.html
4. systemd.socket(5) — Socket activation — https://www.freedesktop.org/software/systemd/man/systemd.socket.html
5. journalctl(1) — Journal query tool — https://www.freedesktop.org/software/systemd/man/journalctl.html
6. Fedora Systemd Docs — https://docs.fedoraproject.org/en-US/quick-docs/systemd/
7. systemd.io portal — https://systemd.io/