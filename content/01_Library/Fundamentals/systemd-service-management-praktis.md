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

| Tipe          | Ekstensi     | Fungsi                      | Contoh                              |
| ------------- | ------------ | --------------------------- | ----------------------------------- |
| **Service**   | `.service`   | Daemon / background process | nginx.service, postgresql.service   |
| **Socket**    | `.socket`    | IPC / network socket        | sshd.socket, docker.socket          |
| **Timer**     | `.timer`     | Scheduled task              | fstrim.timer, logrotate.timer       |
| **Mount**     | `.mount`     | Mount point                 | home.mount, boot.mount              |
| **Automount** | `.automount` | On-demand mount             | mnt-data.automount                  |
| **Path**      | `.path`      | File/directory trigger      | cups.path                           |
| **Slice**     | `.slice`     | Resource control group      | machine.slice, system.slice         |
| **Target**    | `.target`    | Group of units (runlevel)   | multi-user.target, graphical.target |
| **Scope**     | `.scope`     | Externally created process  | user@1000.service (user scope)      |
| **Device**    | `.device`    | Kernel device               | sys-devices-pci...device            |
| **Swap**      | `.swap`      | Swap partition              | swapfile.swap                       |
| **Network**   | `.network`   | Network configuration       | 50-dhcp.network                     |

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

| Type      | Behavior                                           | Cocok untuk                         |
| --------- | -------------------------------------------------- | ----------------------------------- |
| `simple`  | ExecStart langsung jalan, systemd anggap "started" | Node.js, Python, long-running shell |
| `forking` | Parent exit, child lanjut (daemon)                 | MySQL, Nginx, PostgreSQL            |
| `oneshot` | Jalan sekali lalu exit                             | Script setup, cleanup               |
| `dbus`    | Tunggu bus name di D-Bus                           | NetworkManager, systemd-resolved    |
| `notify`  | Panggil `sd_notify()` setelah siap                 | Aplikasi yang pake libsystemd       |
| `idle`    | Simple, tapi delay sampai semua job selesai        | Print banner, welcome message       |

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

| Pattern             | Makna                  | Contoh Next                   |
| ------------------- | ---------------------- | ----------------------------- |
| `daily`             | Setiap hari 00:00      | `Thu 2026-07-31 00:00:00 WIB` |
| `hourly`            | Setiap jam :00         | `Thu 2026-07-30 10:00:00 WIB` |
| `*-*-* 03:00:00`    | Setiap hari jam 3 pagi | `Thu 2026-07-31 03:00:00 WIB` |
| `Mon..Fri 08:30:00` | Weekdays jam 8:30      | `Fri 2026-08-01 08:30:00 WIB` |
| `Sat,Sun 00:00:00`  | Weekend midnight       | `Sat 2026-08-02 00:00:00 WIB` |
| `*:0/15`            | Setiap 15 menit        | `Thu 2026-07-30 09:15:00 WIB` |
| `*-01-01 00:00:00`  | Setiap tahun baru      | `Fri 2027-01-01 00:00:00 WIB` |

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

| Skenario            | Manual                   | Socket Activation             |
| ------------------- | ------------------------ | ----------------------------- |
| SSH diakses jarang  | Jalan 24/7, makan memory | Start saat ada koneksi SSH    |
| Container socket    | Docker socket listen     | Start dockerd pas ada request |
| Web app low traffic | Nginx selalu jalan       | Start saat request masuk      |

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

| Directive                     | Efek                                         | Level    |
| ----------------------------- | -------------------------------------------- | -------- |
| `ProtectSystem=full`          | Read-only /usr, /etc                         | Wajib    |
| `ProtectHome=yes`             | Gak bisa akses /home, /root                  | Wajib    |
| `PrivateTmp=yes`              | /tmp terisolasi                              | Wajib    |
| `NoNewPrivileges=yes`         | Gak bisa suid/sgid                           | Wajib    |
| `CapabilityBoundingSet=...`   | Batasi Linux capabilities                    | Medium   |
| `SystemCallFilter=~@debug`    | Block syscall berbahaya                      | Medium   |
| `PrivateDevices=yes`          | Gak liat /dev (kecuali /dev/null, /dev/zero) | Tinggi   |
| `ProtectKernelModules=yes`    | Block insmod/modprobe                        | Tinggi   |
| `MemoryDenyWriteExecute=yes`  | Prevent W+X memory pages                     | Tinggi   |
| `RestrictAddressFamilies=...` | Batasi network domains                       | Tinggi   |
| `LockPersonality=yes`         | Prevent exec domain change                   | Maksimal |

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

