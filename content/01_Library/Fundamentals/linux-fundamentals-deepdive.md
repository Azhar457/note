---
title: "Linux Fundamentals — Deep Dive: Processes, Systemd, Filesystem, Users, Shell,
  Package Management"
tags:
  - fundamentals
  - linux
  - os
  - library
created: "2026-07-16"
updated: "2026-07-16"
status: pending
cssclasses:
  - wide-table
---

# 🐧 Linux Fundamentals — Deep Dive: Processes, Systemd, Filesystem, Users, Shell, Package Management

> Panduan komprehensif administrasi dan internal Linux untuk security engineer. Vault ini sangat Linux-heavy — [[ebpf-kernel-security]], [[container-kubernetes-security-deepdive]], [[linux-hardening-cis]], [[infrastructure-administrator]], [[ebpf-beyond-security]] — tapi semuanya menganggap lo udah paham dasar Linux. Catatan ini nge-fill gap itu: processes & signals, systemd (units, services, timers, journalctl), filesystem hierarchy (FHS), permission model (ugo, ACL, chattr, capabilities), user & group management, PAM, namespaces & cgroups (fondasi container), package management (apt/dnf/pacman in depth), shell scripting essentials, dan performance troubleshooting. Tanpa ini, lo cuma bisa ikutin tutorial tanpa ngerti kenapa.

> [!info] Posisi di Vault
> Ini adalah **fondasi OS** untuk semua catatan yang berjalan di Linux. Baca ini dulu sebelum [[linux-hardening-cis]] (security hardening), [[infrastructure-administrator]] (ops), [[ebpf-kernel-security]] (kernel tracing), [[container-kubernetes-security-deepdive]] (container isolation), dan [[podman-networking-ufw]] (container networking). [[computer-science-foundations]] adalah prasyarat OS internals level kernel — ini lebih ke userspace administration.

---

## Daftar Isi

- [[#Filesystem Hierarchy]]
- [[#Permission Model]]
- [[#Users & Groups]]
- [[#Processes & Signals]]
- [[#Systemd]]
- [[#Package Management]]
- [[#Storage & Filesystems]]
- [[#Networking Essentials]]
- [[#Shell Scripting Essentials]]
- [[#Performance Troubleshooting]]
- [[#Namespaces & Cgroups]]
- [[#PAM — Pluggable Authentication Modules]]
- [[#Checklist]]
- [[#Koneksi ke Vault]]
- [[#References]]

---

## Filesystem Hierarchy

### FHS (Filesystem Hierarchy Standard)

```
/                   → Root — induk semua
├── bin/            → Essential user binaries (ls, cp, cat, bash) — /usr/bin symlink di modern
├── sbin/           → System binaries (fdisk, mkfs, iptables) — /usr/sbin symlink
├── etc/            → Konfigurasi sistem (hostname, resolv.conf, fstab, shadow, nginx/)
├── usr/            → UNIX System Resources — aplikasi, libraries, docs, source
│   ├── bin/        → User binaries (yang bukan essential buat boot)
│   ├── lib/        → Libraries
│   ├── share/      → Architecture-independent data (man pages, icons)
│   └── local/      → Software yang di-compile manual (prefix /usr/local)
├── var/            → Variable data — berubah seiring waktu
│   ├── log/        → Semua log (syslog, auth.log, nginx/, mysql/)
│   ├── lib/        → Database state, package manager state
│   ├── spool/      → Print queues, cron jobs, mail
│   ├── cache/      → Cache data (apt cache, pip cache)
│   └── tmp/        → Temporary files — survive reboot (beda sama /tmp)
├── tmp/            → Temporary files — dibersihkan setiap boot
├── dev/            → Device files (/dev/sda, /dev/null, /dev/random)
├── proc/           → Pseudofilesystem — kernel & process info (PID = directory)
├── sys/            → Pseudofilesystem — kernel device tree & configuration
├── run/            → Runtime variable data (PID files, sockets) — tmpfs
├── home/           → Home direktori user
├── root/           → Home direktori root (bukan di /home)
├── opt/            → Optional / third-party software (Docker, Chrome, VBox)
├── srv/            → Service data (web server files, FTP)
└── mnt/            → Mountpoint sementara (manual mount)
```

### /proc — Kernel & Process Information

`/proc` adalah **pseudofilesystem** — file di sini gak ada di disk, tapi dibuat oleh kernel saat lo read:

```bash
# System info
cat /proc/cpuinfo     # CPU specs (cores, flags, model)
cat /proc/meminfo     # Memory (total, free, cached, buffers)
cat /proc/uptime      # Uptime (detik sejak boot)
cat /proc/loadavg     # Load average (1, 5, 15 menit)
cat /proc/version     # Linux kernel version
/proc/sys/            # Kernel tunable parameters (sysctl)

# Process-specific (PID)
ls /proc/1/           # Init/systemd process
ls /proc/$$/          # Proses current shell
cat /proc/1/cmdline   # Command line process 1
ls /proc/1/fd/        # File descriptors (fd = file descriptor)
ls /proc/1/map_files/ # Memory mapping
cat /proc/1/environ   # Environment variables
ls /proc/1/ns/        # Namespaces (net, mnt, pid, user, uts, ipc, cgroup)
cat /proc/1/status    # Status (Name, Pid, PPid, Uid, Gid, VmSize, Threads, Cap...)
cat /proc/1/cgroup    # Cgroups membership
```

### /sys — Kernel Device & Driver Info

```bash
ls /sys/class/net/    # Network interfaces
ls /sys/block/        # Block devices
ls /sys/class/drm/    # GPU
cat /sys/class/thermal/thermal_zone*/temp  # Temperatures
```

---

## Permission Model

### Standard Unix Permissions (ugo/rwx)

```bash
# Format: drwxr-xr-x
#         ││││││││││
#         │└┴┴┘└┴┴┘└┴┴┘
#  Type  │  │  │  │  │  └ Other (world) execute (x)
#         │  │  │  └── Other read (r)
#         │  │  └───── User execute (x)
#  r=read │  │  └ Group read
#  w=write│  └── Group execute (x)
#  x=exec └──User (owner) execute
```

| Tipe             | Karakter | Contoh       |
| ---------------- | -------- | ------------ |
| Regular file     | `-`      | `-rw-r--r--` |
| Directory        | `d`      | `drwxr-xr-x` |
| Symlink          | `l`      | `lrwxrwxrwx` |
| Socket           | `s`      | `srwxrwxrwx` |
| Named pipe       | `p`      | `prw-r--r--` |
| Block device     | `b`      | `brw-r-----` |
| Character device | `c`      | `crw-rw-rw-` |

**Numeric (Octal) Representation:**

```
r w x   r - x   r - x
4 2 1   4 0 1   4 0 1
├───┤   ├───┤   ├───┤
 7 5 5  →  rwxr-xr-x
Owner=7  Group=5  Other=5
```

**Special permissions:**

| Bit            | Numerik           | File                                                      | Directory                                 |
| -------------- | ----------------- | --------------------------------------------------------- | ----------------------------------------- |
| **SUID**       | 4xxx (e.g., 4755) | Run sebagai owner file (biasanya root) — `passwd`, `ping` | Ignored                                   |
| **SGID**       | 2xxx (e.g., 2755) | Run sebagai group file                                    | File baru di dalamnya inherit group       |
| **Sticky bit** | 1xxx (e.g., 1777) | Ignored                                                   | Hanya owner yang bisa hapus file — `/tmp` |

```bash
# SUID example
chmod u+s /usr/bin/program   # Set SUID
chmod 4755 /usr/bin/program  # Sama
ls -la /usr/bin/passwd       # -rwsr-xr-x (s di user execute)

# SGID example
chmod g+s /shared/dir        # File baru inherit group

# Sticky bit example
chmod +t /tmp                # Hanya owner file bisa hapus
ls -la /tmp                  # drwxrwxrwt (t di other execute)
```

### Access Control Lists (ACL)

Extend permission beyond ugo:

```bash
# Set ACL: user john read+write access to /data
setfacl -m u:john:rw /data
getfacl /data
# output: user:john:rw-

# Set default ACL: file baru di direktori inherit
setfacl -d -m u:john:rw /shared
```

### Extended Attributes & chattr

```bash
# Immutable — tidak bisa diubah/dihapus bahkan oleh root
chattr +i /etc/hosts
lsattr /etc/hosts  # ----i--------

# Append-only — cuma bisa append
chattr +a /var/log/syslog

# Undeletable — prevent root dari accidental rm
chattr +i critical_data.txt
```

### Linux Capabilities

Pecah privilege root jadi unit-unit kecil:

```bash
# List capabilities
capsh --print

# Set capabilities on binary — tanpa SUID
setcap cap_net_bind_service=+ep /usr/bin/myapp
# Binary bisa bind port <1024 tanpa root

# Common capabilities:
# CAP_NET_BIND_SERVICE — bind port <1024
# CAP_NET_RAW — raw socket (ping, scapy)
# CAP_SYS_ADMIN — "root" capability (hati-hati!)
# CAP_SYS_PTRACE — ptrace proses lain
# CAP_DAC_OVERRIDE — bypass file permission

# Run command with specific caps
 capsh --caps="cap_net_bind_service+eip" -- -c "python -m http.server 80"
```

---

## Users & Groups

### Files

| File           | Fungsi                        | Format                                                     |
| -------------- | ----------------------------- | ---------------------------------------------------------- |
| `/etc/passwd`  | User accounts                 | `username:x:UID:GID:info:home:shell`                       |
| `/etc/shadow`  | Password hash                 | `username:$y$hash:lastchange:min:max:warn:inactive:expire` |
| `/etc/group`   | Groups                        | `groupname:x:GID:user1,user2`                              |
| `/etc/gshadow` | Group passwords               | Jarang dipake                                              |
| `/etc/subuid`  | Subordinate UIDs (containers) | `user:100000:65536`                                        |
| `/etc/shells`  | Valid shells                  | Daftar path shell yang valid                               |

**Hash format di /etc/shadow:**

| Prefix | Algoritma | Status                                      |
| ------ | --------- | ------------------------------------------- |
| `$y$`  | yescrypt  | 🟢 Modern — default di Debian/Ubuntu modern |
| `$6$`  | SHA-512   | 🟡 OK — masih banyak dipake                 |
| `$5$`  | SHA-256   | 🟡 OK                                       |
| `$2b$` | bcrypt    | 🟢 Good                                     |
| `$1$`  | MD5       | 🔴 Deprecated — jangan                      |

### Commands

```bash
# User management
useradd -m -G wheel,sudo -s /bin/bash john     # Create user + home + groups
usermod -aG docker john                         # Add to group (append)
userdel -r john                                  # Delete user + home
passwd john                                      # Change password
chage -l john                                    # Lihat password expiry
chage -M 90 john                                 # Password max 90 hari

# Group management
groupadd devops                                  # Create group
gpasswd -a john devops                           # Add user to group
gpasswd -d john devops                           # Remove user from group

# Who is doing what
w               # Who is logged in + what they're doing
who             # Who is logged in
last            # Last logins (from /var/log/wtmp)
lastb           # Failed login attempts (from /var/log/btmp)
lastlog         # Last login per user
id              # UID, GID, groups
groups          # Groups current user
```

### Password Policy via PAM

```bash
# /etc/pam.d/common-password (Debian)
# Min length 12 chars, remember 5 last passwords
password requisite pam_pwquality.so retry=3 minlen=12
password required pam_unix.so sha512 remember=5
```

---

## Processes & Signals

### Process States

```
R (Running) — sedang jalan atau di run queue
S (Sleeping) — menunggu event (interruptible)
D (Uninterruptible Sleep) — menunggu I/O (tidak bisa di-interrupt)
Z (Zombie) — sudah selesai tapi parent belum wait()
T (Stopped) — di-stop signal (SIGSTOP, SIGTSTP, SIGINT)
X (Dead) — sebentar banget, gak bakal liat di ps
```

### Process Tree

```bash
pstree -a          # Tree view
pstree -p          # With PIDs

# Contoh output:
# systemd───sshd───sshd───bash───pstree
#        ├─nginx───nginx,1234
#        │         └─nginx,1235
#        └─postgres───postgres,2000
#                     ├─postgres,2001
#                     └─postgres,2002
```

### Signals

| Signal      | Number | Default Action            | Use Case                                       |
| ----------- | ------ | ------------------------- | ---------------------------------------------- |
| **SIGHUP**  | 1      | Terminate                 | Reload config (nginx -s reload, kill -HUP PID) |
| **SIGINT**  | 2      | Terminate                 | Ctrl+C — interrupt                             |
| **SIGQUIT** | 3      | Core dump                 | Ctrl+\ — quit + core dump                      |
| **SIGKILL** | 9      | Terminate (cannot catch!) | `kill -9 PID` — force kill                     |
| **SIGTERM** | 15     | Terminate                 | `kill PID` — graceful shutdown                 |
| **SIGSTOP** | 19     | Stop (cannot catch!)      | Ctrl+Z — suspend process                       |
| **SIGCONT** | 18     | Continue                  | `fg` / `bg` — resume                           |

```bash
kill -15 PID       # Graceful shutdown
kill -9 PID        # Force kill (last resort!)
kill -1 PID        # Reload config (jika process support)
killall -9 nginx   # Kill all processes named nginx
pkill -f "python server.py"  # Kill by pattern
```

### /proc/PID

```bash
ls /proc/PID/
# cmdline   — Command line
# cwd/      — Symlink ke working directory
# environ   — Environment variables
# exe       — Symlink ke executable
# fd/       — Open file descriptors (0=stdin, 1=stdout, 2=stderr)
# maps      — Memory mappings
# root/     — Symlink ke filesystem root (jika chroot/container)
# status    — Status (State, Pid, PPid, Uid, Gid, VmSize, Threads, Cap)
# limits    — Resource limits (soft/hard)
# ns/       — Namespaces
```

---

## Systemd

Systemd adalah init system dan service manager default di hampir semua distro modern (Debian 8+, Ubuntu 15+, Fedora, RHEL 7+, Arch).

### Units

Systemd manage **units** — resource yang dikenal systemd:

| Unit Type     | Extension    | Fungsi                                | Contoh                                                 |
| ------------- | ------------ | ------------------------------------- | ------------------------------------------------------ |
| **Service**   | `.service`   | Daemon                                | nginx.service, sshd.service                            |
| **Socket**    | `.socket`    | Socket listening                      | sshd.socket (socket-activated service)                 |
| **Timer**     | `.timer`     | Scheduled task (replacement cron)     | certbot.timer, systemd-tmpfiles-clean.timer            |
| **Mount**     | `.mount`     | Mount point                           | home.mount, var-lib.mount                              |
| **Automount** | `.automount` | On-demand mount                       | mnt-nfs.automount                                      |
| **Path**      | `.path`      | Trigger on file change                | backup.path (trigger backup.service kalo file berubah) |
| **Target**    | `.target`    | Group of units (runlevel replacement) | multi-user.target, graphical.target                    |

### Systemctl Commands

```bash
# Service management
systemctl start nginx         # Start service
systemctl stop nginx          # Stop service
systemctl restart nginx       # Restart
systemctl reload nginx        # Reload config (SIGHUP)
systemctl status nginx        # Status + recent logs
systemctl enable nginx        # Auto-start on boot
systemctl disable nginx       # Remove auto-start
systemctl is-enabled nginx    # Check if enabled
systemctl list-units --type=service --state=running  # Running services

# Journal — logs
journalctl -u nginx           # Logs for nginx service
journalctl -u nginx -f        # Follow (tail -f)
journalctl -u nginx --since "1 hour ago"
journalctl -u nginx -p err    # Only errors
journalctl -k                 # Kernel messages
journalctl --disk-usage       # Log size
journalctl --vacuum-size=100M  # Trim logs to 100MB

# System state
systemctl list-units          # All active units
systemctl list-unit-files     # All installed unit files
systemd-analyze               # Boot time
systemd-analyze blame         # Per-service boot time
systemd-analyze critical-chain  # Boot dependency chain

# Power management
systemctl reboot
systemctl poweroff
systemctl suspend
```

### Example Service Unit

```ini
# /etc/systemd/system/myapp.service
[Unit]
Description=My Custom Application
After=network.target postgresql.service
Requires=postgresql.service
Wants=redis.service  # Optional dependency

[Service]
Type=simple          # Forking, oneshot, notify, dbus, idle
User=myapp
WorkingDirectory=/opt/myapp
ExecStart=/usr/bin/python3 /opt/myapp/server.py
ExecReload=/bin/kill -HUP $MAINPID
Restart=on-failure   # always, on-success, on-abnormal, on-abort, on-watchdog
RestartSec=5
LimitNOFILE=65536
Environment="NODE_ENV=production"
EnvironmentFile=/etc/myapp/env.conf

[Install]
WantedBy=multi-user.target
```

### Timers (Cron Replacement)

```ini
# /etc/systemd/system/backup.timer
[Unit]
Description=Daily Backup

[Timer]
OnCalendar=daily
Persistent=true    # Run immediately if missed (system was off)
RandomizedDelaySec=1800

[Install]
WantedBy=timers.target

# Dan service yang di-trigger:
# /etc/systemd/system/backup.service
[Service]
Type=oneshot
ExecStart=/usr/local/bin/backup.sh
```

```bash
systemctl enable --now backup.timer
systemctl list-timers --all
```

---

## Package Management

### Distro Families

| Family     | Distro                                 | Package Format | Manager            | Low-Level |
| ---------- | -------------------------------------- | -------------- | ------------------ | --------- |
| **Debian** | Debian, Ubuntu, Kali, Mint, Pop!_OS    | `.deb`         | `apt`              | `dpkg`    |
| **RHEL**   | RHEL, Fedora, CentOS, Rocky, AlmaLinux | `.rpm`         | `dnf` (yum legacy) | `rpm`     |
| **SUSE**   | openSUSE, SLES                         | `.rpm`         | `zypper`           | `rpm`     |
| **Arch**   | Arch, Manjaro, EndeavourOS             | `.pkg.tar.zst` | `pacman`           | `pacman`  |
| **Nix**    | NixOS                                  | `.nix`         | `nix`              | `nix`     |

### APT (Debian)

```bash
# Update package index
apt update

# Upgrade
apt upgrade                    # Safe upgrade
apt full-upgrade               # With dependency changes
apt dist-upgrade               # Sama

# Search & install
apt search nginx
apt show nginx
apt install nginx              # Install + dependencies
apt install ./package.deb     # Local .deb

# Remove
apt remove nginx               # Keep config files
apt purge nginx                # Remove everything including config
apt autoremove                  # Remove orphaned dependencies

# List
apt list --installed
apt list --upgradable

# Source
add-apt-repository ppa:nginx/stable
apt-add-repository 'deb http://repo.com/ubuntu focal main'
```

### DNF (RHEL/Fedora)

```bash
dnf update                    # Update package index + upgrade
dnf install nginx
dnf remove nginx
dnf search nginx
dnf info nginx
dnf list installed
dnf list available
dnf provides /usr/bin/ss      # Cari package yang punya file ini
dnf groupinstall "Development Tools"
dnf copr enable user/repo     # Enable COPR repo
```

### Pacman (Arch)

```bash
pacman -Syu                   # Full system update
pacman -S nginx               # Install
pacman -Rs nginx              # Remove + dependencies + config
pacman -Ss nginx              # Search
pacman -Qi nginx              # Info
pacman -Ql nginx              # List files
pacman -F /usr/bin/ss        # File belongs to which package
```

---

## Storage & Filesystems

### Filesystem Types

| FS           | Use Case                               | Max File Size | Max Volume | Journaling | Fitur                                           |
| ------------ | -------------------------------------- | ------------- | ---------- | ---------- | ----------------------------------------------- |
| **ext4**     | General purpose (default Linux)        | 16 TB         | 1 EB       | ✅         | Default, mature, reliable                       |
| **XFS**      | Large files, parallel I/O              | 8 EB          | 8 EB       | ✅         | Good for databases, large files                 |
| **btrfs**    | Advanced: snapshots, compression, RAID | 16 EB         | 16 EB      | ✅         | Snapshot, subvolume, compression, send/receive  |
| **ZFS**      | Enterprise: checksum, pool, dedup      | 16 EB         | 256 ZB     | ✅         | Copy-on-write, checksum all data, built-in RAID |
| **tmpfs**    | RAM-based temporary                    | RAM size      | RAM size   | ❌         | Super fast — /tmp, /dev/shm                     |
| **squashfs** | Compressed RO filesystem               | 16 TB         | 16 TB      | ❌         | Live CD, AppImage, Snap packages                |

### Mount & fstab

```bash
# Mount
mount /dev/sda1 /mnt/data
mount -t tmpfs -o size=2G tmpfs /mnt/ramdisk

# Unmount
umount /mnt/data
umount -l /mnt/data           # Lazy — unmount saat tidak dipake

# fstab format
# <device>    <mountpoint>  <fstype>  <options>  <dump>  <pass>
/dev/sda1     /              ext4      defaults      0       1
UUID=abc123   /boot          ext4      defaults      0       2
/dev/sdb1     /data          xfs       defaults      0       0
192.168.1.10:/export /mnt/nfs nfs4 defaults,_netdev 0 0
tmpfs         /tmp           tmpfs     defaults,size=1G 0 0
```

### Disk & Partition Commands

```bash
lsblk                         # List block devices
fdisk -l                      # Partition table
parted /dev/sda print         # GPT partition info
blkid                         # UUID + filesystem type
df -h                         # Disk usage (human-readable)
du -sh /var                   # Directory size
ncdu                          # Interactive disk usage (install first)
iostat -xz 1                  # I/O stats per device (1-second intervals)
iotop                         # Per-process I/O (interactive)
```

---

## Networking Essentials

### Interface Configuration

```bash
ip addr                       # IP addresses (replacement ifconfig)
ip link                       # Interface status (up/down, MAC)
ip route                      # Routing table (replacement route -n)
ip neigh                      # ARP table (replacement arp -a)

# Modern vs Legacy:
# ip addr show     vs ifconfig
# ip route show    vs route -n
# ip neigh show    vs arp -a
# ip link set eth0 up vs ifconfig eth0 up

# Interface config (NetworkManager)
nmcli dev status              # Device status
nmcli con show                # Connection profiles
nmcli con up "Wired"         # Activate connection

# /etc/netplan/ (Ubuntu modern) — YAML config
# /etc/sysconfig/network-scripts/ (RHEL legacy)
```

### Network Namespace

```bash
# Create isolated network stack
ip netns add blue             # Create namespace
ip netns exec blue bash       # Run shell in namespace
ip netns exec blue ip addr    # Check interfaces (lo down by default)

# Connect two namespaces via veth pair
ip link add veth0 type veth peer name veth1
ip link set veth0 netns blue
ip netns exec blue ip addr add 10.0.0.1/24 dev veth0
```

### Socket Statistics

```bash
ss -tulpn                     # TCP/UDP listening + process
ss -tan                       # TCP established connections
ss -tan state established     # Only ESTABLISHED
# vs legacy: netstat -tulpn

# Bandwidth monitoring
nload                         # Real-time per-interface bandwidth
iftop                         # Per-connection bandwidth
nethogs                       # Per-process bandwidth
iperf3 -c server -t 30       # Network throughput test
```

---

## Shell Scripting Essentials

### Shebang & Execution

```bash
#!/bin/bash - E           # -e: exit on error
set -euxo pipefail        # Safety options:
                          # -e: exit on error
                          # -u: undefined variable = error
                          # -x: print commands before execution
                          # -o pipefail: pipeline error = non-zero exit

# Make executable
chmod +x script.sh
./script.sh
```

### Variable Expansion & Quoting

```bash
name="World"
echo "Hello $name"        # Double quotes: expands
echo 'Hello $name'        # Single quotes: literal
echo ${name:-default}     # Default if unset
echo ${name:0:3}          # Substring: "Wor"
echo ${name/World/All}    # Replace: "Hello All"
```

### Arrays & Loops

```bash
# Array
files=(*.log)
echo ${files[0]}          # First element
echo ${#files[@]}         # Length
echo ${files[@]}          # All elements

# For loop
for file in /var/log/*.log; do
    echo "Parsing $file"
    wc -l "$file"
done

# While read
while IFS= read -r line; do
    echo "Line: $line"
done < /etc/passwd
```

### Conditionals

```bash
# File test
[ -f /etc/passwd ] && echo "File exists"
[ -d /tmp ] && echo "Directory exists"
[ -x /usr/bin/curl ] || echo "curl not installed"

# String test
[ "$name" = "World" ] && echo "Match"
[ -z "$empty" ] && echo "Empty string"

# Numeric test
[ "$count" -gt 10 ] && echo "More than 10"

# Modern [[ ]] (safer, more features)
[[ "$name" == W* ]] && echo "Starts with W"
[[ "$name" =~ ^W.+d$ ]] && echo "Regex match"
```

### Functions

```bash
log() {
    local level="$1"
    local message="$2"
    echo "[$(date +%H:%M:%S)] [$level] $message"
}

log "INFO" "Processing started"
```

---

## Performance Troubleshooting

```bash
# CPU
top/htop                  # Interactive process viewer
mpstat -P ALL 1           # Per-CPU utilization
pidstat 1                 # Per-process CPU + memory
perf top                  # Real-time profiling (kernel + userspace)

# Memory
free -h                   # RAM + swap usage
vmstat 1                  # Memory, paging, swap, I/O, system, CPU
smem                      # Proportional Resident Set Size
cat /proc/meminfo         # Detailed memory info

# Disk I/O
iostat -xz 1              # Per-device I/O stats
iotop                     # Per-process I/O
fatrace                   # File access trace (which process is writing to disk)

# Network
ss -tulpn                 # Listening ports + process
ss -tan | grep ESTAB      # Active connections
sar -n DEV 1              # Historical network stats
tcpdump -i eth0 port 443  # Packet capture

# System load
uptime                    # Load average (1/5/15 min)
cat /proc/loadavg
dmesg -w                  # Kernel log (watch for OOM, disk errors)
journalctl -k -p err --since "1 hour ago"  # Kernel errors last hour
```

---

## Namespaces & Cgroups

### Linux Namespaces

Namespaces mengisolasi sumber daya — ini fondasi container:

| Namespace  | Constants       | Apa yang Diisolasi                                        | Container Impact                                                                     |
| ---------- | --------------- | --------------------------------------------------------- | ------------------------------------------------------------------------------------ |
| **pid**    | CLONE_NEWPID    | Process ID — proses di dalam cuma lihat prosesnya sendiri | ❌ `kill -9 PID` dari host gak bisa liat proses container                            |
| **net**    | CLONE_NEWNET    | Network stack — interface, IP, routing, iptables          | ✅ Setiap container punya eth0 sendiri, IP sendiri                                   |
| **mnt**    | CLONE_NEWNS     | Mount point — filesystem terisolasi                       | ✅ Root container beda dari host                                                     |
| **uts**    | CLONE_NEWUTS    | Hostname + domain                                         | ✅ Container bisa hostname sendiri                                                   |
| **ipc**    | CLONE_NEWIPC    | IPC resources (System V, POSIX message queues)            | Isolasi komunikasi inter-proses                                                      |
| **user**   | CLONE_NEWUSER   | UID/GID mapping — root di container ≠ root di host        | 🔑 **Kunci keamanan container** — bisa peta UID 0 di container ke UID 100000 di host |
| **cgroup** | CLONE_NEWCGROUP | Cgroup hierarchy                                          | Isolasi resource accounting                                                          |
| **time**   | CLONE_NEWTIME   | Boot time + monotonic clock                               | Isolasi waktu                                                                        |

```bash
# Check namespaces of a process
ls -la /proc/$$/ns/
# lrwxrwxrwx ... cgroup -> cgroup:[4026531835]
# lrwxrwxrwx ... net    -> net:[4026531992]
# ...
```

### Cgroups (Control Groups)

Cgroups membatasi dan meng-account resource per group proses:

```bash
# Cgroup v2 — /sys/fs/cgroup/
# Set memory limit
echo "100M" > /sys/fs/cgroup/myapp/memory.max
echo $PID > /sys/fs/cgroup/myapp/cgroup.procs

# Set CPU limit (100000 = 1 core)
echo "50000" > /sys/fs/cgroup/myapp/cpu.max  # 0.5 core

# Check memory usage
cat /sys/fs/cgroup/myapp/memory.current

# With systemd:
systemctl set-property myapp.service MemoryMax=512M
systemctl set-property myapp.service CPUQuota=50%
```

---

## PAM — Pluggable Authentication Modules

PAM adalah framework autentikasi modular. Setiap aplikasi (login, ssh, sudo, passwd) punya file konfigurasi di `/etc/pam.d/`.

### Configuration File Format

```
type    control   module   arguments
```

**Types:**

| Type       | Kapan Di-exec                                                                             |
| ---------- | ----------------------------------------------------------------------------------------- |
| `auth`     | Autentikasi — verifikasi identitas (password, biometric, MFA, YubiKey)                    |
| `account`  | Otorisasi — cek apakah user diizinkan (expired, time-based, group)                        |
| `password` | Password change — update password hash                                                    |
| `session`  | Setup/teardown lingkungan sebelum/sesudah login (open PAM session, mount home, log audit) |

**Control values:**

| Control      | Arti                                                                     |
| ------------ | ------------------------------------------------------------------------ |
| `required`   | Harus sukses, tapi jalan terus ke module berikutnya (gagal di akhir)     |
| `requisite`  | Harus sukses, langsung gagal kalo tidak (gak jalan ke module berikutnya) |
| `sufficient` | Kalo sukses + belum gagal sebelumnya → langsung berhasil (skip sisa)     |
| `optional`   | Gak penting — cuma dipake kalo module lain butuh                         |

### Chain Example

```bash
# /etc/pam.d/sshd  (di Debian)
auth       required     pam_securetty.so      # Cegah root login via tty insecure
auth       requisite    pam_nologin.so         # Cegah login kalo /etc/nologin ada
auth       sufficient   pam_unix.so            # Password unix (/etc/shadow)
auth       required     pam_deny.so            # Fallback — deny kalo semua gagal
account    required     pam_unix.so            # Cek expired, disabled
account    required     pam_time.so            # Time-based access control
password   required     pam_unix.so            # Password change via /etc/shadow
session    required     pam_unix.so            # Log login
session    required     pam_lastlog.so         # Update lastlog
```

---

## Checklist

```
☐ FHS: tau beda /bin vs /usr/bin, /etc vs /tmp vs /var/tmp
☐ Permission: paham ugo/rwx, SUID/SGID/sticky, ACL
☐ chattr: tau immutable (+i) dan append-only (+a)
☐ Capabilities: tau cara set tanpa SUID
☐ Process: tau beda SIGHUP/SIGTERM/SIGKILL, bisa baca /proc/PID
☐ Systemd: bisa bikin service unit, tau journalctl, tau timer
☐ Netstat → ss: udah gak pake netstat lagi
☐ Package: tau apt/dnf/pacman dasar
☐ Mount: tau fstab format, tau lsblk, df, du
☐ Namespace: tau container isolation = namespace + cgroup
☐ Shell: tau quoting, exit code, pipefail, heredoc
☐ Troubleshooting: tau urutan strace → iostat → top → perf
```

---

## Koneksi ke Vault

- [[computer-science-foundations]] — OS internals level kernel (Ring 0, syscall, kernel module). Ini adalah lapisan di BAWAH administrasi Linux.
- [[linux-hardening-cis]] — security hardening Linux. Baca ini dulu sebelum hardening.
- [[infrastructure-administrator]] — network & server administration tingkat lanjut.
- [[ebpf-kernel-security]] — kernel tracing via eBPF — butuh paham process, syscall, dan kernel.
- [[container-kubernetes-security-deepdive]] — container isolation (namespace + cgroup).
- [[podman-networking-ufw]] — container networking.
- [[systemrescue-recovery]] — system rescue via live CD — butuh paham mount, chroot, filesystem.
- [[incident-response-framework]] — IR di Linux (forensik, log analysis).

---

## References

1. Linux Foundation. _Filesystem Hierarchy Standard 3.0_. https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
2. freedesktop.org. _systemd Documentation_. https://www.freedesktop.org/software/systemd/man/systemd.html
3. Linux man pages. _man 7 capabilities, man 7 namespaces, man 7 cgroups_. https://man7.org/linux/man-pages/
4. Debian. _APT User's Guide_. https://www.debian.org/doc/manuals/apt-guide/
5. Fedora. _DNF Documentation_. https://dnf.readthedocs.io/en/latest/
6. Arch Linux. _Pacman Documentation_. https://wiki.archlinux.org/title/pacman
7. Linux.com. _Linux Permissions Guide_. https://www.linux.com/training-tutorials/understanding-linux-file-permissions/
8. Red Hat. _PAM Documentation_. https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_authentication_and_authorization_in_rhel/pluggable-authentication-modules_pam
9. Red Hat. _Linux Namespaces_. https://www.redhat.com/en/topics/containers/what-is-a-linux-namespace
10. Kernel.org. _Cgroup v2 Documentation_. https://www.kernel.org/doc/Documentation/cgroup-v2.txt
11. TLDP. _Bash Guide for Beginners_. https://tldp.org/LDP/Bash-Beginners-Guide/html/
12. Google. _Shell Style Guide_. https://google.github.io/styleguide/shellguide.html
13. Ubuntu. _Netplan Documentation_. https://netplan.io/
14. NetworkManager. _nmcli Documentation_. https://networkmanager.dev/docs/api/latest/nmcli.html
15. Kernel.org. _Linux Kernel /proc Documentation_. https://www.kernel.org/doc/html/latest/filesystems/proc.html

> [!tip] Bottom Line
> Linux adalah **medan operasi utama** buat security engineer — server, container, embedded, cloud, semuanya Linux. Tanpa paham filesystem, process, systemd, dan namespaces, lo cuma bisa execute command tanpa ngerti dampaknya. Investasi waktu belajar Linux fundamentals adalah **investasi dengan ROI tertinggi** di karir ini karena (1) semua tool security jalan di atas Linux, (2) semua log ada di /var/log, (3) semua container = namespace + cgroup, (4) semua remote exploit ujungnya shell di Linux. Prioritaskan: **process & signals** (tau cara matiin/kill process dengan benar), **systemd** (service management modern), **permissions** (kenapa SUID berbahaya, apa itu capabilities), dan **troubleshooting** (tau strace, ss, iostat, dmesg ketika ada yang error).