| SysV Runlevel |  systemd Target   | Fungsi                                |
| :-----------: | :---------------: | :------------------------------------ |
|       0       |  poweroff.target  | Shutdown                              |
|     1 / S     |   rescue.target   | Single-user mode, minimal             |
|       2       | multi-user.target | Multi-user tanpa GUI (debian turunan) |
|       3       | multi-user.target | Multi-user, text-only                 |
|       4       | multi-user.target | Custom (jarang dipake)                |
|       5       | graphical.target  | Multi-user + GUI                      |
|       6       |   reboot.target   | Reboot                                |
|   emergency   | emergency.target  | Rescue shell, root fs ro              |

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

| Directive            | Effect                     | Behavior if fails             |
| -------------------- | -------------------------- | ----------------------------- |
| `After=A.service`    | Order: start AFTER A       | A gagal, service tetap start  |
| `Before=A.service`   | Order: start BEFORE A      | Kebalikan After               |
| `Requires=A.service` | Hard dep: A harus jalan    | A gagal → service gagal       |
| `Wants=A.service`    | Soft dep: usahakan A jalan | A gagal → service tetap jalan |
| `BindsTo=A.service`  | Lifecycle bond             | A stop → service stop         |

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

| Parameter                                 | Efek                            |
| ----------------------------------------- | ------------------------------- |
| `systemd.unit=rescue.target`              | Boot ke rescue                  |
| `systemd.unit=emergency.target`           | Boot ke emergency               |
| `systemd.log_level=debug`                 | Log systemd dengan debug level  |
| `systemd.log_target=console`              | Log ke console (gak ke journal) |
| `systemd.journald.forward_to_console=yes` | Journald output ke console      |
| `systemd.mask=network.service`            | Mask service tertentu saat boot |

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

| Isolation          |    Cache effect     | Notable impact               |
| ------------------ | :-----------------: | :--------------------------- |
| PrivateTmp         |    Session-based    | tmp file gak survive restart |
| ProtectSystem=full |          —          | Gak bisa write ke /etc       |
| ProtectHome=yes    | SSH key gak terbaca | Home SSH key auth            |
| PrivateDevices     |          —          | Gak bisa akses GPU/device    |

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

## 10. Koneksi ke Vault

| Catatan                                    | Koneksi                                                                              |
| ------------------------------------------ | ------------------------------------------------------------------------------------ |
| [[linux-hardening-audit-praktis]]          | Service hardening di catatan itu pakai systemd properties — note ini bedah detailnya |
| [[linux-fundamentals-deepdive]]            | Fondasi OS — prerequisite understanding kernel, cgroups, namespaces                  |
| [[hierarchy-operating-systems]]            | Posisi systemd di OS hierarchy (userspace init)                                      |
| [[linux-hardening-cis]]                    | CIS benchmark — systemd bagian dari Level 1 hardening                                |
| [[observability-stack-prometheus-grafana]] | journald metrics → Prometheus via node_exporter                                      |
| [[vps-hardening-playbook]]                 | Hardening VPS — enable/disable services via systemctl                                |

## References

1. systemd Documentation — https://www.freedesktop.org/software/systemd/man/
2. systemd.exec(5) — Service execution config — https://www.freedesktop.org/software/systemd/man/systemd.exec.html
3. systemd.timer(5) — Timer unit — https://www.freedesktop.org/software/systemd/man/systemd.timer.html
4. systemd.socket(5) — Socket activation — https://www.freedesktop.org/software/systemd/man/systemd.socket.html
5. journalctl(1) — Journal query tool — https://www.freedesktop.org/software/systemd/man/journalctl.html
6. Fedora Systemd Docs — https://docs.fedoraproject.org/en-US/quick-docs/systemd/
7. systemd.io portal — https://systemd.io/
